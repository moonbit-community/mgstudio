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
fn approx_eq(a : Float, b : Float, eps : Float) -> Bool {
  let delta = a - b
  if delta < 0.0F {
    -delta <= eps
  } else {
    delta <= eps
  }
}

///|
fn test_u8_at(bytes : Bytes, index : Int) -> Int {
  match bytes.get(index) {
    Some(value) => value.to_int() & 0xFF
    None => 0
  }
}

///|
fn test_u32le_at(bytes : Bytes, index : Int) -> UInt {
  (test_u8_at(bytes, index) & 0xFF).reinterpret_as_uint() |
  ((test_u8_at(bytes, index + 1) & 0xFF).reinterpret_as_uint() << 8) |
  ((test_u8_at(bytes, index + 2) & 0xFF).reinterpret_as_uint() << 16) |
  ((test_u8_at(bytes, index + 3) & 0xFF).reinterpret_as_uint() << 24)
}

///|
fn test_f32_bits(value : Float) -> UInt {
  value.reinterpret_as_uint()
}

///|
test "pbr render light: fallback spot angles match Bevy defaults" {
  let world = @ecs.World::new()
  let lighting = render3d_collect_lighting(world)
  inspect(approx_eq(lighting.spot_inner_angle, 0.0F, 1.0e-6F), content="true")
  inspect(
    approx_eq(lighting.spot_outer_angle, @math.pi() / 4.0F, 1.0e-6F),
    content="true",
  )
}

///|
test "pbr render light: gpu lights uniform bytes match mesh_view_types native layout" {
  let world = @ecs.World::new()
  let directional = world.spawn()
  try! (world.set_by_key(
    directional,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight(),
  )
  |> ignore)
  let rect = world.spawn()
  try! (world.set_by_key(
    rect,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(1.0F, 2.0F, 3.0F),
  )
  |> ignore)
  try! (world.set_by_key(
    rect,
    @light.ecs_key_rect_light,
    @light.RectLight::new(
      @color.Color::new(0.25F, 0.5F, 0.75F, 1.0F),
      32.0F * @math.pi(),
      12.0F,
      4.0F,
      8.0F,
    ),
  )
  |> ignore)
  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  inspect(gpu_lights.n_directional_lights, content="1")
  inspect(gpu_lights.n_rect_lights, content="1")
  inspect(gpu_lights.rect_lights.length(), content=MAX_RECT_LIGHTS.to_string())
  let bytes = render3d_gpu_lights_uniform_bytes(gpu_lights)
  inspect(bytes.length(), content="4576")
  inspect(test_u32le_at(bytes, 4048), content="1")
  inspect(test_u32le_at(bytes, 4060), content="1")
  inspect(test_u32le_at(bytes, 4064), content=test_f32_bits(0.25F).to_string())
  inspect(test_u32le_at(bytes, 4080), content=test_f32_bits(1.0F).to_string())
  inspect(test_u32le_at(bytes, 4092), content=test_f32_bits(4.0F).to_string())
}

///|
fn test_cluster_offsets_has_point_light(
  bytes : Bytes,
  cluster_count : Int,
) -> Bool {
  let mut cluster_index = 0
  while cluster_index < cluster_count {
    if test_u32le_at(bytes, cluster_index * 32 + 4) > 0U {
      return true
    }
    cluster_index += 1
  }
  false
}

///|
fn test_cluster_offsets_has_decal(bytes : Bytes, cluster_count : Int) -> Bool {
  let mut cluster_index = 0
  while cluster_index < cluster_count {
    if test_u32le_at(bytes, cluster_index * 32 + 20) > 0U {
      return true
    }
    cluster_index += 1
  }
  false
}

///|
fn test_cluster_decal_index_matches(
  offsets : Bytes,
  indices : Bytes,
  cluster_count : Int,
  expected_index : UInt,
) -> Bool {
  let mut cluster_index = 0
  while cluster_index < cluster_count {
    let cluster_offset = cluster_index * 32
    let base = test_u32le_at(offsets, cluster_offset).reinterpret_as_int()
    let point_count = test_u32le_at(offsets, cluster_offset + 4).reinterpret_as_int()
    let spot_count = test_u32le_at(offsets, cluster_offset + 8).reinterpret_as_int()
    let reflection_count = test_u32le_at(offsets, cluster_offset + 12).reinterpret_as_int()
    let irradiance_count = test_u32le_at(offsets, cluster_offset + 16).reinterpret_as_int()
    let decal_count = test_u32le_at(offsets, cluster_offset + 20).reinterpret_as_int()
    if decal_count > 0 {
      let decal_offset = base +
        point_count +
        spot_count +
        reflection_count +
        irradiance_count
      return test_u32le_at(indices, decal_offset * 4) == expected_index
    }
    cluster_index += 1
  }
  false
}

///|
test "pbr render light: LightKeyCache stores keys by retained view entity" {
  let cache = LightKeyCache::LightKeyCache()
  let main_view = @core.Entity::new(10, 1)
  let first = @render_view.RetainedViewEntity::new(
    main_view,
    auxiliary_entity=Some(@core.Entity::new(20, 1)),
    subview_index=0,
  )
  let second = @render_view.RetainedViewEntity::new(
    main_view,
    auxiliary_entity=Some(@core.Entity::new(20, 1)),
    subview_index=1,
  )

  cache.insert(
    first,
    @material.ErasedMeshPipelineKey::new(3UL, "MeshPipelineKey"),
  )
  cache.insert(
    second,
    @material.ErasedMeshPipelineKey::new(7UL, "MeshPipelineKey"),
  )

  debug_inspect(cache.len(), content="2")
  debug_inspect(cache.get(first).map(fn(key) { key.bits() }), content="Some(3)")
  debug_inspect(
    cache.get(second).map(fn(key) { key.bits() }),
    content="Some(7)",
  )
}

///|
test "pbr render light: SpecializedShadowMaterialPipelineCache stores per view light pipelines" {
  let cache = SpecializedShadowMaterialPipelineCache::SpecializedShadowMaterialPipelineCache()
  let view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(10, 1),
    auxiliary_entity=Some(@core.Entity::new(20, 1)),
    subview_index=2,
  )
  let entity = @render_gpu.MainEntity::new(@core.Entity::new(11, 1))
  let pipeline_id = @material.CachedRenderPipelineId::new(55UL)
  let draw_function_id = @material.DrawFunctionId::new(3U)

  cache.insert(view, entity, pipeline_id, draw_function_id)

  debug_inspect(cache.len(), content="1")
  debug_inspect(
    cache.pipeline_id(view, entity).map(fn(value) { value.id() }),
    content="Some(55)",
  )
  let cached_entry = match cache.get(view) {
    Some(view_cache) => view_cache.get(entity)
    None => None
  }
  match cached_entry {
    Some((cached_pipeline, cached_draw)) => {
      debug_inspect(cached_pipeline.id(), content="55")
      debug_inspect(cached_draw.id(), content="3")
    }
    None => debug_inspect(false, content="true")
  }
}

