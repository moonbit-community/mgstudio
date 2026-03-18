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
test "naga_oil: metadata parser reads grouped imports and defines" {
  let metadata = @naga_oil.get_preprocessor_metadata(
    "#define_import_path bevy_ui::ui_node\n#define HDR\n#define TONEMAP_MODE 2u\n#import bevy_render::{\n  view::View,\n  globals::Globals,\n}\n#import bevy_render::maths as maths\nfn main() -> f32 {\n  return 1.0;\n}\n",
  )
  inspect(metadata.name, content="Some(\"bevy_ui::ui_node\")")
  inspect(metadata.imports.length(), content="3")
  inspect(metadata.imports[0].import_path, content="bevy_render::view")
  inspect(metadata.imports[0].items[0], content="View")
  inspect(metadata.imports[1].import_path, content="bevy_render::globals")
  inspect(metadata.imports[1].items[0], content="Globals")
  inspect(metadata.imports[2].import_path, content="bevy_render::maths")
  inspect(metadata.imports[2].items.length(), content="0")
  inspect(metadata.cleaned_source.contains("#import"), content="false")
  inspect(metadata.cleaned_source.contains("fn main() -> f32"), content="true")

  guard metadata.defines.get("HDR")
    is Some(@naga_oil.ShaderDefValue::Bool(enabled)) else {
    abort("expected HDR define")
  }
  inspect(enabled, content="true")

  guard metadata.defines.get("TONEMAP_MODE")
    is Some(@naga_oil.ShaderDefValue::UInt(mode)) else {
    abort("expected TONEMAP_MODE define")
  }
  inspect(mode.to_string(), content="2")
}

///|
test "naga_oil: metadata parser keeps quoted path imports and item lists" {
  let (_, imports, _) = @naga_oil.get_preprocessor_data(
    "#import \"shaders/skills/shared.wgsl\" Vertex, VertexOutput\n",
  )
  inspect(imports.length(), content="1")
  inspect(imports[0].import_path, content="\"shaders/skills/shared.wgsl\"")
  inspect(imports[0].items.length(), content="2")
  inspect(imports[0].items[0], content="Vertex")
  inspect(imports[0].items[1], content="VertexOutput")
}
