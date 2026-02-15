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
/// Port of `bevy/examples/3d/shadow_caster_receiver.rs`.

///|
/// Baseline parity: Bevy's per-entity `NotShadowCaster` / `NotShadowReceiver`
/// components are not exposed in current mgstudio runtime surfaces.

///|
/// Baseline parity: key `C` toggles light shadow-map evaluation globally, and
/// key `R` toggles receiver shading through material `unlit` for target planes.

///|
const PI : Float = 3.141592653589793F

///|
const SHADOW_CASTER_RECEIVER_LIGHT_POINT_INTENSITY : Float = 1_000_000.0F

///|
const SHADOW_CASTER_RECEIVER_LIGHT_DIRECTIONAL_ILLUMINANCE : Float = 10_000.0F

///|
priv struct ShadowCasterReceiverState {
  mut directional_light : @core.Entity?
  mut point_light : @core.Entity?
  mut point_light_enabled : Bool
  mut receiver_enabled : Bool
  mut shadow_maps_enabled : Bool
  receiver_handles : Array[@asset.Handle[@render3d.StandardMaterial]]
}

///|
let shadow_caster_receiver_state : Ref[ShadowCasterReceiverState] = Ref::new({
  directional_light: None,
  point_light: None,
  point_light_enabled: false,
  receiver_enabled: true,
  shadow_maps_enabled: true,
  receiver_handles: [],
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
fn update_light_modes(world : @ecs_world.World) -> Unit {
  let state = shadow_caster_receiver_state.val
  let tick = world.read_change_tick()
  let point_store = world.get_point_light_store()
  let directional_store = world.get_directional_light_store()

  if state.point_light is Some(point_entity) {
    if point_store.get(point_entity) is Some(point_light) {
      let intensity = if state.point_light_enabled {
        SHADOW_CASTER_RECEIVER_LIGHT_POINT_INTENSITY
      } else {
        0.0F
      }
      point_store.set(
        point_entity,
        @render3d.PointLight::new(
          point_light.color,
          intensity,
          point_light.range,
          state.shadow_maps_enabled,
        ),
        tick,
      )
      |> ignore
    }
  }

  if state.directional_light is Some(directional_entity) {
    if directional_store.get(directional_entity) is Some(directional_light) {
      let illuminance = if state.point_light_enabled {
        0.0F
      } else {
        SHADOW_CASTER_RECEIVER_LIGHT_DIRECTIONAL_ILLUMINANCE
      }
      directional_store.set(
        directional_entity,
        @render3d.DirectionalLight::new(
          directional_light.color,
          illuminance,
          state.shadow_maps_enabled,
        ),
        tick,
      )
      |> ignore
    }
  }
}

///|
fn update_receiver_materials() -> Unit {
  let state = shadow_caster_receiver_state.val
  for handle in state.receiver_handles {
    if @render3d.standard_material_get(handle) is Some(material) {
      @render3d.standard_material_set(
        handle,
        material.with_unlit(!state.receiver_enabled),
      )
      |> ignore
    }
  }
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  shadow_caster_receiver_state.val.point_light = None
  shadow_caster_receiver_state.val.directional_light = None
  shadow_caster_receiver_state.val.point_light_enabled = false
  shadow_caster_receiver_state.val.shadow_maps_enabled = true
  shadow_caster_receiver_state.val.receiver_enabled = true
  shadow_caster_receiver_state.val.receiver_handles.clear()

  let spawn_height = 2.0F
  let sphere_mesh = uv_sphere_mesh(0.25F, 16, 24)
  let tick = world.read_change_tick()

  let red_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(1.0F, 0.0F, 0.0F, 1.0F),
    ),
  )
  let blue_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.0F, 0.0F, 1.0F, 1.0F),
    ),
  )
  let lime_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.0F, 1.0F, 0.0F, 1.0F),
    ),
  )
  let white_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::white()),
  )

  @render3d.MeshMaterial3dBundle::new(
    sphere_mesh,
    @render3d.MeshMaterial3d::new(red_material),
    @math.Transform::from_xyz(-1.0F, spawn_height, 0.0F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    sphere_mesh,
    @render3d.MeshMaterial3d::new(blue_material),
    @math.Transform::from_xyz(1.0F, spawn_height, 0.0F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(20.0F, 20.0F),
    @render3d.MeshMaterial3d::new(lime_material),
    @math.Transform::from_xyz(0.0F, 1.0F, -10.0F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(20.0F, 20.0F),
    @render3d.MeshMaterial3d::new(white_material),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  shadow_caster_receiver_state.val.receiver_handles.push(lime_material)
  shadow_caster_receiver_state.val.receiver_handles.push(white_material)

  let point_light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    point_light,
    @render3d.PointLight::new(@render2d.Color::white(), 0.0F, 500.0F, true),
    tick,
  )
  world
  .get_transform_store()
  .insert(point_light, @math.Transform::from_xyz(5.0F, 5.0F, 0.0F), tick)
  shadow_caster_receiver_state.val.point_light = Some(point_light)

  let directional_light = world.spawn_empty()
  world
  .get_directional_light_store()
  .insert(
    directional_light,
    @render3d.DirectionalLight::new(
      @render2d.Color::white(),
      SHADOW_CASTER_RECEIVER_LIGHT_DIRECTIONAL_ILLUMINANCE,
      true,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(
    directional_light,
    @math.Transform::from_xyz(5.0F, 5.0F, 0.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  shadow_caster_receiver_state.val.directional_light = Some(directional_light)

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(-5.0F, 5.0F, 5.0F).looking_at(
      @math.Vec3::new(-1.0F, 1.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn controls(world : @ecs_world.World) -> Unit {
  let state = shadow_caster_receiver_state.val
  let mut light_changed = false
  let mut receiver_changed = false

  if @input.key_just_pressed(@window.KeyCode::KeyL) {
    state.point_light_enabled = !state.point_light_enabled
    light_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyC) {
    state.shadow_maps_enabled = !state.shadow_maps_enabled
    light_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyR) {
    state.receiver_enabled = !state.receiver_enabled
    receiver_changed = true
  }

  if light_changed {
    update_light_modes(world)
  }
  if receiver_changed {
    update_receiver_materials()
  }
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(controls)
  .run()
}
