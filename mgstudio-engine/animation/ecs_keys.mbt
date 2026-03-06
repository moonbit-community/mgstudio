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
pub let ecs_key_animation_target_id : @ecs.ComponentKey[AnimationTargetId] = @ecs.register_component(
  debug_name="animation.animation_target_id",
)

///|
pub let ecs_key_animated_by : @ecs.ComponentKey[AnimatedBy] = @ecs.register_component(
  debug_name="animation.animated_by",
)

///|
pub let ecs_key_animation_player : @ecs.ComponentKey[AnimationPlayer] = @ecs.register_component(
  debug_name="animation.animation_player",
)

///|
pub impl @ecs.Component for AnimationTargetId with component() {
  ecs_key_animation_target_id
}

///|
pub impl @ecs.Component for AnimatedBy with component() {
  ecs_key_animated_by
}

///|
pub impl @ecs.Component for AnimationPlayer with component() {
  ecs_key_animation_player
}
