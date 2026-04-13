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
// Bevy source: `bevy/crates/bevy_pbr/src/volumetric_fog/render.rs`.

///|
fn volumetric_fog_sanitize_non_negative(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn volumetric_fog_sanitize_int(value : Int, min_ : Int) -> Int {
  if value < min_ {
    min_
  } else {
    value
  }
}

///|
fn volumetric_fog_identity_matrix_row_major() -> Array[Float] {
  [
    1.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F,
    0.0F, 0.0F, 1.0F,
  ]
}

///|
pub struct VolumetricFogBindGroupLayoutKey {
  multisampled : Bool
  density_texture : Bool
}

///|
pub fn VolumetricFogBindGroupLayoutKey::default() -> VolumetricFogBindGroupLayoutKey {
  VolumetricFogBindGroupLayoutKey::{
    multisampled: false,
    density_texture: false,
  }
}

///|
pub fn volumetric_fog_bind_group_layout_index(
  key : VolumetricFogBindGroupLayoutKey,
) -> Int {
  let mut bits = 0
  if key.multisampled {
    bits = bits | 1
  }
  if key.density_texture {
    bits = bits | 2
  }
  bits
}

///|
pub struct VolumetricFogPipelineKeyFlags {
  hdr : Bool
  density_texture : Bool
}

///|
pub fn VolumetricFogPipelineKeyFlags::default() -> VolumetricFogPipelineKeyFlags {
  VolumetricFogPipelineKeyFlags::{ hdr: false, density_texture: false }
}

///|
pub struct VolumetricFogPipelineKey {
  msaa_samples : Int
  flags : VolumetricFogPipelineKeyFlags
}

///|
pub fn VolumetricFogPipelineKey::default() -> VolumetricFogPipelineKey {
  VolumetricFogPipelineKey::{
    msaa_samples: 1,
    flags: VolumetricFogPipelineKeyFlags::default(),
  }
}

///|
pub struct VolumetricFogPipeline {
  shader_label : String
  bind_group_layout_count : Int
}

///|
pub fn VolumetricFogPipeline::default() -> VolumetricFogPipeline {
  VolumetricFogPipeline::{
    shader_label: "pbr/volumetric_fog.wgsl",
    bind_group_layout_count: 4,
  }
}

///|
pub struct ViewVolumetricFogPipelines {
  textureless : Int
  textured : Int
}

///|
pub fn ViewVolumetricFogPipelines::default() -> ViewVolumetricFogPipelines {
  ViewVolumetricFogPipelines::{ textureless: -1, textured: -1 }
}

///|
pub fn view_volumetric_fog_pipelines(
  textureless : Int,
  textured : Int,
) -> ViewVolumetricFogPipelines {
  ViewVolumetricFogPipelines::{ textureless, textured }
}

///|
pub struct VolumetricFogUniform {
  clip_from_local_row_major : Array[Float]
  uvw_from_world_row_major : Array[Float]
  far_planes : Array[@math.Vec4]
  fog_color : @math.Vec3
  light_tint : @math.Vec3
  ambient_color : @math.Vec3
  ambient_intensity : Float
  step_count : Int
  bounding_radius : Float
  absorption : Float
  scattering : Float
  density : Float
  density_texture_offset : @math.Vec3
  scattering_asymmetry : Float
  light_intensity : Float
  jitter_strength : Float
}

///|
pub fn VolumetricFogUniform::default() -> VolumetricFogUniform {
  VolumetricFogUniform::{
    clip_from_local_row_major: volumetric_fog_identity_matrix_row_major(),
    uvw_from_world_row_major: volumetric_fog_identity_matrix_row_major(),
    far_planes: [
      @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    ],
    fog_color: @math.Vec3::new(1.0F, 1.0F, 1.0F),
    light_tint: @math.Vec3::new(1.0F, 1.0F, 1.0F),
    ambient_color: @math.Vec3::new(1.0F, 1.0F, 1.0F),
    ambient_intensity: 0.1F,
    step_count: 64,
    bounding_radius: 1.0F,
    absorption: 0.3F,
    scattering: 0.3F,
    density: 0.1F,
    density_texture_offset: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    scattering_asymmetry: 0.0F,
    light_intensity: 1.0F,
    jitter_strength: 0.0F,
  }
}

///|
pub fn VolumetricFogUniform::with_step_count(
  self : VolumetricFogUniform,
  step_count : Int,
) -> VolumetricFogUniform {
  VolumetricFogUniform::{
    ..self,
    step_count: volumetric_fog_sanitize_int(step_count, 1),
  }
}

///|
pub fn VolumetricFogUniform::with_density(
  self : VolumetricFogUniform,
  density : Float,
) -> VolumetricFogUniform {
  VolumetricFogUniform::{
    ..self,
    density: volumetric_fog_sanitize_non_negative(density),
  }
}

///|
pub fn VolumetricFogUniform::with_jitter_strength(
  self : VolumetricFogUniform,
  jitter_strength : Float,
) -> VolumetricFogUniform {
  VolumetricFogUniform::{
    ..self,
    jitter_strength: volumetric_fog_sanitize_non_negative(jitter_strength),
  }
}

///|
pub struct ViewFogVolume {
  density_texture : @asset.Handle[@asset.Image]?
  uniform_buffer_offset : Int
  exterior : Bool
}

///|
pub fn ViewFogVolume::default() -> ViewFogVolume {
  ViewFogVolume::{
    density_texture: None,
    uniform_buffer_offset: 0,
    exterior: true,
  }
}

///|
pub fn ViewFogVolume::has_density_texture(self : ViewFogVolume) -> Bool {
  self.density_texture is Some(_)
}

///|
pub struct ViewVolumetricFog {
  volumes : Array[ViewFogVolume]
}

///|
pub fn ViewVolumetricFog::default() -> ViewVolumetricFog {
  ViewVolumetricFog::{ volumes: [] }
}

///|
pub fn ViewVolumetricFog::push(
  self : ViewVolumetricFog,
  volume : ViewFogVolume,
) -> Unit {
  self.volumes.push(volume)
}

///|
pub fn ViewVolumetricFog::count(self : ViewVolumetricFog) -> Int {
  self.volumes.length()
}

///|
pub struct VolumetricFogUniformBuffer {
  mut uniforms : Array[VolumetricFogUniform]
}

///|
pub fn VolumetricFogUniformBuffer::default() -> VolumetricFogUniformBuffer {
  VolumetricFogUniformBuffer::{ uniforms: [] }
}

///|
pub fn VolumetricFogUniformBuffer::clear(
  self : VolumetricFogUniformBuffer,
) -> Unit {
  self.uniforms = []
}

///|
pub fn VolumetricFogUniformBuffer::push(
  self : VolumetricFogUniformBuffer,
  uniform : VolumetricFogUniform,
) -> Int {
  let offset = self.uniforms.length()
  self.uniforms.push(uniform)
  offset
}

///|
pub fn VolumetricFogUniformBuffer::count(
  self : VolumetricFogUniformBuffer,
) -> Int {
  self.uniforms.length()
}

///|
pub fn volumetric_fog_pipeline_key(
  is_hdr : Bool,
  msaa_samples : Int,
  has_density_texture : Bool,
) -> VolumetricFogPipelineKey {
  VolumetricFogPipelineKey::{
    msaa_samples: volumetric_fog_sanitize_int(msaa_samples, 1),
    flags: VolumetricFogPipelineKeyFlags::{
      hdr: is_hdr,
      density_texture: has_density_texture,
    },
  }
}

///|
pub fn volumetric_fog_select_pipeline(
  pipelines : ViewVolumetricFogPipelines,
  key : VolumetricFogPipelineKey,
) -> Int {
  if key.flags.density_texture {
    pipelines.textured
  } else {
    pipelines.textureless
  }
}

///|
pub fn volumetric_fog_default_settings() -> VolumetricFog {
  VolumetricFog::default()
}

///|
pub fn fog_volume_default_settings() -> FogVolume {
  FogVolume::default()
}

///|
pub fn volumetric_fog_with_step_count(
  fog : VolumetricFog,
  step_count : Int,
) -> VolumetricFog {
  fog.with_step_count(step_count)
}

///|
pub fn fog_volume_with_density(
  volume : FogVolume,
  density_factor : Float,
) -> FogVolume {
  volume.with_density_factor(density_factor)
}
