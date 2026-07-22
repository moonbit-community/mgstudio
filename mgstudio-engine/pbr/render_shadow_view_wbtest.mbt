///|
extend Render3dDirectionalLightShadowTargets with @app.Resource::{resource}

///|
fn shadow_view_approx_eq(a : Float, b : Float) -> Bool {
  let delta = a - b
  if delta < 0.0F {
    -delta <= 1.0e-6F
  } else {
    delta <= 1.0e-6F
  }
}

///|
test "pbr shadow view cache keys are distinct per Bevy retained shadow view" {
  let camera = @core.Entity::new(3, 1)
  let light = @core.Entity::new(9, 2)
  let point0 = render3d_shadow_view_cache_key(
    camera,
    Point(light_entity=light, main_entity=light, face_index=0),
  )
  let point1 = render3d_shadow_view_cache_key(
    camera,
    Point(light_entity=light, main_entity=light, face_index=1),
  )
  let cascade0 = render3d_shadow_view_cache_key(
    camera,
    Directional(light_entity=light, main_entity=light, cascade_index=0),
  )
  let spot = render3d_shadow_view_cache_key(
    camera,
    Spot(light_entity=light, main_entity=light),
  )
  inspect(point0 == point1, content="false")
  inspect(point0 == cascade0, content="false")
  inspect(point0 == spot, content="false")
  inspect(cascade0 == spot, content="false")
}

///|
test "pbr shadow map visible subview keys mirror Bevy light entity rules" {
  let main = @core.Entity::new(30, 1)
  let auxiliary = @core.Entity::new(31, 1)
  let extracted_retained_view = @render_view.RetainedViewEntity::new(
    main,
    auxiliary_entity=Some(auxiliary),
    subview_index=4,
  )
  let light = @core.Entity::new(32, 1)
  let directional = Render3dLightEntity::Directional(
    light_entity=light,
    main_entity=light,
    cascade_index=2,
  )
  let point = Render3dLightEntity::Point(
    light_entity=light,
    main_entity=light,
    face_index=5,
  )
  let spot = Render3dLightEntity::Spot(light_entity=light, main_entity=light)
  let directional_phase_key = directional.shadow_phase_retained_view(
    extracted_retained_view,
  )
  let point_phase_key = point.shadow_phase_retained_view(
    extracted_retained_view,
  )
  let spot_phase_key = spot.shadow_phase_retained_view(extracted_retained_view)
  let directional_key = directional.shadow_map_visible_retained_view(
    directional_phase_key,
  )
  let point_key = point.shadow_map_visible_retained_view(point_phase_key)
  let spot_key = spot.shadow_map_visible_retained_view(spot_phase_key)

  inspect(directional.shadow_map_visible_entity().id, content="32")
  inspect(directional_key.main_entity().id, content="32")
  inspect(directional_key.auxiliary_entity().id, content="30")
  inspect(directional_key.subview_index(), content="2")
  inspect(point_key.main_entity().id, content="32")
  inspect(point_key.auxiliary_entity().id, content="-1")
  inspect(point_key.subview_index(), content="5")
  inspect(spot_key.main_entity().id, content="32")
  inspect(spot_key.auxiliary_entity().id, content="-1")
  inspect(spot_key.subview_index(), content="0")
}

///|
test "pbr shadow phase retained view keys mirror Bevy prepare_lights" {
  let camera = @core.Entity::new(30, 1)
  let auxiliary = @core.Entity::new(31, 1)
  let extracted_retained_view = @render_view.RetainedViewEntity::new(
    camera,
    auxiliary_entity=Some(auxiliary),
    subview_index=4,
  )
  let light = @core.Entity::new(32, 1)
  let directional = Render3dLightEntity::Directional(
    light_entity=light,
    main_entity=light,
    cascade_index=2,
  )
  let point = Render3dLightEntity::Point(
    light_entity=light,
    main_entity=light,
    face_index=5,
  )
  let spot = Render3dLightEntity::Spot(light_entity=light, main_entity=light)
  let directional_key = directional.shadow_phase_retained_view(
    extracted_retained_view,
  )
  let point_key = point.shadow_phase_retained_view(extracted_retained_view)
  let spot_key = spot.shadow_phase_retained_view(extracted_retained_view)

  inspect(directional_key.main_entity().id, content="32")
  inspect(directional_key.auxiliary_entity().id, content="30")
  inspect(directional_key.subview_index(), content="2")
  inspect(point_key.main_entity().id, content="32")
  inspect(point_key.auxiliary_entity().id, content="-1")
  inspect(point_key.subview_index(), content="5")
  inspect(spot_key.main_entity().id, content="32")
  inspect(spot_key.auxiliary_entity().id, content="-1")
  inspect(spot_key.subview_index(), content="0")
}

