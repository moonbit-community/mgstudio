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
// Bevy source: `bevy/crates/bevy_render/src/pipelined_rendering.rs`.

///|
pub struct RenderAppChannels {
  mut render_app_in_render_thread : Bool
}

///|
pub fn RenderAppChannels::new() -> RenderAppChannels {
  RenderAppChannels::{ render_app_in_render_thread: false }
}

///|
pub fn RenderAppChannels::send_blocking(
  self : RenderAppChannels,
  _render_app : @app.SubApp[@ecs.World],
) -> RenderAppChannels {
  self.render_app_in_render_thread = true
  self
}

///|
pub fn RenderAppChannels::recv(
  self : RenderAppChannels,
  render_app : @app.SubApp[@ecs.World],
) -> (RenderAppChannels, @app.SubApp[@ecs.World]) {
  self.render_app_in_render_thread = false
  (self, render_app)
}

///|
pub fn RenderAppChannels::render_app_in_render_thread(
  self : RenderAppChannels,
) -> Bool {
  self.render_app_in_render_thread
}

///|
let ecs_key_render_app_channels : @ecs.ResourceKey[RenderAppChannels] = @ecs.register_resource(
  debug_name="mgstudio_render::RenderAppChannels",
)

///|
pub impl @app.Resource for RenderAppChannels with resource() {
  ecs_key_render_app_channels
}

///|
fn renderer_extract(
  main_world : @ecs.World,
  render_extract_world : @ecs.World,
) -> (@ecs.World, @ecs.World) {
  if (try! main_world.get_resource(RenderAppChannels::resource()))
    is Some(channels) {
    channels.render_app_in_render_thread = false
    main_world.insert_resource(RenderAppChannels::resource(), channels)
  }
  (main_world, render_extract_world)
}

///|
pub fn pipelined_rendering_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  let mut next = app
  if next.get_sub_app(@app.RenderApp) is None {
    return next
  }
  if !next.contains_resource(RenderAppChannels::resource()) {
    next = next.insert_resource(RenderAppChannels::new())
  }
  if next.get_sub_app(render_extract_app_label()) is None {
    next = next.insert_sub_app(
      render_extract_app_label(),
      @app.SubApp::new(@ecs.World::new()),
    )
  }
  next.set_sub_app_extract(render_extract_app_label(), renderer_extract)
}

///|
pub fn render_extract_app_label() -> @app.AppLabel {
  @app.RenderExtractApp
}
