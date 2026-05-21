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
const MESH_PIPELINE_KEY_DEPTH_PREPASS : UInt64 = 8UL

///|
const MESH_PIPELINE_KEY_NORMAL_PREPASS : UInt64 = 16UL

///|
const MESH_PIPELINE_KEY_DEFERRED_PREPASS : UInt64 = 32UL

///|
const MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS : UInt64 = 64UL

///|
const MESH_PIPELINE_KEY_ALL_PREPASS_BITS : UInt64 = 16777464UL

///|
const MESH_PIPELINE_KEY_MORPH_TARGETS : UInt64 = 0x8000_0000_0000_0000UL

///|
const MESH_PIPELINE_KEY_VISIBILITY_RANGE_DITHER : UInt64 = 65536UL

///|
const MESH_PIPELINE_KEY_HAS_PREVIOUS_SKIN : UInt64 = 262144UL

///|
const MESH_PIPELINE_KEY_HAS_PREVIOUS_MORPH : UInt64 = 524288UL

///|
const MESH_PIPELINE_KEY_BLEND_RESERVED_BITS : UInt64 = 1879048192UL

///|
const PBR_PREPASS_RUNTIME_PIPELINE_ID_OFFSET : UInt64 = 0x4000000000000000UL

///|
fn pbr_shader_def(name : String) -> @material.ShaderDefVal {
  @material.ShaderDefVal::Flag(name)
}

///|
fn pbr_shader_def_uint(name : String, value : UInt) -> @material.ShaderDefVal {
  @material.ShaderDefVal::UInt(name, value)
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
fn pbr_mesh_pipeline_view_layout() -> @mesh_view_layout.MeshPipelineViewLayout {
  @mesh_view_layout.render3d_mesh_pipeline_view_layout(
    true,
    true,
    @mesh_view_layout.MeshPipelineViewLayoutKey::default(),
    clustered_decals_usable=false,
    irradiance_volumes_usable=false,
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
        @render_resource.BufferBindingType::Uniform,
        true,
        @pbr_render.RENDER3D_MORPH_BUFFER_SIZE_BYTES.to_uint64(),
      )
    @pbr_render.MeshBindingSlot3d::MorphTargets =>
      @render_resource.BindingType::TextureBinding(
        @render_resource.TextureSampleType::Float(false),
        @render_resource.TextureViewDimension::D3,
        false,
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
  if normal_prepass || deferred_prepass {
    targets.push(
      Some(
        @material.ColorTargetState::new(
          @wgpu.TEXTURE_FORMAT_RGB10_A2_UNORM,
          @wgpu.COLOR_WRITE_MASK_ALL,
        ),
      ),
    )
  } else if motion_vector_prepass {
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
  if (mesh_key_bits & MESH_PIPELINE_KEY_READS_VIEW_TRANSMISSION_TEXTURE) != 0UL {
    shader_defs.push(pbr_shader_def("READS_VIEW_TRANSMISSION_TEXTURE"))
  }
  if binding_arrays_are_usable {
    shader_defs.push(pbr_shader_def("MULTIPLE_LIGHT_PROBES_IN_ARRAY"))
    shader_defs.push(pbr_shader_def("MULTIPLE_LIGHTMAPS_IN_ARRAY"))
  }
  let draw_layout = pbr_setup_morph_and_skinning_defs(
    mesh_key_bits, layout, 6, shader_defs, vertex_attributes, binding_arrays_are_usable,
  )
  let vertex_buffer_layout = match mesh_layout.get_layout(vertex_attributes) {
    Ok(vertex_buffer_layout) => vertex_buffer_layout
    Err(error) =>
      raise @material.specialized_mesh_pipeline_missing_vertex_attribute_error(
        error.with_pipeline_type(Some("PbrMeshPipeline")),
      )
  }
  let fragment_defs = pbr_shader_defs_clone(shader_defs)
  let mesh_view_layout = pbr_mesh_pipeline_view_layout()
  @material.RenderPipelineDescriptor::default()
  .with_label(Some("opaque_mesh_pipeline"))
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
              @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
              @wgpu.COLOR_WRITE_MASK_ALL,
            ),
          ),
        ],
      ),
    ),
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
fn pbr_prepass_pipeline_descriptor(
  mesh_key : @material.ErasedMeshPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
  properties : @material.MaterialProperties,
  binding_arrays_are_usable : Bool,
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
  let draw_layout = pbr_setup_morph_and_skinning_defs(
    mesh_key_bits, layout, 5, shader_defs, vertex_attributes, binding_arrays_are_usable,
  )
  let vertex_buffer_layout = match mesh_layout.get_layout(vertex_attributes) {
    Ok(vertex_buffer_layout) => vertex_buffer_layout
    Err(error) =>
      raise @material.specialized_mesh_pipeline_missing_vertex_attribute_error(
        error.with_pipeline_type(Some("PrepassPipeline")),
      )
  }
  let targets = pbr_prepass_target_descriptors(
    normal_prepass, motion_vector_prepass, deferred_prepass,
  )
  let fragment_required = targets.length() > 0 ||
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
  let material_layout = if pbr_prepass_is_depth_only_opaque(mesh_key_bits) {
    empty_layout
  } else {
    match properties.material_layout {
      Some(layout) => layout
      None => abort("PrepassPipeline requires a material bind group layout")
    }
  }
  @material.RenderPipelineDescriptor::default()
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
}

