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
// Bevy source: `bevy/crates/bevy_pbr/src/prepass/mod.rs`,
// `queue_prepass_material_meshes`.

///|
fn render3d_remove_prepass_phase_entity(
  opaque_prepass : Render3dRetainedMeshPhaseView?,
  alpha_mask_prepass : Render3dRetainedMeshPhaseView?,
  opaque_deferred : Render3dRetainedMeshPhaseView?,
  alpha_mask_deferred : Render3dRetainedMeshPhaseView?,
  entity : @core.Entity,
) -> Unit {
  match opaque_prepass {
    Some(phase) => phase.remove(entity)
    None => ()
  }
  match alpha_mask_prepass {
    Some(phase) => phase.remove(entity)
    None => ()
  }
  match opaque_deferred {
    Some(phase) => phase.remove(entity)
    None => ()
  }
  match alpha_mask_deferred {
    Some(phase) => phase.remove(entity)
    None => ()
  }
}

///|
fn render3d_prepass_extracted_index_by_entity(
  meshes : Array[ExtractedMesh3d],
) -> Map[UInt64, Int] {
  let indices : Map[UInt64, Int] = Map([])
  for index in 0..<meshes.length() {
    indices.set(meshes[index].entity.main_entity.to_bits(), index)
  }
  indices
}

