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
