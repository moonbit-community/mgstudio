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
// Bevy source: `bevy/crates/bevy_render/src/render_phase/rangefinder.rs`.

///|
pub struct ViewRangefinder3d {
  world_from_view_origin_z : Float
}

///|
pub fn ViewRangefinder3d::from_world_from_view(
  world_from_view : @math.Affine3,
) -> ViewRangefinder3d {
  let origin = world_from_view.transform_point3(@math.Vec3::zero())
  ViewRangefinder3d::{ world_from_view_origin_z: origin.z }
}

///|
pub fn ViewRangefinder3d::distance(
  self : ViewRangefinder3d,
  position : @math.Vec3,
) -> Float {
  position.z - self.world_from_view_origin_z
}
