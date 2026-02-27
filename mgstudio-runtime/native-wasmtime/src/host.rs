use std::collections::HashMap;
use std::io::Read;
use std::time::{Duration, Instant};

use anyhow::{anyhow, Context};
use gilrs::{Axis as GilrsAxis, Button as GilrsButton, Gilrs};
use wasmtime::{AnyRef, Caller, ExternRef, Func, FuncType, Linker, Store, Val, ValType};

use winit::event::MouseButton;
use winit::keyboard::KeyCode;

use crate::gpu_backend::{load_wgsl_from_assets_required, GpuBackend};
use crate::native_window::NativeWindow;

use crate::source_spec::{join_dir_best_effort, DirSourceSpec};

const GAMEPAD_BUTTON_COUNT: usize = 20;
const GAMEPAD_AXIS_COUNT: usize = 9;
const KTX2_IDENTIFIER: [u8; 12] = [
    0xAB, 0x4B, 0x54, 0x58, 0x20, 0x32, 0x30, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A,
];
const KTX2_SUPERCOMPRESSION_NONE: u32 = 0;
const KTX2_SUPERCOMPRESSION_ZSTD: u32 = 2;

struct GamepadSnapshot {
    id: i32,
    name: String,
    vendor_id: Option<i32>,
    product_id: Option<i32>,
    button_values: [f32; GAMEPAD_BUTTON_COUNT],
    button_pressed: [bool; GAMEPAD_BUTTON_COUNT],
    axis_values: [f32; GAMEPAD_AXIS_COUNT],
}

impl GamepadSnapshot {
    fn new(id: i32) -> Self {
        Self {
            id,
            name: String::new(),
            vendor_id: None,
            product_id: None,
            button_values: [f32::NAN; GAMEPAD_BUTTON_COUNT],
            button_pressed: [false; GAMEPAD_BUTTON_COUNT],
            axis_values: [f32::NAN; GAMEPAD_AXIS_COUNT],
        }
    }
}

struct GamepadHostState {
    gilrs: Option<Gilrs>,
    snapshots: Vec<GamepadSnapshot>,
}

impl GamepadHostState {
    fn new() -> Self {
        Self {
            gilrs: Gilrs::new().ok(),
            snapshots: Vec::new(),
        }
    }

    fn poll(&mut self) {
        self.snapshots.clear();
        let Some(gilrs) = self.gilrs.as_mut() else {
            return;
        };

        while gilrs.next_event().is_some() {}

        for (id, gamepad) in gilrs.gamepads() {
            if !gamepad.is_connected() {
                continue;
            }
            let mut snapshot = GamepadSnapshot::new(usize::from(id) as i32);
            snapshot.name = gamepad.name().to_string();
            snapshot.vendor_id = gamepad.vendor_id().map(i32::from);
            snapshot.product_id = gamepad.product_id().map(i32::from);

            for button_index in 0..GAMEPAD_BUTTON_COUNT {
                if let Some(button) = gamepad_button_from_index(button_index as i32) {
                    if gamepad.button_code(button).is_some() {
                        snapshot.button_values[button_index] = gamepad
                            .button_data(button)
                            .map(|data| data.value())
                            .unwrap_or(f32::NAN);
                        snapshot.button_pressed[button_index] = gamepad.is_pressed(button);
                    }
                }
            }
            for axis_index in 0..GAMEPAD_AXIS_COUNT {
                if let Some(axis) = gamepad_axis_from_index(axis_index as i32) {
                    if gamepad.axis_code(axis).is_some() {
                        snapshot.axis_values[axis_index] = gamepad.value(axis);
                    }
                }
            }

            self.snapshots.push(snapshot);
        }
    }

    fn find(&self, gamepad_id: i32) -> Option<&GamepadSnapshot> {
        self.snapshots
            .iter()
            .find(|snapshot| snapshot.id == gamepad_id)
    }
}

pub struct HostState {
    pub trace_host: bool,
    pub assets: DirSourceSpec,
    #[allow(dead_code)]
    pub data: DirSourceSpec,

    start_time: Instant,

    // String sink/table (UTF-16 code units).
    string_sink: Vec<u16>,
    next_string_id: i32,
    strings: HashMap<i32, String>,

    // Bytes sink/table.
    bytes_sink: Vec<u8>,
    next_bytes_id: i32,
    bytes: HashMap<i32, Vec<u8>>,

    // Shader source table (for host_asset_load_wgsl handle identity).
    next_shader_id: i32,
    shaders: HashMap<i32, String>,

    // Font bytes table.
    next_font_id: i32,
    fonts: HashMap<i32, Vec<u8>>,

    // Legacy glyph raster table (used by `asset_update_texture_region` path).
    next_glyph_id: i32,
    glyphs: HashMap<i32, GlyphBitmap>,

    // Folder loading table/events.
    next_folder_id: i32,
    folders: HashMap<i32, Vec<i32>>,
    folder_events: Vec<(i32, i32)>,
    folder_event_pos: usize,

    // Shared unit rectangle mesh id for UI fallback and gizmo lines.
    unit_rect_mesh_id: Option<i32>,

    // Closures.
    next_closure_id: i32,
    closures: HashMap<i32, ClosureEntry>,

    window: Option<NativeWindow>,

    gamepads: GamepadHostState,

    gpu: Option<GpuBackend>,
}

struct GlyphBitmap {
    width: u32,
    height: u32,
    offset_x: i32,
    offset_y: i32,
    rgba8: Vec<u8>,
}

struct ClosureEntry {
    #[allow(dead_code)]
    func: Option<Func>,
    #[allow(dead_code)]
    env: Option<wasmtime::OwnedRooted<AnyRef>>,
}

impl HostState {
    pub fn new(assets: DirSourceSpec, data: DirSourceSpec, trace_host: bool) -> Self {
        Self {
            trace_host,
            assets,
            data,
            start_time: Instant::now(),
            string_sink: Vec::new(),
            next_string_id: 1,
            strings: HashMap::new(),
            bytes_sink: Vec::new(),
            next_bytes_id: 1,
            bytes: HashMap::new(),
            next_shader_id: 1,
            shaders: HashMap::new(),
            next_font_id: 1,
            fonts: HashMap::new(),
            next_glyph_id: 1,
            glyphs: HashMap::new(),
            next_folder_id: 1,
            folders: HashMap::new(),
            folder_events: Vec::new(),
            folder_event_pos: 0,
            unit_rect_mesh_id: None,
            next_closure_id: 1,
            closures: HashMap::new(),
            window: None,
            gamepads: GamepadHostState::new(),
            gpu: None,
        }
    }

    fn host_trace(&self, msg: &str) {
        if self.trace_host {
            eprintln!("{msg}");
        }
    }

    fn string_table_put(&mut self, text: String) -> i32 {
        if text.is_empty() {
            return 0;
        }
        let id = self.next_string_id;
        self.next_string_id += 1;
        self.strings.insert(id, text);
        id
    }

    fn string_table_get(&self, id: i32) -> Option<&str> {
        if id <= 0 {
            return None;
        }
        self.strings.get(&id).map(|s| s.as_str())
    }

    fn string_table_drop(&mut self, id: i32) {
        if id > 0 {
            self.strings.remove(&id);
        }
    }

    fn bytes_table_put(&mut self, data: Vec<u8>) -> i32 {
        if data.is_empty() {
            return 0;
        }
        let id = self.next_bytes_id;
        self.next_bytes_id += 1;
        self.bytes.insert(id, data);
        id
    }

    fn bytes_table_get(&self, id: i32) -> Option<&[u8]> {
        if id <= 0 {
            return None;
        }
        self.bytes.get(&id).map(|b| b.as_slice())
    }

    fn bytes_table_drop(&mut self, id: i32) {
        if id > 0 {
            self.bytes.remove(&id);
        }
    }

    fn shader_table_put(&mut self, source: String) -> i32 {
        if source.is_empty() {
            return -1;
        }
        let id = self.next_shader_id;
        self.next_shader_id += 1;
        self.shaders.insert(id, source);
        id
    }

    fn font_table_put(&mut self, bytes: Vec<u8>) -> i32 {
        if bytes.is_empty() {
            return -1;
        }
        let id = self.next_font_id;
        self.next_font_id += 1;
        self.fonts.insert(id, bytes);
        id
    }

    fn font_table_get(&self, id: i32) -> Option<&[u8]> {
        if id <= 0 {
            return None;
        }
        self.fonts.get(&id).map(|v| v.as_slice())
    }

    fn glyph_table_put(&mut self, glyph: GlyphBitmap) -> i32 {
        if glyph.width == 0 || glyph.height == 0 || glyph.rgba8.is_empty() {
            return -1;
        }
        let id = self.next_glyph_id;
        self.next_glyph_id += 1;
        self.glyphs.insert(id, glyph);
        id
    }

    fn glyph_table_get(&self, id: i32) -> Option<&GlyphBitmap> {
        if id <= 0 {
            return None;
        }
        self.glyphs.get(&id)
    }

    fn folder_table_set(&mut self, folder_id: i32, handles: Vec<i32>) {
        self.folders.insert(folder_id, handles);
    }

    fn folder_table_get(&self, folder_id: i32) -> Option<&[i32]> {
        self.folders.get(&folder_id).map(|v| v.as_slice())
    }

    fn folder_events_push(&mut self, kind: i32, folder_id: i32) {
        self.folder_events.push((kind, folder_id));
    }

    fn folder_events_poll_kind(&self) -> i32 {
        if self.folder_event_pos >= self.folder_events.len() {
            -1
        } else {
            self.folder_events[self.folder_event_pos].0
        }
    }

    fn folder_events_poll_id(&mut self) -> i32 {
        if self.folder_event_pos >= self.folder_events.len() {
            self.folder_events.clear();
            self.folder_event_pos = 0;
            return -1;
        }
        let id = self.folder_events[self.folder_event_pos].1;
        self.folder_event_pos += 1;
        if self.folder_event_pos >= self.folder_events.len() {
            self.folder_events.clear();
            self.folder_event_pos = 0;
        }
        id
    }

    fn now_millis_f32(&self) -> f32 {
        let dt: Duration = self.start_time.elapsed();
        dt.as_secs_f32() * 1000.0
    }

    fn ensure_gpu(&mut self) -> anyhow::Result<&mut GpuBackend> {
        if self.gpu.is_none() {
            self.gpu = Some(GpuBackend::new(self.assets.base.clone())?);
        }
        Ok(self.gpu.as_mut().unwrap())
    }

    fn ensure_unit_rect_mesh(&mut self) -> anyhow::Result<i32> {
        if let Some(mesh_id) = self.unit_rect_mesh_id {
            return Ok(mesh_id);
        }
        let mesh_id = {
            let gpu = self.ensure_gpu()?;
            gpu.create_mesh_rectangle(1.0, 1.0)
        };
        self.unit_rect_mesh_id = Some(mesh_id);
        Ok(mesh_id)
    }
}

fn parse_keycode(code: &str) -> Option<KeyCode> {
    match code {
        "KeyA" => Some(KeyCode::KeyA),
        "KeyB" => Some(KeyCode::KeyB),
        "KeyC" => Some(KeyCode::KeyC),
        "KeyD" => Some(KeyCode::KeyD),
        "KeyE" => Some(KeyCode::KeyE),
        "KeyF" => Some(KeyCode::KeyF),
        "KeyG" => Some(KeyCode::KeyG),
        "KeyH" => Some(KeyCode::KeyH),
        "KeyI" => Some(KeyCode::KeyI),
        "KeyJ" => Some(KeyCode::KeyJ),
        "KeyK" => Some(KeyCode::KeyK),
        "KeyL" => Some(KeyCode::KeyL),
        "KeyM" => Some(KeyCode::KeyM),
        "KeyN" => Some(KeyCode::KeyN),
        "KeyO" => Some(KeyCode::KeyO),
        "KeyP" => Some(KeyCode::KeyP),
        "KeyQ" => Some(KeyCode::KeyQ),
        "KeyR" => Some(KeyCode::KeyR),
        "KeyS" => Some(KeyCode::KeyS),
        "KeyT" => Some(KeyCode::KeyT),
        "KeyU" => Some(KeyCode::KeyU),
        "KeyV" => Some(KeyCode::KeyV),
        "KeyW" => Some(KeyCode::KeyW),
        "KeyX" => Some(KeyCode::KeyX),
        "KeyY" => Some(KeyCode::KeyY),
        "KeyZ" => Some(KeyCode::KeyZ),
        "Digit1" => Some(KeyCode::Digit1),
        "Digit2" => Some(KeyCode::Digit2),
        "Digit3" => Some(KeyCode::Digit3),
        "Digit4" => Some(KeyCode::Digit4),
        "Digit5" => Some(KeyCode::Digit5),
        "Digit6" => Some(KeyCode::Digit6),
        "Digit7" => Some(KeyCode::Digit7),
        "Digit8" => Some(KeyCode::Digit8),
        "Tab" => Some(KeyCode::Tab),
        "Enter" => Some(KeyCode::Enter),
        "Backspace" => Some(KeyCode::Backspace),
        "ShiftLeft" => Some(KeyCode::ShiftLeft),
        "ShiftRight" => Some(KeyCode::ShiftRight),
        "ControlLeft" => Some(KeyCode::ControlLeft),
        "ControlRight" => Some(KeyCode::ControlRight),
        "ArrowUp" => Some(KeyCode::ArrowUp),
        "ArrowDown" => Some(KeyCode::ArrowDown),
        "ArrowLeft" => Some(KeyCode::ArrowLeft),
        "ArrowRight" => Some(KeyCode::ArrowRight),
        "PageUp" => Some(KeyCode::PageUp),
        "PageDown" => Some(KeyCode::PageDown),
        "Space" => Some(KeyCode::Space),
        "Escape" => Some(KeyCode::Escape),
        "Semicolon" => Some(KeyCode::Semicolon),
        "Comma" => Some(KeyCode::Comma),
        "Period" => Some(KeyCode::Period),
        "Slash" => Some(KeyCode::Slash),
        _ => None,
    }
}

