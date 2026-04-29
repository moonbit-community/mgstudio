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
// Bevy source: `bevy/crates/bevy_animation/src/morph.rs`.
// Morph weights runtime data and helpers.

///|
pub struct AnimationWeights {
  values : Array[Float]
}

///|
pub impl ToJson for AnimationWeights with to_json(self) {
  self.values.to_json()
}

///|
pub impl @json.FromJson for AnimationWeights with from_json(json, path) {
  AnimationWeights::new(@json.from_json(json, path~))
}

///|
pub fn AnimationWeights::new(values : Array[Float]) -> AnimationWeights {
  AnimationWeights::{ values, }
}

///|
pub fn AnimationWeights::values(self : AnimationWeights) -> Array[Float] {
  self.values
}

///|
pub fn animation_weights(values : Array[Float]) -> AnimationWeights {
  AnimationWeights::new(values)
}

///|
pub fn animation_clip_add_morph_weights_curve(
  clip : AnimationClip,
  target_id : AnimationTargetId,
  keyframes : Array[KeyframeWeights],
) -> AnimationClip {
  clip.add_weights_curve(target_id, keyframes)
}
