use std::collections::HashMap;
use std::time::{Duration, Instant};

use anyhow::Context;
use wasmtime::{AnyRef, Caller, ExternRef, Func, FuncType, Linker, Store, Val, ValType};

use winit::event::MouseButton;
use winit::keyboard::KeyCode;

use crate::native_window::NativeWindow;
use crate::gpu_backend::GpuBackend;

use crate::source_spec::{join_dir_best_effort, DirSourceSpec};

pub struct HostState {
  pub trace_host: bool,
  pub assets: DirSourceSpec,
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

    // Closures.
    next_closure_id: i32,
    closures: HashMap<i32, ClosureEntry>,

    window: Option<NativeWindow>,

    gpu: Option<GpuBackend>,
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
            next_closure_id: 1,
            closures: HashMap::new(),
            window: None,
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

    fn now_seconds_f32(&self) -> f32 {
        let dt: Duration = self.start_time.elapsed();
        dt.as_secs_f32()
    }

    fn ensure_gpu(&mut self) -> anyhow::Result<&mut GpuBackend> {
        if self.gpu.is_none() {
            self.gpu = Some(GpuBackend::new(self.assets.base.clone())?);
        }
        Ok(self.gpu.as_mut().unwrap())
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
        "ArrowUp" => Some(KeyCode::ArrowUp),
        "ArrowDown" => Some(KeyCode::ArrowDown),
        "ArrowLeft" => Some(KeyCode::ArrowLeft),
        "ArrowRight" => Some(KeyCode::ArrowRight),
        "Space" => Some(KeyCode::Space),
        "Escape" => Some(KeyCode::Escape),
        "Comma" => Some(KeyCode::Comma),
        "Period" => Some(KeyCode::Period),
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

fn ok_i32(out: &mut [Val], value: i32) {
    out[0] = Val::I32(value);
}

fn ok_f32(out: &mut [Val], value: f32) {
    out[0] = Val::F32(value.to_bits());
}

fn ok_externref_null(out: &mut [Val]) {
    out[0] = Val::ExternRef(None);
}

fn ok_externref_i32(mut caller: impl wasmtime::AsContextMut, out: &mut [Val], value: i32) -> anyhow::Result<()> {
    let r = ExternRef::new(&mut caller, value)?;
    out[0] = Val::ExternRef(Some(r));
    Ok(())
}

pub fn define_imports(store: &mut Store<HostState>, linker: &mut Linker<HostState>) -> anyhow::Result<()> {
    define_mgstudio_host_imports(store, linker)?;
    define_moonbit_ffi_imports(store, linker)?;
    define_spectest_imports(store, linker)?;
    Ok(())
}

fn define_mgstudio_host_imports(store: &mut Store<HostState>, linker: &mut Linker<HostState>) -> anyhow::Result<()> {
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
                caller.data_mut().string_sink.push((cu as u32 & 0xFFFF) as u16);
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
                caller.data_mut().bytes_sink.extend_from_slice(&u.to_le_bytes());
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
                // Keep window events flowing even if the guest doesn't call
                // `window_poll_events` every frame. This avoids apparent UI
                // freezes on some platforms.
                if let Some(win) = caller.data_mut().window.as_mut() {
                    win.pump_events();
                }
                tick.call(&mut caller, &[], &mut []).context("tick() trapped")?;
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

    // time_now() -> f32
    define_func(
        store,
        linker,
        "mgstudio_host",
        "time_now",
        &[],
        &[ValType::F32],
        |caller, _args, out| {
            ok_f32(out, caller.data().now_seconds_f32());
            Ok(())
        },
    )?;

    // Input.
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

    for (name, which) in [
        ("input_is_key_down", 0),
        ("input_is_key_just_pressed", 1),
        ("input_is_key_just_released", 2),
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
                let ok = if let (Some(win), Some(code_id)) =
                    (caller.data().window.as_ref(), args.get(0).and_then(|v| v.i32()))
                {
                    if let Some(code) = caller.data().string_table_get(code_id) {
                        if let Some(kc) = parse_keycode(code) {
                            match which {
                                0 => win.input.key_down.contains(&kc),
                                1 => win.input.key_just_pressed.contains(&kc),
                                2 => win.input.key_just_released.contains(&kc),
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
                let ok = if let (Some(win), Some(btn_id)) =
                    (caller.data().window.as_ref(), args.get(0).and_then(|v| v.i32()))
                {
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
            let assets_base = caller.data().assets.base.clone();
            if caller.data().trace_host {
                let full = join_dir_best_effort(&assets_base, &rel);
                eprintln!("asset_load_texture: {rel} -> {full}");
            }
            // Empty path = fallback 1x1 white.
            if rel.trim().is_empty() {
                let gpu = caller.data_mut().ensure_gpu()?;
                let id = gpu.create_texture_rgba8(1, 1, &[255, 255, 255, 255], nearest)?;
                ok_i32(out, id);
                return Ok(());
            }
            let full_path = join_dir_best_effort(&assets_base, rel.trim_start_matches('/'));
            let file_bytes = std::fs::read(&full_path).unwrap_or_default();
            let (w, h, pixels) = match image::load_from_memory(&file_bytes) {
                Ok(img) => {
                    let rgba = img.to_rgba8();
                    (rgba.width(), rgba.height(), rgba.into_raw())
                }
                Err(_) => (1u32, 1u32, vec![255u8, 255u8, 255u8, 255u8]),
            };
            let gpu = caller.data_mut().ensure_gpu()?;
            let id = gpu.create_texture_rgba8(w, h, &pixels, nearest)?;
            ok_i32(out, id);
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
        "asset_update_texture_region_bytes",
        &[ValType::I32, ValType::I32, ValType::I32, ValType::I32, ValType::I32, ValType::I32],
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
            let ok = caller.data().gpu.as_ref().map(|g| g.is_texture_loaded(id)).unwrap_or(false);
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
        &[ValType::EXTERNREF, ValType::EXTERNREF, ValType::I32, ValType::I32],
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
                gpu.draw_sprite_uv(texture_id, x, y, rotation, scale_x, scale_y, color, uv_min, uv_max)?;
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
            if let Some(gpu) = caller.data_mut().gpu.as_mut() {
                gpu.draw_mesh(mesh_id, x, y, rotation, scale_x, scale_y, color)?;
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
            let id = gpu.create_mesh_triangles_xy(&floats);
            ok_i32(out, id);
            Ok(())
        },
    )?;

    // Remaining imports: keep as no-ops for now (fonts, folders, capsule mesh, gizmo lines, etc).
    for (name, params, results, default_i32) in [
        ("asset_load_wgsl", vec![ValType::I32], vec![ValType::I32], -1),
        ("asset_load_font", vec![ValType::I32], vec![ValType::I32], -1),
        ("asset_font_bytes_len", vec![ValType::I32], vec![ValType::I32], 0),
        ("asset_font_bytes_get", vec![ValType::I32, ValType::I32], vec![ValType::I32], 0),
        ("asset_font_bytes_get_u32", vec![ValType::I32, ValType::I32], vec![ValType::I32], 0),
        ("font_rasterize_glyph", vec![ValType::I32, ValType::F32, ValType::I32, ValType::I32], vec![ValType::I32], -1),
        ("font_glyph_width", vec![ValType::I32], vec![ValType::I32], 0),
        ("font_glyph_height", vec![ValType::I32], vec![ValType::I32], 0),
        ("font_glyph_offset_x", vec![ValType::I32], vec![ValType::I32], 0),
        ("font_glyph_offset_y", vec![ValType::I32], vec![ValType::I32], 0),
        ("font_measure_advance", vec![ValType::I32, ValType::F32, ValType::I32], vec![ValType::F32], 0),
        ("asset_update_texture_region", vec![ValType::I32, ValType::I32, ValType::I32, ValType::I32, ValType::I32, ValType::I32], vec![ValType::I32], 0),
        ("asset_load_folder", vec![ValType::I32], vec![ValType::I32], -1),
        ("asset_poll_loaded_folder_event_kind", vec![], vec![ValType::I32], -1),
        ("asset_poll_loaded_folder_event_id", vec![], vec![ValType::I32], -1),
        ("asset_loaded_folder_handles_len", vec![ValType::I32], vec![ValType::I32], 0),
        ("asset_loaded_folder_handles_get", vec![ValType::I32, ValType::I32], vec![ValType::I32], -1),
        ("gpu_create_mesh_capsule", vec![ValType::F32, ValType::F32, ValType::I32], vec![ValType::I32], -1),
        ("gpu_draw_gizmo_line", vec![
            ValType::F32, ValType::F32, ValType::F32, ValType::F32,
            ValType::F32, ValType::F32, ValType::F32, ValType::F32,
            ValType::F32, ValType::F32, ValType::F32, ValType::F32,
            ValType::F32, ValType::I32, ValType::F32, ValType::F32,
        ], vec![ValType::I32], 0),
    ] {
        let default0 = default_i32;
        let result0 = results[0].clone();
        define_func(store, linker, "mgstudio_host", name, &params, &results, move |_caller, _args, out| {
            match &result0 {
                ValType::I32 => ok_i32(out, default0),
                ValType::F32 => ok_f32(out, 0.0),
                ValType::Ref(_) => ok_externref_null(out),
                _ => ok_i32(out, default0),
            }
            Ok(())
        })?;
    }

    Ok(())
}

fn define_moonbit_ffi_imports(store: &mut Store<HostState>, linker: &mut Linker<HostState>) -> anyhow::Result<()> {
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
            caller.data_mut().closures.insert(id, ClosureEntry { func, env: env_owned });

            ok_externref_i32(&mut caller, out, id)?;
            Ok(())
        },
    )?;

    Ok(())
}

fn define_spectest_imports(store: &mut Store<HostState>, linker: &mut Linker<HostState>) -> anyhow::Result<()> {
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
    f: impl for<'a> Fn(Caller<'a, HostState>, &[Val], &mut [Val]) -> anyhow::Result<()> + Send + Sync + 'static,
) -> anyhow::Result<()> {
    let ty = FuncType::new(store.engine(), params.iter().cloned(), results.iter().cloned());
    let func = Func::new(&mut *store, ty, move |caller, args, out| f(caller, args, out));
    linker.define(&mut *store, module, name, func)?;
    Ok(())
}