fn parse_mouse_button(btn: &str) -> Option<MouseButton> {
    match btn {
        "Left" => Some(MouseButton::Left),
        "Right" => Some(MouseButton::Right),
        "Middle" => Some(MouseButton::Middle),
        _ => None,
    }
}

fn gamepad_button_from_index(index: i32) -> Option<GilrsButton> {
    match index {
        0 => Some(GilrsButton::South),
        1 => Some(GilrsButton::East),
        2 => Some(GilrsButton::C),
        3 => Some(GilrsButton::North),
        4 => Some(GilrsButton::West),
        5 => Some(GilrsButton::Z),
        6 => Some(GilrsButton::LeftTrigger),
        7 => Some(GilrsButton::RightTrigger),
        8 => Some(GilrsButton::LeftTrigger2),
        9 => Some(GilrsButton::RightTrigger2),
        10 => Some(GilrsButton::Select),
        11 => Some(GilrsButton::Start),
        12 => Some(GilrsButton::Mode),
        13 => Some(GilrsButton::LeftThumb),
        14 => Some(GilrsButton::RightThumb),
        15 => Some(GilrsButton::DPadUp),
        16 => Some(GilrsButton::DPadDown),
        17 => Some(GilrsButton::DPadLeft),
        18 => Some(GilrsButton::DPadRight),
        _ => None,
    }
}

fn gamepad_axis_from_index(index: i32) -> Option<GilrsAxis> {
    match index {
        0 => Some(GilrsAxis::LeftStickX),
        1 => Some(GilrsAxis::LeftStickY),
        2 => Some(GilrsAxis::LeftZ),
        3 => Some(GilrsAxis::RightStickX),
        4 => Some(GilrsAxis::RightStickY),
        5 => Some(GilrsAxis::RightZ),
        6 => Some(GilrsAxis::DPadX),
        7 => Some(GilrsAxis::DPadY),
        _ => None,
    }
}

fn strip_leading_slashes(path: &str) -> &str {
    path.trim_start_matches('/')
}

fn split_trimmed_lines(text: &str) -> impl Iterator<Item = &str> {
    text.lines()
        .map(|line| line.trim())
        .filter(|line| !line.is_empty() && !line.starts_with('#'))
}

#[derive(Clone, Copy)]
struct Ktx2Header {
    vk_format: u32,
    pixel_width: u32,
    pixel_height: u32,
    pixel_depth: u32,
    layer_count: u32,
    face_count: u32,
    supercompression_scheme: u32,
}

#[derive(Clone, Copy)]
struct Ktx2LevelIndex {
    byte_offset: u64,
    byte_length: u64,
    uncompressed_byte_length: u64,
}

#[derive(Clone, Copy)]
struct Ktx2BlockLayout {
    block_width: u32,
    block_height: u32,
    block_bytes: u32,
}

impl Ktx2BlockLayout {
    fn bytes_for_level(self, width: u32, height: u32) -> anyhow::Result<usize> {
        let width = width.max(1);
        let height = height.max(1);
        let blocks_w = width.div_ceil(self.block_width).max(1);
        let blocks_h = height.div_ceil(self.block_height).max(1);
        let bytes_per_row = blocks_w
            .checked_mul(self.block_bytes)
            .ok_or_else(|| anyhow!("KTX2: bytes_per_row overflow"))?;
        let total_bytes_u64 = u64::from(bytes_per_row) * u64::from(blocks_h);
        usize::try_from(total_bytes_u64)
            .context("KTX2: texture level data is too large for host usize")
    }
}

struct Ktx2UploadTexture {
    width: u32,
    height_per_slice: u32,
    slice_count: u32,
    format: wgpu::TextureFormat,
    levels: Vec<Vec<u8>>,
}

fn is_ktx2(bytes: &[u8]) -> bool {
    bytes.len() >= KTX2_IDENTIFIER.len() && bytes.starts_with(&KTX2_IDENTIFIER)
}

fn read_u32_le(bytes: &[u8], offset: usize) -> anyhow::Result<u32> {
    let end = offset.saturating_add(4);
    let chunk = bytes
        .get(offset..end)
        .ok_or_else(|| anyhow!("KTX2: truncated u32 at offset {offset}"))?;
    Ok(u32::from_le_bytes([chunk[0], chunk[1], chunk[2], chunk[3]]))
}

fn read_u64_le(bytes: &[u8], offset: usize) -> anyhow::Result<u64> {
    let end = offset.saturating_add(8);
    let chunk = bytes
        .get(offset..end)
        .ok_or_else(|| anyhow!("KTX2: truncated u64 at offset {offset}"))?;
    Ok(u64::from_le_bytes([
        chunk[0], chunk[1], chunk[2], chunk[3], chunk[4], chunk[5], chunk[6], chunk[7],
    ]))
}

fn parse_ktx2(bytes: &[u8]) -> anyhow::Result<(Ktx2Header, Vec<Ktx2LevelIndex>)> {
    if !is_ktx2(bytes) {
        return Err(anyhow!("KTX2: invalid identifier"));
    }
    if bytes.len() < 80 {
        return Err(anyhow!("KTX2: file shorter than header"));
    }
    let vk_format = read_u32_le(bytes, 12)?;
    let pixel_width = read_u32_le(bytes, 20)?;
    let pixel_height = read_u32_le(bytes, 24)?;
    let pixel_depth = read_u32_le(bytes, 28)?;
    let layer_count = read_u32_le(bytes, 32)?;
    let face_count = read_u32_le(bytes, 36)?;
    let level_count_raw = read_u32_le(bytes, 40)?;
    let supercompression_scheme = read_u32_le(bytes, 44)?;
    let level_count = level_count_raw.max(1);
    let header = Ktx2Header {
        vk_format,
        pixel_width,
        pixel_height,
        pixel_depth,
        layer_count,
        face_count,
        supercompression_scheme,
    };
    if header.pixel_width == 0 || header.pixel_height == 0 {
        return Err(anyhow!(
            "KTX2: zero-sized texture {}x{}",
            header.pixel_width,
            header.pixel_height
        ));
    }
    let mut levels = Vec::with_capacity(level_count as usize);
    let mut offset = 80usize;
    for _ in 0..level_count {
        let byte_offset = read_u64_le(bytes, offset)?;
        let byte_length = read_u64_le(bytes, offset + 8)?;
        let uncompressed_byte_length = read_u64_le(bytes, offset + 16)?;
        levels.push(Ktx2LevelIndex {
            byte_offset,
            byte_length,
            uncompressed_byte_length,
        });
        offset = offset.saturating_add(24);
    }
    Ok((header, levels))
}

fn ktx2_format_info(vk_format: u32) -> anyhow::Result<(wgpu::TextureFormat, Ktx2BlockLayout)> {
    match vk_format {
        // VK_FORMAT_R16G16B16A16_SFLOAT
        97 => Ok((
            wgpu::TextureFormat::Rgba16Float,
            Ktx2BlockLayout {
                block_width: 1,
                block_height: 1,
                block_bytes: 8,
            },
        )),
        // VK_FORMAT_E5B9G9R9_UFLOAT_PACK32
        123 => Ok((
            wgpu::TextureFormat::Rgb9e5Ufloat,
            Ktx2BlockLayout {
                block_width: 1,
                block_height: 1,
                block_bytes: 4,
            },
        )),
        // VK_FORMAT_BC7_UNORM_BLOCK
        146 => Ok((
            wgpu::TextureFormat::Bc7RgbaUnorm,
            Ktx2BlockLayout {
                block_width: 4,
                block_height: 4,
                block_bytes: 16,
            },
        )),
        // VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK
        148 => Ok((
            wgpu::TextureFormat::Etc2Rgba8Unorm,
            Ktx2BlockLayout {
                block_width: 4,
                block_height: 4,
                block_bytes: 16,
            },
        )),
        // VK_FORMAT_ASTC_4x4_UNORM_BLOCK
        158 => Ok((
            wgpu::TextureFormat::Astc {
                block: wgpu::AstcBlock::B4x4,
                channel: wgpu::AstcChannel::Unorm,
            },
            Ktx2BlockLayout {
                block_width: 4,
                block_height: 4,
                block_bytes: 16,
            },
        )),
        _ => Err(anyhow!("KTX2: unsupported vkFormat {}", vk_format)),
    }
}

fn ktx2_decode_level(
    bytes: &[u8],
    header: Ktx2Header,
    level_index: usize,
    level: Ktx2LevelIndex,
) -> anyhow::Result<Vec<u8>> {
    let start = usize::try_from(level.byte_offset)
        .context("KTX2: level offset exceeds host address space")?;
    let len =
        usize::try_from(level.byte_length).context("KTX2: level length exceeds host usize")?;
    let end = start
        .checked_add(len)
        .ok_or_else(|| anyhow!("KTX2: level range overflow"))?;
    let level_data = bytes
        .get(start..end)
        .ok_or_else(|| anyhow!("KTX2: level data range out of bounds"))?;
    match header.supercompression_scheme {
        KTX2_SUPERCOMPRESSION_NONE => Ok(level_data.to_vec()),
        KTX2_SUPERCOMPRESSION_ZSTD => {
            let mut cursor = std::io::Cursor::new(level_data);
            let mut decoder = ruzstd::decoding::StreamingDecoder::new(&mut cursor)
                .map_err(|err| anyhow!("KTX2: zstd decoder init failed: {err}"))?;
            let mut decoded = Vec::new();
            decoder
                .read_to_end(&mut decoded)
                .map_err(|err| anyhow!("KTX2: zstd decode failed at mip {level_index}: {err}"))?;
            if level.uncompressed_byte_length > 0 {
                let expected = usize::try_from(level.uncompressed_byte_length)
                    .context("KTX2: uncompressed level length exceeds host usize")?;
                if decoded.len() != expected {
                    return Err(anyhow!(
                        "KTX2: mip {level_index} decoded size mismatch: got {}, expected {expected}",
                        decoded.len()
                    ));
                }
            }
            Ok(decoded)
        }
        other => Err(anyhow!("KTX2: unsupported supercompression scheme {other}")),
    }
}

fn parse_ktx2_texture(bytes: &[u8]) -> anyhow::Result<Ktx2UploadTexture> {
    let (header, levels) = parse_ktx2(bytes)?;
    let (format, block_layout) = ktx2_format_info(header.vk_format)?;
    let width = header.pixel_width.max(1);
    let height_per_slice = header.pixel_height.max(1);
    let depth = header.pixel_depth.max(1);
    let layers = header.layer_count.max(1);
    let faces = header.face_count.max(1);
    let slice_count = layers
        .checked_mul(faces)
        .and_then(|v| v.checked_mul(depth))
        .ok_or_else(|| anyhow!("KTX2: slice count overflow"))?;
    if slice_count == 0 {
        return Err(anyhow!("KTX2: invalid slice count"));
    }

    let mut stacked_levels = Vec::with_capacity(levels.len());
    for (mip_index, level) in levels.iter().copied().enumerate() {
        let mip = mip_index as u32;
        let mip_width = (width >> mip).max(1);
        let mip_height = (height_per_slice >> mip).max(1);
        let mip_depth = (depth >> mip).max(1);
        let mip_slice_count = layers
            .checked_mul(faces)
            .and_then(|v| v.checked_mul(mip_depth))
            .ok_or_else(|| anyhow!("KTX2: mip slice count overflow"))?;
        if mip_slice_count != slice_count {
            if mip_index == 0 {
                return Err(anyhow!("KTX2: invalid slice count at mip 0"));
            }
            // Stacked-2D upload cannot represent depth-shrinking mips from true
            // 3D textures. Keep mip 0 only (enough for LUT sampling paths).
            break;
        }
        let per_slice_bytes = block_layout.bytes_for_level(mip_width, mip_height)?;
        let expected_level_bytes = per_slice_bytes
            .checked_mul(mip_slice_count as usize)
            .ok_or_else(|| anyhow!("KTX2: mip byte size overflow"))?;
        let decoded = ktx2_decode_level(bytes, header, mip_index, level)?;
        if decoded.len() < expected_level_bytes {
            return Err(anyhow!(
                "KTX2: mip {mip_index} data too short: got {}, expected at least {expected_level_bytes}",
                decoded.len()
            ));
        }
        stacked_levels.push(decoded[..expected_level_bytes].to_vec());
    }

    Ok(Ktx2UploadTexture {
        width,
        height_per_slice,
        slice_count,
        format,
        levels: stacked_levels,
    })
}

