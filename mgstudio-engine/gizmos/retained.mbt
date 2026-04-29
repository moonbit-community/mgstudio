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
// Bevy source: `bevy/crates/bevy_gizmos/src/lib.rs` and
// `bevy/crates/bevy_gizmos/src/retained.rs`.

///|
pub struct GizmoBuffer {
  enabled : Bool
  list_positions : Array[@math.Vec3]
  list_colors : Array[@color.LinearRgba]
  strip_positions : Array[@math.Vec3]
  strip_colors : Array[@color.LinearRgba]
}

///|
pub fn GizmoBuffer::new() -> GizmoBuffer {
  GizmoBuffer::{
    enabled: true,
    list_positions: [],
    list_colors: [],
    strip_positions: [],
    strip_colors: [],
  }
}

///|
pub impl Default for GizmoBuffer with default() {
  GizmoBuffer::new()
}

///|
pub struct GizmoBufferView {
  list_positions : Array[@math.Vec3]
  list_colors : Array[@color.LinearRgba]
  strip_positions : Array[@math.Vec3]
  strip_colors : Array[@color.LinearRgba]
}

///|
pub fn GizmoBuffer::clear(self : GizmoBuffer) -> Unit {
  self.list_positions.clear()
  self.list_colors.clear()
  self.strip_positions.clear()
  self.strip_colors.clear()
}

///|
pub fn GizmoBuffer::buffer(self : GizmoBuffer) -> GizmoBufferView {
  GizmoBufferView::{
    list_positions: self.list_positions,
    list_colors: self.list_colors,
    strip_positions: self.strip_positions,
    strip_colors: self.strip_colors,
  }
}

///|
fn GizmoBuffer::add_list_color(
  self : GizmoBuffer,
  color : @color.Color,
  count : Int,
) -> Unit {
  let linear = color.as_linear_rgba()
  for _ in 0..<count {
    self.list_colors.push(linear)
  }
}

///|
fn GizmoBuffer::add_strip_color(
  self : GizmoBuffer,
  color : @color.Color,
  count : Int,
) -> Unit {
  let linear = color.as_linear_rgba()
  for _ in 0..<count {
    self.strip_colors.push(linear)
  }
}

///|
pub fn GizmoBuffer::line(
  self : GizmoBuffer,
  start : @math.Vec3,
  end : @math.Vec3,
  color : @color.Color,
) -> Unit {
  if !self.enabled {
    return
  }
  self.list_positions.push(start)
  self.list_positions.push(end)
  self.add_list_color(color, 2)
}

///|
pub fn GizmoBuffer::line_gradient(
  self : GizmoBuffer,
  start : @math.Vec3,
  end : @math.Vec3,
  start_color : @color.Color,
  end_color : @color.Color,
) -> Unit {
  if !self.enabled {
    return
  }
  self.list_positions.push(start)
  self.list_positions.push(end)
  self.list_colors.push(start_color.as_linear_rgba())
  self.list_colors.push(end_color.as_linear_rgba())
}

///|
pub fn GizmoBuffer::ray(
  self : GizmoBuffer,
  start : @math.Vec3,
  vector : @math.Vec3,
  color : @color.Color,
) -> Unit {
  self.line(start, start.add(vector), color)
}

///|
pub fn GizmoBuffer::ray_gradient(
  self : GizmoBuffer,
  start : @math.Vec3,
  vector : @math.Vec3,
  start_color : @color.Color,
  end_color : @color.Color,
) -> Unit {
  self.line_gradient(start, start.add(vector), start_color, end_color)
}

///|
fn gizmo_buffer_nan_vec3() -> @math.Vec3 {
  let nan = 0.0F / 0.0F
  @math.Vec3::new(nan, nan, nan)
}

///|
fn gizmo_buffer_nan_color() -> @color.LinearRgba {
  let nan = 0.0F / 0.0F
  @color.Color::new(nan, nan, nan, nan)
}

///|
fn gizmo_buffer_rect_inner(size : @math.Vec2) -> Array[@math.Vec2] {
  let half_size = size.div_scalar(2.0F)
  let tl = @math.Vec2::new(-half_size.x, half_size.y)
  let tr = @math.Vec2::new(half_size.x, half_size.y)
  let bl = @math.Vec2::new(-half_size.x, -half_size.y)
  let br = @math.Vec2::new(half_size.x, -half_size.y)
  [tl, tr, br, bl]
}

