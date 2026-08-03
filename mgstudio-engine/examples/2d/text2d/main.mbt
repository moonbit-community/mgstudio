// Copyright 2025 International Digital Economy Academy
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
struct AnimateTranslation {}

///|
let animate_translation_key : @ecs.ComponentKey[AnimateTranslation] = @ecs.register_component(
  debug_name="examples.2d.text2d.animate_translation",
)

///|
impl @ecs.Component for AnimateTranslation with fn component() {
  animate_translation_key
}

///|
struct AnimateRotation {}

///|
let animate_rotation_key : @ecs.ComponentKey[AnimateRotation] = @ecs.register_component(
  debug_name="examples.2d.text2d.animate_rotation",
)

///|
impl @ecs.Component for AnimateRotation with fn component() {
  animate_rotation_key
}

///|
struct AnimateScale {}

///|
let animate_scale_key : @ecs.ComponentKey[AnimateScale] = @ecs.register_component(
  debug_name="examples.2d.text2d.animate_scale",
)

///|
impl @ecs.Component for AnimateScale with fn component() {
  animate_scale_key
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param2(Startup, setup)
  .add_systems_param2(Update, animate_translation)
  .add_systems_param2(Update, animate_rotation)
  .add_systems_param2(Update, animate_scale)
  .run()
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let large_font = @text.TextFont::TextFont()
    .with_font(font)
    .with_font_size(50.0F)
  let medium_font = @text.TextFont::TextFont()
    .with_font(font)
    .with_font_size(35.0F)
  let text_justification = @text.Justify::Center
  let box_color = @color.Color::srgb(0.25F, 0.25F, 0.55F)
  let text_shadow_color = box_color.darker(0.05F)

  ignore(commands.spawn_component(@camera_components2d.Camera2d::Camera2d()))

  ignore(
    commands.spawn(
      (
        @sprite.Text2d::new(" translation "),
        large_font,
        @text.TextLayout::new_with_justify(text_justification),
        @text.TextBackgroundColor::new(@color.Color::black().with_alpha(0.5F)),
        @sprite.Text2dShadow::Text2dShadow(),
        AnimateTranslation::{  },
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @sprite.Text2d::new(" rotation "),
        large_font,
        @text.TextLayout::new_with_justify(text_justification),
        @text.TextBackgroundColor::new(@color.Color::black().with_alpha(0.5F)),
        @sprite.Text2dShadow::Text2dShadow(),
        AnimateRotation::{  },
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @sprite.Text2d::new(" scale "),
        large_font,
        @text.TextLayout::new_with_justify(text_justification),
        @transform.Transform::from_xyz(400.0F, 0.0F, 0.0F),
        @text.TextBackgroundColor::new(@color.Color::black().with_alpha(0.5F)),
        @sprite.Text2dShadow::Text2dShadow(),
        AnimateScale::{  },
      ),
    ),
  )

  spawn_wrapped_text_box(
    commands,
    medium_font,
    @math.Vec2::new(0.0F, -250.0F),
    @math.Vec2::new(300.0F, 200.0F),
    WordBoundary,
    "this text wraps in the box\n(Unicode linebreaks)",
    box_color,
    text_shadow_color,
    true,
  )
  spawn_wrapped_text_box(
    commands,
    medium_font,
    @math.Vec2::new(320.0F, -250.0F),
    @math.Vec2::new(300.0F, 200.0F),
    AnyCharacter,
    "this text wraps in the box\n(AnyCharacter linebreaks)",
    box_color,
    text_shadow_color,
    false,
  )

  ignore(
    commands.spawn(
      (
        @sprite.Text2d::new(
          "This text has\nFontSmoothing::None\nAnd Justify::Center",
        ),
        medium_font.with_font_smoothing(None),
        @text.TextLayout::new_with_justify(Center),
        @transform.Transform::from_xyz(-400.0F, -250.0F, 0.0F),
        @sprite.Text2dShadow::Text2dShadow(),
      ),
    ),
  )

  let anchor_origin = @math.Vec2::new(0.0F, 250.0F)
  let anchor_marker = commands.spawn(
    (
      @sprite.Sprite::from_color(
        @color.Color::srgb(0.878F, 1.0F, 1.0F),
        @math.Vec2::new(10.0F, 10.0F),
      ),
      @transform.Transform::from_xyz(anchor_origin.x, anchor_origin.y, 0.0F),
    ),
  )

  spawn_anchor_label(
    commands,
    anchor_marker,
    medium_font,
    @sprite.Anchor::top_left(),
    @color.Color::srgb(1.0F, 0.627F, 0.478F),
  )
  spawn_anchor_label(
    commands,
    anchor_marker,
    medium_font,
    @sprite.Anchor::top_right(),
    @color.Color::srgb(0.565F, 0.933F, 0.565F),
  )
  spawn_anchor_label(
    commands,
    anchor_marker,
    medium_font,
    @sprite.Anchor::bottom_right(),
    @color.Color::srgb(0.678F, 0.847F, 0.902F),
  )
  spawn_anchor_label(
    commands,
    anchor_marker,
    medium_font,
    @sprite.Anchor::bottom_left(),
    @color.Color::srgb(1.0F, 1.0F, 0.878F),
  )
}

