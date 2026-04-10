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
// Bevy source: `bevy/crates/bevy_material/src/labels.rs`.
// Bridge constants for material pipeline labels.

///|
pub const MATERIAL_PIPELINE_LABEL : String = "bevy_material::pipeline"

///|
pub const MATERIAL_BIND_GROUP_LABEL : String = "bevy_material::bind_group"

///|
pub const MATERIAL_LABELS_MODULE_TAG : String = "bevy_material::labels"

///|
pub fn material_labels_runtime_tag() -> String {
  MATERIAL_LABELS_MODULE_TAG
}
