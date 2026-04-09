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
// Bevy source: `bevy/crates/bevy_render/src/view/mod.rs`.

///|
pub type Msaa = @core_pipeline.Msaa

///|
pub type Visibility = @visibility.Visibility

///|
pub type InheritedVisibility = @visibility.InheritedVisibility

///|
pub type ViewVisibility = @visibility.ViewVisibility

///|
pub type NoFrustumCulling = @visibility.NoFrustumCulling

///|
pub type VisibilityRange = @visibility.VisibilityRange

///|
pub fn view_visibility_range_always_visible() -> VisibilityRange {
  @visibility.VisibilityRange::always_visible()
}

///|
pub fn view_visibility_range_invisible() -> VisibilityRange {
  @visibility.VisibilityRange::invisible()
}
