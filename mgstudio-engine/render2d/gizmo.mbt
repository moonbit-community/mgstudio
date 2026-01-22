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
pub struct Isometry2d {
  translation : @math.Vec2
  rotation : Float
}

///|
pub fn Isometry2d::identity() -> Isometry2d {
  Isometry2d::{ translation: @math.Vec2::new(0.0F, 0.0F), rotation: 0.0F }
}

///|
pub fn Isometry2d::new(
  translation : @math.Vec2,
  rotation : Float,
) -> Isometry2d {
  Isometry2d::{ translation, rotation }
}

///|
pub fn Isometry2d::transform_point(
  self : Isometry2d,
  point : @math.Vec2,
) -> @math.Vec2 {
  let cosv = @math.cos(self.rotation)
  let sinv = @math.sin(self.rotation)
  let rotated_x = point.x * cosv - point.y * sinv
  let rotated_y = point.x * sinv + point.y * cosv
  @math.Vec2::new(
    rotated_x + self.translation.x,
    rotated_y + self.translation.y,
  )
}

///|
pub(all) enum GizmoLineJoint {
  None
  Miter
  Round(Int)
  Bevel
}

///|
pub(all) enum GizmoLineStyle {
  Solid
  Dotted
  Dashed(gap_scale~ : Float, line_scale~ : Float)
}

///|
pub(all) struct GizmoLineConfig {
  width : Float
  perspective : Bool
  style : GizmoLineStyle
  joints : GizmoLineJoint
}

///|
const DEFAULT_GIZMO_LINE_WIDTH : Float = 2.0F

///|
pub fn GizmoLineConfig::default() -> GizmoLineConfig {
  GizmoLineConfig::{
    width: DEFAULT_GIZMO_LINE_WIDTH,
    perspective: false,
    style: GizmoLineStyle::Solid,
    joints: GizmoLineJoint::None,
  }
}

///|
pub(all) struct GizmoConfig {
  enabled : Bool
  line : GizmoLineConfig
  depth_bias : Float
  render_layers : RenderLayers
}

///|
pub fn GizmoConfig::default() -> GizmoConfig {
  GizmoConfig::{
    enabled: true,
    line: GizmoLineConfig::default(),
    depth_bias: 0.0F,
    render_layers: RenderLayers::default(),
  }
}

///|
pub struct Gizmos {
  layers : RenderLayers
}

///|
pub fn Gizmos::new() -> Gizmos {
  Gizmos::{ layers: gizmo_state.val.config.render_layers }
}

///|
pub fn Gizmos::with_layers(_self : Gizmos, layers : RenderLayers) -> Gizmos {
  Gizmos::{ layers, }
}

///|
pub impl @app.SystemParam for Gizmos with get() {
  Gizmos::new()
}

///|
pub fn gizmo_config() -> GizmoConfig {
  gizmo_state.val.config
}

///|
pub fn gizmo_set_config(config : GizmoConfig) -> Unit {
  gizmo_state.val.config = config
}

///|
const DEFAULT_CIRCLE_RESOLUTION : Int = 32

///|
const DEFAULT_ARC_RESOLUTION : Int = 8

///|
const DEFAULT_CORNER_RADIUS : Float = 0.1F

///|
const PI : Float = 3.141592653589793F

///|
const TAU : Float = 6.283185307179586F

///|
const HALF_PI : Float = 1.5707963267948966F

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
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
fn grid_line_count(include_outer : Bool, count : Int) -> Int {
  if include_outer {
    count + 1
  } else {
    max_int(count - 1, 1)
  }
}

///|
fn max_float(value : Float, min : Float) -> Float {
  if value < min {
    min
  } else {
    value
  }
}

