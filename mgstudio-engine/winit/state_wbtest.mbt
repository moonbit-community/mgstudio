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
test "winit: runner maps window present mode to render host mode" {
  let window = @window.Window::default()
  window.present_mode = @window.PresentMode::AutoVsync
  let auto_vsync_ok = runner_surface_present_mode(Some(window)) ==
    @render.HostGpuPresentMode::AutoVsync
  window.present_mode = @window.PresentMode::AutoNoVsync
  let auto_no_vsync_ok = runner_surface_present_mode(Some(window)) ==
    @render.HostGpuPresentMode::AutoNoVsync
  window.present_mode = @window.PresentMode::Fifo
  let fifo_ok = runner_surface_present_mode(Some(window)) ==
    @render.HostGpuPresentMode::Fifo
  window.present_mode = @window.PresentMode::FifoRelaxed
  let fifo_relaxed_ok = runner_surface_present_mode(Some(window)) ==
    @render.HostGpuPresentMode::FifoRelaxed
  window.present_mode = @window.PresentMode::Immediate
  let immediate_ok = runner_surface_present_mode(Some(window)) ==
    @render.HostGpuPresentMode::Immediate
  window.present_mode = @window.PresentMode::Mailbox
  let mailbox_ok = runner_surface_present_mode(Some(window)) ==
    @render.HostGpuPresentMode::Mailbox
  let none_fallback_ok = runner_surface_present_mode(None) ==
    @render.HostGpuPresentMode::Fifo
  inspect(
    auto_vsync_ok &&
    auto_no_vsync_ok &&
    fifo_ok &&
    fifo_relaxed_ok &&
    immediate_ok &&
    mailbox_ok &&
    none_fallback_ok,
    content="true",
  )
}

///|
test "winit: runner maps window composite alpha mode to render host mode" {
  let window = @window.Window::default()
  window.composite_alpha_mode = @window.CompositeAlphaMode::Auto
  let auto_ok = runner_surface_composite_alpha_mode(Some(window)) ==
    @render.HostGpuCompositeAlphaMode::Auto
  window.composite_alpha_mode = @window.CompositeAlphaMode::Opaque
  let opaque_ok = runner_surface_composite_alpha_mode(Some(window)) ==
    @render.HostGpuCompositeAlphaMode::Opaque
  window.composite_alpha_mode = @window.CompositeAlphaMode::PreMultiplied
  let pre_ok = runner_surface_composite_alpha_mode(Some(window)) ==
    @render.HostGpuCompositeAlphaMode::PreMultiplied
  window.composite_alpha_mode = @window.CompositeAlphaMode::PostMultiplied
  let post_ok = runner_surface_composite_alpha_mode(Some(window)) ==
    @render.HostGpuCompositeAlphaMode::PostMultiplied
  window.composite_alpha_mode = @window.CompositeAlphaMode::Inherit
  let inherit_ok = runner_surface_composite_alpha_mode(Some(window)) ==
    @render.HostGpuCompositeAlphaMode::Inherit
  let none_fallback_ok = runner_surface_composite_alpha_mode(None) ==
    @render.HostGpuCompositeAlphaMode::Auto
  inspect(
    auto_ok && opaque_ok && pre_ok && post_ok && inherit_ok && none_fallback_ok,
    content="true",
  )
}

///|
test "winit: runner maps window desired maximum frame latency" {
  let window = @window.Window::default()
  window.desired_maximum_frame_latency = None
  let none_ok = runner_surface_desired_maximum_frame_latency(Some(window)) ==
    @render.HOST_GPU_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY
  window.desired_maximum_frame_latency = Some(5)
  let explicit_ok = runner_surface_desired_maximum_frame_latency(Some(window)) ==
    5
  window.desired_maximum_frame_latency = Some(0)
  let zero_fallback_ok = runner_surface_desired_maximum_frame_latency(
      Some(window),
    ) ==
    @render.HOST_GPU_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY
  window.desired_maximum_frame_latency = Some(-3)
  let negative_fallback_ok = runner_surface_desired_maximum_frame_latency(
      Some(window),
    ) ==
    @render.HOST_GPU_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY
  let none_window_ok = runner_surface_desired_maximum_frame_latency(None) ==
    @render.HOST_GPU_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY
  inspect(
    none_ok &&
    explicit_ok &&
    zero_fallback_ok &&
    negative_fallback_ok &&
    none_window_ok,
    content="true",
  )
}
