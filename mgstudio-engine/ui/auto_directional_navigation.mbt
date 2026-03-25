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
pub struct AutoDirectionalNavigation {
  respect_tab_order : Bool
} derive(ToJson, FromJson)

///|
pub fn AutoDirectionalNavigation::default() -> AutoDirectionalNavigation {
  { respect_tab_order: false }
}

///|
pub struct AutoDirectionalNavigator {
  world : @ecs.World
}

///|
let ecs_key_auto_directional_navigation : @ecs.ComponentKey[
  AutoDirectionalNavigation,
] = @ecs.register_component(
  debug_name="bevy_ui::auto_directional_navigation::AutoDirectionalNavigation",
)

///|
pub impl @ecs.Component for AutoDirectionalNavigation with component() {
  ecs_key_auto_directional_navigation
}

///|
fn current_auto_directional_navigation_world_abort_missing() -> @ecs.World {
  match @app.current_world() {
    Some(world) => world
    None =>
      abort(
        "AutoDirectionalNavigator requires an active app world; use direct world/resource access outside scheduled systems",
      )
  }
}

///|
fn auto_directional_navigation_focus_ref_mut(
  world : @ecs.World,
) -> Ref[@input_focus.InputFocus]? {
  try world.get_resource_ref_mut(@input_focus.InputFocus::resource()) catch {
    _ => (None : Ref[@input_focus.InputFocus]?)
  } noraise {
    value => value
  }
}

///|
fn auto_directional_navigation_map(
  world : @ecs.World,
) -> @input_focus.DirectionalNavigationMap {
  let map : @input_focus.DirectionalNavigationMap? = try
    world.get_resource(@input_focus.DirectionalNavigationMap::resource())
  catch {
    _ => None
  } noraise {
    value => value
  }
  match map {
    Some(map) => map
    None => @input_focus.DirectionalNavigationMap::default()
  }
}

///|
fn auto_directional_navigation_config(
  world : @ecs.World,
) -> @input_focus.AutoNavigationConfig {
  let config : @input_focus.AutoNavigationConfig? = try
    world.get_resource(@input_focus.AutoNavigationConfig::resource())
  catch {
    _ => None
  } noraise {
    value => value
  }
  match config {
    Some(config) => config
    None => @input_focus.AutoNavigationConfig::default()
  }
}

