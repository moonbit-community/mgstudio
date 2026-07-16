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
fn approx_equal(left : Float, right : Float) -> Bool {
  (left - right).abs() <= 1.0e-4F
}

///|
test "many animated sprites: benchmark configuration matches pinned Bevy" {
  let window = configured_window()
  debug_inspect(window.physical_width(), content="1920")
  debug_inspect(window.physical_height(), content="1080")
  debug_inspect(window.resolution.scale_factor_override(), content="Some(1)")
  debug_inspect(window.present_mode, content="AutoNoVsync")

  let timer = animation_timer(0.75F).timer
  debug_inspect(approx_equal(timer.duration_seconds(), 0.1F), content="true")
  debug_inspect(approx_equal(timer.elapsed_secs(), 0.75F), content="true")
}

///|
test "many animated sprites: camera translates along its rotated local x axis" {
  let transform = @transform.Transform::identity()
  advance_camera_transform(transform, 1.0F)
  let expected = @math.Quat::from_rotation_z(0.5F).mul_vec3(
    @math.Vec3::new(CAMERA_SPEED, 0.0F, 0.0F),
  )
  debug_inspect(
    approx_equal(transform.translation.x, expected.x),
    content="true",
  )
  debug_inspect(
    approx_equal(transform.translation.y, expected.y),
    content="true",
  )
  debug_inspect(approx_equal(transform.translation.z, 0.0F), content="true")
  let right = transform.right()
  let expected_right = expected.normalize_or_zero()
  debug_inspect(approx_equal(right.x, expected_right.x), content="true")
  debug_inspect(approx_equal(right.y, expected_right.y), content="true")
}
