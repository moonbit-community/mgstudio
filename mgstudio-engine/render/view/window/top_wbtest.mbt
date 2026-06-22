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
