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
    @light.PointLight::default()
    .with_intensity(4.0F * @math.pi())
    .with_shadow_normal_bias(1.0F),
  )
  |> ignore)

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
    @light.SpotLight::default()
    .with_intensity(4.0F * @math.pi())
    .with_inner_angle(0.2F)
    .with_outer_angle(0.5F)
    .with_shadow_normal_bias(1.0F),
  )
  |> ignore)

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
test "pbr render light: directional dir_to_light uses transform back vector" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.set_by_key(
    entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default().with_shadow_normal_bias(2.0F),
  )
  |> ignore)
  try! (world.set_by_key(
    entity,
    @transform.ecs_key_transform,
    @transform.Transform::identity(),
  )
  |> ignore)

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
  let lighting = render3d_collect_lighting(world)
  inspect(approx_eq(lighting.directional_dir.x, 0.0F, 1.0e-5F), content="true")
  inspect(approx_eq(lighting.directional_dir.y, 0.0F, 1.0e-5F), content="true")
  inspect(approx_eq(lighting.directional_dir.z, 1.0F, 1.0e-5F), content="true")
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
test "pbr render light: extracted lights skip ViewVisibility(false)" {
  let world = @ecs.World::new()
  let hidden_point = world.spawn()
  try! (world.set_by_key(
    hidden_point,
    @light.ecs_key_point_light,
    @light.PointLight::default(),
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
    @light.DirectionalLight::default(),
  )
  |> ignore)
  try! (world.set_by_key(
    hidden_directional,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )
  |> ignore)

  inspect(render3d_collect_extracted_point_lights(world).length(), content="0")
  inspect(
    render3d_collect_extracted_directional_lights(world).length(),
    content="0",
  )
}

///|
test "pbr render light: point extraction prefers visible clusterable entity list when present" {
  let world = @ecs.World::new()
  world.insert_resource(
    @light.ecs_key_point_light_shadow_map,
    @light.PointLightShadowMap::new(2048),
  )
  let point_visible = world.spawn()
  try! (world.set_by_key(
    point_visible,
    @light.ecs_key_point_light,
    @light.PointLight::default().with_intensity(10.0F),
  )
  |> ignore)
  let point_hidden = world.spawn()
  try! (world.set_by_key(
    point_hidden,
    @light.ecs_key_point_light,
    @light.PointLight::default().with_intensity(20.0F),
  )
  |> ignore)

  let list_owner = world.spawn()
  try! (world.set_by_key(
    list_owner,
    @light_cluster.VisibleClusterableObjects::component(),
    @light_cluster.VisibleClusterableObjects::from_lists(
      [point_visible],
      [],
      [],
      [],
    ),
  )
  |> ignore)

  let extracted = render3d_collect_extracted_point_lights(world)
  inspect(extracted.length(), content="1")
  inspect(extracted[0].entity == point_visible, content="true")
}

///|
test "pbr render light: spot extraction prefers visible clusterable entity list when present" {
  let world = @ecs.World::new()
  world.insert_resource(
    @light.ecs_key_directional_light_shadow_map,
    @light.DirectionalLightShadowMap::new(1024),
  )
  let spot_visible = world.spawn()
  try! (world.set_by_key(
    spot_visible,
    @light.ecs_key_spot_light,
    @light.SpotLight::default().with_intensity(10.0F),
  )
  |> ignore)
  let spot_hidden = world.spawn()
  try! (world.set_by_key(
    spot_hidden,
    @light.ecs_key_spot_light,
    @light.SpotLight::default().with_intensity(20.0F),
  )
  |> ignore)

  let list_owner = world.spawn()
  try! (world.set_by_key(
    list_owner,
    @light_cluster.VisibleClusterableObjects::component(),
    @light_cluster.VisibleClusterableObjects::from_lists(
      [spot_visible],
      [],
      [],
      [],
    ),
  )
  |> ignore)

  let extracted = render3d_collect_extracted_spot_lights(world)
  inspect(extracted.length(), content="1")
  inspect(extracted[0].entity == spot_visible, content="true")
}

///|
test "pbr render light: spot/directional propagate affects_lightmapped_mesh_diffuse" {
  let world = @ecs.World::new()

  let spot_entity = world.spawn()
  try! (world.set_by_key(
    spot_entity,
    @light.ecs_key_spot_light,
    @light.SpotLight::default().with_affects_lightmapped_mesh_diffuse(false),
  )
  |> ignore)
  let spots = render3d_collect_extracted_spot_lights(world)
  inspect(spots.length(), content="1")
  inspect(spots[0].affects_lightmapped_mesh_diffuse, content="false")

  let directional_entity = world.spawn()
  try! (world.set_by_key(
    directional_entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default().with_affects_lightmapped_mesh_diffuse(
      false,
    ),
  )
  |> ignore)
  let directionals = render3d_collect_extracted_directional_lights(world)
  inspect(directionals.length(), content="1")
  inspect(directionals[0].affects_lightmapped_mesh_diffuse, content="false")
}

