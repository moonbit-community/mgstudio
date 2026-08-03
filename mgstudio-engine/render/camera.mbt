// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
// Bevy source: `bevy/crates/bevy_render/src/camera.rs`.

///|
pub type HostGpuSurface = Int

///|
pub(all) enum HostGpuPresentMode {
  AutoVsync
  AutoNoVsync
  Fifo
  FifoRelaxed
  Immediate
  Mailbox
} derive(Eq, Debug)

///|
pub fn HostGpuPresentMode::default() -> HostGpuPresentMode {
  AutoVsync
}

///|
pub(all) enum HostGpuCompositeAlphaMode {
  Auto
  Opaque
  PreMultiplied
  PostMultiplied
  Inherit
} derive(Eq, Debug)

///|
pub fn HostGpuCompositeAlphaMode::default() -> HostGpuCompositeAlphaMode {
  Auto
}

///|
pub const HOST_GPU_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY : Int = @renderer.SURFACE_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY

///|
fn host_gpu_present_mode_kind(mode : HostGpuPresentMode) -> Int {
  match mode {
    AutoVsync => @renderer.SURFACE_PRESENT_MODE_AUTO_VSYNC
    AutoNoVsync => @renderer.SURFACE_PRESENT_MODE_AUTO_NO_VSYNC
    Fifo => @renderer.SURFACE_PRESENT_MODE_FIFO
    FifoRelaxed => @renderer.SURFACE_PRESENT_MODE_FIFO_RELAXED
    Immediate => @renderer.SURFACE_PRESENT_MODE_IMMEDIATE
    Mailbox => @renderer.SURFACE_PRESENT_MODE_MAILBOX
  }
}

///|
fn host_gpu_composite_alpha_mode_kind(mode : HostGpuCompositeAlphaMode) -> Int {
  match mode {
    Auto => @renderer.SURFACE_COMPOSITE_ALPHA_MODE_AUTO
    Opaque => @renderer.SURFACE_COMPOSITE_ALPHA_MODE_OPAQUE
    PreMultiplied => @renderer.SURFACE_COMPOSITE_ALPHA_MODE_PRE_MULTIPLIED
    PostMultiplied => @renderer.SURFACE_COMPOSITE_ALPHA_MODE_POST_MULTIPLIED
    Inherit => @renderer.SURFACE_COMPOSITE_ALPHA_MODE_INHERIT
  }
}

///|
pub fn host_gpu_create_surface(
  handle : @window.RawHandleWrapper,
) -> HostGpuSurface {
  @renderer.create_surface(handle)
}

///|
pub fn host_gpu_surface_target_id(surface : HostGpuSurface) -> Int {
  @renderer.surface_target_id(surface)
}

///|
pub fn host_gpu_surface_target_id_for_window(window : Int) -> Int {
  @renderer.surface_target_id_for_window(window)
}

///|
pub fn host_gpu_release_surface(surface : HostGpuSurface) -> Unit {
  @renderer.release_surface(surface)
}

///|
pub fn host_gpu_configure_surface(
  device~ : HostGpuDevice,
  surface~ : HostGpuSurface,
  width~ : Int,
  height~ : Int,
  present_mode? : HostGpuPresentMode = HostGpuPresentMode::default(),
  composite_alpha_mode? : HostGpuCompositeAlphaMode = HostGpuCompositeAlphaMode::default(),
  desired_maximum_frame_latency? : Int = HOST_GPU_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY,
) -> Unit {
  @renderer.configure_surface(
    device~,
    surface~,
    width~,
    height~,
    present_mode_kind=host_gpu_present_mode_kind(present_mode),
    composite_alpha_mode_kind=host_gpu_composite_alpha_mode_kind(
      composite_alpha_mode,
    ),
    desired_maximum_frame_latency~,
  )
}

///|
pub fn host_gpu_begin_frame(surface : HostGpuSurface) -> Bool {
  @renderer.begin_frame(surface)
}

///|
pub fn host_gpu_set_active_surface_target(target_id : Int) -> Unit {
  @renderer.set_active_surface_target(target_id)
}

///|
// Bevy source:
// - `bevy/crates/bevy_render/src/camera.rs` (`PendingQueues`).
pub struct ViewPendingQueues {
  mut current_frame : @hashset.HashSet[(@core.Entity, MainEntity)]
  mut prev_frame : @hashset.HashSet[(@core.Entity, MainEntity)]
}

///|
pub fn ViewPendingQueues::ViewPendingQueues() -> ViewPendingQueues {
  { current_frame: HashSet([]), prev_frame: HashSet([]) }
}

