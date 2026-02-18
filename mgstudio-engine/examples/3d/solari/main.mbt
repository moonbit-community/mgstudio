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
/// Port of `bevy/examples/3d/solari.rs`.
///
/// Baseline parity:
/// - Keeps Bevy's scene intent and controls (`Space`, `1`, `2`) plus dynamic
///   robot patrol and many-lights stress scene switching.
/// - Solari/pathtracer/DLSS runtime pipeline is not available in mgstudio yet;
///   this example uses a raster fallback while preserving control flow.

///|
const PI : Float = 3.141592653589793F

///|
const MANY_LIGHTS_CUBE_COUNT : Int = 120

///|
const MANY_LIGHTS_EMISSIVE_COUNT : Int = 60

///|
const PATROL_SPEED : Float = 1.2F

///|
const DIRECTIONAL_ILLUMINANCE : Float = 12_000.0F

///|
const ROBOT_EMISSIVE_INTENSITY : Float = 35_000.0F

///|
const PICA_SCENE_ASSET : String = "pica_pica/mini_diorama_01.glb"

///|
const ROBOT_SCENE_ASSET : String = "pica_pica/robot_01.glb"

///|
pub(all) enum SolariSceneMode {
  PicaPica
  ManyLights
} derive(Eq, Show)

///|
priv struct SolariState {
  mut scene_mode : SolariSceneMode
  mut paused : Bool
  mut directional_enabled : Bool
  mut robot_emissive_enabled : Bool
  mut pathtracer_requested : Bool
  mut camera : @core.Entity?
  mut directional_light : @core.Entity?
  mut robot_emissive_light : @core.Entity?
  mut robot_entity : @core.Entity?
  mut control_text : @text.TextHandle?
  mut performance_text : @text.TextHandle?
  pica_entities : Array[@core.Entity]
  many_lights_entities : Array[@core.Entity]
  mut patrol_index : Int
  mut perf_accum : Float
  mut perf_frames : Int
  mut perf_fps : Float
}