///|
test "pbr render light: directional cascade overlap propagates to gpu lights" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  let updated = @light.CascadeShadowConfigBuilder::default()
    .with_overlap_proportion(0.37F)
    .build()
  try! (world.set_by_key(
    entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default().with_cascade_shadow_config(Some(updated)),
  )
  |> ignore)

  let extracted = render3d_collect_extracted_directional_lights(world)
  inspect(extracted.length(), content="1")
  inspect(
    approx_eq(extracted[0].cascade_overlap_proportion, 0.37F, 1.0e-6F),
    content="true",
  )
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
    @light.DirectionalLight::default(),
  )
  |> ignore)

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
    @light.DirectionalLight::default().with_shadow_maps_enabled(true),
  )
  |> ignore)

  let extracted = render3d_collect_extracted_directional_lights(world)
  inspect(extracted.length(), content="1")
  inspect(extracted[0].cascade_count, content="4")
  let gpu_lights = render3d_collect_gpu_lights(world)
  inspect(gpu_lights.n_directional_lights, content="1")
  inspect(gpu_lights.directional_lights[0].num_cascades, content="4")
  inspect(
    gpu_lights.directional_lights[0].depth_texture_base_index,
    content="0",
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
    @light.DirectionalLight::default().with_shadow_maps_enabled(true),
  )
  |> ignore)
  try! (world.set_by_key(
    shadow_and_volumetric,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::default(),
  )
  |> ignore)

  try! (world.set_by_key(
    shadow_only,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default().with_shadow_maps_enabled(true),
  )
  |> ignore)

  try! (world.set_by_key(
    no_shadow,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default(),
  )
  |> ignore)

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
  let first_config = @light.CascadeShadowConfigBuilder::default()
    .with_num_cascades(2)
    .build()
  try! (world.set_by_key(
    first,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default()
    .with_shadow_maps_enabled(true)
    .with_cascade_shadow_config(Some(first_config)),
  )
  |> ignore)

  let second = world.spawn()
  let second_config = @light.CascadeShadowConfigBuilder::default()
    .with_num_cascades(3)
    .build()
  try! (world.set_by_key(
    second,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default()
    .with_shadow_maps_enabled(true)
    .with_cascade_shadow_config(Some(second_config)),
  )
  |> ignore)

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
    @light.DirectionalLight::default(),
  )
  |> ignore)

  let decals = @pbr_decal.RenderClusteredDecals::default()
  let inserted_decal_index = decals.insert_decal(
    directional,
    @pbr_decal.ClusteredDecal::default(),
  )
  world.insert_resource(@pbr_decal.ecs_key_render_clustered_decals, decals)

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
    @light.PointLight::default(),
  )
  |> ignore)

  let shadow_only = world.spawn()
  try! (world.set_by_key(
    shadow_only,
    @light.ecs_key_point_light,
    @light.PointLight::default().with_shadow_maps_enabled(true),
  )
  |> ignore)

  let shadow_and_vol = world.spawn()
  try! (world.set_by_key(
    shadow_and_vol,
    @light.ecs_key_point_light,
    @light.PointLight::default().with_shadow_maps_enabled(true),
  )
  |> ignore)
  try! (world.set_by_key(
    shadow_and_vol,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::default(),
  )
  |> ignore)

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
    @light.SpotLight::default(),
  )
  |> ignore)

  let shadow_only = world.spawn()
  try! (world.set_by_key(
    shadow_only,
    @light.ecs_key_spot_light,
    @light.SpotLight::default().with_shadow_maps_enabled(true),
  )
  |> ignore)

  let shadow_and_vol = world.spawn()
  try! (world.set_by_key(
    shadow_and_vol,
    @light.ecs_key_spot_light,
    @light.SpotLight::default().with_shadow_maps_enabled(true),
  )
  |> ignore)
  try! (world.set_by_key(
    shadow_and_vol,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::default(),
  )
  |> ignore)

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
    @light.SpotLight::default().with_shadow_maps_enabled(true),
  )
  |> ignore)

  let point = world.spawn()
  try! (world.set_by_key(
    point,
    @light.ecs_key_point_light,
    @light.PointLight::default(),
  )
  |> ignore)

  let point_shadow = world.spawn()
  try! (world.set_by_key(
    point_shadow,
    @light.ecs_key_point_light,
    @light.PointLight::default().with_shadow_maps_enabled(true),
  )
  |> ignore)

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
    @light.PointLight::default().with_shadow_maps_enabled(true),
  )
  |> ignore)

  let directional = world.spawn()
  let directional_config = @light.CascadeShadowConfigBuilder::default()
    .with_num_cascades(2)
    .build()
  try! (world.set_by_key(
    directional,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default()
    .with_shadow_maps_enabled(true)
    .with_cascade_shadow_config(Some(directional_config)),
  )
  |> ignore)

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
    @light.DirectionalLight::default(),
  )
  |> ignore)
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
      @sprite.Color::new(0.25F, 0.5F, 0.75F, 1.0F),
      2.0F,
    ).with_affects_lightmapped_meshes(false),
  )
  let gpu_lights = render3d_collect_gpu_lights(world)
  inspect(gpu_lights.ambient_light_affects_lightmapped_meshes, content="0")
  inspect(approx_eq(gpu_lights.ambient_color.r, 0.5F, 1.0e-6F), content="true")
  inspect(approx_eq(gpu_lights.ambient_color.g, 1.0F, 1.0e-6F), content="true")
  inspect(approx_eq(gpu_lights.ambient_color.b, 1.5F, 1.0e-6F), content="true")
}

