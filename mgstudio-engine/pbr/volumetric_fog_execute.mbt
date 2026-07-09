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
    view_count: 0,
    volume_count: 0,
    light_count: 0,
    uniform_count: 0,
    plane_mesh_id: -1,
    cube_mesh_id: -1,
  }
}

///|
priv struct Render3dVolumetricFogUniformPrepareViewInput {
  view_entity : @core.Entity
  volumetric_fog : @pbr_volumetric_fog.VolumetricFog
  world_from_view : @math.Affine3
  clip_from_view : @pbr_volumetric_fog.VolumetricFogMat4
}

///|
fn Render3dVolumetricFogUniformPrepareViewInput::Render3dVolumetricFogUniformPrepareViewInput(
  view_entity : @core.Entity,
  volumetric_fog : @pbr_volumetric_fog.VolumetricFog,
  world_from_view : @math.Affine3,
  clip_from_view : @pbr_volumetric_fog.VolumetricFogMat4,
) -> Render3dVolumetricFogUniformPrepareViewInput {
  Render3dVolumetricFogUniformPrepareViewInput::{
    view_entity,
    volumetric_fog,
    world_from_view,
    clip_from_view,
  }
}

///|
priv struct Render3dVolumetricFogPreparedViewUniforms {
  view_entity : @core.Entity
  view_fog : @pbr_volumetric_fog.ViewVolumetricFog
}

