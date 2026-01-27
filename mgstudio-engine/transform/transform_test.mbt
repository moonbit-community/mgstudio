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
fn abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn approx_eq(a : Float, b : Float) -> Bool {
  abs_float(a - b) < 0.0001F
}

///|
struct TestWorld {
  entities : @core.Entities
  mut tick : @core.Tick
  mut ctx : @core.SystemContext
  transform : @core.ComponentStore[@math.Transform]
  global_transform : @core.ComponentStore[GlobalTransform]
  parent : @core.ComponentStore[@hierarchy.Parent]
  children : @core.ComponentStore[@hierarchy.Children]
}

///|
fn TestWorld::new() -> TestWorld {
  {
    entities: @core.Entities::new(),
    tick: 0,
    ctx: @core.SystemContext::new(),
    transform: @core.ComponentStore::new(),
    global_transform: @core.ComponentStore::new(),
    parent: @core.ComponentStore::new(),
    children: @core.ComponentStore::new(),
  }
}

///|
fn TestWorld::next_system_ticks(self : TestWorld) -> @core.SystemTicks {
  let this_run = @core.ChangeTickWorld::increment_change_tick(self)
  let sys = @core.SystemTicks::new(self.ctx.ticks().this_run, this_run)
  let ctx = @core.SystemContext::new()
  ctx.set(sys)
  @core.SystemContextWorld::set_system_context(self, ctx)
  sys
}

///|
impl @core.ChangeTickWorld for TestWorld with read_change_tick(self) {
  self.tick
}

///|
impl @core.ChangeTickWorld for TestWorld with increment_change_tick(self) {
  self.tick = self.tick + 1
  self.tick
}

///|
impl @core.SystemContextWorld for TestWorld with get_system_context(self) {
  self.ctx
}

///|
impl @core.SystemContextWorld for TestWorld with set_system_context(self, ctx) {
  self.ctx = ctx
}

///|
impl @math.Has_Transform for TestWorld with get_transform_store(self) {
  self.transform
}

///|
impl Has_GlobalTransform for TestWorld with get_global_transform_store(self) {
  self.global_transform
}

///|
impl @hierarchy.Has_Parent for TestWorld with get_parent_store(self) {
  self.parent
}

///|
impl @hierarchy.Has_Children for TestWorld with get_children_store(self) {
  self.children
}

///|
test "transform ecs: root global matches local" {
  let world = TestWorld::new()
  let e = world.entities.spawn()
  let tick = world.next_system_ticks().this_run
  world.transform.insert(
    e,
    @math.Transform::new(
      @math.Vec2::new(1.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
    tick,
  )
  update_children_system(world)
  propagate_transforms_system(world)
  let gt = world.global_transform.get(e).unwrap()
  inspect(
    approx_eq(gt.affine.tx, 1.0F) && approx_eq(gt.affine.ty, 2.0F),
    content="true",
  )
}

///|
test "transform ecs: parent translation affects child global translation" {
  let world = TestWorld::new()
  let parent = world.entities.spawn()
  let child = world.entities.spawn()
  let tick = world.next_system_ticks().this_run
  world.transform.insert(
    parent,
    @math.Transform::new(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
    tick,
  )
  world.transform.insert(
    child,
    @math.Transform::new(
      @math.Vec2::new(0.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
    tick,
  )
  world.parent.insert(child, @hierarchy.Parent::new(parent), tick)
  update_children_system(world)
  propagate_transforms_system(world)
  let gt = world.global_transform.get(child).unwrap()
  inspect(
    approx_eq(gt.affine.tx, 1.0F) && approx_eq(gt.affine.ty, 2.0F),
    content="true",
  )
}

///|
test "transform ecs: propagate updates only when inputs change" {
  let world = TestWorld::new()
  let e = world.entities.spawn()

  // First run: insert Transform, propagate writes GlobalTransform at tick1.
  let tick1 = world.next_system_ticks().this_run
  world.transform.insert(
    e,
    @math.Transform::new(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
    tick1,
  )
  update_children_system(world)
  propagate_transforms_system(world)
  let gt_tick1 = world.global_transform.get_ticks(e).unwrap()
  inspect(gt_tick1.is_changed(@core.SystemTicks::new(0, tick1)), content="true")

  // Second run: no changes, propagate should not touch GlobalTransform.
  let tick2 = world.next_system_ticks().this_run
  update_children_system(world)
  propagate_transforms_system(world)
  let gt_tick2 = world.global_transform.get_ticks(e).unwrap()
  inspect(
    gt_tick2.is_changed(@core.SystemTicks::new(tick1, tick2)),
    content="false",
  )

  // Third run: local change, should update.
  let tick3 = world.next_system_ticks().this_run
  world.transform.set(
    e,
    @math.Transform::new(
      @math.Vec2::new(2.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
    tick3,
  )
  |> ignore
  update_children_system(world)
  propagate_transforms_system(world)
  let gt = world.global_transform.get(e).unwrap()
  inspect(approx_eq(gt.affine.tx, 2.0F), content="true")
}