///|
fn gizmo_buffer_vec2_to_vec3(value : @math.Vec2) -> @math.Vec3 {
  @math.Vec3::new(value.x, value.y, 0.0F)
}

///|
fn gizmo_buffer_isometry2d_points(
  isometry : @sprite.Isometry2d,
  points : Array[@math.Vec2],
) -> Array[@math.Vec2] {
  let out : Array[@math.Vec2] = []
  for point in points {
    out.push(isometry.transform_point(point))
  }
  out
}

///|
fn gizmo_buffer_isometry3d_points_from_2d(
  isometry : @math.Isometry3d,
  points : Array[@math.Vec2],
) -> Array[@math.Vec3] {
  let out : Array[@math.Vec3] = []
  for point in points {
    out.push(isometry.transform_point3(gizmo_buffer_vec2_to_vec3(point)))
  }
  out
}

///|
fn gizmo_buffer_vec3_neg(value : @math.Vec3) -> @math.Vec3 {
  @math.Vec3::new(-value.x, -value.y, -value.z)
}

///|
fn gizmo_buffer_vec2_neg(value : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(-value.x, -value.y)
}

///|
pub fn GizmoBuffer::linestrip(
  self : GizmoBuffer,
  positions : Array[@math.Vec3],
  color : @color.Color,
) -> Unit {
  if !self.enabled || positions.length() == 0 {
    return
  }
  for position in positions {
    self.strip_positions.push(position)
  }
  self.add_strip_color(color, positions.length())
  self.strip_positions.push(gizmo_buffer_nan_vec3())
  self.strip_colors.push(gizmo_buffer_nan_color())
}

///|
pub fn GizmoBuffer::lineloop(
  self : GizmoBuffer,
  positions : Array[@math.Vec3],
  color : @color.Color,
) -> Unit {
  if !self.enabled || positions.length() == 0 {
    return
  }
  let strip : Array[@math.Vec3] = []
  let first = positions[0]
  strip.push(first)
  if positions.length() > 1 {
    let second = positions[1]
    strip.push(second)
    for i in 2..<positions.length() {
      strip.push(positions[i])
    }
    strip.push(first)
    strip.push(second)
  } else {
    strip.push(first)
  }
  self.linestrip(strip, color)
}

///|
pub fn GizmoBuffer::linestrip_gradient(
  self : GizmoBuffer,
  points : Array[(@math.Vec3, @color.Color)],
) -> Unit {
  if !self.enabled || points.length() == 0 {
    return
  }
  for point in points {
    let (position, color) = point
    self.strip_positions.push(position)
    self.strip_colors.push(color.as_linear_rgba())
  }
  self.strip_positions.push(gizmo_buffer_nan_vec3())
  self.strip_colors.push(gizmo_buffer_nan_color())
}

///|
pub fn GizmoBuffer::line_2d(
  self : GizmoBuffer,
  start : @math.Vec2,
  end : @math.Vec2,
  color : @color.Color,
) -> Unit {
  self.line(
    @math.Vec3::new(start.x, start.y, 0.0F),
    @math.Vec3::new(end.x, end.y, 0.0F),
    color,
  )
}

///|
pub fn GizmoBuffer::line_gradient_2d(
  self : GizmoBuffer,
  start : @math.Vec2,
  end : @math.Vec2,
  start_color : @color.Color,
  end_color : @color.Color,
) -> Unit {
  self.line_gradient(
    @math.Vec3::new(start.x, start.y, 0.0F),
    @math.Vec3::new(end.x, end.y, 0.0F),
    start_color,
    end_color,
  )
}

///|
pub fn GizmoBuffer::linestrip_2d(
  self : GizmoBuffer,
  positions : Array[@math.Vec2],
  color : @color.Color,
) -> Unit {
  let converted : Array[@math.Vec3] = []
  for position in positions {
    converted.push(@math.Vec3::new(position.x, position.y, 0.0F))
  }
  self.linestrip(converted, color)
}

///|
pub fn GizmoBuffer::lineloop_2d(
  self : GizmoBuffer,
  positions : Array[@math.Vec2],
  color : @color.Color,
) -> Unit {
  let converted : Array[@math.Vec3] = []
  for position in positions {
    converted.push(@math.Vec3::new(position.x, position.y, 0.0F))
  }
  self.lineloop(converted, color)
}

