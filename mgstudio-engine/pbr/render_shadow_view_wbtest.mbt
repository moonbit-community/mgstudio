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
    Render3dLightEntity::Point(light_entity=light, face_index=0),
  )
  let point1 = render3d_shadow_view_cache_key(
    camera,
    Render3dLightEntity::Point(light_entity=light, face_index=1),
  )
  let cascade0 = render3d_shadow_view_cache_key(
    camera,
    Render3dLightEntity::Directional(light_entity=light, cascade_index=0),
  )
  let spot = render3d_shadow_view_cache_key(
    camera,
    Render3dLightEntity::Spot(light_entity=light),
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
    cascade_index=2,
  )
  let point = Render3dLightEntity::Point(light_entity=light, face_index=5)
  let spot = Render3dLightEntity::Spot(light_entity=light)
  let directional_key = directional.shadow_map_visible_retained_view(
    extracted_retained_view,
  )
  let point_key = point.shadow_map_visible_retained_view(
    extracted_retained_view,
  )
  let spot_key = spot.shadow_map_visible_retained_view(extracted_retained_view)

  inspect(directional.shadow_map_visible_entity().id, content="32")
  inspect(directional_key.main_entity().id, content="30")
  inspect(directional_key.auxiliary_entity().id, content="31")
  inspect(directional_key.subview_index(), content="4")
  inspect(point_key.main_entity().id, content="30")
  inspect(point_key.auxiliary_entity().id, content="-1")
  inspect(point_key.subview_index(), content="5")
  inspect(spot_key.main_entity().id, content="30")
  inspect(spot_key.auxiliary_entity().id, content="-1")
  inspect(spot_key.subview_index(), content="0")
}

///|
test "pbr directional shadow view mirrors Bevy occlusion culling subview marker" {
  let lighting = Render3dLightingState::{
    ..@pbr_render.render3d_default_lighting_state(),
    directional_occlusion_culling: true,
  }
  let subview = render3d_directional_shadow_occlusion_culling_subview(
    lighting, 17, 2048,
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
    @pbr_render.render3d_default_lighting_state(),
    17,
    2048,
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
  let lighting = Render3dLightingState::{
    ..@pbr_render.render3d_default_lighting_state(),
    directional_transform: @transform.Transform::identity(),
    directional_cascade_bounds: [42.0F],
    directional_cascades: cascades,
  }

  let cascade_passes = render3d_directional_shadow_cascades(camera, lighting)
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
  let point_entity = world.spawn()
  let meta = GlobalClusterableObjectMeta::new(0U)
  meta.insert_entity_index(point_entity, 3)
  world.insert_resource(ecs_key_global_clusterable_object_meta, meta)
  let lighting = Render3dLightingState::{
    ..@pbr_render.render3d_default_lighting_state(),
    point_entity: Some(point_entity),
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
