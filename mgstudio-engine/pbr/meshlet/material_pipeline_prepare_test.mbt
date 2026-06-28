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
fn test_meshlet_material_entry(
  material_id : Int,
  pipeline_id : Int,
  bind_group : Int,
) -> MeshletViewMaterialEntry {
  MeshletViewMaterialEntry::new(
    material_id,
    pipeline_id,
    bind_group,
    MeshletMaterialPipelineDescriptor::new(),
  )
}

///|
test "pbr meshlet: material prepare entry count aggregates all passes" {
  let main_opaque = MeshletViewMaterialsMainOpaquePass::MeshletViewMaterialsMainOpaquePass()
  let prepass = MeshletViewMaterialsPrepass::MeshletViewMaterialsPrepass()
  let deferred = MeshletViewMaterialsDeferredGBufferPrepass::MeshletViewMaterialsDeferredGBufferPrepass()
  main_opaque.push(test_meshlet_material_entry(1, 2, 3))
  prepass.push(test_meshlet_material_entry(4, 5, 6))
  inspect(
    meshlet_material_prepare_entry_count(main_opaque, prepass, deferred),
    content="2",
  )
}

///|
test "pbr meshlet: prepare main opaque pass fills bins from material ids" {
  let main_opaque = MeshletViewMaterialsMainOpaquePass::MeshletViewMaterialsMainOpaquePass()
  prepare_material_meshlet_meshes_main_opaque_pass(main_opaque, [10, 20, 30])
  inspect(main_opaque.len(), content="3")
}

///|
test "pbr meshlet: prepare prepass respects deferred toggle" {
  let prepass = MeshletViewMaterialsPrepass::MeshletViewMaterialsPrepass()
  let deferred = MeshletViewMaterialsDeferredGBufferPrepass::MeshletViewMaterialsDeferredGBufferPrepass()
  prepare_material_meshlet_meshes_prepass(
    prepass,
    deferred,
    [7, 8],
    deferred_enabled=false,
  )
  inspect(prepass.len(), content="0")
  inspect(deferred.len(), content="0")
}

///|
test "pbr meshlet: main opaque pass filters by renderer method and transmission" {
  let main_opaque = MeshletViewMaterialsMainOpaquePass::MeshletViewMaterialsMainOpaquePass()
  prepare_material_meshlet_meshes_main_opaque_pass_with_inputs(main_opaque, [
    MeshletPreparedMaterialInput::new(1, 10).with_opaque_render_method(
      @material.OpaqueRendererMethod::Forward,
    ),
    MeshletPreparedMaterialInput::new(2, 11).with_opaque_render_method(
      @material.OpaqueRendererMethod::Deferred,
    ),
    MeshletPreparedMaterialInput::new(3, 12).with_reads_view_transmission_texture(
      true,
    ),
    MeshletPreparedMaterialInput::new(4, 13).with_alpha_mode(
      @material.AlphaMode3d::Blend,
    ),
  ])
  inspect(main_opaque.len(), content="1")
}

///|
test "pbr meshlet: prepass routes deferred materials to deferred bins" {
  let prepass = MeshletViewMaterialsPrepass::MeshletViewMaterialsPrepass()
  let deferred = MeshletViewMaterialsDeferredGBufferPrepass::MeshletViewMaterialsDeferredGBufferPrepass()
  let view_key = MeshletViewMaterialPipelineKey::new(
    normal_prepass=false,
    motion_vector_prepass=false,
    deferred_prepass=true,
  )
  prepare_material_meshlet_meshes_prepass_with_inputs(
    prepass,
    deferred,
    [
      MeshletPreparedMaterialInput::new(10, 100).with_opaque_render_method(
        @material.OpaqueRendererMethod::Deferred,
      ),
      MeshletPreparedMaterialInput::new(11, 101).with_opaque_render_method(
        @material.OpaqueRendererMethod::Forward,
      ),
    ],
    view_key~,
    deferred_enabled=true,
  )
  inspect(prepass.len(), content="0")
  inspect(deferred.len(), content="1")
}

