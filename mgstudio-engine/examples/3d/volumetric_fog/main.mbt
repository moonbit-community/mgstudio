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
/// Demonstrates volumetric fog and lighting.

///|
const DIRECTIONAL_LIGHT_MOVEMENT_SPEED : Float = 0.02F

///|
const VOLUMETRIC_FOG_SCENE_ASSET : String = "models/VolumetricFogExample/VolumetricFogExample.glb"

///|
const POINT_LIGHT_MIN_X : Float = -1.93F

///|
const POINT_LIGHT_MAX_X : Float = -0.4F

///|
const POINT_LIGHT_INITIAL_SPEED : Float = -0.2F

///|
priv struct AppSettings {
  volumetric_spotlight : Bool
  volumetric_pointlight : Bool
}

///|
fn AppSettings::AppSettings() -> AppSettings {
  { volumetric_spotlight: true, volumetric_pointlight: true }
}

///|
let app_settings_resource_key : @ecs.ResourceKey[AppSettings] = @ecs.register_resource(
  debug_name="mgstudio.examples.volumetric_fog.AppSettings",
)

///|
impl @app.Resource for AppSettings with fn resource() {
  app_settings_resource_key
}

///|
priv struct MoveBackAndForthHorizontally {
  min_x : Float
  max_x : Float
  speed : Float
}

///|
fn MoveBackAndForthHorizontally::MoveBackAndForthHorizontally(
  min_x~ : Float,
  max_x~ : Float,
  speed~ : Float,
) -> MoveBackAndForthHorizontally {
  { min_x, max_x, speed }
}

///|
let move_back_and_forth_horizontally_component_key : @ecs.ComponentKey[
  MoveBackAndForthHorizontally,
] = @ecs.register_component(
  debug_name="mgstudio.examples.volumetric_fog.MoveBackAndForthHorizontally",
)

///|
impl @ecs.Component for MoveBackAndForthHorizontally with fn component() {
  move_back_and_forth_horizontally_component_key
}

///|
fn scene_focus() -> @math.Vec3 {
  @math.Vec3::new(-1.5F, 1.7F, 3.5F)
}

///|
fn create_text(app_settings : AppSettings) -> @text.Text {
  let point_text = if app_settings.volumetric_pointlight {
    "Press P to turn volumetric point light off"
  } else {
    "Press P to turn volumetric point light on"
  }

  let spot_text = if app_settings.volumetric_spotlight {
    "Press L to turn volumetric spot light off"
  } else {
    "Press L to turn volumetric spot light on"
  }

  @text.Text::new(
    "Press WASD or the arrow keys to change the direction of the directional light\n\{point_text}\n\{spot_text}",
  )
}

///|
fn setup_scene(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let scene_entity = world.spawn_empty()
  try! world.set_by_key(
    scene_entity,
    @scene.ecs_key_world_asset_root,
    @scene.WorldAssetRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @gltf.GltfAssetLabel::Scene(0).from_asset(VOLUMETRIC_FOG_SCENE_ASSET),
      ),
    ),
  )
  try! world.set_by_key(
    scene_entity,
    @transform.ecs_key_transform,
    @transform.Transform::identity(),
  )
}

///|
fn setup_camera(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let camera = @pbr.Camera3dBundle::new(
    Camera(),
    @transform.Transform::from_xyz(-1.7F, 1.5F, 4.5F).looking_at(
      scene_focus(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_tonemapping,
    TonyMcMapface,
  )
  try! world.set_by_key(camera, @post_process.ecs_key_bloom, Bloom())
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_skybox,
    @pbr.Skybox::new(
      asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
      1000.0F,
    ),
  )
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_volumetric_fog,
    @pbr.VolumetricFog::VolumetricFog().with_ambient_intensity(0.0F),
  )
  ignore(camera)
}