///|
fn min_float(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn positive_or(value : Float, fallback : Float) -> Float {
  if value > 0.0F {
    value
  } else {
    fallback
  }
}

///|
fn render_layers_intersect(a : RenderLayers, b : RenderLayers) -> RenderLayers {
  RenderLayers::{ mask: a.mask & b.mask }
}

///|
fn gizmo_line_style_parts(style : GizmoLineStyle) -> (Int, Float, Float) {
  match style {
    Solid => (0, 1.0F, 1.0F)
    Dotted => (1, 1.0F, 1.0F)
    Dashed(gap_scale~, line_scale~) =>
      (2, positive_or(gap_scale, 1.0F), positive_or(line_scale, 1.0F))
  }
}

///|
fn gizmos_enabled() -> Bool {
  gizmo_state.val.config.enabled
}

///|
fn gizmo_effective_layers(layers : RenderLayers) -> RenderLayers {
  render_layers_intersect(layers, gizmo_state.val.config.render_layers)
}

///|
fn vec2_add(a : @math.Vec2, b : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(a.x + b.x, a.y + b.y)
}

///|
fn vec2_sub(a : @math.Vec2, b : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(a.x - b.x, a.y - b.y)
}

///|
fn vec2_scale(value : @math.Vec2, factor : Float) -> @math.Vec2 {
  @math.Vec2::new(value.x * factor, value.y * factor)
}

///|
fn vec2_length(value : @math.Vec2) -> Float {
  @math.pow(value.x * value.x + value.y * value.y, 0.5F)
}

///|
fn vec2_normalize_or_zero(value : @math.Vec2) -> @math.Vec2 {
  let length = vec2_length(value)
  if length <= 0.0F {
    @math.Vec2::new(0.0F, 0.0F)
  } else {
    vec2_scale(value, 1.0F / length)
  }
}

///|
fn vec2_distance(a : @math.Vec2, b : @math.Vec2) -> Float {
  vec2_length(vec2_sub(a, b))
}

///|
fn vec2_angle_to(a : @math.Vec2, b : @math.Vec2) -> Float {
  let cross = a.x * b.y - a.y * b.x
  let dot = a.x * b.x + a.y * b.y
  @math.atan2(cross, dot)
}

///|
fn tan(value : Float) -> Float {
  let cosv = @math.cos(value)
  if cosv == 0.0F {
    0.0F
  } else {
    @math.sin(value) / cosv
  }
}

///|
fn resolution_from_angle(angle : Float) -> Int {
  let ratio = abs_float(angle) / TAU
  let raw = ratio * float_from_int(DEFAULT_CIRCLE_RESOLUTION)
  let base = raw.to_int()
  let base_float = float_from_int(base)
  let mut result = if raw > base_float { base + 1 } else { base }
  result = max_int(result, 1)
  result
}

///|
fn arc_points(
  arc_angle : Float,
  radius : Float,
  resolution : Int,
) -> Array[@math.Vec2] {
  let steps = max_int(resolution, 1)
  let points : Array[@math.Vec2] = []
  let total = steps + 1
  let denom = float_from_int(steps)
  for i in 0..<total {
    let frac = float_from_int(i) / denom
    let angle = arc_angle * frac + HALF_PI
    let x = @math.cos(angle) * radius
    let y = @math.sin(angle) * radius
    points.push(@math.Vec2::new(x, y))
  }
  points
}

///|
fn ellipse_points(
  half_size : @math.Vec2,
  resolution : Int,
) -> Array[@math.Vec2] {
  let steps = max_int(resolution, 3)
  let points : Array[@math.Vec2] = []
  let total = steps + 1
  let denom = float_from_int(steps)
  for i in 0..<total {
    let angle = TAU * float_from_int(i) / denom
    let x = @math.sin(angle) * half_size.x
    let y = @math.cos(angle) * half_size.y
    points.push(@math.Vec2::new(x, y))
  }
  points
}

///|
priv struct GizmoLine {
  start : @math.Vec2
  end : @math.Vec2
  start_color : Color
  end_color : Color
  layers : RenderLayers
  width : Float
  style : GizmoLineStyle
}

///|
priv struct PendingEllipse {
  isometry : Isometry2d
  half_size : @math.Vec2
  color : Color
  mut resolution : Int
  layers : RenderLayers
}

///|
priv struct PendingArc {
  isometry : Isometry2d
  arc_angle : Float
  radius : Float
  color : Color
  mut resolution : Int
  mut has_resolution : Bool
  layers : RenderLayers
}

///|
priv struct PendingRoundedRect {
  isometry : Isometry2d
  size : @math.Vec2
  color : Color
  mut corner_radius : Float
  mut arc_resolution : Int
  layers : RenderLayers
}

///|
priv struct PendingArrow {
  start : @math.Vec2
  end : @math.Vec2
  color : Color
  mut tip_length : Float
  mut double_ended : Bool
  layers : RenderLayers
}

///|
priv struct PendingGrid {
  isometry : Isometry2d
  spacing : @math.Vec2
  cell_count : @math.IVec2
  mut skew : @math.Vec2
  mut outer_edges_x : Bool
  mut outer_edges_y : Bool
  color : Color
  layers : RenderLayers
}

///|
priv struct GizmoState {
  lines : Array[GizmoLine]
  pending_ellipses : Array[PendingEllipse]
  pending_arcs : Array[PendingArc]
  pending_rounded_rects : Array[PendingRoundedRect]
  pending_arrows : Array[PendingArrow]
  pending_grids : Array[PendingGrid]
  mut config : GizmoConfig
}

///|
let gizmo_state : Ref[GizmoState] = Ref::new(GizmoState::{
  lines: [],
  pending_ellipses: [],
  pending_arcs: [],
  pending_rounded_rects: [],
  pending_arrows: [],
  pending_grids: [],
  config: GizmoConfig::default(),
})

///|
fn gizmos_add_line(
  start : @math.Vec2,
  end : @math.Vec2,
  start_color : Color,
  end_color : Color,
  layers : RenderLayers,
) -> Unit {
  if !gizmos_enabled() {
    return
  }
  let config = gizmo_state.val.config
  let effective_layers = gizmo_effective_layers(layers)
  if effective_layers.mask == 0 {
    return
  }
  let line_config = config.line
  let width = positive_or(line_config.width, DEFAULT_GIZMO_LINE_WIDTH)
  gizmo_state.val.lines.push(GizmoLine::{
    start,
    end,
    start_color,
    end_color,
    layers: effective_layers,
    width,
    style: line_config.style,
  })
}

///|
fn gizmos_linestrip(
  positions : Array[@math.Vec2],
  color : Color,
  layers : RenderLayers,
) -> Unit {
  if !gizmos_enabled() {
    return
  }
  let count = positions.length()
  if count < 2 {
    return
  }
  for i in 0..<(count - 1) {
    gizmos_add_line(positions[i], positions[i + 1], color, color, layers)
  }
}

///|
fn gizmos_linestrip_gradient(
  positions : Array[(@math.Vec2, Color)],
  layers : RenderLayers,
) -> Unit {
  if !gizmos_enabled() {
    return
  }
  let count = positions.length()
  if count < 2 {
    return
  }
  for i in 0..<(count - 1) {
    let (start_pos, start_color) = positions[i]
    let (end_pos, end_color) = positions[i + 1]
    gizmos_add_line(start_pos, end_pos, start_color, end_color, layers)
  }
}

///|
fn gizmos_lineloop(
  positions : Array[@math.Vec2],
  color : Color,
  layers : RenderLayers,
) -> Unit {
  let count = positions.length()
  if count < 2 {
    return
  }
  gizmos_linestrip(positions, color, layers)
  gizmos_add_line(positions[count - 1], positions[0], color, color, layers)
}

///|
fn gizmos_arrow(
  start : @math.Vec2,
  end : @math.Vec2,
  color : Color,
  layers : RenderLayers,
  tip_length : Float,
  double_ended : Bool,
) -> Unit {
  gizmos_add_line(start, end, color, color, layers)
  let delta = vec2_sub(end, start)
  let length = vec2_length(delta)
  if length <= 0.0F {
    return
  }
  let direction = vec2_scale(delta, 1.0F / length)
  let tip_length = if tip_length <= 0.0F { length / 10.0F } else { tip_length }
  let tip_width = tip_length * 0.5F
  let base = vec2_sub(end, vec2_scale(direction, tip_length))
  let perp = @math.Vec2::new(-direction.y, direction.x)
  let tip_left = vec2_add(base, vec2_scale(perp, tip_width))
  let tip_right = vec2_sub(base, vec2_scale(perp, tip_width))
  gizmos_add_line(end, tip_left, color, color, layers)
  gizmos_add_line(end, tip_right, color, color, layers)
  if double_ended {
    let back_dir = vec2_scale(direction, -1.0F)
    let base_start = vec2_sub(start, vec2_scale(back_dir, tip_length))
    let perp_start = @math.Vec2::new(-back_dir.y, back_dir.x)
    let tip_left_start = vec2_add(base_start, vec2_scale(perp_start, tip_width))
    let tip_right_start = vec2_sub(
      base_start,
      vec2_scale(perp_start, tip_width),
    )
    gizmos_add_line(start, tip_left_start, color, color, layers)
    gizmos_add_line(start, tip_right_start, color, color, layers)
  }
}

///|
fn gizmos_draw_grid(
  isometry : Isometry2d,
  cell_count : @math.IVec2,
  spacing : @math.Vec2,
  skew : @math.Vec2,
  outer_edges_x : Bool,
  outer_edges_y : Bool,
  color : Color,
  layers : RenderLayers,
) -> Unit {
  let count_x = if cell_count.x < 0 { 0 } else { cell_count.x }
  let count_y = if cell_count.y < 0 { 0 } else { cell_count.y }
  if count_x == 0 || count_y == 0 {
    return
  }
  let skew_tan_x = tan(skew.x)
  let skew_tan_y = tan(skew.y)
  let dx = if count_x == 0 {
    @math.Vec2::new(0.0F, 0.0F)
  } else {
    @math.Vec2::new(spacing.x, spacing.x * skew_tan_y)
  }
  let dy = if count_y == 0 {
    @math.Vec2::new(0.0F, 0.0F)
  } else {
    @math.Vec2::new(spacing.y * skew_tan_x, spacing.y)
  }
  let half_x = float_from_int(count_x) * 0.5F
  let half_y = float_from_int(count_y) * 0.5F
  let grid_start = vec2_add(vec2_scale(dx, -half_x), vec2_scale(dy, -half_y))
  let x_line_count = grid_line_count(outer_edges_x, count_y)
  let y_line_count = grid_line_count(outer_edges_y, count_x)
  let x_start = if outer_edges_x {
    grid_start
  } else {
    vec2_add(grid_start, dy)
  }
  let y_start = if outer_edges_y {
    grid_start
  } else {
    vec2_add(grid_start, dx)
  }
  for i in 0..<x_line_count {
    let start = vec2_add(x_start, vec2_scale(dy, float_from_int(i)))
    let end = vec2_add(start, vec2_scale(dx, float_from_int(count_x)))
    let world_start = isometry.transform_point(start)
    let world_end = isometry.transform_point(end)
    gizmos_add_line(world_start, world_end, color, color, layers)
  }
  for i in 0..<y_line_count {
    let start = vec2_add(y_start, vec2_scale(dx, float_from_int(i)))
    let end = vec2_add(start, vec2_scale(dy, float_from_int(count_y)))
    let world_start = isometry.transform_point(start)
    let world_end = isometry.transform_point(end)
    gizmos_add_line(world_start, world_end, color, color, layers)
  }
}

///|
fn gizmos_prepare() -> Unit {
  if !gizmos_enabled() {
    gizmos_clear()
    return
  }
  if gizmo_state.val.pending_ellipses.length() > 0 {
    let entries : Array[PendingEllipse] = []
    for item in gizmo_state.val.pending_ellipses {
      entries.push(item)
    }
    gizmo_state.val.pending_ellipses.clear()
    for entry in entries {
      let points = ellipse_points(entry.half_size, entry.resolution)
      let transformed : Array[@math.Vec2] = []
      for point in points {
        transformed.push(entry.isometry.transform_point(point))
      }
      gizmos_linestrip(transformed, entry.color, entry.layers)
    }
  }
  if gizmo_state.val.pending_arcs.length() > 0 {
    let entries : Array[PendingArc] = []
    for item in gizmo_state.val.pending_arcs {
      entries.push(item)
    }
    gizmo_state.val.pending_arcs.clear()
    for entry in entries {
      let resolution = if entry.has_resolution {
        entry.resolution
      } else {
        resolution_from_angle(entry.arc_angle)
      }
      let points = arc_points(entry.arc_angle, entry.radius, resolution)
      let transformed : Array[@math.Vec2] = []
      for point in points {
        transformed.push(entry.isometry.transform_point(point))
      }
      gizmos_linestrip(transformed, entry.color, entry.layers)
    }
  }
  if gizmo_state.val.pending_rounded_rects.length() > 0 {
    let entries : Array[PendingRoundedRect] = []
    for item in gizmo_state.val.pending_rounded_rects {
      entries.push(item)
    }
    gizmo_state.val.pending_rounded_rects.clear()
    for entry in entries {
      let half_size = @math.Vec2::new(entry.size.x / 2.0F, entry.size.y / 2.0F)
      let max_radius = min_float(abs_float(half_size.x), abs_float(half_size.y))
      let radius = max_float(min_float(entry.corner_radius, max_radius), 0.0F)
      if radius <= 0.0F {
        let rect_points = [
          @math.Vec2::new(-half_size.x, half_size.y),
          @math.Vec2::new(half_size.x, half_size.y),
          @math.Vec2::new(half_size.x, -half_size.y),
          @math.Vec2::new(-half_size.x, -half_size.y),
        ]
        let transformed : Array[@math.Vec2] = []
        for point in rect_points {
          transformed.push(entry.isometry.transform_point(point))
        }
        gizmos_lineloop(transformed, entry.color, entry.layers)
      } else {
        let steps = max_int(entry.arc_resolution, 1)
        let points : Array[@math.Vec2] = []
        let tr_center = @math.Vec2::new(
          half_size.x - radius,
          half_size.y - radius,
        )
        let br_center = @math.Vec2::new(
          half_size.x - radius,
          -half_size.y + radius,
        )
        let bl_center = @math.Vec2::new(
          -half_size.x + radius,
          -half_size.y + radius,
        )
        let tl_center = @math.Vec2::new(
          -half_size.x + radius,
          half_size.y - radius,
        )
        let arc_defs = [
          (tr_center, HALF_PI, 0.0F),
          (br_center, 0.0F, -HALF_PI),
          (bl_center, -HALF_PI, -PI),
          (tl_center, -PI, -HALF_PI * 3.0F),
        ]
        for arc_index in 0..<arc_defs.length() {
          let (center, start_angle, end_angle) = arc_defs[arc_index]
          let total = steps + 1
          let denom = float_from_int(steps)
          for i in 0..<total {
            if arc_index > 0 && i == 0 {
              continue
            }
            let t = float_from_int(i) / denom
            let angle = start_angle + (end_angle - start_angle) * t
            let x = @math.cos(angle) * radius + center.x
            let y = @math.sin(angle) * radius + center.y
            points.push(@math.Vec2::new(x, y))
          }
        }
        let transformed : Array[@math.Vec2] = []
        for point in points {
          transformed.push(entry.isometry.transform_point(point))
        }
        gizmos_lineloop(transformed, entry.color, entry.layers)
      }
    }
  }
  if gizmo_state.val.pending_arrows.length() > 0 {
    let entries : Array[PendingArrow] = []
    for item in gizmo_state.val.pending_arrows {
      entries.push(item)
    }
    gizmo_state.val.pending_arrows.clear()
    for entry in entries {
      gizmos_arrow(
        entry.start,
        entry.end,
        entry.color,
        entry.layers,
        entry.tip_length,
        entry.double_ended,
      )
    }
  }
  if gizmo_state.val.pending_grids.length() > 0 {
    let entries : Array[PendingGrid] = []
    for item in gizmo_state.val.pending_grids {
      entries.push(item)
    }
    gizmo_state.val.pending_grids.clear()
    for entry in entries {
      gizmos_draw_grid(
        entry.isometry,
        entry.cell_count,
        entry.spacing,
        entry.skew,
        entry.outer_edges_x,
        entry.outer_edges_y,
        entry.color,
        entry.layers,
      )
    }
  }
}

///|
fn gizmos_clear() -> Unit {
  gizmo_state.val.lines.clear()
  gizmo_state.val.pending_ellipses.clear()
  gizmo_state.val.pending_arcs.clear()
  gizmo_state.val.pending_rounded_rects.clear()
  gizmo_state.val.pending_arrows.clear()
  gizmo_state.val.pending_grids.clear()
}

///|
fn gizmos_reset() -> Unit {
  gizmos_clear()
  gizmo_state.val.config = GizmoConfig::default()
}

///|
fn gizmos_draw_lines(layers : RenderLayers) -> Unit {
  if !gizmos_enabled() {
    return
  }
  if !gizmo_state.val.config.render_layers.matches(layers) {
    return
  }
  for line in gizmo_state.val.lines {
    if line.layers.matches(layers) {
      let (style_kind, gap_scale, line_scale) = gizmo_line_style_parts(
        line.style,
      )
      @window.host_gpu_draw_gizmo_line(
        line.start.x,
        line.start.y,
        line.start_color.r,
        line.start_color.g,
        line.start_color.b,
        line.start_color.a,
        line.end.x,
        line.end.y,
        line.end_color.r,
        line.end_color.g,
        line.end_color.b,
        line.end_color.a,
        line.width,
        style_kind,
        gap_scale,
        line_scale,
      )
    }
  }
}

///|
pub fn Gizmos::line_2d(
  self : Gizmos,
  start : @math.Vec2,
  end : @math.Vec2,
  color : Color,
) -> Unit {
  gizmos_add_line(start, end, color, color, self.layers)
}

///|
pub fn Gizmos::line_gradient_2d(
  self : Gizmos,
  start : @math.Vec2,
  end : @math.Vec2,
  start_color : Color,
  end_color : Color,
) -> Unit {
  gizmos_add_line(start, end, start_color, end_color, self.layers)
}

///|
pub fn Gizmos::linestrip_2d(
  self : Gizmos,
  positions : Array[@math.Vec2],
  color : Color,
) -> Unit {
  gizmos_linestrip(positions, color, self.layers)
}

///|
pub fn Gizmos::lineloop_2d(
  self : Gizmos,
  positions : Array[@math.Vec2],
  color : Color,
) -> Unit {
  gizmos_lineloop(positions, color, self.layers)
}

///|
pub fn Gizmos::linestrip_gradient_2d(
  self : Gizmos,
  positions : Array[(@math.Vec2, Color)],
) -> Unit {
  gizmos_linestrip_gradient(positions, self.layers)
}

///|
pub fn Gizmos::ray_2d(
  self : Gizmos,
  start : @math.Vec2,
  vector : @math.Vec2,
  color : Color,
) -> Unit {
  let end = vec2_add(start, vector)
  gizmos_add_line(start, end, color, color, self.layers)
}

///|
pub fn Gizmos::ray_gradient_2d(
  self : Gizmos,
  start : @math.Vec2,
  vector : @math.Vec2,
  start_color : Color,
  end_color : Color,
) -> Unit {
  let end = vec2_add(start, vector)
  gizmos_add_line(start, end, start_color, end_color, self.layers)
}

///|
pub fn Gizmos::rect_2d(
  self : Gizmos,
  isometry : Isometry2d,
  size : @math.Vec2,
  color : Color,
) -> Unit {
  let half = @math.Vec2::new(size.x / 2.0F, size.y / 2.0F)
  let tl = isometry.transform_point(@math.Vec2::new(-half.x, half.y))
  let tr = isometry.transform_point(@math.Vec2::new(half.x, half.y))
  let br = isometry.transform_point(@math.Vec2::new(half.x, -half.y))
  let bl = isometry.transform_point(@math.Vec2::new(-half.x, -half.y))
  gizmos_lineloop([tl, tr, br, bl], color, self.layers)
}

///|
pub struct RoundedRectBuilder {
  id : Int
}

///|
pub fn RoundedRectBuilder::corner_radius(
  self : RoundedRectBuilder,
  radius : Float,
) -> RoundedRectBuilder {
  if self.id >= 0 && self.id < gizmo_state.val.pending_rounded_rects.length() {
    gizmo_state.val.pending_rounded_rects[self.id].corner_radius = radius
  }
  self
}

///|
pub fn RoundedRectBuilder::arc_resolution(
  self : RoundedRectBuilder,
  resolution : Int,
) -> RoundedRectBuilder {
  if self.id >= 0 && self.id < gizmo_state.val.pending_rounded_rects.length() {
    gizmo_state.val.pending_rounded_rects[self.id].arc_resolution = max_int(
      resolution, 1,
    )
  }
  self
}

///|
pub fn Gizmos::rounded_rect_2d(
  self : Gizmos,
  isometry : Isometry2d,
  size : @math.Vec2,
  color : Color,
) -> RoundedRectBuilder {
  let radius = min_float(abs_float(size.x), abs_float(size.y)) *
    DEFAULT_CORNER_RADIUS
  let entry = PendingRoundedRect::{
    isometry,
    size,
    color,
    corner_radius: radius,
    arc_resolution: DEFAULT_ARC_RESOLUTION,
    layers: self.layers,
  }
  let id = gizmo_state.val.pending_rounded_rects.length()
  gizmo_state.val.pending_rounded_rects.push(entry)
  RoundedRectBuilder::{ id, }
}

///|
pub struct Ellipse2dBuilder {
  id : Int
}

///|
pub fn Ellipse2dBuilder::resolution(
  self : Ellipse2dBuilder,
  segments : Int,
) -> Ellipse2dBuilder {
  if self.id >= 0 && self.id < gizmo_state.val.pending_ellipses.length() {
    gizmo_state.val.pending_ellipses[self.id].resolution = max_int(segments, 3)
  }
  self
}

///|
pub fn Gizmos::circle_2d(
  self : Gizmos,
  isometry : Isometry2d,
  radius : Float,
  color : Color,
) -> Ellipse2dBuilder {
  let entry = PendingEllipse::{
    isometry,
    half_size: @math.Vec2::new(radius, radius),
    color,
    resolution: DEFAULT_CIRCLE_RESOLUTION,
    layers: self.layers,
  }
  let id = gizmo_state.val.pending_ellipses.length()
  gizmo_state.val.pending_ellipses.push(entry)
  Ellipse2dBuilder::{ id, }
}

///|
pub fn Gizmos::ellipse_2d(
  self : Gizmos,
  isometry : Isometry2d,
  half_size : @math.Vec2,
  color : Color,
) -> Ellipse2dBuilder {
  let entry = PendingEllipse::{
    isometry,
    half_size,
    color,
    resolution: DEFAULT_CIRCLE_RESOLUTION,
    layers: self.layers,
  }
  let id = gizmo_state.val.pending_ellipses.length()
  gizmo_state.val.pending_ellipses.push(entry)
  Ellipse2dBuilder::{ id, }
}

///|
pub struct Arc2dBuilder {
  id : Int
}

///|
pub fn Arc2dBuilder::resolution(
  self : Arc2dBuilder,
  segments : Int,
) -> Arc2dBuilder {
  if self.id >= 0 && self.id < gizmo_state.val.pending_arcs.length() {
    gizmo_state.val.pending_arcs[self.id].resolution = max_int(segments, 1)
    gizmo_state.val.pending_arcs[self.id].has_resolution = true
  }
  self
}

///|
pub fn Gizmos::arc_2d(
  self : Gizmos,
  isometry : Isometry2d,
  arc_angle : Float,
  radius : Float,
  color : Color,
) -> Arc2dBuilder {
  let entry = PendingArc::{
    isometry,
    arc_angle,
    radius,
    color,
    resolution: DEFAULT_CIRCLE_RESOLUTION,
    has_resolution: false,
    layers: self.layers,
  }
  let id = gizmo_state.val.pending_arcs.length()
  gizmo_state.val.pending_arcs.push(entry)
  Arc2dBuilder::{ id, }
}

///|
pub fn Gizmos::short_arc_2d_between(
  self : Gizmos,
  center : @math.Vec2,
  start : @math.Vec2,
  end : @math.Vec2,
  color : Color,
) -> Arc2dBuilder {
  let from_axis = vec2_normalize_or_zero(vec2_sub(start, center))
  let to_axis = vec2_normalize_or_zero(vec2_sub(end, center))
  let rotation = vec2_angle_to(@math.Vec2::new(0.0F, 1.0F), from_axis)
  let arc_angle = vec2_angle_to(from_axis, to_axis)
  let radius = vec2_distance(center, start)
  let isometry = Isometry2d::new(center, rotation)
  self.arc_2d(isometry, arc_angle, radius, color)
}

///|
pub fn Gizmos::long_arc_2d_between(
  self : Gizmos,
  center : @math.Vec2,
  start : @math.Vec2,
  end : @math.Vec2,
  color : Color,
) -> Arc2dBuilder {
  let from_axis = vec2_normalize_or_zero(vec2_sub(start, center))
  let to_axis = vec2_normalize_or_zero(vec2_sub(end, center))
  let rotation = vec2_angle_to(@math.Vec2::new(0.0F, 1.0F), from_axis)
  let raw_angle = vec2_angle_to(from_axis, to_axis)
  let arc_angle = raw_angle - TAU
  let radius = vec2_distance(center, start)
  let isometry = Isometry2d::new(center, rotation)
  self.arc_2d(isometry, arc_angle, radius, color)
}

///|
pub struct ArrowBuilder {
  id : Int
}

///|
pub fn ArrowBuilder::with_tip_length(
  self : ArrowBuilder,
  length : Float,
) -> ArrowBuilder {
  if self.id >= 0 && self.id < gizmo_state.val.pending_arrows.length() {
    gizmo_state.val.pending_arrows[self.id].tip_length = length
  }
  self
}

///|
pub fn ArrowBuilder::with_double_end(self : ArrowBuilder) -> ArrowBuilder {
  if self.id >= 0 && self.id < gizmo_state.val.pending_arrows.length() {
    gizmo_state.val.pending_arrows[self.id].double_ended = true
  }
  self
}

///|
pub fn Gizmos::arrow_2d(
  self : Gizmos,
  start : @math.Vec2,
  end : @math.Vec2,
  color : Color,
) -> ArrowBuilder {
  let length = vec2_length(vec2_sub(end, start))
  let tip_length = if length <= 0.0F { 0.0F } else { length / 10.0F }
  let entry = PendingArrow::{
    start,
    end,
    color,
    tip_length,
    double_ended: false,
    layers: self.layers,
  }
  let id = gizmo_state.val.pending_arrows.length()
  gizmo_state.val.pending_arrows.push(entry)
  ArrowBuilder::{ id, }
}

///|
pub fn Gizmos::axes_2d(
  self : Gizmos,
  isometry : Isometry2d,
  length : Float,
) -> Unit {
  let origin = isometry.translation
  let x_end = isometry.transform_point(@math.Vec2::new(length, 0.0F))
  let y_end = isometry.transform_point(@math.Vec2::new(0.0F, length))
  let red = Color::new(1.0F, 0.0F, 0.0F, 1.0F)
  let green = Color::new(0.0F, 1.0F, 0.0F, 1.0F)
  self.arrow_2d(origin, x_end, red) |> ignore
  self.arrow_2d(origin, y_end, green) |> ignore
}

///|
pub fn Gizmos::cross_2d(
  self : Gizmos,
  isometry : Isometry2d,
  half_size : Float,
  color : Color,
) -> Unit {
  let axis_x = @math.Vec2::new(half_size, 0.0F)
  let axis_y = @math.Vec2::new(0.0F, half_size)
  let start_x = isometry.transform_point(axis_x)
  let end_x = isometry.transform_point(vec2_scale(axis_x, -1.0F))
  let start_y = isometry.transform_point(axis_y)
  let end_y = isometry.transform_point(vec2_scale(axis_y, -1.0F))
  gizmos_add_line(start_x, end_x, color, color, self.layers)
  gizmos_add_line(start_y, end_y, color, color, self.layers)
}

///|
pub struct Grid2dBuilder {
  id : Int
}

///|
pub fn Grid2dBuilder::skew_x(
  self : Grid2dBuilder,
  skew : Float,
) -> Grid2dBuilder {
  if self.id >= 0 && self.id < gizmo_state.val.pending_grids.length() {
    let current = gizmo_state.val.pending_grids[self.id].skew
    gizmo_state.val.pending_grids[self.id].skew = @math.Vec2::new(
      skew,
      current.y,
    )
  }
  self
}

///|
pub fn Grid2dBuilder::skew_y(
  self : Grid2dBuilder,
  skew : Float,
) -> Grid2dBuilder {
  if self.id >= 0 && self.id < gizmo_state.val.pending_grids.length() {
    let current = gizmo_state.val.pending_grids[self.id].skew
    gizmo_state.val.pending_grids[self.id].skew = @math.Vec2::new(
      current.x,
      skew,
    )
  }
  self
}

///|
pub fn Grid2dBuilder::skew(
  self : Grid2dBuilder,
  skew : @math.Vec2,
) -> Grid2dBuilder {
  if self.id >= 0 && self.id < gizmo_state.val.pending_grids.length() {
    gizmo_state.val.pending_grids[self.id].skew = skew
  }
  self
}

///|
pub fn Grid2dBuilder::outer_edges_x(self : Grid2dBuilder) -> Grid2dBuilder {
  if self.id >= 0 && self.id < gizmo_state.val.pending_grids.length() {
    gizmo_state.val.pending_grids[self.id].outer_edges_x = true
  }
  self
}

///|
pub fn Grid2dBuilder::outer_edges_y(self : Grid2dBuilder) -> Grid2dBuilder {
  if self.id >= 0 && self.id < gizmo_state.val.pending_grids.length() {
    gizmo_state.val.pending_grids[self.id].outer_edges_y = true
  }
  self
}

///|
pub fn Grid2dBuilder::outer_edges(self : Grid2dBuilder) -> Grid2dBuilder {
  if self.id >= 0 && self.id < gizmo_state.val.pending_grids.length() {
    gizmo_state.val.pending_grids[self.id].outer_edges_x = true
    gizmo_state.val.pending_grids[self.id].outer_edges_y = true
  }
  self
}

///|
pub fn Gizmos::grid_2d(
  self : Gizmos,
  isometry : Isometry2d,
  cell_count : @math.IVec2,
  spacing : @math.Vec2,
  color : Color,
) -> Grid2dBuilder {
  let entry = PendingGrid::{
    isometry,
    spacing,
    cell_count,
    skew: @math.Vec2::new(0.0F, 0.0F),
    outer_edges_x: false,
    outer_edges_y: false,
    color,
    layers: self.layers,
  }
  let id = gizmo_state.val.pending_grids.length()
  gizmo_state.val.pending_grids.push(entry)
  Grid2dBuilder::{ id, }
}

///|
pub fn Gizmos::curve_2d(
  self : Gizmos,
  points : Array[@math.Vec2],
  color : Color,
) -> Unit {
  gizmos_linestrip(points, color, self.layers)
}

///|
pub fn Gizmos::curve_gradient_2d(
  self : Gizmos,
  points : Array[(@math.Vec2, Color)],
) -> Unit {
  gizmos_linestrip_gradient(points, self.layers)
}