///|
test "pbr meshlet: prepass preserves bevy working view key carry after deferred material" {
  let prepass = MeshletViewMaterialsPrepass::MeshletViewMaterialsPrepass()
  let deferred = MeshletViewMaterialsDeferredGBufferPrepass::MeshletViewMaterialsDeferredGBufferPrepass()
  let view_key = MeshletViewMaterialPipelineKey::new(
    normal_prepass=true,
    motion_vector_prepass=false,
    deferred_prepass=true,
  )
  prepare_material_meshlet_meshes_prepass_with_inputs(
    prepass,
    deferred,
    [
      MeshletPreparedMaterialInput::new(20, 200).with_opaque_render_method(
        @material.OpaqueRendererMethod::Deferred,
      ),
      MeshletPreparedMaterialInput::new(21, 201).with_opaque_render_method(
        @material.OpaqueRendererMethod::Forward,
      ),
    ],
    view_key~,
    deferred_enabled=true,
  )
  inspect(prepass.len(), content="0")
  inspect(deferred.len(), content="2")
  inspect(
    deferred.entries[1].descriptor.pass_variant
    is MeshletMaterialPassVariant::DeferredGBufferPrepass,
    content="true",
  )
}

///|
test "pbr meshlet: main opaque pass deduplicates material ids" {
  let main_opaque = MeshletViewMaterialsMainOpaquePass::MeshletViewMaterialsMainOpaquePass()
  prepare_material_meshlet_meshes_main_opaque_pass_with_inputs(main_opaque, [
    MeshletPreparedMaterialInput::new(10, 100),
    MeshletPreparedMaterialInput::new(10, 101),
    MeshletPreparedMaterialInput::new(11, 102),
  ])
  inspect(main_opaque.len(), content="2")
}

///|
test "pbr meshlet: prepass deduplicates material ids per pass" {
  let prepass = MeshletViewMaterialsPrepass::MeshletViewMaterialsPrepass()
  let deferred = MeshletViewMaterialsDeferredGBufferPrepass::MeshletViewMaterialsDeferredGBufferPrepass()
  let view_key = MeshletViewMaterialPipelineKey::new(
    normal_prepass=true,
    motion_vector_prepass=false,
    deferred_prepass=true,
  )
  prepare_material_meshlet_meshes_prepass_with_inputs(
    prepass,
    deferred,
    [
      MeshletPreparedMaterialInput::new(1, 100).with_opaque_render_method(
        @material.OpaqueRendererMethod::Forward,
      ),
      MeshletPreparedMaterialInput::new(1, 101).with_opaque_render_method(
        @material.OpaqueRendererMethod::Forward,
      ),
      MeshletPreparedMaterialInput::new(2, 200).with_opaque_render_method(
        @material.OpaqueRendererMethod::Deferred,
      ),
      MeshletPreparedMaterialInput::new(2, 201).with_opaque_render_method(
        @material.OpaqueRendererMethod::Deferred,
      ),
    ],
    view_key~,
    deferred_enabled=true,
  )
  inspect(prepass.len(), content="1")
  inspect(deferred.len(), content="1")
}

