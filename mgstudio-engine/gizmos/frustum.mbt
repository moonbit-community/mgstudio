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
// Bevy source: `bevy/crates/bevy_gizmos/src/frustum.rs`.

///|
let ecs_key_show_frustum_gizmo : @ecs.ComponentKey[ShowFrustumGizmo] = @ecs.register_component(
  debug_name="mgstudio_gizmos::ShowFrustumGizmo",
)

///|
pub(all) struct FrustumGizmoConfigGroup {
  draw_all : Bool
  default_color : @sprite.Color?
}

///|
pub fn FrustumGizmoConfigGroup::default() -> FrustumGizmoConfigGroup {
  FrustumGizmoConfigGroup::{ draw_all: false, default_color: None }
}

///|
pub impl Default for FrustumGizmoConfigGroup with default() {
  FrustumGizmoConfigGroup::default()
}

///|
pub impl @sprite.GizmoConfigGroup for FrustumGizmoConfigGroup with gizmo_config_group_marker(
  _self,
) {

}

///|
pub struct ShowFrustumGizmo {
  color : @sprite.Color?
}

///|
pub fn ShowFrustumGizmo::default() -> ShowFrustumGizmo {
  ShowFrustumGizmo::{ color: None }
}

///|
pub fn ShowFrustumGizmo::with_color(
  self : ShowFrustumGizmo,
  color : @sprite.Color?,
) -> ShowFrustumGizmo {
  ignore(self)
  ShowFrustumGizmo::{ color, }
}

///|
pub impl @ecs.Component for ShowFrustumGizmo with component() {
  ecs_key_show_frustum_gizmo
}

///|
fn frustum_gizmo_color_from_entity(entity : @core.Entity) -> @sprite.Color {
  let seed = Float::from_double(entity.id.to_double()) +
    Float::from_double(entity.generation.to_double()) * 131.0F
  let r = 0.2F + 0.8F * ((@math.sin(seed * 0.67F) + 1.0F) * 0.5F)
  let g = 0.2F + 0.8F * ((@math.sin(seed * 1.37F + 0.9F) + 1.0F) * 0.5F)
  let b = 0.2F + 0.8F * ((@math.sin(seed * 1.97F + 2.1F) + 1.0F) * 0.5F)
  @sprite.Color::new(r, g, b, 1.0F)
}

///|
fn frustum_gizmo_resolve_color(
  entity : @core.Entity,
  override_color : @sprite.Color?,
  config_group : FrustumGizmoConfigGroup,
) -> @sprite.Color {
  match override_color {
    Some(color) => color
    None =>
      match config_group.default_color {
        Some(color) => color
        None => frustum_gizmo_color_from_entity(entity)
      }
  }
}

///|
fn draw_frustum_outline(
  gizmos : @sprite.Gizmos[FrustumGizmoConfigGroup],
  frustum : @camera.Frustum,
  color : @sprite.Color,
) -> Unit {
  match frustum.corners() {
    Some(corners) if corners.length() == 8 => {
      let tln = corners[0]
      let trn = corners[1]
      let brn = corners[2]
      let bln = corners[3]
      let tlf = corners[4]
      let trf = corners[5]
      let brf = corners[6]
      let blf = corners[7]
      gizmos.linestrip_3d(
        [tln, trn, brn, bln, tln, tlf, trf, brf, blf, tlf],
        color,
      )
      gizmos.line_3d(trn, trf, color)
      gizmos.line_3d(brn, brf, color)
      gizmos.line_3d(bln, blf, color)
    }
    _ => ()
  }
}

///|
pub fn draw_frustum_gizmos(
  query : @ecs.Query[
    (@ecs.Comp[@camera.Frustum], @ecs.Comp[ShowFrustumGizmo]),
    @ecs.All,
  ],
  gizmos : @sprite.Gizmos[FrustumGizmoConfigGroup],
) -> Unit {
  let config_group = gizmos.config_group()
  query.for_each(fn(entity, data) {
    let (frustum_comp, show_frustum_comp) = data
    let show_frustum = show_frustum_comp.value()
    let color = frustum_gizmo_resolve_color(
      entity,
      show_frustum.color,
      config_group,
    )
    draw_frustum_outline(gizmos, frustum_comp.value(), color)
  }) catch {
    _ => ()
  }
}

///|
pub fn draw_all_frustum_gizmos(
  query : @ecs.Query[@ecs.Comp[@camera.Frustum], @ecs.Without[ShowFrustumGizmo]],
  gizmos : @sprite.Gizmos[FrustumGizmoConfigGroup],
) -> Unit {
  let config_group = gizmos.config_group()
  if !config_group.draw_all {
    return
  }
  query.for_each(fn(entity, data) {
    let frustum_comp = data
    let color = frustum_gizmo_resolve_color(entity, None, config_group)
    draw_frustum_outline(gizmos, frustum_comp.value(), color)
  }) catch {
    _ => ()
  }
}

///|
pub fn frustum_gizmo_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @sprite.init_gizmo_group(
    app
    .add_systems(
      @app.PostUpdate,
      @app.system(@app.system_param2(draw_frustum_gizmos)),
    )
    .add_systems(
      @app.PostUpdate,
      @app.system(@app.system_param2(draw_all_frustum_gizmos)),
    ),
    FrustumGizmoConfigGroup::default(),
  )
}
