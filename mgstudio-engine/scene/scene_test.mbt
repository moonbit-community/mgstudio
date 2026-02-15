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
test "scene: gltf label path encoding" {
  let path = @scene.GltfAssetLabel::Scene(3).from_asset("models/Foo/Foo.gltf")
  inspect(path, content="models/Foo/Foo.gltf#Scene3")
}

///|
test "scene: register keeps stable handle" {
  let path = @scene.GltfAssetLabel::Scene(0).from_asset("models/Foo/Foo.gltf")
  let first_handle = @scene.scene_register_gltf_scene(
    path,
    @scene.Scene::new([]),
  )
  let second_handle = @scene.scene_register_gltf_scene(
    path,
    @scene.Scene::new([]),
  )
  inspect(first_handle.id() == second_handle.id(), content="true")

  let ready_scene = @scene.scene_get(second_handle).unwrap()
  inspect(ready_scene.ready, content="true")
}

///|
test "scene: SceneRoot spawns children and marks ready" {
  let world = @ecs_world.World::new()
  let tick = world.increment_change_tick()

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
  )
  let scene_handle = @scene.scene_register_gltf_scene(
    path,
    @scene.Scene::new([node]),
  )

  let root = world.spawn_empty()
  world
  .get_scene_root_store()
  .insert(root, @scene.SceneRoot::new(scene_handle), tick)

  @scene.scene_spawn_roots_system(world)

  let ready = world.get_scene_instance_ready_store().get(root).unwrap()
  inspect(ready.spawned_entities, content="1")

  let children : Array[@core.Entity] = []
  world
  .get_parent_store()
  .for_each(fn(entity, parent) {
    if parent.entity().id == root.id {
      children.push(entity)
    }
  })
  inspect(children.length(), content="1")

  let child = children[0]
  inspect(world.get_mesh3d_store().contains(child), content="true")
  inspect(world.get_mesh_material3d_store().contains(child), content="true")
  inspect(world.get_transform_store().contains(child), content="true")
  inspect(world.get_visibility_range_store().contains(child), content="true")
}
