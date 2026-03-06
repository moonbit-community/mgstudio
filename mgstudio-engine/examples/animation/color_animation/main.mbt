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
/// Port of `bevy/examples/animation/color_animation.rs`.

///|
const SPRITE_SIZE : Float = 75.0F

///|
const HORIZONTAL_TRAVEL : Float = 600.0F

///|
const CURVE_LINEAR_Y : Float = 275.0F

///|
const CURVE_XYZ_Y : Float = 175.0F

///|
const CURVE_OKLAB_Y : Float = 75.0F

///|
const MIX_HSL_Y : Float = -75.0F

///|
const MIX_SRGB_Y : Float = -175.0F

///|
const MIX_OKLCH_Y : Float = -275.0F

///|
const DEG_TO_RAD : Float = 0.017453292519943295F

///|
const RAD_TO_DEG : Float = 57.29577951308232F

///|
priv struct LinearRgba {
  r : Float
  g : Float
  b : Float
  a : Float
}

///|
priv struct Xyza {
  x : Float
  y : Float
  z : Float
  a : Float
}

///|
priv struct Oklaba {
  l : Float
  a_channel : Float
  b_channel : Float
  alpha : Float
}

///|
priv struct Hsla {
  h : Float
  s : Float
  l : Float
  a : Float
}

///|
priv struct Srgba {
  r : Float
  g : Float
  b : Float
  a : Float
}

///|
priv struct Oklcha {
  l : Float
  c : Float
  h : Float
  alpha : Float
}

///|
pub(all) enum ColorAnimationMode {
  CurveLinearRgba
  CurveXyza
  CurveOklaba
  MixedHsla
  MixedSrgba
  MixedOklcha
}

///|
priv struct AnimatedSprite {
  entity : @core.Entity
  y : Float
  mode : ColorAnimationMode
}

///|
priv struct ColorAnimationState {
  sprites : Array[AnimatedSprite]
  mut texture : @asset.Handle[@asset.Image]?
  mut linear_points : Array[LinearRgba]
  mut xyza_points : Array[Xyza]
  mut oklaba_points : Array[Oklaba]
  mut hsla_points : Array[Hsla]
  mut srgba_points : Array[Srgba]
  mut oklcha_points : Array[Oklcha]
}

///|
let color_animation_state : Ref[ColorAnimationState] = Ref::new(ColorAnimationState::{
  sprites: [],
  texture: None,
  linear_points: [],
  xyza_points: [],
  oklaba_points: [],
  hsla_points: [],
  srgba_points: [],
  oklcha_points: [],
})

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(color_animation_setup)
  .add_system(color_animation_update)
  .run()
}

///|
fn color_animation_setup(world : @ecs.World) -> Unit {
  color_animation_state.val.sprites.clear()
  color_animation_state.val.texture = None

  let linear_points = default_linear_control_points()
  color_animation_state.val.linear_points = linear_points
  color_animation_state.val.xyza_points = to_xyza_points(linear_points)
  color_animation_state.val.oklaba_points = to_oklaba_points(linear_points)
  color_animation_state.val.hsla_points = to_hsla_points(linear_points)
  color_animation_state.val.srgba_points = to_srgba_points(linear_points)
  color_animation_state.val.oklcha_points = to_oklcha_points(linear_points)

  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  color_animation_state.val.texture = Some(texture)

  spawn_mode_sprite(
    world,
    texture,
    CURVE_LINEAR_Y,
    ColorAnimationMode::CurveLinearRgba,
  )
  spawn_mode_sprite(world, texture, CURVE_XYZ_Y, ColorAnimationMode::CurveXyza)
  spawn_mode_sprite(
    world,
    texture,
    CURVE_OKLAB_Y,
    ColorAnimationMode::CurveOklaba,
  )
  spawn_mode_sprite(world, texture, MIX_HSL_Y, ColorAnimationMode::MixedHsla)
  spawn_mode_sprite(world, texture, MIX_SRGB_Y, ColorAnimationMode::MixedSrgba)
  spawn_mode_sprite(
    world,
    texture,
    MIX_OKLCH_Y,
    ColorAnimationMode::MixedOklcha,
  )
}

