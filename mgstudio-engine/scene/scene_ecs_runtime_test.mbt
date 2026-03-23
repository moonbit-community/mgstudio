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
    @asset.asset_plugin, @sprite_render.render2d_plugin_ecs, @pbr.render3d_plugin,
    @animation.animation_plugin, @scene.scene_plugin, @gltf.gltf_plugin, @time.time_plugin,
  ]
  let instance_id = Ref::new(0)
  let spawned_entities = Ref::new(0)
  let child_count = Ref::new(0)
  let has_mesh = Ref::new(false)
  let has_material = Ref::new(false)
  let has_transform = Ref::new(false)
  let has_visibility = Ref::new(false)
  let has_target = Ref::new(false)
  let has_animated_by = Ref::new(false)
  let instance_after_second_tick = Ref::new(0)
  ignore(instance_after_second_tick)
  let ready_after_second_tick = Ref::new(0)
  ignore(ready_after_second_tick)
  let ready_entity_count = Ref::new(0)
  let ready_entity_matches_root = Ref::new(false)

  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_system(fn(world : @ecs.World) {
    let path = @gltf.GltfAssetLabel::Scene(0).from_asset("models/Foo/Foo.gltf")
    let material = @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(@sprite.Color::white()),
      ),
    )
    let node = @scene.SceneNode3d::new(
      @pbr.Mesh3d::new(
        @pbr.mesh_assets_mut_or_abort().val.add(
          @pbr.Mesh::from_3d_geometry(
            @pbr.mesh3d_geometry_cuboid(1.0F, 2.0F, 3.0F),
          ),
        ),
      ),
      material,
      @transform.Transform::from_xyz(1.0F, 2.0F, 3.0F),
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

    let instance = (try! world.get(root, @scene.ecs_key_scene_instance)).unwrap()
    let ready = (try! world.get(root, @scene.ecs_key_scene_instance_ready)).unwrap()
    instance_id.val = instance.instance_id
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
    has_mesh.val = (try! world.get(child, @pbr.ecs_key_mesh3d)) is Some(_)
    has_material.val = (try! world.get(child, @pbr.ecs_key_mesh_material3d))
      is Some(_)
    has_transform.val = (try! world.get(child, @transform.ecs_key_transform))
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
    let instance_second = (try! world.get(root, @scene.ecs_key_scene_instance)).unwrap()
    let ready_second = (try! world.get(
      root, @scene.ecs_key_scene_instance_ready,
    )).unwrap()
    instance_after_second_tick.val = instance_second.instance_id
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

  inspect(instance_id.val, content="1")
  inspect(spawned_entities.val, content="1")
  inspect(child_count.val, content="1")
  inspect(has_mesh.val, content="true")
  inspect(has_material.val, content="true")
  inspect(has_transform.val, content="true")
  inspect(has_visibility.val, content="true")
  inspect(has_target.val, content="true")
  inspect(has_animated_by.val, content="true")
  inspect(instance_after_second_tick.val, content="1")
  inspect(ready_after_second_tick.val, content="1")
  inspect(ready_entity_count.val, content="1")
  inspect(ready_entity_matches_root.val, content="true")
}

///|
test "scene ecs: SceneRoot change respawns children and updates SceneInstance" {
  let plugins : Array[@app.Plugin[@ecs.World]] = [
    @asset.asset_plugin, @sprite_render.render2d_plugin_ecs, @pbr.render3d_plugin,
    @animation.animation_plugin, @scene.scene_plugin, @gltf.gltf_plugin, @time.time_plugin,
  ]
  let old_instance_id = Ref::new(0)
  let new_instance_id = Ref::new(0)
  let ready_instance_matches = Ref::new(false)
  let old_child_alive = Ref::new(true)
  let new_child_count = Ref::new(0)
  let new_child_x = Ref::new(0.0)

  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_system(fn(world : @ecs.World) {
    let first_path = @gltf.GltfAssetLabel::Scene(1).from_asset(
      "models/Foo/Foo.gltf",
    )
    let second_path = @gltf.GltfAssetLabel::Scene(2).from_asset(
      "models/Foo/Foo.gltf",
    )
    let material = @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(@sprite.Color::white()),
      ),
    )
    let first_handle = @scene.scene_register_gltf_scene(
      first_path,
      @scene.Scene::new([
        @scene.SceneNode3d::new(
          @pbr.Mesh3d::new(
            @pbr.mesh_assets_mut_or_abort().val.add(
              @pbr.Mesh::from_3d_geometry(
                @pbr.mesh3d_geometry_cuboid(1.0F, 2.0F, 3.0F),
              ),
            ),
          ),
          material,
          @transform.Transform::from_xyz(1.0F, 2.0F, 3.0F),
          None,
          None,
        ),
      ]),
    )
    let second_handle = @scene.scene_register_gltf_scene(
      second_path,
      @scene.Scene::new([
        @scene.SceneNode3d::new(
          @pbr.Mesh3d::new(
            @pbr.mesh_assets_mut_or_abort().val.add(
              @pbr.Mesh::from_3d_geometry(
                @pbr.mesh3d_geometry_cuboid(4.0F, 5.0F, 6.0F),
              ),
            ),
          ),
          material,
          @transform.Transform::from_xyz(9.0F, 8.0F, 7.0F),
          None,
          None,
        ),
      ]),
    )

    let root = world.spawn()
    try! world.set(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(first_handle),
    )

    @scene.scene_spawn_roots_system_ecs(world)
    let first_instance = (try! world.get(root, @scene.ecs_key_scene_instance)).unwrap()
    old_instance_id.val = first_instance.instance_id

    let first_children : Array[@core.Entity] = []
    try! world
    .query1(@hierarchy.ecs_key_parent)
    .view(fn(entity, parent) {
      if parent.entity().id == root.id {
        first_children.push(entity)
      }
    })
    let first_child = first_children[0]

    try! world.set(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(second_handle),
    )
    @scene.scene_spawn_roots_system_ecs(world)

    let second_instance = (try! world.get(root, @scene.ecs_key_scene_instance)).unwrap()
    let ready = (try! world.get(root, @scene.ecs_key_scene_instance_ready)).unwrap()
    new_instance_id.val = second_instance.instance_id
    ready_instance_matches.val = ready.instance_id ==
      second_instance.instance_id
    old_child_alive.val = world.is_alive(first_child)

    let second_children : Array[@core.Entity] = []
    try! world
    .query1(@hierarchy.ecs_key_parent)
    .view(fn(entity, parent) {
      if parent.entity().id == root.id {
        second_children.push(entity)
      }
    })
    new_child_count.val = second_children.length()
    let second_child = second_children[0]
    let transform = (try! world.get(second_child, @transform.ecs_key_transform)).unwrap()
    new_child_x.val = transform.translation.x.to_double()
  })
  .run_once()
  |> ignore

  inspect(old_instance_id.val == new_instance_id.val, content="false")
  inspect(ready_instance_matches.val, content="true")
  inspect(old_child_alive.val, content="false")
  inspect(new_child_count.val, content="1")
  inspect(new_child_x.val, content="9")
}
