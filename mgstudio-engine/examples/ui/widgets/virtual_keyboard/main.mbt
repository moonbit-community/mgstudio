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
struct KeyCap {
  value : String
}

///|
struct WasPressed {
  mut down : Bool
}

///|
struct KeyboardDisplay {}

///|
struct KeyboardBuffer {
  mut value : String
}

///|
let key_cap_key : @ecs.ComponentKey[KeyCap] = @ecs.register_component(
  debug_name="examples.ui.widgets.virtual_keyboard.KeyCap",
)

///|
let was_pressed_key : @ecs.ComponentKey[WasPressed] = @ecs.register_component(
  debug_name="examples.ui.widgets.virtual_keyboard.WasPressed",
)

///|
let keyboard_display_key : @ecs.ComponentKey[KeyboardDisplay] = @ecs.register_component(
  debug_name="examples.ui.widgets.virtual_keyboard.KeyboardDisplay",
)

///|
let keyboard_buffer_key : @ecs.ResourceKey[KeyboardBuffer] = @ecs.register_resource(
  debug_name="examples.ui.widgets.virtual_keyboard.KeyboardBuffer",
)

///|
pub impl @ecs.Component for KeyCap with fn component() {
  key_cap_key
}

///|
pub impl @ecs.Component for WasPressed with fn component() {
  was_pressed_key
}

///|
pub impl @ecs.Component for KeyboardDisplay with fn component() {
  keyboard_display_key
}

///|
pub impl @app.Resource for KeyboardBuffer with fn resource() {
  keyboard_buffer_key
}

///|
fn spawn_key_row(
  commands : @app.Commands,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
  keys : Array[String],
) -> Unit {
  let row = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @ui.Node::Node()
      .with_flex_direction(@ui.FlexDirection::Row)
      .with_column_gap(@ui.Val::Px(4.0F)),
    ),
  )
  for key in keys {
    let button = commands.spawn(
      (
        @hierarchy.Parent::new(row),
        @ui.Button::Button(),
        KeyCap::{ value: key },
        WasPressed::{ down: false },
        @ui.Node::Node()
        .with_width(@ui.Val::Px(48.0F))
        .with_height(@ui.Val::Px(34.0F))
        .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F)))
        .with_align_items(@ui.AlignItems::Center)
        .with_justify_content(@ui.JustifyContent::Center),
        @ui.BorderColor::new(@color.Color::srgb(0.82F, 0.82F, 0.92F)),
        @ui.BackgroundColor::new(@color.Color::srgb(0.18F, 0.18F, 0.24F)),
      ),
    )
    commands.spawn(
      (
        @hierarchy.Parent::new(button),
        @text.Text::new(key),
        @text.TextFont::TextFont().with_font(font).with_font_size(16.0F),
        @text.TextColor::new(@color.Color::white()),
      ),
    )
    |> ignore
  }
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  commands.insert_resource(KeyboardBuffer::{ value: "" })
  commands.spawn(
    (@camera_components2d.Camera2d::Camera2d(), @camera_camera.Camera::Camera()),
  )
  |> ignore
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")

  let root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      @ui.Node::Node()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::End)
      .with_padding(@ui.UiRect::all(@ui.Val::Px(20.0F))),
      @ui.BackgroundColor::new(@color.Color::srgb(0.06F, 0.08F, 0.18F)),
    ),
  )

  let panel = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::Node()
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_row_gap(@ui.Val::Px(6.0F))
      .with_padding(@ui.UiRect::all(@ui.Val::Px(10.0F)))
      .with_border(@ui.UiRect::all(@ui.Val::Px(2.0F))),
      @ui.BorderColor::new(@color.Color::white()),
      @ui.BackgroundColor::new(@color.Color::srgb(0.1F, 0.12F, 0.26F)),
    ),
  )
  commands.spawn(
    (
      @hierarchy.Parent::new(panel),
      KeyboardDisplay::{  },
      @text.Text::new(""),
      @text.TextFont::TextFont().with_font(font).with_font_size(22.0F),
      @text.TextColor::new(@color.Color::srgb(0.95F, 0.95F, 0.95F)),
    ),
  )
  |> ignore

  spawn_key_row(commands, panel, font, ["Q", "W", "E", "R", "T", "Y"])
  spawn_key_row(commands, panel, font, ["A", "S", "D", "F", "G", "H"])
  spawn_key_row(commands, panel, font, ["Z", "X", "C", "V", "B", "N"])
}

///|
fn keyboard_input_system(
  buttons : @ecs.Query[
    (
      @ecs.Read[KeyCap],
      @ecs.Read[@ui.Interaction],
      @ecs.Write[WasPressed],
      @ecs.Write[@ui.BackgroundColor],
    ),
    @ecs.All,
  ],
  buffer : @app.ResMut[KeyboardBuffer],
) -> Unit {
  try! buttons.view(fn(_entity, data) {
    let (key_cap, interaction, was_pressed, background) = data
    let pressed = interaction.value() == @ui.Interaction::Pressed
    if pressed && !was_pressed.value().down {
      buffer.modify(fn(value) {
        value.value = value.value + key_cap.value().value
      })
    }
    was_pressed.modify(fn(value) { value.down = pressed })
    background.set(
      @ui.BackgroundColor::new(
        if pressed {
          @color.Color::srgb(0.28F, 0.58F, 0.92F)
        } else {
          @color.Color::srgb(0.18F, 0.18F, 0.24F)
        },
      ),
    )
  })
}

///|
fn keyboard_display_system(
  buffer : @app.Res[KeyboardBuffer],
  display : @ecs.Query[@ecs.Write[@text.Text], @ecs.With[KeyboardDisplay]],
) -> Unit {
  try! display.view(fn(_entity, text) {
    text.set(@text.Text::new(buffer.get().value))
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param2(@app.Startup, setup)
  .add_systems_param2(@app.Update, keyboard_input_system)
  .add_systems_param2(@app.Update, keyboard_display_system)
  .run()
}
