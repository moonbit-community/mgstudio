use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex, OnceLock};

use anyhow::{anyhow, Context};
use wgpu::util::DeviceExt as _;
use winit::window::Window;

// This module is a Rust port of the former MoonBit native runtime wgpu backend.
// It implements the same high-level
// host contract used by mgstudio-engine (begin_frame/begin_pass/draw/end_pass/end_frame)
// with sprite batching (sprite.wgsl) and basic 2D mesh draws (mesh.wgsl).

const MESH_UNIFORM_MAX_BYTES: u64 = 104 * 4;
const COMPRESSED_IMAGE_FORMAT_ASTC_LDR: i32 = 1;
const COMPRESSED_IMAGE_FORMAT_BC: i32 = 2;
const COMPRESSED_IMAGE_FORMAT_ETC2: i32 = 4;
const MESH3D_VERTEX_SHADER_PATH: &str = "shaders/bevy/bevy_pbr/render/mesh.wgsl";
const MESH3D_FRAGMENT_SHADER_PATH: &str = "shaders/bevy/bevy_pbr/render/pbr.wgsl";
const MESH3D_SHADOW_SHADER_PATH: &str = "shaders/bevy/bevy_pbr/render/mesh.wgsl";
const MESH3D_VERTEX_ENTRY: &str = "vertex";
const MESH3D_FRAGMENT_ENTRY: &str = "fragment";
const MESH3D_SHADOW_FRAGMENT_ENTRY: &str = "fragment";

pub struct GpuBackend {
    assets_base: String,

    instance: wgpu::Instance,
    adapter: wgpu::Adapter,
    device: wgpu::Device,
    queue: wgpu::Queue,

    surface: Option<wgpu::Surface<'static>>,
    surface_format: Option<wgpu::TextureFormat>,
    configured_size: (u32, u32),
    surface_acquire_error_streak: u32,
    last_surface_acquire_error: Option<wgpu::SurfaceError>,
    skipped_surface_draw_streak: u32,

    frame: Option<GpuFrame>,
    pass: Option<GpuPassRecorder>,

    textures: HashMap<i32, GpuTexture>,
    next_texture_id: i32,

    meshes: HashMap<i32, GpuMesh>,
    next_mesh_id: i32,

    sprite: SpriteRenderer,
    mesh: MeshRenderer,
    frame_count: u32,
    last_depth_target_id: i32,
    last_depth_size: (u32, u32),
    last_depth_texture: Option<wgpu::Texture>,
    last_depth_view: Option<wgpu::TextureView>,
}

struct GpuFrame {
    surface_tex: Option<wgpu::SurfaceTexture>,
    surface_view: Option<wgpu::TextureView>,
    encoder: wgpu::CommandEncoder,
}

#[derive(Clone, Copy)]
struct GpuPassState {
    target_id: i32, // -1 = surface
    target_format: wgpu::TextureFormat,

    // Logical (points) sizes used by the camera projection.
    width_logical: f32,
    height_logical: f32,

    clear: [f32; 4],
    clear_enabled: bool,

    is_3d: bool,
    camera_x: f32,
    camera_y: f32,
    camera_rot: f32,
    camera_scale: f32,
    camera_z: f32,
    camera_rot_quat: [f32; 4],
    previous_camera: [f32; 3],
    previous_camera_rot_quat: [f32; 4],
    camera_fov_y: f32,
    camera_near: f32,
    camera_far: f32,
    pass_kind: i32,
    ambient: [f32; 4],
    directional_dir_illum: [f32; 4],
    directional_color: [f32; 3],
    point_pos_range: [f32; 4],
    point_color_intensity: [f32; 4],
    spot_pos_range: [f32; 4],
    spot_dir_inner: [f32; 4],
    spot_color_intensity: [f32; 4],
    spot_outer_angle: f32,
    sub_camera_view: [f32; 4], // (scale_x, scale_y, bias_x, bias_y)

    // Physical (pixels) viewport/scissor.
    viewport_x: u32,
    viewport_y: u32,
    viewport_w: u32,
    viewport_h: u32,
    viewport_depth_min: f32,
    viewport_depth_max: f32,
}

struct GpuPassRecorder {
    st: GpuPassState,
    commands: Vec<DrawCmd>,
    cur_sprites: SpriteSegmentBuilder,
    current_scissor: Option<ScissorRect>,
}

enum DrawCmd {
    Sprites(SpriteSegment),
    Mesh(MeshDraw),
    MotionBlur(MotionBlurDraw),
    Bloom2d(Bloom2dDraw),
}

struct SpriteBatch {
    texture_id: i32,
    first_instance: u32,
    instance_count: u32,
}

struct SpriteSegmentBuilder {
    instance_data: Vec<f32>,
    batches: Vec<SpriteBatch>,
    instance_count: u32,
    scissor: Option<ScissorRect>,
}

struct SpriteSegment {
    instance_data: Vec<f32>,
    batches: Vec<SpriteBatch>,
    instance_count: u32,
    scissor: Option<ScissorRect>,
}

#[derive(Clone, Copy, PartialEq, Eq)]
struct ScissorRect {
    x: u32,
    y: u32,
    w: u32,
    h: u32,
}

struct MeshDraw {
    mesh_id: i32,
    is_3d: bool,
    x: f32,
    y: f32,
    z: f32,
    rotation: f32,
    rotation_quat: [f32; 4],
    scale_x: f32,
    scale_y: f32,
    scale_z: f32,
    cull_mode: i32,
    previous_x: f32,
    previous_y: f32,
    previous_z: f32,
    previous_rotation_quat: [f32; 4],
    previous_scale_x: f32,
    previous_scale_y: f32,
    previous_scale_z: f32,
    color: [f32; 4],
    texture_id: i32,
    normal_texture_id: i32,
    emissive_texture_id: i32,
    metallic_roughness_texture_id: i32,
    occlusion_texture_id: i32,
    depth_texture_id: i32,
    anisotropy_texture_id: i32,
    specular_tint_texture_id: i32,
    uv_offset: [f32; 2],
    uv_scale: [f32; 2],
    map_flags: [f32; 4],
    emissive: [f32; 3],
    unlit: f32,
    metallic: f32,
    roughness: f32,
    reflectance: f32,
    normal_map_flag: f32,
    parallax_depth_scale: f32,
    max_parallax_layer_count: f32,
    max_relief_mapping_search_steps: f32,
    depth_map_flag: f32,
    anisotropy_strength: f32,
    anisotropy_rotation_cos: f32,
    anisotropy_rotation_sin: f32,
    anisotropy_map_flag: f32,
    specular_tint: [f32; 3],
    specular_tint_map_flag: f32,
    diffuse_transmission: f32,
    specular_transmission: f32,
    thickness: f32,
    ior: f32,
    transmission_source_texture_id: i32,
    transmission_blur_taps: f32,
    transmission_steps: f32,
    point_shadow_texture_id: i32,
    point_shadow_enabled: f32,
    point_shadow_depth_bias: f32,
    ubo_offset: u32, // computed during encoding
    scissor: Option<ScissorRect>,
}

struct MotionBlurDraw {
    scene_texture_id: i32,
    velocity_texture_id: i32,
    shutter_angle: f32,
    samples: i32,
    scissor: Option<ScissorRect>,
}

struct Bloom2dDraw {
    scene_texture_id: i32,
    enabled: i32,
    intensity: f32,
    low_frequency_boost: f32,
    low_frequency_boost_curvature: f32,
    high_pass_frequency: f32,
    threshold: f32,
    threshold_softness: f32,
    composite_mode: i32,
    max_mip_dimension: i32,
    scale_x: f32,
    scale_y: f32,
    tonemapping_mode: i32,
    deband_dither_enabled: i32,
    view_width: i32,
    view_height: i32,
    agx_lut_texture_id: i32,
    tony_lut_texture_id: i32,
    blender_lut_texture_id: i32,
    fxaa_enabled: i32,
    fxaa_edge_threshold: f32,
    chromatic_aberration_strength: f32,
    vignette_strength: f32,
    scissor: Option<ScissorRect>,
}

struct GpuTexture {
    width: u32,
    height: u32,
    format: wgpu::TextureFormat,
    texture: wgpu::Texture,
    view: wgpu::TextureView,
    sampler: wgpu::Sampler,
    bind_group: wgpu::BindGroup,
    point_shadow_depth_cube_array_view: Option<wgpu::TextureView>,
    point_shadow_depth_face_views: Option<Vec<wgpu::TextureView>>,
    mip_level_count: u32,
    base_mip_level: u32,
    #[allow(dead_code)]
    is_render_target: bool,
}

struct GpuMesh {
    #[allow(dead_code)]
    vertex_count: u32,
    index_count: u32,
    layout: MeshVertexLayout,
    primitive_topology: wgpu::PrimitiveTopology,
    vertex_buf: wgpu::Buffer,
    index_buf: wgpu::Buffer,
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum MeshVertexLayout {
    XyUvRgba,
    XyzNormal,
}

fn mesh3d_topology_from_kind(kind: i32) -> wgpu::PrimitiveTopology {
    match kind {
        1 => wgpu::PrimitiveTopology::LineList,
        2 => wgpu::PrimitiveTopology::LineStrip,
        _ => wgpu::PrimitiveTopology::TriangleList,
    }
}

fn mesh3d_bevy_shader_defs() -> HashMap<String, WgslShaderDefValue> {
    let mut defs = HashMap::new();
    defs.insert(
        "VERTEX_POSITIONS".to_string(),
        WgslShaderDefValue::Bool(true),
    );
    defs.insert("VERTEX_NORMALS".to_string(), WgslShaderDefValue::Bool(true));
    defs.insert(
        "VERTEX_OUTPUT_INSTANCE_INDEX".to_string(),
        WgslShaderDefValue::Bool(true),
    );
    defs.insert(
        "MATERIAL_BIND_GROUP".to_string(),
        WgslShaderDefValue::UInt(3),
    );
    defs.insert(
        "PER_OBJECT_BUFFER_BATCH_SIZE".to_string(),
        WgslShaderDefValue::UInt(1),
    );
    defs.insert(
        "MAX_CASCADES_PER_LIGHT".to_string(),
        WgslShaderDefValue::UInt(1),
    );
    defs.insert(
        "MAX_DIRECTIONAL_LIGHTS".to_string(),
        WgslShaderDefValue::UInt(1),
    );
    defs.insert(
        "AVAILABLE_STORAGE_BUFFER_BINDINGS".to_string(),
        WgslShaderDefValue::UInt(0),
    );
    defs.insert(
        "SHADOW_FILTER_METHOD_HARDWARE_2X2".to_string(),
        WgslShaderDefValue::Bool(true),
    );
    defs
}

const PASS_KIND_BASE_MASK: i32 = 255;
const PASS_KIND_DISABLE_POSTPROCESS_FLAG: i32 = 1 << 8;
const PASS_KIND_DISABLE_FOG_FLAG: i32 = 1 << 9;
const PASS_KIND_DISABLE_DECAL_FLAG: i32 = 1 << 10;
const PASS_KIND_BASE_MOTION_VECTOR: i32 = 1;
const PASS_KIND_BASE_POINT_SHADOW: i32 = 2;
const MESH3D_CULL_MODE_MASK: i32 = 3;
const MESH3D_DRAW_FLAG_DECAL: i32 = 1 << 8;
const MESH3D_DRAW_FLAG_FOG: i32 = 1 << 9;
const MESH3D_DRAW_FLAG_POSTPROCESS_PROXY: i32 = 1 << 10;
const MESH3D_CLUSTERED_LIGHT_STRIDE_BYTES: usize = 80;
const MESH3D_CLUSTERED_LIGHT_CAPACITY: usize = 204;
const MESH3D_CLUSTERED_LIGHTS_UNIFORM_BYTES: u64 =
    (MESH3D_CLUSTERED_LIGHT_STRIDE_BYTES * MESH3D_CLUSTERED_LIGHT_CAPACITY) as u64;
const MESH3D_CLUSTER_INDEX_LISTS_UNIFORM_BYTES: u64 = 1024 * 16;
const MESH3D_CLUSTER_OFFSETS_UNIFORM_BYTES: u64 = 1024 * 16;
const POINT_LIGHT_FLAG_SHADOWS_ENABLED: u32 = 1 << 0;
const POINT_LIGHT_FLAG_SPOT_LIGHT_Y_NEGATIVE: u32 = 1 << 1;
const POINT_LIGHT_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE: u32 = 1 << 3;
// Bevy scales user bias by texel size and sqrt(2) before uploading.
// Use the default point-shadow map size (1024) for parity in examples:
// 0.6 * (2.0 / 1024.0) * sqrt(2.0)
const POINT_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS: f32 = 0.001_656_854_3;

fn pass_kind_base_kind(pass_kind: i32) -> i32 {
    pass_kind & PASS_KIND_BASE_MASK
}

fn pass_kind_postprocess_enabled(pass_kind: i32) -> bool {
    (pass_kind & PASS_KIND_DISABLE_POSTPROCESS_FLAG) == 0
}

fn pass_kind_fog_enabled(pass_kind: i32) -> bool {
    (pass_kind & PASS_KIND_DISABLE_FOG_FLAG) == 0
}

fn pass_kind_decal_enabled(pass_kind: i32) -> bool {
    (pass_kind & PASS_KIND_DISABLE_DECAL_FLAG) == 0
}

fn mesh3d_draw_is_decal(cull_mode: i32) -> bool {
    (cull_mode & MESH3D_DRAW_FLAG_DECAL) != 0
}

fn mesh3d_draw_is_fog(cull_mode: i32) -> bool {
    (cull_mode & MESH3D_DRAW_FLAG_FOG) != 0
}

fn mesh3d_draw_is_postprocess_proxy(cull_mode: i32) -> bool {
    (cull_mode & MESH3D_DRAW_FLAG_POSTPROCESS_PROXY) != 0
}

fn mesh3d_cull_mode_sanitize(cull_mode: i32) -> i32 {
    match cull_mode & MESH3D_CULL_MODE_MASK {
        1 => 1,
        2 => 2,
        _ => 0,
    }
}

fn mesh3d_cull_mode_wgpu(cull_mode: i32) -> Option<wgpu::Face> {
    match mesh3d_cull_mode_sanitize(cull_mode) {
        1 => Some(wgpu::Face::Front),
        2 => Some(wgpu::Face::Back),
        _ => None,
    }
}

fn align_up_u64(value: u64, align: u64) -> u64 {
    if align <= 1 {
        return value;
    }
    value.div_ceil(align) * align
}

fn max_mip_level_count_for_size(width: u32, height: u32) -> u32 {
    let max_dim = width.max(height).max(1);
    u32::BITS - max_dim.leading_zeros()
}

#[derive(Default)]
struct SpriteRenderer {
    bgl_tex: Option<wgpu::BindGroupLayout>,
    bgl_globals: Option<wgpu::BindGroupLayout>,
    pipeline_layout: Option<wgpu::PipelineLayout>,

    pipeline_rgba8: Option<wgpu::RenderPipeline>,
    pipeline_surface: Option<wgpu::RenderPipeline>,
    pipeline_surface_format: Option<wgpu::TextureFormat>,

    globals_buf: Option<wgpu::Buffer>,
    instance_buf: Option<wgpu::Buffer>,
    instance_capacity: u64,
}

#[derive(Default)]
struct MeshRenderer {
    bgl_uniform: Option<wgpu::BindGroupLayout>,
    bg_view_3d: Option<wgpu::BindGroup>,
    bg_view_env_3d: Option<wgpu::BindGroup>,
    bg_mesh_3d: Option<wgpu::BindGroup>,
    bg_material_3d: Option<wgpu::BindGroup>,
    mesh3d_dummy_uniform_buf: Option<wgpu::Buffer>,
    mesh3d_dummy_color_2d_view: Option<wgpu::TextureView>,
    mesh3d_dummy_3d_view: Option<wgpu::TextureView>,
    mesh3d_dummy_linear_sampler: Option<wgpu::Sampler>,
    mesh3d_dummy_depth_cube_array_view: Option<wgpu::TextureView>,
    mesh3d_dummy_depth_array_view: Option<wgpu::TextureView>,
    mesh3d_dummy_compare_sampler: Option<wgpu::Sampler>,
    mesh3d_view_uniform_buf: Option<wgpu::Buffer>,
    mesh3d_lights_uniform_buf: Option<wgpu::Buffer>,
    mesh3d_clustered_lights_uniform_buf: Option<wgpu::Buffer>,
    mesh3d_cluster_index_lists_uniform_buf: Option<wgpu::Buffer>,
    mesh3d_cluster_offsets_uniform_buf: Option<wgpu::Buffer>,
    mesh3d_mesh_uniform_buf: Option<wgpu::Buffer>,
    mesh3d_material_uniform_buf: Option<wgpu::Buffer>,
    pipeline_layout: Option<wgpu::PipelineLayout>,
    pipeline_layout_3d: Option<wgpu::PipelineLayout>,
    pipelines: HashMap<wgpu::TextureFormat, wgpu::RenderPipeline>,
    pipelines_3d:
        HashMap<(wgpu::TextureFormat, wgpu::PrimitiveTopology, i32), wgpu::RenderPipeline>,
    pipelines_3d_transparent:
        HashMap<(wgpu::TextureFormat, wgpu::PrimitiveTopology, i32), wgpu::RenderPipeline>,
    pipelines_3d_shadow:
        HashMap<(wgpu::TextureFormat, wgpu::PrimitiveTopology, i32), wgpu::RenderPipeline>,

    uniform_buf: Option<wgpu::Buffer>,
    uniform_bg: Option<wgpu::BindGroup>,
    uniform_capacity: u64,
    uniform_binding_size: u64,

    motion_vector_bgl_uniform: Option<wgpu::BindGroupLayout>,
    motion_vector_pipeline_layout: Option<wgpu::PipelineLayout>,
    motion_vector_pipeline: Option<wgpu::RenderPipeline>,
    motion_vector_uniform_buf: Option<wgpu::Buffer>,
    motion_vector_uniform_bg: Option<wgpu::BindGroup>,

    motion_blur_bgl: Option<wgpu::BindGroupLayout>,
    motion_blur_pipeline_layout: Option<wgpu::PipelineLayout>,
    motion_blur_pipeline_rgba8: Option<wgpu::RenderPipeline>,
    motion_blur_pipeline_surface: Option<wgpu::RenderPipeline>,
    motion_blur_pipeline_surface_format: Option<wgpu::TextureFormat>,
    motion_blur_settings_buf: Option<wgpu::Buffer>,
    motion_blur_globals_buf: Option<wgpu::Buffer>,

    bloom2d_bgl: Option<wgpu::BindGroupLayout>,
    bloom2d_pipeline_layout: Option<wgpu::PipelineLayout>,
    bloom2d_downsample_first_pipeline: Option<wgpu::RenderPipeline>,
    bloom2d_downsample_first_no_threshold_pipeline: Option<wgpu::RenderPipeline>,
    bloom2d_downsample_first_uniform_pipeline: Option<wgpu::RenderPipeline>,
    bloom2d_downsample_first_no_threshold_uniform_pipeline: Option<wgpu::RenderPipeline>,
    bloom2d_downsample_pipeline: Option<wgpu::RenderPipeline>,
    bloom2d_downsample_uniform_pipeline: Option<wgpu::RenderPipeline>,
    bloom2d_upsample_pipeline_energy: Option<wgpu::RenderPipeline>,
    bloom2d_upsample_pipeline_additive: Option<wgpu::RenderPipeline>,
    bloom2d_pipeline_rgba8: Option<wgpu::RenderPipeline>,
    bloom2d_pipeline_surface: Option<wgpu::RenderPipeline>,
    bloom2d_pipeline_surface_format: Option<wgpu::TextureFormat>,
    bloom2d_settings_buf: Option<wgpu::Buffer>,
    bloom2d_sampler: Option<wgpu::Sampler>,
    bloom2d_mip_texture: Option<wgpu::Texture>,
    bloom2d_mip_views: Vec<wgpu::TextureView>,
    bloom2d_mip_count: u32,
    bloom2d_mip_width: u32,
    bloom2d_mip_height: u32,
}

impl GpuBackend {
    fn resolve_draw_texture_id(&mut self, id: i32) -> anyhow::Result<Option<i32>> {
        if id < 0 {
            return Ok(Some(self.ensure_default_texture()?));
        }
        if self.textures.contains_key(&id) {
            Ok(Some(id))
        } else {
            Ok(None)
        }
    }

    pub fn new(assets_base: String) -> anyhow::Result<Self> {
        let instance = wgpu::Instance::default();
        let adapter = pollster::block_on(instance.request_adapter(&wgpu::RequestAdapterOptions {
            power_preference: wgpu::PowerPreference::HighPerformance,
            compatible_surface: None,
            force_fallback_adapter: false,
        }))
        .context("wgpu: request_adapter failed")?;
        let adapter_features = adapter.features();
        let mut required_features = wgpu::Features::empty();
        if adapter_features.contains(wgpu::Features::TEXTURE_COMPRESSION_ASTC) {
            required_features |= wgpu::Features::TEXTURE_COMPRESSION_ASTC;
        }
        if adapter_features.contains(wgpu::Features::TEXTURE_COMPRESSION_BC) {
            required_features |= wgpu::Features::TEXTURE_COMPRESSION_BC;
        }
        if adapter_features.contains(wgpu::Features::TEXTURE_COMPRESSION_ETC2) {
            required_features |= wgpu::Features::TEXTURE_COMPRESSION_ETC2;
        }

        let (device, queue) = pollster::block_on(adapter.request_device(&wgpu::DeviceDescriptor {
            label: Some("mgstudio-device"),
            required_features,
            required_limits: wgpu::Limits::default(),
            memory_hints: wgpu::MemoryHints::Performance,
            ..Default::default()
        }))
        .context("wgpu: request_device failed")?;

        Ok(Self {
            assets_base,
            instance,
            adapter,
            device,
            queue,
            surface: None,
            surface_format: None,
            configured_size: (0, 0),
            surface_acquire_error_streak: 0,
            last_surface_acquire_error: None,
            skipped_surface_draw_streak: 0,
            frame: None,
            pass: None,
            textures: HashMap::new(),
            next_texture_id: 1,
            meshes: HashMap::new(),
            next_mesh_id: 1,
            sprite: SpriteRenderer::default(),
            mesh: MeshRenderer::default(),
            frame_count: 0,
            last_depth_target_id: i32::MIN,
            last_depth_size: (0, 0),
            last_depth_texture: None,
            last_depth_view: None,
        })
    }

    #[allow(dead_code)]
    pub fn device(&self) -> &wgpu::Device {
        &self.device
    }

    pub fn create_surface_from_window(
        &self,
        window: Arc<Window>,
    ) -> anyhow::Result<wgpu::Surface<'static>> {
        // Keep an Arc clone alive inside the Surface handle source so the surface remains valid.
        let surface: wgpu::Surface<'static> = self
            .instance
            .create_surface(window)
            .context("wgpu: create_surface failed")?;
        Ok(surface)
    }

    pub fn set_surface(&mut self, surface: wgpu::Surface<'static>) {
        self.surface = Some(surface);
    }

    pub fn is_surface_ready(&self) -> bool {
        self.surface.is_some()
    }

    pub fn configure_surface(&mut self, width: u32, height: u32) -> anyhow::Result<()> {
        let surface = match self.surface.as_ref() {
            Some(s) => s,
            None => return Ok(()),
        };

        let width = width.max(1);
        let height = height.max(1);

        let caps = surface.get_capabilities(&self.adapter);
        let format = pick_surface_format(&caps);
        let present_mode = pick_present_mode(&caps);
        let alpha_mode = caps
            .alpha_modes
            .first()
            .copied()
            .unwrap_or(wgpu::CompositeAlphaMode::Auto);

        // Match mgstudio native runtime: surfaces must be renderable and copyable out.
        let usage = wgpu::TextureUsages::RENDER_ATTACHMENT | wgpu::TextureUsages::COPY_SRC;

        let config = wgpu::SurfaceConfiguration {
            usage,
            format,
            width,
            height,
            present_mode,
            alpha_mode,
            view_formats: vec![],
            desired_maximum_frame_latency: 2,
        };
        surface.configure(&self.device, &config);
        self.surface_format = Some(format);
        self.configured_size = (width, height);
        Ok(())
    }

    pub fn ensure_surface_configured(&mut self, width: u32, height: u32) -> anyhow::Result<()> {
        if self.surface.is_none() {
            return Ok(());
        }
        if self.configured_size == (width, height) && self.surface_format.is_some() {
            return Ok(());
        }
        self.configure_surface(width, height)
    }

    pub fn begin_frame(&mut self) -> anyhow::Result<()> {
        if self.surface.is_none() {
            self.frame = None;
            return Ok(());
        }

        let encoder = self
            .device
            .create_command_encoder(&wgpu::CommandEncoderDescriptor {
                label: Some("mgstudio-frame-encoder"),
            });

        let mut frame = GpuFrame {
            surface_tex: None,
            surface_view: None,
            encoder,
        };

        match self.try_acquire_surface_texture()? {
            Some(st) => {
                let view = st
                    .texture
                    .create_view(&wgpu::TextureViewDescriptor::default());
                frame.surface_view = Some(view);
                frame.surface_tex = Some(st);
                if self.surface_acquire_error_streak > 0 {
                    eprintln!(
                        "[wasmtime-runtime] wgpu surface recovered after {} acquire failure(s).",
                        self.surface_acquire_error_streak
                    );
                }
                self.surface_acquire_error_streak = 0;
                self.last_surface_acquire_error = None;
                self.skipped_surface_draw_streak = 0;
            }
            None => {
                frame.surface_tex = None;
                frame.surface_view = None;
            }
        }

        self.pass = None;
        self.frame = Some(frame);
        Ok(())
    }

    pub fn end_frame(&mut self) -> anyhow::Result<()> {
        // If the guest forgot to end the pass, do it for them.
        if self.pass.is_some() {
            self.end_pass()?;
        }

        let Some(mut frame) = self.frame.take() else {
            return Ok(());
        };
        let cmd = frame.encoder.finish();
        self.queue.submit(Some(cmd));

        if let Some(st) = frame.surface_tex.take() {
            st.present();
        }
        // Keep the device progressing to flush deferred GPU work.
        let _ = self.device.poll(wgpu::PollType::Poll);
        self.frame_count = self.frame_count.wrapping_add(1);

        Ok(())
    }

    fn try_acquire_surface_texture(&mut self) -> anyhow::Result<Option<wgpu::SurfaceTexture>> {
        let Some(surface) = self.surface.as_ref() else {
            return Ok(None);
        };
        match surface.get_current_texture() {
            Ok(st) => Ok(Some(st)),
            Err(err) => {
                self.note_surface_acquire_error(&err, "initial acquire");
                match err {
                    wgpu::SurfaceError::Outdated | wgpu::SurfaceError::Lost => {
                        let (width, height) = self.recovery_surface_size();
                        if let Err(config_err) = self.configure_surface(width, height) {
                            eprintln!(
                                "[wasmtime-runtime] failed to reconfigure surface after acquire error: {config_err:?}"
                            );
                            return Err(config_err)
                                .context("wgpu: surface reconfigure after acquire failure");
                        }
                        match self.surface.as_ref().unwrap().get_current_texture() {
                            Ok(st) => Ok(Some(st)),
                            Err(retry_err) => {
                                self.note_surface_acquire_error(
                                    &retry_err,
                                    "retry after reconfigure",
                                );
                                Ok(None)
                            }
                        }
                    }
                    wgpu::SurfaceError::Timeout | wgpu::SurfaceError::Other => Ok(None),
                    wgpu::SurfaceError::OutOfMemory => Err(anyhow!(
                        "wgpu: out of memory while acquiring surface texture"
                    )),
                }
            }
        }
    }

    fn note_surface_acquire_error(&mut self, err: &wgpu::SurfaceError, stage: &str) {
        self.surface_acquire_error_streak = self.surface_acquire_error_streak.saturating_add(1);
        let changed = self.last_surface_acquire_error.as_ref() != Some(err);
        if changed
            || self.surface_acquire_error_streak == 1
            || self.surface_acquire_error_streak % 120 == 0
        {
            eprintln!(
                "[wasmtime-runtime] wgpu surface acquire failed: {err:?} (stage={stage}, streak={})",
                self.surface_acquire_error_streak
            );
        }
        self.last_surface_acquire_error = Some(err.clone());
    }

    fn recovery_surface_size(&self) -> (u32, u32) {
        let (width, height) = self.configured_size;
        (width.max(1), height.max(1))
    }

    pub fn begin_pass(
        &mut self,
        target_id: i32,
        width_logical: i32,
        height_logical: i32,
        clear: [f32; 4],
        camera_x: f32,
        camera_y: f32,
        camera_rot: f32,
        camera_scale: f32,
        viewport: (i32, i32, i32, i32),
        viewport_depth_range: (f32, f32),
        clear_enabled: bool,
    ) -> anyhow::Result<()> {
        let Some(_frame) = self.frame.as_ref() else {
            return Ok(());
        };

        // If a pass is already open, end it (matching native runtime behavior).
        if self.pass.is_some() {
            self.end_pass()?;
        }

        let (vx, vy, vw, vh) = viewport;
        let vx = vx.max(0) as u32;
        let vy = vy.max(0) as u32;
        let vw = vw.max(0) as u32;
        let vh = vh.max(0) as u32;
        let (viewport_depth_min, viewport_depth_max) = viewport_depth_range;

        let width_logical = width_logical.max(1) as f32;
        let height_logical = height_logical.max(1) as f32;
        let camera_scale = if camera_scale == 0.0 {
            1.0
        } else {
            camera_scale
        };

        let target_format = self.target_format_for_id(target_id)?;
        let st = GpuPassState {
            target_id,
            target_format,
            width_logical,
            height_logical,
            clear,
            clear_enabled,
            is_3d: false,
            camera_x,
            camera_y,
            camera_rot,
            camera_scale,
            camera_z: 0.0,
            camera_rot_quat: [0.0, 0.0, 0.0, 1.0],
            previous_camera: [camera_x, camera_y, 0.0],
            previous_camera_rot_quat: [0.0, 0.0, 0.0, 1.0],
            camera_fov_y: std::f32::consts::FRAC_PI_2,
            camera_near: 0.1,
            camera_far: 1000.0,
            pass_kind: 0,
            ambient: [1.0, 1.0, 1.0, 0.0],
            directional_dir_illum: [0.0, -1.0, 0.0, 0.0],
            directional_color: [1.0, 1.0, 1.0],
            point_pos_range: [0.0, 0.0, 0.0, 1.0],
            point_color_intensity: [1.0, 1.0, 1.0, 0.0],
            spot_pos_range: [0.0, 0.0, 0.0, 1.0],
            spot_dir_inner: [0.0, -1.0, 0.0, 0.6],
            spot_color_intensity: [1.0, 1.0, 1.0, 0.0],
            spot_outer_angle: 0.8,
            sub_camera_view: [1.0, 1.0, 0.0, 0.0],
            viewport_x: vx,
            viewport_y: vy,
            viewport_w: vw,
            viewport_h: vh,
            viewport_depth_min,
            viewport_depth_max,
        };

        // Update sprite globals for this pass (view + ndc scale).
        self.ensure_sprite_resources()?;
        self.write_sprite_globals(&st);

        self.pass = Some(GpuPassRecorder {
            st,
            commands: Vec::new(),
            cur_sprites: SpriteSegmentBuilder {
                instance_data: Vec::new(),
                batches: Vec::new(),
                instance_count: 0,
                scissor: None,
            },
            current_scissor: None,
        });
        Ok(())
    }

    pub fn begin_pass_3d(
        &mut self,
        target_id: i32,
        width_logical: i32,
        height_logical: i32,
        clear: [f32; 4],
        camera_x: f32,
        camera_y: f32,
        camera_z: f32,
        camera_rot_x: f32,
        camera_rot_y: f32,
        camera_rot_z: f32,
        camera_rot_w: f32,
        camera_fov_y: f32,
        camera_near: f32,
        camera_far: f32,
        viewport: (i32, i32, i32, i32),
        ambient: [f32; 4],
        directional_dir_illum: [f32; 4],
        directional_color: [f32; 3],
        point_pos_range: [f32; 4],
        point_color_intensity: [f32; 4],
        spot_pos_range: [f32; 4],
        spot_dir_inner: [f32; 4],
        spot_color_intensity: [f32; 4],
        spot_outer_angle: f32,
        sub_camera_view: [f32; 4],
        previous_camera_x: f32,
        previous_camera_y: f32,
        previous_camera_z: f32,
        previous_camera_rot_x: f32,
        previous_camera_rot_y: f32,
        previous_camera_rot_z: f32,
        previous_camera_rot_w: f32,
        pass_kind: i32,
        clear_enabled: bool,
    ) -> anyhow::Result<()> {
        let camera_rot = quat_to_z_rotation(camera_rot_x, camera_rot_y, camera_rot_z, camera_rot_w);
        self.begin_pass(
            target_id,
            width_logical,
            height_logical,
            clear,
            camera_x,
            camera_y,
            camera_rot,
            1.0,
            viewport,
            (0.0, 1.0),
            clear_enabled,
        )?;
        if let Some(pass) = self.pass.as_mut() {
            pass.st.is_3d = true;
            pass.st.camera_z = camera_z;
            pass.st.camera_rot_quat = [camera_rot_x, camera_rot_y, camera_rot_z, camera_rot_w];
            pass.st.previous_camera = [previous_camera_x, previous_camera_y, previous_camera_z];
            pass.st.previous_camera_rot_quat = [
                previous_camera_rot_x,
                previous_camera_rot_y,
                previous_camera_rot_z,
                previous_camera_rot_w,
            ];
            pass.st.camera_fov_y = camera_fov_y;
            pass.st.camera_near = camera_near;
            pass.st.camera_far = camera_far;
            pass.st.pass_kind = pass_kind;
            pass.st.ambient = ambient;
            pass.st.directional_dir_illum = directional_dir_illum;
            pass.st.directional_color = directional_color;
            pass.st.point_pos_range = point_pos_range;
            pass.st.point_color_intensity = point_color_intensity;
            pass.st.spot_pos_range = spot_pos_range;
            pass.st.spot_dir_inner = spot_dir_inner;
            pass.st.spot_color_intensity = spot_color_intensity;
            pass.st.spot_outer_angle = spot_outer_angle;
            pass.st.sub_camera_view = sub_camera_view;
        }
        Ok(())
    }

