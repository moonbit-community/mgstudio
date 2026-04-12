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
test "render3d: contact shadows uniform mirrors settings" {
  let settings = ContactShadows::new(12, 0.2F, 0.7F)
  let uniform = ContactShadowsUniform::from_settings(settings)
  debug_inspect(
    uniform.linear_steps() == 12U &&
    uniform.thickness() == 0.2F &&
    uniform.length() == 0.7F,
    content="true",
  )
}

///|
test "render3d: contact shadows buffer push/lookup tracks offsets" {
  let buffer = ContactShadowsBuffer::default()
  let a = buffer.push(
    ContactShadowsUniform::from_settings(ContactShadows::new(8, 0.1F, 0.4F)),
  )
  let b = buffer.push(ContactShadowsUniform::disabled())
  debug_inspect(a == 0U, content="true")
  debug_inspect(b == 1U, content="true")
  debug_inspect(buffer.len(), content="2")
  debug_inspect(buffer.uniform_at(1U) is Some(_), content="true")
  debug_inspect(buffer.uniform_at(2U) is None, content="true")
}
