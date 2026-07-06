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
struct AnimatedJoint {
  index : Int
}

///|
let animated_joint_key : @ecs.ComponentKey[AnimatedJoint] = @ecs.register_component(
  debug_name="examples.animation.custom_skinned_mesh.AnimatedJoint",
)

///|
pub impl @ecs.Component for AnimatedJoint with fn component() {
  animated_joint_key
}

///|
fn AnimatedJoint::AnimatedJoint(index : Int) -> AnimatedJoint {
  AnimatedJoint::{ index, }
}

///|
fn build_skinned_strip() -> @mesh.Mesh {
  let positions = [
    @math.Vec3::new(0.0F, 0.0F, 0.0F),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    @math.Vec3::new(0.0F, 0.5F, 0.0F),
    @math.Vec3::new(1.0F, 0.5F, 0.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
    @math.Vec3::new(1.0F, 1.0F, 0.0F),
    @math.Vec3::new(0.0F, 1.5F, 0.0F),
    @math.Vec3::new(1.0F, 1.5F, 0.0F),
    @math.Vec3::new(0.0F, 2.0F, 0.0F),
    @math.Vec3::new(1.0F, 2.0F, 0.0F),
  ]
  let uvs = [
    @math.Vec2::new(0.0F, 0.00F),
    @math.Vec2::new(0.5F, 0.00F),
    @math.Vec2::new(0.0F, 0.25F),
    @math.Vec2::new(0.5F, 0.25F),
    @math.Vec2::new(0.0F, 0.50F),
    @math.Vec2::new(0.5F, 0.50F),
    @math.Vec2::new(0.0F, 0.75F),
    @math.Vec2::new(0.5F, 0.75F),
    @math.Vec2::new(0.0F, 1.00F),
    @math.Vec2::new(0.5F, 1.00F),
  ]
  let indices = [
    0, 1, 3, 0, 3, 2, 2, 3, 5, 2, 5, 4, 4, 5, 7, 4, 7, 6, 6, 7, 9, 6, 9, 8,
  ]
  let normals = [
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
  ]
  let geometry = @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices))
    .with_normals(Some(normals))
    .with_joint_data(
      Some([
        @mesh.MeshJointIndices::new(0, 0, 0, 0),
        @mesh.MeshJointIndices::new(0, 0, 0, 0),
        @mesh.MeshJointIndices::new(0, 1, 0, 0),
        @mesh.MeshJointIndices::new(0, 1, 0, 0),
        @mesh.MeshJointIndices::new(0, 1, 0, 0),
        @mesh.MeshJointIndices::new(0, 1, 0, 0),
        @mesh.MeshJointIndices::new(0, 1, 0, 0),
        @mesh.MeshJointIndices::new(0, 1, 0, 0),
        @mesh.MeshJointIndices::new(0, 1, 0, 0),
        @mesh.MeshJointIndices::new(0, 1, 0, 0),
      ]),
      Some([
        @math.Vec4::new(1.00F, 0.00F, 0.0F, 0.0F),
        @math.Vec4::new(1.00F, 0.00F, 0.0F, 0.0F),
        @math.Vec4::new(0.75F, 0.25F, 0.0F, 0.0F),
        @math.Vec4::new(0.75F, 0.25F, 0.0F, 0.0F),
        @math.Vec4::new(0.50F, 0.50F, 0.0F, 0.0F),
        @math.Vec4::new(0.50F, 0.50F, 0.0F, 0.0F),
        @math.Vec4::new(0.25F, 0.75F, 0.0F, 0.0F),
        @math.Vec4::new(0.25F, 0.75F, 0.0F, 0.0F),
        @math.Vec4::new(0.00F, 1.00F, 0.0F, 0.0F),
        @math.Vec4::new(0.00F, 1.00F, 0.0F, 0.0F),
      ]),
    )
  @mesh.Mesh::from_3d_geometry(geometry).with_generated_skinned_mesh_bounds() catch {
    _ => abort("custom_skinned_mesh mesh bounds generation failed")
  }
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  skinned_mesh_inverse_bindposes_assets : @app.ResMut[
    @asset.Assets[@mesh.SkinnedMeshInverseBindposes],
  ],
) -> Unit {
  commands.insert_resource(
    @pbr.GlobalAmbientLight::new(@color.Color::white(), 3000.0F),
  )
  ignore(
    commands.spawn(
      @camera.Camera3dBundle::new(
        @camera_camera.Camera::Camera(),
        @transform.Transform::from_xyz(2.5F, 2.5F, 9.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  let inverse_bindposes = skinned_mesh_inverse_bindposes_assets.modify(fn(
    assets,
  ) {
    assets.add(
      @mesh.SkinnedMeshInverseBindposes::new([
        @mesh.SkinningMat4::from_transform(
          @transform.Transform::from_xyz(-0.5F, -1.0F, 0.0F),
        ),
        @mesh.SkinningMat4::from_transform(
          @transform.Transform::from_xyz(-0.5F, -1.0F, 0.0F),
        ),
      ]),
    )
  })

  let mesh = meshes.modify(fn(assets) { assets.add(build_skinned_strip()) })
  let rng = @chacha_rng.ChaCha8Rng::seed_from_u64(42UL)
  let checker_texture = asset_server
    .get()
    .load_image("textures/uv_checker_bw.png")

  for i in -5..<5 {
    let joint_0 = commands.spawn_component(
      @transform.Transform::from_xyz(
        Float::from_int(i) * 1.5F,
        0.0F,
        -@math.abs(Float::from_int(i) * 0.01F),
      ),
    )
    let joint_1 = commands.spawn(
      (
        AnimatedJoint::AnimatedJoint(i),
        @transform.Transform::identity(),
        @hierarchy.Parent::new(joint_0),
      ),
    )
    let material = materials.modify(fn(assets) {
      assets.add(
        @pbr.StandardMaterial::StandardMaterial()
        .with_base_color(
          @color.Color::srgb(
            rng.random_float(),
            rng.random_float(),
            rng.random_float(),
          ),
        )
        .with_base_color_texture(Some(checker_texture)),
      )
    })
    let mesh_entity = commands.spawn(
      @pbr.MeshMaterial3dBundle::new(
        @mesh.Mesh3d::new(mesh),
        @pbr.MeshMaterial3dTyped::new(material),
        @transform.Transform::identity(),
      ),
    )
    commands
    .entity(mesh_entity)
    .insert(
      (
        @mesh.SkinnedMesh::new(inverse_bindposes, [joint_0, joint_1]),
        @mesh.DynamicSkinnedMeshBounds::new(),
      ),
    )
  }
}

///|
fn joint_animation(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    (@ecs.Write[@transform.Transform], @ecs.Read[AnimatedJoint]),
    @ecs.All,
  ],
  gizmos : @gizmos.Gizmos[@gizmos.DefaultGizmoConfigGroup],
) -> Unit {
  let elapsed_secs = time.get().elapsed_secs()
  try! query.view(fn(_entity, data) {
    let (transform, animated_joint) = data
    let joint_index = animated_joint.value().index
    transform.modify(fn(value) {
      match joint_index {
        -5 =>
          value.rotation = @math.Quat::from_rotation_x(
            @math.pi_half() * @math.sin(elapsed_secs),
          )
        -4 =>
          value.rotation = @math.Quat::from_rotation_y(
            @math.pi_half() * @math.sin(elapsed_secs),
          )
        -3 =>
          value.rotation = @math.Quat::from_rotation_z(
            @math.pi_half() * @math.sin(elapsed_secs),
          )
        -2 => value.scale.x = @math.sin(elapsed_secs) + 1.0F
        -1 => value.scale.y = @math.sin(elapsed_secs) + 1.0F
        0 => {
          value.translation.x = 0.5F * @math.sin(elapsed_secs)
          value.translation.y = @math.cos(elapsed_secs)
        }
        1 => {
          value.translation.y = @math.sin(elapsed_secs)
          value.translation.z = @math.cos(elapsed_secs)
        }
        2 => value.translation.x = @math.sin(elapsed_secs)
        3 => {
          value.translation.y = @math.sin(elapsed_secs)
          value.scale.x = @math.sin(elapsed_secs) + 1.0F
        }
        _ => ()
      }
    })
    let axis = transform.value()
    axis.translation.x = axis.translation.x +
      Float::from_int(joint_index) * 1.5F
    gizmos.axes_3d(axis, 1.0F)
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param5(@app.Startup, setup)
  .add_systems_param3(@app.Update, joint_animation)
  .run()
}
