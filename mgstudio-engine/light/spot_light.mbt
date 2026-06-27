// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_light/src/spot_light.rs`.

///|
pub type SpotLightComponent = SpotLight

///|
pub type SpotLightTextureComponent = SpotLightTexture

///|
pub let ecs_key_spot_light_component : @ecs.ComponentKey[SpotLightComponent] = ecs_key_spot_light

///|
pub let ecs_key_spot_light_texture_component : @ecs.ComponentKey[
  SpotLightTextureComponent,
] = ecs_key_spot_light_texture

///|
type SpotLightBoundingSphereQuery = @ecs.Query[
  (@core.Entity, @ecs.Read[SpotLight], @ecs.Read[@transform.GlobalTransform]),
  @ecs.Or[(@ecs.Changed[SpotLight], @ecs.Changed[@transform.GlobalTransform])],
]

///|
// Bevy source: `bevy/crates/bevy_light/src/spot_light.rs::update_spot_light_bounding_spheres`.
pub fn update_spot_light_bounding_spheres(world : @ecs.World) -> Unit {
  let query : SpotLightBoundingSphereQuery = @ecs.query_filtered(
    world,
    @ecs.Or::new(
      (
        @ecs.Changed::new(ecs_key_spot_light),
        @ecs.Changed::new(@transform.ecs_key_global_transform),
      ),
    ),
  )
  let updates : Array[(@core.Entity, @camera_primitives.Sphere)] = []
  try! query.for_each(fn(_query_entity, item) {
    let (entity, spot_light, global_transform) = item
    updates.push(
      (
        entity,
        @camera_primitives.Sphere::new(
          global_transform.value().translation(),
          spot_light.value().range,
        ),
      ),
    )
  })
  for update in updates {
    let (entity, sphere) = update
    try! world.set_by_key(entity, @camera_primitives.ecs_key_sphere, sphere)
  }
}
