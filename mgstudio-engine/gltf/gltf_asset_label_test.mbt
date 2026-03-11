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
fn label_option_text(label : @gltf.GltfAssetLabel?) -> String {
  match label {
    Some(value) => "Some(" + value.to_label() + ")"
    None => "None"
  }
}

///|
test "gltf asset label path encoding" {
  let scene_path = @gltf.GltfAssetLabel::Scene(3).from_asset(
    "models/Foo/Foo.gltf",
  )
  let node_path = @gltf.GltfAssetLabel::Node(8).from_asset(
    "models/Foo/Foo.gltf",
  )
  let primitive_path = @gltf.GltfAssetLabel::Primitive(5, 2).from_asset(
    "models/Foo/Foo.gltf",
  )
  let morph_target_path = @gltf.GltfAssetLabel::MorphTarget(5, 2).from_asset(
    "models/Foo/Foo.gltf",
  )
  let inverted_material_path = @gltf.GltfAssetLabel::Material(4, true).from_asset(
    "models/Foo/Foo.gltf",
  )
  let default_material_path = @gltf.GltfAssetLabel::DefaultMaterial.from_asset(
    "models/Foo/Foo.gltf",
  )
  let inverse_bind_matrices_path = @gltf.GltfAssetLabel::InverseBindMatrices(1).from_asset(
    "models/Foo/Foo.gltf",
  )
  let animation_path = @gltf.GltfAssetLabel::Animation(2).from_asset(
    "models/Foo/Foo.gltf",
  )
  let replaced_label_path = @gltf.GltfAssetLabel::Scene(1).from_asset(
    "remote://models/Foo/Foo.gltf#Animation9",
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
  inspect(replaced_label_path, content="remote://models/Foo/Foo.gltf#Scene1")
}

///|
test "gltf asset label parsing and path split" {
  inspect(
    label_option_text(@gltf.GltfAssetLabel::parse("Mesh5/Primitive2")),
    content="Some(Mesh5/Primitive2)",
  )
  inspect(
    label_option_text(
      @gltf.GltfAssetLabel::parse("Mesh5/Primitive2/MorphTargets"),
    ),
    content="Some(Mesh5/Primitive2/MorphTargets)",
  )
  inspect(
    label_option_text(@gltf.GltfAssetLabel::parse("Material4 (inverted)")),
    content="Some(Material4 (inverted))",
  )
  inspect(
    label_option_text(@gltf.GltfAssetLabel::parse("Skin1/InverseBindMatrices")),
    content="Some(Skin1/InverseBindMatrices)",
  )
  inspect(
    label_option_text(@gltf.GltfAssetLabel::parse("DefaultMaterial")),
    content="Some(DefaultMaterial)",
  )
  inspect(
    label_option_text(@gltf.GltfAssetLabel::parse("Unknown12")),
    content="None",
  )

  let split_scene = @gltf.gltf_split_asset_path_with_label(
    "models/Foo/Foo.gltf#Scene7",
  )
  inspect(split_scene.0, content="models/Foo/Foo.gltf")
  inspect(label_option_text(split_scene.1), content="Some(Scene7)")

  let split_primitive = @gltf.gltf_split_asset_path_with_label(
    "models/Foo/Foo.gltf#Mesh2/Primitive1",
  )
  inspect(split_primitive.0, content="models/Foo/Foo.gltf")
  inspect(
    label_option_text(split_primitive.1),
    content="Some(Mesh2/Primitive1)",
  )

  let split_invalid = @gltf.gltf_split_asset_path_with_label(
    "models/Foo/Foo.gltf#SceneX",
  )
  inspect(split_invalid.0, content="models/Foo/Foo.gltf")
  inspect(label_option_text(split_invalid.1), content="None")
}
