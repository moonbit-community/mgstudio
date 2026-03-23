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
/// Port of `bevy/examples/3d/contact_shadows.rs`.
///
/// Baseline parity:
/// - Bevy widget UI + pointer drag interactions are mapped to keyboard
///   controls in this runtime.
/// - Primary-pointer drag now rotates the model as a lightweight fallback for
///   Bevy `Pointer<Drag>` observers.
/// - Contact shadow / shadow filter effects are represented through Bevy-shaped
///   components, while rendering is currently an approximation in mgstudio.

///|
const PI : Float = 3.141592653589793F

///|
const LIGHT_ROTATION_SPEED : Float = 0.12F

///|
const POINT_LIGHT_INTENSITY : Float = 400_000.0F

///|
const SPOT_LIGHT_INTENSITY : Float = 400_000.0F

///|
const DIRECTIONAL_ILLUMINANCE : Float = 10_000.0F

///|
const MODEL_DRAG_ROTATION_SPEED : Float = 0.01F

///|
pub(all) enum ContactShadowState {
  Enabled
  Disabled
} derive(Eq, Show)

///|
pub(all) enum ShadowMapsState {
  Enabled
  Disabled
} derive(Eq, Show)

///|
pub(all) enum LightRotationState {
  Rotating
  Stationary
} derive(Eq, Show)

///|
pub(all) enum LightType {
  Directional
  Point
  Spot
} derive(Eq, Show)

///|
pub(all) enum ReceiveShadowsState {
  Enabled
  Disabled
} derive(Eq, Show)

///|
priv struct ContactShadowsExampleState {
  mut camera : @core.Entity?
  mut directional_light : @core.Entity?
  mut point_light : @core.Entity?
  mut spot_light : @core.Entity?
  mut model : @core.Entity?
  mut ground : @core.Entity?
  mut help_text : @text.TextHandle?
  mut light_angle : Float
  mut model_angle : Float
  mut contact_shadows : ContactShadowState
  mut shadow_maps : ShadowMapsState
  mut light_rotation : LightRotationState
  mut light_type : LightType
  mut receive_shadows : ReceiveShadowsState
}

///|
let contact_shadows_state : Ref[ContactShadowsExampleState] = Ref::new({
  camera: None,
  directional_light: None,
  point_light: None,
  spot_light: None,
  model: None,
  ground: None,
  help_text: None,
  light_angle: 0.0F,
  model_angle: PI,
  contact_shadows: ContactShadowState::Enabled,
  shadow_maps: ShadowMapsState::Enabled,
  light_rotation: LightRotationState::Rotating,
  light_type: LightType::Point,
  receive_shadows: ReceiveShadowsState::Enabled,
})

///|
fn set_global_ambient_light(
  world : @ecs.World,
  color : @sprite.Color,
  brightness : Float,
) -> Unit {
  let ambient = @pbr.GlobalAmbientLight::new(color, brightness)
  world.insert_resource(@pbr.ecs_key_global_ambient_light, ambient)
}

///|
fn on_off_text(enabled : Bool) -> String {
  if enabled {
    "On"
  } else {
    "Off"
  }
}

///|
fn light_type_text(light_type : LightType) -> String {
  match light_type {
    LightType::Directional => "Directional"
    LightType::Point => "Point"
    LightType::Spot => "Spot"
  }
}

///|
fn help_text_content() -> String {
  let state = contact_shadows_state.val
  "Contact Shadows (Bevy-aligned controls)\n" +
  "1/2: Contact Shadows " +
  on_off_text(state.contact_shadows == ContactShadowState::Enabled) +
  "\n" +
  "3/4: Shadow Maps " +
  on_off_text(state.shadow_maps == ShadowMapsState::Enabled) +
  "\n" +
  "5/6: Light Rotation " +
  on_off_text(state.light_rotation == LightRotationState::Rotating) +
  "\n" +
  "Q/W/E: Light Type " +
  light_type_text(state.light_type) +
  "\n" +
  "A/S: Receive Shadows " +
  on_off_text(state.receive_shadows == ReceiveShadowsState::Enabled) +
  "\n" +
  "Arrow Left/Right: Rotate model\n" +
  "Primary pointer drag: Rotate model\n"
}

///|
fn update_help_text() -> Unit {
  if contact_shadows_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, help_text_content())
  }
}

///|
fn light_transform(angle : Float) -> @transform.Transform {
  let base_x = -0.8F
  let base_y = 1.5F
  let base_z = 1.2F
  let x = base_x * @math.cos(angle) - base_z * @math.sin(angle)
  let z = base_x * @math.sin(angle) + base_z * @math.cos(angle)
  @transform.Transform::from_xyz(x, base_y, z).looking_at(
    @math.Vec3::zero(),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
}

///|
fn apply_model_rotation(world : @ecs.World) -> Unit {
  guard contact_shadows_state.val.model is Some(model_entity) else { return }
  let tick = world.read_sequence()
  world
  .component(@transform.ecs_key_transform)
  .set(
    model_entity,
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F).with_rotation(
      @math.Quat::from_rotation_y(contact_shadows_state.val.model_angle),
    ),
    tick,
  )
  |> ignore
}

