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
// Bevy source: `bevy/crates/bevy_ui_render/src/box_shadow.rs`.
pub struct BoxShadowSamples {
  samples : Int
} derive(ToJson, FromJson)

///|
pub fn BoxShadowSamples::new(samples : Int) -> BoxShadowSamples {
  let safe = if samples < 0 { 0 } else { samples }
  BoxShadowSamples::{ samples: safe }
}

///|
pub fn BoxShadowSamples::default() -> BoxShadowSamples {
  BoxShadowSamples::new(4)
}

///|
pub let ecs_key_ui_box_shadow_samples : @ecs.ComponentKey[BoxShadowSamples] = @ecs.register_component(
  debug_name="ui.ui_box_shadow_samples",
)

///|
pub impl @ecs.Component for BoxShadowSamples with component() {
  ecs_key_ui_box_shadow_samples
}
