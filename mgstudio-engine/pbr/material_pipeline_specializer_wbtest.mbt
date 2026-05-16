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
fn pbr_material_specializer_test_layout() -> @mesh.MeshVertexBufferLayoutRef {
  let layouts = @mesh.MeshVertexBufferLayouts::default()
  layouts.insert(
    @mesh.MeshVertexBufferLayout::new(
      attribute_ids=[
        @mesh.MeshVertexAttribute::position().id(),
        @mesh.MeshVertexAttribute::normal().id(),
        @mesh.MeshVertexAttribute::uv_0().id(),
        @mesh.MeshVertexAttribute::color().id(),
      ],
      layout=@mesh.VertexBufferLayout::new(
        array_stride=48,
        step_mode=@mesh.MeshVertexStepMode::Vertex,
        attributes=[
          @mesh.VertexAttribute::new(
            offset=0,
            format=@mesh.MeshVertexFormat::Float32x3,
            shader_location=9,
          ),
          @mesh.VertexAttribute::new(
            offset=12,
            format=@mesh.MeshVertexFormat::Float32x3,
            shader_location=10,
          ),
          @mesh.VertexAttribute::new(
            offset=24,
            format=@mesh.MeshVertexFormat::Float32x2,
            shader_location=11,
          ),
          @mesh.VertexAttribute::new(
            offset=32,
            format=@mesh.MeshVertexFormat::Float32x4,
            shader_location=12,
          ),
        ],
      ),
    ),
  )
}

///|
fn pbr_material_specializer_test_key(
  mesh_bits? : UInt64 = 0UL,
) -> @material.ErasedMaterialPipelineKey {
  @material.ErasedMaterialPipelineKey::new(
    @material.ErasedMeshPipelineKey::new(mesh_bits, "MeshPipelineKey"),
    @material.ErasedMaterialKey::new(3, "StandardMaterialKey"),
    "MaterialPipelineKey",
  )
}

///|
fn pbr_material_specializer_shader_defs_contain_flag(
  shader_defs : Array[@material.ShaderDefVal],
  name : String,
) -> Bool {
  for shader_def in shader_defs {
    match shader_def {
      @material.ShaderDefVal::Flag(flag) if flag == name => return true
      _ => ()
    }
  }
  false
}

///|
fn pbr_material_specializer_shader_defs_contain_uint(
  shader_defs : Array[@material.ShaderDefVal],
  name : String,
  value : UInt,
) -> Bool {
  for shader_def in shader_defs {
    match shader_def {
      @material.ShaderDefVal::UInt(flag, flag_value) if flag == name &&
        flag_value == value => return true
      _ => ()
    }
  }
  false
}

///|
test "pbr material pipeline specializer mirrors bevy mesh attribute shader defs" {
  let properties = @material.MaterialProperties::default().with_material_layout(
    Some(@material.BindGroupLayoutDescriptor::default()),
  )
  let specializer = PbrMaterialPipelineSpecializer::new(properties)
  let descriptor = try! specializer.specialize(
    pbr_material_specializer_test_key(),
    pbr_material_specializer_test_layout(),
  )
  let vertex_defs = descriptor.vertex.shader_defs
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      vertex_defs, "MESH_PIPELINE",
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      vertex_defs, "VERTEX_POSITIONS",
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      vertex_defs, "VERTEX_NORMALS",
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      vertex_defs, "VERTEX_UVS_A",
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      vertex_defs, "VERTEX_COLORS",
    ),
    content="true",
  )
  let vertex_layout = descriptor.vertex.buffers[0]
  inspect(vertex_layout.attributes[0].shader_location, content="0")
  inspect(vertex_layout.attributes[1].shader_location, content="1")
  inspect(vertex_layout.attributes[2].shader_location, content="2")
  inspect(vertex_layout.attributes[3].shader_location, content="5")
}

