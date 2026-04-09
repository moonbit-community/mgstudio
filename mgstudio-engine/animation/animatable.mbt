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
// Bevy source: `bevy/crates/bevy_animation/src/animatable.rs`.
// Runtime wrappers live in this file while the broader animation implementation stays split across the package.

///|
pub fn animation_translation_keyframe(
  time : Float,
  value : @math.Vec3,
) -> KeyframeVec3 {
  KeyframeVec3::new(time, value)
}

///|
pub fn animation_rotation_keyframe(
  time : Float,
  value : @math.Quat,
) -> KeyframeQuat {
  KeyframeQuat::new(time, value)
}

///|
pub fn animation_scale_keyframe(
  time : Float,
  value : @math.Vec3,
) -> KeyframeVec3 {
  KeyframeVec3::new(time, value)
}
