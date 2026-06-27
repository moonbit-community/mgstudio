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
// Bevy source: `bevy/crates/bevy_light/src/point_light.rs`.

///|
pub type PointLightComponent = PointLight

///|
pub type PointLightTextureComponent = PointLightTexture

///|
pub type PointLightShadowMapResource = PointLightShadowMap

///|
pub let ecs_key_point_light_component : @ecs.ComponentKey[PointLightComponent] = ecs_key_point_light

///|
pub let ecs_key_point_light_texture_component : @ecs.ComponentKey[
  PointLightTextureComponent,
] = ecs_key_point_light_texture

///|
pub let ecs_key_point_light_shadow_map_resource : @ecs.ResourceKey[
  PointLightShadowMapResource,
] = ecs_key_point_light_shadow_map

///|
pub fn point_light_shadow_map_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[PointLightShadowMapResource] {
  get_point_light_shadow_map_resource(world)
}

///|
type PointLightBoundingSphereQuery = @ecs.Query[
  (@core.Entity, @ecs.Read[PointLight], @ecs.Read[@transform.GlobalTransform]),
  @ecs.Or[(@ecs.Changed[PointLight], @ecs.Changed[@transform.GlobalTransform])],
]

///|
type PointLightFrustaQuery = @ecs.Query[
  (
    @ecs.Read[@transform.GlobalTransform],
    @ecs.Read[PointLight],
    @ecs.Write[@camera_primitives.CubemapFrusta],
    @ecs.Read[@visibility.ViewVisibility],
  ),
  @ecs.Or[
    (
      @ecs.Changed[@transform.GlobalTransform],
      @ecs.Changed[PointLight],
      @ecs.Changed[@visibility.ViewVisibility],
    ),
  ],
]

///|
fn point_light_global_transform_back(
  transform : @transform.GlobalTransform,
) -> @math.Vec3 {
  transform.affine().matrix3.z_axis.normalize_or_zero()
}

///|
fn point_light_cube_map_view_rotations() -> Array[@transform.Transform] {
  let rotations : Array[@transform.Transform] = []
  for face in @camera_primitives.cube_map_faces() {
    rotations.push(
      @transform.Transform::identity().looking_at(face.target(), face.up()),
    )
  }
  rotations
}

///|
// Bevy source: `bevy/crates/bevy_light/src/point_light.rs::update_point_light_bounding_spheres`.
pub fn update_point_light_bounding_spheres(world : @ecs.World) -> Unit {
  let query : PointLightBoundingSphereQuery = @ecs.query_filtered(
    world,
    @ecs.Or::new(
      (
        @ecs.Changed::new(ecs_key_point_light),
        @ecs.Changed::new(@transform.ecs_key_global_transform),
      ),
    ),
  )
  let updates : Array[(@core.Entity, @camera_primitives.Sphere)] = []
  try! query.for_each(fn(_query_entity, item) {
    let (entity, point_light, global_transform) = item
    updates.push(
      (
        entity,
        @camera_primitives.Sphere::new(
          global_transform.value().translation(),
          point_light.value().range,
        ),
      ),
    )
  })
  for update in updates {
    let (entity, sphere) = update
    try! world.set_by_key(entity, @camera_primitives.ecs_key_sphere, sphere)
  }
}

///|
// Bevy source: `bevy/crates/bevy_light/src/point_light.rs::update_point_light_frusta`.
pub fn update_point_light_frusta(world : @ecs.World) -> Unit {
  let query : PointLightFrustaQuery = @ecs.query_filtered(
    world,
    @ecs.Or::new(
      (
        @ecs.Changed::new(@transform.ecs_key_global_transform),
        @ecs.Changed::new(ecs_key_point_light),
        @ecs.Changed::new(@visibility.ecs_key_view_visibility),
      ),
    ),
  )
  let view_rotations = point_light_cube_map_view_rotations()
  try! query.for_each(fn(_entity, item) {
    let (transform, point_light, cubemap_frusta, view_visibility) = item
    let point_light_value = point_light.value()
    if !point_light_value.shadow_maps_enabled || !view_visibility.value().get() {
      return
    }

    let transform_value = transform.value()
    let clip_from_view = @math.Mat4::perspective_infinite_reverse_rh(
      @math.pi_half(),
      1.0F,
      point_light_value.shadow_map_near_z,
    )
    let view_translation = @math.Affine3::from_translation(
      transform_value.translation(),
    )
    let view_backward = point_light_global_transform_back(transform_value)
    let updated_frusta = @camera_primitives.CubemapFrusta::CubemapFrusta()
    for index = 0; index < view_rotations.length(); index = index + 1 {
      let world_from_view = view_translation.mul(
        @transform.GlobalTransform::from_transform(view_rotations[index]).affine(),
      )
      let clip_from_world = clip_from_view.mul(
        @math.Mat4::from_affine3(world_from_view.inverse()),
      )
      updated_frusta.set(
        index,
        @camera_primitives.Frustum::new(
          @camera_primitives.ViewFrustum::from_clip_from_world_custom_far(
            clip_from_world,
            transform_value.translation(),
            view_backward,
            point_light_value.range,
          ),
        ),
      )
    }
    cubemap_frusta.set(updated_frusta)
  })
}
