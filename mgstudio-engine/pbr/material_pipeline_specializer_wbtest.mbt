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
  let layouts = @mesh.MeshVertexBufferLayouts::MeshVertexBufferLayouts()
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
  let layouts = @mesh.MeshVertexBufferLayouts::MeshVertexBufferLayouts()
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
  material_bits? : UInt64 = STANDARD_MATERIAL_KEY_CULL_BACK,
) -> @material.ErasedMaterialPipelineKey {
  @material.ErasedMaterialPipelineKey::new(
    @material.ErasedMeshPipelineKey::new(mesh_bits, "MeshPipelineKey"),
    @material.ErasedMaterialKey::new(material_bits, "StandardMaterialKey"),
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
fn pbr_material_specializer_shader_defs_contain_int(
  shader_defs : Array[@material.ShaderDefVal],
  name : String,
  value : Int,
) -> Bool {
  for shader_def in shader_defs {
    match shader_def {
      @material.ShaderDefVal::Int(flag, flag_value) if flag == name &&
        flag_value == value => return true
      _ => ()
    }
  }
  false
}

///|
fn pbr_material_specializer_layout_has_binding(
  layout : @render_resource.BindGroupLayoutDescriptor,
  binding : Int,
) -> Bool {
  for entry in layout.entries() {
    if entry.binding() == binding {
      return true
    }
  }
  false
}

///|
test "pbr material pipeline specializer mirrors bevy mesh attribute shader defs" {
  let properties = @material.MaterialProperties::MaterialProperties().with_material_layout(
    Some(
      @render_resource.BindGroupLayoutDescriptor::BindGroupLayoutDescriptor(),
    ),
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
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      vertex_defs, "PBR_MULTI_LAYER_MATERIAL_TEXTURES_SUPPORTED",
    ),
    content="false",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      vertex_defs, "PBR_ANISOTROPY_TEXTURE_SUPPORTED",
    ),
    content="false",
  )
  guard descriptor.fragment is Some(fragment) else {
    abort("expected pbr fragment state")
  }
  for shader_def in ["BLUE_NOISE_TEXTURE", "DFG_LUT", "AREA_LIGHT_LUTS"] {
    debug_inspect(
      pbr_material_specializer_shader_defs_contain_flag(
        fragment.shader_defs,
        shader_def,
      ),
      content="true",
    )
  }
  let vertex_layout = descriptor.vertex.buffers[0]
  inspect(vertex_layout.attributes[0].shader_location, content="0")
  inspect(vertex_layout.attributes[1].shader_location, content="1")
  inspect(vertex_layout.attributes[2].shader_location, content="2")
  inspect(vertex_layout.attributes[3].shader_location, content="5")
}

///|
test "pbr material pipeline specializer mirrors bevy view projection shader defs" {
  let properties = @material.MaterialProperties::MaterialProperties().with_material_layout(
    Some(
      @render_resource.BindGroupLayoutDescriptor::BindGroupLayoutDescriptor(),
    ),
  )
  let descriptor = try! PbrMaterialPipelineSpecializer::new(properties).specialize(
    pbr_material_specializer_test_key(
      mesh_bits=MESH_PIPELINE_KEY_VIEW_PROJECTION_PERSPECTIVE,
    ),
    pbr_material_specializer_test_layout(),
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "VIEW_PROJECTION_PERSPECTIVE",
    ),
    content="true",
  )
  guard descriptor.fragment is Some(fragment) else {
    abort("expected pbr fragment state")
  }
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      fragment.shader_defs,
      "VIEW_PROJECTION_PERSPECTIVE",
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      fragment.shader_defs,
      "VIEW_PROJECTION_ORTHOGRAPHIC",
    ),
    content="false",
  )
}

