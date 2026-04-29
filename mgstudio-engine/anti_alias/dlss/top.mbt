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
// Bevy source: `bevy/crates/bevy_anti_alias/src/dlss/mod.rs`.

///|
pub const DLSS_RUNTIME_SUPPORTED : Bool = false

///|
const DLSS_INIT_PLUGIN_NAME : String = "mgstudio.anti_alias.dlss.DlssInitPlugin"

///|
const DLSS_PLUGIN_NAME : String = "mgstudio.anti_alias.dlss.DlssPlugin"

///|
pub(all) enum DlssPerfQualityMode {
  Auto
  Dlaa
  Quality
  Balanced
  Performance
  UltraPerformance
} derive(Eq, Debug)

///|
pub fn DlssPerfQualityMode::default() -> DlssPerfQualityMode {
  Auto
}

///|
pub impl Default for DlssPerfQualityMode with default() {
  DlssPerfQualityMode::default()
}

///|
pub struct DlssProjectId {
  value : String
}

///|
pub fn DlssProjectId::new(value : String) -> DlssProjectId {
  DlssProjectId::{ value, }
}

///|
pub fn DlssProjectId::value(self : DlssProjectId) -> String {
  self.value
}

///|
pub struct DlssInitPlugin {}

///|
pub fn DlssInitPlugin::default() -> DlssInitPlugin {
  DlssInitPlugin::{  }
}

///|
pub struct DlssPlugin {}

///|
pub fn DlssPlugin::default() -> DlssPlugin {
  DlssPlugin::{  }
}

///|
pub struct Dlss {
  perf_quality_mode : DlssPerfQualityMode
  reset : Bool
}

///|
pub fn Dlss::default() -> Dlss {
  Dlss::{ perf_quality_mode: DlssPerfQualityMode::default(), reset: false }
}

///|
pub impl Default for Dlss with default() {
  Dlss::default()
}

///|
pub fn Dlss::new(
  perf_quality_mode? : DlssPerfQualityMode = DlssPerfQualityMode::default(),
  reset? : Bool = false,
) -> Dlss {
  Dlss::{ perf_quality_mode, reset }
}

///|
pub fn Dlss::with_perf_quality_mode(
  self : Dlss,
  perf_quality_mode : DlssPerfQualityMode,
) -> Dlss {
  Dlss::{ ..self, perf_quality_mode, }
}

///|
pub fn Dlss::with_reset(self : Dlss, reset : Bool) -> Dlss {
  Dlss::{ ..self, reset, }
}

///|
pub struct DlssRuntimeState {
  enabled_camera_count : Int
  reset_requested_count : Int
  runtime_supported : Bool
} derive(Eq, Debug)

///|
pub fn DlssRuntimeState::default() -> DlssRuntimeState {
  DlssRuntimeState::{
    enabled_camera_count: 0,
    reset_requested_count: 0,
    runtime_supported: DLSS_RUNTIME_SUPPORTED,
  }
}

///|
pub struct DlssSuperResolutionSupported {} derive(Default, Eq, Debug)

///|
pub struct DlssRayReconstructionSupported {} derive(Default, Eq, Debug)

///|
priv struct DlssInitPluginMarker {}

///|
let ecs_key_dlss : @ecs.ComponentKey[Dlss] = @ecs.register_component(
  debug_name="mgstudio_anti_alias::Dlss",
)

///|
let dlss_project_id_resource_key : @ecs.ResourceKey[DlssProjectId] = @ecs.register_resource(
  debug_name="mgstudio_anti_alias::DlssProjectId",
)

///|
let dlss_super_resolution_supported_resource_key : @ecs.ResourceKey[
  DlssSuperResolutionSupported,
] = @ecs.register_resource(
  debug_name="mgstudio_anti_alias::DlssSuperResolutionSupported",
)

///|
let dlss_ray_reconstruction_supported_resource_key : @ecs.ResourceKey[
  DlssRayReconstructionSupported,
] = @ecs.register_resource(
  debug_name="mgstudio_anti_alias::DlssRayReconstructionSupported",
)

///|
let dlss_runtime_state_resource_key : @ecs.ResourceKey[DlssRuntimeState] = @ecs.register_resource(
  debug_name="anti_alias.dlss.runtime_state",
)

///|
let dlss_init_plugin_marker_resource_key : @ecs.ResourceKey[
  DlssInitPluginMarker,
] = @ecs.register_resource(debug_name="anti_alias.dlss.init_plugin_marker")

///|
pub impl @ecs.Component for Dlss with component() {
  ecs_key_dlss
}

///|
pub impl @app.Resource for DlssProjectId with resource() {
  dlss_project_id_resource_key
}

///|
pub impl @app.Resource for DlssSuperResolutionSupported with resource() {
  dlss_super_resolution_supported_resource_key
}