///|
test "pbr material pipeline specializer inserts material bind group and overrides shaders" {
  let properties = @material.MaterialProperties::default()
    .with_material_layout(Some(@material.BindGroupLayoutDescriptor::default()))
    .with_bindless(true)
    .add_shader(
      @material.MATERIAL_VERTEX_SHADER_LABEL,
      "custom/material_vertex.wgsl",
    )
    .add_shader(
      @material.MATERIAL_FRAGMENT_SHADER_LABEL,
      "custom/material_fragment.wgsl",
    )
  let specializer = PbrMaterialPipelineSpecializer::new(properties)
  let descriptor = try! specializer.specialize(
    pbr_material_specializer_test_key(
      mesh_bits=MESH_PIPELINE_KEY_READS_VIEW_TRANSMISSION_TEXTURE,
    ),
    pbr_material_specializer_test_layout(),
  )
  inspect(descriptor.layout.length(), content="4")
  debug_inspect(
    descriptor.vertex.shader == Some("custom/material_vertex.wgsl"),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_uint(
      descriptor.vertex.shader_defs,
      "MATERIAL_BIND_GROUP",
      MATERIAL_BIND_GROUP_INDEX.reinterpret_as_uint(),
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "BINDLESS",
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "READS_VIEW_TRANSMISSION_TEXTURE",
    ),
    content="true",
  )
  guard descriptor.fragment is Some(fragment) else {
    abort("expected pbr material fragment state")
  }
  debug_inspect(
    fragment.shader == Some("custom/material_fragment.wgsl"),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_uint(
      fragment.shader_defs,
      "MATERIAL_BIND_GROUP",
      MATERIAL_BIND_GROUP_INDEX.reinterpret_as_uint(),
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      fragment.shader_defs,
      "BINDLESS",
    ),
    content="true",
  )
}

///|
test "pbr standard material properties install base specialization hook" {
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::default().with_alpha_mode(
      @material.AlphaMode3d::Blend,
    ),
    None,
    @material.OpaqueRendererMethod::Forward,
    true,
  )
  debug_inspect(properties.base_specialize is Some(_), content="true")
  let pipeline_key = material_pipeline_key_for_standard_material(properties)
  inspect(
    pipeline_key.mesh_key().bits() & MESH_PIPELINE_KEY_BLEND_ALPHA,
    content="805306368",
  )
  inspect(pipeline_key.type_tag(), content="StandardMaterial")
}

///|
test "pbr material base specialization caches descriptors from real material properties" {
  let world = @ecs.World::new()
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::default(),
    None,
    @material.OpaqueRendererMethod::Forward,
    true,
  )
  guard properties.base_specialize is Some(base_specialize) else {
    abort("expected StandardMaterial base specialize hook")
  }
  let key = material_pipeline_key_for_standard_material(properties)
  let layout = pbr_material_specializer_test_layout()
  let first_id = try! @material.material_specialize_base(
    base_specialize, world, key, layout, properties,
  )
  let second_id = try! @material.material_specialize_base(
    base_specialize, world, key, layout, properties,
  )
  let state_ref = @pbr_render.render3d_mesh_runtime_state_ref_or_abort(world)
  inspect(first_id.id(), content="0")
  inspect(second_id.id(), content="0")
  inspect(
    state_ref.val.specialized_material_pipelines.mesh_layout_cache_len(),
    content="1",
  )
  inspect(
    state_ref.val.specialized_material_pipelines.vertex_layout_cache_len(),
    content="1",
  )
  guard state_ref.val.specialized_material_pipelines.render_pipeline_descriptor(
      first_id,
    )
    is Some(descriptor) else {
    abort("expected cached pbr material descriptor")
  }
  inspect(descriptor.layout.length(), content="4")
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_uint(
      descriptor.vertex.shader_defs,
      "MATERIAL_BIND_GROUP",
      MATERIAL_BIND_GROUP_INDEX.reinterpret_as_uint(),
    ),
    content="true",
  )
}
