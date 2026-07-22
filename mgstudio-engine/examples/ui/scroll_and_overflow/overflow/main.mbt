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
fn margin_x(value : @ui.Val) -> @ui.UiRect {
  @ui.UiRect::new(value, value, Px(0.0F), Px(0.0F))
}

///|
fn margin_bottom(value : @ui.Val) -> @ui.UiRect {
  @ui.UiRect::new(Px(0.0F), Px(0.0F), Px(0.0F), value)
}

///|
fn padding_left_top(left : @ui.Val, top : @ui.Val) -> @ui.UiRect {
  @ui.UiRect::new(left, Px(0.0F), top, Px(0.0F))
}

///|
fn transparent() -> @color.Color {
  @color.Color::new(0.0F, 0.0F, 0.0F, 0.0F)
}

///|
fn overflow_label(overflow : @ui.Overflow) -> String {
  let axis = fn(value : @ui.OverflowAxis) -> String {
    match value {
      Visible => "Visible"
      Clip => "Clip"
      Hidden => "Hidden"
      Scroll => "Scroll"
    }
  }
  "(\{axis(overflow.x)}, \{axis(overflow.y)})"
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.increment_change_tick()
  ignore(tick)
  let icon = @asset.AssetServer::new().load_image("branding/icon.png")

  try! (world.spawn_bundle(
    (
      @camera_components2d.Camera2d::Camera2d(),
      @camera_camera.Camera::Camera(),
      @transform.Transform::identity(),
    ),
  )
  |> ignore)

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, UiRoot())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::Node()
    .with_width(Percent(100.0F))
    .with_height(Percent(100.0F))
    .with_align_items(Center)
    .with_justify_content(Center),
  )
  try! world.set_by_key(
    root,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(@color.Color::srgb(0.98F, 0.92F, 0.84F)),
  )

  let overflows : Array[@ui.Overflow] = [
    @ui.Overflow::new(Visible, Visible),
    @ui.Overflow::new(Clip, Visible),
    @ui.Overflow::new(Visible, Clip),
    @ui.Overflow::new(Clip, Clip),
  ]

  for overflow in overflows {
    let column = world.spawn_empty()
    try! world.set_by_key(
      column,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(root),
    )
    try! world.set_by_key(
      column,
      @ui.ecs_key_node,
      @ui.Node::Node()
      .with_flex_direction(Column)
      .with_align_items(Center)
      .with_margin(margin_x(Px(25.0F))),
    )

    let label_box = world.spawn_empty()
    try! world.set_by_key(
      label_box,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(column),
    )
    try! world.set_by_key(
      label_box,
      @ui.ecs_key_node,
      @ui.Node::Node()
      .with_padding(@ui.UiRect::all(Px(10.0F)))
      .with_margin(margin_bottom(Px(25.0F))),
    )
    try! world.set_by_key(
      label_box,
      @ui.ecs_key_background_color,
      @ui.BackgroundColor::new(@color.Color::srgb(0.25F, 0.25F, 0.25F)),
    )

    let label = world.spawn_empty()
    try! world.set_by_key(
      label,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(label_box),
    )
    try! world.set_by_key(
      label,
      @text.ecs_key_text,
      @text.Text::new(overflow_label(overflow)),
    )
    try! world.set_by_key(label, @text.ecs_key_text_font, TextFont())

    let panel = world.spawn_empty()
    try! world.set_by_key(
      panel,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(column),
    )
    try! world.set_by_key(
      panel,
      @ui.ecs_key_node,
      @ui.Node::Node()
      .with_width(Px(100.0F))
      .with_height(Px(100.0F))
      .with_padding(padding_left_top(Px(25.0F), Px(25.0F)))
      .with_border(@ui.UiRect::all(Px(5.0F)))
      .with_overflow(overflow),
    )
    try! world.set_by_key(
      panel,
      @ui.ecs_key_border_color,
      @ui.BorderColor::new(@color.Color::black()),
    )
    try! world.set_by_key(
      panel,
      @ui.ecs_key_background_color,
      @ui.BackgroundColor::new(@color.Color::srgb(0.5F, 0.5F, 0.5F)),
    )

    let image = world.spawn_empty()
    try! world.set_by_key(
      image,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(panel),
    )
    try! world.set_by_key(image, @ui.ecs_key_node, {
      ..Node(),
      min_width: Px(100.0F),
      min_height: Px(100.0F),
    })
    try! world.set_by_key(
      image,
      @ui.ecs_key_image_node,
      @ui.ImageNode::new(icon),
    )
    try! world.set_by_key(image, @ui.ecs_key_interaction, None)
    try! world.set_by_key(image, @ui.ecs_key_outline, Outline())
  }
}

///|
fn update_outlines(
  query : @ecs.Query[
    (@ecs.Write[@ui.Outline], @ecs.Read[@ui.Interaction]),
    @ecs.All,
  ],
) -> Unit {
  try! query.view(fn(_entity, value) {
    let outline = value.0
    let interaction = value.1.value()
    let color = match interaction {
      Pressed => @color.Color::srgb(1.0F, 0.0F, 0.0F)
      Hovered => @color.Color::white()
      None => transparent()
    }
    outline.set(@ui.Outline::new(Px(2.0F), Px(2.0F), color))
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_startup_system(setup)
  .add_systems_param(Update, update_outlines)
  .run()
}
