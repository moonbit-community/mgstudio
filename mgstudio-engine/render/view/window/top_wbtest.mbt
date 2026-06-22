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
test "render view window: WindowRenderPlugin initializes render-world window resources" {
  let render_sub_app = @app.SubApp::new(@ecs.World::new())
  let app = @app.App::new(@ecs.World::new())
    .insert_sub_app(@app.RenderApp, render_sub_app)
    .add_plugins(WindowRenderPlugin::WindowRenderPlugin())
  let render_world = app.sub_app(@app.RenderApp).world()
  debug_inspect(
    render_world.resource(extracted_windows_resource_key).is_present(),
    content="true",
  )
  debug_inspect(
    render_world.resource(window_surfaces_resource_key).is_present(),
    content="true",
  )
}

///|
test "render view window: WindowRenderPlugin tolerates missing RenderApp" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    WindowRenderPlugin::WindowRenderPlugin(),
  )
  debug_inspect(app.get_sub_app(@app.RenderApp) is None, content="true")
}

///|
test "render view window: ExtractedWindows tracks primary and removes it with entity" {
  let windows = ExtractedWindows::ExtractedWindows()
  let world = @ecs.World::new()
  let entity = world.spawn()
  let handle = @window_pkg.RawHandleWrapper::new(
    @window_pkg.WindowWrapper::new(11),
  )
  let extracted = ExtractedWindow::new(
    entity,
    handle,
    0,
    0,
    @window_pkg.PresentMode::Fifo,
    None,
    @window_pkg.CompositeAlphaMode::Auto,
  )
  windows.primary = Some(entity)
  windows.insert(entity, extracted)
  debug_inspect(windows.len(), content="1")
  debug_inspect(windows.get(entity).unwrap().physical_width, content="1")
  debug_inspect(windows.get(entity).unwrap().physical_height, content="1")
  windows.remove(entity)
  debug_inspect(windows.is_empty(), content="true")
  debug_inspect(windows.primary is None, content="true")
}

///|
test "render view window: WindowSurfaces remove clears configured window state" {
  let surfaces = WindowSurfaces::WindowSurfaces()
  let world = @ecs.World::new()
  let entity = world.spawn()
  ignore(surfaces.configured_windows.add(entity))
  debug_inspect(surfaces.is_configured(entity), content="true")
  surfaces.remove(entity)
  debug_inspect(surfaces.is_configured(entity), content="false")
}

///|
fn test_window_with_size(width : Int, height : Int) -> @window_pkg.Window {
  let window = @window_pkg.Window::Window()
  window.resolution = @window_pkg.WindowResolution::new(width, height)
  window
}

///|
fn spawn_extractable_window(
  world : @ecs.World,
  window : @window_pkg.Window,
  primary? : Bool = false,
) -> @core.Entity {
  let entity = world.spawn()
  try! (world.entity_mut(entity).insert_component(window) |> ignore)
  try! (world
  .entity_mut(entity)
  .insert_component(
    @window_pkg.RawHandleWrapper::new(@window_pkg.WindowWrapper::new(17)),
  )
  |> ignore)
  if primary {
    try! (world
    .entity_mut(entity)
    .insert_component(@window_pkg.PrimaryWindow::{  })
    |> ignore)
  }
  entity
}

///|
test "render view window: extract_windows copies primary window into render world" {
  let main_world = @ecs.World::new()
  let render_world = @ecs.World::new()
  init_extracted_windows(render_world)
  init_window_surfaces(render_world)
  let entity = spawn_extractable_window(
    main_world,
    test_window_with_size(640, 360),
    primary=true,
  )

  extract_windows(main_world, render_world)

  let windows = render_world
    .get_resource(extracted_windows_resource_key)
    .unwrap()
  debug_inspect(windows.primary == Some(entity), content="true")
  debug_inspect(windows.len(), content="1")
  let extracted = windows.get(entity).unwrap()
  debug_inspect(extracted.physical_width, content="640")
  debug_inspect(extracted.physical_height, content="360")
  debug_inspect(extracted.present_mode, content="Fifo")
  debug_inspect(extracted.needs_initial_present, content="true")
}

///|
test "render view window: extract_windows updates size and present-mode change flags" {
  let main_world = @ecs.World::new()
  let render_world = @ecs.World::new()
  init_extracted_windows(render_world)
  init_window_surfaces(render_world)
  let entity = spawn_extractable_window(
    main_world,
    test_window_with_size(640, 360),
  )
  extract_windows(main_world, render_world)

  let next_window = test_window_with_size(800, 600)
  next_window.present_mode = @window_pkg.PresentMode::Immediate
  try! main_world.set_by_key(entity, @window_pkg.ecs_key_window, next_window)
  extract_windows(main_world, render_world)

  let windows = render_world
    .get_resource(extracted_windows_resource_key)
    .unwrap()
  let extracted = windows.get(entity).unwrap()
  debug_inspect(extracted.physical_width, content="800")
  debug_inspect(extracted.physical_height, content="600")
  debug_inspect(extracted.present_mode, content="Immediate")
  debug_inspect(extracted.size_changed, content="true")
  debug_inspect(extracted.present_mode_changed, content="true")
}

