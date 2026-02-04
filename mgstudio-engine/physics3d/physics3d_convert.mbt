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
pub fn mg_vec3_to_rapier(v : @math.Vec3) -> @rapier_core.Vec3 {
  @rapier_core.Vec3::new(v.x, v.y, v.z)
}

///|
pub fn rapier_vec3_to_mg(v : @rapier_core.Vec3) -> @math.Vec3 {
  @math.Vec3::new(v.x, v.y, v.z)
}

///|
pub fn mg_quat_to_rapier(q : @math.Quat) -> @rapier_core.Quat {
  @rapier_core.Quat::new(q.x, q.y, q.z, q.w)
}

///|
pub fn rapier_quat_to_mg(q : @rapier_core.Quat) -> @math.Quat {
  @math.Quat::new(q.x, q.y, q.z, q.w)
}

///|
pub fn mg_transform_to_iso3(t : @math.Transform) -> @rapier_core.Isometry3 {
  @rapier_core.Isometry3::new(
    mg_vec3_to_rapier(t.translation),
    mg_quat_to_rapier(t.rotation),
  )
}

///|
pub fn iso3_to_mg_transform(iso : @rapier_core.Isometry3) -> @math.Transform {
  @math.Transform::new(
    @math.Vec3::new(iso.translation.x, iso.translation.y, iso.translation.z),
    rapier_quat_to_mg(iso.rotation),
    @math.Vec3::new(1.0F, 1.0F, 1.0F),
  )
}
