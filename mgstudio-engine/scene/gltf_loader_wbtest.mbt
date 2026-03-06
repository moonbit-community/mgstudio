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
fn bytes_ascii(input : String) -> Bytes {
  let out : Array[Byte] = []
  for c in input {
    out.push((c.to_int() & 0xFF).to_byte())
  }
  Bytes::from_array(out)
}

///|
fn push_u32_le(out : Array[Byte], value : UInt) -> Unit {
  out.push((value & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 8) & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 16) & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 24) & 0xFFU).reinterpret_as_int().to_byte())
}

///|
fn push_f32_le(out : Array[Byte], value : Float) -> Unit {
  push_u32_le(out, value.reinterpret_as_uint())
}

///|
fn sampler_tag(sampler : @asset.ImageSampler) -> Int {
  match sampler {
    @asset.ImageSampler::Linear => 0
    @asset.ImageSampler::LinearRepeat => 1
    @asset.ImageSampler::Nearest => 2
    @asset.ImageSampler::NearestRepeat => 3
  }
}

///|
fn label_option_text(label : GltfAssetLabel?) -> String {
  match label {
    Some(value) => "Some(" + value.to_label() + ")"
    None => "None"
  }
}

///|
test "scene gltf wb: decode data uri base64" {
  let decoded = data_uri_decode_bytes(
    "data:application/octet-stream;base64,AAEC/w==",
  ).unwrap()
  inspect(decoded.length(), content="4")
  inspect(decoded[0].to_int() & 0xFF, content="0")
  inspect(decoded[1].to_int() & 0xFF, content="1")
  inspect(decoded[2].to_int() & 0xFF, content="2")
  inspect(decoded[3].to_int() & 0xFF, content="255")
}

///|
test "scene gltf wb: decode data uri percent encoding" {
  let decoded = data_uri_decode_bytes("data:text/plain,AB%20C").unwrap()
  inspect(decoded.length(), content="4")
  inspect(decoded[0].to_int() & 0xFF, content="65")
  inspect(decoded[1].to_int() & 0xFF, content="66")
  inspect(decoded[2].to_int() & 0xFF, content="32")
  inspect(decoded[3].to_int() & 0xFF, content="67")
}

///|
test "scene gltf wb: parse glb container" {
  let json = "{" +
    "\"asset\":{\"version\":\"2.0\"}," +
    "\"scene\":0," +
    "\"scenes\":[{\"nodes\":[]}]," +
    "\"nodes\":[]," +
    "\"meshes\":[]," +
    "\"buffers\":[{\"byteLength\":0}]" +
    "}"
  let payload : Array[Byte] = bytes_ascii(json).to_array()
  let space : Int = 0x20
  while payload.length() % 4 != 0 {
    payload.push(space.to_byte())
  }

  let glb : Array[Byte] = []
  let total = 12 + 8 + payload.length()
  push_u32_le(glb, 0x46546C67U)
  push_u32_le(glb, 2U)
  push_u32_le(glb, total.reinterpret_as_uint())
  push_u32_le(glb, payload.length().reinterpret_as_uint())
  push_u32_le(glb, 0x4E4F534AU)
  for b in payload {
    glb.push(b)
  }

  let parsed = gltf_parse_glb(Bytes::from_array(glb)).unwrap()
  inspect(parsed.0.contains("\"asset\""), content="true")
  inspect(parsed.1 == None, content="true")

  let doc = gltf_parse_document(parsed.0).unwrap()
  inspect(doc.buffers.length(), content="1")
}

