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
// Bevy source: `bevy/crates/bevy_feathers/src/controls/checkbox.rs`.

///|
pub struct CheckboxProps {
  checked : Bool
  disabled : Bool
}

///|
pub fn CheckboxProps::default() -> CheckboxProps {
  CheckboxProps::{ checked: false, disabled: false }
}

///|
pub struct Checkbox {
  props : CheckboxProps
  label : String
}

///|
pub fn checkbox(props : CheckboxProps, label : String) -> Checkbox {
  Checkbox::{ props, label }
}

///|
pub struct CheckboxPlugin {}

///|
pub fn CheckboxPlugin::default() -> CheckboxPlugin {
  CheckboxPlugin::{  }
}

///|
pub fn checkbox_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
}
