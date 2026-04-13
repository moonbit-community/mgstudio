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
// Bevy source: `bevy/crates/bevy_input_focus/src/navigator.rs`.

///|
const INPUT_FOCUS_NAVIGATOR_NO_SCORE : Float = 1000000000000.0F

///|
fn input_focus_navigator_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn input_focus_navigator_max(lhs : Float, rhs : Float) -> Float {
  if lhs > rhs {
    lhs
  } else {
    rhs
  }
}

///|
fn input_focus_navigator_is_in_direction(
  origin : @math.Vec2,
  candidate : @math.Vec2,
  octant : @math.CompassOctant,
) -> Bool {
  let dx = candidate.x - origin.x
  let dy = candidate.y - origin.y
  match octant {
    North => dy < 0.0F && input_focus_navigator_abs(dx) <= -dy
    NorthEast => dx > 0.0F && dy < 0.0F
    East => dx > 0.0F && input_focus_navigator_abs(dy) <= dx
    SouthEast => dx > 0.0F && dy > 0.0F
    South => dy > 0.0F && input_focus_navigator_abs(dx) <= dy
    SouthWest => dx < 0.0F && dy > 0.0F
    West => dx < 0.0F && input_focus_navigator_abs(dy) <= -dx
    NorthWest => dx < 0.0F && dy < 0.0F
  }
}

///|
fn input_focus_navigator_score(
  origin : FocusableArea,
  candidate : FocusableArea,
  octant : @math.CompassOctant,
  config : AutoNavigationConfig,
) -> Float {
  if !input_focus_navigator_is_in_direction(
      origin.position(),
      candidate.position(),
      octant,
    ) {
    return INPUT_FOCUS_NAVIGATOR_NO_SCORE
  }

  let to_candidate = candidate.position().sub(origin.position())
  let distance = to_candidate.length()
  match config.max_search_distance() {
    Some(max_distance) if distance > max_distance =>
      return INPUT_FOCUS_NAVIGATOR_NO_SCORE
    _ => ()
  }

  let direction_vector = match octant {
    North => @math.Vec2::new(0.0F, -1.0F)
    NorthEast => @math.Vec2::new(1.0F, -1.0F).normalize_or_zero()
    East => @math.Vec2::new(1.0F, 0.0F)
    SouthEast => @math.Vec2::new(1.0F, 1.0F).normalize_or_zero()
    South => @math.Vec2::new(0.0F, 1.0F)
    SouthWest => @math.Vec2::new(-1.0F, 1.0F).normalize_or_zero()
    West => @math.Vec2::new(-1.0F, 0.0F)
    NorthWest => @math.Vec2::new(-1.0F, -1.0F).normalize_or_zero()
  }
  let alignment = if distance <= 0.0F {
    1.0F
  } else {
    to_candidate.normalize_or_zero().dot(direction_vector)
  }
  let alignment_penalty = if config.prefer_aligned() {
    (1.0F - input_focus_navigator_max(alignment, 0.0F)) * distance * 2.0F
  } else {
    0.0F
  }
  distance + alignment_penalty
}

///|
pub fn find_best_candidate(
  origin : FocusableArea,
  direction : @math.CompassOctant,
  candidates : Array[FocusableArea],
  config : AutoNavigationConfig,
) -> @core.Entity? {
  let mut best_score = INPUT_FOCUS_NAVIGATOR_NO_SCORE
  let mut best_candidate = None
  for candidate in candidates {
    if candidate.entity() == origin.entity() {
      continue
    }
    let score = input_focus_navigator_score(
      origin, candidate, direction, config,
    )
    if score < best_score {
      best_score = score
      best_candidate = Some(candidate.entity())
    }
  }
  best_candidate
}
