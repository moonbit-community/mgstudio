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
priv struct Text2dHandles {
  translation_text : @text.TextHandle
  rotation_text : @text.TextHandle
  scale_text : @text.TextHandle
}

///|
let text2d_handles_resource_key : @ecs.ResourceKey[Text2dHandles] = @ecs.register_resource(
  debug_name="examples.2d.text2d.Text2dHandles",
)

///|
impl @app.Resource for Text2dHandles with resource() {
  text2d_handles_resource_key
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(animate)))
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
  let box_color = @sprite.Color::srgb(0.25F, 0.25F, 0.55F)
  let text_shadow_color = color_darker(box_color, 0.05F)

  let translation_text = spawn_animated_text(
    " translation ",
    large_font,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-400.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  let rotation_text = spawn_animated_text(
    " rotation ",
    large_font,
    @transform.Transform::identity(),
  )
  let scale_text = spawn_animated_text(
    " scale ",
    large_font,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(400.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  commands.insert_resource(Text2dHandles::{
    translation_text,
    rotation_text,
    scale_text,
  })

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

  @text.Text2dBundle::new(
    @text.Text2d::new("This text has\nFontSmoothing::None\nAnd Justify::Center"),
    medium_font.with_font_smoothing(@text.FontSmoothing::None),
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-400.0F, -250.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
  .with_shadow(Some(@text.Text2dShadow::default()))
  .spawn()
  |> ignore

  let anchor_origin = @math.Vec2::new(0.0F, 250.0F)
  ignore(
    commands.spawn(
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
        @transform.Transform::from_xy_rotation_scale(
          anchor_origin,
          0.0F,
          @math.Vec2::new(1.0F, 1.0F),
        ),
      ),
    ),
  )

  spawn_anchor_label(
    medium_font,
    @sprite.Anchor::top_left(),
    @sprite.Color::srgb(1.0F, 0.63F, 0.48F),
    anchor_origin,
  )
  spawn_anchor_label(
    medium_font,
    @sprite.Anchor::top_right(),
    @sprite.Color::srgb(0.67F, 0.90F, 0.60F),
    anchor_origin,
  )
  spawn_anchor_label(
    medium_font,
    @sprite.Anchor::bottom_right(),
    @sprite.Color::srgb(0.53F, 0.81F, 0.98F),
    anchor_origin,
  )
  spawn_anchor_label(
    medium_font,
    @sprite.Anchor::bottom_left(),
    @sprite.Color::srgb(1.0F, 0.93F, 0.55F),
    anchor_origin,
  )

  ignore(commands.spawn_component(@sprite.Camera2d::default()))
}

///|
fn spawn_animated_text(
  content : String,
  font : @text.TextFont,
  transform : @transform.Transform,
) -> @text.TextHandle {
  @text.Text2dBundle::new(@text.Text2d::new(content), font, transform)
  .with_background_color(
    Some(
      @text.TextBackgroundColor::new(@sprite.Color::new(0.0F, 0.0F, 0.0F, 0.5F)),
    ),
  )
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
  .with_shadow(Some(@text.Text2dShadow::default()))
  .spawn()
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
  ignore(
    commands.spawn(
      (
        @sprite.Mesh2d::new(
          meshes.get_ref().val.add(
            @sprite.mesh2d_geometry_rectangle(
              @sprite.Rectangle::from_size(size),
            ).to_mesh(),
          ),
        ),
        @sprite.MeshMaterial2d::new(
          materials.get_ref().val.add(
            @sprite.ColorMaterialAsset::from_color(box_color),
          ),
        ),
        @transform.Transform::from_xy_rotation_scale(
          center,
          0.0F,
          @math.Vec2::new(1.0F, 1.0F),
        ),
      ),
    ),
  )

  @text.Text2dBundle::new(
    @text.Text2d::new(content),
    font,
    @transform.Transform::from_xy_rotation_scale(
      center,
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=1.0F,
    ),
  )
  .with_layout(@text.TextLayout::new(@text.Justify::Left, linebreak))
  .with_bounds(@text.TextBounds::new(size.x, size.y))
  .with_shadow(Some(@text.Text2dShadow::default().with_color(shadow_color)))
  .with_underline(
    if underline {
      Some(@text.Underline::default())
    } else {
      None
    },
  )
  .spawn()
  |> ignore
}

///|
fn spawn_anchor_label(
  font : @text.TextFont,
  anchor : @sprite.Anchor,
  color : @sprite.Color,
  position : @math.Vec2,
) -> Unit {
  let label = anchor_name(anchor)
  let base_handle = @text.Text2dBundle::new(
      @text.Text2d::new(" Anchor"),
      font,
      @transform.Transform::from_xy_rotation_scale(
        position,
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=-1.0F,
      ),
    )
    .with_anchor(anchor)
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
    .with_background_color(
      Some(
        @text.TextBackgroundColor::new(@sprite.Color::srgb(0.2F, 0.2F, 0.2F)),
      ),
    )
    .spawn()
  @text.TextSpanBundle::new(@text.TextSpan::new("::"), font)
  .with_color(@text.TextColor::new(@sprite.Color::srgb(0.83F, 0.83F, 0.83F)))
  .with_background_color(
    Some(@text.TextBackgroundColor::new(@sprite.Color::srgb(0.0F, 0.0F, 0.55F))),
  )
  .spawn(base_handle)
  |> ignore
  @text.TextSpanBundle::new(@text.TextSpan::new(label + " "), font)
  .with_color(@text.TextColor::new(color))
  .with_background_color(
    Some(@text.TextBackgroundColor::new(color_darker(color, 0.3F))),
  )
  .spawn(base_handle)
  |> ignore
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
fn animate(
  text_handles : @app.Res[Text2dHandles],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  let handles = text_handles.get()

  @text.text_set_transform(
    handles.translation_text,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(
        100.0F * @math.sin(elapsed) - 400.0F,
        100.0F * @math.cos(elapsed),
      ),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )

  @text.text_set_transform(
    handles.rotation_text,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      @math.cos(elapsed),
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )

  let scale = (@math.sin(elapsed) + 1.1F) * 2.0F
  @text.text_set_transform(
    handles.scale_text,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(400.0F, 0.0F),
      0.0F,
      @math.Vec2::new(scale, scale),
    ),
  )
}
