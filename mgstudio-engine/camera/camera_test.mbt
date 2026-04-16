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
test "camera: viewport clamp matches bevy edge behavior" {
  let viewport = Viewport::new(
    @math.IVec2::new(260, 120),
    @math.IVec2::new(50, 20),
  )
  let clamped = camera_viewport_clamp_to_size(
    viewport,
    @math.IVec2::new(200, 100),
  )
  let ok = clamped.physical_position.x == 199 &&
    clamped.physical_position.y == 99 &&
    clamped.physical_size.x == 1 &&
    clamped.physical_size.y == 1
  debug_inspect(ok, content="true")
}