///|
fn spawn_mode_sprite(
  world : @ecs.World,
  texture : @asset.Handle[@asset.Image],
  y : Float,
  mode : ColorAnimationMode,
) -> Unit {
  let sprite = @render2d.Sprite::from_image(texture).with_custom_size(
    Some(@math.Vec2::new(SPRITE_SIZE, SPRITE_SIZE)),
  )
  let entity = @render2d.SpriteBundle::new(
    sprite,
    @math.Transform::from_xyz(0.0F, y, 0.0F),
  ).spawn(world)
  color_animation_state.val.sprites.push(AnimatedSprite::{ entity, y, mode })
}

///|
fn color_animation_update(world : @ecs.World) -> Unit {
  if color_animation_state.val.sprites.length() == 0 {
    return
  }
  guard color_animation_state.val.texture is Some(texture) else { return }

  let t = normalized_time(@time.time_elapsed_seconds())
  let x = HORIZONTAL_TRAVEL * (t - 0.5F)
  let next_sprites : Array[AnimatedSprite] = []
  for animated in color_animation_state.val.sprites {
    let color = mode_color(animated.mode, t)
    let sprite = @render2d.Sprite::from_image(texture)
      .with_custom_size(Some(@math.Vec2::new(SPRITE_SIZE, SPRITE_SIZE)))
      .with_color(color)
    try! world.despawn(animated.entity)
    let entity = @render2d.SpriteBundle::new(
      sprite,
      @math.Transform::from_xyz(x, animated.y, 0.0F),
    ).spawn(world)
    next_sprites.push(AnimatedSprite::{
      entity,
      y: animated.y,
      mode: animated.mode,
    })
  }
  color_animation_state.val.sprites.clear()
  for animated in next_sprites {
    color_animation_state.val.sprites.push(animated)
  }
}

///|
fn mode_color(mode : ColorAnimationMode, t : Float) -> @render2d.Color {
  match mode {
    ColorAnimationMode::CurveLinearRgba =>
      linear_to_color(bezier_linear(color_animation_state.val.linear_points, t))
    ColorAnimationMode::CurveXyza =>
      linear_to_color(
        xyza_to_linear(bezier_xyza(color_animation_state.val.xyza_points, t)),
      )
    ColorAnimationMode::CurveOklaba =>
      linear_to_color(
        oklaba_to_linear(
          bezier_oklaba(color_animation_state.val.oklaba_points, t),
        ),
      )
    ColorAnimationMode::MixedHsla =>
      linear_to_color(mix_hsla_points(color_animation_state.val.hsla_points, t))
    ColorAnimationMode::MixedSrgba =>
      linear_to_color(
        mix_srgba_points(color_animation_state.val.srgba_points, t),
      )
    ColorAnimationMode::MixedOklcha =>
      linear_to_color(
        mix_oklcha_points(color_animation_state.val.oklcha_points, t),
      )
  }
}

///|
fn default_linear_control_points() -> Array[LinearRgba] {
  [
    LinearRgba::{ r: 1.0F, g: 1.0F, b: 1.0F, a: 1.0F },
    LinearRgba::{ r: 1.0F, g: 1.0F, b: 0.0F, a: 1.0F },
    LinearRgba::{ r: 1.0F, g: 0.0F, b: 0.0F, a: 1.0F },
    LinearRgba::{ r: 0.0F, g: 0.0F, b: 0.0F, a: 1.0F },
  ]
}

///|
fn to_xyza_points(points : Array[LinearRgba]) -> Array[Xyza] {
  let converted : Array[Xyza] = []
  for point in points {
    converted.push(linear_to_xyza(point))
  }
  converted
}

///|
fn to_oklaba_points(points : Array[LinearRgba]) -> Array[Oklaba] {
  let converted : Array[Oklaba] = []
  for point in points {
    converted.push(linear_to_oklaba(point))
  }
  converted
}

///|
fn to_hsla_points(points : Array[LinearRgba]) -> Array[Hsla] {
  let converted : Array[Hsla] = []
  for point in points {
    converted.push(linear_to_hsla(point))
  }
  converted
}

///|
fn to_srgba_points(points : Array[LinearRgba]) -> Array[Srgba] {
  let converted : Array[Srgba] = []
  for point in points {
    converted.push(linear_to_srgba(point))
  }
  converted
}

///|
fn to_oklcha_points(points : Array[LinearRgba]) -> Array[Oklcha] {
  let converted : Array[Oklcha] = []
  for point in points {
    converted.push(linear_to_oklcha(point))
  }
  converted
}

