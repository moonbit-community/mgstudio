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
  debug_inspect(scene_path, content="\"models/Foo/Foo.gltf#Scene3\"")
  debug_inspect(node_path, content="\"models/Foo/Foo.gltf#Node8\"")
  debug_inspect(
    primitive_path,
    content="\"models/Foo/Foo.gltf#Mesh5/Primitive2\"",
  )
  debug_inspect(
    morph_target_path,
    content="\"models/Foo/Foo.gltf#Mesh5/Primitive2/MorphTargets\"",
  )
  debug_inspect(
    inverted_material_path,
    content="\"models/Foo/Foo.gltf#Material4 (inverted)\"",
  )
  debug_inspect(
    default_material_path,
    content="\"models/Foo/Foo.gltf#DefaultMaterial\"",
  )
  debug_inspect(
    inverse_bind_matrices_path,
    content="\"models/Foo/Foo.gltf#Skin1/InverseBindMatrices\"",
  )
  debug_inspect(animation_path, content="\"models/Foo/Foo.gltf#Animation2\"")
  debug_inspect(
    replaced_label_path,
    content="\"remote://models/Foo/Foo.gltf#Scene1\"",
  )
}
