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
fn wasm_path_from_args(args : Array[String]) -> String {
  if args.length() < 2 {
    @debug.debug("Usage:")
    @debug.debug("  mgstudio-runtime-native <path/to/game.wasm>")
    @debug.debug("")
    @debug.debug("Contract:")
    @debug.debug(
      "  The wasm module must export exactly one entrypoint: game_app() -> Unit",
    )
    @sys.exit(2)
    ""
  } else {
    args[1]
  }
}

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
  let start_desc = match wasm_module.start {
    Some(i) => i.to_string()
    None => "(none)"
  }
  @debug.debug("module.start: " + start_desc)
  let dump_imports = match @sys.get_env_var("MGSTUDIO_NATIVE_DUMP_IMPORTS") {
    Some(v) if v != "" => true
    _ => false
  }
  if dump_imports {
    dump_func_imports(wasm_module)
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
  let trace = match @sys.get_env_var("MGSTUDIO_NATIVE_TRACE") {
    Some(v) if v != "" => true
    _ => false
  }
  if trace && ctx.store is Some(store) {
    // Extra debug: print a few function types referenced by the runner bring-up.
    let interesting : Array[Int] = [
      53, 51, 377, 378, 379, 383, 384, 388, 389, 391, 392, 479, 583, 669,
    ]
    for idx in interesting {
      if idx >= 0 && idx < instance.func_addrs.length() {
        let addr = instance.func_addrs[idx]
        try {
          let ty = store.get_func_type(addr)
          @debug.debug(
            "trace: func[" + idx.to_string() + "].type=" + ty.to_string(),
          )
        } catch {
          err =>
            @debug.debug(
              "trace: func[" +
              idx.to_string() +
              "].type failed: " +
              @runtime.format_runtime_error(err),
            )
        }
      }
    }
    // Print the wrapper that creates the window (this is where we currently trap).
    if 391 >= 0 && 391 < instance.func_addrs.length() {
      try {
        let inst391 = store.get_func_inst(instance.func_addrs[391])
        @debug.debug("trace: func[391].inst=" + inst391.to_string())
      } catch {
        err =>
          @debug.debug(
            "trace: func[391].inst failed: " +
            @runtime.format_runtime_error(err),
          )
      }
    }
    if 392 >= 0 && 392 < instance.func_addrs.length() {
      try {
        let inst392 = store.get_func_inst(instance.func_addrs[392])
        @debug.debug("trace: func[392].inst=" + inst392.to_string())
      } catch {
        err =>
          @debug.debug(
            "trace: func[392].inst failed: " +
            @runtime.format_runtime_error(err),
          )
      }
    }
    if 583 >= 0 && 583 < instance.func_addrs.length() {
      try {
        let inst583 = store.get_func_inst(instance.func_addrs[583])
        @debug.debug("trace: func[583].inst=" + inst583.to_string())
      } catch {
        err =>
          @debug.debug(
            "trace: func[583].inst failed: " +
            @runtime.format_runtime_error(err),
          )
      }
    }
    if 51 >= 0 && 51 < instance.func_addrs.length() {
      try {
        let inst51 = store.get_func_inst(instance.func_addrs[51])
        @debug.debug("trace: func[51].inst=" + inst51.to_string())
      } catch {
        err =>
          @debug.debug(
            "trace: func[51].inst failed: " + @runtime.format_runtime_error(err),
          )
      }
    }
    // Replay the first part of the runner bring-up (window/device/surface)
    // to narrow down where the `unreachable` trap happens.
    try {
      let out53 = @executor.call_func_by_index(store, instance, 53, [
        @types.Value::I32(52),
        @types.Value::I32(1130),
        @types.Value::I32(16),
      ])
      @debug.debug("trace: call 53 ok: " + out53.to_string())
      if out53.length() >= 1 && out53[0] is @types.Value::ArrayRef(arr_ref) {
        try {
          let out391 = @executor.call_func_by_index(store, instance, 391, [
            @types.Value::I32(800),
            @types.Value::I32(600),
            @types.Value::ArrayRef(arr_ref),
          ])
          @debug.debug("trace: call 391 ok: " + out391.to_string())
          if out391.length() >= 1 &&
            out391[0] is @types.Value::ExternRef(win_ref) {
            // func[383] likely performs a window-side initialization.
            try {
              let out383 = @executor.call_func_by_index(store, instance, 383, [
                @types.Value::ExternRef(win_ref),
              ])
              @debug.debug("trace: call 383 ok: " + out383.to_string())
            } catch {
              err =>
                @debug.debug(
                  "trace: call 383 failed: " +
                  @runtime.format_runtime_error(err),
                )
            }

            // func[379]/[378] look like device/surface construction.
            try {
              let out379 = @executor.call_func_by_index(store, instance, 379, [])
              @debug.debug("trace: call 379 ok: " + out379.to_string())
            } catch {
              err =>
                @debug.debug(
                  "trace: call 379 failed: " +
                  @runtime.format_runtime_error(err),
                )
            }
            try {
              let out378 = @executor.call_func_by_index(store, instance, 378, [
                @types.Value::ExternRef(win_ref),
              ])
              @debug.debug("trace: call 378 ok: " + out378.to_string())
            } catch {
              err =>
                @debug.debug(
                  "trace: call 378 failed: " +
                  @runtime.format_runtime_error(err),
                )
            }
          }
        } catch {
          err =>
            @debug.debug(
              "trace: call 391 failed: " + @runtime.format_runtime_error(err),
            )
        }
      }
    } catch {
      err =>
        @debug.debug(
          "trace: call 53 failed: " + @runtime.format_runtime_error(err),
        )
    }
    // Debug helper: narrow down where the guest entrypoint traps by replaying
    // the same call chain with intermediate checks.
    try {
      let g85 = if instance.global_addrs.length() > 85 {
        store.get_global(instance.global_addrs[85]).get()
      } else {
        @types.Value::Null
      }
      @debug.debug("trace: global[85]=" + g85.to_string())
      if wasm_module.globals.length() > 85 {
        let gi = wasm_module.globals[85]
        @debug.debug("trace: module.global[85].type=" + gi.type_.to_string())
        @debug.debug("trace: module.global[85].init=" + gi.init.to_string())
      }
      let g65 = if instance.global_addrs.length() > 65 {
        store.get_global(instance.global_addrs[65]).get()
      } else {
        @types.Value::Null
      }
      @debug.debug("trace: global[65]=" + g65.to_string())
      let g22 = if instance.global_addrs.length() > 22 {
        store.get_global(instance.global_addrs[22]).get()
      } else {
        @types.Value::Null
      }
      @debug.debug("trace: global[22]=" + g22.to_string())
      let plugins_out = @executor.call_func_by_index(store, instance, 177, [])
      let plugins = if plugins_out.length() >= 1 {
        plugins_out[0]
      } else {
        @types.Value::Null
      }
      @debug.debug("trace: plugins=" + plugins.to_string())
      let world_out = @executor.call_func_by_index(store, instance, 168, [])
      let world = if world_out.length() >= 1 {
        world_out[0]
      } else {
        @types.Value::Null
      }
      @debug.debug("trace: world=" + world.to_string())
      let app_out = @executor.call_func_by_index(store, instance, 491, [world])
      let app = if app_out.length() >= 1 {
        app_out[0]
      } else {
        @types.Value::Null
      }
      @debug.debug("trace: app=" + app.to_string())
      let app2_out = @executor.call_func_by_index(store, instance, 490, [
        app, plugins,
      ])
      let app2 = if app2_out.length() >= 1 {
        app2_out[0]
      } else {
        @types.Value::Null
      }
      @debug.debug("trace: app+plugins=" + app2.to_string())
      let app3_out = @executor.call_func_by_index(store, instance, 489, [
        app2, g65,
      ])
      let app3 = if app3_out.length() >= 1 {
        app3_out[0]
      } else {
        @types.Value::Null
      }
      @debug.debug("trace: app+runner=" + app3.to_string())
      // Inspect app.runner before executing it (func 477).
      try {
        if app3 is @types.Value::StructRef(app_ref) {
          let runner_opt = store.struct_get(app_ref, 2)
          @debug.debug("trace: app.runner_opt=" + runner_opt.to_string())
          if runner_opt is @types.Value::StructRef(opt_ref) {
            let tag = store.struct_get(opt_ref, 0)
            @debug.debug("trace: app.runner_tag=" + tag.to_string())
            let payload = store.struct_get(opt_ref, 1)
            @debug.debug("trace: app.runner_payload=" + payload.to_string())
            if payload is @types.Value::StructRef(payload_ref) {
              let func_ref = store.struct_get(payload_ref, 0)
              @debug.debug("trace: app.runner_func_ref=" + func_ref.to_string())
              let env = store.struct_get(payload_ref, 1)
              @debug.debug("trace: app.runner_env=" + env.to_string())
              if func_ref is @types.Value::FuncRef(addr) {
                try {
                  let inst = store.get_func_inst(addr)
                  let ty = store.get_func_type(addr)
                  let owner_idx = store.get_func_owner_idx(addr)
                  @debug.debug("trace: runner.func_inst=" + inst.to_string())
                  @debug.debug("trace: runner.func_type=" + ty.to_string())
                  @debug.debug(
                    "trace: runner.owner_idx=" + owner_idx.to_string(),
                  )
                  // Best-effort: map store function address back to module func_idx.
                  let mut found = -1
                  for i in 0..<instance.func_addrs.length() {
                    if instance.func_addrs[i] == addr {
                      found = i
                      break
                    }
                  }
                  @debug.debug("trace: runner.func_idx=" + found.to_string())
                  if found >= 0 {
                    let _ = @executor.call_func_by_index(
                      store,
                      instance,
                      found,
                      [@types.Value::StructRef(payload_ref)],
                    )
                    @debug.debug("trace: runner direct call ok")
                  }
                } catch {
                  err =>
                    @debug.debug(
                      "trace: runner func_inst/type failed: " +
                      @runtime.format_runtime_error(err),
                    )
                }
              }
            }
          }
        }
      } catch {
        err => @debug.debug("trace: runner inspect failed: " + err.to_string())
      }
      let _ = @executor.call_func_by_index(store, instance, 477, [app3])
      @debug.debug("trace: call 477 ok")
    } catch {
      err => @debug.debug("trace failed: " + @runtime.format_runtime_error(err))
    }
  }
  @debug.debug("Calling export: game_app")
  let result = @executor.call_exported_func(
    ctx.store.unwrap(),
    instance,
    "game_app",
    [],
  ) catch {
    err => {
      @debug.debug("Export call failed: game_app")
      @debug.debug(@runtime.format_runtime_error(err))
      return
    }
  }
  let rendered : Array[String] = []
  for item in result {
    rendered.push(item.to_string())
  }
  @debug.debug(rendered)
}
