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
