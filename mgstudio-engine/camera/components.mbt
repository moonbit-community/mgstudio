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
// Bevy source: `bevy/crates/bevy_camera/src/components.rs`.

///|
pub type Camera = @sprite.Camera

///|
pub type Camera2d = @sprite.Camera2d

///|
pub type Camera2dBundle = @sprite.Camera2dBundle

///|
pub type Hdr = @core_pipeline.Hdr

///|
pub fn camera_2d_bundle_new(
  camera : Camera,
  transform : @transform.Transform,
) -> Camera2dBundle {
  @sprite.Camera2dBundle::new(camera, transform)
}

///|
pub fn camera_2d_bundle_new_with_layers(
  camera : Camera,
  transform : @transform.Transform,
  target : @sprite.RenderTarget,
  layers : @sprite.RenderLayers,
) -> Camera2dBundle {
  @sprite.Camera2dBundle::new_with_layers(camera, transform, target, layers)
}

///|
pub fn camera_2d_bundle_new_with_target(
  camera : Camera,
  transform : @transform.Transform,
  target : @sprite.RenderTarget,
) -> Camera2dBundle {
  @sprite.Camera2dBundle::new_with_target(camera, transform, target)
}

///|
pub fn camera_2d_bundle_new_with_projection(
  camera : Camera,
  projection : @sprite.Projection,
  transform : @transform.Transform,
) -> Camera2dBundle {
  @sprite.Camera2dBundle::new_with_projection(camera, projection, transform)
}
