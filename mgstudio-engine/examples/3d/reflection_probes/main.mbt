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
/// Port of `bevy/examples/3d/reflection_probes.rs`.
///
/// Parity note:
/// - Reflection mode switching, roughness control, camera rotation, and probe
///   placement follow Bevy's control flow.
/// - `GeneratedEnvironmentMapLight` is represented by Bevy-shaped API in
///   mgstudio; runtime cubemap filtering remains adapted.

///|
const PI : Float = 3.141592653589793F

///|
const ENV_MAP_INTENSITY : Float = 5000.0F

///|
const STOP_ROTATION_HELP_TEXT : String = "Press Enter to stop rotation"

///|
const START_ROTATION_HELP_TEXT : String = "Press Enter to start rotation"

///|
const REFLECTION_MODE_HELP_TEXT : String = "Press Space to switch reflection mode"

///|
const CUBES_SCENE_ASSET : String = "models/cubes/Cubes.glb"

///|
const DIFFUSE_ENV_MAP_ASSET : String = "environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"

///|
const SPECULAR_ENV_MAP_ASSET : String = "environment_maps/pisa_specular_rgb9e5_zstd.ktx2"

///|
const SPECULAR_REFLECTION_PROBE_ASSET : String = "environment_maps/cubes_reflection_probe_specular_rgb9e5_zstd.ktx2"

///|
pub(all) enum ReflectionMode {
  EnvironmentMap
  ReflectionProbe
  GeneratedEnvironmentMap
} derive(Eq, Show)

///|
priv struct ReflectionProbesState {
  mut reflection_mode : ReflectionMode
  mut rotating : Bool
  mut sphere_roughness : Float
  mut camera : @core.Entity?
  mut sphere_material : @asset.Handle[@pbr.StandardMaterial]?
  mut cubes_scene : @core.Entity?
  mut reflection_probe : @core.Entity?
  mut help_text : @text.TextHandle?
  mut diffuse_environment_map : @asset.Handle[@asset.Image]?
  mut specular_environment_map : @asset.Handle[@asset.Image]?
  mut specular_reflection_probe : @asset.Handle[@asset.Image]?
  mut environment_map_usage_ready : Bool
}

///|
let reflection_probes_state : Ref[ReflectionProbesState] = Ref::new({
  reflection_mode: ReflectionMode::ReflectionProbe,
  rotating: false,
  sphere_roughness: 0.2F,
  camera: None,
  sphere_material: None,
  cubes_scene: None,
  reflection_probe: None,
  help_text: None,
  diffuse_environment_map: None,
  specular_environment_map: None,
  specular_reflection_probe: None,
  environment_map_usage_ready: false,
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn clampf(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn reflection_mode_text(mode : ReflectionMode) -> String {
  match mode {
    ReflectionMode::EnvironmentMap => "Environment map"
    ReflectionMode::ReflectionProbe => "Reflection probe"
    ReflectionMode::GeneratedEnvironmentMap => "Generated environment map"
  }
}

///|
fn create_help_text() -> String {
  let rotation_help_text = if reflection_probes_state.val.rotating {
    STOP_ROTATION_HELP_TEXT
  } else {
    START_ROTATION_HELP_TEXT
  }
  reflection_mode_text(reflection_probes_state.val.reflection_mode) +
  "\n" +
  rotation_help_text +
  "\n" +
  "Roughness: " +
  reflection_probes_state.val.sphere_roughness.to_string() +
  "\n" +
  REFLECTION_MODE_HELP_TEXT +
  "\n" +
  "Up/Down arrows to change roughness"
}

///|
fn update_help_text() -> Unit {
  if reflection_probes_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, create_help_text())
  }
}

///|
fn uv_sphere_mesh(radius : Float, stacks : Int, sectors : Int) -> @pbr.Mesh3d {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  let stacks_f = float_from_int(stacks)
  let sectors_f = float_from_int(sectors)
  let stack_step = PI / stacks_f
  let sector_step = 2.0F * PI / sectors_f

  for i in 0..<(stacks + 1) {
    let stack_angle = PI / 2.0F - float_from_int(i) * stack_step
    let ring_radius = radius * @math.cos(stack_angle)
    let y = radius * @math.sin(stack_angle)
    for j in 0..<(sectors + 1) {
      let sector_angle = float_from_int(j) * sector_step
      let x = ring_radius * @math.cos(sector_angle)
      let z = ring_radius * @math.sin(sector_angle)
      positions.push(@math.Vec3::new(x, y, z))
      uvs.push(
        @math.Vec2::new(
          float_from_int(j) / sectors_f,
          float_from_int(i) / stacks_f,
        ),
      )
    }
  }

  let row = sectors + 1
  for i in 0..<stacks {
    let k1 = i * row
    let k2 = k1 + row
    for j in 0..<sectors {
      if i != 0 {
        indices.push(k1 + j)
        indices.push(k2 + j)
        indices.push(k1 + j + 1)
      }
      if i != stacks - 1 {
        indices.push(k1 + j + 1)
        indices.push(k2 + j)
        indices.push(k2 + j + 1)
      }
    }
  }

  @pbr.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
  )
}

