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
impl @ecs.Component for AnimateTranslation with component() {
  animate_translation_key
}

///|
struct AnimateRotation {}

///|
let animate_rotation_key : @ecs.ComponentKey[AnimateRotation] = @ecs.register_component(
  debug_name="examples.2d.text2d.animate_rotation",
)

///|
impl @ecs.Component for AnimateRotation with component() {
  animate_rotation_key
}

///|
struct AnimateScale {}

///|
let animate_scale_key : @ecs.ComponentKey[AnimateScale] = @ecs.register_component(
  debug_name="examples.2d.text2d.animate_scale",
)

///|
impl @ecs.Component for AnimateScale with component() {
  animate_scale_key
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(animate_translation)),
  )
  .add_systems(@app.Update, @app.system(@app.system_param2(animate_rotation)))
  .add_systems(@app.Update, @app.system(@app.system_param2(animate_scale)))
  .run()
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
) -> Unit {
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let large_font = @text.TextFont::default()
    .with_font(font)
    .with_font_size(50.0F)
  let medium_font = @text.TextFont::default()
    .with_font(font)
    .with_font_size(35.0F)
  let text_justification = @text.Justify::Center
  let box_color = @sprite.Color::srgb(0.25F, 0.25F, 0.55F)
  let text_shadow_color = color_darker(box_color, 0.05F)

  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  ignore(
    commands.spawn(
      (
        @text.Text2d::new(" translation "),
        large_font,
        @text.TextLayout::new_with_justify(text_justification),
        @text.TextBackgroundColor::new(
          @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.5F),
        ),
        @text.Text2dShadow::default(),
        AnimateTranslation::{  },
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @text.Text2d::new(" rotation "),
        large_font,
        @text.TextLayout::new_with_justify(text_justification),
        @text.TextBackgroundColor::new(
          @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.5F),
        ),
        @text.Text2dShadow::default(),
        AnimateRotation::{  },
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @text.Text2d::new(" scale "),
        large_font,
        @text.TextLayout::new_with_justify(text_justification),
        @transform.Transform::from_xyz(400.0F, 0.0F, 0.0F),
        @text.TextBackgroundColor::new(
          @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.5F),
        ),
        @text.Text2dShadow::default(),
        AnimateScale::{  },
      ),
    ),
  )

  spawn_wrapped_text_box(
    commands,
    meshes,
    materials,
    medium_font,
    @math.Vec2::new(0.0F, -250.0F),
    @math.Vec2::new(300.0F, 200.0F),
    @text.LineBreak::WordBoundary,
    "this text wraps in the box\n(Unicode linebreaks)",
    box_color,
    text_shadow_color,
    true,
  )
  spawn_wrapped_text_box(
    commands,
    meshes,
    materials,
    medium_font,
    @math.Vec2::new(320.0F, -250.0F),
    @math.Vec2::new(300.0F, 200.0F),
    @text.LineBreak::AnyCharacter,
    "this text wraps in the box\n(AnyCharacter linebreaks)",
    box_color,
    text_shadow_color,
    false,
  )

  ignore(
    commands.spawn(
      (
        @text.Text2d::new(
          "This text has\nFontSmoothing::None\nAnd Justify::Center",
        ),
        medium_font.with_font_smoothing(@text.FontSmoothing::None),
        @text.TextLayout::new_with_justify(@text.Justify::Center),
        @transform.Transform::from_xyz(-400.0F, -250.0F, 0.0F),
        @text.Text2dShadow::default(),
      ),
    ),
  )

  let anchor_origin = @math.Vec2::new(0.0F, 250.0F)
  let anchor_marker = commands.spawn(
    (
      @sprite.Mesh2d::new(
        meshes.get_ref().val.add(
          @sprite.mesh2d_geometry_rectangle(
            @sprite.Rectangle::new(10.0F, 10.0F),
          ).to_mesh(),
        ),
      ),
      @sprite.MeshMaterial2d::new(
        materials.get_ref().val.add(
          @sprite.ColorMaterialAsset::from_color(
            @sprite.Color::srgb(0.68F, 0.97F, 0.97F),
          ),
        ),
      ),
      @transform.Transform::from_xyz(anchor_origin.x, anchor_origin.y, 0.0F),
    ),
  )

  spawn_anchor_label(
    commands,
    anchor_marker,
    medium_font,
    @sprite.Anchor::top_left(),
    @sprite.Color::srgb(1.0F, 0.63F, 0.48F),
  )
  spawn_anchor_label(
    commands,
    anchor_marker,
    medium_font,
    @sprite.Anchor::top_right(),
    @sprite.Color::srgb(0.67F, 0.90F, 0.60F),
  )
  spawn_anchor_label(
    commands,
    anchor_marker,
    medium_font,
    @sprite.Anchor::bottom_right(),
    @sprite.Color::srgb(0.53F, 0.81F, 0.98F),
  )
  spawn_anchor_label(
    commands,
    anchor_marker,
    medium_font,
    @sprite.Anchor::bottom_left(),
    @sprite.Color::srgb(1.0F, 0.93F, 0.55F),
  )
}