    pub fn end_pass(&mut self) -> anyhow::Result<()> {
        let Some(mut pass) = self.pass.take() else {
            return Ok(());
        };
        pass.flush_sprites();

        // Collect sprite segments (by reference) to prepare storage buffer + per-segment bind groups.
        let mut sprite_segments: Vec<&SpriteSegment> = Vec::new();
        let mut has_mesh_2d = false;
        let mut has_mesh_3d = false;
        let mut has_mesh_3d_triangles = false;
        let mut has_mesh_3d_line_list = false;
        let mut has_mesh_3d_line_strip = false;
        let mut has_motion_blur = false;
        let mut has_bloom2d = false;
        for cmd in &pass.commands {
            match cmd {
                DrawCmd::Sprites(seg) => sprite_segments.push(seg),
                DrawCmd::Mesh(draw) => {
                    if draw.is_3d {
                        has_mesh_3d = true;
                        if let Some(mesh) = self.meshes.get(&draw.mesh_id) {
                            match mesh.primitive_topology {
                                wgpu::PrimitiveTopology::LineList => {
                                    has_mesh_3d_line_list = true;
                                }
                                wgpu::PrimitiveTopology::LineStrip => {
                                    has_mesh_3d_line_strip = true;
                                }
                                _ => {
                                    has_mesh_3d_triangles = true;
                                }
                            }
                        }
                    } else {
                        has_mesh_2d = true;
                    }
                }
                DrawCmd::MotionBlur(_) => {
                    has_motion_blur = true;
                }
                DrawCmd::Bloom2d(_) => {
                    has_bloom2d = true;
                }
            }
        }

        // Prepare sprite instance storage + bind groups.
        let has_sprites = !sprite_segments.is_empty();
        let sprite_segment_bgs = self.prepare_sprite_segments(&pass.st, &sprite_segments)?;

        // Prepare mesh pipelines + uniforms only if needed.
        if has_mesh_2d {
            self.ensure_mesh_pipeline(pass.st.target_format)?;
        }
        if has_mesh_3d {
            if pass_kind_base_kind(pass.st.pass_kind) == PASS_KIND_BASE_MOTION_VECTOR {
                self.ensure_mesh3d_motion_vector_pipeline()?;
            } else if pass_kind_base_kind(pass.st.pass_kind) == PASS_KIND_BASE_POINT_SHADOW {
                if has_mesh_3d_triangles {
                    for cull_mode in [0, 1, 2] {
                        self.ensure_mesh3d_shadow_pipeline(
                            pass.st.target_format,
                            wgpu::PrimitiveTopology::TriangleList,
                            cull_mode,
                        )?;
                    }
                }
                if has_mesh_3d_line_list {
                    for cull_mode in [0, 1, 2] {
                        self.ensure_mesh3d_shadow_pipeline(
                            pass.st.target_format,
                            wgpu::PrimitiveTopology::LineList,
                            cull_mode,
                        )?;
                    }
                }
                if has_mesh_3d_line_strip {
                    for cull_mode in [0, 1, 2] {
                        self.ensure_mesh3d_shadow_pipeline(
                            pass.st.target_format,
                            wgpu::PrimitiveTopology::LineStrip,
                            cull_mode,
                        )?;
                    }
                }
            } else {
                if has_mesh_3d_triangles {
                    for cull_mode in [0, 1, 2] {
                        self.ensure_mesh3d_pipeline(
                            pass.st.target_format,
                            wgpu::PrimitiveTopology::TriangleList,
                            cull_mode,
                        )?;
                    }
                }
                if has_mesh_3d_line_list {
                    for cull_mode in [0, 1, 2] {
                        self.ensure_mesh3d_pipeline(
                            pass.st.target_format,
                            wgpu::PrimitiveTopology::LineList,
                            cull_mode,
                        )?;
                    }
                }
                if has_mesh_3d_line_strip {
                    for cull_mode in [0, 1, 2] {
                        self.ensure_mesh3d_pipeline(
                            pass.st.target_format,
                            wgpu::PrimitiveTopology::LineStrip,
                            cull_mode,
                        )?;
                    }
                }
            }
        }
        if has_motion_blur {
            self.ensure_motion_blur_pipeline_for_format(pass.st.target_format)?;
        }
        if has_bloom2d {
            self.ensure_bloom2d_pipeline_for_format(pass.st.target_format)?;
        }
        self.prepare_mesh_uniforms(&mut pass)?;

        // Clone wgpu handles so we don't hold long-lived borrows across the encoding phase.
        let sprite_pipeline = if !has_sprites {
            None
        } else if pass.st.target_format == wgpu::TextureFormat::Rgba8Unorm {
            Some(
                self.sprite
                    .pipeline_rgba8
                    .as_ref()
                    .ok_or_else(|| anyhow!("wgpu: sprite rgba8 pipeline missing"))?
                    .clone(),
            )
        } else {
            Some(
                self.sprite
                    .pipeline_surface
                    .as_ref()
                    .ok_or_else(|| anyhow!("wgpu: sprite surface pipeline missing"))?
                    .clone(),
            )
        };
        let mesh_pipeline_2d = self.mesh.pipelines.get(&pass.st.target_format).cloned();
        let mesh_pipelines_3d = self.mesh.pipelines_3d.clone();
        let mesh_pipelines_3d_transparent = self.mesh.pipelines_3d_transparent.clone();
        let mesh_pipelines_3d_shadow = self.mesh.pipelines_3d_shadow.clone();
        let mesh_pipeline_motion_vector = self.mesh.motion_vector_pipeline.as_ref().cloned();
        let mesh_bg_2d = self.mesh.uniform_bg.as_ref().cloned();
        let mesh3d_view_env_bg = self.mesh.bg_view_env_3d.as_ref().cloned();
        let mesh3d_mesh_bg = self.mesh.bg_mesh_3d.as_ref().cloned();
        let mesh3d_material_bg = self.mesh.bg_material_3d.as_ref().cloned();
        let mesh3d_dummy_uniform_buf = self.mesh.mesh3d_dummy_uniform_buf.as_ref().cloned();
        let mesh3d_dummy_color_2d_view = self.mesh.mesh3d_dummy_color_2d_view.as_ref().cloned();
        let mesh3d_dummy_3d_view = self.mesh.mesh3d_dummy_3d_view.as_ref().cloned();
        let mesh3d_dummy_linear_sampler = self.mesh.mesh3d_dummy_linear_sampler.as_ref().cloned();
        let mesh3d_dummy_depth_cube_array_view = self
            .mesh
            .mesh3d_dummy_depth_cube_array_view
            .as_ref()
            .cloned();
        let mesh3d_dummy_depth_array_view =
            self.mesh.mesh3d_dummy_depth_array_view.as_ref().cloned();
        let mesh3d_dummy_compare_sampler = self.mesh.mesh3d_dummy_compare_sampler.as_ref().cloned();
        let mesh_motion_vector_bg = self.mesh.motion_vector_uniform_bg.as_ref().cloned();
        let motion_blur_pipeline = if pass.st.target_format == wgpu::TextureFormat::Rgba8Unorm {
            self.mesh.motion_blur_pipeline_rgba8.as_ref().cloned()
        } else {
            self.mesh.motion_blur_pipeline_surface.as_ref().cloned()
        };
        let motion_blur_bgl = self.mesh.motion_blur_bgl.as_ref().cloned();
        let bloom2d_pipeline = if pass.st.target_format == wgpu::TextureFormat::Rgba8Unorm {
            self.mesh.bloom2d_pipeline_rgba8.as_ref().cloned()
        } else {
            self.mesh.bloom2d_pipeline_surface.as_ref().cloned()
        };
        let bloom2d_bgl = self.mesh.bloom2d_bgl.as_ref().cloned();

        let Some(mut frame) = self.frame.take() else {
            return Ok(());
        };
        let (target_view, target_width, target_height): (wgpu::TextureView, u32, u32) = if pass
            .st
            .target_id
            == -1
        {
            match frame.surface_view.as_ref() {
                Some(v) => {
                    let (w, h) = self.configured_size;
                    (v.clone(), w.max(1), h.max(1))
                }
                None => {
                    self.skipped_surface_draw_streak =
                        self.skipped_surface_draw_streak.saturating_add(1);
                    if self.skipped_surface_draw_streak == 1
                        || self.skipped_surface_draw_streak % 120 == 0
                    {
                        eprintln!(
                                "[wasmtime-runtime] skip surface render pass: no acquired surface texture view (streak={})",
                                self.skipped_surface_draw_streak
                            );
                    }
                    self.frame = Some(frame);
                    return Ok(());
                }
            }
        } else {
            match self.textures.get(&pass.st.target_id) {
                Some(t) => (t.view.clone(), t.width.max(1), t.height.max(1)),
                None => {
                    self.frame = Some(frame);
                    return Ok(());
                }
            }
        };
        let mut depth_view: Option<wgpu::TextureView> = None;
        if pass.st.is_3d {
            let mut used_point_shadow_target_depth = false;
            if pass_kind_base_kind(pass.st.pass_kind) == PASS_KIND_BASE_POINT_SHADOW {
                if let Some(target_tex) = self.textures.get(&pass.st.target_id) {
                    if let Some(face_views) = target_tex.point_shadow_depth_face_views.as_ref() {
                        let face_height = pass.st.viewport_h.max(1);
                        let raw_face = (pass.st.viewport_y / face_height).min(5) as usize;
                        if let Some(face_view) = face_views.get(raw_face) {
                            depth_view = Some(face_view.clone());
                            used_point_shadow_target_depth = true;
                            pass.st.viewport_y = 0;
                        }
                    }
                }
            }
            if !used_point_shadow_target_depth {
                let target_size = (target_width.max(1), target_height.max(1));
                if self.last_depth_view.is_none()
                    || self.last_depth_target_id != pass.st.target_id
                    || self.last_depth_size != target_size
                {
                    let depth_tex = self.device.create_texture(&wgpu::TextureDescriptor {
                        label: Some("mgstudio-pass-depth"),
                        size: wgpu::Extent3d {
                            width: target_size.0,
                            height: target_size.1,
                            depth_or_array_layers: 1,
                        },
                        mip_level_count: 1,
                        sample_count: 1,
                        dimension: wgpu::TextureDimension::D2,
                        format: wgpu::TextureFormat::Depth24Plus,
                        usage: wgpu::TextureUsages::RENDER_ATTACHMENT
                            | wgpu::TextureUsages::TEXTURE_BINDING,
                        view_formats: &[],
                    });
                    let view = depth_tex.create_view(&wgpu::TextureViewDescriptor::default());
                    self.last_depth_texture = Some(depth_tex);
                    self.last_depth_view = Some(view);
                    self.last_depth_target_id = pass.st.target_id;
                    self.last_depth_size = target_size;
                }
                depth_view = self.last_depth_view.as_ref().cloned();
            }
        }

        {
            let depth_attachment =
                depth_view
                    .as_ref()
                    .map(|view| wgpu::RenderPassDepthStencilAttachment {
                        view,
                        depth_ops: Some(wgpu::Operations {
                            load: wgpu::LoadOp::Clear(0.0),
                            store: wgpu::StoreOp::Store,
                        }),
                        stencil_ops: None,
                    });
            let mut rp = frame
                .encoder
                .begin_render_pass(&wgpu::RenderPassDescriptor {
                    label: Some("mgstudio-pass"),
                    color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                        view: &target_view,
                        depth_slice: None,
                        resolve_target: None,
                        ops: wgpu::Operations {
                            load: if pass.st.clear_enabled {
                                wgpu::LoadOp::Clear(wgpu::Color {
                                    r: pass.st.clear[0] as f64,
                                    g: pass.st.clear[1] as f64,
                                    b: pass.st.clear[2] as f64,
                                    a: pass.st.clear[3] as f64,
                                })
                            } else {
                                wgpu::LoadOp::Load
                            },
                            store: wgpu::StoreOp::Store,
                        },
                    })],
                    depth_stencil_attachment: depth_attachment,
                    timestamp_writes: None,
                    occlusion_query_set: None,
                    multiview_mask: None,
                });

            rp.set_viewport(
                pass.st.viewport_x as f32,
                pass.st.viewport_y as f32,
                pass.st.viewport_w as f32,
                pass.st.viewport_h as f32,
                pass.st.viewport_depth_min,
                pass.st.viewport_depth_max,
            );

            let mut seg_i: usize = 0;
            for cmd in pass.commands {
                match cmd {
                    DrawCmd::Sprites(seg) => {
                        if seg.instance_count == 0 {
                            continue;
                        }
                        let Some(bg) = sprite_segment_bgs.get(seg_i) else {
                            break;
                        };
                        let Some(pipeline) = sprite_pipeline.as_ref() else {
                            continue;
                        };
                        seg_i += 1;
                        let Some((sx, sy, sw, sh)) = resolve_scissor_rect(
                            &pass.st,
                            seg.scissor,
                            target_width,
                            target_height,
                        ) else {
                            continue;
                        };

                        rp.set_pipeline(pipeline);
                        rp.set_scissor_rect(sx, sy, sw, sh);
                        rp.set_bind_group(1, bg, &[]);
                        for batch in &seg.batches {
                            let Some(tex) = self.textures.get(&batch.texture_id) else {
                                continue;
                            };
                            rp.set_bind_group(0, &tex.bind_group, &[]);
                            rp.draw(
                                0..6,
                                batch.first_instance..(batch.first_instance + batch.instance_count),
                            );
                        }
                    }
                    DrawCmd::Mesh(draw) => {
                        let Some(mesh) = self.meshes.get(&draw.mesh_id) else {
                            continue;
                        };
                        if draw.is_3d && mesh.layout != MeshVertexLayout::XyzNormal {
                            continue;
                        }
                        if !draw.is_3d && mesh.layout != MeshVertexLayout::XyUvRgba {
                            continue;
                        }
                        let Some((sx, sy, sw, sh)) = resolve_scissor_rect(
                            &pass.st,
                            draw.scissor,
                            target_width,
                            target_height,
                        ) else {
                            continue;
                        };

                        // Motion-vector prepass: opaque-only and separate uniform/pipeline.
                        if draw.is_3d
                            && pass_kind_base_kind(pass.st.pass_kind)
                                == PASS_KIND_BASE_MOTION_VECTOR
                        {
                            if mesh.primitive_topology != wgpu::PrimitiveTopology::TriangleList {
                                continue;
                            }
                            if draw.color[3] < 0.999 {
                                continue;
                            }
                            let (Some(pipeline), Some(bg)) = (
                                mesh_pipeline_motion_vector.as_ref(),
                                mesh_motion_vector_bg.as_ref(),
                            ) else {
                                continue;
                            };
                            let Some(ubo) = self.mesh.motion_vector_uniform_buf.as_ref() else {
                                continue;
                            };
                            let bytes = mesh3d_motion_vector_uniform_bytes(&pass.st, &draw);
                            self.queue.write_buffer(ubo, 0, bytes.as_slice());

                            rp.set_pipeline(pipeline);
                            rp.set_scissor_rect(sx, sy, sw, sh);
                            rp.set_bind_group(0, bg, &[]);
                            rp.set_vertex_buffer(0, mesh.vertex_buf.slice(..));
                            rp.set_index_buffer(
                                mesh.index_buf.slice(..),
                                wgpu::IndexFormat::Uint16,
                            );
                            rp.draw_indexed(0..mesh.index_count, 0, 0..1);
                            continue;
                        }

                        let pipeline = if draw.is_3d {
                            let pass_base_kind = pass_kind_base_kind(pass.st.pass_kind);
                            let key = (
                                pass.st.target_format,
                                mesh.primitive_topology,
                                mesh3d_cull_mode_sanitize(draw.cull_mode),
                            );
                            if pass_base_kind == PASS_KIND_BASE_POINT_SHADOW {
                                if draw.color[3] < 0.999 {
                                    None
                                } else {
                                    mesh_pipelines_3d_shadow.get(&key)
                                }
                            } else if draw.color[3] < 0.999 {
                                mesh_pipelines_3d_transparent.get(&key)
                            } else {
                                mesh_pipelines_3d.get(&key)
                            }
                        } else {
                            mesh_pipeline_2d.as_ref()
                        };
                        if draw.is_3d {
                            let (
                                Some(pipeline),
                                Some(view_env_bg),
                                Some(mesh_bg),
                                Some(material_bg),
                            ) = (
                                pipeline,
                                mesh3d_view_env_bg.as_ref(),
                                mesh3d_mesh_bg.as_ref(),
                                mesh3d_material_bg.as_ref(),
                            )
                            else {
                                continue;
                            };
                            let (
                                Some(view_ubo),
                                Some(lights_ubo),
                                Some(clustered_lights_ubo),
                                Some(cluster_index_lists_ubo),
                                Some(cluster_offsets_ubo),
                                Some(mesh_ubo),
                                Some(material_ubo),
                                Some(dummy_uniform_buf),
                                Some(dummy_color_2d_view),
                                Some(dummy_3d_view),
                                Some(dummy_linear_sampler),
                                Some(dummy_depth_cube_array_view),
                                Some(dummy_depth_array_view),
                                Some(dummy_compare_sampler),
                            ) = (
                                self.mesh.mesh3d_view_uniform_buf.as_ref(),
                                self.mesh.mesh3d_lights_uniform_buf.as_ref(),
                                self.mesh.mesh3d_clustered_lights_uniform_buf.as_ref(),
                                self.mesh.mesh3d_cluster_index_lists_uniform_buf.as_ref(),
                                self.mesh.mesh3d_cluster_offsets_uniform_buf.as_ref(),
                                self.mesh.mesh3d_mesh_uniform_buf.as_ref(),
                                self.mesh.mesh3d_material_uniform_buf.as_ref(),
                                mesh3d_dummy_uniform_buf.as_ref(),
                                mesh3d_dummy_color_2d_view.as_ref(),
                                mesh3d_dummy_3d_view.as_ref(),
                                mesh3d_dummy_linear_sampler.as_ref(),
                                mesh3d_dummy_depth_cube_array_view.as_ref(),
                                mesh3d_dummy_depth_array_view.as_ref(),
                                mesh3d_dummy_compare_sampler.as_ref(),
                            )
                            else {
                                continue;
                            };
                            let view_bytes = mesh3d_bevy_view_uniform_bytes(&pass.st);
                            self.queue.write_buffer(view_ubo, 0, view_bytes.as_slice());
                            let lights_bytes = mesh3d_bevy_lights_uniform_bytes(&pass.st);
                            self.queue
                                .write_buffer(lights_ubo, 0, lights_bytes.as_slice());
                            let clustered_lights_bytes =
                                mesh3d_bevy_clustered_lights_uniform_bytes(&pass.st, &draw);
                            self.queue.write_buffer(
                                clustered_lights_ubo,
                                0,
                                clustered_lights_bytes.as_slice(),
                            );
                            let cluster_index_lists_bytes =
                                mesh3d_bevy_cluster_index_lists_uniform_bytes(&pass.st);
                            self.queue.write_buffer(
                                cluster_index_lists_ubo,
                                0,
                                cluster_index_lists_bytes.as_slice(),
                            );
                            let cluster_offsets_bytes =
                                mesh3d_bevy_cluster_offsets_uniform_bytes(&pass.st);
                            self.queue.write_buffer(
                                cluster_offsets_ubo,
                                0,
                                cluster_offsets_bytes.as_slice(),
                            );
                            let mesh_bytes = mesh3d_bevy_mesh_uniform_bytes(&draw);
                            self.queue.write_buffer(mesh_ubo, 0, mesh_bytes.as_slice());
                            let material_bytes = mesh3d_bevy_material_uniform_bytes(&draw);
                            self.queue
                                .write_buffer(material_ubo, 0, material_bytes.as_slice());
                            let point_shadow_cube_view = if draw.point_shadow_enabled > 0.0
                                && draw.point_shadow_texture_id >= 0
                            {
                                self.textures
                                    .get(&draw.point_shadow_texture_id)
                                    .and_then(|tex| tex.point_shadow_depth_cube_array_view.as_ref())
                                    .unwrap_or(dummy_depth_cube_array_view)
                            } else {
                                dummy_depth_cube_array_view
                            };
                            let view_layout = pipeline.get_bind_group_layout(0);
                            let view_bg =
                                self.device.create_bind_group(&wgpu::BindGroupDescriptor {
                                    label: Some("mgstudio_mesh3d_view_bg_dynamic"),
                                    layout: &view_layout,
                                    entries: &[
                                        wgpu::BindGroupEntry {
                                            binding: 0,
                                            resource: view_ubo.as_entire_binding(),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 1,
                                            resource: lights_ubo.as_entire_binding(),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 2,
                                            resource: wgpu::BindingResource::TextureView(
                                                point_shadow_cube_view,
                                            ),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 3,
                                            resource: wgpu::BindingResource::Sampler(
                                                dummy_compare_sampler,
                                            ),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 5,
                                            resource: wgpu::BindingResource::TextureView(
                                                dummy_depth_array_view,
                                            ),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 6,
                                            resource: wgpu::BindingResource::Sampler(
                                                dummy_compare_sampler,
                                            ),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 8,
                                            resource: clustered_lights_ubo.as_entire_binding(),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 9,
                                            resource: cluster_index_lists_ubo.as_entire_binding(),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 10,
                                            resource: cluster_offsets_ubo.as_entire_binding(),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 11,
                                            resource: dummy_uniform_buf.as_entire_binding(),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 12,
                                            resource: dummy_uniform_buf.as_entire_binding(),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 13,
                                            resource: dummy_uniform_buf.as_entire_binding(),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 14,
                                            resource: dummy_uniform_buf.as_entire_binding(),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 15,
                                            resource: dummy_uniform_buf.as_entire_binding(),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 16,
                                            resource: dummy_uniform_buf.as_entire_binding(),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 17,
                                            resource: wgpu::BindingResource::TextureView(
                                                dummy_color_2d_view,
                                            ),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 18,
                                            resource: dummy_uniform_buf.as_entire_binding(),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 19,
                                            resource: wgpu::BindingResource::TextureView(
                                                dummy_3d_view,
                                            ),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 20,
                                            resource: wgpu::BindingResource::Sampler(
                                                dummy_linear_sampler,
                                            ),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 25,
                                            resource: wgpu::BindingResource::TextureView(
                                                dummy_color_2d_view,
                                            ),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 26,
                                            resource: wgpu::BindingResource::Sampler(
                                                dummy_linear_sampler,
                                            ),
                                        },
                                    ],
                                });
                            rp.set_pipeline(pipeline);
                            rp.set_scissor_rect(sx, sy, sw, sh);
                            rp.set_bind_group(0, &view_bg, &[]);
                            rp.set_bind_group(1, view_env_bg, &[]);
                            rp.set_bind_group(2, mesh_bg, &[]);
                            rp.set_bind_group(3, material_bg, &[]);
                        } else {
                            let (Some(pipeline), Some(bg)) = (pipeline, mesh_bg_2d.as_ref()) else {
                                continue;
                            };
                            rp.set_pipeline(pipeline);
                            rp.set_scissor_rect(sx, sy, sw, sh);
                            rp.set_bind_group(0, bg, &[draw.ubo_offset]);
                            let Some(tex) = self.textures.get(&draw.texture_id) else {
                                continue;
                            };
                            rp.set_bind_group(1, &tex.bind_group, &[]);
                        }
                        rp.set_vertex_buffer(0, mesh.vertex_buf.slice(..));
                        rp.set_index_buffer(mesh.index_buf.slice(..), wgpu::IndexFormat::Uint16);
                        rp.draw_indexed(0..mesh.index_count, 0, 0..1);
                    }
                    DrawCmd::MotionBlur(draw) => {
                        let (Some(pipeline), Some(layout), Some(settings_buf), Some(globals_buf)) = (
                            motion_blur_pipeline.as_ref(),
                            motion_blur_bgl.as_ref(),
                            self.mesh.motion_blur_settings_buf.as_ref().cloned(),
                            self.mesh.motion_blur_globals_buf.as_ref().cloned(),
                        ) else {
                            continue;
                        };
                        let Some(scene_tex) = self.textures.get(&draw.scene_texture_id) else {
                            continue;
                        };
                        let Some(velocity_tex) = self.textures.get(&draw.velocity_texture_id)
                        else {
                            continue;
                        };
                        let Some((sx, sy, sw, sh)) = resolve_scissor_rect(
                            &pass.st,
                            draw.scissor,
                            target_width,
                            target_height,
                        ) else {
                            continue;
                        };
                        let clamped_samples = draw.samples.clamp(0, 64);
                        let settings_words: [u32; 4] =
                            [draw.shutter_angle.to_bits(), clamped_samples as u32, 0, 0];
                        self.queue.write_buffer(
                            &settings_buf,
                            0,
                            bytemuck::cast_slice(&settings_words),
                        );
                        let globals_words: [u32; 4] =
                            [0f32.to_bits(), 0f32.to_bits(), self.frame_count, 0];
                        self.queue.write_buffer(
                            &globals_buf,
                            0,
                            bytemuck::cast_slice(&globals_words),
                        );

                        let Some(depth_view) = self.last_depth_view.as_ref() else {
                            continue;
                        };

                        let bind_group =
                            self.device.create_bind_group(&wgpu::BindGroupDescriptor {
                                label: Some("mgstudio-motion-blur-bg"),
                                layout,
                                entries: &[
                                    wgpu::BindGroupEntry {
                                        binding: 0,
                                        resource: wgpu::BindingResource::TextureView(
                                            &scene_tex.view,
                                        ),
                                    },
                                    wgpu::BindGroupEntry {
                                        binding: 1,
                                        resource: wgpu::BindingResource::TextureView(
                                            &velocity_tex.view,
                                        ),
                                    },
                                    wgpu::BindGroupEntry {
                                        binding: 2,
                                        resource: wgpu::BindingResource::TextureView(depth_view),
                                    },
                                    wgpu::BindGroupEntry {
                                        binding: 3,
                                        resource: wgpu::BindingResource::Sampler(
                                            &scene_tex.sampler,
                                        ),
                                    },
                                    wgpu::BindGroupEntry {
                                        binding: 4,
                                        resource: settings_buf.as_entire_binding(),
                                    },
                                    wgpu::BindGroupEntry {
                                        binding: 5,
                                        resource: globals_buf.as_entire_binding(),
                                    },
                                ],
                            });
                        rp.set_pipeline(pipeline);
                        rp.set_scissor_rect(sx, sy, sw, sh);
                        rp.set_bind_group(0, &bind_group, &[]);
                        rp.draw(0..3, 0..1);
                    }
                    DrawCmd::Bloom2d(draw) => {
                        let (Some(pipeline), Some(layout), Some(settings_buf), Some(bloom_sampler)) = (
                            bloom2d_pipeline.as_ref(),
                            bloom2d_bgl.as_ref(),
                            self.mesh.bloom2d_settings_buf.as_ref().cloned(),
                            self.mesh.bloom2d_sampler.as_ref().cloned(),
                        ) else {
                            continue;
                        };
                        let Some(scene_tex) = self.textures.get(&draw.scene_texture_id) else {
                            continue;
                        };
                        let scene_width = scene_tex.width;
                        let scene_height = scene_tex.height;
                        let scene_view = scene_tex.view.clone();
                        let selected_lut_texture_id = match draw.tonemapping_mode {
                            4 => draw.agx_lut_texture_id,
                            6 => draw.tony_lut_texture_id,
                            7 => draw.blender_lut_texture_id,
                            _ => -1,
                        };
                        let lut_view = self
                            .textures
                            .get(&selected_lut_texture_id)
                            .map(|tex| tex.view.clone())
                            .unwrap_or_else(|| scene_view.clone());

                        drop(rp);
                        self.encode_bloom2d_multipass(
                            &mut frame.encoder,
                            &pass.st,
                            &target_view,
                            target_width,
                            target_height,
                            &draw,
                            pipeline,
                            layout,
                            &settings_buf,
                            &bloom_sampler,
                            &scene_view,
                            &lut_view,
                            scene_width,
                            scene_height,
                        )?;

                        let resumed_depth_attachment = depth_view.as_ref().map(|view| {
                            wgpu::RenderPassDepthStencilAttachment {
                                view,
                                depth_ops: Some(wgpu::Operations {
                                    load: wgpu::LoadOp::Clear(0.0),
                                    store: wgpu::StoreOp::Store,
                                }),
                                stencil_ops: None,
                            }
                        });
                        rp = frame
                            .encoder
                            .begin_render_pass(&wgpu::RenderPassDescriptor {
                                label: Some("mgstudio-pass"),
                                color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                                    view: &target_view,
                                    depth_slice: None,
                                    resolve_target: None,
                                    ops: wgpu::Operations {
                                        load: wgpu::LoadOp::Load,
                                        store: wgpu::StoreOp::Store,
                                    },
                                })],
                                depth_stencil_attachment: resumed_depth_attachment,
                                timestamp_writes: None,
                                occlusion_query_set: None,
                                multiview_mask: None,
                            });
                        rp.set_viewport(
                            pass.st.viewport_x as f32,
                            pass.st.viewport_y as f32,
                            pass.st.viewport_w as f32,
                            pass.st.viewport_h as f32,
                            pass.st.viewport_depth_min,
                            pass.st.viewport_depth_max,
                        );
                    }
                }
            }
        }

        // Keep depth view alive until encoding is finished.
        let _ = depth_view;

        self.frame = Some(frame);
        Ok(())
    }

    pub fn draw_sprite_uv(
        &mut self,
        texture_id: i32,
        x: f32,
        y: f32,
        rotation: f32,
        scale_x: f32,
        scale_y: f32,
        color: [f32; 4],
        uv_min: (f32, f32),
        uv_max: (f32, f32),
    ) -> anyhow::Result<()> {
        if self.frame.is_none() {
            return Ok(());
        }

        let Some(tex_id) = self.resolve_draw_texture_id(texture_id)? else {
            return Ok(());
        };
        let (tex_w, tex_h) = match self.textures.get(&tex_id) {
            Some(t) => (t.width, t.height),
            None => return Ok(()),
        };

        let Some(pass) = self.pass.as_mut() else {
            return Ok(());
        };
        if pass.cur_sprites.instance_count == 0 {
            pass.cur_sprites.scissor = pass.current_scissor;
        } else if pass.cur_sprites.scissor != pass.current_scissor {
            pass.flush_sprites();
            pass.cur_sprites.scissor = pass.current_scissor;
        }

        // Match native runtime's sprite sizing convention (base quad is 128x128).
        let raw_uv_scale_x = uv_max.0 - uv_min.0;
        let raw_uv_scale_y = uv_max.1 - uv_min.1;
        let uv_scale_x = if raw_uv_scale_x <= 0.0 {
            1.0
        } else {
            raw_uv_scale_x
        };
        let uv_scale_y = if raw_uv_scale_y <= 0.0 {
            1.0
        } else {
            raw_uv_scale_y
        };
        let region_w = tex_w as f32 * uv_scale_x;
        let region_h = tex_h as f32 * uv_scale_y;
        let base_size = 128.0f32;
        let tex_scale_x = if region_w > 0.0 {
            region_w / base_size
        } else {
            1.0
        };
        let tex_scale_y = if region_h > 0.0 {
            region_h / base_size
        } else {
            1.0
        };
        let sprite_scale_x = scale_x * tex_scale_x;
        let sprite_scale_y = scale_y * tex_scale_y;

        let cosv = rotation.cos();
        let sinv = rotation.sin();

        let first_instance = pass.cur_sprites.instance_count;
        pass.cur_sprites.instance_count = first_instance + 1;

        // Instance layout: model(x,y,cos,sin), scale(x,y,_,_), color, uv(min_x,min_y,scale_x,scale_y)
        pass.cur_sprites.instance_data.extend_from_slice(&[
            x,
            y,
            cosv,
            sinv,
            sprite_scale_x,
            sprite_scale_y,
            0.0,
            0.0,
            color[0],
            color[1],
            color[2],
            color[3],
            uv_min.0,
            uv_min.1,
            uv_scale_x,
            uv_scale_y,
        ]);

        if let Some(last) = pass.cur_sprites.batches.last_mut() {
            if last.texture_id == tex_id {
                last.instance_count += 1;
                return Ok(());
            }
        }
        pass.cur_sprites.batches.push(SpriteBatch {
            texture_id: tex_id,
            first_instance,
            instance_count: 1,
        });
        Ok(())
    }

    pub fn draw_mesh(
        &mut self,
        mesh_id: i32,
        x: f32,
        y: f32,
        rotation: f32,
        scale_x: f32,
        scale_y: f32,
        color: [f32; 4],
        texture_id: i32,
        uv_offset: (f32, f32),
        uv_scale: (f32, f32),
    ) -> anyhow::Result<()> {
        if self.frame.is_none() {
            return Ok(());
        }
        let textured = texture_id >= 0;
        let requested_texture_id = if textured { texture_id } else { -1 };
        let Some(resolved_texture_id) = self.resolve_draw_texture_id(requested_texture_id)? else {
            return Ok(());
        };
        let uv_offset = if textured {
            [uv_offset.0, uv_offset.1]
        } else {
            [0.0, 0.0]
        };
        let uv_scale = if textured {
            [uv_scale.0, uv_scale.1]
        } else {
            [-1.0, -1.0]
        };
        let Some(resolved_transmission_source_texture_id) = self.resolve_draw_texture_id(-1)?
        else {
            return Ok(());
        };
        let Some(pass) = self.pass.as_mut() else {
            return Ok(());
        };
        pass.flush_sprites();
        pass.commands.push(DrawCmd::Mesh(MeshDraw {
            mesh_id,
            is_3d: false,
            x,
            y,
            z: 0.0,
            rotation,
            rotation_quat: [0.0, 0.0, 0.0, 1.0],
            scale_x,
            scale_y,
            scale_z: 1.0,
            cull_mode: 2,
            previous_x: x,
            previous_y: y,
            previous_z: 0.0,
            previous_rotation_quat: [0.0, 0.0, 0.0, 1.0],
            previous_scale_x: scale_x,
            previous_scale_y: scale_y,
            previous_scale_z: 1.0,
            color,
            texture_id: resolved_texture_id,
            normal_texture_id: resolved_texture_id,
            emissive_texture_id: resolved_texture_id,
            metallic_roughness_texture_id: resolved_texture_id,
            occlusion_texture_id: resolved_texture_id,
            depth_texture_id: resolved_texture_id,
            anisotropy_texture_id: resolved_texture_id,
            specular_tint_texture_id: resolved_texture_id,
            uv_offset,
            uv_scale,
            map_flags: [if textured { 1.0 } else { 0.0 }, 0.0, 0.0, 0.0],
            emissive: [0.0, 0.0, 0.0],
            unlit: 0.0,
            metallic: 0.0,
            roughness: 0.5,
            reflectance: 0.5,
            normal_map_flag: 0.0,
            parallax_depth_scale: 0.0,
            max_parallax_layer_count: 0.0,
            max_relief_mapping_search_steps: 0.0,
            depth_map_flag: 0.0,
            anisotropy_strength: 0.0,
            anisotropy_rotation_cos: 1.0,
            anisotropy_rotation_sin: 0.0,
            anisotropy_map_flag: 0.0,
            specular_tint: [1.0, 1.0, 1.0],
            specular_tint_map_flag: 0.0,
            diffuse_transmission: 0.0,
            specular_transmission: 0.0,
            thickness: 0.0,
            ior: 1.5,
            transmission_source_texture_id: resolved_transmission_source_texture_id,
            transmission_blur_taps: 0.0,
            transmission_steps: 0.0,
            point_shadow_texture_id: resolved_transmission_source_texture_id,
            point_shadow_enabled: 0.0,
            point_shadow_depth_bias: 0.0,
            ubo_offset: 0,
            scissor: pass.current_scissor,
        }));
        Ok(())
    }

    pub fn draw_mesh3d(
        &mut self,
        mesh_id: i32,
        x: f32,
        y: f32,
        z: f32,
        rotation_x: f32,
        rotation_y: f32,
        rotation_z: f32,
        rotation_w: f32,
        scale_x: f32,
        scale_y: f32,
        scale_z: f32,
        previous_x: f32,
        previous_y: f32,
        previous_z: f32,
        previous_rotation_x: f32,
        previous_rotation_y: f32,
        previous_rotation_z: f32,
        previous_rotation_w: f32,
        previous_scale_x: f32,
        previous_scale_y: f32,
        previous_scale_z: f32,
        color: [f32; 4],
        texture_id: i32,
        uv_offset: (f32, f32),
        uv_scale: (f32, f32),
        normal_texture_id: i32,
        emissive_texture_id: i32,
        metallic_roughness_texture_id: i32,
        occlusion_texture_id: i32,
        depth_texture_id: i32,
        emissive: [f32; 3],
        unlit: f32,
        metallic: f32,
        roughness: f32,
        reflectance: f32,
        parallax_depth_scale: f32,
        max_parallax_layer_count: f32,
        max_relief_mapping_search_steps: f32,
        anisotropy_texture_id: i32,
        anisotropy_strength: f32,
        anisotropy_rotation: f32,
        specular_tint_texture_id: i32,
        specular_tint: [f32; 3],
        diffuse_transmission: f32,
        specular_transmission: f32,
        thickness: f32,
        ior: f32,
        transmission_source_texture_id: i32,
        transmission_blur_taps: f32,
        transmission_steps: f32,
        point_shadow_texture_id: i32,
        point_shadow_enabled: f32,
        point_shadow_depth_bias: f32,
        cull_mode: i32,
    ) -> anyhow::Result<()> {
        if self.frame.is_none() {
            return Ok(());
        }
        let textured = texture_id >= 0;
        let Some(resolved_texture_id) = self.resolve_draw_texture_id(texture_id)? else {
            return Ok(());
        };
        let normal_textured = normal_texture_id >= 0;
        let Some(resolved_normal_texture_id) = self.resolve_draw_texture_id(normal_texture_id)?
        else {
            return Ok(());
        };
        let emissive_textured = emissive_texture_id >= 0;
        let Some(resolved_emissive_texture_id) =
            self.resolve_draw_texture_id(emissive_texture_id)?
        else {
            return Ok(());
        };
        let metallic_roughness_textured = metallic_roughness_texture_id >= 0;
        let Some(resolved_metallic_roughness_texture_id) =
            self.resolve_draw_texture_id(metallic_roughness_texture_id)?
        else {
            return Ok(());
        };
        let occlusion_textured = occlusion_texture_id >= 0;
        let Some(resolved_occlusion_texture_id) =
            self.resolve_draw_texture_id(occlusion_texture_id)?
        else {
            return Ok(());
        };
        let depth_textured = depth_texture_id >= 0;
        let Some(resolved_depth_texture_id) = self.resolve_draw_texture_id(depth_texture_id)?
        else {
            return Ok(());
        };
        let anisotropy_textured = anisotropy_texture_id >= 0;
        let Some(resolved_anisotropy_texture_id) =
            self.resolve_draw_texture_id(anisotropy_texture_id)?
        else {
            return Ok(());
        };
        let specular_tint_textured = specular_tint_texture_id >= 0;
        let Some(resolved_specular_tint_texture_id) =
            self.resolve_draw_texture_id(specular_tint_texture_id)?
        else {
            return Ok(());
        };
        let transmission_source_textured = transmission_source_texture_id >= 0;
        let Some(resolved_transmission_source_texture_id) =
            self.resolve_draw_texture_id(transmission_source_texture_id)?
        else {
            return Ok(());
        };
        let point_shadow_textured = point_shadow_texture_id >= 0;
        let Some(resolved_point_shadow_texture_id) =
            self.resolve_draw_texture_id(point_shadow_texture_id)?
        else {
            return Ok(());
        };
        let uv_offset = if textured {
            [uv_offset.0, uv_offset.1]
        } else {
            [0.0, 0.0]
        };
        let uv_scale = if textured {
            [uv_scale.0, uv_scale.1]
        } else {
            [-1.0, -1.0]
        };
        let Some(pass) = self.pass.as_mut() else {
            return Ok(());
        };
        if !pass_kind_decal_enabled(pass.st.pass_kind) && mesh3d_draw_is_decal(cull_mode) {
            return Ok(());
        }
        if !pass_kind_fog_enabled(pass.st.pass_kind) && mesh3d_draw_is_fog(cull_mode) {
            return Ok(());
        }
        if !pass_kind_postprocess_enabled(pass.st.pass_kind)
            && mesh3d_draw_is_postprocess_proxy(cull_mode)
        {
            return Ok(());
        }
        pass.flush_sprites();
        pass.commands.push(DrawCmd::Mesh(MeshDraw {
            mesh_id,
            is_3d: true,
            x,
            y,
            z,
            rotation: 0.0,
            rotation_quat: [rotation_x, rotation_y, rotation_z, rotation_w],
            scale_x,
            scale_y,
            scale_z,
            cull_mode: mesh3d_cull_mode_sanitize(cull_mode),
            previous_x,
            previous_y,
            previous_z,
            previous_rotation_quat: [
                previous_rotation_x,
                previous_rotation_y,
                previous_rotation_z,
                previous_rotation_w,
            ],
            previous_scale_x,
            previous_scale_y,
            previous_scale_z,
            color,
            texture_id: resolved_texture_id,
            normal_texture_id: resolved_normal_texture_id,
            emissive_texture_id: resolved_emissive_texture_id,
            metallic_roughness_texture_id: resolved_metallic_roughness_texture_id,
            occlusion_texture_id: resolved_occlusion_texture_id,
            depth_texture_id: resolved_depth_texture_id,
            anisotropy_texture_id: resolved_anisotropy_texture_id,
            specular_tint_texture_id: resolved_specular_tint_texture_id,
            uv_offset,
            uv_scale,
            map_flags: [
                if textured { 1.0 } else { 0.0 },
                if emissive_textured { 1.0 } else { 0.0 },
                if metallic_roughness_textured {
                    1.0
                } else {
                    0.0
                },
                if occlusion_textured { 1.0 } else { 0.0 },
            ],
            emissive,
            unlit,
            metallic,
            roughness,
            reflectance,
            normal_map_flag: if normal_textured { 1.0 } else { 0.0 },
            parallax_depth_scale,
            max_parallax_layer_count,
            max_relief_mapping_search_steps,
            depth_map_flag: if depth_textured { 1.0 } else { 0.0 },
            anisotropy_strength,
            anisotropy_rotation_cos: anisotropy_rotation.cos(),
            anisotropy_rotation_sin: anisotropy_rotation.sin(),
            anisotropy_map_flag: if anisotropy_textured { 1.0 } else { 0.0 },
            specular_tint,
            specular_tint_map_flag: if specular_tint_textured { 1.0 } else { 0.0 },
            diffuse_transmission,
            specular_transmission,
            thickness,
            ior,
            transmission_source_texture_id: resolved_transmission_source_texture_id,
            transmission_blur_taps: if transmission_source_textured {
                transmission_blur_taps
            } else {
                0.0
            },
            transmission_steps: if transmission_source_textured {
                transmission_steps
            } else {
                0.0
            },
            point_shadow_texture_id: resolved_point_shadow_texture_id,
            point_shadow_enabled: if point_shadow_textured {
                point_shadow_enabled
            } else {
                0.0
            },
            point_shadow_depth_bias: if point_shadow_textured {
                point_shadow_depth_bias
            } else {
                0.0
            },
            ubo_offset: 0,
            scissor: pass.current_scissor,
        }));
        Ok(())
    }

    pub fn draw_motion_blur(
        &mut self,
        scene_texture_id: i32,
        velocity_texture_id: i32,
        shutter_angle: f32,
        samples: i32,
    ) -> anyhow::Result<()> {
        if self.frame.is_none() {
            return Ok(());
        }
        if scene_texture_id < 0 || velocity_texture_id < 0 {
            return Ok(());
        }
        let Some(pass) = self.pass.as_mut() else {
            return Ok(());
        };
        pass.flush_sprites();
        pass.commands.push(DrawCmd::MotionBlur(MotionBlurDraw {
            scene_texture_id,
            velocity_texture_id,
            shutter_angle,
            samples,
            scissor: pass.current_scissor,
        }));
        Ok(())
    }

    pub fn draw_bloom2d(
        &mut self,
        scene_texture_id: i32,
        enabled: i32,
        intensity: f32,
        low_frequency_boost: f32,
        low_frequency_boost_curvature: f32,
        high_pass_frequency: f32,
        threshold: f32,
        threshold_softness: f32,
        composite_mode: i32,
        max_mip_dimension: i32,
        scale_x: f32,
        scale_y: f32,
        tonemapping_mode: i32,
        deband_dither_enabled: i32,
        view_width: i32,
        view_height: i32,
        agx_lut_texture_id: i32,
        tony_lut_texture_id: i32,
        blender_lut_texture_id: i32,
        fxaa_enabled: i32,
        fxaa_edge_threshold: f32,
        chromatic_aberration_strength: f32,
        vignette_strength: f32,
    ) -> anyhow::Result<()> {
        if self.frame.is_none() {
            return Ok(());
        }
        if scene_texture_id < 0 {
            return Ok(());
        }
        let Some(pass) = self.pass.as_mut() else {
            return Ok(());
        };
        pass.flush_sprites();
        pass.commands.push(DrawCmd::Bloom2d(Bloom2dDraw {
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
            fxaa_enabled,
            fxaa_edge_threshold,
            chromatic_aberration_strength,
            vignette_strength,
            scissor: pass.current_scissor,
        }));
        Ok(())
    }

    pub fn set_scissor(&mut self, x: i32, y: i32, width: i32, height: i32) {
        let Some(pass) = self.pass.as_mut() else {
            return;
        };
        let next = if width <= 0 || height <= 0 {
            None
        } else {
            Some(ScissorRect {
                x: x.max(0) as u32,
                y: y.max(0) as u32,
                w: width.max(0) as u32,
                h: height.max(0) as u32,
            })
        };
        if pass.current_scissor != next {
            pass.flush_sprites();
            pass.current_scissor = next;
        }
    }

    pub fn clear_scissor(&mut self) {
        let Some(pass) = self.pass.as_mut() else {
            return;
        };
        if pass.current_scissor.is_some() {
            pass.flush_sprites();
            pass.current_scissor = None;
        }
    }

    pub fn create_mesh_rectangle(&mut self, width: f32, height: f32) -> i32 {
        let id = self.next_mesh_id;
        self.next_mesh_id += 1;
        let hw = width * 0.5;
        let hh = height * 0.5;
        let vertices: [f32; 32] = [
            -hw, -hh, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, //
            hw, -hh, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, //
            hw, hh, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, //
            -hw, hh, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, //
        ];
        let indices: [u16; 6] = [0, 1, 2, 0, 2, 3];

        let vb = self
            .device
            .create_buffer_init(&wgpu::util::BufferInitDescriptor {
                label: Some("mgstudio-mesh-rect-vb"),
                contents: bytemuck::cast_slice(&vertices),
                usage: wgpu::BufferUsages::VERTEX | wgpu::BufferUsages::COPY_DST,
            });
        let ib = self
            .device
            .create_buffer_init(&wgpu::util::BufferInitDescriptor {
                label: Some("mgstudio-mesh-rect-ib"),
                contents: bytemuck::cast_slice(&indices),
                usage: wgpu::BufferUsages::INDEX | wgpu::BufferUsages::COPY_DST,
            });
        self.meshes.insert(
            id,
            GpuMesh {
                vertex_count: 4,
                index_count: 6,
                layout: MeshVertexLayout::XyUvRgba,
                primitive_topology: wgpu::PrimitiveTopology::TriangleList,
                vertex_buf: vb,
                index_buf: ib,
            },
        );
        id
    }

    pub fn create_mesh_capsule(&mut self, radius: f32, half_length: f32, segments: i32) -> i32 {
        let r = radius.max(0.5);
        let hl = half_length.max(0.0);
        let seg = segments.max(4);
        let mut boundary: Vec<(f32, f32)> = Vec::with_capacity((seg as usize + 1) * 2);
        for i in 0..=seg {
            let t = -std::f32::consts::FRAC_PI_2 + (i as f32 / seg as f32) * std::f32::consts::PI;
            boundary.push((hl + r * t.cos(), r * t.sin()));
        }
        for i in 0..=seg {
            let t = std::f32::consts::FRAC_PI_2 + (i as f32 / seg as f32) * std::f32::consts::PI;
            boundary.push((-hl + r * t.cos(), r * t.sin()));
        }
        if boundary.len() < 3 {
            return self.create_mesh_rectangle((hl + r) * 2.0, r * 2.0);
        }
        let total_w = ((hl + r) * 2.0).max(1e-6);
        let total_h = (r * 2.0).max(1e-6);
        let mut verts: Vec<f32> = Vec::with_capacity((boundary.len() - 1) * 3 * 8);
        for i in 0..(boundary.len() - 1) {
            let p0 = (0.0f32, 0.0f32);
            let p1 = boundary[i];
            let p2 = boundary[i + 1];
            for (x, y) in [p0, p1, p2] {
                let u = (x + hl + r) / total_w;
                let v = (y + r) / total_h;
                verts.extend_from_slice(&[x, y, u, v, 1.0, 1.0, 1.0, 1.0]);
            }
        }
        self.create_mesh_triangles_xyuvrgba(verts.as_slice())
    }

    pub fn create_mesh_triangles_xyuvrgba(&mut self, vertices: &[f32]) -> i32 {
        let vcount = vertices.len() / 8;
        if vcount == 0 {
            return 0;
        }
        let usable_vcount = vcount - (vcount % 3);
        if usable_vcount == 0 || usable_vcount > 65535 {
            return 0;
        }
        let trimmed = &vertices[..usable_vcount * 8];
        let mut indices: Vec<u16> = Vec::with_capacity(usable_vcount);
        for i in 0..usable_vcount {
            indices.push(i as u16);
        }
        let id = self.next_mesh_id;
        self.next_mesh_id += 1;
        let vb = self
            .device
            .create_buffer_init(&wgpu::util::BufferInitDescriptor {
                label: Some("mgstudio-mesh-tris-vb"),
                contents: bytemuck::cast_slice(trimmed),
                usage: wgpu::BufferUsages::VERTEX | wgpu::BufferUsages::COPY_DST,
            });
        let ib = self
            .device
            .create_buffer_init(&wgpu::util::BufferInitDescriptor {
                label: Some("mgstudio-mesh-tris-ib"),
                contents: bytemuck::cast_slice(indices.as_slice()),
                usage: wgpu::BufferUsages::INDEX | wgpu::BufferUsages::COPY_DST,
            });
        self.meshes.insert(
            id,
            GpuMesh {
                vertex_count: usable_vcount as u32,
                index_count: usable_vcount as u32,
                layout: MeshVertexLayout::XyUvRgba,
                primitive_topology: wgpu::PrimitiveTopology::TriangleList,
                vertex_buf: vb,
                index_buf: ib,
            },
        );
        id
    }

    pub fn create_mesh3d_xyzuvrgba(
        &mut self,
        vertices: &[f32],
        primitive_topology_kind: i32,
    ) -> i32 {
        let primitive_topology = mesh3d_topology_from_kind(primitive_topology_kind);
        let vcount = vertices.len() / 9;
        if vcount == 0 {
            return 0;
        }
        let usable_vcount = if primitive_topology == wgpu::PrimitiveTopology::TriangleList {
            vcount - (vcount % 3)
        } else if primitive_topology == wgpu::PrimitiveTopology::LineList {
            vcount - (vcount % 2)
        } else if vcount < 2 {
            0
        } else {
            vcount
        };
        if usable_vcount == 0 || usable_vcount > 65535 {
            return 0;
        }
        let trimmed = &vertices[..usable_vcount * 9];
        let mut converted: Vec<f32> = vec![0.0; usable_vcount * 6];
        for i in 0..usable_vcount {
            let src = i * 9;
            let dst = i * 6;
            converted[dst] = trimmed[src];
            converted[dst + 1] = trimmed[src + 1];
            converted[dst + 2] = trimmed[src + 2];
            converted[dst + 3] = 0.0;
            converted[dst + 4] = 0.0;
            converted[dst + 5] = 1.0;
        }
        if primitive_topology == wgpu::PrimitiveTopology::TriangleList {
            let mut tri = 0usize;
            while tri + 2 < usable_vcount {
                let a = tri * 6;
                let b = (tri + 1) * 6;
                let c = (tri + 2) * 6;
                let p0 = [converted[a], converted[a + 1], converted[a + 2]];
                let p1 = [converted[b], converted[b + 1], converted[b + 2]];
                let p2 = [converted[c], converted[c + 1], converted[c + 2]];
                let e1 = [p1[0] - p0[0], p1[1] - p0[1], p1[2] - p0[2]];
                let e2 = [p2[0] - p0[0], p2[1] - p0[1], p2[2] - p0[2]];
                let mut n = [
                    e1[1] * e2[2] - e1[2] * e2[1],
                    e1[2] * e2[0] - e1[0] * e2[2],
                    e1[0] * e2[1] - e1[1] * e2[0],
                ];
                let len = (n[0] * n[0] + n[1] * n[1] + n[2] * n[2]).sqrt();
                if len > 1.0e-8 {
                    n[0] /= len;
                    n[1] /= len;
                    n[2] /= len;
                } else {
                    n = [0.0, 0.0, 1.0];
                }
                for vi in 0..3 {
                    let d = (tri + vi) * 6 + 3;
                    converted[d] = n[0];
                    converted[d + 1] = n[1];
                    converted[d + 2] = n[2];
                }
                tri += 3;
            }
        }
        let mut indices: Vec<u16> = Vec::with_capacity(usable_vcount);
        for i in 0..usable_vcount {
            indices.push(i as u16);
        }
        let id = self.next_mesh_id;
        self.next_mesh_id += 1;
        let vb = self
            .device
            .create_buffer_init(&wgpu::util::BufferInitDescriptor {
                label: Some("mgstudio-mesh3d-tris-vb"),
                contents: bytemuck::cast_slice(converted.as_slice()),
                usage: wgpu::BufferUsages::VERTEX | wgpu::BufferUsages::COPY_DST,
            });
        let ib = self
            .device
            .create_buffer_init(&wgpu::util::BufferInitDescriptor {
                label: Some("mgstudio-mesh3d-tris-ib"),
                contents: bytemuck::cast_slice(indices.as_slice()),
                usage: wgpu::BufferUsages::INDEX | wgpu::BufferUsages::COPY_DST,
            });
        self.meshes.insert(
            id,
            GpuMesh {
                vertex_count: usable_vcount as u32,
                index_count: usable_vcount as u32,
                layout: MeshVertexLayout::XyzNormal,
                primitive_topology,
                vertex_buf: vb,
                index_buf: ib,
            },
        );
        id
    }

    pub fn create_texture_rgba8(
        &mut self,
        width: u32,
        height: u32,
        pixels_rgba8: &[u8],
        nearest: bool,
    ) -> anyhow::Result<i32> {
        self.create_texture_rgba8_mipped(width, height, 1, pixels_rgba8, nearest)
    }

    pub fn create_texture_rgba8_mipped(
        &mut self,
        width: u32,
        height: u32,
        mip_level_count: u32,
        pixels_rgba8: &[u8],
        nearest: bool,
    ) -> anyhow::Result<i32> {
        self.ensure_sprite_resources()?;
        let id = self.next_texture_id;
        self.next_texture_id += 1;
        self.create_texture_rgba8_with_id(
            id,
            width,
            height,
            mip_level_count,
            pixels_rgba8,
            nearest,
            false,
        )?;
        Ok(id)
    }

    pub fn create_texture_stacked_2d_with_format(
        &mut self,
        width: u32,
        height_per_slice: u32,
        slice_count: u32,
        format: wgpu::TextureFormat,
        levels: &[Vec<u8>],
        nearest: bool,
    ) -> anyhow::Result<i32> {
        self.ensure_sprite_resources()?;
        if levels.is_empty() {
            return Err(anyhow!("wgpu: no mip levels provided for texture upload"));
        }
        let block_info = texture_block_info(format)
            .ok_or_else(|| anyhow!("wgpu: unsupported texture format for upload: {format:?}"))?;

        let id = self.next_texture_id;
        self.next_texture_id += 1;
        let width = width.max(1);
        let height_per_slice = height_per_slice.max(1);
        let slice_count = slice_count.max(1);
        let height = height_per_slice
            .checked_mul(slice_count)
            .ok_or_else(|| anyhow!("wgpu: stacked texture height overflow"))?;
        let usage = wgpu::TextureUsages::TEXTURE_BINDING | wgpu::TextureUsages::COPY_DST;
        let texture = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some("mgstudio-texture-stacked"),
            size: wgpu::Extent3d {
                width,
                height,
                depth_or_array_layers: 1,
            },
            mip_level_count: levels.len() as u32,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format,
            usage,
            view_formats: &[],
        });
        let view = texture.create_view(&wgpu::TextureViewDescriptor::default());
        let sampler = if nearest {
            self.device.create_sampler(&wgpu::SamplerDescriptor {
                label: Some("mgstudio-sampler-nearest"),
                mag_filter: wgpu::FilterMode::Nearest,
                min_filter: wgpu::FilterMode::Nearest,
                mipmap_filter: wgpu::MipmapFilterMode::Nearest,
                address_mode_u: wgpu::AddressMode::ClampToEdge,
                address_mode_v: wgpu::AddressMode::ClampToEdge,
                address_mode_w: wgpu::AddressMode::ClampToEdge,
                ..Default::default()
            })
        } else {
            self.device.create_sampler(&wgpu::SamplerDescriptor {
                label: Some("mgstudio-sampler-linear"),
                mag_filter: wgpu::FilterMode::Linear,
                min_filter: wgpu::FilterMode::Linear,
                mipmap_filter: wgpu::MipmapFilterMode::Linear,
                address_mode_u: wgpu::AddressMode::ClampToEdge,
                address_mode_v: wgpu::AddressMode::ClampToEdge,
                address_mode_w: wgpu::AddressMode::ClampToEdge,
                ..Default::default()
            })
        };

        let bgl_tex = self
            .sprite
            .bgl_tex
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: sprite texture bind group layout not initialized"))?;
        let bind_group = self.device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("mgstudio-sprite-tex"),
            layout: bgl_tex,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: wgpu::BindingResource::Sampler(&sampler),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: wgpu::BindingResource::TextureView(&view),
                },
            ],
        });

        for (level_index, level_data) in levels.iter().enumerate() {
            let mip = level_index as u32;
            let level_width = (width >> mip).max(1);
            let level_slice_height = (height_per_slice >> mip).max(1);
            let level_height = level_slice_height
                .checked_mul(slice_count)
                .ok_or_else(|| anyhow!("wgpu: stacked mip height overflow"))?;
            let (bytes_per_row, rows_per_image, expected_bytes) =
                block_info.layout(level_width, level_height)?;
            if level_data.len() < expected_bytes {
                return Err(anyhow!(
                    "wgpu: mip {mip} upload size mismatch: got {}, need at least {expected_bytes}",
                    level_data.len()
                ));
            }
            self.queue.write_texture(
                wgpu::TexelCopyTextureInfo {
                    texture: &texture,
                    mip_level: mip,
                    origin: wgpu::Origin3d::ZERO,
                    aspect: wgpu::TextureAspect::All,
                },
                &level_data[..expected_bytes],
                wgpu::TexelCopyBufferLayout {
                    offset: 0,
                    bytes_per_row: Some(bytes_per_row),
                    rows_per_image: Some(rows_per_image),
                },
                wgpu::Extent3d {
                    width: level_width,
                    height: level_height,
                    depth_or_array_layers: 1,
                },
            );
        }

        self.textures.insert(
            id,
            GpuTexture {
                width,
                height,
                format,
                texture,
                view,
                sampler,
                bind_group,
                point_shadow_depth_cube_array_view: None,
                point_shadow_depth_face_views: None,
                mip_level_count: levels.len() as u32,
                base_mip_level: 0,
                is_render_target: false,
            },
        );
        Ok(id)
    }

    pub fn create_render_target(
        &mut self,
        width: u32,
        height: u32,
        nearest: bool,
    ) -> anyhow::Result<i32> {
        self.create_render_target_with_format(
            width,
            height,
            nearest,
            wgpu::TextureFormat::Rgba8Unorm,
        )
    }

    pub fn create_render_target_rgba16f(
        &mut self,
        width: u32,
        height: u32,
        nearest: bool,
    ) -> anyhow::Result<i32> {
        self.create_render_target_with_format(
            width,
            height,
            nearest,
            wgpu::TextureFormat::Rgba16Float,
        )
    }

    pub fn create_point_light_shadow_target(&mut self, size: u32) -> anyhow::Result<i32> {
        self.ensure_sprite_resources()?;
        let id = self.next_texture_id;
        self.next_texture_id += 1;
        let size = size.max(1);
        let color_format = wgpu::TextureFormat::Rgba8Unorm;
        let color_usage = wgpu::TextureUsages::TEXTURE_BINDING
            | wgpu::TextureUsages::COPY_DST
            | wgpu::TextureUsages::RENDER_ATTACHMENT;
        let color_texture = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some("mgstudio-point-light-shadow-color"),
            size: wgpu::Extent3d {
                width: size,
                height: size,
                depth_or_array_layers: 1,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: color_format,
            usage: color_usage,
            view_formats: &[],
        });
        let color_view = color_texture.create_view(&wgpu::TextureViewDescriptor::default());

        let depth_texture = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some("mgstudio-point-light-shadow-depth-cube"),
            size: wgpu::Extent3d {
                width: size,
                height: size,
                depth_or_array_layers: 6,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Depth32Float,
            usage: wgpu::TextureUsages::TEXTURE_BINDING | wgpu::TextureUsages::RENDER_ATTACHMENT,
            view_formats: &[],
        });
        let depth_cube_array_view = depth_texture.create_view(&wgpu::TextureViewDescriptor {
            label: Some("mgstudio-point-light-shadow-depth-cube-array-view"),
            dimension: Some(wgpu::TextureViewDimension::CubeArray),
            base_array_layer: 0,
            array_layer_count: Some(6),
            ..Default::default()
        });
        let mut depth_face_views = Vec::with_capacity(6);
        for face in 0..6 {
            depth_face_views.push(depth_texture.create_view(&wgpu::TextureViewDescriptor {
                label: Some("mgstudio-point-light-shadow-depth-face-view"),
                dimension: Some(wgpu::TextureViewDimension::D2),
                base_array_layer: face,
                array_layer_count: Some(1),
                ..Default::default()
            }));
        }

        let sampler = self.device.create_sampler(&wgpu::SamplerDescriptor {
            label: Some("mgstudio-point-light-shadow-sampler-nearest"),
            mag_filter: wgpu::FilterMode::Nearest,
            min_filter: wgpu::FilterMode::Nearest,
            mipmap_filter: wgpu::MipmapFilterMode::Nearest,
            address_mode_u: wgpu::AddressMode::ClampToEdge,
            address_mode_v: wgpu::AddressMode::ClampToEdge,
            address_mode_w: wgpu::AddressMode::ClampToEdge,
            ..Default::default()
        });
        let bgl_tex = self
            .sprite
            .bgl_tex
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: sprite texture bind group layout not initialized"))?;
        let bind_group = self.device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("mgstudio-point-light-shadow-bind-group"),
            layout: bgl_tex,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: wgpu::BindingResource::Sampler(&sampler),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: wgpu::BindingResource::TextureView(&color_view),
                },
            ],
        });
        self.textures.insert(
            id,
            GpuTexture {
                width: size,
                height: size,
                format: color_format,
                texture: color_texture,
                view: color_view,
                sampler,
                bind_group,
                point_shadow_depth_cube_array_view: Some(depth_cube_array_view),
                point_shadow_depth_face_views: Some(depth_face_views),
                mip_level_count: 1,
                base_mip_level: 0,
                is_render_target: true,
            },
        );
        Ok(id)
    }

    pub fn texture_width(&self, texture_id: i32) -> u32 {
        self.textures.get(&texture_id).map(|t| t.width).unwrap_or(0)
    }

    pub fn texture_height(&self, texture_id: i32) -> u32 {
        self.textures
            .get(&texture_id)
            .map(|t| t.height)
            .unwrap_or(0)
    }

    pub fn is_texture_loaded(&self, texture_id: i32) -> bool {
        self.textures.contains_key(&texture_id)
    }

    pub fn supported_compressed_image_formats_mask(&self) -> i32 {
        let features = self.device.features();
        let mut gpu_feature_mask = 0;
        if features.contains(wgpu::Features::TEXTURE_COMPRESSION_ASTC) {
            gpu_feature_mask |= COMPRESSED_IMAGE_FORMAT_ASTC_LDR;
        }
        if features.contains(wgpu::Features::TEXTURE_COMPRESSION_BC) {
            gpu_feature_mask |= COMPRESSED_IMAGE_FORMAT_BC;
        }
        if features.contains(wgpu::Features::TEXTURE_COMPRESSION_ETC2) {
            gpu_feature_mask |= COMPRESSED_IMAGE_FORMAT_ETC2;
        }
        // Runtime decoder path supports KTX2 direct-upload formats required by
        // current Bevy parity assets (ASTC/BC/ETC2 + non-compressed formats).
        let runtime_decoder_mask = COMPRESSED_IMAGE_FORMAT_ASTC_LDR
            | COMPRESSED_IMAGE_FORMAT_BC
            | COMPRESSED_IMAGE_FORMAT_ETC2;
        gpu_feature_mask & runtime_decoder_mask
    }

    pub fn write_texture_region_rgba8(
        &mut self,
        texture_id: i32,
        x: u32,
        y: u32,
        width: u32,
        height: u32,
        pixels_rgba8: &[u8],
    ) -> anyhow::Result<()> {
        self.write_texture_region_rgba8_mip(texture_id, x, y, width, height, 0, pixels_rgba8)
    }

    pub fn write_texture_region_rgba8_mip(
        &mut self,
        texture_id: i32,
        x: u32,
        y: u32,
        width: u32,
        height: u32,
        mip_level: u32,
        pixels_rgba8: &[u8],
    ) -> anyhow::Result<()> {
        let Some(tex) = self.textures.get(&texture_id) else {
            return Ok(());
        };
        if mip_level >= tex.mip_level_count {
            return Ok(());
        }

        let target_width = (tex.width >> mip_level).max(1);
        let target_height = (tex.height >> mip_level).max(1);
        if x >= target_width || y >= target_height {
            return Ok(());
        }
        let write_width = width.min(target_width.saturating_sub(x));
        let write_height = height.min(target_height.saturating_sub(y));
        if write_width == 0 || write_height == 0 {
            return Ok(());
        }

        let absolute_mip = tex.base_mip_level + mip_level;
        let expected = (write_width * write_height * 4) as usize;
        if pixels_rgba8.len() < expected {
            return Err(anyhow!(
                "wgpu: invalid texture region byte length for id {texture_id}, expected at least {expected}, got {}",
                pixels_rgba8.len()
            ));
        }
        self.queue.write_texture(
            wgpu::TexelCopyTextureInfo {
                texture: &tex.texture,
                mip_level: absolute_mip,
                origin: wgpu::Origin3d { x, y, z: 0 },
                aspect: wgpu::TextureAspect::All,
            },
            &pixels_rgba8[..expected],
            wgpu::TexelCopyBufferLayout {
                offset: 0,
                bytes_per_row: Some(4 * write_width),
                rows_per_image: Some(write_height),
            },
            wgpu::Extent3d {
                width: write_width,
                height: write_height,
                depth_or_array_layers: 1,
            },
        );
        Ok(())
    }

    pub fn copy_texture_to_texture(
        &mut self,
        dst_texture_id: i32,
        dst_x: u32,
        dst_y: u32,
        src_texture_id: i32,
    ) -> anyhow::Result<()> {
        let Some(dst) = self.textures.get(&dst_texture_id) else {
            return Ok(());
        };
        let Some(src) = self.textures.get(&src_texture_id) else {
            return Ok(());
        };
        let mut encoder = self
            .device
            .create_command_encoder(&wgpu::CommandEncoderDescriptor {
                label: Some("mgstudio-copy-texture"),
            });
        let w = src.width.min(dst.width.saturating_sub(dst_x));
        let h = src.height.min(dst.height.saturating_sub(dst_y));
        if w == 0 || h == 0 {
            return Ok(());
        }
        encoder.copy_texture_to_texture(
            wgpu::TexelCopyTextureInfo {
                texture: &src.texture,
                mip_level: src.base_mip_level,
                origin: wgpu::Origin3d::ZERO,
                aspect: wgpu::TextureAspect::All,
            },
            wgpu::TexelCopyTextureInfo {
                texture: &dst.texture,
                mip_level: dst.base_mip_level,
                origin: wgpu::Origin3d {
                    x: dst_x,
                    y: dst_y,
                    z: 0,
                },
                aspect: wgpu::TextureAspect::All,
            },
            wgpu::Extent3d {
                width: w,
                height: h,
                depth_or_array_layers: 1,
            },
        );
        self.queue.submit(Some(encoder.finish()));
        let _ = self.device.poll(wgpu::PollType::Poll);
        Ok(())
    }

    pub fn save_texture_png(&mut self, texture_id: i32, path: &str) -> anyhow::Result<()> {
        let Some(texture) = self.textures.get(&texture_id) else {
            return Ok(());
        };
        let width = texture.width.max(1);
        let height = texture.height.max(1);
        match texture.format {
            wgpu::TextureFormat::Rgba8Unorm | wgpu::TextureFormat::Rgba8UnormSrgb => {}
            _ => {
                return Err(anyhow!(
                    "wgpu: asset_save_texture_png only supports RGBA8 textures (id={texture_id})"
                ));
            }
        }

        let bytes_per_pixel = 4u32;
        let unpadded_bytes_per_row = width
            .checked_mul(bytes_per_pixel)
            .ok_or_else(|| anyhow!("wgpu: screenshot bytes_per_row overflow"))?;
        let padded_bytes_per_row = align_up(
            unpadded_bytes_per_row as u64,
            wgpu::COPY_BYTES_PER_ROW_ALIGNMENT as u64,
        ) as u32;
        let output_size = u64::from(padded_bytes_per_row) * u64::from(height);

        let readback = self.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("mgstudio-screenshot-readback"),
            size: output_size,
            usage: wgpu::BufferUsages::COPY_DST | wgpu::BufferUsages::MAP_READ,
            mapped_at_creation: false,
        });

        let mut encoder = self
            .device
            .create_command_encoder(&wgpu::CommandEncoderDescriptor {
                label: Some("mgstudio-screenshot-encoder"),
            });
        encoder.copy_texture_to_buffer(
            wgpu::TexelCopyTextureInfo {
                texture: &texture.texture,
                mip_level: texture.base_mip_level,
                origin: wgpu::Origin3d::ZERO,
                aspect: wgpu::TextureAspect::All,
            },
            wgpu::TexelCopyBufferInfo {
                buffer: &readback,
                layout: wgpu::TexelCopyBufferLayout {
                    offset: 0,
                    bytes_per_row: Some(padded_bytes_per_row),
                    rows_per_image: Some(height),
                },
            },
            wgpu::Extent3d {
                width,
                height,
                depth_or_array_layers: 1,
            },
        );
        self.queue.submit(Some(encoder.finish()));

        let slice = readback.slice(..);
        let (sender, receiver) = std::sync::mpsc::channel();
        slice.map_async(wgpu::MapMode::Read, move |result| {
            let _ = sender.send(result);
        });
        loop {
            let _ = self.device.poll(wgpu::PollType::Poll);
            match receiver.try_recv() {
                Ok(result) => {
                    result.context("wgpu: map_async failed for screenshot readback")?;
                    break;
                }
                Err(std::sync::mpsc::TryRecvError::Empty) => {
                    std::thread::sleep(std::time::Duration::from_millis(1));
                }
                Err(std::sync::mpsc::TryRecvError::Disconnected) => {
                    return Err(anyhow!("wgpu: screenshot readback channel disconnected"));
                }
            }
        }

        let mapped = slice.get_mapped_range();
        let mut rgba = vec![0u8; (unpadded_bytes_per_row as usize) * (height as usize)];
        for row in 0..height as usize {
            let src_start = row * (padded_bytes_per_row as usize);
            let src_end = src_start + (unpadded_bytes_per_row as usize);
            let dst_start = row * (unpadded_bytes_per_row as usize);
            let dst_end = dst_start + (unpadded_bytes_per_row as usize);
            rgba[dst_start..dst_end].copy_from_slice(&mapped[src_start..src_end]);
        }
        drop(mapped);
        readback.unmap();

        if let Some(parent) = std::path::Path::new(path).parent() {
            if !parent.as_os_str().is_empty() {
                std::fs::create_dir_all(parent)
                    .with_context(|| format!("create screenshot dir {}", parent.display()))?;
            }
        }
        image::save_buffer_with_format(
            path,
            &rgba,
            width,
            height,
            image::ColorType::Rgba8,
            image::ImageFormat::Png,
        )
        .with_context(|| format!("save screenshot to {path}"))?;
        Ok(())
    }

    pub fn set_texture_sampler(
        &mut self,
        texture_id: i32,
        sampler_kind: i32,
    ) -> anyhow::Result<()> {
        let nearest = sampler_kind == 1 || sampler_kind == 3;
        let repeat = sampler_kind == 2 || sampler_kind == 3;
        let address_mode = if repeat {
            wgpu::AddressMode::Repeat
        } else {
            wgpu::AddressMode::ClampToEdge
        };
        self.ensure_sprite_resources()?;
        let Some(tex) = self.textures.get_mut(&texture_id) else {
            return Ok(());
        };
        let sampler = if nearest {
            self.device.create_sampler(&wgpu::SamplerDescriptor {
                label: Some("mgstudio-sampler-nearest"),
                mag_filter: wgpu::FilterMode::Nearest,
                min_filter: wgpu::FilterMode::Nearest,
                mipmap_filter: wgpu::MipmapFilterMode::Nearest,
                address_mode_u: address_mode,
                address_mode_v: address_mode,
                address_mode_w: address_mode,
                ..Default::default()
            })
        } else {
            self.device.create_sampler(&wgpu::SamplerDescriptor {
                label: Some("mgstudio-sampler-linear"),
                mag_filter: wgpu::FilterMode::Linear,
                min_filter: wgpu::FilterMode::Linear,
                mipmap_filter: wgpu::MipmapFilterMode::Linear,
                address_mode_u: address_mode,
                address_mode_v: address_mode,
                address_mode_w: address_mode,
                ..Default::default()
            })
        };
        let bgl_tex = self
            .sprite
            .bgl_tex
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: sprite texture bind group layout not initialized"))?;
        let bind_group = self.device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("mgstudio-sprite-tex"),
            layout: bgl_tex,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: wgpu::BindingResource::Sampler(&sampler),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: wgpu::BindingResource::TextureView(&tex.view),
                },
            ],
        });
        tex.sampler = sampler;
        tex.bind_group = bind_group;
        Ok(())
    }

    pub fn create_texture_mip_view(
        &mut self,
        texture_id: i32,
        mip_level: u32,
    ) -> anyhow::Result<i32> {
        self.ensure_sprite_resources()?;
        let Some(source) = self.textures.get(&texture_id) else {
            return Ok(0);
        };
        if mip_level >= source.mip_level_count {
            return Ok(0);
        }

        let absolute_base_mip = source.base_mip_level + mip_level;
        let width = (source.width >> mip_level).max(1);
        let height = (source.height >> mip_level).max(1);
        let format = source.format;
        let texture = source.texture.clone();
        let sampler = source.sampler.clone();
        let is_render_target = source.is_render_target;

        let view = texture.create_view(&wgpu::TextureViewDescriptor {
            label: Some("mgstudio-texture-mip-view"),
            format: None,
            dimension: Some(wgpu::TextureViewDimension::D2),
            usage: None,
            aspect: wgpu::TextureAspect::All,
            base_mip_level: absolute_base_mip,
            mip_level_count: Some(1),
            base_array_layer: 0,
            array_layer_count: Some(1),
        });
        let bgl_tex = self
            .sprite
            .bgl_tex
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: sprite texture bind group layout not initialized"))?;
        let bind_group = self.device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("mgstudio-sprite-tex"),
            layout: bgl_tex,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: wgpu::BindingResource::Sampler(&sampler),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: wgpu::BindingResource::TextureView(&view),
                },
            ],
        });

        let id = self.next_texture_id;
        self.next_texture_id += 1;
        self.textures.insert(
            id,
            GpuTexture {
                width,
                height,
                format,
                texture,
                view,
                sampler,
                bind_group,
                point_shadow_depth_cube_array_view: None,
                point_shadow_depth_face_views: None,
                mip_level_count: 1,
                base_mip_level: absolute_base_mip,
                is_render_target,
            },
        );
        Ok(id)
    }

    fn create_texture_rgba8_with_id(
        &mut self,
        id: i32,
        width: u32,
        height: u32,
        mip_level_count: u32,
        pixels_rgba8: &[u8],
        nearest: bool,
        is_render_target: bool,
    ) -> anyhow::Result<()> {
        let width = width.max(1);
        let height = height.max(1);
        let max_mip_count = max_mip_level_count_for_size(width, height);
        let mip_level_count = mip_level_count.max(1).min(max_mip_count);
        let usage = if is_render_target {
            wgpu::TextureUsages::TEXTURE_BINDING
                | wgpu::TextureUsages::COPY_DST
                | wgpu::TextureUsages::COPY_SRC
                | wgpu::TextureUsages::RENDER_ATTACHMENT
        } else {
            wgpu::TextureUsages::TEXTURE_BINDING
                | wgpu::TextureUsages::COPY_DST
                | wgpu::TextureUsages::COPY_SRC
        };
        let texture = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some("mgstudio-texture"),
            size: wgpu::Extent3d {
                width,
                height,
                depth_or_array_layers: 1,
            },
            mip_level_count,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Rgba8Unorm,
            usage,
            view_formats: &[],
        });
        let view = texture.create_view(&wgpu::TextureViewDescriptor::default());
        let sampler = if nearest {
            self.device.create_sampler(&wgpu::SamplerDescriptor {
                label: Some("mgstudio-sampler-nearest"),
                mag_filter: wgpu::FilterMode::Nearest,
                min_filter: wgpu::FilterMode::Nearest,
                mipmap_filter: wgpu::MipmapFilterMode::Nearest,
                address_mode_u: wgpu::AddressMode::ClampToEdge,
                address_mode_v: wgpu::AddressMode::ClampToEdge,
                address_mode_w: wgpu::AddressMode::ClampToEdge,
                ..Default::default()
            })
        } else {
            self.device.create_sampler(&wgpu::SamplerDescriptor {
                label: Some("mgstudio-sampler-linear"),
                mag_filter: wgpu::FilterMode::Linear,
                min_filter: wgpu::FilterMode::Linear,
                mipmap_filter: wgpu::MipmapFilterMode::Linear,
                address_mode_u: wgpu::AddressMode::ClampToEdge,
                address_mode_v: wgpu::AddressMode::ClampToEdge,
                address_mode_w: wgpu::AddressMode::ClampToEdge,
                ..Default::default()
            })
        };

        let bgl_tex = self
            .sprite
            .bgl_tex
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: sprite texture bind group layout not initialized"))?;
        let bind_group = self.device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("mgstudio-sprite-tex"),
            layout: bgl_tex,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: wgpu::BindingResource::Sampler(&sampler),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: wgpu::BindingResource::TextureView(&view),
                },
            ],
        });

        let expected = (width * height * 4) as usize;
        if pixels_rgba8.len() < expected {
            return Err(anyhow!(
                "wgpu: invalid RGBA8 texture byte length for id {id}, expected at least {expected}, got {}",
                pixels_rgba8.len()
            ));
        }
        self.queue.write_texture(
            wgpu::TexelCopyTextureInfo {
                texture: &texture,
                mip_level: 0,
                origin: wgpu::Origin3d::ZERO,
                aspect: wgpu::TextureAspect::All,
            },
            &pixels_rgba8[..expected],
            wgpu::TexelCopyBufferLayout {
                offset: 0,
                bytes_per_row: Some(4 * width),
                rows_per_image: Some(height),
            },
            wgpu::Extent3d {
                width,
                height,
                depth_or_array_layers: 1,
            },
        );

        self.textures.insert(
            id,
            GpuTexture {
                width,
                height,
                format: wgpu::TextureFormat::Rgba8Unorm,
                texture,
                view,
                sampler,
                bind_group,
                point_shadow_depth_cube_array_view: None,
                point_shadow_depth_face_views: None,
                mip_level_count,
                base_mip_level: 0,
                is_render_target,
            },
        );
        Ok(())
    }

    fn create_render_target_with_format(
        &mut self,
        width: u32,
        height: u32,
        nearest: bool,
        format: wgpu::TextureFormat,
    ) -> anyhow::Result<i32> {
        self.ensure_sprite_resources()?;
        let id = self.next_texture_id;
        self.next_texture_id += 1;
        let width = width.max(1);
        let height = height.max(1);
        let usage = wgpu::TextureUsages::TEXTURE_BINDING
            | wgpu::TextureUsages::COPY_DST
            | wgpu::TextureUsages::COPY_SRC
            | wgpu::TextureUsages::RENDER_ATTACHMENT;
        let texture = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some("mgstudio-render-target"),
            size: wgpu::Extent3d {
                width,
                height,
                depth_or_array_layers: 1,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format,
            usage,
            view_formats: &[],
        });
        let view = texture.create_view(&wgpu::TextureViewDescriptor::default());
        let sampler = if nearest {
            self.device.create_sampler(&wgpu::SamplerDescriptor {
                label: Some("mgstudio-sampler-nearest"),
                mag_filter: wgpu::FilterMode::Nearest,
                min_filter: wgpu::FilterMode::Nearest,
                mipmap_filter: wgpu::MipmapFilterMode::Nearest,
                address_mode_u: wgpu::AddressMode::ClampToEdge,
                address_mode_v: wgpu::AddressMode::ClampToEdge,
                address_mode_w: wgpu::AddressMode::ClampToEdge,
                ..Default::default()
            })
        } else {
            self.device.create_sampler(&wgpu::SamplerDescriptor {
                label: Some("mgstudio-sampler-linear"),
                mag_filter: wgpu::FilterMode::Linear,
                min_filter: wgpu::FilterMode::Linear,
                mipmap_filter: wgpu::MipmapFilterMode::Linear,
                address_mode_u: wgpu::AddressMode::ClampToEdge,
                address_mode_v: wgpu::AddressMode::ClampToEdge,
                address_mode_w: wgpu::AddressMode::ClampToEdge,
                ..Default::default()
            })
        };
        let bgl_tex = self
            .sprite
            .bgl_tex
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: sprite texture bind group layout not initialized"))?;
        let bind_group = self.device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("mgstudio-sprite-tex"),
            layout: bgl_tex,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: wgpu::BindingResource::Sampler(&sampler),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: wgpu::BindingResource::TextureView(&view),
                },
            ],
        });
        self.textures.insert(
            id,
            GpuTexture {
                width,
                height,
                format,
                texture,
                view,
                sampler,
                bind_group,
                point_shadow_depth_cube_array_view: None,
                point_shadow_depth_face_views: None,
                mip_level_count: 1,
                base_mip_level: 0,
                is_render_target: true,
            },
        );
        Ok(id)
    }

    fn target_format_for_id(&self, target_id: i32) -> anyhow::Result<wgpu::TextureFormat> {
        if target_id == -1 {
            self.surface_format
                .ok_or_else(|| anyhow!("wgpu: surface not configured"))
        } else {
            self.textures
                .get(&target_id)
                .map(|t| t.format)
                .ok_or_else(|| anyhow!("wgpu: missing render target texture: {target_id}"))
        }
    }

    #[allow(dead_code)]
    fn target_view<'a>(
        &'a self,
        target_id: i32,
        frame: &'a GpuFrame,
    ) -> anyhow::Result<&'a wgpu::TextureView> {
        if target_id == -1 {
            frame
                .surface_view
                .as_ref()
                .ok_or_else(|| anyhow!("wgpu: no current surface texture"))
        } else {
            self.textures
                .get(&target_id)
                .map(|t| &t.view)
                .ok_or_else(|| anyhow!("wgpu: missing render target texture: {target_id}"))
        }
    }

    fn ensure_default_texture(&mut self) -> anyhow::Result<i32> {
        const DEFAULT_TEXTURE_ID: i32 = -1;
        if self.textures.contains_key(&DEFAULT_TEXTURE_ID) {
            return Ok(DEFAULT_TEXTURE_ID);
        }
        // Create a 1x1 white texture used by default material bindings.
        let white = [255u8, 255u8, 255u8, 255u8];
        self.ensure_sprite_resources()?;
        self.create_texture_rgba8_with_id(DEFAULT_TEXTURE_ID, 1, 1, 1, &white, false, false)?;
        Ok(DEFAULT_TEXTURE_ID)
    }

    fn ensure_sprite_resources(&mut self) -> anyhow::Result<()> {
        if self.sprite.pipeline_layout.is_some() {
            return Ok(());
        }

        // group(0): sampler + texture
        let bgl_tex = self
            .device
            .create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
                label: Some("mgstudio_sprite_tex_bgl"),
                entries: &[
                    wgpu::BindGroupLayoutEntry {
                        binding: 0,
                        visibility: wgpu::ShaderStages::FRAGMENT,
                        ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 1,
                        visibility: wgpu::ShaderStages::FRAGMENT,
                        ty: wgpu::BindingType::Texture {
                            sample_type: wgpu::TextureSampleType::Float { filterable: true },
                            view_dimension: wgpu::TextureViewDimension::D2,
                            multisampled: false,
                        },
                        count: None,
                    },
                ],
            });

        // group(1): globals uniform + instances storage
        let bgl_globals = self
            .device
            .create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
                label: Some("mgstudio_sprite_globals_bgl"),
                entries: &[
                    wgpu::BindGroupLayoutEntry {
                        binding: 0,
                        visibility: wgpu::ShaderStages::VERTEX,
                        ty: wgpu::BindingType::Buffer {
                            ty: wgpu::BufferBindingType::Uniform,
                            has_dynamic_offset: false,
                            min_binding_size: None,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 1,
                        visibility: wgpu::ShaderStages::VERTEX,
                        ty: wgpu::BindingType::Buffer {
                            ty: wgpu::BufferBindingType::Storage { read_only: true },
                            has_dynamic_offset: false,
                            min_binding_size: None,
                        },
                        count: None,
                    },
                ],
            });

        let pipeline_layout = self
            .device
            .create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
                label: Some("mgstudio_sprite_pl"),
                bind_group_layouts: &[&bgl_tex, &bgl_globals],
                immediate_size: 0,
            });

        let globals_buf = self.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("mgstudio_sprite_globals"),
            size: 32,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let instance_cap = 65536u64;
        let instance_buf = self.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("mgstudio_sprite_instances"),
            size: instance_cap,
            usage: wgpu::BufferUsages::STORAGE | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });

        self.sprite.bgl_tex = Some(bgl_tex);
        self.sprite.bgl_globals = Some(bgl_globals);
        self.sprite.pipeline_layout = Some(pipeline_layout);
        self.sprite.globals_buf = Some(globals_buf);
        self.sprite.instance_buf = Some(instance_buf);
        self.sprite.instance_capacity = instance_cap;

        // Create RGBA8 pipeline immediately (used by render targets / RGBA8 textures).
        self.ensure_sprite_pipeline_rgba8()?;

        Ok(())
    }

    fn ensure_sprite_pipeline_rgba8(&mut self) -> anyhow::Result<()> {
        if self.sprite.pipeline_rgba8.is_some() {
            return Ok(());
        }
        let pl = self
            .sprite
            .pipeline_layout
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: sprite pipeline layout not initialized"))?;
        let wgsl = load_wgsl_required(&self.assets_base, "shaders/mgstudio/2d/sprite.wgsl")?;
        let sm = self
            .device
            .create_shader_module(wgpu::ShaderModuleDescriptor {
                label: Some("mgstudio_sprite_wgsl"),
                source: wgpu::ShaderSource::Wgsl(wgsl.into()),
            });
        let pipeline = self
            .device
            .create_render_pipeline(&wgpu::RenderPipelineDescriptor {
                label: Some("mgstudio_sprite_rgba8"),
                layout: Some(pl),
                vertex: wgpu::VertexState {
                    module: &sm,
                    entry_point: Some("vs_main"),
                    compilation_options: Default::default(),
                    buffers: &[],
                },
                fragment: Some(wgpu::FragmentState {
                    module: &sm,
                    entry_point: Some("fs_main"),
                    compilation_options: Default::default(),
                    targets: &[Some(wgpu::ColorTargetState {
                        format: wgpu::TextureFormat::Rgba8Unorm,
                        blend: None,
                        write_mask: wgpu::ColorWrites::ALL,
                    })],
                }),
                primitive: wgpu::PrimitiveState {
                    topology: wgpu::PrimitiveTopology::TriangleList,
                    ..Default::default()
                },
                depth_stencil: None,
                multisample: wgpu::MultisampleState::default(),
                multiview_mask: None,
                cache: None,
            });
        self.sprite.pipeline_rgba8 = Some(pipeline);
        Ok(())
    }

    fn ensure_sprite_pipeline_for_format(
        &mut self,
        format: wgpu::TextureFormat,
    ) -> anyhow::Result<()> {
        if format == wgpu::TextureFormat::Rgba8Unorm {
            return self.ensure_sprite_pipeline_rgba8();
        }
        if self.sprite.pipeline_surface_format == Some(format)
            && self.sprite.pipeline_surface.is_some()
        {
            return Ok(());
        }

        let pl = self
            .sprite
            .pipeline_layout
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: sprite pipeline layout not initialized"))?;
        let wgsl = load_wgsl_required(&self.assets_base, "shaders/mgstudio/2d/sprite.wgsl")?;
        let sm = self
            .device
            .create_shader_module(wgpu::ShaderModuleDescriptor {
                label: Some("mgstudio_sprite_wgsl_surface"),
                source: wgpu::ShaderSource::Wgsl(wgsl.into()),
            });
        let pipeline = self
            .device
            .create_render_pipeline(&wgpu::RenderPipelineDescriptor {
                label: Some("mgstudio_sprite_surface"),
                layout: Some(pl),
                vertex: wgpu::VertexState {
                    module: &sm,
                    entry_point: Some("vs_main"),
                    compilation_options: Default::default(),
                    buffers: &[],
                },
                fragment: Some(wgpu::FragmentState {
                    module: &sm,
                    entry_point: Some("fs_main"),
                    compilation_options: Default::default(),
                    targets: &[Some(wgpu::ColorTargetState {
                        format,
                        blend: Some(wgpu::BlendState::ALPHA_BLENDING),
                        write_mask: wgpu::ColorWrites::ALL,
                    })],
                }),
                primitive: wgpu::PrimitiveState {
                    topology: wgpu::PrimitiveTopology::TriangleList,
                    ..Default::default()
                },
                depth_stencil: None,
                multisample: wgpu::MultisampleState::default(),
                multiview_mask: None,
                cache: None,
            });
        self.sprite.pipeline_surface = Some(pipeline);
        self.sprite.pipeline_surface_format = Some(format);
        Ok(())
    }

    fn write_sprite_globals(&self, st: &GpuPassState) {
        let Some(buf) = self.sprite.globals_buf.as_ref() else {
            return;
        };
        let safe_scale = st.camera_scale;
        let scale_x_base = if st.width_logical > 0.0 {
            2.0 / st.width_logical / safe_scale
        } else {
            0.0
        };
        let scale_y_base = if st.height_logical > 0.0 {
            2.0 / st.height_logical / safe_scale
        } else {
            0.0
        };
        let cam_cos = (-st.camera_rot).cos();
        let cam_sin = (-st.camera_rot).sin();
        let globals: [f32; 8] = [
            st.camera_x,
            st.camera_y,
            cam_cos,
            cam_sin,
            scale_x_base,
            scale_y_base,
            0.0,
            0.0,
        ];
        self.queue
            .write_buffer(buf, 0, bytemuck::cast_slice(&globals));
    }

    fn prepare_sprite_segments(
        &mut self,
        st: &GpuPassState,
        segments: &[&SpriteSegment],
    ) -> anyhow::Result<Vec<wgpu::BindGroup>> {
        if segments.is_empty() {
            return Ok(Vec::new());
        }
        self.ensure_sprite_resources()?;
        self.ensure_sprite_pipeline_for_format(st.target_format)?;

        let globals_buf = self
            .sprite
            .globals_buf
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: sprite globals buffer missing"))?;
        let bgl_globals = self
            .sprite
            .bgl_globals
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: sprite globals layout missing"))?;

        // Concatenate all instance data into one storage buffer upload.
        // Each storage binding offset must satisfy device alignment constraints.
        let storage_align = self
            .device
            .limits()
            .min_storage_buffer_offset_alignment
            .max(1) as u64;
        let mut offsets_bytes: Vec<u64> = Vec::with_capacity(segments.len());
        let mut all_f32: Vec<f32> = Vec::new();
        let mut cur_bytes: u64 = 0;
        for seg in segments {
            cur_bytes = align_up_u64(cur_bytes, storage_align);
            offsets_bytes.push(cur_bytes);
            let padded_words = (cur_bytes / 4) as usize;
            if all_f32.len() < padded_words {
                all_f32.resize(padded_words, 0.0);
            }
            all_f32.extend_from_slice(&seg.instance_data);
            cur_bytes = (all_f32.len() * 4) as u64;
        }

        let required_bytes = cur_bytes.max(1);
        if required_bytes > self.sprite.instance_capacity {
            let new_cap = required_bytes.max(256);
            let new_buf = self.device.create_buffer(&wgpu::BufferDescriptor {
                label: Some("mgstudio_sprite_instances_grow"),
                size: new_cap,
                usage: wgpu::BufferUsages::STORAGE | wgpu::BufferUsages::COPY_DST,
                mapped_at_creation: false,
            });
            self.sprite.instance_buf = Some(new_buf);
            self.sprite.instance_capacity = new_cap;
        }
        let instance_buf = self.sprite.instance_buf.as_ref().unwrap();

        self.queue
            .write_buffer(instance_buf, 0, bytemuck::cast_slice(all_f32.as_slice()));

        // Build per-segment bind groups binding the correct storage buffer range.
        let mut bgs: Vec<wgpu::BindGroup> = Vec::with_capacity(segments.len());
        for (i, seg) in segments.iter().enumerate() {
            let offset = offsets_bytes[i];
            let size = (seg.instance_data.len() * 4) as u64;
            let bg = self.device.create_bind_group(&wgpu::BindGroupDescriptor {
                label: Some("mgstudio_sprite_globals_bg"),
                layout: bgl_globals,
                entries: &[
                    wgpu::BindGroupEntry {
                        binding: 0,
                        resource: globals_buf.as_entire_binding(),
                    },
                    wgpu::BindGroupEntry {
                        binding: 1,
                        resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                            buffer: instance_buf,
                            offset,
                            size: Some(std::num::NonZeroU64::new(size.max(1)).unwrap()),
                        }),
                    },
                ],
            });
            bgs.push(bg);
        }
        Ok(bgs)
    }

    #[allow(dead_code)]
    fn encode_sprite_segment(
        &mut self,
        st: &GpuPassState,
        rp: &mut wgpu::RenderPass<'_>,
        seg: &SpriteSegment,
        globals_bg: wgpu::BindGroup,
    ) -> anyhow::Result<()> {
        if seg.instance_count == 0 {
            return Ok(());
        }
        self.ensure_sprite_pipeline_for_format(st.target_format)?;
        let pipeline = if st.target_format == wgpu::TextureFormat::Rgba8Unorm {
            self.sprite.pipeline_rgba8.as_ref().unwrap()
        } else {
            self.sprite.pipeline_surface.as_ref().unwrap()
        };

        rp.set_pipeline(pipeline);
        rp.set_bind_group(1, &globals_bg, &[]);

        for batch in &seg.batches {
            let Some(id) = self.resolve_draw_texture_id(batch.texture_id)? else {
                continue;
            };
            let Some(tg) = self.textures.get(&id) else {
                continue;
            };
            rp.set_bind_group(0, &tg.bind_group, &[]);
            rp.draw(
                0..6,
                batch.first_instance..(batch.first_instance + batch.instance_count),
            );
        }
        Ok(())
    }

    fn ensure_mesh_resources(&mut self) -> anyhow::Result<()> {
        self.ensure_sprite_resources()?;
        if self.mesh.pipeline_layout.is_some() && self.mesh.pipeline_layout_3d.is_some() {
            return Ok(());
        }
        let bgl_tex = self
            .sprite
            .bgl_tex
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: sprite texture bind group layout not initialized"))?;
        let bgl_uniform = self
            .device
            .create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
                label: Some("mgstudio_mesh_uniform_bgl"),
                entries: &[wgpu::BindGroupLayoutEntry {
                    binding: 0,
                    visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                    ty: wgpu::BindingType::Buffer {
                        ty: wgpu::BufferBindingType::Uniform,
                        has_dynamic_offset: true,
                        min_binding_size: None,
                    },
                    count: None,
                }],
            });
        let bgl_view_3d = self
            .device
            .create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
                label: Some("mgstudio_mesh3d_view_bgl"),
                entries: &[
                    wgpu::BindGroupLayoutEntry {
                        binding: 0,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Buffer {
                            ty: wgpu::BufferBindingType::Uniform,
                            has_dynamic_offset: false,
                            min_binding_size: None,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 1,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Buffer {
                            ty: wgpu::BufferBindingType::Uniform,
                            has_dynamic_offset: false,
                            min_binding_size: None,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 2,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Texture {
                            sample_type: wgpu::TextureSampleType::Depth,
                            view_dimension: wgpu::TextureViewDimension::CubeArray,
                            multisampled: false,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 3,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Comparison),
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 5,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Texture {
                            sample_type: wgpu::TextureSampleType::Depth,
                            view_dimension: wgpu::TextureViewDimension::D2Array,
                            multisampled: false,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 6,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Comparison),
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 8,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Buffer {
                            ty: wgpu::BufferBindingType::Uniform,
                            has_dynamic_offset: false,
                            min_binding_size: None,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 9,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Buffer {
                            ty: wgpu::BufferBindingType::Uniform,
                            has_dynamic_offset: false,
                            min_binding_size: None,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 10,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Buffer {
                            ty: wgpu::BufferBindingType::Uniform,
                            has_dynamic_offset: false,
                            min_binding_size: None,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 11,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Buffer {
                            ty: wgpu::BufferBindingType::Uniform,
                            has_dynamic_offset: false,
                            min_binding_size: None,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 12,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Buffer {
                            ty: wgpu::BufferBindingType::Uniform,
                            has_dynamic_offset: false,
                            min_binding_size: None,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 13,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Buffer {
                            ty: wgpu::BufferBindingType::Uniform,
                            has_dynamic_offset: false,
                            min_binding_size: None,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 14,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Buffer {
                            ty: wgpu::BufferBindingType::Uniform,
                            has_dynamic_offset: false,
                            min_binding_size: None,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 15,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Buffer {
                            ty: wgpu::BufferBindingType::Uniform,
                            has_dynamic_offset: false,
                            min_binding_size: None,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 16,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Buffer {
                            ty: wgpu::BufferBindingType::Uniform,
                            has_dynamic_offset: false,
                            min_binding_size: None,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 17,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Texture {
                            sample_type: wgpu::TextureSampleType::Float { filterable: true },
                            view_dimension: wgpu::TextureViewDimension::D2,
                            multisampled: false,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 18,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Buffer {
                            ty: wgpu::BufferBindingType::Uniform,
                            has_dynamic_offset: false,
                            min_binding_size: None,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 19,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Texture {
                            sample_type: wgpu::TextureSampleType::Float { filterable: true },
                            view_dimension: wgpu::TextureViewDimension::D3,
                            multisampled: false,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 20,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 25,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Texture {
                            sample_type: wgpu::TextureSampleType::Float { filterable: true },
                            view_dimension: wgpu::TextureViewDimension::D2,
                            multisampled: false,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 26,
                        visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                        ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                        count: None,
                    },
                ],
            });
        let bgl_view_env_3d =
            self.device
                .create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
                    label: Some("mgstudio_mesh3d_view_env_bgl"),
                    entries: &[
                        wgpu::BindGroupLayoutEntry {
                            binding: 0,
                            visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                            ty: wgpu::BindingType::Texture {
                                sample_type: wgpu::TextureSampleType::Float { filterable: true },
                                view_dimension: wgpu::TextureViewDimension::Cube,
                                multisampled: false,
                            },
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 1,
                            visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                            ty: wgpu::BindingType::Texture {
                                sample_type: wgpu::TextureSampleType::Float { filterable: true },
                                view_dimension: wgpu::TextureViewDimension::Cube,
                                multisampled: false,
                            },
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 2,
                            visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                            ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                            count: None,
                        },
                    ],
                });
        let bgl_mesh_3d = self
            .device
            .create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
                label: Some("mgstudio_mesh3d_mesh_bgl"),
                entries: &[wgpu::BindGroupLayoutEntry {
                    binding: 0,
                    visibility: wgpu::ShaderStages::VERTEX_FRAGMENT,
                    ty: wgpu::BindingType::Buffer {
                        ty: wgpu::BufferBindingType::Uniform,
                        has_dynamic_offset: false,
                        min_binding_size: None,
                    },
                    count: None,
                }],
            });
        let bgl_material_3d =
            self.device
                .create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
                    label: Some("mgstudio_mesh3d_material_bgl"),
                    entries: &[
                        wgpu::BindGroupLayoutEntry {
                            binding: 0,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Buffer {
                                ty: wgpu::BufferBindingType::Uniform,
                                has_dynamic_offset: false,
                                min_binding_size: None,
                            },
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 1,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Texture {
                                sample_type: wgpu::TextureSampleType::Float { filterable: true },
                                view_dimension: wgpu::TextureViewDimension::D2,
                                multisampled: false,
                            },
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 2,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 3,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Texture {
                                sample_type: wgpu::TextureSampleType::Float { filterable: true },
                                view_dimension: wgpu::TextureViewDimension::D2,
                                multisampled: false,
                            },
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 4,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 5,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Texture {
                                sample_type: wgpu::TextureSampleType::Float { filterable: true },
                                view_dimension: wgpu::TextureViewDimension::D2,
                                multisampled: false,
                            },
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 6,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 7,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Texture {
                                sample_type: wgpu::TextureSampleType::Float { filterable: true },
                                view_dimension: wgpu::TextureViewDimension::D2,
                                multisampled: false,
                            },
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 8,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 9,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Texture {
                                sample_type: wgpu::TextureSampleType::Float { filterable: true },
                                view_dimension: wgpu::TextureViewDimension::D2,
                                multisampled: false,
                            },
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 10,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 11,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Texture {
                                sample_type: wgpu::TextureSampleType::Float { filterable: true },
                                view_dimension: wgpu::TextureViewDimension::D2,
                                multisampled: false,
                            },
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 12,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                            count: None,
                        },
                    ],
                });
        let pl = self
            .device
            .create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
                label: Some("mgstudio_mesh_pl"),
                bind_group_layouts: &[&bgl_uniform, bgl_tex],
                immediate_size: 0,
            });
        let pl_3d = self
            .device
            .create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
                label: Some("mgstudio_mesh3d_pl"),
                bind_group_layouts: &[
                    &bgl_view_3d,
                    &bgl_view_env_3d,
                    &bgl_mesh_3d,
                    &bgl_material_3d,
                ],
                immediate_size: 0,
            });
        let align = self
            .device
            .limits()
            .min_uniform_buffer_offset_alignment
            .max(256) as u64;
        let uniform_binding_size = align_up(MESH_UNIFORM_MAX_BYTES, align);
        let cap = uniform_binding_size.max(256u64);
        let uniform_buf = self.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("mgstudio_mesh_uniform_buf"),
            size: cap,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let bg = self.device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("mgstudio_mesh_uniform_bg"),
            layout: &bgl_uniform,
            entries: &[wgpu::BindGroupEntry {
                binding: 0,
                resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                    buffer: &uniform_buf,
                    offset: 0,
                    size: Some(
                        std::num::NonZeroU64::new(uniform_binding_size)
                            .ok_or_else(|| anyhow!("wgpu: mesh uniform binding size is zero"))?,
                    ),
                }),
            }],
        });
        let dummy_view_uniform_buf = self.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("mgstudio_mesh3d_view_uniform_buf"),
            size: 4096,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let dummy_lights_uniform_buf = self.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("mgstudio_mesh3d_lights_uniform_buf"),
            size: 1024,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let clustered_lights_uniform_buf = self.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("mgstudio_mesh3d_clustered_lights_uniform_buf"),
            size: MESH3D_CLUSTERED_LIGHTS_UNIFORM_BYTES,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let cluster_index_lists_uniform_buf = self.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("mgstudio_mesh3d_cluster_index_lists_uniform_buf"),
            size: MESH3D_CLUSTER_INDEX_LISTS_UNIFORM_BYTES,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let cluster_offsets_uniform_buf = self.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("mgstudio_mesh3d_cluster_offsets_uniform_buf"),
            size: MESH3D_CLUSTER_OFFSETS_UNIFORM_BYTES,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let dummy_uniform_buf = self.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("mgstudio_mesh3d_zero_uniform_buf"),
            size: 65536,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let dummy_mesh_buf = self.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("mgstudio_mesh3d_dummy_mesh_buf"),
            size: 512,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let dummy_material_buf = self.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("mgstudio_mesh3d_dummy_material_buf"),
            size: 1024,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let dummy_color_texture_2d = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some("mgstudio_mesh3d_dummy_color_2d"),
            size: wgpu::Extent3d {
                width: 1,
                height: 1,
                depth_or_array_layers: 1,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Rgba8Unorm,
            usage: wgpu::TextureUsages::TEXTURE_BINDING | wgpu::TextureUsages::COPY_DST,
            view_formats: &[],
        });
        let dummy_color_view_2d =
            dummy_color_texture_2d.create_view(&wgpu::TextureViewDescriptor::default());
        let dummy_color_texture_cube = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some("mgstudio_mesh3d_dummy_color_cube"),
            size: wgpu::Extent3d {
                width: 1,
                height: 1,
                depth_or_array_layers: 6,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Rgba8Unorm,
            usage: wgpu::TextureUsages::TEXTURE_BINDING | wgpu::TextureUsages::COPY_DST,
            view_formats: &[],
        });
        let dummy_color_view_cube =
            dummy_color_texture_cube.create_view(&wgpu::TextureViewDescriptor {
                dimension: Some(wgpu::TextureViewDimension::Cube),
                ..Default::default()
            });
        let dummy_depth_cube_array_texture = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some("mgstudio_mesh3d_dummy_depth_cube_array"),
            size: wgpu::Extent3d {
                width: 1,
                height: 1,
                depth_or_array_layers: 6,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Depth32Float,
            usage: wgpu::TextureUsages::TEXTURE_BINDING,
            view_formats: &[],
        });
        let dummy_depth_view_cube_array =
            dummy_depth_cube_array_texture.create_view(&wgpu::TextureViewDescriptor {
                dimension: Some(wgpu::TextureViewDimension::CubeArray),
                array_layer_count: Some(6),
                ..Default::default()
            });
        let dummy_depth_array_texture = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some("mgstudio_mesh3d_dummy_depth_array"),
            size: wgpu::Extent3d {
                width: 1,
                height: 1,
                depth_or_array_layers: 1,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Depth32Float,
            usage: wgpu::TextureUsages::TEXTURE_BINDING,
            view_formats: &[],
        });
        let dummy_depth_view_array =
            dummy_depth_array_texture.create_view(&wgpu::TextureViewDescriptor {
                dimension: Some(wgpu::TextureViewDimension::D2Array),
                ..Default::default()
            });
        let dummy_3d_texture = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some("mgstudio_mesh3d_dummy_3d"),
            size: wgpu::Extent3d {
                width: 1,
                height: 1,
                depth_or_array_layers: 1,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D3,
            format: wgpu::TextureFormat::Rgba8Unorm,
            usage: wgpu::TextureUsages::TEXTURE_BINDING | wgpu::TextureUsages::COPY_DST,
            view_formats: &[],
        });
        let dummy_3d_view = dummy_3d_texture.create_view(&wgpu::TextureViewDescriptor::default());
        let dummy_linear_sampler = self.device.create_sampler(&wgpu::SamplerDescriptor {
            label: Some("mgstudio_mesh3d_dummy_linear_sampler"),
            mag_filter: wgpu::FilterMode::Linear,
            min_filter: wgpu::FilterMode::Linear,
            mipmap_filter: wgpu::MipmapFilterMode::Linear,
            address_mode_u: wgpu::AddressMode::ClampToEdge,
            address_mode_v: wgpu::AddressMode::ClampToEdge,
            address_mode_w: wgpu::AddressMode::ClampToEdge,
            ..Default::default()
        });
        let dummy_comparison_sampler = self.device.create_sampler(&wgpu::SamplerDescriptor {
            label: Some("mgstudio_mesh3d_dummy_comparison_sampler"),
            compare: Some(wgpu::CompareFunction::GreaterEqual),
            mag_filter: wgpu::FilterMode::Linear,
            min_filter: wgpu::FilterMode::Linear,
            mipmap_filter: wgpu::MipmapFilterMode::Linear,
            address_mode_u: wgpu::AddressMode::ClampToEdge,
            address_mode_v: wgpu::AddressMode::ClampToEdge,
            address_mode_w: wgpu::AddressMode::ClampToEdge,
            ..Default::default()
        });
        let bg_view_3d = self.device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("mgstudio_mesh3d_view_bg"),
            layout: &bgl_view_3d,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                        buffer: &dummy_view_uniform_buf,
                        offset: 0,
                        size: None,
                    }),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                        buffer: &dummy_lights_uniform_buf,
                        offset: 0,
                        size: None,
                    }),
                },
                wgpu::BindGroupEntry {
                    binding: 2,
                    resource: wgpu::BindingResource::TextureView(&dummy_depth_view_cube_array),
                },
                wgpu::BindGroupEntry {
                    binding: 3,
                    resource: wgpu::BindingResource::Sampler(&dummy_comparison_sampler),
                },
                wgpu::BindGroupEntry {
                    binding: 5,
                    resource: wgpu::BindingResource::TextureView(&dummy_depth_view_array),
                },
                wgpu::BindGroupEntry {
                    binding: 6,
                    resource: wgpu::BindingResource::Sampler(&dummy_comparison_sampler),
                },
                wgpu::BindGroupEntry {
                    binding: 8,
                    resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                        buffer: &clustered_lights_uniform_buf,
                        offset: 0,
                        size: None,
                    }),
                },
                wgpu::BindGroupEntry {
                    binding: 9,
                    resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                        buffer: &cluster_index_lists_uniform_buf,
                        offset: 0,
                        size: None,
                    }),
                },
                wgpu::BindGroupEntry {
                    binding: 10,
                    resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                        buffer: &cluster_offsets_uniform_buf,
                        offset: 0,
                        size: None,
                    }),
                },
                wgpu::BindGroupEntry {
                    binding: 11,
                    resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                        buffer: &dummy_uniform_buf,
                        offset: 0,
                        size: None,
                    }),
                },
                wgpu::BindGroupEntry {
                    binding: 12,
                    resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                        buffer: &dummy_uniform_buf,
                        offset: 0,
                        size: None,
                    }),
                },
                wgpu::BindGroupEntry {
                    binding: 13,
                    resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                        buffer: &dummy_uniform_buf,
                        offset: 0,
                        size: None,
                    }),
                },
                wgpu::BindGroupEntry {
                    binding: 14,
                    resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                        buffer: &dummy_uniform_buf,
                        offset: 0,
                        size: None,
                    }),
                },
                wgpu::BindGroupEntry {
                    binding: 15,
                    resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                        buffer: &dummy_uniform_buf,
                        offset: 0,
                        size: None,
                    }),
                },
                wgpu::BindGroupEntry {
                    binding: 16,
                    resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                        buffer: &dummy_uniform_buf,
                        offset: 0,
                        size: None,
                    }),
                },
                wgpu::BindGroupEntry {
                    binding: 17,
                    resource: wgpu::BindingResource::TextureView(&dummy_color_view_2d),
                },
                wgpu::BindGroupEntry {
                    binding: 18,
                    resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                        buffer: &dummy_uniform_buf,
                        offset: 0,
                        size: None,
                    }),
                },
                wgpu::BindGroupEntry {
                    binding: 19,
                    resource: wgpu::BindingResource::TextureView(&dummy_3d_view),
                },
                wgpu::BindGroupEntry {
                    binding: 20,
                    resource: wgpu::BindingResource::Sampler(&dummy_linear_sampler),
                },
                wgpu::BindGroupEntry {
                    binding: 25,
                    resource: wgpu::BindingResource::TextureView(&dummy_color_view_2d),
                },
                wgpu::BindGroupEntry {
                    binding: 26,
                    resource: wgpu::BindingResource::Sampler(&dummy_linear_sampler),
                },
            ],
        });
        let bg_view_env_3d = self.device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("mgstudio_mesh3d_view_env_bg"),
            layout: &bgl_view_env_3d,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: wgpu::BindingResource::TextureView(&dummy_color_view_cube),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: wgpu::BindingResource::TextureView(&dummy_color_view_cube),
                },
                wgpu::BindGroupEntry {
                    binding: 2,
                    resource: wgpu::BindingResource::Sampler(&dummy_linear_sampler),
                },
            ],
        });
        let bg_mesh_3d = self.device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("mgstudio_mesh3d_mesh_bg"),
            layout: &bgl_mesh_3d,
            entries: &[wgpu::BindGroupEntry {
                binding: 0,
                resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                    buffer: &dummy_mesh_buf,
                    offset: 0,
                    size: None,
                }),
            }],
        });
        let bg_material_3d = self.device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("mgstudio_mesh3d_material_bg"),
            layout: &bgl_material_3d,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                        buffer: &dummy_material_buf,
                        offset: 0,
                        size: None,
                    }),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: wgpu::BindingResource::TextureView(&dummy_color_view_2d),
                },
                wgpu::BindGroupEntry {
                    binding: 2,
                    resource: wgpu::BindingResource::Sampler(&dummy_linear_sampler),
                },
                wgpu::BindGroupEntry {
                    binding: 3,
                    resource: wgpu::BindingResource::TextureView(&dummy_color_view_2d),
                },
                wgpu::BindGroupEntry {
                    binding: 4,
                    resource: wgpu::BindingResource::Sampler(&dummy_linear_sampler),
                },
                wgpu::BindGroupEntry {
                    binding: 5,
                    resource: wgpu::BindingResource::TextureView(&dummy_color_view_2d),
                },
                wgpu::BindGroupEntry {
                    binding: 6,
                    resource: wgpu::BindingResource::Sampler(&dummy_linear_sampler),
                },
                wgpu::BindGroupEntry {
                    binding: 7,
                    resource: wgpu::BindingResource::TextureView(&dummy_color_view_2d),
                },
                wgpu::BindGroupEntry {
                    binding: 8,
                    resource: wgpu::BindingResource::Sampler(&dummy_linear_sampler),
                },
                wgpu::BindGroupEntry {
                    binding: 9,
                    resource: wgpu::BindingResource::TextureView(&dummy_color_view_2d),
                },
                wgpu::BindGroupEntry {
                    binding: 10,
                    resource: wgpu::BindingResource::Sampler(&dummy_linear_sampler),
                },
                wgpu::BindGroupEntry {
                    binding: 11,
                    resource: wgpu::BindingResource::TextureView(&dummy_color_view_2d),
                },
                wgpu::BindGroupEntry {
                    binding: 12,
                    resource: wgpu::BindingResource::Sampler(&dummy_linear_sampler),
                },
            ],
        });
        self.mesh.bgl_uniform = Some(bgl_uniform);
        self.mesh.bg_view_3d = Some(bg_view_3d);
        self.mesh.bg_view_env_3d = Some(bg_view_env_3d);
        self.mesh.bg_mesh_3d = Some(bg_mesh_3d);
        self.mesh.bg_material_3d = Some(bg_material_3d);
        self.mesh.mesh3d_dummy_uniform_buf = Some(dummy_uniform_buf);
        self.mesh.mesh3d_dummy_color_2d_view = Some(dummy_color_view_2d);
        self.mesh.mesh3d_dummy_3d_view = Some(dummy_3d_view);
        self.mesh.mesh3d_dummy_linear_sampler = Some(dummy_linear_sampler);
        self.mesh.mesh3d_dummy_depth_cube_array_view = Some(dummy_depth_view_cube_array);
        self.mesh.mesh3d_dummy_depth_array_view = Some(dummy_depth_view_array);
        self.mesh.mesh3d_dummy_compare_sampler = Some(dummy_comparison_sampler);
        self.mesh.mesh3d_view_uniform_buf = Some(dummy_view_uniform_buf);
        self.mesh.mesh3d_lights_uniform_buf = Some(dummy_lights_uniform_buf);
        self.mesh.mesh3d_clustered_lights_uniform_buf = Some(clustered_lights_uniform_buf);
        self.mesh.mesh3d_cluster_index_lists_uniform_buf = Some(cluster_index_lists_uniform_buf);
        self.mesh.mesh3d_cluster_offsets_uniform_buf = Some(cluster_offsets_uniform_buf);
        self.mesh.mesh3d_mesh_uniform_buf = Some(dummy_mesh_buf);
        self.mesh.mesh3d_material_uniform_buf = Some(dummy_material_buf);
        self.mesh.pipeline_layout = Some(pl);
        self.mesh.pipeline_layout_3d = Some(pl_3d);
        self.mesh.uniform_buf = Some(uniform_buf);
        self.mesh.uniform_bg = Some(bg);
        self.mesh.uniform_capacity = cap;
        self.mesh.uniform_binding_size = uniform_binding_size;
        Ok(())
    }

    fn ensure_mesh_pipeline(&mut self, format: wgpu::TextureFormat) -> anyhow::Result<()> {
        self.ensure_mesh_resources()?;
        if self.mesh.pipelines.contains_key(&format) {
            return Ok(());
        }
        let pl = self
            .mesh
            .pipeline_layout
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: mesh pipeline layout missing"))?;
        let wgsl = load_wgsl_required(&self.assets_base, "shaders/mgstudio/2d/mesh.wgsl")?;
        let sm = self
            .device
            .create_shader_module(wgpu::ShaderModuleDescriptor {
                label: Some("mgstudio_mesh_wgsl"),
                source: wgpu::ShaderSource::Wgsl(wgsl.into()),
            });
        let vb_layout = wgpu::VertexBufferLayout {
            array_stride: 32,
            step_mode: wgpu::VertexStepMode::Vertex,
            attributes: &[
                wgpu::VertexAttribute {
                    offset: 0,
                    shader_location: 0,
                    format: wgpu::VertexFormat::Float32x2,
                },
                wgpu::VertexAttribute {
                    offset: 8,
                    shader_location: 1,
                    format: wgpu::VertexFormat::Float32x2,
                },
                wgpu::VertexAttribute {
                    offset: 16,
                    shader_location: 2,
                    format: wgpu::VertexFormat::Float32x4,
                },
            ],
        };
        let pipeline = self
            .device
            .create_render_pipeline(&wgpu::RenderPipelineDescriptor {
                label: Some("mgstudio_mesh_pipeline"),
                layout: Some(pl),
                vertex: wgpu::VertexState {
                    module: &sm,
                    entry_point: Some("vs_main"),
                    compilation_options: Default::default(),
                    buffers: &[vb_layout],
                },
                fragment: Some(wgpu::FragmentState {
                    module: &sm,
                    entry_point: Some("fs_main"),
                    compilation_options: Default::default(),
                    targets: &[Some(wgpu::ColorTargetState {
                        format,
                        blend: Some(wgpu::BlendState::ALPHA_BLENDING),
                        write_mask: wgpu::ColorWrites::ALL,
                    })],
                }),
                primitive: wgpu::PrimitiveState {
                    topology: wgpu::PrimitiveTopology::TriangleList,
                    ..Default::default()
                },
                depth_stencil: None,
                multisample: wgpu::MultisampleState::default(),
                multiview_mask: None,
                cache: None,
            });
        self.mesh.pipelines.insert(format, pipeline);
        Ok(())
    }

    fn ensure_mesh3d_pipeline(
        &mut self,
        format: wgpu::TextureFormat,
        topology: wgpu::PrimitiveTopology,
        cull_mode: i32,
    ) -> anyhow::Result<()> {
        self.ensure_mesh_resources()?;
        let key = (format, topology, mesh3d_cull_mode_sanitize(cull_mode));
        if self.mesh.pipelines_3d.contains_key(&key)
            && self.mesh.pipelines_3d_transparent.contains_key(&key)
        {
            return Ok(());
        }
        let cull_mode_wgpu = mesh3d_cull_mode_wgpu(cull_mode);
        let pl = self
            .mesh
            .pipeline_layout_3d
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: mesh3d pipeline layout missing"))?;
        let shader_defs = mesh3d_bevy_shader_defs();
        let vertex_wgsl = load_wgsl_with_shader_defs_required(
            &self.assets_base,
            MESH3D_VERTEX_SHADER_PATH,
            &shader_defs,
        )?;
        let fragment_wgsl = load_wgsl_with_shader_defs_required(
            &self.assets_base,
            MESH3D_FRAGMENT_SHADER_PATH,
            &shader_defs,
        )?;
        let sm_vertex = self
            .device
            .create_shader_module(wgpu::ShaderModuleDescriptor {
                label: Some("mgstudio_mesh3d_vertex_wgsl"),
                source: wgpu::ShaderSource::Wgsl(vertex_wgsl.into()),
            });
        let sm_fragment = self
            .device
            .create_shader_module(wgpu::ShaderModuleDescriptor {
                label: Some("mgstudio_mesh3d_fragment_wgsl"),
                source: wgpu::ShaderSource::Wgsl(fragment_wgsl.into()),
            });
        let vb_layout = wgpu::VertexBufferLayout {
            array_stride: 36,
            step_mode: wgpu::VertexStepMode::Vertex,
            attributes: &[
                wgpu::VertexAttribute {
                    offset: 0,
                    shader_location: 0,
                    format: wgpu::VertexFormat::Float32x3,
                },
                wgpu::VertexAttribute {
                    offset: 12,
                    shader_location: 1,
                    format: wgpu::VertexFormat::Float32x3,
                },
            ],
        };
        let pipeline_opaque = self
            .device
            .create_render_pipeline(&wgpu::RenderPipelineDescriptor {
                label: Some("mgstudio_mesh3d_pipeline_opaque"),
                layout: Some(pl),
                vertex: wgpu::VertexState {
                    module: &sm_vertex,
                    entry_point: Some(MESH3D_VERTEX_ENTRY),
                    compilation_options: Default::default(),
                    buffers: &[vb_layout],
                },
                fragment: Some(wgpu::FragmentState {
                    module: &sm_fragment,
                    entry_point: Some(MESH3D_FRAGMENT_ENTRY),
                    compilation_options: Default::default(),
                    targets: &[Some(wgpu::ColorTargetState {
                        format,
                        blend: Some(wgpu::BlendState::ALPHA_BLENDING),
                        write_mask: wgpu::ColorWrites::ALL,
                    })],
                }),
                primitive: wgpu::PrimitiveState {
                    topology,
                    cull_mode: cull_mode_wgpu,
                    ..Default::default()
                },
                depth_stencil: Some(wgpu::DepthStencilState {
                    format: wgpu::TextureFormat::Depth24Plus,
                    depth_write_enabled: true,
                    depth_compare: wgpu::CompareFunction::GreaterEqual,
                    stencil: wgpu::StencilState::default(),
                    bias: wgpu::DepthBiasState::default(),
                }),
                multisample: wgpu::MultisampleState::default(),
                multiview_mask: None,
                cache: None,
            });
        let vb_layout_transparent = wgpu::VertexBufferLayout {
            array_stride: 36,
            step_mode: wgpu::VertexStepMode::Vertex,
            attributes: &[
                wgpu::VertexAttribute {
                    offset: 0,
                    shader_location: 0,
                    format: wgpu::VertexFormat::Float32x3,
                },
                wgpu::VertexAttribute {
                    offset: 12,
                    shader_location: 1,
                    format: wgpu::VertexFormat::Float32x3,
                },
            ],
        };
        let pipeline_transparent =
            self.device
                .create_render_pipeline(&wgpu::RenderPipelineDescriptor {
                    label: Some("mgstudio_mesh3d_pipeline_transparent"),
                    layout: Some(pl),
                    vertex: wgpu::VertexState {
                        module: &sm_vertex,
                        entry_point: Some(MESH3D_VERTEX_ENTRY),
                        compilation_options: Default::default(),
                        buffers: &[vb_layout_transparent],
                    },
                    fragment: Some(wgpu::FragmentState {
                        module: &sm_fragment,
                        entry_point: Some(MESH3D_FRAGMENT_ENTRY),
                        compilation_options: Default::default(),
                        targets: &[Some(wgpu::ColorTargetState {
                            format,
                            blend: Some(wgpu::BlendState::ALPHA_BLENDING),
                            write_mask: wgpu::ColorWrites::ALL,
                        })],
                    }),
                    primitive: wgpu::PrimitiveState {
                        topology,
                        cull_mode: cull_mode_wgpu,
                        ..Default::default()
                    },
                    depth_stencil: Some(wgpu::DepthStencilState {
                        format: wgpu::TextureFormat::Depth24Plus,
                        depth_write_enabled: false,
                        depth_compare: wgpu::CompareFunction::GreaterEqual,
                        stencil: wgpu::StencilState::default(),
                        bias: wgpu::DepthBiasState::default(),
                    }),
                    multisample: wgpu::MultisampleState::default(),
                    multiview_mask: None,
                    cache: None,
                });
        self.mesh.pipelines_3d.insert(key, pipeline_opaque);
        self.mesh
            .pipelines_3d_transparent
            .insert(key, pipeline_transparent);
        Ok(())
    }

    fn ensure_mesh3d_shadow_pipeline(
        &mut self,
        format: wgpu::TextureFormat,
        topology: wgpu::PrimitiveTopology,
        cull_mode: i32,
    ) -> anyhow::Result<()> {
        self.ensure_mesh_resources()?;
        let key = (format, topology, mesh3d_cull_mode_sanitize(cull_mode));
        if self.mesh.pipelines_3d_shadow.contains_key(&key) {
            return Ok(());
        }
        let cull_mode_wgpu = mesh3d_cull_mode_wgpu(cull_mode);
        let pl = self
            .mesh
            .pipeline_layout_3d
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: mesh3d pipeline layout missing"))?;
        let shader_defs = mesh3d_bevy_shader_defs();
        let vertex_wgsl = load_wgsl_with_shader_defs_required(
            &self.assets_base,
            MESH3D_VERTEX_SHADER_PATH,
            &shader_defs,
        )?;
        let shadow_wgsl = load_wgsl_with_shader_defs_required(
            &self.assets_base,
            MESH3D_SHADOW_SHADER_PATH,
            &shader_defs,
        )?;
        let sm_vertex = self
            .device
            .create_shader_module(wgpu::ShaderModuleDescriptor {
                label: Some("mgstudio_mesh3d_shadow_vertex_wgsl"),
                source: wgpu::ShaderSource::Wgsl(vertex_wgsl.into()),
            });
        let sm_shadow = self
            .device
            .create_shader_module(wgpu::ShaderModuleDescriptor {
                label: Some("mgstudio_mesh3d_shadow_fragment_wgsl"),
                source: wgpu::ShaderSource::Wgsl(shadow_wgsl.into()),
            });
        let vb_layout = wgpu::VertexBufferLayout {
            array_stride: 36,
            step_mode: wgpu::VertexStepMode::Vertex,
            attributes: &[
                wgpu::VertexAttribute {
                    offset: 0,
                    shader_location: 0,
                    format: wgpu::VertexFormat::Float32x3,
                },
                wgpu::VertexAttribute {
                    offset: 12,
                    shader_location: 1,
                    format: wgpu::VertexFormat::Float32x3,
                },
            ],
        };
        let pipeline = self
            .device
            .create_render_pipeline(&wgpu::RenderPipelineDescriptor {
                label: Some("mgstudio_mesh3d_shadow_pipeline"),
                layout: Some(pl),
                vertex: wgpu::VertexState {
                    module: &sm_vertex,
                    entry_point: Some(MESH3D_VERTEX_ENTRY),
                    compilation_options: Default::default(),
                    buffers: &[vb_layout],
                },
                fragment: Some(wgpu::FragmentState {
                    module: &sm_shadow,
                    entry_point: Some(MESH3D_SHADOW_FRAGMENT_ENTRY),
                    compilation_options: Default::default(),
                    targets: &[Some(wgpu::ColorTargetState {
                        format,
                        blend: None,
                        write_mask: wgpu::ColorWrites::ALL,
                    })],
                }),
                primitive: wgpu::PrimitiveState {
                    topology,
                    cull_mode: cull_mode_wgpu,
                    ..Default::default()
                },
                depth_stencil: Some(wgpu::DepthStencilState {
                    format: wgpu::TextureFormat::Depth24Plus,
                    depth_write_enabled: true,
                    depth_compare: wgpu::CompareFunction::GreaterEqual,
                    stencil: wgpu::StencilState::default(),
                    bias: wgpu::DepthBiasState::default(),
                }),
                multisample: wgpu::MultisampleState::default(),
                multiview_mask: None,
                cache: None,
            });
        self.mesh.pipelines_3d_shadow.insert(key, pipeline);
        Ok(())
    }

    fn ensure_mesh3d_motion_vector_pipeline(&mut self) -> anyhow::Result<()> {
        self.ensure_sprite_resources()?;
        if self.mesh.motion_vector_pipeline_layout.is_none() {
            let bgl = self
                .device
                .create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
                    label: Some("mgstudio_motion_vector_uniform_bgl"),
                    entries: &[wgpu::BindGroupLayoutEntry {
                        binding: 0,
                        visibility: wgpu::ShaderStages::VERTEX,
                        ty: wgpu::BindingType::Buffer {
                            ty: wgpu::BufferBindingType::Uniform,
                            has_dynamic_offset: false,
                            min_binding_size: None,
                        },
                        count: None,
                    }],
                });
            let pl = self
                .device
                .create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
                    label: Some("mgstudio_motion_vector_pl"),
                    bind_group_layouts: &[&bgl],
                    immediate_size: 0,
                });
            self.mesh.motion_vector_bgl_uniform = Some(bgl);
            self.mesh.motion_vector_pipeline_layout = Some(pl);
        }
        if self.mesh.motion_vector_uniform_buf.is_none()
            || self.mesh.motion_vector_uniform_bg.is_none()
        {
            let bgl = self
                .mesh
                .motion_vector_bgl_uniform
                .as_ref()
                .ok_or_else(|| anyhow!("wgpu: motion-vector uniform layout missing"))?;
            let uniform_buf = self.device.create_buffer(&wgpu::BufferDescriptor {
                label: Some("mgstudio_motion_vector_uniform_buf"),
                size: 256,
                usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
                mapped_at_creation: false,
            });
            let uniform_bg =
                self.device.create_bind_group(&wgpu::BindGroupDescriptor {
                    label: Some("mgstudio_motion_vector_uniform_bg"),
                    layout: bgl,
                    entries: &[wgpu::BindGroupEntry {
                        binding: 0,
                        resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                            buffer: &uniform_buf,
                            offset: 0,
                            size: Some(std::num::NonZeroU64::new(256).ok_or_else(|| {
                                anyhow!("wgpu: invalid motion-vector uniform size")
                            })?),
                        }),
                    }],
                });
            self.mesh.motion_vector_uniform_buf = Some(uniform_buf);
            self.mesh.motion_vector_uniform_bg = Some(uniform_bg);
        }
        if self.mesh.motion_vector_pipeline.is_some() {
            return Ok(());
        }
        let pl = self
            .mesh
            .motion_vector_pipeline_layout
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: motion-vector pipeline layout missing"))?;
        let wgsl = load_wgsl_required(&self.assets_base, "shaders/mgstudio/3d/motion_vector.wgsl")?;
        let sm = self
            .device
            .create_shader_module(wgpu::ShaderModuleDescriptor {
                label: Some("mgstudio_motion_vector_wgsl"),
                source: wgpu::ShaderSource::Wgsl(wgsl.into()),
            });
        let vb_layout = wgpu::VertexBufferLayout {
            array_stride: 36,
            step_mode: wgpu::VertexStepMode::Vertex,
            attributes: &[
                wgpu::VertexAttribute {
                    offset: 0,
                    shader_location: 0,
                    format: wgpu::VertexFormat::Float32x3,
                },
                wgpu::VertexAttribute {
                    offset: 12,
                    shader_location: 1,
                    format: wgpu::VertexFormat::Float32x2,
                },
                wgpu::VertexAttribute {
                    offset: 20,
                    shader_location: 2,
                    format: wgpu::VertexFormat::Float32x4,
                },
            ],
        };
        let pipeline = self
            .device
            .create_render_pipeline(&wgpu::RenderPipelineDescriptor {
                label: Some("mgstudio_motion_vector_rgba16f"),
                layout: Some(pl),
                vertex: wgpu::VertexState {
                    module: &sm,
                    entry_point: Some("vs_main"),
                    compilation_options: Default::default(),
                    buffers: &[vb_layout],
                },
                fragment: Some(wgpu::FragmentState {
                    module: &sm,
                    entry_point: Some("fs_main"),
                    compilation_options: Default::default(),
                    targets: &[Some(wgpu::ColorTargetState {
                        format: wgpu::TextureFormat::Rgba16Float,
                        blend: None,
                        write_mask: wgpu::ColorWrites::ALL,
                    })],
                }),
                primitive: wgpu::PrimitiveState {
                    topology: wgpu::PrimitiveTopology::TriangleList,
                    ..Default::default()
                },
                depth_stencil: Some(wgpu::DepthStencilState {
                    format: wgpu::TextureFormat::Depth24Plus,
                    depth_write_enabled: true,
                    depth_compare: wgpu::CompareFunction::GreaterEqual,
                    stencil: wgpu::StencilState::default(),
                    bias: wgpu::DepthBiasState::default(),
                }),
                multisample: wgpu::MultisampleState::default(),
                multiview_mask: None,
                cache: None,
            });
        self.mesh.motion_vector_pipeline = Some(pipeline);
        Ok(())
    }

    fn ensure_motion_blur_pipeline_rgba8(&mut self) -> anyhow::Result<()> {
        self.ensure_sprite_resources()?;
        if self.mesh.motion_blur_pipeline_layout.is_none() {
            let bgl = self
                .device
                .create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
                    label: Some("mgstudio_motion_blur_bgl"),
                    entries: &[
                        wgpu::BindGroupLayoutEntry {
                            binding: 0,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Texture {
                                sample_type: wgpu::TextureSampleType::Float { filterable: true },
                                view_dimension: wgpu::TextureViewDimension::D2,
                                multisampled: false,
                            },
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 1,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Texture {
                                sample_type: wgpu::TextureSampleType::Float { filterable: true },
                                view_dimension: wgpu::TextureViewDimension::D2,
                                multisampled: false,
                            },
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 2,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Texture {
                                sample_type: wgpu::TextureSampleType::Depth,
                                view_dimension: wgpu::TextureViewDimension::D2,
                                multisampled: false,
                            },
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 3,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 4,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Buffer {
                                ty: wgpu::BufferBindingType::Uniform,
                                has_dynamic_offset: false,
                                min_binding_size: None,
                            },
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 5,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Buffer {
                                ty: wgpu::BufferBindingType::Uniform,
                                has_dynamic_offset: false,
                                min_binding_size: None,
                            },
                            count: None,
                        },
                    ],
                });
            let pl = self
                .device
                .create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
                    label: Some("mgstudio_motion_blur_pl"),
                    bind_group_layouts: &[&bgl],
                    immediate_size: 0,
                });
            self.mesh.motion_blur_bgl = Some(bgl);
            self.mesh.motion_blur_pipeline_layout = Some(pl);
        }
        if self.mesh.motion_blur_settings_buf.is_none() {
            let settings_buf = self.device.create_buffer(&wgpu::BufferDescriptor {
                label: Some("mgstudio_motion_blur_settings_buf"),
                size: 16,
                usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
                mapped_at_creation: false,
            });
            self.mesh.motion_blur_settings_buf = Some(settings_buf);
        }
        if self.mesh.motion_blur_globals_buf.is_none() {
            let globals_buf = self.device.create_buffer(&wgpu::BufferDescriptor {
                label: Some("mgstudio_motion_blur_globals_buf"),
                size: 16,
                usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
                mapped_at_creation: false,
            });
            self.mesh.motion_blur_globals_buf = Some(globals_buf);
        }
        if self.mesh.motion_blur_pipeline_rgba8.is_some() {
            return Ok(());
        }
        let pl = self
            .mesh
            .motion_blur_pipeline_layout
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: motion-blur pipeline layout missing"))?;
        let wgsl = load_wgsl_required(&self.assets_base, "shaders/mgstudio/3d/motion_blur.wgsl")?;
        let sm = self
            .device
            .create_shader_module(wgpu::ShaderModuleDescriptor {
                label: Some("mgstudio_motion_blur_wgsl"),
                source: wgpu::ShaderSource::Wgsl(wgsl.into()),
            });
        let pipeline = self
            .device
            .create_render_pipeline(&wgpu::RenderPipelineDescriptor {
                label: Some("mgstudio_motion_blur_rgba8"),
                layout: Some(pl),
                vertex: wgpu::VertexState {
                    module: &sm,
                    entry_point: Some("fullscreen_vertex_shader"),
                    compilation_options: Default::default(),
                    buffers: &[],
                },
                fragment: Some(wgpu::FragmentState {
                    module: &sm,
                    entry_point: Some("fragment"),
                    compilation_options: Default::default(),
                    targets: &[Some(wgpu::ColorTargetState {
                        format: wgpu::TextureFormat::Rgba8Unorm,
                        blend: None,
                        write_mask: wgpu::ColorWrites::ALL,
                    })],
                }),
                primitive: wgpu::PrimitiveState {
                    topology: wgpu::PrimitiveTopology::TriangleList,
                    ..Default::default()
                },
                depth_stencil: None,
                multisample: wgpu::MultisampleState::default(),
                multiview_mask: None,
                cache: None,
            });
        self.mesh.motion_blur_pipeline_rgba8 = Some(pipeline);
        Ok(())
    }

    fn ensure_motion_blur_pipeline_for_format(
        &mut self,
        format: wgpu::TextureFormat,
    ) -> anyhow::Result<()> {
        self.ensure_motion_blur_pipeline_rgba8()?;
        if format == wgpu::TextureFormat::Rgba8Unorm {
            return Ok(());
        }
        if self.mesh.motion_blur_pipeline_surface_format == Some(format)
            && self.mesh.motion_blur_pipeline_surface.is_some()
        {
            return Ok(());
        }
        let pl = self
            .mesh
            .motion_blur_pipeline_layout
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: motion-blur pipeline layout missing"))?;
        let wgsl = load_wgsl_required(&self.assets_base, "shaders/mgstudio/3d/motion_blur.wgsl")?;
        let sm = self
            .device
            .create_shader_module(wgpu::ShaderModuleDescriptor {
                label: Some("mgstudio_motion_blur_wgsl_surface"),
                source: wgpu::ShaderSource::Wgsl(wgsl.into()),
            });
        let pipeline = self
            .device
            .create_render_pipeline(&wgpu::RenderPipelineDescriptor {
                label: Some("mgstudio_motion_blur_surface"),
                layout: Some(pl),
                vertex: wgpu::VertexState {
                    module: &sm,
                    entry_point: Some("fullscreen_vertex_shader"),
                    compilation_options: Default::default(),
                    buffers: &[],
                },
                fragment: Some(wgpu::FragmentState {
                    module: &sm,
                    entry_point: Some("fragment"),
                    compilation_options: Default::default(),
                    targets: &[Some(wgpu::ColorTargetState {
                        format,
                        blend: None,
                        write_mask: wgpu::ColorWrites::ALL,
                    })],
                }),
                primitive: wgpu::PrimitiveState {
                    topology: wgpu::PrimitiveTopology::TriangleList,
                    ..Default::default()
                },
                depth_stencil: None,
                multisample: wgpu::MultisampleState::default(),
                multiview_mask: None,
                cache: None,
            });
        self.mesh.motion_blur_pipeline_surface = Some(pipeline);
        self.mesh.motion_blur_pipeline_surface_format = Some(format);
        Ok(())
    }

    fn load_wgsl_with_defines_required(
        &self,
        rel: &str,
        define_keys: &[&str],
    ) -> anyhow::Result<String> {
        let shader_defs = define_keys
            .iter()
            .map(|s| ((*s).to_string(), WgslShaderDefValue::Bool(true)))
            .collect::<HashMap<_, _>>();
        load_wgsl_with_shader_defs_required(&self.assets_base, rel, &shader_defs)
    }

    fn create_bloom2d_pipeline(
        &self,
        layout: &wgpu::PipelineLayout,
        shader_source: &str,
        format: wgpu::TextureFormat,
        fs_entry: &str,
        blend: Option<wgpu::BlendState>,
        label: &'static str,
    ) -> wgpu::RenderPipeline {
        let sm = self
            .device
            .create_shader_module(wgpu::ShaderModuleDescriptor {
                label: Some(label),
                source: wgpu::ShaderSource::Wgsl(shader_source.into()),
            });
        self.device
            .create_render_pipeline(&wgpu::RenderPipelineDescriptor {
                label: Some(label),
                layout: Some(layout),
                vertex: wgpu::VertexState {
                    module: &sm,
                    entry_point: Some("fullscreen_vertex_shader"),
                    compilation_options: Default::default(),
                    buffers: &[],
                },
                fragment: Some(wgpu::FragmentState {
                    module: &sm,
                    entry_point: Some(fs_entry),
                    compilation_options: Default::default(),
                    targets: &[Some(wgpu::ColorTargetState {
                        format,
                        blend,
                        write_mask: wgpu::ColorWrites::ALL,
                    })],
                }),
                primitive: wgpu::PrimitiveState {
                    topology: wgpu::PrimitiveTopology::TriangleList,
                    ..Default::default()
                },
                depth_stencil: None,
                multisample: wgpu::MultisampleState::default(),
                multiview_mask: None,
                cache: None,
            })
    }

    fn ensure_bloom2d_pipeline_rgba8(&mut self) -> anyhow::Result<()> {
        self.ensure_sprite_resources()?;
        if self.mesh.bloom2d_pipeline_layout.is_none() {
            let bgl = self
                .device
                .create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
                    label: Some("mgstudio_bloom2d_bgl"),
                    entries: &[
                        wgpu::BindGroupLayoutEntry {
                            binding: 0,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Texture {
                                sample_type: wgpu::TextureSampleType::Float { filterable: true },
                                view_dimension: wgpu::TextureViewDimension::D2,
                                multisampled: false,
                            },
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 1,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 2,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Buffer {
                                ty: wgpu::BufferBindingType::Uniform,
                                has_dynamic_offset: false,
                                min_binding_size: None,
                            },
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 3,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Texture {
                                sample_type: wgpu::TextureSampleType::Float { filterable: true },
                                view_dimension: wgpu::TextureViewDimension::D2,
                                multisampled: false,
                            },
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 4,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Texture {
                                sample_type: wgpu::TextureSampleType::Float { filterable: true },
                                view_dimension: wgpu::TextureViewDimension::D2,
                                multisampled: false,
                            },
                            count: None,
                        },
                    ],
                });
            let pl = self
                .device
                .create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
                    label: Some("mgstudio_bloom2d_pl"),
                    bind_group_layouts: &[&bgl],
                    immediate_size: 0,
                });
            self.mesh.bloom2d_bgl = Some(bgl);
            self.mesh.bloom2d_pipeline_layout = Some(pl);
        }
        if self.mesh.bloom2d_settings_buf.is_none() {
            let settings_buf = self.device.create_buffer(&wgpu::BufferDescriptor {
                label: Some("mgstudio_bloom2d_settings_buf"),
                size: 80,
                usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
                mapped_at_creation: false,
            });
            self.mesh.bloom2d_settings_buf = Some(settings_buf);
        }
        if self.mesh.bloom2d_sampler.is_none() {
            self.mesh.bloom2d_sampler =
                Some(self.device.create_sampler(&wgpu::SamplerDescriptor {
                    label: Some("mgstudio_bloom2d_sampler"),
                    address_mode_u: wgpu::AddressMode::ClampToEdge,
                    address_mode_v: wgpu::AddressMode::ClampToEdge,
                    address_mode_w: wgpu::AddressMode::ClampToEdge,
                    mag_filter: wgpu::FilterMode::Linear,
                    min_filter: wgpu::FilterMode::Linear,
                    mipmap_filter: wgpu::MipmapFilterMode::Linear,
                    ..Default::default()
                }));
        }
        let pl = self
            .mesh
            .bloom2d_pipeline_layout
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: bloom2d pipeline layout missing"))?;
        let mip_format = wgpu::TextureFormat::Rgba16Float;
        if self.mesh.bloom2d_downsample_first_pipeline.is_none()
            || self
                .mesh
                .bloom2d_downsample_first_no_threshold_pipeline
                .is_none()
            || self
                .mesh
                .bloom2d_downsample_first_uniform_pipeline
                .is_none()
            || self
                .mesh
                .bloom2d_downsample_first_no_threshold_uniform_pipeline
                .is_none()
            || self.mesh.bloom2d_downsample_pipeline.is_none()
            || self.mesh.bloom2d_downsample_uniform_pipeline.is_none()
            || self.mesh.bloom2d_upsample_pipeline_energy.is_none()
            || self.mesh.bloom2d_upsample_pipeline_additive.is_none()
        {
            let downsample_first_source = self.load_wgsl_with_defines_required(
                "shaders/mgstudio/2d/bloom.wgsl",
                &["FIRST_DOWNSAMPLE", "USE_THRESHOLD"],
            )?;
            let downsample_first_no_threshold_source = self.load_wgsl_with_defines_required(
                "shaders/mgstudio/2d/bloom.wgsl",
                &["FIRST_DOWNSAMPLE"],
            )?;
            let downsample_first_uniform_source = self.load_wgsl_with_defines_required(
                "shaders/mgstudio/2d/bloom.wgsl",
                &["FIRST_DOWNSAMPLE", "USE_THRESHOLD", "UNIFORM_SCALE"],
            )?;
            let downsample_first_no_threshold_uniform_source = self
                .load_wgsl_with_defines_required(
                    "shaders/mgstudio/2d/bloom.wgsl",
                    &["FIRST_DOWNSAMPLE", "UNIFORM_SCALE"],
                )?;
            let downsample_source =
                self.load_wgsl_with_defines_required("shaders/mgstudio/2d/bloom.wgsl", &[])?;
            let downsample_uniform_source = self.load_wgsl_with_defines_required(
                "shaders/mgstudio/2d/bloom.wgsl",
                &["UNIFORM_SCALE"],
            )?;
            let upsample_source =
                self.load_wgsl_with_defines_required("shaders/mgstudio/2d/bloom.wgsl", &[])?;
            self.mesh.bloom2d_downsample_first_pipeline = Some(self.create_bloom2d_pipeline(
                pl,
                &downsample_first_source,
                mip_format,
                "downsample_first",
                None,
                "mgstudio_bloom2d_downsample_first",
            ));
            self.mesh.bloom2d_downsample_first_no_threshold_pipeline =
                Some(self.create_bloom2d_pipeline(
                    pl,
                    &downsample_first_no_threshold_source,
                    mip_format,
                    "downsample_first",
                    None,
                    "mgstudio_bloom2d_downsample_first_no_threshold",
                ));
            self.mesh.bloom2d_downsample_first_uniform_pipeline =
                Some(self.create_bloom2d_pipeline(
                    pl,
                    &downsample_first_uniform_source,
                    mip_format,
                    "downsample_first",
                    None,
                    "mgstudio_bloom2d_downsample_first_uniform",
                ));
            self.mesh
                .bloom2d_downsample_first_no_threshold_uniform_pipeline =
                Some(self.create_bloom2d_pipeline(
                    pl,
                    &downsample_first_no_threshold_uniform_source,
                    mip_format,
                    "downsample_first",
                    None,
                    "mgstudio_bloom2d_downsample_first_no_threshold_uniform",
                ));
            self.mesh.bloom2d_downsample_pipeline = Some(self.create_bloom2d_pipeline(
                pl,
                &downsample_source,
                mip_format,
                "downsample",
                None,
                "mgstudio_bloom2d_downsample",
            ));
            self.mesh.bloom2d_downsample_uniform_pipeline = Some(self.create_bloom2d_pipeline(
                pl,
                &downsample_uniform_source,
                mip_format,
                "downsample",
                None,
                "mgstudio_bloom2d_downsample_uniform",
            ));
            self.mesh.bloom2d_upsample_pipeline_energy = Some(self.create_bloom2d_pipeline(
                pl,
                &upsample_source,
                mip_format,
                "upsample",
                Some(wgpu::BlendState {
                    color: wgpu::BlendComponent {
                        src_factor: wgpu::BlendFactor::Constant,
                        dst_factor: wgpu::BlendFactor::OneMinusConstant,
                        operation: wgpu::BlendOperation::Add,
                    },
                    alpha: wgpu::BlendComponent {
                        src_factor: wgpu::BlendFactor::Zero,
                        dst_factor: wgpu::BlendFactor::One,
                        operation: wgpu::BlendOperation::Add,
                    },
                }),
                "mgstudio_bloom2d_upsample_energy",
            ));
            self.mesh.bloom2d_upsample_pipeline_additive = Some(self.create_bloom2d_pipeline(
                pl,
                &upsample_source,
                mip_format,
                "upsample",
                Some(wgpu::BlendState {
                    color: wgpu::BlendComponent {
                        src_factor: wgpu::BlendFactor::Constant,
                        dst_factor: wgpu::BlendFactor::One,
                        operation: wgpu::BlendOperation::Add,
                    },
                    alpha: wgpu::BlendComponent {
                        src_factor: wgpu::BlendFactor::Zero,
                        dst_factor: wgpu::BlendFactor::One,
                        operation: wgpu::BlendOperation::Add,
                    },
                }),
                "mgstudio_bloom2d_upsample_additive",
            ));
        }
        if self.mesh.bloom2d_pipeline_rgba8.is_some() {
            return Ok(());
        }
        let final_source =
            load_wgsl_required(&self.assets_base, "shaders/mgstudio/2d/tonemapping.wgsl")?;
        self.mesh.bloom2d_pipeline_rgba8 = Some(self.create_bloom2d_pipeline(
            pl,
            &final_source,
            wgpu::TextureFormat::Rgba8Unorm,
            "final_fragment",
            None,
            "mgstudio_bloom2d_rgba8",
        ));
        Ok(())
    }

    fn ensure_bloom2d_pipeline_for_format(
        &mut self,
        format: wgpu::TextureFormat,
    ) -> anyhow::Result<()> {
        self.ensure_bloom2d_pipeline_rgba8()?;
        if format == wgpu::TextureFormat::Rgba8Unorm {
            return Ok(());
        }
        if self.mesh.bloom2d_pipeline_surface_format == Some(format)
            && self.mesh.bloom2d_pipeline_surface.is_some()
        {
            return Ok(());
        }
        let pl = self
            .mesh
            .bloom2d_pipeline_layout
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: bloom2d pipeline layout missing"))?;
        let final_source =
            load_wgsl_required(&self.assets_base, "shaders/mgstudio/2d/tonemapping.wgsl")?;
        self.mesh.bloom2d_pipeline_surface = Some(self.create_bloom2d_pipeline(
            pl,
            &final_source,
            format,
            "final_fragment",
            None,
            "mgstudio_bloom2d_surface",
        ));
        self.mesh.bloom2d_pipeline_surface_format = Some(format);
        Ok(())
    }

    fn ensure_bloom2d_mip_texture(
        &mut self,
        mip_count: u32,
        width: u32,
        height: u32,
    ) -> anyhow::Result<()> {
        let safe_mip_count = mip_count.max(1);
        let safe_width = width.max(1);
        let safe_height = height.max(1);
        if self.mesh.bloom2d_mip_texture.is_some()
            && self.mesh.bloom2d_mip_count == safe_mip_count
            && self.mesh.bloom2d_mip_width == safe_width
            && self.mesh.bloom2d_mip_height == safe_height
            && self.mesh.bloom2d_mip_views.len() == safe_mip_count as usize
        {
            return Ok(());
        }
        let texture = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some("mgstudio_bloom2d_mip_texture"),
            size: wgpu::Extent3d {
                width: safe_width,
                height: safe_height,
                depth_or_array_layers: 1,
            },
            mip_level_count: safe_mip_count,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Rgba16Float,
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT | wgpu::TextureUsages::TEXTURE_BINDING,
            view_formats: &[],
        });
        let mut views = Vec::with_capacity(safe_mip_count as usize);
        for mip in 0..safe_mip_count {
            views.push(texture.create_view(&wgpu::TextureViewDescriptor {
                label: Some("mgstudio_bloom2d_mip_view"),
                format: None,
                dimension: Some(wgpu::TextureViewDimension::D2),
                usage: Some(
                    wgpu::TextureUsages::RENDER_ATTACHMENT | wgpu::TextureUsages::TEXTURE_BINDING,
                ),
                aspect: wgpu::TextureAspect::All,
                base_mip_level: mip,
                mip_level_count: Some(1),
                base_array_layer: 0,
                array_layer_count: Some(1),
            }));
        }
        self.mesh.bloom2d_mip_texture = Some(texture);
        self.mesh.bloom2d_mip_views = views;
        self.mesh.bloom2d_mip_count = safe_mip_count;
        self.mesh.bloom2d_mip_width = safe_width;
        self.mesh.bloom2d_mip_height = safe_height;
        Ok(())
    }

    fn create_bloom2d_bind_group(
        &self,
        layout: &wgpu::BindGroupLayout,
        input_view: &wgpu::TextureView,
        sampler: &wgpu::Sampler,
        settings_buf: &wgpu::Buffer,
        scene_view: &wgpu::TextureView,
        lut_view: &wgpu::TextureView,
        label: &'static str,
    ) -> wgpu::BindGroup {
        self.device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some(label),
            layout,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: wgpu::BindingResource::TextureView(input_view),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: wgpu::BindingResource::Sampler(sampler),
                },
                wgpu::BindGroupEntry {
                    binding: 2,
                    resource: settings_buf.as_entire_binding(),
                },
                wgpu::BindGroupEntry {
                    binding: 3,
                    resource: wgpu::BindingResource::TextureView(scene_view),
                },
                wgpu::BindGroupEntry {
                    binding: 4,
                    resource: wgpu::BindingResource::TextureView(lut_view),
                },
            ],
        })
    }

    #[allow(clippy::too_many_arguments)]
    fn encode_bloom2d_multipass(
        &mut self,
        encoder: &mut wgpu::CommandEncoder,
        pass_state: &GpuPassState,
        target_view: &wgpu::TextureView,
        target_width: u32,
        target_height: u32,
        draw: &Bloom2dDraw,
        final_pipeline: &wgpu::RenderPipeline,
        bind_layout: &wgpu::BindGroupLayout,
        settings_buf: &wgpu::Buffer,
        bloom_sampler: &wgpu::Sampler,
        scene_view: &wgpu::TextureView,
        lut_view: &wgpu::TextureView,
        scene_width: u32,
        scene_height: u32,
    ) -> anyhow::Result<()> {
        let Some((sx, sy, sw, sh)) =
            resolve_scissor_rect(pass_state, draw.scissor, target_width, target_height)
        else {
            return Ok(());
        };
        let low_frequency_boost = draw.low_frequency_boost.clamp(0.0, 1.0);
        let low_frequency_boost_curvature = draw.low_frequency_boost_curvature.clamp(0.0, 1.0);
        let high_pass_frequency = draw.high_pass_frequency.clamp(0.0, 1.0);
        let intensity = draw.intensity.max(0.0);
        let threshold = draw.threshold.max(0.0);
        let threshold_softness = draw.threshold_softness.clamp(0.0, 1.0);
        let scale_x = draw.scale_x.max(0.0);
        let scale_y = draw.scale_y.max(0.0);
        let tonemapping_mode = draw.tonemapping_mode.clamp(0, 7) as f32;
        let deband_dither_enabled = if draw.deband_dither_enabled == 0 {
            0.0
        } else {
            1.0
        };
        let fxaa_enabled = if draw.fxaa_enabled == 0 { 0.0 } else { 1.0 };
        let fxaa_edge_threshold = if fxaa_enabled > 0.0 {
            draw.fxaa_edge_threshold.clamp(0.0, 1.0)
        } else {
            0.0
        };
        let chromatic_aberration_strength = draw.chromatic_aberration_strength.clamp(0.0, 1.0);
        let vignette_strength = draw.vignette_strength.clamp(0.0, 1.0);
        let use_uniform_scale = scale_x == 1.0 && scale_y == 1.0;
        let use_prefilter = threshold > 0.0;
        let bloom_enabled = draw.enabled != 0;
        let bloom_weight = if bloom_enabled { intensity } else { 0.0 };
        let safe_scene_width = scene_width.max(1) as i32;
        let safe_scene_height = scene_height.max(1) as i32;
        let viewport_width = if pass_state.viewport_w > 0 {
            pass_state.viewport_w as i32
        } else if draw.view_width > 0 {
            draw.view_width
        } else {
            safe_scene_width
        };
        let viewport_height = if pass_state.viewport_h > 0 {
            pass_state.viewport_h as i32
        } else if draw.view_height > 0 {
            draw.view_height
        } else {
            safe_scene_height
        };
        let safe_viewport_width = viewport_width.max(1);
        let safe_viewport_height = viewport_height.max(1);
        let source_viewport_width = {
            let raw = if draw.view_width > 0 {
                draw.view_width
            } else {
                safe_scene_width
            };
            raw.min(safe_scene_width)
        };
        let source_viewport_height = {
            let raw = if draw.view_height > 0 {
                draw.view_height
            } else {
                safe_scene_height
            };
            raw.min(safe_scene_height)
        };
        let safe_max_mip_dimension = draw.max_mip_dimension.max(4);
        let mip_count = bloom2d_effective_mip_count(safe_max_mip_dimension) as u32;
        let downsample_first_pipeline = if use_uniform_scale {
            if use_prefilter {
                self.mesh
                    .bloom2d_downsample_first_uniform_pipeline
                    .as_ref()
                    .cloned()
            } else {
                self.mesh
                    .bloom2d_downsample_first_no_threshold_uniform_pipeline
                    .as_ref()
                    .cloned()
            }
        } else if use_prefilter {
            self.mesh
                .bloom2d_downsample_first_pipeline
                .as_ref()
                .cloned()
        } else {
            self.mesh
                .bloom2d_downsample_first_no_threshold_pipeline
                .as_ref()
                .cloned()
        };
        let downsample_pipeline = if use_uniform_scale {
            self.mesh
                .bloom2d_downsample_uniform_pipeline
                .as_ref()
                .cloned()
        } else {
            self.mesh.bloom2d_downsample_pipeline.as_ref().cloned()
        };
        let upsample_pipeline = if draw.composite_mode == 0 {
            self.mesh.bloom2d_upsample_pipeline_energy.as_ref().cloned()
        } else {
            self.mesh
                .bloom2d_upsample_pipeline_additive
                .as_ref()
                .cloned()
        };
        let mut bloom_ready = bloom_enabled
            && intensity > 0.0
            && downsample_first_pipeline.is_some()
            && downsample_pipeline.is_some()
            && upsample_pipeline.is_some();
        let mut max_mip_f: f32 = 1.0;
        if bloom_ready {
            let mip_height_ratio = safe_max_mip_dimension as f64 / safe_viewport_height as f64;
            let bloom_width = ((safe_viewport_width as f64 * mip_height_ratio + 0.5) as i32).max(1);
            let bloom_height =
                ((safe_viewport_height as f64 * mip_height_ratio + 0.5) as i32).max(1);
            self.ensure_bloom2d_mip_texture(mip_count, bloom_width as u32, bloom_height as u32)?;
            if self.mesh.bloom2d_mip_views.len() < mip_count as usize {
                bloom_ready = false;
            } else {
                let bloom_words = bloom2d_uniform_words(
                    safe_scene_width as f32,
                    safe_scene_height as f32,
                    0.0,
                    0.0,
                    source_viewport_width as f32,
                    source_viewport_height as f32,
                    threshold,
                    threshold_softness,
                    scale_x,
                    scale_y,
                    tonemapping_mode,
                    deband_dither_enabled,
                    bloom_weight,
                    0.0,
                    fxaa_enabled,
                    fxaa_edge_threshold,
                    chromatic_aberration_strength,
                    vignette_strength,
                );
                self.queue
                    .write_buffer(settings_buf, 0, bytemuck::cast_slice(&bloom_words));
                let first_bg = self.create_bloom2d_bind_group(
                    bind_layout,
                    scene_view,
                    bloom_sampler,
                    settings_buf,
                    scene_view,
                    lut_view,
                    "mgstudio_bloom2d_downsample_first_bg",
                );
                let mut first_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                    label: Some("mgstudio-bloom2d-downsample-first"),
                    color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                        view: &self.mesh.bloom2d_mip_views[0],
                        depth_slice: None,
                        resolve_target: None,
                        ops: wgpu::Operations {
                            load: wgpu::LoadOp::Clear(wgpu::Color {
                                r: 0.0,
                                g: 0.0,
                                b: 0.0,
                                a: 1.0,
                            }),
                            store: wgpu::StoreOp::Store,
                        },
                    })],
                    depth_stencil_attachment: None,
                    timestamp_writes: None,
                    occlusion_query_set: None,
                    multiview_mask: None,
                });
                let mut mip_size_w = bloom_width;
                let mut mip_size_h = bloom_height;
                first_pass.set_viewport(0.0, 0.0, mip_size_w as f32, mip_size_h as f32, 0.0, 1.0);
                first_pass.set_scissor_rect(0, 0, mip_size_w as u32, mip_size_h as u32);
                first_pass.set_pipeline(downsample_first_pipeline.as_ref().unwrap());
                first_pass.set_bind_group(0, &first_bg, &[]);
                first_pass.draw(0..3, 0..1);
                drop(first_pass);
                for mip in 1..mip_count as usize {
                    if !bloom_ready {
                        break;
                    }
                    let down_bg = self.create_bloom2d_bind_group(
                        bind_layout,
                        &self.mesh.bloom2d_mip_views[mip - 1],
                        bloom_sampler,
                        settings_buf,
                        scene_view,
                        lut_view,
                        "mgstudio_bloom2d_downsample_bg",
                    );
                    mip_size_w = if mip_size_w > 1 { mip_size_w / 2 } else { 1 };
                    mip_size_h = if mip_size_h > 1 { mip_size_h / 2 } else { 1 };
                    let mut pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                        label: Some("mgstudio-bloom2d-downsample"),
                        color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                            view: &self.mesh.bloom2d_mip_views[mip],
                            depth_slice: None,
                            resolve_target: None,
                            ops: wgpu::Operations {
                                load: wgpu::LoadOp::Clear(wgpu::Color {
                                    r: 0.0,
                                    g: 0.0,
                                    b: 0.0,
                                    a: 1.0,
                                }),
                                store: wgpu::StoreOp::Store,
                            },
                        })],
                        depth_stencil_attachment: None,
                        timestamp_writes: None,
                        occlusion_query_set: None,
                        multiview_mask: None,
                    });
                    pass.set_viewport(0.0, 0.0, mip_size_w as f32, mip_size_h as f32, 0.0, 1.0);
                    pass.set_scissor_rect(0, 0, mip_size_w as u32, mip_size_h as u32);
                    pass.set_pipeline(downsample_pipeline.as_ref().unwrap());
                    pass.set_bind_group(0, &down_bg, &[]);
                    pass.draw(0..3, 0..1);
                    drop(pass);
                }
                let max_mip = if mip_count > 1 { mip_count - 1 } else { 1 };
                max_mip_f = max_mip as f32;
                let mut upsample_mip = mip_count as i32 - 1;
                while bloom_ready && upsample_mip >= 1 {
                    let blend = bloom2d_compute_blend_factor(
                        intensity,
                        low_frequency_boost,
                        low_frequency_boost_curvature,
                        high_pass_frequency,
                        draw.composite_mode,
                        upsample_mip as f32,
                        max_mip_f,
                    );
                    let up_words = bloom2d_uniform_words(
                        safe_scene_width as f32,
                        safe_scene_height as f32,
                        0.0,
                        0.0,
                        source_viewport_width as f32,
                        source_viewport_height as f32,
                        threshold,
                        threshold_softness,
                        scale_x,
                        scale_y,
                        tonemapping_mode,
                        deband_dither_enabled,
                        bloom_weight,
                        blend,
                        fxaa_enabled,
                        fxaa_edge_threshold,
                        chromatic_aberration_strength,
                        vignette_strength,
                    );
                    self.queue
                        .write_buffer(settings_buf, 0, bytemuck::cast_slice(&up_words));
                    let up_bg = self.create_bloom2d_bind_group(
                        bind_layout,
                        &self.mesh.bloom2d_mip_views[upsample_mip as usize],
                        bloom_sampler,
                        settings_buf,
                        scene_view,
                        lut_view,
                        "mgstudio_bloom2d_upsample_bg",
                    );
                    let size_w = bloom2d_mip_dimension(bloom_width, upsample_mip - 1);
                    let size_h = bloom2d_mip_dimension(bloom_height, upsample_mip - 1);
                    let mut pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                        label: Some("mgstudio-bloom2d-upsample"),
                        color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                            view: &self.mesh.bloom2d_mip_views[upsample_mip as usize - 1],
                            depth_slice: None,
                            resolve_target: None,
                            ops: wgpu::Operations {
                                load: wgpu::LoadOp::Load,
                                store: wgpu::StoreOp::Store,
                            },
                        })],
                        depth_stencil_attachment: None,
                        timestamp_writes: None,
                        occlusion_query_set: None,
                        multiview_mask: None,
                    });
                    pass.set_viewport(0.0, 0.0, size_w as f32, size_h as f32, 0.0, 1.0);
                    pass.set_scissor_rect(0, 0, size_w as u32, size_h as u32);
                    pass.set_pipeline(upsample_pipeline.as_ref().unwrap());
                    pass.set_blend_constant(wgpu::Color {
                        r: blend as f64,
                        g: blend as f64,
                        b: blend as f64,
                        a: blend as f64,
                    });
                    pass.set_bind_group(0, &up_bg, &[]);
                    pass.draw(0..3, 0..1);
                    drop(pass);
                    upsample_mip -= 1;
                }
            }
        }
        let final_bloom_weight = if bloom_ready {
            bloom2d_compute_blend_factor(
                intensity,
                low_frequency_boost,
                low_frequency_boost_curvature,
                high_pass_frequency,
                draw.composite_mode,
                0.0,
                max_mip_f,
            )
        } else {
            0.0
        };
        let final_words = bloom2d_uniform_words(
            safe_scene_width as f32,
            safe_scene_height as f32,
            0.0,
            0.0,
            source_viewport_width as f32,
            source_viewport_height as f32,
            0.0,
            0.0,
            1.0,
            1.0,
            tonemapping_mode,
            deband_dither_enabled,
            final_bloom_weight,
            0.0,
            fxaa_enabled,
            fxaa_edge_threshold,
            chromatic_aberration_strength,
            vignette_strength,
        );
        self.queue
            .write_buffer(settings_buf, 0, bytemuck::cast_slice(&final_words));
        let hdr_view = if bloom_ready {
            &self.mesh.bloom2d_mip_views[0]
        } else {
            scene_view
        };
        let final_bg = self.create_bloom2d_bind_group(
            bind_layout,
            hdr_view,
            bloom_sampler,
            settings_buf,
            scene_view,
            lut_view,
            "mgstudio_bloom2d_final_bg",
        );
        let mut final_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
            label: Some("mgstudio-bloom2d-final"),
            color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                view: target_view,
                depth_slice: None,
                resolve_target: None,
                ops: wgpu::Operations {
                    load: wgpu::LoadOp::Load,
                    store: wgpu::StoreOp::Store,
                },
            })],
            depth_stencil_attachment: None,
            timestamp_writes: None,
            occlusion_query_set: None,
            multiview_mask: None,
        });
        final_pass.set_viewport(
            pass_state.viewport_x as f32,
            pass_state.viewport_y as f32,
            pass_state.viewport_w as f32,
            pass_state.viewport_h as f32,
            pass_state.viewport_depth_min,
            pass_state.viewport_depth_max,
        );
        final_pass.set_scissor_rect(sx, sy, sw, sh);
        final_pass.set_pipeline(final_pipeline);
        final_pass.set_blend_constant(wgpu::Color {
            r: final_bloom_weight as f64,
            g: final_bloom_weight as f64,
            b: final_bloom_weight as f64,
            a: final_bloom_weight as f64,
        });
        final_pass.set_bind_group(0, &final_bg, &[]);
        final_pass.draw(0..3, 0..1);
        drop(final_pass);
        Ok(())
    }

    fn prepare_mesh_uniforms(&mut self, pass: &mut GpuPassRecorder) -> anyhow::Result<()> {
        // Assign dynamic offsets for each mesh draw (alignment is backend-limited).
        let align = self
            .device
            .limits()
            .min_uniform_buffer_offset_alignment
            .max(256) as u64;
        let stride = align_up(MESH_UNIFORM_MAX_BYTES, align);
        let mut buf: Vec<u8> = Vec::new();

        for cmd in &mut pass.commands {
            if let DrawCmd::Mesh(draw) = cmd {
                let offset = align_up(buf.len() as u64, stride);
                if offset as usize > buf.len() {
                    buf.resize(offset as usize, 0);
                }
                let bytes = mesh_uniform_bytes(&pass.st, draw);
                if bytes.len() as u64 > stride {
                    return Err(anyhow!(
                        "wgpu: mesh uniform payload too large: {} > {}",
                        bytes.len(),
                        stride
                    ));
                }
                draw.ubo_offset = offset as u32;
                buf.extend_from_slice(bytes.as_slice());

                // Pad to alignment for the next entry.
                let padded = align_up(buf.len() as u64, stride) as usize;
                if padded > buf.len() {
                    buf.resize(padded, 0);
                }
            }
        }

        self.ensure_mesh_resources()?;
        if buf.is_empty() {
            return Ok(());
        }
        let required = buf.len() as u64;
        if required > self.mesh.uniform_capacity {
            let new_cap = required.max(align);
            let new_buf = self.device.create_buffer(&wgpu::BufferDescriptor {
                label: Some("mgstudio_mesh_uniform_buf_grow"),
                size: new_cap,
                usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
                mapped_at_creation: false,
            });
            let bgl = self.mesh.bgl_uniform.as_ref().unwrap();
            let new_bg = self.device.create_bind_group(&wgpu::BindGroupDescriptor {
                label: Some("mgstudio_mesh_uniform_bg"),
                layout: bgl,
                entries: &[wgpu::BindGroupEntry {
                    binding: 0,
                    resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                        buffer: &new_buf,
                        offset: 0,
                        size: Some(
                            std::num::NonZeroU64::new(self.mesh.uniform_binding_size).ok_or_else(
                                || anyhow!("wgpu: mesh uniform binding size is zero"),
                            )?,
                        ),
                    }),
                }],
            });
            self.mesh.uniform_buf = Some(new_buf);
            self.mesh.uniform_bg = Some(new_bg);
            self.mesh.uniform_capacity = new_cap;
        }
        let ubo = self.mesh.uniform_buf.as_ref().unwrap();
        self.queue.write_buffer(ubo, 0, &buf);
        Ok(())
    }

    #[allow(dead_code)]
    fn encode_mesh_draw(
        &mut self,
        st: &GpuPassState,
        rp: &mut wgpu::RenderPass<'_>,
        draw: &MeshDraw,
    ) -> anyhow::Result<()> {
        self.ensure_mesh_pipeline(st.target_format)?;
        let pipeline = self
            .mesh
            .pipelines
            .get(&st.target_format)
            .ok_or_else(|| anyhow!("wgpu: missing mesh pipeline"))?;
        let bg = self
            .mesh
            .uniform_bg
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: missing mesh uniform bind group"))?;
        let Some(mesh) = self.meshes.get(&draw.mesh_id) else {
            return Ok(());
        };

        rp.set_pipeline(pipeline);
        rp.set_bind_group(0, bg, &[draw.ubo_offset]);
        rp.set_vertex_buffer(0, mesh.vertex_buf.slice(..));
        rp.set_index_buffer(mesh.index_buf.slice(..), wgpu::IndexFormat::Uint16);
        rp.draw_indexed(0..mesh.index_count, 0, 0..1);
        Ok(())
    }
}

