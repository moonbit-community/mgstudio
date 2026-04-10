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
// Bevy source: `bevy/crates/bevy_pbr/src/transmission/texture.rs`.

///|
pub fn transmission_texture_runtime_available() -> Bool {
  true
}

///|
pub struct TransmissionTextureState {
  source_texture_id : Int
  blur_texture_id : Int
}

///|
pub fn TransmissionTextureState::default() -> TransmissionTextureState {
  TransmissionTextureState::{ source_texture_id: -1, blur_texture_id: -1 }
}

///|
pub fn TransmissionTextureState::with_source_texture_id(
  self : TransmissionTextureState,
  source_texture_id : Int,
) -> TransmissionTextureState {
  TransmissionTextureState::{ ..self, source_texture_id, }
}

///|
pub fn TransmissionTextureState::with_blur_texture_id(
  self : TransmissionTextureState,
  blur_texture_id : Int,
) -> TransmissionTextureState {
  TransmissionTextureState::{ ..self, blur_texture_id, }
}