///|
test "pbr material pipeline specializer mirrors StandardMaterial shader defs" {
  let properties = @material.MaterialProperties::MaterialProperties().with_material_layout(
    Some(
      @render_resource.BindGroupLayoutDescriptor::BindGroupLayoutDescriptor(),
    ),
  )
  let material_bits = STANDARD_MATERIAL_KEY_CULL_BACK |
    STANDARD_MATERIAL_KEY_NORMAL_MAP |
    STANDARD_MATERIAL_KEY_DIFFUSE_TRANSMISSION |
    STANDARD_MATERIAL_KEY_SPECULAR_TRANSMISSION |
    STANDARD_MATERIAL_KEY_CLEARCOAT |
    STANDARD_MATERIAL_KEY_CLEARCOAT_NORMAL_MAP |
    STANDARD_MATERIAL_KEY_ANISOTROPY
  let descriptor = try! PbrMaterialPipelineSpecializer::new(properties).specialize(
    pbr_material_specializer_test_key(material_bits~),
    pbr_material_specializer_test_layout(),
  )
  debug_inspect(descriptor.label, content="Some(\"pbr_opaque_mesh_pipeline\")")
  debug_inspect(
    descriptor.primitive.cull_mode == Some(@wgpu.CULL_MODE_BACK),
    content="true",
  )
  guard descriptor.fragment is Some(fragment) else {
    abort("expected pbr fragment state")
  }
  for
    shader_def in [
      "STANDARD_MATERIAL_NORMAL_MAP", "STANDARD_MATERIAL_DIFFUSE_TRANSMISSION", "STANDARD_MATERIAL_SPECULAR_TRANSMISSION",
      "STANDARD_MATERIAL_DIFFUSE_OR_SPECULAR_TRANSMISSION", "STANDARD_MATERIAL_CLEARCOAT",
      "STANDARD_MATERIAL_CLEARCOAT_NORMAL_MAP", "STANDARD_MATERIAL_ANISOTROPY",
    ] {
    debug_inspect(
      pbr_material_specializer_shader_defs_contain_flag(
        fragment.shader_defs,
        shader_def,
      ),
      content="true",
    )
  }
}

///|
test "pbr material pipeline specializer mirrors StandardMaterial inverted culling" {
  let properties = @material.MaterialProperties::MaterialProperties().with_material_layout(
    Some(
      @render_resource.BindGroupLayoutDescriptor::BindGroupLayoutDescriptor(),
    ),
  )
  let descriptor = try! PbrMaterialPipelineSpecializer::new(properties).specialize(
    pbr_material_specializer_test_key(
      mesh_bits=MESH_PIPELINE_KEY_INVERT_CULLING,
      material_bits=STANDARD_MATERIAL_KEY_CULL_BACK,
    ),
    pbr_material_specializer_test_layout(),
  )
  debug_inspect(
    descriptor.primitive.cull_mode == Some(@wgpu.CULL_MODE_FRONT),
    content="true",
  )
}

///|
test "pbr material pipeline specializer selects morphed skinned mesh layout" {
  let properties = @material.MaterialProperties::MaterialProperties().with_material_layout(
    Some(
      @render_resource.BindGroupLayoutDescriptor::BindGroupLayoutDescriptor(),
    ),
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
  inspect(descriptor.layout[2].entries().length(), content="5")
  inspect(descriptor.layout[2].entries()[0].binding(), content="0")
  inspect(descriptor.layout[2].entries()[1].binding(), content="1")
  inspect(descriptor.layout[2].entries()[2].binding(), content="2")
  inspect(descriptor.layout[2].entries()[3].binding(), content="3")
  inspect(descriptor.layout[2].entries()[4].binding(), content="8")
  let vertex_layout = descriptor.vertex.buffers[0]
  inspect(vertex_layout.attributes[4].shader_location, content="6")
  inspect(vertex_layout.attributes[5].shader_location, content="7")
}

///|
test "pbr material pipeline specializer inserts material bind group and overrides shaders" {
  let properties = @material.MaterialProperties::MaterialProperties()
    .with_material_layout(
      Some(
        @render_resource.BindGroupLayoutDescriptor::BindGroupLayoutDescriptor(),
      ),
    )
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
      mesh_bits=MESH_PIPELINE_KEY_READS_VIEW_TRANSMISSION_TEXTURE |
        MESH_PIPELINE_KEY_SCREEN_SPACE_SPECULAR_TRANSMISSION_MEDIUM,
    ),
    pbr_material_specializer_test_layout(),
  )
  inspect(descriptor.layout.length(), content="4")
  inspect(
    descriptor.layout[0].label(),
    content="mesh_view_layout:stbn,area_light_luts,dfg_lut",
  )
  inspect(
    descriptor.layout[1].label(),
    content="mesh_view_layout_binding_array:stbn,area_light_luts,dfg_lut",
  )
  inspect(descriptor.layout[2].label(), content="mesh_layout")
  inspect(descriptor.layout[0].entries().length(), content="19")
  inspect(descriptor.layout[1].entries().length(), content="0")
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
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_int(
      fragment.shader_defs,
      "SCREEN_SPACE_SPECULAR_TRANSMISSION_BLUR_TAPS",
      8,
    ),
    content="true",
  )
}

