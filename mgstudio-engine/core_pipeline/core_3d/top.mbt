// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/core_3d/mod.rs`.
const CORE_3D_PLUGIN_NAME : String = "mgstudio.core_pipeline.core_3d.Core3dPlugin"

///|
pub const CORE_3D_DEPTH_FORMAT : String = "depth32float"

///|
pub const DEPTH_TEXTURE_SAMPLING_SUPPORTED : Bool = true

///|
pub let core_3d_set_prepass : @app.SystemSet = @app.system_set(
  "mgstudio.core_pipeline.core3d.prepass",
)

///|
pub let core_3d_set_main_pass : @app.SystemSet = @app.system_set(
  "mgstudio.core_pipeline.core3d.main_pass",
)

///|
pub let core_3d_set_early_post_process : @app.SystemSet = @app.system_set(
  "mgstudio.core_pipeline.core3d.early_post_process",
)

///|
pub let core_3d_set_post_process : @app.SystemSet = @app.system_set(
  "mgstudio.core_pipeline.core3d.post_process",
)

///|
let core_3d_set_extract : @app.SystemSet = @app.system_set(
  "mgstudio.core_pipeline.core3d.extract",
)

///|
pub struct Core3dPlugin {}

///|
pub fn Core3dPlugin::Core3dPlugin() -> Core3dPlugin {
  Core3dPlugin::{  }
}

///|
pub fn core_3d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  core_3d_plugin_with(app, Core3dPlugin::Core3dPlugin())
}

///|
fn core_3d_configure_render_sub_app(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  let world = sub_app.world()
  if world.get_resource(Opaque3dPhase::resource()) is None {
    world.insert_resource(
      Opaque3dPhase::resource(),
      Opaque3dPhase::Opaque3dPhase(),
    )
  }
  if world.get_resource(AlphaMask3dPhase::resource()) is None {
    world.insert_resource(
      AlphaMask3dPhase::resource(),
      AlphaMask3dPhase::AlphaMask3dPhase(),
    )
  }
  if world.get_resource(Transparent3dPhase::resource()) is None {
    world.insert_resource(
      Transparent3dPhase::resource(),
      Transparent3dPhase::Transparent3dPhase(),
    )
  }
  if world.get_resource(Transparent3dDrawFunctions::resource()) is None {
    world.insert_resource(
      Transparent3dDrawFunctions::resource(),
      Transparent3dDrawFunctions::Transparent3dDrawFunctions(),
    )
  }
  let stage = @render.render_schedule_stage()
  let graph_stage = @render.RenderGraph::schedule()
  let core_3d_stage = @app.schedule_label("mgstudio.core_pipeline.core_3d")
  let sub_app = @render.configure_base_render_sets(sub_app).add_schedule(
    @app.Schedule::new(core_3d_stage),
  )
  sub_app
  .configure_set(stage, @render.render_system_set_extract_commands, before=[
    core_3d_set_extract,
  ])
  .add_systems(
    stage,
    @app.system(extract_core_3d_camera_phases).in_set(core_3d_set_extract),
  )
  .configure_set(stage, core_3d_set_extract, before=[
    @render.render_system_set_queue_meshes,
  ])
  .configure_set(core_3d_stage, core_3d_set_prepass, before=[
    core_3d_set_main_pass,
  ])
  .configure_set(core_3d_stage, core_3d_set_main_pass, before=[
    core_3d_set_early_post_process,
  ])
  .configure_set(core_3d_stage, core_3d_set_early_post_process, before=[
    core_3d_set_post_process,
  ])
  .configure_set(graph_stage, @render.render_graph_system_set_render, before=[
    core_3d_set_prepass,
  ])
  .configure_set(graph_stage, core_3d_set_prepass, before=[
    core_3d_set_main_pass,
  ])
  .configure_set(graph_stage, core_3d_set_main_pass, before=[
    core_3d_set_early_post_process,
  ])
  .configure_set(graph_stage, core_3d_set_early_post_process, before=[
    core_3d_set_post_process,
  ])
  .configure_set(graph_stage, core_3d_set_post_process, before=[
    @render.render_graph_system_set_submit,
  ])
}

