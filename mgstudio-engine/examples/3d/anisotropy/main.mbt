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
/// Port of `bevy/examples/3d/anisotropy.rs`.
///
/// Baseline parity: `Skybox`/`EnvironmentMapLight` are not exposed in current
/// mgstudio APIs. Anisotropy shading is approximated in the current render path.

///|
const PI : Float = 3.141592653589793F

///|
const CAMERA_INITIAL_X : Float = -0.4F

///|
const CAMERA_INITIAL_Y : Float = 0.0F

///|
const CAMERA_INITIAL_Z : Float = 0.0F

///|
priv struct AnisotropyState {
  mut light_mode : Int
  mut anisotropy_enabled : Bool
  mut visible_scene : Int
  mut environment_angle : Float
  mut camera : @core.Entity?
  mut directional_light : @core.Entity?
  mut point_light : @core.Entity?
  mut barn_lamp_scene : @core.Entity?
  mut sphere_scene : @core.Entity?
  mut sphere_anisotropic_material : @asset.Handle[@render3d.StandardMaterial]?
  mut sphere_isotropic_material : @asset.Handle[@render3d.StandardMaterial]?
}

///|
let anisotropy_state : Ref[AnisotropyState] = Ref::new({
  light_mode: 0,
  anisotropy_enabled: true,
  visible_scene: 0,
  environment_angle: 0.0F,
  camera: None,
  directional_light: None,
  point_light: None,
  barn_lamp_scene: None,
  sphere_scene: None,
  sphere_anisotropic_material: None,
  sphere_isotropic_material: None,
})

///|
fn camera_initial_position() -> @math.Vec3 {
  @math.Vec3::new(CAMERA_INITIAL_X, CAMERA_INITIAL_Y, CAMERA_INITIAL_Z)
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
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
fn apply_scene_visibility(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let visibility_store = world.get_visibility_store()

  if anisotropy_state.val.barn_lamp_scene is Some(entity) {
    visibility_store.set(
      entity,
      if anisotropy_state.val.visible_scene == 0 {
        @visibility.Visibility::Inherited
      } else {
        @visibility.Visibility::Hidden
      },
      tick,
    )
    |> ignore
  }

  if anisotropy_state.val.sphere_scene is Some(entity) {
    visibility_store.set(
      entity,
      if anisotropy_state.val.visible_scene == 1 {
        @visibility.Visibility::Inherited
      } else {
        @visibility.Visibility::Hidden
      },
      tick,
    )
    |> ignore
  }
}

///|
fn apply_light_mode(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  if anisotropy_state.val.directional_light is Some(entity) {
    let illuminance = if anisotropy_state.val.light_mode == 0 {
      3000.0F
    } else {
      0.0F
    }
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

  if anisotropy_state.val.point_light is Some(entity) {
    let intensity = if anisotropy_state.val.light_mode == 1 {
      200_000.0F
    } else {
      0.0F
    }
    world
    .get_point_light_store()
    .set(
      entity,
      @render3d.PointLight::new(
        @render2d.Color::white(),
        intensity,
        50.0F,
        true,
      ),
      tick,
    )
    |> ignore
  }
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  anisotropy_state.val.light_mode = 0
  anisotropy_state.val.anisotropy_enabled = true
  anisotropy_state.val.visible_scene = 0
  anisotropy_state.val.environment_angle = 0.0F
  anisotropy_state.val.camera = None
  anisotropy_state.val.directional_light = None
  anisotropy_state.val.point_light = None
  anisotropy_state.val.barn_lamp_scene = None
  anisotropy_state.val.sphere_scene = None
  anisotropy_state.val.sphere_anisotropic_material = None
  anisotropy_state.val.sphere_isotropic_material = None

  let asset_server = @asset.AssetServer::new()

  let camera_entity = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(
      CAMERA_INITIAL_X,
      CAMERA_INITIAL_Y,
      CAMERA_INITIAL_Z,
    ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F)),
  ).spawn(world)
  anisotropy_state.val.camera = Some(camera_entity)

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
  anisotropy_state.val.directional_light = Some(directional_light)

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
  anisotropy_state.val.point_light = Some(point_light)

  let barn_lamp = world.spawn_empty()
  world
  .get_scene_root_store()
  .insert(
    barn_lamp,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @scene.GltfAssetLabel::Scene(0).from_asset(
          "models/AnisotropyBarnLamp/AnisotropyBarnLamp.gltf",
        ),
      ),
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(barn_lamp, @math.Transform::from_xyz(0.0F, 0.07F, -0.13F), tick)
  world
  .get_visibility_store()
  .insert(barn_lamp, @visibility.Visibility::Inherited, tick)
  anisotropy_state.val.barn_lamp_scene = Some(barn_lamp)

  let sphere_material_base = @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.8F, 0.8F, 0.8F, 1.0F),
    )
    .with_metallic(1.0F)
    .with_perceptual_roughness(0.5F)
  let anisotropic_material = @render3d.standard_material_add(
    sphere_material_base
    .with_anisotropy_rotation(0.5F)
    .with_anisotropy_strength(1.0F),
  )
  let isotropic_material = @render3d.standard_material_add(
    sphere_material_base
    .with_anisotropy_rotation(0.0F)
    .with_anisotropy_strength(0.0F)
    .with_anisotropy_texture(None),
  )
  anisotropy_state.val.sphere_anisotropic_material = Some(anisotropic_material)
  anisotropy_state.val.sphere_isotropic_material = Some(isotropic_material)

  let sphere = @render3d.MeshMaterial3dBundle::new(
    uv_sphere_mesh(0.1F, 20, 36),
    @render3d.MeshMaterial3d::new(anisotropic_material),
    @math.Transform::identity(),
  ).spawn(world)
  world
  .get_visibility_store()
  .insert(sphere, @visibility.Visibility::Hidden, tick)
  anisotropy_state.val.sphere_scene = Some(sphere)

  apply_light_mode(world)
  apply_scene_visibility(world)
}