///|
test "pbr directional shadow view mirrors Bevy occlusion culling subview marker" {
  let subview = render3d_directional_shadow_occlusion_culling_subview(
    true, 17, 2048,
  )
  inspect(subview is Some(_), content="true")
  guard subview is Some(subview) else {
    abort("expected directional shadow occlusion culling subview")
  }
  inspect(subview.depth_texture_view_id(), content="17")
  inspect(subview.depth_texture_size(), content="2048")
}

///|
test "pbr directional shadow view omits occlusion culling subview when disabled" {
  let subview = render3d_directional_shadow_occlusion_culling_subview(
    false, 17, 2048,
  )
  inspect(subview is None, content="true")
}

///|
test "pbr directional shadow view consumes extracted light cascades" {
  let camera = @core.Entity::new(3, 1)
  let cascades = @light.Cascades::Cascades()
  cascades.set(camera, [
    @light.Cascade::new(
      @math.Mat4::from_cols(
        @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
        @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
        @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
        @math.Vec4::new(8.0F, 9.0F, 10.0F, 1.0F),
      ),
      @math.Mat4::identity(),
      @math.Mat4::from_cols(
        @math.Vec4::new(2.0F, 0.0F, 0.0F, 0.0F),
        @math.Vec4::new(0.0F, 3.0F, 0.0F, 0.0F),
        @math.Vec4::new(0.0F, 0.0F, 4.0F, 0.0F),
        @math.Vec4::new(5.0F, 6.0F, 7.0F, 1.0F),
      ),
      0.25F,
    ),
  ])
  let directional = shadow_view_test_directional_entry(
    @core.Entity::new(5, 1),
    @core.Entity::new(6, 1),
    cascades,
    [42.0F],
  )
  let cascade_passes = render3d_directional_shadow_cascades_for_light(
    camera,
    directional.light,
  )
  inspect(cascade_passes.length(), content="1")
  inspect(
    shadow_view_approx_eq(cascade_passes[0].transform.translation.x, 8.0F),
    content="true",
  )
  inspect(
    shadow_view_approx_eq(cascade_passes[0].texel_size, 0.25F),
    content="true",
  )
  let data = render3d_directional_shadow_cascade_data(cascade_passes)
  inspect(shadow_view_approx_eq(data[0], 2.0F), content="true")
  inspect(shadow_view_approx_eq(data[5], 3.0F), content="true")
  inspect(shadow_view_approx_eq(data[10], 4.0F), content="true")
  inspect(shadow_view_approx_eq(data[15], 1.0F), content="true")
  inspect(shadow_view_approx_eq(data[16], 0.25F), content="true")
  inspect(shadow_view_approx_eq(data[17], 42.0F), content="true")
}

///|
fn shadow_view_test_camera_payload() -> Camera3dViewPayload {
  {
    decal_config: None,
    deferred_config: None,
    distance_fog: None,
    auto_exposure: None,
    volumetric_fog: None,
    atmosphere: None,
    atmosphere_settings: None,
    camera: Camera(),
    depth_texture_usages: Camera3dDepthTextureUsage(),
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
    transform: Transform(),
    previous_transform: Transform(),
    previous_clip_from_world: None,
    target_id: 0,
    target_size: @math.IVec2::new(1280, 720),
    scale_factor: 1.0F,
    layers: RenderLayers(),
    invert_culling: false,
  }
}

///|
fn shadow_view_test_cascade(
  scale : Float,
  texel_size : Float,
) -> @light.Cascade {
  @light.Cascade::new(
    @math.Mat4::identity(),
    @math.Mat4::identity(),
    @math.Mat4::from_cols(
      @math.Vec4::new(scale, 0.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, scale, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 0.0F, scale, 0.0F),
      @math.Vec4::new(0.0F, 0.0F, 0.0F, 1.0F),
    ),
    texel_size,
  )
}

///|
fn shadow_view_test_directional_entry(
  light : @core.Entity,
  render_light : @core.Entity,
  cascades : @light.Cascades,
  bounds : Array[Float],
) -> @pbr_render.Render3dLightingDirectionalLight {
  {
    render_entity: render_light,
    light: @pbr_render.render3d_extracted_directional_light_for_shadow(
      light,
      @transform.Transform::identity(),
      cascades,
      bounds,
      RenderLayers(),
      false,
    ),
  }
}

