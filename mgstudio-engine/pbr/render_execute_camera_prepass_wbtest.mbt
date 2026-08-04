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
extend Render3dAlphaMaskDeferredPhases with @app.Resource::{resource}

///|
extend Render3dOpaquePrepassPhases with @app.Resource::{resource}

///|
fn render3d_prepass_consumer_test_item(
  entity_id : Int,
  pipeline_id : UInt64,
  phase? : Int = RENDER3D_PHASE_OPAQUE,
) -> MeshPhaseItem3d {
  {
    entity: phase_entity_ref3d(
      @core.Entity::new(entity_id, 0),
      @core.Entity::new(entity_id + 100, 0),
    ),
    extracted_index: entity_id,
    current_uniform_index: entity_id.reinterpret_as_uint(),
    phase,
    draw_function: @material.DrawFunctionId::new(
      entity_id.reinterpret_as_uint(),
    ),
    pipeline_id: @material.CachedRenderPipelineId::new(pipeline_id),
    distance: 0.0F,
    mesh_asset_id: entity_id + 200,
    slabs: @render_mesh.MeshSlabs::new(entity_id + 300),
    material_bind_group_index: entity_id + 400,
    material_bind_group_slot: entity_id + 500,
  }
}

///|
test "pbr prepass: consumer reads retained prepass and deferred phase items" {
  let world = @ecs.World::new()
  defer world.close()
  ensure_render3d_prepass_phase_resources(world)
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(40, 0),
  )
  let mode = @render_batching.GpuPreprocessingMode::Culling
  let opaque_prepass_phases = world
    .get_resource(Render3dOpaquePrepassPhases::resource())
    .unwrap()
  opaque_prepass_phases.phases.prepare_for_new_frame(retained_view, mode)
  let opaque_prepass = opaque_prepass_phases.phases.view(retained_view).unwrap()
  let alpha_mask_deferred_phases = world
    .get_resource(Render3dAlphaMaskDeferredPhases::resource())
    .unwrap()
  alpha_mask_deferred_phases.phases.prepare_for_new_frame(retained_view, mode)
  let alpha_mask_deferred = alpha_mask_deferred_phases.phases
    .view(retained_view)
    .unwrap()
  opaque_prepass.add(
    render3d_prepass_consumer_test_item(1, 101UL),
    BatchableMesh,
  )
  alpha_mask_deferred.add(
    render3d_prepass_consumer_test_item(
      2,
      102UL,
      phase=RENDER3D_PHASE_ALPHA_MASK,
    ),
    UnbatchableMesh,
  )
  let (prepass_items, deferred_items) = render3d_retained_prepass_phase_draw_items(
    world, retained_view,
  )
  inspect(prepass_items.length(), content="1")
  inspect(prepass_items[0].phase_item.phase, content="0")
  inspect(prepass_items[0].phase_item.pipeline_id.id(), content="101")
  inspect(prepass_items[0].phase_item.draw_function.id(), content="1")
  inspect(prepass_items[0].phase_id, content="mgstudio_pbr::Opaque3dPrepass")
  inspect(deferred_items.length(), content="1")
  inspect(deferred_items[0].phase_item.phase, content="1")
  inspect(deferred_items[0].phase_item.pipeline_id.id(), content="102")
  inspect(deferred_items[0].phase_item.draw_function.id(), content="2")
  inspect(
    deferred_items[0].phase_id,
    content="mgstudio_pbr::AlphaMask3dDeferred",
  )
  // The phase buffers were not prepared in this world, so no slot in this
  // phase's instance buffer is CPU-authored yet and every item draws through
  // the per-draw payload slot path.
  inspect(prepass_items[0].output_index, content="-1")
  inspect(deferred_items[0].output_index, content="-1")
}

///|
test "pbr prepass: late node follows Bevy occlusion and indirect gates" {
  inspect(render3d_should_run_late_prepass(true, true, false), content="true")
  inspect(render3d_should_run_late_prepass(false, true, false), content="false")
  inspect(render3d_should_run_late_prepass(true, false, false), content="false")
  inspect(render3d_should_run_late_prepass(true, true, true), content="false")
}
