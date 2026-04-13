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
fn picking_test_ui_context() -> @ui.UiContext {
  @ui.UiContext::new(
    @asset.Handle::new(-1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(100.0F, 100.0F),
    None,
    @transform.Transform::identity(),
    1.0F,
    None,
    false,
  )
}

///|
test "picking wb: window conversion keeps Y-axis orientation (top-left to +Y)" {
  let ctx = picking_test_ui_context()
  let world_pos = picking_window_to_sprite_world(@math.Vec2::new(0.0F, 0.0F), ctx)
  inspect(world_pos.unwrap().x.to_double(), content="-50")
  inspect(world_pos.unwrap().y.to_double(), content="50")
}

///|
test "picking wb: window conversion keeps Y-axis orientation (bottom-right to -Y)" {
  let ctx = picking_test_ui_context()
  let world_pos = picking_window_to_sprite_world(
    @math.Vec2::new(100.0F, 100.0F),
    ctx,
  )
  inspect(world_pos.unwrap().x.to_double(), content="50")
  inspect(world_pos.unwrap().y.to_double(), content="-50")
}

///|
test "picking wb: window conversion maps viewport center to camera translation" {
  let ctx = @ui.UiContext::new(
    @asset.Handle::new(-1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(200.0F, 120.0F),
    None,
    @transform.Transform::from_xyz(12.0F, -7.0F, 0.0F),
    1.0F,
    None,
    false,
  )
  let world_pos = picking_window_to_sprite_world(@math.Vec2::new(100.0F, 60.0F), ctx)
  inspect(world_pos.unwrap().x.to_double(), content="12")
  inspect(world_pos.unwrap().y.to_double(), content="-7")
}

///|
test "picking wb: window conversion respects viewport origin offset" {
  let ctx = @ui.UiContext::new(
    @asset.Handle::new(-1),
    @math.Vec2::new(20.0F, 10.0F),
    @math.Vec2::new(100.0F, 100.0F),
    None,
    @transform.Transform::identity(),
    1.0F,
    None,
    false,
  )
  let world_pos = picking_window_to_sprite_world(@math.Vec2::new(20.0F, 10.0F), ctx)
  inspect(world_pos.unwrap().x.to_double(), content="-50")
  inspect(world_pos.unwrap().y.to_double(), content="50")
}

///|
test "picking wb: window conversion applies camera rotation and scale" {
  let ctx = @ui.UiContext::new(
    @asset.Handle::new(-1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(100.0F, 100.0F),
    None,
    @transform.Transform::from_rotation(@math.Quat::from_rotation_z(@math.pi())),
    2.0F,
    None,
    false,
  )
  let world_pos = picking_window_to_sprite_world(@math.Vec2::new(60.0F, 50.0F), ctx)
  inspect(world_pos.unwrap().x.to_double(), content="-20")
  inspect(@math.abs(world_pos.unwrap().y).to_double() < 0.001, content="true")
}
