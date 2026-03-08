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
  let plugins : Array[@app.Plugin[@ecs.World]] = [
    @asset.asset_plugin, @render2d.render2d_plugin_ecs, @render3d.render3d_plugin,
    @animation.animation_plugin, @scene.scene_plugin,
  ]
  let spawned_entities = Ref::new(0)
  let child_count = Ref::new(0)
  let has_mesh = Ref::new(false)
  let has_material = Ref::new(false)
  let has_transform = Ref::new(false)
  let has_visibility = Ref::new(false)
  let has_target = Ref::new(false)
  let has_animated_by = Ref::new(false)
  let ready_after_second_tick = Ref::new(0)
  let ready_entity_count = Ref::new(0)
  let ready_entity_matches_root = Ref::new(false)

  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_system(fn(world : @ecs.World) {
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
    spawned_entities.val = ready.spawned_entities

    let children : Array[@core.Entity] = []
    try! world
    .query1(@hierarchy.ecs_key_parent)
    .view(fn(entity, parent) {
      if parent.entity().id == root.id {
        children.push(entity)
      }
    })
    child_count.val = children.length()

    let child = children[0]
    has_mesh.val = (try! world.get(child, @render3d.ecs_key_mesh3d)) is Some(_)
    has_material.val = (try! world.get(child, @render3d.ecs_key_mesh_material3d))
      is Some(_)
    has_transform.val = (try! world.get(child, @math.ecs_key_transform))
      is Some(_)
    has_visibility.val = (try! world.get(
        child, @visibility.ecs_key_visibility_range,
      ))
      is Some(_)
    has_target.val = (try! world.get(
        child, @animation.ecs_key_animation_target_id,
      ))
      is Some(_)
    has_animated_by.val = (try! world.get(child, @animation.ecs_key_animated_by))
      is Some(_)

    @scene.scene_spawn_roots_system_ecs(world)
    let ready_second = (try! world.get(
      root, @scene.ecs_key_scene_instance_ready,
    )).unwrap()
    ready_after_second_tick.val = ready_second.spawned_entities

    let ready_entities : Array[@core.Entity] = []
    try! world
    .query1(@scene.ecs_key_scene_instance_ready)
    .view(fn(entity, _ready) { ready_entities.push(entity) })
    ready_entity_count.val = ready_entities.length()
    ready_entity_matches_root.val = ready_entities[0].id == root.id
  })
  .run_once()
  |> ignore

  inspect(spawned_entities.val, content="1")
  inspect(child_count.val, content="1")
  inspect(has_mesh.val, content="true")
  inspect(has_material.val, content="true")
  inspect(has_transform.val, content="true")
  inspect(has_visibility.val, content="true")
  inspect(has_target.val, content="true")
  inspect(has_animated_by.val, content="true")
  inspect(ready_after_second_tick.val, content="1")
  inspect(ready_entity_count.val, content="1")
  inspect(ready_entity_matches_root.val, content="true")
}
