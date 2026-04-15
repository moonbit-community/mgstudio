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
fn sampler_descriptor_or_abort(
  sampler : @asset.ImageSampler,
) -> @asset.ImageSamplerDescriptor {
  match sampler {
    @asset.ImageSampler::Default =>
      abort("expected gltf texture sampler descriptor")
    @asset.ImageSampler::Descriptor(descriptor) => descriptor
  }
}

///|
fn label_text(label : GltfAssetLabel) -> String {
  match label {
    Scene(index) => "Scene\{index.to_string()}"
    Node(index) => "Node\{index.to_string()}"
    Mesh(index) => "Mesh\{index.to_string()}"
    Primitive(mesh, primitive) =>
      "Mesh\{mesh.to_string()}/Primitive\{primitive.to_string()}"
    MorphTarget(mesh, primitive) =>
      "Mesh\{mesh.to_string()}/Primitive\{primitive.to_string()}/MorphTargets"
    Texture(index) => "Texture\{index.to_string()}"
    Material(index, is_scale_inverted) => {
      let suffix = if is_scale_inverted { " (inverted)" } else { "" }
      "Material\{index.to_string()}\{suffix}"
    }
    DefaultMaterial => "DefaultMaterial"
    Animation(index) => "Animation\{index.to_string()}"
    Skin(index) => "Skin\{index.to_string()}"
    InverseBindMatrices(index) => "Skin\{index.to_string()}/InverseBindMatrices"
  }
}

///|
fn label_option_text(label : GltfAssetLabel?) -> String {
  match label {
    Some(value) => "Some(\{label_text(value)})"
    None => "None"
  }
}

///|
test "scene gltf wb: decode data uri base64" {
  let decoded = data_uri_decode_bytes(
    "data:application/octet-stream;base64,AAEC/w==",
  ).unwrap()
  debug_inspect(decoded.length(), content="4")
  debug_inspect(decoded[0].to_int() & 0xFF, content="0")
  debug_inspect(decoded[1].to_int() & 0xFF, content="1")
  debug_inspect(decoded[2].to_int() & 0xFF, content="2")
  debug_inspect(decoded[3].to_int() & 0xFF, content="255")
}

///|
test "scene gltf wb: decode data uri percent encoding" {
  let decoded = data_uri_decode_bytes("data:text/plain,AB%20C").unwrap()
  debug_inspect(decoded.length(), content="4")
  debug_inspect(decoded[0].to_int() & 0xFF, content="65")
  debug_inspect(decoded[1].to_int() & 0xFF, content="66")
  debug_inspect(decoded[2].to_int() & 0xFF, content="32")
  debug_inspect(decoded[3].to_int() & 0xFF, content="67")
}

///|
test "scene gltf wb: parse glb container" {
  let json = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[]}],\"nodes\":[],\"meshes\":[],\"buffers\":[{\"byteLength\":0}]}"
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
  debug_inspect(parsed.0.contains("\"asset\""), content="true")
  debug_inspect(parsed.1 == None, content="true")

  let doc = gltf_parse_document(parsed.0).unwrap()
  debug_inspect(doc.buffers.length(), content="1")
}

///|
test "scene gltf wb: read vec3 from second buffer" {
  let source = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[0]}],\"nodes\":[{\"mesh\":0}],\"meshes\":[{\"primitives\":[{\"attributes\":{\"POSITION\":0}}]}],\"buffers\":[{\"byteLength\":0},{\"byteLength\":12}],\"bufferViews\":[{\"buffer\":1,\"byteOffset\":0,\"byteLength\":12}],\"accessors\":[{\"bufferView\":0,\"componentType\":5126,\"count\":1,\"type\":\"VEC3\"}]}"
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
  debug_inspect(vecs.length(), content="1")
  debug_inspect(vecs[0].x.to_double(), content="1")
  debug_inspect(vecs[0].y.to_double(), content="2")
  debug_inspect(vecs[0].z.to_double(), content="3")
}

///|
test "scene gltf wb: image bufferView bytes" {
  let source = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[]}],\"nodes\":[],\"meshes\":[],\"buffers\":[{\"byteLength\":4}],\"bufferViews\":[{\"buffer\":0,\"byteOffset\":1,\"byteLength\":2}],\"images\":[{\"bufferView\":0,\"mimeType\":\"image/png\"}]}"
  let doc = gltf_parse_document(source).unwrap()
  debug_inspect(doc.images.length(), content="1")
  debug_inspect(doc.images[0].buffer_view, content="Some(0)")
  debug_inspect(doc.images[0].mime_type, content="Some(\"image/png\")")

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
  debug_inspect(bytes.length(), content="2")
  debug_inspect(bytes[0].to_int() & 0xFF, content="20")
  debug_inspect(bytes[1].to_int() & 0xFF, content="30")
}

