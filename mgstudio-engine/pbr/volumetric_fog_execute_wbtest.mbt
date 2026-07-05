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
fn render3d_volumetric_fog_wbtest_identity_projection() -> @pbr_render.ProjectionMatrix3d {
  @pbr_render.ProjectionMatrix3d::from_cols(
    @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 0.0F, 1.0F),
  )
}

///|
fn render3d_volumetric_fog_wbtest_pass_projection() -> @pbr_render.Render3dPassProjection {
  let projection = render3d_volumetric_fog_wbtest_identity_projection()
  @pbr_render.render3d_pass_projection(projection, projection, 0.1F, 1000.0F)
}

///|
fn render3d_volumetric_fog_wbtest_camera_payload(
  volumetric_fog : VolumetricFog?,
) -> Camera3dViewPayload {
  Camera3dViewPayload::{
    decal_config: None,
    deferred_config: None,
    distance_fog: None,
    auto_exposure: None,
    volumetric_fog,
    atmosphere: None,
    atmosphere_settings: None,
    camera: @camera_camera.Camera::Camera(),
    depth_texture_usages: Camera3dDepthTextureUsage::Camera3dDepthTextureUsage(),
    projection: Projection::default(),
    sub_camera_view: None,
    oit_settings: None,
    screen_space_transmission: None,
    bloom: None,
    tonemapping: None,
    deband_dither: None,
    chromatic_aberration: None,
    contrast_adaptive_sharpening: None,
    custom_post_process3d: None,
    vignette: None,
    motion_blur: None,
    exposure: None,
    color_grading: None,
    environment_map_light: None,
    generated_environment_map_light: None,
    atmosphere_environment_map_light: None,
    has_environment_light_probes: false,
    irradiance_volume: None,
    screen_space_ambient_occlusion: None,
    screen_space_reflections: None,
    contact_shadows: None,
    depth_prepass_enabled: false,
    normal_prepass_enabled: false,
    deferred_prepass_enabled: false,
    no_indirect_drawing: false,
    gpu_occlusion_culling_enabled: false,
    hdr_enabled: false,
    fxaa: None,
    temporal_jitter: None,
    temporal_anti_aliasing: None,
    shadow_filtering_method: None,
    motion_vector_prepass_enabled: false,
    msaa: None,
    transform: @transform.Transform::Transform(),
    previous_transform: @transform.Transform::Transform(),
    previous_clip_from_world: None,
    target_id: 0,
    target_size: @math.IVec2::new(1280, 720),
    scale_factor: 1.0F,
    layers: @camera_render_layers.RenderLayers::RenderLayers(),
    has_no_cpu_culling: false,
    invert_culling: false,
  }
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
test "pbr volumetric fog execute: prepare consumes extracted render-world state" {
  let render_world = @ecs.World::new()
  let view_entity = render_world.spawn()
  try! render_world.set_by_key(
    view_entity,
    ecs_key_volumetric_fog,
    VolumetricFog::VolumetricFog().with_step_count(32),
  )
  let light_entity = render_world.spawn()
  try! render_world.set_by_key(
    light_entity,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::VolumetricLight(),
  )
  let volume_entity = render_world.spawn()
  try! render_world.set_by_key(
    volume_entity,
    @light.ecs_key_fog_volume,
    @light.FogVolume::FogVolume().with_density_factor(0.5F),
  )
  try! render_world.set_by_key(
    volume_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(@transform.Transform::identity()),
  )

  let camera = render3d_volumetric_fog_wbtest_camera_payload(
    Some(VolumetricFog::VolumetricFog().with_step_count(96)),
  )
  let prepared = render3d_prepare_camera_volumetric_fog(
    render_world,
    view_entity,
    camera,
    render3d_volumetric_fog_wbtest_pass_projection(),
  )

  inspect(prepared.light_count, content="1")
  inspect(prepared.view_count, content="1")
  inspect(prepared.volume_count, content="1")
  let bytes = render3d_volumetric_fog_uniform_buffer_mut(render_world)
    .peek()
    .bytes()
  inspect(render3d_volumetric_fog_wbtest_u32_at(bytes, 224), content="\{32U}")
  inspect(
    render3d_volumetric_fog_wbtest_u32_at(bytes, 240),
    content="\{0.5F.reinterpret_as_uint()}",
  )
}

///|
test "pbr volumetric fog execute: pre-main prepare state consumes prepared render-world data" {
  let render_world = @ecs.World::new()
  let source_world = @ecs.World::new()
  let main_entity = @core.Entity::new(91, 1)
  let view_entity = render_world.spawn()
  try! render_world.set_by_key(
    view_entity,
    ecs_key_volumetric_fog,
    VolumetricFog::VolumetricFog().with_step_count(40),
  )
  let volume_entity = render_world.spawn()
  try! render_world.set_by_key(
    volume_entity,
    @light.ecs_key_fog_volume,
    @light.FogVolume::FogVolume().with_density_factor(0.625F),
  )
  try! render_world.set_by_key(
    volume_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(@transform.Transform::identity()),
  )

  let camera = render3d_volumetric_fog_wbtest_camera_payload(
    Some(VolumetricFog::VolumetricFog().with_step_count(96)),
  )
  let prepared = render3d_prepare_camera_volumetric_fog_state(
    render_world,
    source_world,
    ExtractedCamera3d::{
      entity: phase_entity_ref3d(main_entity, view_entity),
      payload: camera,
    },
    camera,
    render3d_volumetric_fog_wbtest_pass_projection(),
    0,
    1,
    -1,
    -1,
    -1,
    -1,
    Render3dEnvironmentMapState::{
      diffuse_texture_id: -1,
      specular_texture_id: -1,
      smallest_specular_mip_level: 0,
      intensity: 0.0F,
      rotation: @math.Quat::identity(),
      affects_lightmapped_mesh_diffuse: false,
    },
    Render3dLightProbeState::{
      uniform_bytes: Bytes::from_array([]),
      uniform_offset: 0U,
      diffuse_texture_ids: [],
      specular_texture_ids: [],
      irradiance_volume_texture_ids: [],
    },
  )

  inspect(prepared.view_count, content="1")
  inspect(prepared.volume_count, content="1")
  inspect(prepared.uniform_count, content="1")
  inspect(
    render3d_volumetric_fog_view_volume_count(render_world, view_entity),
    content="1",
  )
  let bytes = render3d_volumetric_fog_uniform_buffer_mut(render_world)
    .peek()
    .bytes()
  inspect(render3d_volumetric_fog_wbtest_u32_at(bytes, 224), content="\{40U}")
  inspect(
    render3d_volumetric_fog_wbtest_u32_at(bytes, 240),
    content="\{0.625F.reinterpret_as_uint()}",
  )
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
test "pbr volumetric fog execute: standalone uniform prepare clears stale data for empty inputs" {
  let world = @ecs.World::new()
  ignore(
    render3d_volumetric_fog_uniform_buffer_mut(world).modify(fn(buffer) {
      @pbr_volumetric_fog.prepare_volumetric_fog_view_uniforms(
        buffer,
        @light.VolumetricFog::VolumetricFog(),
        @math.Affine3::identity(),
        render3d_volumetric_fog_wbtest_identity_mat4(),
        [(@light.FogVolume::FogVolume(), @math.Affine3::identity())],
      )
    }),
  )
  inspect(
    render3d_volumetric_fog_uniform_buffer_mut(world).peek().count(),
    content="1",
  )

  let output = render3d_prepare_volumetric_fog_uniform_buffer(world, [])
  inspect(output.view_count, content="0")
  inspect(output.volume_count, content="0")
  inspect(output.uniform_count, content="0")
  inspect(output.views.length(), content="0")
  inspect(
    render3d_volumetric_fog_uniform_buffer_mut(world).peek().count(),
    content="0",
  )
}

///|
test "pbr volumetric fog execute: standalone uniform prepare keeps zero-volume views empty" {
  let world = @ecs.World::new()
  let view_entity = world.spawn()
  let output = render3d_prepare_volumetric_fog_uniform_buffer(world, [
    Render3dVolumetricFogUniformPrepareViewInput::Render3dVolumetricFogUniformPrepareViewInput(
      view_entity,
      @light.VolumetricFog::VolumetricFog(),
      @math.Affine3::identity(),
      render3d_volumetric_fog_wbtest_identity_mat4(),
    ),
  ])
  inspect(output.view_count, content="1")
  inspect(output.volume_count, content="0")
  inspect(output.uniform_count, content="0")
  inspect(output.views.length(), content="1")
  inspect(output.views[0].view_fog.count(), content="0")
  inspect(
    render3d_volumetric_fog_uniform_buffer_mut(world).peek().bytes().length(),
    content="0",
  )
}

///|
test "pbr volumetric fog execute: standalone uniform prepare derives count from views times render-world volumes" {
  let world = @ecs.World::new()
  let first_volume = world.spawn()
  try! world.set_by_key(
    first_volume,
    @light.ecs_key_fog_volume,
    @light.FogVolume::FogVolume().with_density_factor(0.25F),
  )
  try! world.set_by_key(
    first_volume,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(@transform.Transform::identity()),
  )
  let second_volume = world.spawn()
  try! world.set_by_key(
    second_volume,
    @light.ecs_key_fog_volume,
    @light.FogVolume::FogVolume().with_density_factor(0.75F),
  )
  try! world.set_by_key(
    second_volume,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_translation(@math.Vec3::new(10.0F, 0.0F, 0.0F)),
    ),
  )
  let first_view = world.spawn()
  let second_view = world.spawn()

  let output = render3d_prepare_volumetric_fog_uniform_buffer(world, [
    Render3dVolumetricFogUniformPrepareViewInput::Render3dVolumetricFogUniformPrepareViewInput(
      first_view,
      @light.VolumetricFog::VolumetricFog().with_step_count(32),
      @math.Affine3::identity(),
      render3d_volumetric_fog_wbtest_identity_mat4(),
    ),
    Render3dVolumetricFogUniformPrepareViewInput::Render3dVolumetricFogUniformPrepareViewInput(
      second_view,
      @light.VolumetricFog::VolumetricFog().with_step_count(64),
      @math.Affine3::from_translation(@math.Vec3::new(1.0F, 0.0F, 0.0F)),
      render3d_volumetric_fog_wbtest_identity_mat4(),
    ),
  ])

  inspect(output.view_count, content="2")
  inspect(output.volume_count, content="2")
  inspect(output.light_count, content="0")
  inspect(output.uniform_count, content="4")
  inspect(output.views.length(), content="2")
  inspect(output.views[0].view_entity == first_view, content="true")
  inspect(output.views[1].view_entity == second_view, content="true")
  inspect(output.views[0].view_fog.count(), content="2")
  inspect(output.views[1].view_fog.count(), content="2")
  inspect(
    output.views[0].view_fog.volumes()[0].uniform_buffer_offset(),
    content="0",
  )
  inspect(
    output.views[0].view_fog.volumes()[1].uniform_buffer_offset(),
    content="512",
  )
  inspect(
    output.views[1].view_fog.volumes()[0].uniform_buffer_offset(),
    content="1024",
  )
  inspect(
    output.views[1].view_fog.volumes()[1].uniform_buffer_offset(),
    content="1536",
  )
  let bytes = render3d_volumetric_fog_uniform_buffer_mut(world).peek().bytes()
  inspect(bytes.length(), content="2048")
  inspect(render3d_volumetric_fog_wbtest_u32_at(bytes, 224), content="\{32U}")
  inspect(
    render3d_volumetric_fog_wbtest_u32_at(bytes, 1024 + 224),
    content="\{64U}",
  )
}

///|
test "pbr volumetric fog execute: standalone uniform prepare inserts per-view fog metadata" {
  let world = @ecs.World::new()
  let density_texture : @asset.Handle[@asset.Image] = @asset.Handle::new(77)
  let volume = world.spawn()
  try! world.set_by_key(
    volume,
    @light.ecs_key_fog_volume,
    @light.FogVolume::FogVolume().with_density_texture(Some(density_texture)),
  )
  try! world.set_by_key(
    volume,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(@transform.Transform::identity()),
  )
  let inside_view = world.spawn()
  let outside_view = world.spawn()

  let output = render3d_prepare_volumetric_fog_uniform_buffer(world, [
    Render3dVolumetricFogUniformPrepareViewInput::Render3dVolumetricFogUniformPrepareViewInput(
      inside_view,
      @light.VolumetricFog::VolumetricFog(),
      @math.Affine3::identity(),
      render3d_volumetric_fog_wbtest_identity_mat4(),
    ),
    Render3dVolumetricFogUniformPrepareViewInput::Render3dVolumetricFogUniformPrepareViewInput(
      outside_view,
      @light.VolumetricFog::VolumetricFog(),
      @math.Affine3::from_translation(@math.Vec3::new(0.6F, 0.0F, 0.0F)),
      render3d_volumetric_fog_wbtest_identity_mat4(),
    ),
  ])

  inspect(output.uniform_count, content="2")
  let inside_fog = (try! world.get_by_key(
    inside_view,
    @pbr_volumetric_fog.ViewVolumetricFog::component(),
  )).unwrap()
  let outside_fog = (try! world.get_by_key(
    outside_view,
    @pbr_volumetric_fog.ViewVolumetricFog::component(),
  )).unwrap()
  inspect(inside_fog.count(), content="1")
  inspect(outside_fog.count(), content="1")
  inspect(inside_fog.volumes()[0].exterior(), content="false")
  inspect(outside_fog.volumes()[0].exterior(), content="true")
  inspect(inside_fog.volumes()[0].has_density_texture(), content="true")
  inspect(outside_fog.volumes()[0].density_texture_id(), content="77")
  inspect(inside_fog.volumes()[0].uniform_buffer_offset(), content="0")
  inspect(outside_fog.volumes()[0].uniform_buffer_offset(), content="512")
}

///|
test "pbr volumetric fog execute: clears shared uniform buffer" {
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
test "pbr volumetric fog execute: pipeline keys preserve Bevy texture variants and view dimensions" {
  let view_key = @mesh_view_layout.mesh_view_layout_key(
    true, false, false, false, false, false, true, false,
  )
  let vertex_buffer_layout = @mesh.VertexBufferLayout::new(
    array_stride=32,
    step_mode=@mesh.MeshVertexStepMode::Vertex,
    attributes=[
      @mesh.VertexAttribute::new(
        offset=16,
        format=@mesh.MeshVertexFormat::Float32x3,
        shader_location=0,
      ),
    ],
  )
  let textureless = @pbr_volumetric_fog.VolumetricFogPipelineKey::VolumetricFogPipelineKey(
    mesh_pipeline_view_key=view_key,
    target_format=80U,
    vertex_buffer_layout~,
    has_density_texture=false,
  )
  let textured = @pbr_volumetric_fog.VolumetricFogPipelineKey::VolumetricFogPipelineKey(
    mesh_pipeline_view_key=view_key,
    target_format=80U,
    vertex_buffer_layout~,
    has_density_texture=true,
  )
  inspect(
    textureless.mesh_pipeline_view_key().bits(),
    content="\{view_key.bits()}",
  )
  inspect(
    textured.mesh_pipeline_view_key().bits(),
    content="\{view_key.bits()}",
  )
  inspect(textureless.target_format(), content="80")
  inspect(textured.target_format(), content="80")
  inspect(textureless.vertex_buffer_layout().array_stride(), content="32")
  inspect(textured.vertex_buffer_layout().array_stride(), content="32")
  inspect(
    textureless.vertex_buffer_layout().attributes()[0].offset(),
    content="16",
  )
  inspect(
    textured.vertex_buffer_layout().attributes()[0].offset(),
    content="16",
  )
  inspect(textureless.has_density_texture(), content="false")
  inspect(textured.has_density_texture(), content="true")
  inspect(textureless.bind_group_layout_key().bits(), content="1")
  inspect(textureless.bind_group_layout_key().layout_index(), content="1")
  inspect(textured.bind_group_layout_key().bits(), content="3")
  inspect(textured.bind_group_layout_key().layout_index(), content="3")
  debug_inspect(
    textureless.shader_defs(),
    content="[\"SHADOW_FILTER_METHOD_HARDWARE_2X2\", \"MULTISAMPLED\", \"ATMOSPHERE\"]",
  )
  debug_inspect(
    textured.shader_defs(),
    content="[\n  \"SHADOW_FILTER_METHOD_HARDWARE_2X2\",\n  \"MULTISAMPLED\",\n  \"ATMOSPHERE\",\n  \"DENSITY_TEXTURE\",\n]",
  )
}

///|
test "pbr volumetric fog execute: prepares depth texture usage from sampled depth users" {
  let world = @ecs.World::new()
  let camera3d = Camera3d::Camera3d()
  assert_false(camera3d.depth_texture_usages().has_texture_binding())
  assert_false(render3d_world_has_volumetric_fog_views(world))
  assert_false(
    render3d_prepare_view_depth_texture_usage_for_sampled_depth(
      camera3d,
      render3d_world_has_volumetric_fog_views(world),
      false,
      false,
    ).has_texture_binding(),
  )
  assert_true(
    render3d_prepare_view_depth_texture_usage_for_sampled_depth(
      camera3d,
      render3d_world_has_volumetric_fog_views(world),
      true,
      false,
    ).has_texture_binding(),
  )
  assert_true(
    render3d_prepare_view_depth_texture_usage_for_sampled_depth(
      camera3d,
      render3d_world_has_volumetric_fog_views(world),
      false,
      true,
    ).has_texture_binding(),
  )

  let entity = world.spawn()
  try! (world.set_by_key(
    entity,
    ecs_key_volumetric_fog,
    VolumetricFog::VolumetricFog(),
  )
  |> ignore)
  assert_true(render3d_world_has_volumetric_fog_views(world))
  assert_true(
    render3d_prepare_view_depth_texture_usage_for_sampled_depth(
      camera3d,
      render3d_world_has_volumetric_fog_views(world),
      false,
      false,
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
    render3d_prepare_view_depth_texture_usage_for_sampled_depth(
      camera3d,
      render3d_world_has_volumetric_fog_views(world),
      false,
      false,
    ).has_texture_binding(),
  )
}
