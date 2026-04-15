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
fn shader_defs_to_naga_oil_shader_defs(
  shader_defs : Array[ShaderDefVal],
) -> @hashmap.HashMap[String, @wgsl.ShaderDefValue] {
  let mapped : @hashmap.HashMap[String, @wgsl.ShaderDefValue] = @hashmap.HashMap::new()
  for shader_def in shader_defs {
    match shader_def {
      Bool(name, value) => mapped.set(name, @wgsl.ShaderDefValue::Bool(value))
      Int(name, value) => mapped.set(name, @wgsl.ShaderDefValue::Int(value))
      UInt(name, value) => mapped.set(name, @wgsl.ShaderDefValue::UInt(value))
    }
  }
  mapped
}

///|
pub fn Shader::composable_module_descriptor(
  self : Shader,
) -> @wgsl.ComposableModuleDescriptor {
  let as_name = match self.import_path {
    AssetPath(asset_path) => Some("\"\{asset_path}\"")
    Custom(_) => None
  }
  @wgsl.ComposableModuleDescriptor::{
    source: self.source.as_str(),
    file_path: self.path,
    language: self.source.language(),
    as_name,
    additional_imports: self.additional_imports,
    shader_defs: shader_defs_to_naga_oil_shader_defs(self.shader_defs),
  }
}

///|
pub fn Shader::naga_module_descriptor(
  self : Shader,
) -> @wgsl.NagaModuleDescriptor {
  @wgsl.NagaModuleDescriptor::{
    source: self.source.as_str(),
    file_path: self.path,
    shader_type: self.source.shader_type(),
    shader_defs: @hashmap.HashMap::new(),
    additional_imports: [],
  }
}