impl GpuPassRecorder {
    fn flush_sprites(&mut self) {
        if self.cur_sprites.instance_count == 0 {
            return;
        }
        let seg = SpriteSegment {
            instance_data: std::mem::take(&mut self.cur_sprites.instance_data),
            batches: std::mem::take(&mut self.cur_sprites.batches),
            instance_count: std::mem::take(&mut self.cur_sprites.instance_count),
            scissor: self.cur_sprites.scissor,
        };
        self.cur_sprites.scissor = self.current_scissor;
        self.commands.push(DrawCmd::Sprites(seg));
    }
}

fn pick_surface_format(caps: &wgpu::SurfaceCapabilities) -> wgpu::TextureFormat {
    // Prefer SRGB formats when available (common on Metal).
    for f in caps.formats.iter().copied() {
        if matches!(
            f,
            wgpu::TextureFormat::Bgra8UnormSrgb | wgpu::TextureFormat::Rgba8UnormSrgb
        ) {
            return f;
        }
    }
    caps.formats
        .first()
        .copied()
        .unwrap_or(wgpu::TextureFormat::Bgra8UnormSrgb)
}

fn pick_present_mode(caps: &wgpu::SurfaceCapabilities) -> wgpu::PresentMode {
    if caps.present_modes.contains(&wgpu::PresentMode::Fifo) {
        return wgpu::PresentMode::Fifo;
    }
    caps.present_modes
        .first()
        .copied()
        .unwrap_or(wgpu::PresentMode::Fifo)
}

