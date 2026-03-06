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
  let asset_server = @asset.AssetServer::new()
  let path = @scene.GltfAssetLabel::Animation(1).from_asset(
    "models/Foo/Foo.gltf",
  )
  let first = @scene.scene_load_gltf_animation(asset_server, path)
  let second = @scene.scene_load_gltf_animation(asset_server, path)
  inspect(first.id() == second.id(), content="true")
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
test "scene: gltf lod visibility policy set/get/reset" {
  @scene.scene_reset_gltf_lod_visibility_policy()
  let default_policy = @scene.scene_get_gltf_lod_visibility_policy()
  inspect(default_policy.enabled, content="true")
  inspect(default_policy.step.to_double(), content="5")

  @scene.scene_set_gltf_lod_visibility_policy(
    default_policy
    .with_first_lod_range(1.0F, 2.0F, 6.0F, 7.0F)
    .with_step(3.0F)
    .with_enabled(false),
  )
  let customized = @scene.scene_get_gltf_lod_visibility_policy()
  inspect(customized.enabled, content="false")
  inspect(customized.first_start_margin_min.to_double(), content="1")
  inspect(customized.first_end_margin_max.to_double(), content="7")
  inspect(customized.step.to_double(), content="3")

  @scene.scene_reset_gltf_lod_visibility_policy()
  let restored = @scene.scene_get_gltf_lod_visibility_policy()
  inspect(restored.enabled, content="true")
  inspect(restored.first_end_margin_min.to_double(), content="3")
  inspect(restored.step.to_double(), content="5")
}

///|
test "scene: SceneRoot spawns children and marks ready" {
  let world = @ecs.World::new()
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
  inspect(ready.spawned_entities, content="1")

  let children : Array[@core.Entity] = []
  @hierarchy.get_parent_store(world).for_each(fn(entity, parent) {
    if parent.entity().id == root.id {
      children.push(entity)
    }
  })
  inspect(children.length(), content="1")

  let child = children[0]
  inspect(@render3d.get_mesh3d_store(world).contains(child), content="true")
  inspect(
    @render3d.get_mesh_material3d_store(world).contains(child),
    content="true",
  )
  inspect(@math.get_transform_store(world).contains(child), content="true")
  inspect(
    @visibility.get_visibility_range_store(world).contains(child),
    content="true",
  )
  inspect(
    @animation.get_animation_player_store(world).contains(root),
    content="true",
  )
  inspect(
    @animation.get_animation_target_id_store(world).contains(child),
    content="true",
  )
  inspect(
    @animation.get_animated_by_store(world).contains(child),
    content="true",
  )
}
