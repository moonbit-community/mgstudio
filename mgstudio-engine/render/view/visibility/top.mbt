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
// Bevy source: `bevy/crates/bevy_render/src/view/visibility/mod.rs`.

///|
pub type Visibility = @root_visibility.Visibility

///|
pub type InheritedVisibility = @root_visibility.InheritedVisibility

///|
pub type ViewVisibility = @root_visibility.ViewVisibility

///|
pub type NoFrustumCulling = @root_visibility.NoFrustumCulling

///|
pub type NoCpuCulling = @root_visibility.NoCpuCulling

///|
pub type VisibilityRange = @root_visibility.VisibilityRange

///|
pub struct RenderVisibleEntities {
  entities : @hashmap.HashMap[String, Array[(Int, Int)]]
}

///|
pub fn RenderVisibleEntities::default() -> RenderVisibleEntities {
  RenderVisibleEntities::{ entities: @hashmap.HashMap([]) }
}

///|
pub fn RenderVisibleEntities::clear(self : RenderVisibleEntities) -> Unit {
  self.entities.clear()
}

///|
pub fn RenderVisibleEntities::set(
  self : RenderVisibleEntities,
  filter_key : String,
  entities : Array[(Int, Int)],
) -> Unit {
  self.entities.set(filter_key, entities)
}

///|
pub fn RenderVisibleEntities::get(
  self : RenderVisibleEntities,
  filter_key : String,
) -> Array[(Int, Int)] {
  match self.entities.get(filter_key) {
    Some(entities) => entities
    None => []
  }
}

///|
pub fn RenderVisibleEntities::len(
  self : RenderVisibleEntities,
  filter_key : String,
) -> Int {
  self.get(filter_key).length()
}

///|
pub fn RenderVisibleEntities::is_empty(
  self : RenderVisibleEntities,
  filter_key : String,
) -> Bool {
  self.len(filter_key) == 0
}

///|
pub let ecs_key_render_visible_entities : @ecs.ComponentKey[
  RenderVisibleEntities,
] = @ecs.register_component(
  debug_name="render.view.visibility.render_visible_entities",
)

///|
pub impl @ecs.Component for RenderVisibleEntities with component() {
  ecs_key_render_visible_entities
}

///|
pub fn visibility_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @root_visibility.visibility_plugin(app)
}

///|
pub fn visibility_propagate_system(world : @ecs.World) -> Unit {
  @root_visibility.visibility_propagate_system(world)
}
