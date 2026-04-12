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
// Bevy source: `bevy/crates/bevy_pbr/src/light_probe/irradiance_volume.rs`.

///|
pub const IRRADIANCE_VOLUMES_ARE_USABLE : Bool = true

///|
pub type ParallaxCorrection = @light.ParallaxCorrection

///|
pub type IrradianceVolume = @light.IrradianceVolume

///|
pub(all) enum RenderViewIrradianceVolumeBindGroupEntries {
  Single(@asset.Handle[@asset.Image]?)
  Multiple(Array[@asset.Handle[@asset.Image]?])
}

///|
pub struct RenderViewIrradianceVolumeInfo {
  texture : @asset.Handle[@asset.Image]?
  intensity : Float
}

///|
pub fn RenderViewIrradianceVolumeInfo::default() -> RenderViewIrradianceVolumeInfo {
  RenderViewIrradianceVolumeInfo::{ texture: None, intensity: 1.0F }
}

///|
pub fn RenderViewIrradianceVolumeInfo::with_texture(
  self : RenderViewIrradianceVolumeInfo,
  texture : @asset.Handle[@asset.Image]?,
) -> RenderViewIrradianceVolumeInfo {
  RenderViewIrradianceVolumeInfo::{ ..self, texture, }
}

///|
pub fn RenderViewIrradianceVolumeInfo::with_intensity(
  self : RenderViewIrradianceVolumeInfo,
  intensity : Float,
) -> RenderViewIrradianceVolumeInfo {
  RenderViewIrradianceVolumeInfo::{
    ..self,
    intensity: if intensity < 0.0F {
      0.0F
    } else {
      intensity
    },
  }
}

///|
pub fn pbr_irradiance_volume_bind_group_entries(
  volumes : Array[RenderViewIrradianceVolumeInfo],
  use_binding_arrays : Bool,
  max_view_light_probes : Int,
) -> RenderViewIrradianceVolumeBindGroupEntries {
  if !use_binding_arrays || volumes.length() == 0 {
    let single = if volumes.length() == 0 { None } else { volumes[0].texture }
    RenderViewIrradianceVolumeBindGroupEntries::Single(single)
  } else {
    let max_count = if max_view_light_probes <= 0 {
      1
    } else {
      max_view_light_probes
    }
    let textures : Array[@asset.Handle[@asset.Image]?] = []
    for volume in volumes {
      if textures.length() >= max_count {
        break
      }
      textures.push(volume.texture)
    }
    while textures.length() < max_count {
      textures.push(None)
    }
    RenderViewIrradianceVolumeBindGroupEntries::Multiple(textures)
  }
}

///|
pub fn pbr_irradiance_volume_bind_group_layout_counts(
  use_binding_arrays : Bool,
  max_view_light_probes : Int,
) -> (Int, Int) {
  if use_binding_arrays {
    (if max_view_light_probes <= 0 { 1 } else { max_view_light_probes }, 1)
  } else {
    (1, 1)
  }
}

///|
pub fn pbr_parallax_correction_default() -> ParallaxCorrection {
  ParallaxCorrection::default()
}

///|
pub fn pbr_irradiance_volume_default() -> IrradianceVolume {
  IrradianceVolume::default()
}