///|
test "pbr standard material properties install base specialization hook" {
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::StandardMaterial().with_alpha_mode(
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
    @material.StandardMaterial::StandardMaterial(),
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
    content="4096",
  )
  inspect(
    pipeline_key.mesh_key().bits() & MESH_PIPELINE_KEY_LIGHTMAP_BICUBIC_SAMPLING,
    content="8192",
  )
}

///|
test "pbr material pipeline key carries bevy view bits into descriptor layout" {
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::StandardMaterial(),
    None,
    @material.OpaqueRendererMethod::Forward,
    true,
  )
  let view_key_bits = mesh_pipeline_key_msaa_bits(4) |
    MESH_PIPELINE_KEY_TONEMAP_IN_SHADER |
    MESH_PIPELINE_KEY_DEBAND_DITHER |
    MESH_PIPELINE_KEY_NORMAL_PREPASS |
    (6UL << MESH_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS) |
    (1UL << MESH_PIPELINE_KEY_SHADOW_FILTER_METHOD_SHIFT_BITS) |
    (1UL << MESH_PIPELINE_KEY_VIEW_PROJECTION_SHIFT_BITS)
  let pipeline_key = material_pipeline_key_for_standard_material_render_mesh(
    properties,
    pbr_material_specializer_test_render_mesh(),
    view_key_bits~,
    msaa_samples=4,
  )
  debug_inspect(
    (pipeline_key.mesh_key().bits() & view_key_bits) == view_key_bits,
    content="true",
  )
  let specializer = PbrMaterialPipelineSpecializer::new(properties)
  let descriptor = try! specializer.specialize(
    pipeline_key,
    pbr_material_specializer_test_layout(),
  )
  inspect(
    descriptor.layout[0].label(),
    content="mesh_view_layout:multisampled,normal_prepass,stbn,tonemap_in_shader,area_light_luts,dfg_lut",
  )
  debug_inspect(
    pbr_material_specializer_layout_has_binding(descriptor.layout[0], 18),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_layout_has_binding(descriptor.layout[0], 37),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_layout_has_binding(descriptor.layout[0], 19),
    content="true",
  )
  guard descriptor.fragment is Some(fragment) else {
    abort("expected pbr fragment state")
  }
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      fragment.shader_defs,
      "TONEMAP_IN_SHADER",
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      fragment.shader_defs,
      "TONEMAP_METHOD_TONY_MC_MAPFACE",
    ),
    content="true",
  )
}

///|
test "pbr material pipeline gates lightmap binding-array defs on pipeline support" {
  let properties = @material.MaterialProperties::MaterialProperties().with_material_layout(
    Some(
      @render_resource.BindGroupLayoutDescriptor::BindGroupLayoutDescriptor(),
    ),
  )
  let default_specializer = PbrMaterialPipelineSpecializer::new(properties)
  let default_descriptor = try! default_specializer.specialize(
    pbr_material_specializer_test_key(mesh_bits=MESH_PIPELINE_KEY_LIGHTMAPPED),
    pbr_material_specializer_test_layout(),
  )
  inspect(
    default_descriptor.layout[2].label(),
    content="lightmapped_mesh_layout",
  )
  inspect(default_descriptor.layout[2].entries()[1].count(), content="0")
  inspect(default_descriptor.layout[2].entries()[2].count(), content="0")
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      default_descriptor.vertex.shader_defs,
      "LIGHTMAP",
    ),
    content="true",
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
  inspect(
    binding_array_descriptor.layout[2].label(),
    content="lightmapped_mesh_layout",
  )
  inspect(binding_array_descriptor.layout[2].entries()[1].count(), content="4")
  inspect(binding_array_descriptor.layout[2].entries()[2].count(), content="4")
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
      "LIGHTMAP",
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      binding_array_descriptor.vertex.shader_defs,
      "LIGHTMAP_BICUBIC_SAMPLING",
    ),
    content="false",
  )
  let bicubic_descriptor = try! binding_array_specializer.specialize(
    pbr_material_specializer_test_key(
      mesh_bits=MESH_PIPELINE_KEY_LIGHTMAPPED |
        MESH_PIPELINE_KEY_LIGHTMAP_BICUBIC_SAMPLING,
    ),
    pbr_material_specializer_test_layout(),
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      bicubic_descriptor.vertex.shader_defs,
      "LIGHTMAP_BICUBIC_SAMPLING",
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
test "pbr material pipeline keeps clustered decal shader defs and layout in sync" {
  let properties = @material.MaterialProperties::MaterialProperties().with_material_layout(
    Some(
      @render_resource.BindGroupLayoutDescriptor::BindGroupLayoutDescriptor(),
    ),
  )
  let default_descriptor = try! PbrMaterialPipelineSpecializer::new(properties).specialize(
    pbr_material_specializer_test_key(),
    pbr_material_specializer_test_layout(),
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      default_descriptor.vertex.shader_defs,
      "CLUSTERED_DECALS_ARE_USABLE",
    ),
    content="false",
  )
  inspect(default_descriptor.layout[1].entries().length(), content="0")
  let decal_descriptor = try! PbrMaterialPipelineSpecializer::new(
    properties,
    binding_arrays_are_usable=true,
    clustered_decals_are_usable=true,
  ).specialize(
    pbr_material_specializer_test_key(),
    pbr_material_specializer_test_layout(),
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      decal_descriptor.vertex.shader_defs,
      "CLUSTERED_DECALS_ARE_USABLE",
    ),
    content="true",
  )
  inspect(decal_descriptor.layout[1].entries().length(), content="3")
  inspect(decal_descriptor.layout[1].entries()[0].binding(), content="5")
  inspect(decal_descriptor.layout[1].entries()[1].binding(), content="6")
  inspect(decal_descriptor.layout[1].entries()[1].count(), content="8")
  inspect(decal_descriptor.layout[1].entries()[2].binding(), content="7")
}

