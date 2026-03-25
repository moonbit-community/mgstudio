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
const TAU : Float = 6.283185307179586F

///|
const DEFAULT_LIGHT_GIZMO_RESOLUTION : Int = 32

///|
const DEFAULT_LIGHT_GIZMO_RADIUS_RESOLUTION : Int = 16

///|
let ecs_key_show_light_gizmo : @ecs.ComponentKey[ShowLightGizmo] = @ecs.register_component(
  debug_name="bevy_light::ShowLightGizmo",
)

///|
pub(all) enum LightGizmoColor {
  Manual(@sprite.Color)
  Varied
  MatchLightColor
  ByLightType
} derive(ToJson, FromJson)

///|
pub fn LightGizmoColor::default() -> LightGizmoColor {
  MatchLightColor
}

///|
pub(all) struct LightGizmoConfigGroup {
  draw_all : Bool
  color : LightGizmoColor
  point_light_color : @sprite.Color
  spot_light_color : @sprite.Color
  directional_light_color : @sprite.Color
} derive(ToJson, FromJson)

///|
pub fn LightGizmoConfigGroup::default() -> LightGizmoConfigGroup {
  LightGizmoConfigGroup::{
    draw_all: false,
    color: MatchLightColor,
    point_light_color: @sprite.Color::srgb(1.0F, 0.0F, 0.0F),
    spot_light_color: @sprite.Color::srgb(0.0F, 1.0F, 0.0F),
    directional_light_color: @sprite.Color::srgb(0.0F, 0.0F, 1.0F),
  }
}

///|
pub impl Default for LightGizmoConfigGroup with default() {
  LightGizmoConfigGroup::{
    draw_all: false,
    color: MatchLightColor,
    point_light_color: @sprite.Color::srgb(1.0F, 0.0F, 0.0F),
    spot_light_color: @sprite.Color::srgb(0.0F, 1.0F, 0.0F),
    directional_light_color: @sprite.Color::srgb(0.0F, 0.0F, 1.0F),
  }
}

///|
pub impl @sprite.GizmoConfigGroup for LightGizmoConfigGroup with gizmo_config_group_marker(
  _self,
) {

}

///|
pub struct ShowLightGizmo {
  color : LightGizmoColor?
} derive(ToJson, FromJson)

///|
pub fn ShowLightGizmo::default() -> ShowLightGizmo {
  ShowLightGizmo::{ color: None }
}

///|
pub fn ShowLightGizmo::with_color(
  self : ShowLightGizmo,
  color : LightGizmoColor?,
) -> ShowLightGizmo {
  ignore(self)
  ShowLightGizmo::{ color, }
}