///|
fn spawn_wrapped_text_box(
  commands : @app.Commands,
  font : @text.TextFont,
  center : @math.Vec2,
  size : @math.Vec2,
  linebreak : @text.LineBreak,
  content : String,
  box_color : @color.Color,
  shadow_color : @color.Color,
  underline : Bool,
) -> Unit {
  let box_entity = commands.spawn(
    (
      @sprite.Sprite::from_color(box_color, size),
      @transform.Transform::from_xyz(center.x, center.y, 0.0F),
    ),
  )

  let text_entity = commands.spawn(
    (
      @hierarchy.Parent::new(box_entity),
      @sprite.Text2d::new(content),
      font,
      @text.TextLayout::new(Left, linebreak),
      @text.TextBounds::new(size.x, size.y),
      @transform.Transform::from_xyz(0.0F, 0.0F, 1.0F),
      @sprite.Text2dShadow::Text2dShadow().with_color(shadow_color),
    ),
  )
  if underline {
    commands.entity(text_entity).insert_component(@text.Underline::Underline())
  }
}

///|
fn spawn_anchor_label(
  commands : @app.Commands,
  parent : @core.Entity,
  font : @text.TextFont,
  anchor : @sprite.Anchor,
  color : @color.Color,
) -> Unit {
  let label_entity = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @sprite.Text2d::new(" Anchor"),
      font,
      anchor,
      @text.TextBackgroundColor::new(@color.Color::white().darker(0.8F)),
      @transform.Transform::from_xyz(0.0F, 0.0F, -1.0F),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(label_entity),
        @text.TextSpan::new("::"),
        font,
        @text.TextColor::new(@color.Color::srgb(0.827F, 0.827F, 0.827F)),
        @text.TextBackgroundColor::new(@color.Color::srgb(0.0F, 0.0F, 0.545F)),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(label_entity),
        @text.TextSpan::new("\{anchor_name(anchor)} "),
        font,
        @text.TextColor::new(color),
        @text.TextBackgroundColor::new(color.darker(0.3F)),
      ),
    ),
  )
}

///|
fn anchor_name(anchor : @sprite.Anchor) -> String {
  let v = anchor.as_vec()
  if v.x == -0.5F && v.y == 0.5F {
    "Anchor(Vec2(-0.5, 0.5))"
  } else if v.x == 0.5F && v.y == 0.5F {
    "Anchor(Vec2(0.5, 0.5))"
  } else if v.x == 0.5F && v.y == -0.5F {
    "Anchor(Vec2(0.5, -0.5))"
  } else if v.x == -0.5F && v.y == -0.5F {
    "Anchor(Vec2(-0.5, -0.5))"
  } else if v.x == 0.0F && v.y == 0.5F {
    "Anchor(Vec2(0.0, 0.5))"
  } else if v.x == 0.0F && v.y == -0.5F {
    "Anchor(Vec2(0.0, -0.5))"
  } else if v.x == -0.5F && v.y == 0.0F {
    "Anchor(Vec2(-0.5, 0.0))"
  } else if v.x == 0.5F && v.y == 0.0F {
    "Anchor(Vec2(0.5, 0.0))"
  } else {
    "Anchor(Vec2(0.0, 0.0))"
  }
}

///|
fn animate_translation(
  query : @ecs.Query[
    (
      @ecs.Write[@transform.Transform],
      @ecs.Read[@sprite.Text2d],
      @ecs.Read[AnimateTranslation],
    ),
    @ecs.All,
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  try! query.for_each(fn(_entity, data) {
    let (transform, _text, _marker) = data
    transform.modify(fn(value) {
      value.translation.x = 100.0F * @math.sin(elapsed) - 400.0F
      value.translation.y = 100.0F * @math.cos(elapsed)
    })
  })
}

///|
fn animate_rotation(
  query : @ecs.Query[
    (
      @ecs.Write[@transform.Transform],
      @ecs.Read[@sprite.Text2d],
      @ecs.Read[AnimateRotation],
    ),
    @ecs.All,
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  try! query.for_each(fn(_entity, data) {
    let (transform, _text, _marker) = data
    transform.set(
      transform
      .value()
      .with_rotation(@math.Quat::from_rotation_z(@math.cos(elapsed))),
    )
  })
}

///|
fn animate_scale(
  query : @ecs.Query[
    (
      @ecs.Write[@transform.Transform],
      @ecs.Read[@sprite.Text2d],
      @ecs.Read[AnimateScale],
    ),
    @ecs.All,
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  let scale = (@math.sin(elapsed) + 1.1F) * 2.0F
  try! query.for_each(fn(_entity, data) {
    let (transform, _text, _marker) = data
    transform.modify(fn(value) {
      value.scale.x = scale
      value.scale.y = scale
    })
  })
}
