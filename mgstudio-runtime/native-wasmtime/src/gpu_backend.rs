use std::collections::HashMap;
use std::sync::Arc;

use anyhow::{anyhow, Context};
use wgpu::util::DeviceExt as _;
use winit::window::Window;

// This module is a Rust port of the existing MoonBit native runtime's wgpu backend
// (mgstudio-runtime/native/wgpu_backend.mbt). It implements the same high-level
// host contract used by mgstudio-engine (begin_frame/begin_pass/draw/end_pass/end_frame)
// with sprite batching (sprite.wgsl) and basic 2D mesh draws (mesh.wgsl).

pub struct GpuBackend {
    assets_base: String,

    instance: wgpu::Instance,
    adapter: wgpu::Adapter,
    device: wgpu::Device,
    queue: wgpu::Queue,

    surface: Option<wgpu::Surface<'static>>,
    surface_format: Option<wgpu::TextureFormat>,
    configured_size: (u32, u32),

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

    camera_x: f32,
    camera_y: f32,
    camera_rot: f32,
    camera_scale: f32,

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
}

struct SpriteSegment {
    instance_data: Vec<f32>,
    batches: Vec<SpriteBatch>,
    instance_count: u32,
}

struct MeshDraw {
    mesh_id: i32,
    x: f32,
    y: f32,
    rotation: f32,
    scale_x: f32,
    scale_y: f32,
    color: [f32; 4],
    ubo_offset: u32, // computed during encoding
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
    vertex_buf: wgpu::Buffer,
    index_buf: wgpu::Buffer,
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
    pipeline_layout: Option<wgpu::PipelineLayout>,
    pipelines: HashMap<wgpu::TextureFormat, wgpu::RenderPipeline>,

    uniform_buf: Option<wgpu::Buffer>,
    uniform_bg: Option<wgpu::BindGroup>,
    uniform_capacity: u64,
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

    pub fn create_surface_from_window(&self, window: Arc<Window>) -> anyhow::Result<wgpu::Surface<'static>> {
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
        let present_mode = caps.present_modes.first().copied().unwrap_or(wgpu::PresentMode::Fifo);
        let alpha_mode = caps.alpha_modes.first().copied().unwrap_or(wgpu::CompositeAlphaMode::Auto);

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

