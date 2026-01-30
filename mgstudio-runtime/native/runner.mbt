// Copyright 2025 International Digital Economy Academy
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
pub(all) suberror NativeRuntimeError {
  InvalidWasmPath(String)
  ReadWasmFailed(String, String)
  ParseWasmFailed(String, String)
  InstantiateFailed(String, String)
  MissingExport(String)
  ExportCallFailed(String, String)
} derive(Show)

///|
fn dump_func_imports(mod_ : @types.Module) -> Unit {
  let mut func_idx = 0
  for imp in mod_.imports {
    match imp.desc {
      @types.ImportDesc::Func(type_idx) => {
        let ty = if type_idx >= 0 && type_idx < mod_.types.length() {
          let st = mod_.types[type_idx]
          match st.composite {
            @types.CompositeType::Func(ft) => ft.to_string()
            _ => "(non-func type?)"
          }
        } else {
          "(invalid type idx)"
        }
        @debug.debug(
          "import func[" +
          func_idx.to_string() +
          "] " +
          imp.mod_name +
          "." +
          imp.name +
          " type[" +
          type_idx.to_string() +
          "] " +
          ty,
        )
        func_idx = func_idx + 1
      }
      _ => ()
    }
  }
}

///|
fn is_env_flag_set(key : String) -> Bool {
  match @sys.get_env_var(key) {
    Some(v) if v.trim() != "" => true
    _ => false
  }
}

///|
pub fn run_game(
  wasm_path : String,
  assets_source_spec : String,
  data_source_spec : String,
  wgpu_lib? : String,
) -> Unit raise Error {
  if wasm_path.trim() == "" {
    raise NativeRuntimeError::InvalidWasmPath(wasm_path)
  }
  match wgpu_lib {
    Some(p) if p.trim() != "" =>
      @sys.set_env_var("MBT_WGPU_NATIVE_LIB", p.trim().to_string())
    _ => ()
  }
  let wasm_bytes = @fs.read_file_to_bytes(wasm_path) catch {
    err => raise NativeRuntimeError::ReadWasmFailed(wasm_path, err.to_string())
  }
  let wasm_module = @parser.parse_module(wasm_bytes) catch {
    err => raise NativeRuntimeError::ParseWasmFailed(wasm_path, err.to_string())
  }
  let start_desc = match wasm_module.start {
    Some(i) => i.to_string()
    None => "(none)"
  }
  @debug.debug("module.start: " + start_desc)
  if is_env_flag_set("MGSTUDIO_NATIVE_DUMP_IMPORTS") {
    dump_func_imports(wasm_module)
  }
  let ctx = HostContext::new(assets_source_spec, data_source_spec)
  let linker = @runtime.Linker::new()
  add_mgstudio_host_imports(linker, ctx)
  add_moonbit_ffi_imports(linker, ctx)

  // Capture store/instance so host callbacks can call back into the guest.
  ctx.store = Some(linker.get_store())
  let instance = @executor.instantiate_with_linker(
    linker, "runner", wasm_module,
  ) catch {
    err =>
      raise NativeRuntimeError::InstantiateFailed(
        wasm_path,
        @runtime.format_runtime_error(err),
      )
  }
  ctx.instance = Some(instance)
  @debug.debug("WASM instantiated: " + wasm_path)
  if is_env_flag_set("MGSTUDIO_NATIVE_DUMP_GUEST_GLOBALS") {
    try {
      let store = ctx.store.unwrap()
      // These globals are commonly used by MoonBit runtime init and should be
      // non-null after `start` runs. Useful for diagnosing start/init issues.
      for idx in [33, 40, 41] {
        if idx >= 0 && idx < instance.global_addrs.length() {
          let addr = instance.global_addrs[idx]
          let v = store.get_global(addr).get()
          @debug.debug("guest global[\{idx}] = \{v.to_string()}")
        }
      }
    } catch {
      err => @debug.debug("dump globals failed: " + err.to_string())
    }
  }

  // Contract: the game module exports exactly one entrypoint `game_app`.
  let mut has_entry = false
  for ex in instance.exports {
    if ex.name == "game_app" {
      has_entry = true
      break
    }
  }
  if !has_entry {
    raise NativeRuntimeError::MissingExport("game_app")
  }
  @debug.debug("Calling export: game_app")
  let result = @executor.call_exported_func(
    ctx.store.unwrap(),
    instance,
    "game_app",
    [],
  ) catch {
    err =>
      raise NativeRuntimeError::ExportCallFailed(
        "game_app",
        @runtime.format_runtime_error(err),
      )
  }
  let rendered : Array[String] = []
  for item in result {
    rendered.push(item.to_string())
  }
  @debug.debug(rendered)
}
