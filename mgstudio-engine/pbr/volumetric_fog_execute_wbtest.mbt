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
fn render3d_volumetric_fog_wbtest_identity_mat4() -> @pbr_volumetric_fog.VolumetricFogMat4 {
  @pbr_volumetric_fog.VolumetricFogMat4::from_cols(
    @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 0.0F, 1.0F),
  )
}

///|
fn render3d_volumetric_fog_wbtest_u32_at(
  bytes : Bytes,
  byte_offset : Int,
) -> UInt {
  (bytes[byte_offset].to_uint() & 0xFFU) |
  ((bytes[byte_offset + 1].to_uint() & 0xFFU) << 8) |
  ((bytes[byte_offset + 2].to_uint() & 0xFFU) << 16) |
  ((bytes[byte_offset + 3].to_uint() & 0xFFU) << 24)
}

///|
test "pbr volumetric fog execute: extracts lights and precomputes local-from-world fog volume transforms" {
  let world = @ecs.World::new()
  let light_entity = world.spawn()
  try! (world.set_by_key(
    light_entity,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::VolumetricLight(),
  )
  |> ignore)
  let skipped_volume_entity = world.spawn()
  try! (world.set_by_key(
    skipped_volume_entity,
    @light.ecs_key_fog_volume,
    @light.FogVolume::FogVolume().with_density_factor(2.0F),
  )
  |> ignore)
  let extracted_volume_entity = world.spawn()
  try! (world.set_by_key(
    extracted_volume_entity,
    @light.ecs_key_fog_volume,
    @light.FogVolume::FogVolume().with_density_factor(3.0F),
  )
  |> ignore)
  try! (world.set_by_key(
    extracted_volume_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_translation(@math.Vec3::new(4.0F, 5.0F, 6.0F)),
    ),
  )
  |> ignore)

  let volumes = render3d_collect_fog_volumes(world)
  inspect(render3d_collect_volumetric_light_count(world), content="1")
  inspect(volumes.length(), content="1")
  inspect(volumes[0].0.density_factor, content="3")
  inspect(volumes[0].1.translation.x, content="-4")
}

///|
test "pbr volumetric fog execute: converts clip projection columns without transposing" {
  let projection = @pbr_render.ProjectionMatrix3d::from_cols(
    @math.Vec4::new(1.0F, 2.0F, 3.0F, 4.0F),
    @math.Vec4::new(5.0F, 6.0F, 7.0F, 8.0F),
    @math.Vec4::new(9.0F, 10.0F, 11.0F, 12.0F),
    @math.Vec4::new(13.0F, 14.0F, 15.0F, 16.0F),
  )
  let converted = render3d_projection_matrix_to_volumetric_mat4(projection)
  let buffer = @pbr_volumetric_fog.VolumetricFogUniformBuffer::VolumetricFogUniformBuffer()
  ignore(
    @pbr_volumetric_fog.prepare_volumetric_fog_view_uniforms(
      buffer,
      @light.VolumetricFog::VolumetricFog(),
      @math.Affine3::identity(),
      converted,
      [(@light.FogVolume::FogVolume(), @math.Affine3::identity())],
    ),
  )
  inspect(
    render3d_volumetric_fog_wbtest_u32_at(buffer.bytes(), 0),
    content="\{15.0F.reinterpret_as_uint()}",
  )
}