        let surface = self.surface.as_ref().unwrap();
        match surface.get_current_texture() {
            Ok(st) => {
                let view = st
                    .texture
                    .create_view(&wgpu::TextureViewDescriptor::default());
                frame.surface_view = Some(view);
                frame.surface_tex = Some(st);
            }
            Err(_) => {
                // Surface might be out-of-date; try a best-effort reconfigure on next configure call.
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

        let Some(mut frame) = self.frame.take() else { return Ok(()) };
        let cmd = frame.encoder.finish();
        self.queue.submit(Some(cmd));

        if let Some(st) = frame.surface_tex.take() {
            st.present();
        }
        // Keep the device progressing (similar intent to wgpu-native's process_events()).
        let _ = self.device.poll(wgpu::PollType::Poll);

        Ok(())
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
    ) -> anyhow::Result<()> {
        let Some(_frame) = self.frame.as_ref() else { return Ok(()) };

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
        let camera_scale = if camera_scale == 0.0 { 1.0 } else { camera_scale };

        let target_format = self.target_format_for_id(target_id)?;
        let st = GpuPassState {
            target_id,
            target_format,
            width_logical,
            height_logical,
            clear,
            camera_x,
            camera_y,
            camera_rot,
            camera_scale,
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
            },
        });
        Ok(())
    }

    pub fn end_pass(&mut self) -> anyhow::Result<()> {
        let Some(mut pass) = self.pass.take() else { return Ok(()) };
        pass.flush_sprites();

        // Collect sprite segments (by reference) to prepare storage buffer + per-segment bind groups.
        let mut sprite_segments: Vec<&SpriteSegment> = Vec::new();
        let mut has_mesh = false;
        for cmd in &pass.commands {
            match cmd {
                DrawCmd::Sprites(seg) => sprite_segments.push(seg),
                DrawCmd::Mesh(_) => has_mesh = true,
            }
        }

        // Prepare sprite instance storage + bind groups.
        let sprite_segment_bgs = self.prepare_sprite_segments(&pass.st, &sprite_segments)?;

        // Prepare mesh pipeline + uniforms only if needed.
        if has_mesh {
            self.ensure_mesh_pipeline(pass.st.target_format)?;
        }
        self.prepare_mesh_uniforms(&mut pass)?;

        // Clone wgpu handles so we don't hold long-lived borrows across the encoding phase.
        let sprite_pipeline = if pass.st.target_format == wgpu::TextureFormat::Rgba8Unorm {
            self.sprite.pipeline_rgba8.as_ref().expect("sprite rgba8 pipeline").clone()
        } else {
            self.sprite.pipeline_surface.as_ref().expect("sprite surface pipeline").clone()
        };
        let mesh_pipeline = self.mesh.pipelines.get(&pass.st.target_format).cloned();
        let mesh_bg = self.mesh.uniform_bg.as_ref().cloned();

        let Some(mut frame) = self.frame.take() else { return Ok(()) };
        let target_view: &wgpu::TextureView = if pass.st.target_id == -1 {
            match frame.surface_view.as_ref() {
                Some(v) => v,
                None => {
                    self.frame = Some(frame);
                    return Ok(());
                }
            }
        } else {
            match self.textures.get(&pass.st.target_id) {
                Some(t) => &t.view,
                None => {
                    self.frame = Some(frame);
                    return Ok(());
                }
            }
        };

        {
            let mut rp = frame.encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                label: Some("mgstudio-pass"),
                color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                    view: target_view,
                    depth_slice: None,
                    resolve_target: None,
                    ops: wgpu::Operations {
                        load: wgpu::LoadOp::Clear(wgpu::Color {
                            r: pass.st.clear[0] as f64,
                            g: pass.st.clear[1] as f64,
                            b: pass.st.clear[2] as f64,
                            a: pass.st.clear[3] as f64,
                        }),
                        store: wgpu::StoreOp::Store,
                    },
                })],
                depth_stencil_attachment: None,
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
            rp.set_scissor_rect(
                pass.st.viewport_x,
                pass.st.viewport_y,
                pass.st.viewport_w,
                pass.st.viewport_h,
            );

            let mut seg_i: usize = 0;
            for cmd in pass.commands {
                match cmd {
                    DrawCmd::Sprites(seg) => {
                        if seg.instance_count == 0 {
                            continue;
                        }
                        let Some(bg) = sprite_segment_bgs.get(seg_i) else { break };
                        seg_i += 1;

                        rp.set_pipeline(&sprite_pipeline);
                        rp.set_bind_group(1, bg, &[]);
                        for batch in &seg.batches {
                            let Some(tex) = self.textures.get(&batch.texture_id) else { continue };
                            rp.set_bind_group(0, &tex.bind_group, &[]);
                            rp.draw(0..6, batch.first_instance..(batch.first_instance + batch.instance_count));
                        }
                    }
                    DrawCmd::Mesh(draw) => {
                        let (Some(pipeline), Some(bg)) = (mesh_pipeline.as_ref(), mesh_bg.as_ref()) else { continue };
                        let Some(mesh) = self.meshes.get(&draw.mesh_id) else { continue };
                        rp.set_pipeline(pipeline);
                        rp.set_bind_group(0, bg, &[draw.ubo_offset]);
                        rp.set_vertex_buffer(0, mesh.vertex_buf.slice(..));
                        rp.set_index_buffer(mesh.index_buf.slice(..), wgpu::IndexFormat::Uint16);
                        rp.draw_indexed(0..mesh.index_count, 0, 0..1);
                    }
                }
            }
        }

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

        let Some(pass) = self.pass.as_mut() else { return Ok(()) };

        // Match native runtime's sprite sizing convention (base quad is 128x128).
        let raw_uv_scale_x = uv_max.0 - uv_min.0;
        let raw_uv_scale_y = uv_max.1 - uv_min.1;
        let uv_scale_x = if raw_uv_scale_x <= 0.0 { 1.0 } else { raw_uv_scale_x };
        let uv_scale_y = if raw_uv_scale_y <= 0.0 { 1.0 } else { raw_uv_scale_y };
        let region_w = tex_w as f32 * uv_scale_x;
        let region_h = tex_h as f32 * uv_scale_y;
        let base_size = 128.0f32;
        let tex_scale_x = if region_w > 0.0 { region_w / base_size } else { 1.0 };
        let tex_scale_y = if region_h > 0.0 { region_h / base_size } else { 1.0 };
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
    ) -> anyhow::Result<()> {
        let Some(pass) = self.pass.as_mut() else { return Ok(()) };
        if self.frame.is_none() {
            return Ok(());
        }
        pass.flush_sprites();
        pass.commands.push(DrawCmd::Mesh(MeshDraw {
            mesh_id,
            x,
            y,
            rotation,
            scale_x,
            scale_y,
            color,
            ubo_offset: 0,
        }));
        Ok(())
    }

    pub fn create_mesh_rectangle(&mut self, width: f32, height: f32) -> i32 {
        let id = self.next_mesh_id;
        self.next_mesh_id += 1;
        let hw = width * 0.5;
        let hh = height * 0.5;
        let vertices: [f32; 8] = [-hw, -hh, hw, -hh, hw, hh, -hw, hh];
        let indices: [u16; 6] = [0, 1, 2, 0, 2, 3];

        let vb = self.device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("mgstudio-mesh-rect-vb"),
            contents: bytemuck::cast_slice(&vertices),
            usage: wgpu::BufferUsages::VERTEX | wgpu::BufferUsages::COPY_DST,
        });
        let ib = self.device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("mgstudio-mesh-rect-ib"),
            contents: bytemuck::cast_slice(&indices),
            usage: wgpu::BufferUsages::INDEX | wgpu::BufferUsages::COPY_DST,
        });
        self.meshes.insert(
            id,
            GpuMesh {
                vertex_count: 4,
                index_count: 6,
                vertex_buf: vb,
                index_buf: ib,
            },
        );
        id
    }

    pub fn create_mesh_triangles_xy(&mut self, vertices_xy: &[f32]) -> i32 {
        let vcount = vertices_xy.len() / 2;
        if vcount == 0 {
            return 0;
        }
        let usable_vcount = vcount - (vcount % 3);
        if usable_vcount == 0 || usable_vcount > 65535 {
            return 0;
        }
        let trimmed = &vertices_xy[..usable_vcount * 2];
        let mut indices: Vec<u16> = Vec::with_capacity(usable_vcount);
        for i in 0..usable_vcount {
            indices.push(i as u16);
        }
        let id = self.next_mesh_id;
        self.next_mesh_id += 1;
        let vb = self.device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("mgstudio-mesh-tris-vb"),
            contents: bytemuck::cast_slice(trimmed),
            usage: wgpu::BufferUsages::VERTEX | wgpu::BufferUsages::COPY_DST,
        });
        let ib = self.device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("mgstudio-mesh-tris-ib"),
            contents: bytemuck::cast_slice(indices.as_slice()),
            usage: wgpu::BufferUsages::INDEX | wgpu::BufferUsages::COPY_DST,
        });
        self.meshes.insert(
            id,
            GpuMesh {
                vertex_count: usable_vcount as u32,
                index_count: usable_vcount as u32,
                vertex_buf: vb,
                index_buf: ib,
            },
        );
        id
    }

    pub fn create_texture_rgba8(&mut self, width: u32, height: u32, pixels_rgba8: &[u8], nearest: bool) -> anyhow::Result<i32> {
        self.ensure_sprite_resources()?;
        let id = self.next_texture_id;
        self.next_texture_id += 1;
        self.create_texture_rgba8_with_id(id, width, height, pixels_rgba8, nearest, false)?;
        Ok(id)
    }

    pub fn create_render_target(&mut self, width: u32, height: u32, nearest: bool) -> anyhow::Result<i32> {
        self.ensure_sprite_resources()?;
        let id = self.next_texture_id;
        self.next_texture_id += 1;
        self.create_texture_rgba8_with_id(id, width, height, &vec![0u8; (width.max(1) * height.max(1) * 4) as usize], nearest, true)?;
        Ok(id)
    }

    pub fn texture_width(&self, texture_id: i32) -> u32 {
        self.textures.get(&texture_id).map(|t| t.width).unwrap_or(0)
    }

    pub fn texture_height(&self, texture_id: i32) -> u32 {
        self.textures.get(&texture_id).map(|t| t.height).unwrap_or(0)
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
        let Some(tex) = self.textures.get(&texture_id) else { return Ok(()) };
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

    pub fn copy_texture_to_texture(&mut self, dst_texture_id: i32, dst_x: u32, dst_y: u32, src_texture_id: i32) -> anyhow::Result<()> {
        let Some(dst) = self.textures.get(&dst_texture_id) else { return Ok(()) };
        let Some(src) = self.textures.get(&src_texture_id) else { return Ok(()) };
        let mut encoder = self.device.create_command_encoder(&wgpu::CommandEncoderDescriptor {
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
                origin: wgpu::Origin3d { x: dst_x, y: dst_y, z: 0 },
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

    pub fn set_texture_sampler(&mut self, texture_id: i32, sampler_kind: i32) -> anyhow::Result<()> {
        // 0 = linear, otherwise nearest (best-effort; matches current engine usage).
        let nearest = sampler_kind != 0;
        self.ensure_sprite_resources()?;
        let Some(tex) = self.textures.get_mut(&texture_id) else { return Ok(()) };
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
            wgpu::TextureUsages::TEXTURE_BINDING | wgpu::TextureUsages::COPY_DST | wgpu::TextureUsages::COPY_SRC
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
            self.surface_format.ok_or_else(|| anyhow!("wgpu: surface not configured"))
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
        let bgl_tex = self.device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
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
        let bgl_globals = self.device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
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

        let pipeline_layout = self.device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
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
        let sm = self.device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("mgstudio_sprite_wgsl"),
            source: wgpu::ShaderSource::Wgsl(wgsl.into()),
        });
        let pipeline = self.device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
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

    fn ensure_sprite_pipeline_for_format(&mut self, format: wgpu::TextureFormat) -> anyhow::Result<()> {
        if format == wgpu::TextureFormat::Rgba8Unorm {
            return self.ensure_sprite_pipeline_rgba8();
        }
        if self.sprite.pipeline_surface_format == Some(format) && self.sprite.pipeline_surface.is_some() {
            return Ok(());
        }

        let pl = self
            .sprite
            .pipeline_layout
            .as_ref()
            .ok_or_else(|| anyhow!("wgpu: sprite pipeline layout not initialized"))?;
        let wgsl = load_wgsl_required(&self.assets_base, "shaders/mgstudio/2d/sprite.wgsl")?;
        let sm = self.device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("mgstudio_sprite_wgsl_surface"),
            source: wgpu::ShaderSource::Wgsl(wgsl.into()),
        });
        let pipeline = self.device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
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
        let Some(buf) = self.sprite.globals_buf.as_ref() else { return };
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
        self.queue.write_buffer(buf, 0, bytemuck::cast_slice(&globals));
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
            let Some(tg) = self.textures.get(&id) else { continue };
            rp.set_bind_group(0, &tg.bind_group, &[]);
            rp.draw(0..6, batch.first_instance..(batch.first_instance + batch.instance_count));
        }
        Ok(())
    }

    fn ensure_mesh_resources(&mut self) -> anyhow::Result<()> {
        if self.mesh.pipeline_layout.is_some() {
            return Ok(());
        }
        let bgl_uniform = self.device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
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
        let pl = self.device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("mgstudio_mesh_pl"),
            bind_group_layouts: &[&bgl_uniform],
            immediate_size: 0,
        });
        let cap = 256u64; // will grow on demand (alignment is at least 256 on Metal)
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
                    size: None,
                }),
            }],
        });
        self.mesh.bgl_uniform = Some(bgl_uniform);
        self.mesh.pipeline_layout = Some(pl);
        self.mesh.uniform_buf = Some(uniform_buf);
        self.mesh.uniform_bg = Some(bg);
        self.mesh.uniform_capacity = cap;
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
        let sm = self.device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("mgstudio_mesh_wgsl"),
            source: wgpu::ShaderSource::Wgsl(wgsl.into()),
        });
        let vb_layout = wgpu::VertexBufferLayout {
            array_stride: 8,
            step_mode: wgpu::VertexStepMode::Vertex,
            attributes: &[wgpu::VertexAttribute {
                offset: 0,
                shader_location: 0,
                format: wgpu::VertexFormat::Float32x2,
            }],
        };
        let pipeline = self.device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
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

    fn prepare_mesh_uniforms(&mut self, pass: &mut GpuPassRecorder) -> anyhow::Result<()> {
        // Assign dynamic offsets for each mesh draw (alignment is backend-limited).
        let align = self.device.limits().min_uniform_buffer_offset_alignment.max(256) as u64;
        let mut buf: Vec<u8> = Vec::new();

        for cmd in &mut pass.commands {
            if let DrawCmd::Mesh(draw) = cmd {
                let offset = align_up(buf.len() as u64, align);
                if offset as usize > buf.len() {
                    buf.resize(offset as usize, 0);
                }
                let bytes = mesh_uniform_bytes(&pass.st, draw);
                draw.ubo_offset = offset as u32;
                buf.extend_from_slice(&bytes);

                // Pad to alignment for the next entry.
                let padded = align_up(buf.len() as u64, align) as usize;
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
                        size: None,
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
        let Some(mesh) = self.meshes.get(&draw.mesh_id) else { return Ok(()) };

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
        };
        self.commands.push(DrawCmd::Sprites(seg));
    }
}

