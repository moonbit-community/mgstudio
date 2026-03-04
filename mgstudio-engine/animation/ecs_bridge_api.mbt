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
pub(open) trait Has_AnimatedBy {
  get_animated_by_store(self : Self) -> @ecs.ComponentAccess[AnimatedBy]
}

///|
pub(open) trait Has_AnimationPlayer {
  get_animation_player_store(self : Self) -> @ecs.ComponentAccess[
    AnimationPlayer,
  ]
}

///|
pub(open) trait Has_AnimationWeights {
  get_animation_weights_store(self : Self) -> @ecs.ComponentAccess[
    AnimationWeights,
  ]
}

///|
pub(open) trait Has_AnimationTargetId {
  get_animation_target_id_store(self : Self) -> @ecs.ComponentAccess[
    AnimationTargetId,
  ]
}

///|
pub(open) trait Has_AnimationGraphHandle {
  get_animation_graph_handle_store(self : Self) -> @ecs.ComponentAccess[
    AnimationGraphHandle,
  ]
}

///|
pub(open) trait Has_AnimationTransitions {
  get_animation_transitions_store(self : Self) -> @ecs.ComponentAccess[
    AnimationTransitions,
  ]
}

///|
pub fn[W : Has_AnimatedBy] get_animated_by_store(
  world : W,
) -> @ecs.ComponentAccess[AnimatedBy] {
  world.get_animated_by_store()
}

///|
pub fn[W : Has_AnimationPlayer] get_animation_player_store(
  world : W,
) -> @ecs.ComponentAccess[AnimationPlayer] {
  world.get_animation_player_store()
}

///|
pub fn[W : Has_AnimationWeights] get_animation_weights_store(
  world : W,
) -> @ecs.ComponentAccess[AnimationWeights] {
  world.get_animation_weights_store()
}

///|
pub fn[W : Has_AnimationTargetId] get_animation_target_id_store(
  world : W,
) -> @ecs.ComponentAccess[AnimationTargetId] {
  world.get_animation_target_id_store()
}

///|
pub fn[W : Has_AnimationGraphHandle] get_animation_graph_handle_store(
  world : W,
) -> @ecs.ComponentAccess[AnimationGraphHandle] {
  world.get_animation_graph_handle_store()
}

///|
pub fn[W : Has_AnimationTransitions] get_animation_transitions_store(
  world : W,
) -> @ecs.ComponentAccess[AnimationTransitions] {
  world.get_animation_transitions_store()
}

///|
/// ECS bridge impls for @ecs.World.

///|
pub impl Has_AnimatedBy for @ecs.World with get_animated_by_store(self) {
  self.component(ecs_key_animated_by)
}

///|
pub impl Has_AnimationPlayer for @ecs.World with get_animation_player_store(
  self,
) {
  self.component(ecs_key_animation_player)
}

///|
pub impl Has_AnimationWeights for @ecs.World with get_animation_weights_store(
  self,
) {
  self.component(ecs_key_animation_weights)
}

///|
pub impl Has_AnimationTargetId for @ecs.World with get_animation_target_id_store(
  self,
) {
  self.component(ecs_key_animation_target_id)
}

///|
pub impl Has_AnimationGraphHandle for @ecs.World with get_animation_graph_handle_store(
  self,
) {
  self.component(ecs_key_animation_graph_handle)
}

///|
pub impl Has_AnimationTransitions for @ecs.World with get_animation_transitions_store(
  self,
) {
  self.component(ecs_key_animation_transitions)
}

///|
/// End ECS bridge impls.
