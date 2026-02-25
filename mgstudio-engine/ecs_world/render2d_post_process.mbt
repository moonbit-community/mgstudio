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
fn tonemapping_mode_to_int(mode : @render3d.Tonemapping) -> Int {
  match mode {
    None => 0
    Reinhard => 1
    ReinhardLuminance => 2
    AcesFitted => 3
    AgX => 4
    SomewhatBoringDisplayTransform => 5
    TonyMcMapface => 6
    BlenderFilmic => 7
  }
}

///|
pub impl @render2d.CameraPostProcessWorld for World with camera_tonemapping_mode(
  self,
  camera,
) {
  match self.get_tonemapping_store().get(camera) {
    Some(mode) => tonemapping_mode_to_int(mode)
    None => 0
  }
}

///|
pub impl @render2d.CameraPostProcessWorld for World with camera_deband_dither_enabled(
  self,
  camera,
) {
  match self.get_deband_dither_store().get(camera) {
    Some(Enabled) => true
    _ => false
  }
}
