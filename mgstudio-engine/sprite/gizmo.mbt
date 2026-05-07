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
pub struct Gizmos[Config] {
  config : GizmoConfig
  config_group : Config
  state : Ref[GizmoState]
  world : @ecs.World?
}

///|
pub fn[Config] Gizmos::config(self : Gizmos[Config]) -> GizmoConfig {
  self.config
}

///|
pub fn[Config] Gizmos::config_group(self : Gizmos[Config]) -> Config {
  self.config_group
}

///|
fn[Config : GizmoConfigGroup + Default] gizmos_from_world(
  world : @ecs.World,
) -> Gizmos[Config] raise @ecs.SystemParamValidationError {
  let store : GizmoConfigStore? = world.get_resource(
    GizmoConfigStore::resource(),
  ) catch {
    _ => None
  }
  let group = Config::default()
  let store = match store {
    Some(store) => store
    None => raise @ecs.Invalid("Missing resource for system parameter")
  }
  let configs : (GizmoConfig, Config)? = store.get_config(group)
  match configs {
    Some((config, config_group)) =>
      Gizmos::{
        config,
        config_group,
        state: Ref(GizmoState::new()),
        world: Some(world),
      }
    None => raise @ecs.Invalid(gizmo_group_missing_message(group))
  }
}

///|
pub impl[Config : GizmoConfigGroup + Default] @app.SystemParam for Gizmos[
  Config,
] with init_state(world) {
  @app.system_param_empty_state(world)
}

///|
pub impl[Config : GizmoConfigGroup + Default] @app.SystemParam for Gizmos[
  Config,
] with get(_state) {
  let world = @app.current_world().unwrap()
  let gizmos : Gizmos[Config] = gizmos_from_world(world)
  gizmos
}

///|
pub impl[Config : GizmoConfigGroup + Default] @app.SystemParam for Gizmos[
  Config,
] with store(self, state) {
  self.flush()
  @app.system_param_store_no_state(self, state)
}

