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
/// Simple 2D physics debug rendering, aligned with Bevy+Rapier's debug render plugin.
///
/// This uses mgstudio's `render2d/gizmo` lines, and is disabled by default.

///|
pub struct Physics2dDebugRenderConfig {
  enabled : Bool
  colliders : Bool
  rigid_bodies : Bool
  impulse_joints : Bool
  collider_color : @render2d.Color
  sensor_color : @render2d.Color
  rigid_body_color : @render2d.Color
  joint_color : @render2d.Color
}

///|
pub fn Physics2dDebugRenderConfig::default() -> Physics2dDebugRenderConfig {
  {
    enabled: false,
    colliders: true,
    rigid_bodies: true,
    impulse_joints: true,
    collider_color: @render2d.Color::new(0.0F, 1.0F, 0.0F, 1.0F),
    sensor_color: @render2d.Color::new(0.0F, 1.0F, 1.0F, 1.0F),
    rigid_body_color: @render2d.Color::new(1.0F, 1.0F, 0.0F, 1.0F),
    joint_color: @render2d.Color::new(1.0F, 0.0F, 1.0F, 1.0F),
  }
}

///|
let physics2d_debug_render_state : Ref[Physics2dDebugRenderConfig] = Ref::new(
  Physics2dDebugRenderConfig::default(),
)

///|
pub fn physics2d_debug_render_config() -> Physics2dDebugRenderConfig {
  physics2d_debug_render_state.val
}

///|
pub fn physics2d_debug_render_set_config(
  config : Physics2dDebugRenderConfig,
) -> Unit {
  physics2d_debug_render_state.val = config
}

///|
pub fn physics2d_debug_render_set_enabled(enabled : Bool) -> Unit {
  let c = physics2d_debug_render_state.val
  physics2d_debug_render_state.val = Physics2dDebugRenderConfig::{
    ..c,
    enabled,
  }
}

///|
fn iso2_to_gizmo(iso : @rapier_core.Isometry2) -> @render2d.Isometry2d {
  @render2d.Isometry2d::new(
    rapier_vec2_to_mg(iso.translation),
    iso.rotation.angle(),
  )
}

///|
fn transform_point(
  iso : @rapier_core.Isometry2,
  p : @rapier_core.Vec2,
) -> @math.Vec2 {
  rapier_vec2_to_mg(iso.transform_point(p))
}

///|
fn draw_shape_2d(
  gizmos : @render2d.Gizmos,
  iso : @rapier_core.Isometry2,
  shape : @collision.Shape,
  color : @render2d.Color,
) -> Unit {
  match shape {
    Ball(r) => ignore(gizmos.circle_2d(iso2_to_gizmo(iso), r, color))
    Cuboid(hx, hy) =>
      gizmos.rect_2d(
        iso2_to_gizmo(iso),
        @math.Vec2::new(2.0F * hx, 2.0F * hy),
        color,
      )
    CapsuleX(half_height, radius) =>
      ignore(
        gizmos
        .rounded_rect_2d(
          iso2_to_gizmo(iso),
          @math.Vec2::new(2.0F * (half_height + radius), 2.0F * radius),
          color,
        )
        .corner_radius(radius),
      )
    CapsuleY(half_height, radius) =>
      ignore(
        gizmos
        .rounded_rect_2d(
          iso2_to_gizmo(iso),
          @math.Vec2::new(2.0F * radius, 2.0F * (half_height + radius)),
          color,
        )
        .corner_radius(radius),
      )
    Segment(a, b) =>
      gizmos.line_2d(transform_point(iso, a), transform_point(iso, b), color)
    Polyline(verts, edges) =>
      match edges {
        Some(es) =>
          for e in es {
            let (i, j) = e
            if i >= 0 && i < verts.length() && j >= 0 && j < verts.length() {
              gizmos.line_2d(
                transform_point(iso, verts[i]),
                transform_point(iso, verts[j]),
                color,
              )
            }
          }
        None => {
          let ps : Array[@math.Vec2] = []
          for v in verts {
            ps.push(transform_point(iso, v))
          }
          if ps.length() >= 2 {
            gizmos.linestrip_2d(ps, color)
          }
        }
      }
    ConvexPolygon(verts) => {
      let ps : Array[@math.Vec2] = []
      for v in verts {
        ps.push(transform_point(iso, v))
      }
      if ps.length() >= 3 {
        gizmos.lineloop_2d(ps, color)
      }
    }
    TriMesh(verts, tris) =>
      for tri in tris {
        let (i, j, k) = tri
        if i >= 0 &&
          j >= 0 &&
          k >= 0 &&
          i < verts.length() &&
          j < verts.length() &&
          k < verts.length() {
          let a = transform_point(iso, verts[i])
          let b = transform_point(iso, verts[j])
          let c = transform_point(iso, verts[k])
          gizmos.line_2d(a, b, color)
          gizmos.line_2d(b, c, color)
          gizmos.line_2d(c, a, color)
        }
      }
    Compound(parts) =>
      for part in parts {
        let (local_iso, sub) = part
        draw_shape_2d(gizmos, iso.mul(local_iso), sub, color)
      }
  }
}

///|
pub fn[W : HasRes_Physics2dContext] physics2d_debug_render_system(
  world : W,
) -> Unit {
  let config = physics2d_debug_render_state.val
  if !config.enabled {
    return
  }
  let ctx_res = HasRes_Physics2dContext::get_physics2d_context_resource(world)
  guard ctx_res.get_ref() is Some(ctx_ref) else { return }
  let ctx = ctx_ref.val
  let gizmos = @render2d.Gizmos::new()
  if config.colliders {
    for pair in ctx.colliders.iter_enabled() {
      let (_h, col) = pair
      let iso = col.position()
      let color = if col.is_sensor() {
        config.sensor_color
      } else {
        config.collider_color
      }
      draw_shape_2d(gizmos, iso, col.shape(), color)
    }
  }
  if config.rigid_bodies {
    for pair in ctx.rigid_bodies.iter() {
      let (_h, body) = pair
      ignore(
        gizmos.cross_2d(
          iso2_to_gizmo(body.position()),
          0.15F,
          config.rigid_body_color,
        ),
      )
    }
  }
  if config.impulse_joints {
    for pair in ctx.impulse_joints.iter() {
      let (_h, j) = pair
      let body1 = j.body1
      let body2 = j.body2
      guard ctx.rigid_bodies.get(body1) is Some(b1) else { continue }
      guard ctx.rigid_bodies.get(body2) is Some(b2) else { continue }
      let a1 = transform_point(b1.position(), j.data.local_anchor1())
      let a2 = transform_point(b2.position(), j.data.local_anchor2())
      gizmos.line_2d(a1, a2, config.joint_color)
    }
  }
}