///|
pub fn PbrMaterialPipelineSpecializer::new(
  properties : @material.MaterialProperties,
  binding_arrays_are_usable? : Bool = false,
) -> PbrMaterialPipelineSpecializer {
  PbrMaterialPipelineSpecializer::{ properties, binding_arrays_are_usable }
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
}

///|
pub fn PbrPrepassPipelineSpecializer::new(
  properties : @material.MaterialProperties,
  binding_arrays_are_usable? : Bool = false,
) -> PbrPrepassPipelineSpecializer {
  PbrPrepassPipelineSpecializer::{ properties, binding_arrays_are_usable }
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
fn pbr_material_base_specialize(
  world : @ecs.World,
  key : @material.ErasedMaterialPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
  properties : @material.MaterialProperties,
) -> @material.CachedRenderPipelineId raise @material.SpecializedMeshPipelineError {
  let state_ref = @pbr_render.render3d_mesh_runtime_state_ref_or_abort(world)
  let specializer = PbrMaterialPipelineSpecializer::new(
    properties,
    binding_arrays_are_usable=state_ref.val.binding_arrays_are_usable,
  )
  state_ref.val.specialized_material_pipelines.specialize(
    fn(key, layout) raise @material.SpecializedMeshPipelineError {
      specializer.specialize(key, layout)
    },
    key,
    layout,
  )
}

///|
fn pbr_material_prepass_specialize(
  world : @ecs.World,
  key : @material.ErasedMaterialPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
  properties : @material.MaterialProperties,
) -> @material.CachedRenderPipelineId raise @material.SpecializedMeshPipelineError {
  let state_ref = @pbr_render.render3d_mesh_runtime_state_ref_or_abort(world)
  let specializer = PbrPrepassPipelineSpecializer::new(
    properties,
    binding_arrays_are_usable=state_ref.val.binding_arrays_are_usable,
  )
  state_ref.val.specialized_prepass_material_pipelines.specialize(
    fn(key, layout) raise @material.SpecializedMeshPipelineError {
      specializer.specialize(key, layout)
    },
    key,
    layout,
  )
}

///|
fn pbr_prepass_runtime_pipeline_id(
  pipeline_id : @material.CachedRenderPipelineId,
) -> @material.CachedRenderPipelineId {
  @material.CachedRenderPipelineId::new(
    PBR_PREPASS_RUNTIME_PIPELINE_ID_OFFSET | pipeline_id.id(),
  )
}

///|
