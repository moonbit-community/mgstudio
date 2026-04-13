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
  try! world.set_by_key(
    entity,
    @light.ecs_key_point_light,
    @light.PointLight::default().with_intensity(4.0F * @math.pi())
      .with_shadow_normal_bias(1.0F),
  )
  |> ignore

  let extracted = render3d_collect_extracted_point_lights(world)
  inspect(extracted.length(), content="1")
  let point = extracted[0]
  inspect(approx_eq(point.intensity, 1.0F, 1.0e-5F), content="true")
  let expected_shadow_normal_bias = 1.0F * (2.0F / 2048.0F) * @math.sqrt(
    2.0F,
  )
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
  try! world.set_by_key(
    entity,
    @light.ecs_key_spot_light,
    @light.SpotLight::default().with_intensity(4.0F * @math.pi())
      .with_inner_angle(0.2F)
      .with_outer_angle(0.5F)
      .with_shadow_normal_bias(1.0F),
  )
  |> ignore

  let extracted = render3d_collect_extracted_spot_lights(world)
  inspect(extracted.length(), content="1")
  let spot = extracted[0]
  inspect(approx_eq(spot.intensity, 1.0F, 1.0e-5F), content="true")
  let expected_shadow_normal_bias = 1.0F * (2.0F * @math.sin(0.5F) /
    @math.cos(0.5F) / 1024.0F) * @math.sqrt(2.0F)
  inspect(
    approx_eq(spot.shadow_normal_bias, expected_shadow_normal_bias, 1.0e-5F),
    content="true",
  )
}

///|
test "pbr render light: directional dir_to_light uses transform back vector" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default().with_shadow_normal_bias(2.0F),
  )
  |> ignore
  try! world.set_by_key(
    entity,
    @transform.ecs_key_transform,
    @transform.Transform::identity(),
  )
  |> ignore

  let extracted_directional = render3d_collect_extracted_directional_lights(world)
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
  try! world.set_by_key(
    hidden_point,
    @light.ecs_key_point_light,
    @light.PointLight::default(),
  )
  |> ignore
  try! world.set_by_key(
    hidden_point,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )
  |> ignore
  let hidden_directional = world.spawn()
  try! world.set_by_key(
    hidden_directional,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default(),
  )
  |> ignore
  try! world.set_by_key(
    hidden_directional,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )
  |> ignore

  inspect(render3d_collect_extracted_point_lights(world).length(), content="0")
  inspect(
    render3d_collect_extracted_directional_lights(world).length(),
    content="0",
  )
}

///|
test "pbr render light: spot/directional propagate affects_lightmapped_mesh_diffuse" {
  let world = @ecs.World::new()

  let spot_entity = world.spawn()
  try! world.set_by_key(
    spot_entity,
    @light.ecs_key_spot_light,
    @light.SpotLight::default().with_affects_lightmapped_mesh_diffuse(false),
  )
  |> ignore
  let spots = render3d_collect_extracted_spot_lights(world)
  inspect(spots.length(), content="1")
  inspect(spots[0].affects_lightmapped_mesh_diffuse, content="false")

  let directional_entity = world.spawn()
  try! world.set_by_key(
    directional_entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default().with_affects_lightmapped_mesh_diffuse(
      false,
    ),
  )
  |> ignore
  let directionals = render3d_collect_extracted_directional_lights(world)
  inspect(directionals.length(), content="1")
  inspect(directionals[0].affects_lightmapped_mesh_diffuse, content="false")
}

///|
test "pbr render light: directional cascade overlap propagates to gpu lights" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  let updated = @light.CascadeShadowConfigBuilder::default().with_overlap_proportion(
    0.37F,
  ).build()
  try! world.set_by_key(
    entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default().with_cascade_shadow_config(Some(updated)),
  )
  |> ignore

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
  try! world.set_by_key(
    entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default(),
  )
  |> ignore

  let gpu_lights = render3d_collect_gpu_lights(world)
  inspect(gpu_lights.n_directional_lights, content="1")
  inspect(gpu_lights.directional_lights[0].num_cascades, content="0")
  inspect(gpu_lights.directional_lights[0].cascades.length(), content="0")
}

///|
test "pbr render light: directional with shadows uses default cascade config" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default().with_shadow_maps_enabled(true),
  )
  |> ignore

  let extracted = render3d_collect_extracted_directional_lights(world)
  inspect(extracted.length(), content="1")
  inspect(extracted[0].cascade_count, content="4")
  let gpu_lights = render3d_collect_gpu_lights(world)
  inspect(gpu_lights.n_directional_lights, content="1")
  inspect(gpu_lights.directional_lights[0].num_cascades, content="4")
}

///|
test "pbr render light: gpu lights tracks ambient affects_lightmapped_meshes" {
  let world = @ecs.World::new()
  world.insert_resource(
    @light.ecs_key_global_ambient_light,
    @light.GlobalAmbientLight::default().with_affects_lightmapped_meshes(false),
  )
  let gpu_lights = render3d_collect_gpu_lights(world)
  inspect(gpu_lights.ambient_light_affects_lightmapped_meshes, content="0")
}

///|
test "pbr render light: directional sun disk defaults and component override propagate" {
  let world = @ecs.World::new()
  let entity_default = world.spawn()
  try! world.set_by_key(
    entity_default,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default(),
  )
  |> ignore

  let default_gpu = render3d_collect_gpu_lights(world)
  inspect(default_gpu.n_directional_lights, content="1")
  inspect(
    approx_eq(default_gpu.directional_lights[0].sun_disk_angular_size, 0.00930842F, 1.0e-6F),
    content="true",
  )
  inspect(
    approx_eq(default_gpu.directional_lights[0].sun_disk_intensity, 1.0F, 1.0e-6F),
    content="true",
  )

  let entity_override = world.spawn()
  try! world.set_by_key(
    entity_override,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::default(),
  )
  |> ignore
  try! world.set_by_key(
    entity_override,
    @light.ecs_key_sun_disk,
    @light.SunDisk::off(),
  )
  |> ignore

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
    approx_eq(override_gpu.directional_lights[1].sun_disk_angular_size, 0.0F, 1.0e-6F),
    content="true",
  )
  inspect(
    approx_eq(override_gpu.directional_lights[1].sun_disk_intensity, 0.0F, 1.0e-6F),
    content="true",
  )
}
