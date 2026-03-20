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
/// Port of `bevy/examples/3d/shadow_biases.rs`.
///
/// Parity note: controls and component wiring follow Bevy. Visual output still
/// depends on current backend shadow quality.

///|
const SHADOW_BIASES_POINT_INTENSITY : Float = 1_000_000.0F

///|
const SHADOW_BIASES_POINT_RANGE : Float = 300.0F

///|
const SHADOW_BIASES_DIRECTIONAL_ILLUMINANCE : Float = 10_000.0F

///|
const SHADOW_BIASES_POINT_DEPTH_STEP : Float = 0.01F

///|
const SHADOW_BIASES_POINT_NORMAL_STEP : Float = 0.1F

///|
const SHADOW_BIASES_DIRECTIONAL_DEPTH_STEP : Float = 0.01F

///|
const SHADOW_BIASES_DIRECTIONAL_NORMAL_STEP : Float = 0.1F

///|
priv struct ShadowBiasesState {
  mut camera : @core.Entity?
  mut point_light : @core.Entity?
  mut directional_light : @core.Entity?
  mut light_position : @math.Vec3
  mut using_point_light : Bool
  mut filter_method : @pbr.ShadowFilteringMethod
  mut point_depth_bias : Float
  mut point_normal_bias : Float
  mut directional_depth_bias : Float
  mut directional_normal_bias : Float
  mut help_text : @text.TextHandle?
}

///|
let shadow_biases_state : Ref[ShadowBiasesState] = Ref::new({
  camera: None,
  point_light: None,
  directional_light: None,
  light_position: @math.Vec3::new(5.0F, 5.0F, 0.0F),
  using_point_light: false,
  filter_method: @pbr.ShadowFilteringMethod::Hardware2x2,
  point_depth_bias: @pbr.PointLight::default().shadow_depth_bias,
  point_normal_bias: @pbr.PointLight::default().shadow_normal_bias,
  directional_depth_bias: @pbr.DirectionalLight::default().shadow_depth_bias,
  directional_normal_bias: @pbr.DirectionalLight::default().shadow_normal_bias,
  help_text: None,
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn filter_method_name(filter_method : @pbr.ShadowFilteringMethod) -> String {
  match filter_method {
    @pbr.ShadowFilteringMethod::Hardware2x2 => "Hardware2x2"
    @pbr.ShadowFilteringMethod::Gaussian => "Gaussian"
    @pbr.ShadowFilteringMethod::Temporal => "Temporal"
  }
}

///|
fn active_light_name() -> String {
  if shadow_biases_state.val.using_point_light {
    "PointLight"
  } else {
    "DirectionalLight"
  }
}

///|
fn ui_text() -> String {
  let state = shadow_biases_state.val
  let p = state.light_position

  "Controls:\n" +
  "R / Z - reset biases to default / zero\n" +
  "L     - switch between directional and point lights [" +
  active_light_name() +
  "]\n" +
  "F     - switch directional light filter methods [" +
  filter_method_name(state.filter_method) +
  "]\n" +
  "1/2   - change point light depth bias [" +
  state.point_depth_bias.to_string() +
  "]\n" +
  "3/4   - change point light normal bias [" +
  state.point_normal_bias.to_string() +
  "]\n" +
  "5/6   - change directional light depth bias [" +
  state.directional_depth_bias.to_string() +
  "]\n" +
  "7/8   - change directional light normal bias [" +
  state.directional_normal_bias.to_string() +
  "]\n" +
  "left/right/up/down/pgup/pgdown - adjust light position [" +
  p.x.to_string() +
  ", " +
  p.y.to_string() +
  ", " +
  p.z.to_string() +
  "]\n"
}

///|
fn update_help_text() -> Unit {
  if shadow_biases_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, ui_text())
  }
}

