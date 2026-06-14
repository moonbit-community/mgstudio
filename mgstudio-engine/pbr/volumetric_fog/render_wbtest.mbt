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
fn volumetric_fog_wbtest_abs(value : Float) -> Float {
  if value < 0.0F {
    0.0F - value
  } else {
    value
  }
}

///|
fn volumetric_fog_wbtest_approx_eq(lhs : Float, rhs : Float) -> Bool {
  volumetric_fog_wbtest_abs(lhs - rhs) < 0.0001F
}

///|
fn volumetric_fog_wbtest_u32_at(bytes : Bytes, byte_offset : Int) -> UInt {
  (bytes[byte_offset].to_uint() & 0xFFU) |
  ((bytes[byte_offset + 1].to_uint() & 0xFFU) << 8) |
  ((bytes[byte_offset + 2].to_uint() & 0xFFU) << 16) |
  ((bytes[byte_offset + 3].to_uint() & 0xFFU) << 24)
}

///|
fn volumetric_fog_wbtest_f32_bits_at(bytes : Bytes, byte_offset : Int) -> UInt {
  volumetric_fog_wbtest_u32_at(bytes, byte_offset)
}

///|
test "pbr volumetric fog: uniform buffer prepare and clear" {
  let buffer = VolumetricFogUniformBuffer::VolumetricFogUniformBuffer()
  let fog = @light.VolumetricFog::VolumetricFog()
  let volume = @light.FogVolume::FogVolume()
  ignore(
    prepare_volumetric_fog_view_uniforms(
      buffer,
      fog,
      @math.Affine3::identity(),
      VolumetricFogMat4::identity(),
      [
        (volume, @math.Affine3::identity()),
        (
          volume,
          @math.Affine3::from_translation(@math.Vec3::new(-10.0F, 0.0F, 0.0F)),
        ),
      ],
    ),
  )
  inspect(buffer.count(), content="2")
  inspect(buffer.bytes().length(), content="1024")
  buffer.clear()
  inspect(buffer.count(), content="0")
}

///|
test "pbr volumetric fog: uniform bytes match WGSL host layout" {
  let buffer = VolumetricFogUniformBuffer::VolumetricFogUniformBuffer()
  let fog = @light.VolumetricFog::VolumetricFog()
    .with_step_count(96)
    .with_jitter(0.25F)
  let volume = @light.FogVolume::FogVolume().with_density_factor(0.75F)
  ignore(
    prepare_volumetric_fog_view_uniforms(
      buffer,
      fog,
      @math.Affine3::identity(),
      VolumetricFogMat4::identity(),
      [
        (
          volume,
          @math.Affine3::from_translation(@math.Vec3::new(-10.0F, 0.0F, 0.0F)),
        ),
      ],
    ),
  )
  let bytes = buffer.bytes()
  inspect(bytes.length(), content="512")
  inspect(
    volumetric_fog_wbtest_f32_bits_at(bytes, 0),
    content="\{1.0F.reinterpret_as_uint()}",
  )
  inspect(volumetric_fog_wbtest_u32_at(bytes, 224), content="\{96U}")
  inspect(
    volumetric_fog_wbtest_f32_bits_at(bytes, 240),
    content="\{0.75F.reinterpret_as_uint()}",
  )
  inspect(
    volumetric_fog_wbtest_f32_bits_at(bytes, 276),
    content="\{0.25F.reinterpret_as_uint()}",
  )
}

///|
test "pbr volumetric fog: prepares uniform data from Bevy source inputs" {
  let buffer = VolumetricFogUniformBuffer::VolumetricFogUniformBuffer()
  let fog = @light.VolumetricFog::VolumetricFog()
    .with_step_count(96)
    .with_jitter(0.25F)
  let volume = @light.FogVolume::FogVolume()
    .with_density_factor(0.75F)
    .with_density_texture_offset(@math.Vec3::new(0.0F, 0.0F, 1.25F))
  let prepared = prepare_volumetric_fog_view_uniforms(
    buffer,
    fog,
    @math.Affine3::identity(),
    VolumetricFogMat4::identity(),
    [(volume, @math.Affine3::identity())],
  )
  inspect(prepared.uniform_count, content="1")
  let bytes = buffer.bytes()
  inspect(volumetric_fog_wbtest_u32_at(bytes, 224), content="\{96U}")
  inspect(
    volumetric_fog_wbtest_f32_bits_at(bytes, 240),
    content="\{0.75F.reinterpret_as_uint()}",
  )
  inspect(
    volumetric_fog_wbtest_f32_bits_at(bytes, 256),
    content="\{0.0F.reinterpret_as_uint()}",
  )
  inspect(
    volumetric_fog_wbtest_f32_bits_at(bytes, 264),
    content="\{1.25F.reinterpret_as_uint()}",
  )
  inspect(
    volumetric_fog_wbtest_f32_bits_at(bytes, 276),
    content="\{0.25F.reinterpret_as_uint()}",
  )
}

///|
test "pbr volumetric fog: camera inside volume follows Bevy local cube test" {
  inspect(
    volumetric_fog_camera_is_inside(@math.Affine3::identity()),
    content="true",
  )
  inspect(
    volumetric_fog_camera_is_inside(
      @math.Affine3::from_translation(@math.Vec3::new(0.6F, 0.0F, 0.0F)),
    ),
    content="false",
  )
}

///|
test "pbr volumetric fog: far planes keep only view-facing cube faces" {
  let far_planes = volumetric_fog_far_planes(@math.Affine3::identity())
  inspect(far_planes.length(), content="3")
  inspect(
    volumetric_fog_wbtest_approx_eq(far_planes[0].x, 0.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[0].y, 0.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[0].z, 1.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[0].w, 0.5F),
    content="true",
  )
  inspect(
    volumetric_fog_wbtest_approx_eq(far_planes[1].x, 0.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[1].y, 0.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[1].z, 0.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[1].w, 0.0F),
    content="true",
  )
  inspect(
    volumetric_fog_wbtest_approx_eq(far_planes[2].x, 0.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[2].y, 0.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[2].z, 0.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[2].w, 0.0F),
    content="true",
  )
}