///|
test "scene gltf wb: read vec3 from second buffer" {
  let source = "{" +
    "\"asset\":{\"version\":\"2.0\"}," +
    "\"scene\":0," +
    "\"scenes\":[{\"nodes\":[0]}]," +
    "\"nodes\":[{\"mesh\":0}]," +
    "\"meshes\":[{\"primitives\":[{\"attributes\":{\"POSITION\":0}}]}]," +
    "\"buffers\":[{\"byteLength\":0},{\"byteLength\":12}]," +
    "\"bufferViews\":[{\"buffer\":1,\"byteOffset\":0,\"byteLength\":12}]," +
    "\"accessors\":[{\"bufferView\":0,\"componentType\":5126,\"count\":1,\"type\":\"VEC3\"}]" +
    "}"
  let doc = gltf_parse_document(source).unwrap()

  let raw : Array[Byte] = []
  push_f32_le(raw, 1.0F)
  push_f32_le(raw, 2.0F)
  push_f32_le(raw, 3.0F)

  let vecs = gltf_read_accessor_vec3(
    doc,
    [Bytes::new(0), Bytes::from_array(raw)],
    0,
  ).unwrap()
  inspect(vecs.length(), content="1")
  inspect(vecs[0].x.to_double(), content="1")
  inspect(vecs[0].y.to_double(), content="2")
  inspect(vecs[0].z.to_double(), content="3")
}

///|
test "scene gltf wb: image bufferView bytes" {
  let source = "{" +
    "\"asset\":{\"version\":\"2.0\"}," +
    "\"scene\":0," +
    "\"scenes\":[{\"nodes\":[]}]," +
    "\"nodes\":[]," +
    "\"meshes\":[]," +
    "\"buffers\":[{\"byteLength\":4}]," +
    "\"bufferViews\":[{\"buffer\":0,\"byteOffset\":1,\"byteLength\":2}]," +
    "\"images\":[{\"bufferView\":0,\"mimeType\":\"image/png\"}]" +
    "}"
  let doc = gltf_parse_document(source).unwrap()
  inspect(doc.images.length(), content="1")
  inspect(doc.images[0].buffer_view, content="Some(0)")
  inspect(doc.images[0].mime_type, content="Some(\"image/png\")")

  let bytes = gltf_buffer_view_bytes(
    doc,
    [
      Bytes::from_array([
        (10).to_byte(),
        (20).to_byte(),
        (30).to_byte(),
        (40).to_byte(),
      ]),
    ],
    0,
  ).unwrap()
  inspect(bytes.length(), content="2")
  inspect(bytes[0].to_int() & 0xFF, content="20")
  inspect(bytes[1].to_int() & 0xFF, content="30")
}

///|
test "scene gltf wb: parse sampler and texture mapping" {
  let source = "{" +
    "\"asset\":{\"version\":\"2.0\"}," +
    "\"scene\":0," +
    "\"scenes\":[{\"nodes\":[]}]," +
    "\"nodes\":[]," +
    "\"meshes\":[]," +
    "\"samplers\":[" +
    "{\"magFilter\":9728,\"wrapS\":10497,\"wrapT\":10497}," +
    "{\"minFilter\":9984,\"wrapS\":33071,\"wrapT\":33071}" +
    "]," +
    "\"textures\":[" +
    "{\"sampler\":0}," +
    "{\"sampler\":1}," +
    "{}" +
    "]" +
    "}"
  let doc = gltf_parse_document(source).unwrap()
  inspect(doc.samplers.length(), content="2")
  inspect(doc.samplers[0].nearest, content="true")
  inspect(doc.samplers[0].repeat, content="true")
  inspect(doc.samplers[1].nearest, content="true")
  inspect(doc.samplers[1].repeat, content="false")
  inspect(sampler_tag(gltf_texture_image_sampler(doc, 0)), content="3")
  inspect(sampler_tag(gltf_texture_image_sampler(doc, 1)), content="2")
  inspect(sampler_tag(gltf_texture_image_sampler(doc, 2)), content="1")
}

