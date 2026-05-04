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
test "compile package composes registered embedded shader graph" {
  clear_registered_shader_sources()
  register_shader_source(
    "shader/compile/util.wgsl", "#define_import_path test::util\nfn value() -> u32 { return 1u; }\n",
  )
  register_shader_source(
    "shader/compile/root.wgsl", "#import test::util::value\nfn root() -> u32 { return value(); }\n",
  )
  let source = load_preprocessed_wgsl(
    "",
    "shader/compile/root.wgsl",
    @hashmap.HashMap::new(),
    default_shader_value_defines(),
  ) catch {
    err => abort(err.message())
  }
  debug_inspect(source.contains("return 1u"), content="true")
  debug_inspect(source.contains("#import"), content="false")
}

///|
test "compile package keeps unresolved imports structured" {
  clear_registered_shader_sources()
  register_shader_source(
    "shader/compile/missing_root.wgsl", "#import test::missing\nfn root() {}\n",
  )
  let message = load_preprocessed_wgsl(
    "",
    "shader/compile/missing_root.wgsl",
    @hashmap.HashMap::new(),
    default_shader_value_defines(),
  ) catch {
    UnresolvedImport(path) => path
    err => abort("unexpected compile error: \{err.message()}")
  }
  debug_inspect(message, content="\"test::missing\"")
}
