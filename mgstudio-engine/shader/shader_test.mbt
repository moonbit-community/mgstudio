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
test "shader: from_wgsl collects Bevy-style import metadata" {
  let shader = @shader.Shader::from_wgsl(
    "#define_import_path bevy_ui::ui_node\n#import bevy_render::{view::View, globals::Globals}\nfn main(view: View, globals: Globals) -> f32 {\n  return 1.0;\n}\n",
    "shaders/bevy_ui_render/ui.wgsl",
  )
  debug_inspect(shader.path, content="shaders/bevy_ui_render/ui.wgsl")
  debug_inspect(shader.import_path, content="Custom(\"bevy_ui::ui_node\")")
  debug_inspect(shader.imports.length(), content="2")
  debug_inspect(shader.imports[0], content="Custom(\"bevy_render::view\")")
  debug_inspect(shader.imports[1], content="Custom(\"bevy_render::globals\")")
  debug_inspect(shader.file_dependencies.length(), content="0")
  debug_inspect(shader.validate_shader, content="Disabled")
}

///|
test "shader: from_wgsl_with_defs preserves shader defs" {
  let shader = @shader.Shader::from_wgsl_with_defs(
    "fn main() -> f32 {\n  return 1.0;\n}\n",
    "shaders/demo.wgsl",
    [@shader.shader_def("HDR"), @shader.ShaderDefVal::UInt("TONEMAP_MODE", 2U)],
  )
  debug_inspect(shader.shader_defs.length(), content="2")
  debug_inspect(shader.shader_defs[0].value_as_string(), content="true")
  debug_inspect(shader.shader_defs[1].value_as_string(), content="2")
}

///|
test "shader: source language and shader type align with naga_oil surface" {
  let wgsl = @shader.Source::Wgsl("fn main() {}")
  debug_inspect(wgsl.language(), content="Wgsl")
  debug_inspect(wgsl.shader_type(), content="Wgsl")

  let glsl = @shader.Source::Glsl(
    "void main() {}",
    @shader.ShaderStage::Fragment,
  )
  debug_inspect(glsl.language(), content="Glsl")
  debug_inspect(glsl.shader_type(), content="GlslFragment")
}

///|
test "shader: asset path imports quote module names" {
  let shader_import = @shader.ShaderImport::AssetPath("shaders/demo.wgsl")
  debug_inspect(shader_import.module_name(), content="\"shaders/demo.wgsl\"")
}