fn load_texture_from_ktx2(
    state: &mut HostState,
    bytes: &[u8],
    nearest: bool,
) -> anyhow::Result<i32> {
    let parsed = parse_ktx2_texture(bytes)?;
    let gpu = state.ensure_gpu()?;
    gpu.create_texture_stacked_2d_with_format(
        parsed.width,
        parsed.height_per_slice,
        parsed.slice_count,
        parsed.format,
        &parsed.levels,
        nearest,
    )
}

fn load_texture_from_assets(
    state: &mut HostState,
    relative_path: &str,
    nearest: bool,
) -> anyhow::Result<i32> {
    let rel = relative_path.trim();
    let file_bytes = if rel.is_empty() {
        vec![]
    } else {
        let full_path = join_dir_best_effort(&state.assets.base, strip_leading_slashes(rel));
        std::fs::read(&full_path).unwrap_or_default()
    };
    load_texture_from_bytes(state, &file_bytes, nearest)
}

fn load_texture_from_bytes(
    state: &mut HostState,
    bytes: &[u8],
    nearest: bool,
) -> anyhow::Result<i32> {
    if is_ktx2(bytes) {
        match load_texture_from_ktx2(state, bytes, nearest) {
            Ok(texture_id) => return Ok(texture_id),
            Err(err) => {
                eprintln!(
                    "[wasmtime-runtime] KTX2 upload failed; falling back to rgba8 decode: {err:#}"
                );
            }
        }
    }
    let (w, h, pixels) = match image::load_from_memory(bytes) {
        Ok(img) => {
            let rgba = img.to_rgba8();
            (rgba.width(), rgba.height(), rgba.into_raw())
        }
        Err(_) => (1u32, 1u32, vec![255u8, 255u8, 255u8, 255u8]),
    };
    let gpu = state.ensure_gpu()?;
    gpu.create_texture_rgba8(w, h, &pixels, nearest)
}

fn ok_i32(out: &mut [Val], value: i32) {
    out[0] = Val::I32(value);
}

fn ok_f32(out: &mut [Val], value: f32) {
    out[0] = Val::F32(value.to_bits());
}

fn ok_externref_null(out: &mut [Val]) {
    out[0] = Val::ExternRef(None);
}

fn ok_externref_i32(
    mut caller: impl wasmtime::AsContextMut,
    out: &mut [Val],
    value: i32,
) -> anyhow::Result<()> {
    let r = ExternRef::new(&mut caller, value)?;
    out[0] = Val::ExternRef(Some(r));
    Ok(())
}

pub fn define_imports(
    store: &mut Store<HostState>,
    linker: &mut Linker<HostState>,
) -> anyhow::Result<()> {
    define_mgstudio_host_imports(store, linker)?;
    define_moonbit_ffi_imports(store, linker)?;
    define_spectest_imports(store, linker)?;
    Ok(())
}