fn clamp01(value: f32) -> f32 {
    value.clamp(0.0, 1.0)
}

fn bloom2d_ilog2_floor(value: i32) -> i32 {
    let mut v = value.max(1);
    let mut power = 0;
    while v > 1 {
        v /= 2;
        power += 1;
    }
    power
}

fn bloom2d_effective_mip_count(max_mip_dimension: i32) -> i32 {
    let safe_dimension = max_mip_dimension.max(4);
    let ilog2 = bloom2d_ilog2_floor(safe_dimension);
    let count = if ilog2 < 2 { 1 } else { ilog2 - 1 };
    count.max(1)
}

fn bloom2d_mip_dimension(base: i32, mip: i32) -> i32 {
    let mut value = base.max(1);
    for _ in 0..mip.max(0) {
        value = if value > 1 { value / 2 } else { 1 };
    }
    value.max(1)
}

fn bloom2d_compute_blend_factor(
    intensity: f32,
    low_frequency_boost: f32,
    low_frequency_boost_curvature: f32,
    high_pass_frequency: f32,
    composite_mode: i32,
    mip: f32,
    max_mip: f32,
) -> f32 {
    let safe_max_mip = if max_mip <= 0.0 { 1.0 } else { max_mip };
    let mip_ratio = clamp01(mip / safe_max_mip);
    let safe_curvature = if low_frequency_boost_curvature >= 0.999 {
        0.999
    } else {
        low_frequency_boost_curvature
    };
    let curvature_factor = 1.0 / (1.0 - safe_curvature);
    let one_minus_mip = 1.0 - mip_ratio;
    let lf_pow = one_minus_mip.powf(curvature_factor);
    let mut low_freq = (1.0 - lf_pow) * low_frequency_boost;
    let safe_high_pass = if high_pass_frequency <= 0.0001 {
        0.0001
    } else {
        high_pass_frequency
    };
    let high_pass_lq = 1.0 - clamp01((mip_ratio - high_pass_frequency) / safe_high_pass);
    let mode_factor = if composite_mode == 0 {
        1.0 - intensity
    } else {
        1.0
    };
    low_freq *= mode_factor;
    (intensity + low_freq) * high_pass_lq
}