///|
test "scene gltf wb: parse sampler and texture mapping" {
  let source = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[]}],\"nodes\":[],\"meshes\":[],\"samplers\":[{\"magFilter\":9728,\"minFilter\":9987,\"wrapS\":10497,\"wrapT\":33648},{\"minFilter\":9984,\"wrapS\":33071,\"wrapT\":33071}],\"textures\":[{\"sampler\":0},{\"sampler\":1},{}]}"
  let doc = gltf_parse_document(source).unwrap()
  debug_inspect(doc.samplers.length(), content="2")
  debug_inspect(doc.samplers[0].mag_filter, content="Some(9728)")
  debug_inspect(doc.samplers[0].min_filter, content="Some(9987)")
  debug_inspect(doc.samplers[0].wrap_s, content="Some(10497)")
  debug_inspect(doc.samplers[0].wrap_t, content="Some(33648)")
  debug_inspect(doc.samplers[1].mag_filter, content="None")
  debug_inspect(doc.samplers[1].min_filter, content="Some(9984)")
  debug_inspect(doc.samplers[1].wrap_s, content="Some(33071)")
  debug_inspect(doc.samplers[1].wrap_t, content="Some(33071)")
  let default_sampler = @image.ImageSamplerDescriptor::linear()
  default_sampler.set_address_mode(@image.ImageAddressMode::Repeat) |> ignore
  let descriptor0 = sampler_descriptor_or_abort(
    gltf_texture_image_sampler(doc, 0, default_sampler, false),
  )
  debug_inspect(
    descriptor0.address_mode_u == @asset.ImageAddressMode::Repeat,
    content="true",
  )
  debug_inspect(
    descriptor0.address_mode_v == @asset.ImageAddressMode::MirrorRepeat,
    content="true",
  )
  debug_inspect(
    descriptor0.mag_filter == @asset.ImageFilterMode::Nearest,
    content="true",
  )
  debug_inspect(
    descriptor0.min_filter == @asset.ImageFilterMode::Linear,
    content="true",
  )
  debug_inspect(
    descriptor0.mipmap_filter == @asset.ImageFilterMode::Linear,
    content="true",
  )

  let descriptor1 = sampler_descriptor_or_abort(
    gltf_texture_image_sampler(doc, 1, default_sampler, false),
  )
  debug_inspect(
    descriptor1.address_mode_u == @asset.ImageAddressMode::ClampToEdge,
    content="true",
  )
  debug_inspect(
    descriptor1.address_mode_v == @asset.ImageAddressMode::ClampToEdge,
    content="true",
  )
  debug_inspect(
    descriptor1.mag_filter == @asset.ImageFilterMode::Linear,
    content="true",
  )
  debug_inspect(
    descriptor1.min_filter == @asset.ImageFilterMode::Nearest,
    content="true",
  )
  debug_inspect(
    descriptor1.mipmap_filter == @asset.ImageFilterMode::Nearest,
    content="true",
  )

  let descriptor2 = sampler_descriptor_or_abort(
    gltf_texture_image_sampler(doc, 2, default_sampler, false),
  )
  debug_inspect(
    descriptor2.address_mode_u == @asset.ImageAddressMode::Repeat,
    content="true",
  )
  debug_inspect(
    descriptor2.address_mode_v == @asset.ImageAddressMode::Repeat,
    content="true",
  )
  debug_inspect(
    descriptor2.mag_filter == @asset.ImageFilterMode::Linear,
    content="true",
  )
  debug_inspect(
    descriptor2.min_filter == @asset.ImageFilterMode::Linear,
    content="true",
  )
}

///|
test "scene gltf wb: anisotropic default sampler skips gltf filters" {
  let source = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[]}],\"nodes\":[],\"meshes\":[],\"samplers\":[{\"magFilter\":9728,\"minFilter\":9984,\"wrapS\":33071,\"wrapT\":33071}],\"textures\":[{\"sampler\":0}]}"
  let doc = gltf_parse_document(source).unwrap()
  let default_sampler = @image.ImageSamplerDescriptor::linear()
  default_sampler.set_address_mode(@image.ImageAddressMode::Repeat) |> ignore
  default_sampler.set_anisotropic_filter(4) |> ignore
  let descriptor = sampler_descriptor_or_abort(
    gltf_texture_image_sampler(doc, 0, default_sampler, false),
  )
  debug_inspect(
    descriptor.address_mode_u == @asset.ImageAddressMode::ClampToEdge,
    content="true",
  )
  debug_inspect(
    descriptor.address_mode_v == @asset.ImageAddressMode::ClampToEdge,
    content="true",
  )
  debug_inspect(
    descriptor.mag_filter == @asset.ImageFilterMode::Linear,
    content="true",
  )
  debug_inspect(
    descriptor.min_filter == @asset.ImageFilterMode::Linear,
    content="true",
  )
  debug_inspect(
    descriptor.mipmap_filter == @asset.ImageFilterMode::Linear,
    content="true",
  )
}

