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
test "pbr volumetric fog: pipeline selection by density texture flag" {
  let pipelines = view_volumetric_fog_pipelines(11, 29)
  let key_without_texture = volumetric_fog_pipeline_key(false, 1, false)
  let key_with_texture = volumetric_fog_pipeline_key(true, 4, true)
  inspect(
    volumetric_fog_select_pipeline(pipelines, key_without_texture),
    content="11",
  )
  inspect(
    volumetric_fog_select_pipeline(pipelines, key_with_texture),
    content="29",
  )
}

///|
test "pbr volumetric fog: uniform buffer push and clear" {
  let buffer = @volumetric_fog.VolumetricFogUniformBuffer::VolumetricFogUniformBuffer()
  let offset0 = buffer.push(
    @volumetric_fog.VolumetricFogUniform::VolumetricFogUniform(),
  )
  let offset1 = buffer.push(
    @volumetric_fog.VolumetricFogUniform::VolumetricFogUniform().with_step_count(
      96,
    ),
  )
  inspect(offset0, content="0")
  inspect(offset1, content="1")
  inspect(buffer.count(), content="2")
  buffer.clear()
  inspect(buffer.count(), content="0")
}

///|
test "pbr volumetric fog: camera inside volume follows Bevy local cube test" {
  inspect(
    @volumetric_fog.volumetric_fog_camera_is_inside(@math.Affine3::identity()),
    content="true",
  )
  inspect(
    @volumetric_fog.volumetric_fog_camera_is_inside(
      @math.Affine3::from_translation(@math.Vec3::new(0.6F, 0.0F, 0.0F)),
    ),
    content="false",
  )
}

///|
test "pbr volumetric fog: far planes keep only view-facing cube faces" {
  let far_planes = @volumetric_fog.volumetric_fog_far_planes(
    @math.Affine3::identity(),
  )
  inspect(far_planes.length(), content="3")
  inspect(
    volumetric_fog_test_approx_eq(far_planes[0].x, 0.0F) &&
    volumetric_fog_test_approx_eq(far_planes[0].y, 0.0F) &&
    volumetric_fog_test_approx_eq(far_planes[0].z, 1.0F) &&
    volumetric_fog_test_approx_eq(far_planes[0].w, 0.5F),
    content="true",
  )
  inspect(
    volumetric_fog_test_approx_eq(far_planes[1].x, 0.0F) &&
    volumetric_fog_test_approx_eq(far_planes[1].y, 0.0F) &&
    volumetric_fog_test_approx_eq(far_planes[1].z, 0.0F) &&
    volumetric_fog_test_approx_eq(far_planes[1].w, 0.0F),
    content="true",
  )
  inspect(
    volumetric_fog_test_approx_eq(far_planes[2].x, 0.0F) &&
    volumetric_fog_test_approx_eq(far_planes[2].y, 0.0F) &&
    volumetric_fog_test_approx_eq(far_planes[2].z, 0.0F) &&
    volumetric_fog_test_approx_eq(far_planes[2].w, 0.0F),
    content="true",
  )
}

///|
test "pbr volumetric fog: prepares view volume metadata and uniforms" {
  let buffer = @volumetric_fog.VolumetricFogUniformBuffer::VolumetricFogUniformBuffer()
  let fog = @volumetric_fog.volumetric_fog_default_settings()
    .with_step_count(96)
    .with_jitter(0.25F)
  let density_texture : @asset.Handle[@asset.Image] = @asset.Handle::new(42)
  let volume = @volumetric_fog.fog_volume_default_settings()
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
