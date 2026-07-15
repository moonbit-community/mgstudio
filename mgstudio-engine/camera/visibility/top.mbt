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
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs`.

///|
const VISIBILITY_PLUGIN_NAME : String = "mgstudio.camera.visibility.VisibilityPlugin"

///|
let visibility_set_update_skinned_mesh_bounds : @app.SystemSet = @app.system_set(
  "mgstudio.camera.visibility.update_skinned_mesh_bounds",
)

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::VisibleMeshEntities`.
pub struct VisibleMeshEntities {
  entities : Array[@core.Entity]
}

///|
pub fn VisibleMeshEntities::VisibleMeshEntities() -> VisibleMeshEntities {
  VisibleMeshEntities::{ entities: [] }
}

///|
pub fn VisibleMeshEntities::len(self : VisibleMeshEntities) -> Int {
  self.entities.length()
}

///|
pub fn VisibleMeshEntities::is_empty(self : VisibleMeshEntities) -> Bool {
  self.entities.length() == 0
}

///|
pub fn VisibleMeshEntities::push(
  self : VisibleMeshEntities,
  entity : @core.Entity,
) -> Unit {
  self.entities.push(entity)
}

///|
pub fn VisibleMeshEntities::clear(self : VisibleMeshEntities) -> Unit {
  self.entities.clear()
}

