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
pub fn EnvironmentMapIds::EnvironmentMapIds() -> EnvironmentMapIds {
  EnvironmentMapIds::{ diffuse: None, specular: None }
}

///|
pub struct EnvironmentMapViewLightProbeInfo {
  cubemap_index : Int
  smallest_specular_mip_level : Int
  intensity : Float
  affects_lightmapped_mesh_diffuse : Bool
  rotation : @math.Quat
}

///|
pub fn EnvironmentMapViewLightProbeInfo::EnvironmentMapViewLightProbeInfo() -> EnvironmentMapViewLightProbeInfo {
  EnvironmentMapViewLightProbeInfo::{
    cubemap_index: -1,
    smallest_specular_mip_level: 0,
    intensity: 1.0F,
    affects_lightmapped_mesh_diffuse: true,
    rotation: @math.Quat::identity(),
  }
}

///|
pub struct RenderViewEnvironmentMapBindGroupEntriesSingle {
  diffuse_texture : @asset.Handle[@asset.Image]?
  specular_texture : @asset.Handle[@asset.Image]?
}

///|
pub struct RenderViewEnvironmentMapTextureIdEntriesSingle {
  diffuse_texture_id : Int
  specular_texture_id : Int
}

///|
pub struct RenderViewEnvironmentMapBindGroupEntriesMultiple {
  diffuse_textures : Array[@asset.Handle[@asset.Image]?]
  specular_textures : Array[@asset.Handle[@asset.Image]?]
}

///|
pub struct RenderViewEnvironmentMapTextureIdEntriesMultiple {
  diffuse_texture_ids : Array[Int]
  specular_texture_ids : Array[Int]
}

///|
pub(all) enum RenderViewEnvironmentMapBindGroupEntries {
  Single(RenderViewEnvironmentMapBindGroupEntriesSingle)
  Multiple(RenderViewEnvironmentMapBindGroupEntriesMultiple)
}

///|
pub(all) enum RenderViewEnvironmentMapTextureIdEntries {
  Single(RenderViewEnvironmentMapTextureIdEntriesSingle)
  Multiple(RenderViewEnvironmentMapTextureIdEntriesMultiple)
}

///|
pub fn pbr_environment_map_bind_group_entries(
  cubemaps : Array[EnvironmentMapIds],
  use_binding_arrays : Bool,
  max_view_light_probes : Int,
) -> RenderViewEnvironmentMapBindGroupEntries {
  if !use_binding_arrays || cubemaps.length() == 0 {
    let first = if cubemaps.length() == 0 {
      EnvironmentMapIds::EnvironmentMapIds()
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
pub fn pbr_environment_map_texture_id_entries(
  diffuse_texture_ids : Array[Int],
  specular_texture_ids : Array[Int],
  use_binding_arrays : Bool,
  max_view_light_probes : Int,
) -> RenderViewEnvironmentMapTextureIdEntries {
  if !use_binding_arrays {
    return RenderViewEnvironmentMapTextureIdEntries::Single(RenderViewEnvironmentMapTextureIdEntriesSingle::{
      diffuse_texture_id: if diffuse_texture_ids.length() == 0 {
        -1
      } else {
        diffuse_texture_ids[0]
      },
      specular_texture_id: if specular_texture_ids.length() == 0 {
        -1
      } else {
        specular_texture_ids[0]
      },
    })
  }
  let max_count = if max_view_light_probes <= 0 {
    1
  } else {
    max_view_light_probes
  }
  let diffuse_entries : Array[Int] = []
  let specular_entries : Array[Int] = []
  for index in 0..<max_count {
    diffuse_entries.push(
      if index < diffuse_texture_ids.length() {
        diffuse_texture_ids[index]
      } else {
        -1
      },
    )
    specular_entries.push(
      if index < specular_texture_ids.length() {
        specular_texture_ids[index]
      } else {
        -1
      },
    )
  }
  RenderViewEnvironmentMapTextureIdEntries::Multiple(RenderViewEnvironmentMapTextureIdEntriesMultiple::{
    diffuse_texture_ids: diffuse_entries,
    specular_texture_ids: specular_entries,
  })
}

///|
pub fn pbr_environment_map_texture_id_entries_diffuse_ids(
  entries : RenderViewEnvironmentMapTextureIdEntries,
) -> Array[Int] {
  match entries {
    Single(single) => [single.diffuse_texture_id]
    Multiple(multiple) => multiple.diffuse_texture_ids
  }
}

///|
pub fn pbr_environment_map_texture_id_entries_specular_ids(
  entries : RenderViewEnvironmentMapTextureIdEntries,
) -> Array[Int] {
  match entries {
    Single(single) => [single.specular_texture_id]
    Multiple(multiple) => multiple.specular_texture_ids
  }
}

///|
pub fn pbr_environment_map_texture_id_entries_ids(
  entries : RenderViewEnvironmentMapTextureIdEntries,
) -> (Array[Int], Array[Int]) {
  match entries {
    Single(single) =>
      ([single.diffuse_texture_id], [single.specular_texture_id])
    Multiple(multiple) =>
      (multiple.diffuse_texture_ids, multiple.specular_texture_ids)
  }
}

///|
pub fn pbr_light_probe_default() -> LightProbe {
  LightProbe()
}

///|
pub fn pbr_light_probe_new() -> LightProbe {
  LightProbe::new()
}

///|
pub fn pbr_environment_map_light_default() -> EnvironmentMapLight {
  EnvironmentMapLight()
}
