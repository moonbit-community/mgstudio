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
test "shader: composable descriptor keeps asset-path as_name and shader defs" {
  let shader = @shader.Shader::{
    ..@shader.Shader::from_wgsl_with_defs(
      "#import bevy_render::view\nfn main() -> f32 {\n  return 1.0;\n}\n",
      "shaders/demo.wgsl",
      [@shader.shader_def("HDR"), @shader.ShaderDefVal::UInt("MODE", 2U)],
    ),
    additional_imports: [
      @naga_oil.ImportDefinition::{
        import_path: "bevy_pbr::mesh_functions",
        items: ["mesh_position_local_to_world"],
      },
    ],
  }
  let descriptor = shader.composable_module_descriptor()

  debug_inspect(
    descriptor.source,
    content="#import bevy_render::view\nfn main() -> f32 {\n  return 1.0;\n}\n",
  )
  debug_inspect(descriptor.file_path, content="shaders/demo.wgsl")
  debug_inspect(descriptor.language, content="Wgsl")
  debug_inspect(
    descriptor.as_name,
    content="Some(\"\\\"shaders/demo.wgsl\\\"\")",
  )
  debug_inspect(descriptor.additional_imports.length(), content="1")
  debug_inspect(descriptor.shader_defs.get("HDR"), content="Some(Bool(true))")
  debug_inspect(descriptor.shader_defs.get("MODE"), content="Some(UInt(2))")
}

///|
test "shader: composable descriptor leaves custom import path unnamed" {
  let shader = @shader.Shader::from_wgsl(
    "#define_import_path bevy_pbr::mesh\nfn main() -> f32 {\n  return 1.0;\n}\n",
    "shaders/bevy_pbr/mesh.wgsl",
  )
  let descriptor = shader.composable_module_descriptor()

  debug_inspect(descriptor.as_name, content="None")
}

///|
test "shader: naga descriptor keeps source and shader type but defaults defs" {
  let shader = @shader.Shader::{
    ..@shader.Shader::from_glsl(
      "void main() {}",
      @shader.ShaderStage::Fragment,
      "shaders/demo.frag",
    ),
    additional_imports: [
      @naga_oil.ImportDefinition::{
        import_path: "bevy_pbr::mesh_functions",
        items: ["mesh_position_local_to_world"],
      },
    ],
    shader_defs: [@shader.shader_def("HDR")],
  }
  let descriptor = shader.naga_module_descriptor()

  debug_inspect(descriptor.source, content="void main() {}")
  debug_inspect(descriptor.file_path, content="shaders/demo.frag")
  debug_inspect(descriptor.shader_type, content="GlslFragment")
  debug_inspect(descriptor.additional_imports.length(), content="0")
  debug_inspect(descriptor.shader_defs.length(), content="0")
}
