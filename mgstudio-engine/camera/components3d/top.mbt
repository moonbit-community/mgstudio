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
// Bevy source fragment: `bevy/crates/bevy_camera/src/components.rs::Camera3d`.

///|
pub enum Camera3dDepthLoadOp {
  Clear(Float)
  Load
} derive(ToJson, FromJson)

///|
pub fn Camera3dDepthLoadOp::default() -> Camera3dDepthLoadOp {
  Clear(0.0F)
}

///|
pub struct Camera3dDepthTextureUsage {
  bits : UInt
} derive(ToJson, FromJson)

///|
pub fn Camera3dDepthTextureUsage::Camera3dDepthTextureUsage() -> Camera3dDepthTextureUsage {
  { bits: @asset.IMAGE_USAGE_RENDER_ATTACHMENT.reinterpret_as_uint() }
}

///|
pub fn Camera3dDepthTextureUsage::with_texture_binding(
  self : Camera3dDepthTextureUsage,
) -> Camera3dDepthTextureUsage {
  { bits: self.bits | @asset.IMAGE_USAGE_TEXTURE_BINDING.reinterpret_as_uint() }
}

///|
pub fn Camera3dDepthTextureUsage::with_copy_src(
  self : Camera3dDepthTextureUsage,
) -> Camera3dDepthTextureUsage {
  { bits: self.bits | @asset.IMAGE_USAGE_COPY_SRC.reinterpret_as_uint() }
}

///|
pub fn Camera3dDepthTextureUsage::has_texture_binding(
  self : Camera3dDepthTextureUsage,
) -> Bool {
  (self.bits & @asset.IMAGE_USAGE_TEXTURE_BINDING.reinterpret_as_uint()) != 0U
}

///|
pub fn Camera3dDepthTextureUsage::to_image_usage_bits(
  self : Camera3dDepthTextureUsage,
) -> Int {
  self.bits.reinterpret_as_int()
}

///|
pub struct Camera3d {
  depth_load_op : Camera3dDepthLoadOp
  depth_texture_usages : Camera3dDepthTextureUsage
} derive(ToJson, FromJson)

///|
pub fn Camera3d::Camera3d() -> Camera3d {
  {
    depth_load_op: Camera3dDepthLoadOp::default(),
    depth_texture_usages: Camera3dDepthTextureUsage(),
  }
}

///|
pub fn Camera3d::with_depth_texture_usages(
  self : Camera3d,
  depth_texture_usages : Camera3dDepthTextureUsage,
) -> Camera3d {
  { ..self, depth_texture_usages, }
}

///|
pub fn Camera3d::depth_texture_usages(
  self : Camera3d,
) -> Camera3dDepthTextureUsage {
  self.depth_texture_usages
}

///|
pub fn Camera3d::depth_load_op(self : Camera3d) -> Camera3dDepthLoadOp {
  self.depth_load_op
}

///|
pub let ecs_key_camera3d : @ecs.ComponentKey[Camera3d] = @ecs.register_component(
  debug_name="mgstudio.camera.Camera3d",
)

///|
pub impl @ecs.Component for Camera3d with fn component() {
  ecs_key_camera3d
}
