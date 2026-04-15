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
pub struct Rapier3dDebugRenderPlugin {}

///|
pub fn Rapier3dDebugRenderPlugin::default() -> Rapier3dDebugRenderPlugin {
  Rapier3dDebugRenderPlugin::{  }
}

///|
pub impl @app.Plugin for Rapier3dDebugRenderPlugin with name(_self) {
  "examples.helpers.rapier_examples.Rapier3dDebugRenderPlugin"
}

///|
pub impl @app.Plugin for Rapier3dDebugRenderPlugin with build(_self, app) {
  @physics3d.physics3d_debug_render_plugin(app)
}

///|
pub fn rapier3d_plugins() -> @app.PluginGroupBuilder[@ecs.World] {
  @mgstudio.DefaultPlugins::build().add(Rapier3dDebugRenderPlugin::default())
}

///|
pub fn rapier3d_camera(
  world : @ecs.World,
  eye : @math.Vec3,
  target : @math.Vec3,
) -> Unit {
  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(eye.x, eye.y, eye.z).looking_at(
      target,
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
pub fn rapier3d_basic_lighting(world : @ecs.World) -> Unit {
  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(
      @sprite.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
      0.40F,
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
    @transform.Transform::from_xyz(4.0F, 8.0F, 8.0F),
  )
}

///|
pub fn rapier3d_color(i : Int) -> @sprite.Color {
  let colors = [
    @sprite.Color::new(0.22F, 0.22F, 0.58F, 1.0F),
    @sprite.Color::new(0.12F, 0.64F, 0.58F, 1.0F),
    @sprite.Color::new(0.75F, 0.25F, 0.75F, 1.0F),
  ]
  colors[i % colors.length()]
}

///|
pub fn rapier3d_unlit_material(color : @sprite.Color) -> @pbr.MeshMaterial3d {
  @pbr.MeshMaterial3d::new(
    @pbr.standard_material_add(
      @pbr.StandardMaterial::from_color(color).with_unlit(true),
    ),
  )
}

///|
pub fn rapier3d_spawn_body_mesh(
  world : @ecs.World,
  geometry : @pbr.Mesh3dGeometry,
  color : @sprite.Color,
  transform : @transform.Transform,
  rigid_body : @physics3d.RigidBody3d?,
  collider : @physics3d.Collider3d?,
) -> @core.Entity {
  let entity = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(geometry),
      ),
    ),
    rapier3d_unlit_material(color),
    transform,
  ).spawn(world)
  if rigid_body is Some(rb) {
    try! world.set_by_key(entity, @physics3d.ecs_key_rigid_body3d, rb)
  }
  if collider is Some(col) {
    try! world.set_by_key(entity, @physics3d.ecs_key_collider3d, col)
  }
  entity
}

///|
pub fn rapier3d_spawn_cuboid(
  world : @ecs.World,
  position : @math.Vec3,
  half_extents : @math.Vec3,
  color : @sprite.Color,
  rigid_body : @physics3d.RigidBody3d?,
) -> @core.Entity {
  rapier3d_spawn_body_mesh(
    world,
    @pbr.mesh3d_geometry_cuboid(half_extents.x, half_extents.y, half_extents.z),
    color,
    @transform.Transform::from_xyz(position.x, position.y, position.z),
    rigid_body,
    Some(
      @physics3d.Collider3d::new(
        @physics3d.ColliderShape3d::cuboid(
          half_extents.x,
          half_extents.y,
          half_extents.z,
        ),
      ),
    ),
  )
}

///|
pub fn rapier3d_spawn_ball(
  world : @ecs.World,
  position : @math.Vec3,
  radius : Float,
  color : @sprite.Color,
  rigid_body : @physics3d.RigidBody3d?,
) -> @core.Entity {
  rapier3d_spawn_body_mesh(
    world,
    @pbr.mesh3d_geometry_sphere(radius),
    color,
    @transform.Transform::from_xyz(position.x, position.y, position.z),
    rigid_body,
    Some(@physics3d.Collider3d::new(@physics3d.ColliderShape3d::ball(radius))),
  )
}

///|
pub fn rapier3d_spawn_capsule_y(
  world : @ecs.World,
  position : @math.Vec3,
  half_length : Float,
  radius : Float,
  color : @sprite.Color,
  rigid_body : @physics3d.RigidBody3d?,
) -> @core.Entity {
  rapier3d_spawn_body_mesh(
    world,
    @pbr.mesh3d_geometry_capsule(
      @math.Capsule3d::new(radius, half_length * 2.0F),
    ),
    color,
    @transform.Transform::from_xyz(position.x, position.y, position.z),
    rigid_body,
    Some(
      @physics3d.Collider3d::new(
        @physics3d.ColliderShape3d::capsule_y(half_length, radius),
      ),
    ),
  )
}

///|
pub fn rapier3d_spawn_ground(
  world : @ecs.World,
  half_extents : @math.Vec3,
  position : @math.Vec3,
) -> @core.Entity {
  rapier3d_spawn_cuboid(
    world,
    position,
    half_extents,
    @sprite.Color::new(0.70F, 0.72F, 0.76F, 1.0F),
    Some(@physics3d.RigidBody3d::fixed()),
  )
}
