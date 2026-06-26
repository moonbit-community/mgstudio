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
fn light_wbtest_sync_light_entity(
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
fn light_wbtest_extract_directional_lights(world : @ecs.World) -> Unit {
  world.for_each_component(@light.ecs_key_directional_light, fn(entity, _) {
    light_wbtest_sync_light_entity(world, entity)
  })
  ignore(world.increment_change_tick())
  extract_lights(world)
}

///|
fn light_wbtest_point_shadow_map_size(world : @ecs.World) -> Int {
  match world.get_resource(@light.ecs_key_point_light_shadow_map) {
    Some(value) => value.size
    None => -1
  }
}

///|
fn light_wbtest_directional_shadow_map_size(world : @ecs.World) -> Int {
  match world.get_resource(@light.ecs_key_directional_light_shadow_map) {
    Some(value) => value.size
    None => -1
  }
}

///|
test "pbr/render light: extract_lights mirrors Bevy shadow map resources into render world" {
  let source_world = @ecs.World::new()
  let render_world = @ecs.World::new()
  source_world.insert_resource(
    @light.ecs_key_point_light_shadow_map,
    @light.PointLightShadowMap::new(512),
  )
  source_world.insert_resource(
    @light.ecs_key_directional_light_shadow_map,
    @light.DirectionalLightShadowMap::new(1024),
  )

  extract_shadow_map_resources_from_worlds(
    source_world,
    render_world,
    @core.SystemTicks::new(0, 1),
  )
  inspect(light_wbtest_point_shadow_map_size(render_world), content="512")
  inspect(
    light_wbtest_directional_shadow_map_size(render_world),
    content="1024",
  )

  ignore(source_world.increment_change_tick())
  ignore(source_world.increment_change_tick())
  source_world.insert_resource(
    @light.ecs_key_point_light_shadow_map,
    @light.PointLightShadowMap::new(2048),
  )
  source_world.insert_resource(
    @light.ecs_key_directional_light_shadow_map,
    @light.DirectionalLightShadowMap::new(4096),
  )
  extract_shadow_map_resources_from_worlds(
    source_world,
    render_world,
    @core.SystemTicks::new(1, 2),
  )
  inspect(light_wbtest_point_shadow_map_size(render_world), content="2048")
  inspect(
    light_wbtest_directional_shadow_map_size(render_world),
    content="4096",
  )
}

///|
test "pbr/render light: directional shadow flags respect texture array layer cap" {
  let world = @ecs.World::new()

  let first = world.spawn()
  let first_config = @light.CascadeShadowConfigBuilder::CascadeShadowConfigBuilder()
    .with_num_cascades(MAX_CASCADES_PER_LIGHT)
    .build()
  try! world.set_by_key(
    first,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight()
    .with_shadow_maps_enabled(true)
    .with_cascade_shadow_config(Some(first_config)),
  )
  try! world.set_by_key(
    first,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::VolumetricLight(),
  )

  let second = world.spawn()
  let second_config = @light.CascadeShadowConfigBuilder::CascadeShadowConfigBuilder()
    .with_num_cascades(1)
    .build()
  try! world.set_by_key(
    second,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight()
    .with_shadow_maps_enabled(true)
    .with_cascade_shadow_config(Some(second_config)),
  )
  try! world.set_by_key(
    second,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::VolumetricLight(),
  )

  light_wbtest_extract_directional_lights(world)
  let extracted = render3d_collect_extracted_directional_lights(world)
  let max_texture_array_layers = MAX_CASCADES_PER_LIGHT
  let volumetric_limit = render3d_directional_lights_volumetric_enabled_count(
    extracted, max_texture_array_layers,
  )
  inspect(volumetric_limit, content="1")

  let (first_shadow_enabled, first_cascades) = render3d_directional_light_shadow_state(
    extracted[0],
    0,
    max_texture_array_layers,
  )
  inspect(first_shadow_enabled, content="true")
  inspect(first_cascades, content=MAX_CASCADES_PER_LIGHT.to_string())
  let first_flags = render3d_directional_light_flags_for_gpu(
    extracted[0],
    first_shadow_enabled,
    extracted[0].volumetric && first_shadow_enabled && 0 < volumetric_limit,
  )
  inspect(
    (first_flags & DIRECTIONAL_LIGHT_FLAG_SHADOW_MAPS_ENABLED) != 0U,
    content="true",
  )
  inspect(
    (first_flags & DIRECTIONAL_LIGHT_FLAG_VOLUMETRIC) != 0U,
    content="true",
  )

  let (second_shadow_enabled, second_cascades) = render3d_directional_light_shadow_state(
    extracted[1],
    first_cascades,
    max_texture_array_layers,
  )
  inspect(second_shadow_enabled, content="false")
  inspect(second_cascades, content="0")
  let second_flags = render3d_directional_light_flags_for_gpu(
    extracted[1],
    second_shadow_enabled,
    extracted[1].volumetric && second_shadow_enabled && 1 < volumetric_limit,
  )
  inspect(
    (second_flags & DIRECTIONAL_LIGHT_FLAG_SHADOW_MAPS_ENABLED) == 0U,
    content="true",
  )
  inspect(
    (second_flags & DIRECTIONAL_LIGHT_FLAG_VOLUMETRIC) == 0U,
    content="true",
  )
}