///|
pub impl @app.Plugin for Core3dPlugin with fn name(_self) {
  CORE_3D_PLUGIN_NAME
}

///|
pub impl @app.Plugin for Core3dPlugin with fn build(self, app) {
  core_3d_plugin_with(app, self)
}

///|
pub fn core_3d_plugin_with(
  app : @app.App[@ecs.World],
  plugin : Core3dPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  let next = app.add_plugins(@skybox.SkyboxPlugin::SkyboxPlugin())
  @render.with_render_app(next, core_3d_configure_render_sub_app)
}

///|
pub type Msaa = @render_view.Msaa

///|
pub type Hdr = @camera_hdr.Hdr

///|
pub let ecs_key_hdr : @ecs.ComponentKey[Hdr] = @camera_hdr.ecs_key_hdr

///|
pub let ecs_key_msaa : @ecs.ComponentKey[Msaa] = @render_view.ecs_key_msaa

///|
pub struct Opaque3dBatchSetKey {
  pipeline_id : Int
  draw_function_id : Int
  material_bind_group_index : Int?
  vertex_slab_id : Int
  index_slab_id : Int?
  lightmap_slab_id : Int?
} derive(Eq, Debug)

///|
pub fn Opaque3dBatchSetKey::new(
  pipeline_id~ : Int,
  draw_function_id~ : Int,
  material_bind_group_index? : Int? = None,
  vertex_slab_id? : Int = 0,
  index_slab_id? : Int? = None,
  lightmap_slab_id? : Int? = None,
) -> Opaque3dBatchSetKey {
  Opaque3dBatchSetKey::{
    pipeline_id,
    draw_function_id,
    material_bind_group_index,
    vertex_slab_id,
    index_slab_id,
    lightmap_slab_id,
  }
}

///|
pub fn Opaque3dBatchSetKey::indexed(self : Opaque3dBatchSetKey) -> Bool {
  self.index_slab_id is Some(_)
}

///|
pub struct Opaque3dBinKey {
  asset_id : Int
} derive(Eq, Debug)

///|
pub fn Opaque3dBinKey::new(asset_id~ : Int) -> Opaque3dBinKey {
  Opaque3dBinKey::{ asset_id, }
}

///|
pub struct OpaqueNoLightmap3dBatchSetKey {
  pipeline_id : Int
  draw_function_id : Int
  material_bind_group_index : Int?
  vertex_slab_id : Int
  index_slab_id : Int?
} derive(Eq, Debug)

///|
pub fn OpaqueNoLightmap3dBatchSetKey::new(
  pipeline_id~ : Int,
  draw_function_id~ : Int,
  material_bind_group_index? : Int? = None,
  vertex_slab_id? : Int = 0,
  index_slab_id? : Int? = None,
) -> OpaqueNoLightmap3dBatchSetKey {
  OpaqueNoLightmap3dBatchSetKey::{
    pipeline_id,
    draw_function_id,
    material_bind_group_index,
    vertex_slab_id,
    index_slab_id,
  }
}

///|
pub fn OpaqueNoLightmap3dBatchSetKey::indexed(
  self : OpaqueNoLightmap3dBatchSetKey,
) -> Bool {
  self.index_slab_id is Some(_)
}

///|
pub struct OpaqueNoLightmap3dBinKey {
  asset_id : Int
} derive(Eq, Debug)

///|
pub fn OpaqueNoLightmap3dBinKey::new(
  asset_id~ : Int,
) -> OpaqueNoLightmap3dBinKey {
  OpaqueNoLightmap3dBinKey::{ asset_id, }
}

///|
pub struct Opaque3d {
  batch_set_key : Opaque3dBatchSetKey
  bin_key : Opaque3dBinKey
  representative_entity_id : Int
  main_entity_id : Int
  batch_range_start : Int
  batch_range_end : Int
  extra_index : Int
} derive(Eq, Debug)

