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
fn smaa_test_spawn_camera(world : @ecs.World) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @sprite.ecs_key_camera,
    @sprite.Camera::default(),
  )
  entity
}

///|
test "anti_alias/smaa: runtime state counts only camera entities with Smaa" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(SmaaPlugin::default())
  let camera_entity = smaa_test_spawn_camera(app.world())
  let non_camera_entity = app.world().spawn_empty()
  try! app.world().set_by_key(camera_entity, Smaa::component(), Smaa::default())
  try! app
  .world()
  .set_by_key(non_camera_entity, Smaa::component(), Smaa::default())
  let app = app.update()
  let runtime = try! app
    .world()
    .get_resource(SmaaRuntimeState::resource())
    .unwrap()
  debug_inspect(runtime.enabled_camera_count, content="1")
  debug_inspect(runtime.runtime_supported, content="false")
}

///|
test "anti_alias/smaa: plugin registers embedded wgsl source" {
  let _app = @app.App::new(@ecs.World::new()).add_plugins(SmaaPlugin::default())
  let source = match @wgsl.registered_wgsl_source("anti_alias/smaa/smaa.wgsl") {
    Some(source) => source
    None => ""
  }
  debug_inspect(
    source.contains("fn edge_detection_vertex_main"),
    content="true",
  )
}

///|
test "anti_alias/smaa: plugin registers Bevy lookup table assets" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(SmaaPlugin::default())
  debug_inspect(
    try! (app.world().get_resource(ecs_key_smaa_luts) is Some(_)),
    content="true",
  )
  debug_inspect(
    smaa_embedded_lut_registered("anti_alias/smaa/SMAAAreaLUT.ktx2"),
    content="true",
  )
  debug_inspect(
    smaa_embedded_lut_registered("anti_alias/smaa/SMAASearchLUT.ktx2"),
    content="true",
  )
}

///|
test "anti_alias/smaa: preset shader defs and uniform metrics mirror Bevy" {
  debug_inspect(
    SmaaPreset::Low.shader_def(),
    content=(
      #|"SMAA_PRESET_LOW"
    ),
  )
  debug_inspect(
    SmaaPreset::Medium.shader_def(),
    content=(
      #|"SMAA_PRESET_MEDIUM"
    ),
  )
  debug_inspect(
    SmaaPreset::High.shader_def(),
    content=(
      #|"SMAA_PRESET_HIGH"
    ),
  )
  debug_inspect(
    SmaaPreset::Ultra.shader_def(),
    content=(
      #|"SMAA_PRESET_ULTRA"
    ),
  )
  let uniform = SmaaInfoUniform::from_viewport_size(200.0F, 100.0F)
  debug_inspect(
    uniform.rt_metrics.equal(@math.Vec4::new(0.005F, 0.01F, 200.0F, 100.0F)),
    content="true",
  )
}

///|
test "anti_alias/smaa: pipeline descriptors mirror Bevy pass layout" {
  let pipelines = init_smaa_pipelines()
  let edge = pipelines.edge_detection.specialize(SmaaPreset::High)
  let blend = pipelines.blending_weight_calculation.specialize(
    SmaaPreset::Medium,
  )
  let neighborhood = pipelines.neighborhood_blending.specialize(SmaaNeighborhoodBlendingPipelineKey::{
    texture_format: @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    preset: SmaaPreset::Ultra,
  })
  debug_inspect(edge.label == Some("SMAA edge detection"), content="true")
  inspect(edge.layout.length(), content="2")
  inspect(edge.layout[0].label, content="SMAA postprocess bind group layout")
  inspect(edge.layout[0].entries.length(), content="2")
  inspect(edge.layout[1].entries.length(), content="1")
  debug_inspect(
    edge.vertex.entry_point == Some("edge_detection_vertex_main"),
    content="true",
  )
  debug_inspect(
    edge.fragment.unwrap().entry_point ==
    Some("luma_edge_detection_fragment_main"),
    content="true",
  )
  inspect(edge.fragment.unwrap().targets[0].unwrap().format, content="8")
  inspect(edge.depth_stencil.unwrap().format, content="38")
  debug_inspect(
    blend.fragment.unwrap().entry_point ==
    Some("blending_weight_calculation_fragment_main"),
    content="true",
  )
  inspect(blend.layout[1].entries.length(), content="4")
  debug_inspect(
    neighborhood.fragment.unwrap().entry_point ==
    Some("neighborhood_blending_fragment_main"),
    content="true",
  )
  inspect(
    neighborhood.fragment.unwrap().targets[0].unwrap().format,
    content="18",
  )
}
