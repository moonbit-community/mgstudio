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