///|
test "scene gltf wb: parse KHR_texture_transform on base color texture" {
  let source = "{" +
    "\"asset\":{\"version\":\"2.0\"}," +
    "\"scene\":0," +
    "\"scenes\":[{\"nodes\":[]}]," +
    "\"nodes\":[]," +
    "\"meshes\":[]," +
    "\"materials\":[{" +
    "\"pbrMetallicRoughness\":{" +
    "\"baseColorTexture\":{" +
    "\"index\":3," +
    "\"extensions\":{" +
    "\"KHR_texture_transform\":{" +
    "\"offset\":[0.25,0.5]," +
    "\"scale\":[2.0,0.5]" +
    "}" +
    "}" +
    "}" +
    "}" +
    "}]" +
    "}"
  let doc = gltf_parse_document(source).unwrap()
  inspect(doc.materials.length(), content="1")
  inspect(doc.materials[0].base_color_texture, content="Some(3)")
  inspect(doc.materials[0].base_color_uv_offset.x.to_double(), content="0.25")
  inspect(doc.materials[0].base_color_uv_offset.y.to_double(), content="0.5")
  inspect(doc.materials[0].base_color_uv_scale.x.to_double(), content="2")
  inspect(doc.materials[0].base_color_uv_scale.y.to_double(), content="0.5")
}

///|
test "scene gltf wb: parse KHR_materials_clearcoat" {
  let source = "{" +
    "\"asset\":{\"version\":\"2.0\"}," +
    "\"scene\":0," +
    "\"scenes\":[{\"nodes\":[]}]," +
    "\"nodes\":[]," +
    "\"meshes\":[]," +
    "\"materials\":[{" +
    "\"extensions\":{" +
    "\"KHR_materials_clearcoat\":{" +
    "\"clearcoatFactor\":0.7," +
    "\"clearcoatRoughnessFactor\":0.2," +
    "\"clearcoatTexture\":{\"index\":3}," +
    "\"clearcoatRoughnessTexture\":{\"index\":4}," +
    "\"clearcoatNormalTexture\":{\"index\":5}" +
    "}" +
    "}" +
    "}]" +
    "}"
  let doc = gltf_parse_document(source).unwrap()
  inspect(doc.materials.length(), content="1")
  inspect(doc.materials[0].clearcoat.to_double(), content="0.699999988079071")
  inspect(
    doc.materials[0].clearcoat_roughness.to_double(),
    content="0.20000000298023224",
  )
  inspect(doc.materials[0].clearcoat_texture, content="Some(3)")
  inspect(doc.materials[0].clearcoat_roughness_texture, content="Some(4)")
  inspect(doc.materials[0].clearcoat_normal_texture, content="Some(5)")
}

///|
test "scene gltf wb: parse KHR_materials_anisotropy" {
  let source = "{" +
    "\"asset\":{\"version\":\"2.0\"}," +
    "\"scene\":0," +
    "\"scenes\":[{\"nodes\":[]}]," +
    "\"nodes\":[]," +
    "\"meshes\":[]," +
    "\"materials\":[{" +
    "\"extensions\":{" +
    "\"KHR_materials_anisotropy\":{" +
    "\"anisotropyStrength\":0.6," +
    "\"anisotropyRotation\":1.25," +
    "\"anisotropyTexture\":{\"index\":7}" +
    "}" +
    "}" +
    "}]" +
    "}"
  let doc = gltf_parse_document(source).unwrap()
  inspect(doc.materials.length(), content="1")
  inspect(
    doc.materials[0].anisotropy_strength >= 0.59F &&
    doc.materials[0].anisotropy_strength <= 0.61F,
    content="true",
  )
  inspect(
    doc.materials[0].anisotropy_rotation >= 1.24F &&
    doc.materials[0].anisotropy_rotation <= 1.26F,
    content="true",
  )
  inspect(doc.materials[0].anisotropy_texture, content="Some(7)")
}

///|
test "scene gltf wb: parse node MSFT_lod ids" {
  let source = "{" +
    "\"asset\":{\"version\":\"2.0\"}," +
    "\"scene\":0," +
    "\"scenes\":[{\"nodes\":[0]}]," +
    "\"nodes\":[" +
    "{\"mesh\":0,\"extensions\":{\"MSFT_lod\":{\"ids\":[1,2]}}}," +
    "{\"mesh\":1}," +
    "{\"mesh\":2}" +
    "]," +
    "\"meshes\":[]" +
    "}"
  let doc = gltf_parse_document(source).unwrap()
  inspect(doc.nodes.length(), content="3")
  inspect(doc.nodes[0].lod_nodes.length(), content="2")
  inspect(doc.nodes[0].lod_nodes[0], content="1")
  inspect(doc.nodes[0].lod_nodes[1], content="2")
}