///|
pub fn GizmoBuffer::linestrip_gradient_2d(
  self : GizmoBuffer,
  points : Array[(@math.Vec2, @color.Color)],
) -> Unit {
  let converted : Array[(@math.Vec3, @color.Color)] = []
  for point in points {
    let (position, color) = point
    converted.push((@math.Vec3::new(position.x, position.y, 0.0F), color))
  }
  self.linestrip_gradient(converted)
}

///|
pub fn GizmoBuffer::ray_2d(
  self : GizmoBuffer,
  start : @math.Vec2,
  vector : @math.Vec2,
  color : @color.Color,
) -> Unit {
  self.line_2d(start, start.add(vector), color)
}

///|
pub fn GizmoBuffer::ray_gradient_2d(
  self : GizmoBuffer,
  start : @math.Vec2,
  vector : @math.Vec2,
  start_color : @color.Color,
  end_color : @color.Color,
) -> Unit {
  self.line_gradient_2d(start, start.add(vector), start_color, end_color)
}

///|
pub fn GizmoBuffer::rect(
  self : GizmoBuffer,
  isometry : @math.Isometry3d,
  size : @math.Vec2,
  color : @color.Color,
) -> Unit {
  if !self.enabled {
    return
  }
  self.lineloop(
    gizmo_buffer_isometry3d_points_from_2d(
      isometry,
      gizmo_buffer_rect_inner(size),
    ),
    color,
  )
}

///|
pub fn GizmoBuffer::rect_2d(
  self : GizmoBuffer,
  isometry : @sprite.Isometry2d,
  size : @math.Vec2,
  color : @color.Color,
) -> Unit {
  if !self.enabled {
    return
  }
  self.lineloop_2d(
    gizmo_buffer_isometry2d_points(isometry, gizmo_buffer_rect_inner(size)),
    color,
  )
}

///|
pub fn GizmoBuffer::cube(
  self : GizmoBuffer,
  transform : @transform.Transform,
  color : @color.Color,
) -> Unit {
  if !self.enabled {
    return
  }
  let rect = gizmo_buffer_rect_inner(@math.Vec2::new(1.0F, 1.0F))
  let tlf = transform.transform_point(
    @math.Vec3::new(rect[0].x, rect[0].y, 0.5F),
  )
  let trf = transform.transform_point(
    @math.Vec3::new(rect[1].x, rect[1].y, 0.5F),
  )
  let brf = transform.transform_point(
    @math.Vec3::new(rect[2].x, rect[2].y, 0.5F),
  )
  let blf = transform.transform_point(
    @math.Vec3::new(rect[3].x, rect[3].y, 0.5F),
  )
  let tlb = transform.transform_point(
    @math.Vec3::new(rect[0].x, rect[0].y, -0.5F),
  )
  let trb = transform.transform_point(
    @math.Vec3::new(rect[1].x, rect[1].y, -0.5F),
  )
  let brb = transform.transform_point(
    @math.Vec3::new(rect[2].x, rect[2].y, -0.5F),
  )
  let blb = transform.transform_point(
    @math.Vec3::new(rect[3].x, rect[3].y, -0.5F),
  )
  self.linestrip([tlf, trf, brf, blf, tlf, tlb, trb, brb, blb, tlb], color)
  self.line(trf, trb, color)
  self.line(brf, brb, color)
  self.line(blf, blb, color)
}

///|
pub fn GizmoBuffer::cross(
  self : GizmoBuffer,
  isometry : @math.Isometry3d,
  half_size : Float,
  color : @color.Color,
) -> Unit {
  let axes = [
    @math.Vec3::new(half_size, 0.0F, 0.0F),
    @math.Vec3::new(0.0F, half_size, 0.0F),
    @math.Vec3::new(0.0F, 0.0F, half_size),
  ]
  for axis in axes {
    self.line(
      isometry.transform_point3(axis),
      isometry.transform_point3(gizmo_buffer_vec3_neg(axis)),
      color,
    )
  }
}