///|
fn setup_lights(world : @ecs.World) -> Unit {
  let point_light = world.spawn_empty()
  try! world.set_by_key(
    point_light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(-0.4F, 1.9F, 1.0F),
  )
  try! world.set_by_key(
    point_light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::PointLight()
    .with_shadow_maps_enabled(true)
    .with_range(150.0F)
    .with_color(@color.Color::srgba(1.0F, 0.0F, 0.0F, 1.0F))
    .with_intensity(10_000.0F),
  )
  try! world.set_by_key(
    point_light,
    @pbr.ecs_key_volumetric_light,
    VolumetricLight(),
  )
  try! world.set_by_key(
    point_light,
    move_back_and_forth_horizontally_component_key,
    MoveBackAndForthHorizontally(
      min_x=POINT_LIGHT_MIN_X,
      max_x=POINT_LIGHT_MAX_X,
      speed=POINT_LIGHT_INITIAL_SPEED,
    ),
  )

  let spot_light = world.spawn_empty()
  try! world.set_by_key(
    spot_light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(-1.8F, 3.9F, -2.7F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  try! world.set_by_key(
    spot_light,
    @pbr.ecs_key_spot_light,
    @pbr.SpotLight::SpotLight()
    .with_intensity(50_000.0F)
    .with_shadow_maps_enabled(true)
    .with_inner_angle(0.76F)
    .with_outer_angle(0.94F),
  )
  try! world.set_by_key(
    spot_light,
    @pbr.ecs_key_volumetric_light,
    VolumetricLight(),
  )

  let fog_volume = world.spawn_empty()
  try! world.set_by_key(fog_volume, @pbr.ecs_key_fog_volume, FogVolume())
  try! world.set_by_key(
    fog_volume,
    @transform.ecs_key_transform,
    @transform.Transform::identity().with_scale(@math.Vec3::splat(35.0F)),
  )
}

///|
fn setup_instructions(world : @ecs.World) -> Unit {
  let app_settings = match world.get_resource(app_settings_resource_key) {
    Some(settings) => settings
    None => AppSettings()
  }
  let help_text = world.spawn_empty()
  try! world.set_by_key(
    help_text,
    @text.ecs_key_text,
    create_text(app_settings),
  )
  try! world.set_by_key(help_text, @text.ecs_key_text_font, TextFont())
  try! world.set_by_key(help_text, @text.ecs_key_text_color, TextColor())
  try! world.set_by_key(help_text, @text.ecs_key_text_layout, TextLayout())
  try! world.set_by_key(
    help_text,
    @ui.ecs_key_node,
    @ui.Node::Node()
    .with_position_type(Absolute)
    .with_top(@ui.px(12.0F))
    .with_left(@ui.px(12.0F)),
  )
}

///|
fn directional_light_delta_theta(
  input : @input.ButtonInput[@window.KeyCode],
) -> @math.Vec2 {
  let mut delta_x = 0.0F
  let mut delta_y = 0.0F
  if input.pressed(KeyW) || input.pressed(ArrowUp) {
    delta_y = delta_y + DIRECTIONAL_LIGHT_MOVEMENT_SPEED
  }
  if input.pressed(KeyS) || input.pressed(ArrowDown) {
    delta_y = delta_y - DIRECTIONAL_LIGHT_MOVEMENT_SPEED
  }
  if input.pressed(KeyA) || input.pressed(ArrowLeft) {
    delta_x = delta_x + DIRECTIONAL_LIGHT_MOVEMENT_SPEED
  }
  if input.pressed(KeyD) || input.pressed(ArrowRight) {
    delta_x = delta_x - DIRECTIONAL_LIGHT_MOVEMENT_SPEED
  }
  @math.Vec2::new(delta_x, delta_y)
}

///|
fn directional_light_delta_quat(delta_theta : @math.Vec2) -> @math.Quat {
  @math.Quat::from_euler(XZY, delta_theta.y, 0.0F, delta_theta.x)
}

///|
fn tweak_scene(
  commands : @app.Commands,
  lights : @ecs.Query[
    @ecs.Write[@pbr.DirectionalLight],
    @ecs.Changed[@pbr.DirectionalLight],
  ],
) -> Unit {
  try! lights.view(fn(entity, directional_light) {
    directional_light.set(
      directional_light.value().with_shadow_maps_enabled(true),
    )
    commands
    .entity(entity)
    .insert_component(@pbr.VolumetricLight::VolumetricLight())
  })
}

///|
fn move_directional_light(
  input : @input.ButtonInput[@window.KeyCode],
  directional_lights : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.With[@pbr.DirectionalLight],
  ],
) -> Unit {
  let delta_theta = directional_light_delta_theta(input)
  if delta_theta.x == 0.0F && delta_theta.y == 0.0F {
    return
  }
  let delta_quat = directional_light_delta_quat(delta_theta)
  try! directional_lights.view(fn(_entity, transform) {
    transform.modify(fn(value) { value.rotate(delta_quat) })
  })
}

///|
fn move_point_light(
  time : @app.Res[@time.Time[Unit]],
  objects : @ecs.Query[
    (@ecs.Write[@transform.Transform], @ecs.Write[MoveBackAndForthHorizontally]),
    @ecs.All,
  ],
) -> Unit {
  try! objects.view(fn(_entity, data) {
    let (transform, move_data) = data
    let (translation, next_move_data, need_toggle) = adjust_moving_light_by_seconds(
      transform.value().translation,
      move_data.value(),
      time.get().delta_seconds(),
    )
    if need_toggle {
      move_data.set(next_move_data)
    }
    transform.modify(fn(value) { value.translation = translation })
  })
}

///|
fn adjust_moving_light_by_seconds(
  translation : @math.Vec3,
  move_data : MoveBackAndForthHorizontally,
  delta_seconds : Float,
) -> (@math.Vec3, MoveBackAndForthHorizontally, Bool) {
  let mut x = translation.x + move_data.speed * delta_seconds
  let mut speed = move_data.speed
  let mut need_toggle = false
  if x > move_data.max_x {
    x = move_data.max_x
    need_toggle = true
  } else if x < move_data.min_x {
    x = move_data.min_x
    need_toggle = true
  }
  if need_toggle {
    speed = -speed
  }
  let next_translation = @math.Vec3::new(x, translation.y, translation.z)
  let next_data = MoveBackAndForthHorizontally::MoveBackAndForthHorizontally(
    min_x=move_data.min_x,
    max_x=move_data.max_x,
    speed~,
  )
  (next_translation, next_data, need_toggle)
}

///|
fn app_settings_after_input(
  settings : AppSettings,
  keyboard_input : @input.ButtonInput[@window.KeyCode],
) -> (AppSettings, Bool) {
  let mut next = settings
  let mut any_changes = false
  if keyboard_input.just_pressed(KeyP) {
    next = { ..next, volumetric_pointlight: !next.volumetric_pointlight }
    any_changes = true
  }
  if keyboard_input.just_pressed(KeyL) {
    next = { ..next, volumetric_spotlight: !next.volumetric_spotlight }
    any_changes = true
  }
  (next, any_changes)
}

///|
fn[F : @ecs.QueryFilter] sync_volumetric_light_components(
  commands : @app.Commands,
  entities : @ecs.Query[@core.Entity, F],
  enabled : Bool,
) -> Unit {
  try! entities.view(fn(entity, _value) {
    if enabled {
      commands
      .entity(entity)
      .insert_component(@pbr.VolumetricLight::VolumetricLight())
    } else {
      commands.entity(entity).remove_component(@pbr.ecs_key_volumetric_light)
    }
  })
}

///|
fn adjust_app_settings(
  commands : @app.Commands,
  keyboard_input : @input.ButtonInput[@window.KeyCode],
  app_settings : @app.ResMut[AppSettings],
  point_lights : @ecs.Query[@core.Entity, @ecs.With[@pbr.PointLight]],
  spot_lights : @ecs.Query[@core.Entity, @ecs.With[@pbr.SpotLight]],
  text : @ecs.Query[@ecs.Write[@text.Text], @ecs.All],
) -> Unit {
  let (next_settings, any_changes) = app_settings_after_input(
    app_settings.get(),
    keyboard_input,
  )
  if !any_changes {
    return
  }
  app_settings.set(next_settings)
  sync_volumetric_light_components(
    commands,
    point_lights,
    next_settings.volumetric_pointlight,
  )
  sync_volumetric_light_components(
    commands,
    spot_lights,
    next_settings.volumetric_spotlight,
  )
  try! text.view(fn(_entity, text) { text.set(create_text(next_settings)) })
}

///|
fn setup(world : @ecs.World) -> Unit {
  if world.get_resource(app_settings_resource_key) is None {
    world.insert_resource(app_settings_resource_key, AppSettings())
  }

  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(@color.Color::white(), 0.0F),
  )

  setup_scene(world)
  setup_camera(world)
  setup_lights(world)
  setup_instructions(world)
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .insert_resource(
    @camera.ClearColor::new(@color.Color::srgba(0.02F, 0.02F, 0.02F, 1.0F)),
  )
  .insert_resource(AppSettings::AppSettings())
  .add_systems_world(Startup, setup)
  .add_systems_param2(Update, tweak_scene)
  .add_systems_param2(Update, move_directional_light)
  .add_systems_param2(Update, move_point_light)
  .add_systems_param6(Update, adjust_app_settings)
  .run()
}
