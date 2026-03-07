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
test "math: vec3 smooth_nudge moves towards target" {
  let value = Vec3::new(0.0F, 0.0F, 0.0F)
  value.smooth_nudge(Vec3::new(10.0F, 0.0F, 0.0F), 1.0F, 1.0F)
  inspect(value.x > 6.3F && value.x < 6.4F, content="true")
  inspect(value.y == 0.0F && value.z == 0.0F, content="true")
}

///|
test "math: vec2 normalize_or_zero normalizes nonzero vectors" {
  let value = Vec2::new(3.0F, 4.0F).normalize_or_zero()
  inspect(value.x == 0.6F, content="true")
  inspect(value.y == 0.8F, content="true")
  let zero = Vec2::zero().normalize_or_zero()
  inspect(zero.x == 0.0F, content="true")
  inspect(zero.y == 0.0F, content="true")
}

///|
test "math: transform looking_to aligns forward direction" {
  let transform = Transform::from_xyz(1.0F, 2.0F, 3.0F).looking_to(
    Vec3::new(0.0F, 0.0F, -2.0F),
    Vec3::new(0.0F, 1.0F, 0.0F),
  )
  let forward = transform.forward()
  inspect(forward.x == 0.0F, content="true")
  inspect(forward.y == 0.0F, content="true")
  inspect(forward.z < -0.999F, content="true")
}

///|
test "math: transform rotate_z updates z rotation" {
  let transform = Transform::identity()
  transform.rotate_z(pi_half())
  inspect(
    transform.rotation_z() > 1.56F && transform.rotation_z() < 1.58F,
    content="true",
  )
}

///|
test "math: pi matches two half turns" {
  inspect(pi() > 3.1415F && pi() < 3.1416F, content="true")
  inspect(pi_half() * 2.0F == pi(), content="true")
}