///|
test "scene gltf wb: default visibility ranges for lod levels" {
  scene_reset_gltf_lod_visibility_policy()
  let lod0 = gltf_lod_visibility_range(0).unwrap()
  inspect(lod0.start_margin_min.to_double(), content="0")
  inspect(lod0.start_margin_max.to_double(), content="0")
  inspect(lod0.end_margin_min.to_double(), content="3")
  inspect(lod0.end_margin_max.to_double(), content="4")

  let lod1 = gltf_lod_visibility_range(1).unwrap()
  inspect(lod1.start_margin_min.to_double(), content="3")
  inspect(lod1.start_margin_max.to_double(), content="4")
  inspect(lod1.end_margin_min.to_double(), content="8")
  inspect(lod1.end_margin_max.to_double(), content="9")

  let lod2 = gltf_lod_visibility_range(2).unwrap()
  inspect(lod2.start_margin_min.to_double(), content="8")
  inspect(lod2.start_margin_max.to_double(), content="9")
  inspect(lod2.end_margin_min.to_double(), content="13")
  inspect(lod2.end_margin_max.to_double(), content="14")
}

///|
test "scene gltf wb: custom lod visibility policy and disable switch" {
  scene_set_gltf_lod_visibility_policy(
    GltfLodVisibilityPolicy::default()
    .with_first_lod_range(1.0F, 2.0F, 11.0F, 12.0F)
    .with_step(2.0F),
  )
  let lod0 = gltf_lod_visibility_range(0).unwrap()
  inspect(lod0.start_margin_min.to_double(), content="1")
  inspect(lod0.start_margin_max.to_double(), content="2")
  inspect(lod0.end_margin_min.to_double(), content="11")
  inspect(lod0.end_margin_max.to_double(), content="12")

  let lod2 = gltf_lod_visibility_range(2).unwrap()
  inspect(lod2.start_margin_min.to_double(), content="13")
  inspect(lod2.start_margin_max.to_double(), content="14")
  inspect(lod2.end_margin_min.to_double(), content="15")
  inspect(lod2.end_margin_max.to_double(), content="16")

  scene_set_gltf_lod_visibility_policy(
    scene_get_gltf_lod_visibility_policy().with_enabled(false),
  )
  let disabled_is_none = match gltf_lod_visibility_range(0) {
    None => true
    Some(_) => false
  }
  inspect(disabled_is_none, content="true")
  scene_reset_gltf_lod_visibility_policy()
}