///|
fn spawn_wrapped_text_box(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
  font : @text.TextFont,
  center : @math.Vec2,
  size : @math.Vec2,
  linebreak : @text.LineBreak,
  content : String,
  box_color : @sprite.Color,
  shadow_color : @sprite.Color,
  underline : Bool,
) -> Unit {
  let box_entity = commands.spawn(
    (
      @sprite.Mesh2d::new(
        meshes.get_ref().val.add(
          @sprite.mesh2d_geometry_rectangle(@sprite.Rectangle::from_size(size)).to_mesh(),
        ),
      ),
      @sprite.MeshMaterial2d::new(
        materials.get_ref().val.add(
          @sprite.ColorMaterialAsset::from_color(box_color),
        ),
      ),
      @transform.Transform::from_xyz(center.x, center.y, 0.0F),
    ),
  )

  let text_entity = commands.spawn(
    (
      @hierarchy.Parent::new(box_entity),
      @text.Text2d::new(content),
      font,
      @text.TextLayout::new(@text.Justify::Left, linebreak),
      @text.TextBounds::new(size.x, size.y),
      @transform.Transform::from_xyz(0.0F, 0.0F, 1.0F),
      @text.Text2dShadow::default().with_color(shadow_color),
    ),
  )
  if underline {
    commands.entity(text_entity).insert_component(@text.Underline::default())
  }
}

///|
fn spawn_anchor_label(
  commands : @app.Commands,
  parent : @core.Entity,
  font : @text.TextFont,
  anchor : @sprite.Anchor,
  color : @sprite.Color,
) -> Unit {
  let label_entity = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @text.Text2d::new(" Anchor"),
      font,
      anchor,
      @text.TextBackgroundColor::new(@sprite.Color::srgb(0.2F, 0.2F, 0.2F)),
      @transform.Transform::from_xyz(0.0F, 0.0F, -1.0F),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(label_entity),
        @text.TextSpan::new("::"),
        font,
        @text.TextColor::new(@sprite.Color::srgb(0.83F, 0.83F, 0.83F)),
        @text.TextBackgroundColor::new(@sprite.Color::srgb(0.0F, 0.0F, 0.55F)),
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
        @text.TextBackgroundColor::new(color_darker(color, 0.3F)),
      ),
    ),
  )
}

///|
fn color_darker(color : @sprite.Color, factor : Float) -> @sprite.Color {
  let safe = if factor < 0.0F {
    0.0F
  } else if factor > 1.0F {
    1.0F
  } else {
    factor
  }
  @sprite.Color::new(
    color.r * (1.0F - safe),
    color.g * (1.0F - safe),
    color.b * (1.0F - safe),
    color.a,
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
      @ecs.Mut[@transform.Transform],
      @ecs.Comp[@text.Text2d],
      @ecs.Comp[AnimateTranslation],
    ),
    @ecs.All,
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  try! query.for_each(fn(_entity, data) {
    let (transform, _text, _marker) = data
    let transform_ref = transform.get_ref()
    transform_ref.val.translation.x = 100.0F * @math.sin(elapsed) - 400.0F
    transform_ref.val.translation.y = 100.0F * @math.cos(elapsed)
  })
}

///|
fn animate_rotation(
  query : @ecs.Query[
    (
      @ecs.Mut[@transform.Transform],
      @ecs.Comp[@text.Text2d],
      @ecs.Comp[AnimateRotation],
    ),
    @ecs.All,
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  try! query.for_each(fn(_entity, data) {
    let (transform, _text, _marker) = data
    transform.get_ref().val.rotation = @math.Quat::from_rotation_z(
      @math.cos(elapsed),
    )
  })
}

///|
fn animate_scale(
  query : @ecs.Query[
    (
      @ecs.Mut[@transform.Transform],
      @ecs.Comp[@text.Text2d],
      @ecs.Comp[AnimateScale],
    ),
    @ecs.All,
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  let scale = (@math.sin(elapsed) + 1.1F) * 2.0F
  try! query.for_each(fn(_entity, data) {
    let (transform, _text, _marker) = data
    let transform_ref = transform.get_ref()
    transform_ref.val.scale.x = scale
    transform_ref.val.scale.y = scale
  })
}
