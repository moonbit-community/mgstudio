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
const DIRECTIONAL_NAVIGATION_NO_SCORE : Float = 1000000000000.0F

///|
pub struct DirectionalNavigationPlugin {}

///|
pub fn DirectionalNavigationPlugin::default() -> DirectionalNavigationPlugin {
  DirectionalNavigationPlugin::{  }
}

///|
pub impl @app.Plugin for DirectionalNavigationPlugin with name(_self) {
  "mgstudio.input_focus.DirectionalNavigationPlugin"
}

///|
pub impl @app.Plugin for DirectionalNavigationPlugin with build(_self, app) {
  directional_navigation_plugin(app)
}

///|
pub struct AutoNavigationConfig {
  min_alignment_factor : Float
  max_search_distance : Float?
  prefer_aligned : Bool
}

///|
pub fn AutoNavigationConfig::new(
  min_alignment_factor : Float,
  max_search_distance : Float?,
  prefer_aligned : Bool,
) -> AutoNavigationConfig {
  AutoNavigationConfig::{
    min_alignment_factor,
    max_search_distance,
    prefer_aligned,
  }
}

///|
pub fn AutoNavigationConfig::default() -> AutoNavigationConfig {
  AutoNavigationConfig::new(0.0F, None, true)
}

///|
pub fn AutoNavigationConfig::min_alignment_factor(
  self : AutoNavigationConfig,
) -> Float {
  self.min_alignment_factor
}

///|
pub fn AutoNavigationConfig::max_search_distance(
  self : AutoNavigationConfig,
) -> Float? {
  self.max_search_distance
}

///|
pub fn AutoNavigationConfig::prefer_aligned(
  self : AutoNavigationConfig,
) -> Bool {
  self.prefer_aligned
}

///|
pub struct NavNeighbors {
  north : @core.Entity?
  north_east : @core.Entity?
  east : @core.Entity?
  south_east : @core.Entity?
  south : @core.Entity?
  south_west : @core.Entity?
  west : @core.Entity?
  north_west : @core.Entity?
}

///|
pub fn NavNeighbors::default() -> NavNeighbors {
  NavNeighbors::{
    north: None,
    north_east: None,
    east: None,
    south_east: None,
    south: None,
    south_west: None,
    west: None,
    north_west: None,
  }
}

///|
pub fn NavNeighbors::get(
  self : NavNeighbors,
  octant : @math.CompassOctant,
) -> @core.Entity? {
  match octant {
    North => self.north
    NorthEast => self.north_east
    East => self.east
    SouthEast => self.south_east
    South => self.south
    SouthWest => self.south_west
    West => self.west
    NorthWest => self.north_west
  }
}

///|
pub fn NavNeighbors::set(
  self : NavNeighbors,
  octant : @math.CompassOctant,
  entity : @core.Entity,
) -> NavNeighbors {
  match octant {
    North => { ..self, north: Some(entity) }
    NorthEast => { ..self, north_east: Some(entity) }
    East => { ..self, east: Some(entity) }
    SouthEast => { ..self, south_east: Some(entity) }
    South => { ..self, south: Some(entity) }
    SouthWest => { ..self, south_west: Some(entity) }
    West => { ..self, west: Some(entity) }
    NorthWest => { ..self, north_west: Some(entity) }
  }
}

///|
pub struct DirectionalNavigationMap {
  neighbors : @hashmap.HashMap[(Int, Int), NavNeighbors]
}

///|
pub fn DirectionalNavigationMap::default() -> DirectionalNavigationMap {
  { neighbors: @hashmap.HashMap::new() }
}

///|
pub struct DirectionalNavigation {
  world : @ecs.World
}

///|
pub(all) suberror DirectionalNavigationError {
  NoFocus
  NoNeighborInDirection(@core.Entity, @math.CompassOctant)
}

///|
pub struct FocusableArea {
  entity : @core.Entity
  position : @math.Vec2
  size : @math.Vec2
}

///|
pub fn FocusableArea::new(
  entity : @core.Entity,
  position : @math.Vec2,
  size : @math.Vec2,
) -> FocusableArea {
  { entity, position, size }
}

///|
pub fn FocusableArea::entity(self : FocusableArea) -> @core.Entity {
  self.entity
}

///|
pub fn FocusableArea::position(self : FocusableArea) -> @math.Vec2 {
  self.position
}

///|
pub fn FocusableArea::size(self : FocusableArea) -> @math.Vec2 {
  self.size
}