///|
fn set_entity_visibility(
  world : @ecs.World,
  entity : @core.Entity?,
  visible : Bool,
) -> Unit {
  guard entity is Some(actual) else { return }
  let value = if visible {
    @visibility.Visibility::Inherited
  } else {
    @visibility.Visibility::Hidden
  }
  let tick = world.read_change_tick()
  let store = world.component(@visibility.ecs_key_visibility)
  if store.contains(actual) {
    store.set(actual, value, tick) |> ignore
  } else {
    store.insert(actual, value, tick)
  }
}

///|
fn create_camera_environment_map_light() -> @pbr.EnvironmentMapLight {
  @pbr.EnvironmentMapLight::new(
    reflection_probes_state.val.diffuse_environment_map,
    reflection_probes_state.val.specular_environment_map,
    ENV_MAP_INTENSITY,
  )
}

///|
fn remove_reflection_probe(world : @ecs.World) -> Unit {
  if reflection_probes_state.val.reflection_probe is Some(probe) {
    world.despawn(probe) catch {
      _ => ()
    }
  }
  reflection_probes_state.val.reflection_probe = None
}

///|
fn spawn_reflection_probe(world : @ecs.World) -> Unit {
  remove_reflection_probe(world)
  let tick = world.read_change_tick()
  let probe = world.spawn_empty()
  reflection_probes_state.val.reflection_probe = Some(probe)

  world
  .component(@pbr.ecs_key_light_probe)
  .insert(probe, @pbr.LightProbe::default(), tick)
  world
  .component(@pbr.ecs_key_environment_map_light)
  .insert(
    probe,
    @pbr.EnvironmentMapLight::new(
      reflection_probes_state.val.diffuse_environment_map,
      reflection_probes_state.val.specular_reflection_probe,
      ENV_MAP_INTENSITY,
    ),
    tick,
  )
  world
  .component(@pbr.ecs_key_parallax_correction)
  .insert(probe, @pbr.ParallaxCorrection::None, tick)
  world
  .component(@transform.ecs_key_transform)
  .insert(
    probe,
    @transform.Transform::identity().with_scale(@math.Vec3::splat(2.0F)),
    tick,
  )
}

///|
fn apply_reflection_mode(world : @ecs.World) -> Unit {
  guard reflection_probes_state.val.camera is Some(camera) else { return }
  let tick = world.read_change_tick()

  remove_reflection_probe(world)
  world.component(@pbr.ecs_key_environment_map_light).remove(camera) |> ignore
  world.component(@pbr.ecs_key_generated_environment_map_light).remove(camera)
  |> ignore

  match reflection_probes_state.val.reflection_mode {
    ReflectionMode::EnvironmentMap => {
      set_entity_visibility(
        world,
        reflection_probes_state.val.cubes_scene,
        false,
      )
      world
      .component(@pbr.ecs_key_environment_map_light)
      .insert(camera, create_camera_environment_map_light(), tick)
    }
    ReflectionMode::ReflectionProbe => {
      set_entity_visibility(
        world,
        reflection_probes_state.val.cubes_scene,
        true,
      )
      world
      .component(@pbr.ecs_key_environment_map_light)
      .insert(camera, create_camera_environment_map_light(), tick)
      spawn_reflection_probe(world)
    }
    ReflectionMode::GeneratedEnvironmentMap => {
      set_entity_visibility(
        world,
        reflection_probes_state.val.cubes_scene,
        false,
      )
      world
      .component(@pbr.ecs_key_generated_environment_map_light)
      .insert(
        camera,
        @pbr.GeneratedEnvironmentMapLight::new(
          reflection_probes_state.val.specular_environment_map,
          ENV_MAP_INTENSITY,
        ),
        tick,
      )
    }
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  reflection_probes_state.val.reflection_mode = ReflectionMode::ReflectionProbe
  reflection_probes_state.val.rotating = false
  reflection_probes_state.val.sphere_roughness = 0.2F
  reflection_probes_state.val.camera = None
  reflection_probes_state.val.sphere_material = None
  reflection_probes_state.val.cubes_scene = None
  reflection_probes_state.val.reflection_probe = None
  reflection_probes_state.val.help_text = None
  reflection_probes_state.val.environment_map_usage_ready = false

  let tick = world.read_change_tick()
  let asset_server = @asset.AssetServer::new()

  reflection_probes_state.val.diffuse_environment_map = Some(
    asset_server.load(DIFFUSE_ENV_MAP_ASSET),
  )
  reflection_probes_state.val.specular_environment_map = Some(
    asset_server.load(SPECULAR_ENV_MAP_ASSET),
  )
  reflection_probes_state.val.specular_reflection_probe = Some(
    asset_server.load(SPECULAR_REFLECTION_PROBE_ASSET),
  )

  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(-3.883F, 0.325F, 2.781F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  reflection_probes_state.val.camera = Some(camera)
  world.component(@pbr.ecs_key_hdr).insert(camera, @pbr.Hdr::default(), tick)
  world
  .component(@pbr.ecs_key_exposure)
  .insert(camera, @pbr.Exposure::new(11.0F), tick)
  world
  .component(@post_process.ecs_key_tonemapping)
  .insert(camera, @post_process.Tonemapping::AcesFitted, tick)
  if reflection_probes_state.val.specular_environment_map
    is Some(specular_env_map) {
    world
    .component(@pbr.ecs_key_skybox)
    .insert(camera, @pbr.Skybox::new(specular_env_map, ENV_MAP_INTENSITY), tick)
  }

  let sphere_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white())
    .with_metallic(1.0F)
    .with_perceptual_roughness(reflection_probes_state.val.sphere_roughness),
  )
  reflection_probes_state.val.sphere_material = Some(sphere_material)
  @pbr.MeshMaterial3dBundle::new(
    uv_sphere_mesh(1.0F, 20, 36),
    @pbr.MeshMaterial3d::new(sphere_material),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let cubes_scene = world.spawn_empty()
  world
  .component(@scene.ecs_key_scene_root)
  .insert(
    cubes_scene,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @gltf.GltfAssetLabel::Scene(0).from_asset(CUBES_SCENE_ASSET),
      ),
    ),
    tick,
  )
  reflection_probes_state.val.cubes_scene = Some(cubes_scene)

  let help_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(16.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, -320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::bottom_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  reflection_probes_state.val.help_text = Some(help_text)

  apply_reflection_mode(world)
  update_help_text()
}