///|
test "scene gltf wb: override sampler ignores gltf sampler payload" {
  let source = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[]}],\"nodes\":[],\"meshes\":[],\"samplers\":[{\"magFilter\":9728,\"minFilter\":9984,\"wrapS\":10497,\"wrapT\":33648}],\"textures\":[{\"sampler\":0}]}"
  let doc = gltf_parse_document(source).unwrap()
  let default_sampler = @image.ImageSamplerDescriptor::nearest()
  default_sampler.set_address_mode(@image.ImageAddressMode::ClampToEdge)
  |> ignore
  let descriptor = sampler_descriptor_or_abort(
    gltf_texture_image_sampler(doc, 0, default_sampler, true),
  )
  debug_inspect(
    descriptor.address_mode_u == @asset.ImageAddressMode::ClampToEdge,
    content="true",
  )
  debug_inspect(
    descriptor.address_mode_v == @asset.ImageAddressMode::ClampToEdge,
    content="true",
  )
  debug_inspect(
    descriptor.mag_filter == @asset.ImageFilterMode::Nearest,
    content="true",
  )
  debug_inspect(
    descriptor.min_filter == @asset.ImageFilterMode::Nearest,
    content="true",
  )
  debug_inspect(
    descriptor.mipmap_filter == @asset.ImageFilterMode::Nearest,
    content="true",
  )
}

///|
test "scene gltf wb: texture sampler fallback uses gltf default sampler" {
  let original_default_sampler = @gltf.gltf_default_image_sampler()
  let custom_default_sampler = @image.ImageSamplerDescriptor::nearest()
  custom_default_sampler.set_address_mode(@image.ImageAddressMode::ClampToEdge)
  |> ignore
  @gltf.gltf_set_default_image_sampler(custom_default_sampler)

  let source = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[]}],\"nodes\":[],\"meshes\":[],\"textures\":[{}]}"
  let doc = gltf_parse_document(source).unwrap()
  let descriptor = sampler_descriptor_or_abort(
    gltf_texture_image_sampler(
      doc,
      0,
      @gltf.gltf_default_image_sampler(),
      false,
    ),
  )
  debug_inspect(
    descriptor.address_mode_u == @asset.ImageAddressMode::Repeat,
    content="true",
  )
  debug_inspect(
    descriptor.address_mode_v == @asset.ImageAddressMode::Repeat,
    content="true",
  )
  debug_inspect(
    descriptor.min_filter == @asset.ImageFilterMode::Nearest,
    content="true",
  )
  debug_inspect(
    descriptor.mag_filter == @asset.ImageFilterMode::Nearest,
    content="true",
  )

  @gltf.gltf_set_default_image_sampler(original_default_sampler)
}

///|
test "scene gltf wb: parse KHR_texture_transform on base color texture" {
  let source = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[]}],\"nodes\":[],\"meshes\":[],\"materials\":[{\"pbrMetallicRoughness\":{\"baseColorTexture\":{\"index\":3,\"extensions\":{\"KHR_texture_transform\":{\"offset\":[0.25,0.5],\"scale\":[2.0,0.5]}}}}}]}"
  let doc = gltf_parse_document(source).unwrap()
  debug_inspect(doc.materials.length(), content="1")
  debug_inspect(doc.materials[0].base_color_texture, content="Some(3)")
  debug_inspect(
    doc.materials[0].base_color_uv_offset.x.to_double(),
    content="0.25",
  )
  debug_inspect(
    doc.materials[0].base_color_uv_offset.y.to_double(),
    content="0.5",
  )
  debug_inspect(doc.materials[0].base_color_uv_scale.x.to_double(), content="2")
  debug_inspect(
    doc.materials[0].base_color_uv_scale.y.to_double(),
    content="0.5",
  )
}

