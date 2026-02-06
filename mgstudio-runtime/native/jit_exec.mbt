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
/// JIT execution glue for the native runtime.
///
/// This intentionally keeps the interpreter instantiation path (for `start` and
/// module state initialization) and then switches to JIT for hot execution.

///|
pub(all) suberror NativeJitSetupError {
  UnsupportedModule(String)
  JitLoadFailed(String)
  MemoryInitFailed
  GlobalsAllocFailed
  MissingJitTable(Int)
  MissingCHeap
} derive(Show)

///|
/// Prepared JIT state for a module instance.
///
/// Note: `globals_ptr` is allocated via `@jit.alloc_memory` and must be freed
/// by the embedder (JIT does not own it).
pub struct PreparedJit {
  jm : @jit.JITModule
  globals_ptr : Int64
}

///|
fn store_addr_to_module_func_idx(
  instance : @runtime.ModuleInstance,
  store_addr : Int,
) -> Int? {
  for i in 0..<instance.func_addrs.length() {
    if instance.func_addrs[i] == store_addr {
      return Some(i)
    }
  }
  None
}

///|
/// Convert 8 bytes from Bytes at given offset to Int64 (little-endian).
fn bytes_to_int64_le(bytes : Bytes, offset : Int) -> Int64 {
  let b0 = bytes[offset].to_int64() & 0xFFL
  let b1 = bytes[offset + 1].to_int64() & 0xFFL
  let b2 = bytes[offset + 2].to_int64() & 0xFFL
  let b3 = bytes[offset + 3].to_int64() & 0xFFL
  let b4 = bytes[offset + 4].to_int64() & 0xFFL
  let b5 = bytes[offset + 5].to_int64() & 0xFFL
  let b6 = bytes[offset + 6].to_int64() & 0xFFL
  let b7 = bytes[offset + 7].to_int64() & 0xFFL
  b0 |
  (b1 << 8) |
  (b2 << 16) |
  (b3 << 24) |
  (b4 << 32) |
  (b5 << 40) |
  (b6 << 48) |
  (b7 << 56)
}

///|
fn clamp_opt_level(level : Int) -> Int {
  if level < 0 {
    0
  } else if level > 3 {
    3
  } else {
    level
  }
}

///|
fn read_env_int(key : String, default_ : Int) -> Int {
  match @sys.get_env_var(key) {
    Some(v) => {
      let s = v.trim()
      if s == "" {
        default_
      } else {
        @strconv.parse_int(s) catch {
          _ => default_
        }
      }
    }
    None => default_
  }
}

///|
fn is_jit_trace_enabled() -> Bool {
  match @sys.get_env_var("MGSTUDIO_NATIVE_JIT_TRACE") {
    Some(v) if v.trim() != "" => true
    _ => false
  }
}

///|
fn jit_trace(msg : String) -> Unit {
  if is_jit_trace_enabled() {
    @debug.debug("[jit-trace] " + msg)
  }
}

///|
fn read_env_bool(key : String, default_ : Bool) -> Bool {
  match @sys.get_env_var(key) {
    Some(v) => {
      let normalized = v.trim().to_lower()
      if normalized == "" {
        default_
      } else if normalized == "0" ||
        normalized == "false" ||
        normalized == "off" ||
        normalized == "no" {
        false
      } else {
        true
      }
    }
    None => default_
  }
}

///|
fn should_show_jit_progress(total_codes : Int) -> Bool {
  let default_enabled = total_codes >= 32
  read_env_bool("MGSTUDIO_NATIVE_JIT_PROGRESS", default_enabled)
}

///|
fn should_include_start_in_jit() -> Bool {
  read_env_bool("MGSTUDIO_NATIVE_JIT_INCLUDE_START", false)
}

///|
fn should_force_indirect_jit_calls(total_codes : Int) -> Bool {
  let default_enabled = total_codes >= 1024
  read_env_bool("MGSTUDIO_NATIVE_JIT_FORCE_INDIRECT_CALLS", default_enabled)
}

///|
fn render_jit_progress_bar(done : Int, total : Int, width : Int) -> String {
  if total <= 0 {
    return "[" + "#".repeat(width) + "]"
  }
  let clamped_done = if done < 0 {
    0
  } else if done > total {
    total
  } else {
    done
  }
  let filled = clamped_done * width / total
  "[" + "#".repeat(filled) + "-".repeat(width - filled) + "]"
}