///|
fn light_test_propagate_transforms(world : @ecs.World) -> Unit {
  @hierarchy.hierarchy_install_component_metadata()
  @transform.transform_install_component_metadata()
  let tick = @core.SystemTicks::new(
    world.get_tick_context().ticks().this_run,
    world.increment_change_tick(),
  )
  let ctx = @core.SystemTickContext::new()
  ctx.set(tick)
  world.set_tick_context(ctx)
  @transform.mark_dirty_trees_ecs(world)
  @transform.propagate_transforms_system_ecs(world)
  @transform.sync_simple_transforms_world(world)
}

///|
fn light_test_sync_light_entity(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  if (try! world.get_by_key(entity, @render_gpu.ecs_key_render_entity)) is None {
    try! world.set_by_key(
      entity,
      @render_gpu.ecs_key_render_entity,
      @render_gpu.RenderEntity::new(entity),
    )
  }
  if (try! world.get_by_key(entity, @render_gpu.ecs_key_main_entity)) is None {
    try! world.set_by_key(
      entity,
      @render_gpu.ecs_key_main_entity,
      @render_gpu.MainEntity::new(entity),
    )
  }
}

///|
fn light_test_extract_lights(world : @ecs.World) -> Unit {
  world.for_each_component(@light.ecs_key_point_light, fn(entity, _) {
    light_test_sync_light_entity(world, entity)
  })
  world.for_each_component(@light.ecs_key_spot_light, fn(entity, _) {
    light_test_sync_light_entity(world, entity)
  })
  world.for_each_component(@light.ecs_key_directional_light, fn(entity, _) {
    light_test_sync_light_entity(world, entity)
  })
  world.for_each_component(@light.ecs_key_rect_light, fn(entity, _) {
    light_test_sync_light_entity(world, entity)
  })
  ignore(world.increment_change_tick())
  extract_lights(world)
}

///|
test "pbr render light: point extraction follows bevy intensity and normal-bias scaling" {
  let world = @ecs.World::new()
  world.insert_resource(
    @light.ecs_key_point_light_shadow_map,
    @light.PointLightShadowMap::new(2048),
  )
  let entity = world.spawn()
  try! (world.set_by_key(
    entity,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight()
    .with_intensity(4.0F * @math.pi())
    .with_shadow_normal_bias(1.0F),
  )
  |> ignore)

  light_test_extract_lights(world)
  let extracted = render3d_collect_extracted_point_lights(world)
  inspect(extracted.length(), content="1")
  let point = extracted[0]
  inspect(approx_eq(point.intensity, 1.0F, 1.0e-5F), content="true")
  let expected_shadow_normal_bias = 1.0F * (2.0F / 2048.0F) * @math.sqrt(2.0F)
  inspect(
    approx_eq(point.shadow_normal_bias, expected_shadow_normal_bias, 1.0e-5F),
    content="true",
  )
}

///|
test "pbr render light: point extraction preserves authored fields" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.set_by_key(
    entity,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight()
    .with_range(-20.0F)
    .with_radius(-0.5F)
    .with_shadow_map_near_z(-0.3F),
  )
  |> ignore)

  light_test_extract_lights(world)
  let extracted = render3d_collect_extracted_point_lights(world)
  inspect(extracted.length(), content="1")
  inspect(approx_eq(extracted[0].range, -20.0F, 1.0e-6F), content="true")
  inspect(approx_eq(extracted[0].radius, -0.5F, 1.0e-6F), content="true")
  inspect(
    approx_eq(extracted[0].shadow_map_near_z, -0.3F, 1.0e-6F),
    content="true",
  )
}

///|
test "pbr render light: spot extraction follows bevy intensity and normal-bias scaling" {
  let world = @ecs.World::new()
  world.insert_resource(
    @light.ecs_key_directional_light_shadow_map,
    @light.DirectionalLightShadowMap::new(1024),
  )
  let entity = world.spawn()
  try! (world.set_by_key(
    entity,
    @light.ecs_key_spot_light,
    @light.SpotLight::SpotLight()
    .with_intensity(4.0F * @math.pi())
    .with_inner_angle(0.2F)
    .with_outer_angle(0.5F)
    .with_shadow_normal_bias(1.0F),
  )
  |> ignore)

  light_test_extract_lights(world)
  let extracted = render3d_collect_extracted_spot_lights(world)
  inspect(extracted.length(), content="1")
  let spot = extracted[0]
  inspect(approx_eq(spot.intensity, 1.0F, 1.0e-5F), content="true")
  let expected_shadow_normal_bias = 1.0F *
    (2.0F * @math.sin(0.5F) / @math.cos(0.5F) / 1024.0F) *
    @math.sqrt(2.0F)
  inspect(
    approx_eq(spot.shadow_normal_bias, expected_shadow_normal_bias, 1.0e-5F),
    content="true",
  )
}

///|
test "pbr render light: spot extraction preserves authored angles" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.set_by_key(
    entity,
    @light.ecs_key_spot_light,
    @light.SpotLight::SpotLight()
    .with_inner_angle(1.25F)
    .with_outer_angle(0.25F),
  )
  |> ignore)

  light_test_extract_lights(world)
  let extracted = render3d_collect_extracted_spot_lights(world)
  inspect(extracted.length(), content="1")
  match extracted[0].spot_light_angles {
    Some((inner, outer)) => {
      inspect(approx_eq(inner, 1.25F, 1.0e-6F), content="true")
      inspect(approx_eq(outer, 0.25F, 1.0e-6F), content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "pbr render light: spot extraction preserves authored scalar fields" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.set_by_key(
    entity,
    @light.ecs_key_spot_light,
    @light.SpotLight::new(
      @color.Color::white(),
      4.0F * @math.pi(),
      -20.0F,
      0.1F,
      0.25F,
      false,
    )
    .with_radius(-0.5F)
    .with_shadow_map_near_z(-0.3F),
  )
  |> ignore)

  light_test_extract_lights(world)
  let extracted = render3d_collect_extracted_spot_lights(world)
  inspect(extracted.length(), content="1")
  inspect(approx_eq(extracted[0].range, -20.0F, 1.0e-6F), content="true")
  inspect(approx_eq(extracted[0].radius, -0.5F, 1.0e-6F), content="true")
  inspect(
    approx_eq(extracted[0].shadow_map_near_z, -0.3F, 1.0e-6F),
    content="true",
  )
}

///|
test "pbr render light: directional dir_to_light uses transform back vector" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.set_by_key(
    entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight().with_shadow_normal_bias(2.0F),
  )
  |> ignore)
  try! (world.set_by_key(
    entity,
    @transform.ecs_key_transform,
    @transform.Transform::identity(),
  )
  |> ignore)

  light_test_propagate_transforms(world)
  light_test_extract_lights(world)
  let extracted_directional = render3d_collect_extracted_directional_lights(
    world,
  )
  inspect(extracted_directional.length(), content="1")
  inspect(
    approx_eq(
      extracted_directional[0].shadow_normal_bias,
      2.0F * @math.sqrt(2.0F),
      1.0e-5F,
    ),
    content="true",
  )
  light_test_extract_lights(world)
  let lighting = render3d_collect_lighting(world)
  inspect(approx_eq(lighting.directional_dir.x, 0.0F, 1.0e-5F), content="true")
  inspect(approx_eq(lighting.directional_dir.y, 0.0F, 1.0e-5F), content="true")
  inspect(approx_eq(lighting.directional_dir.z, 1.0F, 1.0e-5F), content="true")
  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  inspect(gpu_lights.n_directional_lights, content="1")
  inspect(
    approx_eq(gpu_lights.directional_lights[0].dir_to_light.z, 1.0F, 1.0e-5F),
    content="true",
  )
  inspect(
    approx_eq(
      gpu_lights.directional_lights[0].color.r,
      extracted_directional[0].color.r * extracted_directional[0].illuminance,
      1.0e-5F,
    ),
    content="true",
  )
}

