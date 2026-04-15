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
fn spawn_box(
  world : @ecs.World,
  parent : @core.Entity,
  left : Float,
  bottom : Float,
  width : Float,
  height : Float,
  color : @sprite.Color,
  z_index : @ui.ZIndex?,
  global_z_index : @ui.GlobalZIndex?,
) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(
    entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(left))
    .with_bottom(@ui.Val::Px(bottom))
    .with_width(@ui.Val::Px(width))
    .with_height(@ui.Val::Px(height)),
  )
  try! world.set_by_key(
    entity,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(color),
  )
  if z_index is Some(value) {
    try! world.set_by_key(entity, @ui.ecs_key_z_index, value)
  }
  if global_z_index is Some(value) {
    try! world.set_by_key(entity, @ui.ecs_key_global_z_index, value)
  }
  entity
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.advance_sequence()
  ignore(tick)

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_align_items(@ui.AlignItems::Center)
    .with_justify_content(@ui.JustifyContent::Center),
  )

  let container = world.spawn_empty()
  try! world.set_by_key(
    container,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    container,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Px(180.0F))
    .with_height(@ui.Val::Px(100.0F)),
  )
  try! world.set_by_key(
    container,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(@sprite.Color::srgb(0.5F, 0.5F, 0.5F)),
  )

  ignore(
    spawn_box(
      world,
      container,
      10.0F,
      40.0F,
      100.0F,
      50.0F,
      @sprite.Color::srgb(1.0F, 0.0F, 0.0F),
      None,
      None,
    ),
  )
  ignore(
    spawn_box(
      world,
      container,
      45.0F,
      30.0F,
      100.0F,
      50.0F,
      @sprite.Color::srgb(0.0F, 0.0F, 1.0F),
      Some(@ui.ZIndex::new(2)),
      None,
    ),
  )
  ignore(
    spawn_box(
      world,
      container,
      70.0F,
      20.0F,
      100.0F,
      75.0F,
      @sprite.Color::srgb(0.0F, 1.0F, 0.0F),
      Some(@ui.ZIndex::new(-1)),
      None,
    ),
  )
  ignore(
    spawn_box(
      world,
      container,
      15.0F,
      10.0F,
      100.0F,
      60.0F,
      @sprite.Color::srgb(0.5F, 0.0F, 0.5F),
      None,
      Some(@ui.GlobalZIndex::new(1)),
    ),
  )
  ignore(
    spawn_box(
      world,
      container,
      -15.0F,
      -15.0F,
      100.0F,
      125.0F,
      @sprite.Color::srgb(1.0F, 1.0F, 0.0F),
      None,
      Some(@ui.GlobalZIndex::new(-1)),
    ),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_startup_system(setup)
  .run()
}
