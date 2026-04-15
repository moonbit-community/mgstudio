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
fn min_float(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn max_float(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.advance_sequence()
  ignore(tick)
  let icon = @asset.AssetServer::new().load_image("branding/icon.png")

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  @ui.get_ui_scale_resource(world).insert(@ui.UiScale::new(1.0F))

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(50.0F))
    .with_height(@ui.Val::Percent(50.0F))
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Percent(25.0F))
    .with_top(@ui.Val::Percent(25.0F))
    .with_justify_content(@ui.JustifyContent::SpaceAround)
    .with_align_items(@ui.AlignItems::Center),
  )
  try! world.set_by_key(
    root,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(@sprite.Color::srgb(0.98F, 0.92F, 0.84F)),
  )

  let red_box = world.spawn_empty()
  try! world.set_by_key(
    red_box,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    red_box,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Px(40.0F))
    .with_height(@ui.Val::Px(40.0F)),
  )
  try! world.set_by_key(
    red_box,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(@sprite.Color::srgb(1.0F, 0.0F, 0.0F)),
  )

  let red_text = world.spawn_empty()
  try! world.set_by_key(
    red_text,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(red_box),
  )
  try! world.set_by_key(red_text, @text.ecs_key_text, @text.Text::new("Size!"))
  try! world.set_by_key(
    red_text,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font_size(@text.FontSize::Px(13.0F)),
  )
  try! world.set_by_key(
    red_text,
    @text.ecs_key_text_color,
    @text.TextColor::black(),
  )

  let blue_box = world.spawn_empty()
  try! world.set_by_key(
    blue_box,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    blue_box,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(15.0F))
    .with_height(@ui.Val::Percent(15.0F)),
  )
  try! world.set_by_key(
    blue_box,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(@sprite.Color::srgb(0.0F, 0.0F, 1.0F)),
  )

  let image = world.spawn_empty()
  try! world.set_by_key(
    image,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    image,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Px(30.0F))
    .with_height(@ui.Val::Px(30.0F)),
  )
  try! world.set_by_key(image, @ui.ecs_key_image_node, @ui.ImageNode::new(icon))
}

///|
fn change_scaling(world : @ecs.World) -> Unit {
  let ui_scale = @ui.get_ui_scale_resource(world)
  let current = match ui_scale.get() {
    Some(scale) => scale.value
    None => 1.0F
  }
  if @input.key_just_pressed(@window.KeyCode::ArrowUp) {
    ui_scale.insert(@ui.UiScale::new(min_float(current * 2.0F, 8.0F)))
  }
  if @input.key_just_pressed(@window.KeyCode::ArrowDown) {
    ui_scale.insert(@ui.UiScale::new(max_float(current / 2.0F, 0.125F)))
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_startup_system(setup)
  .add_systems(@app.Update, @app.system(change_scaling))
  .run()
}