///|
pub fn GizmoBuffer::cross_2d(
  self : GizmoBuffer,
  isometry : @sprite.Isometry2d,
  half_size : Float,
  color : @color.Color,
) -> Unit {
  let axes = [
    @math.Vec2::new(half_size, 0.0F),
    @math.Vec2::new(0.0F, half_size),
  ]
  for axis in axes {
    self.line_2d(
      isometry.transform_point(axis),
      isometry.transform_point(gizmo_buffer_vec2_neg(axis)),
      color,
    )
  }
}

///|
pub fn GizmoBuffer::list_positions(self : GizmoBuffer) -> Array[@math.Vec3] {
  self.list_positions
}

///|
pub fn GizmoBuffer::list_colors(self : GizmoBuffer) -> Array[@color.LinearRgba] {
  self.list_colors
}

///|
pub fn GizmoBuffer::strip_positions(self : GizmoBuffer) -> Array[@math.Vec3] {
  self.strip_positions
}

///|
pub fn GizmoBuffer::strip_colors(
  self : GizmoBuffer,
) -> Array[@color.LinearRgba] {
  self.strip_colors
}

///|
pub struct GizmoAsset {
  buffer : GizmoBuffer
  config_type_name : String
}

///|
pub fn GizmoAsset::new() -> GizmoAsset {
  GizmoAsset::{
    buffer: GizmoBuffer::default(),
    config_type_name: @any.of(@sprite.DefaultGizmoConfigGroup::default()).type_name(),
  }
}

///|
pub fn GizmoAsset::buffer(self : GizmoAsset) -> GizmoBuffer {
  self.buffer
}

///|
pub fn GizmoAsset::line(
  self : GizmoAsset,
  start : @math.Vec3,
  end : @math.Vec3,
  color : @color.Color,
) -> Unit {
  self.buffer.line(start, end, color)
}

///|
pub fn GizmoAsset::clear(self : GizmoAsset) -> Unit {
  self.buffer.clear()
}

///|
pub fn GizmoAsset::line_gradient(
  self : GizmoAsset,
  start : @math.Vec3,
  end : @math.Vec3,
  start_color : @color.Color,
  end_color : @color.Color,
) -> Unit {
  self.buffer.line_gradient(start, end, start_color, end_color)
}

///|
pub fn GizmoAsset::ray(
  self : GizmoAsset,
  start : @math.Vec3,
  vector : @math.Vec3,
  color : @color.Color,
) -> Unit {
  self.buffer.ray(start, vector, color)
}

///|
pub fn GizmoAsset::ray_gradient(
  self : GizmoAsset,
  start : @math.Vec3,
  vector : @math.Vec3,
  start_color : @color.Color,
  end_color : @color.Color,
) -> Unit {
  self.buffer.ray_gradient(start, vector, start_color, end_color)
}

///|
pub fn GizmoAsset::linestrip(
  self : GizmoAsset,
  positions : Array[@math.Vec3],
  color : @color.Color,
) -> Unit {
  self.buffer.linestrip(positions, color)
}

///|
pub fn GizmoAsset::lineloop(
  self : GizmoAsset,
  positions : Array[@math.Vec3],
  color : @color.Color,
) -> Unit {
  self.buffer.lineloop(positions, color)
}

///|
pub fn GizmoAsset::linestrip_gradient(
  self : GizmoAsset,
  points : Array[(@math.Vec3, @color.Color)],
) -> Unit {
  self.buffer.linestrip_gradient(points)
}

///|
pub fn GizmoAsset::line_2d(
  self : GizmoAsset,
  start : @math.Vec2,
  end : @math.Vec2,
  color : @color.Color,
) -> Unit {
  self.buffer.line_2d(start, end, color)
}

///|
pub fn GizmoAsset::line_gradient_2d(
  self : GizmoAsset,
  start : @math.Vec2,
  end : @math.Vec2,
  start_color : @color.Color,
  end_color : @color.Color,
) -> Unit {
  self.buffer.line_gradient_2d(start, end, start_color, end_color)
}

///|
pub fn GizmoAsset::linestrip_2d(
  self : GizmoAsset,
  positions : Array[@math.Vec2],
  color : @color.Color,
) -> Unit {
  self.buffer.linestrip_2d(positions, color)
}

///|
pub fn GizmoAsset::lineloop_2d(
  self : GizmoAsset,
  positions : Array[@math.Vec2],
  color : @color.Color,
) -> Unit {
  self.buffer.lineloop_2d(positions, color)
}

