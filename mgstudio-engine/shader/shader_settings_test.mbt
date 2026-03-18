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
test "shader: settings default to empty shader defs" {
  let settings = @shader.ShaderSettings::default()
  inspect(settings.shader_defs.length(), content="0")
}

///|
test "shader: settings preserve configured shader defs" {
  let settings = @shader.ShaderSettings::{
    shader_defs: [
      @shader.shader_def("HDR"),
      @shader.ShaderDefVal::UInt("MODE", 2U),
    ],
  }
  inspect(settings.shader_defs.length(), content="2")
  inspect(settings.shader_defs[0], content="Bool(\"HDR\", true)")
  inspect(settings.shader_defs[1], content="UInt(\"MODE\", 2)")
}
