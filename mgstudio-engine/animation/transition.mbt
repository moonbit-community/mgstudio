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
// Bevy source: `bevy/crates/bevy_animation/src/transition.rs`.
// Transition runtime and blend-down bookkeeping.

///|
pub struct AnimationTransition {
  mut current_weight : Float
  weight_decline_per_sec : Float
  animation : AnimationNodeIndex
}

///|
pub impl ToJson for AnimationTransition with to_json(self) {
  (self.current_weight, self.weight_decline_per_sec, self.animation).to_json()
}

///|
pub impl @json.FromJson for AnimationTransition with from_json(json, path) {
  let (current_weight, weight_decline_per_sec, animation) : (
    Float,
    Float,
    AnimationNodeIndex,
  ) = @json.from_json(json, path~)
  AnimationTransition::{ current_weight, weight_decline_per_sec, animation }
}

///|
fn animation_transition_new(
  current_weight : Float,
  weight_decline_per_sec : Float,
  animation : AnimationNodeIndex,
) -> AnimationTransition {
  AnimationTransition::{ current_weight, weight_decline_per_sec, animation }
}

///|
pub struct AnimationTransitions {
  mut main_animation : AnimationNodeIndex?
  transitions : Array[AnimationTransition]
}

///|
pub impl ToJson for AnimationTransitions with to_json(self) {
  (self.main_animation, self.transitions).to_json()
}

///|
pub impl @json.FromJson for AnimationTransitions with from_json(json, path) {
  let (main_animation, transitions) : (
    AnimationNodeIndex?,
    Array[AnimationTransition],
  ) = @json.from_json(json, path~)
  AnimationTransitions::{ main_animation, transitions }
}

///|
pub fn AnimationTransitions::new() -> AnimationTransitions {
  AnimationTransitions::{ main_animation: None, transitions: [] }
}

///|
pub fn AnimationTransitions::main_animation(
  self : AnimationTransitions,
) -> AnimationNodeIndex? {
  self.main_animation
}

///|
pub fn AnimationTransitions::get_main_animation(
  self : AnimationTransitions,
) -> AnimationNodeIndex? {
  self.main_animation()
}

///|
fn animation_transitions_remove_for_animation(
  transitions : AnimationTransitions,
  node : AnimationNodeIndex,
) -> Unit {
  let kept : Array[AnimationTransition] = []
  for transition in transitions.transitions {
    if transition.animation != node {
      kept.push(transition)
    }
  }
  transitions.transitions.clear()
  for transition in kept {
    transitions.transitions.push(transition)
  }
}

///|
pub fn AnimationTransitions::play(
  self : AnimationTransitions,
  player : AnimationPlayer,
  new_animation : AnimationNodeIndex,
  transition_duration_seconds : Float,
) -> AnimationPlayerEntry {
  if self.main_animation is Some(old_animation) {
    if player.animation(old_animation) is Some(old_active) {
      if !old_active.is_paused() {
        self.transitions.push(
          animation_transition_new(
            old_active.weight(),
            1.0F / transition_duration_seconds,
            old_animation,
          ),
        )
      }
    }
  }

  self.main_animation = Some(new_animation)
  animation_transitions_remove_for_animation(self, new_animation)
  player.start(new_animation)
}

///|
fn animation_transitions_advance(
  transitions : AnimationTransitions,
  player : AnimationPlayer,
  delta_seconds : Float,
) -> (AnimationTransitions, AnimationPlayer) {
  let mut next_player = player
  let mut remaining_weight = 1.0F
  let mut i = transitions.transitions.length() - 1
  while i >= 0 && i < transitions.transitions.length() {
    let transition = transitions.transitions[i]
    transition.current_weight = transition.current_weight -
      transition.weight_decline_per_sec * delta_seconds
    if transition.current_weight < 0.0F {
      transition.current_weight = 0.0F
    }

    if next_player.animation(transition.animation) is Some(active) {
      let weight = transition.current_weight * remaining_weight
      next_player = next_player.set_animation(
        transition.animation,
        active.set_weight(weight),
      )
      remaining_weight = remaining_weight - weight
      if remaining_weight < 0.0F {
        remaining_weight = 0.0F
      }
    }

    if i == 0 {
      break
    }
    i = i - 1
  }

  if transitions.main_animation is Some(main_animation) {
    if next_player.animation(main_animation) is Some(active) {
      next_player = next_player.set_animation(
        main_animation,
        active.set_weight(remaining_weight),
      )
    }
  }

  (transitions, next_player)
}

///|
fn animation_transitions_expire(
  transitions : AnimationTransitions,
  player : AnimationPlayer,
) -> (AnimationTransitions, AnimationPlayer) {
  let mut next_player = player
  let kept : Array[AnimationTransition] = []
  for transition in transitions.transitions {
    if transition.current_weight <= 0.0F {
      next_player = next_player.stop(transition.animation)
    } else {
      kept.push(transition)
    }
  }
  transitions.transitions.clear()
  for transition in kept {
    transitions.transitions.push(transition)
  }
  (transitions, next_player)
}

///|
pub fn advance_transitions(world : @ecs.World) -> Unit {
  let delta_seconds = animation_default_time_or_default(world).delta_seconds()

  let updates : Array[(@core.Entity, AnimationTransitions, AnimationPlayer)] = []
  let transitions_query : @ecs.Query[@ecs.Comp[AnimationTransitions], @ecs.All] = @ecs.query(
    world,
  )
  try! transitions_query.view(fn(entity, transitions) {
    guard (try! world.get_by_key(entity, ecs_key_animation_player))
      is Some(player) else {
      return
    }
    let (next_transitions, next_player) = animation_transitions_advance(
      transitions.value(),
      player,
      delta_seconds,
    )
    updates.push((entity, next_transitions, next_player))
  })

  for update in updates {
    try! world.set_by_key(update.0, ecs_key_animation_transitions, update.1)
    try! world.set_by_key(update.0, ecs_key_animation_player, update.2)
  }
}

///|
pub fn expire_completed_transitions(world : @ecs.World) -> Unit {
  let updates : Array[(@core.Entity, AnimationTransitions, AnimationPlayer)] = []
  let transitions_query : @ecs.Query[@ecs.Comp[AnimationTransitions], @ecs.All] = @ecs.query(
    world,
  )
  try! transitions_query.view(fn(entity, transitions) {
    guard (try! world.get_by_key(entity, ecs_key_animation_player))
      is Some(player) else {
      return
    }
    let (next_transitions, next_player) = animation_transitions_expire(
      transitions.value(),
      player,
    )
    updates.push((entity, next_transitions, next_player))
  })

  for update in updates {
    try! world.set_by_key(update.0, ecs_key_animation_transitions, update.1)
    try! world.set_by_key(update.0, ecs_key_animation_player, update.2)
  }
}

///|
pub fn expire_transitions(world : @ecs.World) -> Unit {
  expire_completed_transitions(world)
}

///|
pub fn animation_transitions() -> AnimationTransitions {
  AnimationTransitions::new()
}

///|
pub fn animation_transitions_play(
  transitions : AnimationTransitions,
  player : AnimationPlayer,
  node : AnimationNodeIndex,
  duration_seconds : Float,
) -> AnimationPlayerEntry {
  transitions.play(player, node, duration_seconds)
}
