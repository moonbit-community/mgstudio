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
  classes : @hashmap.HashMap[String, RenderVisibleEntitiesClass]
}

///|
pub fn RenderVisibleEntities::RenderVisibleEntities() -> RenderVisibleEntities {
  RenderVisibleEntities::{ classes: @hashmap.HashMap([]) }
}

///|
pub fn RenderVisibleEntities::clear(self : RenderVisibleEntities) -> Unit {
  self.classes.clear()
}

///|
pub fn RenderVisibleEntities::insert(
  self : RenderVisibleEntities,
  visibility_class : String,
  entities : RenderVisibleEntitiesClass,
) -> Unit {
  self.classes.set(visibility_class, entities)
}

///|
pub fn RenderVisibleEntities::get(
  self : RenderVisibleEntities,
  visibility_class : String,
) -> RenderVisibleEntitiesClass? {
  self.classes.get(visibility_class)
}

///|
pub fn RenderVisibleEntities::class_or_insert(
  self : RenderVisibleEntities,
  visibility_class : String,
) -> RenderVisibleEntitiesClass {
  match self.classes.get(visibility_class) {
    Some(entities_class) => entities_class
    None => {
      let entities_class = RenderVisibleEntitiesClass::RenderVisibleEntitiesClass()
      self.classes.set(visibility_class, entities_class)
      entities_class
    }
  }
}

///|
pub fn RenderVisibleEntities::len(
  self : RenderVisibleEntities,
  visibility_class : String,
) -> Int {
  match self.get(visibility_class) {
    Some(entities_class) => entities_class.visible_len()
    None => 0
  }
}

///|
pub fn RenderVisibleEntities::is_empty(
  self : RenderVisibleEntities,
  visibility_class : String,
) -> Bool {
  self.len(visibility_class) == 0
}

///|
fn render_visible_main_entity_compare(
  left : @render.MainEntity,
  right : @render.MainEntity,
) -> Int {
  let left_bits = left.id().to_bits()
  let right_bits = right.id().to_bits()
  if left_bits < right_bits {
    -1
  } else if left_bits > right_bits {
    1
  } else {
    0
  }
}

///|
fn render_visible_pair_compare(
  left : (@core.Entity, @render.MainEntity),
  right : (@core.Entity, @render.MainEntity),
) -> Int {
  render_visible_main_entity_compare(left.1, right.1)
}

///|
pub struct RenderVisibleEntitiesClass {
  mut entities_cpu_culling : Array[(@core.Entity, @render.MainEntity)]
  entities_gpu_culling : @hashmap.HashMap[@render.MainEntity, @core.Entity]
  added_entities : Array[(@core.Entity, @render.MainEntity)]
  removed_entities : Array[(@core.Entity, @render.MainEntity)]
}

///|
pub fn RenderVisibleEntitiesClass::RenderVisibleEntitiesClass() -> RenderVisibleEntitiesClass {
  RenderVisibleEntitiesClass::{
    entities_cpu_culling: [],
    entities_gpu_culling: @hashmap.HashMap([]),
    added_entities: [],
    removed_entities: [],
  }
}

///|
pub fn RenderVisibleEntitiesClass::prepare_for_new_frame(
  self : RenderVisibleEntitiesClass,
) -> Unit {
  self.added_entities.clear()
  self.removed_entities.clear()
}

///|
pub fn RenderVisibleEntitiesClass::update_cpu_culled_entities(
  self : RenderVisibleEntitiesClass,
  visible_mesh_entities_cpu_culling : Array[(@core.Entity, @render.MainEntity)],
) -> Unit {
  let old_entities_cpu_culling = self.entities_cpu_culling
  self.entities_cpu_culling = []
  let mut old_index = 0
  for visible_pair in visible_mesh_entities_cpu_culling {
    while old_index < old_entities_cpu_culling.length() &&
          render_visible_main_entity_compare(
            old_entities_cpu_culling[old_index].1,
            visible_pair.1,
          ) <
          0 {
      self.removed_entities.push(old_entities_cpu_culling[old_index])
      old_index = old_index + 1
    }
    self.entities_cpu_culling.push(visible_pair)
    if old_index < old_entities_cpu_culling.length() &&
      render_visible_main_entity_compare(
        old_entities_cpu_culling[old_index].1,
        visible_pair.1,
      ) ==
      0 {
      old_index = old_index + 1
    } else {
      self.added_entities.push(visible_pair)
    }
  }
  while old_index < old_entities_cpu_culling.length() {
    self.removed_entities.push(old_entities_cpu_culling[old_index])
    old_index = old_index + 1
  }
}

///|
pub fn RenderVisibleEntitiesClass::add_entity(
  self : RenderVisibleEntitiesClass,
  pair : (@core.Entity, @render.MainEntity),
) -> Unit {
  self.added_entities.push(pair)
}

///|
pub fn RenderVisibleEntitiesClass::added_entities(
  self : RenderVisibleEntitiesClass,
) -> Array[(@core.Entity, @render.MainEntity)] {
  self.added_entities
}

///|
pub fn RenderVisibleEntitiesClass::removed_entities(
  self : RenderVisibleEntitiesClass,
) -> Array[(@core.Entity, @render.MainEntity)] {
  self.removed_entities
}

///|
pub fn RenderVisibleEntitiesClass::entity_pair_is_visible(
  self : RenderVisibleEntitiesClass,
  entity : @core.Entity,
  main_entity : @render.MainEntity,
) -> Bool {
  for pair in self.entities_cpu_culling {
    if pair.0 == entity && pair.1 == main_entity {
      return true
    }
  }
  match self.entities_gpu_culling.get(main_entity) {
    Some(gpu_entity) => gpu_entity == entity
    None => false
  }
}

///|
pub fn RenderVisibleEntitiesClass::insert_gpu_culled_entity(
  self : RenderVisibleEntitiesClass,
  main_entity : @render.MainEntity,
  entity : @core.Entity,
) -> Unit {
  self.entities_gpu_culling.set(main_entity, entity)
}

///|
pub fn RenderVisibleEntitiesClass::iter_visible(
  self : RenderVisibleEntitiesClass,
) -> Array[(@core.Entity, @render.MainEntity)] {
  let visible : Array[(@core.Entity, @render.MainEntity)] = []
  for pair in self.entities_cpu_culling {
    visible.push(pair)
  }
  for main_entity, entity in self.entities_gpu_culling {
    visible.push((entity, main_entity))
  }
  visible
}

///|
pub fn RenderVisibleEntitiesClass::sort_added_entities(
  self : RenderVisibleEntitiesClass,
) -> Unit {
  self.added_entities.sort_by(render_visible_pair_compare)
}

///|
pub fn RenderVisibleEntitiesClass::visible_len(
  self : RenderVisibleEntitiesClass,
) -> Int {
  self.entities_cpu_culling.length() + self.entities_gpu_culling.length()
}

///|
pub let ecs_key_render_visible_entities : @ecs.ComponentKey[
  RenderVisibleEntities,
] = @ecs.register_component(
  debug_name="render.view.visibility.render_visible_entities",
)

///|
pub impl @ecs.Component for RenderVisibleEntities with fn component() {
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
