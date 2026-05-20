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
fn pbr_material_specializer_test_skinned_layout() -> @mesh.MeshVertexBufferLayoutRef {
  let layouts = @mesh.MeshVertexBufferLayouts::default()
  layouts.insert(
    @mesh.MeshVertexBufferLayout::new(
      attribute_ids=[
        @mesh.MeshVertexAttribute::position().id(),
        @mesh.MeshVertexAttribute::normal().id(),
        @mesh.MeshVertexAttribute::uv_0().id(),
        @mesh.MeshVertexAttribute::color().id(),
        @mesh.MeshVertexAttribute::joint_index().id(),
        @mesh.MeshVertexAttribute::joint_weight().id(),
      ],
      layout=@mesh.VertexBufferLayout::new(
        array_stride=72,
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
          @mesh.VertexAttribute::new(
            offset=48,
            format=@mesh.MeshVertexFormat::Uint16x4,
            shader_location=13,
          ),
          @mesh.VertexAttribute::new(
            offset=56,
            format=@mesh.MeshVertexFormat::Float32x4,
            shader_location=14,
          ),
        ],
      ),
    ),
  )
}

///|
fn pbr_material_specializer_test_render_mesh() -> @render_mesh.RenderMesh {
  @render_mesh.RenderMesh::new(
    vertex_count=3,
    key_bits=@mesh.BaseMeshPipelineKey::from_primitive_topology(
      @mesh.Mesh3dPrimitiveTopology::TriangleList,
    ),
    layout=pbr_material_specializer_test_layout(),
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
test "pbr material pipeline specializer selects morphed skinned mesh layout" {
  let properties = @material.MaterialProperties::default().with_material_layout(
    Some(@material.BindGroupLayoutDescriptor::default()),
  )
  let specializer = PbrMaterialPipelineSpecializer::new(properties)
  let descriptor = try! specializer.specialize(
    pbr_material_specializer_test_key(mesh_bits=MESH_PIPELINE_KEY_MORPH_TARGETS),
    pbr_material_specializer_test_skinned_layout(),
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "MORPH_TARGETS",
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "SKINNED",
    ),
    content="true",
  )
  inspect(descriptor.layout[2].label(), content="morphed_skinned_mesh_layout")
  inspect(descriptor.layout[2].entries().length(), content="4")
  inspect(descriptor.layout[2].entries()[0].binding(), content="0")
  inspect(descriptor.layout[2].entries()[1].binding(), content="1")
  inspect(descriptor.layout[2].entries()[2].binding(), content="2")
  inspect(descriptor.layout[2].entries()[3].binding(), content="3")
  let vertex_layout = descriptor.vertex.buffers[0]
  inspect(vertex_layout.attributes[4].shader_location, content="6")
  inspect(vertex_layout.attributes[5].shader_location, content="7")
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
  inspect(descriptor.layout[0].label(), content="mesh_view_layout")
  inspect(
    descriptor.layout[1].label(),
    content="mesh_view_layout_binding_array",
  )
  inspect(descriptor.layout[2].label(), content="mesh_layout")
  inspect(descriptor.layout[0].entries().length(), content="21")
  inspect(descriptor.layout[1].entries().length(), content="3")
  inspect(descriptor.layout[2].entries().length(), content="1")
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
  debug_inspect(properties.prepass_specialize is Some(_), content="true")
  debug_inspect(
    properties.get_shader(@material.PREPASS_FRAGMENT_SHADER_LABEL),
    content="Some(\"pbr/render/pbr_prepass.wgsl\")",
  )
  debug_inspect(
    properties.get_shader(@material.DEFERRED_FRAGMENT_SHADER_LABEL),
    content="Some(\"pbr/render/pbr.wgsl\")",
  )
  let pipeline_key = material_pipeline_key_for_standard_material_render_mesh(
    properties,
    pbr_material_specializer_test_render_mesh(),
  )
  inspect(
    pipeline_key.mesh_key().bits() & MESH_PIPELINE_KEY_BLEND_ALPHA,
    content="805306368",
  )
  inspect(pipeline_key.type_tag(), content="StandardMaterial")
}

///|
test "pbr material pipeline key carries mesh-owned lightmap bits" {
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::default(),
    None,
    @material.OpaqueRendererMethod::Forward,
    true,
  )
  let pipeline_key = material_pipeline_key_for_standard_material_render_mesh(
    properties,
    pbr_material_specializer_test_render_mesh(),
    lightmapped=true,
    lightmap_bicubic_sampling=true,
  )
  inspect(
    pipeline_key.mesh_key().bits() & MESH_PIPELINE_KEY_LIGHTMAPPED,
    content="8192",
  )
  inspect(
    pipeline_key.mesh_key().bits() & MESH_PIPELINE_KEY_LIGHTMAP_BICUBIC_SAMPLING,
    content="16384",
  )
}

