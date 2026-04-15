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
pub(all) suberror ResolveError {
  FileNotFound(String, String)
  ModuleNotFound(ModulePath, String)
}

///|
pub fn ResolveError::message(self : ResolveError) -> String {
  match self {
    FileNotFound(path, context) => "file not found: `\{path}` (\{context})"
    ModuleNotFound(path, context) =>
      "module not found: `\{path.to_string()}` (\{context})"
  }
}

///|
pub(open) trait Resolver {
  resolve_source(Self, ModulePath) -> String raise ResolveError
}

///|
pub struct VirtualResolver {
  files : @hashmap.HashMap[ModulePath, String]
}

///|
pub fn VirtualResolver::new() -> VirtualResolver {
  VirtualResolver::{ files: @hashmap.HashMap::new() }
}

///|
pub fn VirtualResolver::add_module(
  self : VirtualResolver,
  path : ModulePath,
  source : String,
) -> Unit {
  self.files.set(path, source)
}

///|
pub fn VirtualResolver::get_module(
  self : VirtualResolver,
  path : ModulePath,
) -> String raise ResolveError {
  match self.files.get(path) {
    Some(source) => source
    None => raise ResolveError::ModuleNotFound(path, "virtual module")
  }
}

///|
pub impl Resolver for VirtualResolver with resolve_source(self, path) {
  self.get_module(path)
}
