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
// Bevy source: `bevy/crates/bevy_animation/src/animation_curves.rs`.
// Runtime wrappers live in this file while the broader animation implementation stays split across the package.

///|
pub fn animation_clip_add_animatable_curve(
  clip : AnimationClip,
  target_id : AnimationTargetId,
  curve : AnimatableCurve,
  sample_count? : Int = 121,
) -> AnimationClip {
  clip.add_curve_to_target(target_id, curve, sample_count~)
}

///|
pub fn animation_clip_sample(
  clip : AnimationClip,
  target_id : AnimationTargetId,
  time_seconds : Float,
) -> AnimationSample? {
  clip.sample_target(target_id, time_seconds)
}
