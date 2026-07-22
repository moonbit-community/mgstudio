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
  let window = @window.Window::Window()
  window.present_mode = AutoVsync
  let auto_vsync_ok = runner_surface_present_mode(Some(window)) == AutoVsync
  window.present_mode = AutoNoVsync
  let auto_no_vsync_ok = runner_surface_present_mode(Some(window)) ==
    AutoNoVsync
  window.present_mode = Fifo
  let fifo_ok = runner_surface_present_mode(Some(window)) == Fifo
  window.present_mode = FifoRelaxed
  let fifo_relaxed_ok = runner_surface_present_mode(Some(window)) == FifoRelaxed
  window.present_mode = Immediate
  let immediate_ok = runner_surface_present_mode(Some(window)) == Immediate
  window.present_mode = Mailbox
  let mailbox_ok = runner_surface_present_mode(Some(window)) == Mailbox
  let none_fallback_ok = runner_surface_present_mode(None) == Fifo
  debug_inspect(
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
  let window = @window.Window::Window()
  window.composite_alpha_mode = Auto
  let auto_ok = runner_surface_composite_alpha_mode(Some(window)) == Auto
  window.composite_alpha_mode = Opaque
  let opaque_ok = runner_surface_composite_alpha_mode(Some(window)) == Opaque
  window.composite_alpha_mode = PreMultiplied
  let pre_ok = runner_surface_composite_alpha_mode(Some(window)) ==
    PreMultiplied
  window.composite_alpha_mode = PostMultiplied
  let post_ok = runner_surface_composite_alpha_mode(Some(window)) ==
    PostMultiplied
  window.composite_alpha_mode = Inherit
  let inherit_ok = runner_surface_composite_alpha_mode(Some(window)) == Inherit
  let none_fallback_ok = runner_surface_composite_alpha_mode(None) == Auto
  debug_inspect(
    auto_ok && opaque_ok && pre_ok && post_ok && inherit_ok && none_fallback_ok,
    content="true",
  )
}

///|
test "winit: runner maps window desired maximum frame latency" {
  let window = @window.Window::Window()
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
  debug_inspect(
    none_ok &&
    explicit_ok &&
    zero_fallback_ok &&
    negative_fallback_ok &&
    none_window_ok,
    content="true",
  )
}

///|
test "winit: runner keeps event loop alive for logical windows awaiting host creation" {
  let world = @ecs.World::new()
  defer world.close()
  debug_inspect(runner_has_logical_windows(world), content="false")

  let entity = world.spawn()
  try! (world.entity_mut(entity).insert_component(@window.Window::Window())
  |> ignore)

  debug_inspect(runner_has_logical_windows(world), content="true")
}

///|
test "winit: runner excludes closing windows before releasing their surfaces" {
  let world = @ecs.World::new()
  defer world.close()
  let entity = world.spawn()
  let entry = @window.WindowHostEntry::new(entity, 17)
  debug_inspect(runner_host_entry_is_closing(world, entry), content="false")
  try! (world.entity_mut(entity).insert_component(@window.ClosingWindow::{  })
  |> ignore)
  debug_inspect(runner_host_entry_is_closing(world, entry), content="true")
}