///|
fn light_transform() -> @transform.Transform {
  let p = shadow_biases_state.val.light_position
  @transform.Transform::from_xyz(p.x, p.y, p.z).looking_at(
    @math.Vec3::zero(),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
}

///|
fn apply_light_state(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let transform = light_transform()
  let state = shadow_biases_state.val

  if state.point_light is Some(point_entity) {
    world
    .component(@transform.ecs_key_transform)
    .set(point_entity, transform, tick)
    |> ignore
    world
    .component(@pbr.ecs_key_point_light)
    .set(
      point_entity,
      @pbr.PointLight::new(
        @sprite.Color::white(),
        if state.using_point_light {
          SHADOW_BIASES_POINT_INTENSITY
        } else {
          0.0F
        },
        SHADOW_BIASES_POINT_RANGE,
        true,
      )
      .with_shadow_depth_bias(state.point_depth_bias)
      .with_shadow_normal_bias(state.point_normal_bias),
      tick,
    )
    |> ignore
  }

  if state.directional_light is Some(directional_entity) {
    world
    .component(@transform.ecs_key_transform)
    .set(directional_entity, transform, tick)
    |> ignore
    world
    .component(@pbr.ecs_key_directional_light)
    .set(
      directional_entity,
      @pbr.DirectionalLight::new(
        @sprite.Color::white(),
        if state.using_point_light {
          0.0F
        } else {
          SHADOW_BIASES_DIRECTIONAL_ILLUMINANCE
        },
        true,
      )
      .with_shadow_depth_bias(state.directional_depth_bias)
      .with_shadow_normal_bias(state.directional_normal_bias),
      tick,
    )
    |> ignore
  }
}

///|
fn apply_shadow_filtering_method(world : @ecs.World) -> Unit {
  guard shadow_biases_state.val.camera is Some(camera) else { return }
  let tick = world.read_change_tick()
  let store = world.component(@pbr.ecs_key_shadow_filtering_method)
  if store.contains(camera) {
    store.set(camera, shadow_biases_state.val.filter_method, tick) |> ignore
  } else {
    store.insert(camera, shadow_biases_state.val.filter_method, tick)
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  shadow_biases_state.val.camera = None
  shadow_biases_state.val.point_light = None
  shadow_biases_state.val.directional_light = None
  shadow_biases_state.val.light_position = @math.Vec3::new(5.0F, 5.0F, 0.0F)
  shadow_biases_state.val.using_point_light = false
  shadow_biases_state.val.filter_method = @pbr.ShadowFilteringMethod::Hardware2x2
  shadow_biases_state.val.point_depth_bias = @pbr.PointLight::default().shadow_depth_bias
  shadow_biases_state.val.point_normal_bias = @pbr.PointLight::default().shadow_normal_bias
  shadow_biases_state.val.directional_depth_bias = @pbr.DirectionalLight::default().shadow_depth_bias
  shadow_biases_state.val.directional_normal_bias = @pbr.DirectionalLight::default().shadow_normal_bias
  shadow_biases_state.val.help_text = None

  let white_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white())
    .with_perceptual_roughness(1.0F)
    .with_metallic(0.0F),
  )

  let sphere_proxy_mesh = @pbr.Mesh3d::from_cuboid(0.5F, 0.5F, 0.5F)

  // Dense row of proxy meshes along the view direction.
  for i in 0..<151 {
    let z_int = -300 + i * 2
    let y = if z_int % 4 == 0 { 2.0F } else { 0.25F }
    @pbr.MeshMaterial3dBundle::new(
      sphere_proxy_mesh,
      @pbr.MeshMaterial3d::new(white_material),
      @transform.Transform::from_xyz(0.0F, y, float_from_int(z_int)),
    ).spawn(world)
    |> ignore
  }

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_plane(600.0F, 600.0F),
    @pbr.MeshMaterial3d::new(white_material),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(-1.0F, 1.0F, 1.0F).looking_at(
      @math.Vec3::new(-1.0F, 1.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  shadow_biases_state.val.camera = Some(camera)

  let tick = world.read_change_tick()
  world
  .component(@pbr.ecs_key_free_camera)
  .insert(camera, @pbr.FreeCamera::default(), tick)
  world
  .component(@pbr.ecs_key_shadow_filtering_method)
  .insert(camera, shadow_biases_state.val.filter_method, tick)

  let point = world.spawn_empty()
  world
  .component(@pbr.ecs_key_point_light)
  .insert(
    point,
    @pbr.PointLight::new(
      @sprite.Color::white(),
      0.0F,
      SHADOW_BIASES_POINT_RANGE,
      true,
    )
    .with_shadow_depth_bias(shadow_biases_state.val.point_depth_bias)
    .with_shadow_normal_bias(shadow_biases_state.val.point_normal_bias),
    tick,
  )
  world
  .component(@transform.ecs_key_transform)
  .insert(point, light_transform(), tick)
  shadow_biases_state.val.point_light = Some(point)

  let directional = world.spawn_empty()
  world
  .component(@pbr.ecs_key_directional_light)
  .insert(
    directional,
    @pbr.DirectionalLight::new(
      @sprite.Color::white(),
      SHADOW_BIASES_DIRECTIONAL_ILLUMINANCE,
      true,
    )
    .with_shadow_depth_bias(shadow_biases_state.val.directional_depth_bias)
    .with_shadow_normal_bias(shadow_biases_state.val.directional_normal_bias),
    tick,
  )
  world
  .component(@transform.ecs_key_transform)
  .insert(directional, light_transform(), tick)
  shadow_biases_state.val.directional_light = Some(directional)

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let text = @text.Text2dBundle::new(
      @text.Text2d::new(ui_text()),
      @text.TextFont::default().with_font(font).with_font_size(16.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  shadow_biases_state.val.help_text = Some(text)

  apply_light_state(world)
  apply_shadow_filtering_method(world)
}

///|
fn update(world : @ecs.World) -> Unit {
  let mut light_changed = false
  let mut filter_changed = false

  if @input.key_just_pressed(@window.KeyCode::KeyL) {
    shadow_biases_state.val.using_point_light = !shadow_biases_state.val.using_point_light
    light_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyF) {
    shadow_biases_state.val.filter_method = match
      shadow_biases_state.val.filter_method {
      @pbr.ShadowFilteringMethod::Hardware2x2 =>
        @pbr.ShadowFilteringMethod::Gaussian
      @pbr.ShadowFilteringMethod::Gaussian =>
        @pbr.ShadowFilteringMethod::Temporal
      @pbr.ShadowFilteringMethod::Temporal =>
        @pbr.ShadowFilteringMethod::Hardware2x2
    }
    filter_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    shadow_biases_state.val.point_depth_bias = shadow_biases_state.val.point_depth_bias -
      SHADOW_BIASES_POINT_DEPTH_STEP
    light_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    shadow_biases_state.val.point_depth_bias = shadow_biases_state.val.point_depth_bias +
      SHADOW_BIASES_POINT_DEPTH_STEP
    light_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit3) {
    shadow_biases_state.val.point_normal_bias = shadow_biases_state.val.point_normal_bias -
      SHADOW_BIASES_POINT_NORMAL_STEP
    light_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit4) {
    shadow_biases_state.val.point_normal_bias = shadow_biases_state.val.point_normal_bias +
      SHADOW_BIASES_POINT_NORMAL_STEP
    light_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit5) {
    shadow_biases_state.val.directional_depth_bias = shadow_biases_state.val.directional_depth_bias -
      SHADOW_BIASES_DIRECTIONAL_DEPTH_STEP
    light_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit6) {
    shadow_biases_state.val.directional_depth_bias = shadow_biases_state.val.directional_depth_bias +
      SHADOW_BIASES_DIRECTIONAL_DEPTH_STEP
    light_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit7) {
    shadow_biases_state.val.directional_normal_bias = shadow_biases_state.val.directional_normal_bias -
      SHADOW_BIASES_DIRECTIONAL_NORMAL_STEP
    light_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit8) {
    shadow_biases_state.val.directional_normal_bias = shadow_biases_state.val.directional_normal_bias +
      SHADOW_BIASES_DIRECTIONAL_NORMAL_STEP
    light_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyR) {
    let point_default = @pbr.PointLight::default()
    let directional_default = @pbr.DirectionalLight::default()
    shadow_biases_state.val.point_depth_bias = point_default.shadow_depth_bias
    shadow_biases_state.val.point_normal_bias = point_default.shadow_normal_bias
    shadow_biases_state.val.directional_depth_bias = directional_default.shadow_depth_bias
    shadow_biases_state.val.directional_normal_bias = directional_default.shadow_normal_bias
    light_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyZ) {
    shadow_biases_state.val.point_depth_bias = 0.0F
    shadow_biases_state.val.point_normal_bias = 0.0F
    shadow_biases_state.val.directional_depth_bias = 0.0F
    shadow_biases_state.val.directional_normal_bias = 0.0F
    light_changed = true
  }

  let mut offset = @math.Vec3::zero()
  if @input.key_just_pressed(@window.KeyCode::ArrowLeft) {
    offset = offset.add(@math.Vec3::new(-1.0F, 0.0F, 0.0F))
  }
  if @input.key_just_pressed(@window.KeyCode::ArrowRight) {
    offset = offset.add(@math.Vec3::new(1.0F, 0.0F, 0.0F))
  }
  if @input.key_just_pressed(@window.KeyCode::ArrowUp) {
    offset = offset.add(@math.Vec3::new(0.0F, 0.0F, -1.0F))
  }
  if @input.key_just_pressed(@window.KeyCode::ArrowDown) {
    offset = offset.add(@math.Vec3::new(0.0F, 0.0F, 1.0F))
  }
  if @input.key_just_pressed(@window.KeyCode::PageDown) {
    offset = offset.add(@math.Vec3::new(0.0F, -1.0F, 0.0F))
  }
  if @input.key_just_pressed(@window.KeyCode::PageUp) {
    offset = offset.add(@math.Vec3::new(0.0F, 1.0F, 0.0F))
  }
  if offset.length_squared() > 0.0F {
    shadow_biases_state.val.light_position = shadow_biases_state.val.light_position.add(
      offset,
    )
    light_changed = true
  }

  if light_changed {
    apply_light_state(world)
  }
  if filter_changed {
    apply_shadow_filtering_method(world)
  }
  if light_changed || filter_changed {
    update_help_text()
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_plugins([@pbr.free_camera_plugin])
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(update))
  .run()
}
