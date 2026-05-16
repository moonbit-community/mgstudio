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

///|
pub const PBR_MESH_VERTEX_SHADER_PATH : String = "pbr/render/mesh.wgsl"

///|
pub const PBR_MESH_FRAGMENT_SHADER_PATH : String = "pbr/render/pbr.wgsl"

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
fn pbr_mesh_pipeline_draw_layout_descriptor() -> @material.BindGroupLayoutDescriptor {
  let vertex_fragment = (@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT).to_uint()
  @material.BindGroupLayoutDescriptor::new("mesh_layout", [
    @render_resource.BindGroupLayoutEntry::new(
      0,
      vertex_fragment,
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Storage(true),
        false,
        176UL,
      ),
    ),
    @render_resource.BindGroupLayoutEntry::new(
      1,
      @wgpu.SHADER_STAGE_VERTEX.to_uint(),
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Storage(true),
        false,
        64UL,
      ),
    ),
  ])
}

///|
fn pbr_mesh_pipeline_descriptor(
  mesh_key : @material.ErasedMeshPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
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
    pbr_mesh_pipeline_draw_layout_descriptor(),
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
pub struct PbrMaterialPipelineSpecializer {
  properties : @material.MaterialProperties
}

///|
pub fn PbrMaterialPipelineSpecializer::new(
  properties : @material.MaterialProperties,
) -> PbrMaterialPipelineSpecializer {
  PbrMaterialPipelineSpecializer::{ properties, }
}

///|
pub fn PbrMaterialPipelineSpecializer::specialize(
  self : PbrMaterialPipelineSpecializer,
  key : @material.ErasedMaterialPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
) -> @material.RenderPipelineDescriptor raise @material.SpecializedMeshPipelineError {
  let mut descriptor = pbr_mesh_pipeline_descriptor(key.mesh_key(), layout)
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
fn pbr_material_base_specialize(
  world : @ecs.World,
  key : @material.ErasedMaterialPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
  properties : @material.MaterialProperties,
) -> @material.CachedRenderPipelineId raise @material.SpecializedMeshPipelineError {
  let state_ref = @pbr_render.render3d_mesh_runtime_state_ref_or_abort(world)
  let specializer = PbrMaterialPipelineSpecializer::new(properties)
  state_ref.val.specialized_material_pipelines.specialize(
    fn(key, layout) raise @material.SpecializedMeshPipelineError {
      specializer.specialize(key, layout)
    },
    key,
    layout,
  )
}

///|
