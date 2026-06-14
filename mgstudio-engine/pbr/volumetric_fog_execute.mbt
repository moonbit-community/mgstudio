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
  view_fog : @pbr_volumetric_fog.ViewVolumetricFog?
  view_count : Int
  volume_count : Int
  light_count : Int
  uniform_count : Int
  plane_mesh_id : Int
  cube_mesh_id : Int
}

///|
fn Render3dVolumetricFogPrepareOutput::Render3dVolumetricFogPrepareOutput() -> Render3dVolumetricFogPrepareOutput {
  Render3dVolumetricFogPrepareOutput::{
    view_fog: None,
    view_count: 0,
    volume_count: 0,
    light_count: 0,
    uniform_count: 0,
    plane_mesh_id: -1,
    cube_mesh_id: -1,
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
fn render3d_upload_volumetric_fog_uniform_buffer(world : @ecs.World) -> Unit {
  match
    world.get_resource(
      @pbr_volumetric_fog.VolumetricFogUniformBuffer::resource(),
    ) {
    Some(buffer) =>
      @render.host_gpu_prepare_mesh3d_volumetric_fog_uniforms(
        volumetric_fog_uniform_bytes=buffer.bytes(),
      )
    None => ()
  }
}

///|
fn render3d_prepare_volumetric_fog_pipelines(
  prepared : Render3dVolumetricFogPrepareOutput,
  target_id : Int,
  msaa_sample_count : Int,
  atmosphere : Bool,
) -> @pbr_volumetric_fog.ViewVolumetricFogPipelines? {
  let (needs_textureless, needs_textured) = render3d_volumetric_fog_pipeline_variants(
    prepared,
  )
  guard needs_textureless || needs_textured else { return None }
  let textureless_pipeline_id = if needs_textureless {
    @render.host_gpu_prepare_mesh3d_volumetric_fog_pipeline(
      target_id~,
      msaa_sample_count~,
      has_density_texture=false,
      atmosphere~,
      hull_mesh_id=prepared.plane_mesh_id,
    )
  } else {
    None
  }
  let textured_pipeline_id = if needs_textured {
    @render.host_gpu_prepare_mesh3d_volumetric_fog_pipeline(
      target_id~,
      msaa_sample_count~,
      has_density_texture=true,
      atmosphere~,
      hull_mesh_id=prepared.plane_mesh_id,
    )
  } else {
    None
  }
  match (textureless_pipeline_id, textured_pipeline_id) {
    (Some(textureless), Some(textured)) =>
      Some(@pbr_volumetric_fog.ViewVolumetricFogPipelines::{
        textureless,
        textured,
      })
    _ => None
  }
}

///|
fn render3d_volumetric_fog_pipeline_variants(
  prepared : Render3dVolumetricFogPrepareOutput,
) -> (Bool, Bool) {
  guard prepared.light_count > 0 &&
    prepared.view_count > 0 &&
    prepared.plane_mesh_id >= 0 else {
    return (false, false)
  }
  (true, true)
}

///|
fn render3d_volumetric_fog_should_prepare_hull_meshes(
  prepared : Render3dVolumetricFogPrepareOutput,
) -> Bool {
  prepared.light_count > 0 && prepared.view_count > 0
}

///|
fn render3d_prepare_volumetric_fog_hull_meshes(
  render_world : @ecs.World,
  source_world : @ecs.World,
  prepared : Render3dVolumetricFogPrepareOutput,
) -> Render3dVolumetricFogPrepareOutput {
  guard render3d_volumetric_fog_should_prepare_hull_meshes(prepared) else {
    return prepared
  }
  guard source_world.get_resource(@pbr_volumetric_fog.FogAssets::resource())
    is Some(fog_assets) else {
    return prepared
  }
  let (plane_mesh_id, cube_mesh_id) = @pbr_render.render3d_mesh_runtime_state_mut_or_abort(
    render_world,
  ).modify(fn(mesh_runtime_state) {
    (
      @pbr_render.render3d_upload_mesh_handle_cached(
        mesh_runtime_state,
        fog_assets.plane_mesh(),
      ),
      @pbr_render.render3d_upload_mesh_handle_cached(
        mesh_runtime_state,
        fog_assets.cube_mesh(),
      ),
    )
  })
  Render3dVolumetricFogPrepareOutput::{
    ..prepared,
    plane_mesh_id,
    cube_mesh_id,
  }
}

///|
fn render3d_world_has_volumetric_fog_views(world : @ecs.World) -> Bool {
  let mut has_volumetric_fog = false
  world.for_each_component(ecs_key_volumetric_fog, fn(_entity, _fog) {
    has_volumetric_fog = true
  })
  has_volumetric_fog
}

///|
fn render3d_prepare_view_depth_texture_usage_for_volumetric_fog(
  camera3d : Camera3d,
  has_volumetric_fog_views : Bool,
) -> Camera3dDepthTextureUsage {
  if has_volumetric_fog_views {
    camera3d.depth_texture_usages().with_texture_binding()
  } else {
    camera3d.depth_texture_usages()
  }
}

///|
fn render3d_draw_volumetric_fog(
  world : @ecs.World,
  view_entity : @core.Entity,
  prepared : Render3dVolumetricFogPrepareOutput,
  camera_entity : @core.Entity,
  atmosphere : Bool,
) -> Unit {
  guard prepared.light_count > 0 &&
    prepared.view_count > 0 &&
    prepared.volume_count > 0 &&
    prepared.plane_mesh_id >= 0 &&
    prepared.cube_mesh_id >= 0 else {
    return
  }
  guard (try! world.get_by_key(
      view_entity,
      @pbr_volumetric_fog.ViewVolumetricFog::component(),
    ))
    is Some(view_fog) else {
    return
  }
  guard (try! world.get_by_key(
      view_entity,
      @pbr_volumetric_fog.ViewVolumetricFogPipelines::component(),
    ))
    is Some(pipelines) else {
    return
  }
  let volumes : Array[@render.HostMesh3dVolumetricFogVolume] = []
  for volume in view_fog.volumes() {
    volumes.push(
      @render.host_mesh3d_volumetric_fog_volume(
        density_texture_id=volume.density_texture_id(),
        uniform_buffer_offset=volume.uniform_buffer_offset(),
        exterior=volume.exterior(),
      ),
    )
  }
  @render.host_gpu_draw_mesh3d_volumetric_fog(
    camera_key_hi=camera_entity.id,
    camera_key_lo=camera_entity.generation,
    plane_mesh_id=prepared.plane_mesh_id,
    cube_mesh_id=prepared.cube_mesh_id,
    textureless_pipeline_id=pipelines.textureless,
    textured_pipeline_id=pipelines.textured,
    atmosphere~,
    volumes~,
  )
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
  let volumes_with_local_from_world : Array[(@light.FogVolume, @math.Affine3)] = []
  world.for_each_component(@light.ecs_key_fog_volume, fn(entity, fog_volume) {
    match (try! world.get_by_key(entity, @transform.ecs_key_global_transform)) {
      Some(global_transform) =>
        volumes_with_local_from_world.push(
          (fog_volume, global_transform.affine().inverse()),
        )
      None => ()
    }
  })
  volumes_with_local_from_world
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
    view_fog: Some(prepared.view_fog),
    view_count: 1,
    volume_count: prepared.view_fog.count(),
    light_count,
    uniform_count,
    plane_mesh_id: -1,
    cube_mesh_id: -1,
  }
}

///|
fn render3d_write_volumetric_fog_view_components(
  world : @ecs.World,
  view_entity : @core.Entity,
  prepared : Render3dVolumetricFogPrepareOutput,
) -> Unit {
  if prepared.light_count <= 0 ||
    prepared.view_count <= 0 ||
    prepared.view_fog is None {
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
  guard prepared.view_fog is Some(view_fog) else { return }
  try! (world.set_by_key(
    view_entity,
    @pbr_volumetric_fog.ViewVolumetricFog::component(),
    view_fog,
  )
  |> ignore)
}

///|
fn render3d_write_volumetric_fog_pipeline_components(
  world : @ecs.World,
  view_entity : @core.Entity,
  pipelines : @pbr_volumetric_fog.ViewVolumetricFogPipelines?,
) -> Unit {
  match pipelines {
    Some(pipelines) =>
      try! (world.set_by_key(
        view_entity,
        @pbr_volumetric_fog.ViewVolumetricFogPipelines::component(),
        pipelines,
      )
      |> ignore)
    None =>
      ignore(
        world.remove_by_key(
          view_entity,
          @pbr_volumetric_fog.ViewVolumetricFogPipelines::component(),
        ) catch {
          _ => false
        },
      )
  }
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
