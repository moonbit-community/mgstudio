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
fn taa_test_spawn_camera(world : @ecs.World) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @sprite.ecs_key_camera,
    @sprite.Camera::default(),
  )
  entity
}

///|
test "anti_alias/taa: runtime state tracks camera-only and reset count" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    TemporalAntiAliasPlugin::default(),
  )
  let camera_entity = taa_test_spawn_camera(app.world())
  let non_camera_entity = app.world().spawn_empty()
  try! app
  .world()
  .set_by_key(
    camera_entity,
    ecs_key_temporal_anti_aliasing,
    TemporalAntiAliasing::new(true),
  )
  try! app
  .world()
  .set_by_key(
    non_camera_entity,
    ecs_key_temporal_anti_aliasing,
    TemporalAntiAliasing::new(true),
  )
  let app = app.update()
  let runtime = try! app
    .world()
    .get_resource(ecs_key_temporal_anti_alias_runtime_state)
    .unwrap()
  let camera_taa = try! app
    .world()
    .get_by_key(camera_entity, ecs_key_temporal_anti_aliasing)
    .unwrap()
  debug_inspect(runtime.enabled_camera_count, content="1")
  debug_inspect(runtime.reset_requested_count, content="1")
  debug_inspect(camera_taa.reset, content="false")
}

///|
test "anti_alias/taa: plugin registers embedded wgsl source" {
  let _app = @app.App::new(@ecs.World::new()).add_plugins(
    TemporalAntiAliasPlugin::default(),
  )
  let source = match @wgsl.registered_wgsl_source("anti_alias/taa/taa.wgsl") {
    Some(source) => source
    None => ""
  }
  debug_inspect(source.contains("fn taa(@location(0) uv"), content="true")
}

///|
test "anti_alias/taa: required components mirror Bevy camera prerequisites" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    TemporalAntiAliasPlugin::default(),
  )
  let entity = app.world().spawn_empty()
  try! app
  .world()
  .set_by_key(
    entity,
    ecs_key_temporal_anti_aliasing,
    TemporalAntiAliasing::default(),
  )
  debug_inspect(
    try! app.world().contains_by_key(entity, ecs_key_temporal_jitter),
    content="true",
  )
  debug_inspect(
    try! app.world().contains_by_key(entity, ecs_key_mip_bias),
    content="true",
  )
  debug_inspect(
    try! app
    .world()
    .contains_by_key(entity, @core_pipeline.ecs_key_depth_prepass),
    content="true",
  )
  debug_inspect(
    try! app
    .world()
    .contains_by_key(entity, @core_pipeline.ecs_key_motion_vector_prepass),
    content="true",
  )
}

///|
test "anti_alias/taa: prepare_taa_jitter follows Bevy Halton sequence" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@diagnostic.FrameCountPlugin::default())
    .add_plugins(TemporalAntiAliasPlugin::default())
  let entity = taa_test_spawn_camera(app.world())
  try! app
  .world()
  .set_by_key(entity, @pbr.ecs_key_camera3d, @pbr.Camera3d::default())
  try! app
  .world()
  .set_by_key(
    entity,
    ecs_key_temporal_anti_aliasing,
    TemporalAntiAliasing::default(),
  )
  let app = app.update().update().update().update()
  let jitter = try! app
    .world()
    .get_by_key(entity, ecs_key_temporal_jitter)
    .unwrap()
  let expected = @math.Vec2::new(0.25F, -0.3888889F)
  let offset_after_wrap = temporal_anti_alias_halton_offset(9)
  let expected_after_wrap = @math.Vec2::new(0.0F, -0.16666666F)
  debug_inspect(
    taa_test_nearly_equal(jitter.offset.x, expected.x) &&
    taa_test_nearly_equal(jitter.offset.y, expected.y),
    content="true",
  )
  debug_inspect(
    taa_test_nearly_equal(offset_after_wrap.x, expected_after_wrap.x) &&
    taa_test_nearly_equal(offset_after_wrap.y, expected_after_wrap.y),
    content="true",
  )
}

///|
fn taa_test_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn taa_test_nearly_equal(lhs : Float, rhs : Float) -> Bool {
  taa_test_abs(lhs - rhs) <= 1.0e-5F
}
