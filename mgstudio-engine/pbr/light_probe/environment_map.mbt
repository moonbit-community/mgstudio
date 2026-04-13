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
// Bevy source: `bevy/crates/bevy_pbr/src/light_probe/environment_map.rs`.

///|
pub type LightProbe = @light.LightProbe

///|
pub type EnvironmentMapLight = @light.EnvironmentMapLight

///|
pub struct EnvironmentMapIds {
  diffuse : @asset.Handle[@asset.Image]?
  specular : @asset.Handle[@asset.Image]?
}

///|
pub fn EnvironmentMapIds::default() -> EnvironmentMapIds {
  EnvironmentMapIds::{ diffuse: None, specular: None }
}

///|
pub struct EnvironmentMapViewLightProbeInfo {
  cubemap_index : Int
  smallest_specular_mip_level : Int
  intensity : Float
  affects_lightmapped_mesh_diffuse : Bool
}

///|
pub fn EnvironmentMapViewLightProbeInfo::default() -> EnvironmentMapViewLightProbeInfo {
  EnvironmentMapViewLightProbeInfo::{
    cubemap_index: -1,
    smallest_specular_mip_level: 0,
    intensity: 1.0F,
    affects_lightmapped_mesh_diffuse: true,
  }
}

///|
pub struct RenderViewEnvironmentMapBindGroupEntriesSingle {
  diffuse_texture : @asset.Handle[@asset.Image]?
  specular_texture : @asset.Handle[@asset.Image]?
}

///|
pub struct RenderViewEnvironmentMapBindGroupEntriesMultiple {
  diffuse_textures : Array[@asset.Handle[@asset.Image]?]
  specular_textures : Array[@asset.Handle[@asset.Image]?]
}

///|
pub(all) enum RenderViewEnvironmentMapBindGroupEntries {
  Single(RenderViewEnvironmentMapBindGroupEntriesSingle)
  Multiple(RenderViewEnvironmentMapBindGroupEntriesMultiple)
}

///|
pub fn pbr_environment_map_bind_group_entries(
  cubemaps : Array[EnvironmentMapIds],
  use_binding_arrays : Bool,
  max_view_light_probes : Int,
) -> RenderViewEnvironmentMapBindGroupEntries {
  if !use_binding_arrays || cubemaps.length() == 0 {
    let first = if cubemaps.length() == 0 {
      EnvironmentMapIds::default()
    } else {
      cubemaps[0]
    }
    return RenderViewEnvironmentMapBindGroupEntries::Single(RenderViewEnvironmentMapBindGroupEntriesSingle::{
      diffuse_texture: first.diffuse,
      specular_texture: first.specular,
    })
  }

  let max_count = if max_view_light_probes <= 0 {
    1
  } else {
    max_view_light_probes
  }
  let diffuse_textures : Array[@asset.Handle[@asset.Image]?] = []
  let specular_textures : Array[@asset.Handle[@asset.Image]?] = []
  for cubemap in cubemaps {
    if diffuse_textures.length() >= max_count {
      break
    }
    diffuse_textures.push(cubemap.diffuse)
    specular_textures.push(cubemap.specular)
  }
  while diffuse_textures.length() < max_count {
    diffuse_textures.push(None)
    specular_textures.push(None)
  }
  RenderViewEnvironmentMapBindGroupEntries::Multiple(RenderViewEnvironmentMapBindGroupEntriesMultiple::{
    diffuse_textures,
    specular_textures,
  })
}

///|
pub fn pbr_environment_map_bind_group_layout_count(
  use_binding_arrays : Bool,
  max_view_light_probes : Int,
) -> Int {
  if use_binding_arrays {
    if max_view_light_probes <= 0 {
      1
    } else {
      max_view_light_probes
    }
  } else {
    1
  }
}

///|
pub fn pbr_environment_map_bind_group_entries_counts(
  entries : RenderViewEnvironmentMapBindGroupEntries,
) -> (Int, Int) {
  match entries {
    Single(_) => (1, 1)
    Multiple(payload) =>
      (payload.diffuse_textures.length(), payload.specular_textures.length())
  }
}

///|
pub fn pbr_light_probe_default() -> LightProbe {
  LightProbe::default()
}

///|
pub fn pbr_light_probe_new() -> LightProbe {
  LightProbe::new()
}

///|
pub fn pbr_environment_map_light_default() -> EnvironmentMapLight {
  EnvironmentMapLight::default()
}
