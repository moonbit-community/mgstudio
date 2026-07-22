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
  { diffuse: None, specular: None }
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
  {
    cubemap_index: -1,
    smallest_specular_mip_level: 0,
    intensity: 1.0F,
    affects_lightmapped_mesh_diffuse: true,
    rotation: @math.Quat::identity(),
  }
}

///|
pub fn EnvironmentMapViewLightProbeInfo::new(
  cubemap_index : Int,
  smallest_specular_mip_level : Int,
  intensity : Float,
  affects_lightmapped_mesh_diffuse : Bool,
  rotation : @math.Quat,
) -> EnvironmentMapViewLightProbeInfo {
  {
    cubemap_index,
    smallest_specular_mip_level,
    intensity,
    affects_lightmapped_mesh_diffuse,
    rotation,
  }
}

///|
pub fn EnvironmentMapViewLightProbeInfo::cubemap_index(
  self : EnvironmentMapViewLightProbeInfo,
) -> Int {
  self.cubemap_index
}

///|
pub fn EnvironmentMapViewLightProbeInfo::smallest_specular_mip_level(
  self : EnvironmentMapViewLightProbeInfo,
) -> Int {
  self.smallest_specular_mip_level
}

///|
pub fn EnvironmentMapViewLightProbeInfo::intensity(
  self : EnvironmentMapViewLightProbeInfo,
) -> Float {
  self.intensity
}

///|
pub fn EnvironmentMapViewLightProbeInfo::affects_lightmapped_mesh_diffuse(
  self : EnvironmentMapViewLightProbeInfo,
) -> Bool {
  self.affects_lightmapped_mesh_diffuse
}

///|
pub fn EnvironmentMapViewLightProbeInfo::rotation(
  self : EnvironmentMapViewLightProbeInfo,
) -> @math.Quat {
  self.rotation
}

///|
pub fn environment_map_light_create_render_view_light_probes(
  view_component : EnvironmentMapLight?,
) -> RenderViewLightProbes {
  let render_view_light_probes = RenderViewLightProbes::RenderViewLightProbes()
  match view_component {
    Some(environment_map_light) =>
      environment_map_light_insert_view_light_probe_info(
        render_view_light_probes, environment_map_light,
      )
    None => ()
  }
  render_view_light_probes
}

///|
fn environment_map_light_loaded_gpu_image(
  image : @asset.Handle[@asset.Image]?,
) -> @render_texture.GpuImage? {
  guard image is Some(handle) else { return None }
  guard @render_texture.GpuImage::from_texture_id(handle.id())
    is Some(gpu_image) else {
    return None
  }
  if gpu_image.is_loaded() {
    Some(gpu_image)
  } else {
    None
  }
}

///|
fn environment_map_light_insert_view_light_probe_info(
  render_view_light_probes : RenderViewLightProbes,
  environment_map_light : EnvironmentMapLight,
) -> Unit {
  guard environment_map_light.diffuse_map is Some(diffuse_map) else { return }
  guard environment_map_light.specular_map is Some(specular_map) else { return }
  guard environment_map_light_loaded_gpu_image(
      environment_map_light.diffuse_map,
    )
    is Some(_) else {
    return
  }
  guard environment_map_light_loaded_gpu_image(
      environment_map_light.specular_map,
    )
    is Some(specular_image) else {
    return
  }
  let cubemap_index = render_view_light_probes.get_or_insert_texture(
    LightProbeTextureId::environment_map(diffuse_map, specular_map),
  )
  render_view_light_probes.set_view_light_probe_info(
    EnvironmentMapViewLightProbeInfo::new(
      cubemap_index,
      specular_image.mip_level_count() - 1,
      environment_map_light.intensity,
      environment_map_light.affects_lightmapped_mesh_diffuse,
      environment_map_light.rotation,
    ),
  )
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
    return Single({
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
  Multiple({ diffuse_textures, specular_textures })
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
    return Single({
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
  Multiple({
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