///|
pub impl @ecs.Component for ShowLightGizmo with component() {
  ecs_key_show_light_gizmo
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn max_int(value : Int, min : Int) -> Int {
  if value < min {
    min
  } else {
    value
  }
}

///|
fn light_gizmo_varied_color(entity : @core.Entity) -> @sprite.Color {
  let seed = float_from_int(entity.id) +
    float_from_int(entity.generation) * 97.0F
  let r = 0.2F + 0.8F * ((@math.sin(seed * 0.73F) + 1.0F) * 0.5F)
  let g = 0.2F + 0.8F * ((@math.sin(seed * 1.11F + 1.2F) + 1.0F) * 0.5F)
  let b = 0.2F + 0.8F * ((@math.sin(seed * 1.61F + 2.4F) + 1.0F) * 0.5F)
  @sprite.Color::new(r, g, b, 1.0F)
}

///|
fn light_gizmo_resolve_color(
  entity : @core.Entity,
  override_color : LightGizmoColor?,
  config_group : LightGizmoConfigGroup,
  light_color : @sprite.Color,
  type_color : @sprite.Color,
) -> @sprite.Color {
  match override_color.unwrap_or(config_group.color) {
    Manual(color) => color
    Varied => light_gizmo_varied_color(entity)
    MatchLightColor => light_color
    ByLightType => type_color
  }
}

///|
fn[Config] draw_circle_3d(
  gizmos : @sprite.Gizmos[Config],
  center : @math.Vec3,
  axis_x : @math.Vec3,
  axis_y : @math.Vec3,
  radius : Float,
  color : @sprite.Color,
  resolution : Int,
) -> Unit {
  if radius <= 0.0F {
    return
  }
  let steps = max_int(resolution, 3)
  let points : Array[@math.Vec3] = []
  let denom = float_from_int(steps)
  for i in 0..<=steps {
    let angle = TAU * float_from_int(i) / denom
    let point = center
      .add(axis_x.mul_scalar(radius * @math.cos(angle)))
      .add(axis_y.mul_scalar(radius * @math.sin(angle)))
    points.push(point)
  }
  gizmos.linestrip_3d(points, color)
}

///|
fn[Config] draw_wire_sphere(
  gizmos : @sprite.Gizmos[Config],
  center : @math.Vec3,
  radius : Float,
  color : @sprite.Color,
  resolution : Int,
) -> Unit {
  let x = @math.Vec3::new(1.0F, 0.0F, 0.0F)
  let y = @math.Vec3::new(0.0F, 1.0F, 0.0F)
  let z = @math.Vec3::new(0.0F, 0.0F, 1.0F)
  draw_circle_3d(gizmos, center, x, y, radius, color, resolution)
  draw_circle_3d(gizmos, center, x, z, radius, color, resolution)
  draw_circle_3d(gizmos, center, y, z, radius, color, resolution)
}

///|
fn[Config] draw_spot_cone(
  gizmos : @sprite.Gizmos[Config],
  transform : @transform.Transform,
  range : Float,
  angle : Float,
  color : @sprite.Color,
  resolution : Int,
) -> Unit {
  if range <= 0.0F || angle <= 0.0F {
    return
  }
  let forward = transform.forward()
  let right = transform.right()
  let up = transform.up()
  let height = range * @math.cos(angle)
  let base_radius = range * @math.sin(angle)
  let origin = transform.translation
  let base_center = origin.add(forward.mul_scalar(height))
  draw_circle_3d(gizmos, base_center, right, up, base_radius, color, resolution)
  gizmos.line_3d(origin, base_center.add(right.mul_scalar(base_radius)), color)
  gizmos.line_3d(origin, base_center.sub(right.mul_scalar(base_radius)), color)
  gizmos.line_3d(origin, base_center.add(up.mul_scalar(base_radius)), color)
  gizmos.line_3d(origin, base_center.sub(up.mul_scalar(base_radius)), color)
}

///|
fn draw_point_light_gizmo(
  gizmos : @sprite.Gizmos[LightGizmoConfigGroup],
  transform : @transform.Transform,
  point_light : PointLight,
  color : @sprite.Color,
) -> Unit {
  draw_wire_sphere(
    gizmos,
    transform.translation,
    point_light.radius,
    color,
    DEFAULT_LIGHT_GIZMO_RADIUS_RESOLUTION,
  )
  draw_wire_sphere(
    gizmos,
    transform.translation,
    point_light.range,
    color,
    DEFAULT_LIGHT_GIZMO_RESOLUTION,
  )
}

///|
fn draw_spot_light_gizmo(
  gizmos : @sprite.Gizmos[LightGizmoConfigGroup],
  transform : @transform.Transform,
  spot_light : SpotLight,
  color : @sprite.Color,
) -> Unit {
  draw_wire_sphere(
    gizmos,
    transform.translation,
    spot_light.radius,
    color,
    DEFAULT_LIGHT_GIZMO_RADIUS_RESOLUTION,
  )
  draw_spot_cone(
    gizmos,
    transform,
    spot_light.range,
    spot_light.inner_angle,
    color,
    DEFAULT_LIGHT_GIZMO_RADIUS_RESOLUTION,
  )
  draw_spot_cone(
    gizmos,
    transform,
    spot_light.range,
    spot_light.outer_angle,
    color,
    DEFAULT_LIGHT_GIZMO_RESOLUTION,
  )
}

///|
fn draw_directional_light_gizmo(
  gizmos : @sprite.Gizmos[LightGizmoConfigGroup],
  transform : @transform.Transform,
  color : @sprite.Color,
) -> Unit {
  gizmos.arrow_3d(
    transform.translation,
    transform.translation.add(transform.forward()),
    color,
  )
}

///|
pub fn draw_light_gizmos(
  point_query : @ecs.Query[
    (
      @core.Entity,
      @ecs.Comp[PointLight],
      @ecs.Comp[@transform.Transform],
      @ecs.Comp[ShowLightGizmo],
    ),
    @ecs.All,
  ],
  spot_query : @ecs.Query[
    (
      @core.Entity,
      @ecs.Comp[SpotLight],
      @ecs.Comp[@transform.Transform],
      @ecs.Comp[ShowLightGizmo],
    ),
    @ecs.All,
  ],
  directional_query : @ecs.Query[
    (
      @core.Entity,
      @ecs.Comp[DirectionalLight],
      @ecs.Comp[@transform.Transform],
      @ecs.Comp[ShowLightGizmo],
    ),
    @ecs.All,
  ],
  gizmos : @sprite.Gizmos[LightGizmoConfigGroup],
) -> Unit {
  let config_group = gizmos.config_group()
  point_query.for_each(fn(_entity, item) {
    let (entity, point_light_comp, transform_comp, show_light_gizmo_comp) = item
    let point_light = point_light_comp.value()
    let transform = transform_comp.value()
    let show_light_gizmo = show_light_gizmo_comp.value()
    let color = light_gizmo_resolve_color(
      entity,
      show_light_gizmo.color,
      config_group,
      point_light.color,
      config_group.point_light_color,
    )
    draw_point_light_gizmo(gizmos, transform, point_light, color)
  }) catch {
    _ => ()
  }
  spot_query.for_each(fn(_entity, item) {
    let (entity, spot_light_comp, transform_comp, show_light_gizmo_comp) = item
    let spot_light = spot_light_comp.value()
    let transform = transform_comp.value()
    let show_light_gizmo = show_light_gizmo_comp.value()
    let color = light_gizmo_resolve_color(
      entity,
      show_light_gizmo.color,
      config_group,
      spot_light.color,
      config_group.spot_light_color,
    )
    draw_spot_light_gizmo(gizmos, transform, spot_light, color)
  }) catch {
    _ => ()
  }
  directional_query.for_each(fn(_entity, item) {
    let (entity, directional_light_comp, transform_comp, show_light_gizmo_comp) = item
    let directional_light = directional_light_comp.value()
    let transform = transform_comp.value()
    let show_light_gizmo = show_light_gizmo_comp.value()
    let color = light_gizmo_resolve_color(
      entity,
      show_light_gizmo.color,
      config_group,
      directional_light.color,
      config_group.directional_light_color,
    )
    draw_directional_light_gizmo(gizmos, transform, color)
  }) catch {
    _ => ()
  }
}

///|
pub fn draw_all_light_gizmos(
  point_query : @ecs.Query[
    (@core.Entity, @ecs.Comp[PointLight], @ecs.Comp[@transform.Transform]),
    @ecs.Without[ShowLightGizmo],
  ],
  spot_query : @ecs.Query[
    (@core.Entity, @ecs.Comp[SpotLight], @ecs.Comp[@transform.Transform]),
    @ecs.Without[ShowLightGizmo],
  ],
  directional_query : @ecs.Query[
    (@core.Entity, @ecs.Comp[DirectionalLight], @ecs.Comp[@transform.Transform]),
    @ecs.Without[ShowLightGizmo],
  ],
  gizmos : @sprite.Gizmos[LightGizmoConfigGroup],
) -> Unit {
  let config_group = gizmos.config_group()
  if !config_group.draw_all {
    return
  }
  point_query.for_each(fn(_entity, item) {
    let (entity, point_light_comp, transform_comp) = item
    let point_light = point_light_comp.value()
    let transform = transform_comp.value()
    let color = light_gizmo_resolve_color(
      entity,
      None,
      config_group,
      point_light.color,
      config_group.point_light_color,
    )
    draw_point_light_gizmo(gizmos, transform, point_light, color)
  }) catch {
    _ => ()
  }
  spot_query.for_each(fn(_entity, item) {
    let (entity, spot_light_comp, transform_comp) = item
    let spot_light = spot_light_comp.value()
    let transform = transform_comp.value()
    let color = light_gizmo_resolve_color(
      entity,
      None,
      config_group,
      spot_light.color,
      config_group.spot_light_color,
    )
    draw_spot_light_gizmo(gizmos, transform, spot_light, color)
  }) catch {
    _ => ()
  }
  directional_query.for_each(fn(_entity, item) {
    let (entity, directional_light_comp, transform_comp) = item
    let directional_light = directional_light_comp.value()
    let transform = transform_comp.value()
    let color = light_gizmo_resolve_color(
      entity,
      None,
      config_group,
      directional_light.color,
      config_group.directional_light_color,
    )
    draw_directional_light_gizmo(gizmos, transform, color)
  }) catch {
    _ => ()
  }
}
