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
// Bevy source: `bevy/crates/bevy_render/src/extract_resource.rs`.

///|
const EXTRACT_RESOURCE_PLUGIN_NAME : String = "mgstudio.render.ExtractResourcePlugin"

///|
pub struct ExtractResourcePlugin[_, _] {}

///|
pub fn[R, F] ExtractResourcePlugin::default() -> ExtractResourcePlugin[R, F] {
  ExtractResourcePlugin::{  }
}

///|
pub impl[R : @app.Resource, F] @app.PluginReplacement for ExtractResourcePlugin[
  R,
  F,
] with plugin_name(_self) {
  EXTRACT_RESOURCE_PLUGIN_NAME
}

///|
pub impl[R : @app.Resource, F] @app.PluginReplacement for ExtractResourcePlugin[
  R,
  F,
] with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    extract_resource_plugin_with(app, self)
  }
}

///|
pub struct ExtractedResourceState[R] {
  mut has_value : Bool
  mut value : R?
}

///|
pub fn[R] ExtractedResourceState::default() -> ExtractedResourceState[R] {
  ExtractedResourceState::{ has_value: false, value: None }
}

///|
pub fn[R] ExtractedResourceState::replace(
  self : ExtractedResourceState[R],
  value : R,
) -> Unit {
  self.has_value = true
  self.value = Some(value)
}

///|
pub fn[R] ExtractedResourceState::get(self : ExtractedResourceState[R]) -> R? {
  self.value
}

///|
pub fn[R, S] extract_resource_once(source : S, extract : (S) -> R) -> R {
  extract(source)
}

///|
fn[R] extract_resource_system(
  render_world : @ecs.World,
  resource_key : @ecs.ResourceKey[R],
) -> Unit {
  let main_world = render_source_world(render_world)
  match (main_world.get_resource(resource_key) catch { _ => None }) {
    Some(main_resource) =>
      render_world.insert_resource(resource_key, main_resource)
    None => ()
  }
}

///|
pub fn extract_resource_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  render_plugin(app)
}

///|
pub fn[R : @app.Resource, F] extract_resource_plugin_with(
  app : @app.App[@ecs.World],
  plugin : ExtractResourcePlugin[R, F],
) -> @app.App[@ecs.World] {
  ignore(plugin)
  let next = render_plugin(app)
  let resource_key = R::resource()
  with_render_app(next, fn(sub_app : @app.SubApp[@ecs.World]) {
    sub_app.add_systems(
      render_schedule_stage(),
      @app.system(fn(render_world : @ecs.World) -> Unit {
        extract_resource_system(render_world, resource_key)
      }).in_set(render_system_set_extract_commands),
    )
  })
}

///|
pub fn extract_resource_source_world(world : @ecs.World) -> @ecs.World {
  render_source_world(world)
}