///|
fn apply_camera_components(world : @ecs.World) -> Unit {
  guard contact_shadows_state.val.camera is Some(camera) else { return }
  let tick = world.read_sequence()
  if contact_shadows_state.val.contact_shadows == ContactShadowState::Enabled {
    world
    .component(@pbr.ecs_key_contact_shadows)
    .insert(camera, @pbr.ContactShadows::default(), tick)
  } else {
    world.component(@pbr.ecs_key_contact_shadows).remove(camera) |> ignore
  }
}

///|
fn apply_ground_receive_shadows(world : @ecs.World) -> Unit {
  guard contact_shadows_state.val.ground is Some(ground_entity) else { return }
  let receiving = contact_shadows_state.val.receive_shadows ==
    ReceiveShadowsState::Enabled
  let tick = world.read_sequence()
  if receiving {
    world.component(@pbr.ecs_key_not_shadow_receiver).remove(ground_entity)
    |> ignore
  } else {
    world
    .component(@pbr.ecs_key_not_shadow_receiver)
    .insert(ground_entity, @pbr.NotShadowReceiver::default(), tick)
  }
}

///|
fn apply_light_state(world : @ecs.World) -> Unit {
  let state = contact_shadows_state.val
  let tick = world.read_sequence()
  let transform = light_transform(state.light_angle)
  let shadow_maps_enabled = state.shadow_maps == ShadowMapsState::Enabled
  let contact_shadows_enabled = state.contact_shadows ==
    ContactShadowState::Enabled

  if state.directional_light is Some(entity) {
    world.component(@transform.ecs_key_transform).set(entity, transform, tick)
    |> ignore
    world
    .component(@pbr.ecs_key_directional_light)
    .set(
      entity,
      @pbr.DirectionalLight::new(
        @sprite.Color::white(),
        if state.light_type == LightType::Directional {
          DIRECTIONAL_ILLUMINANCE
        } else {
          0.0F
        },
        shadow_maps_enabled,
      ).with_contact_shadows_enabled(contact_shadows_enabled),
      tick,
    )
    |> ignore
  }

  if state.point_light is Some(entity) {
    world.component(@transform.ecs_key_transform).set(entity, transform, tick)
    |> ignore
    world
    .component(@pbr.ecs_key_point_light)
    .set(
      entity,
      @pbr.PointLight::new(
        @sprite.Color::white(),
        if state.light_type == LightType::Point {
          POINT_LIGHT_INTENSITY
        } else {
          0.0F
        },
        25.0F,
        shadow_maps_enabled,
      )
      .with_radius(0.35F)
      .with_contact_shadows_enabled(contact_shadows_enabled),
      tick,
    )
    |> ignore
  }

  if state.spot_light is Some(entity) {
    world.component(@transform.ecs_key_transform).set(entity, transform, tick)
    |> ignore
    world
    .component(@pbr.ecs_key_spot_light)
    .set(
      entity,
      @pbr.SpotLight::new(
        @sprite.Color::white(),
        if state.light_type == LightType::Spot {
          SPOT_LIGHT_INTENSITY
        } else {
          0.0F
        },
        25.0F,
        0.6F,
        0.8F,
        shadow_maps_enabled,
      )
      .with_radius(0.35F)
      .with_contact_shadows_enabled(contact_shadows_enabled),
      tick,
    )
    |> ignore
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  contact_shadows_state.val = {
    camera: None,
    directional_light: None,
    point_light: None,
    spot_light: None,
    model: None,
    ground: None,
    help_text: None,
    light_angle: 0.0F,
    model_angle: PI,
    contact_shadows: ContactShadowState::Enabled,
    shadow_maps: ShadowMapsState::Enabled,
    light_rotation: LightRotationState::Rotating,
    light_type: LightType::Point,
    receive_shadows: ReceiveShadowsState::Enabled,
  }

  let tick = world.read_sequence()
  let asset_server = @asset.AssetServer::new()

  let camera = @pbr.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(-0.8F, 0.6F, -0.8F).looking_at(
        @math.Vec3::new(0.0F, 0.35F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_motion_blur(
      Some(@post_process.MotionBlur::default().with_shutter_angle(2.0F)),
    )
    .spawn(world)

  contact_shadows_state.val.camera = Some(camera)
  world
  .component(@pbr.ecs_key_contact_shadows)
  .insert(camera, @pbr.ContactShadows::default(), tick)
  world
  .component(@post_process.ecs_key_screen_space_ambient_occlusion)
  .insert(camera, @post_process.ScreenSpaceAmbientOcclusion::default(), tick)
  world
  .component(@post_process.ecs_key_temporal_anti_aliasing)
  .insert(camera, @post_process.TemporalAntiAliasing::default(), tick)
  world
  .component(@pbr.ecs_key_depth_prepass)
  .insert(camera, @pbr.DepthPrepass::default(), tick)
  world
  .component(@post_process.ecs_key_bloom)
  .insert(camera, @post_process.Bloom::default(), tick)
  world.component(@pbr.ecs_key_hdr).insert(camera, @pbr.Hdr::default(), tick)
  world
  .component(@post_process.ecs_key_tonemapping)
  .insert(camera, @post_process.Tonemapping::AcesFitted, tick)
  world
  .component(@pbr.ecs_key_skybox)
  .insert(
    camera,
    @pbr.Skybox::new(
      asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"),
      1000.0F,
    ),
    tick,
  )

  let directional_light = world.spawn_empty()
  let point_light = world.spawn_empty()
  let spot_light = world.spawn_empty()
  contact_shadows_state.val.directional_light = Some(directional_light)
  contact_shadows_state.val.point_light = Some(point_light)
  contact_shadows_state.val.spot_light = Some(spot_light)

  world
  .component(@pbr.ecs_key_directional_light)
  .insert(directional_light, @pbr.DirectionalLight::default(), tick)
  world
  .component(@pbr.ecs_key_point_light)
  .insert(point_light, @pbr.PointLight::default(), tick)
  world
  .component(@pbr.ecs_key_spot_light)
  .insert(spot_light, @pbr.SpotLight::default(), tick)

  let model = world.spawn_empty()
  contact_shadows_state.val.model = Some(model)
  world
  .component(@scene.ecs_key_scene_root)
  .insert(
    model,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @gltf.GltfAssetLabel::Scene(0).from_asset(
          "models/FlightHelmet/FlightHelmet.gltf",
        ),
      ),
    ),
    tick,
  )
  world
  .component(@transform.ecs_key_transform)
  .insert(
    model,
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F).with_rotation(
      @math.Quat::from_rotation_y(PI),
    ),
    tick,
  )

  let ground_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.06F, 0.06F, 0.06F, 1.0F),
    )
    .with_perceptual_roughness(1.0F)
    .with_metallic(0.0F),
  )
  let ground = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(4.0F, 4.0F)),
      ),
    ),
    @pbr.MeshMaterial3d::new(ground_material),
    @transform.Transform::identity(),
  ).spawn(world)
  contact_shadows_state.val.ground = Some(ground)

  let help_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(16.0F),
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
  contact_shadows_state.val.help_text = Some(help_text)

  set_global_ambient_light(world, @sprite.Color::white(), 0.0F)
  apply_camera_components(world)
  apply_light_state(world)
  apply_ground_receive_shadows(world)
  apply_model_rotation(world)
  update_help_text()
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in contact_shadows example")
  }
}

