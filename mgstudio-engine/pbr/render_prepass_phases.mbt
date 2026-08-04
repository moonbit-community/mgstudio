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
// Bevy sources:
// - `bevy/crates/bevy_core_pipeline/src/prepass/mod.rs` (`Opaque3dPrepass`,
//   `AlphaMask3dPrepass`, `OpaqueNoLightmap3dBatchSetKey`,
//   `OpaqueNoLightmap3dBinKey`)
// - `bevy/crates/bevy_core_pipeline/src/core_3d/mod.rs`
//   (`extract_camera_prepass_phase`, `Opaque3dDeferred`, `AlphaMask3dDeferred`)
// - `bevy/crates/bevy_render/src/render_phase/mod.rs` (`BinnedRenderPhase`,
//   `BinnedRenderPhasePlugin::build`)

///|
type Render3dPrepassBinnedRenderPhaseType = @render_phase.BinnedRenderPhaseType

///|
// Bevy source:
// `bevy/crates/bevy_core_pipeline/src/prepass/mod.rs::OpaqueNoLightmap3dBatchSetKey`.
priv struct Render3dPrepassBatchSetKey {
  pipeline : @material.CachedRenderPipelineId
  draw_function : @material.DrawFunctionId
  material_bind_group_index : Int?
  slabs : @render_mesh.MeshSlabs
}

///|
impl Eq for Render3dPrepassBatchSetKey with fn equal(self, other) {
  self.pipeline.id() == other.pipeline.id() &&
  self.draw_function == other.draw_function &&
  self.material_bind_group_index == other.material_bind_group_index &&
  self.slabs == other.slabs
}

///|
fn Render3dPrepassBatchSetKey::indexed(
  self : Render3dPrepassBatchSetKey,
) -> Bool {
  self.slabs.index_slab_id is Some(_)
}

///|
// Bevy source:
// `bevy/crates/bevy_core_pipeline/src/prepass/mod.rs::OpaqueNoLightmap3dBinKey`.
// The asset id is the mesh asset id, matching
// `bevy_pbr/src/prepass/mod.rs::queue_prepass_material_meshes`.
priv struct Render3dPrepassBinKey {
  asset_id : Int
} derive(Eq, Hash)

///|
// Bevy source: `bevy/crates/bevy_render/src/render_phase/mod.rs::BinnedRenderPhase`
// instantiated for the four prepass/deferred phase items. The Bevy phase item
// stores only keys, representative entity, batch range, and extra index; the
// per-entity draw payload in `queued_items` is the local bridge consumed by the
// current executor until it reads this phase's own prepared buffers.
priv struct Render3dPrepassViewPhase {
  phase : @render_phase.BinnedRenderPhase[
    Render3dPrepassBatchSetKey,
    Render3dPrepassBinKey,
  ]
  queued_items : Map[UInt64, MeshPhaseItem3d]
}

///|
fn Render3dPrepassViewPhase::new(
  gpu_preprocessing_mode : @render_batching.GpuPreprocessingMode,
) -> Render3dPrepassViewPhase {
  {
    phase: @render_phase.BinnedRenderPhase::new(gpu_preprocessing_mode),
    queued_items: Map([]),
  }
}

///|
fn Render3dPrepassViewPhase::gpu_preprocessing_mode(
  self : Render3dPrepassViewPhase,
) -> @render_batching.GpuPreprocessingMode {
  self.phase.gpu_preprocessing_mode()
}

///|
fn Render3dPrepassViewPhase::prepare_for_new_frame(
  self : Render3dPrepassViewPhase,
) -> Unit {
  self.phase.prepare_for_new_frame()
}

///|
fn Render3dPrepassViewPhase::add(
  self : Render3dPrepassViewPhase,
  item : MeshPhaseItem3d,
  phase_type : Render3dPrepassBinnedRenderPhaseType,
) -> Unit {
  let batch_set_key = Render3dPrepassBatchSetKey::{
    pipeline: item.pipeline_id,
    draw_function: item.draw_function,
    material_bind_group_index: if item.material_bind_group_index < 0 {
      None
    } else {
      Some(item.material_bind_group_index)
    },
    slabs: item.slabs,
  }
  let bin_key = Render3dPrepassBinKey::{ asset_id: item.mesh_asset_id }
  self.phase.add(
    batch_set_key,
    bin_key,
    (
      item.entity.render_entity,
      @render.MainEntity::new(item.entity.main_entity),
    ),
    item.current_uniform_index,
    phase_type,
  )
  self.queued_items.set(item.entity.main_entity.to_bits(), item)
}

