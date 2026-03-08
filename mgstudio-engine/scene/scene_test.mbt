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
fn label_option_text(label : @scene.GltfAssetLabel?) -> String {
  match label {
    Some(value) => "Some(" + value.to_label() + ")"
    None => "None"
  }
}

///|
fn run_scene_test_app(system : (@ecs.World) -> Unit) -> Unit {
  let plugins : Array[@app.Plugin[@ecs.World]] = [
    @asset.asset_plugin, @render2d.render2d_plugin_ecs, @render3d.render3d_plugin,
    @animation.animation_plugin, @scene.scene_plugin,
  ]
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_system(system)
  .run_once()
  |> ignore
}

///|
test "scene: gltf label path encoding" {
  let scene_path = @scene.GltfAssetLabel::Scene(3).from_asset(
    "models/Foo/Foo.gltf",
  )
  let node_path = @scene.GltfAssetLabel::Node(8).from_asset(
    "models/Foo/Foo.gltf",
  )
  let primitive_path = @scene.GltfAssetLabel::Primitive(5, 2).from_asset(
    "models/Foo/Foo.gltf",
  )
  let morph_target_path = @scene.GltfAssetLabel::MorphTarget(5, 2).from_asset(
    "models/Foo/Foo.gltf",
  )
  let inverted_material_path = @scene.GltfAssetLabel::Material(4, true).from_asset(
    "models/Foo/Foo.gltf",
  )
  let default_material_path = @scene.GltfAssetLabel::DefaultMaterial.from_asset(
    "models/Foo/Foo.gltf",
  )
  let inverse_bind_matrices_path = @scene.GltfAssetLabel::InverseBindMatrices(1).from_asset(
    "models/Foo/Foo.gltf",
  )
  let animation_path = @scene.GltfAssetLabel::Animation(2).from_asset(
    "models/Foo/Foo.gltf",
  )
  inspect(scene_path, content="models/Foo/Foo.gltf#Scene3")
  inspect(node_path, content="models/Foo/Foo.gltf#Node8")
  inspect(primitive_path, content="models/Foo/Foo.gltf#Mesh5/Primitive2")
  inspect(
    morph_target_path,
    content="models/Foo/Foo.gltf#Mesh5/Primitive2/MorphTargets",
  )
  inspect(
    inverted_material_path,
    content="models/Foo/Foo.gltf#Material4 (inverted)",
  )
  inspect(default_material_path, content="models/Foo/Foo.gltf#DefaultMaterial")
  inspect(
    inverse_bind_matrices_path,
    content="models/Foo/Foo.gltf#Skin1/InverseBindMatrices",
  )
  inspect(animation_path, content="models/Foo/Foo.gltf#Animation2")
}

///|
test "scene: gltf label parsing and path split" {
  inspect(
    label_option_text(@scene.GltfAssetLabel::parse("Mesh5/Primitive2")),
    content="Some(Mesh5/Primitive2)",
  )
  inspect(
    label_option_text(
      @scene.GltfAssetLabel::parse("Mesh5/Primitive2/MorphTargets"),
    ),
    content="Some(Mesh5/Primitive2/MorphTargets)",
  )
  inspect(
    label_option_text(@scene.GltfAssetLabel::parse("Material4 (inverted)")),
    content="Some(Material4 (inverted))",
  )
  inspect(
    label_option_text(@scene.GltfAssetLabel::parse("Skin1/InverseBindMatrices")),
    content="Some(Skin1/InverseBindMatrices)",
  )
  inspect(
    label_option_text(@scene.GltfAssetLabel::parse("DefaultMaterial")),
    content="Some(DefaultMaterial)",
  )
  inspect(
    label_option_text(@scene.GltfAssetLabel::parse("Unknown12")),
    content="None",
  )

  let split_scene = @scene.gltf_split_asset_path_with_label(
    "models/Foo/Foo.gltf#Scene7",
  )
  inspect(split_scene.0, content="models/Foo/Foo.gltf")
  inspect(label_option_text(split_scene.1), content="Some(Scene7)")

  let split_primitive = @scene.gltf_split_asset_path_with_label(
    "models/Foo/Foo.gltf#Mesh2/Primitive1",
  )
  inspect(split_primitive.0, content="models/Foo/Foo.gltf")
  inspect(
    label_option_text(split_primitive.1),
    content="Some(Mesh2/Primitive1)",
  )

  let split_invalid = @scene.gltf_split_asset_path_with_label(
    "models/Foo/Foo.gltf#SceneX",
  )
  inspect(split_invalid.0, content="models/Foo/Foo.gltf")
  inspect(label_option_text(split_invalid.1), content="None")
}

///|
test "scene: load gltf animation keeps stable handle" {
  let same_handle = Ref::new(false)
  run_scene_test_app(fn(_world : @ecs.World) {
    let asset_server = @asset.AssetServer::new()
    let path = @scene.GltfAssetLabel::Animation(1).from_asset(
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
    let path = @scene.GltfAssetLabel::Primitive(0, 0).from_asset(
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
    let path = @scene.GltfAssetLabel::Primitive(0, 0).from_asset(
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
    let path = @scene.GltfAssetLabel::Scene(0).from_asset("models/Foo/Foo.gltf")
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
  let spawned_entities = Ref::new(0)
  let child_count = Ref::new(0)
  let has_mesh = Ref::new(false)
  let has_material = Ref::new(false)
  let has_transform = Ref::new(false)
  let has_visibility = Ref::new(false)
  let has_player = Ref::new(false)
  let has_target = Ref::new(false)
  let has_animated_by = Ref::new(false)
  run_scene_test_app(fn(world : @ecs.World) {
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
      tick,
    )

    @scene.scene_spawn_roots_system(world)

    let ready = get_scene_instance_ready_store(world).get(root).unwrap()
    spawned_entities.val = ready.spawned_entities

    let children : Array[@core.Entity] = []
    @hierarchy.get_parent_store(world).for_each(fn(entity, parent) {
      if parent.entity().id == root.id {
        children.push(entity)
      }
    })
    child_count.val = children.length()

    let child = children[0]
    has_mesh.val = @render3d.get_mesh3d_store(world).contains(child)
    has_material.val = @render3d.get_mesh_material3d_store(world).contains(
      child,
    )
    has_transform.val = @math.get_transform_store(world).contains(child)
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
  })
  inspect(spawned_entities.val, content="1")
  inspect(child_count.val, content="1")
  inspect(has_mesh.val, content="true")
  inspect(has_material.val, content="true")
  inspect(has_transform.val, content="true")
  inspect(has_visibility.val, content="true")
  inspect(has_player.val, content="true")
  inspect(has_target.val, content="true")
  inspect(has_animated_by.val, content="true")
}