///|
priv struct Render3dVolumetricFogUniformPrepareOutput {
  views : Array[Render3dVolumetricFogPreparedViewUniforms]
  view_count : Int
  volume_count : Int
  light_count : Int
  uniform_count : Int
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
fn render3d_prepare_volumetric_fog_uniform_buffer(
  render_world : @ecs.World,
  views : Array[Render3dVolumetricFogUniformPrepareViewInput],
) -> Render3dVolumetricFogUniformPrepareOutput {
  let light_count = render3d_collect_volumetric_light_count(render_world)
  let fog_volumes = render3d_collect_fog_volumes(render_world)
  let prepared_views : Array[Render3dVolumetricFogPreparedViewUniforms] = []
  let uniform_count = render3d_volumetric_fog_uniform_buffer_mut(render_world).modify(fn(
      uniform_buffer,
    ) {
      uniform_buffer.clear()
      for view in views {
        let view_fog = @pbr_volumetric_fog.prepare_volumetric_fog_view_uniforms(
          uniform_buffer,
          view.volumetric_fog,
          view.world_from_view,
          view.clip_from_view,
          fog_volumes,
        )
        try! (render_world.set_by_key(
          view.view_entity,
          @pbr_volumetric_fog.ViewVolumetricFog::component(),
          view_fog,
        )
        |> ignore)
        prepared_views.push(Render3dVolumetricFogPreparedViewUniforms::{
          view_entity: view.view_entity,
          view_fog,
        })
      }
      uniform_buffer.count()
    },
  )
  render3d_upload_volumetric_fog_uniform_buffer(render_world)
  Render3dVolumetricFogUniformPrepareOutput::{
    views: prepared_views,
    view_count: views.length(),
    volume_count: fog_volumes.length(),
    light_count,
    uniform_count,
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
fn render3d_volumetric_fog_pipeline_key(
  target_id : Int,
  hull_mesh_id : Int,
  mesh_pipeline_view_key : @mesh_view_layout.MeshPipelineViewLayoutKey,
  has_density_texture : Bool,
) -> @pbr_volumetric_fog.VolumetricFogPipelineKey? {
  guard @render.host_gpu_mesh3d_volumetric_fog_pipeline_key_inputs(
      target_id~,
      hull_mesh_id~,
    )
    is Some((target_format, vertex_buffer_layout)) else {
    return None
  }
  Some(
    @pbr_volumetric_fog.VolumetricFogPipelineKey::VolumetricFogPipelineKey(
      mesh_pipeline_view_key~,
      target_format~,
      vertex_buffer_layout~,
      has_density_texture~,
    ),
  )
}

///|
fn render3d_prepare_volumetric_fog_pipeline_id(
  key : @pbr_volumetric_fog.VolumetricFogPipelineKey,
  msaa_sample_count : Int,
) -> Int? {
  @render.host_gpu_prepare_mesh3d_volumetric_fog_pipeline(
    target_format=key.target_format(),
    msaa_sample_count~,
    has_density_texture=key.has_density_texture(),
    mesh_pipeline_view_key_bits=key.mesh_pipeline_view_key().bits(),
    vertex_buffer_layout=key.vertex_buffer_layout(),
  )
}

///|
fn render3d_trace_volumetric_fog_pipeline_variant(
  key : @pbr_volumetric_fog.VolumetricFogPipelineKey,
  pipeline_id : Int,
  msaa_sample_count : Int,
) -> Unit {
  guard pipeline_id > 0 else { return }
  let variant = if key.has_density_texture() {
    "textured"
  } else {
    "textureless"
  }
  @app.timeline_trace_emit_counter_int(
    "render_3d_volumetric_fog_pipeline_" + variant,
    1,
  )
  let bind_group_layout_key = key.bind_group_layout_key()
  @app.timeline_trace_emit_counter_int(
    "render_3d_volumetric_fog_pipeline_" +
    variant +
    "_shadow_filter_hardware_2x2",
    1,
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_volumetric_fog_pipeline_" + variant + "_density_texture",
    if key.has_density_texture() {
      1
    } else {
      0
    },
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_volumetric_fog_pipeline_" + variant + "_target_format_raw",
    key.target_format().reinterpret_as_int(),
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_volumetric_fog_pipeline_" + variant + "_msaa_sample_count",
    msaa_sample_count,
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_volumetric_fog_pipeline_" + variant + "_multisampled",
    if bind_group_layout_key.is_multisampled() {
      1
    } else {
      0
    },
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_volumetric_fog_pipeline_" + variant + "_atmosphere",
    if (
        key.mesh_pipeline_view_key().bits() &
        @mesh_view_layout.MESH_VIEW_LAYOUT_ATMOSPHERE
      ) !=
      0U {
      1
    } else {
      0
    },
  )
}

///|
fn render3d_prepare_volumetric_fog_pipelines(
  render_world : @ecs.World,
  view_entity : @core.Entity,
  prepared : Render3dVolumetricFogPrepareOutput,
  target_id : Int,
  msaa_sample_count : Int,
  mesh_pipeline_view_key : @mesh_view_layout.MeshPipelineViewLayoutKey,
) -> Unit {
  let (needs_textureless, needs_textured) = render3d_volumetric_fog_pipeline_variants(
    prepared,
  )
  if @sys.get_env_var("MGSTUDIO_ATMOSPHERE_PARITY_DEBUG") is Some(_) {
    println(
      "[DEBUG-atmosphere-parity] fog-prepare lights=\{prepared.light_count} views=\{prepared.view_count} volumes=\{prepared.volume_count} plane=\{prepared.plane_mesh_id} cube=\{prepared.cube_mesh_id} needs_textureless=\{needs_textureless} needs_textured=\{needs_textured}",
    )
  }
  guard needs_textureless || needs_textured else { return }
  let textureless_pipeline_id = if needs_textureless {
    match
      render3d_volumetric_fog_pipeline_key(
        target_id,
        prepared.plane_mesh_id,
        mesh_pipeline_view_key,
        false,
      ) {
      Some(key) => {
        let pipeline_id = render3d_prepare_volumetric_fog_pipeline_id(
          key, msaa_sample_count,
        )
        match pipeline_id {
          Some(id) =>
            render3d_trace_volumetric_fog_pipeline_variant(
              key, id, msaa_sample_count,
            )
          None => ()
        }
        pipeline_id
      }
      None => None
    }
  } else {
    None
  }
  let textured_pipeline_id = if needs_textured {
    match
      render3d_volumetric_fog_pipeline_key(
        target_id,
        prepared.plane_mesh_id,
        mesh_pipeline_view_key,
        true,
      ) {
      Some(key) => {
        let pipeline_id = render3d_prepare_volumetric_fog_pipeline_id(
          key, msaa_sample_count,
        )
        match pipeline_id {
          Some(id) =>
            render3d_trace_volumetric_fog_pipeline_variant(
              key, id, msaa_sample_count,
            )
          None => ()
        }
        pipeline_id
      }
      None => None
    }
  } else {
    None
  }
  let pipelines = match (textureless_pipeline_id, textured_pipeline_id) {
    (Some(textureless), Some(textured)) => {
      if @sys.get_env_var("MGSTUDIO_ATMOSPHERE_PARITY_DEBUG") is Some(_) {
        println(
          "[DEBUG-atmosphere-parity] fog-pipelines textureless=\{textureless} textured=\{textured}",
        )
      }
      Some(@pbr_volumetric_fog.ViewVolumetricFogPipelines::{
        textureless,
        textured,
      })
    }
    _ => {
      if @sys.get_env_var("MGSTUDIO_ATMOSPHERE_PARITY_DEBUG") is Some(_) {
        println("[DEBUG-atmosphere-parity] fog-pipelines missing")
      }
      None
    }
  }
  match pipelines {
    Some(pipelines) =>
      try! (render_world.set_by_key(
        view_entity,
        @pbr_volumetric_fog.ViewVolumetricFogPipelines::component(),
        pipelines,
      )
      |> ignore)
    None => ()
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
  ignore(source_world)
  guard render_world.get_resource(@pbr_volumetric_fog.FogAssets::resource())
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
fn render3d_prepare_view_depth_texture_usage_for_sampled_depth(
  camera3d : Camera3d,
  has_volumetric_fog_views : Bool,
  has_screen_space_ambient_occlusion : Bool,
  has_atmosphere : Bool,
) -> Camera3dDepthTextureUsage {
  if has_volumetric_fog_views ||
    has_screen_space_ambient_occlusion ||
    has_atmosphere {
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
  shadow_bindings : Render3dViewShadowBindings,
  camera_entity : @core.Entity,
  atmosphere : Bool,
) -> Unit {
  guard prepared.light_count > 0 &&
    prepared.view_count > 0 &&
    prepared.volume_count > 0 &&
    prepared.plane_mesh_id >= 0 &&
    prepared.cube_mesh_id >= 0 else {
    if @sys.get_env_var("MGSTUDIO_ATMOSPHERE_PARITY_DEBUG") is Some(_) {
      println(
        "[DEBUG-atmosphere-parity] fog-draw skip counts lights=\{prepared.light_count} views=\{prepared.view_count} volumes=\{prepared.volume_count} plane=\{prepared.plane_mesh_id} cube=\{prepared.cube_mesh_id}",
      )
    }
    return
  }
  guard (try! world.get_by_key(
      view_entity,
      @pbr_volumetric_fog.ViewVolumetricFog::component(),
    ))
    is Some(view_fog) else {
    if @sys.get_env_var("MGSTUDIO_ATMOSPHERE_PARITY_DEBUG") is Some(_) {
      println("[DEBUG-atmosphere-parity] fog-draw skip missing view fog")
    }
    return
  }
  guard (try! world.get_by_key(
      view_entity,
      @pbr_volumetric_fog.ViewVolumetricFogPipelines::component(),
    ))
    is Some(pipelines) else {
    if @sys.get_env_var("MGSTUDIO_ATMOSPHERE_PARITY_DEBUG") is Some(_) {
      println("[DEBUG-atmosphere-parity] fog-draw skip missing pipelines")
    }
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
  if shadow_bindings.directional.texture_id >= 0 &&
    shadow_bindings.directional.cascade_count > 0 {
    @app.timeline_trace_emit_counter_int(
      "render_3d_volumetric_fog_view_shadow_binding_resources", 1,
    )
  }
  if shadow_bindings.point.texture_id >= 0 {
    @app.timeline_trace_emit_counter_int(
      "render_3d_volumetric_fog_view_point_shadow_binding_resources", 1,
    )
  }
  if shadow_bindings.directional.texture_id >= 0 {
    @app.timeline_trace_emit_counter_int(
      "render_3d_volumetric_fog_view_directional_spot_shadow_binding_resources",
      1,
    )
  }
  @render.host_gpu_draw_mesh3d_volumetric_fog(
    camera_key_hi=camera_entity.id,
    camera_key_lo=camera_entity.generation,
    point_shadow_texture_id=shadow_bindings.point.texture_id,
    directional_shadow_texture_id=shadow_bindings.directional.texture_id,
    plane_mesh_id=prepared.plane_mesh_id,
    cube_mesh_id=prepared.cube_mesh_id,
    textureless_pipeline_id=pipelines.textureless,
    textured_pipeline_id=pipelines.textured,
    atmosphere~,
    volumes~,
  )
}

///|
fn render3d_execute_camera_volumetric_fog_pass(
  world : @ecs.World,
  view_entity : @core.Entity,
  prepared : Render3dVolumetricFogPrepareOutput,
  shadow_bindings : Render3dViewShadowBindings,
  camera_entity : @core.Entity,
  atmosphere : Bool,
) -> Unit {
  render3d_draw_volumetric_fog(
    world, view_entity, prepared, shadow_bindings, camera_entity, atmosphere,
  )
  @render.host_gpu_end_pass()
  @app.timeline_trace_emit_counter_int(
    "render_3d_volumetric_fog_views",
    prepared.view_count,
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_volumetric_fog_volumes",
    render3d_volumetric_fog_view_volume_count(world, view_entity),
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_volumetric_fog_lights",
    prepared.light_count,
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_volumetric_fog_uniforms",
    prepared.uniform_count,
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_volumetric_fog_plane_mesh_id",
    prepared.plane_mesh_id,
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_volumetric_fog_cube_mesh_id",
    prepared.cube_mesh_id,
  )
}

///|
fn render3d_collect_volumetric_light_count(world : @ecs.World) -> Int {
  @pbr_volumetric_fog.volumetric_fog_render_world_storage_counts(world).light_count()
}

///|
fn render3d_collect_fog_volumes(
  world : @ecs.World,
) -> Array[(@light.FogVolume, @math.Affine3)] {
  @pbr_volumetric_fog.volumetric_fog_render_world_volume_inputs(world)
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
  view_entity : @core.Entity,
  camera : Camera3dViewPayload,
  camera_pass_projection : @pbr_render.Render3dPassProjection,
) -> Render3dVolumetricFogPrepareOutput {
  let light_count = render3d_collect_volumetric_light_count(render_world)
  guard (try! render_world.get_by_key(view_entity, ecs_key_volumetric_fog))
    is Some(volumetric_fog) else {
    return Render3dVolumetricFogPrepareOutput::{
      ..Render3dVolumetricFogPrepareOutput::Render3dVolumetricFogPrepareOutput(),
      light_count,
    }
  }
  let uniform_prepare = render3d_prepare_volumetric_fog_uniform_buffer(
    render_world,
    [
      Render3dVolumetricFogUniformPrepareViewInput::Render3dVolumetricFogUniformPrepareViewInput(
        view_entity,
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
      ),
    ],
  )
  guard uniform_prepare.views.length() > 0 else {
    return Render3dVolumetricFogPrepareOutput::{
      ..Render3dVolumetricFogPrepareOutput::Render3dVolumetricFogPrepareOutput(),
      view_count: uniform_prepare.view_count,
      volume_count: uniform_prepare.volume_count,
      light_count: uniform_prepare.light_count,
      uniform_count: uniform_prepare.uniform_count,
    }
  }
  let prepared_view = uniform_prepare.views[0]
  guard prepared_view.view_entity == view_entity else {
    return Render3dVolumetricFogPrepareOutput::{
      ..Render3dVolumetricFogPrepareOutput::Render3dVolumetricFogPrepareOutput(),
      view_count: uniform_prepare.view_count,
      volume_count: uniform_prepare.volume_count,
      light_count: uniform_prepare.light_count,
      uniform_count: uniform_prepare.uniform_count,
    }
  }
  Render3dVolumetricFogPrepareOutput::{
    view_count: uniform_prepare.view_count,
    volume_count: prepared_view.view_fog.count(),
    light_count: uniform_prepare.light_count,
    uniform_count: uniform_prepare.uniform_count,
    plane_mesh_id: -1,
    cube_mesh_id: -1,
  }
}

///|
fn render3d_prepare_camera_volumetric_fog_state(
  render_world : @ecs.World,
  source_world : @ecs.World,
  extracted_camera : ExtractedCamera3d,
  camera : Camera3dViewPayload,
  camera_pass_projection : @pbr_render.Render3dPassProjection,
  scene_target_id : Int,
  msaa_sample_count : Int,
  prepass_depth_texture_id : Int,
  prepass_normal_texture_id : Int,
  prepass_motion_vector_texture_id : Int,
  prepass_deferred_texture_id : Int,
  environment_map_state : Render3dEnvironmentMapState,
  light_probe_state : Render3dLightProbeState,
) -> Render3dVolumetricFogPrepareOutput {
  let prepared = render3d_prepare_camera_volumetric_fog(
    render_world,
    extracted_camera.entity.render_entity,
    camera,
    camera_pass_projection,
  )
  let prepared = render3d_prepare_volumetric_fog_hull_meshes(
    render_world, source_world, prepared,
  )
  let mesh_pipeline_view_key = @mesh_view_layout.mesh_view_layout_key(
    msaa_sample_count > 1,
    prepass_depth_texture_id >= 0,
    prepass_normal_texture_id >= 0,
    prepass_motion_vector_texture_id >= 0,
    prepass_deferred_texture_id >= 0,
    false,
    camera.atmosphere is Some(_),
    false,
    tonemap_in_shader=render3d_main_pass_tonemap_in_shader(camera),
    environment_map=environment_map_state.intensity > 0.0F,
    irradiance_volume=light_probe_state.irradiance_volume_texture_ids.length() >
      0,
    screen_space_reflections=camera.screen_space_reflections is Some(_),
    area_light_luts=false,
    dfg_lut=false,
  )
  render3d_prepare_volumetric_fog_pipelines(
    render_world,
    extracted_camera.entity.render_entity,
    prepared,
    scene_target_id,
    msaa_sample_count,
    mesh_pipeline_view_key,
  )
  prepared
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