///|
pub fn ViewPendingQueues::prepare_for_new_frame(
  self : ViewPendingQueues,
) -> Unit {
  let prev_frame = self.prev_frame
  self.prev_frame = self.current_frame
  self.current_frame = prev_frame
  self.current_frame.clear()
}

///|
pub fn ViewPendingQueues::push_current(
  self : ViewPendingQueues,
  render_entity : @core.Entity,
  main_entity : MainEntity,
) -> Unit {
  self.current_frame.add((render_entity, main_entity))
}

///|
pub fn ViewPendingQueues::prev_frame(
  self : ViewPendingQueues,
) -> @hashset.HashSet[(@core.Entity, MainEntity)] {
  self.prev_frame
}

///|
pub fn ViewPendingQueues::current_len(self : ViewPendingQueues) -> Int {
  self.current_frame.length()
}

///|
pub fn ViewPendingQueues::prev_len(self : ViewPendingQueues) -> Int {
  self.prev_frame.length()
}

///|
pub struct PendingQueues {
  views : @hashmap.HashMap[@render_view.RetainedViewEntity, ViewPendingQueues]
}

///|
pub fn PendingQueues::PendingQueues() -> PendingQueues {
  { views: HashMap([]) }
}

///|
pub fn PendingQueues::view_or_insert(
  self : PendingQueues,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> ViewPendingQueues {
  match self.views.get(retained_view_entity) {
    Some(queues) => queues
    None => {
      let queues = ViewPendingQueues::ViewPendingQueues()
      self.views.set(retained_view_entity, queues)
      queues
    }
  }
}

///|
pub fn PendingQueues::get(
  self : PendingQueues,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> ViewPendingQueues? {
  self.views.get(retained_view_entity)
}

///|
pub fn PendingQueues::prepare_for_new_frame(
  self : PendingQueues,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> ViewPendingQueues {
  let queues = self.view_or_insert(retained_view_entity)
  queues.prepare_for_new_frame()
  queues
}

///|
pub fn PendingQueues::push_current(
  self : PendingQueues,
  retained_view_entity : @render_view.RetainedViewEntity,
  render_entity : @core.Entity,
  main_entity : MainEntity,
) -> Unit {
  self
  .view_or_insert(retained_view_entity)
  .push_current(render_entity, main_entity)
}

///|
pub fn PendingQueues::current_len(
  self : PendingQueues,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> Int {
  match self.views.get(retained_view_entity) {
    Some(queues) => queues.current_len()
    None => 0
  }
}

///|
pub fn PendingQueues::prev_len(
  self : PendingQueues,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> Int {
  match self.views.get(retained_view_entity) {
    Some(queues) => queues.prev_len()
    None => 0
  }
}

///|
pub fn PendingQueues::contains_view(
  self : PendingQueues,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> Bool {
  self.views.contains(retained_view_entity)
}

///|
pub fn PendingQueues::view_len(self : PendingQueues) -> Int {
  self.views.length()
}

///|
pub fn PendingQueues::expire_stale_views(
  self : PendingQueues,
  live_views : @hashset.HashSet[@render_view.RetainedViewEntity],
) -> Unit {
  let stale : Array[@render_view.RetainedViewEntity] = []
  for view, _queues in self.views {
    if !live_views.contains(view) {
      stale.push(view)
    }
  }
  for view in stale {
    self.views.remove(view)
  }
}

///|
pub type CameraOutputMode = @render_camera_sort.CameraOutputMode

///|
pub type SortedCamera = @render_camera_sort.SortedCamera

///|
pub type SortedCameras = @render_camera_sort.SortedCameras

///|
pub let sorted_cameras_key : @ecs.ResourceKey[SortedCameras] = @render_camera_sort.sorted_cameras_key

///|
pub fn ensure_sorted_cameras_resource(world : @ecs.World) -> Unit {
  @render_camera_sort.ensure_sorted_cameras_resource(world)
}

///|
pub fn sorted_cameras_ref_or_abort(
  world : @ecs.World,
) -> @ecs.ResourceMut[SortedCameras] {
  @render_camera_sort.sorted_cameras_ref_or_abort(world)
}

///|
pub fn sorted_cameras_or_default(world : @ecs.World) -> SortedCameras {
  @render_camera_sort.sorted_cameras_or_default(world)
}

///|
pub fn sorted_cameras_replace(
  sorted_cameras_ref : @ecs.ResourceMut[SortedCameras],
  cameras : Array[SortedCamera],
) -> Unit {
  @render_camera_sort.sorted_cameras_replace(sorted_cameras_ref, cameras)
}

///|
pub fn sorted_cameras_clear(
  sorted_cameras_ref : @ecs.ResourceMut[SortedCameras],
) -> Unit {
  @render_camera_sort.sorted_cameras_clear(sorted_cameras_ref)
}

///|
// Bevy source: `bevy/crates/bevy_render/src/camera.rs` --
// `register_required_components::<Camera, SyncToRenderWorld>()` in the render
// plugin. `bevy_camera` never references the render world; the render side
// attaches the sync marker to every camera.
pub fn register_camera_sync_to_render_world(
  world : @ecs.World,
) -> Unit raise @ecs.RequiredComponentsError {
  world.register_required_components_with(
    @camera_camera.ecs_key_camera,
    ecs_key_sync_to_render_world,
    fn() { SyncToRenderWorld() },
  )
}

///|
pub fn ensure_camera_sync_to_render_world(world : @ecs.World) -> Unit {
  register_camera_sync_to_render_world(world) catch {
    DuplicateRegistration(_, _) => ()
    ArchetypeExists(component_id) =>
      abort(
        "Camera sync registration ran too late for component \{component_id}",
      )
    CyclicRequirement(requiree, required) =>
      abort("Camera sync required-component cycle: \{requiree} -> \{required}")
  }
}

///|
pub struct RenderTargetComputed3d {
  target_id : Int
  target_size : @math.IVec2
  scale_factor : Float
}

///|
pub fn render3d_target_info(
  world : @ecs.World,
  target : @camera_camera.RenderTarget,
) -> RenderTargetComputed3d? {
  match target {
    Screen => {
      let width = @window.window_physical_width_for(world, Primary)
      let height = @window.window_physical_height_for(world, Primary)
      if width <= 0 || height <= 0 {
        return None
      }
      let mut scale_factor = @window.window_scale_factor_for(world, Primary)
      if scale_factor <= 0.0F {
        scale_factor = 1.0F
      }
      Some({
        target_id: -1,
        target_size: @math.IVec2::new(width, height),
        scale_factor,
      })
    }
    Window(window_ref) => {
      guard @window.window_host_window_for_ref(world, window_ref)
        is Some(host_window) else {
        return None
      }
      let surface_target_id = host_gpu_surface_target_id_for_window(host_window)
      if surface_target_id == 0 {
        return None
      }
      let width = @window.window_physical_width_for(world, window_ref)
      let height = @window.window_physical_height_for(world, window_ref)
      if width <= 0 || height <= 0 {
        return None
      }
      let mut scale_factor = @window.window_scale_factor_for(world, window_ref)
      if scale_factor <= 0.0F {
        scale_factor = 1.0F
      }
      Some({
        target_id: surface_target_id,
        target_size: @math.IVec2::new(width, height),
        scale_factor,
      })
    }
    Image(handle) => {
      let width = @asset.asset_texture_width(handle)
      let height = @asset.asset_texture_height(handle)
      if width <= 0 || height <= 0 {
        return None
      }
      Some({
        target_id: handle.id(),
        target_size: @math.IVec2::new(width, height),
        scale_factor: 1.0F,
      })
    }
  }
}

///|
pub fn render3d_clamp_viewport(
  viewport : @camera_viewport.Viewport,
  target_size : @math.IVec2,
) -> @camera_viewport.Viewport {
  viewport.clamp_to_size(target_size)
}

///|
fn render3d_scale_viewport_axis(value : Int, scale : Float) -> Int {
  if value <= 0 || scale <= 0.0F {
    return 0
  }
  let scaled = Float::from_double(value.to_double()) * scale
  if scaled <= 0.0F {
    return 0
  }
  scaled.to_int()
}

///|
fn render3d_scale_viewport(
  viewport : @camera_viewport.Viewport,
  scale : Float,
) -> @camera_viewport.Viewport {
  let position = @math.IVec2::new(
    render3d_scale_viewport_axis(viewport.physical_position.x, scale),
    render3d_scale_viewport_axis(viewport.physical_position.y, scale),
  )
  let size = @math.IVec2::new(
    render3d_scale_viewport_axis(viewport.physical_size.x, scale),
    render3d_scale_viewport_axis(viewport.physical_size.y, scale),
  )
  @camera_viewport.Viewport::new(position, size).with_depth(
    viewport.depth_min,
    viewport.depth_max,
  )
}

///|
fn render3d_sub_camera_view_eq(
  lhs : @camera_camera.SubCameraView3d?,
  rhs : @camera_camera.SubCameraView3d?,
) -> Bool {
  match (lhs, rhs) {
    (None, None) => true
    (Some(a), Some(b)) =>
      render3d_ivec2_eq(a.full_size, b.full_size) &&
      render3d_vec2_eq(a.offset, b.offset) &&
      render3d_ivec2_eq(a.size, b.size)
    _ => false
  }
}

///|
fn render3d_ivec2_eq(lhs : @math.IVec2, rhs : @math.IVec2) -> Bool {
  lhs.x == rhs.x && lhs.y == rhs.y
}

///|
fn render3d_vec2_eq(lhs : @math.Vec2, rhs : @math.Vec2) -> Bool {
  lhs.x == rhs.x && lhs.y == rhs.y
}

///|
fn render3d_optional_ivec2_eq(lhs : @math.IVec2?, rhs : @math.IVec2?) -> Bool {
  match (lhs, rhs) {
    (None, None) => true
    (Some(a), Some(b)) => render3d_ivec2_eq(a, b)
    _ => false
  }
}

///|
fn render3d_target_info_eq(
  lhs : @camera_camera.RenderTargetInfo?,
  rhs : @camera_camera.RenderTargetInfo?,
) -> Bool {
  match (lhs, rhs) {
    (None, None) => true
    (Some(a), Some(b)) =>
      render3d_ivec2_eq(a.physical_size, b.physical_size) &&
      a.scale_factor == b.scale_factor
    _ => false
  }
}

///|
// Bevy source: `bevy/crates/bevy_render/src/camera.rs::camera_system`.
pub fn camera_system(world : @ecs.World) -> Unit {
  let projection_updates : Array[
    (@core.Entity, @camera_projection3d.Projection),
  ] = []
  let camera_updates : Array[(@core.Entity, @camera_camera.Camera)] = []
  let camera_query : @ecs.Query[
    (
      @core.Entity,
      @ecs.Read[@camera_camera.Camera],
      @ecs.Read[@camera_projection3d.Projection],
      @ecs.Optional[@camera_camera.RenderTarget],
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! camera_query.view(fn(_query_entity, data) {
    let (entity, camera_read, projection_read, target_opt) = data
    let target = match target_opt.value() {
      Some(v) => v
      None => Screen
    }
    match render3d_target_info(world, target) {
      Some(target_info) => {
        let mut camera = camera_read.value()
        let viewport_size = camera.physical_viewport_size()
        let next_target_info = Some(
          @camera_camera.RenderTargetInfo::new(
            target_info.target_size,
            target_info.scale_factor,
          ),
        )
        let scale_factor_changed = camera.computed.target_info
          is Some(old_target_info) &&
          old_target_info.scale_factor > 0.0F &&
          old_target_info.scale_factor != target_info.scale_factor
        let should_update = !render3d_target_info_eq(
            camera.computed.target_info,
            next_target_info,
          ) ||
          camera_read.is_added() ||
          projection_read.is_changed() ||
          !render3d_optional_ivec2_eq(
            camera.computed.old_viewport_size,
            viewport_size,
          ) ||
          !render3d_sub_camera_view_eq(
            camera.computed.old_sub_camera_view,
            camera.sub_camera_view,
          )
        if should_update {
          if scale_factor_changed &&
            camera.computed.target_info is Some(old_target_info) &&
            camera.viewport is Some(viewport) {
            let resize_factor = target_info.scale_factor /
              old_target_info.scale_factor
            camera = camera.with_viewport(
              render3d_scale_viewport(viewport, resize_factor),
            )
          }
          if camera.viewport is Some(viewport) {
            camera = camera.with_viewport(
              render3d_clamp_viewport(viewport, target_info.target_size),
            )
          }
        }
        let projection = projection_read.value()
        let mut updated_projection = projection
        let mut clip_from_view = projection.get_clip_from_view()
        match camera.logical_viewport_size() {
          Some(logical_size) =>
            if logical_size.x != 0.0F && logical_size.y != 0.0F {
              updated_projection = projection.update(
                logical_size.x,
                logical_size.y,
              )
              clip_from_view = match camera.sub_camera_view {
                Some(sub_view) =>
                  updated_projection.get_clip_from_view_for_sub(sub_view)
                None => updated_projection.get_clip_from_view()
              }
              if should_update {
                projection_updates.push((entity, updated_projection))
              }
            }
          None => ()
        }
        let computed = @camera_camera.ComputedCameraValues::new(
          clip_from_view.to_mat4(),
          next_target_info,
          camera.physical_viewport_size(),
          camera.sub_camera_view,
        )
        let camera_with_computed = camera.with_computed(computed)
        if should_update {
          camera_updates.push((entity, camera_with_computed))
        }
      }
      None => ()
    }
  })
  for update in projection_updates {
    try! world.set_by_key(
      update.0,
      @camera_projection3d.ecs_key_projection,
      update.1,
    )
  }
  for update in camera_updates {
    try! world.set_by_key(update.0, @camera_camera.ecs_key_camera, update.1)
  }
}

///|
pub fn render3d_projection_runtime_update(
  projection : @camera_projection3d.Projection,
  runtime : @camera_projection3d.ProjectionRuntime3d?,
  force_update : Bool,
  camera : @camera_camera.Camera,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> (
  @camera_projection3d.Projection,
  @camera_projection3d.ProjectionRuntime3d?,
) {
  match
    @camera_projection_math.camera_viewport_rect_logical(
      camera, target_size, scale_factor,
    ) {
    Some((_, _, viewport_width, viewport_height)) => {
      let updated_projection = projection.update(
        viewport_width, viewport_height,
      )
      let is_orthographic = !updated_projection.is_perspective()
      let orthographic_first_slice_depth = if is_orthographic {
        let clip_from_view = updated_projection.get_clip_from_view()
        let row_two = clip_from_view.row(2)
        let safe_row_two_z = if row_two.z.abs() <= 1.0e-6F {
          1.0e-6F
        } else {
          row_two.z
        }
        (row_two.w - 1.0F) / safe_row_two_z
      } else {
        0.0F
      }
      let next_runtime = @camera_projection3d.ProjectionRuntime3d::{
        last_view_width: viewport_width,
        last_view_height: viewport_height,
        is_orthographic,
        orthographic_first_slice_depth,
      }
      if runtime is Some(previous_runtime) &&
        previous_runtime.last_view_width == viewport_width &&
        previous_runtime.last_view_height == viewport_height &&
        previous_runtime.is_orthographic == is_orthographic &&
        previous_runtime.orthographic_first_slice_depth ==
        orthographic_first_slice_depth &&
        !force_update {
        (projection, None)
      } else {
        (updated_projection, Some(next_runtime))
      }
    }
    None => (projection, None)
  }
}

///|
/// Camera jitter settings aligned with Bevy's `TemporalJitter`.
pub struct TemporalJitter {
  offset : @math.Vec2
} derive(ToJson, FromJson)

///|
pub fn TemporalJitter::TemporalJitter() -> TemporalJitter {
  { offset: @math.Vec2::new(0.0F, 0.0F) }
}

///|
pub fn TemporalJitter::new(offset : @math.Vec2) -> TemporalJitter {
  { offset, }
}

///|
pub fn TemporalJitter::with_offset(
  self : TemporalJitter,
  offset : @math.Vec2,
) -> TemporalJitter {
  self |> ignore
  { offset, }
}

///|
pub let ecs_key_temporal_jitter : @ecs.ComponentKey[TemporalJitter] = @ecs.register_component(
  debug_name="render3d.temporal_jitter",
)

///|
pub impl @ecs.Component for TemporalJitter with fn component() {
  ecs_key_temporal_jitter
}

///|
// Bevy source: `bevy/crates/bevy_render/src/camera.rs::TemporalJitter::jitter_projection`.

pub fn render3d_projection_matrix_apply_temporal_jitter(
  clip_from_view : @camera_projection3d.ProjectionMatrix3d,
  temporal_jitter : TemporalJitter,
  view_width : Int,
  view_height : Int,
) -> @camera_projection3d.ProjectionMatrix3d {
  let width = Float::from_double(view_width.to_double())
  let height = Float::from_double(view_height.to_double())
  if width <= 0.0F || height <= 0.0F {
    return clip_from_view
  }
  let mut jitter_x = temporal_jitter.offset.x * 2.0F / width
  let mut jitter_y = temporal_jitter.offset.y * -2.0F / height
  if clip_from_view.w_axis.w == 1.0F {
    jitter_x = jitter_x * clip_from_view.x_axis.x * 0.5F
    jitter_y = jitter_y * clip_from_view.y_axis.y * 0.5F
  }
  let z_axis = clip_from_view.z_axis
  {
    ..clip_from_view,
    z_axis: @math.Vec4::new(
      z_axis.x + jitter_x,
      z_axis.y + jitter_y,
      z_axis.z,
      z_axis.w,
    ),
  }
}