///|
fn Render3dPrepassViewPhase::remove(
  self : Render3dPrepassViewPhase,
  main_entity : @core.Entity,
) -> Unit {
  self.phase.remove(@render.MainEntity::new(main_entity))
  self.queued_items.remove(main_entity.to_bits())
}

///|
fn Render3dPrepassViewPhase::refresh_extracted_indices(
  self : Render3dPrepassViewPhase,
  extracted_indices : Map[UInt64, Int],
) -> Unit {
  let refreshed : Array[(UInt64, MeshPhaseItem3d)] = []
  for entity_bits, item in self.queued_items {
    guard extracted_indices.get(entity_bits) is Some(extracted_index) else {
      abort(
        "Retained prepass phase entity is missing its current extracted mesh payload",
      )
    }
    refreshed.push((entity_bits, { ..item, extracted_index, }))
  }
  for entry in refreshed {
    self.queued_items.set(entry.0, entry.1)
  }
}

///|
fn Render3dPrepassViewPhase::queued_item(
  self : Render3dPrepassViewPhase,
  main_entity : @render.MainEntity,
) -> MeshPhaseItem3d {
  match self.queued_items.get(main_entity.id().to_bits()) {
    Some(item) => item
    None =>
      abort("Retained prepass phase entity is missing its queued draw payload")
  }
}

///|
// Materializes the retained bins into executable draw items in Bevy's binned
// iteration order: multidrawable batch sets first, then batchable bins, then
// unbatchable entities. The queue only emits mesh phase types, so
// `non_mesh_items` is always empty for these phases. `output_index` is filled
// from the slots `prepare_gpu_buffers` recorded: batchable bins read their
// absolute instance range from the prepared batch sets, and direct-mode
// unbatchables read their per-entity buffer index. GPU-unpacked multidraw
// slots and indirect-mode unbatchable slots are not CPU-authored, so those
// items keep `-1` and draw through the per-draw payload slot path until
// Bevy's batch-set indirect consumption is ported.
fn Render3dPrepassViewPhase::draw_items(
  self : Render3dPrepassViewPhase,
  phase_id : String,
) -> Array[Render3dPrepassPhaseDrawItem3d] {
  let result : Array[Render3dPrepassPhaseDrawItem3d] = []
  for entry in self.phase.multidrawable_meshes() {
    let batch_set = entry.batch_set()
    for index in 0..<batch_set.cpu_instance_count() {
      guard batch_set.cpu_instance_at(index) is Some(cpu_instance) else {
        continue
      }
      result.push({
        phase_item: self.queued_item(cpu_instance.main_entity()),
        phase_id,
        output_index: -1,
      })
    }
  }
  let batchable_entries = self.phase.batchable_meshes()
  for index in 0..<batchable_entries.length() {
    let entry = batchable_entries[index]
    let range_start = match self.phase.batch_sets() {
      Direct(batches) =>
        if index < batches.length() {
          batches[index].instance_range().start()
        } else {
          -1
        }
      MultidrawIndirect(batch_sets) =>
        if index < batch_sets.length() {
          batch_sets[index].first_batch().instance_range().start()
        } else {
          -1
        }
      DynamicUniforms(_) => -1
    }
    let entities = entry.bin().entities()
    for entity_index in 0..<entities.length() {
      result.push({
        phase_item: self.queued_item(entities[entity_index].0),
        phase_id,
        output_index: if range_start < 0 {
          -1
        } else {
          range_start + entity_index
        },
      })
    }
  }
  for entry in self.phase.unbatchable_meshes() {
    let entities = entry.entities()
    let retained_entities = entities.entities()
    for entity_index in 0..<retained_entities.length() {
      let output_index = match
        entities.buffer_indices().indices_for_entity_index(entity_index) {
        Some(indices) =>
          match indices.extra_index() {
            None => indices.instance_index()
            _ => -1
          }
        None => -1
      }
      result.push({
        phase_item: self.queued_item(retained_entities[entity_index].0),
        phase_id,
        output_index,
      })
    }
  }
  result
}

