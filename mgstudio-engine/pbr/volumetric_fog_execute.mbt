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
priv struct Render3dVolumetricFogPrepareOutput {
  view_fog : @pbr_volumetric_fog.ViewVolumetricFog
  view_count : Int
  volume_count : Int
  light_count : Int
  uniform_count : Int
}

///|
fn Render3dVolumetricFogPrepareOutput::Render3dVolumetricFogPrepareOutput() -> Render3dVolumetricFogPrepareOutput {
  Render3dVolumetricFogPrepareOutput::{
    view_fog: @pbr_volumetric_fog.ViewVolumetricFog::ViewVolumetricFog(),
    view_count: 0,
    volume_count: 0,
    light_count: 0,
    uniform_count: 0,
  }
}

///|
fn render3d_volumetric_fog_uniform_buffer_mut(
  world : @ecs.World,
) -> @ecs.ResourceMut[@pbr_volumetric_fog.VolumetricFogUniformBuffer] {
  if world.get_resource(
      @pbr_volumetric_fog.VolumetricFogUniformBuffer::resource(),
    )
    is None {
    world.insert_resource(
      @pbr_volumetric_fog.VolumetricFogUniformBuffer::resource(),
      @pbr_volumetric_fog.VolumetricFogUniformBuffer::VolumetricFogUniformBuffer(),
    )
  }
  match
    world.get_resource_mut(
      @pbr_volumetric_fog.VolumetricFogUniformBuffer::resource(),
    ) {
    Some(buffer) => buffer
    None => abort("missing VolumetricFogUniformBuffer render resource")
  }
}

///|
fn render3d_reset_volumetric_fog_uniform_buffer(world : @ecs.World) -> Unit {
  render3d_volumetric_fog_uniform_buffer_mut(world).modify(fn(buffer) {
    buffer.clear()
  })
}

///|
fn render3d_collect_volumetric_light_count(world : @ecs.World) -> Int {
  let mut count = 0
  world.for_each_component(@light.ecs_key_volumetric_light, fn(
    _entity,
    _volumetric_light,
  ) {
    count = count + 1
  })
  count
}

///|
fn render3d_collect_fog_volumes(
  world : @ecs.World,
) -> Array[(@light.FogVolume, @math.Affine3)] {
  let volumes : Array[(@light.FogVolume, @math.Affine3)] = []
  world.for_each_component(@light.ecs_key_fog_volume, fn(entity, fog_volume) {
    match (try! world.get_by_key(entity, @transform.ecs_key_global_transform)) {
      Some(global_transform) =>
        volumes.push((fog_volume, global_transform.affine()))
      None => ()
    }
  })
  volumes
}

///|
fn render3d_projection_matrix_to_volumetric_mat4(
  matrix : @pbr_render.ProjectionMatrix3d,
) -> @pbr_volumetric_fog.VolumetricFogMat4 {
  let row0 = matrix.row(0)
  let row1 = matrix.row(1)
  let row2 = matrix.row(2)
  let row3 = matrix.row(3)
  @pbr_volumetric_fog.VolumetricFogMat4::from_cols(
    @math.Vec4::new(row0.x, row1.x, row2.x, row3.x),
    @math.Vec4::new(row0.y, row1.y, row2.y, row3.y),
    @math.Vec4::new(row0.z, row1.z, row2.z, row3.z),
    @math.Vec4::new(row0.w, row1.w, row2.w, row3.w),
  )
}

///|
fn render3d_prepare_camera_volumetric_fog(
  render_world : @ecs.World,
  source_world : @ecs.World,
  camera : Camera3dViewPayload,
  camera_pass_projection : @pbr_render.Render3dPassProjection,
) -> Render3dVolumetricFogPrepareOutput {
  let light_count = render3d_collect_volumetric_light_count(source_world)
  guard light_count > 0 else {
    return Render3dVolumetricFogPrepareOutput::{
      ..Render3dVolumetricFogPrepareOutput::Render3dVolumetricFogPrepareOutput(),
      light_count,
    }
  }
  guard camera.volumetric_fog is Some(volumetric_fog) else {
    return Render3dVolumetricFogPrepareOutput::{
      ..Render3dVolumetricFogPrepareOutput::Render3dVolumetricFogPrepareOutput(),
      light_count,
    }
  }
  let fog_volumes = render3d_collect_fog_volumes(source_world)
  let prepared = render3d_volumetric_fog_uniform_buffer_mut(render_world).modify(fn(
      uniform_buffer,
    ) {
      @pbr_volumetric_fog.prepare_volumetric_fog_view_uniforms(
        uniform_buffer,
        volumetric_fog,
        @math.Affine3::from_scale_rotation_translation(
          camera.transform.scale,
          camera.transform.rotation,
          camera.transform.translation,
        ),
        render3d_projection_matrix_to_volumetric_mat4(
          @pbr_render.render3d_pass_projection_clip_from_view(
            camera_pass_projection,
          ),
        ),
        fog_volumes,
      )
    },
  )
  let uniform_count = render3d_volumetric_fog_uniform_buffer_mut(render_world)
    .peek()
    .count()
  Render3dVolumetricFogPrepareOutput::{
    view_fog: prepared.view_fog,
    view_count: 1,
    volume_count: prepared.view_fog.count(),
    light_count,
    uniform_count,
  }
}

///|
fn render3d_write_volumetric_fog_view_components(
  world : @ecs.World,
  view_entity : @core.Entity,
  prepared : Render3dVolumetricFogPrepareOutput,
) -> Unit {
  if prepared.light_count <= 0 || prepared.view_count <= 0 {
    ignore(
      world.remove_by_key(
        view_entity,
        @pbr_volumetric_fog.ViewVolumetricFog::component(),
      ) catch {
        _ => false
      },
    )
    ignore(
      world.remove_by_key(
        view_entity,
        @pbr_volumetric_fog.ViewVolumetricFogPipelines::component(),
      ) catch {
        _ => false
      },
    )
    return
  }
  try! (world.set_by_key(
    view_entity,
    @pbr_volumetric_fog.ViewVolumetricFog::component(),
    prepared.view_fog,
  )
  |> ignore)
}

///|
fn render3d_volumetric_fog_view_volume_count(
  world : @ecs.World,
  view_entity : @core.Entity,
) -> Int {
  match
    (try! world.get_by_key(
      view_entity,
      @pbr_volumetric_fog.ViewVolumetricFog::component(),
    )) {
    Some(view_fog) => view_fog.count()
    None => 0
  }
}

///|
fn render3d_update_volumetric_fog_plugin_state(
  world : @ecs.World,
  prepared : Render3dVolumetricFogPrepareOutput,
) -> Unit {
  match
    world.get_resource_mut(
      @pbr_volumetric_fog.VolumetricFogPluginState::resource(),
    ) {
    Some(state) =>
      ignore(
        state.modify(fn(value) {
          @pbr_volumetric_fog.volumetric_fog_plugin_state_with_extracted_counts(
            value,
            prepared.view_count,
            prepared.volume_count,
            prepared.light_count,
          )
        }),
      )
    None => ()
  }
}
