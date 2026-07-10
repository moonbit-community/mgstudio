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
test "renderer: prepass attachments clear once per frame" {
  let used : Map[Int, Bool] = Map([])
  assert_eq(mesh3d_prepass_attachment_load_op(used, 10, 1), @wgpu.LOAD_OP_CLEAR)
  assert_eq(mesh3d_prepass_attachment_load_op(used, 10, 1), @wgpu.LOAD_OP_LOAD)
  assert_eq(mesh3d_prepass_attachment_load_op(used, 11, 1), @wgpu.LOAD_OP_CLEAR)
  assert_eq(mesh3d_prepass_attachment_load_op(used, 12, 0), @wgpu.LOAD_OP_LOAD)
  inspect(used.contains(12), content="false")
  used.clear()
  assert_eq(mesh3d_prepass_attachment_load_op(used, 10, 1), @wgpu.LOAD_OP_CLEAR)
}
