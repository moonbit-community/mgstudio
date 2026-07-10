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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/core_3d/mod.rs`,
// `extract_camera_prepass_phase`.

///|
priv struct Render3dRetainedMeshPhaseView {
  mut items : Array[MeshPhaseItem3d]
  gpu_preprocessing_mode : @render_batching.GpuPreprocessingMode
  phase_types : Map[UInt64, Render3dPrepassBinnedRenderPhaseType]
}

///|
priv enum Render3dPrepassBinnedRenderPhaseType {
  MultidrawableMesh
  BatchableMesh
  UnbatchableMesh
}

///|
fn Render3dPrepassBinnedRenderPhaseType::mesh(
  batchable : Bool,
  gpu_preprocessing_support : @render_batching.GpuPreprocessingSupport,
) -> Render3dPrepassBinnedRenderPhaseType {
  match (batchable, gpu_preprocessing_support.is_culling_supported()) {
    (true, true) => MultidrawableMesh
    (true, false) => BatchableMesh
    (false, _) => UnbatchableMesh
  }
}

///|
fn render3d_prepass_effective_phase_type(
  gpu_preprocessing_mode : @render_batching.GpuPreprocessingMode,
  phase_type : Render3dPrepassBinnedRenderPhaseType,
) -> Render3dPrepassBinnedRenderPhaseType {
  match (gpu_preprocessing_mode, phase_type) {
    (@render_batching.GpuPreprocessingMode::PreprocessingOnly, MultidrawableMesh
    ) => BatchableMesh
    (_, MultidrawableMesh) => MultidrawableMesh
    (_, BatchableMesh) => BatchableMesh
    (_, UnbatchableMesh) => UnbatchableMesh
  }
}

///|
priv struct Render3dRetainedMeshPhaseViews {
  views : @hashmap.HashMap[
    @render_view.RetainedViewEntity,
    Render3dRetainedMeshPhaseView,
  ]
}

///|
fn Render3dRetainedMeshPhaseViews::Render3dRetainedMeshPhaseViews() -> Render3dRetainedMeshPhaseViews {
  Render3dRetainedMeshPhaseViews::{ views: @hashmap.HashMap([]) }
}

///|
fn Render3dRetainedMeshPhaseViews::prepare_for_new_frame(
  self : Render3dRetainedMeshPhaseViews,
  retained_view_entity : @render_view.RetainedViewEntity,
  gpu_preprocessing_mode : @render_batching.GpuPreprocessingMode,
) -> Unit {
  if !self.views.contains(retained_view_entity) {
    self.views.set(retained_view_entity, Render3dRetainedMeshPhaseView::{
      items: [],
      gpu_preprocessing_mode,
      phase_types: Map([]),
    })
  }
}

///|
fn Render3dRetainedMeshPhaseViews::remove(
  self : Render3dRetainedMeshPhaseViews,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> Unit {
  self.views.remove(retained_view_entity)
}

///|
fn Render3dRetainedMeshPhaseViews::retain_live_views(
  self : Render3dRetainedMeshPhaseViews,
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
fn Render3dRetainedMeshPhaseViews::contains(
  self : Render3dRetainedMeshPhaseViews,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> Bool {
  self.views.contains(retained_view_entity)
}

///|
fn Render3dRetainedMeshPhaseViews::view(
  self : Render3dRetainedMeshPhaseViews,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> Render3dRetainedMeshPhaseView? {
  self.views.get(retained_view_entity)
}

///|
fn Render3dRetainedMeshPhaseView::remove(
  self : Render3dRetainedMeshPhaseView,
  main_entity : @core.Entity,
) -> Unit {
  self.items = self.items.filter(fn(item) {
    item.entity.main_entity != main_entity
  })
  self.phase_types.remove(main_entity.to_bits())
}

///|
fn Render3dRetainedMeshPhaseView::add(
  self : Render3dRetainedMeshPhaseView,
  item : MeshPhaseItem3d,
  phase_type : Render3dPrepassBinnedRenderPhaseType,
) -> Unit {
  let effective_phase_type = render3d_prepass_effective_phase_type(
    self.gpu_preprocessing_mode,
    phase_type,
  )
  self.remove(item.entity.main_entity)
  self.items.push(item)
  self.phase_types.set(item.entity.main_entity.to_bits(), effective_phase_type)
}

///|
fn Render3dRetainedMeshPhaseView::refresh_extracted_indices(
  self : Render3dRetainedMeshPhaseView,
  extracted_indices : Map[UInt64, Int],
) -> Unit {
  for index in 0..<self.items.length() {
    let item = self.items[index]
    guard extracted_indices.get(item.entity.main_entity.to_bits())
      is Some(extracted_index) else {
      abort(
        "Retained prepass phase entity is missing its current extracted mesh payload",
      )
    }
    self.items[index] = MeshPhaseItem3d::{ ..item, extracted_index, }
  }
}

///|
priv struct Render3dOpaquePrepassPhases {
  phases : Render3dRetainedMeshPhaseViews
}

///|
fn Render3dOpaquePrepassPhases::Render3dOpaquePrepassPhases() -> Render3dOpaquePrepassPhases {
  Render3dOpaquePrepassPhases::{
    phases: Render3dRetainedMeshPhaseViews::Render3dRetainedMeshPhaseViews(),
  }
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
  phases : Render3dRetainedMeshPhaseViews
}

///|
fn Render3dAlphaMaskPrepassPhases::Render3dAlphaMaskPrepassPhases() -> Render3dAlphaMaskPrepassPhases {
  Render3dAlphaMaskPrepassPhases::{
    phases: Render3dRetainedMeshPhaseViews::Render3dRetainedMeshPhaseViews(),
  }
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
  phases : Render3dRetainedMeshPhaseViews
}

///|
fn Render3dOpaqueDeferredPhases::Render3dOpaqueDeferredPhases() -> Render3dOpaqueDeferredPhases {
  Render3dOpaqueDeferredPhases::{
    phases: Render3dRetainedMeshPhaseViews::Render3dRetainedMeshPhaseViews(),
  }
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
  phases : Render3dRetainedMeshPhaseViews
}

///|
fn Render3dAlphaMaskDeferredPhases::Render3dAlphaMaskDeferredPhases() -> Render3dAlphaMaskDeferredPhases {
  Render3dAlphaMaskDeferredPhases::{
    phases: Render3dRetainedMeshPhaseViews::Render3dRetainedMeshPhaseViews(),
  }
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
fn ensure_render3d_prepass_phase_resources(world : @ecs.World) -> Unit {
  if world.get_resource(Render3dOpaquePrepassPhases::resource()) is None {
    world.insert_resource(
      Render3dOpaquePrepassPhases::resource(),
      Render3dOpaquePrepassPhases::Render3dOpaquePrepassPhases(),
    )
  }
  if world.get_resource(Render3dAlphaMaskPrepassPhases::resource()) is None {
    world.insert_resource(
      Render3dAlphaMaskPrepassPhases::resource(),
      Render3dAlphaMaskPrepassPhases::Render3dAlphaMaskPrepassPhases(),
    )
  }
  if world.get_resource(Render3dOpaqueDeferredPhases::resource()) is None {
    world.insert_resource(
      Render3dOpaqueDeferredPhases::resource(),
      Render3dOpaqueDeferredPhases::Render3dOpaqueDeferredPhases(),
    )
  }
  if world.get_resource(Render3dAlphaMaskDeferredPhases::resource()) is None {
    world.insert_resource(
      Render3dAlphaMaskDeferredPhases::resource(),
      Render3dAlphaMaskDeferredPhases::Render3dAlphaMaskDeferredPhases(),
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
  let live_views : @hashset.HashSet[@render_view.RetainedViewEntity] = @hashset.HashSet([],
  )
  for camera in cameras {
    if !camera.payload.camera.is_active {
      continue
    }
    let requested_gpu_preprocessing_mode = if camera.payload.no_indirect_drawing {
      @render_batching.GpuPreprocessingMode::PreprocessingOnly
    } else {
      @render_batching.GpuPreprocessingMode::Culling
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
      match world.get_resource(Render3dOpaquePrepassPhases::resource()) {
        Some(phases) =>
          phases.phases.prepare_for_new_frame(
            retained_view_entity, gpu_preprocessing_mode,
          )
        None => abort("Missing Opaque3dPrepass phases during extraction")
      }
      match world.get_resource(Render3dAlphaMaskPrepassPhases::resource()) {
        Some(phases) =>
          phases.phases.prepare_for_new_frame(
            retained_view_entity, gpu_preprocessing_mode,
          )
        None => abort("Missing AlphaMask3dPrepass phases during extraction")
      }
    } else {
      match world.get_resource(Render3dOpaquePrepassPhases::resource()) {
        Some(phases) => phases.phases.remove(retained_view_entity)
        None => abort("Missing Opaque3dPrepass phases during extraction")
      }
      match world.get_resource(Render3dAlphaMaskPrepassPhases::resource()) {
        Some(phases) => phases.phases.remove(retained_view_entity)
        None => abort("Missing AlphaMask3dPrepass phases during extraction")
      }
    }
    if camera.payload.deferred_prepass_enabled {
      match world.get_resource(Render3dOpaqueDeferredPhases::resource()) {
        Some(phases) =>
          phases.phases.prepare_for_new_frame(
            retained_view_entity, gpu_preprocessing_mode,
          )
        None => abort("Missing Opaque3dDeferred phases during extraction")
      }
      match world.get_resource(Render3dAlphaMaskDeferredPhases::resource()) {
        Some(phases) =>
          phases.phases.prepare_for_new_frame(
            retained_view_entity, gpu_preprocessing_mode,
          )
        None => abort("Missing AlphaMask3dDeferred phases during extraction")
      }
    } else {
      match world.get_resource(Render3dOpaqueDeferredPhases::resource()) {
        Some(phases) => phases.phases.remove(retained_view_entity)
        None => abort("Missing Opaque3dDeferred phases during extraction")
      }
      match world.get_resource(Render3dAlphaMaskDeferredPhases::resource()) {
        Some(phases) => phases.phases.remove(retained_view_entity)
        None => abort("Missing AlphaMask3dDeferred phases during extraction")
      }
    }
    live_views.add(retained_view_entity)
  }
  match world.get_resource(Render3dOpaquePrepassPhases::resource()) {
    Some(phases) => phases.phases.retain_live_views(live_views)
    None => abort("Missing Opaque3dPrepass phases during extraction")
  }
  match world.get_resource(Render3dAlphaMaskPrepassPhases::resource()) {
    Some(phases) => phases.phases.retain_live_views(live_views)
    None => abort("Missing AlphaMask3dPrepass phases during extraction")
  }
  match world.get_resource(Render3dOpaqueDeferredPhases::resource()) {
    Some(phases) => phases.phases.retain_live_views(live_views)
    None => abort("Missing Opaque3dDeferred phases during extraction")
  }
  match world.get_resource(Render3dAlphaMaskDeferredPhases::resource()) {
    Some(phases) => phases.phases.retain_live_views(live_views)
    None => abort("Missing AlphaMask3dDeferred phases during extraction")
  }
}