///|
test "pbr meshlet: prepass pipeline key ignores depth-prepass bit" {
  let prepass_a = MeshletViewMaterialsPrepass::MeshletViewMaterialsPrepass()
  let deferred_a = MeshletViewMaterialsDeferredGBufferPrepass::MeshletViewMaterialsDeferredGBufferPrepass()
  let prepass_b = MeshletViewMaterialsPrepass::MeshletViewMaterialsPrepass()
  let deferred_b = MeshletViewMaterialsDeferredGBufferPrepass::MeshletViewMaterialsDeferredGBufferPrepass()
  let inputs = [
    MeshletPreparedMaterialInput::new(1, 100).with_opaque_render_method(
      @material.OpaqueRendererMethod::Forward,
    ),
  ]
  prepare_material_meshlet_meshes_prepass_with_inputs(
    prepass_a,
    deferred_a,
    inputs,
    view_key=MeshletViewMaterialPipelineKey::new(
      normal_prepass=true,
      depth_prepass=false,
      motion_vector_prepass=false,
      deferred_prepass=false,
    ),
    deferred_enabled=false,
  )
  prepare_material_meshlet_meshes_prepass_with_inputs(
    prepass_b,
    deferred_b,
    inputs,
    view_key=MeshletViewMaterialPipelineKey::new(
      normal_prepass=true,
      depth_prepass=true,
      motion_vector_prepass=false,
      deferred_prepass=false,
    ),
    deferred_enabled=false,
  )
  inspect(prepass_a.len(), content="1")
  inspect(prepass_b.len(), content="1")
  let pipeline_a = prepass_a.entries[0].material_pipeline_id
  let pipeline_b = prepass_b.entries[0].material_pipeline_id
  inspect(pipeline_a == pipeline_b, content="true")
}

///|
test "pbr meshlet: prepass pipeline key ignores main-pass-only view dimensions" {
  let prepass_a = MeshletViewMaterialsPrepass::MeshletViewMaterialsPrepass()
  let deferred_a = MeshletViewMaterialsDeferredGBufferPrepass::MeshletViewMaterialsDeferredGBufferPrepass()
  let prepass_b = MeshletViewMaterialsPrepass::MeshletViewMaterialsPrepass()
  let deferred_b = MeshletViewMaterialsDeferredGBufferPrepass::MeshletViewMaterialsDeferredGBufferPrepass()
  let inputs = [
    MeshletPreparedMaterialInput::new(1, 100).with_opaque_render_method(
      @material.OpaqueRendererMethod::Forward,
    ),
  ]
  prepare_material_meshlet_meshes_prepass_with_inputs(
    prepass_a,
    deferred_a,
    inputs,
    view_key=MeshletViewMaterialPipelineKey::new(
      hdr=true,
      normal_prepass=true,
      motion_vector_prepass=false,
      deferred_prepass=false,
      temporal_jitter=true,
      projection_type=3,
      shadow_filter_method=2,
      tonemap_in_shader=true,
      tonemapping_mode=6,
      deband_dither=true,
      environment_map=true,
      irradiance_volume=true,
      ssao=true,
      distance_fog=true,
    ),
    deferred_enabled=false,
  )
  prepare_material_meshlet_meshes_prepass_with_inputs(
    prepass_b,
    deferred_b,
    inputs,
    view_key=MeshletViewMaterialPipelineKey::new(
      hdr=true,
      normal_prepass=true,
      motion_vector_prepass=false,
      deferred_prepass=false,
      temporal_jitter=false,
      projection_type=0,
      shadow_filter_method=0,
      tonemap_in_shader=false,
      tonemapping_mode=0,
      deband_dither=false,
      environment_map=false,
      irradiance_volume=false,
      ssao=false,
      distance_fog=false,
    ),
    deferred_enabled=false,
  )
  inspect(prepass_a.len(), content="1")
  inspect(prepass_b.len(), content="1")
  inspect(
    prepass_a.entries[0].material_pipeline_id ==
    prepass_b.entries[0].material_pipeline_id,
    content="true",
  )
}