///|
fn print_jit_progress(done : Int, total : Int) -> Unit {
  let percent = if total <= 0 { 100 } else { done * 100 / total }
  println(
    "[jit-progress] compile " +
    render_jit_progress_bar(done, total, 32) +
    " " +
    done.to_string() +
    "/" +
    total.to_string() +
    " (" +
    percent.to_string() +
    "%)",
  )
}

///|
fn join_strings(values : Array[String], sep : String) -> String {
  let mut out = ""
  for i, value in values {
    if i != 0 {
      out = out + sep
    }
    out = out + value
  }
  out
}

///|
fn format_list_with_limit(values : Array[String], limit : Int) -> String {
  if values.is_empty() {
    return "(none)"
  }
  let shown : Array[String] = []
  for value in values {
    if shown.length() >= limit {
      break
    }
    shown.push(value)
  }
  let mut suffix = ""
  if values.length() > shown.length() {
    suffix = " ... +" + (values.length() - shown.length()).to_string()
  }
  join_strings(shown, ", ") + suffix
}

///|
fn summarize_external_imports(
  external_imports : Map[String, Map[String, Int64]],
) -> (Int, Int, Int) {
  let module_count = external_imports.length()
  let mut func_count = 0
  let mut hostcall_count = 0
  for _, by_name in external_imports {
    func_count = func_count + by_name.length()
    for _, ptr in by_name {
      if ptr < 0L {
        hostcall_count = hostcall_count + 1
      }
    }
  }
  (module_count, func_count, hostcall_count)
}

///|
fn collect_missing_imports(
  wasm_module : @types.Module,
  external_imports : Map[String, Map[String, Int64]],
) -> Array[String] {
  let missing : Array[String] = []
  for imp in wasm_module.imports {
    if imp.desc is @types.ImportDesc::Func(_) {
      let has_builtin = @jit.get_import_trampoline(imp.mod_name, imp.name)
        is Some(_)
      let has_external = match external_imports.get(imp.mod_name) {
        Some(by_name) => by_name.get(imp.name) is Some(_)
        None => false
      }
      if !has_builtin && !has_external {
        missing.push(imp.mod_name + "." + imp.name)
      }
    }
  }
  missing
}

///|
fn collect_import_signature_mismatches(
  pc : @cwasm.PrecompiledModule,
  func_signatures : Array[(Array[@types.ValueType], Array[@types.ValueType])],
) -> Array[String] {
  let mismatches : Array[String] = []
  for i, imp in pc.imports {
    if i >= func_signatures.length() {
      mismatches.push(
        imp.module_name +
        "." +
        imp.func_name +
        " signature missing at index " +
        i.to_string(),
      )
      continue
    }
    let (params, results) = func_signatures[i]
    if params.length() != imp.num_params || results.length() != imp.num_results {
      mismatches.push(
        imp.module_name +
        "." +
        imp.func_name +
        " expected " +
        imp.num_params.to_string() +
        "->" +
        imp.num_results.to_string() +
        " but got " +
        params.length().to_string() +
        "->" +
        results.length().to_string(),
      )
    }
  }
  mismatches
}

///|
fn collect_empty_compiled_functions(
  pc : @cwasm.PrecompiledModule,
) -> Array[String] {
  let empty_funcs : Array[String] = []
  for entry in pc.functions {
    if entry.code.is_empty() {
      empty_funcs.push(entry.func_idx.to_string() + ":" + entry.name)
    }
  }
  empty_funcs
}