///|
pub impl[Config : GizmoConfigGroup + Default] @app.SystemParam for Gizmos[
  Config,
] with access(_world) {
  let access = @app.SystemAccess::new()
  access.add_read_resource(GizmoConfigStore::resource().id())
  access
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
fn gizmo_line_style_parts(style : GizmoLineStyle) -> (Int, Float, Float) {
  match style {
    Solid => (0, 1.0F, 1.0F)
    Dotted => (1, 1.0F, 1.0F)
    Dashed(gap_scale~, line_scale~) => {
      if gap_scale <= 0.0F {
        @app.log_warn_once(
          "gizmos.dashed_gap_scale", "When using gizmos with the line style `GizmoLineStyle::Dashed{..}` the gap scale should be greater than zero.",
        )
      }
      if line_scale <= 0.0F {
        @app.log_warn_once(
          "gizmos.dashed_line_scale", "When using gizmos with the line style `GizmoLineStyle::Dashed{..}` the line scale should be greater than zero.",
        )
      }
      (2, gap_scale, line_scale)
    }
  }
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
fn vec3_add(a : @math.Vec3, b : @math.Vec3) -> @math.Vec3 {
  @math.Vec3::new(a.x + b.x, a.y + b.y, a.z + b.z)
}

///|
fn vec3_sub(a : @math.Vec3, b : @math.Vec3) -> @math.Vec3 {
  @math.Vec3::new(a.x - b.x, a.y - b.y, a.z - b.z)
}

///|
fn vec3_scale(value : @math.Vec3, factor : Float) -> @math.Vec3 {
  @math.Vec3::new(value.x * factor, value.y * factor, value.z * factor)
}

///|
fn vec3_length(value : @math.Vec3) -> Float {
  @math.pow(value.x * value.x + value.y * value.y + value.z * value.z, 0.5F)
}

///|
fn vec3_normalize_or_zero(value : @math.Vec3) -> @math.Vec3 {
  let length = vec3_length(value)
  if length <= 0.0F {
    @math.Vec3::zero()
  } else {
    vec3_scale(value, 1.0F / length)
  }
}

///|
fn color_to_vec4(color : Color) -> @math.Vec4 {
  @math.Vec4::new(color.r, color.g, color.b, color.a)
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
fn isometry3_points_from_2d(
  isometry : @math.Isometry3d,
  points : Array[@math.Vec2],
) -> Array[@math.Vec3] {
  let out : Array[@math.Vec3] = []
  for point in points {
    out.push(isometry.transform_point3(@math.Vec3::new(point.x, point.y, 0.0F)))
  }
  out
}

///|
fn transform_point_3d(
  transform : @transform.Transform,
  point : @math.Vec3,
) -> @math.Vec3 {
  transform.translation
  .add(transform.right().mul_scalar(point.x * transform.scale.x))
  .add(transform.up().mul_scalar(point.y * transform.scale.y))
  .add(transform.back().mul_scalar(point.z * transform.scale.z))
}

///|
pub(all) struct GizmoLine {
  start : @math.Vec2
  end : @math.Vec2
  start_color : Color
  end_color : Color
  layers : RenderLayers
  width : Float
  style : GizmoLineStyle
}

///|
pub(all) struct GizmoLine3d {
  start : @math.Vec3
  end : @math.Vec3
  start_color : Color
  end_color : Color
  layers : RenderLayers
}

///|
pub(all) struct PendingEllipse {
  isometry : Isometry2d
  half_size : @math.Vec2
  color : Color
  mut resolution : Int
  config : GizmoConfig
}

///|
pub(all) struct PendingArc {
  isometry : Isometry2d
  arc_angle : Float
  radius : Float
  color : Color
  mut resolution : Int
  mut has_resolution : Bool
  config : GizmoConfig
}

///|
pub(all) struct PendingRoundedRect {
  isometry : Isometry2d
  size : @math.Vec2
  color : Color
  mut corner_radius : Float
  mut arc_resolution : Int
  config : GizmoConfig
}

///|
pub(all) struct PendingArrow {
  start : @math.Vec2
  end : @math.Vec2
  color : Color
  mut tip_length : Float
  mut double_ended : Bool
  config : GizmoConfig
}

///|
pub(all) struct PendingGrid {
  isometry : Isometry2d
  spacing : @math.Vec2
  cell_count : @math.IVec2
  mut skew : @math.Vec2
  mut outer_edges_x : Bool
  mut outer_edges_y : Bool
  color : Color
  config : GizmoConfig
}

///|
pub(all) struct GizmoState {
  lines : Array[GizmoLine]
  lines_3d : Array[GizmoLine3d]
  pending_ellipses : Array[PendingEllipse]
  pending_arcs : Array[PendingArc]
  pending_rounded_rects : Array[PendingRoundedRect]
  pending_arrows : Array[PendingArrow]
  pending_grids : Array[PendingGrid]
  mut mesh_handle_3d : @asset.Handle[@mesh.Mesh]?
}

///|
fn GizmoState::new() -> GizmoState {
  GizmoState::{
    lines: [],
    lines_3d: [],
    pending_ellipses: [],
    pending_arcs: [],
    pending_rounded_rects: [],
    pending_arrows: [],
    pending_grids: [],
    mesh_handle_3d: None,
  }
}

///|
fn GizmoState::clear(self : GizmoState) -> Unit {
  self.lines.clear()
  self.lines_3d.clear()
  self.pending_ellipses.clear()
  self.pending_arcs.clear()
  self.pending_rounded_rects.clear()
  self.pending_arrows.clear()
  self.pending_grids.clear()
}

///|
fn GizmoState::append_from(self : GizmoState, other : GizmoState) -> Unit {
  for item in other.lines {
    self.lines.push(item)
  }
  for item in other.lines_3d {
    self.lines_3d.push(item)
  }
  for item in other.pending_ellipses {
    self.pending_ellipses.push(item)
  }
  for item in other.pending_arcs {
    self.pending_arcs.push(item)
  }
  for item in other.pending_rounded_rects {
    self.pending_rounded_rects.push(item)
  }
  for item in other.pending_arrows {
    self.pending_arrows.push(item)
  }
  for item in other.pending_grids {
    self.pending_grids.push(item)
  }
}

///|
fn GizmoState::append_from_with_config(
  self : GizmoState,
  other : GizmoState,
  config : GizmoConfig,
) -> Unit {
  let line_config = config.line
  let width = positive_or(line_config.width, DEFAULT_GIZMO_LINE_WIDTH)
  for item in other.lines {
    self.lines.push(GizmoLine::{
      start: item.start,
      end: item.end,
      start_color: item.start_color,
      end_color: item.end_color,
      layers: config.render_layers,
      width,
      style: line_config.style,
    })
  }
  for item in other.lines_3d {
    self.lines_3d.push(GizmoLine3d::{
      start: item.start,
      end: item.end,
      start_color: item.start_color,
      end_color: item.end_color,
      layers: config.render_layers,
    })
  }
  for item in other.pending_ellipses {
    self.pending_ellipses.push({ ..item, config, })
  }
  for item in other.pending_arcs {
    self.pending_arcs.push({ ..item, config, })
  }
  for item in other.pending_rounded_rects {
    self.pending_rounded_rects.push({ ..item, config, })
  }
  for item in other.pending_arrows {
    self.pending_arrows.push({ ..item, config, })
  }
  for item in other.pending_grids {
    self.pending_grids.push({ ..item, config, })
  }
}

///|
pub struct GizmoStorage[Config] {
  state : GizmoState
  phantom : Config?
}

///|
pub fn[Config] GizmoStorage::new() -> GizmoStorage[Config] {
  GizmoStorage::{ state: GizmoState::new(), phantom: None }
}

///|
pub impl[Config] Default for GizmoStorage[Config] with default() {
  GizmoStorage::new()
}

///|
let gizmo_storage_resource_registry : Ref[@hashmap.HashMap[String, @any.Any]] = Ref(
  @hashmap.HashMap([]),
)

///|
let gizmo_storage_drain_registry : Ref[
  @hashmap.HashMap[String, (@ecs.World) -> Unit],
] = Ref(@hashmap.HashMap([]))

///|
fn[Config] gizmo_storage_type_name_of(_probe : GizmoStorage[Config]) -> String {
  @any.of(_probe).type_name()
}

///|
fn[Config] registered_gizmo_storage_resource_key() -> @ecs.ResourceKey[
  GizmoStorage[Config],
] {
  let probe : GizmoStorage[Config] = GizmoStorage::new()
  let type_name = gizmo_storage_type_name_of(probe)
  match gizmo_storage_resource_registry.val.get(type_name) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None =>
          abort(
            "gizmo storage resource registry contained a mismatched key for \{type_name}",
          )
      }
    None => {
      let key : @ecs.ResourceKey[GizmoStorage[Config]] = @ecs.register_resource(
        debug_name="mgstudio_gizmos::GizmoStorage<\{type_name}>",
      )
      gizmo_storage_resource_registry.val.set(type_name, @any.of(key))
      key
    }
  }
}

///|
pub impl[Config] @app.Resource for GizmoStorage[Config] with resource() {
  registered_gizmo_storage_resource_key()
}

///|
fn[Config] register_gizmo_storage_drain(_group : Config) -> Unit {
  let probe : GizmoStorage[Config] = GizmoStorage::new()
  let type_name = gizmo_storage_type_name_of(probe)
  if gizmo_storage_drain_registry.val.contains(type_name) {
    return
  }
  let drain : (@ecs.World) -> Unit = fn(world) {
    let key : @ecs.ResourceKey[GizmoStorage[Config]] = registered_gizmo_storage_resource_key()
    match (try! world.get_resource_mut(key)) {
      Some(storage_ref) =>
        storage_ref.modify(fn(storage) {
          gizmo_state.val.append_from(storage.state)
          storage.state.clear()
        })
      None => ()
    }
  }
  gizmo_storage_drain_registry.val.set(type_name, drain)
}

///|
fn[Config] Gizmos::flush(self : Gizmos[Config]) -> Unit {
  match self.world {
    Some(world) => {
      let key : @ecs.ResourceKey[GizmoStorage[Config]] = registered_gizmo_storage_resource_key()
      match (try! world.get_resource_mut(key)) {
        Some(storage_ref) =>
          storage_ref.modify(fn(storage) {
            storage.state.append_from(self.state.val)
            self.state.val.clear()
          })
        None => self.state.val.clear()
      }
    }
    None => self.state.val.clear()
  }
}

///|
let gizmo_state : Ref[GizmoState] = Ref(GizmoState::new())

///|
let global_gizmo_state : Ref[GizmoState] = Ref(GizmoState::new())

///|
pub fn gizmo() -> Gizmos[DefaultGizmoConfigGroup] {
  Gizmos::{
    config: GizmoConfig::default(),
    config_group: DefaultGizmoConfigGroup::default(),
    state: global_gizmo_state,
    world: None,
  }
}

///|
pub fn flush_global_gizmos(gizmos : Gizmos[DefaultGizmoConfigGroup]) -> Unit {
  if !gizmos.config.enabled {
    global_gizmo_state.val.clear()
    return
  }
  gizmos.state.val.append_from_with_config(
    global_gizmo_state.val,
    gizmos.config,
  )
  global_gizmo_state.val.clear()
}

///|
fn gizmos_add_line_with_config(
  state : Ref[GizmoState],
  config : GizmoConfig,
  start : @math.Vec2,
  end : @math.Vec2,
  start_color : Color,
  end_color : Color,
) -> Unit {
  if !config.enabled {
    return
  }
  let effective_layers = config.render_layers
  if effective_layers.mask == 0 {
    return
  }
  let line_config = config.line
  let width = positive_or(line_config.width, DEFAULT_GIZMO_LINE_WIDTH)
  state.val.lines.push(GizmoLine::{
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
fn gizmos_linestrip_with_config(
  state : Ref[GizmoState],
  config : GizmoConfig,
  positions : Array[@math.Vec2],
  color : Color,
) -> Unit {
  if !config.enabled {
    return
  }
  let count = positions.length()
  if count < 2 {
    return
  }
  for i in 0..<(count - 1) {
    gizmos_add_line_with_config(
      state,
      config,
      positions[i],
      positions[i + 1],
      color,
      color,
    )
  }
}

///|
fn gizmos_linestrip_gradient_with_config(
  state : Ref[GizmoState],
  config : GizmoConfig,
  positions : Array[(@math.Vec2, Color)],
) -> Unit {
  if !config.enabled {
    return
  }
  let count = positions.length()
  if count < 2 {
    return
  }
  for i in 0..<(count - 1) {
    let (start_pos, start_color) = positions[i]
    let (end_pos, end_color) = positions[i + 1]
    gizmos_add_line_with_config(
      state, config, start_pos, end_pos, start_color, end_color,
    )
  }
}

///|
fn gizmos_add_line_3d_with_config(
  state : Ref[GizmoState],
  config : GizmoConfig,
  start : @math.Vec3,
  end : @math.Vec3,
  start_color : Color,
  end_color : Color,
) -> Unit {
  if !config.enabled {
    return
  }
  let effective_layers = config.render_layers
  if effective_layers.mask == 0 {
    return
  }
  state.val.lines_3d.push(GizmoLine3d::{
    start,
    end,
    start_color,
    end_color,
    layers: effective_layers,
  })
}

///|
fn gizmos_linestrip_3d_with_config(
  state : Ref[GizmoState],
  config : GizmoConfig,
  positions : Array[@math.Vec3],
  color : Color,
) -> Unit {
  if !config.enabled {
    return
  }
  let count = positions.length()
  if count < 2 {
    return
  }
  for i in 0..<(count - 1) {
    gizmos_add_line_3d_with_config(
      state,
      config,
      positions[i],
      positions[i + 1],
      color,
      color,
    )
  }
}

///|
fn gizmos_linestrip_gradient_3d_with_config(
  state : Ref[GizmoState],
  config : GizmoConfig,
  positions : Array[(@math.Vec3, Color)],
) -> Unit {
  if !config.enabled {
    return
  }
  let count = positions.length()
  if count < 2 {
    return
  }
  for i in 0..<(count - 1) {
    let (start_pos, start_color) = positions[i]
    let (end_pos, end_color) = positions[i + 1]
    gizmos_add_line_3d_with_config(
      state, config, start_pos, end_pos, start_color, end_color,
    )
  }
}

///|
fn gizmos_lineloop_with_config(
  state : Ref[GizmoState],
  config : GizmoConfig,
  positions : Array[@math.Vec2],
  color : Color,
) -> Unit {
  let count = positions.length()
  if count < 2 {
    return
  }
  gizmos_linestrip_with_config(state, config, positions, color)
  gizmos_add_line_with_config(
    state,
    config,
    positions[count - 1],
    positions[0],
    color,
    color,
  )
}

///|
fn gizmos_arrow_with_config(
  state : Ref[GizmoState],
  config : GizmoConfig,
  start : @math.Vec2,
  end : @math.Vec2,
  color : Color,
  tip_length : Float,
  double_ended : Bool,
) -> Unit {
  gizmos_add_line_with_config(state, config, start, end, color, color)
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
  gizmos_add_line_with_config(state, config, end, tip_left, color, color)
  gizmos_add_line_with_config(state, config, end, tip_right, color, color)
  if double_ended {
    let back_dir = vec2_scale(direction, -1.0F)
    let base_start = vec2_sub(start, vec2_scale(back_dir, tip_length))
    let perp_start = @math.Vec2::new(-back_dir.y, back_dir.x)
    let tip_left_start = vec2_add(base_start, vec2_scale(perp_start, tip_width))
    let tip_right_start = vec2_sub(
      base_start,
      vec2_scale(perp_start, tip_width),
    )
    gizmos_add_line_with_config(
      state, config, start, tip_left_start, color, color,
    )
    gizmos_add_line_with_config(
      state, config, start, tip_right_start, color, color,
    )
  }
}

///|
fn gizmos_draw_grid_with_config(
  state : Ref[GizmoState],
  config : GizmoConfig,
  isometry : Isometry2d,
  cell_count : @math.IVec2,
  spacing : @math.Vec2,
  skew : @math.Vec2,
  outer_edges_x : Bool,
  outer_edges_y : Bool,
  color : Color,
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
    gizmos_add_line_with_config(
      state, config, world_start, world_end, color, color,
    )
  }
  for i in 0..<y_line_count {
    let start = vec2_add(y_start, vec2_scale(dx, float_from_int(i)))
    let end = vec2_add(start, vec2_scale(dy, float_from_int(count_y)))
    let world_start = isometry.transform_point(start)
    let world_end = isometry.transform_point(end)
    gizmos_add_line_with_config(
      state, config, world_start, world_end, color, color,
    )
  }
}

///|
fn gizmos_prepare(world : @ecs.World) -> Unit {
  for entry in gizmo_storage_drain_registry.val.iter() {
    let (_, drain) = entry
    drain(world)
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
      gizmos_linestrip_with_config(
        gizmo_state,
        entry.config,
        transformed,
        entry.color,
      )
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
      gizmos_linestrip_with_config(
        gizmo_state,
        entry.config,
        transformed,
        entry.color,
      )
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
        gizmos_lineloop_with_config(
          gizmo_state,
          entry.config,
          transformed,
          entry.color,
        )
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
        gizmos_lineloop_with_config(
          gizmo_state,
          entry.config,
          transformed,
          entry.color,
        )
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
      gizmos_arrow_with_config(
        gizmo_state,
        entry.config,
        entry.start,
        entry.end,
        entry.color,
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
      gizmos_draw_grid_with_config(
        gizmo_state,
        entry.config,
        entry.isometry,
        entry.cell_count,
        entry.spacing,
        entry.skew,
        entry.outer_edges_x,
        entry.outer_edges_y,
        entry.color,
      )
    }
  }
}

///|
fn gizmos_clear() -> Unit {
  gizmo_state.val.lines.clear()
  gizmo_state.val.lines_3d.clear()
  gizmo_state.val.pending_ellipses.clear()
  gizmo_state.val.pending_arcs.clear()
  gizmo_state.val.pending_rounded_rects.clear()
  gizmo_state.val.pending_arrows.clear()
  gizmo_state.val.pending_grids.clear()
}

///|
pub fn gizmos_clear_3d() -> Unit {
  gizmo_state.val.lines_3d.clear()
}

///|
fn gizmos_reset() -> Unit {
  gizmos_clear()
  gizmos_clear_3d()
  global_gizmo_state.val.clear()
}

///|
fn gizmos_draw_lines(layers : RenderLayers) -> Unit {
  for line in gizmo_state.val.lines {
    if line.layers.matches(layers) {
      let (style_kind, gap_scale, line_scale) = gizmo_line_style_parts(
        line.style,
      )
      @render.host_gpu_draw_gizmo_line(
        start_x=line.start.x,
        start_y=line.start.y,
        start_r=line.start_color.r,
        start_g=line.start_color.g,
        start_b=line.start_color.b,
        start_a=line.start_color.a,
        end_x=line.end.x,
        end_y=line.end.y,
        end_r=line.end_color.r,
        end_g=line.end_color.g,
        end_b=line.end_color.b,
        end_a=line.end_color.a,
        line_width=line.width,
        style_kind~,
        gap_scale~,
        line_scale~,
      )
    }
  }
}

///|
pub fn gizmos_mesh_id_3d(layers : RenderLayers) -> Int? {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let colors : Array[@math.Vec4] = []
  for line in gizmo_state.val.lines_3d {
    if !line.layers.matches(layers) {
      continue
    }
    positions.push(line.start)
    positions.push(line.end)
    uvs.push(@math.Vec2::zero())
    uvs.push(@math.Vec2::zero())
    colors.push(color_to_vec4(line.start_color))
    colors.push(color_to_vec4(line.end_color))
  }
  if positions.length() == 0 {
    return None
  }
  let geometry = @mesh.Mesh3dGeometry::new_with_colors_and_topology(
    positions,
    uvs,
    colors,
    None,
    @mesh.Mesh3dPrimitiveTopology::LineList,
  )
  let mesh = @mesh.Mesh::from_3d_geometry(geometry)
  let handle = match gizmo_state.val.mesh_handle_3d {
    Some(handle) => {
      ignore(render_mesh_asset_set(handle, mesh))
      handle
    }
    None => {
      let handle = render_mesh_asset_add(mesh)
      gizmo_state.val.mesh_handle_3d = Some(handle)
      handle
    }
  }
  Some(render2d_upload_mesh_handle(handle))
}

///|
pub fn[Config] Gizmos::line_2d(
  self : Gizmos[Config],
  start : @math.Vec2,
  end : @math.Vec2,
  color : Color,
) -> Unit {
  gizmos_add_line_with_config(self.state, self.config, start, end, color, color)
}

///|
pub fn[Config] Gizmos::line_3d(
  self : Gizmos[Config],
  start : @math.Vec3,
  end : @math.Vec3,
  color : Color,
) -> Unit {
  gizmos_add_line_3d_with_config(
    self.state,
    self.config,
    start,
    end,
    color,
    color,
  )
}

///|
fn gizmo_transform_point_2d(
  transform : @transform.Transform,
  point : @math.Vec2,
) -> @math.Vec2 {
  let scaled = @math.Vec2::new(
    point.x * transform.scale.x,
    point.y * transform.scale.y,
  )
  let rotation = transform.rotation_z()
  let cosv = @math.cos(rotation)
  let sinv = @math.sin(rotation)
  let rotated_x = scaled.x * cosv - scaled.y * sinv
  let rotated_y = scaled.x * sinv + scaled.y * cosv
  @math.Vec2::new(
    rotated_x + transform.translation.x,
    rotated_y + transform.translation.y,
  )
}

///|
pub fn[Config] Gizmos::mesh_wireframe_2d(
  self : Gizmos[Config],
  geometry : @mesh.Mesh2dGeometry,
  transform : @transform.Transform,
  color : Color,
) -> Unit {
  guard geometry.wireframe_segments() is Some(segments) else { return }
  for segment in segments {
    let world_start = gizmo_transform_point_2d(transform, segment.0)
    let world_end = gizmo_transform_point_2d(transform, segment.1)
    gizmos_add_line_with_config(
      self.state,
      self.config,
      world_start,
      world_end,
      color,
      color,
    )
  }
}

///|
pub fn[Config] Gizmos::line_gradient_2d(
  self : Gizmos[Config],
  start : @math.Vec2,
  end : @math.Vec2,
  start_color : Color,
  end_color : Color,
) -> Unit {
  gizmos_add_line_with_config(
    self.state,
    self.config,
    start,
    end,
    start_color,
    end_color,
  )
}

///|
pub fn[Config] Gizmos::line_gradient_3d(
  self : Gizmos[Config],
  start : @math.Vec3,
  end : @math.Vec3,
  start_color : Color,
  end_color : Color,
) -> Unit {
  gizmos_add_line_3d_with_config(
    self.state,
    self.config,
    start,
    end,
    start_color,
    end_color,
  )
}

///|
pub fn[Config] Gizmos::linestrip_2d(
  self : Gizmos[Config],
  positions : Array[@math.Vec2],
  color : Color,
) -> Unit {
  gizmos_linestrip_with_config(self.state, self.config, positions, color)
}

///|
pub fn[Config] Gizmos::linestrip_3d(
  self : Gizmos[Config],
  positions : Array[@math.Vec3],
  color : Color,
) -> Unit {
  gizmos_linestrip_3d_with_config(self.state, self.config, positions, color)
}

///|
pub fn[Config] Gizmos::lineloop_2d(
  self : Gizmos[Config],
  positions : Array[@math.Vec2],
  color : Color,
) -> Unit {
  gizmos_lineloop_with_config(self.state, self.config, positions, color)
}

///|
pub fn[Config] Gizmos::linestrip_gradient_2d(
  self : Gizmos[Config],
  positions : Array[(@math.Vec2, Color)],
) -> Unit {
  gizmos_linestrip_gradient_with_config(self.state, self.config, positions)
}

///|
pub fn[Config] Gizmos::linestrip_gradient_3d(
  self : Gizmos[Config],
  positions : Array[(@math.Vec3, Color)],
) -> Unit {
  gizmos_linestrip_gradient_3d_with_config(self.state, self.config, positions)
}

///|
pub fn[Config] Gizmos::ray_2d(
  self : Gizmos[Config],
  start : @math.Vec2,
  vector : @math.Vec2,
  color : Color,
) -> Unit {
  let end = vec2_add(start, vector)
  gizmos_add_line_with_config(self.state, self.config, start, end, color, color)
}

///|
pub fn[Config] Gizmos::ray_3d(
  self : Gizmos[Config],
  start : @math.Vec3,
  vector : @math.Vec3,
  color : Color,
) -> Unit {
  let end = vec3_add(start, vector)
  gizmos_add_line_3d_with_config(
    self.state,
    self.config,
    start,
    end,
    color,
    color,
  )
}

///|
pub fn[Config] Gizmos::ray_gradient_2d(
  self : Gizmos[Config],
  start : @math.Vec2,
  vector : @math.Vec2,
  start_color : Color,
  end_color : Color,
) -> Unit {
  let end = vec2_add(start, vector)
  gizmos_add_line_with_config(
    self.state,
    self.config,
    start,
    end,
    start_color,
    end_color,
  )
}

///|
pub fn[Config] Gizmos::rect_2d(
  self : Gizmos[Config],
  isometry : Isometry2d,
  size : @math.Vec2,
  color : Color,
) -> Unit {
  let half = @math.Vec2::new(size.x / 2.0F, size.y / 2.0F)
  let tl = isometry.transform_point(@math.Vec2::new(-half.x, half.y))
  let tr = isometry.transform_point(@math.Vec2::new(half.x, half.y))
  let br = isometry.transform_point(@math.Vec2::new(half.x, -half.y))
  let bl = isometry.transform_point(@math.Vec2::new(-half.x, -half.y))
  gizmos_lineloop_with_config(self.state, self.config, [tl, tr, br, bl], color)
}

///|
pub struct RoundedRectBuilder {
  id : Int
  state : Ref[GizmoState]
}

///|
pub fn RoundedRectBuilder::corner_radius(
  self : RoundedRectBuilder,
  radius : Float,
) -> RoundedRectBuilder {
  if self.id >= 0 && self.id < self.state.val.pending_rounded_rects.length() {
    self.state.val.pending_rounded_rects[self.id].corner_radius = radius
  }
  self
}

///|
pub fn RoundedRectBuilder::arc_resolution(
  self : RoundedRectBuilder,
  resolution : Int,
) -> RoundedRectBuilder {
  if self.id >= 0 && self.id < self.state.val.pending_rounded_rects.length() {
    self.state.val.pending_rounded_rects[self.id].arc_resolution = max_int(
      resolution, 1,
    )
  }
  self
}

///|
pub fn[Config] Gizmos::rounded_rect_2d(
  self : Gizmos[Config],
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
    config: self.config,
  }
  let id = self.state.val.pending_rounded_rects.length()
  self.state.val.pending_rounded_rects.push(entry)
  RoundedRectBuilder::{ id, state: self.state }
}

///|
pub struct Ellipse2dBuilder {
  id : Int
  state : Ref[GizmoState]
}

///|
pub fn Ellipse2dBuilder::resolution(
  self : Ellipse2dBuilder,
  segments : Int,
) -> Ellipse2dBuilder {
  if self.id >= 0 && self.id < self.state.val.pending_ellipses.length() {
    self.state.val.pending_ellipses[self.id].resolution = max_int(segments, 3)
  }
  self
}

///|
pub fn[Config] Gizmos::circle_2d(
  self : Gizmos[Config],
  isometry : Isometry2d,
  radius : Float,
  color : Color,
) -> Ellipse2dBuilder {
  let entry = PendingEllipse::{
    isometry,
    half_size: @math.Vec2::new(radius, radius),
    color,
    resolution: DEFAULT_CIRCLE_RESOLUTION,
    config: self.config,
  }
  let id = self.state.val.pending_ellipses.length()
  self.state.val.pending_ellipses.push(entry)
  Ellipse2dBuilder::{ id, state: self.state }
}

///|
pub fn[Config] Gizmos::ellipse_2d(
  self : Gizmos[Config],
  isometry : Isometry2d,
  half_size : @math.Vec2,
  color : Color,
) -> Ellipse2dBuilder {
  let entry = PendingEllipse::{
    isometry,
    half_size,
    color,
    resolution: DEFAULT_CIRCLE_RESOLUTION,
    config: self.config,
  }
  let id = self.state.val.pending_ellipses.length()
  self.state.val.pending_ellipses.push(entry)
  Ellipse2dBuilder::{ id, state: self.state }
}

///|
pub struct Arc2dBuilder {
  id : Int
  state : Ref[GizmoState]
}

///|
pub fn Arc2dBuilder::resolution(
  self : Arc2dBuilder,
  segments : Int,
) -> Arc2dBuilder {
  if self.id >= 0 && self.id < self.state.val.pending_arcs.length() {
    self.state.val.pending_arcs[self.id].resolution = max_int(segments, 1)
    self.state.val.pending_arcs[self.id].has_resolution = true
  }
  self
}

///|
pub fn[Config] Gizmos::arc_2d(
  self : Gizmos[Config],
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
    config: self.config,
  }
  let id = self.state.val.pending_arcs.length()
  self.state.val.pending_arcs.push(entry)
  Arc2dBuilder::{ id, state: self.state }
}

///|
pub fn[Config] Gizmos::short_arc_2d_between(
  self : Gizmos[Config],
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
pub fn[Config] Gizmos::long_arc_2d_between(
  self : Gizmos[Config],
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
  state : Ref[GizmoState]
}

///|
pub fn ArrowBuilder::with_tip_length(
  self : ArrowBuilder,
  length : Float,
) -> ArrowBuilder {
  if self.id >= 0 && self.id < self.state.val.pending_arrows.length() {
    self.state.val.pending_arrows[self.id].tip_length = length
  }
  self
}

///|
pub fn ArrowBuilder::with_double_end(self : ArrowBuilder) -> ArrowBuilder {
  if self.id >= 0 && self.id < self.state.val.pending_arrows.length() {
    self.state.val.pending_arrows[self.id].double_ended = true
  }
  self
}

///|
pub fn[Config] Gizmos::arrow_2d(
  self : Gizmos[Config],
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
    config: self.config,
  }
  let id = self.state.val.pending_arrows.length()
  self.state.val.pending_arrows.push(entry)
  ArrowBuilder::{ id, state: self.state }
}

///|
pub fn[Config] Gizmos::arrow_3d(
  self : Gizmos[Config],
  start : @math.Vec3,
  end : @math.Vec3,
  color : Color,
) -> Unit {
  let delta = vec3_sub(end, start)
  let length = vec3_length(delta)
  gizmos_add_line_3d_with_config(
    self.state,
    self.config,
    start,
    end,
    color,
    color,
  )
  if length <= 0.0F {
    return
  }
  let direction = vec3_normalize_or_zero(delta)
  let tip_length = length / 10.0F
  let up_seed = if abs_float(direction.y) < 0.99F {
    @math.Vec3::new(0.0F, 1.0F, 0.0F)
  } else {
    @math.Vec3::new(1.0F, 0.0F, 0.0F)
  }
  let side = direction.cross(up_seed).normalize_or_zero()
  let up = side.cross(direction).normalize_or_zero()
  let tip_back = vec3_scale(direction, -tip_length)
  let tip_left = vec3_add(
    end,
    vec3_add(tip_back, vec3_scale(side, tip_length * 0.5F)),
  )
  let tip_right = vec3_add(
    end,
    vec3_add(tip_back, vec3_scale(side, -tip_length * 0.5F)),
  )
  let tip_up = vec3_add(
    end,
    vec3_add(tip_back, vec3_scale(up, tip_length * 0.5F)),
  )
  let tip_down = vec3_add(
    end,
    vec3_add(tip_back, vec3_scale(up, -tip_length * 0.5F)),
  )
  gizmos_add_line_3d_with_config(
    self.state,
    self.config,
    end,
    tip_left,
    color,
    color,
  )
  gizmos_add_line_3d_with_config(
    self.state,
    self.config,
    end,
    tip_right,
    color,
    color,
  )
  gizmos_add_line_3d_with_config(
    self.state,
    self.config,
    end,
    tip_up,
    color,
    color,
  )
  gizmos_add_line_3d_with_config(
    self.state,
    self.config,
    end,
    tip_down,
    color,
    color,
  )
}

///|
pub fn[Config] Gizmos::axes_2d(
  self : Gizmos[Config],
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
pub fn[Config] Gizmos::axes_3d(
  self : Gizmos[Config],
  transform : @transform.Transform,
  length : Float,
) -> Unit {
  let origin = transform.translation
  let x_end = vec3_add(origin, vec3_scale(transform.right(), length))
  let y_end = vec3_add(origin, vec3_scale(transform.up(), length))
  let z_end = vec3_add(origin, vec3_scale(transform.back(), length))
  self.arrow_3d(origin, x_end, Color::new(1.0F, 0.0F, 0.0F, 1.0F))
  self.arrow_3d(origin, y_end, Color::new(0.0F, 1.0F, 0.0F, 1.0F))
  self.arrow_3d(origin, z_end, Color::new(0.0F, 0.0F, 1.0F, 1.0F))
}

///|
pub fn[Config] Gizmos::cross_3d(
  self : Gizmos[Config],
  center : @math.Vec3,
  half_size : Float,
  color : Color,
) -> Unit {
  let axis_x = @math.Vec3::new(half_size, 0.0F, 0.0F)
  let axis_y = @math.Vec3::new(0.0F, half_size, 0.0F)
  let axis_z = @math.Vec3::new(0.0F, 0.0F, half_size)
  gizmos_add_line_3d_with_config(
    self.state,
    self.config,
    center.sub(axis_x),
    center.add(axis_x),
    color,
    color,
  )
  gizmos_add_line_3d_with_config(
    self.state,
    self.config,
    center.sub(axis_y),
    center.add(axis_y),
    color,
    color,
  )
  gizmos_add_line_3d_with_config(
    self.state,
    self.config,
    center.sub(axis_z),
    center.add(axis_z),
    color,
    color,
  )
}

///|
pub fn[Config] Gizmos::cross_2d(
  self : Gizmos[Config],
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
  gizmos_add_line_with_config(
    self.state,
    self.config,
    start_x,
    end_x,
    color,
    color,
  )
  gizmos_add_line_with_config(
    self.state,
    self.config,
    start_y,
    end_y,
    color,
    color,
  )
}

///|
pub struct Grid2dBuilder {
  id : Int
  state : Ref[GizmoState]
}

///|
pub fn Grid2dBuilder::skew_x(
  self : Grid2dBuilder,
  skew : Float,
) -> Grid2dBuilder {
  if self.id >= 0 && self.id < self.state.val.pending_grids.length() {
    let current = self.state.val.pending_grids[self.id].skew
    self.state.val.pending_grids[self.id].skew = @math.Vec2::new(
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
  if self.id >= 0 && self.id < self.state.val.pending_grids.length() {
    let current = self.state.val.pending_grids[self.id].skew
    self.state.val.pending_grids[self.id].skew = @math.Vec2::new(
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
  if self.id >= 0 && self.id < self.state.val.pending_grids.length() {
    self.state.val.pending_grids[self.id].skew = skew
  }
  self
}

///|
pub fn Grid2dBuilder::outer_edges_x(self : Grid2dBuilder) -> Grid2dBuilder {
  if self.id >= 0 && self.id < self.state.val.pending_grids.length() {
    self.state.val.pending_grids[self.id].outer_edges_x = true
  }
  self
}

///|
pub fn Grid2dBuilder::outer_edges_y(self : Grid2dBuilder) -> Grid2dBuilder {
  if self.id >= 0 && self.id < self.state.val.pending_grids.length() {
    self.state.val.pending_grids[self.id].outer_edges_y = true
  }
  self
}

///|
pub fn Grid2dBuilder::outer_edges(self : Grid2dBuilder) -> Grid2dBuilder {
  if self.id >= 0 && self.id < self.state.val.pending_grids.length() {
    self.state.val.pending_grids[self.id].outer_edges_x = true
    self.state.val.pending_grids[self.id].outer_edges_y = true
  }
  self
}

///|
pub fn[Config] Gizmos::grid_2d(
  self : Gizmos[Config],
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
    config: self.config,
  }
  let id = self.state.val.pending_grids.length()
  self.state.val.pending_grids.push(entry)
  Grid2dBuilder::{ id, state: self.state }
}

///|
pub fn[Config] Gizmos::curve_2d(
  self : Gizmos[Config],
  points : Array[@math.Vec2],
  color : Color,
) -> Unit {
  gizmos_linestrip_with_config(self.state, self.config, points, color)
}

///|
pub fn[Config] Gizmos::curve_gradient_2d(
  self : Gizmos[Config],
  points : Array[(@math.Vec2, Color)],
) -> Unit {
  gizmos_linestrip_gradient_with_config(self.state, self.config, points)
}

///|
pub fn[Config] Gizmos::grid_3d(
  self : Gizmos[Config],
  isometry : @math.Isometry3d,
  cell_count : @math.IVec2,
  spacing : @math.Vec2,
  color : Color,
) -> Unit {
  let columns = max_int(cell_count.x, 1)
  let rows = max_int(cell_count.y, 1)
  let half_width = spacing.x * float_from_int(columns) * 0.5F
  let half_height = spacing.y * float_from_int(rows) * 0.5F
  for column in 0..<=columns {
    let x = -half_width + spacing.x * float_from_int(column)
    let start = isometry.transform_point3(
      @math.Vec3::new(x, -half_height, 0.0F),
    )
    let end = isometry.transform_point3(@math.Vec3::new(x, half_height, 0.0F))
    gizmos_add_line_3d_with_config(
      self.state,
      self.config,
      start,
      end,
      color,
      color,
    )
  }
  for row in 0..<=rows {
    let y = -half_height + spacing.y * float_from_int(row)
    let start = isometry.transform_point3(@math.Vec3::new(-half_width, y, 0.0F))
    let end = isometry.transform_point3(@math.Vec3::new(half_width, y, 0.0F))
    gizmos_add_line_3d_with_config(
      self.state,
      self.config,
      start,
      end,
      color,
      color,
    )
  }
}

///|
pub fn[Config] Gizmos::rect_3d(
  self : Gizmos[Config],
  isometry : @math.Isometry3d,
  size : @math.Vec2,
  color : Color,
) -> Unit {
  let half_x = size.x * 0.5F
  let half_y = size.y * 0.5F
  let points = [
    @math.Vec2::new(-half_x, -half_y),
    @math.Vec2::new(half_x, -half_y),
    @math.Vec2::new(half_x, half_y),
    @math.Vec2::new(-half_x, half_y),
    @math.Vec2::new(-half_x, -half_y),
  ]
  self.linestrip_3d(isometry3_points_from_2d(isometry, points), color)
}

///|
pub fn[Config] Gizmos::circle_3d(
  self : Gizmos[Config],
  isometry : @math.Isometry3d,
  radius : Float,
  color : Color,
) -> Unit {
  self.linestrip_3d(
    isometry3_points_from_2d(
      isometry,
      ellipse_points(@math.Vec2::new(radius, radius), DEFAULT_CIRCLE_RESOLUTION),
    ),
    color,
  )
}

///|
pub fn[Config] Gizmos::arc_3d(
  self : Gizmos[Config],
  isometry : @math.Isometry3d,
  arc_angle : Float,
  radius : Float,
  color : Color,
) -> Unit {
  self.linestrip_3d(
    isometry3_points_from_2d(
      isometry,
      arc_points(arc_angle, radius, resolution_from_angle(arc_angle)),
    ),
    color,
  )
}

///|
pub fn[Config] Gizmos::sphere_3d(
  self : Gizmos[Config],
  isometry : @math.Isometry3d,
  radius : Float,
  color : Color,
) -> Unit {
  let circle = ellipse_points(
    @math.Vec2::new(radius, radius),
    DEFAULT_CIRCLE_RESOLUTION,
  )
  self.linestrip_3d(isometry3_points_from_2d(isometry, circle), color)
  self.linestrip_3d(
    isometry3_points_from_2d(
      @math.Isometry3d::new(
        isometry.translation,
        isometry.rotation.mul(@math.Quat::from_rotation_x(HALF_PI)),
      ),
      circle,
    ),
    color,
  )
  self.linestrip_3d(
    isometry3_points_from_2d(
      @math.Isometry3d::new(
        isometry.translation,
        isometry.rotation.mul(@math.Quat::from_rotation_y(HALF_PI)),
      ),
      circle,
    ),
    color,
  )
}

///|
pub fn[Config] Gizmos::cuboid_3d(
  self : Gizmos[Config],
  transform : @transform.Transform,
  size : @math.Vec3,
  color : Color,
) -> Unit {
  let half = @math.Vec3::new(size.x * 0.5F, size.y * 0.5F, size.z * 0.5F)
  let corners = [
    transform_point_3d(transform, @math.Vec3::new(-half.x, -half.y, -half.z)),
    transform_point_3d(transform, @math.Vec3::new(half.x, -half.y, -half.z)),
    transform_point_3d(transform, @math.Vec3::new(half.x, half.y, -half.z)),
    transform_point_3d(transform, @math.Vec3::new(-half.x, half.y, -half.z)),
    transform_point_3d(transform, @math.Vec3::new(-half.x, -half.y, half.z)),
    transform_point_3d(transform, @math.Vec3::new(half.x, -half.y, half.z)),
    transform_point_3d(transform, @math.Vec3::new(half.x, half.y, half.z)),
    transform_point_3d(transform, @math.Vec3::new(-half.x, half.y, half.z)),
  ]
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
    let (start_id, end_id) = edge
    gizmos_add_line_3d_with_config(
      self.state,
      self.config,
      corners[start_id],
      corners[end_id],
      color,
      color,
    )
  }
}

///|
pub fn[Config] Gizmos::curve_3d(
  self : Gizmos[Config],
  points : Array[@math.Vec3],
  color : Color,
) -> Unit {
  gizmos_linestrip_3d_with_config(self.state, self.config, points, color)
}

///|
pub fn[Config] Gizmos::curve_gradient_3d(
  self : Gizmos[Config],
  points : Array[(@math.Vec3, Color)],
) -> Unit {
  gizmos_linestrip_gradient_3d_with_config(self.state, self.config, points)
}

///|
pub fn[Config] Gizmos::text_3d(
  self : Gizmos[Config],
  isometry : @math.Isometry3d,
  text : String,
  font_size : Float,
  anchor : @math.Vec2,
  color : Color,
) -> Unit {
  stroke_text_emit_3d(
    self.state,
    self.config,
    isometry,
    text,
    font_size,
    anchor,
    color,
  )
}

///|
pub fn[Config] Gizmos::text_2d(
  self : Gizmos[Config],
  isometry : Isometry2d,
  text : String,
  font_size : Float,
  anchor : @math.Vec2,
  color : Color,
) -> Unit {
  stroke_text_emit_2d(
    self.state,
    self.config,
    isometry,
    text,
    font_size,
    anchor,
    color,
  )
}