///|
test "scene gltf wb: parse scene mesh primitive and material extras" {
  let source = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[0],\"extras\":{\"scene\":\"root\"}}],\"nodes\":[{\"mesh\":0}],\"meshes\":[{\"name\":\"NamedMesh\",\"extras\":{\"mesh\":true},\"primitives\":[{\"attributes\":{\"POSITION\":0},\"material\":0,\"extras\":{\"primitive\":1}}]}],\"materials\":[{\"name\":\"Top\",\"extras\":{\"material\":\"value\"}}],\"buffers\":[{\"byteLength\":0}],\"bufferViews\":[],\"accessors\":[{\"componentType\":5126,\"count\":0,\"type\":\"VEC3\"}]}"
  let doc = gltf_parse_document(source).unwrap()
  debug_inspect(
    doc.scenes[0].extras.unwrap_or(""),
    content="\"{\\\"scene\\\":\\\"root\\\"}\"",
  )
  debug_inspect(doc.meshes[0].name, content="\"NamedMesh\"")
  debug_inspect(
    doc.meshes[0].extras.unwrap_or(""),
    content="\"{\\\"mesh\\\":true}\"",
  )
  debug_inspect(
    doc.meshes[0].primitives[0].extras.unwrap_or(""),
    content="\"{\\\"primitive\\\":1}\"",
  )
  debug_inspect(
    doc.materials[0].extras.unwrap_or(""),
    content="\"{\\\"material\\\":\\\"value\\\"}\"",
  )
  let extras = gltf_scene_extras_for_selected_scene(doc, 0)
  debug_inspect(extras is Some(_), content="true")
  let missing_extras = gltf_scene_extras_for_selected_scene(doc, -1)
  debug_inspect(missing_extras is None, content="true")
}

///|
test "scene gltf wb: parse KHR_materials_clearcoat" {
  let source = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[]}],\"nodes\":[],\"meshes\":[],\"materials\":[{\"extensions\":{\"KHR_materials_clearcoat\":{\"clearcoatFactor\":0.7,\"clearcoatRoughnessFactor\":0.2,\"clearcoatTexture\":{\"index\":3},\"clearcoatRoughnessTexture\":{\"index\":4},\"clearcoatNormalTexture\":{\"index\":5}}}}]}"
  let doc = gltf_parse_document(source).unwrap()
  debug_inspect(doc.materials.length(), content="1")
  debug_inspect(
    doc.materials[0].clearcoat.to_double(),
    content="0.699999988079071",
  )
  debug_inspect(
    doc.materials[0].clearcoat_roughness.to_double(),
    content="0.20000000298023224",
  )
  debug_inspect(doc.materials[0].clearcoat_texture, content="Some(3)")
  debug_inspect(doc.materials[0].clearcoat_roughness_texture, content="Some(4)")
  debug_inspect(doc.materials[0].clearcoat_normal_texture, content="Some(5)")
}

///|
test "scene gltf wb: parse KHR_materials_anisotropy" {
  let source = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[]}],\"nodes\":[],\"meshes\":[],\"materials\":[{\"extensions\":{\"KHR_materials_anisotropy\":{\"anisotropyStrength\":0.6,\"anisotropyRotation\":1.25,\"anisotropyTexture\":{\"index\":7}}}}]}"
  let doc = gltf_parse_document(source).unwrap()
  debug_inspect(doc.materials.length(), content="1")
  debug_inspect(
    doc.materials[0].anisotropy_strength >= 0.59F &&
    doc.materials[0].anisotropy_strength <= 0.61F,
    content="true",
  )
  debug_inspect(
    doc.materials[0].anisotropy_rotation >= 1.24F &&
    doc.materials[0].anisotropy_rotation <= 1.26F,
    content="true",
  )
  debug_inspect(doc.materials[0].anisotropy_texture, content="Some(7)")
}

///|
test "scene gltf wb: parse node MSFT_lod ids" {
  let source = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[0]}],\"nodes\":[{\"mesh\":0,\"extensions\":{\"MSFT_lod\":{\"ids\":[1,2]}}},{\"mesh\":1},{\"mesh\":2}],\"meshes\":[]}"
  let doc = gltf_parse_document(source).unwrap()
  debug_inspect(doc.nodes.length(), content="3")
  debug_inspect(doc.nodes[0].lod_nodes.length(), content="2")
  debug_inspect(doc.nodes[0].lod_nodes[0], content="1")
  debug_inspect(doc.nodes[0].lod_nodes[1], content="2")
}

