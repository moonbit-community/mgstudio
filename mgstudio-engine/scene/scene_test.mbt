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
fn run_scene_test_app(system : (@ecs.World) -> Unit) -> Unit {
  let plugins : Array[@app.Plugin[@ecs.World]] = [
    @asset.asset_plugin, @sprite_render.render2d_plugin_ecs, @pbr.render3d_plugin,
    @animation.animation_plugin, @scene.scene_plugin, @gltf.gltf_plugin, @time.time_plugin,
  ]
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_system(system)
  .run_once()
  |> ignore
}

///|
test "scene: load gltf animation keeps stable handle" {
  let same_handle = Ref::new(false)
  run_scene_test_app(fn(_world : @ecs.World) {
    let asset_server = @asset.AssetServer::new()
    let path = @gltf.GltfAssetLabel::Animation(1).from_asset(
      "models/Foo/Foo.gltf",
    )
    let first = @scene.scene_load_gltf_animation(asset_server, path)
    let second = @scene.scene_load_gltf_animation(asset_server, path)
    same_handle.val = first.id() == second.id()
  })
  inspect(same_handle.val, content="true")
}

///|
test "scene: load gltf primitive mesh keeps stable handle" {
  let same_handle = Ref::new(false)
  run_scene_test_app(fn(_world : @ecs.World) {
    let asset_server = @asset.AssetServer::new()
    let path = @gltf.GltfAssetLabel::Primitive(0, 0).from_asset(
      "models/torus/torus.gltf",
    )
    let first : @asset.Handle[@mesh.Mesh] = asset_server.load(path)
    let second : @asset.Handle[@mesh.Mesh] = asset_server.load(path)
    same_handle.val = first.id() == second.id()
  })
  inspect(same_handle.val, content="true")
}

///|
test "scene: load gltf primitive mesh stays pending in the issuing frame" {
  let asset_missing = Ref::new(false)
  run_scene_test_app(fn(world : @ecs.World) {
    let asset_server = @asset.AssetServer::new()
    let path = @gltf.GltfAssetLabel::Primitive(0, 0).from_asset(
      "models/torus/torus.gltf",
    )
    let handle : @asset.Handle[@mesh.Mesh] = asset_server.load(path)
    let key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
    let meshes = (try! world.get_resource(key)).unwrap()
    asset_missing.val = meshes.get(handle) is None
  })
  inspect(asset_missing.val, content="true")
}

///|
test "scene: register keeps stable handle" {
  let same_handle = Ref::new(false)
  let ready_scene = Ref::new(false)
  run_scene_test_app(fn(_world : @ecs.World) {
    let path = @gltf.GltfAssetLabel::Scene(0).from_asset("models/Foo/Foo.gltf")
    let first_handle = @scene.scene_register_gltf_scene(
      path,
      @scene.Scene::new([]),
    )
    let second_handle = @scene.scene_register_gltf_scene(
      path,
      @scene.Scene::new([]),
    )
    same_handle.val = first_handle.id() == second_handle.id()
    ready_scene.val = @scene.scene_get(second_handle).unwrap().ready
  })
  inspect(same_handle.val, content="true")
  inspect(ready_scene.val, content="true")
}

///|
test "scene: gltf lod visibility policy set/get/reset" {
  let default_enabled = Ref::new(false)
  let default_step = Ref::new(0.0)
  let customized_enabled = Ref::new(true)
  let customized_start = Ref::new(0.0)
  let customized_end = Ref::new(0.0)
  let customized_step = Ref::new(0.0)
  let restored_enabled = Ref::new(false)
  let restored_end = Ref::new(0.0)
  let restored_step = Ref::new(0.0)
  run_scene_test_app(fn(_world : @ecs.World) {
    @scene.scene_reset_gltf_lod_visibility_policy()
    let default_policy = @scene.scene_get_gltf_lod_visibility_policy()
    default_enabled.val = default_policy.enabled
    default_step.val = default_policy.step.to_double()

    @scene.scene_set_gltf_lod_visibility_policy(
      default_policy
      .with_first_lod_range(1.0F, 2.0F, 6.0F, 7.0F)
      .with_step(3.0F)
      .with_enabled(false),
    )
    let customized = @scene.scene_get_gltf_lod_visibility_policy()
    customized_enabled.val = customized.enabled
    customized_start.val = customized.first_start_margin_min.to_double()
    customized_end.val = customized.first_end_margin_max.to_double()
    customized_step.val = customized.step.to_double()

    @scene.scene_reset_gltf_lod_visibility_policy()
    let restored = @scene.scene_get_gltf_lod_visibility_policy()
    restored_enabled.val = restored.enabled
    restored_end.val = restored.first_end_margin_min.to_double()
    restored_step.val = restored.step.to_double()
  })
  inspect(default_enabled.val, content="true")
  inspect(default_step.val, content="5")
  inspect(customized_enabled.val, content="false")
  inspect(customized_start.val, content="1")
  inspect(customized_end.val, content="7")
  inspect(customized_step.val, content="3")
  inspect(restored_enabled.val, content="true")
  inspect(restored_end.val, content="3")
  inspect(restored_step.val, content="5")
}

