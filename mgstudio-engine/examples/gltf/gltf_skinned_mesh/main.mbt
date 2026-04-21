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
const GLTF_PATH : String = "models/SimpleSkin/SimpleSkin.gltf"

///|
fn setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(@sprite.Color::white(), 750.0F),
  )

  ignore(
    @camera.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ).spawn(world),
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
fn joint_animation(
  time : @app.Res[@time.Time[Unit]],
  skinned_mesh_parents : @ecs.Query[
    @ecs.Comp[@hierarchy.Parent],
    @ecs.With[@mesh.SkinnedMesh],
  ],
  parents : @ecs.Query[@ecs.Comp[@hierarchy.Children], @ecs.All],
  transforms : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.All],
) -> Unit {
  let angle = @math.pi_half() * @math.sin(time.get().elapsed_secs())
  try! skinned_mesh_parents.view(fn(_entity, parent_comp) {
    let mesh_node_entity = parent_comp.value().entity()
    guard (parents.get(mesh_node_entity) catch { _ => None })
      is Some(mesh_node_children_comp) else {
      return
    }
    let mesh_node_children = mesh_node_children_comp.value().entities()
    if mesh_node_children.length() < 2 {
      return
    }
    let first_joint_entity = mesh_node_children[1]
    guard (parents.get(first_joint_entity) catch { _ => None })
      is Some(first_joint_children_comp) else {
      return
    }
    let first_joint_children = first_joint_children_comp.value().entities()
    if first_joint_children.length() == 0 {
      return
    }
    let second_joint_entity = first_joint_children[0]
    guard (transforms.get(second_joint_entity) catch { _ => None })
      is Some(second_joint_transform) else {
      return
    }
    second_joint_transform.modify(fn(value) {
      value.rotation = @math.Quat::from_rotation_z(angle)
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(@app.system_param4(joint_animation)))
  .run()
}