///|
test "scene gltf wb: parse cameras lights and node extras" {
  let source = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[0]}],\"cameras\":[{\"type\":\"perspective\",\"perspective\":{\"yfov\":1.1,\"znear\":0.2,\"zfar\":100.0,\"aspectRatio\":1.6}},{\"type\":\"orthographic\",\"orthographic\":{\"xmag\":2.0,\"ymag\":1.0,\"znear\":0.3,\"zfar\":55.0}}],\"extensions\":{\"KHR_lights_punctual\":{\"lights\":[{\"type\":\"spot\",\"name\":\"Lamp\",\"color\":[0.25,0.5,0.75],\"intensity\":12.0,\"range\":9.0,\"spot\":{\"innerConeAngle\":0.1,\"outerConeAngle\":0.5},\"extras\":{\"light\":true}}]}},\"nodes\":[{\"name\":\"Node\",\"camera\":0,\"extensions\":{\"KHR_lights_punctual\":{\"light\":0}},\"extras\":{\"node\":1}}],\"meshes\":[]}"
  let doc = gltf_parse_document(source).unwrap()
  debug_inspect(doc.cameras.length(), content="2")
  debug_inspect(doc.lights.length(), content="1")
  debug_inspect(doc.nodes[0].camera, content="Some(0)")
  debug_inspect(doc.nodes[0].light, content="Some(0)")
  debug_inspect(
    doc.nodes[0].extras.unwrap_or(""),
    content="\"{\\\"node\\\":1}\"",
  )
  match doc.cameras[0].projection {
    Perspective(yfov, znear, zfar, aspect_ratio) => {
      debug_inspect(yfov.to_double(), content="1.100000023841858")
      debug_inspect(znear.to_double(), content="0.20000000298023224")
      debug_inspect(zfar, content="Some(100)")
      debug_inspect(aspect_ratio, content="Some(1.600000023841858)")
    }
    _ => abort("expected perspective camera")
  }
  match doc.cameras[1].projection {
    Orthographic(xmag, znear, zfar) => {
      debug_inspect(xmag.to_double(), content="2")
      debug_inspect(znear.to_double(), content="0.30000001192092896")
      debug_inspect(zfar.to_double(), content="55")
    }
    _ => abort("expected orthographic camera")
  }
  match doc.lights[0].kind {
    Spot(inner_angle, outer_angle) => {
      debug_inspect(inner_angle.to_double(), content="0.10000000149011612")
      debug_inspect(outer_angle.to_double(), content="0.5")
    }
    _ => abort("expected spot light")
  }
  debug_inspect(doc.lights[0].name, content="\"Lamp\"")
  debug_inspect(
    doc.lights[0].extras.unwrap_or(""),
    content="\"{\\\"light\\\":true}\"",
  )
}

///|
test "scene gltf wb: camera and light helpers respect loader gates" {
  let source = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[0]}],\"cameras\":[{\"type\":\"perspective\",\"perspective\":{\"yfov\":1.0,\"znear\":0.1}}],\"extensions\":{\"KHR_lights_punctual\":{\"lights\":[{\"type\":\"point\",\"name\":\"Point\",\"intensity\":2.0,\"range\":6.0}]}} ,\"nodes\":[{\"name\":\"Root\",\"camera\":0,\"extensions\":{\"KHR_lights_punctual\":{\"light\":0}},\"extras\":{\"node\":1}}],\"meshes\":[]}"
  let doc = gltf_parse_document(source).unwrap()
  let node = doc.nodes[0]
  let active_camera_found = Ref::new(false)

  let enabled_camera = gltf_scene_node_camera_components(
    doc, node, active_camera_found,
  )
  debug_inspect(enabled_camera is Some(_), content="true")
  match enabled_camera {
    Some(camera_components) => {
      debug_inspect(camera_components.camera.is_active, content="true")
      let is_perspective = match camera_components.projection {
        @pbr.Projection::Perspective(_) => true
        _ => false
      }
      debug_inspect(is_perspective, content="true")
    }
    None => abort("expected enabled camera components")
  }
  let next_camera = gltf_scene_node_camera_components(
    doc, node, active_camera_found,
  )
  match next_camera {
    Some(camera_components) =>
      debug_inspect(!camera_components.camera.is_active, content="true")
    None => abort("expected second camera components")
  }

  let disabled_settings = @asset.ImageLoaderSettings::default()
  disabled_settings.load_cameras = false
  disabled_settings.load_lights = false
  let disabled_camera = if disabled_settings.load_cameras {
    gltf_scene_node_camera_components(doc, node, active_camera_found)
  } else {
    None
  }
  debug_inspect(disabled_camera is None, content="true")

  let enabled_light = gltf_scene_node_light_components(doc, node)
  debug_inspect(enabled_light is Some(_), content="true")
  match enabled_light {
    Some(light_components) => {
      debug_inspect(light_components.name is Some(_), content="true")
      debug_inspect(light_components.point_light is Some(_), content="true")
      debug_inspect(light_components.directional_light is None, content="true")
      debug_inspect(light_components.spot_light is None, content="true")
      debug_inspect(light_components.extras is None, content="true")
    }
    None => abort("expected enabled light components")
  }
  let disabled_light = if disabled_settings.load_lights {
    gltf_scene_node_light_components(doc, node)
  } else {
    None
  }
  debug_inspect(disabled_light is None, content="true")
}