///|
test "pbr meshlet: main opaque pipeline key includes bevy view dimensions" {
  let main_opaque_a = MeshletViewMaterialsMainOpaquePass::MeshletViewMaterialsMainOpaquePass()
  let main_opaque_b = MeshletViewMaterialsMainOpaquePass::MeshletViewMaterialsMainOpaquePass()
  let inputs = [MeshletPreparedMaterialInput::new(1, 100)]
  prepare_material_meshlet_meshes_main_opaque_pass_with_inputs(
    main_opaque_a,
    inputs,
    view_key=MeshletViewMaterialPipelineKey::new(
      hdr=false,
      temporal_jitter=true,
      projection_type=1,
      shadow_filter_method=1,
      tonemap_in_shader=true,
      tonemapping_mode=6,
      deband_dither=true,
      environment_map=true,
      irradiance_volume=true,
      ssao=true,
      distance_fog=true,
    ),
  )
  prepare_material_meshlet_meshes_main_opaque_pass_with_inputs(
    main_opaque_b,
    inputs,
    view_key=MeshletViewMaterialPipelineKey::new(
      hdr=false,
      temporal_jitter=false,
      projection_type=2,
      shadow_filter_method=2,
      tonemap_in_shader=true,
      tonemapping_mode=3,
      deband_dither=false,
      environment_map=false,
      irradiance_volume=false,
      ssao=false,
      distance_fog=false,
    ),
  )
  inspect(main_opaque_a.len(), content="1")
  inspect(main_opaque_b.len(), content="1")
  inspect(
    main_opaque_a.entries[0].material_pipeline_id !=
    main_opaque_b.entries[0].material_pipeline_id,
    content="true",
  )
}

///|
test "pbr meshlet: main opaque descriptor mirrors bevy material pass layout" {
  let main_opaque = MeshletViewMaterialsMainOpaquePass::MeshletViewMaterialsMainOpaquePass()
  let view_key = MeshletViewMaterialPipelineKey::new(hdr=true)
  prepare_material_meshlet_meshes_main_opaque_pass_with_inputs(
    main_opaque,
    [
      MeshletPreparedMaterialInput::new(5, 50)
      .with_material_layout_id(77)
      .with_material_shader_def_count(3)
      .with_meshlet_fragment_shader_override(),
    ],
    view_key~,
  )
  let descriptor = main_opaque.entries[0].descriptor
  inspect(
    descriptor.pass_variant is MeshletMaterialPassVariant::MainOpaque,
    content="true",
  )
  inspect(descriptor.view_key.equal(view_key), content="true")
  inspect(
    descriptor.view_layout_kind is MeshletMaterialViewLayoutKind::MeshView,
    content="true",
  )
  let fake_layout = descriptor.fake_vertex_buffer_layout
  let attribute_ids = fake_layout.attribute_ids()
  let vertex_layout = fake_layout.layout()
  inspect(attribute_ids.length(), content="4")
  debug_inspect(
    [
      attribute_ids[0].value(),
      attribute_ids[1].value(),
      attribute_ids[2].value(),
      attribute_ids[3].value(),
    ],
    content="[0, 1, 2, 4]",
  )
  inspect(vertex_layout.array_stride, content="48")
  inspect(
    vertex_layout.step_mode is @mesh.MeshVertexStepMode::Vertex,
    content="true",
  )
  inspect(vertex_layout.attributes.length(), content="4")
  inspect(vertex_layout.attributes[0].offset, content="0")
  inspect(vertex_layout.attributes[0].shader_location, content="0")
  inspect(
    vertex_layout.attributes[0].format is @mesh.MeshVertexFormat::Float32x3,
    content="true",
  )
  inspect(vertex_layout.attributes[1].offset, content="12")
  inspect(vertex_layout.attributes[1].shader_location, content="1")
  inspect(
    vertex_layout.attributes[1].format is @mesh.MeshVertexFormat::Float32x3,
    content="true",
  )
  inspect(vertex_layout.attributes[2].offset, content="24")
  inspect(vertex_layout.attributes[2].shader_location, content="2")
  inspect(
    vertex_layout.attributes[2].format is @mesh.MeshVertexFormat::Float32x2,
    content="true",
  )
  inspect(vertex_layout.attributes[3].offset, content="32")
  inspect(vertex_layout.attributes[3].shader_location, content="3")
  inspect(
    vertex_layout.attributes[3].format is @mesh.MeshVertexFormat::Float32x4,
    content="true",
  )
  inspect(descriptor.layout_count, content="4")
  inspect(descriptor.uses_binding_array_layout, content="true")
  inspect(descriptor.uses_empty_bind_group_layout, content="false")
  inspect(descriptor.uses_material_shade_layout, content="true")
  inspect(descriptor.material_layout_id, content="77")
  inspect(
    descriptor.fragment_shader_kind
    is MeshletMaterialFragmentShaderKind::MeshletFragmentOverride,
    content="true",
  )
  inspect(descriptor.shader_def_meshlet_material_pass, content="true")
  inspect(descriptor.shader_def_count, content="4")
  inspect(descriptor.uses_material_fragment_entry_point, content="true")
  inspect(descriptor.depth_format_depth16_unorm, content="true")
  inspect(descriptor.depth_write_enabled, content="false")
  inspect(descriptor.depth_compare_equal, content="true")
  inspect(descriptor.zero_initialize_workgroup_memory, content="false")
}

