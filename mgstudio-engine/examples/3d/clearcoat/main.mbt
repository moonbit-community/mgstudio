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
/// Port of `bevy/examples/3d/clearcoat.rs`.
///
/// Baseline parity: `Hdr`, `Skybox`, `EnvironmentMapLight`, and image load
/// color-space settings are not exposed in current mgstudio APIs.

///|
const PI : Float = 3.141592653589793F

///|
const SPHERE_SCALE : Float = 0.9F

///|
const SPHERE_ROTATION_SPEED : Float = 0.8F

///|
priv struct ClearcoatState {
  sphere_entities : Array[@core.Entity]
  sphere_positions : Array[@math.Vec3]
  mut light_mode : Int
  mut point_light : @core.Entity?
  mut directional_light : @core.Entity?
}

///|
let clearcoat_state : Ref[ClearcoatState] = Ref::new({
  sphere_entities: [],
  sphere_positions: [],
  light_mode: 0,
  point_light: None,
  directional_light: None,
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn uv_sphere_mesh(
  radius : Float,
  stacks : Int,
  sectors : Int,
) -> @render3d.Mesh3d {
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

  @render3d.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
  )
}

///|
fn apply_light_mode(world : @ecs_world.World) -> Unit {
  let state = clearcoat_state.val
  let tick = world.read_change_tick()

  if state.point_light is Some(entity) {
    let intensity = if state.light_mode == 0 { 80_000.0F } else { 0.0F }
    world
    .get_point_light_store()
    .set(
      entity,
      @render3d.PointLight::new(
        @render2d.Color::white(),
        intensity,
        30.0F,
        true,
      ),
      tick,
    )
    |> ignore
  }

  if state.directional_light is Some(entity) {
    let illuminance = if state.light_mode == 1 { 12_000.0F } else { 0.0F }
    world
    .get_directional_light_store()
    .set(
      entity,
      @render3d.DirectionalLight::new(
        @render2d.Color::white(),
        illuminance,
        true,
      ),
      tick,
    )
    |> ignore
  }
}

///|
fn spawn_sphere(
  world : @ecs_world.World,
  mesh : @render3d.Mesh3d,
  material : @asset.Handle[@render3d.StandardMaterial],
  position : @math.Vec3,
) -> Unit {
  let entity = @render3d.MeshMaterial3dBundle::new(
    mesh,
    @render3d.MeshMaterial3d::new(material),
    @math.Transform::from_xyz(position.x, position.y, position.z).with_scale(
      @math.Vec3::splat(SPHERE_SCALE),
    ),
  ).spawn(world)
  clearcoat_state.val.sphere_entities.push(entity)
  clearcoat_state.val.sphere_positions.push(position)
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  clearcoat_state.val.sphere_entities.clear()
  clearcoat_state.val.sphere_positions.clear()
  clearcoat_state.val.light_mode = 0
  clearcoat_state.val.point_light = None
  clearcoat_state.val.directional_light = None

  let asset_server = @asset.AssetServer::new()
  let sphere = uv_sphere_mesh(1.0F, 24, 48)

  let blue_noise = asset_server.load("textures/BlueNoise-Normal.png")
  let scratched_gold = asset_server.load("textures/ScratchedGold-Normal.png")

  let car_paint = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.12F, 0.32F, 0.9F, 1.0F),
    )
    .with_clearcoat(1.0F)
    .with_clearcoat_perceptual_roughness(0.1F)
    .with_normal_map_texture(Some(blue_noise))
    .with_metallic(0.9F)
    .with_perceptual_roughness(0.5F),
  )
  spawn_sphere(world, sphere, car_paint, @math.Vec3::new(-1.0F, 1.0F, 0.0F))

  let coated_glass = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.9F, 0.9F, 0.9F, 0.3F),
    )
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_clearcoat(1.0F)
    .with_clearcoat_perceptual_roughness(0.1F)
    .with_metallic(0.5F)
    .with_perceptual_roughness(0.1F),
  )
  spawn_sphere(world, sphere, coated_glass, @math.Vec3::new(-1.0F, -1.0F, 0.0F))

  let scratched_gold_ball = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(1.0F, 0.843F, 0.0F, 1.0F),
    )
    .with_clearcoat(1.0F)
    .with_clearcoat_perceptual_roughness(0.3F)
    .with_clearcoat_normal_texture(Some(scratched_gold))
    .with_metallic(0.9F)
    .with_perceptual_roughness(0.1F),
  )
  spawn_sphere(
    world,
    sphere,
    scratched_gold_ball,
    @math.Vec3::new(1.0F, -1.0F, 0.0F),
  )

  let golf_ball_root = world.spawn_empty()
  world
  .get_scene_root_store()
  .insert(
    golf_ball_root,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @scene.GltfAssetLabel::Scene(0).from_asset(
          "models/GolfBall/GolfBall.glb",
        ),
      ),
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(
    golf_ball_root,
    @math.Transform::from_xyz(1.0F, 1.0F, 0.0F).with_scale(
      @math.Vec3::splat(SPHERE_SCALE),
    ),
    tick,
  )
  clearcoat_state.val.sphere_entities.push(golf_ball_root)
  clearcoat_state.val.sphere_positions.push(@math.Vec3::new(1.0F, 1.0F, 0.0F))

  let point_light = world.spawn_empty()
  world
  .get_transform_store()
  .insert(
    point_light,
    @math.Transform::from_xyz(3.0F, 4.0F, 3.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  clearcoat_state.val.point_light = Some(point_light)

  let directional_light = world.spawn_empty()
  world
  .get_transform_store()
  .insert(
    directional_light,
    @math.Transform::from_xyz(3.0F, 4.0F, 3.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  clearcoat_state.val.directional_light = Some(directional_light)

  apply_light_mode(world)

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.0F, 0.0F, 10.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn animate_light(world : @ecs_world.World) -> Unit {
  let now = @time.time_elapsed_seconds()
  let light_pos = @math.Vec3::new(
    @math.sin(now * 1.4F) * 3.0F,
    @math.cos(now * 1.0F) * 4.0F,
    @math.cos(now * 0.6F) * 3.0F,
  )
  let target = @math.Vec3::zero()
  let up = @math.Vec3::new(0.0F, 1.0F, 0.0F)
  let tick = world.read_change_tick()

  if clearcoat_state.val.point_light is Some(entity) {
    world
    .get_transform_store()
    .set(
      entity,
      @math.Transform::from_xyz(light_pos.x, light_pos.y, light_pos.z).looking_at(
        target, up,
      ),
      tick,
    )
    |> ignore
  }

  if clearcoat_state.val.directional_light is Some(entity) {
    world
    .get_transform_store()
    .set(
      entity,
      @math.Transform::from_xyz(light_pos.x, light_pos.y, light_pos.z).looking_at(
        target, up,
      ),
      tick,
    )
    |> ignore
  }
}

///|
fn animate_spheres(world : @ecs_world.World) -> Unit {
  let angle = SPHERE_ROTATION_SPEED * @time.time_elapsed_seconds()
  let rotation = @math.Quat::from_rotation_y(angle)
  let tick = world.read_change_tick()
  let count = clearcoat_state.val.sphere_entities.length()
  for i in 0..<count {
    let entity = clearcoat_state.val.sphere_entities[i]
    let position = clearcoat_state.val.sphere_positions[i]
    world
    .get_transform_store()
    .set(
      entity,
      @math.Transform::from_xyz(position.x, position.y, position.z)
      .with_rotation(rotation)
      .with_scale(@math.Vec3::splat(SPHERE_SCALE)),
      tick,
    )
    |> ignore
  }
}

///|
fn handle_input(world : @ecs_world.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Space) {
    return
  }
  if clearcoat_state.val.light_mode == 0 {
    clearcoat_state.val.light_mode = 1
  } else {
    clearcoat_state.val.light_mode = 0
  }
  apply_light_mode(world)
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(animate_light)
  .add_system(animate_spheres)
  .add_system(handle_input)
  .run()
}