///|
test "scene gltf wb: default visibility ranges for lod levels" {
  let policy = GltfLodVisibilityPolicy::default()
  let lod0 = gltf_lod_visibility_range_with_policy(policy, 0).unwrap()
  debug_inspect(lod0.start_margin_min.to_double(), content="0")
  debug_inspect(lod0.start_margin_max.to_double(), content="0")
  debug_inspect(lod0.end_margin_min.to_double(), content="3")
  debug_inspect(lod0.end_margin_max.to_double(), content="4")

  let lod1 = gltf_lod_visibility_range_with_policy(policy, 1).unwrap()
  debug_inspect(lod1.start_margin_min.to_double(), content="3")
  debug_inspect(lod1.start_margin_max.to_double(), content="4")
  debug_inspect(lod1.end_margin_min.to_double(), content="8")
  debug_inspect(lod1.end_margin_max.to_double(), content="9")

  let lod2 = gltf_lod_visibility_range_with_policy(policy, 2).unwrap()
  debug_inspect(lod2.start_margin_min.to_double(), content="8")
  debug_inspect(lod2.start_margin_max.to_double(), content="9")
  debug_inspect(lod2.end_margin_min.to_double(), content="13")
  debug_inspect(lod2.end_margin_max.to_double(), content="14")
}

///|
test "scene gltf wb: custom lod visibility policy and disable switch" {
  let custom_policy = GltfLodVisibilityPolicy::default()
    .with_first_lod_range(1.0F, 2.0F, 11.0F, 12.0F)
    .with_step(2.0F)
  let lod0 = gltf_lod_visibility_range_with_policy(custom_policy, 0).unwrap()
  debug_inspect(lod0.start_margin_min.to_double(), content="1")
  debug_inspect(lod0.start_margin_max.to_double(), content="2")
  debug_inspect(lod0.end_margin_min.to_double(), content="11")
  debug_inspect(lod0.end_margin_max.to_double(), content="12")

  let lod2 = gltf_lod_visibility_range_with_policy(custom_policy, 2).unwrap()
  debug_inspect(lod2.start_margin_min.to_double(), content="13")
  debug_inspect(lod2.start_margin_max.to_double(), content="14")
  debug_inspect(lod2.end_margin_min.to_double(), content="15")
  debug_inspect(lod2.end_margin_max.to_double(), content="16")

  let disabled_policy = custom_policy.with_enabled(false)
  let disabled_is_none = match
    gltf_lod_visibility_range_with_policy(disabled_policy, 0) {
    None => true
    Some(_) => false
  }
  debug_inspect(disabled_is_none, content="true")
}

///|
test "scene gltf wb: parse animation channels and samplers" {
  let source = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[0]}],\"nodes\":[{\"children\":[1]},{}],\"meshes\":[],\"buffers\":[{\"byteLength\":152}],\"bufferViews\":[{\"buffer\":0,\"byteOffset\":0,\"byteLength\":8},{\"buffer\":0,\"byteOffset\":8,\"byteLength\":24},{\"buffer\":0,\"byteOffset\":32,\"byteLength\":32},{\"buffer\":0,\"byteOffset\":64,\"byteLength\":72},{\"buffer\":0,\"byteOffset\":136,\"byteLength\":16}],\"accessors\":[{\"bufferView\":0,\"componentType\":5126,\"count\":2,\"type\":\"SCALAR\"},{\"bufferView\":1,\"componentType\":5126,\"count\":2,\"type\":\"VEC3\"},{\"bufferView\":2,\"componentType\":5126,\"count\":2,\"type\":\"VEC4\"},{\"bufferView\":3,\"componentType\":5126,\"count\":6,\"type\":\"VEC3\"},{\"bufferView\":4,\"componentType\":5126,\"count\":4,\"type\":\"SCALAR\"}],\"animations\":[{\"samplers\":[{\"input\":0,\"output\":1,\"interpolation\":\"LINEAR\"},{\"input\":0,\"output\":2,\"interpolation\":\"STEP\"},{\"input\":0,\"output\":3,\"interpolation\":\"CUBICSPLINE\"},{\"input\":0,\"output\":4}],\"channels\":[{\"sampler\":0,\"target\":{\"node\":0,\"path\":\"translation\"}},{\"sampler\":1,\"target\":{\"node\":1,\"path\":\"rotation\"}},{\"sampler\":2,\"target\":{\"node\":0,\"path\":\"scale\"}},{\"sampler\":3,\"target\":{\"node\":1,\"path\":\"weights\"}}]}]}"
  let doc = gltf_parse_document(source).unwrap()
  debug_inspect(doc.animations.length(), content="1")
  debug_inspect(doc.animations[0].samplers.length(), content="4")
  debug_inspect(doc.animations[0].channels.length(), content="4")
  debug_inspect(
    @animation.gltf_interpolation_is_cubic_spline(
      doc.animations[0].samplers[1].interpolation,
    ),
    content="false",
  )
  debug_inspect(
    @animation.gltf_interpolation_is_step(
      doc.animations[0].samplers[1].interpolation,
    ),
    content="true",
  )
  debug_inspect(
    @animation.gltf_interpolation_is_cubic_spline(
      doc.animations[0].samplers[2].interpolation,
    ),
    content="true",
  )
  debug_inspect(
    doc.animations[0].channels[3].target_path,
    content="\"weights\"",
  )
}