///|
fn build_jit_load_failure_message(
  wasm_module : @types.Module,
  pc : @cwasm.PrecompiledModule,
  func_signatures : Array[(Array[@types.ValueType], Array[@types.ValueType])],
  external_imports : Map[String, Map[String, Int64]],
) -> String {
  let func_imports = @wast.count_func_imports(wasm_module.imports)
  let total_funcs = func_imports + wasm_module.funcs.length()
  let (external_modules, external_funcs, external_hostcalls) = summarize_external_imports(
    external_imports,
  )
  let missing_imports = collect_missing_imports(wasm_module, external_imports)
  let signature_mismatches = collect_import_signature_mismatches(
    pc, func_signatures,
  )
  let empty_compiled_funcs = collect_empty_compiled_functions(pc)
  let summary = "JIT module load failed.\n" +
    "stats: wasm_import_funcs=" +
    func_imports.to_string() +
    ", precompiled_imports=" +
    pc.imports.length().to_string() +
    ", wasm_local_funcs=" +
    wasm_module.funcs.length().to_string() +
    ", wasm_codes=" +
    wasm_module.codes.length().to_string() +
    ", precompiled_funcs=" +
    pc.functions.length().to_string() +
    ", total_funcs_expected=" +
    total_funcs.to_string() +
    ", func_signatures=" +
    func_signatures.length().to_string() +
    ", external_modules=" +
    external_modules.to_string() +
    ", external_funcs=" +
    external_funcs.to_string() +
    ", external_hostcalls=" +
    external_hostcalls.to_string()
  let details = "\nmissing_imports: " +
    format_list_with_limit(missing_imports, 8) +
    "\nimport_signature_mismatches: " +
    format_list_with_limit(signature_mismatches, 8) +
    "\nempty_compiled_functions: " +
    format_list_with_limit(empty_compiled_funcs, 8)
  let hints = "\nhints: set MGSTUDIO_NATIVE_JIT_TRACE=1 for per-stage logs; " +
    "set MGSTUDIO_NATIVE_NO_JIT=1 to run with interpreter fallback."
  summary + details + hints
}

///|
fn build_start_stub_compiled_function(
  func_name : String,
) -> @vcode.CompiledFunction {
  let mc = @emit.MachineCode::new()
  mc.emit_ret(30)
  @vcode.CompiledFunction::new(func_name, mc, 0)
}

