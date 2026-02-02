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
  JitLoadFailed
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
fn compile_module_to_precompiled(
  wasm_module : @types.Module,
  opt_level : Int,
  actual_memory_max? : Int? = None,
) -> @cwasm.PrecompiledModule {
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

  // Compile local functions.
  for i, _ in wasm_module.codes {
    let func_idx = num_func_imports + i
    let func_name = @wast.get_func_name(wasm_module, func_idx)
    let ir_func = @ir.translate_function(
      wasm_module,
      i,
      name=func_name,
      memory_max_override=actual_memory_max,
    )
    @ir.optimize_with_level(ir_func, @ir.OptLevel::from_int(normalized))
    |> ignore
    let vcode = @lower.lower_function(ir_func, num_imports=num_func_imports)
    let allocated = @regalloc.allocate_registers_backtracking(vcode)
    let mc = @emit.emit_function(
      allocated,
      debug_func_idx=None,
      force_frame_setup=false,
    )
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
  if @wast.has_unsupported_instructions(wasm_module) {
    raise NativeJitSetupError::UnsupportedModule(
      "module contains JIT-unsupported instructions",
    )
  }
  let opt_level = read_env_int("MGSTUDIO_NATIVE_JIT_OPT_LEVEL", 2)
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
  let pc = compile_module_to_precompiled(
    wasm_module,
    opt_level,
    actual_memory_max~,
  )
  let func_signatures = @wast.build_func_signatures(wasm_module)
  let external_imports = @wast.build_external_imports_for_jit(
    wasm_module, instance, store,
  )
  let jit_module = @jit.JITModule::load_with_imports(
    pc, func_signatures, external_imports,
  )
  guard jit_module is Some(jm) else { raise NativeJitSetupError::JitLoadFailed }

  // Enable arbitrary host function imports in JIT mode.
  @wast.install_jit_hostcall_dispatcher(jm, store, instance)

  // Use an independent wasm stack when possible (better trap behavior and
  // avoids host stack blow-ups).
  jm.alloc_wasm_stack(16L * 1024L * 1024L) |> ignore

  // WASI built-ins (no-op for non-WASI modules, but harmless).
  jm.init_wasi_quiet([], [], [])

  // Share memories via descriptor pointers.
  guard @wast.init_jit_memories_from_store(instance, store, jm) is Some(_) else {
    raise NativeJitSetupError::MemoryInitFailed
  }

  // Initialize globals from the interpreter state.
  let globals_ptr = alloc_and_init_jit_globals(instance, store, jm)
  if globals_ptr == 0L && !instance.global_addrs.is_empty() {
    raise NativeJitSetupError::GlobalsAllocFailed
  }
  if globals_ptr != 0L {
    jm.set_globals(globals_ptr)
  }

  // Tables: initialize shared tables from elem segments and then sync the
  // (possibly mutated by start) interpreter tables into JIT tables.
  @wast.init_elem_segments(wasm_module, jm, instance, store)
  @wast.sync_tables_to_jit(instance, store, jm)
  for table_addr in instance.table_addrs {
    if store.get_jit_table(table_addr) is None {
      raise NativeJitSetupError::MissingJitTable(table_addr)
    }
  }

  // GC setup (required for wasm-gc).
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
