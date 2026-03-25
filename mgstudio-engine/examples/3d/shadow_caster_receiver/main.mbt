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
}

///|
let shadow_caster_receiver_state : Ref[ShadowCasterReceiverState] = Ref::new({
  directional_light: None,
  point_light: None,
  point_light_enabled: false,
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
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

  @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(
        @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
      ),
    ),
  )
}

///|
fn update_light_modes(world : @ecs.World) -> Unit {
  let state = shadow_caster_receiver_state.val

  if state.point_light is Some(point_entity) {
    if (try! world.get_by_key(point_entity, @pbr.ecs_key_point_light))
      is Some(point_light) {
      let intensity = if state.point_light_enabled {
        SHADOW_CASTER_RECEIVER_LIGHT_POINT_INTENSITY
      } else {
        0.0F
      }
      try! (world.replace(
        point_entity,
        @pbr.ecs_key_point_light,
        @pbr.PointLight::new(
          point_light.color,
          intensity,
          point_light.range,
          point_light.shadow_maps_enabled,
        ),
      )
      |> ignore)
    }
  }

  if state.directional_light is Some(directional_entity) {
    if (try! world.get_by_key(
        directional_entity, @pbr.ecs_key_directional_light,
      ))
      is Some(directional_light) {
      let illuminance = if state.point_light_enabled {
        0.0F
      } else {
        SHADOW_CASTER_RECEIVER_LIGHT_DIRECTIONAL_ILLUMINANCE
      }
      try! (world.replace(
        directional_entity,
        @pbr.ecs_key_directional_light,
        @pbr.DirectionalLight::new(
          directional_light.color,
          illuminance,
          directional_light.shadow_maps_enabled,
        ),
      )
      |> ignore)
    }
  }
}

///|
fn toggle_shadow_casters(world : @ecs.World) -> Unit {
  let make_shadow_caster : Array[@core.Entity] = []
  let make_not_shadow_caster : Array[@core.Entity] = []

  world.for_each_component(@pbr.ecs_key_mesh3d, fn(entity, _mesh) {
    if (try! world.contains_by_key(entity, @pbr.ecs_key_not_shadow_caster)) {
      make_shadow_caster.push(entity)
    } else {
      make_not_shadow_caster.push(entity)
    }
  })

  for entity in make_shadow_caster {
    try! (world.take(entity, @pbr.ecs_key_not_shadow_caster) |> ignore)
  }
  for entity in make_not_shadow_caster {
    try! world.set_by_key(
      entity,
      @pbr.ecs_key_not_shadow_caster,
      @pbr.NotShadowCaster::default(),
    )
  }
}

///|
fn toggle_shadow_receivers(world : @ecs.World) -> Unit {
  let make_shadow_receiver : Array[@core.Entity] = []
  let make_not_shadow_receiver : Array[@core.Entity] = []

  world.for_each_component(@pbr.ecs_key_mesh3d, fn(entity, _mesh) {
    if (try! world.contains_by_key(entity, @pbr.ecs_key_not_shadow_receiver)) {
      make_shadow_receiver.push(entity)
    } else {
      make_not_shadow_receiver.push(entity)
    }
  })

  for entity in make_shadow_receiver {
    try! (world.take(entity, @pbr.ecs_key_not_shadow_receiver) |> ignore)
  }
  for entity in make_not_shadow_receiver {
    try! world.set_by_key(
      entity,
      @pbr.ecs_key_not_shadow_receiver,
      @pbr.NotShadowReceiver::default(),
    )
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  shadow_caster_receiver_state.val.point_light = None
  shadow_caster_receiver_state.val.directional_light = None
  shadow_caster_receiver_state.val.point_light_enabled = false

  let spawn_height = 2.0F
  let sphere_mesh = uv_sphere_mesh(0.25F, 16, 24)

  let red_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F),
    ),
  )
  let blue_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.0F, 0.0F, 1.0F, 1.0F),
    ),
  )
  let lime_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.0F, 1.0F, 0.0F, 1.0F),
    ),
  )
  let white_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white()).with_perceptual_roughness(
      1.0F,
    ),
  )

  let red_sphere = @pbr.MeshMaterial3dBundle::new(
    sphere_mesh,
    @pbr.MeshMaterial3d::new(red_material),
    @transform.Transform::from_xyz(-1.0F, spawn_height, 0.0F),
  ).spawn(world)
  red_sphere |> ignore

  let blue_sphere = @pbr.MeshMaterial3dBundle::new(
    sphere_mesh,
    @pbr.MeshMaterial3d::new(blue_material),
    @transform.Transform::from_xyz(1.0F, spawn_height, 0.0F),
  ).spawn(world)
  try! world.set_by_key(
    blue_sphere,
    @pbr.ecs_key_not_shadow_caster,
    @pbr.NotShadowCaster::default(),
  )

  let floating_plane = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(20.0F, 20.0F)),
      ),
    ),
    @pbr.MeshMaterial3d::new(lime_material),
    @transform.Transform::from_xyz(0.0F, 1.0F, -10.0F),
  ).spawn(world)
  try! world.set_by_key(
    floating_plane,
    @pbr.ecs_key_not_shadow_caster,
    @pbr.NotShadowCaster::default(),
  )
  try! world.set_by_key(
    floating_plane,
    @pbr.ecs_key_not_shadow_receiver,
    @pbr.NotShadowReceiver::default(),
  )

  let ground_plane = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(20.0F, 20.0F)),
      ),
    ),
    @pbr.MeshMaterial3d::new(white_material),
    @transform.Transform::identity(),
  ).spawn(world)
  ground_plane |> ignore

  let point_light = world.spawn_empty()
  try! world.set_by_key(
    point_light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::new(@sprite.Color::white(), 0.0F, 500.0F, true),
  )
  try! world.set_by_key(
    point_light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(5.0F, 5.0F, 0.0F),
  )
  shadow_caster_receiver_state.val.point_light = Some(point_light)

  let directional_light = world.spawn_empty()
  let cascade_shadow_config = @pbr.CascadeShadowConfigBuilder::default()
    .with_first_cascade_far_bound(7.0F)
    .with_maximum_distance(25.0F)
    .build()
  try! world.set_by_key(
    directional_light,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::new(
      @sprite.Color::white(),
      SHADOW_CASTER_RECEIVER_LIGHT_DIRECTIONAL_ILLUMINANCE,
      true,
    ).with_cascade_shadow_config(Some(cascade_shadow_config)),
  )
  try! world.set_by_key(
    directional_light,
    @transform.ecs_key_transform,
    @transform.Transform::identity().with_rotation(
      @math.Quat::from_rotation_y(PI / 2.0F).mul(
        @math.Quat::from_rotation_x(-PI / 4.0F),
      ),
    ),
  )
  shadow_caster_receiver_state.val.directional_light = Some(directional_light)

  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(-5.0F, 5.0F, 5.0F).looking_at(
      @math.Vec3::new(-1.0F, 1.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn controls(world : @ecs.World) -> Unit {
  let state = shadow_caster_receiver_state.val
  if @input.key_just_pressed(@window.KeyCode::KeyL) {
    state.point_light_enabled = !state.point_light_enabled
    update_light_modes(world)
  }

  if @input.key_just_pressed(@window.KeyCode::KeyC) {
    toggle_shadow_casters(world)
  }

  if @input.key_just_pressed(@window.KeyCode::KeyR) {
    toggle_shadow_receivers(world)
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(controls))
  .run()
}