///|
priv struct Render3dPrepassPhases {
  views : @hashmap.HashMap[
    @render_view.RetainedViewEntity,
    Render3dPrepassViewPhase,
  ]
}

///|
fn Render3dPrepassPhases::Render3dPrepassPhases() -> Render3dPrepassPhases {
  { views: HashMap([]) }
}

///|
fn Render3dPrepassPhases::prepare_for_new_frame(
  self : Render3dPrepassPhases,
  retained_view_entity : @render_view.RetainedViewEntity,
  gpu_preprocessing_mode : @render_batching.GpuPreprocessingMode,
) -> Unit {
  match self.views.get(retained_view_entity) {
    Some(phase) => phase.prepare_for_new_frame()
    None =>
      self.views.set(
        retained_view_entity,
        Render3dPrepassViewPhase::new(gpu_preprocessing_mode),
      )
  }
}

///|
fn Render3dPrepassPhases::remove(
  self : Render3dPrepassPhases,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> Unit {
  self.views.remove(retained_view_entity)
}

///|
fn Render3dPrepassPhases::retain_live_views(
  self : Render3dPrepassPhases,
  live_views : @hashset.HashSet[@render_view.RetainedViewEntity],
) -> Unit {
  let stale_views : Array[@render_view.RetainedViewEntity] = []
  for retained_view_entity, _phase in self.views {
    if !live_views.contains(retained_view_entity) {
      stale_views.push(retained_view_entity)
    }
  }
  for retained_view_entity in stale_views {
    self.views.remove(retained_view_entity)
  }
}

///|
fn Render3dPrepassPhases::contains(
  self : Render3dPrepassPhases,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> Bool {
  self.views.contains(retained_view_entity)
}

///|
fn Render3dPrepassPhases::view(
  self : Render3dPrepassPhases,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> Render3dPrepassViewPhase? {
  self.views.get(retained_view_entity)
}

///|
fn render3d_prepass_retained_view_id(
  retained_view_entity : @render_view.RetainedViewEntity,
) -> String {
  let main_bits = retained_view_entity.main_entity().to_bits()
  let auxiliary_bits = retained_view_entity.auxiliary_entity().to_bits()
  let subview_index = retained_view_entity.subview_index()
  "\{main_bits}:\{auxiliary_bits}:\{subview_index}"
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/batching/gpu_preprocessing.rs::batch_and_prepare_binned_render_phase`.
fn Render3dPrepassPhases::prepare_phase_buffers_into(
  self : Render3dPrepassPhases,
  render_mesh_instances : RenderMeshInstances,
  occlusion_culling_views : @hashset.HashSet[@render_view.RetainedViewEntity],
  cpu_batched_instance_buffer : @render_batching.BatchedInstanceBuffer[Unit],
  phase_batched_instance_buffers : @render_batching.PhaseBatchedInstanceBuffers[
    Unit,
  ],
  phase_indirect_parameters_buffers : @render_batching.PhaseIndirectParametersBuffers,
) -> Unit {
  cpu_batched_instance_buffer.clear()
  let get_binned_index = fn(main_entity : @render.MainEntity) {
    render_mesh_instances
    .render_mesh_queue_data(main_entity)
    .map(fn(mesh_instance) { mesh_instance.current_uniform_index() })
  }
  for retained_view_entity, view_phase in self.views {
    match view_phase.gpu_preprocessing_mode() {
      None =>
        view_phase.phase.prepare_cpu_buffers(
          cpu_batched_instance_buffer, get_binned_index,
        )
      mode =>
        view_phase.phase.prepare_gpu_buffers(
          render3d_prepass_retained_view_id(retained_view_entity),
          mode == PreprocessingOnly,
          occlusion_culling_views.contains(retained_view_entity),
          phase_batched_instance_buffers,
          phase_indirect_parameters_buffers,
          get_binned_index,
          fn(batch_set_key) { batch_set_key.indexed() },
        )
    }
  }
}

///|
fn render3d_append_retained_prepass_phase_draw_items(
  output : Array[Render3dPrepassPhaseDrawItem3d],
  view : Render3dPrepassViewPhase?,
  phase_id : String,
) -> Unit {
  match view {
    Some(view) =>
      for item in view.draw_items(phase_id) {
        output.push(item)
      }
    None => ()
  }
}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/prepass/node.rs` reads the
// retained prepass/deferred phases per view at render time; this is the
// executor-side accessor for the same four retained phase resources.
fn render3d_retained_prepass_phase_draw_items(
  world : @ecs.World,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> (
  Array[Render3dPrepassPhaseDrawItem3d],
  Array[Render3dPrepassPhaseDrawItem3d],
) {
  let prepass_items : Array[Render3dPrepassPhaseDrawItem3d] = []
  let deferred_items : Array[Render3dPrepassPhaseDrawItem3d] = []
  let opaque_prepass = world
    .get_resource(
      (@app.Resource::resource() : @ecs.ResourceKey[Render3dOpaquePrepassPhases]),
    )
    .unwrap()
  let alpha_mask_prepass = world
    .get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dAlphaMaskPrepassPhases]),
    )
    .unwrap()
  let opaque_deferred = world
    .get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dOpaqueDeferredPhases]),
    )
    .unwrap()
  let alpha_mask_deferred = world
    .get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dAlphaMaskDeferredPhases]),
    )
    .unwrap()
  render3d_append_retained_prepass_phase_draw_items(
    prepass_items,
    opaque_prepass.phases.view(retained_view_entity),
    RENDER3D_OPAQUE_PREPASS_PHASE_ID,
  )
  render3d_append_retained_prepass_phase_draw_items(
    prepass_items,
    alpha_mask_prepass.phases.view(retained_view_entity),
    RENDER3D_ALPHA_MASK_PREPASS_PHASE_ID,
  )
  render3d_append_retained_prepass_phase_draw_items(
    deferred_items,
    opaque_deferred.phases.view(retained_view_entity),
    RENDER3D_OPAQUE_DEFERRED_PHASE_ID,
  )
  render3d_append_retained_prepass_phase_draw_items(
    deferred_items,
    alpha_mask_deferred.phases.view(retained_view_entity),
    RENDER3D_ALPHA_MASK_DEFERRED_PHASE_ID,
  )
  (prepass_items, deferred_items)
}