#[allow(clippy::too_many_arguments)]
fn bloom2d_uniform_words(
    source_width: f32,
    source_height: f32,
    source_viewport_x: f32,
    source_viewport_y: f32,
    source_viewport_width: f32,
    source_viewport_height: f32,
    threshold: f32,
    threshold_softness: f32,
    scale_x: f32,
    scale_y: f32,
    tonemapping_mode: f32,
    deband_dither_enabled: f32,
    bloom_weight: f32,
    upsample_blend: f32,
    fxaa_enabled: f32,
    fxaa_edge_threshold: f32,
    chromatic_aberration_strength: f32,
    vignette_strength: f32,
) -> [u32; 20] {
    let softness = threshold_softness;
    let knee = threshold * softness;
    let safe_source_width = if source_width > 0.0 {
        source_width
    } else {
        1.0
    };
    let safe_source_height = if source_height > 0.0 {
        source_height
    } else {
        1.0
    };
    let safe_viewport_width = if source_viewport_width > 0.0 {
        source_viewport_width
    } else {
        safe_source_width
    };
    let safe_viewport_height = if source_viewport_height > 0.0 {
        source_viewport_height
    } else {
        safe_source_height
    };
    let aspect = if safe_viewport_height > 0.0 {
        safe_viewport_width / safe_viewport_height
    } else {
        1.0
    };
    [
        threshold.to_bits(),
        (threshold - knee).to_bits(),
        (2.0 * knee).to_bits(),
        (0.25 / (knee + 0.00001)).to_bits(),
        (source_viewport_x / safe_source_width).to_bits(),
        (source_viewport_y / safe_source_height).to_bits(),
        (safe_viewport_width / safe_source_width).to_bits(),
        (safe_viewport_height / safe_source_height).to_bits(),
        scale_x.to_bits(),
        scale_y.to_bits(),
        aspect.to_bits(),
        0.0f32.to_bits(),
        tonemapping_mode.to_bits(),
        deband_dither_enabled.to_bits(),
        bloom_weight.to_bits(),
        upsample_blend.to_bits(),
        fxaa_enabled.to_bits(),
        fxaa_edge_threshold.to_bits(),
        chromatic_aberration_strength.to_bits(),
        vignette_strength.to_bits(),
    ]
}

