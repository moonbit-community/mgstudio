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
// Bevy source: `bevy/crates/bevy_light/src/lib.rs`.

///|
type DirectionalLightVisibilityQuery = @ecs.Query[
  (
    @ecs.Read[DirectionalLight],
    @ecs.Read[@camera_primitives.CascadesFrusta],
    @ecs.Write[@camera_visibility.CascadesVisibleEntities],
    @ecs.Optional[@camera_render_layers.RenderLayers],
    @ecs.Read[@visibility.ViewVisibility],
  ),
  @ecs.Without[SpotLight],
]

///|
type ShadowCasterVisibilityQuery = @ecs.Query[
  (
    @core.Entity,
    @ecs.Read[@visibility.InheritedVisibility],
    @ecs.Write[@visibility.ViewVisibility],
    @ecs.Optional[@camera_render_layers.RenderLayers],
    @ecs.Optional[@camera_primitives.Aabb],
    @ecs.Optional[@transform.GlobalTransform],
    @ecs.Has[@visibility.VisibilityRange],
    @ecs.Has[@visibility.NoFrustumCulling],
  ),
  (
    @ecs.Without[NotShadowCaster],
    @ecs.Without[DirectionalLight],
    @ecs.Without[@visibility.NoCpuCulling],
    @ecs.With[@mesh.Mesh3d],
  ),
]

///|
type PointLightVisibilityQuery = @ecs.Query[
  (
    @ecs.Read[PointLight],
    @ecs.Read[@transform.GlobalTransform],
    @ecs.Read[@camera_primitives.CubemapFrusta],
    @ecs.Write[@camera_visibility.CubemapVisibleEntities],
    @ecs.Optional[@camera_render_layers.RenderLayers],
  ),
  @ecs.All,
]

///|
type SpotLightVisibilityQuery = @ecs.Query[
  (
    @ecs.Read[SpotLight],
    @ecs.Read[@transform.GlobalTransform],
    @ecs.Read[@camera_primitives.Frustum],
    @ecs.Write[@camera_visibility.VisibleMeshEntities],
    @ecs.Optional[@camera_render_layers.RenderLayers],
  ),
  @ecs.All,
]

///|
fn shadow_caster_visibility_query(
  world : @ecs.World,
) -> ShadowCasterVisibilityQuery {
  @ecs.query_filtered(
    world,
    (
      @ecs.Without::new(ecs_key_not_shadow_caster),
      @ecs.Without::new(ecs_key_directional_light),
      @ecs.Without::new(@visibility.ecs_key_no_cpu_culling),
      @ecs.With::new(@mesh.ecs_key_mesh3d),
    ),
  )
}

///|
fn shadow_visibility_layers(
  layers : @ecs.Optional[@camera_render_layers.RenderLayers],
) -> @camera_render_layers.RenderLayers {
  layers.value().unwrap_or(@camera_render_layers.RenderLayers::RenderLayers())
}

///|
fn shadow_visibility_range_culls(
  ranges : @camera_visibility.VisibleEntityRanges?,
  entity : @core.Entity,
  view : @core.Entity,
) -> Bool {
  match ranges {
    Some(visible_entity_ranges) =>
      !visible_entity_ranges.entity_is_in_range_of_view(entity, view)
    None => false
  }
}

///|
fn shadow_visible_entities_sort(
  visible_entities : @camera_visibility.VisibleMeshEntities,
) -> Unit {
  visible_entities.iter().sort_by(fn(left, right) { left.id.compare(right.id) })
}

