// Copyright 2025 International Digital Economy Academy
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
test "ui: interaction updates component state" {
  let world = @ecs_world.World::new()
  let tick = world.increment_change_tick()
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @math.Transform::identity(),
    1.0F,
    Some(@math.Vec2::new(60.0F, 60.0F)),
    false,
  )
  world.get_ui_context_resource().insert(ctx, tick)
  let e = world.spawn_empty()
  world.get_button_store().insert(e, Button::default(), tick)
  world
  .get_ui_layout_store()
  .insert(
    e,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(40.0F, 50.0F),
        @math.Vec2::new(240.0F, 110.0F),
      ),
    ),
    tick,
  )
  ui_stack_system(world)
  ui_interaction_system(world)
  let s0 = world.get_interaction_store().get(e).unwrap()
  inspect(s0 == Interaction::Hovered, content="true")

  // Pressed.
  let ctx2 = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @math.Transform::identity(),
    1.0F,
    Some(@math.Vec2::new(60.0F, 60.0F)),
    true,
  )
  world.get_ui_context_resource().insert(ctx2, tick)
  ui_stack_system(world)
  ui_interaction_system(world)
  let s1 = world.get_interaction_store().get(e).unwrap()
  inspect(s1 == Interaction::Pressed, content="true")

  // Outside.
  let ctx3 = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @math.Transform::identity(),
    1.0F,
    Some(@math.Vec2::new(1.0F, 1.0F)),
    false,
  )
  world.get_ui_context_resource().insert(ctx3, tick)
  ui_stack_system(world)
  ui_interaction_system(world)
  let s2 = world.get_interaction_store().get(e).unwrap()
  inspect(s2 == Interaction::None, content="true")
}