///|
test "pbr render light: directional light uses propagated required GlobalTransform" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  let transform = @transform.Transform::from_rotation(
    @math.Quat::from_euler(
      @math.EulerRot::ZYX,
      0.0F,
      1.0F,
      -3.141592653589793F / 4.0F,
    ),
  )
  try! (world.set_by_key(
    entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight(),
  )
  |> ignore)
  try! (world.set_by_key(entity, @transform.ecs_key_transform, transform)
  |> ignore)

  light_test_propagate_transforms(world)
  let local_dir = transform.rotation
    .mul_vec3(@math.Vec3::new(0.0F, 0.0F, 1.0F))
    .normalize_or_zero()
  light_test_extract_lights(world)
  let lighting = render3d_collect_lighting(world)
  inspect(
    approx_eq(lighting.directional_dir.x, local_dir.x, 1.0e-5F),
    content="true",
  )
  inspect(
    approx_eq(lighting.directional_dir.y, local_dir.y, 1.0e-5F),
    content="true",
  )
  inspect(
    approx_eq(lighting.directional_dir.z, local_dir.z, 1.0e-5F),
    content="true",
  )
  inspect(
    approx_eq(
      lighting.directional_dir.z,
      @math.Quat::identity()
      .mul_vec3(@math.Vec3::new(0.0F, 0.0F, 1.0F))
      .normalize_or_zero().z,
      1.0e-5F,
    ),
    content="false",
  )
}

///|
test "pbr render light: extracted lights skip ViewVisibility(false)" {
  let world = @ecs.World::new()
  let hidden_point = world.spawn()
  try! (world.set_by_key(
    hidden_point,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight(),
  )
  |> ignore)
  try! (world.set_by_key(
    hidden_point,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )
  |> ignore)
  let hidden_directional = world.spawn()
  try! (world.set_by_key(
    hidden_directional,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight(),
  )
  |> ignore)
  try! (world.set_by_key(
    hidden_directional,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )
  |> ignore)

  light_test_extract_lights(world)
  inspect(render3d_collect_extracted_point_lights(world).length(), content="0")
  inspect(
    render3d_collect_extracted_directional_lights(world).length(),
    content="0",
  )
}

///|
test "pbr render light: point extraction keeps all view-visible lights before cluster assignment" {
  let world = @ecs.World::new()
  world.insert_resource(
    @light.ecs_key_point_light_shadow_map,
    @light.PointLightShadowMap::new(2048),
  )
  let point_visible = world.spawn()
  try! (world.set_by_key(
    point_visible,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_intensity(10.0F),
  )
  |> ignore)
  let point_hidden = world.spawn()
  try! (world.set_by_key(
    point_hidden,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_intensity(20.0F),
  )
  |> ignore)

  let list_owner = world.spawn()
  try! (world.set_by_key(
    list_owner,
    @light_cluster.VisibleClusterableObjects::component(),
    @light_cluster.VisibleClusterableObjects::from_lists([point_visible], [], []),
  )
  |> ignore)

  light_test_extract_lights(world)
  let extracted = render3d_collect_extracted_point_lights(world)
  inspect(extracted.length(), content="2")
  inspect(extracted[0].entity == point_visible, content="true")
  inspect(extracted[1].entity == point_hidden, content="true")
}

///|
test "pbr render light: spot extraction keeps all view-visible lights before cluster assignment" {
  let world = @ecs.World::new()
  world.insert_resource(
    @light.ecs_key_directional_light_shadow_map,
    @light.DirectionalLightShadowMap::new(1024),
  )
  let spot_visible = world.spawn()
  try! (world.set_by_key(
    spot_visible,
    @light.ecs_key_spot_light,
    @light.SpotLight::SpotLight().with_intensity(10.0F),
  )
  |> ignore)
  let spot_hidden = world.spawn()
  try! (world.set_by_key(
    spot_hidden,
    @light.ecs_key_spot_light,
    @light.SpotLight::SpotLight().with_intensity(20.0F),
  )
  |> ignore)

  let list_owner = world.spawn()
  try! (world.set_by_key(
    list_owner,
    @light_cluster.VisibleClusterableObjects::component(),
    @light_cluster.VisibleClusterableObjects::from_lists([spot_visible], [], []),
  )
  |> ignore)

  light_test_extract_lights(world)
  let extracted = render3d_collect_extracted_spot_lights(world)
  inspect(extracted.length(), content="2")
  inspect(extracted[0].entity == spot_visible, content="true")
  inspect(extracted[1].entity == spot_hidden, content="true")
}

///|
test "pbr render light: spot/directional propagate affects_lightmapped_mesh_diffuse" {
  let world = @ecs.World::new()

  let spot_entity = world.spawn()
  try! (world.set_by_key(
    spot_entity,
    @light.ecs_key_spot_light,
    @light.SpotLight::SpotLight().with_affects_lightmapped_mesh_diffuse(false),
  )
  |> ignore)
  light_test_extract_lights(world)
  let spots = render3d_collect_extracted_spot_lights(world)
  inspect(spots.length(), content="1")
  inspect(spots[0].affects_lightmapped_mesh_diffuse, content="false")

  ignore(world.increment_change_tick())
  let directional_entity = world.spawn()
  try! (world.set_by_key(
    directional_entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight().with_affects_lightmapped_mesh_diffuse(
      false,
    ),
  )
  |> ignore)
  light_test_extract_lights(world)
  let directionals = render3d_collect_extracted_directional_lights(world)
  inspect(directionals.length(), content="1")
  inspect(directionals[0].affects_lightmapped_mesh_diffuse, content="false")
}

