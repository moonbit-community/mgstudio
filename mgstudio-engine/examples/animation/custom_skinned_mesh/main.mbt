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
struct AnimatedJoint {}

///|
let animated_joint_key : @ecs.ComponentKey[AnimatedJoint] = @ecs.register_component(
  debug_name="examples.animation.custom_skinned_mesh.AnimatedJoint",
)

///|
pub impl @ecs.Component for AnimatedJoint with component() {
  animated_joint_key
}

///|
fn build_skinned_strip() -> @mesh.Mesh3dGeometry {
  let positions = [
    @math.Vec3::new(-0.2F, 0.0F, 0.0F),
    @math.Vec3::new(0.2F, 0.0F, 0.0F),
    @math.Vec3::new(-0.2F, 2.0F, 0.0F),
    @math.Vec3::new(0.2F, 2.0F, 0.0F),
  ]
  let uvs = [
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 1.0F),
    @math.Vec2::new(1.0F, 1.0F),
  ]
  let indices = [0, 1, 2, 1, 3, 2]
  @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)).with_joint_data(
    Some([
      @mesh.MeshJointIndices::new(0, 0, 0, 0),
      @mesh.MeshJointIndices::new(0, 0, 0, 0),
      @mesh.MeshJointIndices::new(1, 0, 0, 0),
      @mesh.MeshJointIndices::new(1, 0, 0, 0),
    ]),
    Some([
      @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
      @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
      @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
      @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
    ]),
  )
}

///|
fn setup(world : @ecs.World) -> Unit {
  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(@sprite.Color::white(), 1200.0F),
  )
  ignore(
    @pbr.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(0.0F, 1.4F, 6.0F).looking_at(
        @math.Vec3::new(0.0F, 0.8F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ).spawn(world),
  )
  let light = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(light)
    .insert(
      (
        @transform.Transform::from_rotation(
          @math.Quat::from_euler(@math.EulerRot::ZYX, 0.0F, 0.8F, -0.7F),
        ),
        @pbr.DirectionalLight::new(@sprite.Color::white(), 9000.0F, true),
      ),
    ),
  )

  let source_mesh = @mesh.Mesh::from_3d_geometry(build_skinned_strip())
  let source_handle = @pbr.mesh_assets_mut_or_abort().val.add(source_mesh)
  let instance_handle = @pbr.mesh_assets_mut_or_abort().val.add(
    @mesh.Mesh::from_3d_geometry(build_skinned_strip()),
  )
  let material_handle = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.3F, 0.8F, 1.0F)),
  )

  let root = world.spawn_empty()
  let first_joint = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(first_joint)
    .insert((@transform.Transform::identity(), @hierarchy.Parent::new(root))),
  )
  let second_joint = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(second_joint)
    .insert(
      (
        AnimatedJoint::{  },
        @transform.Transform::from_xyz(0.0F, 1.0F, 0.0F),
        @hierarchy.Parent::new(first_joint),
      ),
    ),
  )

  let mesh_entity = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(mesh_entity)
    .insert(
      (
        @pbr.Mesh3d::new(instance_handle),
        @pbr.MeshMaterial3d::new(material_handle),
        @transform.Transform::identity(),
        @hierarchy.Parent::new(root),
      ),
    ),
  )
  ignore(
    try! world
    .entity_mut(mesh_entity)
    .insert(
      (
        @mesh.SkinnedMesh::new(
          source_handle,
          [first_joint, second_joint],
          [
            @mesh.SkinningMat4::identity(),
            @mesh.SkinningMat4::inverse_transform(
              @transform.Transform::from_xyz(0.0F, 1.0F, 0.0F),
            ),
          ],
          mesh_root=Some(root),
        ),
        @mesh.DynamicSkinnedMeshBounds::new(),
      ),
    ),
  )
}

///|
fn animate_joint(
  time : @app.Res[@time.Time[Unit]],
  joints : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[AnimatedJoint]],
) -> Unit {
  let angle = 0.8F * @math.sin(time.get().elapsed_secs())
  try! joints.view(fn(_entity, transform) {
    transform.get_ref().val.rotation = @math.Quat::from_rotation_z(angle)
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(@app.system_param2(animate_joint)))
  .run()
}
