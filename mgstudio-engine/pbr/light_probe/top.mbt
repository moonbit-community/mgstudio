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
// Bevy source: `bevy/crates/bevy_pbr/src/light_probe/mod.rs`.

///|
const LIGHT_PROBE_PLUGIN_NAME : String = "mgstudio.pbr.light_probe.LightProbePlugin"

///|
pub const MAX_VIEW_LIGHT_PROBES : Int = 8

///|
pub const STANDARD_MATERIAL_FRAGMENT_SHADER_MIN_TEXTURE_BINDINGS : Int = 16

///|
pub fn max_view_light_probes() -> Int {
  MAX_VIEW_LIGHT_PROBES
}

///|
pub struct LightProbePlugin {}

///|
pub fn LightProbePlugin::default() -> LightProbePlugin {
  LightProbePlugin::{  }
}

///|
pub impl @app.Plugin for LightProbePlugin with name(_self) {
  LIGHT_PROBE_PLUGIN_NAME
}

///|
pub impl @app.Plugin for LightProbePlugin with build(self, app) {
  register_embedded_wgsl_sources()
  light_probe_plugin_with(app, self)
}

///|
pub struct LightProbePluginState {
  binding_arrays_supported : Bool
  extracted_probe_count : Int
}

///|
pub fn LightProbePluginState::default() -> LightProbePluginState {
  LightProbePluginState::{
    binding_arrays_supported: true,
    extracted_probe_count: 0,
  }
}

///|
pub fn light_probe_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  light_probe_plugin_with(app, LightProbePlugin::default())
}

///|
pub fn light_probe_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : LightProbePlugin,
) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { LightProbePluginState::default() })
  .init_resource(fn() { LightProbesUniform::default() })
}

///|
pub fn light_probe_plugin_state_with_extracted_probe_count(
  state : LightProbePluginState,
  extracted_probe_count : Int,
) -> LightProbePluginState {
  LightProbePluginState::{
    ..state,
    extracted_probe_count: if extracted_probe_count < 0 {
      0
    } else {
      extracted_probe_count
    },
  }
}

///|
pub struct RenderLightProbe {
  light_from_world_transposed : Array[@math.Vec4]
  falloff : @math.Vec3
  parallax_correction_bounds : @math.Vec3
  texture_index : Int
  intensity : Float
  flags : Int
}

///|
pub fn RenderLightProbe::default() -> RenderLightProbe {
  RenderLightProbe::{
    light_from_world_transposed: [
      @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    ],
    falloff: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    parallax_correction_bounds: @math.Vec3::new(1.0F, 1.0F, 1.0F),
    texture_index: -1,
    intensity: 1.0F,
    flags: 0,
  }
}

///|
pub const RENDER_LIGHT_PROBE_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE : Int = 1

///|
pub const RENDER_LIGHT_PROBE_FLAG_ENABLE_PARALLAX_CORRECTION : Int = 2

///|
pub fn render_light_probe_flags_insert(flags : Int, flag : Int) -> Int {
  flags | flag
}

///|
pub fn render_light_probe_flags_contains(flags : Int, flag : Int) -> Bool {
  (flags & flag) != 0
}

///|
pub struct RenderViewLightProbes {
  binding_index_to_textures : Array[@asset.Handle[@asset.Image]?]
  render_light_probes : Array[RenderLightProbe]
  view_texture_index : Int
}

///|
pub fn RenderViewLightProbes::default() -> RenderViewLightProbes {
  RenderViewLightProbes::{
    binding_index_to_textures: [],
    render_light_probes: [],
    view_texture_index: -1,
  }
}

///|
pub fn RenderViewLightProbes::push_texture(
  self : RenderViewLightProbes,
  texture : @asset.Handle[@asset.Image]?,
) -> Int {
  if self.binding_index_to_textures.length() >= MAX_VIEW_LIGHT_PROBES {
    return MAX_VIEW_LIGHT_PROBES - 1
  }
  let index = self.binding_index_to_textures.length()
  self.binding_index_to_textures.push(texture)
  index
}

///|
pub fn RenderViewLightProbes::push_probe(
  self : RenderViewLightProbes,
  probe : RenderLightProbe,
) -> Unit {
  if self.render_light_probes.length() >= MAX_VIEW_LIGHT_PROBES {
    return
  }
  self.render_light_probes.push(probe)
}

///|
pub fn RenderViewLightProbes::texture_count(
  self : RenderViewLightProbes,
) -> Int {
  self.binding_index_to_textures.length()
}

///|
pub fn RenderViewLightProbes::probe_count(self : RenderViewLightProbes) -> Int {
  self.render_light_probes.length()
}

///|
pub let ecs_key_light_probe_plugin_state : @ecs.ResourceKey[
  LightProbePluginState,
] = @ecs.register_resource(debug_name="mgstudio.pbr.light_probe.plugin_state")

///|
pub let ecs_key_render_view_light_probes : @ecs.ComponentKey[
  RenderViewLightProbes,
] = @ecs.register_component(
  debug_name="mgstudio.pbr.light_probe.render_view_light_probes",
)

///|
pub struct LightProbesUniform {
  reflection_probe_count : Int
  irradiance_volume_count : Int
  view_cubemap_index : Int
}

///|
pub fn LightProbesUniform::default() -> LightProbesUniform {
  LightProbesUniform::{
    reflection_probe_count: 0,
    irradiance_volume_count: 0,
    view_cubemap_index: -1,
  }
}

///|
pub let ecs_key_light_probes_uniform : @ecs.ResourceKey[LightProbesUniform] = @ecs.register_resource(
  debug_name="mgstudio.pbr.light_probe.uniform",
)

///|
pub struct ViewLightProbesUniformOffset {
  offset : UInt
}

///|
pub fn ViewLightProbesUniformOffset::default() -> ViewLightProbesUniformOffset {
  ViewLightProbesUniformOffset::{ offset: 0U }
}

///|
pub let ecs_key_view_light_probes_uniform_offset : @ecs.ComponentKey[
  ViewLightProbesUniformOffset,
] = @ecs.register_component(
  debug_name="mgstudio.pbr.light_probe.uniform_offset",
)

///|
pub impl @app.Resource for LightProbePluginState with resource() {
  ecs_key_light_probe_plugin_state
}

///|
pub impl @ecs.Component for RenderViewLightProbes with component() {
  ecs_key_render_view_light_probes
}

///|
pub impl @app.Resource for LightProbesUniform with resource() {
  ecs_key_light_probes_uniform
}

///|
pub impl @ecs.Component for ViewLightProbesUniformOffset with component() {
  ecs_key_view_light_probes_uniform_offset
}
