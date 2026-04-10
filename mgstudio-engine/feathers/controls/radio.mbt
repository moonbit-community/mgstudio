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
// Bevy source: `bevy/crates/bevy_feathers/src/controls/radio.rs`.

///|
pub struct RadioProps {
  selected : Bool
  disabled : Bool
}

///|
pub fn RadioProps::default() -> RadioProps {
  RadioProps::{ selected: false, disabled: false }
}

///|
pub struct RadioButton {
  props : RadioProps
  label : String
}

///|
pub fn radio(props : RadioProps, label : String) -> RadioButton {
  RadioButton::{ props, label }
}

///|
pub struct RadioPlugin {}

///|
pub fn RadioPlugin::default() -> RadioPlugin {
  RadioPlugin::{  }
}

///|
pub fn radio_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
}