///|
test "scene gltf wb: parse animation channels and samplers" {
  let source = "{" +
    "\"asset\":{\"version\":\"2.0\"}," +
    "\"scene\":0," +
    "\"scenes\":[{\"nodes\":[0]}]," +
    "\"nodes\":[{\"children\":[1]},{}]," +
    "\"meshes\":[]," +
    "\"buffers\":[{\"byteLength\":104}]," +
    "\"bufferViews\":[" +
    "{\"buffer\":0,\"byteOffset\":0,\"byteLength\":8}," +
    "{\"buffer\":0,\"byteOffset\":8,\"byteLength\":24}," +
    "{\"buffer\":0,\"byteOffset\":32,\"byteLength\":32}," +
    "{\"buffer\":0,\"byteOffset\":64,\"byteLength\":24}," +
    "{\"buffer\":0,\"byteOffset\":88,\"byteLength\":16}" +
    "]," +
    "\"accessors\":[" +
    "{\"bufferView\":0,\"componentType\":5126,\"count\":2,\"type\":\"SCALAR\"}," +
    "{\"bufferView\":1,\"componentType\":5126,\"count\":2,\"type\":\"VEC3\"}," +
    "{\"bufferView\":2,\"componentType\":5126,\"count\":2,\"type\":\"VEC4\"}," +
    "{\"bufferView\":3,\"componentType\":5126,\"count\":2,\"type\":\"VEC3\"}," +
    "{\"bufferView\":4,\"componentType\":5126,\"count\":4,\"type\":\"SCALAR\"}" +
    "]," +
    "\"animations\":[{" +
    "\"samplers\":[" +
    "{\"input\":0,\"output\":1,\"interpolation\":\"LINEAR\"}," +
    "{\"input\":0,\"output\":2,\"interpolation\":\"STEP\"}," +
    "{\"input\":0,\"output\":3,\"interpolation\":\"CUBICSPLINE\"}," +
    "{\"input\":0,\"output\":4}" +
    "]," +
    "\"channels\":[" +
    "{\"sampler\":0,\"target\":{\"node\":0,\"path\":\"translation\"}}," +
    "{\"sampler\":1,\"target\":{\"node\":1,\"path\":\"rotation\"}}," +
    "{\"sampler\":2,\"target\":{\"node\":0,\"path\":\"scale\"}}," +
    "{\"sampler\":3,\"target\":{\"node\":1,\"path\":\"weights\"}}" +
    "]" +
    "}]" +
    "}"
  let doc = gltf_parse_document(source).unwrap()
  inspect(doc.animations.length(), content="1")
  inspect(doc.animations[0].samplers.length(), content="4")
  inspect(doc.animations[0].channels.length(), content="4")
  inspect(doc.animations[0].samplers[1].is_cubic_spline, content="false")
  inspect(doc.animations[0].samplers[2].is_cubic_spline, content="true")
  inspect(doc.animations[0].channels[3].target_path, content="weights")
}

