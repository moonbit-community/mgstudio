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
struct AutoScrollArea {}

///|
let auto_scroll_area_key : @ecs.ComponentKey[AutoScrollArea] = @ecs.register_component(
  debug_name="examples.ui.scroll_and_overflow.scrollbars.AutoScrollArea",
)

///|
pub impl @ecs.Component for AutoScrollArea with fn component() {
  auto_scroll_area_key
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  commands.spawn(
    (@camera_components2d.Camera2d::Camera2d(), @camera_camera.Camera::Camera()),
  )
  |> ignore
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")

  let root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      @ui.Node::Node()
      .with_width(Percent(100.0F))
      .with_height(Percent(100.0F))
      .with_align_items(Center)
      .with_justify_content(Center),
      @ui.BackgroundColor::new(@color.Color::srgb(0.1F, 0.1F, 0.12F)),
    ),
  )

  let panel = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::Node()
      .with_width(Px(360.0F))
      .with_height(Px(260.0F))
      .with_padding(@ui.UiRect::all(Px(8.0F)))
      .with_flex_direction(Column)
      .with_row_gap(Px(6.0F)),
      @ui.BackgroundColor::new(@color.Color::srgb(0.16F, 0.16F, 0.22F)),
    ),
  )

  let content_row = commands.spawn(
    (
      @hierarchy.Parent::new(panel),
      @ui.Node::Node()
      .with_width(Percent(100.0F))
      .with_height(Px(210.0F))
      .with_flex_direction(Row)
      .with_column_gap(Px(6.0F)),
    ),
  )

  let scroll_area = commands.spawn(
    (
      @hierarchy.Parent::new(content_row),
      AutoScrollArea::{  },
      @ui.ScrollPosition::new(0.0F, 0.0F),
      @ui.Node::Node()
      .with_width(Px(320.0F))
      .with_height(Px(210.0F))
      .with_overflow(@ui.Overflow::new(Scroll, Scroll))
      .with_flex_direction(Column)
      .with_row_gap(Px(4.0F))
      .with_padding(@ui.UiRect::all(Px(6.0F))),
      @ui.BackgroundColor::new(@color.Color::srgb(0.08F, 0.08F, 0.1F)),
    ),
  )
  for i in 0..<40 {
    commands.spawn(
      (
        @hierarchy.Parent::new(scroll_area),
        @text.Text::new("Scrollable line \{i.to_string()}"),
        @text.TextFont::TextFont().with_font(font).with_font_size(16.0F),
        @text.TextColor::new(@color.Color::srgb(0.92F, 0.92F, 0.92F)),
      ),
    )
    |> ignore
  }

  commands.spawn(
    (
      @hierarchy.Parent::new(content_row),
      @ui.Node::Node()
      .with_width(Px(12.0F))
      .with_height(Px(210.0F))
      .with_border_radius(@ui.BorderRadius::all(Px(6.0F))),
      @ui.BackgroundColor::new(@color.Color::srgb(0.3F, 0.3F, 0.36F)),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @hierarchy.Parent::new(panel),
      @ui.Node::Node()
      .with_width(Px(320.0F))
      .with_height(Px(12.0F))
      .with_border_radius(@ui.BorderRadius::all(Px(6.0F))),
      @ui.BackgroundColor::new(@color.Color::srgb(0.3F, 0.3F, 0.36F)),
    ),
  )
  |> ignore
}

///|
fn auto_scroll(
  areas : @ecs.Query[@ecs.Write[@ui.ScrollPosition], @ecs.With[AutoScrollArea]],
) -> Unit {
  try! areas.view(fn(_entity, scroll) {
    scroll.set(scroll.value().with_delta(0.15F, 0.65F))
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param2(Startup, setup)
  .add_systems_param(Update, auto_scroll)
  .run()
}