///|
test "pbr directional shadow binding carries cascades for volumetric fog pass" {
  let world = @ecs.World::new()
  defer world.close()
  let camera = world.spawn()
  let light = world.spawn()
  let render_light = world.spawn()
  let cascades = @light.Cascades::Cascades()
  cascades.set(camera, [
    shadow_view_test_cascade(1.0F, 0.125F),
    shadow_view_test_cascade(2.0F, 0.25F),
    shadow_view_test_cascade(3.0F, 0.5F),
    shadow_view_test_cascade(4.0F, 1.0F),
  ])
  world.insert_resource(
    @light.ecs_key_directional_light_shadow_map,
    @light.DirectionalLightShadowMap::new(4096),
  )
  world.insert_resource(Render3dDirectionalLightShadowTargets::resource(), {
    entries: [{ camera_entity: camera, size: 4096, layers: 4, target_id: 77 }],
  })
  let lighting = Render3dLightingState::{
    ..@pbr_render.render3d_default_lighting_state(),
    directional_lights: [
      shadow_view_test_directional_entry(light, render_light, cascades, [
        8.0F, 16.0F, 32.0F, 64.0F,
      ]),
    ],
  }

  let plan = render3d_prepare_camera_directional_shadow_pass(
    world,
    camera,
    shadow_view_test_camera_payload(),
    lighting,
    [],
    0,
  )

  inspect(plan.binding.texture_id, content="77")
  inspect(shadow_view_approx_eq(plan.binding.enabled, 1.0F), content="true")
  inspect(plan.binding.cascade_count, content="4")
  inspect(plan.binding.cascade_data.length(), content="80")
  if plan.binding.cascade_data.length() >= 18 {
    inspect(
      shadow_view_approx_eq(plan.binding.cascade_data[0], 1.0F),
      content="true",
    )
    inspect(
      shadow_view_approx_eq(plan.binding.cascade_data[17], 8.0F),
      content="true",
    )
  } else {
    inspect(false, content="true")
  }
  inspect(plan.phase_views.length(), content="4")
  inspect(plan.queued_phase_views.length(), content="4")
}

///|
test "pbr directional shadow pass attaches Bevy-shaped target layers" {
  let world = @ecs.World::new()
  defer world.close()
  let camera = world.spawn()
  let light = world.spawn()
  let render_light = world.spawn()
  let cascades = @light.Cascades::Cascades()
  cascades.set(camera, [
    shadow_view_test_cascade(1.0F, 0.125F),
    shadow_view_test_cascade(2.0F, 0.25F),
    shadow_view_test_cascade(3.0F, 0.5F),
  ])
  world.insert_resource(
    @light.ecs_key_directional_light_shadow_map,
    @light.DirectionalLightShadowMap::new(2048),
  )
  world.insert_resource(Render3dDirectionalLightShadowTargets::resource(), {
    entries: [{ camera_entity: camera, size: 2048, layers: 3, target_id: 91 }],
  })
  let lighting = Render3dLightingState::{
    ..@pbr_render.render3d_default_lighting_state(),
    directional_lights: [
      shadow_view_test_directional_entry(light, render_light, cascades, [
        10.0F, 25.0F, 50.0F,
      ]),
    ],
  }

  let plan = render3d_prepare_camera_directional_shadow_pass(
    world,
    camera,
    shadow_view_test_camera_payload(),
    lighting,
    [],
    @pbr_render.RENDER3D_PASS_KIND_BASE_DIRECTIONAL_SHADOW,
  )

  inspect(plan.phase_views.length(), content="3")
  for i in 0..<plan.phase_views.length() {
    let view = plan.phase_views[i]
    let shadow_view = view.phase_view.shadow_view
    inspect(shadow_view.target_id, content="91")
    inspect(shadow_view.target_layer, content="\{i}")
    inspect(shadow_view.width, content="2048")
    inspect(shadow_view.height, content="2048")
    inspect(
      shadow_view.pass_name,
      content="shadow_directional_light_0_cascade_\{i}",
    )
    inspect(
      view.pass_kind,
      content="\{@pbr_render.RENDER3D_PASS_KIND_BASE_DIRECTIONAL_SHADOW}",
    )
  }
}

