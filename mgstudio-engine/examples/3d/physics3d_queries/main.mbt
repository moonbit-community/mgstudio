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
  .add_systems(@app.Update, @app.system(run_queries))
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
    @transform.Transform::from_xyz(6.0F, 8.0F, 6.0F),
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
          @pbr.mesh3d_geometry_cuboid(20.0F, 1.0F, 20.0F),
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
      @physics3d.ColliderShape3d::cuboid(10.0F, 0.5F, 10.0F),
    ),
  )

  let wall_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.80F, 0.35F, 0.35F, 1.0F),
    ).with_unlit(true),
  )
  let wall = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(4.0F, 4.0F, 0.4F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(wall_material),
    @transform.Transform::from_xyz(0.0F, 2.0F, -3.0F),
  ).spawn(world)
  try! world.set_by_key(
    wall,
    @physics3d.ecs_key_rigid_body3d,
    @physics3d.RigidBody3d::fixed(),
  )
  try! world.set_by_key(
    wall,
    @physics3d.ecs_key_collider3d,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::cuboid(2.0F, 2.0F, 0.2F),
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
  println("[physics3d_queries] Press Space to cast ray and shape queries")
}

///|
fn run_queries(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Space) {
    return
  }
  guard @physics3d.get_physics3d_context_resource(world).get() is Some(ctx) else {
    return
  }
  match
    ctx.cast_ray_entity(
      @math.Vec3::new(0.0F, 4.0F, 8.0F),
      @math.Vec3::new(0.0F, -0.2F, -1.0F),
      100.0F,
      true,
    ) {
    Some(hit) =>
      println(
        "[physics3d_queries] ray hit entity=\{hit.entity.id}, toi=\{hit.toi}",
      )
    None => println("[physics3d_queries] ray missed")
  }

  let shape_hits = ctx.intersect_shape_entities(
    @transform.Transform::from_xyz(0.0F, 1.0F, -3.0F),
    @collision.Shape3D::ball(1.2F),
  )
  println("[physics3d_queries] intersect_shape count=\{shape_hits.length()}")
}