fn pick_surface_format(caps: &wgpu::SurfaceCapabilities) -> wgpu::TextureFormat {
    // Prefer SRGB formats when available (common on Metal).
    for f in caps.formats.iter().copied() {
        if matches!(f, wgpu::TextureFormat::Bgra8UnormSrgb | wgpu::TextureFormat::Rgba8UnormSrgb) {
            return f;
        }
    }
    caps.formats.first().copied().unwrap_or(wgpu::TextureFormat::Bgra8UnormSrgb)
}

fn load_wgsl_required(assets_base: &str, rel: &str) -> anyhow::Result<String> {
    let base = assets_base.trim();
    if base.is_empty() {
        return Err(anyhow!("wgpu: assets_base is empty; cannot load shader: {rel}"));
    }
    let full = std::path::Path::new(base).join(rel.trim_start_matches('/'));
    std::fs::read_to_string(&full).with_context(|| format!("wgpu: failed to read shader: {}", full.display()))
}

fn align_up(v: u64, align: u64) -> u64 {
    if align == 0 {
        return v;
    }
    ((v + align - 1) / align) * align
}

fn mesh_uniform_bytes(pass: &GpuPassState, draw: &MeshDraw) -> [u8; 80] {
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
        0.0,
        0.0,
        1.0,
        1.0,
    ];
    let mut out = [0u8; 80];
    out.copy_from_slice(bytemuck::cast_slice(&floats));
    out
}