///|
test "pbr render light: directional cascade overlap propagates to gpu lights" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  let updated = @light.CascadeShadowConfigBuilder::CascadeShadowConfigBuilder()
    .with_overlap_proportion(0.37F)
    .build()
  try! (world.set_by_key(
    entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight().with_cascade_shadow_config(
      Some(updated),
    ),
  )
  |> ignore)

  light_test_extract_lights(world)
  let extracted = render3d_collect_extracted_directional_lights(world)
  inspect(extracted.length(), content="1")
  inspect(
    approx_eq(extracted[0].cascade_overlap_proportion, 0.37F, 1.0e-6F),
    content="true",
  )
  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  inspect(gpu_lights.n_directional_lights, content="1")
  inspect(
    approx_eq(
      gpu_lights.directional_lights[0].cascades_overlap_proportion,
      0.37F,
      1.0e-6F,
    ),
    content="true",
  )
}

///|
test "pbr render light: directional without shadows keeps zero cascades" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.set_by_key(
    entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight(),
  )
  |> ignore)

  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  inspect(gpu_lights.n_directional_lights, content="1")
  inspect(gpu_lights.directional_lights[0].num_cascades, content="0")
  inspect(
    gpu_lights.directional_lights[0].cascades.length(),
    content=MAX_CASCADES_PER_LIGHT.to_string(),
  )
}

///|
test "pbr render light: directional with shadows uses default cascade config" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.set_by_key(
    entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight().with_shadow_maps_enabled(true),
  )
  |> ignore)

  light_test_extract_lights(world)
  let extracted = render3d_collect_extracted_directional_lights(world)
  inspect(extracted.length(), content="1")
  inspect(extracted[0].cascade_count, content="4")
  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  inspect(gpu_lights.n_directional_lights, content="1")
  inspect(gpu_lights.directional_lights[0].num_cascades, content="4")
  inspect(
    gpu_lights.directional_lights[0].depth_texture_base_index,
    content="0",
  )
}

///|
test "pbr render light: directional gpu lights resolve view cascade data" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.set_by_key(
    entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight().with_shadow_maps_enabled(true),
  )
  |> ignore)

  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  let cascade_data = [
    1.0F, 2.0F, 3.0F, 4.0F, 5.0F, 6.0F, 7.0F, 8.0F, 9.0F, 10.0F, 11.0F, 12.0F, 13.0F,
    14.0F, 15.0F, 16.0F, 0.25F, 42.0F, 0.0F, 0.0F,
  ]
  let resolved = render3d_gpu_lights_with_directional_shadow_cascades(
    gpu_lights, 7, 1.0F, 1, 0.21F, cascade_data,
  )

  inspect(resolved.directional_lights[0].num_cascades, content="1")
  inspect(
    approx_eq(
      resolved.directional_lights[0].cascades_overlap_proportion,
      0.21F,
      1.0e-6F,
    ),
    content="true",
  )
  inspect((resolved.directional_lights[0].flags & 1U) == 1U, content="true")
  inspect(
    approx_eq(
      resolved.directional_lights[0].cascades[0].clip_from_world.x_axis.x,
      1.0F,
      1.0e-6F,
    ),
    content="true",
  )
  inspect(
    approx_eq(
      resolved.directional_lights[0].cascades[0].texel_size,
      0.25F,
      1.0e-6F,
    ),
    content="true",
  )
  inspect(
    approx_eq(
      resolved.directional_lights[0].cascades[0].far_bound,
      42.0F,
      1.0e-6F,
    ),
    content="true",
  )
}

///|
test "pbr render light: directional extraction order follows bevy key" {
  let world = @ecs.World::new()
  let shadow_and_volumetric = world.spawn()
  let shadow_only = world.spawn()
  let no_shadow = world.spawn()

  try! (world.set_by_key(
    shadow_and_volumetric,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight().with_shadow_maps_enabled(true),
  )
  |> ignore)
  try! (world.set_by_key(
    shadow_and_volumetric,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::VolumetricLight(),
  )
  |> ignore)

  try! (world.set_by_key(
    shadow_only,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight().with_shadow_maps_enabled(true),
  )
  |> ignore)

  try! (world.set_by_key(
    no_shadow,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight(),
  )
  |> ignore)

  light_test_extract_lights(world)
  let extracted = render3d_collect_extracted_directional_lights(world)
  inspect(extracted.length(), content="3")
  inspect(extracted[0].entity.id, content="2")
  inspect(extracted[1].entity.id, content="1")
  inspect(extracted[2].entity.id, content="0")
}

///|
test "pbr render light: directional depth texture base index accumulates cascades" {
  let world = @ecs.World::new()

  let first = world.spawn()
  let first_config = @light.CascadeShadowConfigBuilder::CascadeShadowConfigBuilder()
    .with_num_cascades(2)
    .build()
  try! (world.set_by_key(
    first,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight()
    .with_shadow_maps_enabled(true)
    .with_cascade_shadow_config(Some(first_config)),
  )
  |> ignore)

  let second = world.spawn()
  let second_config = @light.CascadeShadowConfigBuilder::CascadeShadowConfigBuilder()
    .with_num_cascades(3)
    .build()
  try! (world.set_by_key(
    second,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight()
    .with_shadow_maps_enabled(true)
    .with_cascade_shadow_config(Some(second_config)),
  )
  |> ignore)

  light_test_extract_lights(world)
  let gpu = render3d_collect_gpu_lights(world)
  inspect(gpu.n_directional_lights, content="2")
  inspect(gpu.directional_lights[0].num_cascades, content="2")
  inspect(gpu.directional_lights[0].depth_texture_base_index, content="0")
  inspect(gpu.directional_lights[1].num_cascades, content="3")
  inspect(gpu.directional_lights[1].depth_texture_base_index, content="2")
  inspect(gpu.directional_lights[0].decal_index, content="-1")
  inspect(gpu.directional_lights[1].decal_index, content="-1")
}

///|
test "pbr render light: directional light reads decal index from clustered decals resource" {
  let world = @ecs.World::new()

  let directional = world.spawn()
  try! (world.set_by_key(
    directional,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight(),
  )
  |> ignore)

  let decals = @pbr_decal.RenderClusteredDecals::RenderClusteredDecals()
  let inserted_decal_index = decals.insert_decal(
    directional,
    @pbr_decal.ClusteredDecal::ClusteredDecal(),
  )
  world.insert_resource(@pbr_decal.ecs_key_render_clustered_decals, decals)

  light_test_extract_lights(world)
  let gpu = render3d_collect_gpu_lights(world)
  inspect(gpu.n_directional_lights, content="1")
  inspect(
    gpu.directional_lights[0].decal_index,
    content=inserted_decal_index.to_string(),
  )
}