///|
// Bevy source: `bevy/crates/bevy_light/src/lib.rs::check_dir_light_mesh_visibility`.
pub fn check_dir_light_mesh_visibility(world : @ecs.World) -> Unit {
  let directional_lights : DirectionalLightVisibilityQuery = @ecs.query_filtered(
    world,
    @ecs.Without::new(ecs_key_spot_light),
  )
  let visible_entity_query = shadow_caster_visibility_query(world)
  let visible_entity_ranges = world.get_resource(
    @camera_visibility.ecs_key_visible_entity_ranges,
  )
  try! directional_lights.view(fn(_light_entity, item) {
    let (
      directional_light,
      cascades_frusta,
      cascades_visible_entities,
      light_layers,
      light_view_visibility,
    ) = item
    cascades_visible_entities.modify(fn(visible_entities) {
      visible_entities.clear()
      if !directional_light.value().shadow_maps_enabled ||
        !light_view_visibility.value().get() {
        return
      }
      let view_mask = shadow_visibility_layers(light_layers)
      for entry in cascades_frusta.value().iter() {
        let (view, view_frusta) = entry
        let cascade_visible_entities : Array[
          @camera_visibility.VisibleMeshEntities,
        ] = []
        for _ in view_frusta {
          cascade_visible_entities.push(
            @camera_visibility.VisibleMeshEntities::VisibleMeshEntities(),
          )
        }
        try! visible_entity_query.view(fn(_candidate_entity, candidate) {
          let (
            entity,
            inherited_visibility,
            view_visibility,
            entity_layers,
            aabb,
            transform,
            has_visibility_range,
            has_no_frustum_culling,
          ) = candidate
          if !inherited_visibility.value().get() ||
            !view_mask.intersects(shadow_visibility_layers(entity_layers)) {
            return
          }
          if has_visibility_range.present() &&
            shadow_visibility_range_culls(visible_entity_ranges, entity, view) {
            return
          }
          let mut visible = false
          match (aabb.value(), transform.value()) {
            (Some(model_aabb), Some(global_transform)) =>
              for index = 0; index < view_frusta.length(); index = index + 1 {
                if has_no_frustum_culling.present() ||
                  view_frusta[index].intersects_obb(
                    model_aabb,
                    global_transform.affine(),
                    false,
                    true,
                  ) {
                  visible = true
                  cascade_visible_entities[index].push(entity)
                }
              }
            _ => {
              visible = true
              for entities in cascade_visible_entities {
                entities.push(entity)
              }
            }
          }
          if visible {
            @visibility.SetViewVisibility::set_visible(view_visibility)
          }
        })
        for entities in cascade_visible_entities {
          shadow_visible_entities_sort(entities)
        }
        visible_entities.set(view, cascade_visible_entities)
      }
    })
  })
}

///|
fn shadow_visible_light_entities(world : @ecs.World) -> Array[@core.Entity] {
  let entities : Array[@core.Entity] = []
  let checked : Map[UInt64, Bool] = Map([])
  let visible_lights : @ecs.Query[
    @ecs.Read[@camera_camera.VisibleEntities],
    @ecs.All,
  ] = @ecs.query(world)
  try! visible_lights.view(fn(_view, visible_entities) {
    for entity in visible_entities.value().get(cluster_visibility_class_id()) {
      let key = entity.to_bits()
      if !checked.contains(key) {
        checked.set(key, true)
        entities.push(entity)
      }
    }
  })
  entities
}

///|
fn shadow_lod_range_culls(
  ranges : @camera_visibility.VisibleEntityRanges?,
  shadow_lod_origin : @core.Entity?,
  entity : @core.Entity,
) -> Bool {
  match ranges {
    Some(visible_entity_ranges) =>
      match shadow_lod_origin {
        Some(origin) =>
          !visible_entity_ranges.entity_is_in_range_of_view(entity, origin)
        None => true
      }
    None => false
  }
}

///|
fn check_point_light_visibility(
  visible_entity_query : ShadowCasterVisibilityQuery,
  visible_entity_ranges : @camera_visibility.VisibleEntityRanges?,
  shadow_lod_origin : @core.Entity?,
  item : (
    @ecs.Read[PointLight],
    @ecs.Read[@transform.GlobalTransform],
    @ecs.Read[@camera_primitives.CubemapFrusta],
    @ecs.Write[@camera_visibility.CubemapVisibleEntities],
    @ecs.Optional[@camera_render_layers.RenderLayers],
  ),
) -> Unit {
  let (
    point_light,
    light_transform,
    cubemap_frusta,
    cubemap_visible_entities,
    light_layers,
  ) = item
  if !point_light.value().shadow_maps_enabled {
    return
  }
  let view_mask = shadow_visibility_layers(light_layers)
  let light_sphere = @camera_primitives.Sphere::new(
    light_transform.value().translation(),
    point_light.value().range,
  )
  cubemap_visible_entities.modify(fn(visible_entities) {
    for entities in visible_entities.iter() {
      entities.clear()
    }
    try! visible_entity_query.view(fn(_candidate_entity, candidate) {
      let (
        entity,
        inherited_visibility,
        view_visibility,
        entity_layers,
        aabb,
        transform,
        has_visibility_range,
        has_no_frustum_culling,
      ) = candidate
      if !inherited_visibility.value().get() ||
        !view_mask.intersects(shadow_visibility_layers(entity_layers)) {
        return
      }
      if has_visibility_range.present() &&
        shadow_lod_range_culls(visible_entity_ranges, shadow_lod_origin, entity) {
        return
      }
      match (aabb.value(), transform.value()) {
        (Some(model_aabb), Some(global_transform)) => {
          if !has_no_frustum_culling.present() &&
            !light_sphere.intersects_obb(model_aabb, global_transform.affine()) {
            return
          }
          for index = 0
              index < cubemap_frusta.value().iter().length()
              index = index + 1 {
            if has_no_frustum_culling.present() ||
              cubemap_frusta.value().iter()[index].intersects_obb(
                model_aabb,
                global_transform.affine(),
                true,
                true,
              ) {
              @visibility.SetViewVisibility::set_visible(view_visibility)
              visible_entities.iter()[index].push(entity)
            }
          }
        }
        _ => {
          @visibility.SetViewVisibility::set_visible(view_visibility)
          for entities in visible_entities.iter() {
            entities.push(entity)
          }
        }
      }
    })
    for entities in visible_entities.iter() {
      shadow_visible_entities_sort(entities)
    }
  })
}

