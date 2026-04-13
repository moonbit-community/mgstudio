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
test "ui picking wb: viewport origin maps to local zero" {
  let pos = ui_pointer_pos_in_viewport(
    @math.Vec2::new(20.0F, 10.0F),
    @math.Vec2::new(20.0F, 10.0F),
    @math.Vec2::new(100.0F, 80.0F),
  )
  debug_inspect(pos is Some(v) && v.x == 0.0F && v.y == 0.0F, content="true")
}

///|
test "ui picking wb: viewport max edge is inclusive" {
  let pos = ui_pointer_pos_in_viewport(
    @math.Vec2::new(120.0F, 90.0F),
    @math.Vec2::new(20.0F, 10.0F),
    @math.Vec2::new(100.0F, 80.0F),
  )
  debug_inspect(pos is Some(v) && v.x == 100.0F && v.y == 80.0F, content="true")
}

///|
test "ui picking wb: outside viewport returns None" {
  let left = ui_pointer_pos_in_viewport(
    @math.Vec2::new(19.0F, 10.0F),
    @math.Vec2::new(20.0F, 10.0F),
    @math.Vec2::new(100.0F, 80.0F),
  )
  let bottom = ui_pointer_pos_in_viewport(
    @math.Vec2::new(20.0F, 91.0F),
    @math.Vec2::new(20.0F, 10.0F),
    @math.Vec2::new(100.0F, 80.0F),
  )
  debug_inspect(left is None, content="true")
  debug_inspect(bottom is None, content="true")
}