///|
fn compile_module_to_precompiled(
  wasm_module : @types.Module,
  opt_level : Int,
  actual_memory_max? : Int? = None,
) -> @cwasm.PrecompiledModule {
  if is_jit_trace_enabled() {
    let total_codes = wasm_module.codes.length()
    jit_trace(
      "compile_module_to_precompiled: opt_level=" +
      opt_level.to_string() +
      " codes=" +
      total_codes.to_string(),
    )
  }
  let precompiled = @cwasm.PrecompiledModule::new(@cwasm.AArch64)

  // Record imported functions (needed for import trampolines and func table).
  for imp in wasm_module.imports {
    if imp.desc is @types.ImportDesc::Func(type_idx) {
      let ft = wasm_module.get_func_type(type_idx)
      precompiled.add_import(
        imp.mod_name,
        imp.name,
        ft.params.length(),
        ft.results.length(),
      )
    }
  }
  let num_func_imports = @wast.count_func_imports(wasm_module.imports)
  let normalized = clamp_opt_level(opt_level)
  let start_func_idx = wasm_module.start
  let include_start_in_jit = should_include_start_in_jit()
  let force_indirect_calls = should_force_indirect_jit_calls(
    wasm_module.codes.length(),
  )
  let lowering_num_imports = if force_indirect_calls {
    -1
  } else {
    num_func_imports
  }
  if is_jit_trace_enabled() {
    jit_trace(
      "lowering_num_imports=" +
      lowering_num_imports.to_string() +
      " (force_indirect_calls=" +
      force_indirect_calls.to_string() +
      ")",
    )
  }

  // Compile local functions.
  let total_codes = wasm_module.codes.length()
  let progress_enabled = should_show_jit_progress(total_codes)
  let mut last_progress_percent = -1
  if progress_enabled {
    if total_codes == 0 {
      print_jit_progress(0, 0)
    } else {
      print_jit_progress(0, total_codes)
    }
  }
  for i, _ in wasm_module.codes {
    let func_idx = num_func_imports + i
    let func_name = @wast.get_func_name(wasm_module, func_idx)
    if !include_start_in_jit &&
      start_func_idx is Some(start_idx) &&
      start_idx == func_idx {
      if is_jit_trace_enabled() {
        jit_trace(
          "use stub JIT body for start function func_idx=" +
          func_idx.to_string(),
        )
      }
      let type_idx = wasm_module.funcs[i]
      let ft = wasm_module.get_func_type(type_idx)
      let compiled = build_start_stub_compiled_function(func_name)
      precompiled.add_function(
        func_idx,
        func_name,
        compiled,
        ft.params.length(),
        ft.results.length(),
      )
      if progress_enabled && total_codes > 0 {
        let done = i + 1
        let percent = done * 100 / total_codes
        if done == total_codes || percent >= last_progress_percent + 2 {
          print_jit_progress(done, total_codes)
          last_progress_percent = percent
        }
      }
      continue
    }
    if is_jit_trace_enabled() {
      // Avoid overly chatty output; enough to see progress or where we stall.
      if i == 0 || i == total_codes - 1 || i % 200 == 0 {
        jit_trace(
          "compiling code " +
          i.to_string() +
          "/" +
          total_codes.to_string() +
          " (func_idx=" +
          func_idx.to_string() +
          " name=" +
          func_name +
          ")",
        )
      }
    }
    let trace_stages = is_jit_trace_enabled() &&
      (i == 0 || i == total_codes - 1)
    if trace_stages {
      jit_trace(
        "  stage: translate_function begin (func_idx=" +
        func_idx.to_string() +
        ")",
      )
    }
    let ir_func = @ir.translate_function(
      wasm_module,
      i,
      name=func_name,
      memory_max_override=actual_memory_max,
    )
    if trace_stages {
      jit_trace(
        "  stage: optimize begin (func_idx=" + func_idx.to_string() + ")",
      )
    }
    @ir.optimize_with_level(ir_func, @ir.OptLevel::from_int(normalized))
    |> ignore
    if trace_stages {
      jit_trace(
        "  stage: lower_function begin (func_idx=" + func_idx.to_string() + ")",
      )
    }
    let vcode = @lower.lower_function(ir_func, num_imports=lowering_num_imports)
    if trace_stages {
      let blocks = vcode.get_blocks()
      let mut insts = 0
      for b in blocks {
        insts = insts + b.insts.length()
      }
      // These numbers help diagnose pathological regalloc behavior.
      jit_trace(
        "  vcode stats: blocks=" +
        blocks.length().to_string() +
        " insts=" +
        insts.to_string() +
        " next_vreg_id=" +
        vcode.next_vreg_id.to_string(),
      )
      jit_trace(
        "  stage: regalloc begin (func_idx=" + func_idx.to_string() + ")",
      )
    }
    let allocated = @regalloc.allocate_registers_backtracking(vcode)
    if trace_stages {
      jit_trace(
        "  stage: emit_function begin (func_idx=" + func_idx.to_string() + ")",
      )
    }
    let mc = @emit.emit_function(
      allocated,
      debug_func_idx=None,
      force_frame_setup=false,
    )
    if trace_stages {
      jit_trace(
        "  stage: add_function begin (func_idx=" + func_idx.to_string() + ")",
      )
    }
    let compiled = @vcode.CompiledFunction::new(func_name, mc, 0)
    let type_idx = wasm_module.funcs[i]
    let ft = wasm_module.get_func_type(type_idx)
    precompiled.add_function(
      func_idx,
      func_name,
      compiled,
      ft.params.length(),
      ft.results.length(),
    )
    if progress_enabled && total_codes > 0 {
      let done = i + 1
      let percent = done * 100 / total_codes
      if done == total_codes || percent >= last_progress_percent + 2 {
        print_jit_progress(done, total_codes)
        last_progress_percent = percent
      }
    }
    if trace_stages {
      jit_trace("  stage: done (func_idx=" + func_idx.to_string() + ")")
    }
  }
  precompiled
}