///|
test "pbr directional shadow pass accumulates multiple Bevy directional lights" {
  let world = @ecs.World::new()
  defer world.close()
  let camera = world.spawn()
  let first_light = world.spawn()
  let first_render_light = world.spawn()
  let second_light = world.spawn()
  let second_render_light = world.spawn()
  let first_cascades = @light.Cascades::Cascades()
  first_cascades.set(camera, [
    shadow_view_test_cascade(1.0F, 0.125F),
    shadow_view_test_cascade(2.0F, 0.25F),
  ])
  let second_cascades = @light.Cascades::Cascades()
  second_cascades.set(camera, [
    shadow_view_test_cascade(3.0F, 0.5F),
    shadow_view_test_cascade(4.0F, 1.0F),
    shadow_view_test_cascade(5.0F, 2.0F),
  ])
  world.insert_resource(
    @light.ecs_key_directional_light_shadow_map,
    @light.DirectionalLightShadowMap::new(2048),
  )
  world.insert_resource(Render3dDirectionalLightShadowTargets::resource(), {
    entries: [{ camera_entity: camera, size: 2048, layers: 5, target_id: 133 }],
  })
  let lighting = Render3dLightingState::{
    ..@pbr_render.render3d_default_lighting_state(),
    directional_lights: [
      shadow_view_test_directional_entry(
        first_light,
        first_render_light,
        first_cascades,
        [8.0F, 16.0F],
      ),
      shadow_view_test_directional_entry(
        second_light,
        second_render_light,
        second_cascades,
        [32.0F, 64.0F, 128.0F],
      ),
    ],
  }

  let plan = render3d_prepare_camera_directional_shadow_pass(
    world,
    camera,
    shadow_view_test_camera_payload(),
    lighting,
    [],
    @pbr_render.RENDER3D_PASS_KIND_BASE_DIRECTIONAL_SHADOW,
  )

  inspect(plan.binding.texture_id, content="133")
  inspect(plan.binding.cascade_count, content="5")
  inspect(plan.binding.cascade_data.length(), content="100")
  inspect(plan.phase_views.length(), content="5")
  inspect(plan.queued_phase_views.length(), content="5")
  for i in 0..<plan.phase_views.length() {
    inspect(
      plan.phase_views[i].phase_view.shadow_view.target_layer,
      content="\{i}",
    )
  }
  inspect(
    plan.phase_views[0].phase_view.shadow_view.pass_name,
    content="shadow_directional_light_0_cascade_0",
  )
  inspect(
    plan.phase_views[1].phase_view.shadow_view.pass_name,
    content="shadow_directional_light_0_cascade_1",
  )
  inspect(
    plan.phase_views[2].phase_view.shadow_view.pass_name,
    content="shadow_directional_light_1_cascade_0",
  )
  inspect(
    plan.phase_views[4].phase_view.shadow_view.pass_name,
    content="shadow_directional_light_1_cascade_2",
  )
  inspect(
    shadow_view_approx_eq(plan.binding.cascade_data[17], 8.0F),
    content="true",
  )
  inspect(
    shadow_view_approx_eq(plan.binding.cascade_data[37], 16.0F),
    content="true",
  )
  inspect(
    shadow_view_approx_eq(plan.binding.cascade_data[57], 32.0F),
    content="true",
  )
  inspect(
    shadow_view_approx_eq(plan.binding.cascade_data[77], 64.0F),
    content="true",
  )
  inspect(
    shadow_view_approx_eq(plan.binding.cascade_data[97], 128.0F),
    content="true",
  )
  let retained_view = plan.phase_views[2].phase_view.shadow_view.light_entity.shadow_phase_retained_view(
    @render_view.RetainedViewEntity::new(camera),
  )
  inspect(retained_view.main_entity().id, content="\{second_light.id}")
  inspect(retained_view.auxiliary_entity().id, content="\{camera.id}")
  inspect(retained_view.subview_index(), content="0")
  match plan.phase_views[2].phase_view.shadow_view.light_entity {
    Directional(light_entity~, main_entity~, cascade_index~) => {
      inspect(light_entity.id, content="\{second_render_light.id}")
      inspect(main_entity.id, content="\{second_light.id}")
      inspect(cascade_index, content="0")
    }
    _ => inspect(false, content="true")
  }
}