///|
pub(open) trait Navigable {
  get_bounds(Self) -> (@math.Vec2, @math.Vec2)
}

///|
let auto_navigation_config_resource_key : @ecs.ResourceKey[AutoNavigationConfig] = @ecs.register_resource(
  debug_name="mgstudio_input_focus::AutoNavigationConfig",
)

///|
let directional_navigation_map_resource_key : @ecs.ResourceKey[
  DirectionalNavigationMap,
] = @ecs.register_resource(
  debug_name="mgstudio_input_focus::DirectionalNavigationMap",
)

///|
pub impl @app.Resource for AutoNavigationConfig with resource() {
  auto_navigation_config_resource_key
}

///|
pub impl @app.Resource for DirectionalNavigationMap with resource() {
  directional_navigation_map_resource_key
}

///|
fn directional_navigation_entity_key(entity : @core.Entity) -> (Int, Int) {
  (entity.id, entity.generation)
}

///|
fn directional_navigation_opposite(
  octant : @math.CompassOctant,
) -> @math.CompassOctant {
  match octant {
    North => South
    NorthEast => SouthWest
    East => West
    SouthEast => NorthWest
    South => North
    SouthWest => NorthEast
    West => East
    NorthWest => SouthEast
  }
}

///|
fn directional_navigation_without_entity(
  neighbors : NavNeighbors,
  entity : @core.Entity,
) -> NavNeighbors {
  let keep = fn(value : @core.Entity?) -> @core.Entity? {
    if value == Some(entity) {
      None
    } else {
      value
    }
  }
  NavNeighbors::{
    north: keep(neighbors.north),
    north_east: keep(neighbors.north_east),
    east: keep(neighbors.east),
    south_east: keep(neighbors.south_east),
    south: keep(neighbors.south),
    south_west: keep(neighbors.south_west),
    west: keep(neighbors.west),
    north_west: keep(neighbors.north_west),
  }
}

///|
pub fn DirectionalNavigationMap::remove(
  self : DirectionalNavigationMap,
  entity : @core.Entity,
) -> Unit {
  self.neighbors.remove(directional_navigation_entity_key(entity))
  let entries = self.neighbors.to_array()
  for entry in entries {
    let (key, neighbors) = entry
    self.neighbors.set(
      key,
      directional_navigation_without_entity(neighbors, entity),
    )
  }
}

///|
pub fn DirectionalNavigationMap::clear(self : DirectionalNavigationMap) -> Unit {
  self.neighbors.clear()
}

///|
pub fn DirectionalNavigationMap::add_edge(
  self : DirectionalNavigationMap,
  a : @core.Entity,
  b : @core.Entity,
  direction : @math.CompassOctant,
) -> Unit {
  let key = directional_navigation_entity_key(a)
  let neighbors = self.neighbors.get(key).unwrap_or(NavNeighbors::default())
  self.neighbors.set(key, neighbors.set(direction, b))
}

///|
pub fn DirectionalNavigationMap::add_symmetrical_edge(
  self : DirectionalNavigationMap,
  a : @core.Entity,
  b : @core.Entity,
  direction : @math.CompassOctant,
) -> Unit {
  self.add_edge(a, b, direction)
  self.add_edge(b, a, directional_navigation_opposite(direction))
}

///|
pub fn DirectionalNavigationMap::add_edges(
  self : DirectionalNavigationMap,
  entities : Array[@core.Entity],
  direction : @math.CompassOctant,
) -> Unit {
  if entities.length() < 2 {
    return
  }
  for i in 0..<(entities.length() - 1) {
    self.add_symmetrical_edge(entities[i], entities[i + 1], direction)
  }
}

///|
pub fn DirectionalNavigationMap::add_looping_edges(
  self : DirectionalNavigationMap,
  entities : Array[@core.Entity],
  direction : @math.CompassOctant,
) -> Unit {
  self.add_edges(entities, direction)
  if entities.length() >= 2 {
    self.add_symmetrical_edge(
      entities[entities.length() - 1],
      entities[0],
      direction,
    )
  }
}

///|
pub fn DirectionalNavigationMap::get_neighbor(
  self : DirectionalNavigationMap,
  focus : @core.Entity,
  octant : @math.CompassOctant,
) -> @core.Entity? {
  match self.neighbors.get(directional_navigation_entity_key(focus)) {
    Some(neighbors) => neighbors.get(octant)
    None => None
  }
}

///|
pub fn DirectionalNavigationMap::get_neighbors(
  self : DirectionalNavigationMap,
  entity : @core.Entity,
) -> NavNeighbors? {
  self.neighbors.get(directional_navigation_entity_key(entity))
}

