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
fn render3d_runtime_config_or_default(
  world : @ecs.World,
) -> PbrPluginRuntimeConfig {
  match (try! world.get_resource(ecs_key_pbr_plugin_runtime_config)) {
    Some(config) => config
    None => pbr_plugin_runtime_config()
  }
}

///|
const RENDER3D_MESH3D_DRAW_FLAG_DECAL : Int = 1 << 8

///|
fn render3d_mesh_draw_flags(mesh : ExtractedMesh3d) -> Int {
  let mut flags = 0
  if mesh.payload.is_forward_decal || mesh.payload.clustered_decal is Some(_) {
    flags = flags | RENDER3D_MESH3D_DRAW_FLAG_DECAL
  }
  flags
}

///|
fn render3d_decal_mode_allows_forward(mode : DecalRenderMode3d) -> Bool {
  match mode {
    Disabled => false
    ForwardOnly => true
    ClusteredOnly => false
    ForwardAndClustered => true
  }
}

///|
fn render3d_decal_mode_allows_clustered(mode : DecalRenderMode3d) -> Bool {
  match mode {
    Disabled => false
    ForwardOnly => false
    ClusteredOnly => true
    ForwardAndClustered => true
  }
}

///|
fn render3d_camera_deferred_mode(
  config : CameraDeferredConfig3d,
  default_method : OpaqueRendererMethod,
  deferred_lighting_enabled : Bool,
) -> OpaqueRendererMethod {
  if !deferred_lighting_enabled {
    return OpaqueRendererMethod::Forward
  }
  match config.mode {
    CameraDeferredMode3d::Forward => OpaqueRendererMethod::Forward
    CameraDeferredMode3d::Deferred => OpaqueRendererMethod::Deferred
    CameraDeferredMode3d::Auto =>
      match default_method {
        OpaqueRendererMethod::Forward => OpaqueRendererMethod::Forward
        OpaqueRendererMethod::Deferred => OpaqueRendererMethod::Deferred
        OpaqueRendererMethod::Auto => OpaqueRendererMethod::Forward
      }
  }
}

///|
fn render3d_default_opaque_renderer_method(
  world : @ecs.World,
  deferred_lighting_enabled : Bool,
) -> OpaqueRendererMethod {
  let mut default_method = if (try! world.get_resource(
      ecs_key_default_opaque_renderer_method,
    ))
    is Some(resource) {
    resource.renderer_method()
  } else {
    OpaqueRendererMethod::Forward
  }
  if !deferred_lighting_enabled &&
    default_method is OpaqueRendererMethod::Deferred {
    default_method = OpaqueRendererMethod::Forward
  }
  default_method
}

///|
fn render3d_point_light_shadow_map_size(world : @ecs.World) -> Int {
  if (try! world.get_resource(ecs_key_point_light_shadow_map))
    is Some(shadow_map) {
    if shadow_map.size <= 0 {
      1
    } else {
      shadow_map.size
    }
  } else {
    PointLightShadowMap::default().size
  }
}

///|
fn render3d_wireframe_config_or_none(world : @ecs.World) -> WireframeConfig? {
  if (try! world.get_resource(ecs_key_wireframe_config)) is Some(config) {
    Some(config)
  } else {
    None
  }
}
