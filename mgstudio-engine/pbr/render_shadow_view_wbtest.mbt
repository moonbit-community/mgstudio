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
  inspect(point0 == point1, content="false")
  inspect(point0 == cascade0, content="false")
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