///|
pub fn Opaque3d::new(
  batch_set_key : Opaque3dBatchSetKey,
  bin_key : Opaque3dBinKey,
  representative_entity_id~ : Int,
  main_entity_id~ : Int,
  batch_range_start? : Int = 0,
  batch_range_end? : Int = 0,
  extra_index? : Int = 0,
) -> Opaque3d {
  Opaque3d::{
    batch_set_key,
    bin_key,
    representative_entity_id,
    main_entity_id,
    batch_range_start,
    batch_range_end,
    extra_index,
  }
}

///|
pub fn Opaque3d::cached_pipeline_id(self : Opaque3d) -> Int {
  self.batch_set_key.pipeline_id
}

///|
pub fn Opaque3d::draw_function_id(self : Opaque3d) -> Int {
  self.batch_set_key.draw_function_id
}

///|
pub struct AlphaMask3d {
  batch_set_key : OpaqueNoLightmap3dBatchSetKey
  bin_key : OpaqueNoLightmap3dBinKey
  representative_entity_id : Int
  main_entity_id : Int
  batch_range_start : Int
  batch_range_end : Int
  extra_index : Int
} derive(Eq, Debug)

///|
pub fn AlphaMask3d::new(
  batch_set_key : OpaqueNoLightmap3dBatchSetKey,
  bin_key : OpaqueNoLightmap3dBinKey,
  representative_entity_id~ : Int,
  main_entity_id~ : Int,
  batch_range_start? : Int = 0,
  batch_range_end? : Int = 0,
  extra_index? : Int = 0,
) -> AlphaMask3d {
  AlphaMask3d::{
    batch_set_key,
    bin_key,
    representative_entity_id,
    main_entity_id,
    batch_range_start,
    batch_range_end,
    extra_index,
  }
}

///|
pub fn AlphaMask3d::cached_pipeline_id(self : AlphaMask3d) -> Int {
  self.batch_set_key.pipeline_id
}

///|
pub fn AlphaMask3d::draw_function_id(self : AlphaMask3d) -> Int {
  self.batch_set_key.draw_function_id
}

///|
pub enum TransparentSortingInfo3d {
  AlwaysOnTop
  Sorted(@math.Vec3, Float)
}

///|
pub fn TransparentSortingInfo3d::always_on_top() -> TransparentSortingInfo3d {
  AlwaysOnTop
}

///|
pub fn TransparentSortingInfo3d::sorted(
  mesh_center~ : @math.Vec3,
  depth_bias? : Float = 0.0F,
) -> TransparentSortingInfo3d {
  Sorted(mesh_center, depth_bias)
}

///|
pub struct Transparent3d {
  sorting_info : TransparentSortingInfo3d
  distance : Float
  pipeline : @material.CachedRenderPipelineId
  entity : @core.Entity
  main_entity : @render.MainEntity
  draw_function : @material.DrawFunctionId
  batch_range_start : Int
  batch_range_end : Int
  extra_index : Int
  indexed : Bool
}

///|
// Bevy source: `bevy_render::render_phase::RenderCommandResult`.
pub(all) enum Transparent3dRenderCommandResult {
  Success
  Skip
} derive(Eq, Debug)

///|
pub type Transparent3dRenderCommand = (@ecs.World, Transparent3d) -> Transparent3dRenderCommandResult

///|
// Bevy source: `DrawFunctions<Transparent3d>` populated by
// `AddRenderCommand::add_render_command`.
pub struct Transparent3dDrawFunctions {
  draw_functions : @material.DrawFunctions
  commands : Array[(@material.DrawFunctionId, Transparent3dRenderCommand)]
}

///|
pub fn Transparent3dDrawFunctions::Transparent3dDrawFunctions() -> Transparent3dDrawFunctions {
  Transparent3dDrawFunctions::{
    draw_functions: @material.DrawFunctions::new(),
    commands: [],
  }
}