fn resolve_scissor_rect(
    pass: &GpuPassState,
    requested: Option<ScissorRect>,
    target_width: u32,
    target_height: u32,
) -> Option<(u32, u32, u32, u32)> {
    let default = ScissorRect {
        x: pass.viewport_x,
        y: pass.viewport_y,
        w: pass.viewport_w,
        h: pass.viewport_h,
    };
    let mut scissor = requested.unwrap_or(default);
    if scissor.w == 0 || scissor.h == 0 || target_width == 0 || target_height == 0 {
        return None;
    }
    if scissor.x >= target_width || scissor.y >= target_height {
        return None;
    }
    if scissor.x.saturating_add(scissor.w) > target_width {
        scissor.w = target_width.saturating_sub(scissor.x);
    }
    if scissor.y.saturating_add(scissor.h) > target_height {
        scissor.h = target_height.saturating_sub(scissor.y);
    }
    if scissor.w == 0 || scissor.h == 0 {
        return None;
    }
    Some((scissor.x, scissor.y, scissor.w, scissor.h))
}

pub(crate) fn load_wgsl_from_assets_required(
    assets_base: &str,
    rel: &str,
) -> anyhow::Result<String> {
    load_wgsl_required(assets_base, rel)
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash, PartialOrd, Ord)]
#[allow(dead_code)]
enum WgslShaderDefValue {
    Bool(bool),
    Int(i32),
    UInt(u32),
}

impl WgslShaderDefValue {
    fn value_as_string(self) -> String {
        match self {
            Self::Bool(value) => value.to_string(),
            Self::Int(value) => value.to_string(),
            Self::UInt(value) => value.to_string(),
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq, Hash)]
struct WgslComposeCacheKey {
    root_path: String,
    defines: Vec<(String, WgslShaderDefValue)>,
}

impl WgslComposeCacheKey {
    fn new(root_path: &str, shader_defs: &HashMap<String, WgslShaderDefValue>) -> Self {
        let mut defines = shader_defs
            .iter()
            .map(|(key, value)| (key.clone(), *value))
            .collect::<Vec<_>>();
        defines.sort_by(|a, b| a.0.cmp(&b.0).then_with(|| a.1.cmp(&b.1)));
        Self {
            root_path: root_path.to_string(),
            defines,
        }
    }
}

#[derive(Default, Clone)]
struct WgslModuleIndex {
    indexed_modules: HashMap<String, String>,
    fallback_modules: HashMap<String, String>,
}

#[derive(Clone, Copy)]
struct WgslConditionalFrame {
    parent_active: bool,
    branch_taken: bool,
    current_active: bool,
}

#[derive(Clone, Debug, PartialEq, Eq)]
struct WgslImportPath {
    full_path: String,
    used_name: String,
}

#[derive(Clone, Debug, PartialEq, Eq)]
enum WgslImportToken {
    Ident(String),
    Scope,
    LBrace,
    RBrace,
    Comma,
    Semicolon,
    As,
}

#[derive(Clone, Debug, PartialEq, Eq)]
enum WgslIfExprToken {
    Ident(String),
    Bool(bool),
    Number(i128),
    LParen,
    RParen,
    Op(String),
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum WgslIfExprValue {
    Bool(bool),
    Number(i128),
}

impl WgslIfExprValue {
    fn truthy(self) -> bool {
        match self {
            Self::Bool(value) => value,
            Self::Number(value) => value != 0,
        }
    }

    fn as_number(self) -> i128 {
        match self {
            Self::Bool(value) => i128::from(value),
            Self::Number(value) => value,
        }
    }
}

struct WgslIfExprParser<'a> {
    tokens: &'a [WgslIfExprToken],
    cursor: usize,
    shader_defs: &'a HashMap<String, WgslShaderDefValue>,
}

impl<'a> WgslIfExprParser<'a> {
    fn new(
        tokens: &'a [WgslIfExprToken],
        shader_defs: &'a HashMap<String, WgslShaderDefValue>,
    ) -> Self {
        Self {
            tokens,
            cursor: 0,
            shader_defs,
        }
    }

    fn parse_expression(&mut self) -> Option<WgslIfExprValue> {
        self.parse_logical_or()
    }

    fn parse_logical_or(&mut self) -> Option<WgslIfExprValue> {
        let mut value = self.parse_logical_and()?;
        while self.consume_operator("||") {
            let rhs = self.parse_logical_and()?;
            value = WgslIfExprValue::Bool(value.truthy() || rhs.truthy());
        }
        Some(value)
    }

    fn parse_logical_and(&mut self) -> Option<WgslIfExprValue> {
        let mut value = self.parse_equality()?;
        while self.consume_operator("&&") {
            let rhs = self.parse_equality()?;
            value = WgslIfExprValue::Bool(value.truthy() && rhs.truthy());
        }
        Some(value)
    }

    fn parse_equality(&mut self) -> Option<WgslIfExprValue> {
        let mut value = self.parse_relational()?;
        loop {
            if self.consume_operator("==") {
                let rhs = self.parse_relational()?;
                value = WgslIfExprValue::Bool(match (value, rhs) {
                    (WgslIfExprValue::Bool(a), WgslIfExprValue::Bool(b)) => a == b,
                    (a, b) => a.as_number() == b.as_number(),
                });
                continue;
            }
            if self.consume_operator("!=") {
                let rhs = self.parse_relational()?;
                value = WgslIfExprValue::Bool(match (value, rhs) {
                    (WgslIfExprValue::Bool(a), WgslIfExprValue::Bool(b)) => a != b,
                    (a, b) => a.as_number() != b.as_number(),
                });
                continue;
            }
            break;
        }
        Some(value)
    }

    fn parse_relational(&mut self) -> Option<WgslIfExprValue> {
        let mut value = self.parse_additive()?;
        loop {
            if self.consume_operator(">=") {
                let rhs = self.parse_additive()?;
                value = WgslIfExprValue::Bool(value.as_number() >= rhs.as_number());
                continue;
            }
            if self.consume_operator("<=") {
                let rhs = self.parse_additive()?;
                value = WgslIfExprValue::Bool(value.as_number() <= rhs.as_number());
                continue;
            }
            if self.consume_operator(">") {
                let rhs = self.parse_additive()?;
                value = WgslIfExprValue::Bool(value.as_number() > rhs.as_number());
                continue;
            }
            if self.consume_operator("<") {
                let rhs = self.parse_additive()?;
                value = WgslIfExprValue::Bool(value.as_number() < rhs.as_number());
                continue;
            }
            break;
        }
        Some(value)
    }

    fn parse_additive(&mut self) -> Option<WgslIfExprValue> {
        let mut value = self.parse_multiplicative()?;
        loop {
            if self.consume_operator("+") {
                let rhs = self.parse_multiplicative()?;
                value = WgslIfExprValue::Number(value.as_number().saturating_add(rhs.as_number()));
                continue;
            }
            if self.consume_operator("-") {
                let rhs = self.parse_multiplicative()?;
                value = WgslIfExprValue::Number(value.as_number().saturating_sub(rhs.as_number()));
                continue;
            }
            break;
        }
        Some(value)
    }

    fn parse_multiplicative(&mut self) -> Option<WgslIfExprValue> {
        let mut value = self.parse_unary()?;
        loop {
            if self.consume_operator("*") {
                let rhs = self.parse_unary()?;
                value = WgslIfExprValue::Number(value.as_number().saturating_mul(rhs.as_number()));
                continue;
            }
            if self.consume_operator("/") {
                let rhs = self.parse_unary()?;
                let divisor = rhs.as_number();
                value = if divisor == 0 {
                    WgslIfExprValue::Number(0)
                } else {
                    WgslIfExprValue::Number(value.as_number() / divisor)
                };
                continue;
            }
            if self.consume_operator("%") {
                let rhs = self.parse_unary()?;
                let divisor = rhs.as_number();
                value = if divisor == 0 {
                    WgslIfExprValue::Number(0)
                } else {
                    WgslIfExprValue::Number(value.as_number() % divisor)
                };
                continue;
            }
            break;
        }
        Some(value)
    }

    fn parse_unary(&mut self) -> Option<WgslIfExprValue> {
        if self.consume_operator("!") {
            let value = self.parse_unary()?;
            return Some(WgslIfExprValue::Bool(!value.truthy()));
        }
        if self.consume_operator("+") {
            let value = self.parse_unary()?;
            return Some(WgslIfExprValue::Number(value.as_number()));
        }
        if self.consume_operator("-") {
            let value = self.parse_unary()?;
            return Some(WgslIfExprValue::Number(value.as_number().saturating_neg()));
        }
        self.parse_primary()
    }

    fn parse_primary(&mut self) -> Option<WgslIfExprValue> {
        let token = self.tokens.get(self.cursor)?;
        match token {
            WgslIfExprToken::Bool(value) => {
                self.cursor += 1;
                Some(WgslIfExprValue::Bool(*value))
            }
            WgslIfExprToken::Number(value) => {
                self.cursor += 1;
                Some(WgslIfExprValue::Number(*value))
            }
            WgslIfExprToken::Ident(name) => {
                self.cursor += 1;
                Some(match self.shader_defs.get(name) {
                    Some(WgslShaderDefValue::Bool(value)) => WgslIfExprValue::Bool(*value),
                    Some(WgslShaderDefValue::Int(value)) => {
                        WgslIfExprValue::Number(i128::from(*value))
                    }
                    Some(WgslShaderDefValue::UInt(value)) => {
                        WgslIfExprValue::Number(i128::from(*value))
                    }
                    None => WgslIfExprValue::Number(0),
                })
            }
            WgslIfExprToken::LParen => {
                self.cursor += 1;
                let value = self.parse_expression()?;
                if self.consume_rparen() {
                    Some(value)
                } else {
                    None
                }
            }
            _ => None,
        }
    }

    fn consume_operator(&mut self, op: &str) -> bool {
        match self.tokens.get(self.cursor) {
            Some(WgslIfExprToken::Op(token_op)) if token_op == op => {
                self.cursor += 1;
                true
            }
            _ => false,
        }
    }

