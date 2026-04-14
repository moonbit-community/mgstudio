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
test "pbr meshlet: material prepare entry count aggregates all passes" {
  let main_opaque = MeshletViewMaterialsMainOpaquePass::default()
  let prepass = MeshletViewMaterialsPrepass::default()
  let deferred = MeshletViewMaterialsDeferredGBufferPrepass::default()
  main_opaque.push((1, 2, 3))
  prepass.push((4, 5, 6))
  inspect(
    meshlet_material_prepare_entry_count(main_opaque, prepass, deferred),
    content="2",
  )
}

///|
test "pbr meshlet: prepare main opaque pass fills bins from material ids" {
  let main_opaque = MeshletViewMaterialsMainOpaquePass::default()
  prepare_material_meshlet_meshes_main_opaque_pass(main_opaque, [10, 20, 30])
  inspect(main_opaque.len(), content="3")
}

///|
test "pbr meshlet: prepare prepass respects deferred toggle" {
  let prepass = MeshletViewMaterialsPrepass::default()
  let deferred = MeshletViewMaterialsDeferredGBufferPrepass::default()
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
  let main_opaque = MeshletViewMaterialsMainOpaquePass::default()
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
    MeshletPreparedMaterialInput::new(4, 13).with_alpha_mode_opaque(false),
  ])
  inspect(main_opaque.len(), content="1")
}

///|
test "pbr meshlet: prepass routes deferred materials to deferred bins" {
  let prepass = MeshletViewMaterialsPrepass::default()
  let deferred = MeshletViewMaterialsDeferredGBufferPrepass::default()
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
test "pbr meshlet: main opaque pass deduplicates material ids" {
  let main_opaque = MeshletViewMaterialsMainOpaquePass::default()
  prepare_material_meshlet_meshes_main_opaque_pass_with_inputs(main_opaque, [
    MeshletPreparedMaterialInput::new(10, 100),
    MeshletPreparedMaterialInput::new(10, 101),
    MeshletPreparedMaterialInput::new(11, 102),
  ])
  inspect(main_opaque.len(), content="2")
}

///|
test "pbr meshlet: prepass deduplicates material ids per pass" {
  let prepass = MeshletViewMaterialsPrepass::default()
  let deferred = MeshletViewMaterialsDeferredGBufferPrepass::default()
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