///|
pub fn Transparent3dDrawFunctions::register(
  self : Transparent3dDrawFunctions,
  label : @material.DrawFunctionLabel,
  command : Transparent3dRenderCommand,
) -> @material.DrawFunctionId {
  let id = self.draw_functions.register(label)
  for index in 0..<self.commands.length() {
    let (entry_id, _) = self.commands[index]
    if entry_id == id {
      self.commands[index] = (id, command)
      return id
    }
  }
  self.commands.push((id, command))
  id
}

///|
pub fn Transparent3dDrawFunctions::len(
  self : Transparent3dDrawFunctions,
) -> Int {
  self.commands.length()
}

///|
pub fn Transparent3dDrawFunctions::id(
  self : Transparent3dDrawFunctions,
  label : @material.DrawFunctionLabel,
) -> @material.DrawFunctionId? {
  self.draw_functions.id(label)
}

///|
pub fn Transparent3dDrawFunctions::render(
  self : Transparent3dDrawFunctions,
  world : @ecs.World,
  item : Transparent3d,
) -> Transparent3dRenderCommandResult {
  for entry in self.commands {
    let (id, command) = entry
    if id == item.draw_function() {
      return command(world, item)
    }
  }
  Transparent3dRenderCommandResult::Skip
}

///|
pub fn Transparent3d::new(
  sorting_info? : TransparentSortingInfo3d = TransparentSortingInfo3d::always_on_top(),
  distance~ : Float,
  pipeline~ : @material.CachedRenderPipelineId,
  entity~ : @core.Entity,
  main_entity~ : @render.MainEntity,
  draw_function~ : @material.DrawFunctionId,
  batch_range_start? : Int = 0,
  batch_range_end? : Int = 0,
  extra_index? : Int = 0,
  indexed? : Bool = false,
) -> Transparent3d {
  Transparent3d::{
    sorting_info,
    distance,
    pipeline,
    entity,
    main_entity,
    draw_function,
    batch_range_start,
    batch_range_end,
    extra_index,
    indexed,
  }
}

///|
pub fn Transparent3d::sort_key(self : Transparent3d) -> Float {
  self.distance
}

///|
pub fn Transparent3d::sorting_info(
  self : Transparent3d,
) -> TransparentSortingInfo3d {
  self.sorting_info
}

///|
pub fn Transparent3d::pipeline(
  self : Transparent3d,
) -> @material.CachedRenderPipelineId {
  self.pipeline
}

///|
pub fn Transparent3d::entity(self : Transparent3d) -> @core.Entity {
  self.entity
}

///|
pub fn Transparent3d::main_entity(self : Transparent3d) -> @render.MainEntity {
  self.main_entity
}

///|
pub fn Transparent3d::draw_function(
  self : Transparent3d,
) -> @material.DrawFunctionId {
  self.draw_function
}

///|
pub fn Transparent3d::batch_range(self : Transparent3d) -> (Int, Int) {
  (self.batch_range_start, self.batch_range_end)
}

///|
pub fn Transparent3d::extra_index(self : Transparent3d) -> Int {
  self.extra_index
}

///|
pub fn Transparent3d::indexed(self : Transparent3d) -> Bool {
  self.indexed
}

///|
pub struct Opaque3dPhase {
  items : Array[Opaque3d]
}

///|
pub fn Opaque3dPhase::Opaque3dPhase() -> Opaque3dPhase {
  Opaque3dPhase::{ items: [] }
}

///|
pub fn Opaque3dPhase::is_empty(self : Opaque3dPhase) -> Bool {
  self.items.is_empty()
}

///|
pub fn Opaque3dPhase::clear(self : Opaque3dPhase) -> Unit {
  self.items.clear()
}

///|
pub fn Opaque3dPhase::push(self : Opaque3dPhase, item : Opaque3d) -> Unit {
  self.items.push(item)
}

///|
pub struct AlphaMask3dPhase {
  items : Array[AlphaMask3d]
}

///|
pub fn AlphaMask3dPhase::AlphaMask3dPhase() -> AlphaMask3dPhase {
  AlphaMask3dPhase::{ items: [] }
}

