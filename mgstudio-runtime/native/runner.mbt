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
  JitSetupFailed(String)
  JitCallFailed(String, String)
} derive(Show)

///|
fn cleanup_jit(ctx : HostContext) -> Unit {
  // gc_teardown is safe to call even if the cache is already cleared.
  match ctx.jit {
    Some(jm) => {
      let ctx_ptr = jm.get_context_ptr()
      if ctx_ptr != 0L {
        @jit.gc_teardown(ctx_ptr)
      }
    }
    None => ()
  }
  if ctx.jit_globals_ptr != 0L {
    @jit.free_memory(ctx.jit_globals_ptr)
    ctx.jit_globals_ptr = 0L
  }
  ctx.jit = None
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
fn is_env_flag_set(key : String) -> Bool {
  match @sys.get_env_var(key) {
    Some(v) if v.trim() != "" => true
    _ => false
  }
}

///|
fn preflight_stage_to_string(stage : @preflight.PreflightStage) -> String {
  match stage {
    @preflight.PreflightStage::Parse => "parse"
    @preflight.PreflightStage::Validate => "validate"
    @preflight.PreflightStage::Translate => "translate"
    @preflight.PreflightStage::Lower => "lower"
    @preflight.PreflightStage::Regalloc => "regalloc"
  }
}

///|
fn preflight_severity_to_string(
  severity : @preflight.PreflightSeverity,
) -> String {
  match severity {
    @preflight.PreflightSeverity::Error => "error"
    @preflight.PreflightSeverity::Warning => "warning"
  }
}

///|
fn log_preflight_result(
  label : String,
  result : @preflight.PreflightResult,
  limit : Int,
) -> Unit {
  @debug.debug(
    "[preflight/" +
    label +
    "] ok=" +
    result.ok.to_string() +
    " checked=" +
    result.checked_funcs.to_string() +
    "/" +
    result.total_funcs.to_string() +
    " diagnostics=" +
    result.diagnostics.length().to_string(),
  )
  for i, diag in result.diagnostics {
    if i >= limit {
      break
    }
    let func_idx = match diag.func_idx {
      Some(v) => v.to_string()
      None => "-"
    }
    let func_name = diag.func_name.unwrap_or("-")
    @debug.debug(
      "[preflight/" +
      label +
      "] " +
      preflight_severity_to_string(diag.severity) +
      "@" +
      preflight_stage_to_string(diag.stage) +
      " func_idx=" +
      func_idx +
      " func_name=" +
      func_name +
      " msg=" +
      diag.message,
    )
  }
  if result.diagnostics.length() > limit {
    @debug.debug(
      "[preflight/" +
      label +
      "] ... +" +
      (result.diagnostics.length() - limit).to_string() +
      " more diagnostics",
    )
  }
}

///|
fn import_diagnostic_kind_to_string(
  kind : @executor.ImportDiagnosticKind,
) -> String {
  match kind {
    @executor.ImportDiagnosticKind::MissingImport => "missing_import"
    @executor.ImportDiagnosticKind::ImportKindMismatch => "kind_mismatch"
    @executor.ImportDiagnosticKind::ImportTypeMismatch => "type_mismatch"
  }
}

///|
fn log_import_diagnostics(
  result : @executor.ImportDiagnosticsResult,
  limit : Int,
) -> Unit {
  @debug.debug(
    "[imports] ok=" +
    result.ok.to_string() +
    " diagnostics=" +
    result.diagnostics.length().to_string(),
  )
  for i, diag in result.diagnostics {
    if i >= limit {
      break
    }
    @debug.debug(
      "[imports] idx=" +
      diag.import_index.to_string() +
      " " +
      diag.module_name +
      "." +
      diag.name +
      " kind=" +
      import_diagnostic_kind_to_string(diag.kind) +
      " expected=" +
      diag.expected +
      " actual=" +
      diag.actual.unwrap_or("(none)") +
      " msg=" +
      diag.message,
    )
  }
  if result.diagnostics.length() > limit {
    @debug.debug(
      "[imports] ... +" +
      (result.diagnostics.length() - limit).to_string() +
      " more diagnostics",
    )
  }
}

///|
fn call_export_failure_kind_to_string(
  kind : @executor.CallExportFailureKind,
) -> String {
  match kind {
    @executor.CallExportFailureKind::ExportNotFound => "export_not_found"
    @executor.CallExportFailureKind::NotFunctionExport => "not_function_export"
    @executor.CallExportFailureKind::Trap => "trap"
    @executor.CallExportFailureKind::HostInvocation => "host_invocation"
    @executor.CallExportFailureKind::Cancelled => "cancelled"
    @executor.CallExportFailureKind::UnsupportedOption => "unsupported_option"
  }
}

///|
fn format_call_export_failure(failure : @executor.CallExportFailure) -> String {
  let mut rendered = call_export_failure_kind_to_string(failure.kind) +
    ": " +
    failure.message
  match failure.runtime_error {
    Some(err) =>
      rendered = rendered + " (" + @runtime.format_runtime_error(err) + ")"
    None => ()
  }
  rendered
}

///|
fn format_jit_trap_report(report : @jit.TrapReport?) -> String {
  match report {
    Some(r) => {
      let wasm_func_idx = match r.wasm_func_idx {
        Some(v) => v.to_string()
        None => "-"
      }
      let wasm_func_name = r.wasm_func_name.unwrap_or("-")
      let wasm_offset = match r.wasm_offset {
        Some(v) => v.to_string()
        None => "-"
      }
      ", trap_kind=" +
      r.trap_kind +
      ", signal=" +
      r.signal_name +
      "(" +
      r.signal.to_string() +
      ")" +
      ", pc=" +
      r.pc.to_string() +
      ", wasm_func=" +
      wasm_func_idx +
      ":" +
      wasm_func_name +
      ", wasm_offset=" +
      wasm_offset +
      ", dump_path=" +
      r.dump_path.unwrap_or("-")
    }
    None => ""
  }
}

///|
fn log_runtime_capabilities(caps : @runtime.RuntimeCapabilities) -> Unit {
  @debug.debug("wasmoon runtime version: " + @runtime.runtime_version())
  @debug.debug(
    "wasmoon capabilities: " +
    "interpreter=" +
    caps.interpreter.to_string() +
    ", jit=" +
    caps.jit.to_string() +
    ", simd=" +
    caps.simd.to_string() +
    ", gc=" +
    caps.gc.to_string() +
    ", component_model=" +
    caps.component_model.to_string() +
    ", wasi_preview1=" +
    caps.wasi_preview1.to_string() +
    ", threads=" +
    caps.threads.to_string(),
  )
}

///|
pub fn run_game(
  wasm_path : String,
  assets_source_spec : String,
  data_source_spec : String,
  wgpu_lib? : String,
) -> Unit raise Error {
  let ctx = HostContext::new(assets_source_spec, data_source_spec)
  try {
    if wasm_path.trim() == "" {
      raise NativeRuntimeError::InvalidWasmPath(wasm_path)
    }
    match wgpu_lib {
      Some(p) if p.trim() != "" =>
        @sys.set_env_var("MBT_WGPU_NATIVE_LIB", p.trim().to_string())
      _ => ()
    }
    let wasm_bytes = @fs.read_file_to_bytes(wasm_path) catch {
      err =>
        raise NativeRuntimeError::ReadWasmFailed(wasm_path, err.to_string())
    }
    let module_preflight = @preflight.validate_module(wasm_bytes)
    if !module_preflight.ok {
      log_preflight_result("module", module_preflight, 16)
      raise NativeRuntimeError::ParseWasmFailed(
        wasm_path, "module preflight validation failed",
      )
    }
    let wasm_module = @parser.parse_module(wasm_bytes) catch {
      err =>
        raise NativeRuntimeError::ParseWasmFailed(wasm_path, err.to_string())
    }
    let start_desc = match wasm_module.start {
      Some(i) => i.to_string()
      None => "(none)"
    }
    @debug.debug("module.start: " + start_desc)
    if is_env_flag_set("MGSTUDIO_NATIVE_DUMP_IMPORTS") {
      dump_func_imports(wasm_module)
    }
    let runtime_caps = @runtime.runtime_capabilities()
    log_runtime_capabilities(runtime_caps)
    let disable_jit_by_env = is_env_flag_set("MGSTUDIO_NATIVE_NO_JIT")
    let use_jit = !disable_jit_by_env && runtime_caps.jit
    if !disable_jit_by_env && !runtime_caps.jit {
      @debug.debug(
        "JIT requested but unavailable in runtime capabilities, fallback to interpreter",
      )
    }
    let store = if use_jit {
      @runtime.Store::with_c_heap()
    } else {
      @runtime.Store::new()
    }
    let linker = @runtime.Linker::with_store(store)
    add_mgstudio_host_imports(linker, ctx)
    add_moonbit_ffi_imports(linker, ctx)

    // Capture store/instance so host callbacks can call back into the guest.
    ctx.store = Some(store)
    let imports = linker.build_imports()
    let instance = match
      @executor.instantiate_module_with_import_diagnostics(
        store, wasm_module, imports,
      ) {
      @executor.InstantiateWithImportDiagnosticsResult::Ok(instance) => {
        linker.register("runner", instance)
        instance
      }
      @executor.InstantiateWithImportDiagnosticsResult::ImportError(diagnostics) => {
        log_import_diagnostics(diagnostics, 16)
        raise NativeRuntimeError::InstantiateFailed(
          wasm_path, "import diagnostics failed",
        )
      }
      @executor.InstantiateWithImportDiagnosticsResult::RuntimeFailure(err) =>
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

    // JIT is the default execution engine. Set `MGSTUDIO_NATIVE_NO_JIT=1` to
    // force the interpreter for debugging.
    if use_jit {
      let prepared = prepare_jit_for_instance(wasm_module, instance, store) catch {
        err => {
          let jit_preflight = @preflight.validate_jit(wasm_bytes)
          log_preflight_result("jit", jit_preflight, 16)
          raise NativeRuntimeError::JitSetupFailed(err.to_string())
        }
      }
      ctx.jit = Some(prepared.jm)
      ctx.jit_globals_ptr = prepared.globals_ptr
    }
    match ctx.jit {
      Some(jm) => {
        @debug.debug("Calling export (JIT): game_app")
        match jm.get_func_by_name("game_app") {
          Some(f) => {
            let result = jm.call_with_context(f, []) catch {
              err =>
                raise NativeRuntimeError::JitCallFailed(
                  "game_app",
                  err.to_string() +
                  format_jit_trap_report(jm.get_last_trap_report()),
                )
            }
            let rendered : Array[String] = []
            for item in result {
              rendered.push(item.to_string())
            }
            @debug.debug(rendered)
          }
          None => raise NativeRuntimeError::MissingExport("game_app")
        }
      }
      None => {
        @debug.debug("Calling export: game_app")
        let result = match
          @executor.call_exported_func_with_options(
            ctx.store.unwrap(),
            instance,
            "game_app",
            [],
            options=@executor.CallExportOptions::new(),
          ) {
          @executor.CallExportResult::Ok(values) => values
          @executor.CallExportResult::Err(failure) =>
            raise NativeRuntimeError::ExportCallFailed(
              "game_app",
              format_call_export_failure(failure),
            )
        }
        let rendered : Array[String] = []
        for item in result {
          rendered.push(item.to_string())
        }
        @debug.debug(rendered)
      }
    }
  } catch {
    err => {
      cleanup_jit(ctx)
      raise err
    }
  }
  cleanup_jit(ctx)
}