///|
test "pbr render light: gpu lights carries bevy-shaped cluster dimensions" {
  let world = @ecs.World::new()
  let gpu_lights = render3d_collect_gpu_lights(world)
  let expected_factors_zw = @light_cluster.calculate_cluster_factors(
    0.1F, 1000.0F, 24.0F, false,
  )
  inspect(gpu_lights.cluster_dimensions.0, content="16")
  inspect(gpu_lights.cluster_dimensions.1, content="9")
  inspect(gpu_lights.cluster_dimensions.2, content="24")
  inspect(gpu_lights.cluster_dimensions.3, content="3456")
  inspect(
    approx_eq(gpu_lights.cluster_factors.x, 0.0F, 1.0e-6F),
    content="true",
  )
  inspect(
    approx_eq(gpu_lights.cluster_factors.y, 0.0F, 1.0e-6F),
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
test "pbr render light: gpu lights cluster dimensions follow cluster config component" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.set_by_key(
    entity,
    @sprite.ecs_key_camera,
    @sprite.Camera::default(),
  )
  |> ignore)
  try! (world.set_by_key(
    entity,
    @light_cluster.ClusterConfig::component(),
    @light_cluster.ClusterConfig::XYZ(
      8,
      4,
      12,
      @light_cluster.ClusterZConfig::default(),
      false,
    ),
  )
  |> ignore)
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
      @light_cluster.ClusterZConfig::default(),
      false,
    ),
  )
  |> ignore)
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
    @sprite.ecs_key_camera,
    @sprite.Camera::default(),
  )
  |> ignore)
  try! (world.set_by_key(
    entity,
    @light_cluster.ClusterConfig::component(),
    @light_cluster.ClusterConfig::None,
  )
  |> ignore)
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
    @sprite.ecs_key_camera,
    @sprite.Camera::default(),
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
  let gpu_lights = render3d_collect_gpu_lights(world)
  inspect(gpu_lights.cluster_dimensions.0, content="12")
  inspect(gpu_lights.cluster_dimensions.1, content="6")
  inspect(gpu_lights.cluster_dimensions.2, content="8")
  inspect(gpu_lights.cluster_dimensions.3, content="576")
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
test "pbr render light: volumetric flags require shadow maps for point and directional lights" {
  let world = @ecs.World::new()

  let point_entity = world.spawn()
  try! (world.set_by_key(
    point_entity,
    @light.ecs_key_point_light,
    @light.PointLight::default(),
  )
  |> ignore)
  try! (world.set_by_key(
    point_entity,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::default(),
  )
  |> ignore)
  let points_no_shadow = render3d_collect_extracted_point_lights(world)
  inspect(points_no_shadow.length(), content="1")
  let point_flags_no_shadow = render3d_point_light_flags(points_no_shadow[0])
  inspect((point_flags_no_shadow & (1U << 2)) == 0U, content="true")

  try! (world.set_by_key(
    point_entity,
    @light.ecs_key_point_light,
    @light.PointLight::default().with_shadow_maps_enabled(true),
  )
  |> ignore)
  let points_with_shadow = render3d_collect_extracted_point_lights(world)
  let point_flags_with_shadow = render3d_point_light_flags(
    points_with_shadow[0],
  )
  inspect((point_flags_with_shadow & (1U << 2)) != 0U, content="true")

  let directional_entity = world.spawn()
  try! (world.set_by_key(
    directional_entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default(),
  )
  |> ignore)
  try! (world.set_by_key(
    directional_entity,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::default(),
  )
  |> ignore)
  let directional_no_shadow = render3d_collect_extracted_directional_lights(
    world,
  )
  inspect(directional_no_shadow.length(), content="1")
  let directional_flags_no_shadow = render3d_directional_light_flags(
    directional_no_shadow[0],
  )
  inspect((directional_flags_no_shadow & (1U << 1)) == 0U, content="true")

  try! (world.set_by_key(
    directional_entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default().with_shadow_maps_enabled(true),
  )
  |> ignore)
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
    @light.DirectionalLight::default(),
  )
  |> ignore)

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

  let entity_override = world.spawn()
  try! (world.set_by_key(
    entity_override,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default(),
  )
  |> ignore)
  try! (world.set_by_key(
    entity_override,
    @light.ecs_key_sun_disk,
    @light.SunDisk::off(),
  )
  |> ignore)

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
