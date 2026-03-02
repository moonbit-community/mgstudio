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
/// Legacy ECS component types.
pub let ecs_components : Array[String] = [
  "AnimatedBy", "AnimationPlayer", "AnimationWeights", "AnimationTargetId", "AnimationGraphHandle",
  "AnimationTransitions",
]

///|
/// Legacy ECS resource types.
pub let ecs_resources : Array[String] = []

///|
pub(open) trait Has_AnimatedBy {
  get_animated_by_store(self : Self) -> @core.ComponentStore[AnimatedBy]
}

///|
pub(open) trait Has_AnimationPlayer {
  get_animation_player_store(self : Self) -> @core.ComponentStore[
    AnimationPlayer,
  ]
}

///|
pub(open) trait Has_AnimationWeights {
  get_animation_weights_store(self : Self) -> @core.ComponentStore[
    AnimationWeights,
  ]
}

///|
pub(open) trait Has_AnimationTargetId {
  get_animation_target_id_store(self : Self) -> @core.ComponentStore[
    AnimationTargetId,
  ]
}

///|
pub(open) trait Has_AnimationGraphHandle {
  get_animation_graph_handle_store(self : Self) -> @core.ComponentStore[
    AnimationGraphHandle,
  ]
}

///|
pub(open) trait Has_AnimationTransitions {
  get_animation_transitions_store(self : Self) -> @core.ComponentStore[
    AnimationTransitions,
  ]
}

///|
pub fn[W : Has_AnimatedBy] query_get_animated_by_store(
  world : W,
) -> @core.ComponentStore[AnimatedBy] {
  world.get_animated_by_store()
}

///|
pub fn[W : Has_AnimationPlayer] query_get_animation_player_store(
  world : W,
) -> @core.ComponentStore[AnimationPlayer] {
  world.get_animation_player_store()
}

///|
pub fn[W : Has_AnimationWeights] query_get_animation_weights_store(
  world : W,
) -> @core.ComponentStore[AnimationWeights] {
  world.get_animation_weights_store()
}

///|
pub fn[W : Has_AnimationTargetId] query_get_animation_target_id_store(
  world : W,
) -> @core.ComponentStore[AnimationTargetId] {
  world.get_animation_target_id_store()
}

///|
pub fn[W : Has_AnimationGraphHandle] query_get_animation_graph_handle_store(
  world : W,
) -> @core.ComponentStore[AnimationGraphHandle] {
  world.get_animation_graph_handle_store()
}

///|
pub fn[W : Has_AnimationTransitions] query_get_animation_transitions_store(
  world : W,
) -> @core.ComponentStore[AnimationTransitions] {
  world.get_animation_transitions_store()
}

///|
/// ECS bridge impls for @ecs.World (auto-generated).

///|
let bridge_get_animated_by_store_by_world : Map[
  Int,
  @core.ComponentStore[AnimatedBy],
] = {}

///|
pub impl Has_AnimatedBy for @ecs.World with get_animated_by_store(self) {
  bridge_get_animated_by_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_animation_player_store_by_world : Map[
  Int,
  @core.ComponentStore[AnimationPlayer],
] = {}

///|
pub impl Has_AnimationPlayer for @ecs.World with get_animation_player_store(
  self,
) {
  bridge_get_animation_player_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_animation_weights_store_by_world : Map[
  Int,
  @core.ComponentStore[AnimationWeights],
] = {}

///|
pub impl Has_AnimationWeights for @ecs.World with get_animation_weights_store(
  self,
) {
  bridge_get_animation_weights_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_animation_target_id_store_by_world : Map[
  Int,
  @core.ComponentStore[AnimationTargetId],
] = {}

///|
pub impl Has_AnimationTargetId for @ecs.World with get_animation_target_id_store(
  self,
) {
  bridge_get_animation_target_id_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_animation_graph_handle_store_by_world : Map[
  Int,
  @core.ComponentStore[AnimationGraphHandle],
] = {}

///|
pub impl Has_AnimationGraphHandle for @ecs.World with get_animation_graph_handle_store(
  self,
) {
  bridge_get_animation_graph_handle_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_animation_transitions_store_by_world : Map[
  Int,
  @core.ComponentStore[AnimationTransitions],
] = {}

///|
pub impl Has_AnimationTransitions for @ecs.World with get_animation_transitions_store(
  self,
) {
  bridge_get_animation_transitions_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
/// End ECS bridge impls.
