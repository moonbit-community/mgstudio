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
const BOX_SIZE : Float = 100.0F

///|
struct CameraOrderBox {
  camera_entity : @core.Entity
  label_entity : @core.Entity
}

///|
let camera_order_box_key : @ecs.ComponentKey[CameraOrderBox] = @ecs.register_component(
  debug_name="examples.ui.ui_target_camera.CameraOrderBox",
)

///|
pub impl @ecs.Component for CameraOrderBox with component() {
  camera_order_box_key
}

///|
fn red() -> @sprite.Color {
  @sprite.Color::srgb(1.0F, 0.0F, 0.0F)
}

///|
fn green() -> @sprite.Color {
  @sprite.Color::srgb(0.0F, 0.5F, 0.0F)
}

///|
fn blue() -> @sprite.Color {
  @sprite.Color::srgb(0.0F, 0.0F, 1.0F)
}

///|
fn yellow() -> @sprite.Color {
  @sprite.Color::srgb(1.0F, 1.0F, 0.0F)
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @ui.Node::{
          ..@ui.Node::default(),
          align_self: @ui.AlignSelf::Center,
          justify_self: @ui.JustifySelf::Center,
          justify_content: @ui.JustifyContent::Center,
          bottom: @ui.Val::Px(2.0F * BOX_SIZE),
        },
        @text.Text::new(
          "Each box is rendered by a different camera\n" +
          "* left-click: increase the camera's order\n" +
          "* right-click: decrease the camera's order",
        ),
        @text.TextFont::from_font_size(22.0F),
        @text.TextColor::new(@sprite.Color::white()),
      ),
    ),
  )

  let colors = [red(), green(), blue()]
  for i in 0..<colors.length() {
    let color = colors[i]
    let camera_entity = commands.spawn(
      (
        @sprite.Camera2d::default(),
        @sprite.Camera::default().with_clear_color(color).with_order(i),
      ),
    )

    let label_entity = commands.spawn(
      (
        @text.Text::new(i.to_string()),
        @text.TextFont::from_font_size(50.0F),
        @text.TextColor::new(color),
      ),
    )

    let offset = 0.67F * BOX_SIZE * (Float::from_int(i) - 1.0F)
    let button_entity = commands.spawn(
      (
        @ui.Node::{
          ..@ui.Node::default(),
          align_self: @ui.AlignSelf::Center,
          justify_self: @ui.JustifySelf::Center,
          justify_content: @ui.JustifyContent::Center,
          align_items: @ui.AlignItems::Center,
          left: @ui.Val::Px(offset),
          top: @ui.Val::Px(offset),
          width: @ui.Val::Px(BOX_SIZE),
          height: @ui.Val::Px(BOX_SIZE),
          border: @ui.UiRect::all(@ui.Val::Px(0.1F * BOX_SIZE)),
        },
        @ui.UiTargetCamera::new(camera_entity),
        @ui.Button::default(),
        @ui.BackgroundColor::new(@sprite.Color::black()),
        @ui.BorderColor::new(yellow()),
        CameraOrderBox::{ camera_entity, label_entity },
      ),
    )

    commands
    .entity(label_entity)
    .insert_component(@hierarchy.Parent::new(button_entity))
  }
}

///|
fn update_camera_orders(
  mouse_buttons : @input.ButtonInput[@window.MouseButton],
  buttons : @ecs.Query2[@ui.Interaction, CameraOrderBox],
  cameras : @ecs.Query1[@sprite.Camera],
  texts : @ecs.Query1[@text.Text],
) -> Unit {
  let delta = if mouse_buttons.just_pressed(Left) {
    1
  } else if mouse_buttons.just_pressed(Right) {
    -1
  } else {
    0
  }
  guard delta != 0 else { return }

  try! buttons.view(fn(_entity, interaction, box) {
    guard interaction == @ui.Interaction::Pressed else { return }
    guard (try! cameras.get_mut(box.camera_entity)) is Some(camera) else {
      return
    }
    let camera_ref = camera.get_ref()
    let next_order = camera_ref.val.order + delta
    camera_ref.val = camera_ref.val.with_order(next_order)

    if (try! texts.get(box.label_entity)) is Some(label_text) {
      label_text.content = next_order.to_string()
    }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param4(update_camera_orders)),
  )
  .run()
}