///|
test "scene gltf wb: build animation clip tracks and fallback node paths" {
  let source = "{" +
    "\"asset\":{\"version\":\"2.0\"}," +
    "\"scene\":0," +
    "\"scenes\":[{\"nodes\":[0]}]," +
    "\"nodes\":[{\"children\":[1]},{}]," +
    "\"meshes\":[]," +
    "\"buffers\":[{\"byteLength\":104}]," +
    "\"bufferViews\":[" +
    "{\"buffer\":0,\"byteOffset\":0,\"byteLength\":8}," +
    "{\"buffer\":0,\"byteOffset\":8,\"byteLength\":24}," +
    "{\"buffer\":0,\"byteOffset\":32,\"byteLength\":32}," +
    "{\"buffer\":0,\"byteOffset\":64,\"byteLength\":24}," +
    "{\"buffer\":0,\"byteOffset\":88,\"byteLength\":16}" +
    "]," +
    "\"accessors\":[" +
    "{\"bufferView\":0,\"componentType\":5126,\"count\":2,\"type\":\"SCALAR\"}," +
    "{\"bufferView\":1,\"componentType\":5126,\"count\":2,\"type\":\"VEC3\"}," +
    "{\"bufferView\":2,\"componentType\":5126,\"count\":2,\"type\":\"VEC4\"}," +
    "{\"bufferView\":3,\"componentType\":5126,\"count\":2,\"type\":\"VEC3\"}," +
    "{\"bufferView\":4,\"componentType\":5126,\"count\":4,\"type\":\"SCALAR\"}" +
    "]," +
    "\"animations\":[{" +
    "\"samplers\":[" +
    "{\"input\":0,\"output\":1,\"interpolation\":\"LINEAR\"}," +
    "{\"input\":0,\"output\":2,\"interpolation\":\"STEP\"}," +
    "{\"input\":0,\"output\":3,\"interpolation\":\"CUBICSPLINE\"}," +
    "{\"input\":0,\"output\":4}" +
    "]," +
    "\"channels\":[" +
    "{\"sampler\":0,\"target\":{\"node\":0,\"path\":\"translation\"}}," +
    "{\"sampler\":1,\"target\":{\"node\":1,\"path\":\"rotation\"}}," +
    "{\"sampler\":2,\"target\":{\"node\":0,\"path\":\"scale\"}}," +
    "{\"sampler\":3,\"target\":{\"node\":1,\"path\":\"weights\"}}" +
    "]" +
    "}]" +
    "}"
  let doc = gltf_parse_document(source).unwrap()
  let raw : Array[Byte] = []
  // input timestamps
  push_f32_le(raw, 0.0F)
  push_f32_le(raw, 1.0F)
  // translation values
  push_f32_le(raw, 1.0F)
  push_f32_le(raw, 2.0F)
  push_f32_le(raw, 3.0F)
  push_f32_le(raw, 4.0F)
  push_f32_le(raw, 5.0F)
  push_f32_le(raw, 6.0F)
  // rotation values
  push_f32_le(raw, 0.0F)
  push_f32_le(raw, 0.0F)
  push_f32_le(raw, 0.0F)
  push_f32_le(raw, 1.0F)
  push_f32_le(raw, 0.0F)
  push_f32_le(raw, 0.70710677F)
  push_f32_le(raw, 0.0F)
  push_f32_le(raw, 0.70710677F)
  // scale values
  push_f32_le(raw, 1.0F)
  push_f32_le(raw, 1.0F)
  push_f32_le(raw, 1.0F)
  push_f32_le(raw, 2.0F)
  push_f32_le(raw, 2.0F)
  push_f32_le(raw, 2.0F)
  // weights values
  push_f32_le(raw, 0.1F)
  push_f32_le(raw, 0.9F)
  push_f32_le(raw, 0.2F)
  push_f32_le(raw, 0.8F)

  let clip = scene_build_animation_clip_from_gltf(0, doc, [
    Bytes::from_array(raw),
  ])
  inspect(clip.duration().to_double(), content="1")

  let target0 = @animation.AnimationTargetId::from_names(["GltfNode0"])
  let target1 = @animation.AnimationTargetId::from_names([
    "GltfNode0", "GltfNode1",
  ])

  let sample0 = clip.sample_target(target0, 1.0F).unwrap()
  let sample1 = clip.sample_target(target1, 1.0F).unwrap()

  let translation = sample0.translation().unwrap()
  inspect(translation.x.to_double(), content="4")
  inspect(translation.z.to_double(), content="6")

  let scale = sample0.scale().unwrap()
  inspect(scale.x.to_double(), content="2")
  inspect(scale.y.to_double(), content="2")

  let rotation = sample1.rotation().unwrap()
  inspect(rotation.w >= 0.70F && rotation.w <= 0.71F, content="true")

  let weights = sample1.weights().unwrap()
  inspect(weights.length(), content="2")
  inspect(weights[0] >= 0.19F && weights[0] <= 0.21F, content="true")
  inspect(weights[1] >= 0.79F && weights[1] <= 0.81F, content="true")
}

///|
test "scene gltf wb: split labeled gltf path with extended labels" {
  let scene_label = scene_split_gltf_asset_path("models/Foo/Foo.gltf#Scene2")
  inspect(scene_label.0, content="models/Foo/Foo.gltf")
  inspect(label_option_text(scene_label.1), content="Some(Scene2)")

  let primitive_label = scene_split_gltf_asset_path(
    "models/Foo/Foo.gltf#Mesh3/Primitive1",
  )
  inspect(primitive_label.0, content="models/Foo/Foo.gltf")
  inspect(
    label_option_text(primitive_label.1),
    content="Some(Mesh3/Primitive1)",
  )

  let inverse_bind_label = scene_split_gltf_asset_path(
    "models/Foo/Foo.gltf#Skin4/InverseBindMatrices",
  )
  inspect(
    label_option_text(inverse_bind_label.1),
    content="Some(Skin4/InverseBindMatrices)",
  )

  let unknown_label = scene_split_gltf_asset_path(
    "models/Foo/Foo.gltf#NotALabel",
  )
  inspect(unknown_label.0, content="models/Foo/Foo.gltf")
  inspect(label_option_text(unknown_label.1), content="None")
}
