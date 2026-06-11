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
fn test_main_entity(id : Int) -> @render.MainEntity {
  @render.MainEntity::new(@core.Entity::new(id, 1))
}

///|
test "render visibility: RenderVisibleEntitiesClass tracks added and removed CPU-cull pairs" {
  let class = RenderVisibleEntitiesClass::RenderVisibleEntitiesClass()
  let old_render = @core.Entity::new(10, 1)
  let old_main = test_main_entity(1)
  let stable_render = @core.Entity::new(20, 1)
  let stable_main = test_main_entity(2)
  let new_render = @core.Entity::new(30, 1)
  let new_main = test_main_entity(3)

  class.update_cpu_culled_entities([
    (old_render, old_main),
    (stable_render, stable_main),
  ])
  class.prepare_for_new_frame()
  class.update_cpu_culled_entities([
    (stable_render, stable_main),
    (new_render, new_main),
  ])

  debug_inspect(class.visible_len(), content="2")
  debug_inspect(class.added_entities().length(), content="1")
  debug_inspect(class.removed_entities().length(), content="1")
  debug_inspect(
    class.entity_pair_is_visible(stable_render, stable_main),
    content="true",
  )
  debug_inspect(
    class.entity_pair_is_visible(old_render, old_main),
    content="false",
  )
  debug_inspect(
    class.added_entities()[0].1.id(),
    content="{ id: 3, generation: 1 }",
  )
  debug_inspect(
    class.removed_entities()[0].1.id(),
    content="{ id: 1, generation: 1 }",
  )
}

///|
test "render visibility: RenderVisibleEntitiesClass includes GPU-cull entities" {
  let class = RenderVisibleEntitiesClass::RenderVisibleEntitiesClass()
  let render_entity = @core.Entity::new(40, 1)
  let main_entity = test_main_entity(4)
  class.insert_gpu_culled_entity(main_entity, render_entity)

  let visible = class.iter_visible()

  debug_inspect(class.visible_len(), content="1")
  debug_inspect(
    class.entity_pair_is_visible(render_entity, main_entity),
    content="true",
  )
  debug_inspect(visible.length(), content="1")
  debug_inspect(visible[0].0, content="{ id: 40, generation: 1 }")
  debug_inspect(visible[0].1.id(), content="{ id: 4, generation: 1 }")
}

///|
test "render visibility: RenderVisibleEntities stores classes by visibility key" {
  let visible = RenderVisibleEntities::RenderVisibleEntities()
  let class = visible.class_or_insert("Mesh3d")
  class.add_entity((@core.Entity::new(2, 1), test_main_entity(2)))
  class.add_entity((@core.Entity::new(1, 1), test_main_entity(1)))
  class.sort_added_entities()

  let stored = match visible.get("Mesh3d") {
    Some(value) => value
    None => abort("missing Mesh3d visibility class")
  }

  debug_inspect(visible.is_empty("Mesh3d"), content="true")
  debug_inspect(stored.added_entities().length(), content="2")
  debug_inspect(
    stored.added_entities()[0].1.id(),
    content="{ id: 1, generation: 1 }",
  )
}
