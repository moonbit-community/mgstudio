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
priv struct Text2dState {
  mut translation_text : @text.TextHandle?
  mut rotation_text : @text.TextHandle?
  mut scale_text : @text.TextHandle?
}

///|
let text2d_state : Ref[Text2dState] = Ref::new(Text2dState::{
  translation_text: None,
  rotation_text: None,
  scale_text: None,
})

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(text2d_setup))
  .add_systems(@app.Update, @app.system(text2d_animate))
  .run()
}

///|
fn text2d_setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let large_font = @text.TextFont::default()
    .with_font(font)
    .with_font_size(50.0F)
  let medium_font = @text.TextFont::default()
    .with_font(font)
    .with_font_size(35.0F)
  let box_color = @sprite.Color::srgb(0.25F, 0.25F, 0.55F)
  let text_shadow_color = color_darker(box_color, 0.05F)

  text2d_state.val.translation_text = Some(
    spawn_animated_text(
      " translation ",
      large_font,
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-400.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
      ),
    ),
  )
  text2d_state.val.rotation_text = Some(
    spawn_animated_text(" rotation ", large_font, @math.Transform::identity()),
  )
  text2d_state.val.scale_text = Some(
    spawn_animated_text(
      " scale ",
      large_font,
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(400.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
      ),
    ),
  )

  spawn_wrapped_text_box(
    world,
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
    world,
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
    @math.Transform::from_xy_rotation_scale(
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
  @sprite.Mesh2dBundle::new(
    @sprite.Mesh2d::from_rectangle(@sprite.Rectangle::new(10.0F, 10.0F)),
    @sprite.ColorMaterial::new(@sprite.Color::srgb(0.68F, 0.97F, 0.97F)),
    @math.Transform::from_xy_rotation_scale(
      anchor_origin,
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  ).spawn(world)
  |> ignore

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

  let camera = @sprite.Camera::default()
  @sprite.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(world)
  |> ignore
}

///|
fn spawn_animated_text(
  content : String,
  font : @text.TextFont,
  transform : @math.Transform,
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
  world : @ecs.World,
  font : @text.TextFont,
  center : @math.Vec2,
  size : @math.Vec2,
  linebreak : @text.LineBreak,
  content : String,
  box_color : @sprite.Color,
  shadow_color : @sprite.Color,
  underline : Bool,
) -> Unit {
  @sprite.Mesh2dBundle::new(
    @sprite.Mesh2d::from_rectangle(@sprite.Rectangle::from_size(size)),
    @sprite.ColorMaterial::new(box_color),
    @math.Transform::from_xy_rotation_scale(
      center,
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  ).spawn(world)
  |> ignore

  @text.Text2dBundle::new(
    @text.Text2d::new(content),
    font,
    @math.Transform::from_xy_rotation_scale(
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
      @math.Transform::from_xy_rotation_scale(
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
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in text2d example")
  }
}

///|
fn text2d_animate(world : @ecs.World) -> Unit {
  let elapsed = world_time(world).elapsed_seconds()

  if text2d_state.val.translation_text is Some(handle) {
    @text.text_set_transform(
      handle,
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(
          100.0F * @math.sin(elapsed) - 400.0F,
          100.0F * @math.cos(elapsed),
        ),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
      ),
    )
  }

  if text2d_state.val.rotation_text is Some(handle) {
    @text.text_set_transform(
      handle,
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 0.0F),
        @math.cos(elapsed),
        @math.Vec2::new(1.0F, 1.0F),
      ),
    )
  }

  if text2d_state.val.scale_text is Some(handle) {
    let scale = (@math.sin(elapsed) + 1.1F) * 2.0F
    @text.text_set_transform(
      handle,
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(400.0F, 0.0F),
        0.0F,
        @math.Vec2::new(scale, scale),
      ),
    )
  }
}