///|
test "pbr material pipeline carries Bevy primitive state from mesh key" {
  let properties = @material.MaterialProperties::MaterialProperties().with_material_layout(
    Some(
      @render_resource.BindGroupLayoutDescriptor::BindGroupLayoutDescriptor(),
    ),
  )
  let mesh_key = @mesh.BaseMeshPipelineKey::from_primitive_topology_and_strip_index(
    @mesh.Mesh3dPrimitiveTopology::LineStrip,
    Some(@mesh.Mesh3dIndexFormat::Uint16),
  )
  let descriptor = try! PbrMaterialPipelineSpecializer::new(properties).specialize(
    pbr_material_specializer_test_key(mesh_bits=mesh_key.bits()),
    pbr_material_specializer_test_layout(),
  )
  debug_inspect(descriptor.primitive.topology, content="3")
  debug_inspect(descriptor.primitive.strip_index_format, content="Some(1)")
}

///|
test "pbr material base specialization caches descriptors from real material properties" {
  let world = @ecs.World::new()
  let pipeline_cache = @render_resource.PipelineCache::new()
  world.insert_resource(@render.pipeline_cache_resource_key, pipeline_cache)
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::StandardMaterial(),
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
  let state = @pbr_render.render3d_mesh_runtime_state_mut_or_abort(world)
  inspect(first_id.id(), content="0")
  inspect(second_id.id(), content="0")
  inspect(
    state.peek().specialized_material_pipelines.mesh_layout_cache_len(),
    content="1",
  )
  inspect(
    state.peek().specialized_material_pipelines.vertex_layout_cache_len(),
    content="1",
  )
  pipeline_cache.process_queue()
  let descriptor = try! pipeline_cache.get_render_pipeline_descriptor(first_id)
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
    @material.StandardMaterial::StandardMaterial().with_alpha_mode(
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
    @material.StandardMaterial::StandardMaterial(),
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
test "pbr prepass pipeline emulates unclipped depth when depth clip control is missing" {
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::StandardMaterial(),
    None,
    @material.OpaqueRendererMethod::Forward,
    true,
  )
  let specializer = PbrPrepassPipelineSpecializer::new(
    properties,
    depth_clip_control_supported=false,
  )
  let descriptor = try! specializer.specialize(
    pbr_material_specializer_test_key(
      mesh_bits=MESH_PIPELINE_KEY_DEPTH_PREPASS |
        MESH_PIPELINE_KEY_UNCLIPPED_DEPTH_ORTHO,
    ),
    pbr_material_specializer_test_layout(),
  )
  inspect(descriptor.layout[3].label(), content="StandardMaterial")
  debug_inspect(descriptor.primitive.unclipped_depth, content="false")
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "UNCLIPPED_DEPTH_ORTHO_EMULATION",
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "PREPASS_FRAGMENT",
    ),
    content="true",
  )
  guard descriptor.fragment is Some(fragment) else {
    abort("expected unclipped depth emulation fragment")
  }
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      fragment.shader_defs,
      "UNCLIPPED_DEPTH_ORTHO_EMULATION",
    ),
    content="true",
  )
}

