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
test "pbr light probe generate: downsampling config requires high limits" {
  inspect(
    pbr_downsampling_config(11, true).combine_bind_group_enabled(),
    content="false",
  )
  inspect(
    pbr_downsampling_config(12, false).combine_bind_group_enabled(),
    content="false",
  )
  inspect(
    pbr_downsampling_config(12, true).combine_bind_group_enabled(),
    content="true",
  )
}

///|
fn test_image_has_usage(image : @asset.Image, usage_bits : Int) -> Bool {
  let usage = image.texture_usage_bits().reinterpret_as_uint()
  let required = usage_bits.reinterpret_as_uint()
  (usage & required) == required
}

///|
test "pbr light probe generate: generated cubemap creates Bevy-shaped environment maps" {
  let world = @ecs.World::new()
  defer world.close()
  let image_assets_key : @ecs.ResourceKey[@asset.Assets[@asset.Image]] = @asset.assets_resource_key()
  world.insert_resource(
    @asset.asset_server_resource_key,
    @asset.AssetServer::new(),
  )
  world.insert_resource(image_assets_key, @asset.Assets::new())
  let source_handle = @asset.asset_with_world(world, fn() {
    world
    .get_resource_mut(image_assets_key)
    .unwrap()
    .modify(fn(images) {
      images.add(
        @asset.Image::new(64, 64 * 6, Bytes::new(64 * 64 * 6 * 8))
        .with_format(Rgba16Float)
        .with_texture_usage_bits(
          @asset.IMAGE_USAGE_TEXTURE_BINDING |
          @asset.IMAGE_USAGE_STORAGE_BINDING |
          @asset.IMAGE_USAGE_COPY_SRC,
        )
        .with_array_layout(Some(RowCount(6)))
        .with_texture_view_dimension(Some(Cube)),
      )
    })
  })
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @light.ecs_key_generated_environment_map_light,
    @light.GeneratedEnvironmentMapLight::new(Some(source_handle), 3.0F)
    .with_rotation(@math.Quat::from_rotation_y(0.5F))
    .with_affects_lightmapped_mesh_diffuse(false),
  )

  generate_environment_map_light(world)

  let environment = (try! world.get_by_key(
    entity, @light.ecs_key_environment_map_light,
  )).unwrap()
  let diffuse_handle = environment.diffuse_map.unwrap()
  let specular_handle = environment.specular_map.unwrap()
  let images = world.get_resource(image_assets_key).unwrap()
  let diffuse = images.get(diffuse_handle).unwrap()
  let specular = images.get(specular_handle).unwrap()

  inspect(environment.intensity, content="3")
  inspect(environment.affects_lightmapped_mesh_diffuse, content="false")
  inspect(diffuse.width(), content="32")
  inspect(diffuse.height(), content="192")
  inspect(diffuse.mip_level_count(), content="1")
  inspect(diffuse.format() == Rgba16Float, content="true")
  inspect(diffuse.texture_view_dimension() == Some(Cube), content="true")
  inspect(specular.width(), content="64")
  inspect(specular.height(), content="384")
  inspect(specular.mip_level_count(), content="7")
  inspect(specular.format() == Rgba16Float, content="true")
  inspect(specular.texture_view_dimension() == Some(Cube), content="true")
  inspect(
    test_image_has_usage(diffuse, @asset.IMAGE_USAGE_STORAGE_BINDING),
    content="true",
  )
  inspect(
    test_image_has_usage(specular, @asset.IMAGE_USAGE_STORAGE_BINDING),
    content="true",
  )
}