///|
priv struct Render3dOpaquePrepassPhases {
  phases : Render3dPrepassPhases
}

///|
fn Render3dOpaquePrepassPhases::Render3dOpaquePrepassPhases() -> Render3dOpaquePrepassPhases {
  { phases: Render3dPrepassPhases() }
}

///|
let render3d_opaque_prepass_phases_key : @ecs.ResourceKey[
  Render3dOpaquePrepassPhases,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::ViewBinnedRenderPhases<Opaque3dPrepass>",
)

///|
impl @app.Resource for Render3dOpaquePrepassPhases with fn resource() {
  render3d_opaque_prepass_phases_key
}

///|
priv struct Render3dAlphaMaskPrepassPhases {
  phases : Render3dPrepassPhases
}

///|
fn Render3dAlphaMaskPrepassPhases::Render3dAlphaMaskPrepassPhases() -> Render3dAlphaMaskPrepassPhases {
  { phases: Render3dPrepassPhases() }
}

///|
let render3d_alpha_mask_prepass_phases_key : @ecs.ResourceKey[
  Render3dAlphaMaskPrepassPhases,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::ViewBinnedRenderPhases<AlphaMask3dPrepass>",
)

///|
impl @app.Resource for Render3dAlphaMaskPrepassPhases with fn resource() {
  render3d_alpha_mask_prepass_phases_key
}

///|
priv struct Render3dOpaqueDeferredPhases {
  phases : Render3dPrepassPhases
}

///|
fn Render3dOpaqueDeferredPhases::Render3dOpaqueDeferredPhases() -> Render3dOpaqueDeferredPhases {
  { phases: Render3dPrepassPhases() }
}

///|
let render3d_opaque_deferred_phases_key : @ecs.ResourceKey[
  Render3dOpaqueDeferredPhases,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::ViewBinnedRenderPhases<Opaque3dDeferred>",
)

///|
impl @app.Resource for Render3dOpaqueDeferredPhases with fn resource() {
  render3d_opaque_deferred_phases_key
}

///|
priv struct Render3dAlphaMaskDeferredPhases {
  phases : Render3dPrepassPhases
}

///|
fn Render3dAlphaMaskDeferredPhases::Render3dAlphaMaskDeferredPhases() -> Render3dAlphaMaskDeferredPhases {
  { phases: Render3dPrepassPhases() }
}