///|
fn normalized_time(elapsed_seconds : Float) -> Float {
  (@math.sin(elapsed_seconds) + 1.0F) / 2.0F
}

///|
fn linear_to_color(color : LinearRgba) -> @render2d.Color {
  @render2d.Color::new(color.r, color.g, color.b, color.a)
}

///|
fn lerp(a : Float, b : Float, t : Float) -> Float {
  a + (b - a) * t
}

///|
fn cubic_bezier_scalar(
  p0 : Float,
  p1 : Float,
  p2 : Float,
  p3 : Float,
  t : Float,
) -> Float {
  let one_minus_t = 1.0F - t
  let b0 = one_minus_t * one_minus_t * one_minus_t
  let b1 = 3.0F * one_minus_t * one_minus_t * t
  let b2 = 3.0F * one_minus_t * t * t
  let b3 = t * t * t
  p0 * b0 + p1 * b1 + p2 * b2 + p3 * b3
}

///|
fn bezier_linear(points : Array[LinearRgba], t : Float) -> LinearRgba {
  if points.length() < 4 {
    return LinearRgba::{ r: 1.0F, g: 1.0F, b: 1.0F, a: 1.0F }
  }
  let p0 = points[0]
  let p1 = points[1]
  let p2 = points[2]
  let p3 = points[3]
  LinearRgba::{
    r: cubic_bezier_scalar(p0.r, p1.r, p2.r, p3.r, t),
    g: cubic_bezier_scalar(p0.g, p1.g, p2.g, p3.g, t),
    b: cubic_bezier_scalar(p0.b, p1.b, p2.b, p3.b, t),
    a: cubic_bezier_scalar(p0.a, p1.a, p2.a, p3.a, t),
  }
}

///|
fn bezier_xyza(points : Array[Xyza], t : Float) -> Xyza {
  if points.length() < 4 {
    return Xyza::{ x: 0.0F, y: 0.0F, z: 0.0F, a: 1.0F }
  }
  let p0 = points[0]
  let p1 = points[1]
  let p2 = points[2]
  let p3 = points[3]
  Xyza::{
    x: cubic_bezier_scalar(p0.x, p1.x, p2.x, p3.x, t),
    y: cubic_bezier_scalar(p0.y, p1.y, p2.y, p3.y, t),
    z: cubic_bezier_scalar(p0.z, p1.z, p2.z, p3.z, t),
    a: cubic_bezier_scalar(p0.a, p1.a, p2.a, p3.a, t),
  }
}

///|
fn bezier_oklaba(points : Array[Oklaba], t : Float) -> Oklaba {
  if points.length() < 4 {
    return Oklaba::{ l: 1.0F, a_channel: 0.0F, b_channel: 0.0F, alpha: 1.0F }
  }
  let p0 = points[0]
  let p1 = points[1]
  let p2 = points[2]
  let p3 = points[3]
  Oklaba::{
    l: cubic_bezier_scalar(p0.l, p1.l, p2.l, p3.l, t),
    a_channel: cubic_bezier_scalar(
      p0.a_channel,
      p1.a_channel,
      p2.a_channel,
      p3.a_channel,
      t,
    ),
    b_channel: cubic_bezier_scalar(
      p0.b_channel,
      p1.b_channel,
      p2.b_channel,
      p3.b_channel,
      t,
    ),
    alpha: cubic_bezier_scalar(p0.alpha, p1.alpha, p2.alpha, p3.alpha, t),
  }
}

///|
fn mixed_interval(t : Float) -> (Int, Float) {
  let scaled = t * 3.0F
  if scaled < 1.0F {
    (0, scaled)
  } else if scaled < 2.0F {
    (1, scaled - 1.0F)
  } else {
    (2, scaled - 2.0F)
  }
}

///|
fn mix_hsla_points(points : Array[Hsla], t : Float) -> LinearRgba {
  if points.length() < 4 {
    return LinearRgba::{ r: 1.0F, g: 1.0F, b: 1.0F, a: 1.0F }
  }
  let (start_i, local_t) = mixed_interval(t)
  let start_color = points[start_i]
  let end_color = points[start_i + 1]
  hsla_to_linear(Hsla::{
    h: lerp_hue_degrees(start_color.h, end_color.h, local_t),
    s: lerp(start_color.s, end_color.s, local_t),
    l: lerp(start_color.l, end_color.l, local_t),
    a: lerp(start_color.a, end_color.a, local_t),
  })
}

