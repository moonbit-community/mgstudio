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
pub fn host_gpu_create_surface(window : Int) -> HostGpuSurface {
  @renderer.create_surface(window)
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
  ViewPendingQueues::{
    current_frame: @hashset.HashSet([]),
    prev_frame: @hashset.HashSet([]),
  }
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
  PendingQueues::{ views: @hashmap.HashMap([]) }
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