///|
pub fn GizmoAsset::linestrip_gradient_2d(
  self : GizmoAsset,
  points : Array[(@math.Vec2, @color.Color)],
) -> Unit {
  self.buffer.linestrip_gradient_2d(points)
}

///|
pub fn GizmoAsset::ray_2d(
  self : GizmoAsset,
  start : @math.Vec2,
  vector : @math.Vec2,
  color : @color.Color,
) -> Unit {
  self.buffer.ray_2d(start, vector, color)
}

///|
pub fn GizmoAsset::ray_gradient_2d(
  self : GizmoAsset,
  start : @math.Vec2,
  vector : @math.Vec2,
  start_color : @color.Color,
  end_color : @color.Color,
) -> Unit {
  self.buffer.ray_gradient_2d(start, vector, start_color, end_color)
}

///|
pub fn GizmoAsset::rect(
  self : GizmoAsset,
  isometry : @math.Isometry3d,
  size : @math.Vec2,
  color : @color.Color,
) -> Unit {
  self.buffer.rect(isometry, size, color)
}

///|
pub fn GizmoAsset::rect_2d(
  self : GizmoAsset,
  isometry : @sprite.Isometry2d,
  size : @math.Vec2,
  color : @color.Color,
) -> Unit {
  self.buffer.rect_2d(isometry, size, color)
}

///|
pub fn GizmoAsset::cube(
  self : GizmoAsset,
  transform : @transform.Transform,
  color : @color.Color,
) -> Unit {
  self.buffer.cube(transform, color)
}

///|
pub fn GizmoAsset::cross(
  self : GizmoAsset,
  isometry : @math.Isometry3d,
  half_size : Float,
  color : @color.Color,
) -> Unit {
  self.buffer.cross(isometry, half_size, color)
}

///|
pub fn GizmoAsset::cross_2d(
  self : GizmoAsset,
  isometry : @sprite.Isometry2d,
  half_size : Float,
  color : @color.Color,
) -> Unit {
  self.buffer.cross_2d(isometry, half_size, color)
}

///|
pub fn GizmoAsset::config_type_name(self : GizmoAsset) -> String {
  self.config_type_name
}

///|
pub impl Default for GizmoAsset with default() {
  GizmoAsset::new()
}

///|
let ecs_key_gizmo : @ecs.ComponentKey[Gizmo] = @ecs.register_component(
  debug_name="mgstudio_gizmos::Gizmo",
)

///|
pub struct Gizmo {
  handle : @asset.Handle[GizmoAsset]
  line_config : GizmoLineConfig
  depth_bias : Float
}

///|
pub fn Gizmo::default() -> Gizmo {
  Gizmo::{
    handle: @asset.Handle::new(0),
    line_config: GizmoLineConfig::default(),
    depth_bias: 0.0F,
  }
}

///|
pub fn Gizmo::handle(self : Gizmo) -> @asset.Handle[GizmoAsset] {
  self.handle
}

///|
pub fn Gizmo::line_config(self : Gizmo) -> GizmoLineConfig {
  self.line_config
}

///|
pub fn Gizmo::depth_bias(self : Gizmo) -> Float {
  self.depth_bias
}

///|
pub fn Gizmo::with_handle(
  self : Gizmo,
  handle : @asset.Handle[GizmoAsset],
) -> Gizmo {
  Gizmo::{ handle, line_config: self.line_config, depth_bias: self.depth_bias }
}

///|
pub fn Gizmo::with_line_config(
  self : Gizmo,
  line_config : GizmoLineConfig,
) -> Gizmo {
  Gizmo::{ handle: self.handle, line_config, depth_bias: self.depth_bias }
}

///|
pub fn Gizmo::with_depth_bias(self : Gizmo, depth_bias : Float) -> Gizmo {
  Gizmo::{ handle: self.handle, line_config: self.line_config, depth_bias }
}

///|
pub impl Default for Gizmo with default() {
  Gizmo::default()
}

///|
pub impl @ecs.Component for Gizmo with component() {
  ecs_key_gizmo
}

///|
pub fn install_retained_gizmo_required_components(world : @ecs.World) -> Unit {
  world.register_required_components(
    ecs_key_gizmo,
    @transform.Transform::component(),
  ) catch {
    _ => ()
  }
}