///|
test "scene gltf wb: build animation clip tracks and fallback node paths" {
  let source = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[0]}],\"nodes\":[{\"children\":[1]},{}],\"meshes\":[],\"buffers\":[{\"byteLength\":152}],\"bufferViews\":[{\"buffer\":0,\"byteOffset\":0,\"byteLength\":8},{\"buffer\":0,\"byteOffset\":8,\"byteLength\":24},{\"buffer\":0,\"byteOffset\":32,\"byteLength\":32},{\"buffer\":0,\"byteOffset\":64,\"byteLength\":72},{\"buffer\":0,\"byteOffset\":136,\"byteLength\":16}],\"accessors\":[{\"bufferView\":0,\"componentType\":5126,\"count\":2,\"type\":\"SCALAR\"},{\"bufferView\":1,\"componentType\":5126,\"count\":2,\"type\":\"VEC3\"},{\"bufferView\":2,\"componentType\":5126,\"count\":2,\"type\":\"VEC4\"},{\"bufferView\":3,\"componentType\":5126,\"count\":6,\"type\":\"VEC3\"},{\"bufferView\":4,\"componentType\":5126,\"count\":4,\"type\":\"SCALAR\"}],\"animations\":[{\"samplers\":[{\"input\":0,\"output\":1,\"interpolation\":\"LINEAR\"},{\"input\":0,\"output\":2,\"interpolation\":\"STEP\"},{\"input\":0,\"output\":3,\"interpolation\":\"CUBICSPLINE\"},{\"input\":0,\"output\":4}],\"channels\":[{\"sampler\":0,\"target\":{\"node\":0,\"path\":\"translation\"}},{\"sampler\":1,\"target\":{\"node\":1,\"path\":\"rotation\"}},{\"sampler\":2,\"target\":{\"node\":0,\"path\":\"scale\"}},{\"sampler\":3,\"target\":{\"node\":1,\"path\":\"weights\"}}]}]}"
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
  // scale values (CUBICSPLINE: in, value, out per keyframe)
  push_f32_le(raw, 0.0F)
  push_f32_le(raw, 0.0F)
  push_f32_le(raw, 0.0F)
  push_f32_le(raw, 1.0F)
  push_f32_le(raw, 1.0F)
  push_f32_le(raw, 1.0F)
  push_f32_le(raw, 0.0F)
  push_f32_le(raw, 0.0F)
  push_f32_le(raw, 0.0F)
  push_f32_le(raw, 0.0F)
  push_f32_le(raw, 0.0F)
  push_f32_le(raw, 0.0F)
  push_f32_le(raw, 2.0F)
  push_f32_le(raw, 2.0F)
  push_f32_le(raw, 2.0F)
  push_f32_le(raw, 0.0F)
  push_f32_le(raw, 0.0F)
  push_f32_le(raw, 0.0F)
  // weights values
  push_f32_le(raw, 0.1F)
  push_f32_le(raw, 0.9F)
  push_f32_le(raw, 0.2F)
  push_f32_le(raw, 0.8F)

  let clip = scene_build_animation_clip_from_gltf(0, doc, [
    Bytes::from_array(raw),
  ])
  debug_inspect(clip.duration().to_double(), content="1")

  let target0 = @animation.AnimationTargetId::from_names(["GltfNode0"])
  let target1 = @animation.AnimationTargetId::from_names([
    "GltfNode0", "GltfNode1",
  ])

  let sample0 = clip.sample_target(target0, 1.0F).unwrap()
  let sample1 = clip.sample_target(target1, 1.0F).unwrap()

  let translation = sample0.translation().unwrap()
  debug_inspect(translation.x.to_double(), content="4")
  debug_inspect(translation.z.to_double(), content="6")

  let scale = sample0.scale().unwrap()
  debug_inspect(scale.x.to_double(), content="2")
  debug_inspect(scale.y.to_double(), content="2")

  let rotation = sample1.rotation().unwrap()
  debug_inspect(rotation.w >= 0.70F && rotation.w <= 0.71F, content="true")
  let step_rotation_mid = clip
    .sample_target(target1, 0.5F)
    .unwrap()
    .rotation()
    .unwrap()
  debug_inspect(
    step_rotation_mid.w >= 0.99F && step_rotation_mid.w <= 1.01F,
    content="true",
  )

  let weights = sample1.weights().unwrap()
  debug_inspect(weights.length(), content="2")
  debug_inspect(weights[0] >= 0.19F && weights[0] <= 0.21F, content="true")
  debug_inspect(weights[1] >= 0.79F && weights[1] <= 0.81F, content="true")
}

