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
test "core_pipeline boundary re-exports prepass markers and msaa" {
  let depth = @core_pipeline.DepthPrepass::default()
  let normal = @core_pipeline.NormalPrepass::default()
  let motion = @core_pipeline.MotionVectorPrepass::default()
  let deferred = @core_pipeline.DeferredPrepass::default()
  let hdr = @core_pipeline.Hdr::default()
  debug_inspect(depth.to_json().to_string(), content="\"Object({})\"")
  debug_inspect(normal.to_json().to_string(), content="\"Object({})\"")
  debug_inspect(motion.to_json().to_string(), content="\"Object({})\"")
  debug_inspect(deferred.to_json().to_string(), content="\"Object({})\"")
  debug_inspect(hdr.to_json().to_string(), content="\"Object({})\"")
  debug_inspect(@core_pipeline.Msaa::from_samples(4).samples(), content="4")
}

///|
test "mip_generation plugin initializes downsample shader registry resource" {
  let app = @app.App::new(@ecs.World::new()).add_plugin(
    @mip_generation.mip_generation_plugin,
  )
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let shaders = try! render_world
    .get_resource(@mip_generation.ecs_key_downsample_shaders)
    .unwrap()
  debug_inspect(
    shaders.depth_shader_path(),
    content="\"core_pipeline/mip_generation/experimental/downsample_depth.wgsl\"",
  )
  debug_inspect(shaders.general_shader_count(), content="40")
}

///|
test "mip_generation texture format table follows bevy list shape" {
  let formats = @mip_generation.downsample_texture_formats()
  debug_inspect(formats.length(), content="40")
  debug_inspect(formats[0], content="(\"Rgba8Unorm\", \"rgba8unorm\")")
  debug_inspect(
    formats[formats.length() - 1],
    content="(\"Rg11b10Ufloat\", \"rg11b10ufloat\")",
  )
}
