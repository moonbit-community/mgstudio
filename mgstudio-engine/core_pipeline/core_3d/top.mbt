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
pub let core_3d_set_post_process : @app.SystemSet = @app.system_set(
  "mgstudio.core_pipeline.core3d.post_process",
)

///|
pub struct Core3dPlugin {}

///|
pub fn Core3dPlugin::default() -> Core3dPlugin {
  Core3dPlugin::{  }
}

///|
pub fn core_3d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  core_3d_plugin_with(app, Core3dPlugin::default())
}

///|
pub impl @app.PluginReplacement for Core3dPlugin with plugin_name(_self) {
  CORE_3D_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for Core3dPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    core_3d_plugin_with(app, self)
  }
}

///|
pub fn core_3d_plugin_with(
  app : @app.App[@ecs.World],
  plugin : Core3dPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  app
  .init_resource(fn() { Opaque3dPhase::default() })
  .init_resource(fn() { AlphaMask3dPhase::default() })
  .init_resource(fn() { Transparent3dPhase::default() })
  .add_plugin(@skybox.skybox_plugin)
}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/core_3d/mod.rs`.
pub(all) enum Msaa {
  Off
  Sample2
  Sample4
  Sample8
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn Msaa::default() -> Msaa {
  Msaa::Sample4
}

///|
pub fn Msaa::samples(self : Msaa) -> Int {
  match self {
    Off => 1
    Sample2 => 2
    Sample4 => 4
    Sample8 => 8
  }
}

///|
pub fn Msaa::from_samples(samples : Int) -> Msaa {
  if samples <= 1 {
    Msaa::Off
  } else if samples <= 2 {
    Msaa::Sample2
  } else if samples <= 4 {
    Msaa::Sample4
  } else {
    Msaa::Sample8
  }
}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/core_3d/mod.rs`.
pub struct Hdr {} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn Hdr::default() -> Hdr {
  Hdr::{  }
}

///|
pub let ecs_key_hdr : @ecs.ComponentKey[Hdr] = @ecs.register_component(
  debug_name="render3d.hdr",
)

///|
pub let ecs_key_msaa : @ecs.ComponentKey[Msaa] = @ecs.register_component(
  debug_name="render3d.msaa",
)

///|
pub impl @ecs.Component for Hdr with component() {
  ecs_key_hdr
}

///|
pub impl @ecs.Component for Msaa with component() {
  ecs_key_msaa
}

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
pub struct Transparent3d {
  distance : Float
  pipeline_id : Int
  entity_id : Int
  main_entity_id : Int
  draw_function_id : Int
  batch_range_start : Int
  batch_range_end : Int
  extra_index : Int
  indexed : Bool
} derive(Eq, Debug)

///|
pub fn Transparent3d::new(
  distance~ : Float,
  pipeline_id~ : Int,
  entity_id~ : Int,
  main_entity_id~ : Int,
  draw_function_id~ : Int,
  batch_range_start? : Int = 0,
  batch_range_end? : Int = 0,
  extra_index? : Int = 0,
  indexed? : Bool = false,
) -> Transparent3d {
  Transparent3d::{
    distance,
    pipeline_id,
    entity_id,
    main_entity_id,
    draw_function_id,
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
pub struct Opaque3dPhase {
  items : Array[Opaque3d]
}

///|
pub fn Opaque3dPhase::default() -> Opaque3dPhase {
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
pub fn AlphaMask3dPhase::default() -> AlphaMask3dPhase {
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
pub struct Transparent3dPhase {
  items : Array[Transparent3d]
}

///|
pub fn Transparent3dPhase::default() -> Transparent3dPhase {
  Transparent3dPhase::{ items: [] }
}

///|
pub fn Transparent3dPhase::is_empty(self : Transparent3dPhase) -> Bool {
  self.items.is_empty()
}

///|
pub fn Transparent3dPhase::clear(self : Transparent3dPhase) -> Unit {
  self.items.clear()
}

///|
pub fn Transparent3dPhase::push(
  self : Transparent3dPhase,
  item : Transparent3d,
) -> Unit {
  self.items.push(item)
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
pub impl @app.Resource for Opaque3dPhase with resource() {
  ecs_key_opaque3d_phase
}

///|
pub impl @app.Resource for AlphaMask3dPhase with resource() {
  ecs_key_alpha_mask3d_phase
}

///|
pub impl @app.Resource for Transparent3dPhase with resource() {
  ecs_key_transparent3d_phase
}
