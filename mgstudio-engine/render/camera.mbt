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
pub type HostGpuFrame = Int

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
pub fn host_gpu_begin_frame(surface : HostGpuSurface) -> HostGpuFrame {
  @renderer.begin_frame(surface)
}

///|
pub fn host_gpu_end_frame(frame : HostGpuFrame) -> Unit {
  @renderer.end_frame(frame)
}

///|
pub fn host_gpu_set_active_surface_target(target_id : Int) -> Unit {
  @renderer.set_active_surface_target(target_id)
}