///|
test "pbr render light: point extraction order keeps shadow and volumetric first" {
  let world = @ecs.World::new()
  let no_shadow = world.spawn()
  try! (world.set_by_key(
    no_shadow,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight(),
  )
  |> ignore)

  let shadow_only = world.spawn()
  try! (world.set_by_key(
    shadow_only,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_shadow_maps_enabled(true),
  )
  |> ignore)

  let shadow_and_vol = world.spawn()
  try! (world.set_by_key(
    shadow_and_vol,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_shadow_maps_enabled(true),
  )
  |> ignore)
  try! (world.set_by_key(
    shadow_and_vol,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::VolumetricLight(),
  )
  |> ignore)

  light_test_extract_lights(world)
  let extracted = render3d_collect_extracted_point_lights(world)
  inspect(extracted.length(), content="3")
  inspect(extracted[0].entity.id, content="2")
  inspect(extracted[1].entity.id, content="1")
  inspect(extracted[2].entity.id, content="0")
}

///|
test "pbr render light: spot extraction order keeps shadow and volumetric first" {
  let world = @ecs.World::new()
  let no_shadow = world.spawn()
  try! (world.set_by_key(
    no_shadow,
    @light.ecs_key_spot_light,
    @light.SpotLight::SpotLight(),
  )
  |> ignore)

  let shadow_only = world.spawn()
  try! (world.set_by_key(
    shadow_only,
    @light.ecs_key_spot_light,
    @light.SpotLight::SpotLight().with_shadow_maps_enabled(true),
  )
  |> ignore)

  let shadow_and_vol = world.spawn()
  try! (world.set_by_key(
    shadow_and_vol,
    @light.ecs_key_spot_light,
    @light.SpotLight::SpotLight().with_shadow_maps_enabled(true),
  )
  |> ignore)
  try! (world.set_by_key(
    shadow_and_vol,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::VolumetricLight(),
  )
  |> ignore)

  light_test_extract_lights(world)
  let extracted = render3d_collect_extracted_spot_lights(world)
  inspect(extracted.length(), content="3")
  inspect(extracted[0].entity.id, content="2")
  inspect(extracted[1].entity.id, content="1")
  inspect(extracted[2].entity.id, content="0")
}

///|
test "pbr render light: clusterable point-light ordering keeps points before spots" {
  let world = @ecs.World::new()

  let spot = world.spawn()
  try! (world.set_by_key(
    spot,
    @light.ecs_key_spot_light,
    @light.SpotLight::SpotLight().with_shadow_maps_enabled(true),
  )
  |> ignore)

  let point = world.spawn()
  try! (world.set_by_key(
    point,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight(),
  )
  |> ignore)

  let point_shadow = world.spawn()
  try! (world.set_by_key(
    point_shadow,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_shadow_maps_enabled(true),
  )
  |> ignore)

  light_test_extract_lights(world)
  let ordered = render3d_collect_extracted_clusterable_point_lights(world)
  inspect(ordered.length(), content="3")
  inspect(ordered[0].is_point_light(), content="true")
  inspect(ordered[1].is_point_light(), content="true")
  inspect(ordered[2].is_spot_light(), content="true")
  inspect(ordered[0].light().entity.id, content="2")
  inspect(ordered[1].light().entity.id, content="1")
  inspect(ordered[2].light().entity.id, content="0")
}

///|
test "pbr render light: gpu lights computes spot shadow map offset" {
  let world = @ecs.World::new()

  let point = world.spawn()
  try! (world.set_by_key(
    point,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_shadow_maps_enabled(true),
  )
  |> ignore)

  let directional = world.spawn()
  let directional_config = @light.CascadeShadowConfigBuilder::CascadeShadowConfigBuilder()
    .with_num_cascades(2)
    .build()
  try! (world.set_by_key(
    directional,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight()
    .with_shadow_maps_enabled(true)
    .with_cascade_shadow_config(Some(directional_config)),
  )
  |> ignore)

  light_test_extract_lights(world)
  let gpu = render3d_collect_gpu_lights(world)
  inspect(gpu.n_directional_lights, content="1")
  inspect(gpu.directional_lights[0].num_cascades, content="2")
  inspect(gpu.spot_light_shadowmap_offset, content="1")
}

///|
test "pbr render light: gpu directional array is padded to max while count stays logical" {
  let world = @ecs.World::new()
  let directional = world.spawn()
  try! (world.set_by_key(
    directional,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight(),
  )
  |> ignore)
  light_test_extract_lights(world)
  let gpu = render3d_collect_gpu_lights(world)
  inspect(gpu.n_directional_lights, content="1")
  inspect(
    gpu.directional_lights.length(),
    content=MAX_DIRECTIONAL_LIGHTS.to_string(),
  )
  inspect(gpu.directional_lights[1].num_cascades, content="0")
  inspect(gpu.directional_lights[1].flags, content="65535")
  inspect(gpu.directional_lights[1].decal_index, content="-1")
}

///|
test "pbr render light: gpu lights tracks ambient affects_lightmapped_meshes" {
  let world = @ecs.World::new()
  world.insert_resource(
    @light.ecs_key_global_ambient_light,
    @light.GlobalAmbientLight::new(
      @color.Color::new(0.25F, 0.5F, 0.75F, 1.0F),
      2.0F,
    ).with_affects_lightmapped_meshes(false),
  )
  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  inspect(gpu_lights.ambient_light_affects_lightmapped_meshes, content="0")
  inspect(approx_eq(gpu_lights.ambient_color.r, 0.5F, 1.0e-6F), content="true")
  inspect(approx_eq(gpu_lights.ambient_color.g, 1.0F, 1.0e-6F), content="true")
  inspect(approx_eq(gpu_lights.ambient_color.b, 1.5F, 1.0e-6F), content="true")
}

///|
test "pbr render light: gpu lights carries bevy-shaped cluster dimensions" {
  let world = @ecs.World::new()
  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  let expected_factors_zw = @light_cluster.calculate_cluster_factors(
    5.0F, 5.0F, 24.0F, false,
  )
  let expected_factor_x = 16.0F / 1280.0F
  let expected_factor_y = 9.0F / 720.0F
  inspect(gpu_lights.cluster_dimensions.0, content="16")
  inspect(gpu_lights.cluster_dimensions.1, content="9")
  inspect(gpu_lights.cluster_dimensions.2, content="24")
  inspect(gpu_lights.cluster_dimensions.3, content="3456")
  inspect(
    approx_eq(gpu_lights.cluster_factors.x, expected_factor_x, 1.0e-6F),
    content="true",
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.y, expected_factor_y, 1.0e-6F),
    content="true",
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.z, expected_factors_zw.x, 1.0e-5F),
    content="true",
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.w, expected_factors_zw.y, 1.0e-5F),
    content="true",
  )
}