///|
test "pbr meshlet: view material key carries bevy target format bits" {
  let main_opaque = MeshletViewMaterialsMainOpaquePass::MeshletViewMaterialsMainOpaquePass()
  let view_key = MeshletViewMaterialPipelineKey::new(
    target_format_raw=@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
  )
  prepare_material_meshlet_meshes_main_opaque_pass_with_inputs(
    main_opaque,
    [MeshletPreparedMaterialInput::new(17, 170)],
    view_key~,
  )
  let descriptor = main_opaque.entries[0].descriptor
  debug_inspect(descriptor.view_key.equal(view_key), content="true")
  debug_inspect(
    view_key.equal(
      MeshletViewMaterialPipelineKey::new(
        target_format_raw=@wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB,
      ),
    ),
    content="false",
  )
}

///|
test "pbr meshlet: prepass descriptor switches view layout and entry point for overrides" {
  let prepass = MeshletViewMaterialsPrepass::MeshletViewMaterialsPrepass()
  let deferred = MeshletViewMaterialsDeferredGBufferPrepass::MeshletViewMaterialsDeferredGBufferPrepass()
  let view_key = MeshletViewMaterialPipelineKey::new(
    normal_prepass=true,
    motion_vector_prepass=true,
  )
  prepare_material_meshlet_meshes_prepass_with_inputs(
    prepass,
    deferred,
    [
      MeshletPreparedMaterialInput::new(9, 90)
      .with_material_layout_id(91)
      .with_meshlet_prepass_fragment_shader_override(),
    ],
    view_key~,
    deferred_enabled=false,
  )
  let descriptor = prepass.entries[0].descriptor
  inspect(
    descriptor.pass_variant is MeshletMaterialPassVariant::Prepass,
    content="true",
  )
  inspect(
    descriptor.view_layout_kind
    is MeshletMaterialViewLayoutKind::PrepassMotionVectors,
    content="true",
  )
  inspect(descriptor.uses_binding_array_layout, content="false")
  inspect(descriptor.uses_empty_bind_group_layout, content="true")
  inspect(
    descriptor.fragment_shader_kind
    is MeshletMaterialFragmentShaderKind::MeshletPrepassFragmentOverride,
    content="true",
  )
  inspect(descriptor.uses_material_fragment_entry_point, content="false")
}

///|
test "pbr meshlet: prepare skips materials without bevy required binding state" {
  let main_opaque = MeshletViewMaterialsMainOpaquePass::MeshletViewMaterialsMainOpaquePass()
  prepare_material_meshlet_meshes_main_opaque_pass_with_inputs(main_opaque, [
    MeshletPreparedMaterialInput::new(1, 10).without_material_layout(),
    MeshletPreparedMaterialInput::new(2, 20).without_material_bind_group_allocator(),
    MeshletPreparedMaterialInput::new(3, 30).without_material_bind_group(),
    MeshletPreparedMaterialInput::new(4, 40),
  ])
  inspect(main_opaque.len(), content="1")
  inspect(main_opaque.entries[0].material_id, content="4")
}
