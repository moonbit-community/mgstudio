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
test "transform: root global matches local" {
  reset()
  let e = spawn(
    @math.Transform::new(
      @math.Vec2::new(1.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  propagate()
  let gt = global(e).unwrap()
  inspect(
    approx_eq(gt.affine.tx, 1.0F) && approx_eq(gt.affine.ty, 2.0F),
    content="true",
  )
}

///|
test "transform: parent translation affects child global translation" {
  reset()
  let parent = spawn(
    @math.Transform::new(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  let child = spawn(
    @math.Transform::new(
      @math.Vec2::new(0.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  set_parent(child, Some(parent))
  propagate()
  let gt = global(child).unwrap()
  inspect(
    approx_eq(gt.affine.tx, 1.0F) && approx_eq(gt.affine.ty, 2.0F),
    content="true",
  )
}

///|
test "transform: propagate updates only when inputs change" {
  reset()
  let e = spawn(
    @math.Transform::new(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  propagate()
  let tick1 = propagate_tick()
  let updated1 = global_updated_tick(e).unwrap()
  inspect(tick1 == updated1, content="true")

  // No changes: should not update.
  propagate()
  let tick2 = propagate_tick()
  let updated2 = global_updated_tick(e).unwrap()
  inspect(tick2 > tick1, content="true")
  inspect(updated2 == updated1, content="true")

  // Local change: should update this tick.
  set_local(
    e,
    @math.Transform::new(
      @math.Vec2::new(2.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  propagate()
  let tick3 = propagate_tick()
  let updated3 = global_updated_tick(e).unwrap()
  inspect(tick3 == updated3, content="true")
  inspect(updated3 > updated2, content="true")
}

///|
test "transform: parent change updates descendants" {
  reset()
  let parent = spawn(
    @math.Transform::new(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  let child = spawn(
    @math.Transform::new(
      @math.Vec2::new(0.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  set_parent(child, Some(parent))
  propagate()
  let updated1 = global_updated_tick(child).unwrap()
  set_local(
    parent,
    @math.Transform::new(
      @math.Vec2::new(3.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  propagate()
  let updated2 = global_updated_tick(child).unwrap()
  inspect(updated2 > updated1, content="true")
  let gt = global(child).unwrap()
  inspect(
    approx_eq(gt.affine.tx, 3.0F) && approx_eq(gt.affine.ty, 2.0F),
    content="true",
  )
}
