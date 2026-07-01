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
// Bevy source:
// - `bevy/crates/bevy_pbr/src/render/mesh.rs`
// - `bevy/crates/bevy_pbr/src/material.rs`
// - `bevy/crates/bevy_pbr/src/prepass/mod.rs`

///|
pub const PBR_MESH_VERTEX_SHADER_PATH : String = "pbr/render/mesh.wgsl"

///|
pub const PBR_MESH_FRAGMENT_SHADER_PATH : String = "pbr/render/pbr.wgsl"

///|
pub const PBR_PREPASS_SHADER_PATH : String = "pbr/prepass/prepass.wgsl"

///|
pub const PBR_MESH_PREPASS_FRAGMENT_SHADER_PATH : String = "pbr/render/pbr_prepass.wgsl"

///|
const MESH_PIPELINE_KEY_TONEMAP_IN_SHADER : UInt64 = 1UL

///|
const MESH_PIPELINE_KEY_DEBAND_DITHER : UInt64 = 2UL

///|
const MESH_PIPELINE_KEY_DEPTH_PREPASS : UInt64 = 4UL

///|
const MESH_PIPELINE_KEY_NORMAL_PREPASS : UInt64 = 8UL

///|
const MESH_PIPELINE_KEY_DEFERRED_PREPASS : UInt64 = 16UL

///|
const MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS : UInt64 = 32UL

///|
const MESH_PIPELINE_KEY_UNCLIPPED_DEPTH_ORTHO : UInt64 = 512UL

///|
const MESH_PIPELINE_KEY_ENVIRONMENT_MAP : UInt64 = 128UL

///|
const MESH_PIPELINE_KEY_SCREEN_SPACE_AMBIENT_OCCLUSION : UInt64 = 256UL

///|
const MESH_PIPELINE_KEY_TEMPORAL_JITTER : UInt64 = 1024UL

///|
const MESH_PIPELINE_KEY_IRRADIANCE_VOLUME : UInt64 = 16384UL

///|
const MESH_PIPELINE_KEY_VISIBILITY_RANGE_DITHER : UInt64 = 32768UL

///|
const MESH_PIPELINE_KEY_SCREEN_SPACE_REFLECTIONS : UInt64 = 65536UL

///|
const MESH_PIPELINE_KEY_HAS_PREVIOUS_SKIN : UInt64 = 131072UL

///|
const MESH_PIPELINE_KEY_HAS_PREVIOUS_MORPH : UInt64 = 262144UL

///|
const MESH_PIPELINE_KEY_OIT_ENABLED : UInt64 = 524288UL

///|
const MESH_PIPELINE_KEY_DISTANCE_FOG : UInt64 = 1048576UL

///|
const MESH_PIPELINE_KEY_ATMOSPHERE : UInt64 = 2097152UL

///|
const MESH_PIPELINE_KEY_INVERT_CULLING : UInt64 = 4194304UL

///|
const MESH_PIPELINE_KEY_CONTACT_SHADOWS : UInt64 = 16777216UL

///|
const MESH_PIPELINE_KEY_ALL_PREPASS_BITS : UInt64 = 8388732UL

///|
const MESH_PIPELINE_KEY_MORPH_TARGETS : UInt64 = 0x8000_0000_0000_0000UL

///|
const MESH_PIPELINE_KEY_MSAA_SHIFT_BITS : Int = 25

///|
const MESH_PIPELINE_KEY_MSAA_MASK_BITS : UInt64 = 0b111UL

///|
const MESH_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS : Int = 31

///|
const MESH_PIPELINE_KEY_TONEMAP_METHOD_MASK_BITS : UInt64 = 0b1111UL

///|
const MESH_PIPELINE_KEY_SHADOW_FILTER_METHOD_SHIFT_BITS : Int = 35

///|
const MESH_PIPELINE_KEY_SHADOW_FILTER_METHOD_RESERVED_BITS : UInt64 = 0b11UL <<
  MESH_PIPELINE_KEY_SHADOW_FILTER_METHOD_SHIFT_BITS

///|
const MESH_PIPELINE_KEY_SHADOW_FILTER_METHOD_HARDWARE_2X2 : UInt64 = 0UL <<
  MESH_PIPELINE_KEY_SHADOW_FILTER_METHOD_SHIFT_BITS

///|
const MESH_PIPELINE_KEY_SHADOW_FILTER_METHOD_GAUSSIAN : UInt64 = 1UL <<
  MESH_PIPELINE_KEY_SHADOW_FILTER_METHOD_SHIFT_BITS

///|
const MESH_PIPELINE_KEY_SHADOW_FILTER_METHOD_TEMPORAL : UInt64 = 2UL <<
  MESH_PIPELINE_KEY_SHADOW_FILTER_METHOD_SHIFT_BITS

///|
const MESH_PIPELINE_KEY_VIEW_PROJECTION_SHIFT_BITS : Int = 37

///|
const MESH_PIPELINE_KEY_VIEW_PROJECTION_RESERVED_BITS : UInt64 = 0b11UL <<
  MESH_PIPELINE_KEY_VIEW_PROJECTION_SHIFT_BITS

///|
const MESH_PIPELINE_KEY_VIEW_PROJECTION_NONSTANDARD : UInt64 = 0UL <<
  MESH_PIPELINE_KEY_VIEW_PROJECTION_SHIFT_BITS

///|
const MESH_PIPELINE_KEY_VIEW_PROJECTION_PERSPECTIVE : UInt64 = 1UL <<
  MESH_PIPELINE_KEY_VIEW_PROJECTION_SHIFT_BITS

///|
const MESH_PIPELINE_KEY_VIEW_PROJECTION_ORTHOGRAPHIC : UInt64 = 2UL <<
  MESH_PIPELINE_KEY_VIEW_PROJECTION_SHIFT_BITS

///|
const MESH_PIPELINE_KEY_BLEND_RESERVED_BITS : UInt64 = 1879048192UL

///|
fn pbr_shader_def(name : String) -> @material.ShaderDefVal {
  @material.ShaderDefVal::Flag(name)
}

///|
fn pbr_shader_def_uint(name : String, value : UInt) -> @material.ShaderDefVal {
  @material.ShaderDefVal::UInt(name, value)
}

///|
fn pbr_shader_def_int(name : String, value : Int) -> @material.ShaderDefVal {
  @material.ShaderDefVal::Int(name, value)
}

///|
fn pbr_push_standard_material_feature_shader_defs(
  shader_defs : Array[@material.ShaderDefVal],
  features : StandardMaterialTextureFeatureSet,
) -> Unit {
  if features.pbr_transmission_textures() {
    shader_defs.push(pbr_shader_def("PBR_TRANSMISSION_TEXTURES_SUPPORTED"))
  }
  if features.pbr_multi_layer_material_textures() {
    shader_defs.push(
      pbr_shader_def("PBR_MULTI_LAYER_MATERIAL_TEXTURES_SUPPORTED"),
    )
  }
  if features.pbr_anisotropy_texture() {
    shader_defs.push(pbr_shader_def("PBR_ANISOTROPY_TEXTURE_SUPPORTED"))
  }
  if features.pbr_specular_textures() {
    shader_defs.push(pbr_shader_def("PBR_SPECULAR_TEXTURES_SUPPORTED"))
  }
}

///|
fn pbr_pipeline_layout_fragment_sampler_count(
  descriptor : @render_resource.RenderPipelineDescriptor,
) -> Int {
  let fragment_visibility = @wgpu.SHADER_STAGE_FRAGMENT.to_uint()
  let mut sampler_count = 0
  for layout in descriptor.layout() {
    for entry in layout.entries() {
      if (entry.visibility() & fragment_visibility) == 0U {
        continue
      }
      match entry.kind() {
        @render_resource.BindingType::Sampler
        | @render_resource.BindingType::SamplerBinding(_) => {
          let entry_count = entry.count()
          sampler_count += if entry_count > 0 { entry_count } else { 1 }
        }
        _ => ()
      }
    }
  }
  sampler_count
}

///|
fn pbr_pipeline_layout_sampler_limit_unsupported_reason(
  descriptor : @render_resource.RenderPipelineDescriptor,
  max_fragment_samplers_per_shader_stage : UInt,
) -> String? {
  let sampler_count = pbr_pipeline_layout_fragment_sampler_count(descriptor)
  if sampler_count.reinterpret_as_uint() <=
    max_fragment_samplers_per_shader_stage {
    return None
  }
  let label = match descriptor.label() {
    Some(label) => label
    None => "unnamed PBR material pipeline"
  }
  Some(
    "\{label} uses \{sampler_count.to_string()} fragment-visible samplers, exceeding max_samplers_per_shader_stage \{max_fragment_samplers_per_shader_stage.to_string()}",
  )
}

