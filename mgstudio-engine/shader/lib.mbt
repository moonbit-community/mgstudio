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
/// Shader asset API boundary aligned with Bevy's `bevy_shader` crate.
/// Runtime ownership lives in `Milky2018/mgstudio/shader`.

///|
pub(all) struct Shader {
  path : String
  source : Source
  import_path : ShaderImport
  imports : Array[ShaderImport]
  additional_imports : Array[@naga_oil.ImportDefinition]
  shader_defs : Array[ShaderDefVal]
  file_dependencies : Array[@asset.Handle[Shader]]
  validate_shader : ValidateShader
}

///|
fn trim_trailing_semicolons(text : String) -> String {
  let mut out = text.trim().to_string()
  while out.length() > 0 && out.code_unit_at(out.length() - 1).to_int() == 59 { // ';'
    out = out[:out.length() - 1].to_string().trim().to_string()
  }
  out
}

///|
fn shader_import_from_raw(raw_import : String) -> ShaderImport {
  let trimmed = trim_trailing_semicolons(raw_import)
  if trimmed.length() >= 2 &&
    trimmed.code_unit_at(0).to_int() == 34 && // '"'
    trimmed.code_unit_at(trimmed.length() - 1).to_int() == 34 { // '"'
    return ShaderImport::AssetPath(trimmed[1:trimmed.length() - 1].to_string())
  }
  ShaderImport::Custom(trimmed)
}

///|
fn preprocess_shader_imports(
  source : String,
  path : String,
) -> (ShaderImport, Array[ShaderImport]) {
  let (import_path, imports, _) = @naga_oil.get_preprocessor_data(source)
  let shader_import_path = match import_path {
    Some(module_path) => ShaderImport::Custom(module_path)
    None => ShaderImport::AssetPath(path)
  }
  let shader_imports : Array[ShaderImport] = []
  for import_definition in imports {
    shader_imports.push(shader_import_from_raw(import_definition.import_path))
  }
  (shader_import_path, shader_imports)
}

///|
fn shader_drop_extension(path : String) -> String {
  let mut last_slash = -1
  let mut last_dot = -1
  for i in 0..<path.length() {
    let code = path.code_unit_at(i).to_int()
    if code == 47 { // '/'
      last_slash = i
      last_dot = -1
    } else if code == 46 { // '.'
      last_dot = i
    }
  }
  if last_dot > last_slash {
    path[:last_dot].to_string()
  } else {
    path
  }
}

///|
fn shader_wesl_asset_import_path(path : String) -> String {
  let normalized = shader_drop_extension(path.replace_all(old="\\", new="/"))
  if normalized == "" {
    abort("wesl shader path cannot be empty")
  }
  if normalized.has_prefix("/") {
    normalized
  } else {
    "/\{normalized}"
  }
}

///|
pub fn Shader::new(source : String) -> Shader {
  Shader::from_wgsl(source, "")
}

///|
pub fn Shader::from_wgsl(source : String, path : String) -> Shader {
  let (import_path, imports) = preprocess_shader_imports(source, path)
  Shader::{
    path,
    imports,
    import_path,
    source: Source::Wgsl(source),
    additional_imports: [],
    shader_defs: [],
    file_dependencies: [],
    validate_shader: ValidateShader::Disabled,
  }
}

///|
pub fn Shader::from_wgsl_with_defs(
  source : String,
  path : String,
  shader_defs : Array[ShaderDefVal],
) -> Shader {
  let shader = Shader::from_wgsl(source, path)
  Shader::{ ..shader, shader_defs, }
}

///|
pub fn Shader::from_wesl(source : String, path : String) -> Shader {
  let (import_path, imports) = preprocess_shader_imports(source, path)
  match import_path {
    AssetPath(_) => ()
    Custom(module_path) =>
      abort(
        "wesl shaders only support asset-backed import paths: \{module_path}",
      )
  }
  Shader::{
    path,
    imports,
    import_path: ShaderImport::AssetPath(shader_wesl_asset_import_path(path)),
    source: Source::Wesl(source),
    additional_imports: [],
    shader_defs: [],
    file_dependencies: [],
    validate_shader: ValidateShader::Disabled,
  }
}

///|
pub fn Shader::from_glsl(
  source : String,
  stage : ShaderStage,
  path : String,
) -> Shader {
  let (import_path, imports) = preprocess_shader_imports(source, path)
  Shader::{
    path,
    imports,
    import_path,
    source: Source::Glsl(source, stage),
    additional_imports: [],
    shader_defs: [],
    file_dependencies: [],
    validate_shader: ValidateShader::Disabled,
  }
}

///|
pub fn Shader::from_spirv(source : Bytes, path : String) -> Shader {
  Shader::{
    path,
    imports: [],
    import_path: ShaderImport::AssetPath(path),
    source: Source::SpirV(source),
    additional_imports: [],
    shader_defs: [],
    file_dependencies: [],
    validate_shader: ValidateShader::Disabled,
  }
}

///|
pub fn shader_from_source(source : String) -> Shader {
  Shader::new(source)
}
