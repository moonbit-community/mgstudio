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
struct ClickCounter {
  value : Int
}

///|
struct CounterLabel {}

///|
let click_counter_key : @ecs.ResourceKey[ClickCounter] = @ecs.register_resource(
  debug_name="examples.ui.widgets.standard_widgets_observers.ClickCounter",
)

///|
let counter_label_key : @ecs.ComponentKey[CounterLabel] = @ecs.register_component(
  debug_name="examples.ui.widgets.standard_widgets_observers.CounterLabel",
)

///|
pub impl @app.Resource for ClickCounter with fn resource() {
  click_counter_key
}

///|
pub impl @ecs.Component for CounterLabel with fn component() {
  counter_label_key
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  commands.insert_resource(ClickCounter::{ value: 0 })
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
      .with_justify_content(@ui.JustifyContent::Center)
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_row_gap(@ui.Val::Px(10.0F)),
      @ui.BackgroundColor::new(@color.Color::srgb(0.12F, 0.12F, 0.14F)),
    ),
  )

  let button = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Button::Button(),
      @ui.Node::Node()
      .with_width(@ui.Val::Px(220.0F))
      .with_height(@ui.Val::Px(60.0F))
      .with_border(@ui.UiRect::all(@ui.Val::Px(2.0F)))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center),
      @ui.BorderColor::new(@color.Color::white()),
      @ui.BackgroundColor::new(@color.Color::srgb(0.2F, 0.28F, 0.44F)),
    ),
  )
  commands.spawn(
    (
      @hierarchy.Parent::new(button),
      @text.Text::new("Click Me"),
      @text.TextFont::TextFont().with_font(font).with_font_size(22.0F),
      @text.TextColor::new(@color.Color::white()),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @hierarchy.Parent::new(root),
      CounterLabel::{  },
      @text.Text::new("Clicks: 0"),
      @text.TextFont::TextFont().with_font(font).with_font_size(24.0F),
      @text.TextColor::new(@color.Color::srgb(0.9F, 0.9F, 0.9F)),
    ),
  )
  |> ignore

  ignore(
    commands
    .entity(button)
    .observe_pointer2(fn(
      _pointer : @app.OnPointer[@app.PointerClick],
      counter : @app.ResMut[ClickCounter],
    ) {
      counter.set(ClickCounter::{ value: counter.get().value + 1 })
    }),
  )
}

///|
fn update_counter_label(
  counter : @app.Res[ClickCounter],
  label_query : @ecs.Query[@ecs.Mut[@text.Text], @ecs.With[CounterLabel]],
) -> Unit {
  try! label_query.view(fn(_entity, label) {
    label.set(@text.Text::new("Clicks: \{counter.get().value.to_string()}"))
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems(@app.Startup, @app.system_config_param2(setup))
  .add_systems(@app.Update, @app.system_config_param2(update_counter_label))
  .run()
}