///|
fn pbr_validate_pipeline_layout_sampler_limit(
  descriptor : @render_resource.RenderPipelineDescriptor,
  max_fragment_samplers_per_shader_stage : UInt?,
) -> Unit raise @material.SpecializedMeshPipelineError {
  guard max_fragment_samplers_per_shader_stage is Some(limit) else { return }
  guard pbr_pipeline_layout_sampler_limit_unsupported_reason(descriptor, limit)
    is Some(reason) else {
    return
  }
  raise @material.specialized_mesh_pipeline_unsupported_feature_error(reason)
}

///|
fn pbr_push_view_projection_shader_def(
  mesh_key_bits : UInt64,
  shader_defs : Array[@material.ShaderDefVal],
) -> Unit {
  let view_projection = mesh_key_bits &
    MESH_PIPELINE_KEY_VIEW_PROJECTION_RESERVED_BITS
  if view_projection == MESH_PIPELINE_KEY_VIEW_PROJECTION_NONSTANDARD {
    shader_defs.push(pbr_shader_def("VIEW_PROJECTION_NONSTANDARD"))
  } else if view_projection == MESH_PIPELINE_KEY_VIEW_PROJECTION_PERSPECTIVE {
    shader_defs.push(pbr_shader_def("VIEW_PROJECTION_PERSPECTIVE"))
  } else if view_projection == MESH_PIPELINE_KEY_VIEW_PROJECTION_ORTHOGRAPHIC {
    shader_defs.push(pbr_shader_def("VIEW_PROJECTION_ORTHOGRAPHIC"))
  }
}

///|
fn pbr_push_shadow_filter_method_shader_def(
  mesh_key_bits : UInt64,
  shader_defs : Array[@material.ShaderDefVal],
) -> Unit {
  let shadow_filter_method = mesh_key_bits &
    MESH_PIPELINE_KEY_SHADOW_FILTER_METHOD_RESERVED_BITS
  if shadow_filter_method == MESH_PIPELINE_KEY_SHADOW_FILTER_METHOD_HARDWARE_2X2 {
    shader_defs.push(pbr_shader_def("SHADOW_FILTER_METHOD_HARDWARE_2X2"))
  } else if shadow_filter_method ==
    MESH_PIPELINE_KEY_SHADOW_FILTER_METHOD_GAUSSIAN {
    shader_defs.push(pbr_shader_def("SHADOW_FILTER_METHOD_GAUSSIAN"))
  } else if shadow_filter_method ==
    MESH_PIPELINE_KEY_SHADOW_FILTER_METHOD_TEMPORAL {
    shader_defs.push(pbr_shader_def("SHADOW_FILTER_METHOD_TEMPORAL"))
  }
}

///|
fn pbr_mesh_key_msaa_samples_is_one(mesh_key_bits : UInt64) -> Bool {
  (
    (mesh_key_bits >> MESH_PIPELINE_KEY_MSAA_SHIFT_BITS) &
    MESH_PIPELINE_KEY_MSAA_MASK_BITS
  ) ==
  0UL
}

///|
fn pbr_mesh_key_msaa_samples(mesh_key_bits : UInt64) -> UInt {
  let bits = (mesh_key_bits >> MESH_PIPELINE_KEY_MSAA_SHIFT_BITS) &
    MESH_PIPELINE_KEY_MSAA_MASK_BITS
  match bits {
    0UL => 1U
    1UL => 2U
    2UL => 4U
    3UL => 8U
    _ => 1U
  }
}

///|
fn pbr_mesh_key_target_format(mesh_key_bits : UInt64) -> UInt {
  let code = (mesh_key_bits >> MESH_PIPELINE_KEY_COLOR_TARGET_FORMAT_SHIFT_BITS) &
    MESH_PIPELINE_KEY_COLOR_TARGET_FORMAT_MASK_BITS
  match @render_view.texture_format_from_code(code.to_uint()) {
    Some(format_raw) => format_raw
    None => abort("Unknown bits in COLOR_TARGET_FORMAT_MASK_BITS")
  }
}

///|
fn pbr_mesh_key_is_opaque(mesh_key_bits : UInt64) -> Bool {
  let blend_key = mesh_key_bits & MESH_PIPELINE_KEY_BLEND_RESERVED_BITS
  let reads_view_transmission = (
      mesh_key_bits & MESH_PIPELINE_KEY_READS_VIEW_TRANSMISSION_TEXTURE
    ) !=
    0UL
  if (mesh_key_bits & MESH_PIPELINE_KEY_OIT_ENABLED) != 0UL &&
    blend_key == MESH_PIPELINE_KEY_BLEND_ALPHA {
    false
  } else if blend_key == MESH_PIPELINE_KEY_BLEND_ALPHA {
    false
  } else if blend_key == MESH_PIPELINE_KEY_BLEND_PREMULTIPLIED_ALPHA {
    false
  } else if blend_key == MESH_PIPELINE_KEY_BLEND_MULTIPLY {
    false
  } else {
    !reads_view_transmission
  }
}

///|
fn pbr_multiply_blend_state() -> @material.BlendState {
  @material.BlendState::BlendState(
    color=@material.BlendComponent::BlendComponent(
      src_factor=@wgpu.BLEND_FACTOR_DST,
      dst_factor=@wgpu.BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
      operation=@wgpu.BLEND_OPERATION_ADD,
    ),
    alpha=@material.BlendComponent::over(),
  )
}

///|
fn pbr_mesh_pipeline_blend_state(
  mesh_key_bits : UInt64,
  shader_defs : Array[@material.ShaderDefVal],
) -> (String, @material.BlendState?, Bool, Bool) {
  let pass = mesh_key_bits & MESH_PIPELINE_KEY_BLEND_RESERVED_BITS
  if (mesh_key_bits & MESH_PIPELINE_KEY_OIT_ENABLED) != 0UL &&
    pass == MESH_PIPELINE_KEY_BLEND_ALPHA {
    shader_defs.push(pbr_shader_def("OIT_ENABLED"))
    ("oit_mesh_pipeline", None, false, false)
  } else if pass == MESH_PIPELINE_KEY_BLEND_ALPHA {
    (
      "alpha_blend_mesh_pipeline",
      Some(@material.BlendState::alpha_blending()),
      false,
      false,
    )
  } else if pass == MESH_PIPELINE_KEY_BLEND_PREMULTIPLIED_ALPHA {
    shader_defs.push(pbr_shader_def("PREMULTIPLY_ALPHA"))
    shader_defs.push(pbr_shader_def("BLEND_PREMULTIPLIED_ALPHA"))
    (
      "premultiplied_alpha_mesh_pipeline",
      Some(@material.BlendState::premultiplied_alpha_blending()),
      false,
      false,
    )
  } else if pass == MESH_PIPELINE_KEY_BLEND_MULTIPLY {
    shader_defs.push(pbr_shader_def("PREMULTIPLY_ALPHA"))
    shader_defs.push(pbr_shader_def("BLEND_MULTIPLY"))
    ("multiply_mesh_pipeline", Some(pbr_multiply_blend_state()), false, false)
  } else if pass == MESH_PIPELINE_KEY_BLEND_ALPHA_TO_COVERAGE {
    shader_defs.push(pbr_shader_def("ALPHA_TO_COVERAGE"))
    ("alpha_to_coverage_mesh_pipeline", None, true, true)
  } else {
    ("opaque_mesh_pipeline", None, true, false)
  }
}

