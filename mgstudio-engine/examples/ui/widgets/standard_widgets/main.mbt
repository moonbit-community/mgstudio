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
struct ToggleButton {}

///|
struct ToggleLabel {}

///|
struct WidgetSlider {}

///|
struct WidgetSliderFill {}

///|
struct WidgetState {
  mut enabled : Bool
  mut slider : Float
}

///|
let toggle_button_key : @ecs.ComponentKey[ToggleButton] = @ecs.register_component(
  debug_name="examples.ui.widgets.standard_widgets.ToggleButton",
)

///|
let toggle_label_key : @ecs.ComponentKey[ToggleLabel] = @ecs.register_component(
  debug_name="examples.ui.widgets.standard_widgets.ToggleLabel",
)

///|
let widget_slider_key : @ecs.ComponentKey[WidgetSlider] = @ecs.register_component(
  debug_name="examples.ui.widgets.standard_widgets.WidgetSlider",
)

///|
let widget_slider_fill_key : @ecs.ComponentKey[WidgetSliderFill] = @ecs.register_component(
  debug_name="examples.ui.widgets.standard_widgets.WidgetSliderFill",
)

///|
let widget_state_key : @ecs.ResourceKey[WidgetState] = @ecs.register_resource(
  debug_name="examples.ui.widgets.standard_widgets.WidgetState",
)

///|
pub impl @ecs.Component for ToggleButton with component() {
  toggle_button_key
}

///|
pub impl @ecs.Component for ToggleLabel with component() {
  toggle_label_key
}

///|
pub impl @ecs.Component for WidgetSlider with component() {
  widget_slider_key
}

///|
pub impl @ecs.Component for WidgetSliderFill with component() {
  widget_slider_fill_key
}

///|
pub impl @app.Resource for WidgetState with resource() {
  widget_state_key
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  commands.insert_resource(WidgetState::{ enabled: true, slider: 0.5F })
  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center)
      .with_row_gap(@ui.Val::Px(12.0F)),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.1F, 0.1F, 0.12F)),
    ),
  )

  let toggle_button = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      ToggleButton::{  },
      @ui.Button::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Px(220.0F))
      .with_height(@ui.Val::Px(56.0F))
      .with_border(@ui.UiRect::all(@ui.Val::Px(2.0F)))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center),
      @ui.BorderColor::new(@sprite.Color::srgb(0.7F, 0.7F, 0.76F)),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.2F, 0.2F, 0.25F)),
    ),
  )
  commands.spawn(
    (
      @hierarchy.Parent::new(toggle_button),
      ToggleLabel::{  },
      @text.Text::new("Enabled"),
      @text.TextFont::default().with_font(font).with_font_size(20.0F),
      @text.TextColor::new(@sprite.Color::white()),
    ),
  )
  |> ignore

  let slider = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      WidgetSlider::{  },
      @ui.Node::default()
      .with_width(@ui.Val::Px(300.0F))
      .with_height(@ui.Val::Px(20.0F))
      .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F))),
      @ui.BorderColor::new(@sprite.Color::srgb(0.72F, 0.72F, 0.8F)),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.12F, 0.12F, 0.14F)),
    ),
  )
  commands.spawn(
    (
      @hierarchy.Parent::new(slider),
      WidgetSliderFill::{  },
      @ui.Node::default()
      .with_width(@ui.Val::Percent(50.0F))
      .with_height(@ui.Val::Percent(100.0F)),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.32F, 0.72F, 0.32F)),
    ),
  )
  |> ignore
}

///|
fn input_system(
  keyboard : @input.ButtonInput[@window.KeyCode],
  widget_state : @app.ResMut[WidgetState],
) -> Unit {
  if keyboard.just_pressed(@window.KeyCode::Space) {
    widget_state.get_ref().val.enabled = !widget_state.get_ref().val.enabled
  }
  if keyboard.pressed(@window.KeyCode::ArrowLeft) {
    widget_state.get_ref().val.slider = (widget_state.get_ref().val.slider -
    0.01F).max(0.0F)
  }
  if keyboard.pressed(@window.KeyCode::ArrowRight) {
    widget_state.get_ref().val.slider = (widget_state.get_ref().val.slider +
    0.01F).min(1.0F)
  }
}

///|
fn update_widget_styles(
  widget_state : @app.Res[WidgetState],
  button_query : @ecs.Query[
    @ecs.Mut[@ui.BackgroundColor],
    @ecs.With[ToggleButton],
  ],
  label_query : @ecs.Query[@ecs.Mut[@text.Text], @ecs.With[ToggleLabel]],
  fill_query : @ecs.Query[@ecs.Mut[@ui.Node], @ecs.With[WidgetSliderFill]],
) -> Unit {
  let enabled = widget_state.get().enabled
  let slider = widget_state.get().slider
  try! button_query.view(fn(_entity, background) {
    background.set(
      @ui.BackgroundColor::new(
        if enabled {
          @sprite.Color::srgb(0.2F, 0.45F, 0.24F)
        } else {
          @sprite.Color::srgb(0.35F, 0.2F, 0.2F)
        },
      ),
    )
  })
  try! label_query.view(fn(_entity, label) {
    label.set(@text.Text::new(if enabled { "Enabled" } else { "Disabled" }))
  })
  try! fill_query.view(fn(_entity, fill_node) {
    fill_node.set(
      fill_node.value().with_width(@ui.Val::Percent(slider * 100.0F)),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(input_system)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param4(update_widget_styles)),
  )
  .run()
}