///|
test "pbr render light: storage cluster buffers fit bevy default clusters" {
  let world = @ecs.World::new()
  let camera = world.spawn()
  try! (world.set_by_key(
    camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  |> ignore)
  try! (world.set_by_key(
    camera,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 7.0F, 14.0F).looking_at(
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  |> ignore)
  let point = world.spawn()
  try! (world.set_by_key(
    point,
    @light.ecs_key_point_light,
    @light.PointLight::new(@color.Color::white(), 10_000_000.0F, 100.0F, true),
  )
  |> ignore)
  try! (world.set_by_key(
    point,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(8.0F, 16.0F, 8.0F),
  )
  |> ignore)

  light_test_propagate_transforms(world)
  @light_cluster.cluster_assign_lights_system(world)
  light_test_extract_lights(world)
  let lighting = render3d_collect_lighting(world)
  guard lighting.gpu_clustered_lights_bytes is Some(clustered) else {
    inspect("missing", content="clustered")
    return
  }
  guard lighting.gpu_clusterable_object_index_lists_bytes is Some(indices) else {
    inspect("missing", content="indices")
    return
  }
  guard lighting.gpu_cluster_offsets_and_counts_bytes is Some(offsets) else {
    inspect("missing", content="offsets")
    return
  }

  inspect(clustered.length(), content="16320")
  inspect(indices.length(), content="65536")
  inspect(offsets.length(), content="131072")
  inspect(test_cluster_offsets_has_point_light(offsets, 3456), content="true")
}

///|
test "pbr render light: storage cluster buffers include clustered decal ranges" {
  let world = @ecs.World::new()
  let camera = world.spawn()
  try! (world.set_by_key(
    camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  |> ignore)
  try! (world.set_by_key(
    camera,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 0.0F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  |> ignore)
  let decal = world.spawn()
  try! (world.set_by_key(
    decal,
    @light.ecs_key_clustered_decal,
    @light.ClusteredDecal::ClusteredDecal(),
  )
  |> ignore)
  try! (world.set_by_key(
    decal,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F).with_scale(
      @math.Vec3::new(4.0F, 4.0F, 4.0F),
    ),
  )
  |> ignore)

  light_test_propagate_transforms(world)
  @light_cluster.cluster_assign_lights_system(world)
  let render_decals = @pbr_decal.RenderClusteredDecals::RenderClusteredDecals()
  let decal_index = render_decals.insert_decal(
    decal,
    @pbr_decal.ClusteredDecal::ClusteredDecal(),
  )
  world.insert_resource(
    @pbr_decal.ecs_key_render_clustered_decals, render_decals,
  )
  light_test_extract_lights(world)
  let lighting = render3d_collect_lighting(world)
  guard lighting.gpu_clusterable_object_index_lists_bytes is Some(indices) else {
    inspect("missing", content="indices")
    return
  }
  guard lighting.gpu_cluster_offsets_and_counts_bytes is Some(offsets) else {
    inspect("missing", content="offsets")
    return
  }

  inspect(test_cluster_offsets_has_decal(offsets, 3456), content="true")
  inspect(
    test_cluster_decal_index_matches(
      offsets,
      indices,
      3456,
      decal_index.reinterpret_as_uint(),
    ),
    content="true",
  )
}

///|
test "pbr render light: point shadow clustered custom data matches Bevy projection" {
  let world = @ecs.World::new()
  let camera = world.spawn()
  try! (world.set_by_key(
    camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  |> ignore)
  try! (world.set_by_key(
    camera,
    @light_cluster.ClusterConfig::component(),
    @light_cluster.ClusterConfig::default(),
  )
  |> ignore)
  try! (world.set_by_key(
    camera,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::identity(),
  )
  |> ignore)
  let point = world.spawn()
  try! (world.set_by_key(
    point,
    @light.ecs_key_point_light,
    @light.PointLight::new(@color.Color::white(), 10_000_000.0F, 100.0F, true),
  )
  |> ignore)
  try! (world.set_by_key(
    point,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(8.0F, 16.0F, 8.0F),
  )
  |> ignore)
  light_test_propagate_transforms(world)
  @light_cluster.cluster_assign_lights_system(world)
  light_test_extract_lights(world)
  let lighting = render3d_collect_lighting(world)
  guard lighting.gpu_clustered_lights_bytes is Some(clustered) else {
    inspect("missing", content="clustered")
    return
  }
  let projection = render3d_point_shadow_pass_projection(0.1F, 100.0F).clip_from_view
  inspect(test_u32le_at(clustered, 0), content="0")
  inspect(
    test_u32le_at(clustered, 4),
    content="\{test_f32_bits(projection.z_axis.w)}",
  )
  inspect(
    test_u32le_at(clustered, 8),
    content="\{test_f32_bits(projection.w_axis.z)}",
  )
  inspect(test_u32le_at(clustered, 12), content="0")
}

///|
test "pbr render light: cluster factors zw follow orthographic projection runtime" {
  let world = @ecs.World::new()
  let camera = world.spawn()
  try! (world.set_by_key(
    camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  |> ignore)
  try! (world.set_by_key(
    camera,
    @light_cluster.ClusterConfig::component(),
    @light_cluster.ClusterConfig::default(),
  )
  |> ignore)
  try! (world.set_by_key(camera, ecs_key_projection_runtime3d, ProjectionRuntime3d::{
    last_view_width: 1280.0F,
    last_view_height: 720.0F,
    is_orthographic: true,
    orthographic_first_slice_depth: 2.0F,
  })
  |> ignore)
  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  let expected_factors_zw = @light_cluster.calculate_cluster_factors(
    2.0F, 2.0F, 24.0F, true,
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.z, expected_factors_zw.x, 1.0e-5F),
    content="true",
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.w, expected_factors_zw.y, 1.0e-5F),
    content="true",
  )
}

///|
test "pbr render light: cluster far fallback follows max visible clusterable range" {
  let world = @ecs.World::new()
  let visible_point = world.spawn()
  try! (world.set_by_key(
    visible_point,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_range(40.0F),
  )
  |> ignore)
  let hidden_spot = world.spawn()
  try! (world.set_by_key(
    hidden_spot,
    @light.ecs_key_spot_light,
    {
      let default_spot = @light.SpotLight::SpotLight()
      @light.SpotLight::new(
        default_spot.color,
        default_spot.intensity,
        80.0F,
        default_spot.inner_angle,
        default_spot.outer_angle,
        default_spot.shadow_maps_enabled,
      )
    },
  )
  |> ignore)
  try! (world.set_by_key(
    hidden_spot,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )
  |> ignore)
  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  let expected_factors_zw = @light_cluster.calculate_cluster_factors(
    5.0F, 40.0F, 24.0F, false,
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.z, expected_factors_zw.x, 1.0e-5F),
    content="true",
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.w, expected_factors_zw.y, 1.0e-5F),
    content="true",
  )
}

///|
test "pbr render light: cluster far fallback prefers camera visible cluster list" {
  let world = @ecs.World::new()
  let camera = world.spawn()
  try! (world.set_by_key(
    camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  |> ignore)
  try! (world.set_by_key(
    camera,
    @light_cluster.ClusterConfig::component(),
    @light_cluster.ClusterConfig::default(),
  )
  |> ignore)
  let light_in_view = world.spawn()
  try! (world.set_by_key(
    light_in_view,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_range(20.0F),
  )
  |> ignore)
  let light_outside_view = world.spawn()
  try! (world.set_by_key(
    light_outside_view,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_range(120.0F),
  )
  |> ignore)
  try! (world.set_by_key(
    camera,
    @light_cluster.VisibleClusterableObjects::component(),
    @light_cluster.VisibleClusterableObjects::from_lists([light_in_view], [], []),
  )
  |> ignore)
  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  let expected_factors_zw = @light_cluster.calculate_cluster_factors(
    5.0F, 20.0F, 24.0F, false,
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.z, expected_factors_zw.x, 1.0e-5F),
    content="true",
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.w, expected_factors_zw.y, 1.0e-5F),
    content="true",
  )
}

