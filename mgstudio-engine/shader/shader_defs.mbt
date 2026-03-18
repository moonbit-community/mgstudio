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
pub(all) enum ValidateShader {
  Disabled
  Enabled
} derive(Eq, Show)

///|
pub fn ValidateShader::default() -> ValidateShader {
  ValidateShader::Disabled
}

///|
pub(all) enum ShaderStage {
  Vertex
  Fragment
  Compute
} derive(Eq, Show)

///|
pub(all) enum ShaderDefVal {
  Bool(String, Bool)
  Int(String, Int)
  UInt(String, UInt)
} derive(Eq, Hash, Show)

///|
pub fn shader_def(name : String) -> ShaderDefVal {
  ShaderDefVal::Bool(name, true)
}

///|
pub fn ShaderDefVal::name(self : ShaderDefVal) -> String {
  match self {
    Bool(name, _) => name
    Int(name, _) => name
    UInt(name, _) => name
  }
}

///|
pub fn ShaderDefVal::value_as_string(self : ShaderDefVal) -> String {
  match self {
    Bool(_, value) => value.to_string()
    Int(_, value) => value.to_string()
    UInt(_, value) => value.to_string()
  }
}
