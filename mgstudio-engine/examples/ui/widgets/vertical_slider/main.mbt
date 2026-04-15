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
struct VerticalFill {}

///|
struct HorizontalFill {}

///|
struct SliderValues {
  mut vertical : Float
  mut horizontal : Float
}

///|
let vertical_fill_key : @ecs.ComponentKey[VerticalFill] = @ecs.register_component(
  debug_name="examples.ui.widgets.vertical_slider.VerticalFill",
)

///|
let horizontal_fill_key : @ecs.ComponentKey[HorizontalFill] = @ecs.register_component(
  debug_name="examples.ui.widgets.vertical_slider.HorizontalFill",
)

///|
let slider_values_key : @ecs.ResourceKey[SliderValues] = @ecs.register_resource(
  debug_name="examples.ui.widgets.vertical_slider.SliderValues",
)

///|
pub impl @ecs.Component for VerticalFill with component() {
  vertical_fill_key
}

///|
pub impl @ecs.Component for HorizontalFill with component() {
  horizontal_fill_key
}

///|
pub impl @app.Resource for SliderValues with resource() {
  slider_values_key
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  commands.insert_resource(SliderValues::{ vertical: 0.5F, horizontal: 0.5F })
  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_flex_direction(@ui.FlexDirection::Row)
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center)
      .with_column_gap(@ui.Val::Px(40.0F)),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.1F, 0.1F, 0.13F)),
    ),
  )

  let vertical = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_width(@ui.Val::Px(24.0F))
      .with_height(@ui.Val::Px(240.0F))
      .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F))),
      @ui.BorderColor::new(@sprite.Color::white()),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.12F, 0.12F, 0.16F)),
    ),
  )
  commands.spawn(
    (
      @hierarchy.Parent::new(vertical),
      VerticalFill::{  },
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(50.0F))
      .with_position_type(@ui.PositionType::Absolute)
      .with_bottom(@ui.Val::Px(0.0F)),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.35F, 0.76F, 0.35F)),
    ),
  )
  |> ignore

  let horizontal = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_width(@ui.Val::Px(260.0F))
      .with_height(@ui.Val::Px(24.0F))
      .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F))),
      @ui.BorderColor::new(@sprite.Color::white()),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.12F, 0.12F, 0.16F)),
    ),
  )
  commands.spawn(
    (
      @hierarchy.Parent::new(horizontal),
      HorizontalFill::{  },
      @ui.Node::default()
      .with_width(@ui.Val::Percent(50.0F))
      .with_height(@ui.Val::Percent(100.0F)),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.35F, 0.76F, 0.35F)),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @text.Text::new("Use Arrow keys to adjust both sliders"),
      @text.TextFont::default().with_font(font).with_font_size(16.0F),
      @text.TextColor::new(@sprite.Color::srgb(0.9F, 0.9F, 0.9F)),
    ),
  )
  |> ignore
}

///|
fn update_values(
  keyboard : @input.ButtonInput[@window.KeyCode],
  values : @app.ResMut[SliderValues],
) -> Unit {
  if keyboard.pressed(@window.KeyCode::ArrowUp) {
    values.get_ref().val.vertical = (values.get_ref().val.vertical + 0.01F).min(
      1.0F,
    )
  }
  if keyboard.pressed(@window.KeyCode::ArrowDown) {
    values.get_ref().val.vertical = (values.get_ref().val.vertical - 0.01F).max(
      0.0F,
    )
  }
  if keyboard.pressed(@window.KeyCode::ArrowRight) {
    values.get_ref().val.horizontal = (values.get_ref().val.horizontal + 0.01F).min(
      1.0F,
    )
  }
  if keyboard.pressed(@window.KeyCode::ArrowLeft) {
    values.get_ref().val.horizontal = (values.get_ref().val.horizontal - 0.01F).max(
      0.0F,
    )
  }
}

///|
fn apply_values(
  values : @app.Res[SliderValues],
  vertical_fill : @ecs.Query[@ecs.Mut[@ui.Node], @ecs.With[VerticalFill]],
  horizontal_fill : @ecs.Query[@ecs.Mut[@ui.Node], @ecs.With[HorizontalFill]],
) -> Unit {
  try! vertical_fill.view(fn(_entity, node) {
    node.set(
      node.value().with_height(@ui.Val::Percent(values.get().vertical * 100.0F)),
    )
  })
  try! horizontal_fill.view(fn(_entity, node) {
    node.set(
      node
      .value()
      .with_width(@ui.Val::Percent(values.get().horizontal * 100.0F)),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(update_values)))
  .add_systems(@app.Update, @app.system(@app.system_param3(apply_values)))
  .run()
}
