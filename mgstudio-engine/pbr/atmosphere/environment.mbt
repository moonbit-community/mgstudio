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
// Bevy source: `bevy/crates/bevy_pbr/src/atmosphere/environment.rs`.

///|
pub type AtmosphereEnvironmentMapLight = @light.AtmosphereEnvironmentMapLight

///|
pub type GeneratedEnvironmentMapLight = @light.GeneratedEnvironmentMapLight

///|
pub struct AtmosphereEnvironmentMap {
  environment_map : @asset.Handle[@asset.Image]?
  size : @math.UVec2
}

///|
pub let ecs_key_atmosphere_environment_map : @ecs.ComponentKey[
  AtmosphereEnvironmentMap,
] = @ecs.register_component(debug_name="mgstudio_pbr::AtmosphereEnvironmentMap")

///|
pub impl @ecs.Component for AtmosphereEnvironmentMap with fn component() {
  ecs_key_atmosphere_environment_map
}

///|
pub fn AtmosphereEnvironmentMap::AtmosphereEnvironmentMap() -> AtmosphereEnvironmentMap {
  { environment_map: None, size: @math.UVec2::new(512, 512) }
}

///|
fn atmosphere_next_power_of_two(value : Int) -> Int {
  if value <= 1 {
    1
  } else {
    let mut out = 1
    while out < value {
      out = out * 2
    }
    out
  }
}

///|
pub fn pbr_validate_atmosphere_environment_map_size(
  size : @math.UVec2,
) -> @math.UVec2 {
  @math.UVec2::new(
    atmosphere_next_power_of_two(if size.x <= 0 { 1 } else { size.x }),
    atmosphere_next_power_of_two(if size.y <= 0 { 1 } else { size.y }),
  )
}

///|
pub fn pbr_atmosphere_environment_map(
  environment_map : @asset.Handle[@asset.Image]?,
  size : @math.UVec2,
) -> AtmosphereEnvironmentMap {
  { environment_map, size: pbr_validate_atmosphere_environment_map_size(size) }
}

///|
pub fn pbr_generated_environment_map_light_from_atmosphere(
  environment_map : @asset.Handle[@asset.Image]?,
  intensity : Float,
  affects_lightmapped_mesh_diffuse : Bool,
) -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight::new(environment_map, intensity).with_affects_lightmapped_mesh_diffuse(
    affects_lightmapped_mesh_diffuse,
  )
}

///|
pub fn pbr_atmosphere_environment_map_light_default() -> AtmosphereEnvironmentMapLight {
  AtmosphereEnvironmentMapLight()
}

///|
pub fn pbr_atmosphere_environment_map_light_new(
  intensity : Float,
  affects_lightmapped_mesh_diffuse : Bool,
  size : @math.UVec2,
) -> AtmosphereEnvironmentMapLight {
  AtmosphereEnvironmentMapLight::new(
    intensity, affects_lightmapped_mesh_diffuse, size,
  )
}

///|
pub fn pbr_atmosphere_environment_map_light_with_intensity(
  light : AtmosphereEnvironmentMapLight,
  intensity : Float,
) -> AtmosphereEnvironmentMapLight {
  light.with_intensity(intensity)
}

///|
pub fn AtmosphereEnvironmentMap::environment_map(
  self : AtmosphereEnvironmentMap,
) -> @asset.Handle[@asset.Image]? {
  self.environment_map
}

///|
pub fn AtmosphereEnvironmentMap::size(
  self : AtmosphereEnvironmentMap,
) -> @math.UVec2 {
  self.size
}

///|
fn pbr_atmosphere_environment_cube_byte_len(size : @math.UVec2) -> Int {
  size.x * size.y * 6 * 8
}

///|
fn pbr_atmosphere_environment_cube_image(size : @math.UVec2) -> @asset.Image {
  @asset.Image::new(
    size.x,
    size.y * 6,
    Bytes::new(pbr_atmosphere_environment_cube_byte_len(size)),
  )
  .with_format(Rgba16Float)
  .with_texture_usage_bits(
    @asset.IMAGE_USAGE_TEXTURE_BINDING |
    @asset.IMAGE_USAGE_STORAGE_BINDING |
    @asset.IMAGE_USAGE_COPY_SRC,
  )
  .with_array_layout(Some(RowCount(6)))
  .with_texture_view_dimension(Some(Cube))
}

///|
pub fn prepare_atmosphere_probe_components(world : @ecs.World) -> Unit {
  @asset.asset_with_world(world, fn() {
    let image_assets_key : @ecs.ResourceKey[@asset.Assets[@asset.Image]] = @asset.assets_resource_key()
    guard world.get_resource_mut(image_assets_key) is Some(images_ref) else {
      return
    }
    let probes : Array[(@core.Entity, AtmosphereEnvironmentMapLight)] = []
    world.for_each_component(@light.ecs_key_atmosphere_environment_map_light, fn(
      entity,
      env_map_light,
    ) {
      if (try! world.contains_by_key(entity, ecs_key_atmosphere_environment_map)) {
        return
      }
      probes.push((entity, env_map_light))
    })
    if probes.length() == 0 {
      return
    }
    for probe in probes {
      let (entity, env_map_light) = probe
      let size = pbr_validate_atmosphere_environment_map_size(
        env_map_light.size,
      )
      let environment_handle = images_ref.modify(fn(images) {
        images.add(pbr_atmosphere_environment_cube_image(size))
      })
      try! world.set_by_key(entity, ecs_key_atmosphere_environment_map, {
        environment_map: Some(environment_handle),
        size,
      })
      try! world.set_by_key(
        entity,
        @light.ecs_key_generated_environment_map_light,
        pbr_generated_environment_map_light_from_atmosphere(
          Some(environment_handle),
          env_map_light.intensity,
          env_map_light.affects_lightmapped_mesh_diffuse,
        ),
      )
    }
  })
}