///|
test "scene gltf wb: split labeled gltf path with extended labels" {
  let scene_label = scene_split_gltf_asset_path("models/Foo/Foo.gltf#Scene2")
  debug_inspect(scene_label.0, content="\"models/Foo/Foo.gltf\"")
  debug_inspect(label_option_text(scene_label.1), content="\"Some(Scene2)\"")

  let primitive_label = scene_split_gltf_asset_path(
    "models/Foo/Foo.gltf#Mesh3/Primitive1",
  )
  debug_inspect(primitive_label.0, content="\"models/Foo/Foo.gltf\"")
  debug_inspect(
    label_option_text(primitive_label.1),
    content="\"Some(Mesh3/Primitive1)\"",
  )

  let inverse_bind_label = scene_split_gltf_asset_path(
    "models/Foo/Foo.gltf#Skin4/InverseBindMatrices",
  )
  debug_inspect(
    label_option_text(inverse_bind_label.1),
    content="\"Some(Skin4/InverseBindMatrices)\"",
  )

  let unknown_label = scene_split_gltf_asset_path(
    "models/Foo/Foo.gltf#NotALabel",
  )
  debug_inspect(unknown_label.0, content="\"models/Foo/Foo.gltf\"")
  debug_inspect(label_option_text(unknown_label.1), content="\"None\"")
}

///|
test "scene gltf wb: read MAT4 accessor as row-major SkinningMat4" {
  let source = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[]}],\"nodes\":[],\"meshes\":[],\"buffers\":[{\"byteLength\":64}],\"bufferViews\":[{\"buffer\":0,\"byteOffset\":0,\"byteLength\":64}],\"accessors\":[{\"bufferView\":0,\"componentType\":5126,\"count\":1,\"type\":\"MAT4\"}]}"
  let doc = gltf_parse_document(source).unwrap()
  let raw : Array[Byte] = []
  for i in 1..<17 {
    push_f32_le(raw, Float::from_int(i))
  }
  let mats = gltf_read_accessor_mat4(doc, [Bytes::from_array(raw)], 0).unwrap()
  debug_inspect(mats.length(), content="1")
  let row_major = mats[0].to_row_major_f32()
  debug_inspect(row_major.length(), content="16")
  debug_inspect(row_major[0].to_double(), content="1")
  debug_inspect(row_major[1].to_double(), content="5")
  debug_inspect(row_major[2].to_double(), content="9")
  debug_inspect(row_major[3].to_double(), content="13")
  debug_inspect(row_major[4].to_double(), content="2")
  debug_inspect(row_major[8].to_double(), content="3")
  debug_inspect(row_major[12].to_double(), content="4")
}

///|
test "scene gltf wb: parse skin joint node indices from gltf doc" {
  let source = "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[]}],\"nodes\":[],\"meshes\":[],\"skins\":[{\"joints\":[2,0,1,5]}]}"
  let doc = gltf_parse_document(source).unwrap()
  debug_inspect(doc.skins.length(), content="1")
  debug_inspect(doc.skins[0].joints.length(), content="4")
  debug_inspect(doc.skins[0].joints[0], content="2")
  debug_inspect(doc.skins[0].joints[1], content="0")
  debug_inspect(doc.skins[0].joints[2], content="1")
  debug_inspect(doc.skins[0].joints[3], content="5")
}
