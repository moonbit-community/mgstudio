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
// Bevy source: `bevy/crates/bevy_render/src/view/visibility/mod.rs::RenderShadowMapVisibleEntities`.
pub struct RenderShadowMapVisibleEntities {
  subviews : @hashmap.HashMap[
    @render_view.RetainedViewEntity,
    RenderVisibleEntities,
  ]
}

///|
pub fn RenderShadowMapVisibleEntities::RenderShadowMapVisibleEntities() -> RenderShadowMapVisibleEntities {
  RenderShadowMapVisibleEntities::{ subviews: @hashmap.HashMap([]) }
}

///|
pub fn RenderShadowMapVisibleEntities::len(
  self : RenderShadowMapVisibleEntities,
) -> Int {
  self.subviews.length()
}

///|
pub let ecs_key_render_shadow_map_visible_entities : @ecs.ComponentKey[
  RenderShadowMapVisibleEntities,
] = @ecs.register_component(
  debug_name="render.view.visibility.render_shadow_map_visible_entities",
)

///|
pub impl @ecs.Component for RenderShadowMapVisibleEntities with fn component() {
  ecs_key_render_shadow_map_visible_entities
}

///|
// Bevy source: `bevy/crates/bevy_render/src/view/visibility/mod.rs::RenderExtractedVisibleEntities`.
pub struct RenderExtractedVisibleEntities {
  classes : @hashmap.HashMap[String, RenderExtractedVisibleEntitiesClass]
}

///|
pub fn RenderExtractedVisibleEntities::RenderExtractedVisibleEntities() -> RenderExtractedVisibleEntities {
  RenderExtractedVisibleEntities::{ classes: @hashmap.HashMap([]) }
}

///|
pub let ecs_key_render_extracted_visible_entities : @ecs.ComponentKey[
  RenderExtractedVisibleEntities,
] = @ecs.register_component(
  debug_name="render.view.visibility.render_extracted_visible_entities",
)

///|
pub impl @ecs.Component for RenderExtractedVisibleEntities with fn component() {
  ecs_key_render_extracted_visible_entities
}

///|
// Bevy source: `bevy/crates/bevy_render/src/view/visibility/mod.rs::RenderExtractedShadowMapVisibleEntities`.
pub struct RenderExtractedShadowMapVisibleEntities {
  subviews : @hashmap.HashMap[
    @render_view.RetainedViewEntity,
    RenderExtractedVisibleEntities,
  ]
}

///|
pub fn RenderExtractedShadowMapVisibleEntities::RenderExtractedShadowMapVisibleEntities() -> RenderExtractedShadowMapVisibleEntities {
  RenderExtractedShadowMapVisibleEntities::{ subviews: @hashmap.HashMap([]) }
}

///|
pub fn RenderExtractedShadowMapVisibleEntities::len(
  self : RenderExtractedShadowMapVisibleEntities,
) -> Int {
  self.subviews.length()
}

///|
pub let ecs_key_render_extracted_shadow_map_visible_entities : @ecs.ComponentKey[
  RenderExtractedShadowMapVisibleEntities,
] = @ecs.register_component(
  debug_name="render.view.visibility.render_extracted_shadow_map_visible_entities",
)

