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
// Bevy source: `bevy/crates/bevy_gizmos/src/aabb.rs`.

///|
let ecs_key_show_aabb_gizmo : @ecs.ComponentKey[ShowAabbGizmo] = @ecs.register_component(
  debug_name="mgstudio_gizmos::ShowAabbGizmo",
)

///|
pub(all) struct AabbGizmoConfigGroup {
  draw_all : Bool
  default_color : @sprite.Color?
}

///|
pub fn AabbGizmoConfigGroup::default() -> AabbGizmoConfigGroup {
  AabbGizmoConfigGroup::{ draw_all: false, default_color: None }
}

///|
pub impl Default for AabbGizmoConfigGroup with default() {
  AabbGizmoConfigGroup::default()
}

///|
pub impl @sprite.GizmoConfigGroup for AabbGizmoConfigGroup with gizmo_config_group_marker(
  _self,
) {

}

///|
pub struct ShowAabbGizmo {
  color : @sprite.Color?
}

///|
pub fn ShowAabbGizmo::default() -> ShowAabbGizmo {
  ShowAabbGizmo::{ color: None }
}

///|
pub fn ShowAabbGizmo::with_color(
  self : ShowAabbGizmo,
  color : @sprite.Color?,
) -> ShowAabbGizmo {
  ignore(self)
  ShowAabbGizmo::{ color, }
}

///|
pub impl @ecs.Component for ShowAabbGizmo with component() {
  ecs_key_show_aabb_gizmo
}

///|
fn aabb_gizmo_color_from_entity(entity : @core.Entity) -> @sprite.Color {
  let seed = Float::from_double(entity.id.to_double()) +
    Float::from_double(entity.generation.to_double()) * 97.0F
  let r = 0.2F + 0.8F * ((@math.sin(seed * 0.73F) + 1.0F) * 0.5F)
  let g = 0.2F + 0.8F * ((@math.sin(seed * 1.11F + 1.2F) + 1.0F) * 0.5F)
  let b = 0.2F + 0.8F * ((@math.sin(seed * 1.61F + 2.4F) + 1.0F) * 0.5F)
  @sprite.Color::new(r, g, b, 1.0F)
}

///|
fn aabb_gizmo_is_visible(
  view_visibility : @ecs.Comp[@visibility.ViewVisibility]?,
) -> Bool {
  match view_visibility {
    Some(comp) => comp.value().is_visible()
    None => true
  }
}

///|
fn aabb_gizmo_resolve_color(
  entity : @core.Entity,
  override_color : @sprite.Color?,
  config_group : AabbGizmoConfigGroup,
) -> @sprite.Color {
  match override_color {
    Some(color) => color
    None =>
      match config_group.default_color {
        Some(color) => color
        None => aabb_gizmo_color_from_entity(entity)
      }
  }
}

///|
fn aabb_local_corners(aabb : @camera.Aabb) -> Array[@math.Vec3] {
  let center = aabb.center()
  let half_size = aabb.half_size()
  let min = center.sub(half_size)
  let max = center.add(half_size)
  [
    @math.Vec3::new(min.x, min.y, min.z),
    @math.Vec3::new(max.x, min.y, min.z),
    @math.Vec3::new(max.x, max.y, min.z),
    @math.Vec3::new(min.x, max.y, min.z),
    @math.Vec3::new(min.x, min.y, max.z),
    @math.Vec3::new(max.x, min.y, max.z),
    @math.Vec3::new(max.x, max.y, max.z),
    @math.Vec3::new(min.x, max.y, max.z),
  ]
}

///|
fn[Config] draw_aabb_3d(
  gizmos : @sprite.Gizmos[Config],
  aabb : @camera.Aabb,
  transform : @transform.GlobalTransform,
  color : @sprite.Color,
) -> Unit {
  let corners = @transform.transform_points(transform, aabb_local_corners(aabb))
  let edges = [
    (0, 1),
    (1, 2),
    (2, 3),
    (3, 0),
    (4, 5),
    (5, 6),
    (6, 7),
    (7, 4),
    (0, 4),
    (1, 5),
    (2, 6),
    (3, 7),
  ]
  for edge in edges {
    let (start_idx, end_idx) = edge
    gizmos.line_3d(corners[start_idx], corners[end_idx], color)
  }
}

///|
pub fn draw_aabb_gizmos(
  query : @ecs.Query[
    (
      @ecs.Comp[@camera.Aabb],
      @ecs.Comp[@transform.GlobalTransform],
      @ecs.Comp[@visibility.ViewVisibility]?,
      @ecs.Comp[ShowAabbGizmo],
    ),
    @ecs.All,
  ],
  gizmos : @sprite.Gizmos[AabbGizmoConfigGroup],
) -> Unit {
  let config_group = gizmos.config_group()
  query.for_each(fn(entity, data) {
    let (aabb_comp, transform_comp, view_visibility_comp, show_aabb_comp) = data
    if !aabb_gizmo_is_visible(view_visibility_comp) {
      return
    }
    let show_aabb = show_aabb_comp.value()
    let color = aabb_gizmo_resolve_color(entity, show_aabb.color, config_group)
    draw_aabb_3d(gizmos, aabb_comp.value(), transform_comp.value(), color)
  }) catch {
    _ => ()
  }
}

///|
pub fn draw_all_aabb_gizmos(
  query : @ecs.Query[
    (
      @ecs.Comp[@camera.Aabb],
      @ecs.Comp[@transform.GlobalTransform],
      @ecs.Comp[@visibility.ViewVisibility]?,
    ),
    @ecs.Without[ShowAabbGizmo],
  ],
  gizmos : @sprite.Gizmos[AabbGizmoConfigGroup],
) -> Unit {
  let config_group = gizmos.config_group()
  if !config_group.draw_all {
    return
  }
  query.for_each(fn(entity, data) {
    let (aabb_comp, transform_comp, view_visibility_comp) = data
    if !aabb_gizmo_is_visible(view_visibility_comp) {
      return
    }
    let color = aabb_gizmo_resolve_color(entity, None, config_group)
    draw_aabb_3d(gizmos, aabb_comp.value(), transform_comp.value(), color)
  }) catch {
    _ => ()
  }
}

///|
pub fn aabb_gizmo_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @sprite.init_gizmo_group(
    app
    .add_systems(
      @app.PostUpdate,
      @app.system(@app.system_param2(draw_aabb_gizmos)),
    )
    .add_systems(
      @app.PostUpdate,
      @app.system(@app.system_param2(draw_all_aabb_gizmos)),
    ),
    AabbGizmoConfigGroup::default(),
  )
}
