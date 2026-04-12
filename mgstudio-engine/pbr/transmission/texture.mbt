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
pub struct ViewTransmissionTexture {
  texture_id : Int
  width : Int
  height : Int
  sampler_linear : Bool
}

///|
pub fn ViewTransmissionTexture::default() -> ViewTransmissionTexture {
  ViewTransmissionTexture::{
    texture_id: -1,
    width: 0,
    height: 0,
    sampler_linear: true,
  }
}

///|
pub fn ViewTransmissionTexture::is_ready(
  self : ViewTransmissionTexture,
) -> Bool {
  self.texture_id >= 0 && self.width > 0 && self.height > 0
}

///|
pub fn pbr_prepare_view_transmission_texture(
  texture_id : Int,
  width : Int,
  height : Int,
) -> ViewTransmissionTexture {
  ViewTransmissionTexture::{
    texture_id,
    width: if width < 0 {
      0
    } else {
      width
    },
    height: if height < 0 {
      0
    } else {
      height
    },
    sampler_linear: true,
  }
}

///|
pub fn pbr_should_prepare_transmission_texture(
  transmission_steps : Int,
  transmissive_item_count : Int,
  opaque_phase_ready : Bool,
  alpha_mask_phase_ready : Bool,
  transparent_phase_ready : Bool,
) -> Bool {
  transmission_steps > 0 &&
  transmissive_item_count > 0 &&
  opaque_phase_ready &&
  alpha_mask_phase_ready &&
  transparent_phase_ready
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
