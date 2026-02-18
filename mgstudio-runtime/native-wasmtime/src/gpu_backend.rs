use std::collections::HashMap;
use std::sync::Arc;

use anyhow::{anyhow, Context};
use wgpu::util::DeviceExt as _;
use winit::window::Window;

// This module is a Rust port of the existing MoonBit native runtime's wgpu backend
// (mgstudio-runtime/native/wgpu_backend.mbt). It implements the same high-level
// host contract used by mgstudio-engine (begin_frame/begin_pass/draw/end_pass/end_frame)
// with sprite batching (sprite.wgsl) and basic 2D mesh draws (mesh.wgsl).

const MESH_UNIFORM_MAX_BYTES: u64 = 88 * 4;

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
    camera_fov_y: f32,
    camera_near: f32,
    camera_far: f32,
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
    color: [f32; 4],
    texture_id: i32,
    normal_texture_id: i32,
    emissive_texture_id: i32,
    metallic_roughness_texture_id: i32,
    occlusion_texture_id: i32,
    depth_texture_id: i32,
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
    ubo_offset: u32, // computed during encoding
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
    #[allow(dead_code)]
    is_render_target: bool,
}

struct GpuMesh {
    #[allow(dead_code)]
    vertex_count: u32,
    index_count: u32,
    layout: MeshVertexLayout,
    vertex_buf: wgpu::Buffer,
    index_buf: wgpu::Buffer,
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum MeshVertexLayout {
    XyUvRgba,
    XyzUvRgba,
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
    bgl_material_3d: Option<wgpu::BindGroupLayout>,
    pipeline_layout: Option<wgpu::PipelineLayout>,
    pipeline_layout_3d: Option<wgpu::PipelineLayout>,
    pipelines: HashMap<wgpu::TextureFormat, wgpu::RenderPipeline>,
    pipelines_3d: HashMap<wgpu::TextureFormat, wgpu::RenderPipeline>,
    pipelines_3d_transparent: HashMap<wgpu::TextureFormat, wgpu::RenderPipeline>,

    uniform_buf: Option<wgpu::Buffer>,
    uniform_bg: Option<wgpu::BindGroup>,
    uniform_capacity: u64,
    uniform_binding_size: u64,
}

impl GpuBackend {
    pub fn new(assets_base: String) -> anyhow::Result<Self> {
        let instance = wgpu::Instance::default();
        let adapter = pollster::block_on(instance.request_adapter(&wgpu::RequestAdapterOptions {
            power_preference: wgpu::PowerPreference::HighPerformance,
            compatible_surface: None,
            force_fallback_adapter: false,
        }))
        .context("wgpu: request_adapter failed")?;

        let (device, queue) = pollster::block_on(adapter.request_device(&wgpu::DeviceDescriptor {
            label: Some("mgstudio-device"),
            required_features: wgpu::Features::empty(),
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
        // Keep the device progressing (similar intent to wgpu-native's process_events()).
        let _ = self.device.poll(wgpu::PollType::Poll);

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
            camera_fov_y: std::f32::consts::FRAC_PI_2,
            camera_near: 0.1,
            camera_far: 1000.0,
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
            clear_enabled,
        )?;
        if let Some(pass) = self.pass.as_mut() {
            pass.st.is_3d = true;
            pass.st.camera_z = camera_z;
            pass.st.camera_rot_quat = [camera_rot_x, camera_rot_y, camera_rot_z, camera_rot_w];
            pass.st.camera_fov_y = camera_fov_y;
            pass.st.camera_near = camera_near;
            pass.st.camera_far = camera_far;
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
        for cmd in &pass.commands {
            match cmd {
                DrawCmd::Sprites(seg) => sprite_segments.push(seg),
                DrawCmd::Mesh(draw) => {
                    if draw.is_3d {
                        has_mesh_3d = true;
                    } else {
                        has_mesh_2d = true;
                    }
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
            self.ensure_mesh3d_pipeline(pass.st.target_format)?;
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
        let mesh_pipeline_3d = self.mesh.pipelines_3d.get(&pass.st.target_format).cloned();
        let mesh_pipeline_3d_transparent = self
            .mesh
            .pipelines_3d_transparent
            .get(&pass.st.target_format)
            .cloned();
        let mesh_bg = self.mesh.uniform_bg.as_ref().cloned();

        let Some(mut frame) = self.frame.take() else {
            return Ok(());
        };
        let (target_view, target_width, target_height): (&wgpu::TextureView, u32, u32) = if pass
            .st
            .target_id
            == -1
        {
            match frame.surface_view.as_ref() {
                Some(v) => {
                    let (w, h) = self.configured_size;
                    (v, w.max(1), h.max(1))
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
                Some(t) => (&t.view, t.width.max(1), t.height.max(1)),
                None => {
                    self.frame = Some(frame);
                    return Ok(());
                }
            }
        };
        let mut depth_texture: Option<wgpu::Texture> = None;
        let mut depth_view: Option<wgpu::TextureView> = None;
        if pass.st.is_3d {
            let depth_tex = self.device.create_texture(&wgpu::TextureDescriptor {
                label: Some("mgstudio-pass-depth"),
                size: wgpu::Extent3d {
                    width: target_width,
                    height: target_height,
                    depth_or_array_layers: 1,
                },
                mip_level_count: 1,
                sample_count: 1,
                dimension: wgpu::TextureDimension::D2,
                format: wgpu::TextureFormat::Depth24Plus,
                usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
                view_formats: &[],
            });
            let view = depth_tex.create_view(&wgpu::TextureViewDescriptor::default());
            depth_texture = Some(depth_tex);
            depth_view = Some(view);
        };

        {
            let depth_attachment =
                depth_view
                    .as_ref()
                    .map(|view| wgpu::RenderPassDepthStencilAttachment {
                        view,
                        depth_ops: Some(wgpu::Operations {
                            load: wgpu::LoadOp::Clear(1.0),
                            store: wgpu::StoreOp::Store,
                        }),
                        stencil_ops: None,
                    });
            let mut rp = frame
                .encoder
                .begin_render_pass(&wgpu::RenderPassDescriptor {
                    label: Some("mgstudio-pass"),
                    color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                        view: target_view,
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
                0.0,
                1.0,
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
                        let pipeline = if draw.is_3d {
                            if draw.color[3] < 0.999 {
                                mesh_pipeline_3d_transparent.as_ref()
                            } else {
                                mesh_pipeline_3d.as_ref()
                            }
                        } else {
                            mesh_pipeline_2d.as_ref()
                        };
                        let (Some(pipeline), Some(bg)) = (pipeline, mesh_bg.as_ref()) else {
                            continue;
                        };
                        let Some(mesh) = self.meshes.get(&draw.mesh_id) else {
                            continue;
                        };
                        if draw.is_3d && mesh.layout != MeshVertexLayout::XyzUvRgba {
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
                        rp.set_pipeline(pipeline);
                        rp.set_scissor_rect(sx, sy, sw, sh);
                        if draw.is_3d {
                            if let Some(ubo) = self.mesh.uniform_buf.as_ref() {
                                let bytes = mesh_uniform_bytes(&pass.st, &draw);
                                self.queue.write_buffer(ubo, 0, bytes.as_slice());
                            } else {
                                continue;
                            }
                            rp.set_bind_group(0, bg, &[0]);
                        } else {
                            rp.set_bind_group(0, bg, &[draw.ubo_offset]);
                        }
                        if draw.is_3d {
                            let Some(base_tex) = self.textures.get(&draw.texture_id) else {
                                continue;
                            };
                            let Some(normal_tex) = self.textures.get(&draw.normal_texture_id)
                            else {
                                continue;
                            };
                            let Some(emissive_tex) = self.textures.get(&draw.emissive_texture_id)
                            else {
                                continue;
                            };
                            let Some(metallic_roughness_tex) =
                                self.textures.get(&draw.metallic_roughness_texture_id)
                            else {
                                continue;
                            };
                            let Some(occlusion_tex) = self.textures.get(&draw.occlusion_texture_id)
                            else {
                                continue;
                            };
                            let Some(depth_tex) = self.textures.get(&draw.depth_texture_id) else {
                                continue;
                            };
                            let layout = pipeline.get_bind_group_layout(1);
                            let material_bg =
                                self.device.create_bind_group(&wgpu::BindGroupDescriptor {
                                    label: Some("mgstudio-mesh3d-material-bg"),
                                    layout: &layout,
                                    entries: &[
                                        wgpu::BindGroupEntry {
                                            binding: 0,
                                            resource: wgpu::BindingResource::Sampler(
                                                &base_tex.sampler,
                                            ),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 1,
                                            resource: wgpu::BindingResource::TextureView(
                                                &base_tex.view,
                                            ),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 2,
                                            resource: wgpu::BindingResource::TextureView(
                                                &normal_tex.view,
                                            ),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 3,
                                            resource: wgpu::BindingResource::TextureView(
                                                &emissive_tex.view,
                                            ),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 4,
                                            resource: wgpu::BindingResource::TextureView(
                                                &metallic_roughness_tex.view,
                                            ),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 5,
                                            resource: wgpu::BindingResource::TextureView(
                                                &occlusion_tex.view,
                                            ),
                                        },
                                        wgpu::BindGroupEntry {
                                            binding: 6,
                                            resource: wgpu::BindingResource::TextureView(
                                                &depth_tex.view,
                                            ),
                                        },
                                    ],
                                });
                            rp.set_bind_group(1, &material_bg, &[]);
                        } else {
                            let Some(tex) = self.textures.get(&draw.texture_id) else {
                                continue;
                            };
                            rp.set_bind_group(1, &tex.bind_group, &[]);
                        }
                        rp.set_vertex_buffer(0, mesh.vertex_buf.slice(..));
                        rp.set_index_buffer(mesh.index_buf.slice(..), wgpu::IndexFormat::Uint16);
                        rp.draw_indexed(0..mesh.index_count, 0, 0..1);
                    }
                }
            }
        }

        // Keep depth resources alive until encoding is finished.
        let _ = depth_texture;
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

        let tex_id = self.ensure_fallback_texture(texture_id)?;
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
        let resolved_texture_id = self.ensure_fallback_texture(requested_texture_id)?;
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
            color,
            texture_id: resolved_texture_id,
            normal_texture_id: resolved_texture_id,
            emissive_texture_id: resolved_texture_id,
            metallic_roughness_texture_id: resolved_texture_id,
            occlusion_texture_id: resolved_texture_id,
            depth_texture_id: resolved_texture_id,
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
    ) -> anyhow::Result<()> {
        if self.frame.is_none() {
            return Ok(());
        }
        let textured = texture_id >= 0;
        let requested_texture_id = if textured { texture_id } else { -1 };
        let resolved_texture_id = self.ensure_fallback_texture(requested_texture_id)?;
        let normal_textured = normal_texture_id >= 0;
        let requested_normal_texture_id = if normal_textured {
            normal_texture_id
        } else {
            -1
        };
        let resolved_normal_texture_id =
            self.ensure_fallback_texture(requested_normal_texture_id)?;
        let emissive_textured = emissive_texture_id >= 0;
        let requested_emissive_texture_id = if emissive_textured {
            emissive_texture_id
        } else {
            -1
        };
        let resolved_emissive_texture_id =
            self.ensure_fallback_texture(requested_emissive_texture_id)?;
        let metallic_roughness_textured = metallic_roughness_texture_id >= 0;
        let requested_metallic_roughness_texture_id = if metallic_roughness_textured {
            metallic_roughness_texture_id
        } else {
            -1
        };
        let resolved_metallic_roughness_texture_id =
            self.ensure_fallback_texture(requested_metallic_roughness_texture_id)?;
        let occlusion_textured = occlusion_texture_id >= 0;
        let requested_occlusion_texture_id = if occlusion_textured {
            occlusion_texture_id
        } else {
            -1
        };
        let resolved_occlusion_texture_id =
            self.ensure_fallback_texture(requested_occlusion_texture_id)?;
        let depth_textured = depth_texture_id >= 0;
        let requested_depth_texture_id = if depth_textured { depth_texture_id } else { -1 };
        let resolved_depth_texture_id = self.ensure_fallback_texture(requested_depth_texture_id)?;
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
            color,
            texture_id: resolved_texture_id,
            normal_texture_id: resolved_normal_texture_id,
            emissive_texture_id: resolved_emissive_texture_id,
            metallic_roughness_texture_id: resolved_metallic_roughness_texture_id,
            occlusion_texture_id: resolved_occlusion_texture_id,
            depth_texture_id: resolved_depth_texture_id,
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
            ubo_offset: 0,
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
                vertex_buf: vb,
                index_buf: ib,
            },
        );
        id
    }

    pub fn create_mesh_triangles_xyzuvrgba(&mut self, vertices: &[f32]) -> i32 {
        let vcount = vertices.len() / 9;
        if vcount == 0 {
            return 0;
        }
        let usable_vcount = vcount - (vcount % 3);
        if usable_vcount == 0 || usable_vcount > 65535 {
            return 0;
        }
        let trimmed = &vertices[..usable_vcount * 9];
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
                contents: bytemuck::cast_slice(trimmed),
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
                layout: MeshVertexLayout::XyzUvRgba,
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
        self.ensure_sprite_resources()?;
        let id = self.next_texture_id;
        self.next_texture_id += 1;
        self.create_texture_rgba8_with_id(id, width, height, pixels_rgba8, nearest, false)?;
        Ok(id)
    }

    pub fn create_render_target(
        &mut self,
        width: u32,
        height: u32,
        nearest: bool,
    ) -> anyhow::Result<i32> {
        self.ensure_sprite_resources()?;
        let id = self.next_texture_id;
        self.next_texture_id += 1;
        self.create_texture_rgba8_with_id(
            id,
            width,
            height,
            &vec![0u8; (width.max(1) * height.max(1) * 4) as usize],
            nearest,
            true,
        )?;
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

    pub fn write_texture_region_rgba8(
        &mut self,
        texture_id: i32,
        x: u32,
        y: u32,
        width: u32,
        height: u32,
        pixels_rgba8: &[u8],
    ) -> anyhow::Result<()> {
        let Some(tex) = self.textures.get(&texture_id) else {
            return Ok(());
        };
        let expected = (width * height * 4) as usize;
        if pixels_rgba8.len() < expected {
            return Ok(());
        }
        self.queue.write_texture(
            wgpu::TexelCopyTextureInfo {
                texture: &tex.texture,
                mip_level: 0,
                origin: wgpu::Origin3d { x, y, z: 0 },
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
                mip_level: 0,
                origin: wgpu::Origin3d::ZERO,
                aspect: wgpu::TextureAspect::All,
            },
            wgpu::TexelCopyTextureInfo {
                texture: &dst.texture,
                mip_level: 0,
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

    fn create_texture_rgba8_with_id(
        &mut self,
        id: i32,
        width: u32,
        height: u32,
        pixels_rgba8: &[u8],
        nearest: bool,
        is_render_target: bool,
    ) -> anyhow::Result<()> {
        let width = width.max(1);
        let height = height.max(1);
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
            mip_level_count: 1,
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
        if pixels_rgba8.len() >= expected {
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
        }

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
                is_render_target,
            },
        );
        Ok(())
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

    fn ensure_fallback_texture(&mut self, id: i32) -> anyhow::Result<i32> {
        if self.textures.contains_key(&id) {
            return Ok(id);
        }
        // Create a 1x1 white texture for invalid IDs (matches native runtime behavior).
        let white = [255u8, 255u8, 255u8, 255u8];
        let tid = if id > 0 { id } else { 1 };
        if !self.textures.contains_key(&tid) {
            self.ensure_sprite_resources()?;
            self.create_texture_rgba8_with_id(tid, 1, 1, &white, false, false)?;
        }
        Ok(tid)
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
        let mut offsets_bytes: Vec<u64> = Vec::with_capacity(segments.len());
        let mut all_f32: Vec<f32> = Vec::new();
        let mut cur_bytes: u64 = 0;
        for seg in segments {
            offsets_bytes.push(cur_bytes);
            all_f32.extend_from_slice(&seg.instance_data);
            cur_bytes += (seg.instance_data.len() * 4) as u64;
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
            let id = self.ensure_fallback_texture(batch.texture_id)?;
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
        if self.mesh.pipeline_layout.is_some() {
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
        let bgl_material_3d =
            self.device
                .create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
                    label: Some("mgstudio_mesh3d_material_bgl"),
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
                        wgpu::BindGroupLayoutEntry {
                            binding: 2,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Texture {
                                sample_type: wgpu::TextureSampleType::Float { filterable: true },
                                view_dimension: wgpu::TextureViewDimension::D2,
                                multisampled: false,
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
                label: Some("mgstudio_mesh_pl"),
                bind_group_layouts: &[&bgl_uniform, bgl_tex],
                immediate_size: 0,
            });
        let pl_3d = self
            .device
            .create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
                label: Some("mgstudio_mesh3d_pl"),
                bind_group_layouts: &[&bgl_uniform, &bgl_material_3d],
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
        self.mesh.bgl_uniform = Some(bgl_uniform);
        self.mesh.bgl_material_3d = Some(bgl_material_3d);
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

    fn ensure_mesh3d_pipeline(&mut self, format: wgpu::TextureFormat) -> anyhow::Result<()> {
        self.ensure_mesh_resources()?;
        if self.mesh.pipelines_3d.contains_key(&format)
            && self.mesh.pipelines_3d_transparent.contains_key(&format)
        {
            return Ok(());
        }
        let pl = self
            .mesh
            .pipeline_layout_3d
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: mesh3d pipeline layout missing"))?;
        let wgsl = load_wgsl_required(&self.assets_base, "shaders/mgstudio/3d/mesh3d.wgsl")?;
        let sm = self
            .device
            .create_shader_module(wgpu::ShaderModuleDescriptor {
                label: Some("mgstudio_mesh3d_wgsl"),
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
        let pipeline_opaque = self
            .device
            .create_render_pipeline(&wgpu::RenderPipelineDescriptor {
                label: Some("mgstudio_mesh3d_pipeline_opaque"),
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
                depth_stencil: Some(wgpu::DepthStencilState {
                    format: wgpu::TextureFormat::Depth24Plus,
                    depth_write_enabled: true,
                    depth_compare: wgpu::CompareFunction::LessEqual,
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
                    format: wgpu::VertexFormat::Float32x2,
                },
                wgpu::VertexAttribute {
                    offset: 20,
                    shader_location: 2,
                    format: wgpu::VertexFormat::Float32x4,
                },
            ],
        };
        let pipeline_transparent =
            self.device
                .create_render_pipeline(&wgpu::RenderPipelineDescriptor {
                    label: Some("mgstudio_mesh3d_pipeline_transparent"),
                    layout: Some(pl),
                    vertex: wgpu::VertexState {
                        module: &sm,
                        entry_point: Some("vs_main"),
                        compilation_options: Default::default(),
                        buffers: &[vb_layout_transparent],
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
                    depth_stencil: Some(wgpu::DepthStencilState {
                        format: wgpu::TextureFormat::Depth24Plus,
                        depth_write_enabled: false,
                        depth_compare: wgpu::CompareFunction::LessEqual,
                        stencil: wgpu::StencilState::default(),
                        bias: wgpu::DepthBiasState::default(),
                    }),
                    multisample: wgpu::MultisampleState::default(),
                    multiview_mask: None,
                    cache: None,
                });
        self.mesh.pipelines_3d.insert(format, pipeline_opaque);
        self.mesh
            .pipelines_3d_transparent
            .insert(format, pipeline_transparent);
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

fn load_wgsl_required(assets_base: &str, rel: &str) -> anyhow::Result<String> {
    let base = assets_base.trim();
    if base.is_empty() {
        return Err(anyhow!(
            "wgpu: assets_base is empty; cannot load shader: {rel}"
        ));
    }
    let full = std::path::Path::new(base).join(rel.trim_start_matches('/'));
    std::fs::read_to_string(&full)
        .with_context(|| format!("wgpu: failed to read shader: {}", full.display()))
}

fn align_up(v: u64, align: u64) -> u64 {
    if align == 0 {
        return v;
    }
    ((v + align - 1) / align) * align
}

fn quat_to_z_rotation(x: f32, y: f32, z: f32, w: f32) -> f32 {
    let siny_cosp = 2.0f32 * (w * z + x * y);
    let cosy_cosp = 1.0f32 - 2.0f32 * (y * y + z * z);
    siny_cosp.atan2(cosy_cosp)
}

fn mesh_uniform_bytes(pass: &GpuPassState, draw: &MeshDraw) -> Vec<u8> {
    if draw.is_3d {
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
    let floats: [f32; 88] = [
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
        0.0,
        0.0,
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
    ];
    bytemuck::cast_slice(&floats).to_vec()
}