///|
let render3d_alpha_mask_deferred_phases_key : @ecs.ResourceKey[
  Render3dAlphaMaskDeferredPhases,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::ViewBinnedRenderPhases<AlphaMask3dDeferred>",
)

///|
impl @app.Resource for Render3dAlphaMaskDeferredPhases with fn resource() {
  render3d_alpha_mask_deferred_phases_key
}

///|
// Bevy source: `bevy/crates/bevy_render/src/render_phase/mod.rs::BinnedRenderPhasePlugin::build`
// (`PhaseBatchedInstanceBuffers<BPI>`, `PhaseIndirectParametersBuffers<BPI>`,
// and the CPU-path `no_gpu_preprocessing::BatchedInstanceBuffer`).
priv struct Render3dPrepassPhaseBufferSet {
  cpu_instances : @render_batching.BatchedInstanceBuffer[Unit]
  phase_instances : @render_batching.PhaseBatchedInstanceBuffers[Unit]
  phase_indirect : @render_batching.PhaseIndirectParametersBuffers
}

///|
fn Render3dPrepassPhaseBufferSet::Render3dPrepassPhaseBufferSet() -> Render3dPrepassPhaseBufferSet {
  {
    cpu_instances: @render_batching.BatchedInstanceBuffer::new(),
    phase_instances: @render_batching.PhaseBatchedInstanceBuffers::new(),
    phase_indirect: @render_batching.PhaseIndirectParametersBuffers::new(false),
  }
}

///|
const RENDER3D_OPAQUE_PREPASS_PHASE_ID : String = "mgstudio_pbr::Opaque3dPrepass"

///|
const RENDER3D_ALPHA_MASK_PREPASS_PHASE_ID : String = "mgstudio_pbr::AlphaMask3dPrepass"

///|
const RENDER3D_OPAQUE_DEFERRED_PHASE_ID : String = "mgstudio_pbr::Opaque3dDeferred"

///|
const RENDER3D_ALPHA_MASK_DEFERRED_PHASE_ID : String = "mgstudio_pbr::AlphaMask3dDeferred"

///|
let render3d_opaque_prepass_phase_buffers_key : @ecs.ResourceKey[
  Render3dPrepassPhaseBufferSet,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::BinnedPhaseBuffers<Opaque3dPrepass>",
)

///|
let render3d_alpha_mask_prepass_phase_buffers_key : @ecs.ResourceKey[
  Render3dPrepassPhaseBufferSet,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::BinnedPhaseBuffers<AlphaMask3dPrepass>",
)

///|
let render3d_opaque_deferred_phase_buffers_key : @ecs.ResourceKey[
  Render3dPrepassPhaseBufferSet,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::BinnedPhaseBuffers<Opaque3dDeferred>",
)

///|
let render3d_alpha_mask_deferred_phase_buffers_key : @ecs.ResourceKey[
  Render3dPrepassPhaseBufferSet,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::BinnedPhaseBuffers<AlphaMask3dDeferred>",
)

///|
fn ensure_render3d_prepass_phase_resources(world : @ecs.World) -> Unit {
  if world.get_resource(
      (@app.Resource::resource() : @ecs.ResourceKey[Render3dOpaquePrepassPhases]),
    )
    is None {
    world.insert_resource(
      (@app.Resource::resource() : @ecs.ResourceKey[Render3dOpaquePrepassPhases]),
      Render3dOpaquePrepassPhases(),
    )
  }
  if world.get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dAlphaMaskPrepassPhases]),
    )
    is None {
    world.insert_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dAlphaMaskPrepassPhases]),
      Render3dAlphaMaskPrepassPhases(),
    )
  }
  if world.get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dOpaqueDeferredPhases]),
    )
    is None {
    world.insert_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dOpaqueDeferredPhases]),
      Render3dOpaqueDeferredPhases(),
    )
  }
  if world.get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dAlphaMaskDeferredPhases]),
    )
    is None {
    world.insert_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dAlphaMaskDeferredPhases]),
      Render3dAlphaMaskDeferredPhases(),
    )
  }
  if world.get_resource(render3d_opaque_prepass_phase_buffers_key) is None {
    world.insert_resource(
      render3d_opaque_prepass_phase_buffers_key,
      Render3dPrepassPhaseBufferSet(),
    )
  }
  if world.get_resource(render3d_alpha_mask_prepass_phase_buffers_key) is None {
    world.insert_resource(
      render3d_alpha_mask_prepass_phase_buffers_key,
      Render3dPrepassPhaseBufferSet(),
    )
  }
  if world.get_resource(render3d_opaque_deferred_phase_buffers_key) is None {
    world.insert_resource(
      render3d_opaque_deferred_phase_buffers_key,
      Render3dPrepassPhaseBufferSet(),
    )
  }
  if world.get_resource(render3d_alpha_mask_deferred_phase_buffers_key) is None {
    world.insert_resource(
      render3d_alpha_mask_deferred_phase_buffers_key,
      Render3dPrepassPhaseBufferSet(),
    )
  }
}

