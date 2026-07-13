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
test "post_process boundary re-exports bloom and tonemapping APIs" {
  let bloom = @post_process.Bloom::Bloom()
  debug_inspect(bloom.max_mip_dimension, content="512")
  let tonemapping = @post_process.Tonemapping::default()
  debug_inspect(
    tonemapping.to_json(),
    content=(
      #|String("TonyMcMapface")
    ),
  )
  debug_inspect(
    @post_process.DebandDither::default() == Disabled,
    content="true",
  )
}

///|
test "post_process boundary re-exports fxaa and ssao APIs" {
  let fxaa = @post_process.Fxaa::Fxaa()
  debug_inspect(fxaa.enabled, content="true")
  let ssao = @post_process.ScreenSpaceAmbientOcclusion::ScreenSpaceAmbientOcclusion()
  debug_inspect(ssao.constant_object_thickness.to_double(), content="0.25")
}

///|
test "post_process mip bias mirrors Bevy default" {
  debug_inspect(
    @post_process.MipBias::MipBias().value().to_double(),
    content="-1",
  )
  debug_inspect(
    @post_process.MipBias::new(-0.5F).value().to_double(),
    content="-0.5",
  )
}

///|
test "post_process msaa writeback mirrors Bevy Off Auto Always semantics" {
  debug_inspect(@post_process.MsaaWriteback::default(), content="Auto")
  debug_inspect(
    @post_process.msaa_writeback_required(
      Some(@post_process.MsaaWriteback::Off),
      4,
      sorted_camera_index_for_target=1,
    ),
    content="false",
  )
  debug_inspect(
    @post_process.msaa_writeback_required(
      Some(@post_process.MsaaWriteback::Auto),
      4,
      sorted_camera_index_for_target=0,
    ),
    content="false",
  )
  debug_inspect(
    @post_process.msaa_writeback_required(
      Some(@post_process.MsaaWriteback::Auto),
      4,
      sorted_camera_index_for_target=1,
    ),
    content="true",
  )
  debug_inspect(
    @post_process.msaa_writeback_required(
      Some(@post_process.MsaaWriteback::Always),
      1,
      sorted_camera_index_for_target=0,
    ),
    content="false",
  )
  debug_inspect(
    @post_process.msaa_writeback_required(
      Some(@post_process.MsaaWriteback::Always),
      4,
      sorted_camera_index_for_target=0,
    ),
    content="true",
  )
}

///|
test "post_process registers Bevy root gaussian blur shader library" {
  @post_process.register_embedded_wgsl_sources()
  let source = match
    @shader_source.embedded_shader_source("post_process/gaussian_blur.wgsl") {
    Some(source) => source
    None => ""
  }
  debug_inspect(source.contains("fn gaussian_blur("), content="true")
}

///|
test "post_process plugin owns Bloom Hdr required component" {
  let lifecycle_world_108_0 = @ecs.World::new()
  defer lifecycle_world_108_0.close()
  let app = @app.App::new(lifecycle_world_108_0).add_plugins(
    @post_process.PostProcessPlugin::PostProcessPlugin(),
  )
  let world = app.world()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @post_process.ecs_key_bloom,
    @post_process.Bloom::Bloom(),
  )
  debug_inspect(
    (try! world.get_by_key(entity, @camera_hdr.ecs_key_hdr)) is Some(_),
    content="true",
  )
}
