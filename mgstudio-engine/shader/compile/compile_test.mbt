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
    @hashmap.HashMap([]),
    default_shader_value_defines(),
  ) catch {
    err => abort(err.message())
  }
  debug_inspect(source.contains("return 1u"), content="true")
  debug_inspect(source.contains("#import"), content="false")
}

///|
test "compile package applies shader defs inside imported modules" {
  clear_registered_shader_sources()
  register_shader_source(
    "shader/compile/defined_util.wgsl", "#define_import_path test::defined_util\n#ifdef USE_REAL\nfn value() -> u32 { return 7u; }\n#else\nfn value() -> u32 { return 3u; }\n#endif\n",
  )
  register_shader_source(
    "shader/compile/defined_root.wgsl", "#import test::defined_util::value\nfn root() -> u32 { return value(); }\n",
  )
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  defines.set("USE_REAL", true)
  let source = load_preprocessed_wgsl(
    "",
    "shader/compile/defined_root.wgsl",
    defines,
    default_shader_value_defines(),
  ) catch {
    err => abort(err.message())
  }
  debug_inspect(source.contains("return 7u"), content="true")
  debug_inspect(source.contains("return 3u"), content="false")
  debug_inspect(source.contains("#ifdef"), content="false")
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
    @hashmap.HashMap([]),
    default_shader_value_defines(),
  ) catch {
    UnresolvedImport(path) => path
    err => abort("unexpected compile error: \{err.message()}")
  }
  debug_inspect(message, content="\"test::missing\"")
}

///|
test "compile package does not auto-register entry shaders as import modules" {
  clear_registered_shader_sources()
  register_shader_source(
    "shader/compile/util.wgsl", "#define_import_path test::util\nfn value() -> u32 { return 1u; }\n",
  )
  register_shader_source(
    "shader/compile/entry_only.wgsl", "fn root() -> u32 { return 2u; }\n",
  )
  let import_paths = copy_registered_shader_import_module_paths()
  debug_inspect(
    import_paths.get("test::util"),
    content="Some(\"shader/compile/util.wgsl\")",
  )
  debug_inspect(import_paths.get("shader::compile::entry_only"), content="None")

  let source = load_preprocessed_wgsl(
    "",
    "shader/compile/entry_only.wgsl",
    @hashmap.HashMap([]),
    default_shader_value_defines(),
  ) catch {
    err => abort(err.message())
  }
  debug_inspect(source.contains("return 2u"), content="true")
}

///|
test "compile package invalidates persistent shader cache after source update" {
  clear_registered_shader_sources()
  register_shader_source(
    "shader/compile/live_util.wgsl", "#define_import_path test::live_util\nfn value() -> u32 { return 1u; }\n",
  )
  register_shader_source(
    "shader/compile/live_root.wgsl", "#import test::live_util::value\nfn root() -> u32 { return value(); }\n",
  )
  let first = load_preprocessed_wgsl(
    "",
    "shader/compile/live_root.wgsl",
    @hashmap.HashMap([]),
    default_shader_value_defines(),
  ) catch {
    err => abort(err.message())
  }
  debug_inspect(first.contains("return 1u"), content="true")

  register_shader_source(
    "shader/compile/live_util.wgsl", "#define_import_path test::live_util\nfn value() -> u32 { return 7u; }\n",
  )
  let second = load_preprocessed_wgsl(
    "",
    "shader/compile/live_root.wgsl",
    @hashmap.HashMap([]),
    default_shader_value_defines(),
  ) catch {
    err => abort(err.message())
  }
  debug_inspect(second.contains("return 7u"), content="true")
  debug_inspect(second.contains("return 1u"), content="false")
}