///|
fn render3d_extract_camera_prepass_phases(
  world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
) -> Unit {
  ensure_render3d_prepass_phase_resources(world)
  let gpu_preprocessing_support = match
    world.get_resource(@render_batching.GpuPreprocessingSupport::resource()) {
    Some(value) => value
    None =>
      abort(
        "Missing GpuPreprocessingSupport resource during camera prepass phase extraction",
      )
  }
  let live_views : @hashset.HashSet[@render_view.RetainedViewEntity] = HashSet([])
  for camera in cameras {
    if !camera.payload.camera.is_active {
      continue
    }
    let requested_gpu_preprocessing_mode = if camera.payload.no_indirect_drawing {
      @render_batching.GpuPreprocessingMode::PreprocessingOnly
    } else {
      Culling
    }
    let gpu_preprocessing_mode = gpu_preprocessing_support.min(
      requested_gpu_preprocessing_mode,
    )
    let retained_view_entity = @render_view.RetainedViewEntity::new(
      camera.entity.main_entity,
    )
    let has_prepass = camera.payload.depth_prepass_enabled ||
      camera.payload.normal_prepass_enabled ||
      camera.payload.motion_vector_prepass_enabled
    if has_prepass {
      match
        world.get_resource(
          (
            @app.Resource::resource() :
            @ecs.ResourceKey[Render3dOpaquePrepassPhases]),
        ) {
        Some(phases) =>
          phases.phases.prepare_for_new_frame(
            retained_view_entity, gpu_preprocessing_mode,
          )
        None => abort("Missing Opaque3dPrepass phases during extraction")
      }
      match
        world.get_resource(
          (
            @app.Resource::resource() :
            @ecs.ResourceKey[Render3dAlphaMaskPrepassPhases]),
        ) {
        Some(phases) =>
          phases.phases.prepare_for_new_frame(
            retained_view_entity, gpu_preprocessing_mode,
          )
        None => abort("Missing AlphaMask3dPrepass phases during extraction")
      }
    } else {
      match
        world.get_resource(
          (
            @app.Resource::resource() :
            @ecs.ResourceKey[Render3dOpaquePrepassPhases]),
        ) {
        Some(phases) => phases.phases.remove(retained_view_entity)
        None => abort("Missing Opaque3dPrepass phases during extraction")
      }
      match
        world.get_resource(
          (
            @app.Resource::resource() :
            @ecs.ResourceKey[Render3dAlphaMaskPrepassPhases]),
        ) {
        Some(phases) => phases.phases.remove(retained_view_entity)
        None => abort("Missing AlphaMask3dPrepass phases during extraction")
      }
    }
    if camera.payload.deferred_prepass_enabled {
      match
        world.get_resource(
          (
            @app.Resource::resource() :
            @ecs.ResourceKey[Render3dOpaqueDeferredPhases]),
        ) {
        Some(phases) =>
          phases.phases.prepare_for_new_frame(
            retained_view_entity, gpu_preprocessing_mode,
          )
        None => abort("Missing Opaque3dDeferred phases during extraction")
      }
      match
        world.get_resource(
          (
            @app.Resource::resource() :
            @ecs.ResourceKey[Render3dAlphaMaskDeferredPhases]),
        ) {
        Some(phases) =>
          phases.phases.prepare_for_new_frame(
            retained_view_entity, gpu_preprocessing_mode,
          )
        None => abort("Missing AlphaMask3dDeferred phases during extraction")
      }
    } else {
      match
        world.get_resource(
          (
            @app.Resource::resource() :
            @ecs.ResourceKey[Render3dOpaqueDeferredPhases]),
        ) {
        Some(phases) => phases.phases.remove(retained_view_entity)
        None => abort("Missing Opaque3dDeferred phases during extraction")
      }
      match
        world.get_resource(
          (
            @app.Resource::resource() :
            @ecs.ResourceKey[Render3dAlphaMaskDeferredPhases]),
        ) {
        Some(phases) => phases.phases.remove(retained_view_entity)
        None => abort("Missing AlphaMask3dDeferred phases during extraction")
      }
    }
    live_views.add(retained_view_entity)
  }
  match
    world.get_resource(
      (@app.Resource::resource() : @ecs.ResourceKey[Render3dOpaquePrepassPhases]),
    ) {
    Some(phases) => phases.phases.retain_live_views(live_views)
    None => abort("Missing Opaque3dPrepass phases during extraction")
  }
  match
    world.get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dAlphaMaskPrepassPhases]),
    ) {
    Some(phases) => phases.phases.retain_live_views(live_views)
    None => abort("Missing AlphaMask3dPrepass phases during extraction")
  }
  match
    world.get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dOpaqueDeferredPhases]),
    ) {
    Some(phases) => phases.phases.retain_live_views(live_views)
    None => abort("Missing Opaque3dDeferred phases during extraction")
  }
  match
    world.get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dAlphaMaskDeferredPhases]),
    ) {
    Some(phases) => phases.phases.retain_live_views(live_views)
    None => abort("Missing AlphaMask3dDeferred phases during extraction")
  }
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/batching/gpu_preprocessing.rs::batch_and_prepare_binned_render_phase`.
fn render3d_prepare_prepass_phase_buffer_set(
  world : @ecs.World,
  phases : Render3dPrepassPhases,
  buffers : Render3dPrepassPhaseBufferSet,
) -> Unit {
  guard world.get_resource(RenderMeshInstances::resource())
    is Some(render_mesh_instances) else {
    return
  }
  let source_world = @render.render_source_world(world)
  let occlusion_culling_views : @hashset.HashSet[
    @render_view.RetainedViewEntity,
  ] = HashSet([])
  for retained_view_entity, _view_phase in phases.views {
    if (try! source_world.get_by_key(
        retained_view_entity.main_entity(),
        ecs_key_occlusion_culling,
      ))
      is Some(_) {
      occlusion_culling_views.add(retained_view_entity)
    }
  }
  phases.prepare_phase_buffers_into(
    render_mesh_instances,
    occlusion_culling_views,
    buffers.cpu_instances,
    buffers.phase_instances,
    buffers.phase_indirect,
  )
}

///|
fn render3d_prepare_opaque_prepass_phase_buffers(world : @ecs.World) -> Unit {
  let phases_ref = match
    world.get_resource_mut(render3d_opaque_prepass_phases_key) {
    Some(value) => value
    None => return
  }
  let buffers_ref = match
    world.get_resource_mut(render3d_opaque_prepass_phase_buffers_key) {
    Some(value) => value
    None => return
  }
  phases_ref.modify(fn(phases) {
    buffers_ref.modify(fn(buffers) {
      render3d_prepare_prepass_phase_buffer_set(world, phases.phases, buffers)
    })
  })
}

///|
pub fn render3d_prepare_opaque_prepass_phase_buffers_system(
  world : @ecs.World,
) -> Unit {
  render3d_prepare_opaque_prepass_phase_buffers(world)
}

///|
fn render3d_prepare_alpha_mask_prepass_phase_buffers(
  world : @ecs.World,
) -> Unit {
  let phases_ref = match
    world.get_resource_mut(render3d_alpha_mask_prepass_phases_key) {
    Some(value) => value
    None => return
  }
  let buffers_ref = match
    world.get_resource_mut(render3d_alpha_mask_prepass_phase_buffers_key) {
    Some(value) => value
    None => return
  }
  phases_ref.modify(fn(phases) {
    buffers_ref.modify(fn(buffers) {
      render3d_prepare_prepass_phase_buffer_set(world, phases.phases, buffers)
    })
  })
}

///|
pub fn render3d_prepare_alpha_mask_prepass_phase_buffers_system(
  world : @ecs.World,
) -> Unit {
  render3d_prepare_alpha_mask_prepass_phase_buffers(world)
}

///|
fn render3d_prepare_opaque_deferred_phase_buffers(world : @ecs.World) -> Unit {
  let phases_ref = match
    world.get_resource_mut(render3d_opaque_deferred_phases_key) {
    Some(value) => value
    None => return
  }
  let buffers_ref = match
    world.get_resource_mut(render3d_opaque_deferred_phase_buffers_key) {
    Some(value) => value
    None => return
  }
  phases_ref.modify(fn(phases) {
    buffers_ref.modify(fn(buffers) {
      render3d_prepare_prepass_phase_buffer_set(world, phases.phases, buffers)
    })
  })
}

///|
pub fn render3d_prepare_opaque_deferred_phase_buffers_system(
  world : @ecs.World,
) -> Unit {
  render3d_prepare_opaque_deferred_phase_buffers(world)
}

///|
fn render3d_prepare_alpha_mask_deferred_phase_buffers(
  world : @ecs.World,
) -> Unit {
  let phases_ref = match
    world.get_resource_mut(render3d_alpha_mask_deferred_phases_key) {
    Some(value) => value
    None => return
  }
  let buffers_ref = match
    world.get_resource_mut(render3d_alpha_mask_deferred_phase_buffers_key) {
    Some(value) => value
    None => return
  }
  phases_ref.modify(fn(phases) {
    buffers_ref.modify(fn(buffers) {
      render3d_prepare_prepass_phase_buffer_set(world, phases.phases, buffers)
    })
  })
}

///|
pub fn render3d_prepare_alpha_mask_deferred_phase_buffers_system(
  world : @ecs.World,
) -> Unit {
  render3d_prepare_alpha_mask_deferred_phase_buffers(world)
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/batching/gpu_preprocessing.rs::collect_buffers_for_phase`.
fn render3d_collect_prepass_phase_buffer_set(
  world : @ecs.World,
  phase_id : String,
  buffers_key : @ecs.ResourceKey[Render3dPrepassPhaseBufferSet],
) -> Unit {
  let buffers_ref = match world.get_resource_mut(buffers_key) {
    Some(value) => value
    None => return
  }
  let batched_instances_ref = match
    world.get_resource_mut(
      RenderMeshInstanceGpuBatchedInstanceBuffers::resource(),
    ) {
    Some(value) => value
    None => return
  }
  let indirect_buffers_ref = match
    world.get_resource_mut(
      @render_batching.IndirectParametersBuffers::resource(),
    ) {
    Some(value) => value
    None => return
  }
  let settings = match
    world.get_resource(
      @render_batching.IndirectParametersBuffersSettings::resource(),
    ) {
    Some(value) => value
    None => IndirectParametersBuffersSettings()
  }
  buffers_ref.modify(fn(buffers) {
    batched_instances_ref.modify(fn(batched_instances) {
      indirect_buffers_ref.modify(fn(indirect_buffers) {
        @render_batching.collect_buffers_for_phase(
          phase_id,
          buffers.phase_instances,
          buffers.phase_indirect,
          batched_instances.buffers,
          indirect_buffers,
          settings,
        )
      })
    })
  })
}

