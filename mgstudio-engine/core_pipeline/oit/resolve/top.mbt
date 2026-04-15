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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/oit/resolve/mod.rs`.
// OIT resolve plugin owner surface.

///|
const OIT_RESOLVE_PLUGIN_NAME : String = "mgstudio.core_pipeline.oit.resolve.OitResolvePlugin"

///|
pub const OIT_RESOLVE_PASS_LABEL : String = "oit_resolve"

///|
pub struct OitResolvePlugin {}

///|
pub fn OitResolvePlugin::default() -> OitResolvePlugin {
  OitResolvePlugin::{  }
}

///|
pub fn oit_resolve_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_plugins(OitResolvePlugin::default())
}

///|
pub fn oit_resolve_plugin_with(
  app : @app.App[@ecs.World],
  plugin : OitResolvePlugin,
) -> @app.App[@ecs.World] {
  app.add_plugins(plugin)
}

///|
fn oit_resolve_plugin_install_with(
  app : @app.App[@ecs.World],
  plugin : OitResolvePlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  app.init_resource(fn() { OitResolvePipeline::default() })
}

///|
pub const OIT_REQUIRED_STORAGE_BUFFERS : Int = 3

///|
pub impl @app.Plugin for OitResolvePlugin with name(_self) {
  OIT_RESOLVE_PLUGIN_NAME
}

///|
pub impl @app.Plugin for OitResolvePlugin with build(self, app) {
  register_embedded_wgsl_sources()
  oit_resolve_plugin_install_with(app, self)
}

///|
pub struct OitSupportState {
  has_fragment_writable_storage : Bool
  max_storage_buffers_per_shader_stage : Int
}

///|
pub fn OitSupportState::new(
  has_fragment_writable_storage? : Bool = false,
  max_storage_buffers_per_shader_stage? : Int = 0,
) -> OitSupportState {
  OitSupportState::{
    has_fragment_writable_storage,
    max_storage_buffers_per_shader_stage,
  }
}

///|
pub fn is_oit_supported(state : OitSupportState) -> Bool {
  state.has_fragment_writable_storage &&
  state.max_storage_buffers_per_shader_stage >= OIT_REQUIRED_STORAGE_BUFFERS
}

///|
pub struct OitResolveBindGroup {
  bind_group_id : Int
}

///|
pub fn OitResolveBindGroup::new(bind_group_id~ : Int) -> OitResolveBindGroup {
  OitResolveBindGroup::{ bind_group_id, }
}

///|
pub struct OitResolvePipeline {
  has_view_bind_group_layout : Bool
  has_depth_bind_group_layout : Bool
}

///|
pub fn OitResolvePipeline::default() -> OitResolvePipeline {
  OitResolvePipeline::new()
}

///|
pub fn OitResolvePipeline::new() -> OitResolvePipeline {
  OitResolvePipeline::{
    has_view_bind_group_layout: true,
    has_depth_bind_group_layout: true,
  }
}

///|
pub let ecs_key_oit_resolve_pipeline : @ecs.ResourceKey[OitResolvePipeline] = @ecs.register_resource(
  debug_name="core_pipeline.oit.resolve.pipeline",
)

///|
pub impl @app.Resource for OitResolvePipeline with resource() {
  ecs_key_oit_resolve_pipeline
}

///|
pub struct OitResolvePipelineId {
  pipeline_id : Int
}

///|
pub fn OitResolvePipelineId::new(pipeline_id~ : Int) -> OitResolvePipelineId {
  OitResolvePipelineId::{ pipeline_id, }
}

///|
pub struct OitResolvePipelineKey {
  hdr : Bool
  sorted_fragment_max_count : Int
  depth_prepass : Bool
} derive(Eq, Debug)

///|
pub fn OitResolvePipelineKey::new(
  hdr? : Bool = true,
  sorted_fragment_max_count? : Int = 64,
  depth_prepass? : Bool = false,
) -> OitResolvePipelineKey {
  let sorted_fragment_max_count = if sorted_fragment_max_count <= 0 {
    1
  } else {
    sorted_fragment_max_count
  }
  OitResolvePipelineKey::{ hdr, sorted_fragment_max_count, depth_prepass }
}

///|
pub fn oit_resolve_pipeline_target_format(
  key : OitResolvePipelineKey,
) -> String {
  if key.hdr {
    "hdr"
  } else {
    "default"
  }
}

///|
pub fn oit_resolve_pipeline_uses_depth_bind_group(
  key : OitResolvePipelineKey,
) -> Bool {
  !key.depth_prepass
}
