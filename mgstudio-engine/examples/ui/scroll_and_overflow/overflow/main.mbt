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
  @ui.UiRect::new(value, @ui.Val::Px(0.0F), value, @ui.Val::Px(0.0F))
}

///|
fn margin_bottom(value : @ui.Val) -> @ui.UiRect {
  @ui.UiRect::new(
    @ui.Val::Px(0.0F),
    @ui.Val::Px(0.0F),
    @ui.Val::Px(0.0F),
    value,
  )
}

///|
fn padding_left_top(left : @ui.Val, top : @ui.Val) -> @ui.UiRect {
  @ui.UiRect::new(left, top, @ui.Val::Px(0.0F), @ui.Val::Px(0.0F))
}

///|
fn transparent() -> @sprite.Color {
  @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.0F)
}

///|
fn overflow_label(overflow : @ui.Overflow) -> String {
  let axis = fn(value : @ui.OverflowAxis) -> String {
    match value {
      @ui.OverflowAxis::Visible => "Visible"
      @ui.OverflowAxis::Clip => "Clip"
      @ui.OverflowAxis::Hidden => "Hidden"
      @ui.OverflowAxis::Scroll => "Scroll"
    }
  }
  "(\{axis(overflow.x)}, \{axis(overflow.y)})"
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.advance_sequence()
  ignore(tick)
  let icon = @asset.AssetServer::new().load_image("branding/icon.png")

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_align_items(@ui.AlignItems::Center)
    .with_justify_content(@ui.JustifyContent::Center),
  )
  try! world.set_by_key(
    root,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(@sprite.Color::srgb(0.98F, 0.92F, 0.84F)),
  )

  let overflows : Array[@ui.Overflow] = [
    @ui.Overflow::new(@ui.OverflowAxis::Visible, @ui.OverflowAxis::Visible),
    @ui.Overflow::new(@ui.OverflowAxis::Clip, @ui.OverflowAxis::Visible),
    @ui.Overflow::new(@ui.OverflowAxis::Visible, @ui.OverflowAxis::Clip),
    @ui.Overflow::new(@ui.OverflowAxis::Clip, @ui.OverflowAxis::Clip),
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
      @ui.Node::default()
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_align_items(@ui.AlignItems::Center)
      .with_margin(margin_x(@ui.Val::Px(25.0F))),
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
      @ui.Node::default()
      .with_padding(@ui.UiRect::all(@ui.Val::Px(10.0F)))
      .with_margin(margin_bottom(@ui.Val::Px(25.0F))),
    )
    try! world.set_by_key(
      label_box,
      @ui.ecs_key_background_color,
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.25F, 0.25F, 0.25F)),
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
    try! world.set_by_key(
      label,
      @text.ecs_key_text_font,
      @text.TextFont::default(),
    )

    let panel = world.spawn_empty()
    try! world.set_by_key(
      panel,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(column),
    )
    try! world.set_by_key(
      panel,
      @ui.ecs_key_node,
      @ui.Node::default()
      .with_width(@ui.Val::Px(100.0F))
      .with_height(@ui.Val::Px(100.0F))
      .with_padding(padding_left_top(@ui.Val::Px(25.0F), @ui.Val::Px(25.0F)))
      .with_border(@ui.UiRect::all(@ui.Val::Px(5.0F)))
      .with_overflow(overflow),
    )
    try! world.set_by_key(
      panel,
      @ui.ecs_key_border_color,
      @ui.BorderColor::new(@sprite.Color::black()),
    )
    try! world.set_by_key(
      panel,
      @ui.ecs_key_background_color,
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.5F, 0.5F, 0.5F)),
    )

    let image = world.spawn_empty()
    try! world.set_by_key(
      image,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(panel),
    )
    try! world.set_by_key(image, @ui.ecs_key_node, @ui.Node::{
      ..@ui.Node::default(),
      min_width: @ui.Val::Px(100.0F),
      min_height: @ui.Val::Px(100.0F),
    })
    try! world.set_by_key(
      image,
      @ui.ecs_key_image_node,
      @ui.ImageNode::new(icon),
    )
    try! world.set_by_key(image, @ui.ecs_key_interaction, @ui.Interaction::None)
    try! world.set_by_key(image, @ui.ecs_key_outline, @ui.Outline::default())
  }
}

///|
fn update_outlines(
  query : @ecs.Query[
    (@ecs.Mut[@ui.Outline], @ecs.Comp[@ui.Interaction]),
    @ecs.All,
  ],
) -> Unit {
  try! query.view(fn(_entity, value) {
    let outline = value.0
    let interaction = value.1.value()
    let color = match interaction {
      @ui.Interaction::Pressed => @sprite.Color::srgb(1.0F, 0.0F, 0.0F)
      @ui.Interaction::Hovered => @sprite.Color::white()
      @ui.Interaction::None => transparent()
    }
    outline.set(@ui.Outline::new(@ui.Val::Px(2.0F), @ui.Val::Px(2.0F), color))
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_startup_system(setup)
  .add_systems(@app.Update, @app.system(@app.system_param(update_outlines)))
  .run()
}
