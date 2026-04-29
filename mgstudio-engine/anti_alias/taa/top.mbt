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
// Bevy source: `bevy/crates/bevy_anti_alias/src/taa/mod.rs`.

///|
pub type TemporalAntiAliasing = @post_process.TemporalAntiAliasing

///|
pub type TemporalJitter = @post_process.TemporalJitter

///|
pub type MipBias = @post_process.MipBias

///|
pub let ecs_key_temporal_anti_aliasing : @ecs.ComponentKey[TemporalAntiAliasing] = @post_process.ecs_key_temporal_anti_aliasing

///|
pub let ecs_key_temporal_jitter : @ecs.ComponentKey[TemporalJitter] = @post_process.ecs_key_temporal_jitter

///|
pub let ecs_key_mip_bias : @ecs.ComponentKey[MipBias] = @post_process.ecs_key_mip_bias

///|
const TEMPORAL_ANTI_ALIAS_PLUGIN_NAME : String = "mgstudio.anti_alias.taa.TemporalAntiAliasPlugin"

///|
pub struct TemporalAntiAliasPlugin {}

///|
pub fn TemporalAntiAliasPlugin::default() -> TemporalAntiAliasPlugin {
  TemporalAntiAliasPlugin::{  }
}

///|
pub struct TemporalAntiAliasRuntimeState {
  enabled_camera_count : Int
  reset_requested_count : Int
} derive(Eq, Debug)

///|
pub fn TemporalAntiAliasRuntimeState::default() -> TemporalAntiAliasRuntimeState {
  TemporalAntiAliasRuntimeState::{
    enabled_camera_count: 0,
    reset_requested_count: 0,
  }
}

///|
pub let ecs_key_temporal_anti_alias_runtime_state : @ecs.ResourceKey[
  TemporalAntiAliasRuntimeState,
] = @ecs.register_resource(debug_name="anti_alias.taa.runtime_state")

///|
pub impl @app.Resource for TemporalAntiAliasRuntimeState with resource() {
  ecs_key_temporal_anti_alias_runtime_state
}

///|
pub impl @app.Plugin for TemporalAntiAliasPlugin with name(_self) {
  TEMPORAL_ANTI_ALIAS_PLUGIN_NAME
}

///|
let temporal_anti_alias_required_components_installed : Ref[Bool] = Ref::new(
  false,
)

///|
pub fn install_temporal_anti_alias_required_components() -> Unit {
  if temporal_anti_alias_required_components_installed.val {
    return
  }
  ignore(
    @ecs.component_metadata_builder(ecs_key_temporal_anti_aliasing)
    .require_with(ecs_key_temporal_jitter, fn() { TemporalJitter::default() })
    .require_with(ecs_key_mip_bias, fn() { MipBias::default() })
    .require_with(@core_pipeline.ecs_key_depth_prepass, fn() {
      @core_pipeline.DepthPrepass::default()
    })
    .require_with(@core_pipeline.ecs_key_motion_vector_prepass, fn() {
      @core_pipeline.MotionVectorPrepass::default()
    }),
  )
  temporal_anti_alias_required_components_installed.val = true
}

///|
pub impl @app.Plugin for TemporalAntiAliasPlugin with build(self, app) {
  install_temporal_anti_alias_required_components()
  register_embedded_wgsl_sources()
  temporal_anti_alias_plugin_with(app, self)
}

///|
pub fn temporal_anti_alias_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  temporal_anti_alias_plugin_with(app, TemporalAntiAliasPlugin::default())
}

///|
pub fn temporal_anti_alias_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : TemporalAntiAliasPlugin,
) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { TemporalAntiAliasRuntimeState::default() })
  .add_system(temporal_anti_alias_update_runtime_state)
  .add_system(prepare_taa_jitter)
}

///|
fn temporal_anti_alias_camera_component_present(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  try! world.contains_by_key(entity, @sprite.ecs_key_camera)
}

///|
pub fn temporal_anti_alias_update_runtime_state(world : @ecs.World) -> Unit {
  let mut enabled_camera_count = 0
  let mut reset_requested_count = 0
  let reset_entities : Array[@core.Entity] = []
  world.for_each_component(ecs_key_temporal_anti_aliasing, fn(
    entity,
    taa : TemporalAntiAliasing,
  ) {
    if temporal_anti_alias_camera_component_present(world, entity) {
      enabled_camera_count = enabled_camera_count + 1
      if taa.reset {
        reset_requested_count = reset_requested_count + 1
        reset_entities.push(entity)
      }
    }
  })
  for entity in reset_entities {
    try! world.set_by_key(
      entity,
      ecs_key_temporal_anti_aliasing,
      TemporalAntiAliasing::new(false),
    )
  }
  let next = TemporalAntiAliasRuntimeState::{
    enabled_camera_count,
    reset_requested_count,
  }
  let current : TemporalAntiAliasRuntimeState? = try! world.get_resource(
    ecs_key_temporal_anti_alias_runtime_state,
  )
  match current {
    Some(state) =>
      if state != next {
        world.insert_resource(ecs_key_temporal_anti_alias_runtime_state, next)
      }
    None =>
      world.insert_resource(ecs_key_temporal_anti_alias_runtime_state, next)
  }
}

///|
pub fn temporal_anti_alias_halton_offset(frame_count : Int) -> @math.Vec2 {
  // Bevy source: `bevy_anti_alias/src/taa/mod.rs::prepare_taa_jitter`.
  let halton_sequence = [
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(0.0F, -0.16666666F),
    @math.Vec2::new(-0.25F, 0.16666669F),
    @math.Vec2::new(0.25F, -0.3888889F),
    @math.Vec2::new(-0.375F, -0.055555552F),
    @math.Vec2::new(0.125F, 0.2777778F),
    @math.Vec2::new(-0.125F, -0.2777778F),
    @math.Vec2::new(0.375F, 0.055555582F),
  ]
  halton_sequence[frame_count % halton_sequence.length()]
}

///|
pub fn prepare_taa_jitter(world : @ecs.World) -> Unit {
  let frame_count = match
    (try! world.get_resource(@diagnostic.FrameCount::resource())) {
    Some(frame_count) => frame_count.value
    None => 0
  }
  let offset = temporal_anti_alias_halton_offset(frame_count)
  world.for_each_component(ecs_key_temporal_anti_aliasing, fn(entity, _taa) {
    let is_camera3d = try! world.contains_by_key(entity, @pbr.ecs_key_camera3d)
    let has_jitter = try! world.contains_by_key(entity, ecs_key_temporal_jitter)
    let has_depth_prepass = try! world.contains_by_key(
      entity, @core_pipeline.ecs_key_depth_prepass,
    )
    let has_motion_vector_prepass = try! world.contains_by_key(
      entity, @core_pipeline.ecs_key_motion_vector_prepass,
    )
    if is_camera3d &&
      has_jitter &&
      has_depth_prepass &&
      has_motion_vector_prepass {
      try! world.set_by_key(
        entity,
        ecs_key_temporal_jitter,
        TemporalJitter::new(offset),
      )
    }
  })
}