///|
pub fn AlphaMask3dPhase::is_empty(self : AlphaMask3dPhase) -> Bool {
  self.items.is_empty()
}

///|
pub fn AlphaMask3dPhase::clear(self : AlphaMask3dPhase) -> Unit {
  self.items.clear()
}

///|
pub fn AlphaMask3dPhase::push(
  self : AlphaMask3dPhase,
  item : AlphaMask3d,
) -> Unit {
  self.items.push(item)
}

///|
pub struct Transparent3dViewPhase {
  mut items : Array[Transparent3d]
  transient_items : Array[(@core.Entity, @render.MainEntity)]
}

///|
pub fn Transparent3dViewPhase::Transparent3dViewPhase() -> Transparent3dViewPhase {
  Transparent3dViewPhase::{ items: [], transient_items: [] }
}

///|
fn Transparent3dViewPhase::item_index(
  self : Transparent3dViewPhase,
  entity : @core.Entity,
  main_entity : @render.MainEntity,
) -> Int? {
  for index in 0..<self.items.length() {
    let item = self.items[index]
    if item.entity() == entity && item.main_entity() == main_entity {
      return Some(index)
    }
  }
  None
}

///|
pub fn Transparent3dViewPhase::add(
  self : Transparent3dViewPhase,
  item : Transparent3d,
) -> Unit {
  match self.item_index(item.entity(), item.main_entity()) {
    Some(index) => self.items[index] = item
    None => self.items.push(item)
  }
}

///|
pub fn Transparent3dViewPhase::add_transient(
  self : Transparent3dViewPhase,
  item : Transparent3d,
) -> Unit {
  let key = (item.entity(), item.main_entity())
  self.add(item)
  self.transient_items.push(key)
}

///|
pub fn Transparent3dViewPhase::remove(
  self : Transparent3dViewPhase,
  entity : @core.Entity,
  main_entity : @render.MainEntity,
) -> Unit {
  self.items = self.items.filter(fn(item) {
    item.entity() != entity || item.main_entity() != main_entity
  })
}

///|
pub fn Transparent3dViewPhase::clear(self : Transparent3dViewPhase) -> Unit {
  self.items.clear()
  self.transient_items.clear()
}

///|
fn Transparent3dViewPhase::prepare_for_new_frame(
  self : Transparent3dViewPhase,
) -> Unit {
  for key in self.transient_items {
    let (entity, main_entity) = key
    self.remove(entity, main_entity)
  }
  self.transient_items.clear()
}

///|
pub fn Transparent3dViewPhase::items(
  self : Transparent3dViewPhase,
) -> Array[Transparent3d] {
  self.items
}

///|
pub fn Transparent3dViewPhase::len(self : Transparent3dViewPhase) -> Int {
  self.items.length()
}

///|
pub struct Transparent3dPhase {
  views : @hashmap.HashMap[
    @render_view.RetainedViewEntity,
    Transparent3dViewPhase,
  ]
}

///|
pub fn Transparent3dPhase::Transparent3dPhase() -> Transparent3dPhase {
  Transparent3dPhase::{ views: @hashmap.HashMap([]) }
}

///|
pub fn Transparent3dPhase::is_empty(self : Transparent3dPhase) -> Bool {
  for _, phase in self.views {
    if !phase.items().is_empty() {
      return false
    }
  }
  true
}

///|
pub fn Transparent3dPhase::clear(self : Transparent3dPhase) -> Unit {
  self.views.clear()
}