///|
fn mix_srgba_points(points : Array[Srgba], t : Float) -> LinearRgba {
  if points.length() < 4 {
    return LinearRgba::{ r: 1.0F, g: 1.0F, b: 1.0F, a: 1.0F }
  }
  let (start_i, local_t) = mixed_interval(t)
  let start_color = points[start_i]
  let end_color = points[start_i + 1]
  srgba_to_linear(Srgba::{
    r: lerp(start_color.r, end_color.r, local_t),
    g: lerp(start_color.g, end_color.g, local_t),
    b: lerp(start_color.b, end_color.b, local_t),
    a: lerp(start_color.a, end_color.a, local_t),
  })
}

///|
fn mix_oklcha_points(points : Array[Oklcha], t : Float) -> LinearRgba {
  if points.length() < 4 {
    return LinearRgba::{ r: 1.0F, g: 1.0F, b: 1.0F, a: 1.0F }
  }
  let (start_i, local_t) = mixed_interval(t)
  let start_color = points[start_i]
  let end_color = points[start_i + 1]
  oklcha_to_linear(Oklcha::{
    l: lerp(start_color.l, end_color.l, local_t),
    c: lerp(start_color.c, end_color.c, local_t),
    h: lerp_hue_degrees(start_color.h, end_color.h, local_t),
    alpha: lerp(start_color.alpha, end_color.alpha, local_t),
  })
}

///|
fn linear_to_xyza(color : LinearRgba) -> Xyza {
  Xyza::{
    x: 0.4124564F * color.r + 0.3575761F * color.g + 0.1804375F * color.b,
    y: 0.2126729F * color.r + 0.7151522F * color.g + 0.0721750F * color.b,
    z: 0.0193339F * color.r + 0.1191920F * color.g + 0.9503041F * color.b,
    a: color.a,
  }
}

///|
fn xyza_to_linear(color : Xyza) -> LinearRgba {
  LinearRgba::{
    r: 3.2404542F * color.x - 1.5371385F * color.y - 0.4985314F * color.z,
    g: -0.9692660F * color.x + 1.8760108F * color.y + 0.0415560F * color.z,
    b: 0.0556434F * color.x - 0.2040259F * color.y + 1.0572252F * color.z,
    a: color.a,
  }
}

///|
fn cube(value : Float) -> Float {
  value * value * value
}

///|
fn cbrt_signed(value : Float) -> Float {
  if value < 0.0F {
    -@math.pow(-value, 1.0F / 3.0F)
  } else {
    @math.pow(value, 1.0F / 3.0F)
  }
}

///|
fn linear_to_oklaba(color : LinearRgba) -> Oklaba {
  let l = 0.4122214708F * color.r +
    0.5363325363F * color.g +
    0.0514459929F * color.b
  let m = 0.2119034982F * color.r +
    0.6806995451F * color.g +
    0.1073969566F * color.b
  let s = 0.0883024619F * color.r +
    0.2817188376F * color.g +
    0.6299787005F * color.b

  let l_ = cbrt_signed(l)
  let m_ = cbrt_signed(m)
  let s_ = cbrt_signed(s)

  Oklaba::{
    l: 0.2104542553F * l_ + 0.7936177850F * m_ - 0.0040720468F * s_,
    a_channel: 1.9779984951F * l_ - 2.4285922050F * m_ + 0.4505937099F * s_,
    b_channel: 0.0259040371F * l_ + 0.7827717662F * m_ - 0.8086757660F * s_,
    alpha: color.a,
  }
}

///|
fn oklaba_to_linear(color : Oklaba) -> LinearRgba {
  let l_ = color.l +
    0.3963377774F * color.a_channel +
    0.2158037573F * color.b_channel
  let m_ = color.l -
    0.1055613458F * color.a_channel -
    0.0638541728F * color.b_channel
  let s_ = color.l -
    0.0894841775F * color.a_channel -
    1.2914855480F * color.b_channel

  let l = cube(l_)
  let m = cube(m_)
  let s = cube(s_)

  LinearRgba::{
    r: 4.0767416621F * l - 3.3077115913F * m + 0.2309699292F * s,
    g: -1.2684380046F * l + 2.6097574011F * m - 0.3413193965F * s,
    b: -0.0041960863F * l - 0.7034186147F * m + 1.7076147010F * s,
    a: color.alpha,
  }
}