///|
fn check_spot_light_visibility(
  visible_entity_query : ShadowCasterVisibilityQuery,
  visible_entity_ranges : @camera_visibility.VisibleEntityRanges?,
  shadow_lod_origin : @core.Entity?,
  item : (
    @ecs.Read[SpotLight],
    @ecs.Read[@transform.GlobalTransform],
    @ecs.Read[@camera_primitives.Frustum],
    @ecs.Write[@camera_visibility.VisibleMeshEntities],
    @ecs.Optional[@camera_render_layers.RenderLayers],
  ),
) -> Unit {
  let (spot_light, light_transform, frustum, visible_entities, light_layers) = item
  if !spot_light.value().shadow_maps_enabled {
    return
  }
  let view_mask = shadow_visibility_layers(light_layers)
  let light_sphere = @camera_primitives.Sphere::new(
    light_transform.value().translation(),
    spot_light.value().range,
  )
  visible_entities.modify(fn(entities) {
    entities.clear()
    try! visible_entity_query.view(fn(_candidate_entity, candidate) {
      let (
        entity,
        inherited_visibility,
        view_visibility,
        entity_layers,
        aabb,
        transform,
        has_visibility_range,
        has_no_frustum_culling,
      ) = candidate
      if !inherited_visibility.value().get() ||
        !view_mask.intersects(shadow_visibility_layers(entity_layers)) {
        return
      }
      if has_visibility_range.present() &&
        shadow_lod_range_culls(visible_entity_ranges, shadow_lod_origin, entity) {
        return
      }
      match (aabb.value(), transform.value()) {
        (Some(model_aabb), Some(global_transform)) => {
          if !has_no_frustum_culling.present() &&
            !light_sphere.intersects_obb(model_aabb, global_transform.affine()) {
            return
          }
          if has_no_frustum_culling.present() ||
            frustum
            .value()
            .intersects_obb(model_aabb, global_transform.affine(), true, true) {
            @visibility.SetViewVisibility::set_visible(view_visibility)
            entities.push(entity)
          }
        }
        _ => {
          @visibility.SetViewVisibility::set_visible(view_visibility)
          entities.push(entity)
        }
      }
    })
    shadow_visible_entities_sort(entities)
  })
}

///|
// Bevy source: `bevy/crates/bevy_light/src/lib.rs::check_point_light_mesh_visibility`.
pub fn check_point_light_mesh_visibility(world : @ecs.World) -> Unit {
  let visible_entity_query = shadow_caster_visibility_query(world)
  let point_lights : PointLightVisibilityQuery = @ecs.query(world)
  let spot_lights : SpotLightVisibilityQuery = @ecs.query(world)
  let visible_entity_ranges = world.get_resource(
    @camera_visibility.ecs_key_visible_entity_ranges,
  )
  let shadow_lod_origin = get_shadow_lod_origin(world)
  for light_entity in shadow_visible_light_entities(world) {
    match (try! point_lights.get(light_entity)) {
      Some(point_light) => {
        check_point_light_visibility(
          visible_entity_query, visible_entity_ranges, shadow_lod_origin, point_light,
        )
        continue
      }
      None => ()
    }
    match (try! spot_lights.get(light_entity)) {
      Some(spot_light) =>
        check_spot_light_visibility(
          visible_entity_query, visible_entity_ranges, shadow_lod_origin, spot_light,
        )
      None => ()
    }
  }
}