    fn consume_rparen(&mut self) -> bool {
        match self.tokens.get(self.cursor) {
            Some(WgslIfExprToken::RParen) => {
                self.cursor += 1;
                true
            }
            _ => false,
        }
    }
}

static WGSL_COMPOSE_CACHE: OnceLock<Mutex<HashMap<WgslComposeCacheKey, String>>> = OnceLock::new();
static WGSL_MODULE_INDEX_CACHE: OnceLock<Mutex<HashMap<String, Arc<WgslModuleIndex>>>> =
    OnceLock::new();

const WGSL_MODULE_INDEX_CANDIDATES: &[&str] = &[
    "module_index.json",
    "module-index.json",
    "modules.json",
    "index.json",
    "module_index.txt",
    "module-index.txt",
    "modules.txt",
    "index.txt",
    "module_index",
    "index",
];

fn load_wgsl_required(assets_base: &str, rel: &str) -> anyhow::Result<String> {
    let shader_defs = HashMap::<String, WgslShaderDefValue>::new();
    load_wgsl_with_shader_defs_required(assets_base, rel, &shader_defs)
}

fn load_wgsl_with_shader_defs_required(
    assets_base: &str,
    rel: &str,
    shader_defs: &HashMap<String, WgslShaderDefValue>,
) -> anyhow::Result<String> {
    let base = assets_base.trim();
    if base.is_empty() {
        return Err(anyhow!(
            "wgpu: assets_base is empty; cannot load shader: {rel}"
        ));
    }
    let normalized_rel = normalize_shader_rel_path(rel);
    let cache_key = WgslComposeCacheKey::new(&normalized_rel, shader_defs);
    if let Some(cached) = wgsl_compose_cache_get(&cache_key) {
        return Ok(cached);
    }

    let module_index = load_wgsl_module_index_cached(base);
    let mut visited = HashSet::<String>::new();
    let mut source = load_wgsl_preprocessed(
        base,
        module_index.as_ref(),
        &normalized_rel,
        shader_defs,
        &mut visited,
    )?;
    if is_motion_blur_shader_path(&normalized_rel) {
        source = lower_motion_blur_texture_samples_for_runtime(source);
    }
    wgsl_compose_cache_insert(cache_key, source.clone());
    Ok(source)
}

fn wgsl_compose_cache_get(key: &WgslComposeCacheKey) -> Option<String> {
    WGSL_COMPOSE_CACHE
        .get_or_init(|| Mutex::new(HashMap::new()))
        .lock()
        .ok()
        .and_then(|cache| cache.get(key).cloned())
}

fn wgsl_compose_cache_insert(key: WgslComposeCacheKey, value: String) {
    if let Ok(mut cache) = WGSL_COMPOSE_CACHE
        .get_or_init(|| Mutex::new(HashMap::new()))
        .lock()
    {
        cache.insert(key, value);
    }
}

fn load_wgsl_module_index_cached(assets_base: &str) -> Arc<WgslModuleIndex> {
    if let Ok(mut cache) = WGSL_MODULE_INDEX_CACHE
        .get_or_init(|| Mutex::new(HashMap::new()))
        .lock()
    {
        if let Some(index) = cache.get(assets_base) {
            return Arc::clone(index);
        }
        let index = Arc::new(build_wgsl_module_index(assets_base));
        cache.insert(assets_base.to_string(), Arc::clone(&index));
        return index;
    }
    Arc::new(build_wgsl_module_index(assets_base))
}

fn build_wgsl_module_index(assets_base: &str) -> WgslModuleIndex {
    let bevy_root = Path::new(assets_base).join("shaders/bevy");
    let mut indexed_modules = HashMap::<String, String>::new();
    let mut fallback_modules = HashMap::<String, String>::new();

    if !bevy_root.is_dir() {
        return WgslModuleIndex {
            indexed_modules,
            fallback_modules,
        };
    }

    for name in WGSL_MODULE_INDEX_CANDIDATES {
        let path = bevy_root.join(name);
        if !path.is_file() {
            continue;
        }
        if let Ok(contents) = std::fs::read_to_string(&path) {
            let parsed = parse_wgsl_module_index_text(&contents);
            for (module_name, rel_path) in parsed {
                indexed_modules
                    .entry(module_name)
                    .and_modify(|current| {
                        if rel_path < *current {
                            *current = rel_path.clone();
                        }
                    })
                    .or_insert(rel_path);
            }
        }
        break;
    }

    let mut files = collect_wgsl_files(&bevy_root);
    files.sort();
    for file in files {
        let rel_inside_bevy = match file.strip_prefix(&bevy_root) {
            Ok(path) => path.to_string_lossy().replace('\\', "/"),
            Err(_) => continue,
        };
        let rel_path = format!("shaders/bevy/{rel_inside_bevy}");
        let module_from_path = module_name_from_rel_wgsl_path(&rel_path);
        if !module_from_path.is_empty() {
            fallback_modules
                .entry(module_from_path)
                .and_modify(|current| {
                    if rel_path < *current {
                        *current = rel_path.clone();
                    }
                })
                .or_insert_with(|| rel_path.clone());
        }

        if let Ok(source) = std::fs::read_to_string(&file) {
            if let Some(module_name) = parse_define_import_path_from_source(&source) {
                fallback_modules
                    .entry(module_name)
                    .and_modify(|current| {
                        if rel_path < *current {
                            *current = rel_path.clone();
                        }
                    })
                    .or_insert(rel_path.clone());
            }
        }
    }

    WgslModuleIndex {
        indexed_modules,
        fallback_modules,
    }
}

fn parse_wgsl_module_index_text(text: &str) -> HashMap<String, String> {
    let mut entries = HashMap::<String, String>::new();

    if let Ok(json) = serde_json::from_str::<serde_json::Value>(text) {
        ingest_wgsl_module_index_json(&json, &mut entries);
    }

    if entries.is_empty() {
        for line in text.lines() {
            if let Some((module_name, rel_path)) = parse_wgsl_module_index_line(line) {
                insert_wgsl_module_index_entry(&mut entries, module_name, rel_path);
            }
        }
    }

    entries
}

fn ingest_wgsl_module_index_json(node: &serde_json::Value, out: &mut HashMap<String, String>) {
    match node {
        serde_json::Value::Array(items) => {
            for item in items {
                if let serde_json::Value::Array(pair) = item {
                    if pair.len() >= 2 {
                        if let (Some(module_raw), Some(path_raw)) =
                            (pair[0].as_str(), pair[1].as_str())
                        {
                            insert_wgsl_module_index_entry(
                                out,
                                normalize_wgsl_module_name_from_index(module_raw),
                                normalize_wgsl_module_rel_path(path_raw, module_raw),
                            );
                        }
                    }
                }
                ingest_wgsl_module_index_json(item, out);
            }
        }
        serde_json::Value::Object(map) => {
            let module_hint = map
                .get("module")
                .or_else(|| map.get("name"))
                .or_else(|| map.get("key"))
                .and_then(|value| value.as_str());
            let path_hint = map
                .get("path")
                .or_else(|| map.get("file"))
                .or_else(|| map.get("rel_path"))
                .or_else(|| map.get("value"))
                .and_then(|value| value.as_str());

            if let (Some(module_raw), Some(path_raw)) = (module_hint, path_hint) {
                insert_wgsl_module_index_entry(
                    out,
                    normalize_wgsl_module_name_from_index(module_raw),
                    normalize_wgsl_module_rel_path(path_raw, module_raw),
                );
            }

            for (key, value) in map {
                if let Some(path_raw) = value.as_str() {
                    insert_wgsl_module_index_entry(
                        out,
                        normalize_wgsl_module_name_from_index(key),
                        normalize_wgsl_module_rel_path(path_raw, key),
                    );
                    continue;
                }
                ingest_wgsl_module_index_json(value, out);
            }
        }
        _ => {}
    }
}

fn insert_wgsl_module_index_entry(
    out: &mut HashMap<String, String>,
    module_name: String,
    rel_path: String,
) {
    if module_name.is_empty() || rel_path.is_empty() {
        return;
    }
    out.entry(module_name)
        .and_modify(|current| {
            if rel_path < *current {
                *current = rel_path.clone();
            }
        })
        .or_insert(rel_path);
}

fn parse_wgsl_module_index_line(line: &str) -> Option<(String, String)> {
    let line = line
        .split('#')
        .next()
        .unwrap_or("")
        .split("//")
        .next()
        .unwrap_or("")
        .trim();
    if line.is_empty() {
        return None;
    }

    let (module_token, path_token) = if let Some(idx) = line.find('=') {
        (line[..idx].trim(), line[idx + 1..].trim())
    } else {
        let mut parts = line.split_whitespace();
        let module = parts.next()?;
        let path = parts.next().unwrap_or("");
        (module, path)
    };

    let module_name = normalize_wgsl_module_name_from_index(module_token);
    if module_name.is_empty() {
        return None;
    }
    let rel_path = normalize_wgsl_module_rel_path(path_token, &module_name);
    Some((module_name, rel_path))
}

fn normalize_wgsl_module_name_from_index(token: &str) -> String {
    let token = token.trim().trim_matches('"');
    if token.is_empty() {
        return String::new();
    }
    if token.contains("::") {
        return normalize_wgsl_module_name(token);
    }
    if token.contains('/') || token.ends_with(".wgsl") || token.starts_with("shaders/") {
        let mut rel = normalize_shader_rel_path(token);
        if !rel.ends_with(".wgsl") {
            rel.push_str(".wgsl");
        }
        if !rel.starts_with("shaders/") {
            if rel.starts_with("bevy/") {
                rel = format!("shaders/{rel}");
            } else {
                rel = format!("shaders/bevy/{rel}");
            }
        }
        return module_name_from_rel_wgsl_path(&rel);
    }
    normalize_wgsl_module_name(token)
}

fn normalize_wgsl_module_rel_path(path_token: &str, module_name: &str) -> String {
    let token = path_token.trim().trim_matches('"');
    if token.is_empty() {
        return format!("shaders/bevy/{}.wgsl", module_name.replace("::", "/"));
    }
    if token.contains("::") {
        return format!(
            "shaders/bevy/{}.wgsl",
            normalize_wgsl_module_name(token).replace("::", "/")
        );
    }
    let mut rel = normalize_shader_rel_path(token);
    if !rel.ends_with(".wgsl") {
        rel.push_str(".wgsl");
    }
    if rel.starts_with("shaders/") {
        return rel;
    }
    if rel.starts_with("bevy/") {
        return format!("shaders/{rel}");
    }
    format!("shaders/bevy/{rel}")
}

fn module_name_from_rel_wgsl_path(rel_path: &str) -> String {
    let normalized = normalize_shader_rel_path(rel_path);
    let Some(rest) = normalized.strip_prefix("shaders/bevy/") else {
        return String::new();
    };
    let Some(stem) = rest.strip_suffix(".wgsl") else {
        return String::new();
    };
    if stem.is_empty() {
        return String::new();
    }
    stem.replace('/', "::")
}

fn parse_define_import_path_from_source(source: &str) -> Option<String> {
    for line in source.lines() {
        if let Some(value) = strip_wgsl_directive_arg(line.trim(), "define_import_path") {
            let module_name = normalize_wgsl_module_name(value);
            if !module_name.is_empty() {
                return Some(module_name);
            }
        }
    }
    None
}

fn collect_wgsl_files(root: &Path) -> Vec<PathBuf> {
    if !root.is_dir() {
        return Vec::new();
    }
    let mut stack = vec![root.to_path_buf()];
    let mut files = Vec::new();
    while let Some(dir) = stack.pop() {
        let entries = match std::fs::read_dir(&dir) {
            Ok(entries) => entries,
            Err(_) => continue,
        };
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                stack.push(path);
                continue;
            }
            if path
                .extension()
                .and_then(|ext| ext.to_str())
                .is_some_and(|ext| ext.eq_ignore_ascii_case("wgsl"))
            {
                files.push(path);
            }
        }
    }
    files
}

fn load_wgsl_preprocessed(
    assets_base: &str,
    module_index: &WgslModuleIndex,
    rel: &str,
    shader_defs: &HashMap<String, WgslShaderDefValue>,
    visited: &mut HashSet<String>,
) -> anyhow::Result<String> {
    let normalized_rel = normalize_shader_rel_path(rel);
    if !visited.insert(normalized_rel.clone()) {
        return Ok(String::new());
    }
    let full = std::path::Path::new(assets_base).join(&normalized_rel);
    let source = std::fs::read_to_string(&full)
        .with_context(|| format!("wgpu: failed to read shader: {}", full.display()))?;
    preprocess_wgsl_source(assets_base, module_index, &source, shader_defs, visited)
}

fn preprocess_wgsl_source(
    assets_base: &str,
    module_index: &WgslModuleIndex,
    source: &str,
    shader_defs: &HashMap<String, WgslShaderDefValue>,
    visited: &mut HashSet<String>,
) -> anyhow::Result<String> {
    let conditioned_source = apply_wgsl_conditionals(source, shader_defs);
    let mut imported_source = String::new();
    let mut aliases: Vec<String> = Vec::new();

    let lines = conditioned_source.lines().collect::<Vec<_>>();
    let mut line_idx = 0usize;
    while line_idx < lines.len() {
        let line = lines[line_idx];
        let trimmed = line.trim();

        if strip_wgsl_directive_arg(trimmed, "define_import_path").is_some() {
            line_idx += 1;
            continue;
        }

        if is_wgsl_import_directive(trimmed) {
            let (import_block, consumed) = collect_wgsl_import_block(&lines, line_idx);
            let import_paths = parse_wgsl_import_block(&import_block).with_context(|| {
                format!(
                    "wgpu: failed to parse WGSL import block: {}",
                    import_block.trim()
                )
            })?;
            for import_path in import_paths {
                if should_skip_wgsl_import_for_shader_defs(&import_path.full_path, shader_defs) {
                    continue;
                }
                let (module_rel_path, resolved_exact) = resolve_wgsl_import_module_path(
                    assets_base,
                    module_index,
                    &import_path.full_path,
                )
                .ok_or_else(|| {
                    anyhow!(
                        "wgpu: failed to resolve WGSL import path: {}",
                        import_path.full_path
                    )
                })?;
                if resolved_exact && !import_path.used_name.is_empty() {
                    aliases.push(import_path.used_name.clone());
                }
                let mut module_source = load_wgsl_preprocessed(
                    assets_base,
                    module_index,
                    &module_rel_path,
                    shader_defs,
                    visited,
                )?;
                if !resolved_exact
                    && module_rel_path.ends_with("bevy_render/view.wgsl")
                    && import_leaf_symbol(&import_path.full_path)
                        .as_deref()
                        .is_some_and(wgsl_symbol_looks_like_type)
                {
                    module_source = strip_wgsl_top_level_functions(&module_source);
                }
                if !module_source.is_empty() {
                    imported_source.push_str(&module_source);
                    if !module_source.ends_with('\n') {
                        imported_source.push('\n');
                    }
                }
            }
            line_idx += consumed;
            continue;
        }

        imported_source.push_str(line);
        imported_source.push('\n');
        line_idx += 1;
    }

    let mut out = apply_wgsl_shader_def_substitutions(&imported_source, shader_defs);
    for alias in aliases.into_iter().filter(|alias| !alias.is_empty()) {
        out = out.replace(&format!("{alias}::"), "");
    }
    Ok(out)
}

fn is_wgsl_import_directive(trimmed: &str) -> bool {
    strip_wgsl_directive_arg(trimmed, "import").is_some()
}

fn collect_wgsl_import_block(lines: &[&str], start: usize) -> (String, usize) {
    let mut block = String::new();
    let mut consumed = 0usize;
    let mut brace_balance = 0i32;
    let mut line_idx = start;
    while line_idx < lines.len() {
        let line = lines[line_idx];
        if !block.is_empty() {
            block.push('\n');
        }
        block.push_str(line);
        consumed += 1;

        brace_balance += count_char_occurrences(line, '{') as i32;
        brace_balance -= count_char_occurrences(line, '}') as i32;

        if brace_balance <= 0 {
            break;
        }
        line_idx += 1;
    }
    (block, consumed.max(1))
}

fn count_char_occurrences(text: &str, needle: char) -> usize {
    text.chars().filter(|ch| *ch == needle).count()
}

fn resolve_wgsl_import_module_path(
    assets_base: &str,
    module_index: &WgslModuleIndex,
    import_path: &str,
) -> Option<(String, bool)> {
    let mut candidates = Vec::<String>::new();
    let mut cur = import_path.trim().trim_end_matches(';').to_string();
    while !cur.is_empty() {
        if !candidates.contains(&cur) {
            candidates.push(cur.clone());
        }
        let Some(split) = cur.rfind("::") else {
            break;
        };
        cur = cur[..split].trim().to_string();
    }

    for (index, candidate) in candidates.into_iter().enumerate() {
        if let Some(rel_path) = module_index.resolve_rel_path(assets_base, &candidate) {
            return Some((rel_path, index == 0));
        }
    }
    None
}

impl WgslModuleIndex {
    fn resolve_rel_path(&self, assets_base: &str, module_path: &str) -> Option<String> {
        if let Some(quoted_path) = extract_wgsl_quoted_import_path(module_path) {
            let mut rel_path = normalize_shader_rel_path(&quoted_path);
            if !rel_path.ends_with(".wgsl") {
                rel_path.push_str(".wgsl");
            }
            if !rel_path.starts_with("shaders/") {
                if rel_path.starts_with("bevy/") {
                    rel_path = format!("shaders/{rel_path}");
                } else {
                    rel_path = format!("shaders/bevy/{rel_path}");
                }
            }
            return Some(rel_path);
        }

        let module_path = normalize_wgsl_module_name(module_path);
        if module_path.is_empty() {
            return None;
        }

        if let Some(rel_path) = self.indexed_modules.get(&module_path) {
            return Some(rel_path.clone());
        }
        if let Some(rel_path) = self.fallback_modules.get(&module_path) {
            return Some(rel_path.clone());
        }

        let derived = format!("shaders/bevy/{}.wgsl", module_path.replace("::", "/"));
        let full = Path::new(assets_base).join(&derived);
        if full.is_file() {
            return Some(derived);
        }
        None
    }
}

fn extract_wgsl_quoted_import_path(module_path: &str) -> Option<String> {
    let text = module_path.trim();
    if !text.starts_with('"') {
        return None;
    }
    let rest = &text[1..];
    let end = rest.find('"')?;
    Some(rest[..end].to_string())
}

fn normalize_wgsl_module_name(module: &str) -> String {
    module
        .trim()
        .split("::")
        .map(str::trim)
        .filter(|part| !part.is_empty())
        .collect::<Vec<_>>()
        .join("::")
}

fn wgsl_shader_def_enabled(shader_defs: &HashMap<String, WgslShaderDefValue>, name: &str) -> bool {
    match shader_defs.get(name) {
        Some(WgslShaderDefValue::Bool(v)) => *v,
        Some(WgslShaderDefValue::Int(v)) => *v != 0,
        Some(WgslShaderDefValue::UInt(v)) => *v != 0,
        None => false,
    }
}

fn should_skip_wgsl_import_for_shader_defs(
    import_path: &str,
    shader_defs: &HashMap<String, WgslShaderDefValue>,
) -> bool {
    let normalized = import_path.trim().trim_end_matches(';').trim();
    let environment_map_enabled = wgsl_shader_def_enabled(shader_defs, "ENVIRONMENT_MAP");
    let irradiance_volume_enabled = wgsl_shader_def_enabled(shader_defs, "IRRADIANCE_VOLUME")
        || wgsl_shader_def_enabled(shader_defs, "IRRADIANCE_VOLUMES_ARE_USABLE");
    let ssr_enabled = wgsl_shader_def_enabled(shader_defs, "SCREEN_SPACE_REFLECTIONS");
    if normalized.contains("atmosphere::") && !wgsl_shader_def_enabled(shader_defs, "ATMOSPHERE") {
        return true;
    }
    if normalized.contains("environment_map") && !environment_map_enabled {
        return true;
    }
    if normalized.contains("irradiance_volume") && !irradiance_volume_enabled {
        return true;
    }
    if normalized.contains("light_probe") && !(environment_map_enabled || irradiance_volume_enabled)
    {
        return true;
    }
    if normalized.contains("lightmap") && !wgsl_shader_def_enabled(shader_defs, "LIGHTMAP") {
        return true;
    }
    if normalized.contains("ssr") && !ssr_enabled {
        return true;
    }
    if normalized.contains("raymarch") && !ssr_enabled {
        return true;
    }
    if normalized.contains("ssao::")
        && !wgsl_shader_def_enabled(shader_defs, "SCREEN_SPACE_AMBIENT_OCCLUSION")
    {
        return true;
    }
    false
}

fn import_leaf_symbol(full_path: &str) -> Option<String> {
    let trimmed = full_path.trim().trim_end_matches(';').trim();
    if trimmed.is_empty() || trimmed.starts_with('"') {
        return None;
    }
    trimmed
        .rsplit("::")
        .next()
        .map(|segment| segment.trim().trim_matches('"').to_string())
}

fn wgsl_symbol_looks_like_type(symbol: &str) -> bool {
    symbol
        .chars()
        .next()
        .is_some_and(|ch| ch.is_ascii_uppercase())
}

fn strip_wgsl_top_level_functions(source: &str) -> String {
    let lines = source.lines().collect::<Vec<_>>();
    let first_fn_index = lines.iter().enumerate().find_map(|(index, line)| {
        let trimmed = line.trim_start();
        if trimmed.starts_with("fn ") {
            return Some(index);
        }
        if trimmed.starts_with('@') {
            let mut lookahead = index + 1;
            while lookahead < lines.len() && lines[lookahead].trim().is_empty() {
                lookahead += 1;
            }
            if lookahead < lines.len() && lines[lookahead].trim_start().starts_with("fn ") {
                return Some(index);
            }
        }
        None
    });
    let Some(first_fn_index) = first_fn_index else {
        return source.to_string();
    };
    if first_fn_index == 0 {
        return String::new();
    }
    let mut out = lines[..first_fn_index].join("\n");
    if !out.is_empty() && !out.ends_with('\n') {
        out.push('\n');
    }
    out
}

fn wgsl_directive_body_without_line_comment(trimmed: &str) -> Option<&str> {
    let text = trimmed.strip_prefix('#')?.trim_start();
    let text = if let Some(index) = text.find("//") {
        &text[..index]
    } else {
        text
    };
    Some(text.trim_end())
}

fn strip_wgsl_directive_arg<'a>(trimmed: &'a str, directive: &str) -> Option<&'a str> {
    let text = wgsl_directive_body_without_line_comment(trimmed)?;
    let rest = text.strip_prefix(directive)?;
    if rest.is_empty() {
        return Some("");
    }
    let Some(first) = rest.chars().next() else {
        return Some("");
    };
    if !first.is_whitespace() {
        return None;
    }
    Some(rest.trim())
}

fn is_wgsl_directive_keyword(trimmed: &str, keyword: &str) -> bool {
    wgsl_directive_body_without_line_comment(trimmed).is_some_and(|text| text.trim() == keyword)
}

fn wgsl_condition_is_active(frames: &[WgslConditionalFrame]) -> bool {
    frames.last().map_or(true, |frame| frame.current_active)
}

fn apply_wgsl_conditional_directive(
    trimmed: &str,
    shader_defs: &HashMap<String, WgslShaderDefValue>,
    frames: &mut Vec<WgslConditionalFrame>,
) -> bool {
    if let Some(name) = strip_wgsl_directive_arg(trimmed, "ifdef") {
        let parent = wgsl_condition_is_active(frames);
        let cond = shader_defs.contains_key(name);
        let current = parent && cond;
        frames.push(WgslConditionalFrame {
            parent_active: parent,
            branch_taken: current,
            current_active: current,
        });
        return true;
    }

    if let Some(name) = strip_wgsl_directive_arg(trimmed, "ifndef") {
        let parent = wgsl_condition_is_active(frames);
        let cond = !shader_defs.contains_key(name);
        let current = parent && cond;
        frames.push(WgslConditionalFrame {
            parent_active: parent,
            branch_taken: current,
            current_active: current,
        });
        return true;
    }

    if let Some(expr) = strip_wgsl_directive_arg(trimmed, "if") {
        let parent = wgsl_condition_is_active(frames);
        let cond = evaluate_wgsl_if_expression(expr, shader_defs);
        let current = parent && cond;
        frames.push(WgslConditionalFrame {
            parent_active: parent,
            branch_taken: current,
            current_active: current,
        });
        return true;
    }

    if let Some(name) = strip_wgsl_directive_arg(trimmed, "else ifdef") {
        if let Some(frame) = frames.last_mut() {
            let cond = shader_defs.contains_key(name);
            let current = frame.parent_active && !frame.branch_taken && cond;
            frame.current_active = current;
            if current {
                frame.branch_taken = true;
            }
        }
        return true;
    }

    if let Some(name) = strip_wgsl_directive_arg(trimmed, "else ifndef") {
        if let Some(frame) = frames.last_mut() {
            let cond = !shader_defs.contains_key(name);
            let current = frame.parent_active && !frame.branch_taken && cond;
            frame.current_active = current;
            if current {
                frame.branch_taken = true;
            }
        }
        return true;
    }

    if is_wgsl_directive_keyword(trimmed, "else") {
        if let Some(frame) = frames.last_mut() {
            let current = frame.parent_active && !frame.branch_taken;
            frame.current_active = current;
            if current {
                frame.branch_taken = true;
            }
        }
        return true;
    }

    if is_wgsl_directive_keyword(trimmed, "endif") {
        if !frames.is_empty() {
            frames.pop();
        }
        return true;
    }

    false
}

fn apply_wgsl_conditionals(
    source: &str,
    shader_defs: &HashMap<String, WgslShaderDefValue>,
) -> String {
    let mut out = String::new();
    let mut frames = Vec::<WgslConditionalFrame>::new();
    for line in source.lines() {
        let trimmed = line.trim();
        if apply_wgsl_conditional_directive(trimmed, shader_defs, &mut frames) {
            continue;
        }
        if wgsl_condition_is_active(&frames) {
            out.push_str(line);
            out.push('\n');
        }
    }
    out
}

fn evaluate_wgsl_if_expression(
    expr: &str,
    shader_defs: &HashMap<String, WgslShaderDefValue>,
) -> bool {
    let tokens = tokenize_wgsl_if_expression(expr);
    if tokens.is_empty() {
        return false;
    }
    let mut parser = WgslIfExprParser::new(&tokens, shader_defs);
    let Some(result) = parser.parse_expression() else {
        return false;
    };
    if parser.cursor != tokens.len() {
        return false;
    }
    result.truthy()
}

fn tokenize_wgsl_if_expression(expr: &str) -> Vec<WgslIfExprToken> {
    let chars = expr.chars().collect::<Vec<_>>();
    let mut tokens = Vec::<WgslIfExprToken>::new();
    let mut idx = 0usize;

    while idx < chars.len() {
        let ch = chars[idx];
        if ch.is_whitespace() {
            idx += 1;
            continue;
        }
        if ch == '(' {
            tokens.push(WgslIfExprToken::LParen);
            idx += 1;
            continue;
        }
        if ch == ')' {
            tokens.push(WgslIfExprToken::RParen);
            idx += 1;
            continue;
        }

        if idx + 1 < chars.len() {
            let op = match (chars[idx], chars[idx + 1]) {
                ('&', '&') => Some("&&"),
                ('|', '|') => Some("||"),
                ('=', '=') => Some("=="),
                ('!', '=') => Some("!="),
                ('<', '=') => Some("<="),
                ('>', '=') => Some(">="),
                _ => None,
            };
            if let Some(op) = op {
                tokens.push(WgslIfExprToken::Op(op.to_string()));
                idx += 2;
                continue;
            }
        }

        if matches!(ch, '!' | '<' | '>' | '+' | '-' | '*' | '/' | '%') {
            tokens.push(WgslIfExprToken::Op(ch.to_string()));
            idx += 1;
            continue;
        }

        if ch.is_ascii_digit() {
            let start = idx;
            idx += 1;
            while idx < chars.len() && chars[idx].is_ascii_digit() {
                idx += 1;
            }
            let literal = chars[start..idx].iter().collect::<String>();
            if idx < chars.len() && matches!(chars[idx], 'u' | 'U') {
                idx += 1;
            }
            if let Ok(value) = literal.parse::<i128>() {
                tokens.push(WgslIfExprToken::Number(value));
                continue;
            }
            return Vec::new();
        }

        if ch.is_ascii_alphabetic() || ch == '_' {
            let start = idx;
            idx += 1;
            while idx < chars.len() && (chars[idx].is_ascii_alphanumeric() || chars[idx] == '_') {
                idx += 1;
            }
            let ident = chars[start..idx].iter().collect::<String>();
            match ident.as_str() {
                "true" => tokens.push(WgslIfExprToken::Bool(true)),
                "false" => tokens.push(WgslIfExprToken::Bool(false)),
                _ => tokens.push(WgslIfExprToken::Ident(ident)),
            }
            continue;
        }

        return Vec::new();
    }
    tokens
}

fn apply_wgsl_shader_def_substitutions(
    source: &str,
    shader_defs: &HashMap<String, WgslShaderDefValue>,
) -> String {
    let mut out = String::with_capacity(source.len());
    let mut cursor = 0usize;
    while let Some(start_rel) = source[cursor..].find("#{") {
        let start = cursor + start_rel;
        out.push_str(&source[cursor..start]);
        let key_start = start + 2;
        let Some(end_rel) = source[key_start..].find('}') else {
            out.push_str(&source[start..]);
            return out;
        };
        let key_end = key_start + end_rel;
        let key = &source[key_start..key_end];
        if is_valid_wgsl_shader_def_key(key) {
            if let Some(value) = shader_defs.get(key) {
                out.push_str(&value.value_as_string());
                cursor = key_end + 1;
                continue;
            }
        }
        out.push_str(&source[start..=key_end]);
        cursor = key_end + 1;
    }
    out.push_str(&source[cursor..]);
    out
}

fn is_valid_wgsl_shader_def_key(key: &str) -> bool {
    let mut chars = key.chars();
    let Some(first) = chars.next() else {
        return false;
    };
    if !(first.is_ascii_alphabetic() || first == '_') {
        return false;
    }
    chars.all(|ch| ch.is_ascii_alphanumeric() || ch == '_')
}

fn parse_wgsl_import_block(import_block: &str) -> anyhow::Result<Vec<WgslImportPath>> {
    let Some(spec) = strip_wgsl_directive_arg(import_block.trim_start(), "import") else {
        return Ok(Vec::new());
    };
    let tokens = tokenize_wgsl_import_spec(spec)?;
    let mut out = Vec::<WgslImportPath>::new();
    let mut cursor = 0usize;
    while cursor < tokens.len() {
        match tokens.get(cursor) {
            Some(WgslImportToken::Comma) => {
                cursor += 1;
            }
            Some(WgslImportToken::Semicolon) => break,
            Some(_) => {
                parse_wgsl_import_item(&tokens, &mut cursor, None, &mut out)?;
                if matches!(tokens.get(cursor), Some(WgslImportToken::Comma)) {
                    cursor += 1;
                }
            }
            None => break,
        }
    }
    Ok(out)
}

fn parse_wgsl_import_item(
    tokens: &[WgslImportToken],
    cursor: &mut usize,
    prefix: Option<&str>,
    out: &mut Vec<WgslImportPath>,
) -> anyhow::Result<()> {
    let segment = parse_wgsl_import_segment(tokens, cursor)?;
    let mut path = String::new();
    if let Some(prefix) = prefix {
        path.push_str(prefix);
        if !prefix.is_empty() && !segment.is_empty() {
            path.push_str("::");
        }
    }
    path.push_str(&segment);

    loop {
        match tokens.get(*cursor) {
            Some(WgslImportToken::Scope) => {
                *cursor += 1;
                if matches!(tokens.get(*cursor), Some(WgslImportToken::LBrace)) {
                    *cursor += 1;
                    loop {
                        if matches!(tokens.get(*cursor), Some(WgslImportToken::RBrace)) {
                            *cursor += 1;
                            break;
                        }
                        parse_wgsl_import_item(tokens, cursor, Some(&path), out)?;
                        if matches!(tokens.get(*cursor), Some(WgslImportToken::Comma)) {
                            *cursor += 1;
                            continue;
                        }
                        if matches!(tokens.get(*cursor), Some(WgslImportToken::RBrace)) {
                            *cursor += 1;
                            break;
                        }
                        return Err(anyhow!("wgpu: malformed WGSL import block"));
                    }
                    return Ok(());
                }
                let next_segment = parse_wgsl_import_segment(tokens, cursor)?;
                path.push_str("::");
                path.push_str(&next_segment);
            }
            _ => break,
        }
    }

    let used_name = if matches!(tokens.get(*cursor), Some(WgslImportToken::As)) {
        *cursor += 1;
        parse_wgsl_import_segment(tokens, cursor)?
    } else {
        path.rsplit("::")
            .next()
            .unwrap_or("")
            .trim_matches('"')
            .to_string()
    };
    out.push(WgslImportPath {
        full_path: path,
        used_name,
    });
    Ok(())
}

fn parse_wgsl_import_segment(
    tokens: &[WgslImportToken],
    cursor: &mut usize,
) -> anyhow::Result<String> {
    match tokens.get(*cursor) {
        Some(WgslImportToken::Ident(segment)) => {
            *cursor += 1;
            Ok(segment.clone())
        }
        _ => Err(anyhow!("wgpu: malformed WGSL import segment")),
    }
}

fn tokenize_wgsl_import_spec(spec: &str) -> anyhow::Result<Vec<WgslImportToken>> {
    let chars = spec.chars().collect::<Vec<_>>();
    let mut tokens = Vec::<WgslImportToken>::new();
    let mut idx = 0usize;
    while idx < chars.len() {
        let ch = chars[idx];
        if ch.is_whitespace() {
            idx += 1;
            continue;
        }

        if ch == '/' && idx + 1 < chars.len() && chars[idx + 1] == '/' {
            break;
        }

        match ch {
            ',' => {
                tokens.push(WgslImportToken::Comma);
                idx += 1;
                continue;
            }
            ';' => {
                tokens.push(WgslImportToken::Semicolon);
                idx += 1;
                continue;
            }
            '{' => {
                tokens.push(WgslImportToken::LBrace);
                idx += 1;
                continue;
            }
            '}' => {
                tokens.push(WgslImportToken::RBrace);
                idx += 1;
                continue;
            }
            ':' => {
                if idx + 1 < chars.len() && chars[idx + 1] == ':' {
                    tokens.push(WgslImportToken::Scope);
                    idx += 2;
                    continue;
                }
                return Err(anyhow!("wgpu: malformed WGSL import: expected `::`"));
            }
            '"' => {
                let start = idx;
                idx += 1;
                while idx < chars.len() && chars[idx] != '"' {
                    idx += 1;
                }
                if idx >= chars.len() {
                    return Err(anyhow!("wgpu: malformed WGSL import: unterminated quote"));
                }
                idx += 1;
                let ident = chars[start..idx].iter().collect::<String>();
                tokens.push(WgslImportToken::Ident(ident));
                continue;
            }
            _ => {}
        }

        if ch.is_ascii_alphabetic() || ch == '_' {
            let start = idx;
            idx += 1;
            while idx < chars.len() && (chars[idx].is_ascii_alphanumeric() || chars[idx] == '_') {
                idx += 1;
            }
            let ident = chars[start..idx].iter().collect::<String>();
            if ident == "as" {
                tokens.push(WgslImportToken::As);
            } else {
                tokens.push(WgslImportToken::Ident(ident));
            }
            continue;
        }

        return Err(anyhow!(
            "wgpu: malformed WGSL import: unexpected token `{ch}`"
        ));
    }
    Ok(tokens)
}

fn normalize_shader_rel_path(rel: &str) -> String {
    let mut text = rel.trim().trim_start_matches('/').to_string();
    while let Some(rest) = text.strip_prefix("./") {
        text = rest.to_string();
    }
    if let Some(rest) = text.strip_prefix("assets/") {
        text = rest.to_string();
    }
    text
}

fn is_motion_blur_shader_path(rel: &str) -> bool {
    normalize_shader_rel_path(rel) == "shaders/mgstudio/3d/motion_blur.wgsl"
}

fn lower_motion_blur_texture_samples_for_runtime(source: String) -> String {
    let mut out = source;
    let replacements = [
        (
            "textureSample(screen_texture, texture_sampler, in.uv)",
            "textureSampleLevel(screen_texture, texture_sampler, in.uv, 0.0)",
        ),
        (
            "textureSample(motion_vectors, texture_sampler, in.uv).rg",
            "textureSampleLevel(motion_vectors, texture_sampler, in.uv, 0.0).rg",
        ),
        (
            "textureSample(depth, texture_sampler, in.uv)",
            "textureLoad(depth, frag_coords, 0)",
        ),
        (
            "textureSample(screen_texture, texture_sampler, sample_uv)",
            "textureSampleLevel(screen_texture, texture_sampler, sample_uv, 0.0)",
        ),
        (
            "textureSample(motion_vectors, texture_sampler, sample_uv).rg",
            "textureSampleLevel(motion_vectors, texture_sampler, sample_uv, 0.0).rg",
        ),
        (
            "textureSample(depth, texture_sampler, sample_uv)",
            "textureLoad(depth, sample_coords, 0)",
        ),
    ];
    for (from, to) in replacements {
        out = out.replace(from, to);
    }
    out
}

fn align_up(v: u64, align: u64) -> u64 {
    if align == 0 {
        return v;
    }
    ((v + align - 1) / align) * align
}

#[derive(Clone, Copy)]
struct TextureBlockInfo {
    block_width: u32,
    block_height: u32,
    block_bytes: u32,
}

impl TextureBlockInfo {
    fn layout(self, width: u32, height: u32) -> anyhow::Result<(u32, u32, usize)> {
        let width = width.max(1);
        let height = height.max(1);
        let blocks_w = width.div_ceil(self.block_width).max(1);
        let blocks_h = height.div_ceil(self.block_height).max(1);
        let bytes_per_row = blocks_w
            .checked_mul(self.block_bytes)
            .ok_or_else(|| anyhow!("wgpu: bytes_per_row overflow"))?;
        let total_bytes_u64 = u64::from(bytes_per_row) * u64::from(blocks_h);
        let total_bytes = usize::try_from(total_bytes_u64)
            .context("wgpu: texture upload size exceeds host usize")?;
        Ok((bytes_per_row, blocks_h, total_bytes))
    }
}

fn texture_block_info(format: wgpu::TextureFormat) -> Option<TextureBlockInfo> {
    match format {
        wgpu::TextureFormat::Rgba8Unorm | wgpu::TextureFormat::Rgba8UnormSrgb => {
            Some(TextureBlockInfo {
                block_width: 1,
                block_height: 1,
                block_bytes: 4,
            })
        }
        wgpu::TextureFormat::Rgb9e5Ufloat => Some(TextureBlockInfo {
            block_width: 1,
            block_height: 1,
            block_bytes: 4,
        }),
        wgpu::TextureFormat::Rgba16Float => Some(TextureBlockInfo {
            block_width: 1,
            block_height: 1,
            block_bytes: 8,
        }),
        wgpu::TextureFormat::Bc7RgbaUnorm | wgpu::TextureFormat::Bc7RgbaUnormSrgb => {
            Some(TextureBlockInfo {
                block_width: 4,
                block_height: 4,
                block_bytes: 16,
            })
        }
        wgpu::TextureFormat::Etc2Rgba8Unorm | wgpu::TextureFormat::Etc2Rgba8UnormSrgb => {
            Some(TextureBlockInfo {
                block_width: 4,
                block_height: 4,
                block_bytes: 16,
            })
        }
        wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B4x4,
            channel: wgpu::AstcChannel::Unorm | wgpu::AstcChannel::UnormSrgb,
        } => Some(TextureBlockInfo {
            block_width: 4,
            block_height: 4,
            block_bytes: 16,
        }),
        _ => None,
    }
}

fn quat_to_z_rotation(x: f32, y: f32, z: f32, w: f32) -> f32 {
    let siny_cosp = 2.0f32 * (w * z + x * y);
    let cosy_cosp = 1.0f32 - 2.0f32 * (y * y + z * z);
    siny_cosp.atan2(cosy_cosp)
}

fn mesh_uniform_bytes(pass: &GpuPassState, draw: &MeshDraw) -> Vec<u8> {
    if draw.is_3d {
        if pass_kind_base_kind(pass.pass_kind) == PASS_KIND_BASE_MOTION_VECTOR {
            return mesh3d_motion_vector_uniform_bytes(pass, draw);
        }
        return mesh3d_uniform_bytes(pass, draw);
    }
    mesh2d_uniform_bytes(pass, draw)
}

fn mesh2d_uniform_bytes(pass: &GpuPassState, draw: &MeshDraw) -> Vec<u8> {
    let safe_scale = pass.camera_scale;
    let scale_x_base = if pass.width_logical > 0.0 {
        2.0 / pass.width_logical / safe_scale
    } else {
        0.0
    };
    let scale_y_base = if pass.height_logical > 0.0 {
        2.0 / pass.height_logical / safe_scale
    } else {
        0.0
    };
    let cosr = draw.rotation.cos();
    let sinr = draw.rotation.sin();
    let cam_cos = (-pass.camera_rot).cos();
    let cam_sin = (-pass.camera_rot).sin();

    let floats: [f32; 20] = [
        draw.x,
        draw.y,
        cosr,
        sinr,
        pass.camera_x,
        pass.camera_y,
        cam_cos,
        cam_sin,
        scale_x_base,
        scale_y_base,
        draw.scale_x,
        draw.scale_y,
        draw.color[0],
        draw.color[1],
        draw.color[2],
        draw.color[3],
        draw.uv_offset[0],
        draw.uv_offset[1],
        draw.uv_scale[0],
        draw.uv_scale[1],
    ];
    bytemuck::cast_slice(&floats).to_vec()
}

