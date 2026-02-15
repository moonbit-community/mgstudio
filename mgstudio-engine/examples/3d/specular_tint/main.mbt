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
/// Port of `bevy/examples/3d/specular_tint.rs`.

///|
/// Baseline parity: Bevy's `Skybox`, `EnvironmentMapLight`, `Hdr`,
/// `specular_tint`, and `specular_tint_texture` surfaces are not available in
/// current mgstudio runtime APIs.

///|
/// Baseline parity: this port preserves the interaction pattern by alternating
/// between animated solid tint and texture-driven tint on `base_color`.

///|
const CAMERA_ROTATION_SPEED : Float = 0.8F

///|
const CAMERA_RADIUS : Float = 4.031128874149275F

///|
const CAMERA_START_ANGLE : Float = -0.5191461142465229F

///|
const HUE_SHIFT_SPEED : Float = 1.2F

///|
const TWO_PI : Float = 6.283185307179586F

///|
const TWO_PI_OVER_THREE : Float = 2.0943951023931953F

///|
priv struct SpecularTintState {
  mut camera : @core.Entity?
  mut camera_angle : Float
  mut hue : Float
  mut use_map : Bool
  mut material : @asset.Handle[@render3d.StandardMaterial]?
  mut noise_texture : @asset.Handle[@asset.Image]?
}

///|
let specular_tint_state : Ref[SpecularTintState] = Ref::new({
  camera: None,
  camera_angle: CAMERA_START_ANGLE,
  hue: 0.0F,
  use_map: false,
  material: None,
  noise_texture: None,
})

///|
fn tint_from_hue(hue : Float) -> @render2d.Color {
  let r = @math.sin(hue) * 0.5F + 0.5F
  let g = @math.sin(hue + TWO_PI_OVER_THREE) * 0.5F + 0.5F
  let b = @math.sin(hue + TWO_PI_OVER_THREE + TWO_PI_OVER_THREE) * 0.5F + 0.5F
  @render2d.Color::new(r, g, b, 1.0F)
}

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
  let stack_step = 3.141592653589793F / stacks_f
  let sector_step = TWO_PI / sectors_f

  for i in 0..<(stacks + 1) {
    let stack_angle = 3.141592653589793F / 2.0F - float_from_int(i) * stack_step
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
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  specular_tint_state.val.camera = None
  specular_tint_state.val.camera_angle = CAMERA_START_ANGLE
  specular_tint_state.val.hue = 0.0F
  specular_tint_state.val.use_map = false
  specular_tint_state.val.material = None

  let asset_server = @asset.AssetServer::new()
  let noise_texture = asset_server.load("textures/AlphaNoise.png")
  specular_tint_state.val.noise_texture = Some(noise_texture)

  let material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::black())
    .with_metallic(0.0F)
    .with_perceptual_roughness(0.0F),
  )
  specular_tint_state.val.material = Some(material)

  @render3d.MeshMaterial3dBundle::new(
    uv_sphere_mesh(1.0F, 18, 32),
    @render3d.MeshMaterial3d::new(material),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let point_light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    point_light,
    @render3d.PointLight::new(
      @render2d.Color::white(),
      1_000_000.0F,
      30.0F,
      true,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(point_light, @math.Transform::from_xyz(4.0F, 4.0F, 4.0F), tick)

  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(-2.0F, 0.0F, 3.5F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  specular_tint_state.val.camera = Some(camera)
}

///|
fn rotate_camera(world : @ecs_world.World) -> Unit {
  let state = specular_tint_state.val
  guard state.camera is Some(camera_entity) else { return }
  let delta = @time.time_delta_seconds()
  state.camera_angle = state.camera_angle + CAMERA_ROTATION_SPEED * delta
  let x = @math.sin(state.camera_angle) * CAMERA_RADIUS
  let z = @math.cos(state.camera_angle) * CAMERA_RADIUS
  world
  .get_transform_store()
  .set(
    camera_entity,
    @math.Transform::from_xyz(x, 0.0F, z).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    world.read_change_tick(),
  )
  |> ignore
}

///|
fn update_material(_world : @ecs_world.World) -> Unit {
  let state = specular_tint_state.val
  guard state.material is Some(material_handle) else { return }
  guard @render3d.standard_material_get(material_handle) is Some(material) else {
    return
  }

  if @input.key_just_pressed(@window.KeyCode::Space) {
    state.use_map = !state.use_map
  }

  if state.use_map {
    guard state.noise_texture is Some(texture) else { return }
    let next_material = material
      .with_base_color(@render2d.Color::white())
      .with_base_color_texture(Some(texture))
      .with_perceptual_roughness(0.1F)
    @render3d.standard_material_set(material_handle, next_material) |> ignore
  } else {
    state.hue = state.hue + HUE_SHIFT_SPEED * @time.time_delta_seconds()
    if state.hue >= TWO_PI {
      state.hue = state.hue - TWO_PI
    }
    let next_material = material
      .with_base_color(tint_from_hue(state.hue))
      .with_base_color_texture(None)
      .with_perceptual_roughness(0.0F)
    @render3d.standard_material_set(material_handle, next_material) |> ignore
  }
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(rotate_camera)
  .add_system(update_material)
  .run()
}
