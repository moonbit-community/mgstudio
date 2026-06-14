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
test "pbr volumetric fog execute: extracts lights and globally transformed fog volumes" {
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
  inspect(volumes[0].1.translation.x, content="4")
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
  let row_major = converted.to_row_major_array()
  inspect(row_major[0], content="1")
  inspect(row_major[1], content="5")
  inspect(row_major[4], content="2")
  inspect(row_major[15], content="16")
}

///|
test "pbr volumetric fog execute: stores view component and clears shared uniform buffer" {
  let world = @ecs.World::new()
  let buffer = render3d_volumetric_fog_uniform_buffer_mut(world)
  ignore(
    buffer.modify(fn(uniform_buffer) {
      uniform_buffer.push(
        @pbr_volumetric_fog.VolumetricFogUniform::VolumetricFogUniform(),
      )
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
  let view_fog = @pbr_volumetric_fog.ViewVolumetricFog::ViewVolumetricFog()
  view_fog.push(@pbr_volumetric_fog.ViewFogVolume::ViewFogVolume())
  render3d_write_volumetric_fog_view_components(world, view_entity, Render3dVolumetricFogPrepareOutput::{
    view_fog,
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
