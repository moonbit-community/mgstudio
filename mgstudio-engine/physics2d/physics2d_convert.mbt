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
/// Conversions between mgstudio math types and moon_rapier core types.
///
/// Note: Physics v1 ignores `@math.Transform.scale`.

///|
pub fn mg_vec2_to_rapier(v : @math.Vec2) -> @rapier_core.Vec2 {
  @rapier_core.Vec2::new(v.x, v.y)
}

///|
pub fn rapier_vec2_to_mg(v : @rapier_core.Vec2) -> @math.Vec2 {
  @math.Vec2::new(v.x, v.y)
}

///|
pub fn mg_transform_to_iso2(t : @math.Transform) -> @rapier_core.Isometry2 {
  let translation = @rapier_core.Vec2::new(t.translation.x, t.translation.y)
  let rot = @rapier_core.Rot2::from_angle(t.rotation_z())
  @rapier_core.Isometry2::new(translation, rot)
}

///|
pub fn iso2_to_mg_transform(
  iso : @rapier_core.Isometry2,
  z : Float,
) -> @math.Transform {
  let angle = iso.rotation.angle()
  @math.Transform::from_xy_rotation_scale(
    @math.Vec2::new(iso.translation.x, iso.translation.y),
    angle,
    @math.Vec2::new(1.0F, 1.0F),
    z~,
  )
}