fn define_mgstudio_host_imports(
    store: &mut Store<HostState>,
    linker: &mut Linker<HostState>,
) -> anyhow::Result<()> {
    // string_sink_reset() -> i32
    define_func(
        store,
        linker,
        "mgstudio_host",
        "string_sink_reset",
        &[],
        &[ValType::I32],
        |mut caller, _args, out| {
            caller.data().host_trace("host: string_sink_reset");
            caller.data_mut().string_sink.clear();
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    // string_sink_push(i32) -> i32
    define_func(
        store,
        linker,
        "mgstudio_host",
        "string_sink_push",
        &[ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            caller.data().host_trace("host: string_sink_push");
            if let Some(cu) = args.get(0).and_then(|v| v.i32()) {
                caller
                    .data_mut()
                    .string_sink
                    .push((cu as u32 & 0xFFFF) as u16);
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    // string_sink_take() -> i32
    define_func(
        store,
        linker,
        "mgstudio_host",
        "string_sink_take",
        &[],
        &[ValType::I32],
        |mut caller, _args, out| {
            caller.data().host_trace("host: string_sink_take");
            let text = String::from_utf16_lossy(&caller.data().string_sink);
            caller.data_mut().string_sink.clear();
            let id = caller.data_mut().string_table_put(text);
            ok_i32(out, id);
            Ok(())
        },
    )?;

    // string_drop(i32) -> i32
    define_func(
        store,
        linker,
        "mgstudio_host",
        "string_drop",
        &[ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            if let Some(id) = args.get(0).and_then(|v| v.i32()) {
                caller.data_mut().string_table_drop(id);
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    // bytes_sink_reset() -> i32
    define_func(
        store,
        linker,
        "mgstudio_host",
        "bytes_sink_reset",
        &[],
        &[ValType::I32],
        |mut caller, _args, out| {
            caller.data().host_trace("host: bytes_sink_reset");
            caller.data_mut().bytes_sink.clear();
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    // bytes_sink_push(i32) -> i32
    define_func(
        store,
        linker,
        "mgstudio_host",
        "bytes_sink_push",
        &[ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            caller.data().host_trace("host: bytes_sink_push");
            if let Some(x) = args.get(0).and_then(|v| v.i32()) {
                caller.data_mut().bytes_sink.push((x as u32 & 0xFF) as u8);
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    // bytes_sink_push_u32(i32) -> i32
    define_func(
        store,
        linker,
        "mgstudio_host",
        "bytes_sink_push_u32",
        &[ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            caller.data().host_trace("host: bytes_sink_push_u32");
            if let Some(word) = args.get(0).and_then(|v| v.i32()) {
                let u = word as u32;
                caller
                    .data_mut()
                    .bytes_sink
                    .extend_from_slice(&u.to_le_bytes());
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    // bytes_sink_take() -> i32
    define_func(
        store,
        linker,
        "mgstudio_host",
        "bytes_sink_take",
        &[],
        &[ValType::I32],
        |mut caller, _args, out| {
            caller.data().host_trace("host: bytes_sink_take");
            let data = std::mem::take(&mut caller.data_mut().bytes_sink);
            let id = caller.data_mut().bytes_table_put(data);
            ok_i32(out, id);
            Ok(())
        },
    )?;

    // bytes_drop(i32) -> i32
    define_func(
        store,
        linker,
        "mgstudio_host",
        "bytes_drop",
        &[ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            if let Some(id) = args.get(0).and_then(|v| v.i32()) {
                caller.data_mut().bytes_table_drop(id);
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    // debug_string(i32) -> i32
    define_func(
        store,
        linker,
        "mgstudio_host",
        "debug_string",
        &[ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            if let Some(id) = args.get(0).and_then(|v| v.i32()) {
                if let Some(msg) = caller.data().string_table_get(id) {
                    eprintln!("{msg}");
                }
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    // A11y (stubbed in wasmtime backend for now).
    define_func(
        store,
        linker,
        "mgstudio_host",
        "a11y_begin_update",
        &[ValType::I32],
        &[ValType::I32],
        |caller, _args, out| {
            caller.data().host_trace("host: a11y_begin_update");
            ok_i32(out, 0);
            Ok(())
        },
    )?;
    define_func(
        store,
        linker,
        "mgstudio_host",
        "a11y_push_node",
        &[
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::I32,
            ValType::I32,
        ],
        &[ValType::I32],
        |caller, _args, out| {
            caller.data().host_trace("host: a11y_push_node");
            ok_i32(out, 0);
            Ok(())
        },
    )?;
    define_func(
        store,
        linker,
        "mgstudio_host",
        "a11y_end_update",
        &[],
        &[ValType::I32],
        |caller, _args, out| {
            caller.data().host_trace("host: a11y_end_update");
            ok_i32(out, 0);
            Ok(())
        },
    )?;
    define_func(
        store,
        linker,
        "mgstudio_host",
        "a11y_apply_update",
        &[ValType::I32],
        &[ValType::I32],
        |caller, _args, out| {
            caller.data().host_trace("host: a11y_apply_update");
            ok_i32(out, 0);
            Ok(())
        },
    )?;
    define_func(
        store,
        linker,
        "mgstudio_host",
        "a11y_actions_len",
        &[],
        &[ValType::I32],
        |caller, _args, out| {
            caller.data().host_trace("host: a11y_actions_len");
            ok_i32(out, 0);
            Ok(())
        },
    )?;
    define_func(
        store,
        linker,
        "mgstudio_host",
        "a11y_action_target",
        &[ValType::I32],
        &[ValType::I32],
        |caller, _args, out| {
            caller.data().host_trace("host: a11y_action_target");
            ok_i32(out, -1);
            Ok(())
        },
    )?;
    define_func(
        store,
        linker,
        "mgstudio_host",
        "a11y_action_kind",
        &[ValType::I32],
        &[ValType::I32],
        |caller, _args, out| {
            caller.data().host_trace("host: a11y_action_kind");
            ok_i32(out, 0);
            Ok(())
        },
    )?;
    define_func(
        store,
        linker,
        "mgstudio_host",
        "a11y_action_value_len",
        &[ValType::I32],
        &[ValType::I32],
        |caller, _args, out| {
            caller.data().host_trace("host: a11y_action_value_len");
            ok_i32(out, 0);
            Ok(())
        },
    )?;
    define_func(
        store,
        linker,
        "mgstudio_host",
        "a11y_action_value_code_unit",
        &[ValType::I32, ValType::I32],
        &[ValType::I32],
        |caller, _args, out| {
            caller
                .data()
                .host_trace("host: a11y_action_value_code_unit");
            ok_i32(out, 0);
            Ok(())
        },
    )?;
    define_func(
        store,
        linker,
        "mgstudio_host",
        "a11y_actions_clear",
        &[],
        &[ValType::I32],
        |caller, _args, out| {
            caller.data().host_trace("host: a11y_actions_clear");
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    // Window.
    define_func(
        store,
        linker,
        "mgstudio_host",
        "window_create",
        &[ValType::I32, ValType::I32, ValType::I32],
        &[ValType::EXTERNREF],
        |mut caller, args, out| {
            caller.data().host_trace("host: window_create");
            let width = args.get(0).and_then(|v| v.i32()).unwrap_or(800);
            let height = args.get(1).and_then(|v| v.i32()).unwrap_or(600);
            let title = args
                .get(2)
                .and_then(|v| v.i32())
                .and_then(|id| caller.data().string_table_get(id).map(|s| s.to_string()))
                .unwrap_or_else(|| "Moon Game Studio".to_string());

            if caller.data().window.is_none() {
                let win = NativeWindow::create(width, height, &title).context("create window")?;
                caller.data_mut().window = Some(win);
            }
            ok_externref_i32(&mut caller, out, 10_001)?;
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_supported_compressed_image_formats",
        &[],
        &[ValType::I32],
        |mut caller, _args, out| {
            let gpu = caller.data_mut().ensure_gpu()?;
            ok_i32(out, gpu.supported_compressed_image_formats_mask());
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "window_run_loop",
        &[ValType::FUNCREF],
        &[ValType::I32],
        |mut caller, args, out| {
            caller.data().host_trace("host: window_run_loop");
            let tick = match args.get(0) {
                Some(Val::FuncRef(Some(f))) => f.clone(),
                _ => {
                    ok_i32(out, 0);
                    return Ok(());
                }
            };

            loop {
                // The guest is responsible for calling `window_poll_events` each tick.
                tick.call(&mut caller, &[], &mut [])
                    .context("tick() trapped")?;
                let should_close = caller
                    .data()
                    .window
                    .as_ref()
                    .map(|w| w.should_close)
                    .unwrap_or(true);
                if should_close {
                    break;
                }
                // Avoid a pure busy loop during bring-up (GPU is still stubbed).
                std::thread::sleep(Duration::from_millis(1));
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "window_poll_events",
        &[ValType::EXTERNREF],
        &[ValType::I32],
        |mut caller, _args, out| {
            if let Some(win) = caller.data_mut().window.as_mut() {
                win.pump_events();
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "window_get_width",
        &[ValType::EXTERNREF],
        &[ValType::I32],
        |caller, _args, out| {
            let w = caller
                .data()
                .window
                .as_ref()
                .map(|win| win.inner_size().width as i32)
                .unwrap_or(0);
            ok_i32(out, w);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "window_get_height",
        &[ValType::EXTERNREF],
        &[ValType::I32],
        |caller, _args, out| {
            let h = caller
                .data()
                .window
                .as_ref()
                .map(|win| win.inner_size().height as i32)
                .unwrap_or(0);
            ok_i32(out, h);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "window_get_scale_factor",
        &[ValType::EXTERNREF],
        &[ValType::F32],
        |caller, _args, out| {
            let sf = caller
                .data()
                .window
                .as_ref()
                .map(|win| win.scale_factor() as f32)
                .unwrap_or(1.0);
            ok_f32(out, sf);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "window_should_close",
        &[ValType::EXTERNREF],
        &[ValType::I32],
        |caller, _args, out| {
            let should_close = caller
                .data()
                .window
                .as_ref()
                .map(|win| win.should_close)
                .unwrap_or(true);
            ok_i32(out, if should_close { 1 } else { 0 });
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "window_request_close",
        &[ValType::EXTERNREF],
        &[ValType::I32],
        |mut caller, _args, out| {
            if let Some(win) = caller.data_mut().window.as_mut() {
                win.should_close = true;
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "window_set_title",
        &[ValType::EXTERNREF, ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            if let (Some(win), Some(title_id)) = (
                caller.data().window.as_ref(),
                args.get(1).and_then(|v| v.i32()),
            ) {
                if let Some(title) = caller.data().string_table_get(title_id) {
                    win.set_title(title);
                }
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "window_set_size",
        &[ValType::EXTERNREF, ValType::I32, ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            if let (Some(win), Some(width), Some(height)) = (
                caller.data().window.as_ref(),
                args.get(1).and_then(|v| v.i32()),
                args.get(2).and_then(|v| v.i32()),
            ) {
                win.set_size(width, height);
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "window_set_resizable",
        &[ValType::EXTERNREF, ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            if let (Some(win), Some(resizable_i32)) = (
                caller.data().window.as_ref(),
                args.get(1).and_then(|v| v.i32()),
            ) {
                win.set_resizable(resizable_i32 != 0);
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "window_set_cursor_visible",
        &[ValType::EXTERNREF, ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            if let (Some(win), Some(visible_i32)) = (
                caller.data().window.as_ref(),
                args.get(1).and_then(|v| v.i32()),
            ) {
                win.set_cursor_visible(visible_i32 != 0);
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "window_set_cursor_grab_mode",
        &[ValType::EXTERNREF, ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            if let (Some(win), Some(mode)) = (
                caller.data().window.as_ref(),
                args.get(1).and_then(|v| v.i32()),
            ) {
                win.set_cursor_grab_mode(mode);
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "window_set_mode",
        &[ValType::EXTERNREF, ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            if let (Some(win), Some(mode)) = (
                caller.data().window.as_ref(),
                args.get(1).and_then(|v| v.i32()),
            ) {
                win.set_mode(mode);
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "window_set_position",
        &[ValType::EXTERNREF, ValType::I32, ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            if let (Some(win), Some(x), Some(y)) = (
                caller.data().window.as_ref(),
                args.get(1).and_then(|v| v.i32()),
                args.get(2).and_then(|v| v.i32()),
            ) {
                win.set_position(x, y);
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "window_get_position_x",
        &[ValType::EXTERNREF],
        &[ValType::I32],
        |caller, _args, out| {
            let x = caller
                .data()
                .window
                .as_ref()
                .map(|win| win.position_x())
                .unwrap_or(0);
            ok_i32(out, x);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "window_get_position_y",
        &[ValType::EXTERNREF],
        &[ValType::I32],
        |caller, _args, out| {
            let y = caller
                .data()
                .window
                .as_ref()
                .map(|win| win.position_y())
                .unwrap_or(0);
            ok_i32(out, y);
            Ok(())
        },
    )?;

    // time_now() -> f32
    define_func(
        store,
        linker,
        "mgstudio_host",
        "time_now",
        &[],
        &[ValType::F32],
        |caller, _args, out| {
            ok_f32(out, caller.data().now_millis_f32());
            Ok(())
        },
    )?;

    // Input.
    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_gamepad_poll",
        &[],
        &[ValType::I32],
        |mut caller, _args, out| {
            caller.data_mut().gamepads.poll();
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_gamepad_count",
        &[],
        &[ValType::I32],
        |caller, _args, out| {
            ok_i32(out, caller.data().gamepads.snapshots.len() as i32);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_gamepad_id",
        &[ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let index = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let id = if index >= 0 {
                caller
                    .data()
                    .gamepads
                    .snapshots
                    .get(index as usize)
                    .map(|snapshot| snapshot.id)
                    .unwrap_or(-1)
            } else {
                -1
            };
            ok_i32(out, id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_gamepad_connected",
        &[ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let gamepad_id = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let connected = caller.data().gamepads.find(gamepad_id).is_some();
            ok_i32(out, if connected { 1 } else { 0 });
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_gamepad_name_len",
        &[ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let gamepad_id = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let len = caller
                .data()
                .gamepads
                .find(gamepad_id)
                .map(|snapshot| snapshot.name.encode_utf16().count() as i32)
                .unwrap_or(0);
            ok_i32(out, len);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_gamepad_name_code_unit",
        &[ValType::I32, ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let gamepad_id = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let offset = args.get(1).and_then(|v| v.i32()).unwrap_or(-1);
            let code_unit = if offset >= 0 {
                caller
                    .data()
                    .gamepads
                    .find(gamepad_id)
                    .and_then(|snapshot| snapshot.name.encode_utf16().nth(offset as usize))
                    .map(|v| v as i32)
                    .unwrap_or(0)
            } else {
                0
            };
            ok_i32(out, code_unit);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_gamepad_vendor_id",
        &[ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let gamepad_id = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let vendor_id = caller
                .data()
                .gamepads
                .find(gamepad_id)
                .and_then(|snapshot| snapshot.vendor_id)
                .unwrap_or(-1);
            ok_i32(out, vendor_id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_gamepad_product_id",
        &[ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let gamepad_id = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let product_id = caller
                .data()
                .gamepads
                .find(gamepad_id)
                .and_then(|snapshot| snapshot.product_id)
                .unwrap_or(-1);
            ok_i32(out, product_id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_gamepad_button_value",
        &[ValType::I32, ValType::I32],
        &[ValType::F32],
        |caller, args, out| {
            let gamepad_id = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let button_index = args.get(1).and_then(|v| v.i32()).unwrap_or(-1);
            let value = if button_index >= 0 {
                caller
                    .data()
                    .gamepads
                    .find(gamepad_id)
                    .and_then(|snapshot| snapshot.button_values.get(button_index as usize))
                    .copied()
                    .unwrap_or(f32::NAN)
            } else {
                f32::NAN
            };
            ok_f32(out, value);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_gamepad_button_pressed",
        &[ValType::I32, ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let gamepad_id = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let button_index = args.get(1).and_then(|v| v.i32()).unwrap_or(-1);
            let pressed = if button_index >= 0 {
                caller
                    .data()
                    .gamepads
                    .find(gamepad_id)
                    .and_then(|snapshot| snapshot.button_pressed.get(button_index as usize))
                    .copied()
                    .unwrap_or(false)
            } else {
                false
            };
            ok_i32(out, if pressed { 1 } else { 0 });
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_gamepad_axis_value",
        &[ValType::I32, ValType::I32],
        &[ValType::F32],
        |caller, args, out| {
            let gamepad_id = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let axis_index = args.get(1).and_then(|v| v.i32()).unwrap_or(-1);
            let value = if axis_index >= 0 {
                caller
                    .data()
                    .gamepads
                    .find(gamepad_id)
                    .and_then(|snapshot| snapshot.axis_values.get(axis_index as usize))
                    .copied()
                    .unwrap_or(f32::NAN)
            } else {
                f32::NAN
            };
            ok_f32(out, value);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_finish_frame",
        &[],
        &[ValType::I32],
        |mut caller, _args, out| {
            if let Some(win) = caller.data_mut().window.as_mut() {
                win.input_finish_frame();
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_has_cursor",
        &[],
        &[ValType::I32],
        |caller, _args, out| {
            let has = caller
                .data()
                .window
                .as_ref()
                .map(|win| win.input.has_cursor)
                .unwrap_or(false);
            ok_i32(out, if has { 1 } else { 0 });
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_touch_event_count",
        &[],
        &[ValType::I32],
        |caller, _args, out| {
            let count = caller
                .data()
                .window
                .as_ref()
                .map(|win| win.input.touch_events.len() as i32)
                .unwrap_or(0);
            ok_i32(out, count);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_touch_event_id",
        &[ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let index = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let id = if index >= 0 {
                caller
                    .data()
                    .window
                    .as_ref()
                    .and_then(|win| win.input.touch_events.get(index as usize))
                    .map(|touch| touch.id)
                    .unwrap_or(-1)
            } else {
                -1
            };
            ok_i32(out, id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_touch_event_phase",
        &[ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let index = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let phase = if index >= 0 {
                caller
                    .data()
                    .window
                    .as_ref()
                    .and_then(|win| win.input.touch_events.get(index as usize))
                    .map(|touch| touch.phase)
                    .unwrap_or(3)
            } else {
                3
            };
            ok_i32(out, phase);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_touch_event_x",
        &[ValType::I32],
        &[ValType::F32],
        |caller, args, out| {
            let index = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let x = if index >= 0 {
                caller
                    .data()
                    .window
                    .as_ref()
                    .and_then(|win| win.input.touch_events.get(index as usize))
                    .map(|touch| touch.x)
                    .unwrap_or(0.0)
            } else {
                0.0
            };
            ok_f32(out, x);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_touch_event_y",
        &[ValType::I32],
        &[ValType::F32],
        |caller, args, out| {
            let index = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let y = if index >= 0 {
                caller
                    .data()
                    .window
                    .as_ref()
                    .and_then(|win| win.input.touch_events.get(index as usize))
                    .map(|touch| touch.y)
                    .unwrap_or(0.0)
            } else {
                0.0
            };
            ok_f32(out, y);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_mouse_x",
        &[],
        &[ValType::F32],
        |caller, _args, out| {
            let x = caller
                .data()
                .window
                .as_ref()
                .map(|win| win.input.mouse_x)
                .unwrap_or(0.0);
            ok_f32(out, x);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_mouse_y",
        &[],
        &[ValType::F32],
        |caller, _args, out| {
            let y = caller
                .data()
                .window
                .as_ref()
                .map(|win| win.input.mouse_y)
                .unwrap_or(0.0);
            ok_f32(out, y);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_wheel_x",
        &[],
        &[ValType::F32],
        |caller, _args, out| {
            let x = caller
                .data()
                .window
                .as_ref()
                .map(|win| win.input.wheel_x)
                .unwrap_or(0.0);
            ok_f32(out, x);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_wheel_y",
        &[],
        &[ValType::F32],
        |caller, _args, out| {
            let y = caller
                .data()
                .window
                .as_ref()
                .map(|win| win.input.wheel_y)
                .unwrap_or(0.0);
            ok_f32(out, y);
            Ok(())
        },
    )?;

    for (name, which) in [
        ("input_is_key_down", 0),
        ("input_is_key_just_pressed", 1),
        ("input_is_key_just_released", 2),
        ("input_is_key_repeated", 3),
    ] {
        let name0 = name;
        define_func(
            store,
            linker,
            "mgstudio_host",
            name0,
            &[ValType::I32],
            &[ValType::I32],
            move |caller, args, out| {
                let ok = if let (Some(win), Some(code_id)) = (
                    caller.data().window.as_ref(),
                    args.get(0).and_then(|v| v.i32()),
                ) {
                    if let Some(code) = caller.data().string_table_get(code_id) {
                        if let Some(kc) = parse_keycode(code) {
                            match which {
                                0 => win.input.key_down.contains(&kc),
                                1 => win.input.key_just_pressed.contains(&kc),
                                2 => win.input.key_just_released.contains(&kc),
                                3 => win.input.key_repeated.contains(&kc),
                                _ => false,
                            }
                        } else {
                            false
                        }
                    } else {
                        false
                    }
                } else {
                    false
                };
                ok_i32(out, if ok { 1 } else { 0 });
                Ok(())
            },
        )?;
    }

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_text_event_count",
        &[],
        &[ValType::I32],
        |caller, _args, out| {
            let count = caller
                .data()
                .window
                .as_ref()
                .map(|win| win.input.text_events.len() as i32)
                .unwrap_or(0);
            ok_i32(out, count);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_text_event_len",
        &[ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let index = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let len = caller
                .data()
                .window
                .as_ref()
                .and_then(|win| {
                    if index < 0 {
                        None
                    } else {
                        win.input.text_events.get(index as usize)
                    }
                })
                .map(|text| text.encode_utf16().count() as i32)
                .unwrap_or(0);
            ok_i32(out, len);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "input_text_event_code_unit",
        &[ValType::I32, ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let index = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let offset = args.get(1).and_then(|v| v.i32()).unwrap_or(-1);
            let code_unit = caller
                .data()
                .window
                .as_ref()
                .and_then(|win| {
                    if index < 0 {
                        None
                    } else {
                        win.input.text_events.get(index as usize)
                    }
                })
                .and_then(|text| {
                    if offset < 0 {
                        None
                    } else {
                        text.encode_utf16().nth(offset as usize)
                    }
                })
                .map(i32::from)
                .unwrap_or(0);
            ok_i32(out, code_unit);
            Ok(())
        },
    )?;

    for (name, which) in [
        ("input_is_mouse_button_down", 0),
        ("input_is_mouse_button_just_pressed", 1),
        ("input_is_mouse_button_just_released", 2),
    ] {
        let name0 = name;
        define_func(
            store,
            linker,
            "mgstudio_host",
            name0,
            &[ValType::I32],
            &[ValType::I32],
            move |caller, args, out| {
                let ok = if let (Some(win), Some(btn_id)) = (
                    caller.data().window.as_ref(),
                    args.get(0).and_then(|v| v.i32()),
                ) {
                    if let Some(btn) = caller.data().string_table_get(btn_id) {
                        if let Some(b) = parse_mouse_button(btn) {
                            match which {
                                0 => win.input.mouse_down.contains(&b),
                                1 => win.input.mouse_just_pressed.contains(&b),
                                2 => win.input.mouse_just_released.contains(&b),
                                _ => false,
                            }
                        } else {
                            false
                        }
                    } else {
                        false
                    }
                } else {
                    false
                };
                ok_i32(out, if ok { 1 } else { 0 });
                Ok(())
            },
        )?;
    }

    // Asset: load textures from the assets dir and allocate wgpu textures.
    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_load_texture",
        &[ValType::I32, ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let path_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let nearest = args.get(1).and_then(|v| v.i32()).unwrap_or(0) != 0;
            let rel = caller
                .data()
                .string_table_get(path_id)
                .unwrap_or("")
                .to_string();
            if caller.data().trace_host {
                let full = join_dir_best_effort(&caller.data().assets.base, &rel);
                eprintln!("asset_load_texture: {rel} -> {full}");
            }
            let id = load_texture_from_assets(caller.data_mut(), &rel, nearest)?;
            ok_i32(out, id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_load_texture_bytes",
        &[ValType::I32, ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let blob_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let nearest = args.get(1).and_then(|v| v.i32()).unwrap_or(0) != 0;
            let bytes = caller
                .data()
                .bytes_table_get(blob_id)
                .map(|b| b.to_vec())
                .unwrap_or_default();
            let id = load_texture_from_bytes(caller.data_mut(), &bytes, nearest)?;
            ok_i32(out, id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_load_wgsl",
        &[ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let path_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let rel = caller
                .data()
                .string_table_get(path_id)
                .unwrap_or("")
                .to_string();
            if rel.trim().is_empty() {
                ok_i32(out, -1);
                return Ok(());
            }
            let source = load_wgsl_from_assets_required(&caller.data().assets.base, &rel)
                .unwrap_or_default();
            let shader_id = caller.data_mut().shader_table_put(source);
            ok_i32(out, shader_id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_load_font",
        &[ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let path_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let rel = caller
                .data()
                .string_table_get(path_id)
                .unwrap_or("")
                .to_string();
            if rel.trim().is_empty() {
                ok_i32(out, -1);
                return Ok(());
            }
            let full_path =
                join_dir_best_effort(&caller.data().assets.base, strip_leading_slashes(&rel));
            let bytes = std::fs::read(&full_path).unwrap_or_default();
            let font_id = caller.data_mut().font_table_put(bytes);
            ok_i32(out, font_id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_load_bytes",
        &[ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let path_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let rel = caller
                .data()
                .string_table_get(path_id)
                .unwrap_or("")
                .to_string();
            if rel.trim().is_empty() {
                ok_i32(out, -1);
                return Ok(());
            }
            let full_path =
                join_dir_best_effort(&caller.data().assets.base, strip_leading_slashes(&rel));
            let bytes = std::fs::read(&full_path).unwrap_or_default();
            let blob_id = caller.data_mut().bytes_table_put(bytes);
            ok_i32(out, blob_id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_bytes_len",
        &[ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let blob_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let len = caller
                .data()
                .bytes_table_get(blob_id)
                .map(|b| b.len() as i32)
                .unwrap_or(0);
            ok_i32(out, len);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_bytes_get_u32",
        &[ValType::I32, ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let blob_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let index = args.get(1).and_then(|v| v.i32()).unwrap_or(-1);
            if index < 0 {
                ok_i32(out, 0);
                return Ok(());
            }
            let mut packed: u32 = 0;
            if let Some(bytes) = caller.data().bytes_table_get(blob_id) {
                for j in 0..4 {
                    let value = bytes.get(index as usize + j).copied().unwrap_or(0) as u32;
                    packed |= value << (j * 8);
                }
            }
            ok_i32(out, packed as i32);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_font_bytes_len",
        &[ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let font_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let len = caller
                .data()
                .font_table_get(font_id)
                .map(|b| b.len() as i32)
                .unwrap_or(0);
            ok_i32(out, len);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_font_bytes_get",
        &[ValType::I32, ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let font_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let index = args.get(1).and_then(|v| v.i32()).unwrap_or(-1);
            let value = caller
                .data()
                .font_table_get(font_id)
                .and_then(|b| b.get(index.max(0) as usize).copied())
                .map(|v| v as i32)
                .unwrap_or(0);
            ok_i32(out, value);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_font_bytes_get_u32",
        &[ValType::I32, ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let font_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let index = args.get(1).and_then(|v| v.i32()).unwrap_or(-1).max(0) as usize;
            let mut word: u32 = 0;
            if let Some(bytes) = caller.data().font_table_get(font_id) {
                for j in 0..4usize {
                    if let Some(v) = bytes.get(index + j) {
                        word |= (*v as u32) << (j * 8);
                    }
                }
            }
            ok_i32(out, word as i32);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "font_rasterize_glyph",
        &[ValType::I32, ValType::F32, ValType::I32, ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let font_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let font_size = match args.get(1) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let glyph_code = args.get(2).and_then(|v| v.i32()).unwrap_or(0);
            let _smoothing = args.get(3).and_then(|v| v.i32()).unwrap_or(1);
            if caller.data().font_table_get(font_id).is_none() || font_size <= 0.0 {
                ok_i32(out, -1);
                return Ok(());
            }
            let width = ((font_size * 0.6).round() as i32).max(1) as u32;
            let height = (font_size.round() as i32).max(1) as u32;
            let alpha = if glyph_code <= 0 { 0u8 } else { 255u8 };
            let mut rgba8 = vec![0u8; (width * height * 4) as usize];
            for idx in 0..(width * height) as usize {
                let base = idx * 4;
                rgba8[base] = 255;
                rgba8[base + 1] = 255;
                rgba8[base + 2] = 255;
                rgba8[base + 3] = alpha;
            }
            let glyph_id = caller.data_mut().glyph_table_put(GlyphBitmap {
                width,
                height,
                offset_x: 0,
                offset_y: 0,
                rgba8,
            });
            ok_i32(out, glyph_id);
            Ok(())
        },
    )?;

    for (name, selector) in [
        ("font_glyph_width", 0),
        ("font_glyph_height", 1),
        ("font_glyph_offset_x", 2),
        ("font_glyph_offset_y", 3),
    ] {
        define_func(
            store,
            linker,
            "mgstudio_host",
            name,
            &[ValType::I32],
            &[ValType::I32],
            move |caller, args, out| {
                let glyph_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
                let value = caller
                    .data()
                    .glyph_table_get(glyph_id)
                    .map(|g| match selector {
                        0 => g.width as i32,
                        1 => g.height as i32,
                        2 => g.offset_x,
                        3 => g.offset_y,
                        _ => 0,
                    })
                    .unwrap_or(0);
                ok_i32(out, value);
                Ok(())
            },
        )?;
    }

    define_func(
        store,
        linker,
        "mgstudio_host",
        "font_measure_advance",
        &[ValType::I32, ValType::F32, ValType::I32],
        &[ValType::F32],
        |caller, args, out| {
            let font_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let font_size = match args.get(1) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let codepoint = args.get(2).and_then(|v| v.i32()).unwrap_or(0);
            let base = if caller.data().font_table_get(font_id).is_some() && codepoint > 0 {
                (font_size * 0.6).max(0.0)
            } else {
                0.0
            };
            ok_f32(out, base);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_create_dynamic_texture",
        &[ValType::I32, ValType::I32, ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let w = args.get(0).and_then(|v| v.i32()).unwrap_or(1).max(1) as u32;
            let h = args.get(1).and_then(|v| v.i32()).unwrap_or(1).max(1) as u32;
            let nearest = args.get(2).and_then(|v| v.i32()).unwrap_or(0) != 0;
            let gpu = caller.data_mut().ensure_gpu()?;
            let pixels = vec![0u8; (w * h * 4) as usize];
            let id = gpu.create_texture_rgba8(w, h, &pixels, nearest)?;
            ok_i32(out, id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_create_dynamic_texture_mipped",
        &[ValType::I32, ValType::I32, ValType::I32, ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let w = args.get(0).and_then(|v| v.i32()).unwrap_or(1).max(1) as u32;
            let h = args.get(1).and_then(|v| v.i32()).unwrap_or(1).max(1) as u32;
            let mip_level_count = args.get(2).and_then(|v| v.i32()).unwrap_or(1).max(1) as u32;
            let nearest = args.get(3).and_then(|v| v.i32()).unwrap_or(0) != 0;
            let gpu = caller.data_mut().ensure_gpu()?;
            let pixels = vec![0u8; (w * h * 4) as usize];
            let id = gpu.create_texture_rgba8_mipped(w, h, mip_level_count, &pixels, nearest)?;
            ok_i32(out, id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_update_texture_region",
        &[
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
        ],
        &[ValType::I32],
        |mut caller, args, out| {
            let texture_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let x = args.get(1).and_then(|v| v.i32()).unwrap_or(0).max(0) as u32;
            let y = args.get(2).and_then(|v| v.i32()).unwrap_or(0).max(0) as u32;
            let w = args.get(3).and_then(|v| v.i32()).unwrap_or(0).max(0) as u32;
            let h = args.get(4).and_then(|v| v.i32()).unwrap_or(0).max(0) as u32;
            let glyph_id = args.get(5).and_then(|v| v.i32()).unwrap_or(0);
            if w == 0 || h == 0 {
                ok_i32(out, 0);
                return Ok(());
            }
            let Some(glyph) = caller.data().glyph_table_get(glyph_id) else {
                ok_i32(out, 0);
                return Ok(());
            };
            let glyph_width = glyph.width;
            let glyph_height = glyph.height;
            let glyph_pixels = glyph.rgba8.clone();
            let write_width = w.min(glyph_width);
            let write_height = h.min(glyph_height);
            if write_width == 0 || write_height == 0 {
                ok_i32(out, 0);
                return Ok(());
            }
            let mut pixels = vec![0u8; (write_width * write_height * 4) as usize];
            for row in 0..write_height as usize {
                let src_start = row * glyph_width as usize * 4;
                let src_end = src_start + write_width as usize * 4;
                let dst_start = row * write_width as usize * 4;
                pixels[dst_start..(dst_start + write_width as usize * 4)]
                    .copy_from_slice(&glyph_pixels[src_start..src_end]);
            }
            let gpu = caller.data_mut().ensure_gpu()?;
            gpu.write_texture_region_rgba8(texture_id, x, y, write_width, write_height, &pixels)?;
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_update_texture_region_bytes",
        &[
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
        ],
        &[ValType::I32],
        |mut caller, args, out| {
            let texture_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let x = args.get(1).and_then(|v| v.i32()).unwrap_or(0).max(0) as u32;
            let y = args.get(2).and_then(|v| v.i32()).unwrap_or(0).max(0) as u32;
            let w = args.get(3).and_then(|v| v.i32()).unwrap_or(0).max(0) as u32;
            let h = args.get(4).and_then(|v| v.i32()).unwrap_or(0).max(0) as u32;
            let bytes_id = args.get(5).and_then(|v| v.i32()).unwrap_or(0);
            if w == 0 || h == 0 {
                ok_i32(out, 0);
                return Ok(());
            }
            let Some(pixels) = caller.data().bytes_table_get(bytes_id) else {
                ok_i32(out, 0);
                return Ok(());
            };
            let pixels = pixels.to_vec();
            let gpu = caller.data_mut().ensure_gpu()?;
            gpu.write_texture_region_rgba8(texture_id, x, y, w, h, &pixels)?;
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_update_texture_region_mip_bytes",
        &[
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
        ],
        &[ValType::I32],
        |mut caller, args, out| {
            let texture_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let x = args.get(1).and_then(|v| v.i32()).unwrap_or(0).max(0) as u32;
            let y = args.get(2).and_then(|v| v.i32()).unwrap_or(0).max(0) as u32;
            let w = args.get(3).and_then(|v| v.i32()).unwrap_or(0).max(0) as u32;
            let h = args.get(4).and_then(|v| v.i32()).unwrap_or(0).max(0) as u32;
            let mip_level = args.get(5).and_then(|v| v.i32()).unwrap_or(0).max(0) as u32;
            let bytes_id = args.get(6).and_then(|v| v.i32()).unwrap_or(0);
            if w == 0 || h == 0 {
                ok_i32(out, 0);
                return Ok(());
            }
            let Some(pixels) = caller.data().bytes_table_get(bytes_id) else {
                ok_i32(out, 0);
                return Ok(());
            };
            let pixels = pixels.to_vec();
            let gpu = caller.data_mut().ensure_gpu()?;
            gpu.write_texture_region_rgba8_mip(texture_id, x, y, w, h, mip_level, &pixels)?;
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_create_texture_mip_view",
        &[ValType::I32, ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let texture_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let mip_level = args.get(1).and_then(|v| v.i32()).unwrap_or(0).max(0) as u32;
            let gpu = caller.data_mut().ensure_gpu()?;
            let id = gpu.create_texture_mip_view(texture_id, mip_level)?;
            ok_i32(out, id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_texture_width",
        &[ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let w = caller
                .data()
                .gpu
                .as_ref()
                .map(|g| g.texture_width(id) as i32)
                .unwrap_or(0);
            ok_i32(out, w);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_texture_height",
        &[ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let h = caller
                .data()
                .gpu
                .as_ref()
                .map(|g| g.texture_height(id) as i32)
                .unwrap_or(0);
            ok_i32(out, h);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_is_texture_loaded",
        &[ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let ok = caller
                .data()
                .gpu
                .as_ref()
                .map(|g| g.is_texture_loaded(id))
                .unwrap_or(false);
            ok_i32(out, if ok { 1 } else { 0 });
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_copy_texture_to_texture",
        &[ValType::I32, ValType::I32, ValType::I32, ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let dst_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let dst_x = args.get(1).and_then(|v| v.i32()).unwrap_or(0).max(0) as u32;
            let dst_y = args.get(2).and_then(|v| v.i32()).unwrap_or(0).max(0) as u32;
            let src_id = args.get(3).and_then(|v| v.i32()).unwrap_or(0);
            if let Some(gpu) = caller.data_mut().gpu.as_mut() {
                gpu.copy_texture_to_texture(dst_id, dst_x, dst_y, src_id)?;
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_set_texture_sampler",
        &[ValType::I32, ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let texture_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let kind = args.get(1).and_then(|v| v.i32()).unwrap_or(0);
            if let Some(gpu) = caller.data_mut().gpu.as_mut() {
                gpu.set_texture_sampler(texture_id, kind)?;
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_load_folder",
        &[ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let path_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let base_rel = caller
                .data()
                .string_table_get(path_id)
                .unwrap_or("")
                .to_string();
            if base_rel.trim().is_empty() {
                ok_i32(out, -1);
                return Ok(());
            }
            let folder_id = caller.data().next_folder_id;
            caller.data_mut().next_folder_id += 1;
            let manifest_rel = format!("{}/folder.txt", base_rel.trim_end_matches('/'));
            let manifest_full = join_dir_best_effort(
                &caller.data().assets.base,
                strip_leading_slashes(&manifest_rel),
            );
            let manifest = std::fs::read_to_string(&manifest_full).unwrap_or_default();
            let mut handles: Vec<i32> = Vec::new();
            for entry in split_trimmed_lines(&manifest) {
                let asset_rel = if base_rel.trim().is_empty() {
                    entry.to_string()
                } else {
                    format!(
                        "{}/{}",
                        base_rel.trim_end_matches('/'),
                        entry.trim_start_matches('/')
                    )
                };
                let texture_id = load_texture_from_assets(caller.data_mut(), &asset_rel, false)?;
                handles.push(texture_id);
            }
            caller.data_mut().folder_table_set(folder_id, handles);
            caller.data_mut().folder_events_push(3, folder_id);
            ok_i32(out, folder_id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_poll_loaded_folder_event_kind",
        &[],
        &[ValType::I32],
        |caller, _args, out| {
            ok_i32(out, caller.data().folder_events_poll_kind());
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_poll_loaded_folder_event_id",
        &[],
        &[ValType::I32],
        |mut caller, _args, out| {
            ok_i32(out, caller.data_mut().folder_events_poll_id());
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_loaded_folder_handles_len",
        &[ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let folder_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let len = caller
                .data()
                .folder_table_get(folder_id)
                .map(|v| v.len() as i32)
                .unwrap_or(0);
            ok_i32(out, len);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "asset_loaded_folder_handles_get",
        &[ValType::I32, ValType::I32],
        &[ValType::I32],
        |caller, args, out| {
            let folder_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let index = args.get(1).and_then(|v| v.i32()).unwrap_or(-1);
            let handle = caller
                .data()
                .folder_table_get(folder_id)
                .and_then(|v| v.get(index.max(0) as usize).copied())
                .unwrap_or(-1);
            ok_i32(out, handle);
            Ok(())
        },
    )?;

    // GPU: wgpu-backed implementations matching the mgstudio_host contract.
    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_request_device",
        &[],
        &[ValType::EXTERNREF],
        |mut caller, _args, out| {
            caller.data().host_trace("host: gpu_request_device");
            let _ = caller.data_mut().ensure_gpu()?;
            ok_externref_i32(&mut caller, out, 10_010)?;
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_get_queue",
        &[ValType::EXTERNREF],
        &[ValType::EXTERNREF],
        |mut caller, _args, out| {
            let _ = caller.data_mut().ensure_gpu()?;
            ok_externref_i32(&mut caller, out, 10_013)?;
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_create_surface",
        &[ValType::EXTERNREF],
        &[ValType::EXTERNREF],
        |mut caller, _args, out| {
            caller.data().host_trace("host: gpu_create_surface");
            let Some(win_arc) = caller.data().window.as_ref().map(|w| w.window_arc()) else {
                ok_externref_null(out);
                return Ok(());
            };
            let gpu = caller.data_mut().ensure_gpu()?;
            if !gpu.is_surface_ready() {
                let surface = gpu.create_surface_from_window(win_arc)?;
                gpu.set_surface(surface);
            }
            ok_externref_i32(&mut caller, out, 10_011)?;
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_configure_surface",
        &[
            ValType::EXTERNREF,
            ValType::EXTERNREF,
            ValType::I32,
            ValType::I32,
        ],
        &[ValType::I32],
        |mut caller, args, out| {
            caller.data().host_trace("host: gpu_configure_surface");
            let w = args.get(2).and_then(|v| v.i32()).unwrap_or(1).max(1) as u32;
            let h = args.get(3).and_then(|v| v.i32()).unwrap_or(1).max(1) as u32;
            let gpu = caller.data_mut().ensure_gpu()?;
            gpu.configure_surface(w, h)?;
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_begin_frame",
        &[ValType::EXTERNREF],
        &[ValType::EXTERNREF],
        |mut caller, _args, out| {
            let size = caller.data().window.as_ref().map(|w| w.inner_size());
            if let (Some(size), Some(gpu)) = (size, caller.data_mut().gpu.as_mut()) {
                gpu.ensure_surface_configured(size.width.max(1), size.height.max(1))?;
                gpu.begin_frame()?;
            }
            ok_externref_i32(&mut caller, out, 10_012)?;
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_end_frame",
        &[ValType::EXTERNREF],
        &[ValType::I32],
        |mut caller, _args, out| {
            if let Some(gpu) = caller.data_mut().gpu.as_mut() {
                gpu.end_frame()?;
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_begin_pass",
        &[
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::I32,
        ],
        &[ValType::I32],
        |mut caller, args, out| {
            let target_id = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let w_logical = args.get(1).and_then(|v| v.i32()).unwrap_or(1);
            let h_logical = args.get(2).and_then(|v| v.i32()).unwrap_or(1);
            let f = |i: usize| match args.get(i) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let clear = [f(3), f(4), f(5), f(6)];
            let camera_x = f(7);
            let camera_y = f(8);
            let camera_rot = f(9);
            let camera_scale = f(10);
            let vx = args.get(11).and_then(|v| v.i32()).unwrap_or(0);
            let vy = args.get(12).and_then(|v| v.i32()).unwrap_or(0);
            let vw = args.get(13).and_then(|v| v.i32()).unwrap_or(0);
            let vh = args.get(14).and_then(|v| v.i32()).unwrap_or(0);
            let viewport_depth_min = match args.get(15) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let viewport_depth_max = match args.get(16) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 1.0,
            };
            let clear_enabled = args.get(17).and_then(|v| v.i32()).unwrap_or(1) != 0;
            if let Some(gpu) = caller.data_mut().gpu.as_mut() {
                gpu.begin_pass(
                    target_id,
                    w_logical,
                    h_logical,
                    clear,
                    camera_x,
                    camera_y,
                    camera_rot,
                    camera_scale,
                    (vx, vy, vw, vh),
                    (viewport_depth_min, viewport_depth_max),
                    clear_enabled,
                )?;
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_begin_pass_3d",
        &[
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::I32,
            ValType::I32,
        ],
        &[ValType::I32],
        |mut caller, args, out| {
            let target_id = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let w_logical = args.get(1).and_then(|v| v.i32()).unwrap_or(1);
            let h_logical = args.get(2).and_then(|v| v.i32()).unwrap_or(1);
            let f = |i: usize| match args.get(i) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let clear = [f(3), f(4), f(5), f(6)];
            let camera_x = f(7);
            let camera_y = f(8);
            let camera_z = f(9);
            let camera_rot_x = f(10);
            let camera_rot_y = f(11);
            let camera_rot_z = f(12);
            let camera_rot_w = f(13);
            let camera_fov_y = f(14);
            let camera_near = f(15);
            let camera_far = f(16);
            let vx = args.get(17).and_then(|v| v.i32()).unwrap_or(0);
            let vy = args.get(18).and_then(|v| v.i32()).unwrap_or(0);
            let vw = args.get(19).and_then(|v| v.i32()).unwrap_or(0);
            let vh = args.get(20).and_then(|v| v.i32()).unwrap_or(0);
            let ambient_r = f(21);
            let ambient_g = f(22);
            let ambient_b = f(23);
            let ambient_brightness = f(24);
            let directional_dir_x = f(25);
            let directional_dir_y = f(26);
            let directional_dir_z = f(27);
            let directional_color_r = f(28);
            let directional_color_g = f(29);
            let directional_color_b = f(30);
            let directional_illuminance = f(31);
            let point_pos_x = f(32);
            let point_pos_y = f(33);
            let point_pos_z = f(34);
            let point_color_r = f(35);
            let point_color_g = f(36);
            let point_color_b = f(37);
            let point_intensity = f(38);
            let point_range = f(39);
            let spot_pos_x = f(40);
            let spot_pos_y = f(41);
            let spot_pos_z = f(42);
            let spot_dir_x = f(43);
            let spot_dir_y = f(44);
            let spot_dir_z = f(45);
            let spot_color_r = f(46);
            let spot_color_g = f(47);
            let spot_color_b = f(48);
            let spot_intensity = f(49);
            let spot_range = f(50);
            let spot_inner_angle = f(51);
            let spot_outer_angle = f(52);
            let sub_camera_view_scale_x = f(53);
            let sub_camera_view_scale_y = f(54);
            let sub_camera_view_bias_x = f(55);
            let sub_camera_view_bias_y = f(56);
            let previous_camera_x = match args.get(57) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => camera_x,
            };
            let previous_camera_y = match args.get(58) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => camera_y,
            };
            let previous_camera_z = match args.get(59) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => camera_z,
            };
            let previous_camera_rot_x = match args.get(60) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => camera_rot_x,
            };
            let previous_camera_rot_y = match args.get(61) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => camera_rot_y,
            };
            let previous_camera_rot_z = match args.get(62) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => camera_rot_z,
            };
            let previous_camera_rot_w = match args.get(63) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => camera_rot_w,
            };
            let pass_kind = args.get(64).and_then(|v| v.i32()).unwrap_or(0);
            let clear_enabled = args.get(65).and_then(|v| v.i32()).unwrap_or(1) != 0;
            if let Some(gpu) = caller.data_mut().gpu.as_mut() {
                gpu.begin_pass_3d(
                    target_id,
                    w_logical,
                    h_logical,
                    clear,
                    camera_x,
                    camera_y,
                    camera_z,
                    camera_rot_x,
                    camera_rot_y,
                    camera_rot_z,
                    camera_rot_w,
                    camera_fov_y,
                    camera_near,
                    camera_far,
                    (vx, vy, vw, vh),
                    [ambient_r, ambient_g, ambient_b, ambient_brightness],
                    [
                        directional_dir_x,
                        directional_dir_y,
                        directional_dir_z,
                        directional_illuminance,
                    ],
                    [
                        directional_color_r,
                        directional_color_g,
                        directional_color_b,
                    ],
                    [point_pos_x, point_pos_y, point_pos_z, point_range],
                    [point_color_r, point_color_g, point_color_b, point_intensity],
                    [spot_pos_x, spot_pos_y, spot_pos_z, spot_range],
                    [spot_dir_x, spot_dir_y, spot_dir_z, spot_inner_angle],
                    [spot_color_r, spot_color_g, spot_color_b, spot_intensity],
                    spot_outer_angle,
                    [
                        sub_camera_view_scale_x,
                        sub_camera_view_scale_y,
                        sub_camera_view_bias_x,
                        sub_camera_view_bias_y,
                    ],
                    previous_camera_x,
                    previous_camera_y,
                    previous_camera_z,
                    previous_camera_rot_x,
                    previous_camera_rot_y,
                    previous_camera_rot_z,
                    previous_camera_rot_w,
                    pass_kind,
                    clear_enabled,
                )?;
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_set_scissor",
        &[ValType::I32, ValType::I32, ValType::I32, ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let x = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let y = args.get(1).and_then(|v| v.i32()).unwrap_or(0);
            let width = args.get(2).and_then(|v| v.i32()).unwrap_or(0);
            let height = args.get(3).and_then(|v| v.i32()).unwrap_or(0);
            let gpu = caller.data_mut().ensure_gpu()?;
            gpu.set_scissor(x, y, width, height);
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_clear_scissor",
        &[],
        &[ValType::I32],
        |mut caller, _args, out| {
            let gpu = caller.data_mut().ensure_gpu()?;
            gpu.clear_scissor();
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_end_pass",
        &[],
        &[ValType::I32],
        |mut caller, _args, out| {
            if let Some(gpu) = caller.data_mut().gpu.as_mut() {
                gpu.end_pass()?;
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_draw_sprite",
        &[
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
        ],
        &[ValType::I32],
        |mut caller, args, out| {
            let texture_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let f = |i: usize| match args.get(i) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let x = f(1);
            let y = f(2);
            let rotation = f(3);
            let scale_x = f(4);
            let scale_y = f(5);
            let color = [f(6), f(7), f(8), f(9)];
            if let Some(gpu) = caller.data_mut().gpu.as_mut() {
                gpu.draw_sprite_uv(
                    texture_id,
                    x,
                    y,
                    rotation,
                    scale_x,
                    scale_y,
                    color,
                    (0.0, 0.0),
                    (1.0, 1.0),
                )?;
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_draw_sprite_uv",
        &[
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
        ],
        &[ValType::I32],
        |mut caller, args, out| {
            let texture_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let f = |i: usize| match args.get(i) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let x = f(1);
            let y = f(2);
            let rotation = f(3);
            let scale_x = f(4);
            let scale_y = f(5);
            let color = [f(6), f(7), f(8), f(9)];
            let uv_min = (f(10), f(11));
            let uv_max = (f(12), f(13));
            if let Some(gpu) = caller.data_mut().gpu.as_mut() {
                gpu.draw_sprite_uv(
                    texture_id, x, y, rotation, scale_x, scale_y, color, uv_min, uv_max,
                )?;
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_draw_ui_rect",
        &[
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
        ],
        &[ValType::I32],
        |mut caller, args, out| {
            let texture_id = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let f = |i: usize| match args.get(i) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let x = f(1);
            let y = f(2);
            let rotation = f(3);
            let scale_x = f(4);
            let scale_y = f(5);
            let color = [f(6), f(7), f(8), f(9)];
            let uv_min = (f(10), f(11));
            let raw_uv_scale_x = f(12) - f(10);
            let raw_uv_scale_y = f(13) - f(11);
            let uv_scale = (
                if raw_uv_scale_x <= 0.0 {
                    1.0
                } else {
                    raw_uv_scale_x
                },
                if raw_uv_scale_y <= 0.0 {
                    1.0
                } else {
                    raw_uv_scale_y
                },
            );
            let mesh_id = caller.data_mut().ensure_unit_rect_mesh()?;
            if let Some(gpu) = caller.data_mut().gpu.as_mut() {
                gpu.draw_mesh(
                    mesh_id, x, y, rotation, scale_x, scale_y, color, texture_id, uv_min, uv_scale,
                )?;
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_draw_ui_texture_slice",
        &[
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
        ],
        &[ValType::I32],
        |mut caller, args, out| {
            let texture_id = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let f = |i: usize| match args.get(i) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let x = f(1);
            let y = f(2);
            let rotation = f(3);
            let scale_x = f(4);
            let scale_y = f(5);
            let color = [f(6), f(7), f(8), f(9)];
            let mut uv_min = (f(22), f(23));
            let mut uv_scale = (f(24) - f(22), f(25) - f(23));
            if uv_scale.0 <= 0.0 {
                uv_min.0 = 0.0;
                uv_scale.0 = 1.0;
            }
            if uv_scale.1 <= 0.0 {
                uv_min.1 = 0.0;
                uv_scale.1 = 1.0;
            }
            let mesh_id = caller.data_mut().ensure_unit_rect_mesh()?;
            if let Some(gpu) = caller.data_mut().gpu.as_mut() {
                gpu.draw_mesh(
                    mesh_id, x, y, rotation, scale_x, scale_y, color, texture_id, uv_min, uv_scale,
                )?;
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_draw_ui_box_shadow",
        &[
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::I32,
        ],
        &[ValType::I32],
        |mut caller, args, out| {
            let texture_id = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let f = |i: usize| match args.get(i) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let x = f(1);
            let y = f(2);
            let rotation = f(3);
            let scale_x = f(4);
            let scale_y = f(5);
            let color = [f(6), f(7), f(8), f(9)];
            let mesh_id = caller.data_mut().ensure_unit_rect_mesh()?;
            if let Some(gpu) = caller.data_mut().gpu.as_mut() {
                gpu.draw_mesh(
                    mesh_id,
                    x,
                    y,
                    rotation,
                    scale_x,
                    scale_y,
                    color,
                    texture_id,
                    (0.0, 0.0),
                    (1.0, 1.0),
                )?;
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_draw_gizmo_line",
        &[
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::I32,
            ValType::F32,
            ValType::F32,
        ],
        &[ValType::I32],
        |mut caller, args, out| {
            let f = |i: usize| match args.get(i) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let start_x = f(0);
            let start_y = f(1);
            let end_x = f(6);
            let end_y = f(7);
            let line_width = f(12).max(1.0);
            let line_scale = f(15).max(0.01);
            let dx = end_x - start_x;
            let dy = end_y - start_y;
            let length = (dx * dx + dy * dy).sqrt() * line_scale;
            if length <= 0.0 {
                ok_i32(out, 0);
                return Ok(());
            }
            let center_x = (start_x + end_x) * 0.5;
            let center_y = (start_y + end_y) * 0.5;
            let rotation = dy.atan2(dx);
            let color = [
                (f(2) + f(8)) * 0.5,
                (f(3) + f(9)) * 0.5,
                (f(4) + f(10)) * 0.5,
                (f(5) + f(11)) * 0.5,
            ];
            let mesh_id = caller.data_mut().ensure_unit_rect_mesh()?;
            if let Some(gpu) = caller.data_mut().gpu.as_mut() {
                gpu.draw_mesh(
                    mesh_id,
                    center_x,
                    center_y,
                    rotation,
                    length,
                    line_width,
                    color,
                    -1,
                    (0.0, 0.0),
                    (1.0, 1.0),
                )?;
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_draw_mesh",
        &[
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
        ],
        &[ValType::I32],
        |mut caller, args, out| {
            let mesh_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let f = |i: usize| match args.get(i) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let x = f(1);
            let y = f(2);
            let rotation = f(3);
            let scale_x = f(4);
            let scale_y = f(5);
            let color = [f(6), f(7), f(8), f(9)];
            let texture_id = args.get(10).and_then(|v| v.i32()).unwrap_or(-1);
            let uv_offset = (f(11), f(12));
            let uv_scale = (f(13), f(14));
            if let Some(gpu) = caller.data_mut().gpu.as_mut() {
                gpu.draw_mesh(
                    mesh_id, x, y, rotation, scale_x, scale_y, color, texture_id, uv_offset,
                    uv_scale,
                )?;
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_draw_mesh3d",
        &[
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::I32,
            ValType::F32,
            ValType::F32,
        ],
        &[ValType::I32],
        |mut caller, args, out| {
            let mesh_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let f = |i: usize| match args.get(i) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let x = f(1);
            let y = f(2);
            let z = f(3);
            let rotation_x = f(4);
            let rotation_y = f(5);
            let rotation_z = f(6);
            let rotation_w = f(7);
            let scale_x = f(8);
            let scale_y = f(9);
            let scale_z = f(10);
            let previous_x = f(11);
            let previous_y = f(12);
            let previous_z = f(13);
            let previous_rotation_x = f(14);
            let previous_rotation_y = f(15);
            let previous_rotation_z = f(16);
            let previous_rotation_w = f(17);
            let previous_scale_x = f(18);
            let previous_scale_y = f(19);
            let previous_scale_z = f(20);
            let color = [f(21), f(22), f(23), f(24)];
            let texture_id = args.get(25).and_then(|v| v.i32()).unwrap_or(-1);
            let uv_offset = (f(26), f(27));
            let uv_scale = (f(28), f(29));
            let normal_texture_id = args.get(30).and_then(|v| v.i32()).unwrap_or(-1);
            let emissive_texture_id = args.get(31).and_then(|v| v.i32()).unwrap_or(-1);
            let metallic_roughness_texture_id = args.get(32).and_then(|v| v.i32()).unwrap_or(-1);
            let occlusion_texture_id = args.get(33).and_then(|v| v.i32()).unwrap_or(-1);
            let depth_texture_id = args.get(34).and_then(|v| v.i32()).unwrap_or(-1);
            let emissive = [f(35), f(36), f(37)];
            let unlit = f(38);
            let metallic = f(39);
            let roughness = f(40);
            let reflectance = f(41);
            let parallax_depth_scale = f(42);
            let max_parallax_layer_count = f(43);
            let max_relief_mapping_search_steps = f(44);
            let anisotropy_texture_id = args.get(45).and_then(|v| v.i32()).unwrap_or(-1);
            let anisotropy_strength = f(46);
            let anisotropy_rotation = f(47);
            let specular_tint_texture_id = args.get(48).and_then(|v| v.i32()).unwrap_or(-1);
            let specular_tint_r = if args.len() > 49 { f(49) } else { 1.0 };
            let specular_tint_g = if args.len() > 50 { f(50) } else { 1.0 };
            let specular_tint_b = if args.len() > 51 { f(51) } else { 1.0 };
            let diffuse_transmission = if args.len() > 52 { f(52) } else { 0.0 };
            let specular_transmission = if args.len() > 53 { f(53) } else { 0.0 };
            let thickness = if args.len() > 54 { f(54) } else { 0.0 };
            let ior = if args.len() > 55 { f(55) } else { 1.5 };
            let transmission_source_texture_id = args.get(56).and_then(|v| v.i32()).unwrap_or(-1);
            let transmission_blur_taps = if args.len() > 57 { f(57) } else { 0.0 };
            let transmission_steps = if args.len() > 58 { f(58) } else { 0.0 };
            if let Some(gpu) = caller.data_mut().gpu.as_mut() {
                gpu.draw_mesh3d(
                    mesh_id,
                    x,
                    y,
                    z,
                    rotation_x,
                    rotation_y,
                    rotation_z,
                    rotation_w,
                    scale_x,
                    scale_y,
                    scale_z,
                    previous_x,
                    previous_y,
                    previous_z,
                    previous_rotation_x,
                    previous_rotation_y,
                    previous_rotation_z,
                    previous_rotation_w,
                    previous_scale_x,
                    previous_scale_y,
                    previous_scale_z,
                    color,
                    texture_id,
                    uv_offset,
                    uv_scale,
                    normal_texture_id,
                    emissive_texture_id,
                    metallic_roughness_texture_id,
                    occlusion_texture_id,
                    depth_texture_id,
                    emissive,
                    unlit,
                    metallic,
                    roughness,
                    reflectance,
                    parallax_depth_scale,
                    max_parallax_layer_count,
                    max_relief_mapping_search_steps,
                    anisotropy_texture_id,
                    anisotropy_strength,
                    anisotropy_rotation,
                    specular_tint_texture_id,
                    [specular_tint_r, specular_tint_g, specular_tint_b],
                    diffuse_transmission,
                    specular_transmission,
                    thickness,
                    ior,
                    transmission_source_texture_id,
                    transmission_blur_taps,
                    transmission_steps,
                )?;
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_draw_motion_blur",
        &[ValType::I32, ValType::I32, ValType::F32, ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let scene_texture_id = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let velocity_texture_id = args.get(1).and_then(|v| v.i32()).unwrap_or(-1);
            let shutter_angle = match args.get(2) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let samples = args.get(3).and_then(|v| v.i32()).unwrap_or(0);
            if let Some(gpu) = caller.data_mut().gpu.as_mut() {
                gpu.draw_motion_blur(
                    scene_texture_id,
                    velocity_texture_id,
                    shutter_angle,
                    samples,
                )?;
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_draw_bloom2d",
        &[
            ValType::I32,
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::F32,
            ValType::I32,
            ValType::I32,
            ValType::F32,
            ValType::F32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
            ValType::I32,
        ],
        &[ValType::I32],
        |mut caller, args, out| {
            let scene_texture_id = args.get(0).and_then(|v| v.i32()).unwrap_or(-1);
            let enabled = args.get(1).and_then(|v| v.i32()).unwrap_or(1);
            let intensity = match args.get(2) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.15,
            };
            let low_frequency_boost = match args.get(3) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.7,
            };
            let low_frequency_boost_curvature = match args.get(4) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.95,
            };
            let high_pass_frequency = match args.get(5) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 1.0,
            };
            let threshold = match args.get(6) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let threshold_softness = match args.get(7) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let composite_mode = args.get(8).and_then(|v| v.i32()).unwrap_or(0);
            let max_mip_dimension = args.get(9).and_then(|v| v.i32()).unwrap_or(512);
            let scale_x = match args.get(10) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 1.0,
            };
            let scale_y = match args.get(11) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 1.0,
            };
            let tonemapping_mode = args.get(12).and_then(|v| v.i32()).unwrap_or(0);
            let deband_dither_enabled = args.get(13).and_then(|v| v.i32()).unwrap_or(0);
            let view_width = args.get(14).and_then(|v| v.i32()).unwrap_or(1);
            let view_height = args.get(15).and_then(|v| v.i32()).unwrap_or(1);
            let agx_lut_texture_id = args.get(16).and_then(|v| v.i32()).unwrap_or(-1);
            let tony_lut_texture_id = args.get(17).and_then(|v| v.i32()).unwrap_or(-1);
            let blender_lut_texture_id = args.get(18).and_then(|v| v.i32()).unwrap_or(-1);
            if let Some(gpu) = caller.data_mut().gpu.as_mut() {
                gpu.draw_bloom2d(
                    scene_texture_id,
                    enabled,
                    intensity,
                    low_frequency_boost,
                    low_frequency_boost_curvature,
                    high_pass_frequency,
                    threshold,
                    threshold_softness,
                    composite_mode,
                    max_mip_dimension,
                    scale_x,
                    scale_y,
                    tonemapping_mode,
                    deband_dither_enabled,
                    view_width,
                    view_height,
                    agx_lut_texture_id,
                    tony_lut_texture_id,
                    blender_lut_texture_id,
                )?;
            }
            ok_i32(out, 0);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_create_render_target",
        &[ValType::I32, ValType::I32, ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let w = args.get(0).and_then(|v| v.i32()).unwrap_or(1).max(1) as u32;
            let h = args.get(1).and_then(|v| v.i32()).unwrap_or(1).max(1) as u32;
            let nearest = args.get(2).and_then(|v| v.i32()).unwrap_or(0) != 0;
            let gpu = caller.data_mut().ensure_gpu()?;
            let id = gpu.create_render_target(w, h, nearest)?;
            ok_i32(out, id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_create_render_target_rgba16f",
        &[ValType::I32, ValType::I32, ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let w = args.get(0).and_then(|v| v.i32()).unwrap_or(1).max(1) as u32;
            let h = args.get(1).and_then(|v| v.i32()).unwrap_or(1).max(1) as u32;
            let nearest = args.get(2).and_then(|v| v.i32()).unwrap_or(0) != 0;
            let gpu = caller.data_mut().ensure_gpu()?;
            let id = gpu.create_render_target_rgba16f(w, h, nearest)?;
            ok_i32(out, id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_create_mesh_capsule",
        &[ValType::F32, ValType::F32, ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let radius = match args.get(0) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let half_length = match args.get(1) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let segments = args.get(2).and_then(|v| v.i32()).unwrap_or(8);
            let gpu = caller.data_mut().ensure_gpu()?;
            let id = gpu.create_mesh_capsule(radius, half_length, segments);
            ok_i32(out, id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_create_mesh_rectangle",
        &[ValType::F32, ValType::F32],
        &[ValType::I32],
        |mut caller, args, out| {
            let w = match args.get(0) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let h = match args.get(1) {
                Some(Val::F32(bits)) => f32::from_bits(*bits),
                _ => 0.0,
            };
            let gpu = caller.data_mut().ensure_gpu()?;
            let id = gpu.create_mesh_rectangle(w, h);
            ok_i32(out, id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_create_mesh_triangles",
        &[ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let text_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let csv = caller.data().string_table_get(text_id).unwrap_or("");
            let mut floats: Vec<f32> = Vec::new();
            for line in csv.lines() {
                let t = line.trim();
                if t.is_empty() || t.starts_with('#') {
                    continue;
                }
                for part in t.split(|c: char| c == ',' || c.is_whitespace()) {
                    let p = part.trim();
                    if p.is_empty() {
                        continue;
                    }
                    if let Ok(v) = p.parse::<f32>() {
                        floats.push(v);
                    }
                }
            }
            let gpu = caller.data_mut().ensure_gpu()?;
            let id = gpu.create_mesh_triangles_xyuvrgba(&floats);
            ok_i32(out, id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_create_mesh3d",
        &[ValType::I32, ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let text_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let primitive_topology_kind = args.get(1).and_then(|v| v.i32()).unwrap_or(0);
            let csv = caller.data().string_table_get(text_id).unwrap_or("");
            let mut floats: Vec<f32> = Vec::new();
            for line in csv.lines() {
                let t = line.trim();
                if t.is_empty() || t.starts_with('#') {
                    continue;
                }
                for part in t.split(|c: char| c == ',' || c.is_whitespace()) {
                    let p = part.trim();
                    if p.is_empty() {
                        continue;
                    }
                    if let Ok(v) = p.parse::<f32>() {
                        floats.push(v);
                    }
                }
            }
            let gpu = caller.data_mut().ensure_gpu()?;
            let id = gpu.create_mesh3d_xyzuvrgba(&floats, primitive_topology_kind);
            ok_i32(out, id);
            Ok(())
        },
    )?;

    define_func(
        store,
        linker,
        "mgstudio_host",
        "gpu_create_mesh_triangles3d",
        &[ValType::I32],
        &[ValType::I32],
        |mut caller, args, out| {
            let text_id = args.get(0).and_then(|v| v.i32()).unwrap_or(0);
            let csv = caller.data().string_table_get(text_id).unwrap_or("");
            let mut floats: Vec<f32> = Vec::new();
            for line in csv.lines() {
                let t = line.trim();
                if t.is_empty() || t.starts_with('#') {
                    continue;
                }
                for part in t.split(|c: char| c == ',' || c.is_whitespace()) {
                    let p = part.trim();
                    if p.is_empty() {
                        continue;
                    }
                    if let Ok(v) = p.parse::<f32>() {
                        floats.push(v);
                    }
                }
            }
            let gpu = caller.data_mut().ensure_gpu()?;
            let id = gpu.create_mesh3d_xyzuvrgba(&floats, 0);
            ok_i32(out, id);
            Ok(())
        },
    )?;

    Ok(())
}

fn define_moonbit_ffi_imports(
    store: &mut Store<HostState>,
    linker: &mut Linker<HostState>,
) -> anyhow::Result<()> {
    // moonbit:ffi.make_closure(funcref, anyref) -> externref
    define_func(
        store,
        linker,
        "moonbit:ffi",
        "make_closure",
        &[ValType::FUNCREF, ValType::ANYREF],
        &[ValType::EXTERNREF],
        |mut caller, args, out| {
            let func = match args.get(0) {
                Some(Val::FuncRef(f)) => f.clone(),
                _ => None,
            };

            let env_owned = match args.get(1) {
                Some(Val::AnyRef(Some(env))) => Some(env.to_owned_rooted(&mut caller)?),
                _ => None,
            };

            let id = caller.data().next_closure_id;
            caller.data_mut().next_closure_id += 1;
            caller.data_mut().closures.insert(
                id,
                ClosureEntry {
                    func,
                    env: env_owned,
                },
            );

            ok_externref_i32(&mut caller, out, id)?;
            Ok(())
        },
    )?;

    Ok(())
}

fn define_spectest_imports(
    store: &mut Store<HostState>,
    linker: &mut Linker<HostState>,
) -> anyhow::Result<()> {
    // Some MoonBit-generated wasm modules import `spectest.print_char` for low-level debug output.
    define_func(
        store,
        linker,
        "spectest",
        "print_char",
        &[ValType::I32],
        &[],
        |_caller, args, _out| {
            if let Some(ch) = args.get(0).and_then(|v| v.i32()) {
                let b = (ch as u32 & 0xFF) as u8;
                eprint!("{}", b as char);
            }
            Ok(())
        },
    )?;
    Ok(())
}

fn define_func(
    store: &mut Store<HostState>,
    linker: &mut Linker<HostState>,
    module: &str,
    name: &str,
    params: &[ValType],
    results: &[ValType],
    f: impl for<'a> Fn(Caller<'a, HostState>, &[Val], &mut [Val]) -> anyhow::Result<()>
        + Send
        + Sync
        + 'static,
) -> anyhow::Result<()> {
    let module_name = module.to_string();
    let func_name = name.to_string();
    let ty = FuncType::new(
        store.engine(),
        params.iter().cloned(),
        results.iter().cloned(),
    );
    let func = Func::new(&mut *store, ty, move |caller, args, out| {
        let result =
            std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| f(caller, args, out)));
        match result {
            Ok(res) => res,
            Err(payload) => {
                let panic_msg = if let Some(msg) = payload.downcast_ref::<&str>() {
                    (*msg).to_string()
                } else if let Some(msg) = payload.downcast_ref::<String>() {
                    msg.clone()
                } else {
                    "<non-string panic payload>".to_string()
                };
                Err(anyhow::anyhow!(
                    "panic in host import {}.{}: {}",
                    module_name,
                    func_name,
                    panic_msg
                ))
            }
        }
    });
    linker.define(&mut *store, module, name, func)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn repo_path(relative: &str) -> std::path::PathBuf {
        std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("../..")
            .join(relative)
    }

    #[test]
    fn parse_bc7_cubemap_ktx2() {
        let path = repo_path("bevy/assets/textures/Ryfjallet_cubemap_bc7.ktx2");
        let bytes = std::fs::read(&path).expect("read ktx2");
        let parsed = parse_ktx2_texture(&bytes).expect("parse ktx2");
        assert_eq!(parsed.width, 512);
        assert_eq!(parsed.height_per_slice, 512);
        assert_eq!(parsed.slice_count, 6);
        assert_eq!(parsed.format, wgpu::TextureFormat::Bc7RgbaUnorm);
        assert_eq!(parsed.levels.len(), 1);
        assert_eq!(parsed.levels[0].len(), 1_572_864);
    }

    #[test]
    fn parse_rgb9e5_zstd_cubemap_ktx2() {
        let path =
            repo_path("mgstudio-engine/assets/environment_maps/pisa_specular_rgb9e5_zstd.ktx2");
        let bytes = std::fs::read(&path).expect("read ktx2");
        let parsed = parse_ktx2_texture(&bytes).expect("parse ktx2");
        assert_eq!(parsed.width, 512);
        assert_eq!(parsed.height_per_slice, 512);
        assert_eq!(parsed.slice_count, 6);
        assert_eq!(parsed.format, wgpu::TextureFormat::Rgb9e5Ufloat);
        assert_eq!(parsed.levels.len(), 9);
    }
}