///|
test "render view window: extract_windows removes closing windows and consumes cursor once" {
  let main_app = @app.App::new(@ecs.World::new()).add_message(
    @window_pkg.ecs_key_window_closing,
  )
  let main_world = main_app.world()
  let render_world = @ecs.World::new()
  init_extracted_windows(render_world)
  init_window_surfaces(render_world)
  let entity = spawn_extractable_window(
    main_world,
    test_window_with_size(640, 360),
  )
  extract_windows(main_world, render_world)
  render_world
  .get_resource_mut(window_surfaces_resource_key)
  .unwrap()
  .modify(fn(surfaces) { ignore(surfaces.configured_windows.add(entity)) })

  ignore(
    main_world.send_message(@window_pkg.ecs_key_window_closing, @window_pkg.WindowClosing::{
      window: entity,
    }),
  )
  extract_windows(main_world, render_world)
  let windows_after_close = render_world
    .get_resource(extracted_windows_resource_key)
    .unwrap()
  let surfaces_after_close = render_world
    .get_resource(window_surfaces_resource_key)
    .unwrap()
  debug_inspect(windows_after_close.is_empty(), content="true")
  debug_inspect(surfaces_after_close.is_configured(entity), content="false")

  let replacement = spawn_extractable_window(
    main_world,
    test_window_with_size(320, 180),
  )
  extract_windows(main_world, render_world)
  let windows_after_cursor_reuse = render_world
    .get_resource(extracted_windows_resource_key)
    .unwrap()
  debug_inspect(windows_after_cursor_reuse.len(), content="2")
  debug_inspect(
    windows_after_cursor_reuse.get(replacement).unwrap().physical_width,
    content="320",
  )
}

///|
test "render view window: need_surface_configuration follows configured and changed windows" {
  let windows = ExtractedWindows::ExtractedWindows()
  let surfaces = WindowSurfaces::WindowSurfaces()
  let world = @ecs.World::new()
  let entity = world.spawn()
  let extracted = ExtractedWindow::new(
    entity,
    @window_pkg.RawHandleWrapper::new(@window_pkg.WindowWrapper::new(17)),
    640,
    360,
    @window_pkg.PresentMode::Fifo,
    None,
    @window_pkg.CompositeAlphaMode::Auto,
  )
  windows.insert(entity, extracted)
  debug_inspect(need_surface_configuration(windows, surfaces), content="true")
  ignore(surfaces.configured_windows.add(entity))
  debug_inspect(need_surface_configuration(windows, surfaces), content="false")
  let changed = extracted
  changed.size_changed = true
  windows.insert(entity, changed)
  debug_inspect(need_surface_configuration(windows, surfaces), content="true")
}

///|
test "render view window: present mode fallbacks follow Bevy ordering" {
  let auto_vsync = present_mode_fallbacks_raw(
    @window_pkg.PresentMode::AutoVsync,
  )
  debug_inspect(
    auto_vsync == [@wgpu.PRESENT_MODE_FIFO_RELAXED, @wgpu.PRESENT_MODE_FIFO],
    content="true",
  )
  let auto_no_vsync = present_mode_fallbacks_raw(
    @window_pkg.PresentMode::AutoNoVsync,
  )
  debug_inspect(
    auto_no_vsync ==
    [
      @wgpu.PRESENT_MODE_IMMEDIATE,
      @wgpu.PRESENT_MODE_MAILBOX,
      @wgpu.PRESENT_MODE_FIFO,
    ],
    content="true",
  )
  let mailbox = present_mode_fallbacks_raw(@window_pkg.PresentMode::Mailbox)
  debug_inspect(
    mailbox ==
    [
      @wgpu.PRESENT_MODE_MAILBOX,
      @wgpu.PRESENT_MODE_IMMEDIATE,
      @wgpu.PRESENT_MODE_FIFO,
    ],
    content="true",
  )
}

///|
test "render view window: present_mode_raw chooses first supported fallback" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  let window = ExtractedWindow::new(
    entity,
    @window_pkg.RawHandleWrapper::new(@window_pkg.WindowWrapper::new(17)),
    640,
    360,
    @window_pkg.PresentMode::AutoNoVsync,
    None,
    @window_pkg.CompositeAlphaMode::Auto,
  )
  debug_inspect(
    present_mode_raw(window, [
      @wgpu.PRESENT_MODE_FIFO,
      @wgpu.PRESENT_MODE_MAILBOX,
    ]) ==
    @wgpu.PRESENT_MODE_MAILBOX,
    content="true",
  )
}