fn mesh3d_uniform_bytes(pass: &GpuPassState, draw: &MeshDraw) -> Vec<u8> {
    let aspect_ratio = if pass.height_logical > 0.0 {
        pass.width_logical / pass.height_logical
    } else {
        1.0
    };
    let floats: [f32; 104] = [
        draw.x,
        draw.y,
        draw.z,
        1.0,
        draw.rotation_quat[0],
        draw.rotation_quat[1],
        draw.rotation_quat[2],
        draw.rotation_quat[3],
        draw.scale_x,
        draw.scale_y,
        draw.scale_z,
        1.0,
        pass.camera_x,
        pass.camera_y,
        pass.camera_z,
        1.0,
        pass.camera_rot_quat[0],
        pass.camera_rot_quat[1],
        pass.camera_rot_quat[2],
        pass.camera_rot_quat[3],
        pass.camera_fov_y,
        aspect_ratio,
        pass.camera_near,
        pass.camera_far,
        pass.sub_camera_view[0],
        pass.sub_camera_view[1],
        pass.sub_camera_view[2],
        pass.sub_camera_view[3],
        draw.color[0],
        draw.color[1],
        draw.color[2],
        draw.color[3],
        draw.uv_offset[0],
        draw.uv_offset[1],
        draw.uv_scale[0],
        draw.uv_scale[1],
        pass.ambient[0],
        pass.ambient[1],
        pass.ambient[2],
        pass.ambient[3],
        pass.directional_dir_illum[0],
        pass.directional_dir_illum[1],
        pass.directional_dir_illum[2],
        pass.directional_dir_illum[3],
        pass.directional_color[0],
        pass.directional_color[1],
        pass.directional_color[2],
        1.0,
        pass.point_pos_range[0],
        pass.point_pos_range[1],
        pass.point_pos_range[2],
        pass.point_pos_range[3],
        pass.point_color_intensity[0],
        pass.point_color_intensity[1],
        pass.point_color_intensity[2],
        pass.point_color_intensity[3],
        pass.spot_pos_range[0],
        pass.spot_pos_range[1],
        pass.spot_pos_range[2],
        pass.spot_pos_range[3],
        pass.spot_dir_inner[0],
        pass.spot_dir_inner[1],
        pass.spot_dir_inner[2],
        pass.spot_dir_inner[3],
        pass.spot_color_intensity[0],
        pass.spot_color_intensity[1],
        pass.spot_color_intensity[2],
        pass.spot_color_intensity[3],
        pass.spot_outer_angle,
        draw.transmission_blur_taps,
        draw.transmission_steps,
        0.0,
        draw.emissive[0],
        draw.emissive[1],
        draw.emissive[2],
        draw.unlit,
        draw.metallic,
        draw.roughness,
        draw.reflectance,
        draw.normal_map_flag,
        draw.map_flags[0],
        draw.map_flags[1],
        draw.map_flags[2],
        draw.map_flags[3],
        draw.parallax_depth_scale,
        draw.max_parallax_layer_count,
        draw.max_relief_mapping_search_steps,
        draw.depth_map_flag,
        draw.anisotropy_strength,
        draw.anisotropy_rotation_cos,
        draw.anisotropy_rotation_sin,
        draw.anisotropy_map_flag,
        draw.specular_tint[0],
        draw.specular_tint[1],
        draw.specular_tint[2],
        draw.specular_tint_map_flag,
        draw.diffuse_transmission,
        draw.specular_transmission,
        draw.thickness,
        draw.ior,
        draw.point_shadow_enabled,
        draw.point_shadow_depth_bias,
        0.0,
        0.0,
    ];
    bytemuck::cast_slice(&floats).to_vec()
}

fn write_f32_le(bytes: &mut [u8], offset: usize, value: f32) {
    if offset + 4 <= bytes.len() {
        bytes[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
    }
}

fn write_u32_le(bytes: &mut [u8], offset: usize, value: u32) {
    if offset + 4 <= bytes.len() {
        bytes[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
    }
}

fn write_f32s_le(bytes: &mut [u8], offset: usize, values: &[f32]) {
    for (i, value) in values.iter().enumerate() {
        write_f32_le(bytes, offset + i * 4, *value);
    }
}

fn quat_normalize4(mut q: [f32; 4]) -> [f32; 4] {
    let n2 = (q[0] * q[0] + q[1] * q[1] + q[2] * q[2] + q[3] * q[3]).max(1.0e-8);
    let inv = n2.sqrt().recip();
    q[0] *= inv;
    q[1] *= inv;
    q[2] *= inv;
    q[3] *= inv;
    q
}

fn quat_to_row_mat3(q_raw: [f32; 4]) -> [f32; 9] {
    let q = quat_normalize4(q_raw);
    let x = q[0];
    let y = q[1];
    let z = q[2];
    let w = q[3];
    [
        1.0 - 2.0 * (y * y + z * z),
        2.0 * (x * y - w * z),
        2.0 * (x * z + w * y),
        2.0 * (x * y + w * z),
        1.0 - 2.0 * (x * x + z * z),
        2.0 * (y * z - w * x),
        2.0 * (x * z - w * y),
        2.0 * (y * z + w * x),
        1.0 - 2.0 * (x * x + y * y),
    ]
}

fn mat4_row_mul(a: &[f32; 16], b: &[f32; 16]) -> [f32; 16] {
    let mut out = [0.0f32; 16];
    for r in 0..4 {
        for c in 0..4 {
            out[r * 4 + c] = a[r * 4] * b[c]
                + a[r * 4 + 1] * b[4 + c]
                + a[r * 4 + 2] * b[8 + c]
                + a[r * 4 + 3] * b[12 + c];
        }
    }
    out
}

fn mat4_row_inverse(m: &[f32; 16]) -> [f32; 16] {
    let mut aug = [[0.0f32; 8]; 4];
    for r in 0..4 {
        for c in 0..4 {
            aug[r][c] = m[r * 4 + c];
        }
        aug[r][4 + r] = 1.0;
    }

    for col in 0..4 {
        let mut pivot = col;
        let mut pivot_abs = aug[col][col].abs();
        for r in (col + 1)..4 {
            let v = aug[r][col].abs();
            if v > pivot_abs {
                pivot_abs = v;
                pivot = r;
            }
        }
        if pivot_abs <= 1.0e-8 {
            return [
                1.0, 0.0, 0.0, 0.0, //
                0.0, 1.0, 0.0, 0.0, //
                0.0, 0.0, 1.0, 0.0, //
                0.0, 0.0, 0.0, 1.0,
            ];
        }
        if pivot != col {
            aug.swap(col, pivot);
        }
        let inv_pivot = aug[col][col].recip();
        for c in 0..8 {
            aug[col][c] *= inv_pivot;
        }
        for r in 0..4 {
            if r == col {
                continue;
            }
            let factor = aug[r][col];
            if factor.abs() <= 1.0e-12 {
                continue;
            }
            for c in 0..8 {
                aug[r][c] -= factor * aug[col][c];
            }
        }
    }

    let mut out = [0.0f32; 16];
    for r in 0..4 {
        for c in 0..4 {
            out[r * 4 + c] = aug[r][4 + c];
        }
    }
    out
}

fn mat4_row_to_col(m: &[f32; 16]) -> [f32; 16] {
    [
        m[0], m[4], m[8], m[12], m[1], m[5], m[9], m[13], m[2], m[6], m[10], m[14], m[3], m[7],
        m[11], m[15],
    ]
}

fn mesh3d_build_model_rows(pos: [f32; 3], rot: [f32; 4], scale: [f32; 3]) -> [f32; 12] {
    let r = quat_to_row_mat3(rot);
    [
        r[0] * scale[0],
        r[1] * scale[1],
        r[2] * scale[2],
        pos[0],
        r[3] * scale[0],
        r[4] * scale[1],
        r[5] * scale[2],
        pos[1],
        r[6] * scale[0],
        r[7] * scale[1],
        r[8] * scale[2],
        pos[2],
    ]
}

fn safe_reciprocal(value: f32) -> f32 {
    if value.abs() > 1.0e-8 {
        value.recip()
    } else {
        0.0
    }
}

fn mesh3d_build_local_from_world_transpose_cols(rot: [f32; 4], scale: [f32; 3]) -> [f32; 9] {
    let r = quat_to_row_mat3(rot);
    let inv_sx = safe_reciprocal(scale[0]);
    let inv_sy = safe_reciprocal(scale[1]);
    let inv_sz = safe_reciprocal(scale[2]);
    let m00 = r[0] * inv_sx;
    let m01 = r[1] * inv_sy;
    let m02 = r[2] * inv_sz;
    let m10 = r[3] * inv_sx;
    let m11 = r[4] * inv_sy;
    let m12 = r[5] * inv_sz;
    let m20 = r[6] * inv_sx;
    let m21 = r[7] * inv_sy;
    let m22 = r[8] * inv_sz;
    [
        m00, m10, m20, //
        m01, m11, m21, //
        m02, m12, m22, //
    ]
}

fn mesh3d_build_world_from_view_row(pass: &GpuPassState) -> [f32; 16] {
    let r = quat_to_row_mat3(pass.camera_rot_quat);
    [
        r[0],
        r[1],
        r[2],
        pass.camera_x,
        r[3],
        r[4],
        r[5],
        pass.camera_y,
        r[6],
        r[7],
        r[8],
        pass.camera_z,
        0.0,
        0.0,
        0.0,
        1.0,
    ]
}

fn mesh3d_build_view_from_world_row(pass: &GpuPassState) -> [f32; 16] {
    let r = quat_to_row_mat3(pass.camera_rot_quat);
    let rt = [r[0], r[3], r[6], r[1], r[4], r[7], r[2], r[5], r[8]];
    let tx = -(rt[0] * pass.camera_x + rt[1] * pass.camera_y + rt[2] * pass.camera_z);
    let ty = -(rt[3] * pass.camera_x + rt[4] * pass.camera_y + rt[5] * pass.camera_z);
    let tz = -(rt[6] * pass.camera_x + rt[7] * pass.camera_y + rt[8] * pass.camera_z);
    [
        rt[0], rt[1], rt[2], tx, rt[3], rt[4], rt[5], ty, rt[6], rt[7], rt[8], tz, 0.0, 0.0, 0.0,
        1.0,
    ]
}

fn mesh3d_build_clip_from_view_row(pass: &GpuPassState, aspect: f32) -> [f32; 16] {
    if pass.camera_fov_y > 0.0 {
        let f = 1.0 / (0.5 * pass.camera_fov_y.max(1.0e-3)).tan();
        let near = pass.camera_near.max(1.0e-4);
        [
            f / aspect.max(1.0e-3),
            0.0,
            0.0,
            0.0,
            0.0,
            f,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            near,
            0.0,
            0.0,
            -1.0,
            0.0,
        ]
    } else {
        let half_h = (-pass.camera_fov_y).max(1.0e-5);
        let half_w = (half_h * aspect.max(1.0e-3)).max(1.0e-5);
        let near = pass.camera_near.max(0.0);
        let far = pass.camera_far.max(near + 1.0e-4);
        let left = -half_w;
        let right = half_w;
        let bottom = -half_h;
        let top = half_h;
        let w = (right - left).max(1.0e-5);
        let h = (top - bottom).max(1.0e-5);
        let d = (far - near).max(1.0e-5);
        let cw = -right - left;
        let ch = -top - bottom;
        [
            2.0 / w,
            0.0,
            0.0,
            cw / w,
            0.0,
            2.0 / h,
            0.0,
            ch / h,
            0.0,
            0.0,
            1.0 / d,
            far / d,
            0.0,
            0.0,
            0.0,
            1.0,
        ]
    }
}

fn mesh3d_apply_subview_row(mut clip: [f32; 16], sub: [f32; 4]) -> [f32; 16] {
    for c in 0..4 {
        clip[c] = sub[0] * clip[c] + sub[2] * clip[12 + c];
        clip[4 + c] = sub[1] * clip[4 + c] + sub[3] * clip[12 + c];
    }
    clip
}

fn mesh3d_bevy_view_uniform_bytes(pass: &GpuPassState) -> Vec<u8> {
    let mut floats = vec![0.0f32; 192];
    let aspect = if pass.height_logical > 0.0 {
        pass.width_logical / pass.height_logical
    } else {
        1.0
    };
    let world_from_view_row = mesh3d_build_world_from_view_row(pass);
    let view_from_world_row = mesh3d_build_view_from_world_row(pass);
    let clip_from_view_row = mesh3d_apply_subview_row(
        mesh3d_build_clip_from_view_row(pass, aspect),
        pass.sub_camera_view,
    );
    let clip_from_world_row = mat4_row_mul(&clip_from_view_row, &view_from_world_row);
    let view_from_clip_row = mat4_row_inverse(&clip_from_view_row);
    let world_from_clip_row = mat4_row_mul(&world_from_view_row, &view_from_clip_row);
    let clip_from_world_col = mat4_row_to_col(&clip_from_world_row);
    let world_from_clip_col = mat4_row_to_col(&world_from_clip_row);
    let world_from_view_col = mat4_row_to_col(&world_from_view_row);
    let view_from_world_col = mat4_row_to_col(&view_from_world_row);
    let clip_from_view_col = mat4_row_to_col(&clip_from_view_row);
    let view_from_clip_col = mat4_row_to_col(&view_from_clip_row);
    for i in 0..16 {
        floats[i] = clip_from_world_col[i];
        floats[16 + i] = clip_from_world_col[i];
        floats[32 + i] = world_from_clip_col[i];
        floats[48 + i] = world_from_view_col[i];
        floats[64 + i] = view_from_world_col[i];
        floats[80 + i] = clip_from_view_col[i];
        floats[96 + i] = view_from_clip_col[i];
    }
    floats[112] = pass.camera_x;
    floats[113] = pass.camera_y;
    floats[114] = pass.camera_z;
    // Bevy camera default exposure (Exposure::BLENDER: ev100=9.7).
    floats[115] = 0.0010019079;
    floats[116] = pass.viewport_x as f32;
    floats[117] = pass.viewport_y as f32;
    floats[118] = pass.viewport_w as f32;
    floats[119] = pass.viewport_h as f32;
    floats[120] = pass.viewport_x as f32;
    floats[121] = pass.viewport_y as f32;
    floats[122] = pass.viewport_w as f32;
    floats[123] = pass.viewport_h as f32;
    bytemuck::cast_slice(floats.as_slice()).to_vec()
}

fn mesh3d_bevy_lights_uniform_bytes(pass: &GpuPassState) -> Vec<u8> {
    let mut bytes = vec![0u8; 256];
    let ambient_scale = pass.ambient[3];
    write_f32_le(&mut bytes, 160, pass.ambient[0] * ambient_scale);
    write_f32_le(&mut bytes, 164, pass.ambient[1] * ambient_scale);
    write_f32_le(&mut bytes, 168, pass.ambient[2] * ambient_scale);
    write_f32_le(&mut bytes, 172, 1.0);
    write_u32_le(&mut bytes, 176, 1);
    write_u32_le(&mut bytes, 180, 1);
    write_u32_le(&mut bytes, 184, 1);
    write_u32_le(&mut bytes, 188, 1);
    let inv_viewport_w = 1.0 / (pass.viewport_w.max(1) as f32);
    let inv_viewport_h = 1.0 / (pass.viewport_h.max(1) as f32);
    write_f32_le(&mut bytes, 192, inv_viewport_w);
    write_f32_le(&mut bytes, 196, inv_viewport_h);
    let near = pass.camera_near.max(1.0e-4);
    let far = pass.camera_far.max(near + 1.0e-4);
    if pass.camera_fov_y > 0.0 {
        let log_ratio = (far / near).ln().max(1.0e-5);
        write_f32_le(&mut bytes, 200, 1.0 / log_ratio);
        write_f32_le(&mut bytes, 204, near.ln() / log_ratio);
    } else {
        write_f32_le(&mut bytes, 200, -near);
        let mut denom = -far - -near;
        if denom.abs() < 1.0e-5 {
            denom = if denom < 0.0 { -1.0e-5 } else { 1.0e-5 };
        }
        write_f32_le(&mut bytes, 204, 1.0 / denom);
    }
    if pass.directional_dir_illum[3] > 0.0 {
        write_f32_le(
            &mut bytes,
            80,
            pass.directional_color[0] * pass.directional_dir_illum[3],
        );
        write_f32_le(
            &mut bytes,
            84,
            pass.directional_color[1] * pass.directional_dir_illum[3],
        );
        write_f32_le(
            &mut bytes,
            88,
            pass.directional_color[2] * pass.directional_dir_illum[3],
        );
        write_f32_le(&mut bytes, 92, 1.0);
        write_f32_le(&mut bytes, 96, -pass.directional_dir_illum[0]);
        write_f32_le(&mut bytes, 100, -pass.directional_dir_illum[1]);
        write_f32_le(&mut bytes, 104, -pass.directional_dir_illum[2]);
        write_u32_le(&mut bytes, 208, 1);
    } else {
        write_u32_le(&mut bytes, 208, 0);
    }
    let point_count = if mesh3d_point_light_enabled(pass) {
        1i32
    } else {
        0
    };
    write_u32_le(&mut bytes, 212, (-point_count) as u32);
    write_u32_le(&mut bytes, 216, 1);
    bytemuck::cast_slice(bytes.as_slice()).to_vec()
}

fn mesh3d_point_light_enabled(pass: &GpuPassState) -> bool {
    pass.point_color_intensity[3] > 0.0 && pass.point_pos_range[3] > 0.0
}

fn mesh3d_spot_light_enabled(pass: &GpuPassState) -> bool {
    pass.spot_color_intensity[3] > 0.0 && pass.spot_pos_range[3] > 0.0
}

fn mesh3d_write_clustered_light(
    bytes: &mut [u8],
    index: usize,
    light_custom_data: [f32; 4],
    color_inverse_square_range: [f32; 4],
    position_radius: [f32; 4],
    flags: u32,
    shadow_depth_bias: f32,
    shadow_normal_bias: f32,
    spot_light_tan_angle: f32,
    soft_shadow_size: f32,
    shadow_map_near_z: f32,
) {
    let base = index * MESH3D_CLUSTERED_LIGHT_STRIDE_BYTES;
    if base + MESH3D_CLUSTERED_LIGHT_STRIDE_BYTES > bytes.len() {
        return;
    }
    write_f32s_le(bytes, base, &light_custom_data);
    write_f32s_le(bytes, base + 16, &color_inverse_square_range);
    write_f32s_le(bytes, base + 32, &position_radius);
    write_u32_le(bytes, base + 48, flags);
    write_f32_le(bytes, base + 52, shadow_depth_bias);
    write_f32_le(bytes, base + 56, shadow_normal_bias);
    write_f32_le(bytes, base + 60, spot_light_tan_angle);
    write_f32_le(bytes, base + 64, soft_shadow_size);
    write_f32_le(bytes, base + 68, shadow_map_near_z);
    write_u32_le(bytes, base + 72, u32::MAX);
    write_f32_le(bytes, base + 76, 0.0);
}

fn mesh3d_bevy_clustered_lights_uniform_bytes(pass: &GpuPassState, draw: &MeshDraw) -> Vec<u8> {
    let mut bytes = vec![0u8; MESH3D_CLUSTERED_LIGHTS_UNIFORM_BYTES as usize];
    let mut next_light_index = 0usize;
    if mesh3d_point_light_enabled(pass) {
        let range = pass.point_pos_range[3].max(1.0e-4);
        let shadow_map_near_z = 0.1f32;
        let intensity_scale = pass.point_color_intensity[3] / (4.0 * std::f32::consts::PI);
        let point_shadow_enabled =
            draw.point_shadow_enabled > 0.0 && draw.point_shadow_texture_id >= 0;
        let mut flags = POINT_LIGHT_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE;
        if point_shadow_enabled {
            flags |= POINT_LIGHT_FLAG_SHADOWS_ENABLED;
        }
        mesh3d_write_clustered_light(
            bytes.as_mut_slice(),
            next_light_index,
            [0.0, -1.0, shadow_map_near_z, 0.0],
            [
                pass.point_color_intensity[0] * intensity_scale,
                pass.point_color_intensity[1] * intensity_scale,
                pass.point_color_intensity[2] * intensity_scale,
                1.0 / (range * range),
            ],
            [
                pass.point_pos_range[0],
                pass.point_pos_range[1],
                pass.point_pos_range[2],
                0.0,
            ],
            flags,
            if point_shadow_enabled {
                draw.point_shadow_depth_bias.max(0.0)
            } else {
                0.0
            },
            POINT_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS,
            0.0,
            0.0,
            shadow_map_near_z,
        );
        next_light_index += 1;
    }
    if mesh3d_spot_light_enabled(pass) {
        let range = pass.spot_pos_range[3].max(1.0e-4);
        let intensity_scale = pass.spot_color_intensity[3] / (4.0 * std::f32::consts::PI);
        let (dir_x, dir_y, dir_z) = {
            let x = pass.spot_dir_inner[0];
            let y = pass.spot_dir_inner[1];
            let z = pass.spot_dir_inner[2];
            let len_sq = x * x + y * y + z * z;
            if len_sq > 1.0e-8 {
                let inv_len = len_sq.sqrt().recip();
                (x * inv_len, y * inv_len, z * inv_len)
            } else {
                (0.0, -1.0, 0.0)
            }
        };
        let inner = pass.spot_dir_inner[3];
        let outer = pass.spot_outer_angle.max(inner);
        let cos_outer = outer.cos();
        let spot_scale = 1.0 / (inner.cos() - cos_outer).max(1.0e-4);
        let spot_offset = -cos_outer * spot_scale;
        let mut flags = POINT_LIGHT_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE;
        if dir_y.is_sign_negative() {
            flags |= POINT_LIGHT_FLAG_SPOT_LIGHT_Y_NEGATIVE;
        }
        mesh3d_write_clustered_light(
            bytes.as_mut_slice(),
            next_light_index,
            [dir_x, dir_z, spot_scale, spot_offset],
            [
                pass.spot_color_intensity[0] * intensity_scale,
                pass.spot_color_intensity[1] * intensity_scale,
                pass.spot_color_intensity[2] * intensity_scale,
                1.0 / (range * range),
            ],
            [
                pass.spot_pos_range[0],
                pass.spot_pos_range[1],
                pass.spot_pos_range[2],
                0.0,
            ],
            flags,
            0.0,
            0.0,
            outer.tan(),
            0.0,
            0.1,
        );
    }
    bytes
}

fn mesh3d_bevy_cluster_index_lists_uniform_bytes(pass: &GpuPassState) -> Vec<u8> {
    let mut bytes = vec![0u8; MESH3D_CLUSTER_INDEX_LISTS_UNIFORM_BYTES as usize];
    let point_count = if mesh3d_point_light_enabled(pass) {
        1u32
    } else {
        0u32
    };
    let spot_count = if mesh3d_spot_light_enabled(pass) {
        1u32
    } else {
        0u32
    };
    if point_count + spot_count > 0 {
        let mut packed = 0u32;
        if spot_count > 0 {
            packed |= (point_count & 0xFF) << 8;
        }
        write_u32_le(&mut bytes, 0, packed);
    }
    bytes
}

fn mesh3d_bevy_cluster_offsets_uniform_bytes(pass: &GpuPassState) -> Vec<u8> {
    let mut bytes = vec![0u8; MESH3D_CLUSTER_OFFSETS_UNIFORM_BYTES as usize];
    let point_count = if mesh3d_point_light_enabled(pass) {
        1u32
    } else {
        0u32
    };
    let spot_count = if mesh3d_spot_light_enabled(pass) {
        1u32
    } else {
        0u32
    };
    let raw_offsets_and_counts = ((point_count & 0x1FF) << 9) | (spot_count & 0x1FF);
    write_u32_le(&mut bytes, 0, raw_offsets_and_counts);
    bytes
}

fn mesh3d_bevy_mesh_uniform_bytes(draw: &MeshDraw) -> Vec<u8> {
    let mut bytes = vec![0u8; 192];
    let world_rows = mesh3d_build_model_rows(
        [draw.x, draw.y, draw.z],
        draw.rotation_quat,
        [draw.scale_x, draw.scale_y, draw.scale_z],
    );
    let prev_rows = mesh3d_build_model_rows(
        [draw.previous_x, draw.previous_y, draw.previous_z],
        draw.previous_rotation_quat,
        [
            draw.previous_scale_x,
            draw.previous_scale_y,
            draw.previous_scale_z,
        ],
    );
    write_f32s_le(&mut bytes, 0, &world_rows);
    write_f32s_le(&mut bytes, 48, &prev_rows);
    let local_from_world_transpose_cols = mesh3d_build_local_from_world_transpose_cols(
        draw.rotation_quat,
        [draw.scale_x, draw.scale_y, draw.scale_z],
    );
    write_f32s_le(&mut bytes, 96, &local_from_world_transpose_cols[0..8]);
    write_f32_le(&mut bytes, 128, local_from_world_transpose_cols[8]);
    // Match Bevy mesh flags defaults:
    // - LOD index = u16::MAX (no LOD)
    // - SHADOW_RECEIVER
    // - SIGN_DETERMINANT_MODEL_3X3 when determinant is positive.
    let mut mesh_flags: u32 = 0x0000_FFFF | (1u32 << 29);
    let determinant_sign = draw.scale_x * draw.scale_y * draw.scale_z;
    if determinant_sign >= 0.0 {
        mesh_flags |= 1u32 << 31;
    }
    write_u32_le(&mut bytes, 132, mesh_flags);
    write_u32_le(&mut bytes, 136, 0); // lightmap_uv_rect.x
    write_u32_le(&mut bytes, 140, 0); // lightmap_uv_rect.y
    write_u32_le(&mut bytes, 144, 0); // first_vertex_index
    write_u32_le(&mut bytes, 148, 0); // current_skin_index
    write_u32_le(&mut bytes, 152, 0); // material_and_lightmap_bind_group_slot
    write_u32_le(&mut bytes, 156, 0); // tag
    write_u32_le(&mut bytes, 160, 0); // pad
    bytemuck::cast_slice(bytes.as_slice()).to_vec()
}

fn mesh3d_bevy_material_uniform_bytes(draw: &MeshDraw) -> Vec<u8> {
    let mut bytes = vec![0u8; 256];
    write_f32s_le(&mut bytes, 0, &draw.color);
    write_f32s_le(
        &mut bytes,
        16,
        &[draw.emissive[0], draw.emissive[1], draw.emissive[2], 1.0],
    );
    write_f32s_le(&mut bytes, 32, &[1.0, 1.0, 1.0, 1.0]);
    write_f32s_le(
        &mut bytes,
        48,
        &[
            1.0, 0.0, 0.0, 0.0, //
            0.0, 1.0, 0.0, 0.0, //
            0.0, 0.0, 1.0, 0.0, //
        ],
    );
    write_f32s_le(
        &mut bytes,
        96,
        &[
            draw.reflectance,
            draw.reflectance,
            draw.reflectance,
            draw.roughness,
        ],
    );
    write_f32_le(&mut bytes, 112, draw.metallic);
    write_f32_le(&mut bytes, 116, draw.diffuse_transmission);
    write_f32_le(&mut bytes, 120, draw.specular_transmission);
    write_f32_le(&mut bytes, 124, draw.thickness);
    write_f32_le(&mut bytes, 128, draw.ior);
    write_f32_le(&mut bytes, 132, 1.0);
    write_f32_le(&mut bytes, 144, draw.anisotropy_strength);
    let flags = if draw.unlit > 0.5 { 1u32 << 5 } else { 0 };
    write_u32_le(&mut bytes, 156, flags);
    write_f32_le(&mut bytes, 160, 0.5);
    write_f32_le(&mut bytes, 164, draw.parallax_depth_scale);
    write_f32_le(&mut bytes, 168, draw.max_parallax_layer_count);
    write_f32_le(&mut bytes, 172, 1.0);
    write_u32_le(
        &mut bytes,
        176,
        draw.max_relief_mapping_search_steps.max(0.0) as u32,
    );
    write_u32_le(&mut bytes, 180, 1);
    bytemuck::cast_slice(bytes.as_slice()).to_vec()
}

fn mesh3d_motion_vector_uniform_bytes(pass: &GpuPassState, draw: &MeshDraw) -> Vec<u8> {
    let aspect_ratio = if pass.height_logical > 0.0 {
        pass.width_logical / pass.height_logical
    } else {
        1.0
    };
    let floats: [f32; 48] = [
        draw.x,
        draw.y,
        draw.z,
        1.0,
        draw.rotation_quat[0],
        draw.rotation_quat[1],
        draw.rotation_quat[2],
        draw.rotation_quat[3],
        draw.scale_x,
        draw.scale_y,
        draw.scale_z,
        1.0,
        draw.previous_x,
        draw.previous_y,
        draw.previous_z,
        1.0,
        draw.previous_rotation_quat[0],
        draw.previous_rotation_quat[1],
        draw.previous_rotation_quat[2],
        draw.previous_rotation_quat[3],
        draw.previous_scale_x,
        draw.previous_scale_y,
        draw.previous_scale_z,
        1.0,
        pass.camera_x,
        pass.camera_y,
        pass.camera_z,
        1.0,
        pass.camera_rot_quat[0],
        pass.camera_rot_quat[1],
        pass.camera_rot_quat[2],
        pass.camera_rot_quat[3],
        pass.previous_camera[0],
        pass.previous_camera[1],
        pass.previous_camera[2],
        1.0,
        pass.previous_camera_rot_quat[0],
        pass.previous_camera_rot_quat[1],
        pass.previous_camera_rot_quat[2],
        pass.previous_camera_rot_quat[3],
        pass.camera_fov_y,
        aspect_ratio,
        pass.camera_near,
        pass.camera_far,
        pass.sub_camera_view[0],
        pass.sub_camera_view[1],
        pass.sub_camera_view[2],
        pass.sub_camera_view[3],
    ];
    bytemuck::cast_slice(&floats).to_vec()
}

#[cfg(test)]
mod wgsl_composer_tests {
    use super::*;
    use std::time::{SystemTime, UNIX_EPOCH};

    fn temp_assets_dir(test_name: &str) -> PathBuf {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_nanos();
        let dir = std::env::temp_dir().join(format!(
            "mgstudio-wgsl-{test_name}-{}-{nanos}",
            std::process::id()
        ));
        std::fs::create_dir_all(&dir).expect("create temp dir");
        dir
    }

    fn write_shader_file(base: &Path, rel: &str, content: &str) {
        let file = base.join(rel);
        if let Some(parent) = file.parent() {
            std::fs::create_dir_all(parent).expect("create parent dir");
        }
        std::fs::write(file, content).expect("write shader file");
    }

    #[test]
    fn parse_multiline_import_block_and_brace_forms() {
        let import_block = r#"
            #import bevy_pbr::{
                prepass_utils,
                utils as Utils,
                nested::{foo, bar as Baz},
            }
        "#;
        let parsed = parse_wgsl_import_block(import_block).expect("parse import block");
        let pairs = parsed
            .iter()
            .map(|item| (item.full_path.as_str(), item.used_name.as_str()))
            .collect::<Vec<_>>();
        assert!(pairs.contains(&("bevy_pbr::prepass_utils", "prepass_utils")));
        assert!(pairs.contains(&("bevy_pbr::utils", "Utils")));
        assert!(pairs.contains(&("bevy_pbr::nested::foo", "foo")));
        assert!(pairs.contains(&("bevy_pbr::nested::bar", "Baz")));
    }

    #[test]
    fn resolve_module_path_from_index_and_fallback() {
        let assets = temp_assets_dir("module-index");
        write_shader_file(
            &assets,
            "shaders/bevy/module_index.txt",
            "bevy_render::globals = bevy_render/globals.wgsl\n",
        );
        write_shader_file(
            &assets,
            "shaders/bevy/bevy_render/globals.wgsl",
            "#define_import_path bevy_render::globals\n",
        );
        write_shader_file(
            &assets,
            "shaders/bevy/bevy_pbr/utils.wgsl",
            "#define_import_path bevy_pbr::utils\n",
        );

        let index = build_wgsl_module_index(&assets.to_string_lossy());
        let from_index = resolve_wgsl_import_module_path(
            &assets.to_string_lossy(),
            &index,
            "bevy_render::globals::Globals",
        )
        .expect("resolve index module");
        assert_eq!(from_index.0, "shaders/bevy/bevy_render/globals.wgsl");
        assert!(!from_index.1);

        let from_fallback =
            resolve_wgsl_import_module_path(&assets.to_string_lossy(), &index, "bevy_pbr::utils")
                .expect("resolve fallback module");
        assert_eq!(from_fallback.0, "shaders/bevy/bevy_pbr/utils.wgsl");
        assert!(from_fallback.1);

        let _ = std::fs::remove_dir_all(&assets);
    }

    #[test]
    fn resolve_module_path_from_json_index() {
        let assets = temp_assets_dir("module-index-json");
        write_shader_file(
            &assets,
            "shaders/bevy/module_index.json",
            r#"{
  "bevy_render::globals": "bevy_render/globals.wgsl",
  "nested": {
    "module": "bevy_pbr::utils",
    "path": "bevy_pbr/utils.wgsl"
  },
  "entries": [
    ["bevy_pbr::mesh_view_bindings", "bevy_pbr/mesh_view_bindings.wgsl"]
  ]
}
"#,
        );
        write_shader_file(
            &assets,
            "shaders/bevy/bevy_render/globals.wgsl",
            "#define_import_path bevy_render::globals\n",
        );
        write_shader_file(
            &assets,
            "shaders/bevy/bevy_pbr/utils.wgsl",
            "#define_import_path bevy_pbr::utils\n",
        );
        write_shader_file(
            &assets,
            "shaders/bevy/bevy_pbr/mesh_view_bindings.wgsl",
            "#define_import_path bevy_pbr::mesh_view_bindings\n",
        );

        let index = build_wgsl_module_index(&assets.to_string_lossy());
        let from_index = resolve_wgsl_import_module_path(
            &assets.to_string_lossy(),
            &index,
            "bevy_render::globals::Globals",
        )
        .expect("resolve json indexed module");
        assert_eq!(from_index.0, "shaders/bevy/bevy_render/globals.wgsl");
        assert!(!from_index.1);

        let from_nested =
            resolve_wgsl_import_module_path(&assets.to_string_lossy(), &index, "bevy_pbr::utils")
                .expect("resolve nested json module");
        assert_eq!(from_nested.0, "shaders/bevy/bevy_pbr/utils.wgsl");
        assert!(from_nested.1);

        let from_array = resolve_wgsl_import_module_path(
            &assets.to_string_lossy(),
            &index,
            "bevy_pbr::mesh_view_bindings::view",
        )
        .expect("resolve array json module");
        assert_eq!(
            from_array.0,
            "shaders/bevy/bevy_pbr/mesh_view_bindings.wgsl"
        );
        assert!(!from_array.1);

        let _ = std::fs::remove_dir_all(&assets);
    }

    #[test]
    fn apply_conditionals_with_if_numeric_and_else_if_variants() {
        let source = r#"
#if COUNT + 1 >= 3
NUMERIC_TRUE
#else
NUMERIC_FALSE
#endif
#ifdef ENABLED
IFDEF_TRUE
#else ifdef OTHER
ELSE_IFDEF_TRUE
#else ifndef ALSO_MISSING
ELSE_IFNDEF_TRUE
#else
ELSE_FALLBACK
#endif
#ifdef MISSING
UNUSED
#else ifndef ALSO_MISSING
ELSE_IFNDEF_SECOND
#else
UNUSED_2
#endif
#ifndef DISABLED
IFNDEF_TRUE
#endif
"#;

        let defs = HashMap::from([
            ("COUNT".to_string(), WgslShaderDefValue::Int(2)),
            ("OTHER".to_string(), WgslShaderDefValue::Bool(true)),
        ]);
        let out = apply_wgsl_conditionals(source, &defs);

        assert!(out.contains("NUMERIC_TRUE"));
        assert!(!out.contains("NUMERIC_FALSE"));
        assert!(out.contains("ELSE_IFDEF_TRUE"));
        assert!(!out.contains("ELSE_IFNDEF_TRUE"));
        assert!(out.contains("ELSE_IFNDEF_SECOND"));
        assert!(out.contains("IFNDEF_TRUE"));
    }

    #[test]
    fn substitute_typed_shader_defs_with_hash_braces() {
        let source = "A=#{A}, B=#{B}, C=#{C}";
        let defs = HashMap::from([
            ("A".to_string(), WgslShaderDefValue::Bool(true)),
            ("B".to_string(), WgslShaderDefValue::Int(-3)),
            ("C".to_string(), WgslShaderDefValue::UInt(7)),
        ]);
        let out = apply_wgsl_shader_def_substitutions(source, &defs);
        assert_eq!(out, "A=true, B=-3, C=7");
    }

    #[test]
    fn compose_cache_key_uses_root_path_and_typed_defines() {
        let key_a = WgslComposeCacheKey::new(
            "shaders/mgstudio/2d/bloom.wgsl",
            &HashMap::from([
                (
                    "FIRST_DOWNSAMPLE".to_string(),
                    WgslShaderDefValue::Bool(true),
                ),
                ("LEVEL".to_string(), WgslShaderDefValue::Int(1)),
            ]),
        );
        let key_b = WgslComposeCacheKey::new(
            "shaders/mgstudio/2d/bloom.wgsl",
            &HashMap::from([
                ("LEVEL".to_string(), WgslShaderDefValue::Int(1)),
                (
                    "FIRST_DOWNSAMPLE".to_string(),
                    WgslShaderDefValue::Bool(true),
                ),
            ]),
        );
        let key_c = WgslComposeCacheKey::new(
            "shaders/mgstudio/2d/bloom.wgsl",
            &HashMap::from([
                (
                    "FIRST_DOWNSAMPLE".to_string(),
                    WgslShaderDefValue::Bool(false),
                ),
                ("LEVEL".to_string(), WgslShaderDefValue::Int(1)),
            ]),
        );

        assert_eq!(key_a, key_b);
        assert_ne!(key_a, key_c);
    }
}