///|
pub impl @ecs.Component for RenderExtractedShadowMapVisibleEntities with fn component() {
  ecs_key_render_extracted_shadow_map_visible_entities
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
// Bevy source: `bevy/crates/bevy_render/src/view/visibility/mod.rs::RenderExtractedVisibleEntitiesClass`.
pub struct RenderExtractedVisibleEntitiesClass {
  entities : Array[@render.MainEntity]
}

///|
pub fn RenderExtractedVisibleEntitiesClass::RenderExtractedVisibleEntitiesClass() -> RenderExtractedVisibleEntitiesClass {
  RenderExtractedVisibleEntitiesClass::{ entities: [] }
}

///|
pub fn RenderExtractedVisibleEntitiesClass::len(
  self : RenderExtractedVisibleEntitiesClass,
) -> Int {
  self.entities.length()
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
// Bevy source:
// - `bevy/crates/bevy_render/src/camera.rs` (`DirtySpecializations`).
pub struct DirtySpecializations {
  changed_renderables : @hashset.HashSet[@render.MainEntity]
  removed_renderables : @hashset.HashSet[@render.MainEntity]
  views : @hashset.HashSet[@render_view.RetainedViewEntity]
}

///|
pub fn DirtySpecializations::DirtySpecializations() -> DirtySpecializations {
  DirtySpecializations::{
    changed_renderables: @hashset.HashSet([]),
    removed_renderables: @hashset.HashSet([]),
    views: @hashset.HashSet([]),
  }
}

///|
pub let ecs_key_dirty_specializations : @ecs.ResourceKey[DirtySpecializations] = @ecs.register_resource(
  debug_name="render.view.visibility.DirtySpecializations",
)

///|
pub impl @app.Resource for DirtySpecializations with fn resource() {
  ecs_key_dirty_specializations
}

///|
pub fn DirtySpecializations::clear(self : DirtySpecializations) -> Unit {
  self.changed_renderables.clear()
  self.removed_renderables.clear()
  self.views.clear()
}

///|
pub fn DirtySpecializations::insert_changed(
  self : DirtySpecializations,
  entity : @render.MainEntity,
) -> Unit {
  self.changed_renderables.add(entity)
}

///|
pub fn DirtySpecializations::insert_removed(
  self : DirtySpecializations,
  entity : @render.MainEntity,
) -> Unit {
  self.removed_renderables.add(entity)
}

///|
pub fn DirtySpecializations::insert_view(
  self : DirtySpecializations,
  view : @render_view.RetainedViewEntity,
) -> Unit {
  self.views.add(view)
}

///|
pub fn DirtySpecializations::changed_len(self : DirtySpecializations) -> Int {
  self.changed_renderables.length()
}

///|
pub fn DirtySpecializations::removed_len(self : DirtySpecializations) -> Int {
  self.removed_renderables.length()
}

///|
pub fn DirtySpecializations::views_len(self : DirtySpecializations) -> Int {
  self.views.length()
}

///|
pub fn DirtySpecializations::changed_contains(
  self : DirtySpecializations,
  entity : @render.MainEntity,
) -> Bool {
  self.changed_renderables.contains(entity)
}

///|
pub fn DirtySpecializations::removed_contains(
  self : DirtySpecializations,
  entity : @render.MainEntity,
) -> Bool {
  self.removed_renderables.contains(entity)
}

///|
pub fn DirtySpecializations::must_wipe_specializations_for_view(
  self : DirtySpecializations,
  view : @render_view.RetainedViewEntity,
) -> Bool {
  self.views.contains(view)
}

///|
pub fn DirtySpecializations::iter_to_despecialize(
  self : DirtySpecializations,
) -> Array[@render.MainEntity] {
  let entities : Array[@render.MainEntity] = []
  for entity in self.changed_renderables.iter() {
    entities.push(entity)
  }
  for entity in self.removed_renderables.iter() {
    entities.push(entity)
  }
  entities
}

///|
pub fn DirtySpecializations::entity_pair_from_visible_main_entity(
  _self : DirtySpecializations,
  render_visible_mesh_entities : RenderVisibleEntitiesClass,
  main_entity : @render.MainEntity,
) -> (@core.Entity, @render.MainEntity)? {
  for pair in render_visible_mesh_entities.entities_cpu_culling {
    if pair.1 == main_entity {
      return Some(pair)
    }
  }
  match render_visible_mesh_entities.entities_gpu_culling.get(main_entity) {
    Some(entity) => Some((entity, main_entity))
    None => None
  }
}

///|
fn dirty_specialization_main_entity_in_pairs(
  pairs : Array[(@core.Entity, @render.MainEntity)],
  main_entity : @render.MainEntity,
) -> Bool {
  for pair in pairs {
    if pair.1 == main_entity {
      return true
    }
  }
  false
}

///|
pub fn DirtySpecializations::iter_to_specialize(
  self : DirtySpecializations,
  view : @render_view.RetainedViewEntity,
  render_visible_mesh_entities : RenderVisibleEntitiesClass,
  last_frame_view_pending_queues : @hashset.HashSet[
    (@core.Entity, @render.MainEntity),
  ],
) -> Array[(@core.Entity, @render.MainEntity)] {
  let result : Array[(@core.Entity, @render.MainEntity)] = []
  if self.must_wipe_specializations_for_view(view) {
    for pair in render_visible_mesh_entities.iter_visible() {
      result.push(pair)
    }
  } else {
    for pair in render_visible_mesh_entities.added_entities() {
      result.push(pair)
    }
    for main_entity in self.changed_renderables.iter() {
      match
        self.entity_pair_from_visible_main_entity(
          render_visible_mesh_entities, main_entity,
        ) {
        Some(pair) => result.push(pair)
        None => ()
      }
    }
  }
  for pair in last_frame_view_pending_queues.iter() {
    if render_visible_mesh_entities.entity_pair_is_visible(pair.0, pair.1) {
      result.push(pair)
    }
  }
  result
}

///|
pub fn DirtySpecializations::iter_to_dequeue(
  self : DirtySpecializations,
  view : @render_view.RetainedViewEntity,
  render_visible_mesh_entities : RenderVisibleEntitiesClass,
) -> Array[@render.MainEntity] {
  let result : Array[@render.MainEntity] = []
  for pair in render_visible_mesh_entities.removed_entities() {
    result.push(pair.1)
  }
  if self.must_wipe_specializations_for_view(view) {
    for pair in render_visible_mesh_entities.iter_visible() {
      result.push(pair.1)
    }
  } else {
    for main_entity in self.changed_renderables.iter() {
      result.push(main_entity)
    }
    for main_entity in self.removed_renderables.iter() {
      result.push(main_entity)
    }
  }
  result
}

///|
pub fn DirtySpecializations::iter_to_queue(
  self : DirtySpecializations,
  view : @render_view.RetainedViewEntity,
  render_visible_mesh_entities : RenderVisibleEntitiesClass,
  last_frame_view_pending_queues : @hashset.HashSet[
    (@core.Entity, @render.MainEntity),
  ],
) -> Array[(@core.Entity, @render.MainEntity)] {
  let result : Array[(@core.Entity, @render.MainEntity)] = []
  if self.must_wipe_specializations_for_view(view) {
    for pair in render_visible_mesh_entities.iter_visible() {
      result.push(pair)
    }
  } else {
    let added = render_visible_mesh_entities.added_entities()
    for pair in added {
      result.push(pair)
    }
    for main_entity in self.changed_renderables.iter() {
      if !dirty_specialization_main_entity_in_pairs(added, main_entity) {
        match
          self.entity_pair_from_visible_main_entity(
            render_visible_mesh_entities, main_entity,
          ) {
          Some(pair) => result.push(pair)
          None => ()
        }
      }
    }
  }
  for pair in last_frame_view_pending_queues.iter() {
    if render_visible_mesh_entities.entity_pair_is_visible(pair.0, pair.1) {
      result.push(pair)
    }
  }
  result
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