///|
fn linear_channel_to_srgb(value : Float) -> Float {
  if value <= 0.0031308F {
    12.92F * value
  } else {
    1.055F * @math.pow(value, 1.0F / 2.4F) - 0.055F
  }
}

///|
fn srgb_channel_to_linear(value : Float) -> Float {
  if value <= 0.0F {
    value
  } else if value <= 0.04045F {
    value / 12.92F
  } else {
    @math.pow((value + 0.055F) / 1.055F, 2.4F)
  }
}

///|
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn max3(a : Float, b : Float, c : Float) -> Float {
  let ab = if a > b { a } else { b }
  if ab > c {
    ab
  } else {
    c
  }
}

///|
fn min3(a : Float, b : Float, c : Float) -> Float {
  let ab = if a < b { a } else { b }
  if ab < c {
    ab
  } else {
    c
  }
}

///|
fn wrap_degrees(hue : Float) -> Float {
  let mut wrapped = hue
  while wrapped < 0.0F {
    wrapped = wrapped + 360.0F
  }
  while wrapped >= 360.0F {
    wrapped = wrapped - 360.0F
  }
  wrapped
}

///|
fn linear_to_hsla(color : LinearRgba) -> Hsla {
  let r = linear_channel_to_srgb(color.r)
  let g = linear_channel_to_srgb(color.g)
  let b = linear_channel_to_srgb(color.b)

  let max_v = max3(r, g, b)
  let min_v = min3(r, g, b)
  let delta = max_v - min_v
  let lightness = (max_v + min_v) / 2.0F

  if delta == 0.0F {
    return Hsla::{ h: 0.0F, s: 0.0F, l: lightness, a: color.a }
  }

  let saturation = delta / (1.0F - absf(2.0F * lightness - 1.0F))
  let mut hue = 0.0F
  if max_v == r {
    hue = 60.0F * ((g - b) / delta)
  } else if max_v == g {
    hue = 60.0F * ((b - r) / delta + 2.0F)
  } else {
    hue = 60.0F * ((r - g) / delta + 4.0F)
  }

  Hsla::{ h: wrap_degrees(hue), s: saturation, l: lightness, a: color.a }
}

///|
fn hsla_to_linear(color : Hsla) -> LinearRgba {
  let linear_color = @render2d.Color::hsla(color.h, color.s, color.l, color.a)
  LinearRgba::{
    r: linear_color.r,
    g: linear_color.g,
    b: linear_color.b,
    a: linear_color.a,
  }
}

///|
fn linear_to_srgba(color : LinearRgba) -> Srgba {
  Srgba::{
    r: linear_channel_to_srgb(color.r),
    g: linear_channel_to_srgb(color.g),
    b: linear_channel_to_srgb(color.b),
    a: color.a,
  }
}

///|
fn srgba_to_linear(color : Srgba) -> LinearRgba {
  LinearRgba::{
    r: srgb_channel_to_linear(color.r),
    g: srgb_channel_to_linear(color.g),
    b: srgb_channel_to_linear(color.b),
    a: color.a,
  }
}

///|
fn linear_to_oklcha(color : LinearRgba) -> Oklcha {
  let oklab = linear_to_oklaba(color)
  let chroma = @math.sqrt(
    oklab.a_channel * oklab.a_channel + oklab.b_channel * oklab.b_channel,
  )
  let hue = if chroma <= 0.000001F {
    0.0F
  } else {
    wrap_degrees(@math.atan2(oklab.b_channel, oklab.a_channel) * RAD_TO_DEG)
  }
  Oklcha::{ l: oklab.l, c: chroma, h: hue, alpha: color.a }
}

///|
fn oklcha_to_linear(color : Oklcha) -> LinearRgba {
  let hue_radians = color.h * DEG_TO_RAD
  oklaba_to_linear(Oklaba::{
    l: color.l,
    a_channel: color.c * @math.cos(hue_radians),
    b_channel: color.c * @math.sin(hue_radians),
    alpha: color.alpha,
  })
}

///|
fn lerp_hue_degrees(start_hue : Float, end_hue : Float, t : Float) -> Float {
  let mut delta = end_hue - start_hue
  if delta > 180.0F {
    delta = delta - 360.0F
  } else if delta < -180.0F {
    delta = delta + 360.0F
  }
  wrap_degrees(start_hue + delta * t)
}