///|
fn animate_light(world : @ecs_world.World) -> Unit {
  if anisotropy_state.val.light_mode == 2 {
    return
  }
  let now = @time.time_elapsed_seconds()
  let light_position = @math.Vec3::new(
    @math.cos(now) * 3.0F,
    4.0F,
    @math.sin(now) * 3.0F,
  )
  let next_transform = @math.Transform::from_xyz(
    light_position.x,
    light_position.y,
    light_position.z,
  ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F))

  let tick = world.read_change_tick()
  if anisotropy_state.val.directional_light is Some(entity) {
    world.get_transform_store().set(entity, next_transform, tick) |> ignore
  }
  if anisotropy_state.val.point_light is Some(entity) {
    world.get_transform_store().set(entity, next_transform, tick) |> ignore
  }
}

///|
fn rotate_camera(world : @ecs_world.World) -> Unit {
  if anisotropy_state.val.light_mode == 2 {
    anisotropy_state.val.environment_angle = anisotropy_state.val.environment_angle +
      @time.time_delta_seconds()
  }

  if anisotropy_state.val.camera is Some(entity) {
    let rotated_position = quat_rotate_vec3(
      @math.Quat::from_rotation_y(anisotropy_state.val.environment_angle),
      camera_initial_position(),
    )
    let tick = world.read_change_tick()
    world
    .get_transform_store()
    .set(
      entity,
      @math.Transform::from_xyz(
        rotated_position.x,
        rotated_position.y,
        rotated_position.z,
      ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F)),
      tick,
    )
    |> ignore
  }
}

///|
fn toggle_anisotropy(world : @ecs_world.World) -> Unit {
  anisotropy_state.val.anisotropy_enabled = !anisotropy_state.val.anisotropy_enabled

  guard anisotropy_state.val.sphere_scene is Some(entity) else { return }
  guard anisotropy_state.val.sphere_anisotropic_material is Some(anisotropic) else {
    return
  }
  guard anisotropy_state.val.sphere_isotropic_material is Some(isotropic) else {
    return
  }

  let next_material = if anisotropy_state.val.anisotropy_enabled {
    anisotropic
  } else {
    isotropic
  }
  world
  .get_mesh_material3d_store()
  .set(
    entity,
    @render3d.MeshMaterial3d::new(next_material),
    world.read_change_tick(),
  )
  |> ignore
}

///|
fn handle_input(world : @ecs_world.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Space) {
    anisotropy_state.val.light_mode = (anisotropy_state.val.light_mode + 1) % 3
    apply_light_mode(world)
  }

  if @input.key_just_pressed(@window.KeyCode::Enter) {
    toggle_anisotropy(world)
  }

  if @input.key_just_pressed(@window.KeyCode::KeyQ) {
    anisotropy_state.val.visible_scene = (
        anisotropy_state.val.visible_scene + 1
      ) %
      2
    apply_scene_visibility(world)
  }
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(animate_light)
  .add_system(rotate_camera)
  .add_system(handle_input)
  .run()
}