///|
test "pbr prepass pipeline uses native unclipped depth when depth clip control exists" {
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::StandardMaterial(),
    None,
    @material.OpaqueRendererMethod::Forward,
    true,
  )
  let specializer = PbrPrepassPipelineSpecializer::new(
    properties,
    depth_clip_control_supported=true,
  )
  let descriptor = try! specializer.specialize(
    pbr_material_specializer_test_key(
      mesh_bits=MESH_PIPELINE_KEY_DEPTH_PREPASS |
        MESH_PIPELINE_KEY_UNCLIPPED_DEPTH_ORTHO,
    ),
    pbr_material_specializer_test_layout(),
  )
  inspect(descriptor.layout[3].label(), content="prepass_empty_layout")
  debug_inspect(descriptor.primitive.unclipped_depth, content="true")
  debug_inspect(descriptor.fragment is None, content="true")
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "UNCLIPPED_DEPTH_ORTHO_EMULATION",
    ),
    content="false",
  )
}

///|
test "pbr prepass pipeline mirrors bevy view projection shader defs" {
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::StandardMaterial(),
    None,
    @material.OpaqueRendererMethod::Forward,
    true,
  )
  let descriptor = try! PbrPrepassPipelineSpecializer::new(properties).specialize(
    pbr_material_specializer_test_key(
      mesh_bits=MESH_PIPELINE_KEY_DEPTH_PREPASS |
        MESH_PIPELINE_KEY_VIEW_PROJECTION_ORTHOGRAPHIC,
    ),
    pbr_material_specializer_test_layout(),
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "VIEW_PROJECTION_ORTHOGRAPHIC",
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "VIEW_PROJECTION_PERSPECTIVE",
    ),
    content="false",
  )
}

///|
test "pbr prepass pipeline carries Bevy primitive state from mesh key" {
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::StandardMaterial(),
    None,
    @material.OpaqueRendererMethod::Forward,
    true,
  )
  let mesh_key = @mesh.BaseMeshPipelineKey::from_primitive_topology_and_strip_index(
    @mesh.Mesh3dPrimitiveTopology::LineStrip,
    Some(@mesh.Mesh3dIndexFormat::Uint16),
  )
  let descriptor = try! PbrPrepassPipelineSpecializer::new(properties).specialize(
    pbr_material_specializer_test_key(
      mesh_bits=mesh_key.bits() | MESH_PIPELINE_KEY_DEPTH_PREPASS,
    ),
    pbr_material_specializer_test_layout(),
  )
  debug_inspect(descriptor.primitive.topology, content="3")
  debug_inspect(descriptor.primitive.strip_index_format, content="Some(1)")
}

///|
test "pbr prepass pipeline specializer selects morphed skinned motion layout" {
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::StandardMaterial(),
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
  inspect(descriptor.layout[2].entries().length(), content="7")
  inspect(descriptor.layout[2].entries()[0].binding(), content="0")
  inspect(descriptor.layout[2].entries()[1].binding(), content="1")
  inspect(descriptor.layout[2].entries()[2].binding(), content="2")
  inspect(descriptor.layout[2].entries()[3].binding(), content="3")
  inspect(descriptor.layout[2].entries()[4].binding(), content="8")
  inspect(descriptor.layout[2].entries()[5].binding(), content="6")
  inspect(descriptor.layout[2].entries()[6].binding(), content="7")
  let vertex_layout = descriptor.vertex.buffers[0]
  inspect(vertex_layout.attributes[3].shader_location, content="5")
  inspect(vertex_layout.attributes[4].shader_location, content="6")
}

///|
test "pbr prepass pipeline gates lightmap binding-array defs on pipeline support" {
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::StandardMaterial(),
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
  inspect(
    default_descriptor.layout[2].label(),
    content="lightmapped_mesh_layout",
  )
  inspect(default_descriptor.layout[2].entries()[1].count(), content="0")
  inspect(default_descriptor.layout[2].entries()[2].count(), content="0")
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
  inspect(
    binding_array_descriptor.layout[2].label(),
    content="lightmapped_mesh_layout",
  )
  inspect(binding_array_descriptor.layout[2].entries()[1].count(), content="4")
  inspect(binding_array_descriptor.layout[2].entries()[2].count(), content="4")
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      binding_array_descriptor.vertex.shader_defs,
      "MULTIPLE_LIGHTMAPS_IN_ARRAY",
    ),
    content="true",
  )
}