///|
pub fn VisibleMeshEntities::iter(
  self : VisibleMeshEntities,
) -> Array[@core.Entity] {
  self.entities
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::CubemapVisibleEntities`.
pub struct CubemapVisibleEntities {
  data : Array[VisibleMeshEntities]
}

///|
pub fn CubemapVisibleEntities::CubemapVisibleEntities() -> CubemapVisibleEntities {
  CubemapVisibleEntities::{
    data: [
      VisibleMeshEntities::VisibleMeshEntities(),
      VisibleMeshEntities::VisibleMeshEntities(),
      VisibleMeshEntities::VisibleMeshEntities(),
      VisibleMeshEntities::VisibleMeshEntities(),
      VisibleMeshEntities::VisibleMeshEntities(),
      VisibleMeshEntities::VisibleMeshEntities(),
    ],
  }
}

///|
pub fn CubemapVisibleEntities::get(
  self : CubemapVisibleEntities,
  index : Int,
) -> VisibleMeshEntities? {
  if index < 0 || index >= self.data.length() {
    None
  } else {
    Some(self.data[index])
  }
}

///|
pub fn CubemapVisibleEntities::set(
  self : CubemapVisibleEntities,
  index : Int,
  entities : VisibleMeshEntities,
) -> Unit {
  if index >= 0 && index < self.data.length() {
    self.data[index] = entities
  }
}

///|
pub fn CubemapVisibleEntities::iter(
  self : CubemapVisibleEntities,
) -> Array[VisibleMeshEntities] {
  self.data
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::CascadesVisibleEntities`.
pub struct CascadesVisibleEntities {
  entities : @hashmap.HashMap[@core.Entity, Array[VisibleMeshEntities]]
}

///|
pub fn CascadesVisibleEntities::CascadesVisibleEntities() -> CascadesVisibleEntities {
  CascadesVisibleEntities::{ entities: @hashmap.HashMap([]) }
}

///|
pub fn CascadesVisibleEntities::get(
  self : CascadesVisibleEntities,
  view : @core.Entity,
) -> Array[VisibleMeshEntities] {
  self.entities.get(view).unwrap_or([])
}

///|
pub fn CascadesVisibleEntities::set(
  self : CascadesVisibleEntities,
  view : @core.Entity,
  entities : Array[VisibleMeshEntities],
) -> Unit {
  self.entities.set(view, entities)
}

///|
pub fn CascadesVisibleEntities::clear(self : CascadesVisibleEntities) -> Unit {
  self.entities.clear()
}

///|
pub let ecs_key_visible_mesh_entities : @ecs.ComponentKey[VisibleMeshEntities] = @ecs.register_component(
  debug_name="mgstudio.camera.VisibleMeshEntities",
)

///|
pub let ecs_key_cubemap_visible_entities : @ecs.ComponentKey[
  CubemapVisibleEntities,
] = @ecs.register_component(debug_name="mgstudio.camera.CubemapVisibleEntities")

///|
pub let ecs_key_cascades_visible_entities : @ecs.ComponentKey[
  CascadesVisibleEntities,
] = @ecs.register_component(
  debug_name="mgstudio.camera.CascadesVisibleEntities",
)

///|
pub impl @ecs.Component for VisibleMeshEntities with fn component() {
  ecs_key_visible_mesh_entities
}

///|
pub impl @ecs.Component for CubemapVisibleEntities with fn component() {
  ecs_key_cubemap_visible_entities
}

///|
pub impl @ecs.Component for CascadesVisibleEntities with fn component() {
  ecs_key_cascades_visible_entities
}

///|
fn visibility_radius_vec3(
  world_from_local : @math.Affine3,
  extents : @math.Vec3,
) -> Float {
  world_from_local.matrix3.mul_vec3(extents).length()
}

///|
fn visibility_cull_aabb(
  frustum : @camera_primitives.Frustum,
  aabb : @camera_primitives.Aabb,
  global_transform : @transform.GlobalTransform,
) -> Bool {
  let world_from_local = global_transform.affine()
  let model_sphere = @camera_primitives.Sphere::new(
    world_from_local.transform_point3(aabb.center()),
    visibility_radius_vec3(world_from_local, aabb.half_size()),
  )
  !frustum.intersects_sphere(model_sphere, false) ||
  !frustum.intersects_obb(aabb, world_from_local, true, false)
}

///|
fn visibility_cull_sphere(
  frustum : @camera_primitives.Frustum,
  sphere : @camera_primitives.Sphere,
) -> Bool {
  !frustum.intersects_sphere(sphere, false)
}

///|
fn check_visibility_visible_entities_system(world : @ecs.World) -> Unit {
  let visible_query : @ecs.Query[
    (
      @core.Entity,
      (
        @ecs.Read[@root_visibility.InheritedVisibility],
        @ecs.Write[@root_visibility.ViewVisibility],
        @ecs.Optional[@root_visibility.VisibilityClass],
        @ecs.Optional[@camera_render_layers.RenderLayers],
        @ecs.Optional[@camera_primitives.Aabb],
        @ecs.Optional[@camera_primitives.Sphere],
        @ecs.Read[@transform.GlobalTransform],
      ),
      (
        @ecs.Has[@root_visibility.NoFrustumCulling],
        @ecs.Has[@root_visibility.VisibilityRange],
      ),
    ),
    @ecs.Without[@root_visibility.NoCpuCulling],
  ] = @ecs.query_filtered(
    world,
    @ecs.Without::new(@root_visibility.ecs_key_no_cpu_culling),
  )
  let visible_entity_ranges = world.get_resource(ecs_key_visible_entity_ranges)
  let view_query : @ecs.Query[
    (
      @core.Entity,
      (
        @ecs.Write[@camera_camera.VisibleEntities],
        @ecs.Optional[@camera_render_layers.RenderLayers],
        @ecs.Read[@camera_camera.Camera],
        @ecs.Read[@camera_primitives.Frustum],
        @ecs.Has[@root_visibility.NoCpuCulling],
      ),
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! view_query.view(fn(_query_entity, data) {
    let (
      view_entity,
      (visible_entities, view_layers, camera, frustum, no_cpu_culling_camera),
    ) = data
    if !camera.value().is_active {
      return
    }
    let view_mask = view_layers
      .value()
      .unwrap_or(@camera_render_layers.RenderLayers::RenderLayers())
    visible_entities.modify(fn(value) {
      value.clear_all()
      try! visible_query.view(fn(_candidate_entity, candidate_data) {
        let (
          entity,
          (
            inherited_visibility,
            view_visibility,
            visibility_class,
            render_layers,
            aabb,
            sphere,
            global_transform,
          ),
          (no_frustum_culling, has_visibility_range),
        ) = candidate_data
        if !inherited_visibility.value().get() {
          return
        }
        let entity_layers = render_layers
          .value()
          .unwrap_or(@camera_render_layers.RenderLayers::RenderLayers())
        if !view_mask.intersects(entity_layers) {
          return
        }
        if has_visibility_range.present() {
          match visible_entity_ranges {
            Some(ranges) =>
              if !ranges.entity_is_in_range_of_view(entity, view_entity) {
                return
              }
            None => ()
          }
        }
        if !no_frustum_culling.present() && !no_cpu_culling_camera.present() {
          match aabb.value() {
            Some(model_aabb) =>
              if visibility_cull_aabb(
                  frustum.value(),
                  model_aabb,
                  global_transform.value(),
                ) {
                return
              }
            None =>
              match sphere.value() {
                Some(model_sphere) =>
                  if visibility_cull_sphere(frustum.value(), model_sphere) {
                    return
                  }
                None => ()
              }
          }
        }
        @root_visibility.SetViewVisibility::set_visible(view_visibility)
        match visibility_class.value() {
          Some(classes) =>
            for class_id in classes.iter() {
              value.push(entity, class_id)
            }
          None => ()
        }
      })
      value.sort_all()
    })
  })
}

///|
pub struct VisibilityPlugin {}

///|
pub fn VisibilityPlugin::VisibilityPlugin() -> VisibilityPlugin {
  VisibilityPlugin::{  }
}

///|
pub fn visibility_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  visibility_plugin_with(app, VisibilityPlugin::VisibilityPlugin())
}

///|
pub fn visibility_plugin_with(
  app : @app.App[@ecs.World],
  plugin : VisibilityPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  @root_visibility.visibility_plugin(app)
  .configure_set(
    @app.PostUpdate,
    @root_visibility.visibility_set_calculate_bounds,
    after=[@transform.transform_set_propagate, @asset.asset_event_system_set()],
  )
  .configure_set(@app.PostUpdate, visibility_set_update_skinned_mesh_bounds, after=[
    @root_visibility.visibility_set_calculate_bounds,
  ])
  .add_post_update_system_config(
    @app.system(@camera_primitives.calculate_bounds_system)
    .named("mgstudio.visibility.calculate_bounds")
    .in_set(@root_visibility.visibility_set_calculate_bounds),
  )
  .add_post_update_system_config(
    @app.system(@camera_primitives.update_skinned_mesh_bounds_system)
    .named("mgstudio.visibility.update_skinned_mesh_bounds")
    .in_set(visibility_set_update_skinned_mesh_bounds),
  )
  .add_post_update_system_config(
    @app.system(check_visibility_visible_entities_system)
    .named("mgstudio.visibility.check_visibility_visible_entities")
    .in_set(@root_visibility.visibility_set_check_visibility),
  )
}

///|
pub impl @app.Plugin for VisibilityPlugin with fn name(_self) {
  VISIBILITY_PLUGIN_NAME
}

///|
pub impl @app.Plugin for VisibilityPlugin with fn build(self, app) {
  visibility_plugin_with(app, self)
}

///|
pub fn visibility_component_keys() -> (
  @ecs.ComponentKey[@root_visibility.Visibility],
  @ecs.ComponentKey[@root_visibility.InheritedVisibility],
  @ecs.ComponentKey[@root_visibility.ViewVisibility],
) {
  (
    @root_visibility.ecs_key_visibility, @root_visibility.ecs_key_inherited_visibility,
    @root_visibility.ecs_key_view_visibility,
  )
}

///|
pub fn default_visibility() -> @root_visibility.Visibility {
  @root_visibility.Visibility::Inherited
}

///|
pub fn inherited_visibility(
  visible : Bool,
) -> @root_visibility.InheritedVisibility {
  @root_visibility.InheritedVisibility::new(visible)
}

///|
pub fn view_visibility(visible : Bool) -> @root_visibility.ViewVisibility {
  @root_visibility.ViewVisibility::new(visible)
}

///|
pub fn no_frustum_culling() -> @root_visibility.NoFrustumCulling {
  @root_visibility.NoFrustumCulling::NoFrustumCulling()
}

///|
pub fn no_auto_aabb() -> @root_visibility.NoAutoAabb {
  @root_visibility.NoAutoAabb::NoAutoAabb()
}

///|
pub fn no_cpu_culling() -> @root_visibility.NoCpuCulling {
  @root_visibility.NoCpuCulling::NoCpuCulling()
}
