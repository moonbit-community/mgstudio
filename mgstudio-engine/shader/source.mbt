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
pub(all) enum Source {
  Wgsl(String)
  Wesl(String)
  Glsl(String, ShaderStage)
  SpirV(Bytes)
}

///|
pub fn Source::as_str(self : Source) -> String {
  match self {
    Wgsl(source) => source
    Wesl(source) => source
    Glsl(source, _) => source
    SpirV(_) => abort("spirv source does not expose a UTF-8 source string")
  }
}

///|
pub(all) enum ShaderLanguage {
  Wgsl
  Glsl
} derive(Eq, Debug)

///|
pub(all) enum ShaderType {
  Wgsl
  GlslVertex
  GlslFragment
} derive(Eq, Debug)

///|
pub(all) struct ComposableModuleDescriptor {
  source : String
  file_path : String
  language : ShaderLanguage
  as_name : String?
  additional_imports : Array[@wgsl_common.ImportDefinition]
  shader_defs : @hashmap.HashMap[String, @wgsl_common.ShaderDefValue]
} derive(Eq)

///|
pub(all) struct NagaModuleDescriptor {
  source : String
  file_path : String
  shader_type : ShaderType
  shader_defs : @hashmap.HashMap[String, @wgsl_common.ShaderDefValue]
  additional_imports : Array[@wgsl_common.ImportDefinition]
} derive(Eq)

///|
pub fn Source::language(self : Source) -> ShaderLanguage {
  match self {
    Wgsl(_) => ShaderLanguage::Wgsl
    Wesl(_) => abort("wesl source does not have a naga_oil language")
    Glsl(_, _) => ShaderLanguage::Glsl
    SpirV(_) => abort("spirv source does not have a composable source language")
  }
}

///|
pub fn Source::shader_type(self : Source) -> ShaderType {
  match self {
    Wgsl(_) => ShaderType::Wgsl
    Wesl(_) => abort("wesl source does not have a naga_oil shader type")
    Glsl(_, ShaderStage::Vertex) => ShaderType::GlslVertex
    Glsl(_, ShaderStage::Fragment) => ShaderType::GlslFragment
    Glsl(_, ShaderStage::Compute) =>
      abort("GLSL compute shader type is not yet supported in naga_oil")
    SpirV(_) => abort("spirv source does not have a composable shader type")
  }
}