///|
fn rotate_light(world : @ecs.World) -> Unit {
  if contact_shadows_state.val.light_rotation != LightRotationState::Rotating {
    return
  }
  contact_shadows_state.val.light_angle = contact_shadows_state.val.light_angle +
    LIGHT_ROTATION_SPEED * world_time(world).delta_seconds()
  apply_light_state(world)
}

///|
fn controls(world : @ecs.World) -> Unit {
  let mut changed = false

  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    contact_shadows_state.val.contact_shadows = ContactShadowState::Enabled
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    contact_shadows_state.val.contact_shadows = ContactShadowState::Disabled
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit3) {
    contact_shadows_state.val.shadow_maps = ShadowMapsState::Enabled
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit4) {
    contact_shadows_state.val.shadow_maps = ShadowMapsState::Disabled
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit5) {
    contact_shadows_state.val.light_rotation = LightRotationState::Rotating
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit6) {
    contact_shadows_state.val.light_rotation = LightRotationState::Stationary
    changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyQ) {
    contact_shadows_state.val.light_type = LightType::Directional
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyW) {
    contact_shadows_state.val.light_type = LightType::Point
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyE) {
    contact_shadows_state.val.light_type = LightType::Spot
    changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyA) {
    contact_shadows_state.val.receive_shadows = ReceiveShadowsState::Enabled
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyS) {
    contact_shadows_state.val.receive_shadows = ReceiveShadowsState::Disabled
    changed = true
  }

  let dt = world_time(world).delta_seconds()
  if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    contact_shadows_state.val.model_angle = contact_shadows_state.val.model_angle +
      dt
    apply_model_rotation(world)
  }
  if @input.key_pressed(@window.KeyCode::ArrowRight) {
    contact_shadows_state.val.model_angle = contact_shadows_state.val.model_angle -
      dt
    apply_model_rotation(world)
  }
  if @input.primary_pointer_pressed() {
    let pointer_delta = @input.primary_pointer_delta()
    if pointer_delta.x != 0.0F {
      contact_shadows_state.val.model_angle = contact_shadows_state.val.model_angle +
        pointer_delta.x * MODEL_DRAG_ROTATION_SPEED
      apply_model_rotation(world)
    }
  }

  if changed {
    apply_camera_components(world)
    apply_light_state(world)
    apply_ground_receive_shadows(world)
    update_help_text()
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(controls))
  .add_systems(@app.Update, @app.system(rotate_light))
  .run()
}