///|
fn render3d_queue_prepass_material_meshes(
  world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
  meshes : Array[ExtractedMesh3d],
) -> Unit {
  let render_mesh_instances = world
    .get_resource(RenderMeshInstances::resource())
    .unwrap()
  let render_material_instances = world
    .get_resource(ecs_key_render_material_instances)
    .unwrap()
  let render_material_bindings = world
    .get_resource(RenderMaterialBindings::resource())
    .unwrap()
  let material_slots = render_material3d_resolved_slots_or_empty(world)
  let mesh_allocator = world
    .get_resource(@render_mesh.MeshAllocator::resource())
    .unwrap()
  let gpu_preprocessing_support = world
    .get_resource(@render_batching.GpuPreprocessingSupport::resource())
    .unwrap()
  let specialized_cache = world
    .get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[SpecializedPrepassMaterialPipelineCache]),
    )
    .unwrap()
  let pending_queues = world
    .get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[PendingPrepassMeshMaterialQueues]),
    )
    .unwrap()
  let dirty_specializations = world
    .get_resource(@render_visibility.DirtySpecializations::resource())
    .unwrap()
  let opaque_prepass_phases = world
    .get_resource(
      (@app.Resource::resource() : @ecs.ResourceKey[Render3dOpaquePrepassPhases]),
    )
    .unwrap()
  let alpha_mask_prepass_phases = world
    .get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dAlphaMaskPrepassPhases]),
    )
    .unwrap()
  let opaque_deferred_phases = world
    .get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dOpaqueDeferredPhases]),
    )
    .unwrap()
  let alpha_mask_deferred_phases = world
    .get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dAlphaMaskDeferredPhases]),
    )
    .unwrap()
  let extracted_indices = render3d_prepass_extracted_index_by_entity(meshes)
  for camera in cameras {
    let retained_view_entity = @render_view.RetainedViewEntity::new(
      camera.entity.main_entity,
    )
    let opaque_prepass = opaque_prepass_phases.phases.view(retained_view_entity)
    let alpha_mask_prepass = alpha_mask_prepass_phases.phases.view(
      retained_view_entity,
    )
    let opaque_deferred = opaque_deferred_phases.phases.view(
      retained_view_entity,
    )
    let alpha_mask_deferred = alpha_mask_deferred_phases.phases.view(
      retained_view_entity,
    )
    guard specialized_cache.get(retained_view_entity) is Some(view_cache) else {
      continue
    }
    if opaque_prepass is None &&
      alpha_mask_prepass is None &&
      opaque_deferred is None &&
      alpha_mask_deferred is None {
      continue
    }
    guard (try! world.get_by_key(
        camera.entity.render_entity,
        @render_visibility.ecs_key_render_visible_entities,
      ))
      is Some(visible_entities) else {
      continue
    }
    guard visible_entities.get(render3d_mesh_visibility_class())
      is Some(render_visible_mesh_entities) else {
      continue
    }
    let view_pending_queues = match
      pending_queues.queues.get(retained_view_entity) {
      Some(value) => value
      None =>
        abort(
          "View pending prepass mesh material queues should have been created in specialize_prepass_material_meshes",
        )
    }
    for
      entity in dirty_specializations.iter_to_dequeue(
        retained_view_entity, render_visible_mesh_entities,
      ) {
      render3d_remove_prepass_phase_entity(
        opaque_prepass,
        alpha_mask_prepass,
        opaque_deferred,
        alpha_mask_deferred,
        entity.id(),
      )
    }
    match opaque_prepass {
      Some(phase) => phase.refresh_extracted_indices(extracted_indices)
      None => ()
    }
    match alpha_mask_prepass {
      Some(phase) => phase.refresh_extracted_indices(extracted_indices)
      None => ()
    }
    match opaque_deferred {
      Some(phase) => phase.refresh_extracted_indices(extracted_indices)
      None => ()
    }
    match alpha_mask_deferred {
      Some(phase) => phase.refresh_extracted_indices(extracted_indices)
      None => ()
    }
    let candidates = dirty_specializations.iter_to_queue(
      retained_view_entity,
      render_visible_mesh_entities,
      view_pending_queues.prev_frame(),
    )
    for candidate in candidates {
      let (render_entity, visible_entity) = candidate
      guard view_cache.get(visible_entity.id()) is Some(cache_entry) else {
        continue
      }
      guard render_material_instances.get(visible_entity.id())
        is Some(material_instance) else {
        render3d_enqueue_pending_prepass_material(
          view_pending_queues, render_entity, visible_entity,
        )
        continue
      }
      guard render_mesh_instances.render_mesh_queue_data(visible_entity)
        is Some(mesh_instance) else {
        render3d_enqueue_pending_prepass_material(
          view_pending_queues, render_entity, visible_entity,
        )
        continue
      }
      guard material_slots.get(visible_entity.id()) is Some(Resolved(material)) else {
        render3d_enqueue_pending_prepass_material(
          view_pending_queues, render_entity, visible_entity,
        )
        continue
      }
      let material_binding = if material_instance.asset_id() ==
        DUMMY_MESH_MATERIAL_ID {
        MaterialBindingId::MaterialBindingId()
      } else {
        match render_material_bindings.get(material_instance.asset_id()) {
          Some(binding) => binding
          None => {
            render3d_enqueue_pending_prepass_material(
              view_pending_queues, render_entity, visible_entity,
            )
            continue
          }
        }
      }
      guard mesh_allocator.mesh_slabs(mesh_instance.mesh_asset_id())
        is Some(mesh_slabs) else {
        continue
      }
      guard extracted_indices.get(visible_entity.id().to_bits())
        is Some(extracted_index) else {
        abort(
          "Queued prepass entity is missing its current extracted mesh payload",
        )
      }
      let properties = material.material_properties()
      ignore(cache_entry.tick)
      let deferred = properties.render_method is OpaqueRendererMethod::Deferred
      let depth_only_draw_function = properties.get_draw_function(
        PREPASS_OPAQUE_DEPTH_ONLY_DRAW_FUNCTION_LABEL,
      )
      let material_bind_group_required = Some(cache_entry.draw_function) !=
        depth_only_draw_function
      let phase_item = MeshPhaseItem3d::{
        entity: phase_entity_ref3d(visible_entity.id(), render_entity),
        extracted_index,
        current_uniform_index: mesh_instance.current_uniform_index(),
        phase: if properties.render_phase_type
          is @material.RenderPhaseType::Opaque {
          RENDER3D_PHASE_OPAQUE
        } else {
          RENDER3D_PHASE_ALPHA_MASK
        },
        draw_function: cache_entry.draw_function,
        pipeline_id: cache_entry.pipeline_id,
        distance: 0.0F,
        mesh_asset_id: mesh_instance.mesh_asset_id(),
        slabs: mesh_slabs,
        material_bind_group_index: if material_bind_group_required {
          material_binding.group().to_int()
        } else {
          -1
        },
        material_bind_group_slot: if material_bind_group_required {
          material_binding.slot().to_int()
        } else {
          -1
        },
      }
      let phase_type = Render3dPrepassBinnedRenderPhaseType::mesh(
        mesh_instance.should_batch(),
        gpu_preprocessing_support,
      )
      match properties.render_phase_type {
        @material.RenderPhaseType::Opaque =>
          if deferred {
            match opaque_deferred {
              Some(phase) => phase.add(phase_item, phase_type)
              None =>
                abort("Missing Opaque3dDeferred phase for deferred material")
            }
          } else {
            match opaque_prepass {
              Some(phase) => phase.add(phase_item, phase_type)
              None => ()
            }
          }
        @material.RenderPhaseType::AlphaMask =>
          if deferred {
            match alpha_mask_deferred {
              Some(phase) => phase.add(phase_item, phase_type)
              None =>
                abort("Missing AlphaMask3dDeferred phase for deferred material")
            }
          } else {
            match alpha_mask_prepass {
              Some(phase) => phase.add(phase_item, phase_type)
              None => ()
            }
          }
        @material.RenderPhaseType::Transmissive
        | @material.RenderPhaseType::Transparent => ()
      }
    }
  }
}
