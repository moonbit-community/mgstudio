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
// Bevy source:
// - `bevy/crates/bevy_render/src/camera.rs` (`SortedCameras`,
//   `SortedCamera`).
pub(all) enum CameraOutputMode {
  Write
  Skip
} derive(Eq, Debug)

///|
pub fn CameraOutputMode::default() -> CameraOutputMode {
  Write
}

///|
pub fn CameraOutputMode::writes(self : CameraOutputMode) -> Bool {
  self == Write
}

///|
pub struct SortedCamera {
  entity : @core.Entity
  order : Int
  target : @camera_render_target.NormalizedRenderTarget?
  hdr : Bool
  output_mode : CameraOutputMode
}

///|
pub fn SortedCamera::new(
  entity : @core.Entity,
  order : Int,
  target : @camera_render_target.NormalizedRenderTarget?,
  hdr : Bool,
  output_mode : CameraOutputMode,
) -> SortedCamera {
  { entity, order, target, hdr, output_mode }
}

///|
pub fn SortedCamera::entity(self : SortedCamera) -> @core.Entity {
  self.entity
}

///|
pub fn SortedCamera::order(self : SortedCamera) -> Int {
  self.order
}

///|
pub fn SortedCamera::target(
  self : SortedCamera,
) -> @camera_render_target.NormalizedRenderTarget? {
  self.target
}

///|
pub fn SortedCamera::hdr(self : SortedCamera) -> Bool {
  self.hdr
}

///|
pub fn SortedCamera::output_mode(self : SortedCamera) -> CameraOutputMode {
  self.output_mode
}

///|
pub fn SortedCamera::writes_output(self : SortedCamera) -> Bool {
  self.output_mode.writes()
}

///|
pub struct SortedCameras {
  mut cameras : Array[SortedCamera]
}

///|
pub fn SortedCameras::new() -> SortedCameras {
  { cameras: [] }
}

///|
pub fn SortedCameras::from_array(
  cameras : Array[SortedCamera],
) -> SortedCameras {
  { cameras, }
}

///|
pub fn SortedCameras::len(self : SortedCameras) -> Int {
  self.cameras.length()
}

///|
pub fn SortedCameras::is_empty(self : SortedCameras) -> Bool {
  self.len() == 0
}

///|
pub fn SortedCameras::cameras(self : SortedCameras) -> Array[SortedCamera] {
  self.cameras
}

///|
pub fn SortedCameras::camera_entities(
  self : SortedCameras,
) -> Array[@core.Entity] {
  let entities : Array[@core.Entity] = []
  for camera in self.cameras {
    entities.push(camera.entity)
  }
  entities
}

///|
pub let sorted_cameras_key : @ecs.ResourceKey[SortedCameras] = @ecs.register_resource(
  debug_name="mgstudio_render::SortedCameras",
)

///|
pub impl @app.Resource for SortedCameras with fn resource() {
  sorted_cameras_key
}

///|
pub fn ensure_sorted_cameras_resource(world : @ecs.World) -> Unit {
  if world.get_resource(SortedCameras::resource()) is None {
    world.insert_resource(SortedCameras::resource(), SortedCameras::new())
  }
}

///|
pub fn sorted_cameras_ref_or_abort(
  world : @ecs.World,
) -> @ecs.ResourceMut[SortedCameras] {
  ensure_sorted_cameras_resource(world)
  match world.get_resource_mut(SortedCameras::resource()) {
    Some(state) => state
    None => abort("Missing SortedCameras resource in render world")
  }
}

///|
pub fn sorted_cameras_or_default(world : @ecs.World) -> SortedCameras {
  ensure_sorted_cameras_resource(world)
  match world.get_resource(SortedCameras::resource()) {
    Some(state) => state
    None => SortedCameras::new()
  }
}

///|
pub fn sorted_cameras_replace(
  sorted_cameras_ref : @ecs.ResourceMut[SortedCameras],
  cameras : Array[SortedCamera],
) -> Unit {
  sorted_cameras_ref.modify(fn(value) { value.cameras = cameras })
}

///|
pub fn sorted_cameras_clear(
  sorted_cameras_ref : @ecs.ResourceMut[SortedCameras],
) -> Unit {
  sorted_cameras_ref.modify(fn(value) { value.cameras.clear() })
}