///|
fn pbr_push_mesh_prepass_shader_defs(
  mesh_key_bits : UInt64,
  shader_defs : Array[@material.ShaderDefVal],
) -> Unit {
  if (mesh_key_bits & MESH_PIPELINE_KEY_NORMAL_PREPASS) != 0UL {
    shader_defs.push(pbr_shader_def("NORMAL_PREPASS"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_DEPTH_PREPASS) != 0UL {
    shader_defs.push(pbr_shader_def("DEPTH_PREPASS"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS) != 0UL {
    shader_defs.push(pbr_shader_def("MOTION_VECTOR_PREPASS"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_HAS_PREVIOUS_SKIN) != 0UL {
    shader_defs.push(pbr_shader_def("HAS_PREVIOUS_SKIN"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_HAS_PREVIOUS_MORPH) != 0UL {
    shader_defs.push(pbr_shader_def("HAS_PREVIOUS_MORPH"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_DEFERRED_PREPASS) != 0UL {
    shader_defs.push(pbr_shader_def("DEFERRED_PREPASS"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_NORMAL_PREPASS) != 0UL &&
    pbr_mesh_key_msaa_samples_is_one(mesh_key_bits) &&
    pbr_mesh_key_is_opaque(mesh_key_bits) {
    shader_defs.push(pbr_shader_def("LOAD_PREPASS_NORMALS"))
  }
}

///|
fn pbr_shader_defs_clone(
  shader_defs : Array[@material.ShaderDefVal],
) -> Array[@material.ShaderDefVal] {
  let cloned : Array[@material.ShaderDefVal] = []
  for shader_def in shader_defs {
    cloned.push(shader_def)
  }
  cloned
}

///|
fn pbr_standard_material_fragment_shader_defs() -> Array[(UInt64, String)] {
  [
    (STANDARD_MATERIAL_KEY_NORMAL_MAP, "STANDARD_MATERIAL_NORMAL_MAP"),
    (STANDARD_MATERIAL_KEY_RELIEF_MAPPING, "RELIEF_MAPPING"),
    (
      STANDARD_MATERIAL_KEY_DIFFUSE_TRANSMISSION,
      "STANDARD_MATERIAL_DIFFUSE_TRANSMISSION",
    ),
    (
      STANDARD_MATERIAL_KEY_SPECULAR_TRANSMISSION,
      "STANDARD_MATERIAL_SPECULAR_TRANSMISSION",
    ),
    (
      STANDARD_MATERIAL_KEY_DIFFUSE_TRANSMISSION |
      STANDARD_MATERIAL_KEY_SPECULAR_TRANSMISSION,
      "STANDARD_MATERIAL_DIFFUSE_OR_SPECULAR_TRANSMISSION",
    ),
    (STANDARD_MATERIAL_KEY_CLEARCOAT, "STANDARD_MATERIAL_CLEARCOAT"),
    (
      STANDARD_MATERIAL_KEY_CLEARCOAT_NORMAL_MAP,
      "STANDARD_MATERIAL_CLEARCOAT_NORMAL_MAP",
    ),
    (STANDARD_MATERIAL_KEY_ANISOTROPY, "STANDARD_MATERIAL_ANISOTROPY"),
    (STANDARD_MATERIAL_KEY_BASE_COLOR_UV, "STANDARD_MATERIAL_BASE_COLOR_UV_B"),
    (STANDARD_MATERIAL_KEY_EMISSIVE_UV, "STANDARD_MATERIAL_EMISSIVE_UV_B"),
    (
      STANDARD_MATERIAL_KEY_METALLIC_ROUGHNESS_UV,
      "STANDARD_MATERIAL_METALLIC_ROUGHNESS_UV_B",
    ),
    (STANDARD_MATERIAL_KEY_OCCLUSION_UV, "STANDARD_MATERIAL_OCCLUSION_UV_B"),
    (
      STANDARD_MATERIAL_KEY_SPECULAR_TRANSMISSION_UV,
      "STANDARD_MATERIAL_SPECULAR_TRANSMISSION_UV_B",
    ),
    (STANDARD_MATERIAL_KEY_THICKNESS_UV, "STANDARD_MATERIAL_THICKNESS_UV_B"),
    (
      STANDARD_MATERIAL_KEY_DIFFUSE_TRANSMISSION_UV,
      "STANDARD_MATERIAL_DIFFUSE_TRANSMISSION_UV_B",
    ),
    (STANDARD_MATERIAL_KEY_NORMAL_MAP_UV, "STANDARD_MATERIAL_NORMAL_MAP_UV_B"),
    (STANDARD_MATERIAL_KEY_CLEARCOAT_UV, "STANDARD_MATERIAL_CLEARCOAT_UV_B"),
    (
      STANDARD_MATERIAL_KEY_CLEARCOAT_ROUGHNESS_UV,
      "STANDARD_MATERIAL_CLEARCOAT_ROUGHNESS_UV_B",
    ),
    (
      STANDARD_MATERIAL_KEY_CLEARCOAT_NORMAL_UV,
      "STANDARD_MATERIAL_CLEARCOAT_NORMAL_UV_B",
    ),
    (STANDARD_MATERIAL_KEY_ANISOTROPY_UV, "STANDARD_MATERIAL_ANISOTROPY_UV_B"),
    (STANDARD_MATERIAL_KEY_SPECULAR_UV, "STANDARD_MATERIAL_SPECULAR_UV_B"),
    (
      STANDARD_MATERIAL_KEY_SPECULAR_TINT_UV,
      "STANDARD_MATERIAL_SPECULAR_TINT_UV_B",
    ),
  ]
}

///|
fn pbr_standard_material_cull_mode(
  material_key_bits : UInt64,
  mesh_key_bits : UInt64,
) -> UInt? {
  let cull_front = (material_key_bits & STANDARD_MATERIAL_KEY_CULL_FRONT) != 0UL
  let cull_back = (material_key_bits & STANDARD_MATERIAL_KEY_CULL_BACK) != 0UL
  let invert_culling = (mesh_key_bits & MESH_PIPELINE_KEY_INVERT_CULLING) != 0UL
  match (cull_front, cull_back, invert_culling) {
    (true, false, false) | (false, true, true) => Some(@wgpu.CULL_MODE_FRONT)
    (false, true, false) | (true, false, true) => Some(@wgpu.CULL_MODE_BACK)
    _ => None
  }
}

///|
fn pbr_standard_material_depth_bias_constant(material_key_bits : UInt64) -> Int {
  let raw = (material_key_bits & STANDARD_MATERIAL_KEY_DEPTH_BIAS_MASK) >>
    STANDARD_MATERIAL_KEY_DEPTH_BIAS_SHIFT
  raw.to_uint().reinterpret_as_int()
}

///|
fn pbr_mesh_key_primitive_topology(mesh_key_bits : UInt64) -> UInt {
  let mesh_key = @mesh.BaseMeshPipelineKey::new(mesh_key_bits)
  match mesh_key.primitive_topology() {
    TriangleList => @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST
    LineList => @wgpu.PRIMITIVE_TOPOLOGY_LINE_LIST
    LineStrip => @wgpu.PRIMITIVE_TOPOLOGY_LINE_STRIP
  }
}

///|
fn pbr_mesh_key_strip_index_format(mesh_key_bits : UInt64) -> UInt? {
  let mesh_key = @mesh.BaseMeshPipelineKey::new(mesh_key_bits)
  match mesh_key.strip_index_format() {
    Some(Uint16) => Some(@wgpu.INDEX_FORMAT_UINT16)
    Some(Uint32) => Some(@wgpu.INDEX_FORMAT_UINT32)
    None => None
  }
}

///|
fn pbr_specialize_standard_material_descriptor(
  descriptor : @material.RenderPipelineDescriptor,
  key : @material.ErasedMaterialPipelineKey,
) -> @material.RenderPipelineDescriptor {
  let material_key = key.material_key()
  guard material_key.type_tag() == "StandardMaterialKey" else {
    return descriptor
  }
  let material_key_bits = material_key.bits()
  let mesh_key_bits = key.mesh_key().downcast_u64("MeshPipelineKey")
  let mut specialized = descriptor
  if specialized.fragment is Some(fragment) {
    for item in pbr_standard_material_fragment_shader_defs() {
      let (flags, shader_def) = item
      if (material_key_bits & flags) != 0UL {
        fragment.shader_defs.push(pbr_shader_def(shader_def))
      }
    }
    specialized = specialized.with_fragment(Some(fragment))
  }
  specialized = specialized.with_primitive(
    specialized.primitive.with_cull_mode(
      pbr_standard_material_cull_mode(material_key_bits, mesh_key_bits),
    ),
  )
  if specialized.depth_stencil is Some(depth_stencil) {
    specialized = specialized.with_depth_stencil(
      Some(
        depth_stencil.with_bias_constant(
          pbr_standard_material_depth_bias_constant(material_key_bits),
        ),
      ),
    )
  }
  if specialized.label is Some(label) {
    specialized = specialized.with_label(Some("pbr_" + label))
  }
  specialized
}

///|
pub fn pbr_specialize_standard_material_descriptor_for_key(
  descriptor : @material.RenderPipelineDescriptor,
  key : @material.ErasedMaterialPipelineKey,
) -> @material.RenderPipelineDescriptor {
  pbr_specialize_standard_material_descriptor(descriptor, key)
}

///|
fn pbr_mesh_vertex_attribute_descriptor(
  attribute : @mesh.MeshVertexAttribute,
  shader_location : Int,
) -> @mesh.VertexAttributeDescriptor {
  @mesh.VertexAttributeDescriptor::new(
    shader_location~,
    id=attribute.id(),
    name=attribute.name(),
  )
}

///|
fn pbr_mesh_pipeline_view_layout_key(
  mesh_key_bits : UInt64,
) -> @mesh_view_layout.MeshPipelineViewLayoutKey {
  let msaa_bits = (mesh_key_bits >> MESH_PIPELINE_KEY_MSAA_SHIFT_BITS) &
    MESH_PIPELINE_KEY_MSAA_MASK_BITS
  @mesh_view_layout.mesh_view_layout_key(
    msaa_bits != 0UL,
    (mesh_key_bits & MESH_PIPELINE_KEY_DEPTH_PREPASS) != 0UL,
    (mesh_key_bits & MESH_PIPELINE_KEY_NORMAL_PREPASS) != 0UL,
    (mesh_key_bits & MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS) != 0UL,
    (mesh_key_bits & MESH_PIPELINE_KEY_DEFERRED_PREPASS) != 0UL,
    (mesh_key_bits & MESH_PIPELINE_KEY_OIT_ENABLED) != 0UL,
    (mesh_key_bits & MESH_PIPELINE_KEY_ATMOSPHERE) != 0UL,
    true,
    tonemap_in_shader=(mesh_key_bits & MESH_PIPELINE_KEY_TONEMAP_IN_SHADER) !=
      0UL,
    environment_map=(mesh_key_bits & MESH_PIPELINE_KEY_ENVIRONMENT_MAP) != 0UL,
    screen_space_ambient_occlusion=(
        mesh_key_bits & MESH_PIPELINE_KEY_SCREEN_SPACE_AMBIENT_OCCLUSION
      ) !=
      0UL,
    irradiance_volume=(mesh_key_bits & MESH_PIPELINE_KEY_IRRADIANCE_VOLUME) !=
      0UL,
    screen_space_reflections=(
        mesh_key_bits & MESH_PIPELINE_KEY_SCREEN_SPACE_REFLECTIONS
      ) !=
      0UL,
    contact_shadows=(mesh_key_bits & MESH_PIPELINE_KEY_CONTACT_SHADOWS) != 0UL,
    distance_fog=(mesh_key_bits & MESH_PIPELINE_KEY_DISTANCE_FOG) != 0UL,
    area_light_luts=true,
    dfg_lut=true,
  )
}

///|
fn pbr_mesh_pipeline_view_layout(
  mesh_key_bits : UInt64,
  binding_arrays_are_usable : Bool,
  clustered_decals_are_usable : Bool,
) -> @mesh_view_layout.MeshPipelineViewLayout {
  @mesh_view_layout.render3d_mesh_pipeline_view_layout(
    true,
    true,
    pbr_mesh_pipeline_view_layout_key(mesh_key_bits),
    multiple_light_probes_in_array=binding_arrays_are_usable,
    clustered_decals_usable=clustered_decals_are_usable,
    irradiance_volumes_usable=@pbr_light_probe.IRRADIANCE_VOLUMES_ARE_USABLE,
    oit_supported=false,
  )
}

///|
fn pbr_mesh_binding_layout_entry(
  slot : @pbr_render.MeshBindingSlot3d,
  binding : Int,
  count? : Int = 0,
) -> @render_resource.BindGroupLayoutEntry {
  let vertex_fragment = (@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT).to_uint()
  let vertex = @wgpu.SHADER_STAGE_VERTEX.to_uint()
  let fragment = @wgpu.SHADER_STAGE_FRAGMENT.to_uint()
  let kind = match slot {
    @pbr_render.MeshBindingSlot3d::Model =>
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Storage(true),
        false,
        176UL,
      )
    @pbr_render.MeshBindingSlot3d::SkinCurrent
    | @pbr_render.MeshBindingSlot3d::SkinPrevious =>
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Storage(true),
        false,
        @pbr_render.RENDER3D_JOINT_BUFFER_SIZE_BYTES.to_uint64(),
      )
    @pbr_render.MeshBindingSlot3d::MorphWeightsCurrent
    | @pbr_render.MeshBindingSlot3d::MorphWeightsPrevious =>
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Storage(true),
        false,
        @pbr_render.RENDER3D_MORPH_BUFFER_SIZE_BYTES.to_uint64(),
      )
    @pbr_render.MeshBindingSlot3d::MorphTargets =>
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Storage(true),
        false,
        48UL,
      )
    @pbr_render.MeshBindingSlot3d::MorphDescriptors =>
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Storage(true),
        false,
        20UL,
      )
    @pbr_render.MeshBindingSlot3d::LightmapTexture =>
      @render_resource.BindingType::TextureBinding(
        @render_resource.TextureSampleType::Float(true),
        @render_resource.TextureViewDimension::D2,
        false,
      )
    @pbr_render.MeshBindingSlot3d::LightmapSampler =>
      @render_resource.BindingType::SamplerBinding(
        @render_resource.SamplerBindingType::Filtering,
      )
  }
  let visibility = match slot {
    @pbr_render.MeshBindingSlot3d::Model => vertex_fragment
    @pbr_render.MeshBindingSlot3d::LightmapTexture
    | @pbr_render.MeshBindingSlot3d::LightmapSampler => fragment
    _ => vertex
  }
  @render_resource.BindGroupLayoutEntry::new(binding, visibility, kind, count~)
}

///|
fn pbr_mesh_layout_is_skinned(
  mesh_layout : @mesh.MeshVertexBufferLayoutRef,
) -> Bool {
  let layout = mesh_layout.layout()
  layout.contains(@mesh.MeshVertexAttribute::joint_index().id()) &&
  layout.contains(@mesh.MeshVertexAttribute::joint_weight().id())
}

///|
fn pbr_setup_morph_and_skinning_defs(
  mesh_key_bits : UInt64,
  mesh_layout : @mesh.MeshVertexBufferLayoutRef,
  skinning_attribute_offset : Int,
  shader_defs : Array[@material.ShaderDefVal],
  vertex_attributes : Array[@mesh.VertexAttributeDescriptor],
  binding_arrays_are_usable : Bool,
) -> @material.BindGroupLayoutDescriptor {
  let is_morphed = (mesh_key_bits & MESH_PIPELINE_KEY_MORPH_TARGETS) != 0UL
  let is_lightmapped = (mesh_key_bits & MESH_PIPELINE_KEY_LIGHTMAPPED) != 0UL
  let motion_vectors = (mesh_key_bits & MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS) !=
    0UL
  let is_skinned = pbr_mesh_layout_is_skinned(mesh_layout)
  if is_skinned {
    shader_defs.push(pbr_shader_def("SKINNED"))
    vertex_attributes.push(
      pbr_mesh_vertex_attribute_descriptor(
        @mesh.MeshVertexAttribute::joint_index(),
        skinning_attribute_offset,
      ),
    )
    vertex_attributes.push(
      pbr_mesh_vertex_attribute_descriptor(
        @mesh.MeshVertexAttribute::joint_weight(),
        skinning_attribute_offset + 1,
      ),
    )
  }
  if is_morphed {
    shader_defs.push(pbr_shader_def("MORPH_TARGETS"))
  }
  let selected_layout = @pbr_render.render3d_mesh_layouts(
    binding_arrays_are_usable~,
  ).select(
    skinned=is_skinned,
    morphed=is_morphed,
    lightmapped=is_lightmapped,
    motion_vectors~,
  )
  let entries : Array[@render_resource.BindGroupLayoutEntry] = []
  for entry in selected_layout.entries() {
    entries.push(
      pbr_mesh_binding_layout_entry(
        entry.slot(),
        entry.binding(),
        count=entry.count(),
      ),
    )
  }
  @material.BindGroupLayoutDescriptor::new(selected_layout.name(), entries)
}

///|
fn pbr_prepass_empty_layout_descriptor() -> @material.BindGroupLayoutDescriptor {
  @material.BindGroupLayoutDescriptor::new("prepass_empty_layout", [])
}

///|
fn pbr_prepass_view_layout_descriptor(
  motion_vectors : Bool,
) -> @material.BindGroupLayoutDescriptor {
  let vertex_fragment = (@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT).to_uint()
  let entries = [
    @render_resource.BindGroupLayoutEntry::new(
      0,
      vertex_fragment,
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Uniform,
        true,
        0UL,
      ),
    ),
    @render_resource.BindGroupLayoutEntry::new(
      1,
      vertex_fragment,
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Uniform,
        false,
        0UL,
      ),
    ),
  ]
  if motion_vectors {
    entries.push(
      @render_resource.BindGroupLayoutEntry::new(
        2,
        vertex_fragment,
        @render_resource.BindingType::BufferBinding(
          @render_resource.BufferBindingType::Uniform,
          true,
          0UL,
        ),
      ),
    )
  }
  entries.push(
    @render_resource.BindGroupLayoutEntry::new(
      14,
      @wgpu.SHADER_STAGE_VERTEX.to_uint(),
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Storage(true),
        false,
        16UL,
      ),
    ),
  )
  @material.BindGroupLayoutDescriptor::new(
    if motion_vectors {
      "prepass_view_layout_motion_vectors"
    } else {
      "prepass_view_layout_no_motion_vectors"
    },
    entries,
  )
}

///|
fn pbr_prepass_is_depth_only_opaque(mesh_key_bits : UInt64) -> Bool {
  (mesh_key_bits & MESH_PIPELINE_KEY_ALL_PREPASS_BITS) ==
  MESH_PIPELINE_KEY_DEPTH_PREPASS
}

///|
fn pbr_screen_space_specular_transmission_blur_taps(
  mesh_key_bits : UInt64,
) -> Int {
  let quality_bits = mesh_key_bits &
    (
      MESH_PIPELINE_KEY_SCREEN_SPACE_SPECULAR_TRANSMISSION_MASK_BITS <<
      MESH_PIPELINE_KEY_SCREEN_SPACE_SPECULAR_TRANSMISSION_SHIFT_BITS
    )
  match quality_bits {
    bits if bits == MESH_PIPELINE_KEY_SCREEN_SPACE_SPECULAR_TRANSMISSION_MEDIUM =>
      8
    bits if bits == MESH_PIPELINE_KEY_SCREEN_SPACE_SPECULAR_TRANSMISSION_HIGH =>
      16
    bits if bits == MESH_PIPELINE_KEY_SCREEN_SPACE_SPECULAR_TRANSMISSION_ULTRA =>
      32
    _ => 4
  }
}

///|
fn pbr_prepass_targets_all_none(
  targets : Array[@material.ColorTargetState?],
) -> Bool {
  for target in targets {
    if target is Some(_) {
      return false
    }
  }
  true
}

///|
fn pbr_prepass_target_descriptors(
  normal_prepass : Bool,
  motion_vector_prepass : Bool,
  deferred_prepass : Bool,
) -> Array[@material.ColorTargetState?] {
  let targets : Array[@material.ColorTargetState?] = []
  if normal_prepass {
    targets.push(
      Some(
        @material.ColorTargetState::new(
          @wgpu.TEXTURE_FORMAT_RGB10_A2_UNORM,
          @wgpu.COLOR_WRITE_MASK_ALL,
        ),
      ),
    )
  } else if motion_vector_prepass || deferred_prepass {
    targets.push(None)
  }
  if motion_vector_prepass {
    targets.push(
      Some(
        @material.ColorTargetState::new(
          @wgpu.TEXTURE_FORMAT_RG16_FLOAT,
          @wgpu.COLOR_WRITE_MASK_ALL,
        ),
      ),
    )
  } else if deferred_prepass {
    targets.push(None)
  }
  if deferred_prepass {
    targets.push(
      Some(
        @material.ColorTargetState::new(
          @wgpu.TEXTURE_FORMAT_RGBA32_UINT,
          @wgpu.COLOR_WRITE_MASK_ALL,
        ),
      ),
    )
    targets.push(
      Some(
        @material.ColorTargetState::new(
          @wgpu.TEXTURE_FORMAT_R8_UINT,
          @wgpu.COLOR_WRITE_MASK_ALL,
        ),
      ),
    )
  }
  if targets.length() > 0 && pbr_prepass_targets_all_none(targets) {
    []
  } else {
    targets
  }
}

///|
fn pbr_mesh_pipeline_descriptor(
  mesh_key : @material.ErasedMeshPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
  binding_arrays_are_usable : Bool,
  clustered_decals_are_usable : Bool,
  standard_material_texture_features : StandardMaterialTextureFeatureSet,
) -> @material.RenderPipelineDescriptor raise @material.SpecializedMeshPipelineError {
  let mesh_key_bits = mesh_key.downcast_u64("MeshPipelineKey")
  let shader_defs : Array[@material.ShaderDefVal] = []
  let vertex_attributes : Array[@mesh.VertexAttributeDescriptor] = []
  shader_defs.push(pbr_shader_def("MESH_PIPELINE"))
  shader_defs.push(pbr_shader_def("VERTEX_OUTPUT_INSTANCE_INDEX"))
  let mesh_layout = layout.layout()
  if mesh_layout.contains(@mesh.MeshVertexAttribute::position().id()) {
    shader_defs.push(pbr_shader_def("VERTEX_POSITIONS"))
    vertex_attributes.push(
      pbr_mesh_vertex_attribute_descriptor(
        @mesh.MeshVertexAttribute::position(),
        0,
      ),
    )
  }
  if mesh_layout.contains(@mesh.MeshVertexAttribute::normal().id()) {
    shader_defs.push(pbr_shader_def("VERTEX_NORMALS"))
    vertex_attributes.push(
      pbr_mesh_vertex_attribute_descriptor(
        @mesh.MeshVertexAttribute::normal(),
        1,
      ),
    )
  }
  if mesh_layout.contains(@mesh.MeshVertexAttribute::uv_0().id()) {
    shader_defs.push(pbr_shader_def("VERTEX_UVS"))
    shader_defs.push(pbr_shader_def("VERTEX_UVS_A"))
    vertex_attributes.push(
      pbr_mesh_vertex_attribute_descriptor(@mesh.MeshVertexAttribute::uv_0(), 2),
    )
  }
  if mesh_layout.contains(@mesh.MeshVertexAttribute::uv_1().id()) {
    shader_defs.push(pbr_shader_def("VERTEX_UVS"))
    shader_defs.push(pbr_shader_def("VERTEX_UVS_B"))
    vertex_attributes.push(
      pbr_mesh_vertex_attribute_descriptor(@mesh.MeshVertexAttribute::uv_1(), 3),
    )
  }
  if mesh_layout.contains(@mesh.MeshVertexAttribute::tangent().id()) {
    shader_defs.push(pbr_shader_def("VERTEX_TANGENTS"))
    vertex_attributes.push(
      pbr_mesh_vertex_attribute_descriptor(
        @mesh.MeshVertexAttribute::tangent(),
        4,
      ),
    )
  }
  if mesh_layout.contains(@mesh.MeshVertexAttribute::color().id()) {
    shader_defs.push(pbr_shader_def("VERTEX_COLORS"))
    vertex_attributes.push(
      pbr_mesh_vertex_attribute_descriptor(
        @mesh.MeshVertexAttribute::color(),
        5,
      ),
    )
  }
  pbr_push_standard_material_feature_shader_defs(
    shader_defs, standard_material_texture_features,
  )
  if !pbr_mesh_key_msaa_samples_is_one(mesh_key_bits) {
    shader_defs.push(pbr_shader_def("MULTISAMPLED"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_READS_VIEW_TRANSMISSION_TEXTURE) != 0UL {
    shader_defs.push(pbr_shader_def("READS_VIEW_TRANSMISSION_TEXTURE"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_SCREEN_SPACE_AMBIENT_OCCLUSION) != 0UL {
    shader_defs.push(pbr_shader_def("SCREEN_SPACE_AMBIENT_OCCLUSION"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_CONTACT_SHADOWS) != 0UL {
    shader_defs.push(pbr_shader_def("CONTACT_SHADOWS"))
  }
  let (
    pipeline_label,
    color_target_blend,
    depth_write_enabled,
    alpha_to_coverage_enabled,
  ) = pbr_mesh_pipeline_blend_state(mesh_key_bits, shader_defs)
  shader_defs.push(pbr_shader_def("BLUE_NOISE_TEXTURE"))
  shader_defs.push(pbr_shader_def("DFG_LUT"))
  shader_defs.push(pbr_shader_def("AREA_LIGHT_LUTS"))
  if (mesh_key_bits & MESH_PIPELINE_KEY_TONEMAP_IN_SHADER) != 0UL {
    shader_defs.push(pbr_shader_def("TONEMAP_IN_SHADER"))
    shader_defs.push(
      pbr_shader_def_uint("TONEMAPPING_LUT_TEXTURE_BINDING_INDEX", 18U),
    )
    shader_defs.push(
      pbr_shader_def_uint("TONEMAPPING_LUT_SAMPLER_BINDING_INDEX", 19U),
    )
    let tonemap_method = (
        mesh_key_bits >> MESH_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS
      ) &
      MESH_PIPELINE_KEY_TONEMAP_METHOD_MASK_BITS
    match tonemap_method {
      1UL => shader_defs.push(pbr_shader_def("TONEMAP_METHOD_REINHARD"))
      2UL =>
        shader_defs.push(pbr_shader_def("TONEMAP_METHOD_REINHARD_LUMINANCE"))
      3UL => shader_defs.push(pbr_shader_def("TONEMAP_METHOD_ACES_FITTED"))
      4UL => shader_defs.push(pbr_shader_def("TONEMAP_METHOD_AGX"))
      5UL =>
        shader_defs.push(
          pbr_shader_def("TONEMAP_METHOD_SOMEWHAT_BORING_DISPLAY_TRANSFORM"),
        )
      6UL => shader_defs.push(pbr_shader_def("TONEMAP_METHOD_TONY_MC_MAPFACE"))
      7UL => shader_defs.push(pbr_shader_def("TONEMAP_METHOD_BLENDER_FILMIC"))
      8UL => shader_defs.push(pbr_shader_def("TONEMAP_METHOD_PBR_NEUTRAL"))
      _ => shader_defs.push(pbr_shader_def("TONEMAP_METHOD_NONE"))
    }
    if (mesh_key_bits & MESH_PIPELINE_KEY_DEBAND_DITHER) != 0UL {
      shader_defs.push(pbr_shader_def("DEBAND_DITHER"))
    }
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_MAY_DISCARD) != 0UL {
    shader_defs.push(pbr_shader_def("MAY_DISCARD"))
  }
  pbr_push_mesh_prepass_shader_defs(mesh_key_bits, shader_defs)
  if (mesh_key_bits & MESH_PIPELINE_KEY_ENVIRONMENT_MAP) != 0UL {
    shader_defs.push(pbr_shader_def("ENVIRONMENT_MAP"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_IRRADIANCE_VOLUME) != 0UL &&
    @pbr_light_probe.IRRADIANCE_VOLUMES_ARE_USABLE {
    shader_defs.push(pbr_shader_def("IRRADIANCE_VOLUME"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_LIGHTMAPPED) != 0UL {
    shader_defs.push(pbr_shader_def("LIGHTMAP"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_LIGHTMAP_BICUBIC_SAMPLING) != 0UL {
    shader_defs.push(pbr_shader_def("LIGHTMAP_BICUBIC_SAMPLING"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_TEMPORAL_JITTER) != 0UL {
    shader_defs.push(pbr_shader_def("TEMPORAL_JITTER"))
  }
  pbr_push_shadow_filter_method_shader_def(mesh_key_bits, shader_defs)
  if (mesh_key_bits & MESH_PIPELINE_KEY_SCREEN_SPACE_REFLECTIONS) != 0UL {
    shader_defs.push(pbr_shader_def("SCREEN_SPACE_REFLECTIONS"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_VISIBILITY_RANGE_DITHER) != 0UL {
    shader_defs.push(pbr_shader_def("VISIBILITY_RANGE_DITHER"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_DISTANCE_FOG) != 0UL {
    shader_defs.push(pbr_shader_def("DISTANCE_FOG"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_ATMOSPHERE) != 0UL {
    shader_defs.push(pbr_shader_def("ATMOSPHERE"))
  }
  if binding_arrays_are_usable {
    shader_defs.push(pbr_shader_def("MULTIPLE_LIGHT_PROBES_IN_ARRAY"))
    shader_defs.push(pbr_shader_def("MULTIPLE_LIGHTMAPS_IN_ARRAY"))
  }
  if @pbr_light_probe.IRRADIANCE_VOLUMES_ARE_USABLE {
    shader_defs.push(pbr_shader_def("IRRADIANCE_VOLUMES_ARE_USABLE"))
  }
  if clustered_decals_are_usable {
    shader_defs.push(pbr_shader_def("CLUSTERED_DECALS_ARE_USABLE"))
  }
  shader_defs.push(
    pbr_shader_def_int(
      "SCREEN_SPACE_SPECULAR_TRANSMISSION_BLUR_TAPS",
      pbr_screen_space_specular_transmission_blur_taps(mesh_key_bits),
    ),
  )
  pbr_push_view_projection_shader_def(mesh_key_bits, shader_defs)
  let draw_layout = pbr_setup_morph_and_skinning_defs(
    mesh_key_bits, layout, 6, shader_defs, vertex_attributes, binding_arrays_are_usable,
  )
  let vertex_buffer_layout = mesh_layout.get_layout(vertex_attributes) catch {
    error =>
      raise @material.specialized_mesh_pipeline_missing_vertex_attribute_error(
        error.with_pipeline_type(Some("PbrMeshPipeline")),
      )
  }
  let fragment_defs = pbr_shader_defs_clone(shader_defs)
  let mesh_view_layout = pbr_mesh_pipeline_view_layout(
    mesh_key_bits, binding_arrays_are_usable, clustered_decals_are_usable,
  )
  @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor()
  .with_label(Some(pipeline_label))
  .with_layout([
    mesh_view_layout.main_bind_group_layout_descriptor(),
    mesh_view_layout.binding_array_bind_group_layout_descriptor(),
    draw_layout,
  ])
  .with_vertex(
    @material.VertexState::new(
      Some(PBR_MESH_VERTEX_SHADER_PATH),
      shader_defs,
      None,
      [vertex_buffer_layout],
    ),
  )
  .with_fragment(
    Some(
      @material.FragmentState::new(
        Some(PBR_MESH_FRAGMENT_SHADER_PATH),
        fragment_defs,
        None,
        [
          Some(
            @material.ColorTargetState::new(
              pbr_mesh_key_target_format(mesh_key_bits),
              @wgpu.COLOR_WRITE_MASK_ALL,
              blend=color_target_blend,
            ),
          ),
        ],
      ),
    ),
  )
  .with_primitive(
    @render_resource.PrimitiveState::PrimitiveState()
    .with_topology(pbr_mesh_key_primitive_topology(mesh_key_bits))
    .with_strip_index_format(pbr_mesh_key_strip_index_format(mesh_key_bits)),
  )
  .with_depth_stencil(
    Some(
      @material.DepthStencilState::new(
        @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
        depth_write_enabled,
        @wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
      ),
    ),
  )
  .with_multisample(
    @material.MultisampleState::new(
      pbr_mesh_key_msaa_samples(mesh_key_bits),
      alpha_to_coverage_enabled~,
    ),
  )
}

///|
fn pbr_prepass_pipeline_descriptor(
  mesh_key : @material.ErasedMeshPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
  properties : @material.MaterialProperties,
  binding_arrays_are_usable : Bool,
  depth_clip_control_supported : Bool,
) -> @material.RenderPipelineDescriptor raise @material.SpecializedMeshPipelineError {
  let mesh_key_bits = mesh_key.downcast_u64("MeshPipelineKey")
  let motion_vector_prepass = (
      mesh_key_bits & MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS
    ) !=
    0UL
  let normal_prepass = (mesh_key_bits & MESH_PIPELINE_KEY_NORMAL_PREPASS) != 0UL
  let deferred_prepass = (mesh_key_bits & MESH_PIPELINE_KEY_DEFERRED_PREPASS) !=
    0UL
  let may_discard = (mesh_key_bits & MESH_PIPELINE_KEY_MAY_DISCARD) != 0UL
  let shader_defs : Array[@material.ShaderDefVal] = []
  let vertex_attributes : Array[@mesh.VertexAttributeDescriptor] = []
  shader_defs.push(pbr_shader_def("PREPASS_PIPELINE"))
  shader_defs.push(
    pbr_shader_def_uint(
      "MATERIAL_BIND_GROUP",
      MATERIAL_BIND_GROUP_INDEX.reinterpret_as_uint(),
    ),
  )
  shader_defs.push(pbr_shader_def("VERTEX_OUTPUT_INSTANCE_INDEX"))
  pbr_push_view_projection_shader_def(mesh_key_bits, shader_defs)
  if (mesh_key_bits & MESH_PIPELINE_KEY_DEPTH_PREPASS) != 0UL {
    shader_defs.push(pbr_shader_def("DEPTH_PREPASS"))
  }
  if may_discard {
    shader_defs.push(pbr_shader_def("MAY_DISCARD"))
  }
  let blend_key = mesh_key_bits & MESH_PIPELINE_KEY_BLEND_RESERVED_BITS
  if blend_key == MESH_PIPELINE_KEY_BLEND_PREMULTIPLIED_ALPHA {
    shader_defs.push(pbr_shader_def("BLEND_PREMULTIPLIED_ALPHA"))
  }
  if blend_key == MESH_PIPELINE_KEY_BLEND_ALPHA {
    shader_defs.push(pbr_shader_def("BLEND_ALPHA"))
  }
  let mesh_layout = layout.layout()
  if mesh_layout.contains(@mesh.MeshVertexAttribute::position().id()) {
    shader_defs.push(pbr_shader_def("VERTEX_POSITIONS"))
    vertex_attributes.push(
      pbr_mesh_vertex_attribute_descriptor(
        @mesh.MeshVertexAttribute::position(),
        0,
      ),
    )
  }
  if mesh_layout.contains(@mesh.MeshVertexAttribute::uv_0().id()) {
    shader_defs.push(pbr_shader_def("VERTEX_UVS"))
    shader_defs.push(pbr_shader_def("VERTEX_UVS_A"))
    vertex_attributes.push(
      pbr_mesh_vertex_attribute_descriptor(@mesh.MeshVertexAttribute::uv_0(), 1),
    )
  }
  if mesh_layout.contains(@mesh.MeshVertexAttribute::uv_1().id()) {
    shader_defs.push(pbr_shader_def("VERTEX_UVS"))
    shader_defs.push(pbr_shader_def("VERTEX_UVS_B"))
    vertex_attributes.push(
      pbr_mesh_vertex_attribute_descriptor(@mesh.MeshVertexAttribute::uv_1(), 2),
    )
  }
  if normal_prepass {
    shader_defs.push(pbr_shader_def("NORMAL_PREPASS"))
  }
  if normal_prepass || deferred_prepass {
    shader_defs.push(pbr_shader_def("NORMAL_PREPASS_OR_DEFERRED_PREPASS"))
    if mesh_layout.contains(@mesh.MeshVertexAttribute::normal().id()) {
      shader_defs.push(pbr_shader_def("VERTEX_NORMALS"))
      vertex_attributes.push(
        pbr_mesh_vertex_attribute_descriptor(
          @mesh.MeshVertexAttribute::normal(),
          3,
        ),
      )
    }
    if mesh_layout.contains(@mesh.MeshVertexAttribute::tangent().id()) {
      shader_defs.push(pbr_shader_def("VERTEX_TANGENTS"))
      vertex_attributes.push(
        pbr_mesh_vertex_attribute_descriptor(
          @mesh.MeshVertexAttribute::tangent(),
          4,
        ),
      )
    }
  }
  if motion_vector_prepass || deferred_prepass {
    shader_defs.push(
      pbr_shader_def("MOTION_VECTOR_PREPASS_OR_DEFERRED_PREPASS"),
    )
  }
  if deferred_prepass {
    shader_defs.push(pbr_shader_def("DEFERRED_PREPASS"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_LIGHTMAPPED) != 0UL {
    shader_defs.push(pbr_shader_def("LIGHTMAP"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_LIGHTMAP_BICUBIC_SAMPLING) != 0UL {
    shader_defs.push(pbr_shader_def("LIGHTMAP_BICUBIC_SAMPLING"))
  }
  if mesh_layout.contains(@mesh.MeshVertexAttribute::color().id()) {
    shader_defs.push(pbr_shader_def("VERTEX_COLORS"))
    vertex_attributes.push(
      pbr_mesh_vertex_attribute_descriptor(
        @mesh.MeshVertexAttribute::color(),
        7,
      ),
    )
  }
  if motion_vector_prepass {
    shader_defs.push(pbr_shader_def("MOTION_VECTOR_PREPASS"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_HAS_PREVIOUS_SKIN) != 0UL {
    shader_defs.push(pbr_shader_def("HAS_PREVIOUS_SKIN"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_HAS_PREVIOUS_MORPH) != 0UL {
    shader_defs.push(pbr_shader_def("HAS_PREVIOUS_MORPH"))
  }
  if binding_arrays_are_usable {
    shader_defs.push(pbr_shader_def("MULTIPLE_LIGHTMAPS_IN_ARRAY"))
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_VISIBILITY_RANGE_DITHER) != 0UL {
    shader_defs.push(pbr_shader_def("VISIBILITY_RANGE_DITHER"))
  }
  if normal_prepass || motion_vector_prepass || deferred_prepass {
    shader_defs.push(pbr_shader_def("PREPASS_FRAGMENT"))
  }
  let unclipped_depth_ortho = (
      mesh_key_bits & MESH_PIPELINE_KEY_UNCLIPPED_DEPTH_ORTHO
    ) !=
    0UL
  let emulate_unclipped_depth = unclipped_depth_ortho &&
    !depth_clip_control_supported
  if emulate_unclipped_depth {
    shader_defs.push(pbr_shader_def("UNCLIPPED_DEPTH_ORTHO_EMULATION"))
    shader_defs.push(pbr_shader_def("PREPASS_FRAGMENT"))
  }
  let native_unclipped_depth = unclipped_depth_ortho &&
    depth_clip_control_supported
  let draw_layout = pbr_setup_morph_and_skinning_defs(
    mesh_key_bits, layout, 5, shader_defs, vertex_attributes, binding_arrays_are_usable,
  )
  let vertex_buffer_layout = mesh_layout.get_layout(vertex_attributes) catch {
    error =>
      raise @material.specialized_mesh_pipeline_missing_vertex_attribute_error(
        error.with_pipeline_type(Some("PrepassPipeline")),
      )
  }
  let targets = pbr_prepass_target_descriptors(
    normal_prepass, motion_vector_prepass, deferred_prepass,
  )
  let fragment_required = targets.length() > 0 ||
    emulate_unclipped_depth ||
    (
      may_discard &&
      properties.get_shader(@material.PREPASS_FRAGMENT_SHADER_LABEL) is Some(_)
    )
  let fragment = if fragment_required {
    let fragment_shader = if deferred_prepass {
      match properties.get_shader(@material.DEFERRED_FRAGMENT_SHADER_LABEL) {
        Some(shader) => shader
        None => PBR_PREPASS_SHADER_PATH
      }
    } else {
      match properties.get_shader(@material.PREPASS_FRAGMENT_SHADER_LABEL) {
        Some(shader) => shader
        None => PBR_PREPASS_SHADER_PATH
      }
    }
    Some(
      @material.FragmentState::new(
        Some(fragment_shader),
        pbr_shader_defs_clone(shader_defs),
        None,
        targets,
      ),
    )
  } else {
    None
  }
  let vertex_shader = if deferred_prepass {
    match properties.get_shader(@material.DEFERRED_VERTEX_SHADER_LABEL) {
      Some(shader) => shader
      None => PBR_PREPASS_SHADER_PATH
    }
  } else {
    match properties.get_shader(@material.PREPASS_VERTEX_SHADER_LABEL) {
      Some(shader) => shader
      None => PBR_PREPASS_SHADER_PATH
    }
  }
  let empty_layout = pbr_prepass_empty_layout_descriptor()
  let material_layout = if pbr_prepass_is_depth_only_opaque(mesh_key_bits) &&
    !emulate_unclipped_depth {
    empty_layout
  } else {
    match properties.material_layout {
      Some(layout) => layout
      None => abort("PrepassPipeline requires a material bind group layout")
    }
  }
  @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor()
  .with_label(Some("prepass_pipeline"))
  .with_layout([
    pbr_prepass_view_layout_descriptor(motion_vector_prepass),
    pbr_prepass_empty_layout_descriptor(),
    draw_layout,
    material_layout,
  ])
  .with_vertex(
    @material.VertexState::new(Some(vertex_shader), shader_defs, None, [
      vertex_buffer_layout,
    ]),
  )
  .with_fragment(fragment)
  .with_primitive(
    @render_resource.PrimitiveState::PrimitiveState()
    .with_topology(pbr_mesh_key_primitive_topology(mesh_key_bits))
    .with_strip_index_format(pbr_mesh_key_strip_index_format(mesh_key_bits))
    .with_unclipped_depth(native_unclipped_depth),
  )
  .with_depth_stencil(
    Some(
      @material.DepthStencilState::new(
        @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
        true,
        @wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
      ),
    ),
  )
}

///|
pub struct PbrMaterialPipelineSpecializer {
  properties : @material.MaterialProperties
  binding_arrays_are_usable : Bool
  clustered_decals_are_usable : Bool
  standard_material_texture_features : StandardMaterialTextureFeatureSet
  max_fragment_samplers_per_shader_stage : UInt?
}

///|
pub fn PbrMaterialPipelineSpecializer::new(
  properties : @material.MaterialProperties,
  binding_arrays_are_usable? : Bool = false,
  clustered_decals_are_usable? : Bool = false,
  standard_material_texture_features? : StandardMaterialTextureFeatureSet = standard_material_default_texture_feature_set(),
  max_fragment_samplers_per_shader_stage? : UInt? = None,
) -> PbrMaterialPipelineSpecializer {
  PbrMaterialPipelineSpecializer::{
    properties,
    binding_arrays_are_usable,
    clustered_decals_are_usable,
    standard_material_texture_features,
    max_fragment_samplers_per_shader_stage,
  }
}

///|
pub fn PbrMaterialPipelineSpecializer::specialize(
  self : PbrMaterialPipelineSpecializer,
  key : @material.ErasedMaterialPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
) -> @material.RenderPipelineDescriptor raise @material.SpecializedMeshPipelineError {
  let mut descriptor = pbr_mesh_pipeline_descriptor(
    key.mesh_key(),
    layout,
    self.binding_arrays_are_usable,
    self.clustered_decals_are_usable,
    self.standard_material_texture_features,
  )
  pbr_validate_pipeline_layout_sampler_limit(
    descriptor,
    self.max_fragment_samplers_per_shader_stage,
  )
  descriptor.vertex.shader_defs.push(
    pbr_shader_def_uint(
      "MATERIAL_BIND_GROUP",
      MATERIAL_BIND_GROUP_INDEX.reinterpret_as_uint(),
    ),
  )
  let fragment = match descriptor.fragment {
    Some(fragment) => fragment
    None => abort("PbrMaterialPipelineSpecializer expected fragment state")
  }
  fragment.shader_defs.push(
    pbr_shader_def_uint(
      "MATERIAL_BIND_GROUP",
      MATERIAL_BIND_GROUP_INDEX.reinterpret_as_uint(),
    ),
  )
  descriptor = descriptor.with_fragment(Some(fragment))
  if self.properties.get_shader(@material.MATERIAL_VERTEX_SHADER_LABEL)
    is Some(vertex_shader) {
    descriptor = descriptor.with_vertex(
      @material.VertexState::new(
        Some(vertex_shader),
        descriptor.vertex.shader_defs,
        descriptor.vertex.entry_point,
        descriptor.vertex.buffers,
      ),
    )
  }
  if self.properties.get_shader(@material.MATERIAL_FRAGMENT_SHADER_LABEL)
    is Some(fragment_shader) {
    let fragment = match descriptor.fragment {
      Some(fragment) => fragment
      None => abort("PbrMaterialPipelineSpecializer expected fragment state")
    }
    descriptor = descriptor.with_fragment(
      Some(
        @material.FragmentState::new(
          Some(fragment_shader),
          fragment.shader_defs,
          fragment.entry_point,
          fragment.targets,
        ),
      ),
    )
  }
  guard self.properties.material_layout is Some(material_layout) else {
    abort(
      "PbrMaterialPipelineSpecializer requires a material bind group layout",
    )
  }
  descriptor = descriptor.set_layout(MATERIAL_BIND_GROUP_INDEX, material_layout)
  descriptor = pbr_specialize_standard_material_descriptor(descriptor, key)
  if self.properties.user_specialize is Some(specialize) {
    descriptor = specialize("PbrMaterialPipeline", descriptor, layout, key)
  }
  if self.properties.bindless {
    descriptor.vertex.shader_defs.push(pbr_shader_def("BINDLESS"))
    let fragment = match descriptor.fragment {
      Some(fragment) => fragment
      None => abort("PbrMaterialPipelineSpecializer expected fragment state")
    }
    fragment.shader_defs.push(pbr_shader_def("BINDLESS"))
    descriptor = descriptor.with_fragment(Some(fragment))
  }
  descriptor
}

///|
pub struct PbrPrepassPipelineSpecializer {
  properties : @material.MaterialProperties
  binding_arrays_are_usable : Bool
  depth_clip_control_supported : Bool
}

///|
pub fn PbrPrepassPipelineSpecializer::new(
  properties : @material.MaterialProperties,
  binding_arrays_are_usable? : Bool = false,
  depth_clip_control_supported? : Bool = false,
) -> PbrPrepassPipelineSpecializer {
  PbrPrepassPipelineSpecializer::{
    properties,
    binding_arrays_are_usable,
    depth_clip_control_supported,
  }
}

///|
pub fn PbrPrepassPipelineSpecializer::specialize(
  self : PbrPrepassPipelineSpecializer,
  key : @material.ErasedMaterialPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
) -> @material.RenderPipelineDescriptor raise @material.SpecializedMeshPipelineError {
  let mut descriptor = pbr_prepass_pipeline_descriptor(
    key.mesh_key(),
    layout,
    self.properties,
    self.binding_arrays_are_usable,
    self.depth_clip_control_supported,
  )
  if self.properties.user_specialize is Some(specialize) {
    descriptor = specialize("PrepassPipeline", descriptor, layout, key)
  }
  if self.properties.bindless {
    descriptor.vertex.shader_defs.push(pbr_shader_def("BINDLESS"))
    if descriptor.fragment is Some(fragment) {
      fragment.shader_defs.push(pbr_shader_def("BINDLESS"))
      descriptor = descriptor.with_fragment(Some(fragment))
    }
  }
  descriptor
}

///|
fn pbr_pipeline_cache_or_abort(
  world : @ecs.World,
) -> @render_resource.PipelineCache {
  match world.get_resource(@render.pipeline_cache_resource_key) {
    Some(cache) => cache
    None => abort("Missing PipelineCache resource in render world")
  }
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/prepass/mod.rs::init_prepass_pipeline`.
fn pbr_prepass_depth_clip_control_supported(world : @ecs.World) -> Bool {
  match world.get_resource(@render.render_device_resource_key) {
    Some(render_device) =>
      render_device.supports_rust_features_u64(
        @wgpu.FEATURES_DEPTH_CLIP_CONTROL,
      )
    None => false
  }
}

///|
fn pbr_register_pipeline_descriptor_for_same_frame_draw(
  pipeline_cache : @render_resource.PipelineCache,
  pipeline_id : @material.CachedRenderPipelineId,
) -> Unit {
  pipeline_cache.process_queue()
  let descriptor = pipeline_cache.get_render_pipeline_descriptor(pipeline_id) catch {
    _ => return
  }
  @render.host_gpu_register_mesh3d_material_pipeline_descriptor(
    material_pipeline_id=pipeline_id.id(),
    descriptor~,
  )
}

///|
fn pbr_material_base_specialize(
  world : @ecs.World,
  key : @material.ErasedMaterialPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
  properties : @material.MaterialProperties,
) -> @material.CachedRenderPipelineId raise @material.SpecializedMeshPipelineError {
  let pipeline_cache = pbr_pipeline_cache_or_abort(world)
  let state = @pbr_render.render3d_mesh_runtime_state_mut_or_abort(world)
  let state_value = state.peek()
  let specializer = PbrMaterialPipelineSpecializer::new(
    properties,
    binding_arrays_are_usable=state_value.binding_arrays_are_usable,
    clustered_decals_are_usable=state_value.clustered_decals_are_usable,
    standard_material_texture_features=pbr_render_world_standard_material_texture_features(
      world,
    ),
    max_fragment_samplers_per_shader_stage=match
      world.get_resource(@render.render_device_resource_key) {
      Some(render_device) =>
        Some(render_device.limits_max_samplers_per_shader_stage_u32())
      None => None
    },
  )
  let result = state_value.specialized_material_pipelines.specialize(
    pipeline_cache,
    fn(key, layout) raise @material.SpecializedMeshPipelineError {
      specializer.specialize(key, layout)
    },
    key,
    layout,
  )
  state.set(state_value)
  pbr_register_pipeline_descriptor_for_same_frame_draw(pipeline_cache, result)
  result
}

///|
fn pbr_material_prepass_specialize(
  world : @ecs.World,
  key : @material.ErasedMaterialPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
  properties : @material.MaterialProperties,
) -> @material.CachedRenderPipelineId raise @material.SpecializedMeshPipelineError {
  let pipeline_cache = pbr_pipeline_cache_or_abort(world)
  let state = @pbr_render.render3d_mesh_runtime_state_mut_or_abort(world)
  let state_value = state.peek()
  let specializer = PbrPrepassPipelineSpecializer::new(
    properties,
    binding_arrays_are_usable=state_value.binding_arrays_are_usable,
    depth_clip_control_supported=pbr_prepass_depth_clip_control_supported(world),
  )
  let result = state_value.specialized_prepass_material_pipelines.specialize(
    pipeline_cache,
    fn(key, layout) raise @material.SpecializedMeshPipelineError {
      specializer.specialize(key, layout)
    },
    key,
    layout,
  )
  state.set(state_value)
  pbr_register_pipeline_descriptor_for_same_frame_draw(pipeline_cache, result)
  result
}

///|
fn pbr_prepass_runtime_pipeline_id(
  pipeline_id : @material.CachedRenderPipelineId,
) -> @material.CachedRenderPipelineId {
  pipeline_id
}

///|
