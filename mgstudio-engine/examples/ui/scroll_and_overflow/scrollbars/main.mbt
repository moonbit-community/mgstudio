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
pub impl @ecs.Component for AutoScrollArea with component() {
  auto_scroll_area_key
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.1F, 0.1F, 0.12F)),
    ),
  )

  let panel = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_width(@ui.Val::Px(360.0F))
      .with_height(@ui.Val::Px(260.0F))
      .with_padding(@ui.UiRect::all(@ui.Val::Px(8.0F)))
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_row_gap(@ui.Val::Px(6.0F)),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.16F, 0.16F, 0.22F)),
    ),
  )

  let content_row = commands.spawn(
    (
      @hierarchy.Parent::new(panel),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Px(210.0F))
      .with_flex_direction(@ui.FlexDirection::Row)
      .with_column_gap(@ui.Val::Px(6.0F)),
    ),
  )

  let scroll_area = commands.spawn(
    (
      @hierarchy.Parent::new(content_row),
      AutoScrollArea::{  },
      @ui.ScrollPosition::new(0.0F, 0.0F),
      @ui.Node::default()
      .with_width(@ui.Val::Px(320.0F))
      .with_height(@ui.Val::Px(210.0F))
      .with_overflow(
        @ui.Overflow::new(@ui.OverflowAxis::Scroll, @ui.OverflowAxis::Scroll),
      )
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_row_gap(@ui.Val::Px(4.0F))
      .with_padding(@ui.UiRect::all(@ui.Val::Px(6.0F))),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.08F, 0.08F, 0.1F)),
    ),
  )
  for i in 0..<40 {
    commands.spawn(
      (
        @hierarchy.Parent::new(scroll_area),
        @text.Text::new("Scrollable line " + i.to_string()),
        @text.TextFont::default().with_font(font).with_font_size(16.0F),
        @text.TextColor::new(@sprite.Color::srgb(0.92F, 0.92F, 0.92F)),
      ),
    )
    |> ignore
  }

  commands.spawn(
    (
      @hierarchy.Parent::new(content_row),
      @ui.Node::default()
      .with_width(@ui.Val::Px(12.0F))
      .with_height(@ui.Val::Px(210.0F)),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.3F, 0.3F, 0.36F)),
      @ui.BorderRadius::all(@ui.Val::Px(6.0F)),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @hierarchy.Parent::new(panel),
      @ui.Node::default()
      .with_width(@ui.Val::Px(320.0F))
      .with_height(@ui.Val::Px(12.0F)),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.3F, 0.3F, 0.36F)),
      @ui.BorderRadius::all(@ui.Val::Px(6.0F)),
    ),
  )
  |> ignore
}

///|
fn auto_scroll(
  areas : @ecs.Query[@ecs.Mut[@ui.ScrollPosition], @ecs.With[AutoScrollArea]],
) -> Unit {
  try! areas.view(fn(_entity, scroll) {
    scroll.set(scroll.value().with_delta(0.15F, 0.65F))
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param(auto_scroll)))
  .run()
}
