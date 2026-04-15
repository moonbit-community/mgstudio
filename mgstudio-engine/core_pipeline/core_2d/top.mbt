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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/core_2d/mod.rs`.
// Core 2D plugin owner surface.

///|
const CORE_2D_PLUGIN_NAME : String = "mgstudio.core_pipeline.core_2d.Core2dPlugin"

///|
pub const CORE_2D_DEPTH_FORMAT : String = "depth32float"

///|
pub struct Core2dPlugin {}

///|
pub fn Core2dPlugin::default() -> Core2dPlugin {
  Core2dPlugin::{  }
}

///|
pub type DebandDither = @post_process.DebandDither

///|
pub type Tonemapping = @post_process.Tonemapping

///|
pub let ecs_key_deband_dither : @ecs.ComponentKey[DebandDither] = @post_process.ecs_key_deband_dither

///|
pub let ecs_key_tonemapping : @ecs.ComponentKey[Tonemapping] = @post_process.ecs_key_tonemapping

///|
pub let core_2d_set_extract : @app.SystemSet = @app.system_set(
  "mgstudio.core_pipeline.core2d.extract",
)

///|
pub let core_2d_set_prepare : @app.SystemSet = @app.system_set(
  "mgstudio.core_pipeline.core2d.prepare",
)

///|
pub let core_2d_set_queue : @app.SystemSet = @app.system_set(
  "mgstudio.core_pipeline.core2d.queue",
)

///|
pub let core_2d_set_render : @app.SystemSet = @app.system_set(
  "mgstudio.core_pipeline.core2d.render",
)

///|
pub let core_2d_set_main_pass : @app.SystemSet = @app.system_set(
  "mgstudio.core_pipeline.core2d.main_pass",
)

///|
pub let core_2d_set_post_process : @app.SystemSet = @app.system_set(
  "mgstudio.core_pipeline.core2d.post_process",
)

///|
pub fn core_2d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  core_2d_plugin_with(app, Core2dPlugin::default())
}

///|
fn core_2d_configure_render_sub_app(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  let world = sub_app.world()
  if !world.resource(ecs_key_opaque2d_phase).is_present() {
    world.insert_resource(ecs_key_opaque2d_phase, Opaque2dPhase::default())
  }
  if !world.resource(ecs_key_alpha_mask2d_phase).is_present() {
    world.insert_resource(
      ecs_key_alpha_mask2d_phase,
      AlphaMask2dPhase::default(),
    )
  }
  if !world.resource(ecs_key_transparent2d_phase).is_present() {
    world.insert_resource(
      ecs_key_transparent2d_phase,
      Transparent2dPhase::default(),
    )
  }
  let stage = @render.render_schedule_stage()
  let core_2d_stage = @app.schedule_label("mgstudio.core_pipeline.core_2d")
  let sub_app = @render.configure_base_render_sets(sub_app).add_schedule(
    @app.Schedule::new(core_2d_stage),
  )
  sub_app
  .configure_set(core_2d_stage, core_2d_set_main_pass, before=[
    core_2d_set_post_process,
  ])
  .configure_set(stage, @render.render_system_set_extract_commands, before=[
    core_2d_set_extract,
  ])
  .configure_set(stage, core_2d_set_extract, before=[core_2d_set_prepare])
  .configure_set(stage, @render.render_system_set_prepare, before=[
    core_2d_set_prepare,
  ])
  .configure_set(stage, core_2d_set_prepare, before=[core_2d_set_queue])
  .configure_set(stage, @render.render_system_set_queue_meshes, before=[
    core_2d_set_queue,
  ])
  .configure_set(stage, core_2d_set_queue, before=[core_2d_set_main_pass])
  .configure_set(stage, core_2d_set_queue, before=[
    @render.render_system_set_queue_sweep,
  ])
  .configure_set(stage, core_2d_set_main_pass, before=[core_2d_set_post_process])
  .configure_set(stage, @render.render_system_set_render, before=[
    core_2d_set_main_pass,
  ])
  .configure_set(stage, core_2d_set_post_process, before=[
    @render.render_system_set_cleanup,
  ])
}

///|
pub impl @app.Plugin for Core2dPlugin with name(_self) {
  CORE_2D_PLUGIN_NAME
}

///|
pub impl @app.Plugin for Core2dPlugin with build(self, app) {
  core_2d_plugin_with(app, self)
}

///|
pub fn core_2d_plugin_with(
  app : @app.App[@ecs.World],
  plugin : Core2dPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  let next = app
  @render.with_render_app(next, core_2d_configure_render_sub_app)
}

///|
pub struct BatchSetKey2d {
  indexed : Bool
} derive(Eq, Debug)

///|
pub fn BatchSetKey2d::new(indexed? : Bool = false) -> BatchSetKey2d {
  BatchSetKey2d::{ indexed, }
}

///|
pub fn BatchSetKey2d::indexed(self : BatchSetKey2d) -> Bool {
  self.indexed
}

///|
pub struct Opaque2dBinKey {
  pipeline_id : Int
  draw_function_id : Int
  asset_id : Int
  material_bind_group_id : Int?
} derive(Eq, Debug)

///|
pub fn Opaque2dBinKey::new(
  pipeline_id~ : Int,
  draw_function_id~ : Int,
  asset_id~ : Int,
  material_bind_group_id? : Int? = None,
) -> Opaque2dBinKey {
  Opaque2dBinKey::{
    pipeline_id,
    draw_function_id,
    asset_id,
    material_bind_group_id,
  }
}

///|
pub struct AlphaMask2dBinKey {
  pipeline_id : Int
  draw_function_id : Int
  asset_id : Int
  material_bind_group_id : Int?
} derive(Eq, Debug)

///|
pub fn AlphaMask2dBinKey::new(
  pipeline_id~ : Int,
  draw_function_id~ : Int,
  asset_id~ : Int,
  material_bind_group_id? : Int? = None,
) -> AlphaMask2dBinKey {
  AlphaMask2dBinKey::{
    pipeline_id,
    draw_function_id,
    asset_id,
    material_bind_group_id,
  }
}

///|
pub struct Opaque2d {
  batch_set_key : BatchSetKey2d
  bin_key : Opaque2dBinKey
  representative_entity_id : Int
  main_entity_id : Int
  batch_range_start : Int
  batch_range_end : Int
  extra_index : Int
} derive(Eq, Debug)

///|
pub fn Opaque2d::new(
  batch_set_key : BatchSetKey2d,
  bin_key : Opaque2dBinKey,
  representative_entity_id~ : Int,
  main_entity_id~ : Int,
  batch_range_start? : Int = 0,
  batch_range_end? : Int = 0,
  extra_index? : Int = 0,
) -> Opaque2d {
  Opaque2d::{
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
pub fn Opaque2d::is_indexed(self : Opaque2d) -> Bool {
  self.batch_set_key.indexed
}

///|
pub fn Opaque2d::cached_pipeline_id(self : Opaque2d) -> Int {
  self.bin_key.pipeline_id
}

///|
pub fn Opaque2d::draw_function_id(self : Opaque2d) -> Int {
  self.bin_key.draw_function_id
}

///|
pub struct AlphaMask2d {
  batch_set_key : BatchSetKey2d
  bin_key : AlphaMask2dBinKey
  representative_entity_id : Int
  main_entity_id : Int
  batch_range_start : Int
  batch_range_end : Int
  extra_index : Int
} derive(Eq, Debug)

///|
pub fn AlphaMask2d::new(
  batch_set_key : BatchSetKey2d,
  bin_key : AlphaMask2dBinKey,
  representative_entity_id~ : Int,
  main_entity_id~ : Int,
  batch_range_start? : Int = 0,
  batch_range_end? : Int = 0,
  extra_index? : Int = 0,
) -> AlphaMask2d {
  AlphaMask2d::{
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
pub fn AlphaMask2d::is_indexed(self : AlphaMask2d) -> Bool {
  self.batch_set_key.indexed
}

///|
pub fn AlphaMask2d::cached_pipeline_id(self : AlphaMask2d) -> Int {
  self.bin_key.pipeline_id
}

///|
pub fn AlphaMask2d::draw_function_id(self : AlphaMask2d) -> Int {
  self.bin_key.draw_function_id
}

///|
pub struct Transparent2d {
  sort_key : Float
  entity_id : Int
  main_entity_id : Int
  pipeline_id : Int
  draw_function_id : Int
  batch_range_start : Int
  batch_range_end : Int
  extracted_index : Int
  extra_index : Int
  indexed : Bool
} derive(Eq, Debug)

///|
pub fn Transparent2d::new(
  sort_key~ : Float,
  entity_id~ : Int,
  main_entity_id~ : Int,
  pipeline_id~ : Int,
  draw_function_id~ : Int,
  batch_range_start? : Int = 0,
  batch_range_end? : Int = 0,
  extracted_index? : Int = 0,
  extra_index? : Int = 0,
  indexed? : Bool = false,
) -> Transparent2d {
  Transparent2d::{
    sort_key,
    entity_id,
    main_entity_id,
    pipeline_id,
    draw_function_id,
    batch_range_start,
    batch_range_end,
    extracted_index,
    extra_index,
    indexed,
  }
}

///|
pub fn Transparent2d::is_indexed(self : Transparent2d) -> Bool {
  self.indexed
}

///|
pub fn Transparent2d::distance(self : Transparent2d) -> Float {
  self.sort_key
}

///|
pub struct Opaque2dPhase {
  items : Array[Opaque2d]
}

///|
pub fn Opaque2dPhase::default() -> Opaque2dPhase {
  Opaque2dPhase::{ items: [] }
}

///|
pub fn Opaque2dPhase::is_empty(self : Opaque2dPhase) -> Bool {
  self.items.is_empty()
}

///|
pub fn Opaque2dPhase::len(self : Opaque2dPhase) -> Int {
  self.items.length()
}

///|
pub fn Opaque2dPhase::clear(self : Opaque2dPhase) -> Unit {
  self.items.clear()
}

///|
pub fn Opaque2dPhase::push(self : Opaque2dPhase, item : Opaque2d) -> Unit {
  self.items.push(item)
}

///|
pub struct AlphaMask2dPhase {
  items : Array[AlphaMask2d]
}

///|
pub fn AlphaMask2dPhase::default() -> AlphaMask2dPhase {
  AlphaMask2dPhase::{ items: [] }
}

///|
pub fn AlphaMask2dPhase::is_empty(self : AlphaMask2dPhase) -> Bool {
  self.items.is_empty()
}

///|
pub fn AlphaMask2dPhase::len(self : AlphaMask2dPhase) -> Int {
  self.items.length()
}

///|
pub fn AlphaMask2dPhase::clear(self : AlphaMask2dPhase) -> Unit {
  self.items.clear()
}

///|
pub fn AlphaMask2dPhase::push(
  self : AlphaMask2dPhase,
  item : AlphaMask2d,
) -> Unit {
  self.items.push(item)
}

///|
pub struct Transparent2dPhase {
  items : Array[Transparent2d]
}

///|
pub fn Transparent2dPhase::default() -> Transparent2dPhase {
  Transparent2dPhase::{ items: [] }
}

///|
pub fn Transparent2dPhase::is_empty(self : Transparent2dPhase) -> Bool {
  self.items.is_empty()
}

///|
pub fn Transparent2dPhase::len(self : Transparent2dPhase) -> Int {
  self.items.length()
}

///|
pub fn Transparent2dPhase::clear(self : Transparent2dPhase) -> Unit {
  self.items.clear()
}

///|
pub fn Transparent2dPhase::push(
  self : Transparent2dPhase,
  item : Transparent2d,
) -> Unit {
  self.items.push(item)
}

///|
pub let ecs_key_opaque2d_phase : @ecs.ResourceKey[Opaque2dPhase] = @ecs.register_resource(
  debug_name="core_pipeline.core_2d.opaque2d_phase",
)

///|
pub let ecs_key_alpha_mask2d_phase : @ecs.ResourceKey[AlphaMask2dPhase] = @ecs.register_resource(
  debug_name="core_pipeline.core_2d.alpha_mask2d_phase",
)

///|
pub let ecs_key_transparent2d_phase : @ecs.ResourceKey[Transparent2dPhase] = @ecs.register_resource(
  debug_name="core_pipeline.core_2d.transparent2d_phase",
)

///|
pub impl @app.Resource for Opaque2dPhase with resource() {
  ecs_key_opaque2d_phase
}

///|
pub impl @app.Resource for AlphaMask2dPhase with resource() {
  ecs_key_alpha_mask2d_phase
}

///|
pub impl @app.Resource for Transparent2dPhase with resource() {
  ecs_key_transparent2d_phase
}
