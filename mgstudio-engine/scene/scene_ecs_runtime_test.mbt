// Copyright 2025 International Digital Economy Academy
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
test "scene ecs: SceneRoot spawns children and marks ready" {
  let world = @ecs.World::new()

  let path = @scene.GltfAssetLabel::Scene(0).from_asset("models/Foo/Foo.gltf")
  let material = @render3d.MeshMaterial3d::new(
    @render3d.standard_material_add(
      @render3d.StandardMaterial::from_color(@render2d.Color::white()),
    ),
  )
  let node = @scene.SceneNode3d::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 2.0F, 3.0F),
    material,
    @math.Transform::from_xyz(1.0F, 2.0F, 3.0F),
    Some(@visibility.VisibilityRange::new(0.0F, 0.0F, 4.0F, 5.0F, false)),
    Some(@animation.AnimationTargetId::from_name("Node")),
  )
  let scene_handle = @scene.scene_register_gltf_scene(
    path,
    @scene.Scene::new([node]),
  )

  let root = world.spawn()
  try! world.set(
    root,
    @scene.ecs_key_scene_root,
    @scene.SceneRoot::new(scene_handle),
  )

  @scene.scene_spawn_roots_system_ecs(world)

  let ready = (try! world.get(root, @scene.ecs_key_scene_instance_ready)).unwrap()
  inspect(ready.spawned_entities, content="1")

  let children : Array[@core.Entity] = []
  try! world
  .query1(@hierarchy.ecs_key_parent)
  .view(fn(entity, parent) {
    if parent.entity().id == root.id {
      children.push(entity)
    }
  })
  inspect(children.length(), content="1")

  let child = children[0]
  inspect(
    (try! world.get(child, @render3d.ecs_key_mesh3d)) is Some(_),
    content="true",
  )
  inspect(
    (try! world.get(child, @render3d.ecs_key_mesh_material3d)) is Some(_),
    content="true",
  )
  inspect(
    (try! world.get(child, @math.ecs_key_transform)) is Some(_),
    content="true",
  )
  inspect(
    (try! world.get(child, @visibility.ecs_key_visibility_range)) is Some(_),
    content="true",
  )
  inspect(
    (try! world.get(child, @animation.ecs_key_animation_target_id)) is Some(_),
    content="true",
  )
  inspect(
    (try! world.get(child, @animation.ecs_key_animated_by)) is Some(_),
    content="true",
  )

  @scene.scene_spawn_roots_system_ecs(world)
  let ready_after_second_tick = (try! world.get(
    root, @scene.ecs_key_scene_instance_ready,
  )).unwrap()
  inspect(ready_after_second_tick.spawned_entities, content="1")

  let ready_entities : Array[@core.Entity] = []
  try! world
  .query1(@scene.ecs_key_scene_instance_ready)
  .view(fn(entity, _ready) { ready_entities.push(entity) })
  inspect(ready_entities.length(), content="1")
  inspect(ready_entities[0].id == root.id, content="true")
}
