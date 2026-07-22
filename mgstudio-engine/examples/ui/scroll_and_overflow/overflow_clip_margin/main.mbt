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
fn sample_margins() -> Array[(String, @ui.OverflowClipMargin)] {
  [
    (
      "BorderBox + 25px",
      @ui.OverflowClipMargin::border_box().with_margin(25.0F),
    ),
    ("BorderBox", @ui.OverflowClipMargin::border_box()),
    ("PaddingBox", @ui.OverflowClipMargin::padding_box()),
    ("ContentBox", @ui.OverflowClipMargin::content_box()),
  ]
}

///|
fn spawn_label(
  world : @ecs.World,
  parent : @core.Entity,
  text : String,
  font : @asset.Handle[@asset.Font],
) -> Unit {
  let entity = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(entity)
    .insert(
      (
        @hierarchy.Parent::new(parent),
        @text.Text::new(text),
        @text.TextFont::from_font_size(@text.FontSize::Px(16.0F)).with_font(
          font,
        ),
        @text.TextColor::new(@color.Color::white()),
      ),
    ),
  )
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.increment_change_tick()
  ignore(tick)

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let icon = asset_server.load_image("branding/icon.png")

  ignore(
    try! world.spawn_bundle(
      (
        @camera_components2d.Camera2d::Camera2d(),
        @camera_camera.Camera::Camera(),
        @transform.Transform::identity(),
      ),
    ),
  )

  let root = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(root)
    .insert(
      (
        @ui.UiRoot::UiRoot(),
        @ui.Node::Node()
        .with_width(Percent(100.0F))
        .with_height(Percent(100.0F))
        .with_align_items(Center)
        .with_justify_content(Center)
        .with_flex_direction(Column)
        .with_row_gap(Px(40.0F)),
        @ui.BackgroundColor::new(@color.Color::srgb(0.98F, 0.92F, 0.84F)),
      ),
    ),
  )

  for sample in sample_margins() {
    let (label, overflow_clip_margin) = sample
    let row = world.spawn_empty()
    ignore(
      try! world
      .entity_mut(row)
      .insert(
        (
          @hierarchy.Parent::new(root),
          @ui.Node::Node().with_flex_direction(Row).with_column_gap(Px(20.0F)),
          @ui.BackgroundColor::new(@color.Color::new(0.0F, 0.0F, 0.0F, 0.0F)),
        ),
      ),
    )

    let label_box = world.spawn_empty()
    ignore(
      try! world
      .entity_mut(label_box)
      .insert(
        (
          @hierarchy.Parent::new(row),
          @ui.Node::Node()
          .with_padding(@ui.UiRect::all(Px(10.0F)))
          .with_margin(@ui.UiRect::new(Px(0.0F), Px(0.0F), Px(0.0F), Px(25.0F))),
          @ui.BackgroundColor::new(@color.Color::srgb(0.25F, 0.25F, 0.25F)),
        ),
      ),
    )
    spawn_label(world, label_box, label, font)

    let panel = world.spawn_empty()
    ignore(
      try! world
      .entity_mut(panel)
      .insert(
        (
          @hierarchy.Parent::new(row),
          @ui.Node::Node()
          .with_width(Px(100.0F))
          .with_height(Px(100.0F))
          .with_padding(@ui.UiRect::all(Px(20.0F)))
          .with_border(@ui.UiRect::all(Px(5.0F)))
          .with_overflow(@ui.Overflow::new(Clip, Clip))
          .with_overflow_clip_margin(overflow_clip_margin)
          .with_margin(@ui.UiRect::new(Px(0.0F), Px(10.0F), Px(0.0F), Px(0.0F))),
          @ui.BackgroundColor::new(@color.Color::srgb(0.5F, 0.5F, 0.5F)),
          @ui.BorderColor::new(@color.Color::black()),
        ),
      ),
    )

    let child = world.spawn_empty()
    ignore(
      try! world
      .entity_mut(child)
      .insert(
        (
          @hierarchy.Parent::new(panel),
          @ui.Node::{ ..Node(), min_width: Px(100.0F), min_height: Px(100.0F) },
          @ui.BackgroundColor::new(@color.Color::srgb(0.88F, 1.0F, 1.0F)),
          @ui.ImageNode::new(icon),
        ),
      ),
    )
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_world(Startup, setup)
  .run()
}