///|
test "pbr render light: cluster far fallback includes camera view depth" {
  let world = @ecs.World::new()
  let camera = world.spawn()
  try! (world.set_by_key(
    camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  |> ignore)
  try! (world.set_by_key(
    camera,
    @light_cluster.ClusterConfig::component(),
    @light_cluster.ClusterConfig::default(),
  )
  |> ignore)
  try! (world.set_by_key(
    camera,
    @transform.ecs_key_transform,
    @transform.Transform::identity().with_translation(
      @math.Vec3::new(0.0F, 0.0F, 10.0F),
    ),
  )
  |> ignore)
  let light_entity = world.spawn()
  try! (world.set_by_key(
    light_entity,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_range(5.0F),
  )
  |> ignore)
  try! (world.set_by_key(
    light_entity,
    @transform.ecs_key_transform,
    @transform.Transform::identity().with_translation(
      @math.Vec3::new(0.0F, 0.0F, -20.0F),
    ),
  )
  |> ignore)
  try! (world.set_by_key(
    camera,
    @light_cluster.VisibleClusterableObjects::component(),
    @light_cluster.VisibleClusterableObjects::from_lists([light_entity], [], []),
  )
  |> ignore)
  light_test_propagate_transforms(world)
  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  let expected_factors_zw = @light_cluster.calculate_cluster_factors(
    5.0F, 35.0F, 24.0F, false,
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.z, expected_factors_zw.x, 1.0e-5F),
    content="true",
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.w, expected_factors_zw.y, 1.0e-5F),
    content="true",
  )
}

///|
test "pbr render light: single-z perspective cluster near pins to far" {
  let world = @ecs.World::new()
  let camera = world.spawn()
  try! (world.set_by_key(
    camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  |> ignore)
  try! (world.set_by_key(
    camera,
    @light_cluster.ClusterConfig::component(),
    @light_cluster.ClusterConfig::Single,
  )
  |> ignore)
  let point = world.spawn()
  try! (world.set_by_key(
    point,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_range(10.0F),
  )
  |> ignore)
  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  let expected_factors_zw = @light_cluster.calculate_cluster_factors(
    10.0F, 10.0F, 1.0F, false,
  )
  inspect(gpu_lights.cluster_dimensions.2, content="1")
  inspect(
    approx_eq(gpu_lights.cluster_factors.z, expected_factors_zw.x, 1.0e-5F),
    content="true",
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.w, expected_factors_zw.y, 1.0e-5F),
    content="true",
  )
}

///|
test "pbr render light: gpu lights cluster dimensions follow cluster config component" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.set_by_key(
    entity,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  |> ignore)
  try! (world.set_by_key(
    entity,
    @light_cluster.ClusterConfig::component(),
    @light_cluster.ClusterConfig::XYZ(
      8,
      4,
      12,
      @light_cluster.ClusterZConfig::ClusterZConfig(),
      false,
    ),
  )
  |> ignore)
  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  inspect(gpu_lights.cluster_dimensions.0, content="8")
  inspect(gpu_lights.cluster_dimensions.1, content="4")
  inspect(gpu_lights.cluster_dimensions.2, content="12")
  inspect(gpu_lights.cluster_dimensions.3, content="384")
}

///|
test "pbr render light: cluster config is sourced from camera entities" {
  let world = @ecs.World::new()
  let non_camera_entity = world.spawn()
  try! (world.set_by_key(
    non_camera_entity,
    @light_cluster.ClusterConfig::component(),
    @light_cluster.ClusterConfig::XYZ(
      2,
      2,
      2,
      @light_cluster.ClusterZConfig::ClusterZConfig(),
      false,
    ),
  )
  |> ignore)
  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  inspect(gpu_lights.cluster_dimensions.0, content="16")
  inspect(gpu_lights.cluster_dimensions.1, content="9")
  inspect(gpu_lights.cluster_dimensions.2, content="24")
}

///|
test "pbr render light: cluster config none yields zero cluster payload" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.set_by_key(
    entity,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  |> ignore)
  try! (world.set_by_key(
    entity,
    @light_cluster.ClusterConfig::component(),
    @light_cluster.ClusterConfig::None,
  )
  |> ignore)
  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  inspect(gpu_lights.cluster_dimensions.0, content="0")
  inspect(gpu_lights.cluster_dimensions.1, content="0")
  inspect(gpu_lights.cluster_dimensions.2, content="0")
  inspect(gpu_lights.cluster_dimensions.3, content="0")
  inspect(
    approx_eq(gpu_lights.cluster_factors.z, 0.0F, 1.0e-6F),
    content="true",
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.w, 0.0F, 1.0e-6F),
    content="true",
  )
}