///|
pub fn Transparent3dPhase::prepare_for_new_frame(
  self : Transparent3dPhase,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> Unit {
  match self.views.get(retained_view_entity) {
    Some(phase) => phase.prepare_for_new_frame()
    None =>
      self.views.set(
        retained_view_entity,
        Transparent3dViewPhase::Transparent3dViewPhase(),
      )
  }
}

///|
pub fn Transparent3dPhase::view(
  self : Transparent3dPhase,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> Transparent3dViewPhase? {
  self.views.get(retained_view_entity)
}

///|
pub fn Transparent3dPhase::add(
  self : Transparent3dPhase,
  retained_view_entity : @render_view.RetainedViewEntity,
  item : Transparent3d,
) -> Unit {
  self.prepare_for_view(retained_view_entity).add(item)
}

///|
pub fn Transparent3dPhase::add_transient(
  self : Transparent3dPhase,
  retained_view_entity : @render_view.RetainedViewEntity,
  item : Transparent3d,
) -> Unit {
  self.prepare_for_view(retained_view_entity).add_transient(item)
}

///|
fn Transparent3dPhase::prepare_for_view(
  self : Transparent3dPhase,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> Transparent3dViewPhase {
  match self.views.get(retained_view_entity) {
    Some(phase) => phase
    None => {
      let phase = Transparent3dViewPhase::Transparent3dViewPhase()
      self.views.set(retained_view_entity, phase)
      phase
    }
  }
}

///|
pub fn Transparent3dPhase::retain_views(
  self : Transparent3dPhase,
  live_views : Array[@render_view.RetainedViewEntity],
) -> Unit {
  let stale_views : Array[@render_view.RetainedViewEntity] = []
  for retained_view_entity, _phase in self.views {
    if !@render_view.retained_view_entity_contains(
        live_views, retained_view_entity,
      ) {
      stale_views.push(retained_view_entity)
    }
  }
  for retained_view_entity in stale_views {
    self.views.remove(retained_view_entity)
  }
}

///|
pub fn Transparent3dPhase::view_count(self : Transparent3dPhase) -> Int {
  self.views.length()
}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/core_3d/mod.rs::extract_core_3d_camera_phases`.
pub fn extract_core_3d_camera_phases(render_world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(render_world)
  guard render_world.get_resource(Transparent3dPhase::resource())
    is Some(transparent_phases) else {
    return
  }
  let live_views : Array[@render_view.RetainedViewEntity] = []
  let cameras_3d : @ecs.Query[
    @ecs.Read[@camera_components3d.Camera3d],
    @ecs.All,
  ] = @ecs.query(source_world)
  try! cameras_3d.view(fn(entity, _camera3d) {
    guard (try! source_world.get_by_key(entity, @camera_camera.ecs_key_camera))
      is Some(camera) else {
      return
    }
    if !camera.is_active {
      return
    }
    let retained_view_entity = @render_view.RetainedViewEntity::new(entity)
    transparent_phases.prepare_for_new_frame(retained_view_entity)
    live_views.push(retained_view_entity)
  })
  transparent_phases.retain_views(live_views)
}

///|
pub let ecs_key_opaque3d_phase : @ecs.ResourceKey[Opaque3dPhase] = @ecs.register_resource(
  debug_name="core_pipeline.core_3d.opaque3d_phase",
)

///|
pub let ecs_key_alpha_mask3d_phase : @ecs.ResourceKey[AlphaMask3dPhase] = @ecs.register_resource(
  debug_name="core_pipeline.core_3d.alpha_mask3d_phase",
)

///|
pub let ecs_key_transparent3d_phase : @ecs.ResourceKey[Transparent3dPhase] = @ecs.register_resource(
  debug_name="core_pipeline.core_3d.transparent3d_phase",
)

///|
pub let ecs_key_transparent3d_draw_functions : @ecs.ResourceKey[
  Transparent3dDrawFunctions,
] = @ecs.register_resource(
  debug_name="core_pipeline.core_3d.DrawFunctions<Transparent3d>",
)

///|
pub impl @app.Resource for Opaque3dPhase with fn resource() {
  ecs_key_opaque3d_phase
}

///|
pub impl @app.Resource for AlphaMask3dPhase with fn resource() {
  ecs_key_alpha_mask3d_phase
}

///|
pub impl @app.Resource for Transparent3dPhase with fn resource() {
  ecs_key_transparent3d_phase
}

///|
pub impl @app.Resource for Transparent3dDrawFunctions with fn resource() {
  ecs_key_transparent3d_draw_functions
}