///|
fn auto_directional_navigation_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn auto_directional_navigation_max(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn auto_directional_navigation_min(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn auto_directional_navigation_calculate_1d_overlap(
  origin_pos : Float,
  origin_size : Float,
  candidate_pos : Float,
  candidate_size : Float,
) -> Float {
  let origin_min = origin_pos - origin_size / 2.0F
  let origin_max = origin_pos + origin_size / 2.0F
  let candidate_min = candidate_pos - candidate_size / 2.0F
  let candidate_max = candidate_pos + candidate_size / 2.0F
  let overlap = auto_directional_navigation_max(
    auto_directional_navigation_min(origin_max, candidate_max) -
    auto_directional_navigation_max(origin_min, candidate_min),
    0.0F,
  )
  let max_overlap = auto_directional_navigation_min(origin_size, candidate_size)
  if max_overlap > 0.0F {
    overlap / max_overlap
  } else {
    0.0F
  }
}

///|
fn auto_directional_navigation_calculate_overlap(
  origin_pos : @math.Vec2,
  origin_size : @math.Vec2,
  candidate_pos : @math.Vec2,
  candidate_size : @math.Vec2,
  octant : @math.CompassOctant,
) -> Float {
  match octant {
    North | South =>
      auto_directional_navigation_calculate_1d_overlap(
        origin_pos.x,
        origin_size.x,
        candidate_pos.x,
        candidate_size.x,
      )
    East | West =>
      auto_directional_navigation_calculate_1d_overlap(
        origin_pos.y,
        origin_size.y,
        candidate_pos.y,
        candidate_size.y,
      )
    _ => 1.0F
  }
}

///|
fn auto_directional_navigation_is_in_direction(
  origin : @math.Vec2,
  candidate : @math.Vec2,
  octant : @math.CompassOctant,
) -> Bool {
  let dx = candidate.x - origin.x
  let dy = candidate.y - origin.y
  match octant {
    North => dy < 0.0F && auto_directional_navigation_abs(dx) <= -dy
    NorthEast => dx > 0.0F && dy < 0.0F
    East => dx > 0.0F && auto_directional_navigation_abs(dy) <= dx
    SouthEast => dx > 0.0F && dy > 0.0F
    South => dy > 0.0F && auto_directional_navigation_abs(dx) <= dy
    SouthWest => dx < 0.0F && dy > 0.0F
    West => dx < 0.0F && auto_directional_navigation_abs(dy) <= -dx
    NorthWest => dx < 0.0F && dy < 0.0F
  }
}

///|
fn auto_directional_navigation_direction_vector(
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
fn auto_directional_navigation_score_candidate(
  origin : @input_focus.FocusableArea,
  candidate : @input_focus.FocusableArea,
  octant : @math.CompassOctant,
  config : @input_focus.AutoNavigationConfig,
) -> Float {
  if !auto_directional_navigation_is_in_direction(
      origin.position(),
      candidate.position(),
      octant,
    ) {
    return 1000000000000.0F
  }

  let overlap_factor = auto_directional_navigation_calculate_overlap(
    origin.position(),
    origin.size(),
    candidate.position(),
    candidate.size(),
    octant,
  )
  if overlap_factor < config.min_alignment_factor() {
    return 1000000000000.0F
  }

  let origin_half = origin.size().div_scalar(2.0F)
  let candidate_half = candidate.size().div_scalar(2.0F)
  let origin_min = origin.position().sub(origin_half)
  let origin_max = origin.position().add(origin_half)
  let candidate_min = candidate.position().sub(candidate_half)
  let candidate_max = candidate.position().add(candidate_half)
  let dx = auto_directional_navigation_max(
    auto_directional_navigation_max(
      candidate_min.x - origin_max.x,
      origin_min.x - candidate_max.x,
    ),
    0.0F,
  )
  let dy = auto_directional_navigation_max(
    auto_directional_navigation_max(
      candidate_min.y - origin_max.y,
      origin_min.y - candidate_max.y,
    ),
    0.0F,
  )
  let distance = @math.sqrt(dx * dx + dy * dy)
  match config.max_search_distance() {
    Some(max_distance) if distance > max_distance => return 1000000000000.0F
    _ => ()
  }

  let to_candidate = candidate.position().sub(origin.position())
  let center_distance = to_candidate.length()
  let alignment = if center_distance > 0.0F {
    to_candidate
    .normalize_or_zero()
    .dot(auto_directional_navigation_direction_vector(octant))
  } else {
    1.0F
  }
  let alignment_penalty = if config.prefer_aligned() {
    (1.0F - auto_directional_navigation_max(alignment, 0.0F)) * distance * 2.0F
  } else {
    0.0F
  }
  distance + alignment_penalty
}

///|
fn auto_directional_navigation_best_candidate(
  origin : @input_focus.FocusableArea,
  direction : @math.CompassOctant,
  candidates : Array[@input_focus.FocusableArea],
  config : @input_focus.AutoNavigationConfig,
) -> @core.Entity? {
  let mut best_score = 1000000000000.0F
  let mut best_candidate : @core.Entity? = None
  for candidate in candidates {
    if candidate.entity() == origin.entity() {
      continue
    }
    let score = auto_directional_navigation_score_candidate(
      origin, candidate, direction, config,
    )
    if score < best_score {
      best_score = score
      best_candidate = Some(candidate.entity())
    }
  }
  best_candidate
}

///|
fn auto_directional_navigation_area_query(
  world : @ecs.World,
) -> @ecs.Query[
  (@core.Entity, @ecs.Comp[AutoDirectionalNavigation], @ecs.Comp[UiLayout]),
  @ecs.All,
] {
  @ecs.query(world)
}

///|
fn auto_directional_navigation_focusable_area(
  world : @ecs.World,
  entity : @core.Entity,
) -> (@core.Entity?, @input_focus.FocusableArea)? {
  let query = auto_directional_navigation_area_query(world)
  guard (try! query.get(entity)) is Some((_query_entity, _marker, layout)) else {
    return None
  }
  let inherited_visibility : @visibility.InheritedVisibility? = try
    world.entity(entity).get()
  catch {
    _ => None
  } noraise {
    value => value
  }
  match inherited_visibility {
    Some(visibility) if !visibility.is_visible() => None
    _ => {
      let target_camera : ComputedUiTargetCamera? = try
        world.entity(entity).get()
      catch {
        _ => None
      } noraise {
        value => value
      }
      Some(
        (
          match target_camera {
            Some(camera) => camera.get()
            None => None
          },
          @input_focus.FocusableArea::new(
            entity,
            layout.value().rect.center(),
            layout.value().rect.size(),
          ),
        ),
      )
    }
  }
}

///|
fn auto_directional_navigation_candidates(
  world : @ecs.World,
  target_camera : @core.Entity?,
) -> Array[@input_focus.FocusableArea] {
  let candidates : Array[@input_focus.FocusableArea] = []
  let query = auto_directional_navigation_area_query(world)
  try! query.view(fn(_query_entity, data) {
    let (entity, _marker, layout) = data
    let inherited_visibility : @visibility.InheritedVisibility? = try
      world.entity(entity).get()
    catch {
      _ => None
    } noraise {
      value => value
    }
    match inherited_visibility {
      Some(visibility) if !visibility.is_visible() => return
      _ => ()
    }
    let computed_camera : ComputedUiTargetCamera? = try
      world.entity(entity).get()
    catch {
      _ => None
    } noraise {
      value => value
    }
    let entity_camera = match computed_camera {
      Some(camera) => camera.get()
      None => None
    }
    if target_camera is Some(required_camera) &&
      entity_camera != Some(required_camera) {
      return
    }
    candidates.push(
      @input_focus.FocusableArea::new(
        entity,
        layout.value().rect.center(),
        layout.value().rect.size(),
      ),
    )
  })
  candidates
}

///|
pub fn AutoDirectionalNavigator::input_focus(
  self : AutoDirectionalNavigator,
) -> @core.Entity? {
  let focus : @input_focus.InputFocus? = try
    self.world.get_resource(@input_focus.InputFocus::resource())
  catch {
    _ => None
  } noraise {
    value => value
  }
  match focus {
    Some(focus) => focus.get()
    None => None
  }
}

///|
pub fn AutoDirectionalNavigator::navigate(
  self : AutoDirectionalNavigator,
  direction : @math.CompassOctant,
) -> @core.Entity raise @input_focus.DirectionalNavigationError {
  guard auto_directional_navigation_focus_ref_mut(self.world) is Some(focus_ref) else {
    raise @input_focus.NoFocus
  }
  guard focus_ref.val.get() is Some(current_focus) else {
    raise @input_focus.NoFocus
  }
  if !self.world.is_alive(current_focus) {
    focus_ref.val.clear()
    raise @input_focus.NoFocus
  }

  let manual_map = auto_directional_navigation_map(self.world)
  if manual_map.get_neighbor(current_focus, direction) is Some(new_focus) {
    focus_ref.val.set(new_focus)
    return new_focus
  }

  guard auto_directional_navigation_focusable_area(self.world, current_focus)
    is Some((target_camera, origin)) else {
    raise @input_focus.NoNeighborInDirection(current_focus, direction)
  }
  let config = auto_directional_navigation_config(self.world)
  let candidates = auto_directional_navigation_candidates(
    self.world,
    target_camera,
  )
  guard auto_directional_navigation_best_candidate(
      origin, direction, candidates, config,
    )
    is Some(new_focus) else {
    raise @input_focus.NoNeighborInDirection(current_focus, direction)
  }
  focus_ref.val.set(new_focus)
  new_focus
}

///|
pub impl @app.SystemParam for AutoDirectionalNavigator with init_state(world) {
  @app.system_param_empty_state(world)
}

///|
pub impl @app.SystemParam for AutoDirectionalNavigator with get(_state) {
  AutoDirectionalNavigator::{
    world: current_auto_directional_navigation_world_abort_missing(),
  }
}

///|
pub impl @app.SystemParam for AutoDirectionalNavigator with store(self, state) {
  @app.system_param_store_no_state(self, state)
}
