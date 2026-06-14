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
fn volumetric_fog_test_abs(value : Float) -> Float {
  if value < 0.0F {
    0.0F - value
  } else {
    value
  }
}

///|
fn volumetric_fog_test_approx_eq(lhs : Float, rhs : Float) -> Bool {
  volumetric_fog_test_abs(lhs - rhs) < 0.0001F
}

///|
fn volumetric_fog_test_u32_at(bytes : Bytes, byte_offset : Int) -> UInt {
  (bytes[byte_offset].to_uint() & 0xFFU) |
  ((bytes[byte_offset + 1].to_uint() & 0xFFU) << 8) |
  ((bytes[byte_offset + 2].to_uint() & 0xFFU) << 16) |
  ((bytes[byte_offset + 3].to_uint() & 0xFFU) << 24)
}

///|
fn volumetric_fog_test_f32_bits_at(bytes : Bytes, byte_offset : Int) -> UInt {
  volumetric_fog_test_u32_at(bytes, byte_offset)
}

///|
test "pbr volumetric fog: uniform buffer push and clear" {
  let buffer = @volumetric_fog.VolumetricFogUniformBuffer::VolumetricFogUniformBuffer()
  let offset0 = buffer.push(
    @volumetric_fog.VolumetricFogUniform::VolumetricFogUniform(),
  )
  let offset1 = buffer.push(
    @volumetric_fog.VolumetricFogUniform::VolumetricFogUniform(),
  )
  inspect(offset0, content="0")
  inspect(offset1, content="512")
  inspect(buffer.count(), content="2")
  inspect(buffer.bytes().length(), content="1024")
  buffer.clear()
  inspect(buffer.count(), content="0")
}

///|
test "pbr volumetric fog: uniform bytes match WGSL host layout" {
  let buffer = @volumetric_fog.VolumetricFogUniformBuffer::VolumetricFogUniformBuffer()
  let fog = @light.VolumetricFog::VolumetricFog()
    .with_step_count(96)
    .with_jitter(0.25F)
  let volume = @light.FogVolume::FogVolume().with_density_factor(0.75F)
  ignore(
    @volumetric_fog.prepare_volumetric_fog_view_uniforms(
      buffer,
      fog,
      @math.Affine3::identity(),
      @volumetric_fog.VolumetricFogMat4::identity(),
      [
        (
          volume,
          @math.Affine3::from_translation(@math.Vec3::new(10.0F, 0.0F, 0.0F)),
        ),
      ],
    ),
  )
  let uniform = buffer.uniform_at(0).unwrap()
  let bytes = uniform.bytes()
  inspect(bytes.length(), content="288")
  inspect(
    volumetric_fog_test_f32_bits_at(bytes, 0),
    content="\{1.0F.reinterpret_as_uint()}",
  )
  inspect(volumetric_fog_test_u32_at(bytes, 224), content="\{96U}")
  inspect(
    volumetric_fog_test_f32_bits_at(bytes, 240),
    content="\{0.75F.reinterpret_as_uint()}",
  )
  inspect(
    volumetric_fog_test_f32_bits_at(bytes, 276),
    content="\{0.25F.reinterpret_as_uint()}",
  )
}

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
  match buffer.uniform_at(0) {
    Some(uniform) => {
      inspect(uniform.step_count, content="96")
      inspect(uniform.density, content="0.75")
      inspect(
        volumetric_fog_test_approx_eq(uniform.density_texture_offset.x, 0.0F) &&
        volumetric_fog_test_approx_eq(uniform.density_texture_offset.y, 0.0F) &&
        volumetric_fog_test_approx_eq(uniform.density_texture_offset.z, 1.25F),
        content="true",
      )
      inspect(uniform.jitter_strength, content="0.25")
      inspect(
        volumetric_fog_test_approx_eq(uniform.bounding_radius, 0.8660254F),
        content="true",
      )
    }
    None => inspect("missing", content="uniform")
  }
}
