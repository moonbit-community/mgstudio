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
fn spot_light_copysign_one(sign_source : Float) -> Float {
  if (sign_source.reinterpret_as_uint() & 0x8000_0000U) != 0U {
    -1.0F
  } else {
    1.0F
  }
}

///|
// Bevy source: `bevy/crates/bevy_light/src/spot_light.rs::orthonormalize`.
pub fn orthonormalize(z_basis : @math.Vec3) -> @math.Mat3 {
  let normalized_z = z_basis.normalize_or_zero()
  let sign = spot_light_copysign_one(normalized_z.z)
  let a = -1.0F / (sign + normalized_z.z)
  let b = normalized_z.x * normalized_z.y * a
  let x_basis = @math.Vec3::new(
    1.0F + sign * normalized_z.x * normalized_z.x * a,
    sign * b,
    -sign * normalized_z.x,
  )
  let y_basis = @math.Vec3::new(
    b,
    sign + normalized_z.y * normalized_z.y * a,
    -normalized_z.y,
  )
  @math.Mat3::from_cols(x_basis, y_basis, normalized_z)
}

///|
fn spot_light_global_transform_back(
  transform : @transform.GlobalTransform,
) -> @math.Vec3 {
  transform.affine().matrix3.z_axis.normalize_or_zero()
}

///|
// Bevy source: `bevy/crates/bevy_light/src/spot_light.rs::spot_light_world_from_view`.
pub fn spot_light_world_from_view(
  transform : @transform.GlobalTransform,
) -> @math.Affine3 {
  @math.Affine3::from_mat3_translation(
    orthonormalize(spot_light_global_transform_back(transform)),
    transform.translation(),
  )
}

///|
// Bevy source: `bevy/crates/bevy_light/src/spot_light.rs::spot_light_clip_from_view`.
pub fn spot_light_clip_from_view(angle : Float, near_z : Float) -> @math.Mat4 {
  @math.Mat4::perspective_infinite_reverse_rh(angle * 2.0F, 1.0F, near_z)
}

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