///|
test "pbr directional shadow frame identity reaches volumetric view binding" {
  let world = @ecs.World::new()
  defer world.close()
  let camera = world.spawn()
  let light = world.spawn()
  let render_light = world.spawn()
  let cascades = @light.Cascades::Cascades()
  cascades.set(camera, [
    shadow_view_test_cascade(1.0F, 0.125F),
    shadow_view_test_cascade(2.0F, 0.25F),
  ])
  world.insert_resource(
    @light.ecs_key_directional_light_shadow_map,
    @light.DirectionalLightShadowMap::new(1024),
  )
  world.insert_resource(Render3dDirectionalLightShadowTargets::resource(), {
    entries: [{ camera_entity: camera, size: 1024, layers: 2, target_id: 123 }],
  })
  let lighting = Render3dLightingState::{
    ..@pbr_render.render3d_default_lighting_state(),
    directional_lights: [
      shadow_view_test_directional_entry(light, render_light, cascades, [
        8.0F, 16.0F,
      ]),
    ],
  }

  let plan = render3d_prepare_camera_shadow_passes(
    world,
    camera,
    shadow_view_test_camera_payload(),
    lighting,
    [],
    512,
    @pbr_render.RENDER3D_PASS_KIND_BASE_POINT_SHADOW,
    @pbr_render.RENDER3D_PASS_KIND_BASE_DIRECTIONAL_SHADOW,
  )

  inspect(plan.bindings.directional.texture_id, content="123")
  inspect(plan.bindings.directional.cascade_count, content="2")
  inspect(plan.bindings.directional.cascade_data.length(), content="40")
  inspect(plan.phase_views.length(), content="2")
  inspect(plan.queued_phase_views.length(), content="2")
  for i in 0..<plan.phase_views.length() {
    let execution_view = plan.phase_views[i]
    let shadow_view = execution_view.phase_view.shadow_view
    inspect(
      shadow_view.target_id,
      content="\{plan.bindings.directional.texture_id}",
    )
    inspect(shadow_view.target_layer, content="\{i}")
    let retained_view = shadow_view.light_entity.shadow_phase_retained_view(
      @render_view.RetainedViewEntity::new(camera),
    )
    inspect(retained_view.main_entity().id, content="\{light.id}")
    inspect(retained_view.auxiliary_entity().id, content="\{camera.id}")
    inspect(retained_view.subview_index(), content="\{i}")
    match shadow_view.light_entity {
      Directional(light_entity~, main_entity~, cascade_index~) => {
        inspect(light_entity.id, content="\{render_light.id}")
        inspect(light_entity.generation, content="\{render_light.generation}")
        inspect(main_entity.id, content="\{light.id}")
        inspect(main_entity.generation, content="\{light.generation}")
        inspect(cascade_index, content="\{i}")
      }
      _ => inspect(false, content="true")
    }
  }
}

///|
test "pbr directional shadow target reserves Bevy spot layers" {
  inspect(render3d_directional_spot_shadow_target_layers(4, 0), content="4")
  inspect(render3d_directional_spot_shadow_target_layers(4, 1), content="5")
  inspect(render3d_directional_spot_shadow_target_layers(4, 3), content="7")
  inspect(render3d_directional_spot_shadow_target_layers(0, 1), content="1")
  inspect(render3d_directional_spot_shadow_target_layers(0, 0), content="1")
}

///|
test "pbr spot shadow target layer follows Bevy directional-array indexing" {
  inspect(render3d_spot_shadow_target_layer(4, 0), content="4")
  inspect(render3d_spot_shadow_target_layer(4, 2), content="6")
  inspect(render3d_spot_shadow_target_layer(0, 2), content="2")
}

///|
test "pbr point shadow target layer follows Bevy cubemap array indexing" {
  inspect(render3d_point_shadow_target_layer(0, 0), content="0")
  inspect(render3d_point_shadow_target_layer(0, 5), content="5")
  inspect(render3d_point_shadow_target_layer(2, 0), content="12")
  inspect(render3d_point_shadow_target_layer(2, 5), content="17")
}

///|
test "pbr lighting state uses global clusterable point light index" {
  let world = @ecs.World::new()
  defer world.close()
  let point_entity = world.spawn()
  let meta = GlobalClusterableObjectMeta::new(0U)
  meta.insert_entity_index(point_entity, 3)
  world.insert_resource(ecs_key_global_clusterable_object_meta, meta)
  let lighting = Render3dLightingState::{
    ..@pbr_render.render3d_default_lighting_state(),
    point_entity: Some(point_entity),
    point_render_entity: Some(point_entity),
  }
  let resolved = render3d_lighting_with_clusterable_indices(world, lighting)
  inspect(resolved.point_light_index, content="3")
}

///|
test "pbr spot light index subtracts Bevy point light prefix" {
  inspect(render3d_spot_light_index_from_global_index(1, 1), content="0")
  inspect(render3d_spot_light_index_from_global_index(3, 1), content="2")
  inspect(render3d_spot_light_index_from_global_index(0, 2), content="0")
}

///|
test "pbr shadow view pass names match Bevy light and view indices" {
  inspect(
    render3d_directional_shadow_pass_name(0, 2),
    content="shadow_directional_light_0_cascade_2",
  )
  inspect(
    render3d_point_shadow_pass_name(0, 5),
    content="shadow_point_light_0_-z",
  )
  inspect(render3d_cube_face_index_to_name(6), content="invalid")
  inspect(render3d_spot_shadow_pass_name(0), content="shadow_spot_light_0")
}
