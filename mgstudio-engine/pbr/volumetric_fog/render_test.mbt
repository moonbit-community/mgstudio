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
test "pbr volumetric fog: matrices pack in WGSL column order" {
  let matrix = @volumetric_fog.VolumetricFogMat4::from_cols(
    @math.Vec4::new(1.0F, 2.0F, 3.0F, 4.0F),
    @math.Vec4::new(5.0F, 6.0F, 7.0F, 8.0F),
    @math.Vec4::new(9.0F, 10.0F, 11.0F, 12.0F),
    @math.Vec4::new(13.0F, 14.0F, 15.0F, 16.0F),
  )
  debug_inspect(
    matrix.to_cols_array(),
    content="[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]",
  )
}

///|
test "pbr volumetric fog: prepares view volume metadata and uniforms" {
  let buffer = @volumetric_fog.VolumetricFogUniformBuffer::VolumetricFogUniformBuffer()
  let fog = @light.VolumetricFog::VolumetricFog()
    .with_step_count(96)
    .with_jitter(0.25F)
  let density_texture : @asset.Handle[@asset.Image] = @asset.Handle::new(42)
  let volume = @light.FogVolume::FogVolume()
    .with_density_factor(0.75F)
    .with_density_texture(Some(density_texture))
    .with_density_texture_offset(@math.Vec3::new(0.0F, 0.0F, 1.25F))
  let prepared = @volumetric_fog.prepare_volumetric_fog_view_uniforms(
    buffer,
    fog,
    @math.Affine3::identity(),
    @volumetric_fog.VolumetricFogMat4::identity(),
    [(volume, @math.Affine3::identity())],
  )
  inspect(prepared.uniform_count, content="1")
  inspect(prepared.view_fog.count(), content="1")
  inspect(prepared.view_fog.volumes[0].exterior, content="false")
  inspect(prepared.view_fog.volumes[0].has_density_texture(), content="true")
  inspect(buffer.count(), content="1")
  inspect(buffer.bytes().length(), content="512")
}
