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
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .run()
}

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
          @pbr.mesh3d_geometry_cuboid(16.0F, 1.0F, 16.0F),
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
      @physics3d.ColliderShape3d::cuboid(8.0F, 0.5F, 8.0F),
    ),
  )

  let body_material_a = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.90F, 0.60F, 0.20F, 1.0F),
    ).with_unlit(true),
  )
  let body_material_b = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.20F, 0.75F, 0.95F, 1.0F),
    ).with_unlit(true),
  )
  let a = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_uv_sphere(0.4F, 16, 12),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(body_material_a),
    @transform.Transform::from_xyz(-1.5F, 2.0F, 0.0F),
  ).spawn(world)
  try! world.set_by_key(
    a,
    @physics3d.ecs_key_rigid_body3d,
    @physics3d.RigidBody3d::dynamic(),
  )
  try! world.set_by_key(
    a,
    @physics3d.ecs_key_collider3d,
    @physics3d.Collider3d::new(@physics3d.ColliderShape3d::ball(0.4F)),
  )

  let b = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_uv_sphere(0.4F, 16, 12),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(body_material_b),
    @transform.Transform::from_xyz(1.5F, 2.0F, 0.0F),
  ).spawn(world)
  try! world.set_by_key(
    b,
    @physics3d.ecs_key_rigid_body3d,
    @physics3d.RigidBody3d::dynamic(),
  )
  try! world.set_by_key(
    b,
    @physics3d.ecs_key_collider3d,
    @physics3d.Collider3d::new(@physics3d.ColliderShape3d::ball(0.4F)),
  )
  try! world.set_by_key(
    b,
    @physics3d.ecs_key_impulse_joint3d,
    @physics3d.ImpulseJoint3d::new(
      a,
      @physics3d.joint3d_fixed(
        @math.Vec3::new(0.0F, 0.0F, 0.0F),
        @math.Vec3::new(0.0F, 0.0F, 0.0F),
      ),
    ),
  )
  try! world.set_by_key(
    a,
    @physics3d.ecs_key_velocity3d,
    @physics3d.Velocity3d::new(
      @math.Vec3::new(0.0F, 0.0F, 2.5F),
      @math.Vec3::zero(),
    ),
  )
  try! world.set_by_key(
    b,
    @physics3d.ecs_key_velocity3d,
    @physics3d.Velocity3d::new(
      @math.Vec3::new(0.0F, 0.0F, -2.5F),
      @math.Vec3::zero(),
    ),
  )

  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(0.0F, 6.0F, 10.0F).looking_at(
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
  println("[physics3d_joints] two dynamic bodies are connected by fixed joint")
}
