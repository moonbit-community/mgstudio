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
fn camera_pending_test_main_entity(entity : @core.Entity) -> MainEntity {
  MainEntity::new(entity)
}

///|
test "render camera: PendingQueues moves per-view current frame into prev frame" {
  let queues = PendingQueues::PendingQueues()
  let view_a = @render_view.RetainedViewEntity::new(
    @core.Entity::new(10, 1),
    auxiliary_entity=Some(@core.Entity::new(20, 1)),
    subview_index=1,
  )
  let view_b = @render_view.RetainedViewEntity::new(@core.Entity::new(11, 1))
  queues.push_current(
    view_a,
    @core.Entity::new(1, 1),
    camera_pending_test_main_entity(@core.Entity::new(2, 1)),
  )
  queues.push_current(
    view_a,
    @core.Entity::new(1, 1),
    camera_pending_test_main_entity(@core.Entity::new(2, 1)),
  )
  queues.push_current(
    view_a,
    @core.Entity::new(3, 1),
    camera_pending_test_main_entity(@core.Entity::new(4, 1)),
  )
  queues.push_current(
    view_b,
    @core.Entity::new(5, 1),
    camera_pending_test_main_entity(@core.Entity::new(6, 1)),
  )

  debug_inspect(queues.view_len(), content="2")
  debug_inspect(queues.current_len(view_a), content="2")
  debug_inspect(queues.current_len(view_b), content="1")
  debug_inspect(queues.prev_len(view_a), content="0")

  let view_a_queues = queues.prepare_for_new_frame(view_a)

  debug_inspect(view_a_queues.current_len(), content="0")
  debug_inspect(view_a_queues.prev_len(), content="2")
  debug_inspect(queues.current_len(view_a), content="0")
  debug_inspect(queues.prev_len(view_a), content="2")
  debug_inspect(queues.current_len(view_b), content="1")
  debug_inspect(queues.prev_len(view_b), content="0")
}

///|
test "render camera: PendingQueues retains auxiliary and subview identity" {
  let queues = PendingQueues::PendingQueues()
  let main_view = @core.Entity::new(10, 1)
  let first = @render_view.RetainedViewEntity::new(
    main_view,
    auxiliary_entity=Some(@core.Entity::new(20, 1)),
    subview_index=0,
  )
  let second = @render_view.RetainedViewEntity::new(
    main_view,
    auxiliary_entity=Some(@core.Entity::new(21, 1)),
    subview_index=0,
  )
  let third = @render_view.RetainedViewEntity::new(
    main_view,
    auxiliary_entity=Some(@core.Entity::new(20, 1)),
    subview_index=1,
  )

  queues.push_current(
    first,
    @core.Entity::new(1, 1),
    camera_pending_test_main_entity(@core.Entity::new(2, 1)),
  )
  queues.push_current(
    second,
    @core.Entity::new(3, 1),
    camera_pending_test_main_entity(@core.Entity::new(4, 1)),
  )
  queues.push_current(
    third,
    @core.Entity::new(5, 1),
    camera_pending_test_main_entity(@core.Entity::new(6, 1)),
  )

  debug_inspect(queues.view_len(), content="3")
  debug_inspect(queues.current_len(first), content="1")
  debug_inspect(queues.current_len(second), content="1")
  debug_inspect(queues.current_len(third), content="1")
}

///|
test "render camera: PendingQueues expires stale views" {
  let queues = PendingQueues::PendingQueues()
  let live_view = @render_view.RetainedViewEntity::new(@core.Entity::new(10, 1))
  let stale_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(11, 1),
  )
  queues.push_current(
    live_view,
    @core.Entity::new(1, 1),
    camera_pending_test_main_entity(@core.Entity::new(2, 1)),
  )
  queues.push_current(
    stale_view,
    @core.Entity::new(3, 1),
    camera_pending_test_main_entity(@core.Entity::new(4, 1)),
  )
  let live : @hashset.HashSet[@render_view.RetainedViewEntity] = @hashset.HashSet([],
  )
  live.add(live_view)

  queues.expire_stale_views(live)

  debug_inspect(queues.contains_view(live_view), content="true")
  debug_inspect(queues.contains_view(stale_view), content="false")
  debug_inspect(queues.view_len(), content="1")
}