///|
test "scene: SceneRoot spawns children and marks ready" {
  let instance_id = Ref::new(0)
  let ready_instance_id = Ref::new(0)
  let spawned_entities = Ref::new(0)
  let child_count = Ref::new(0)
  let child_count_after_second_tick = Ref::new(0)
  ignore(child_count_after_second_tick)
  let has_mesh = Ref::new(false)
  let has_material = Ref::new(false)
  let has_transform = Ref::new(false)
  let has_visibility = Ref::new(false)
  let has_player = Ref::new(false)
  let has_target = Ref::new(false)
  let has_animated_by = Ref::new(false)
  let instance_after_second_tick = Ref::new(0)
  ignore(instance_after_second_tick)
  let ready_after_second_tick = Ref::new(0)
  ignore(ready_after_second_tick)
  run_scene_test_app(fn(world : @ecs.World) {
    let tick = world.advance_sequence()
    ignore(tick)
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

    let root = world.spawn_empty()
    get_scene_root_store(world).insert(
      root,
      @scene.SceneRoot::new(scene_handle),
    )

    @scene.scene_spawn_roots_system(world)

    let instance = get_scene_instance_store(world).get(root).unwrap()
    let ready = get_scene_instance_ready_store(world).get(root).unwrap()
    instance_id.val = instance.instance_id
    ready_instance_id.val = ready.instance_id
    spawned_entities.val = ready.spawned_entities

    let children : Array[@core.Entity] = []
    @hierarchy.get_parent_store(world).for_each(fn(entity, parent) {
      if parent.entity().id == root.id {
        children.push(entity)
      }
    })
    child_count.val = children.length()

    let child = children[0]
    has_mesh.val = @pbr.get_mesh3d_store(world).contains(child)
    has_material.val = @pbr.get_mesh_material3d_store(world).contains(child)
    has_transform.val = @transform.get_transform_store(world).contains(child)
    has_visibility.val = @visibility.get_visibility_range_store(world).contains(
      child,
    )
    has_player.val = @animation.get_animation_player_store(world).contains(root)
    has_target.val = @animation.get_animation_target_id_store(world).contains(
      child,
    )
    has_animated_by.val = @animation.get_animated_by_store(world).contains(
      child,
    )

    @scene.scene_spawn_roots_system(world)
    let instance_second = get_scene_instance_store(world).get(root).unwrap()
    let ready_second = get_scene_instance_ready_store(world).get(root).unwrap()
    instance_after_second_tick.val = instance_second.instance_id
    ready_after_second_tick.val = ready_second.spawned_entities

    let children_second : Array[@core.Entity] = []
    @hierarchy.get_parent_store(world).for_each(fn(entity, parent) {
      if parent.entity().id == root.id {
        children_second.push(entity)
      }
    })
    child_count_after_second_tick.val = children_second.length()
  })
  inspect(instance_id.val, content="1")
  inspect(ready_instance_id.val, content="1")
  inspect(spawned_entities.val, content="1")
  inspect(child_count.val, content="1")
  inspect(child_count_after_second_tick.val, content="1")
  inspect(has_mesh.val, content="true")
  inspect(has_material.val, content="true")
  inspect(has_transform.val, content="true")
  inspect(has_visibility.val, content="true")
  inspect(has_player.val, content="true")
  inspect(has_target.val, content="true")
  inspect(has_animated_by.val, content="true")
  inspect(instance_after_second_tick.val, content="1")
  inspect(ready_after_second_tick.val, content="1")
}