///|
let solari_state : Ref[SolariState] = Ref::new({
  scene_mode: SolariSceneMode::PicaPica,
  paused: false,
  directional_enabled: true,
  robot_emissive_enabled: true,
  pathtracer_requested: false,
  camera: None,
  directional_light: None,
  robot_emissive_light: None,
  robot_entity: None,
  control_text: None,
  performance_text: None,
  pica_entities: [],
  many_lights_entities: [],
  patrol_index: 0,
  perf_accum: 0.0F,
  perf_frames: 0,
  perf_fps: 0.0F,
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
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
fn maxf(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn scene_mode_text(mode : SolariSceneMode) -> String {
  match mode {
    SolariSceneMode::PicaPica => "Pica Pica"
    SolariSceneMode::ManyLights => "Many Lights"
  }
}

///|
fn control_text_content() -> String {
  let pause_text = if solari_state.val.paused {
    "(Space): Resume"
  } else {
    "(Space): Pause"
  }
  let directional_text = if solari_state.val.directional_enabled {
    "(1): Disable directional light"
  } else {
    "(1): Enable directional light"
  }
  let emissive_text = if solari_state.val.robot_emissive_enabled {
    "(2): Disable robot emissive light"
  } else {
    "(2): Enable robot emissive light"
  }
  let pathtracer_text = if solari_state.val.pathtracer_requested {
    "(T): Pathtracer request = On"
  } else {
    "(T): Pathtracer request = Off"
  }

  "Solari (Adapted)\n" +
  "Scene: " +
  scene_mode_text(solari_state.val.scene_mode) +
  "\n" +
  pause_text +
  "\n" +
  directional_text +
  "\n" +
  emissive_text +
  "\n" +
  "(M): Switch scene mode (PicaPica/ManyLights)\n" +
  pathtracer_text +
  "\n\n" +
  "Runtime note: Solari/pathtracer/DLSS are not available; using raster fallback."
}

///|
fn performance_text_content() -> String {
  "Frame: " +
  (@time.time_delta_seconds() * 1000.0F).to_string() +
  " ms\n" +
  "FPS (CPU est): " +
  solari_state.val.perf_fps.to_string() +
  "\n" +
  "GPU Solari diagnostics: unavailable in fallback mode"
}

///|
fn update_control_text() -> Unit {
  if solari_state.val.control_text is Some(handle) {
    @text.text_set_content(handle, control_text_content())
  }
}

///|
fn update_performance_text() -> Unit {
  if solari_state.val.performance_text is Some(handle) {
    @text.text_set_content(handle, performance_text_content())
  }
}

///|
fn despawn_entities(
  world : @ecs_world.World,
  entities : Array[@core.Entity],
) -> Unit {
  for entity in entities {
    world.despawn(entity) catch {
      _ => ()
    }
  }
}

///|
fn spawn_camera(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.219417F, 2.5764852F, 6.9718704F).looking_at(
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world.get_bloom_store().insert(camera, @render3d.Bloom::new(0.1F), tick)
  solari_state.val.camera = Some(camera)
}

///|
fn spawn_lights(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()

  let directional_light = world.spawn_empty()
  world
  .get_directional_light_store()
  .insert(
    directional_light,
    @render3d.DirectionalLight::new(
      @render2d.Color::white(),
      DIRECTIONAL_ILLUMINANCE,
      false,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(
    directional_light,
    @math.Transform::from_xyz(5.0F, 10.0F, 3.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  solari_state.val.directional_light = Some(directional_light)

  let robot_emissive_light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    robot_emissive_light,
    @render3d.PointLight::new(
      @render2d.Color::new(0.94F, 0.71F, 0.04F, 1.0F),
      ROBOT_EMISSIVE_INTENSITY,
      8.0F,
      false,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(
    robot_emissive_light,
    @math.Transform::from_xyz(-2.0F, 1.7F, -2.1F),
    tick,
  )
  solari_state.val.robot_emissive_light = Some(robot_emissive_light)
}

///|
fn spawn_text(asset_server : @asset.AssetServer) -> Unit {
  let control = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(16.0F),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, -320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@render2d.Anchor::bottom_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  solari_state.val.control_text = Some(control)

  let perf = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraMono-Medium.ttf"))
      .with_font_size(11.0F),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(365.0F, 335.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@render2d.Anchor::top_right())
    .with_bounds(@text.TextBounds::new_horizontal(420.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Right))
    .with_color(
      @text.TextColor::new(@render2d.Color::new(0.88F, 0.88F, 0.88F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  solari_state.val.performance_text = Some(perf)
}

///|
fn spawn_pica_scene(
  world : @ecs_world.World,
  asset_server : @asset.AssetServer,
) -> Unit {
  let tick = world.read_change_tick()
  let diorama = world.spawn_empty()
  world
  .get_scene_root_store()
  .insert(
    diorama,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @scene.GltfAssetLabel::Scene(0).from_asset(PICA_SCENE_ASSET),
      ),
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(
    diorama,
    @math.Transform::identity().with_scale(@math.Vec3::splat(10.0F)),
    tick,
  )
  solari_state.val.pica_entities.push(diorama)

  let robot = world.spawn_empty()
  world
  .get_scene_root_store()
  .insert(
    robot,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @scene.GltfAssetLabel::Scene(0).from_asset(ROBOT_SCENE_ASSET),
      ),
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(
    robot,
    @math.Transform::from_xyz(-2.0F, 0.05F, -2.1F)
    .with_scale(@math.Vec3::splat(2.0F))
    .with_rotation(@math.Quat::from_rotation_y(PI / 2.0F)),
    tick,
  )
  solari_state.val.robot_entity = Some(robot)
  solari_state.val.pica_entities.push(robot)
  solari_state.val.patrol_index = 0
}

///|
fn spawn_many_lights_scene(world : @ecs_world.World) -> Unit {
  let ground = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(40.0F, 40.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::new(0.28F, 0.30F, 0.34F, 1.0F),
        )
        .with_perceptual_roughness(0.85F)
        .with_metallic(0.0F),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  solari_state.val.many_lights_entities.push(ground)

  for i in 0..<MANY_LIGHTS_CUBE_COUNT {
    let fi = float_from_int(i)
    let x = @math.sin(fi * 1.73F) * 18.0F
    let z = @math.cos(fi * 1.29F) * 18.0F
    let sx = 0.3F + (0.5F + 0.5F * @math.sin(fi * 0.77F)) * 1.7F
    let sy = 0.3F + (0.5F + 0.5F * @math.sin(fi * 1.11F + 0.8F)) * 1.7F
    let sz = 0.3F + (0.5F + 0.5F * @math.sin(fi * 1.41F + 1.6F)) * 1.7F
    let color = @render2d.Color::new(
      0.2F + 0.8F * (0.5F + 0.5F * @math.sin(fi * 0.31F)),
      0.2F + 0.8F * (0.5F + 0.5F * @math.sin(fi * 0.47F + 1.0F)),
      0.2F + 0.8F * (0.5F + 0.5F * @math.sin(fi * 0.53F + 2.0F)),
      1.0F,
    )
    let entity = @render3d.MeshMaterial3dBundle::new(
      @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
      @render3d.MeshMaterial3d::new(
        @render3d.standard_material_add(
          @render3d.StandardMaterial::from_color(color).with_perceptual_roughness(
            0.2F + 0.75F * absf(@math.sin(fi * 0.92F)),
          ),
        ),
      ),
      @math.Transform::from_xyz(x, 0.2F, z).with_scale(
        @math.Vec3::new(sx, sy, sz),
      ),
    ).spawn(world)
    solari_state.val.many_lights_entities.push(entity)
  }

  for i in 0..<MANY_LIGHTS_EMISSIVE_COUNT {
    let fi = float_from_int(i)
    let entity = @render3d.MeshMaterial3dBundle::new(
      @render3d.Mesh3d::from_tetrahedron(0.5F),
      @render3d.MeshMaterial3d::new(
        @render3d.standard_material_add(
          @render3d.StandardMaterial::from_color(@render2d.Color::black()).with_emissive(
            @render2d.Color::new(
              8.0F + 22.0F * (0.5F + 0.5F * @math.sin(fi * 0.37F + 0.2F)),
              8.0F + 22.0F * (0.5F + 0.5F * @math.sin(fi * 0.41F + 1.1F)),
              8.0F + 22.0F * (0.5F + 0.5F * @math.sin(fi * 0.59F + 2.0F)),
              1.0F,
            ),
          ),
        ),
      ),
      @math.Transform::from_xyz(
        @math.sin(fi * 0.81F) * 17.5F,
        5.5F + 3.0F * (0.5F + 0.5F * @math.sin(fi * 1.33F)),
        @math.cos(fi * 0.67F) * 17.5F,
      ),
    ).spawn(world)
    solari_state.val.many_lights_entities.push(entity)
  }

  if solari_state.val.camera is Some(camera) {
    world
    .get_transform_store()
    .set(
      camera,
      @math.Transform::from_xyz(0.0919233F, 7.5015035F, 28.449198F).looking_at(
        @math.Vec3::new(0.0F, 0.0F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
      world.read_change_tick(),
    )
    |> ignore
  }
}

///|
fn clear_scene(world : @ecs_world.World) -> Unit {
  despawn_entities(world, solari_state.val.pica_entities)
  despawn_entities(world, solari_state.val.many_lights_entities)
  solari_state.val.pica_entities.clear()
  solari_state.val.many_lights_entities.clear()
  solari_state.val.robot_entity = None
  solari_state.val.patrol_index = 0
}

///|
fn apply_scene_mode(
  world : @ecs_world.World,
  asset_server : @asset.AssetServer,
) -> Unit {
  clear_scene(world)
  match solari_state.val.scene_mode {
    SolariSceneMode::PicaPica => {
      spawn_pica_scene(world, asset_server)
      if solari_state.val.camera is Some(camera) {
        world
        .get_transform_store()
        .set(
          camera,
          @math.Transform::from_xyz(0.219417F, 2.5764852F, 6.9718704F).looking_at(
            @math.Vec3::new(0.0F, 1.0F, 0.0F),
            @math.Vec3::new(0.0F, 1.0F, 0.0F),
          ),
          world.read_change_tick(),
        )
        |> ignore
      }
    }
    SolariSceneMode::ManyLights => spawn_many_lights_scene(world)
  }
}

///|
fn apply_light_switches(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  if solari_state.val.directional_light is Some(light) {
    if world.get_directional_light_store().get(light) is Some(current) {
      let updated = current.with_illuminance(
        if solari_state.val.directional_enabled {
          DIRECTIONAL_ILLUMINANCE
        } else {
          0.0F
        },
      )
      world.get_directional_light_store().set(light, updated, tick) |> ignore
    }
  }

  if solari_state.val.robot_emissive_light is Some(light) {
    if world.get_point_light_store().get(light) is Some(current) {
      let updated = current.with_intensity(
        if solari_state.val.robot_emissive_enabled {
          ROBOT_EMISSIVE_INTENSITY
        } else {
          0.0F
        },
      )
      world.get_point_light_store().set(light, updated, tick) |> ignore
    }
  }
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  solari_state.val.scene_mode = SolariSceneMode::PicaPica
  solari_state.val.paused = false
  solari_state.val.directional_enabled = true
  solari_state.val.robot_emissive_enabled = true
  solari_state.val.pathtracer_requested = false
  solari_state.val.camera = None
  solari_state.val.directional_light = None
  solari_state.val.robot_emissive_light = None
  solari_state.val.robot_entity = None
  solari_state.val.control_text = None
  solari_state.val.performance_text = None
  solari_state.val.pica_entities.clear()
  solari_state.val.many_lights_entities.clear()
  solari_state.val.patrol_index = 0
  solari_state.val.perf_accum = 0.0F
  solari_state.val.perf_frames = 0
  solari_state.val.perf_fps = 0.0F

  let asset_server = @asset.AssetServer::new()
  spawn_camera(world)
  spawn_lights(world)
  spawn_text(asset_server)
  apply_scene_mode(world, asset_server)
  apply_light_switches(world)
  update_control_text()
  update_performance_text()
}

///|
fn pause_scene(_world : @ecs_world.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Space) {
    solari_state.val.paused = !solari_state.val.paused
    update_control_text()
  }
}

///|
fn toggle_lights(world : @ecs_world.World) -> Unit {
  let mut changed = false
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    solari_state.val.directional_enabled = !solari_state.val.directional_enabled
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    solari_state.val.robot_emissive_enabled = !solari_state.val.robot_emissive_enabled
    changed = true
  }
  if changed {
    apply_light_switches(world)
    update_control_text()
  }
}

///|
fn toggle_pathtracer_request(_world : @ecs_world.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::KeyT) {
    solari_state.val.pathtracer_requested = !solari_state.val.pathtracer_requested
    update_control_text()
  }
}

///|
fn switch_scene_mode(world : @ecs_world.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::KeyM) {
    return
  }

  solari_state.val.scene_mode = match solari_state.val.scene_mode {
    SolariSceneMode::PicaPica => SolariSceneMode::ManyLights
    SolariSceneMode::ManyLights => SolariSceneMode::PicaPica
  }

  let asset_server = @asset.AssetServer::new()
  apply_scene_mode(world, asset_server)
  update_control_text()
}

///|
fn patrol_path(world : @ecs_world.World) -> Unit {
  if solari_state.val.scene_mode != SolariSceneMode::PicaPica {
    return
  }
  if solari_state.val.paused {
    return
  }
  guard solari_state.val.robot_entity is Some(robot) else { return }
  guard world.get_transform_store().get(robot) is Some(transform) else {
    return
  }

  let path : Array[(@math.Vec3, @math.Quat)] = [
    (
      @math.Vec3::new(-2.0F, 0.05F, -2.1F),
      @math.Quat::from_rotation_y(PI / 2.0F),
    ),
    (@math.Vec3::new(2.2F, 0.05F, -2.1F), @math.Quat::from_rotation_y(0.0F)),
    (
      @math.Vec3::new(2.2F, 0.05F, 2.1F),
      @math.Quat::from_rotation_y(3.0F * PI / 2.0F),
    ),
    (@math.Vec3::new(-2.0F, 0.05F, 2.1F), @math.Quat::from_rotation_y(PI)),
  ]

  let target = path[solari_state.val.patrol_index]
  let to_target = target.0.sub(transform.translation)
  let distance = to_target.length()
  let max_step = PATROL_SPEED * @time.time_delta_seconds()
  let tick = world.read_change_tick()

  if distance <= max_step || distance < 0.01F {
    world
    .get_transform_store()
    .set(
      robot,
      transform.with_translation(target.0).with_rotation(target.1),
      tick,
    )
    |> ignore
    solari_state.val.patrol_index = (solari_state.val.patrol_index + 1) %
      path.length()
  } else {
    world
    .get_transform_store()
    .set(
      robot,
      transform.with_translation(
        transform.translation.add(
          to_target.normalize_or_zero().mul_scalar(max_step),
        ),
      ),
      tick,
    )
    |> ignore
  }
}

///|
fn sync_robot_emissive_light(world : @ecs_world.World) -> Unit {
  guard solari_state.val.robot_entity is Some(robot) else { return }
  guard solari_state.val.robot_emissive_light is Some(light) else { return }
  guard world.get_transform_store().get(robot) is Some(robot_transform) else {
    return
  }

  world
  .get_transform_store()
  .set(
    light,
    @math.Transform::from_xyz(
      robot_transform.translation.x,
      robot_transform.translation.y + 1.6F,
      robot_transform.translation.z,
    ),
    world.read_change_tick(),
  )
  |> ignore
}

///|
fn update_performance(_world : @ecs_world.World) -> Unit {
  let delta = maxf(@time.time_delta_seconds(), 1.0e-6F)
  solari_state.val.perf_accum = solari_state.val.perf_accum + delta
  solari_state.val.perf_frames = solari_state.val.perf_frames + 1
  if solari_state.val.perf_accum >= 0.5F {
    solari_state.val.perf_fps = float_from_int(solari_state.val.perf_frames) /
      solari_state.val.perf_accum
    solari_state.val.perf_accum = 0.0F
    solari_state.val.perf_frames = 0
  }
  update_performance_text()
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(pause_scene)
  .add_system(toggle_lights)
  .add_system(toggle_pathtracer_request)
  .add_system(switch_scene_mode)
  .add_system(patrol_path)
  .add_system(sync_robot_emissive_light)
  .add_system(update_performance)
  .run()
}
