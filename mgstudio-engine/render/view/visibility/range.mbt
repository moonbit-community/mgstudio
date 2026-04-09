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
// Bevy source: `bevy/crates/bevy_render/src/view/visibility/range.rs`.

///|
pub fn visibility_range_new(
  start_margin_min : Float,
  start_margin_max : Float,
  end_margin_min : Float,
  end_margin_max : Float,
  use_aabb : Bool,
) -> @visibility.VisibilityRange {
  @visibility.VisibilityRange::new(
    start_margin_min, start_margin_max, end_margin_min, end_margin_max, use_aabb,
  )
}

///|
pub fn visibility_range_always_visible() -> @visibility.VisibilityRange {
  @visibility.VisibilityRange::always_visible()
}

///|
pub fn visibility_range_invisible() -> @visibility.VisibilityRange {
  @visibility.VisibilityRange::invisible()
}