///|
test "pbr volumetric fog execute: stores view component and clears shared uniform buffer" {
  let world = @ecs.World::new()
  let buffer = render3d_volumetric_fog_uniform_buffer_mut(world)
  ignore(
    buffer.modify(fn(uniform_buffer) {
      @pbr_volumetric_fog.prepare_volumetric_fog_view_uniforms(
        uniform_buffer,
        @light.VolumetricFog::VolumetricFog(),
        @math.Affine3::identity(),
        render3d_volumetric_fog_wbtest_identity_mat4(),
        [(@light.FogVolume::FogVolume(), @math.Affine3::identity())],
      )
      |> ignore
    }),
  )
  inspect(
    world
    .get_resource(@pbr_volumetric_fog.VolumetricFogUniformBuffer::resource())
    .unwrap()
    .count(),
    content="1",
  )
  render3d_reset_volumetric_fog_uniform_buffer(world)
  inspect(
    world
    .get_resource(@pbr_volumetric_fog.VolumetricFogUniformBuffer::resource())
    .unwrap()
    .count(),
    content="0",
  )

  let view_entity = world.spawn()
  let view_fog = render3d_volumetric_fog_uniform_buffer_mut(world).modify(fn(
    uniform_buffer,
  ) {
    @pbr_volumetric_fog.prepare_volumetric_fog_view_uniforms(
      uniform_buffer,
      @light.VolumetricFog::VolumetricFog(),
      @math.Affine3::identity(),
      render3d_volumetric_fog_wbtest_identity_mat4(),
      [(@light.FogVolume::FogVolume(), @math.Affine3::identity())],
    )
  })
  render3d_write_volumetric_fog_view_components(world, view_entity, Render3dVolumetricFogPrepareOutput::{
    view_fog: Some(view_fog),
    view_count: 1,
    volume_count: 1,
    light_count: 1,
    uniform_count: 1,
    plane_mesh_id: -1,
    cube_mesh_id: -1,
  })
  inspect(
    render3d_volumetric_fog_view_volume_count(world, view_entity),
    content="1",
  )
  render3d_write_volumetric_fog_pipeline_components(
    world,
    view_entity,
    Some(@pbr_volumetric_fog.ViewVolumetricFogPipelines::{
      textureless: 11,
      textured: 29,
    }),
  )
  match
    (try! world.get_by_key(
      view_entity,
      @pbr_volumetric_fog.ViewVolumetricFogPipelines::component(),
    )) {
    Some(pipelines) => {
      inspect(pipelines.textureless, content="11")
      inspect(pipelines.textured, content="29")
    }
    None => fail("expected ViewVolumetricFogPipelines")
  }
  render3d_write_volumetric_fog_pipeline_components(world, view_entity, None)
  assert_true(
    (try! world.get_by_key(
      view_entity,
      @pbr_volumetric_fog.ViewVolumetricFogPipelines::component(),
    ))
    is None,
  )
  render3d_write_volumetric_fog_view_components(
    world,
    view_entity,
    Render3dVolumetricFogPrepareOutput::Render3dVolumetricFogPrepareOutput(),
  )
  inspect(
    render3d_volumetric_fog_view_volume_count(world, view_entity),
    content="0",
  )
}

///|
test "pbr volumetric fog execute: prepares both Bevy pipeline variants per fog view" {
  let inactive = Render3dVolumetricFogPrepareOutput::{
    ..Render3dVolumetricFogPrepareOutput::Render3dVolumetricFogPrepareOutput(),
    view_count: 1,
    light_count: 1,
    plane_mesh_id: -1,
  }
  debug_inspect(
    render3d_volumetric_fog_pipeline_variants(inactive),
    content="(false, false)",
  )
  let active = Render3dVolumetricFogPrepareOutput::{
    ..Render3dVolumetricFogPrepareOutput::Render3dVolumetricFogPrepareOutput(),
    view_count: 1,
    light_count: 1,
    plane_mesh_id: 7,
  }
  debug_inspect(
    render3d_volumetric_fog_pipeline_variants(active),
    content="(true, true)",
  )
  assert_true(render3d_volumetric_fog_should_prepare_hull_meshes(active))
  let view_without_volume = Render3dVolumetricFogPrepareOutput::{
    ..Render3dVolumetricFogPrepareOutput::Render3dVolumetricFogPrepareOutput(),
    view_count: 1,
    volume_count: 0,
    light_count: 1,
    plane_mesh_id: -1,
  }
  assert_true(
    render3d_volumetric_fog_should_prepare_hull_meshes(view_without_volume),
  )
}

///|
test "pbr volumetric fog execute: prepares depth texture usage from extracted fog views" {
  let world = @ecs.World::new()
  let camera3d = Camera3d::Camera3d()
  assert_false(camera3d.depth_texture_usages().has_texture_binding())
  assert_false(render3d_world_has_volumetric_fog_views(world))
  assert_false(
    render3d_prepare_view_depth_texture_usage_for_volumetric_fog(
      camera3d,
      render3d_world_has_volumetric_fog_views(world),
    ).has_texture_binding(),
  )

  let entity = world.spawn()
  try! (world.set_by_key(
    entity,
    ecs_key_volumetric_fog,
    VolumetricFog::VolumetricFog(),
  )
  |> ignore)
  assert_false(render3d_world_has_volumetric_fog_views(world))
  assert_false(
    render3d_prepare_view_depth_texture_usage_for_volumetric_fog(
      camera3d,
      render3d_world_has_volumetric_fog_views(world),
    ).has_texture_binding(),
  )
  let light_entity = world.spawn()
  try! (world.set_by_key(
    light_entity,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::VolumetricLight(),
  )
  |> ignore)
  assert_true(render3d_world_has_volumetric_fog_views(world))
  assert_true(
    render3d_prepare_view_depth_texture_usage_for_volumetric_fog(
      camera3d,
      render3d_world_has_volumetric_fog_views(world),
    ).has_texture_binding(),
  )
}
