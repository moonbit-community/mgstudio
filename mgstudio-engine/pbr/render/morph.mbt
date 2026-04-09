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

// Bevy-aligned render module anchor.

///|
pub fn render3d_morph_weights_all_zero(weights : Array[Float]) -> Bool {
  for weight in weights {
    if weight != 0.0F {
      return false
    }
  }
  true
}

///|
pub fn render3d_normalize_morph_weights(weights : Array[Float]) -> Array[Float] {
  let normalized : Array[Float] = []
  let mut sum = 0.0F
  for weight in weights {
    let safe = if weight < 0.0F { 0.0F } else { weight }
    normalized.push(safe)
    sum = sum + safe
  }
  if sum <= 0.0F {
    return normalized
  }
  for index in 0..<normalized.length() {
    normalized[index] = normalized[index] / sum
  }
  normalized
}