///|
test "pbr material pipeline gates lightmap binding-array defs on pipeline support" {
  let properties = @material.MaterialProperties::default().with_material_layout(
    Some(@material.BindGroupLayoutDescriptor::default()),
  )
  let default_specializer = PbrMaterialPipelineSpecializer::new(properties)
  let default_descriptor = try! default_specializer.specialize(
    pbr_material_specializer_test_key(mesh_bits=MESH_PIPELINE_KEY_LIGHTMAPPED),
    pbr_material_specializer_test_layout(),
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      default_descriptor.vertex.shader_defs,
      "MULTIPLE_LIGHTMAPS_IN_ARRAY",
    ),
    content="false",
  )
  let binding_array_specializer = PbrMaterialPipelineSpecializer::new(
    properties,
    binding_arrays_are_usable=true,
  )
  let binding_array_descriptor = try! binding_array_specializer.specialize(
    pbr_material_specializer_test_key(mesh_bits=MESH_PIPELINE_KEY_LIGHTMAPPED),
    pbr_material_specializer_test_layout(),
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      binding_array_descriptor.vertex.shader_defs,
      "MULTIPLE_LIGHT_PROBES_IN_ARRAY",
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      binding_array_descriptor.vertex.shader_defs,
      "MULTIPLE_LIGHTMAPS_IN_ARRAY",
    ),
    content="true",
  )
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
  let key = material_pipeline_key_for_standard_material_render_mesh(
    properties,
    pbr_material_specializer_test_render_mesh(),
  )
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

///|
test "pbr prepass pipeline specializer mirrors bevy layout and shader defs" {
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::default().with_alpha_mode(
      @material.AlphaMode3d::Mask(0.5F),
    ),
    None,
    @material.OpaqueRendererMethod::Forward,
    true,
  )
  let specializer = PbrPrepassPipelineSpecializer::new(properties)
  let descriptor = try! specializer.specialize(
    pbr_material_specializer_test_key(
      mesh_bits=MESH_PIPELINE_KEY_DEPTH_PREPASS |
        MESH_PIPELINE_KEY_NORMAL_PREPASS |
        MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS |
        MESH_PIPELINE_KEY_MAY_DISCARD,
    ),
    pbr_material_specializer_test_layout(),
  )
  debug_inspect(descriptor.label, content="Some(\"prepass_pipeline\")")
  inspect(descriptor.layout.length(), content="4")
  inspect(
    descriptor.layout[0].label(),
    content="prepass_view_layout_motion_vectors",
  )
  inspect(descriptor.layout[0].entries().length(), content="4")
  inspect(descriptor.layout[1].label(), content="prepass_empty_layout")
  inspect(descriptor.layout[2].label(), content="mesh_layout")
  inspect(descriptor.layout[3].label(), content="StandardMaterial")
  debug_inspect(
    descriptor.vertex.shader,
    content="Some(\"pbr/prepass/prepass.wgsl\")",
  )
  let vertex_layout = descriptor.vertex.buffers[0]
  inspect(vertex_layout.attributes[0].shader_location, content="0")
  inspect(vertex_layout.attributes[1].shader_location, content="1")
  inspect(vertex_layout.attributes[2].shader_location, content="3")
  inspect(vertex_layout.attributes[3].shader_location, content="7")
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "PREPASS_PIPELINE",
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "NORMAL_PREPASS",
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "MOTION_VECTOR_PREPASS",
    ),
    content="true",
  )
  guard descriptor.fragment is Some(fragment) else {
    abort("expected standard material prepass fragment state")
  }
  debug_inspect(
    fragment.shader,
    content="Some(\"pbr/render/pbr_prepass.wgsl\")",
  )
  inspect(fragment.targets.length(), content="2")
  debug_inspect(fragment.targets[0] is Some(_), content="true")
  debug_inspect(fragment.targets[1] is Some(_), content="true")
}

///|
test "pbr prepass depth-only opaque path uses empty material layout" {
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::default(),
    None,
    @material.OpaqueRendererMethod::Forward,
    true,
  )
  let specializer = PbrPrepassPipelineSpecializer::new(properties)
  let descriptor = try! specializer.specialize(
    pbr_material_specializer_test_key(mesh_bits=MESH_PIPELINE_KEY_DEPTH_PREPASS),
    pbr_material_specializer_test_layout(),
  )
  inspect(
    descriptor.layout[0].label(),
    content="prepass_view_layout_no_motion_vectors",
  )
  inspect(descriptor.layout[0].entries().length(), content="3")
  inspect(descriptor.layout[3].label(), content="prepass_empty_layout")
  debug_inspect(descriptor.fragment is None, content="true")
  let vertex_layout = descriptor.vertex.buffers[0]
  inspect(vertex_layout.attributes[0].shader_location, content="0")
  inspect(vertex_layout.attributes[1].shader_location, content="1")
  inspect(vertex_layout.attributes[2].shader_location, content="7")
}

