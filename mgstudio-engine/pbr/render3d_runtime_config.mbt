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
fn render3d_default_time_or_default(world : @ecs.World) -> @time.Time[Unit] {
  @pbr_render.render3d_default_time_or_default(world)
}

///|
fn render3d_runtime_config_or_default(
  world : @ecs.World,
) -> PbrPluginRuntimeConfig {
  match (try! world.get_resource(ecs_key_pbr_plugin_runtime_config)) {
    Some(config) => config
    None => pbr_plugin_runtime_config()
  }
}

///|
fn render3d_use_gpu_instance_buffer_builder(
  runtime_config : PbrPluginRuntimeConfig,
) -> Bool {
  @pbr_render.render3d_use_gpu_instance_buffer_builder(
    runtime_config.use_gpu_instance_buffer_builder,
  )
}

///|
fn render3d_gpu_culling_supported() -> Bool {
  @pbr_render.render3d_gpu_culling_supported()
}

///|
fn render3d_camera_indirect_enabled(
  use_gpu_instance_buffer_builder : Bool,
  gpu_culling_supported : Bool,
  no_indirect_drawing : Bool,
) -> Bool {
  @pbr_render.render3d_camera_indirect_enabled(
    use_gpu_instance_buffer_builder, gpu_culling_supported, no_indirect_drawing,
  )
}