///|
fn alloc_and_init_jit_globals(
  instance : @runtime.ModuleInstance,
  store : @runtime.Store,
  jit_module : @jit.JITModule,
) -> Int64 {
  let n = instance.global_addrs.length()
  if n == 0 {
    return 0L
  }
  let globals_ptr = @jit.alloc_memory((n * 16).to_int64())
  if globals_ptr == 0L {
    return 0L
  }
  for i in 0..<n {
    let global_addr = instance.global_addrs[i]
    let global_inst = store.globals[global_addr]
    let ty = global_inst.get_type().value_type
    let v = global_inst.get()
    let (lo, hi) : (Int64, Int64?) = match ty {
      I32 =>
        match v {
          I32(x) => (@types.ToInt64::to_int64_bits(x), None)
          _ => (0L, None)
        }
      I64 =>
        match v {
          I64(x) => (@types.ToInt64::to_int64_bits(x), None)
          _ => (0L, None)
        }
      F32 =>
        match v {
          F32(x) => (@types.ToInt64::to_int64_bits(x), None)
          _ => (0L, None)
        }
      F64 =>
        match v {
          F64(x) => (@types.ToInt64::to_int64_bits(x), None)
          _ => (0L, None)
        }
      V128 =>
        match v {
          V128(bytes) =>
            if bytes.length() >= 16 {
              let lo = bytes_to_int64_le(bytes, 0)
              let hi = bytes_to_int64_le(bytes, 8)
              (lo, Some(hi))
            } else {
              (0L, Some(0L))
            }
          _ => (0L, Some(0L))
        }
      FuncRef | RefFunc | RefFuncTyped(_) | RefNullFuncTyped(_) | NullFuncRef =>
        match v {
          Null => (@types.NULL_REF, None)
          FuncRef(store_addr) =>
            match store_addr_to_module_func_idx(instance, store_addr) {
              Some(mod_idx) => {
                let ptr = jit_module.get_func_ptr(mod_idx)
                if ptr == 0L {
                  (@types.NULL_REF, None)
                } else {
                  (@jit.tag_funcref_ptr(ptr), None)
                }
              }
              None => (@types.NULL_REF, None)
            }
          _ => (@types.NULL_REF, None)
        }
      ExternRef | RefExtern | NullExternRef =>
        match v {
          Null => (@types.NULL_REF, None)
          ExternRef(idx) => (@jit.encode_externref(idx), None)
          _ => (@types.NULL_REF, None)
        }
      ExnRef | NullExnRef =>
        match v {
          Null => (@types.NULL_REF, None)
          ExnRef(idx) => (idx.to_int64(), None)
          _ => (@types.NULL_REF, None)
        }
      StructRef | RefStruct(_) | RefNullStruct(_) | RefStructAbs =>
        match v {
          Null => (@types.NULL_REF, None)
          StructRef(gc_ref) => (@jit.encode_heap_ref(gc_ref), None)
          ArrayRef(gc_ref) => (@jit.encode_heap_ref(gc_ref), None)
          _ => (@types.NULL_REF, None)
        }
      ArrayRef | RefArray(_) | RefNullArray(_) | RefArrayAbs =>
        match v {
          Null => (@types.NULL_REF, None)
          ArrayRef(gc_ref) => (@jit.encode_heap_ref(gc_ref), None)
          StructRef(gc_ref) => (@jit.encode_heap_ref(gc_ref), None)
          _ => (@types.NULL_REF, None)
        }
      AnyRef | NullRef | RefAny | RefEq | RefNullEq =>
        match v {
          Null => (@types.NULL_REF, None)
          I31(n) => (@jit.encode_i31(n), None)
          StructRef(gc_ref) => (@jit.encode_heap_ref(gc_ref), None)
          ArrayRef(gc_ref) => (@jit.encode_heap_ref(gc_ref), None)
          _ => (@types.NULL_REF, None)
        }
      RefI31 | RefNullI31 =>
        match v {
          Null => (@types.NULL_REF, None)
          I31(n) => (@jit.encode_i31(n), None)
          _ => (@types.NULL_REF, None)
        }
      RefNone => (@types.NULL_REF, None)
    }
    let offset = globals_ptr + (i * 16).to_int64()
    @jit.c_jit_write_i64(offset, lo)
    match hi {
      Some(v) => @jit.c_jit_write_i64(offset + 8L, v)
      None => ()
    }
  }
  globals_ptr
}

