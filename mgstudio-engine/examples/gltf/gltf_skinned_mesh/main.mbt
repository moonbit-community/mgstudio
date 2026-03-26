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
const GLTF_PATH : String = "models/animated/Fox.glb"

///|
fn setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(@sprite.Color::white(), 1200.0F),
  )

  ignore(
    @pbr.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(100.0F, 90.0F, 140.0F).looking_at(
        @math.Vec3::new(0.0F, 20.0F, 0.0F),
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
          @math.Quat::from_euler(@math.EulerRot::ZYX, 0.0F, 1.0F, -0.6F),
        ),
        @pbr.DirectionalLight::new(@sprite.Color::white(), 10000.0F, true),
      ),
    ),
  )

  let root = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(root)
    .insert_component(
      @scene.SceneRoot::new(
        asset_server.load(@gltf.GltfAssetLabel::Scene(0).from_asset(GLTF_PATH)),
      ),
    ),
  )
}

///|
fn animate_joint_chain(
  time : @app.Res[@time.Time[Unit]],
  skinned_meshes : @ecs.Query[@ecs.Comp[@mesh.SkinnedMesh], @ecs.All],
  transforms : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.All],
) -> Unit {
  let angle = 0.5F * @math.sin(time.get().elapsed_secs())
  try! skinned_meshes.view(fn(_entity, skinned_mesh) {
    let joints = skinned_mesh.value().joints()
    if joints.length() < 2 {
      return
    }
    guard (try! transforms.get(joints[1])) is Some(transform) else { return }
    transform.get_ref().val.rotation = @math.Quat::from_rotation_z(angle)
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(animate_joint_chain)),
  )
  .run()
}
