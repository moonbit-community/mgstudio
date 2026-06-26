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

///|
fn test_retained_view(id : Int) -> @render_view.RetainedViewEntity {
  @render_view.RetainedViewEntity::new(@core.Entity::new(id, 1))
}

///|
fn test_pair_list_contains_main(
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
test "render visibility: DirtySpecializations dequeues removed and dirty renderables" {
  let dirty = DirtySpecializations::DirtySpecializations()
  let view = test_retained_view(70)
  let visible = RenderVisibleEntitiesClass::RenderVisibleEntitiesClass()
  let removed_main = test_main_entity(71)
  let changed_main = test_main_entity(72)
  let swept_main = test_main_entity(73)

  visible.update_cpu_culled_entities([
    (@core.Entity::new(171, 1), removed_main),
    (@core.Entity::new(173, 1), swept_main),
  ])
  visible.prepare_for_new_frame()
  visible.update_cpu_culled_entities([(@core.Entity::new(173, 1), swept_main)])
  dirty.insert_changed(changed_main)

  let dequeued = dirty.iter_to_dequeue(view, visible)

  debug_inspect(dequeued.length(), content="2")
  debug_inspect(dequeued[0].id(), content="{ id: 71, generation: 1 }")
  debug_inspect(dequeued[1].id(), content="{ id: 72, generation: 1 }")
}

///|
test "render visibility: DirtySpecializations queues added changed and pending visible renderables" {
  let dirty = DirtySpecializations::DirtySpecializations()
  let view = test_retained_view(80)
  let visible = RenderVisibleEntitiesClass::RenderVisibleEntitiesClass()
  let added_main = test_main_entity(81)
  let changed_main = test_main_entity(82)
  let pending_main = test_main_entity(83)
  let invisible_pending_main = test_main_entity(84)
  let added_render = @core.Entity::new(181, 1)
  let changed_render = @core.Entity::new(182, 1)
  let pending_render = @core.Entity::new(183, 1)
  let invisible_pending_render = @core.Entity::new(184, 1)
  let pending : @hashset.HashSet[(@core.Entity, @render.MainEntity)] = @hashset.HashSet([],
  )

  visible.update_cpu_culled_entities([
    (changed_render, changed_main),
    (pending_render, pending_main),
  ])
  visible.prepare_for_new_frame()
  visible.update_cpu_culled_entities([
    (added_render, added_main),
    (changed_render, changed_main),
    (pending_render, pending_main),
  ])
  dirty.insert_changed(added_main)
  dirty.insert_changed(changed_main)
  pending.add((pending_render, pending_main))
  pending.add((invisible_pending_render, invisible_pending_main))

  let queued = dirty.iter_to_queue(view, visible, pending)

  debug_inspect(queued.length(), content="3")
  debug_inspect(
    test_pair_list_contains_main(queued, added_main),
    content="true",
  )
  debug_inspect(
    test_pair_list_contains_main(queued, changed_main),
    content="true",
  )
  debug_inspect(
    test_pair_list_contains_main(queued, pending_main),
    content="true",
  )
  debug_inspect(
    test_pair_list_contains_main(queued, invisible_pending_main),
    content="false",
  )
}

///|
test "render visibility: DirtySpecializations view wipe queues and dequeues all visible renderables" {
  let dirty = DirtySpecializations::DirtySpecializations()
  let view = test_retained_view(90)
  let visible = RenderVisibleEntitiesClass::RenderVisibleEntitiesClass()
  let first_main = test_main_entity(91)
  let second_main = test_main_entity(92)
  let pending : @hashset.HashSet[(@core.Entity, @render.MainEntity)] = @hashset.HashSet([],
  )

  visible.update_cpu_culled_entities([(@core.Entity::new(191, 1), first_main)])
  visible.insert_gpu_culled_entity(second_main, @core.Entity::new(192, 1))
  dirty.insert_view(view)

  let dequeued = dirty.iter_to_dequeue(view, visible)
  let queued = dirty.iter_to_queue(view, visible, pending)

  debug_inspect(dequeued.length(), content="2")
  debug_inspect(queued.length(), content="2")
}
