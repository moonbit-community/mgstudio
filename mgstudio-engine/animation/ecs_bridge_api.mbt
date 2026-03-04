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
/// ECS component bridge types.
pub let ecs_components : Array[String] = [
  "AnimatedBy", "AnimationPlayer", "AnimationWeights", "AnimationTargetId", "AnimationGraphHandle",
  "AnimationTransitions",
]

///|
/// ECS resource bridge types.
pub let ecs_resources : Array[String] = []

///|
pub fn get_animated_by_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[AnimatedBy] {
  world.component(ecs_key_animated_by)
}

///|
pub fn get_animation_player_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[AnimationPlayer] {
  world.component(ecs_key_animation_player)
}

///|
pub fn get_animation_weights_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[AnimationWeights] {
  world.component(ecs_key_animation_weights)
}

///|
pub fn get_animation_target_id_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[AnimationTargetId] {
  world.component(ecs_key_animation_target_id)
}

///|
pub fn get_animation_graph_handle_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[AnimationGraphHandle] {
  world.component(ecs_key_animation_graph_handle)
}

///|
pub fn get_animation_transitions_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[AnimationTransitions] {
  world.component(ecs_key_animation_transitions)
}
