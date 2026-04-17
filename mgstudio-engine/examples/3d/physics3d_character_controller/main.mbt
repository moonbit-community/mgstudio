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
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.FixedUpdate, @app.system(controller_input))
  .run()
}

///|
let player_entity : Ref[@core.Entity?] = Ref::new(None)

///|
fn setup(world : @ecs.World) -> Unit {
  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(
      @sprite.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
      0.45F,
    ),
  )
  let light = world.spawn_empty()
  try! world.set_by_key(
    light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::new(@sprite.Color::white(), 5000.0F, 30.0F, false),
  )
  try! world.set_by_key(
    light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(5.0F, 7.0F, 5.0F),
  )

  let ground_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.24F, 0.26F, 0.30F, 1.0F),
    ).with_unlit(true),
  )
  let ground = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(24.0F, 1.0F, 24.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(ground_material),
    @transform.Transform::from_xyz(0.0F, -0.5F, 0.0F),
  ).spawn(world)
  try! world.set_by_key(
    ground,
    @physics3d.ecs_key_rigid_body3d,
    @physics3d.RigidBody3d::fixed(),
  )
  try! world.set_by_key(
    ground,
    @physics3d.ecs_key_collider3d,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::cuboid(12.0F, 0.5F, 12.0F),
    ),
  )

  let player_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.95F, 0.72F, 0.22F, 1.0F),
    ).with_unlit(true),
  )
  let player = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_capsule(@math.Capsule3d::new(0.35F, 0.75F)),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(player_material),
    @transform.Transform::from_xyz(0.0F, 1.0F, 0.0F),
  ).spawn(world)
  try! world.set_by_key(
    player,
    @physics3d.ecs_key_collider3d,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::capsule_y(0.35F, 0.75F),
    ),
  )
  try! world.set_by_key(
    player,
    @physics3d.ecs_key_kinematic_character_controller3d,
    @physics3d.KinematicCharacterController3d::default(),
  )
  player_entity.val = Some(player)

  @camera.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(0.0F, 5.0F, 8.0F).looking_at(
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
  println("[physics3d_character_controller] WASD to move capsule controller")
}

///|
fn controller_input(world : @ecs.World) -> Unit {
  guard player_entity.val is Some(player) else { return }
  guard (try! world.get_by_key(
      player, @physics3d.ecs_key_kinematic_character_controller3d,
    ))
    is Some(kcc) else {
    return
  }
  let dt = @time.time_fixed_timestep_seconds()
  let speed = 4.0F
  let mut axis = @math.Vec3::zero()
  if @input.key_pressed(@window.KeyCode::KeyA) {
    axis = @math.Vec3::new(axis.x - 1.0F, axis.y, axis.z)
  }
  if @input.key_pressed(@window.KeyCode::KeyD) {
    axis = @math.Vec3::new(axis.x + 1.0F, axis.y, axis.z)
  }
  if @input.key_pressed(@window.KeyCode::KeyW) {
    axis = @math.Vec3::new(axis.x, axis.y, axis.z - 1.0F)
  }
  if @input.key_pressed(@window.KeyCode::KeyS) {
    axis = @math.Vec3::new(axis.x, axis.y, axis.z + 1.0F)
  }
  if axis.x == 0.0F && axis.z == 0.0F {
    return
  }
  let len = Float::sqrt(axis.x * axis.x + axis.z * axis.z)
  let dir = if len > 0.0F {
    @math.Vec3::new(axis.x / len, 0.0F, axis.z / len)
  } else {
    @math.Vec3::zero()
  }
  try! (world.replace(
    player,
    @physics3d.ecs_key_kinematic_character_controller3d,
    kcc.add_translation(
      @math.Vec3::new(dir.x * speed * dt, 0.0F, dir.z * speed * dt),
    ),
  )
  |> ignore)
}