///|
test "pbr material specialization keeps tangent defs for forward decal meshes" {
  let geometry = @mesh.Mesh3dGeometry::new(
    [
      @math.Vec3::new(-0.5F, -0.5F, 0.0F),
      @math.Vec3::new(0.5F, -0.5F, 0.0F),
      @math.Vec3::new(0.5F, 0.5F, 0.0F),
      @math.Vec3::new(-0.5F, 0.5F, 0.0F),
    ],
    [
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      @math.Vec2::new(0.0F, 1.0F),
    ],
    Some([0, 1, 2, 0, 2, 3]),
  )
  match geometry.generate_tangents() {
    Some(err) => {
      ignore(err)
      fail("forward decal test mesh must generate tangents")
    }
    None => ()
  }
  let render_mesh = @render_mesh.RenderMesh::from_mesh(
    @mesh.Mesh::from_3d_geometry(geometry),
    @mesh.MeshVertexBufferLayouts::MeshVertexBufferLayouts(),
  )
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::StandardMaterial(),
    Some(
      forward_decal_material_extension_metadata(
        ForwardDecalMaterialExt::new(1.0F),
      ),
    ),
    @material.OpaqueRendererMethod::Forward,
    true,
  )
  let pipeline_key = material_pipeline_key_for_standard_material_render_mesh(
    properties, render_mesh,
  )
  let descriptor = try! PbrMaterialPipelineSpecializer::new(properties).specialize(
    pipeline_key,
    render_mesh.layout(),
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "VERTEX_TANGENTS",
    ),
    content="true",
  )
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "FORWARD_DECAL",
    ),
    content="true",
  )
}

///|
test "pbr material prepass specialization caches descriptors separately" {
  let world = @ecs.World::new()
  let pipeline_cache = @render_resource.PipelineCache::new()
  world.insert_resource(@render.pipeline_cache_resource_key, pipeline_cache)
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::StandardMaterial(),
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
  let state = @pbr_render.render3d_mesh_runtime_state_mut_or_abort(world)
  inspect(first_id.id(), content="0")
  inspect(second_id.id(), content="0")
  inspect(
    state.peek().specialized_material_pipelines.vertex_layout_cache_len(),
    content="0",
  )
  inspect(
    state.peek().specialized_prepass_material_pipelines.mesh_layout_cache_len(),
    content="1",
  )
  pipeline_cache.process_queue()
  let descriptor = try! pipeline_cache.get_render_pipeline_descriptor(first_id)
  debug_inspect(descriptor.label, content="Some(\"prepass_pipeline\")")
}

///|
test "pbr material pipeline capability changes invalidate specialized descriptors" {
  let world = @ecs.World::new()
  let pipeline_cache = @render_resource.PipelineCache::new()
  world.insert_resource(@render.pipeline_cache_resource_key, pipeline_cache)
  let properties = render3d_material_properties_for_standard_material(
    @material.StandardMaterial::StandardMaterial(),
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
  ignore(
    try! @material.material_specialize_base(
      base_specialize,
      world,
      key,
      pbr_material_specializer_test_layout(),
      properties,
    ),
  )
  let state = @pbr_render.render3d_mesh_runtime_state_mut_or_abort(world)
  inspect(
    state.peek().specialized_material_pipelines.mesh_layout_cache_len(),
    content="1",
  )
  state.set(state.peek().with_pipeline_capabilities(true, true))
  inspect(
    state.peek().specialized_material_pipelines.mesh_layout_cache_len(),
    content="0",
  )
  inspect(
    state.peek().specialized_prepass_material_pipelines.mesh_layout_cache_len(),
    content="0",
  )
}

///|
test "pbr prepass runtime pipeline ids preserve global pipeline cache ids" {
  let prepass_zero = pbr_prepass_runtime_pipeline_id(
    @material.CachedRenderPipelineId::new(0UL),
  )
  let prepass_one = pbr_prepass_runtime_pipeline_id(
    @material.CachedRenderPipelineId::new(1UL),
  )
  inspect(prepass_zero.id(), content="0")
  inspect(prepass_one.id(), content="1")
}