///|
pub impl @app.Resource for DlssRayReconstructionSupported with resource() {
  dlss_ray_reconstruction_supported_resource_key
}

///|
pub impl @app.Resource for DlssRuntimeState with resource() {
  dlss_runtime_state_resource_key
}

///|
pub impl @app.Plugin for DlssInitPlugin with name(_self) {
  DLSS_INIT_PLUGIN_NAME
}

///|
pub impl @app.Plugin for DlssInitPlugin with build(self, app) {
  dlss_init_plugin_with(app, self)
}

///|
pub impl @app.Plugin for DlssPlugin with name(_self) {
  DLSS_PLUGIN_NAME
}

///|
let dlss_required_components_installed : Ref[Bool] = Ref::new(false)

///|
pub fn install_dlss_required_components() -> Unit {
  if dlss_required_components_installed.val {
    return
  }
  ignore(
    @ecs.component_metadata_builder(ecs_key_dlss)
    .require_with(@post_process.ecs_key_temporal_jitter, fn() {
      @post_process.TemporalJitter::default()
    })
    .require_with(@post_process.ecs_key_mip_bias, fn() {
      @post_process.MipBias::default()
    })
    .require_with(@core_pipeline.ecs_key_depth_prepass, fn() {
      @core_pipeline.DepthPrepass::default()
    })
    .require_with(@core_pipeline.ecs_key_motion_vector_prepass, fn() {
      @core_pipeline.MotionVectorPrepass::default()
    })
    .require_with(@core_pipeline.ecs_key_hdr, fn() {
      @core_pipeline.Hdr::default()
    }),
  )
  dlss_required_components_installed.val = true
}

///|
pub impl @app.Plugin for DlssPlugin with build(self, app) {
  install_dlss_required_components()
  dlss_plugin_with(app, self)
}

///|
pub fn dlss_init_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  dlss_init_plugin_with(app, DlssInitPlugin::default())
}

///|
pub fn dlss_init_plugin_with(
  app : @app.App[@ecs.World],
  plugin : DlssInitPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  if app.contains_resource(dlss_init_plugin_marker_resource_key) {
    return app
  }
  if !app.contains_resource(dlss_project_id_resource_key) {
    abort(
      "DlssProjectId must be inserted before DlssInitPlugin, matching bevy_anti_alias::dlss",
    )
  }
  app.insert_world_resource(dlss_init_plugin_marker_resource_key, DlssInitPluginMarker::{

  })
}

///|
pub fn dlss_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  dlss_plugin_with(app, DlssPlugin::default())
}

///|
pub fn dlss_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : DlssPlugin,
) -> @app.App[@ecs.World] {
  let app = if DLSS_RUNTIME_SUPPORTED &&
    !app.contains_resource(dlss_super_resolution_supported_resource_key) {
    app.insert_world_resource(dlss_super_resolution_supported_resource_key, DlssSuperResolutionSupported::{

    })
  } else {
    app
  }
  let app = if DLSS_RUNTIME_SUPPORTED &&
    !app.contains_resource(dlss_ray_reconstruction_supported_resource_key) {
    app.insert_world_resource(dlss_ray_reconstruction_supported_resource_key, DlssRayReconstructionSupported::{

    })
  } else {
    app
  }
  app
  .init_resource(fn() { DlssRuntimeState::default() })
  .add_system(dlss_update_runtime_state)
}

///|
fn dlss_camera_component_present(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  try! world.contains_by_key(entity, @sprite.ecs_key_camera)
}

///|
pub fn dlss_update_runtime_state(world : @ecs.World) -> Unit {
  let mut enabled_camera_count = 0
  let mut reset_requested_count = 0
  let reset_entities : Array[(@core.Entity, Dlss)] = []
  world.for_each_component(ecs_key_dlss, fn(entity, dlss : Dlss) {
    if dlss_camera_component_present(world, entity) {
      enabled_camera_count = enabled_camera_count + 1
      if dlss.reset {
        reset_requested_count = reset_requested_count + 1
        reset_entities.push((entity, dlss))
      }
    }
  })
  for entry in reset_entities {
    try! world.set_by_key(entry.0, ecs_key_dlss, entry.1.with_reset(false))
  }
  let next = DlssRuntimeState::{
    enabled_camera_count,
    reset_requested_count,
    runtime_supported: DLSS_RUNTIME_SUPPORTED,
  }
  let current : DlssRuntimeState? = try! world.get_resource(
    dlss_runtime_state_resource_key,
  )
  match current {
    Some(state) =>
      if state != next {
        world.insert_resource(dlss_runtime_state_resource_key, next)
      }
    None => world.insert_resource(dlss_runtime_state_resource_key, next)
  }
}