///|
fn directional_navigation_map_value(
  world : @ecs.World,
) -> DirectionalNavigationMap {
  match
    (try world.get_resource(DirectionalNavigationMap::resource()) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(map) => map
    None => DirectionalNavigationMap::default()
  }
}

///|
fn directional_navigation_focus_ref_mut(
  world : @ecs.World,
) -> @ecs.ResourceMut[InputFocus]? {
  try world.get_resource_mut(InputFocus::resource()) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn directional_navigation_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn directional_navigation_max(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn directional_navigation_min(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn directional_navigation_calculate_1d_overlap(
  origin_pos : Float,
  origin_size : Float,
  candidate_pos : Float,
  candidate_size : Float,
) -> Float {
  let origin_min = origin_pos - origin_size / 2.0F
  let origin_max = origin_pos + origin_size / 2.0F
  let candidate_min = candidate_pos - candidate_size / 2.0F
  let candidate_max = candidate_pos + candidate_size / 2.0F
  let overlap = directional_navigation_max(
    directional_navigation_min(origin_max, candidate_max) -
    directional_navigation_max(origin_min, candidate_min),
    0.0F,
  )
  let max_overlap = directional_navigation_min(origin_size, candidate_size)
  if max_overlap > 0.0F {
    overlap / max_overlap
  } else {
    0.0F
  }
}

///|
fn directional_navigation_calculate_overlap(
  origin_pos : @math.Vec2,
  origin_size : @math.Vec2,
  candidate_pos : @math.Vec2,
  candidate_size : @math.Vec2,
  octant : @math.CompassOctant,
) -> Float {
  match octant {
    North | South =>
      directional_navigation_calculate_1d_overlap(
        origin_pos.x,
        origin_size.x,
        candidate_pos.x,
        candidate_size.x,
      )
    East | West =>
      directional_navigation_calculate_1d_overlap(
        origin_pos.y,
        origin_size.y,
        candidate_pos.y,
        candidate_size.y,
      )
    _ => 1.0F
  }
}

///|
fn directional_navigation_is_in_direction(
  origin : @math.Vec2,
  candidate : @math.Vec2,
  octant : @math.CompassOctant,
) -> Bool {
  let dx = candidate.x - origin.x
  let dy = candidate.y - origin.y
  match octant {
    North => dy < 0.0F && directional_navigation_abs(dx) <= -dy
    NorthEast => dx > 0.0F && dy < 0.0F
    East => dx > 0.0F && directional_navigation_abs(dy) <= dx
    SouthEast => dx > 0.0F && dy > 0.0F
    South => dy > 0.0F && directional_navigation_abs(dx) <= dy
    SouthWest => dx < 0.0F && dy > 0.0F
    West => dx < 0.0F && directional_navigation_abs(dy) <= -dx
    NorthWest => dx < 0.0F && dy < 0.0F
  }
}

///|
fn directional_navigation_direction_vector(
  octant : @math.CompassOctant,
) -> @math.Vec2 {
  match octant {
    North => @math.Vec2::new(0.0F, -1.0F)
    NorthEast => @math.Vec2::new(1.0F, -1.0F).normalize_or_zero()
    East => @math.Vec2::new(1.0F, 0.0F)
    SouthEast => @math.Vec2::new(1.0F, 1.0F).normalize_or_zero()
    South => @math.Vec2::new(0.0F, 1.0F)
    SouthWest => @math.Vec2::new(-1.0F, 1.0F).normalize_or_zero()
    West => @math.Vec2::new(-1.0F, 0.0F)
    NorthWest => @math.Vec2::new(-1.0F, -1.0F).normalize_or_zero()
  }
}

///|
fn directional_navigation_score_candidate(
  origin : FocusableArea,
  candidate : FocusableArea,
  octant : @math.CompassOctant,
  config : AutoNavigationConfig,
) -> Float {
  if !directional_navigation_is_in_direction(
      origin.position,
      candidate.position,
      octant,
    ) {
    return DIRECTIONAL_NAVIGATION_NO_SCORE
  }

  let overlap_factor = directional_navigation_calculate_overlap(
    origin.position,
    origin.size,
    candidate.position,
    candidate.size,
    octant,
  )
  if overlap_factor < config.min_alignment_factor {
    return DIRECTIONAL_NAVIGATION_NO_SCORE
  }

  let origin_half = origin.size.div_scalar(2.0F)
  let candidate_half = candidate.size.div_scalar(2.0F)
  let origin_min = origin.position.sub(origin_half)
  let origin_max = origin.position.add(origin_half)
  let candidate_min = candidate.position.sub(candidate_half)
  let candidate_max = candidate.position.add(candidate_half)
  let dx = directional_navigation_max(
    directional_navigation_max(
      candidate_min.x - origin_max.x,
      origin_min.x - candidate_max.x,
    ),
    0.0F,
  )
  let dy = directional_navigation_max(
    directional_navigation_max(
      candidate_min.y - origin_max.y,
      origin_min.y - candidate_max.y,
    ),
    0.0F,
  )
  let distance = @math.sqrt(dx * dx + dy * dy)
  match config.max_search_distance {
    Some(max_distance) if distance > max_distance =>
      return DIRECTIONAL_NAVIGATION_NO_SCORE
    _ => ()
  }

  let to_candidate = candidate.position.sub(origin.position)
  let center_distance = to_candidate.length()
  let alignment = if center_distance > 0.0F {
    to_candidate
    .normalize_or_zero()
    .dot(directional_navigation_direction_vector(octant))
  } else {
    1.0F
  }
  let alignment_penalty = if config.prefer_aligned {
    (1.0F - directional_navigation_max(alignment, 0.0F)) * distance * 2.0F
  } else {
    0.0F
  }
  distance + alignment_penalty
}

///|
fn directional_navigation_best_candidate(
  origin : FocusableArea,
  direction : @math.CompassOctant,
  candidates : Array[FocusableArea],
  config : AutoNavigationConfig,
) -> @core.Entity? {
  let mut best_score = DIRECTIONAL_NAVIGATION_NO_SCORE
  let mut best_candidate = None
  for candidate in candidates {
    if candidate.entity == origin.entity {
      continue
    }
    let score = directional_navigation_score_candidate(
      origin, candidate, direction, config,
    )
    if score < best_score {
      best_score = score
      best_candidate = Some(candidate.entity)
    }
  }
  best_candidate
}

///|
pub fn auto_generate_navigation_edges(
  nav_map : DirectionalNavigationMap,
  nodes : Array[FocusableArea],
  config : AutoNavigationConfig,
) -> Unit {
  let octants = [
    @math.CompassOctant::North,
    @math.CompassOctant::NorthEast,
    @math.CompassOctant::East,
    @math.CompassOctant::SouthEast,
    @math.CompassOctant::South,
    @math.CompassOctant::SouthWest,
    @math.CompassOctant::West,
    @math.CompassOctant::NorthWest,
  ]
  for origin in nodes {
    for octant in octants {
      if nav_map.get_neighbor(origin.entity, octant) is Some(_) {
        continue
      }
      if directional_navigation_best_candidate(origin, octant, nodes, config)
        is Some(best_candidate) {
        nav_map.add_edge(origin.entity, best_candidate, octant)
      }
    }
  }
}

///|
pub fn DirectionalNavigation::input_focus(
  self : DirectionalNavigation,
) -> @core.Entity? {
  match input_focus_world_resource(self.world, InputFocus::resource()) {
    Some(focus) => focus.get()
    None => None
  }
}

///|
pub fn DirectionalNavigation::navigate(
  self : DirectionalNavigation,
  direction : @math.CompassOctant,
) -> @core.Entity raise DirectionalNavigationError {
  guard directional_navigation_focus_ref_mut(self.world) is Some(focus) else {
    raise NoFocus
  }
  guard focus.peek().get() is Some(current_focus) else { raise NoFocus }
  if !self.world.is_alive(current_focus) {
    focus.modify(fn(value) { value.clear() })
    raise NoFocus
  }
  let map = directional_navigation_map_value(self.world)
  guard map.get_neighbor(current_focus, direction) is Some(new_focus) else {
    raise NoNeighborInDirection(current_focus, direction)
  }
  focus.modify(fn(value) { value.set(new_focus) })
  new_focus
}

///|
pub impl @app.SystemParam for DirectionalNavigation with init_state(world) {
  @app.system_param_empty_state(world)
}

///|
pub impl @app.SystemParam for DirectionalNavigation with get(_state) {
  DirectionalNavigation::{ world: current_input_focus_world_abort_missing() }
}

///|
pub impl @app.SystemParam for DirectionalNavigation with store(self, state) {
  @app.system_param_store_no_state(self, state)
}

///|
pub fn directional_navigation_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { DirectionalNavigationMap::default() })
  .init_resource(fn() { AutoNavigationConfig::default() })
}
