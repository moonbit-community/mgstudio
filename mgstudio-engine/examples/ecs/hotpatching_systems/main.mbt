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
struct Mode {
  mut value : Int
}

///|
struct ClickCount {
  mut value : Int
}

///|
struct HotText {}

///|
let mode_key : @ecs.ResourceKey[Mode] = @ecs.register_resource(
  debug_name="examples.ecs.hotpatching_systems.Mode",
)

///|
let click_count_key : @ecs.ResourceKey[ClickCount] = @ecs.register_resource(
  debug_name="examples.ecs.hotpatching_systems.ClickCount",
)

///|
let hot_text_key : @ecs.ComponentKey[HotText] = @ecs.register_component(
  debug_name="examples.ecs.hotpatching_systems.HotText",
)

///|
pub impl @app.Resource for Mode with fn resource() {
  mode_key
}

///|
pub impl @app.Resource for ClickCount with fn resource() {
  click_count_key
}

///|
pub impl @ecs.Component for HotText with fn component() {
  hot_text_key
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  commands.insert_resource(Mode::{ value: 0 })
  commands.insert_resource(ClickCount::{ value: 0 })
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
    ),
  )
  let text_button = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Button::Button(),
      @ui.Node::Node()
      .with_width(@ui.Val::Px(460.0F))
      .with_height(@ui.Val::Px(100.0F))
      .with_border(@ui.UiRect::all(@ui.Val::Px(2.0F)))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center),
      @ui.BorderColor::new(@color.Color::white()),
      @ui.BackgroundColor::new(@color.Color::srgb(0.15F, 0.15F, 0.2F)),
    ),
  )
  commands.spawn(
    (
      @hierarchy.Parent::new(text_button),
      HotText::{  },
      @text.Text::new("before"),
      @text.TextFont::TextFont().with_font(font).with_font_size(42.0F),
      @text.TextColor::new(@color.Color::srgb(0.95F, 0.95F, 0.95F)),
    ),
  )
  |> ignore
  ignore(
    commands
    .entity(text_button)
    .observe_pointer3(fn(
      _pointer : @app.OnPointer[@app.PointerClick],
      clicks : @app.ResMut[ClickCount],
      mode : @app.ResMut[Mode],
    ) {
      clicks.modify(fn(value) { value.value = value.value + 1 })
      mode.modify(fn(value) { value.value = (value.value + 1) % 2 })
    }),
  )
}

///|
fn keyboard_toggle(
  keyboard : @input.ButtonInput[@window.KeyCode],
  mode : @app.ResMut[Mode],
) -> Unit {
  if keyboard.just_pressed(@window.KeyCode::KeyH) {
    mode.modify(fn(value) { value.value = (value.value + 1) % 2 })
  }
}

///|
fn update_text(
  mode : @app.Res[Mode],
  clicks : @app.Res[ClickCount],
  text_query : @ecs.Query[
    (@ecs.Mut[@text.Text], @ecs.Mut[@text.TextColor]),
    @ecs.With[HotText],
  ],
) -> Unit {
  try! text_query.view(fn(_entity, data) {
    let (text, color) = data
    let message = if mode.get().value == 0 { "before" } else { "after" }
    text.set(
      @text.Text::new("\{message} (clicks: \{clicks.get().value.to_string()})"),
    )
    color.set(
      @text.TextColor::new(
        if mode.get().value == 0 {
          @color.Color::srgb(0.95F, 0.95F, 0.95F)
        } else {
          @color.Color::srgb(0.95F, 0.4F, 0.4F)
        },
      ),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems(@app.Startup, @app.system_config_param2(setup))
  .add_systems(@app.Update, @app.system_config_param2(keyboard_toggle))
  .add_systems(@app.Update, @app.system_config_param3(update_text))
  .run()
}
