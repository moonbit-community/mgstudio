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
test "naga_oil: composable and naga descriptors default to empty source" {
  let composable = @naga_oil.ComposableModuleDescriptor::default()
  inspect(composable.source, content="")
  inspect(composable.file_path, content="")
  inspect(composable.language, content="Wgsl")
  inspect(composable.as_name, content="None")
  inspect(composable.additional_imports.length(), content="0")
  inspect(composable.shader_defs.length(), content="0")

  let naga = @naga_oil.NagaModuleDescriptor::default()
  inspect(naga.source, content="")
  inspect(naga.file_path, content="")
  inspect(naga.shader_type, content="Wgsl")
  inspect(naga.additional_imports.length(), content="0")
  inspect(naga.shader_defs.length(), content="0")
}
