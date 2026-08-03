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
pub fn render3d_pass_clear_enabled_for_target(
  cleared_targets : Array[Int],
  target_id : Int,
  requested : Bool,
) -> Int {
  if !requested {
    return 0
  }
  for cleared_target_id in cleared_targets {
    if cleared_target_id == target_id {
      return 0
    }
  }
  cleared_targets.push(target_id)
  1
}

///|
pub fn render3d_pass_viewport_for_target(
  pass_target_id : Int,
  camera_target_id : Int,
  camera_viewport_x : Int,
  camera_viewport_y : Int,
  camera_viewport_width : Int,
  camera_viewport_height : Int,
) -> (Int, Int, Int, Int) {
  if pass_target_id == camera_target_id {
    (
      camera_viewport_x, camera_viewport_y, camera_viewport_width, camera_viewport_height,
    )
  } else {
    (0, 0, camera_viewport_width, camera_viewport_height)
  }
}
