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
// Bevy source: `bevy/crates/bevy_feathers/src/controls/button.rs`.

///|
pub(all) enum ButtonVariant {
  Default
  Primary
} derive(Eq, Debug)

///|
pub struct ButtonProps {
  variant : ButtonVariant
  disabled : Bool
}

///|
pub fn ButtonProps::default() -> ButtonProps {
  ButtonProps::{ variant: Default, disabled: false }
}

///|
pub struct Button {
  props : ButtonProps
  label : String
}

///|
pub fn button(props : ButtonProps, label : String) -> Button {
  Button::{ props, label }
}

///|
pub struct ButtonPlugin {}

///|
pub fn ButtonPlugin::default() -> ButtonPlugin {
  ButtonPlugin::{  }
}

///|
pub fn button_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  ensure_controls_runtime(app)
}
