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
pub(all) enum UpdateMode {
  Continuous
  Reactive(@core.Duration, Bool, Bool, Bool)
} derive(Eq, Debug)

///|
pub fn UpdateMode::reactive(wait : @core.Duration) -> UpdateMode {
  Reactive(wait, true, true, true)
}

///|
pub fn UpdateMode::reactive_low_power(wait : @core.Duration) -> UpdateMode {
  Reactive(wait, false, true, true)
}

///|
pub(all) struct WinitSettings {
  focused_mode : UpdateMode
  unfocused_mode : UpdateMode
} derive(Eq, Debug)

///|
pub fn WinitSettings::game() -> WinitSettings {
  WinitSettings::{
    focused_mode: Continuous,
    unfocused_mode: UpdateMode::reactive_low_power(
      @core.Duration::from_secs_f64(1.0 / 60.0),
    ),
  }
}

///|
pub fn WinitSettings::desktop_app() -> WinitSettings {
  WinitSettings::{
    focused_mode: UpdateMode::reactive(@core.Duration::from_secs(5L)),
    unfocused_mode: UpdateMode::reactive_low_power(
      @core.Duration::from_secs(60L),
    ),
  }
}

///|
pub fn WinitSettings::mobile() -> WinitSettings {
  WinitSettings::{
    focused_mode: UpdateMode::reactive(
      @core.Duration::from_secs_f32(1.0F / 60.0F),
    ),
    unfocused_mode: UpdateMode::reactive_low_power(
      @core.Duration::from_secs(1L),
    ),
  }
}

///|
pub fn WinitSettings::continuous() -> WinitSettings {
  WinitSettings::{ focused_mode: Continuous, unfocused_mode: Continuous }
}

///|
pub fn WinitSettings::update_mode(
  self : WinitSettings,
  focused : Bool,
) -> UpdateMode {
  if focused {
    self.focused_mode
  } else {
    self.unfocused_mode
  }
}

///|
pub impl Default for WinitSettings with default() {
  WinitSettings::game()
}

///|
let ecs_key_winit_settings : @ecs.ResourceKey[WinitSettings] = @ecs.register_resource(
  debug_name="mgstudio_winit::WinitSettings",
)

///|
pub impl @app.Resource for WinitSettings with resource() {
  ecs_key_winit_settings
}