///|
fn setup_environment_map_usage(_world : @ecs.World) -> Unit {
  if reflection_probes_state.val.environment_map_usage_ready {
    return
  }
  if reflection_probes_state.val.specular_environment_map
    is Some(specular_environment_map) {
    if !@asset.asset_image_has_usage(
        specular_environment_map,
        @asset.IMAGE_USAGE_COPY_SRC,
      ) {
      @asset.asset_image_add_usage(
        specular_environment_map,
        @asset.IMAGE_USAGE_COPY_SRC,
      )
    }
    reflection_probes_state.val.environment_map_usage_ready = true
  }
}

///|
fn cycle_reflection_mode(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Space) {
    return
  }

  reflection_probes_state.val.reflection_mode = match
    reflection_probes_state.val.reflection_mode {
    ReflectionMode::EnvironmentMap => ReflectionMode::ReflectionProbe
    ReflectionMode::ReflectionProbe => ReflectionMode::GeneratedEnvironmentMap
    ReflectionMode::GeneratedEnvironmentMap => ReflectionMode::EnvironmentMap
  }

  apply_reflection_mode(world)
  update_help_text()
}

///|
fn toggle_rotation(_world : @ecs.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Enter) {
    reflection_probes_state.val.rotating = !reflection_probes_state.val.rotating
    update_help_text()
  }
}

///|
fn change_sphere_roughness(_world : @ecs.World) -> Unit {
  let roughness_delta = if @input.key_pressed(@window.KeyCode::ArrowUp) {
    0.01F
  } else if @input.key_pressed(@window.KeyCode::ArrowDown) {
    -0.01F
  } else {
    0.0F
  }

  if roughness_delta == 0.0F {
    return
  }

  reflection_probes_state.val.sphere_roughness = clampf(
    reflection_probes_state.val.sphere_roughness + roughness_delta,
    0.0F,
    1.0F,
  )

  if reflection_probes_state.val.sphere_material is Some(handle) {
    if @pbr.standard_material_get(handle) is Some(material) {
      @pbr.standard_material_set(
        handle,
        material.with_perceptual_roughness(
          reflection_probes_state.val.sphere_roughness,
        ),
      )
      |> ignore
    }
  }

  update_help_text()
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in reflection_probes example")
  }
}

///|
fn rotate_camera(world : @ecs.World) -> Unit {
  if !reflection_probes_state.val.rotating {
    return
  }
  guard reflection_probes_state.val.camera is Some(camera) else { return }
  guard world.component(@transform.ecs_key_transform).get(camera)
    is Some(transform) else {
    return
  }

  let angle = world_time(world).delta_seconds() * PI / 5.0F
  let cos_v = @math.cos(angle)
  let sin_v = @math.sin(angle)
  let x = transform.translation.x
  let z = transform.translation.z
  let rotated_x = cos_v * x - sin_v * z
  let rotated_z = sin_v * x + cos_v * z

  world
  .component(@transform.ecs_key_transform)
  .set(
    camera,
    @transform.Transform::from_xyz(
      rotated_x,
      transform.translation.y,
      rotated_z,
    ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F)),
    world.read_change_tick(),
  )
  |> ignore
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(setup_environment_map_usage))
  .add_systems(@app.Update, @app.system(cycle_reflection_mode))
  .add_systems(@app.Update, @app.system(toggle_rotation))
  .add_systems(@app.Update, @app.system(change_sphere_roughness))
  .add_systems(@app.Update, @app.system(rotate_camera))
  .run()
}