///|
pub fn render3d_collect_opaque_prepass_phase_buffers_system(
  world : @ecs.World,
) -> Unit {
  render3d_collect_prepass_phase_buffer_set(
    world,
    RENDER3D_OPAQUE_PREPASS_PHASE_ID,
    render3d_opaque_prepass_phase_buffers_key,
  )
}

///|
pub fn render3d_collect_alpha_mask_prepass_phase_buffers_system(
  world : @ecs.World,
) -> Unit {
  render3d_collect_prepass_phase_buffer_set(
    world,
    RENDER3D_ALPHA_MASK_PREPASS_PHASE_ID,
    render3d_alpha_mask_prepass_phase_buffers_key,
  )
}

///|
pub fn render3d_collect_opaque_deferred_phase_buffers_system(
  world : @ecs.World,
) -> Unit {
  render3d_collect_prepass_phase_buffer_set(
    world,
    RENDER3D_OPAQUE_DEFERRED_PHASE_ID,
    render3d_opaque_deferred_phase_buffers_key,
  )
}

///|
pub fn render3d_collect_alpha_mask_deferred_phase_buffers_system(
  world : @ecs.World,
) -> Unit {
  render3d_collect_prepass_phase_buffer_set(
    world,
    RENDER3D_ALPHA_MASK_DEFERRED_PHASE_ID,
    render3d_alpha_mask_deferred_phase_buffers_key,
  )
}
