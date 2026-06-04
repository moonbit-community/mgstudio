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
// Bevy source: `bevy/crates/bevy_camera/src/camera.rs::Camera`.

///|
pub type Viewport = @camera_viewport.Viewport

///|
pub type RenderTargetInfo = @camera_computed.RenderTargetInfo

///|
pub type ComputedCameraValues = @camera_computed.ComputedCameraValues

///|
pub type ClearColorConfig = @camera_clear_color.ClearColorConfig

///|
pub struct Camera {
  viewport : Viewport?
  order : Int
  is_active : Bool
  computed : ComputedCameraValues
  clear_color : ClearColorConfig
}

///|
pub fn Camera::new(clear_color : @color.Color) -> Camera {
  Camera::{
    viewport: None,
    order: 0,
    is_active: true,
    computed: ComputedCameraValues::ComputedCameraValues(),
    clear_color: ClearColorConfig::Custom(clear_color),
  }
}

///|
pub fn Camera::Camera() -> Camera {
  Camera::{
    viewport: None,
    order: 0,
    is_active: true,
    computed: ComputedCameraValues::ComputedCameraValues(),
    clear_color: ClearColorConfig::default(),
  }
}

///|
pub fn Camera::with_order(self : Camera, order : Int) -> Camera {
  Camera::{ ..self, order, }
}

///|
pub fn Camera::with_viewport(self : Camera, viewport : Viewport) -> Camera {
  Camera::{ ..self, viewport: Some(viewport) }
}

///|
pub fn Camera::clear_viewport(self : Camera) -> Camera {
  Camera::{ ..self, viewport: None }
}

///|
pub fn Camera::with_clear_color(
  self : Camera,
  clear_color : @color.Color,
) -> Camera {
  Camera::{ ..self, clear_color: ClearColorConfig::Custom(clear_color) }
}

///|
pub fn Camera::with_clear_color_config(
  self : Camera,
  clear_color : ClearColorConfig,
) -> Camera {
  Camera::{ ..self, clear_color, }
}

///|
pub fn Camera::with_clear_color_none(self : Camera) -> Camera {
  Camera::{ ..self, clear_color: ClearColorConfig::None }
}

///|
pub fn Camera::with_is_active(self : Camera, is_active : Bool) -> Camera {
  Camera::{ ..self, is_active, }
}

///|
pub fn Camera::with_computed(
  self : Camera,
  computed : ComputedCameraValues,
) -> Camera {
  Camera::{ ..self, computed, }
}

///|
pub fn Camera::to_logical(
  self : Camera,
  physical_size : @math.IVec2,
) -> @math.Vec2? {
  guard self.computed.target_info is Some(target_info) else { return None }
  let mut scale = target_info.scale_factor
  if scale <= 0.0F {
    scale = 1.0F
  }
  Some(
    @math.Vec2::new(
      Float::from_double(physical_size.x.to_double()) / scale,
      Float::from_double(physical_size.y.to_double()) / scale,
    ),
  )
}

///|
pub fn Camera::physical_target_size(self : Camera) -> @math.IVec2? {
  self.computed.target_info.map(fn(target_info) { target_info.physical_size })
}

///|
pub fn Camera::logical_target_size(self : Camera) -> @math.Vec2? {
  match self.physical_target_size() {
    Some(size) => self.to_logical(size)
    None => None
  }
}

///|
pub fn Camera::physical_viewport_size(self : Camera) -> @math.IVec2? {
  match self.viewport {
    Some(viewport) => Some(viewport.physical_size)
    None => self.physical_target_size()
  }
}

///|
pub fn Camera::logical_viewport_size(self : Camera) -> @math.Vec2? {
  match self.viewport {
    Some(viewport) => self.to_logical(viewport.physical_size)
    None => self.logical_target_size()
  }
}

///|
pub fn Camera::target_scaling_factor(self : Camera) -> Float? {
  self.computed.target_info.map(fn(target_info) { target_info.scale_factor })
}

///|
pub(all) enum RenderTarget {
  Screen
  Window(@window.WindowRef)
  Image(@asset.Handle[@asset.Image])
}

///|
pub let ecs_key_camera : @ecs.ComponentKey[Camera] = @ecs.register_component(
  debug_name="mgstudio.camera.Camera",
)

///|
pub let ecs_key_render_target : @ecs.ComponentKey[RenderTarget] = @ecs.register_component(
  debug_name="mgstudio.camera.RenderTarget",
)

///|
pub impl @ecs.Component for Camera with fn component() {
  ecs_key_camera
}

///|
pub impl @ecs.Component for RenderTarget with fn component() {
  ecs_key_render_target
}

///|
fn encode_camera(camera : Camera) -> Json {
  (
    camera.viewport.map(fn(viewport) {
      @camera_viewport.encode_viewport(viewport)
    }),
    camera.order,
    camera.is_active,
    @camera_computed.encode_computed_camera_values(camera.computed),
    @camera_clear_color.encode_clear_color_config(camera.clear_color),
  ).to_json()
}

///|
fn encode_image_handle(handle : @asset.Handle[@asset.Image]) -> Json {
  handle.id().to_json()
}

///|
fn encode_render_target(target : RenderTarget) -> Json {
  match target {
    Screen => (0, Json::null()).to_json()
    Image(image) => (1, encode_image_handle(image)).to_json()
    Window(window_ref) => (2, window_ref.to_json()).to_json()
  }
}

///|
fn decode_camera(json : Json) -> Camera {
  let (viewport_json, order, is_active, computed_json, clear_color_json) : (
    Json?,
    Int,
    Bool,
    Json,
    Json,
  ) = try! @json.from_json(json)
  Camera::{
    viewport: viewport_json.map(fn(value) {
      @camera_viewport.decode_viewport(value)
    }),
    order,
    is_active,
    computed: @camera_computed.decode_computed_camera_values(computed_json),
    clear_color: @camera_clear_color.decode_clear_color_config(clear_color_json),
  }
}

///|
fn decode_image_handle(json : Json) -> @asset.Handle[@asset.Image] {
  let id : Int = try! @json.from_json(json)
  @asset.Handle::new(id)
}

///|
fn decode_render_target(json : Json) -> RenderTarget {
  let (tag, payload) : (Int, Json) = try! @json.from_json(json)
  match tag {
    0 => Screen
    1 => Image(decode_image_handle(payload))
    2 => Window(try! @json.from_json(payload))
    _ => Screen
  }
}

///|
pub impl ToJson for Camera with fn to_json(self) {
  encode_camera(self)
}

///|
pub impl @json.FromJson for Camera with fn from_json(json, _path) {
  decode_camera(json)
}

///|
pub impl ToJson for RenderTarget with fn to_json(self) {
  encode_render_target(self)
}

///|
pub impl @json.FromJson for RenderTarget with fn from_json(json, _path) {
  decode_render_target(json)
}
