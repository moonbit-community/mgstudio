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
fn approx_eq(lhs : Float, rhs : Float) -> Bool {
  @math.abs(lhs - rhs) <= 0.0001F
}

///|
fn vec3_approx_eq(lhs : @math.Vec3, rhs : @math.Vec3) -> Bool {
  approx_eq(lhs.x, rhs.x) && approx_eq(lhs.y, rhs.y) && approx_eq(lhs.z, rhs.z)
}

///|
test "scrolling_fog: Bevy scene authoring inputs reach source world" {
  let mut app = scrolling_fog_app()
  app = app.update()
  let world = app.world()
  match world.get_resource(@pbr.ecs_key_directional_light_shadow_map) {
    Some(shadow_map) => debug_inspect(shadow_map.size, content="4096")
    None => abort("expected DirectionalLightShadowMap resource")
  }

  let camera_count = Ref(0)
  let camera_transform_matches = Ref(true)
  let camera_msaa_matches = Ref(true)
  let camera_fog_matches = Ref(true)
  let camera_query : @ecs.Query[
    (
      @ecs.Read[@camera.Camera3d],
      @ecs.Read[@transform.Transform],
      @ecs.Read[@pbr.Msaa],
      @ecs.Read[@post_process.TemporalAntiAliasing],
      @ecs.Read[@post_process.Bloom],
      @ecs.Read[@pbr.VolumetricFog],
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! camera_query.view(fn(_entity, data) {
    let (_camera, transform_read, msaa_read, _taa, _bloom, fog_read) = data
    camera_count.val = camera_count.val + 1
    let transform = transform_read.value()
    camera_transform_matches.val = camera_transform_matches.val &&
      vec3_approx_eq(transform.translation, @math.Vec3::new(0.0F, 2.0F, 0.0F))
    camera_msaa_matches.val = camera_msaa_matches.val &&
      msaa_read.value() == @pbr.Msaa::Off
    let fog = fog_read.value()
    camera_fog_matches.val = camera_fog_matches.val &&
      approx_eq(fog.ambient_intensity, 0.0F) &&
      approx_eq(fog.jitter, 0.5F)
  })
  debug_inspect(camera_count.val, content="1")
  debug_inspect(camera_transform_matches.val, content="true")
  debug_inspect(camera_msaa_matches.val, content="true")
  debug_inspect(camera_fog_matches.val, content="true")

  let directional_light_count = Ref(0)
  let directional_light_shadow_matches = Ref(true)
  let directional_light_transform_matches = Ref(true)
  let directional_light_query : @ecs.Query[
    (
      @ecs.Read[@pbr.DirectionalLight],
      @ecs.Read[@transform.Transform],
      @ecs.Read[@pbr.VolumetricLight],
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! directional_light_query.view(fn(_entity, data) {
    let (light_read, transform_read, _volumetric_light) = data
    let light = light_read.value()
    directional_light_count.val = directional_light_count.val + 1
    directional_light_shadow_matches.val = directional_light_shadow_matches.val &&
      light.shadow_maps_enabled
    let transform = transform_read.value()
    directional_light_transform_matches.val = directional_light_transform_matches.val &&
      vec3_approx_eq(transform.translation, @math.Vec3::new(-5.0F, 5.0F, -7.0F))
  })
  debug_inspect(directional_light_count.val, content="1")
  debug_inspect(directional_light_shadow_matches.val, content="true")
  debug_inspect(directional_light_transform_matches.val, content="true")

  let fog_volume_count = Ref(0)
  let fog_volume_transform_matches = Ref(true)
  let fog_volume_density_matches = Ref(true)
  let fog_volume_texture_matches = Ref(true)
  let fog_volume_offset_matches = Ref(true)
  let fog_volume_query : @ecs.Query[
    (@ecs.Read[@pbr.FogVolume], @ecs.Read[@transform.Transform]),
    @ecs.All,
  ] = @ecs.query(world)
  try! fog_volume_query.view(fn(_entity, data) {
    let (fog_volume_read, transform_read) = data
    let fog_volume = fog_volume_read.value()
    fog_volume_count.val = fog_volume_count.val + 1
    let transform = transform_read.value()
    fog_volume_transform_matches.val = fog_volume_transform_matches.val &&
      vec3_approx_eq(transform.translation, @math.Vec3::new(0.0F, 32.0F, 0.0F)) &&
      vec3_approx_eq(transform.scale, @math.Vec3::splat(64.0F))
    fog_volume_density_matches.val = fog_volume_density_matches.val &&
      approx_eq(fog_volume.density_factor, 0.05F)
    fog_volume_texture_matches.val = fog_volume_texture_matches.val &&
      fog_volume.density_texture is Some(_)
    fog_volume_offset_matches.val = fog_volume_offset_matches.val &&
      vec3_approx_eq(fog_volume.density_texture_offset, @math.Vec3::zero())
  })
  debug_inspect(fog_volume_count.val, content="1")
  debug_inspect(fog_volume_transform_matches.val, content="true")
  debug_inspect(fog_volume_density_matches.val, content="true")
  debug_inspect(fog_volume_texture_matches.val, content="true")
  debug_inspect(fog_volume_offset_matches.val, content="true")

  let mesh_count = Ref(0)
  let ground_count = Ref(0)
  let pillar_count = Ref(0)
  let material_count = Ref(0)
  let legacy_material_count = Ref(0)
  let material_key : @ecs.ComponentKey[
    @pbr.MeshMaterial3dTyped[@pbr.StandardMaterial],
  ] = @pbr.MeshMaterial3dTyped::component()
  let mesh_query : @ecs.Query[
    (@ecs.Read[@mesh.Mesh3d], @ecs.Read[@transform.Transform]),
    @ecs.All,
  ] = @ecs.query(world)
  try! mesh_query.view(fn(_entity, data) {
    let (_mesh, transform_read) = data
    mesh_count.val = mesh_count.val + 1
    let transform = transform_read.value()
    if vec3_approx_eq(transform.translation, @math.Vec3::new(0.0F, -0.5F, 0.0F)) {
      ground_count.val = ground_count.val + 1
    }
    if vec3_approx_eq(
        transform.translation,
        @math.Vec3::new(-10.0F, 4.5F, -11.0F),
      ) {
      pillar_count.val = pillar_count.val + 1
    }
  })
  world.for_each_component(material_key, fn(_entity, _material) {
    material_count.val = material_count.val + 1
  })
  world.for_each_component(@pbr.ecs_key_mesh_material3d, fn(
    _entity,
    _material,
  ) {
    legacy_material_count.val = legacy_material_count.val + 1
  })
  debug_inspect(mesh_count.val, content="2")
  debug_inspect(material_count.val, content="2")
  debug_inspect(legacy_material_count.val, content="0")
  debug_inspect(ground_count.val, content="1")
  debug_inspect(pillar_count.val, content="1")
}

///|
test "scrolling_fog: directional cascade inputs are Bevy-shaped" {
  let mut app = scrolling_fog_app()
  app = app.update()
  let world = app.world()

  let camera_entity = Ref(None)
  let camera_projection_aspect_matches = Ref(false)
  let camera_query : @ecs.Query[
    (@ecs.Read[@camera.Camera3d], @ecs.Read[@camera.Projection]),
    @ecs.All,
  ] = @ecs.query(world)
  try! camera_query.view(fn(entity, data) {
    let (_camera3d, projection_read) = data
    camera_entity.val = Some(entity)
    match projection_read.value() {
      @camera.Projection::Perspective(projection) =>
        camera_projection_aspect_matches.val = approx_eq(
          projection.aspect_ratio(),
          1280.0F / 720.0F,
        )
      _ => ()
    }
  })
  debug_inspect(camera_projection_aspect_matches.val, content="true")

  let light_count = Ref(0)
  let cascade_config_matches = Ref(true)
  let cascade_count_matches = Ref(false)
  let cascade_texels_valid = Ref(true)
  let cascade_projection_valid = Ref(true)
  let light_query : @ecs.Query[
    (
      @ecs.Read[@pbr.DirectionalLight],
      @ecs.Read[@pbr.CascadeShadowConfig],
      @ecs.Read[@light.Cascades],
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! light_query.view(fn(_entity, data) {
    let (light_read, config_read, cascades_read) = data
    if light_read.value().shadow_maps_enabled {
      light_count.val = light_count.val + 1
      let config = config_read.value()
      cascade_config_matches.val = cascade_config_matches.val &&
        config.bounds.length() == 4 &&
        approx_eq(config.bounds[0], 10.0F) &&
        approx_eq(config.bounds[3], 150.0F) &&
        approx_eq(config.minimum_distance, 0.1F) &&
        approx_eq(config.overlap_proportion, 0.2F)
      guard camera_entity.val is Some(camera_entity_value) else {
        abort("expected scrolling_fog camera entity")
      }
      let view_cascades = cascades_read.value().get(camera_entity_value)
      cascade_count_matches.val = view_cascades.length() == 4
      for cascade in view_cascades {
        cascade_texels_valid.val = cascade_texels_valid.val &&
          cascade.texel_size > 0.0F
        cascade_projection_valid.val = cascade_projection_valid.val &&
          cascade.clip_from_world.x_axis().x != 0.0F &&
          cascade.clip_from_world.y_axis().y != 0.0F &&
          cascade.clip_from_world.w_axis().w == 1.0F
      }
    }
  })
  debug_inspect(light_count.val, content="1")
  debug_inspect(cascade_config_matches.val, content="true")
  debug_inspect(cascade_count_matches.val, content="true")
  debug_inspect(cascade_texels_valid.val, content="true")
  debug_inspect(cascade_projection_valid.val, content="true")
}

///|
test "scrolling_fog: volumetric fog shader defs mirror Bevy active pipeline key" {
  let counters : Array[@app.TimelineTraceCounter] = []
  @app.set_timeline_trace_counter_sink(
    Some(fn(counter) { counters.push(counter) }),
  )
  let mut app = scrolling_fog_app()
  for _ in 0..<6 {
    app = app.update()
  }
  @app.clear_timeline_trace_counter_sink()
  let world = app.world()

  let camera_count = Ref(0)
  let camera_non_msaa = Ref(true)
  let camera_query : @ecs.Query[
    (
      @ecs.Read[@camera.Camera3d],
      @ecs.Read[@pbr.Msaa],
      @ecs.Read[@pbr.VolumetricFog],
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! camera_query.view(fn(_entity, data) {
    let (_camera, msaa_read, _volumetric_fog) = data
    camera_count.val = camera_count.val + 1
    camera_non_msaa.val = camera_non_msaa.val &&
      msaa_read.value() == @pbr.Msaa::Off
  })
  let atmosphere_count = Ref(0)
  world.for_each_component(@pbr_atmosphere.Atmosphere::component(), fn(
    _entity,
    _atmosphere,
  ) {
    atmosphere_count.val = atmosphere_count.val + 1
  })
  debug_inspect(camera_count.val, content="1")
  debug_inspect(camera_non_msaa.val, content="true")
  debug_inspect(atmosphere_count.val, content="0")

  let fog_volume_count = Ref(0)
  let fog_volume_textured = Ref(true)
  let fog_volume_query : @ecs.Query[@ecs.Read[@pbr.FogVolume], @ecs.All] = @ecs.query(
    world,
  )
  try! fog_volume_query.view(fn(_entity, fog_volume_read) {
    fog_volume_count.val = fog_volume_count.val + 1
    fog_volume_textured.val = fog_volume_textured.val &&
      fog_volume_read.value().density_texture is Some(_)
  })
  debug_inspect(fog_volume_count.val, content="1")
  debug_inspect(fog_volume_textured.val, content="true")

  let view_key = @mesh_view_layout.mesh_view_layout_key(
    false, false, false, false, false, false, false, false,
  )
  let vertex_buffer_layout = @mesh.VertexBufferLayout::new(
    array_stride=12,
    step_mode=@mesh.MeshVertexStepMode::Vertex,
    attributes=[
      @mesh.VertexAttribute::new(
        offset=0,
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

  debug_inspect(
    textureless.shader_defs(),
    content="[\"SHADOW_FILTER_METHOD_HARDWARE_2X2\"]",
  )
  debug_inspect(
    textured.shader_defs(),
    content="[\"SHADOW_FILTER_METHOD_HARDWARE_2X2\", \"DENSITY_TEXTURE\"]",
  )
  inspect(
    textureless.bind_group_layout_key().is_multisampled(),
    content="false",
  )
  inspect(textured.bind_group_layout_key().is_multisampled(), content="false")
  inspect(
    textureless.bind_group_layout_key().has_density_texture(),
    content="false",
  )
  inspect(
    textured.bind_group_layout_key().has_density_texture(),
    content="true",
  )

  let runtime_textureless = Ref(false)
  let runtime_textured = Ref(false)
  let runtime_textureless_shadow_def = Ref(false)
  let runtime_textured_shadow_def = Ref(false)
  let runtime_textureless_density_absent = Ref(false)
  let runtime_textured_density_present = Ref(false)
  let runtime_textureless_non_msaa = Ref(false)
  let runtime_textured_non_msaa = Ref(false)
  let runtime_textureless_no_atmosphere = Ref(false)
  let runtime_textured_no_atmosphere = Ref(false)
  for counter in counters {
    if counter.name() == "render_3d_volumetric_fog_pipeline_textureless" &&
      counter.value() > 0.0 {
      runtime_textureless.val = true
    }
    if counter.name() == "render_3d_volumetric_fog_pipeline_textured" &&
      counter.value() > 0.0 {
      runtime_textured.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textureless_shadow_filter_hardware_2x2" &&
      counter.value() > 0.0 {
      runtime_textureless_shadow_def.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textured_shadow_filter_hardware_2x2" &&
      counter.value() > 0.0 {
      runtime_textured_shadow_def.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textureless_density_texture" &&
      counter.value() == 0.0 {
      runtime_textureless_density_absent.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textured_density_texture" &&
      counter.value() > 0.0 {
      runtime_textured_density_present.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textureless_multisampled" &&
      counter.value() == 0.0 {
      runtime_textureless_non_msaa.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textured_multisampled" &&
      counter.value() == 0.0 {
      runtime_textured_non_msaa.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textureless_atmosphere" &&
      counter.value() == 0.0 {
      runtime_textureless_no_atmosphere.val = true
    }
    if counter.name() == "render_3d_volumetric_fog_pipeline_textured_atmosphere" &&
      counter.value() == 0.0 {
      runtime_textured_no_atmosphere.val = true
    }
  }
  debug_inspect(runtime_textureless.val, content="true")
  debug_inspect(runtime_textured.val, content="true")
  debug_inspect(runtime_textureless_shadow_def.val, content="true")
  debug_inspect(runtime_textured_shadow_def.val, content="true")
  debug_inspect(runtime_textureless_density_absent.val, content="true")
  debug_inspect(runtime_textured_density_present.val, content="true")
  debug_inspect(runtime_textureless_non_msaa.val, content="true")
  debug_inspect(runtime_textured_non_msaa.val, content="true")
  debug_inspect(runtime_textureless_no_atmosphere.val, content="true")
  debug_inspect(runtime_textured_no_atmosphere.val, content="true")
}

///|
test "scrolling_fog: runtime volumetric fog pass receives directional shadow resources" {
  let counters : Array[@app.TimelineTraceCounter] = []
  @app.set_timeline_trace_counter_sink(
    Some(fn(counter) { counters.push(counter) }),
  )
  let mut app = scrolling_fog_app()
  for _ in 0..<6 {
    app = app.update()
  }
  @app.clear_timeline_trace_counter_sink()

  let volumetric_view_counter = Ref(false)
  let volumetric_volume_counter = Ref(false)
  let volumetric_light_counter = Ref(false)
  let volumetric_uniform_counter = Ref(false)
  let directional_shadow_binding_counter = Ref(false)
  let main_pass_directional_shadow_counter = Ref(false)
  let volumetric_view_shadow_binding_counter = Ref(false)
  for counter in counters {
    if counter.name() == "render_3d_volumetric_fog_views" &&
      counter.value() > 0.0 {
      volumetric_view_counter.val = true
    }
    if counter.name() == "render_3d_volumetric_fog_volumes" &&
      counter.value() > 0.0 {
      volumetric_volume_counter.val = true
    }
    if counter.name() == "render_3d_volumetric_fog_lights" &&
      counter.value() > 0.0 {
      volumetric_light_counter.val = true
    }
    if counter.name() == "render_3d_volumetric_fog_uniforms" &&
      counter.value() > 0.0 {
      volumetric_uniform_counter.val = true
    }
    if counter.name() == "render_3d_directional_shadow_binding_resources" &&
      counter.value() > 0.0 {
      directional_shadow_binding_counter.val = true
    }
    if counter.name() == "render_3d_main_pass_directional_shadow_resources" &&
      counter.value() > 0.0 {
      main_pass_directional_shadow_counter.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_view_shadow_binding_resources" &&
      counter.value() > 0.0 {
      volumetric_view_shadow_binding_counter.val = true
    }
  }

  let render_world = app.sub_app(@app.RenderApp).world()
  let lighting = @pbr_render.render3d_collect_lighting(render_world)
  debug_inspect(lighting.directional_shadow_maps_enabled, content="true")
  debug_inspect(
    lighting.directional_cascade_bounds.length() > 0,
    content="true",
  )
  debug_inspect(
    lighting.directional_cascades.entries().length() > 0,
    content="true",
  )
  let render_view_count = Ref(0)
  let view_fog_count_positive = Ref(false)
  let view_fog_textured_volume = Ref(false)
  let view_fog_offset_valid = Ref(false)
  let view_pipeline_ids_valid = Ref(false)
  render_world.for_each_component(
    @pbr_volumetric_fog.ViewVolumetricFog::component(),
    fn(entity, view_fog) {
      render_view_count.val = render_view_count.val + 1
      view_fog_count_positive.val = view_fog_count_positive.val ||
        view_fog.count() > 0
      for volume in view_fog.volumes() {
        view_fog_textured_volume.val = view_fog_textured_volume.val ||
          volume.has_density_texture()
        view_fog_offset_valid.val = view_fog_offset_valid.val ||
          volume.uniform_buffer_offset() == 0U
      }
      match
        (try! render_world.get_by_key(
          entity,
          @pbr_volumetric_fog.ViewVolumetricFogPipelines::component(),
        )) {
        Some(pipelines) =>
          view_pipeline_ids_valid.val = view_pipeline_ids_valid.val ||
            (pipelines.textureless > 0 && pipelines.textured > 0)
        None => ()
      }
    },
  )

  debug_inspect(volumetric_view_counter.val, content="true")
  debug_inspect(volumetric_volume_counter.val, content="true")
  debug_inspect(volumetric_light_counter.val, content="true")
  debug_inspect(volumetric_uniform_counter.val, content="true")
  debug_inspect(directional_shadow_binding_counter.val, content="true")
  debug_inspect(main_pass_directional_shadow_counter.val, content="true")
  debug_inspect(volumetric_view_shadow_binding_counter.val, content="true")
  debug_inspect(render_view_count.val > 0, content="true")
  debug_inspect(view_fog_count_positive.val, content="true")
  debug_inspect(view_fog_textured_volume.val, content="true")
  debug_inspect(view_fog_offset_valid.val, content="true")
  debug_inspect(view_pipeline_ids_valid.val, content="true")
}

///|
test "scrolling_fog: pillar reaches directional shadow visible set" {
  let mut app = scrolling_fog_app()
  app = app.update()
  let world = app.world()
  let pillar_entity = Ref(None)
  let mesh_query : @ecs.Query[
    (@ecs.Read[@mesh.Mesh3d], @ecs.Read[@transform.Transform]),
    @ecs.All,
  ] = @ecs.query(world)
  try! mesh_query.view(fn(entity, data) {
    let (_mesh, transform_read) = data
    let transform = transform_read.value()
    if vec3_approx_eq(
        transform.translation,
        @math.Vec3::new(-10.0F, 4.5F, -11.0F),
      ) {
      pillar_entity.val = Some(entity)
    }
  })
  guard pillar_entity.val is Some(pillar) else {
    abort("expected scrolling_fog pillar entity")
  }
  let pillar_main_entity = @render.MainEntity::new(pillar)
  let mesh_visibility_class = @mesh.ecs_key_mesh3d.id().to_string()
  let render_world = app.sub_app(@app.RenderApp).world()
  let subview_count = Ref(0)
  let visible_cascade_count = Ref(0)
  let pillar_visible = Ref(false)
  render_world.for_each_component(
    @render_visibility.ecs_key_render_shadow_map_visible_entities,
    fn(_entity, shadow_visible) {
      shadow_visible.for_each_subview(fn(_retained_view, visible_entities) {
        subview_count.val = subview_count.val + 1
        match visible_entities.get(mesh_visibility_class) {
          Some(mesh_visible) => {
            if mesh_visible.visible_len() > 0 {
              visible_cascade_count.val = visible_cascade_count.val + 1
            }
            for pair in mesh_visible.iter_visible() {
              if pair.1.id() == pillar_main_entity.id() {
                pillar_visible.val = true
              }
            }
          }
          None => ()
        }
      })
    },
  )
  debug_inspect(subview_count.val > 0, content="true")
  debug_inspect(visible_cascade_count.val > 0, content="true")
  debug_inspect(pillar_visible.val, content="true")
}

///|
test "scrolling_fog: pillar resolves Bevy shadow specialization inputs" {
  let mut app = scrolling_fog_app()
  app = app.update()
  app = app.update()
  app = app.update()
  let world = app.world()
  let pillar_entity = Ref(None)
  let mesh_query : @ecs.Query[
    (@ecs.Read[@mesh.Mesh3d], @ecs.Read[@transform.Transform]),
    @ecs.All,
  ] = @ecs.query(world)
  try! mesh_query.view(fn(entity, data) {
    let (_mesh, transform_read) = data
    let transform = transform_read.value()
    if vec3_approx_eq(
        transform.translation,
        @math.Vec3::new(-10.0F, 4.5F, -11.0F),
      ) {
      pillar_entity.val = Some(entity)
    }
  })
  guard pillar_entity.val is Some(pillar) else {
    abort("expected scrolling_fog pillar entity")
  }
  let pillar_main_entity = @render.MainEntity::new(pillar)
  let render_world = app.sub_app(@app.RenderApp).world()
  let subview_count = Ref(0)
  let input_ready_count = Ref(0)
  let material_instance_found = Ref(false)
  let mesh_instance_found = Ref(false)
  let material_resolved = Ref(false)
  let material_shadows_enabled = Ref(false)
  let render_mesh_asset_found = Ref(false)
  let shadow_caster_flag_found = Ref(false)
  let helper_returns_queue_data = Ref(false)
  let helper_keeps_pending_empty = Ref(false)
  let render_material_instances = match
    render_world.get_resource(@pbr.ecs_key_render_material_instances) {
    Some(value) => value
    None => abort("expected RenderMaterialInstances resource")
  }
  let render_mesh_instances = match
    render_world.get_resource(@pbr.RenderMeshInstances::resource()) {
    Some(value) => value
    None => abort("expected RenderMeshInstances resource")
  }
  let resolved_material = match
    @pbr.render_material3d_resolved_slots_or_empty(render_world).get(pillar) {
    Some(Resolved(material)) => Some(material)
    Some(Pending) | None => None
  }
  let render_mesh_assets = match
    render_world.get_resource(@render_mesh.RenderMeshAssets::resource()) {
    Some(value) => value
    None => abort("expected RenderMeshAssets resource")
  }
  let mesh_queue_data = render_mesh_instances.render_mesh_queue_data(
    pillar_main_entity,
  )
  if render_material_instances.get(pillar) is Some(_) {
    material_instance_found.val = true
  }
  if mesh_queue_data is Some(queue_data) {
    mesh_instance_found.val = true
    shadow_caster_flag_found.val = queue_data
      .flags()
      .contains(@pbr.RenderMeshInstanceFlags::shadow_caster())
    if render_mesh_assets.get(queue_data.mesh_asset_id()) is Some(_) {
      render_mesh_asset_found.val = true
    }
  }
  if resolved_material is Some(material) {
    material_resolved.val = true
    material_shadows_enabled.val = material.material_properties().shadows_enabled
  }
  render_world.for_each_component(
    @render_visibility.ecs_key_render_shadow_map_visible_entities,
    fn(_entity, shadow_visible) {
      shadow_visible.for_each_subview(fn(retained_view, _visible_entities) {
        subview_count.val = subview_count.val + 1
        let fresh_pending = @render.ViewPendingQueues::ViewPendingQueues()
        match
          @pbr.render3d_shadow_specialization_queue_data(
            render_world, retained_view, pillar, pillar_main_entity, fresh_pending,
          ) {
          Some(_) => {
            input_ready_count.val = input_ready_count.val + 1
            helper_returns_queue_data.val = true
            helper_keeps_pending_empty.val = fresh_pending.current_len() == 0
          }
          None => ()
        }
      })
    },
  )
  debug_inspect(subview_count.val > 0, content="true")
  debug_inspect(material_instance_found.val, content="true")
  debug_inspect(mesh_instance_found.val, content="true")
  debug_inspect(material_resolved.val, content="true")
  debug_inspect(material_shadows_enabled.val, content="true")
  debug_inspect(render_mesh_asset_found.val, content="true")
  debug_inspect(shadow_caster_flag_found.val, content="true")
  debug_inspect(input_ready_count.val > 0, content="true")
  debug_inspect(helper_returns_queue_data.val, content="true")
  debug_inspect(helper_keeps_pending_empty.val, content="true")
}

///|
test "scrolling_fog: pillar produces shadow specialization cache entry" {
  let mut app = scrolling_fog_app()
  app = app.update()
  app = app.update()
  app = app.update()
  let world = app.world()
  let pillar_entity = Ref(None)
  let mesh_query : @ecs.Query[
    (@ecs.Read[@mesh.Mesh3d], @ecs.Read[@transform.Transform]),
    @ecs.All,
  ] = @ecs.query(world)
  try! mesh_query.view(fn(entity, data) {
    let (_mesh, transform_read) = data
    let transform = transform_read.value()
    if vec3_approx_eq(
        transform.translation,
        @math.Vec3::new(-10.0F, 4.5F, -11.0F),
      ) {
      pillar_entity.val = Some(entity)
    }
  })
  guard pillar_entity.val is Some(pillar) else {
    abort("expected scrolling_fog pillar entity")
  }
  let pillar_main_entity = @render.MainEntity::new(pillar)
  let render_world = app.sub_app(@app.RenderApp).world()
  let shadow_pipeline_cache = match
    render_world.get_resource(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    ) {
    Some(value) => value
    None => abort("expected SpecializedShadowMaterialPipelineCache resource")
  }
  let subview_count = Ref(0)
  let cache_entry_count = Ref(0)
  let pipeline_valid = Ref(false)
  let draw_function_valid = Ref(false)
  render_world.for_each_component(
    @render_visibility.ecs_key_render_shadow_map_visible_entities,
    fn(_entity, shadow_visible) {
      shadow_visible.for_each_subview(fn(retained_view, _visible_entities) {
        subview_count.val = subview_count.val + 1
        match shadow_pipeline_cache.get(retained_view) {
          Some(view_cache) =>
            match view_cache.get(pillar_main_entity) {
              Some(entry) => {
                cache_entry_count.val = cache_entry_count.val + 1
                let (pipeline_id, draw_function) = entry
                pipeline_valid.val = pipeline_valid.val ||
                  pipeline_id.id() > 0UL
                draw_function_valid.val = draw_function_valid.val ||
                  draw_function.id() > 0U
              }
              None => ()
            }
          None => ()
        }
      })
    },
  )
  debug_inspect(subview_count.val > 0, content="true")
  debug_inspect(cache_entry_count.val > 0, content="true")
  debug_inspect(pipeline_valid.val, content="true")
  debug_inspect(draw_function_valid.val, content="true")
}

///|
test "scrolling_fog: pillar produces queued directional shadow phase item" {
  let counters : Array[@app.TimelineTraceCounter] = []
  @app.set_timeline_trace_counter_sink(
    Some(fn(counter) { counters.push(counter) }),
  )
  let mut app = scrolling_fog_app()
  app = app.update()
  app = app.update()
  app = app.update()
  @app.clear_timeline_trace_counter_sink()
  let world = app.world()
  let pillar_entity = Ref(None)
  let mesh_query : @ecs.Query[
    (@ecs.Read[@mesh.Mesh3d], @ecs.Read[@transform.Transform]),
    @ecs.All,
  ] = @ecs.query(world)
  try! mesh_query.view(fn(entity, data) {
    let (_mesh, transform_read) = data
    let transform = transform_read.value()
    if vec3_approx_eq(
        transform.translation,
        @math.Vec3::new(-10.0F, 4.5F, -11.0F),
      ) {
      pillar_entity.val = Some(entity)
    }
  })
  guard pillar_entity.val is Some(pillar) else {
    abort("expected scrolling_fog pillar entity")
  }
  let pillar_main_entity = @render.MainEntity::new(pillar)
  let render_world = app.sub_app(@app.RenderApp).world()
  let shadow_phases = match
    render_world.get_resource(@pbr.Render3dShadowPhasesData::resource()) {
    Some(value) => value
    None => abort("expected Render3dShadowPhasesData resource")
  }
  let queued_item_found = Ref(false)
  let pipeline_valid = Ref(false)
  let draw_function_valid = Ref(false)
  let mesh_asset_valid = Ref(false)
  let material_bind_group_matches_depth_only = Ref(false)
  let mesh_slab_valid = Ref(false)
  let bin_mesh_asset_valid = Ref(false)
  let subview_count = Ref(0)
  let phase_hit_count = Ref(0)
  let phase_item_count = Ref(0)
  let shadow_phase_items_counter_positive = Ref(false)
  let shadow_binned_batches_counter_positive = Ref(false)
  for counter in counters {
    if counter.name() == "render_3d_shadow_phase_items" && counter.value() > 0.0 {
      shadow_phase_items_counter_positive.val = true
    }
    if counter.name() == "render_3d_shadow_binned_batches" &&
      counter.value() > 0.0 {
      shadow_binned_batches_counter_positive.val = true
    }
  }
  render_world.for_each_component(
    @render_visibility.ecs_key_render_shadow_map_visible_entities,
    fn(_entity, shadow_visible) {
      shadow_visible.for_each_subview(fn(retained_view, _visible_entities) {
        subview_count.val = subview_count.val + 1
        match shadow_phases.get(retained_view) {
          Some(phase) => {
            phase_hit_count.val = phase_hit_count.val + 1
            if phase.phase_type(pillar_main_entity) is Some(_) {
              queued_item_found.val = true
              phase_item_count.val = phase_item_count.val + 1
            }
            for item in phase.render_items(false) {
              if item.main_entity().id() == pillar_main_entity.id() {
                let batch_set_key = item.batch_set_key()
                let bin_key = item.bin_key()
                material_bind_group_matches_depth_only.val = material_bind_group_matches_depth_only.val ||
                  batch_set_key.material_bind_group_index() is None
                mesh_slab_valid.val = mesh_slab_valid.val ||
                  batch_set_key.slabs().vertex_slab_id() >= 0
                bin_mesh_asset_valid.val = bin_mesh_asset_valid.val ||
                  bin_key.mesh_asset_id() > 0
              }
            }
            match
              render_world.get_resource(
                @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
              ) {
              Some(cache) =>
                match cache.get(retained_view) {
                  Some(view_cache) =>
                    match view_cache.get(pillar_main_entity) {
                      Some(entry) => {
                        let (pipeline_id, draw_function) = entry
                        pipeline_valid.val = pipeline_valid.val ||
                          pipeline_id.id() > 0UL
                        draw_function_valid.val = draw_function_valid.val ||
                          draw_function.id() > 0U
                      }
                      None => ()
                    }
                  None => ()
                }
              None => ()
            }
            match
              render_world.get_resource(@pbr.RenderMeshInstances::resource()) {
              Some(mesh_instances) =>
                match
                  mesh_instances.render_mesh_queue_data(pillar_main_entity) {
                  Some(mesh_instance) =>
                    mesh_asset_valid.val = mesh_asset_valid.val ||
                      mesh_instance.mesh_asset_id() > 0
                  None => ()
                }
              None => ()
            }
          }
          None => ()
        }
      })
    },
  )
  debug_inspect(subview_count.val > 0, content="true")
  debug_inspect(phase_hit_count.val > 0, content="true")
  debug_inspect(phase_item_count.val > 0, content="true")
  debug_inspect(queued_item_found.val, content="true")
  debug_inspect(pipeline_valid.val, content="true")
  debug_inspect(draw_function_valid.val, content="true")
  debug_inspect(mesh_asset_valid.val, content="true")
  debug_inspect(material_bind_group_matches_depth_only.val, content="true")
  debug_inspect(mesh_slab_valid.val, content="true")
  debug_inspect(bin_mesh_asset_valid.val, content="true")
  debug_inspect(shadow_phase_items_counter_positive.val, content="true")
  debug_inspect(shadow_binned_batches_counter_positive.val, content="true")
}
