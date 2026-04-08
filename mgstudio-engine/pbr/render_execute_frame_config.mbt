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
priv struct Render3dExecuteFrameConfig {
  gpu_instance_buffer_builder_requested : Bool
  gpu_culling_supported : Bool
  gpu_instance_buffer_builder_enabled : Bool
  prepass_enabled : Bool
  deferred_lighting_enabled : Bool
  delta_seconds : Float
  default_opaque_renderer_method : OpaqueRendererMethod
  point_light_shadow_map_size : Int
  wireframe_config : WireframeConfig?
}

///|
fn render3d_execute_frame_config(
  source_world : @ecs.World,
) -> Render3dExecuteFrameConfig {
  let runtime_config = render3d_runtime_config_or_default(source_world)
  let gpu_instance_buffer_builder_requested = @pbr_render.render3d_use_gpu_instance_buffer_builder(
    runtime_config.use_gpu_instance_buffer_builder,
  )
  let prepass_enabled = standard_material_prepass_enabled(source_world)
  let deferred_lighting_enabled = runtime_config.add_default_deferred_lighting_plugin &&
    deferred_pbr_lighting_enabled(source_world)
  let gpu_culling_supported = @pbr_render.render3d_gpu_culling_supported()
  let gpu_instance_buffer_builder_enabled = gpu_instance_buffer_builder_requested &&
    gpu_culling_supported
  @render.host_gpu_set_mesh3d_gpu_instance_builder_enabled(
    gpu_instance_buffer_builder_enabled,
  )
  let default_opaque_renderer_method = render3d_default_opaque_renderer_method(
    source_world, deferred_lighting_enabled,
  )
  let point_light_shadow_map_size = render3d_point_light_shadow_map_size(
    source_world,
  )
  let delta_seconds = @pbr_render.render3d_default_time_or_default(source_world).delta_seconds()
  let wireframe_config = render3d_wireframe_config_or_none(source_world)
  Render3dExecuteFrameConfig::{
    gpu_instance_buffer_builder_requested,
    gpu_culling_supported,
    gpu_instance_buffer_builder_enabled,
    prepass_enabled,
    deferred_lighting_enabled,
    delta_seconds,
    default_opaque_renderer_method,
    point_light_shadow_map_size,
    wireframe_config,
  }
}
