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
// Bevy source: `bevy/crates/bevy_pbr/src/light_probe/generate.rs`.

///|
const ENVIRONMENT_MAP_GENERATION_PLUGIN_NAME : String = "mgstudio.pbr.light_probe.EnvironmentMapGenerationPlugin"

///|
pub type GeneratedEnvironmentMapLight = @light.GeneratedEnvironmentMapLight

///|
pub struct GeneratorBindGroupLayouts {
  downsampling_first : String
  downsampling_second : String
  radiance : String
  irradiance : String
  copy : String
}

///|
pub fn GeneratorBindGroupLayouts::GeneratorBindGroupLayouts() -> GeneratorBindGroupLayouts {
  GeneratorBindGroupLayouts::{
    downsampling_first: "downsampling_first_bind_group_layout",
    downsampling_second: "downsampling_second_bind_group_layout",
    radiance: "radiance_bind_group_layout",
    irradiance: "irradiance_bind_group_layout",
    copy: "copy_bind_group_layout",
  }
}

///|
pub struct GeneratorSamplers {
  linear : String
}

///|
pub fn GeneratorSamplers::GeneratorSamplers() -> GeneratorSamplers {
  GeneratorSamplers::{ linear: "generator_linear_sampler" }
}

///|
pub struct GeneratorPipelines {
  downsample_first : Int
  downsample_second : Int
  copy : Int
  radiance : Int
  irradiance : Int
}

///|
pub fn GeneratorPipelines::GeneratorPipelines() -> GeneratorPipelines {
  GeneratorPipelines::{
    downsample_first: -1,
    downsample_second: -1,
    copy: -1,
    radiance: -1,
    irradiance: -1,
  }
}

///|
pub struct DownsamplingConfig {
  combine_bind_group : Bool
}

///|
pub fn DownsamplingConfig::DownsamplingConfig() -> DownsamplingConfig {
  DownsamplingConfig::{ combine_bind_group: false }
}

///|
pub fn DownsamplingConfig::combine_bind_group_enabled(
  self : DownsamplingConfig,
) -> Bool {
  self.combine_bind_group
}

///|
pub fn pbr_generated_environment_map_light_default() -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight()
}

///|
pub struct EnvironmentMapGenerationPlugin {}

///|
pub fn EnvironmentMapGenerationPlugin::EnvironmentMapGenerationPlugin() -> EnvironmentMapGenerationPlugin {
  EnvironmentMapGenerationPlugin::{  }
}

///|
pub impl @app.Plugin for EnvironmentMapGenerationPlugin with fn name(_self) {
  ENVIRONMENT_MAP_GENERATION_PLUGIN_NAME
}

///|
pub impl @app.Plugin for EnvironmentMapGenerationPlugin with fn build(self, app) {
  register_embedded_wgsl_sources()
  ignore(self)
  app.add_systems_world(@app.Update, generate_environment_map_light)
}

///|
pub fn pbr_downsampling_config(
  max_storage_textures_per_shader_stage : Int,
  supports_read_write_storage_texture : Bool,
) -> DownsamplingConfig {
  DownsamplingConfig::{
    combine_bind_group: max_storage_textures_per_shader_stage >= 12 &&
    supports_read_write_storage_texture,
  }
}

///|
pub fn pbr_generated_environment_map_light_new() -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight::new(None, 1.0F)
}

///|
pub fn pbr_generated_environment_map_light_with_intensity(
  light : GeneratedEnvironmentMapLight,
  intensity : Float,
) -> GeneratedEnvironmentMapLight {
  light.with_intensity(intensity)
}

///|
fn pbr_generated_environment_map_compute_mip_count(size : Int) -> Int {
  let mut safe_size = if size <= 0 { 1 } else { size }
  let mut count = 1
  while safe_size > 1 {
    safe_size = safe_size / 2
    count = count + 1
  }
  count
}

///|
fn pbr_generated_environment_map_is_power_of_two(size : Int) -> Bool {
  if size <= 0 {
    false
  } else {
    let value = size.reinterpret_as_uint()
    (value & (value - 1U)) == 0U
  }
}

///|
fn pbr_generated_environment_map_face_height(image : @asset.Image) -> Int? {
  match image.array_layout() {
    Some(@asset.ImageArrayLayout::RowCount(6)) => Some(image.height() / 6)
    Some(@asset.ImageArrayLayout::RowHeight(height)) => Some(height)
    _ => Some(image.height())
  }
}

///|
fn pbr_generated_environment_map_validate_source(image : @asset.Image) -> Int? {
  let base_size = image.width()
  guard pbr_generated_environment_map_face_height(image) is Some(height) else {
    return None
  }
  if height != base_size ||
    !pbr_generated_environment_map_is_power_of_two(base_size) ||
    base_size > 8192 {
    abort(
      "GeneratedEnvironmentMapLight source cubemap must be square power-of-two <= 8192, got \{base_size}x\{height}",
    )
  }
  Some(base_size)
}

///|
fn pbr_generated_environment_map_cube_image(
  size : Int,
  mip_level_count : Int,
  usage_bits : Int,
) -> @asset.Image {
  @asset.Image::new(size, size * 6, Bytes::new(size * size * 6 * 8))
  .with_format(@asset.TextureFormat::Rgba16Float)
  .with_texture_usage_bits(usage_bits)
  .with_array_layout(Some(@asset.ImageArrayLayout::RowCount(6)))
  .with_texture_view_dimension(Some(@asset.ImageTextureViewDimension::Cube))
  .with_mip_level_count(mip_level_count)
}

///|
pub fn generate_environment_map_light(world : @ecs.World) -> Unit {
  @asset.asset_with_world(world, fn() {
    let image_assets_key : @ecs.ResourceKey[@asset.Assets[@asset.Image]] = @asset.assets_resource_key()
    guard world.get_resource_mut(image_assets_key) is Some(images_ref) else {
      return
    }
    let generated_lights : Array[(@core.Entity, GeneratedEnvironmentMapLight)] = []
    world.for_each_component(@light.ecs_key_generated_environment_map_light, fn(
      entity,
      generated,
    ) {
      if (try! world.contains_by_key(
          entity, @light.ecs_key_environment_map_light,
        )) {
        return
      }
      generated_lights.push((entity, generated))
    })
    for entry in generated_lights {
      let (entity, generated) = entry
      guard generated.environment_map is Some(environment_map) else { continue }
      let source = images_ref.modify(fn(images) { images.get(environment_map) })
      guard source is Some(source_image) else { continue }
      guard pbr_generated_environment_map_validate_source(source_image)
        is Some(base_size) else {
        continue
      }
      let mip_count = pbr_generated_environment_map_compute_mip_count(base_size)
      let usage_bits = @asset.IMAGE_USAGE_TEXTURE_BINDING |
        @asset.IMAGE_USAGE_STORAGE_BINDING
      let (diffuse_handle, specular_handle) = images_ref.modify(fn(images) {
        let diffuse = images.add(
          pbr_generated_environment_map_cube_image(32, 1, usage_bits),
        )
        let specular = images.add(
          pbr_generated_environment_map_cube_image(
            base_size, mip_count, usage_bits,
          ),
        )
        (diffuse, specular)
      })
      try! world.set_by_key(
        entity,
        @light.ecs_key_environment_map_light,
        @light.EnvironmentMapLight::new(
          Some(diffuse_handle),
          Some(specular_handle),
          generated.intensity,
        )
        .with_rotation(generated.rotation)
        .with_affects_lightmapped_mesh_diffuse(
          generated.affects_lightmapped_mesh_diffuse,
        ),
      )
    }
  })
}
