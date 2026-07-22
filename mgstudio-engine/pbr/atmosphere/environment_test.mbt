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
test "pbr atmosphere: environment map size is normalized to power-of-two" {
  let size = pbr_validate_atmosphere_environment_map_size(
    @math.UVec2::new(333, 777),
  )
  inspect(size.x, content="512")
  inspect(size.y, content="1024")
}

///|
fn test_image_has_usage(image : @asset.Image, usage_bits : Int) -> Bool {
  let usage = image.texture_usage_bits().reinterpret_as_uint()
  let required = usage_bits.reinterpret_as_uint()
  (usage & required) == required
}

///|
test "pbr atmosphere: probe component system creates Bevy-shaped generated cubemap" {
  let world = @ecs.World::new()
  defer world.close()
  let image_assets_key : @ecs.ResourceKey[@asset.Assets[@asset.Image]] = @asset.assets_resource_key()
  world.insert_resource(
    @asset.asset_server_resource_key,
    @asset.AssetServer::new(),
  )
  world.insert_resource(image_assets_key, @asset.Assets::new())
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @light.ecs_key_atmosphere_environment_map_light,
    @light.AtmosphereEnvironmentMapLight::new(
      2.5F,
      false,
      @math.UVec2::new(300, 500),
    ),
  )

  prepare_atmosphere_probe_components(world)

  let atmosphere_map = (try! world.get_by_key(
    entity, ecs_key_atmosphere_environment_map,
  )).unwrap()
  let generated = (try! world.get_by_key(
    entity, @light.ecs_key_generated_environment_map_light,
  )).unwrap()
  let image_handle = atmosphere_map.environment_map().unwrap()
  let stored_image = world
    .get_resource(image_assets_key)
    .unwrap()
    .get(image_handle)
    .unwrap()

  inspect(atmosphere_map.size().x, content="512")
  inspect(atmosphere_map.size().y, content="512")
  inspect(
    generated.environment_map.unwrap().id(),
    content=image_handle.id().to_string(),
  )
  inspect(generated.intensity, content="2.5")
  inspect(generated.affects_lightmapped_mesh_diffuse, content="false")
  inspect(stored_image.width(), content="512")
  inspect(stored_image.height(), content="3072")
  inspect(stored_image.pixel_byte_len(), content="12582912")
  inspect(stored_image.format() == Rgba16Float, content="true")
  inspect(stored_image.array_layout() == Some(RowCount(6)), content="true")
  inspect(stored_image.texture_view_dimension() == Some(Cube), content="true")
  inspect(
    test_image_has_usage(stored_image, @asset.IMAGE_USAGE_STORAGE_BINDING),
    content="true",
  )
  inspect(
    test_image_has_usage(stored_image, @asset.IMAGE_USAGE_COPY_SRC),
    content="true",
  )
}