///|
test "pbr prepass pipeline specializer selects morphed skinned motion layout" {
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::default(),
    None,
    @material.OpaqueRendererMethod::Forward,
    true,
  )
  let specializer = PbrPrepassPipelineSpecializer::new(properties)
  let descriptor = try! specializer.specialize(
    pbr_material_specializer_test_key(
      mesh_bits=MESH_PIPELINE_KEY_DEPTH_PREPASS |
        MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS |
        MESH_PIPELINE_KEY_MORPH_TARGETS,
    ),
    pbr_material_specializer_test_skinned_layout(),
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "MORPH_TARGETS",
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "SKINNED",
    ),
    content="true",
  )
  inspect(
    descriptor.layout[2].label(),
    content="morphed_skinned_motion_mesh_layout",
  )
  inspect(descriptor.layout[2].entries().length(), content="6")
  inspect(descriptor.layout[2].entries()[0].binding(), content="0")
  inspect(descriptor.layout[2].entries()[1].binding(), content="1")
  inspect(descriptor.layout[2].entries()[2].binding(), content="2")
  inspect(descriptor.layout[2].entries()[3].binding(), content="3")
  inspect(descriptor.layout[2].entries()[4].binding(), content="6")
  inspect(descriptor.layout[2].entries()[5].binding(), content="7")
  let vertex_layout = descriptor.vertex.buffers[0]
  inspect(vertex_layout.attributes[3].shader_location, content="5")
  inspect(vertex_layout.attributes[4].shader_location, content="6")
}

///|
test "pbr prepass pipeline gates lightmap binding-array defs on pipeline support" {
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::default(),
    None,
    @material.OpaqueRendererMethod::Forward,
    true,
  )
  let default_specializer = PbrPrepassPipelineSpecializer::new(properties)
  let default_descriptor = try! default_specializer.specialize(
    pbr_material_specializer_test_key(
      mesh_bits=MESH_PIPELINE_KEY_DEPTH_PREPASS | MESH_PIPELINE_KEY_LIGHTMAPPED,
    ),
    pbr_material_specializer_test_layout(),
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      default_descriptor.vertex.shader_defs,
      "MULTIPLE_LIGHTMAPS_IN_ARRAY",
    ),
    content="false",
  )
  let binding_array_specializer = PbrPrepassPipelineSpecializer::new(
    properties,
    binding_arrays_are_usable=true,
  )
  let binding_array_descriptor = try! binding_array_specializer.specialize(
    pbr_material_specializer_test_key(
      mesh_bits=MESH_PIPELINE_KEY_DEPTH_PREPASS | MESH_PIPELINE_KEY_LIGHTMAPPED,
    ),
    pbr_material_specializer_test_layout(),
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      binding_array_descriptor.vertex.shader_defs,
      "MULTIPLE_LIGHTMAPS_IN_ARRAY",
    ),
    content="true",
  )
}

///|
test "pbr material prepass specialization caches descriptors separately" {
  let world = @ecs.World::new()
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::default(),
    None,
    @material.OpaqueRendererMethod::Forward,
    true,
  )
  guard properties.prepass_specialize is Some(prepass_specialize) else {
    abort("expected StandardMaterial prepass specialize hook")
  }
  let key = @material.ErasedMaterialPipelineKey::new(
    @material.ErasedMeshPipelineKey::new(
      material_pipeline_key_for_standard_material_render_mesh(
        properties,
        pbr_material_specializer_test_render_mesh(),
      )
      .mesh_key()
      .bits() |
      MESH_PIPELINE_KEY_DEPTH_PREPASS,
      "MeshPipelineKey",
    ),
    properties.material_key,
    "StandardMaterial",
  )
  let layout = pbr_material_specializer_test_layout()
  let first_id = try! @material.material_specialize_prepass(
    prepass_specialize, world, key, layout, properties,
  )
  let second_id = try! @material.material_specialize_prepass(
    prepass_specialize, world, key, layout, properties,
  )
  let state_ref = @pbr_render.render3d_mesh_runtime_state_ref_or_abort(world)
  inspect(first_id.id(), content="0")
  inspect(second_id.id(), content="0")
  inspect(
    state_ref.val.specialized_material_pipelines.vertex_layout_cache_len(),
    content="0",
  )
  inspect(
    state_ref.val.specialized_prepass_material_pipelines.mesh_layout_cache_len(),
    content="1",
  )
  guard state_ref.val.specialized_prepass_material_pipelines.render_pipeline_descriptor(
      first_id,
    )
    is Some(descriptor) else {
    abort("expected cached prepass material descriptor")
  }
  debug_inspect(descriptor.label, content="Some(\"prepass_pipeline\")")
}

///|
test "pbr prepass runtime pipeline ids do not collide with main pass cache ids" {
  let prepass_zero = pbr_prepass_runtime_pipeline_id(
    @material.CachedRenderPipelineId::new(0UL),
  )
  let prepass_one = pbr_prepass_runtime_pipeline_id(
    @material.CachedRenderPipelineId::new(1UL),
  )
  inspect(prepass_zero.id(), content="4611686018427387904")
  inspect(prepass_one.id(), content="4611686018427387905")
}
