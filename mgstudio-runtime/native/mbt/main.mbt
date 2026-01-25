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
const DEFAULT_WASM_PATH : String = "../../../mgstudio-engine/_build/wasm-gc/release/build/examples/runner/runner.wasm"

///|
fn wasm_path_from_args(args : Array[String]) -> String {
  if args.length() >= 2 {
    args[1]
  } else {
    DEFAULT_WASM_PATH
  }
}

///|
fn call_export_from_args(args : Array[String]) -> String? {
  if args.length() >= 3 {
    Some(args[2])
  } else {
    None
  }
}

///|
fn main {
  let args = @sys.get_cli_args()
  let wasm_path = wasm_path_from_args(args)
  let wasm_bytes = @fs.read_file_to_bytes(wasm_path) catch {
    err => {
      @debug.debug("Failed to read wasm: " + wasm_path)
      @debug.debug(err.to_string())
      return
    }
  }
  let wasm_module = @parser.parse_module(wasm_bytes) catch {
    err => {
      @debug.debug("Failed to parse wasm module: " + wasm_path)
      @debug.debug(err.to_string())
      @debug.debug(
        "Note: if you see `invalid heap type` while parsing MoonBit wasm-gc modules, upgrade Milky2018/wasmoon to >= 0.1.3.",
      )
      return
    }
  }
  let ctx = HostContext::new()
  let linker = @runtime.Linker::new()
  add_mgstudio_host_imports(linker, ctx)
  add_moonbit_ffi_imports(linker, ctx)

  // Capture store/instance so host callbacks can call back into the guest.
  ctx.store = Some(linker.get_store())
  let instance = @executor.instantiate_with_linker(
    linker, "runner", wasm_module,
  ) catch {
    err => {
      @debug.debug("Failed to instantiate wasm module: " + wasm_path)
      @debug.debug(@runtime.format_runtime_error(err))
      return
    }
  }
  ctx.instance = Some(instance)
  @debug.debug("WASM instantiated: " + wasm_path)
  if call_export_from_args(args) is Some(export_name) {
    @debug.debug("Calling export: " + export_name)
    let result = @executor.call_exported_func(
      ctx.store.unwrap(),
      instance,
      export_name,
      [],
    ) catch {
      err => {
        @debug.debug("Export call failed: " + export_name)
        @debug.debug(@runtime.format_runtime_error(err))
        return
      }
    }
    let rendered : Array[String] = []
    for item in result {
      rendered.push(item.to_string())
    }
    @debug.debug(rendered)
  } else {
    @debug.debug("No export specified. Usage:")
    @debug.debug(
      "  mgstudio-runtime-native <path/to/runner.wasm> <export_name>",
    )
    @debug.debug("Example:")
    @debug.debug("  mgstudio-runtime-native " + wasm_path + " run_sprite")
  }
}