///|
test "scene: SceneRoot change respawns children and updates SceneInstance" {
  let old_instance_id = Ref::new(0)
  let new_instance_id = Ref::new(0)
  let ready_instance_id = Ref::new(0)
  let spawned_entities = Ref::new(0)
  let old_child_alive = Ref::new(true)
  let new_child_count = Ref::new(0)
  let new_child_x = Ref::new(0.0)
  run_scene_test_app(fn(world : @ecs.World) {
    let first_tick = world.advance_sequence()
    ignore(first_tick)
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
    let first_scene = @scene.Scene::new([
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
    ])
    let second_scene = @scene.Scene::new([
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
    ])
    let first_handle = @scene.scene_register_gltf_scene(first_path, first_scene)
    let second_handle = @scene.scene_register_gltf_scene(
      second_path, second_scene,
    )

    let root = world.spawn_empty()
    get_scene_root_store(world).insert(
      root,
      @scene.SceneRoot::new(first_handle),
    )

    @scene.scene_spawn_roots_system(world)
    let first_instance = get_scene_instance_store(world).get(root).unwrap()
    old_instance_id.val = first_instance.instance_id

    let first_children : Array[@core.Entity] = []
    @hierarchy.get_parent_store(world).for_each(fn(entity, parent) {
      if parent.entity().id == root.id {
        first_children.push(entity)
      }
    })
    let first_child = first_children[0]

    get_scene_root_store(world).set(root, @scene.SceneRoot::new(second_handle))
    |> ignore

    @scene.scene_spawn_roots_system(world)

    let second_instance = get_scene_instance_store(world).get(root).unwrap()
    let ready = get_scene_instance_ready_store(world).get(root).unwrap()
    new_instance_id.val = second_instance.instance_id
    ready_instance_id.val = ready.instance_id
    spawned_entities.val = ready.spawned_entities
    old_child_alive.val = world.is_alive(first_child)

    let second_children : Array[@core.Entity] = []
    @hierarchy.get_parent_store(world).for_each(fn(entity, parent) {
      if parent.entity().id == root.id {
        second_children.push(entity)
      }
    })
    new_child_count.val = second_children.length()
    let new_child = second_children[0]
    let transform = @transform.get_transform_store(world)
      .get(new_child)
      .unwrap()
    new_child_x.val = transform.translation.x.to_double()
  })
  inspect(old_instance_id.val == new_instance_id.val, content="false")
  inspect(ready_instance_id.val == new_instance_id.val, content="true")
  inspect(spawned_entities.val, content="1")
  inspect(old_child_alive.val, content="false")
  inspect(new_child_count.val, content="1")
  inspect(new_child_x.val, content="9")
}

///|
test "scene: modified scene asset respawns SceneRoot children" {
  let handle_stable = Ref::new(false)
  let old_child_alive = Ref::new(true)
  let new_child_count = Ref::new(0)
  let new_child_x = Ref::new(0.0)
  run_scene_test_app(fn(world : @ecs.World) {
    let path = @gltf.GltfAssetLabel::Scene(0).from_asset("models/Foo/Foo.gltf")
    let material = @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(@sprite.Color::white()),
      ),
    )
    let first_scene = @scene.Scene::new([
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
    ])
    let second_scene = @scene.Scene::new([
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
    ])
    let handle = @scene.scene_register_gltf_scene(path, first_scene)

    let root = world.spawn_empty()
    get_scene_root_store(world).insert(root, @scene.SceneRoot::new(handle))

    @scene.scene_spawn_roots_system(world)

    let first_children : Array[@core.Entity] = []
    @hierarchy.get_parent_store(world).for_each(fn(entity, parent) {
      if parent.entity().id == root.id {
        first_children.push(entity)
      }
    })
    let first_child = first_children[0]

    let updated_handle = @scene.scene_register_gltf_scene(path, second_scene)
    handle_stable.val = handle.id() == updated_handle.id()

    @asset.asset_update_event_messages(world)
    @scene.scene_reload_modified_roots_system(world)
    @scene.scene_spawn_roots_system(world)

    old_child_alive.val = world.is_alive(first_child)
    let second_children : Array[@core.Entity] = []
    @hierarchy.get_parent_store(world).for_each(fn(entity, parent) {
      if parent.entity().id == root.id {
        second_children.push(entity)
      }
    })
    new_child_count.val = second_children.length()
    let new_child = second_children[0]
    let transform = @transform.get_transform_store(world)
      .get(new_child)
      .unwrap()
    new_child_x.val = transform.translation.x.to_double()
  })

  inspect(handle_stable.val, content="true")
  inspect(old_child_alive.val, content="false")
  inspect(new_child_count.val, content="1")
  inspect(new_child_x.val, content="9")
}