///|
test "pbr render light: cluster payload prefers runtime clusters component" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.set_by_key(
    entity,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  |> ignore)
  try! (world.set_by_key(
    entity,
    @light_cluster.Clusters::component(),
    @light_cluster.Clusters::new(64, 64, 12, 6, 8, 1.0F, 81.0F),
  )
  |> ignore)
  let expected_factors_zw = @light_cluster.calculate_cluster_factors(
    1.0F, 81.0F, 8.0F, false,
  )
  let expected_factor_x = 12.0F / 1280.0F
  let expected_factor_y = 6.0F / 720.0F
  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  inspect(gpu_lights.cluster_dimensions.0, content="12")
  inspect(gpu_lights.cluster_dimensions.1, content="6")
  inspect(gpu_lights.cluster_dimensions.2, content="8")
  inspect(gpu_lights.cluster_dimensions.3, content="576")
  inspect(
    approx_eq(gpu_lights.cluster_factors.x, expected_factor_x, 1.0e-6F),
    content="true",
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.y, expected_factor_y, 1.0e-6F),
    content="true",
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.z, expected_factors_zw.x, 1.0e-5F),
    content="true",
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.w, expected_factors_zw.y, 1.0e-5F),
    content="true",
  )
}

///|
test "pbr render light: cluster factors xy prefer camera viewport size when present" {
  let world = @ecs.World::new()
  let camera = world.spawn()
  try! (world.set_by_key(
    camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera().with_viewport(
      @camera_viewport.Viewport::new(
        @math.IVec2::new(0, 0),
        @math.IVec2::new(640, 360),
      ),
    ),
  )
  |> ignore)
  try! (world.set_by_key(
    camera,
    @light_cluster.ClusterConfig::component(),
    @light_cluster.ClusterConfig::XYZ(
      16,
      9,
      24,
      @light_cluster.ClusterZConfig::ClusterZConfig(),
      false,
    ),
  )
  |> ignore)
  light_test_extract_lights(world)
  let gpu_lights = render3d_collect_gpu_lights(world)
  inspect(
    approx_eq(gpu_lights.cluster_factors.x, 16.0F / 640.0F, 1.0e-6F),
    content="true",
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.y, 9.0F / 360.0F, 1.0e-6F),
    content="true",
  )
}

///|
test "pbr render light: volumetric flags require shadow maps for point and directional lights" {
  let world = @ecs.World::new()

  let point_entity = world.spawn()
  try! (world.set_by_key(
    point_entity,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight(),
  )
  |> ignore)
  try! (world.set_by_key(
    point_entity,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::VolumetricLight(),
  )
  |> ignore)
  light_test_extract_lights(world)
  let points_no_shadow = render3d_collect_extracted_point_lights(world)
  inspect(points_no_shadow.length(), content="1")
  let point_flags_no_shadow = render3d_point_light_flags(points_no_shadow[0])
  inspect((point_flags_no_shadow & (1U << 2)) == 0U, content="true")

  ignore(world.increment_change_tick())
  try! (world.set_by_key(
    point_entity,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_shadow_maps_enabled(true),
  )
  |> ignore)
  light_test_extract_lights(world)
  let points_with_shadow = render3d_collect_extracted_point_lights(world)
  let point_flags_with_shadow = render3d_point_light_flags(
    points_with_shadow[0],
  )
  inspect((point_flags_with_shadow & (1U << 2)) != 0U, content="true")

  ignore(world.increment_change_tick())
  let directional_entity = world.spawn()
  try! (world.set_by_key(
    directional_entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight(),
  )
  |> ignore)
  try! (world.set_by_key(
    directional_entity,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::VolumetricLight(),
  )
  |> ignore)
  light_test_extract_lights(world)
  let directional_no_shadow = render3d_collect_extracted_directional_lights(
    world,
  )
  inspect(directional_no_shadow.length(), content="1")
  let directional_flags_no_shadow = render3d_directional_light_flags(
    directional_no_shadow[0],
  )
  inspect((directional_flags_no_shadow & (1U << 1)) == 0U, content="true")

  ignore(world.increment_change_tick())
  try! (world.set_by_key(
    directional_entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight().with_shadow_maps_enabled(true),
  )
  |> ignore)
  light_test_extract_lights(world)
  let directional_with_shadow = render3d_collect_extracted_directional_lights(
    world,
  )
  let directional_flags_with_shadow = render3d_directional_light_flags(
    directional_with_shadow[0],
  )
  inspect((directional_flags_with_shadow & (1U << 1)) != 0U, content="true")
}

///|
test "pbr render light: directional sun disk defaults and component override propagate" {
  let world = @ecs.World::new()
  let entity_default = world.spawn()
  try! (world.set_by_key(
    entity_default,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight(),
  )
  |> ignore)

  light_test_extract_lights(world)
  let default_gpu = render3d_collect_gpu_lights(world)
  inspect(default_gpu.n_directional_lights, content="1")
  inspect(
    approx_eq(
      default_gpu.directional_lights[0].sun_disk_angular_size,
      0.00930842F,
      1.0e-6F,
    ),
    content="true",
  )
  inspect(
    approx_eq(
      default_gpu.directional_lights[0].sun_disk_intensity,
      1.0F,
      1.0e-6F,
    ),
    content="true",
  )

  ignore(world.increment_change_tick())
  let entity_override = world.spawn()
  try! (world.set_by_key(
    entity_override,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight(),
  )
  |> ignore)
  try! (world.set_by_key(
    entity_override,
    @light.ecs_key_sun_disk,
    @light.SunDisk::off(),
  )
  |> ignore)

  light_test_extract_lights(world)
  let extracted = render3d_collect_extracted_directional_lights(world)
  inspect(extracted.length(), content="2")
  inspect(
    approx_eq(extracted[1].sun_disk_angular_size, 0.0F, 1.0e-6F),
    content="true",
  )
  inspect(
    approx_eq(extracted[1].sun_disk_intensity, 0.0F, 1.0e-6F),
    content="true",
  )

  light_test_extract_lights(world)
  let override_gpu = render3d_collect_gpu_lights(world)
  inspect(override_gpu.n_directional_lights, content="2")
  inspect(
    approx_eq(
      override_gpu.directional_lights[1].sun_disk_angular_size,
      0.0F,
      1.0e-6F,
    ),
    content="true",
  )
  inspect(
    approx_eq(
      override_gpu.directional_lights[1].sun_disk_intensity,
      0.0F,
      1.0e-6F,
    ),
    content="true",
  )
}

///|
test "pbr render light: LightMeta uploads view gpu lights to gpu binding" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let queue = device.queue()
  let light_meta = LightMeta::LightMeta()
  light_meta.write_view_gpu_lights_buffer(device, queue)
  inspect(light_meta.view_gpu_lights_binding() is None, content="true")
  let offset = light_meta.push_view_gpu_lights(GpuLights3d::GpuLights3d())
  inspect(offset, content="0")

  light_meta.write_view_gpu_lights_buffer(device, queue)

  inspect(light_meta.view_gpu_lights_binding() is Some(_), content="true")
  inspect(light_meta.view_gpu_lights_capacity() > 0UL, content="true")
  device.release()
  adapter.release()
  instance.release()
}
