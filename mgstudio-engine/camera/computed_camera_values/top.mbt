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
// Bevy source: `bevy/crates/bevy_camera/src/camera.rs::RenderTargetInfo`.

///|
pub struct RenderTargetInfo {
  physical_size : @math.IVec2
  scale_factor : Float
}

///|
pub fn RenderTargetInfo::new(
  physical_size : @math.IVec2,
  scale_factor : Float,
) -> RenderTargetInfo {
  RenderTargetInfo::{ physical_size, scale_factor }
}

///|
pub fn RenderTargetInfo::RenderTargetInfo() -> RenderTargetInfo {
  RenderTargetInfo::{
    physical_size: @math.IVec2::new(0, 0),
    scale_factor: 1.0F,
  }
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/camera.rs::ComputedCameraValues`.

///|
pub struct ComputedCameraValues {
  clip_from_view : @math.Mat4
  target_info : RenderTargetInfo?
  old_viewport_size : @math.IVec2?
  old_sub_camera_view : @camera_primitives.SubCameraView3d?
}

///|
pub fn ComputedCameraValues::ComputedCameraValues() -> ComputedCameraValues {
  ComputedCameraValues::{
    clip_from_view: @math.Mat4::identity(),
    target_info: None,
    old_viewport_size: None,
    old_sub_camera_view: None,
  }
}

///|
pub fn ComputedCameraValues::new(
  clip_from_view : @math.Mat4,
  target_info : RenderTargetInfo?,
  old_viewport_size : @math.IVec2?,
  old_sub_camera_view : @camera_primitives.SubCameraView3d?,
) -> ComputedCameraValues {
  ComputedCameraValues::{
    clip_from_view,
    target_info,
    old_viewport_size,
    old_sub_camera_view,
  }
}

///|
pub fn encode_render_target_info(target_info : RenderTargetInfo) -> Json {
  (encode_ivec2(target_info.physical_size), target_info.scale_factor).to_json()
}

///|
pub fn decode_render_target_info(json : Json) -> RenderTargetInfo {
  let (size, scale_factor) : (Json, Float) = try! @json.from_json(json)
  RenderTargetInfo::new(decode_ivec2(size), scale_factor)
}

///|
pub fn encode_computed_camera_values(computed : ComputedCameraValues) -> Json {
  (
    computed.clip_from_view,
    computed.target_info.map(fn(target_info) {
      encode_render_target_info(target_info)
    }),
    computed.old_viewport_size.map(fn(size) { encode_ivec2(size) }),
    computed.old_sub_camera_view,
  ).to_json()
}

///|
pub fn decode_computed_camera_values(json : Json) -> ComputedCameraValues {
  let (
    clip_from_view,
    target_info_json,
    old_viewport_size_json,
    old_sub_camera_view,
  ) : (@math.Mat4, Json?, Json?, @camera_primitives.SubCameraView3d?) = try! @json.from_json(
    json,
  )
  ComputedCameraValues::{
    clip_from_view,
    target_info: target_info_json.map(fn(value) {
      decode_render_target_info(value)
    }),
    old_viewport_size: old_viewport_size_json.map(fn(value) {
      decode_ivec2(value)
    }),
    old_sub_camera_view,
  }
}

///|
fn encode_ivec2(value : @math.IVec2) -> Json {
  (value.x, value.y).to_json()
}

///|
fn decode_ivec2(json : Json) -> @math.IVec2 {
  let (x, y) : (Int, Int) = try! @json.from_json(json)
  @math.IVec2::new(x, y)
}

///|
pub impl ToJson for RenderTargetInfo with fn to_json(self) {
  encode_render_target_info(self)
}

///|
pub impl @json.FromJson for RenderTargetInfo with fn from_json(json, _path) {
  decode_render_target_info(json)
}

///|
pub impl ToJson for ComputedCameraValues with fn to_json(self) {
  encode_computed_camera_values(self)
}

///|
pub impl @json.FromJson for ComputedCameraValues with fn from_json(json, _path) {
  decode_computed_camera_values(json)
}