///|
/// Prepare a JIT module that shares runtime state (memories/tables) with the
/// already-instantiated interpreter instance.
///
/// Returns the JIT module on success.
pub fn prepare_jit_for_instance(
  wasm_module : @types.Module,
  instance : @runtime.ModuleInstance,
  store : @runtime.Store,
) -> PreparedJit raise NativeJitSetupError {
  jit_trace("prepare_jit_for_instance: begin")
  if @wast.has_unsupported_instructions(wasm_module) {
    raise NativeJitSetupError::UnsupportedModule(
      "module contains JIT-unsupported instructions",
    )
  }
  let opt_level = read_env_int("MGSTUDIO_NATIVE_JIT_OPT_LEVEL", 2)
  jit_trace("opt_level=" + opt_level.to_string())
  let actual_memory_max : Int? = if instance.mem_addrs.length() > 0 {
    try {
      let mem = store.get_mem(instance.mem_addrs[0])
      let (_, max) = mem.get_limits()
      max
    } catch {
      _ => None
    }
  } else {
    None
  }
  let actual_memory_max_desc = match actual_memory_max {
    Some(v) => v.to_string()
    None => "(none)".to_string()
  }
  jit_trace("actual_memory_max=" + actual_memory_max_desc)
  jit_trace("compiling module -> precompiled")
  let pc = compile_module_to_precompiled(
    wasm_module,
    opt_level,
    actual_memory_max~,
  )
  jit_trace("building func signatures")
  let func_signatures = @wast.build_func_signatures(wasm_module)
  jit_trace("building external imports")
  let external_imports = @wast.build_external_imports_for_jit(
    wasm_module, instance, store,
  )
  jit_trace("loading JIT module")
  let jit_module = @jit.JITModule::load_with_imports(
    pc, func_signatures, external_imports,
  )
  guard jit_module is Some(jm) else {
    raise NativeJitSetupError::JitLoadFailed(
      build_jit_load_failure_message(
        wasm_module, pc, func_signatures, external_imports,
      ),
    )
  }

  // Enable arbitrary host function imports in JIT mode.
  jit_trace("install hostcall dispatcher")
  @wast.install_jit_hostcall_dispatcher(jm, store, instance)

  // Use an independent wasm stack when possible (better trap behavior and
  // avoids host stack blow-ups).
  jit_trace("alloc wasm stack")
  jm.alloc_wasm_stack(16L * 1024L * 1024L) |> ignore

  // WASI built-ins (no-op for non-WASI modules, but harmless).
  jit_trace("init WASI")
  jm.init_wasi_quiet([], [], [])

  // Share memories via descriptor pointers.
  jit_trace("init jit memories from store")
  guard @wast.init_jit_memories_from_store(instance, store, jm) is Some(_) else {
    raise NativeJitSetupError::MemoryInitFailed
  }

  // Initialize globals from the interpreter state.
  jit_trace("alloc/init globals")
  let globals_ptr = alloc_and_init_jit_globals(instance, store, jm)
  if globals_ptr == 0L && !instance.global_addrs.is_empty() {
    raise NativeJitSetupError::GlobalsAllocFailed
  }
  if globals_ptr != 0L {
    jm.set_globals(globals_ptr)
  }

  // Tables: initialize shared tables from elem segments and then sync the
  // (possibly mutated by start) interpreter tables into JIT tables.
  jit_trace("init elem segments")
  @wast.init_elem_segments(wasm_module, jm, instance, store)
  jit_trace("sync tables to jit")
  @wast.sync_tables_to_jit(instance, store, jm)
  for table_addr in instance.table_addrs {
    if store.get_jit_table(table_addr) is None {
      raise NativeJitSetupError::MissingJitTable(table_addr)
    }
  }

  // GC setup (required for wasm-gc).
  jit_trace("gc_setup")
  match store.c_heap {
    Some(heap) => {
      let canonical = @types.compute_canonical_type_indices(
        store.module_types,
        type_rec_groups=store.module_rec_groups,
      )
      @jit.gc_setup(heap, store.module_types, canonical)
      jm.set_gc_heap(heap.get_ptr())
    }
    None => raise NativeJitSetupError::MissingCHeap
  }
  jit_trace("prepare_jit_for_instance: done")
  PreparedJit::{ jm, globals_ptr }
}

///|
pub fn call_jit_func_by_index(
  jm : @jit.JITModule,
  func_idx : Int,
) -> Bool raise @jit.JITTrap {
  match jm.get_func(func_idx) {
    Some(f) => {
      jm.call_with_context(f, []) |> ignore
      true
    }
    None => false
  }
}
