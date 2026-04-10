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
// Bevy source: `bevy/crates/bevy_camera/src/clear_color.rs`.

///|
pub type ClearColor = @sprite.ClearColor

///|
pub type ClearColorConfig = @sprite.ClearColorConfig

///|
pub type MsaaWriteback = @post_process.MsaaWriteback

///|
pub fn camera_clear_color_default() -> ClearColor {
  @sprite.ClearColor::default()
}

///|
pub fn camera_clear_color_config_default() -> ClearColorConfig {
  @sprite.ClearColorConfig::default()
}

///|
pub fn camera_msaa_writeback_default() -> MsaaWriteback {
  @post_process.MsaaWriteback::default()
}

///|
pub fn camera_clear_color_new(color : @color.Color) -> ClearColor {
  @sprite.ClearColor::new(color)
}

///|
pub fn camera_clear_color_config_resolve(
  config : ClearColorConfig,
) -> (Bool, @color.Color) {
  config.resolve()
}
