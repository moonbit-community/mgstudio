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
/// Native host stubs for `mgstudio_host` and `moonbit:ffi`.
///
/// This is a "bring-up" implementation: enough to instantiate and start running
/// the wasm-gc build. Real window/GPU/input implementations will be added later.
///
/// Important: the wasm imports' signatures must match the game's wasm import
/// section; otherwise instantiation fails.

///|
pub struct HostContext {
  mut store : @runtime.Store?
  mut instance : @runtime.ModuleInstance?
  mut jit : @jit.JITModule?
  // Owned JIT globals backing store (allocated via @jit.alloc_memory). JIT does
  // not free it, so the runtime must free it on shutdown.
  mut jit_globals_ptr : Int64
  mut gpu : GpuBackend?
  mut window : @win.Window?
  assets_source : @rtcore.SourceSpec
  data_source : @rtcore.SourceSpec
  string_sink : Ref[Array[Char]]
  next_string_id : Ref[Int]
  strings : Ref[Array[(Int, String)]]
  bytes_sink : Ref[Array[Byte]]
  next_bytes_id : Ref[Int]
  bytes : Ref[Array[(Int, Bytes)]]
  next_font_id : Ref[Int]
  fonts : Ref[Array[(Int, Bytes)]]
  next_shader_id : Ref[Int]
  shaders : Ref[Array[(Int, String)]]
  next_folder_id : Ref[Int]
  folders : Ref[Array[(Int, Array[Int])]]
  folder_events : Ref[Array[Int]]
  folder_events_pos : Ref[Int]
  next_closure_id : Ref[Int]
  closures : Ref[Array[(Int, @types.Value, Int)]]
  // (id, env, func_idx)
}

///|
pub fn HostContext::new(
  assets_source_spec : String,
  data_source_spec : String,
) -> HostContext raise {
  fn ensure_dir_all(path : String) -> Unit {
    if path == "" || @fs.path_exists(path) {
      return
    }
    let parent = @path.Path(path).dirname().to_string()
    if parent != "" && parent != path {
      ensure_dir_all(parent)
    }
    @fs.create_dir(path) catch {
      _ => ()
    }
  }

  let assets_source : @rtcore.SourceSpec = @rtcore.parse_dir_source(
    Some(assets_source_spec),
    ".",
  )
  let data_source : @rtcore.SourceSpec = @rtcore.parse_dir_source(
    Some(data_source_spec),
    ".",
  )
  ensure_dir_all(data_source.base)
  HostContext::{
    store: None,
    instance: None,
    jit: None,
    jit_globals_ptr: 0L,
    gpu: None,
    window: None,
    assets_source,
    data_source,
    string_sink: Ref::new([]),
    next_string_id: Ref::new(1),
    strings: Ref::new([]),
    bytes_sink: Ref::new([]),
    next_bytes_id: Ref::new(1),
    bytes: Ref::new([]),
    next_font_id: Ref::new(1),
    fonts: Ref::new([]),
    next_shader_id: Ref::new(1),
    shaders: Ref::new([]),
    next_folder_id: Ref::new(1),
    folders: Ref::new([]),
    folder_events: Ref::new([]),
    folder_events_pos: Ref::new(0),
    next_closure_id: Ref::new(1),
    closures: Ref::new([]),
  }
}

///|
fn ft(
  params : Array[@types.ValueType],
  results : Array[@types.ValueType],
) -> @types.FuncType {
  { params, results }
}

///|
fn alloc_closure(ctx : HostContext, func_idx : Int, env : @types.Value) -> Int {
  let id = ctx.next_closure_id.val
  ctx.next_closure_id.val = id + 1
  ctx.closures.val.push((id, env, func_idx))
  id
}

///|
fn funcref_to_func_idx(
  instance : @runtime.ModuleInstance,
  func_ref : Int,
) -> Int? {
  // In wasmoon, `Value::FuncRef` stores the store function address.
  // Convert it back to a module-level function index so we can call it via the executor.
  for i in 0..<instance.func_addrs.length() {
    if instance.func_addrs[i] == func_ref {
      return Some(i)
    }
  }
  None
}

///|
fn ok_i32(value : Int) -> Array[@types.Value] {
  [@types.Value::I32(value)]
}

///|
fn ok_f32(value : Float) -> Array[@types.Value] {
  [@types.Value::F32(value)]
}

///|
fn ok_extern_null() -> Array[@types.Value] {
  [@types.Value::Null]
}

///|
fn ok_extern_ref(id : Int) -> Array[@types.Value] {
  [@types.Value::ExternRef(id)]
}

///|
fn[T] host_fail(what : String, err : String) -> T raise @runtime.RuntimeError {
  let msg = what + " failed: " + err
  @debug.debug(msg)
  raise @runtime.RuntimeError::InvalidConstantExpression(msg)
}

///|
fn string_table_get(ctx : HostContext, id : Int) -> String? {
  if id <= 0 {
    return None
  }
  let entries = ctx.strings.val
  let n = entries.length()
  for i in 0..<n {
    let entry = entries[i]
    if entry.0 == id {
      return Some(entry.1)
    }
  }
  None
}

///|
fn string_table_put(ctx : HostContext, text : String) -> Int {
  if text == "" {
    return 0
  }
  let id = ctx.next_string_id.val
  ctx.next_string_id.val = id + 1
  ctx.strings.val.push((id, text))
  id
}

///|
fn string_table_drop(ctx : HostContext, id : Int) -> Unit {
  if id <= 0 {
    return
  }
  let entries = ctx.strings.val
  let n = entries.length()
  for i in 0..<n {
    if entries[i].0 == id {
      let last = n - 1
      if i != last {
        entries[i] = entries[last]
      }
      entries.pop() |> ignore
      break
    }
  }
}

///|
fn bytes_table_get(ctx : HostContext, id : Int) -> Bytes? {
  if id <= 0 {
    return None
  }
  let entries = ctx.bytes.val
  let n = entries.length()
  for i in 0..<n {
    let entry = entries[i]
    if entry.0 == id {
      return Some(entry.1)
    }
  }
  None
}

///|
fn bytes_table_put(ctx : HostContext, data : Bytes) -> Int {
  if data.length() == 0 {
    return 0
  }
  let id = ctx.next_bytes_id.val
  ctx.next_bytes_id.val = id + 1
  ctx.bytes.val.push((id, data))
  id
}

///|
fn bytes_table_drop(ctx : HostContext, id : Int) -> Unit {
  if id <= 0 {
    return
  }
  let entries = ctx.bytes.val
  let n = entries.length()
  for i in 0..<n {
    if entries[i].0 == id {
      let last = n - 1
      if i != last {
        entries[i] = entries[last]
      }
      entries.pop() |> ignore
      break
    }
  }
}

///|
fn font_table_get(ctx : HostContext, id : Int) -> Bytes? {
  if id <= 0 {
    return None
  }
  let entries = ctx.fonts.val
  let n = entries.length()
  for i in 0..<n {
    let entry = entries[i]
    if entry.0 == id {
      return Some(entry.1)
    }
  }
  None
}

///|
fn font_table_put(ctx : HostContext, data : Bytes) -> Int {
  let id = ctx.next_font_id.val
  ctx.next_font_id.val = id + 1
  ctx.fonts.val.push((id, data))
  id
}

///|
fn shader_table_put(ctx : HostContext, source : String) -> Int {
  let id = ctx.next_shader_id.val
  ctx.next_shader_id.val = id + 1
  ctx.shaders.val.push((id, source))
  id
}

///|
fn code_unit_from_gc_value(v : @types.Value) -> Int? {
  match v {
    I32(x) => Some(x & 0xFFFF)
    I64(x) => Some(x.to_int() & 0xFFFF)
    I31(x) => Some(x & 0xFFFF)
    _ => None
  }
}

///|
fn macos_keycode_from_string(code : String) -> Int? {
  match code {
    "KeyA" => Some(0)
    "KeyS" => Some(1)
    "KeyD" => Some(2)
    "KeyF" => Some(3)
    "KeyH" => Some(4)
    "KeyG" => Some(5)
    "KeyZ" => Some(6)
    "KeyX" => Some(7)
    "KeyC" => Some(8)
    "KeyV" => Some(9)
    "KeyB" => Some(11)
    "KeyQ" => Some(12)
    "KeyW" => Some(13)
    "KeyE" => Some(14)
    "KeyR" => Some(15)
    "KeyY" => Some(16)
    "KeyT" => Some(17)
    "KeyM" => Some(46)
    "KeyN" => Some(45)
    "KeyJ" => Some(38)
    "KeyK" => Some(40)
    "KeyL" => Some(37)
    "KeyI" => Some(34)
    "KeyO" => Some(31)
    "KeyP" => Some(35)
    "KeyU" => Some(32)
    "ArrowLeft" => Some(123)
    "ArrowRight" => Some(124)
    "ArrowDown" => Some(125)
    "ArrowUp" => Some(126)
    "Space" => Some(49)
    "Escape" => Some(53)
    "Comma" => Some(43)
    "Period" => Some(47)
    _ => None
  }
}

///|
fn mouse_button_from_string(button : String) -> Int? {
  match button {
    "Left" => Some(0)
    "Right" => Some(1)
    "Middle" => Some(2)
    _ => None
  }
}

///|
const HANDLE_BASE : Int = 10_000

///|
fn strip_leading_slashes(text : String) -> String {
  let n = text.length()
  let mut i = 0
  while i < n && text.code_unit_at(i).to_int() == 47 { // '/'
    i = i + 1
  }
  if i == 0 {
    text
  } else {
    (try! text[i:n]).to_string()
  }
}

///|
fn parse_f32_csv_list(csv : String) -> Array[Float]? {
  if csv == "" {
    return Some([])
  }
  let out : Array[Float] = []
  for part in csv.split(",") {
    let s = part.to_string().trim()
    if s == "" {
      continue
    }
    let n = @strconv.parse_double(s) catch { _ => return None }
    out.push(Float::from_double(n))
  }
  Some(out)
}

///|
fn join_fs_path(base : String, entry : String) -> String {
  if base == "" {
    entry
  } else if entry == "" {
    base
  } else {
    let normalized = strip_leading_slashes(entry)
    let n = base.length()
    if n > 0 && base.code_unit_at(n - 1).to_int() == 47 { // '/'
      base + normalized
    } else {
      base + "/" + normalized
    }
  }
}

///|
fn ensure_gpu_backend(ctx : HostContext) -> Unit {
  if ctx.gpu is None {
    ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
  }
}

///|
fn load_texture_from_assets(
  ctx : HostContext,
  rel : String,
  nearest : Bool,
) -> Int raise {
  ensure_gpu_backend(ctx)
  if rel == "" {
    return ctx.gpu
      .unwrap()
      .create_texture_rgba8(
        1,
        1,
        Bytes::makei(4, _ => (255).to_byte()),
        nearest,
      )
  }
  let full_path = @rtcore.join_dir(
    ctx.assets_source.base,
    strip_leading_slashes(rel),
  ) catch {
    _ => join_fs_path(ctx.assets_source.base, rel)
  }
  let file_bytes = @fs.read_file_to_bytes(full_path) catch {
    _ => Bytes::makei(0, _ => (0).to_byte())
  }
  let decoded = @img.decode_rgba8(file_bytes)
  match decoded {
    Some(img) => {
      let w = img.width()
      let h = img.height()
      let pixels = img.pixels_rgba8()
      img.destroy()
      ctx.gpu.unwrap().create_texture_rgba8(w, h, pixels, nearest)
    }
    None =>
      ctx.gpu
      .unwrap()
      .create_texture_rgba8(
        1,
        1,
        Bytes::makei(4, _ => (255).to_byte()),
        nearest,
      )
  }
}

///|
fn split_trimmed_lines(text : String) -> Array[String] {
  let out : Array[String] = []
  let buf : Array[Char] = []
  fn flush(out : Array[String], buf : Array[Char]) -> Unit {
    if buf.length() == 0 {
      return
    }
    let line = String::from_array(buf).trim().to_string()
    buf.clear()
    if line != "" && !line.has_prefix("#") {
      out.push(line)
    }
  }

  for c in text {
    if c == '\n' || c == '\r' {
      flush(out, buf)
    } else {
      buf.push(c)
    }
  }
  flush(out, buf)
  out
}

///|
fn folder_table_set(
  ctx : HostContext,
  folder_id : Int,
  handles : Array[Int],
) -> Unit {
  let entries = ctx.folders.val
  let n = entries.length()
  for i in 0..<n {
    if entries[i].0 == folder_id {
      entries[i] = (folder_id, handles)
      return
    }
  }
  entries.push((folder_id, handles))
}

///|
fn folder_table_get(ctx : HostContext, folder_id : Int) -> Array[Int]? {
  let entries = ctx.folders.val
  let n = entries.length()
  for i in 0..<n {
    if entries[i].0 == folder_id {
      return Some(entries[i].1)
    }
  }
  None
}

///|
fn folder_events_push(ctx : HostContext, kind : Int, folder_id : Int) -> Unit {
  let pos = ctx.folder_events_pos.val
  if pos >= ctx.folder_events.val.length() {
    ctx.folder_events.val.clear()
    ctx.folder_events_pos.val = 0
  }
  ctx.folder_events.val.push(kind)
  ctx.folder_events.val.push(folder_id)
}

///|
fn host_trace_enabled() -> Bool {
  match @sys.get_env_var("MGSTUDIO_NATIVE_HOST_TRACE") {
    Some(v) if v != "" => true
    _ => false
  }
}

///|
fn host_trace(msg : String) -> Unit {
  if host_trace_enabled() {
    @debug.debug(msg)
  }
}

///|
extern "C" fn c_time_now_seconds() -> Float = "mgstudio_time_now"

///|
extern "C" fn c_spectest_print_char(ch : Int) -> Unit = "mgstudio_spectest_print_char"

///|
#warnings("-unused_try")
pub fn add_mgstudio_host_imports(
  linker : @runtime.Linker,
  ctx : HostContext,
) -> Unit {
  // wasm spec test host module.
  linker.add_host_func(
    "spectest",
    "print_char",
    fn(args) {
      // Print a single byte to stdout (no newline).
      if args.length() >= 1 && code_unit_from_gc_value(args[0]) is Some(cu) {
        c_spectest_print_char(cu & 0xFF)
      }
      []
    },
    func_type=ft([@types.ValueType::I32], []),
  )
  linker.add_host_func(
    "mgstudio_host",
    "string_sink_reset",
    fn(_args) {
      host_trace("host: string_sink_reset")
      ctx.string_sink.val.clear()
      ok_i32(0)
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "string_sink_push",
    fn(args) {
      host_trace("host: string_sink_push")
      if args.length() >= 1 && code_unit_from_gc_value(args[0]) is Some(cu) {
        ctx.string_sink.val.push(Int::unsafe_to_char(cu))
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "string_sink_take",
    fn(_args) {
      host_trace("host: string_sink_take")
      let text = String::from_array(ctx.string_sink.val)
      ctx.string_sink.val.clear()
      ok_i32(string_table_put(ctx, text))
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "string_drop",
    fn(args) {
      host_trace("host: string_drop")
      if args.length() >= 1 && args[0] is @types.Value::I32(id) {
        string_table_drop(ctx, id)
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "bytes_sink_reset",
    fn(_args) {
      host_trace("host: bytes_sink_reset")
      ctx.bytes_sink.val.clear()
      ok_i32(0)
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "bytes_sink_push",
    fn(args) {
      host_trace("host: bytes_sink_push")
      if args.length() >= 1 && args[0] is @types.Value::I32(x) {
        ctx.bytes_sink.val.push((x & 0xFF).to_byte())
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "bytes_sink_push_u32",
    fn(args) {
      host_trace("host: bytes_sink_push_u32")
      if args.length() >= 1 && args[0] is @types.Value::I32(word_i32) {
        let u = word_i32.reinterpret_as_uint()
        ctx.bytes_sink.val.push((u & 0xFFU).reinterpret_as_int().to_byte())
        ctx.bytes_sink.val.push(
          ((u >> 8) & 0xFFU).reinterpret_as_int().to_byte(),
        )
        ctx.bytes_sink.val.push(
          ((u >> 16) & 0xFFU).reinterpret_as_int().to_byte(),
        )
        ctx.bytes_sink.val.push(
          ((u >> 24) & 0xFFU).reinterpret_as_int().to_byte(),
        )
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "bytes_sink_take",
    fn(_args) {
      host_trace("host: bytes_sink_take")
      let data = Bytes::from_array(ctx.bytes_sink.val)
      ctx.bytes_sink.val.clear()
      ok_i32(bytes_table_put(ctx, data))
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "bytes_drop",
    fn(args) {
      host_trace("host: bytes_drop")
      if args.length() >= 1 && args[0] is @types.Value::I32(id) {
        bytes_table_drop(ctx, id)
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "debug_string",
    fn(args) {
      // Best-effort debug output from the guest.
      try {
        if args.length() >= 1 && args[0] is @types.Value::I32(id) {
          string_table_get(ctx, id).map(fn(msg) { @debug.debug(msg) }) |> ignore
        }
        ok_i32(0)
      } catch {
        _ => {
          // Avoid calling Error::to_string here: it can trigger a MoonBit native
          // backend ordering bug in the generated blackbox test harness.
          @debug.debug("debug_string failed")
          host_fail("debug_string", "<error>")
        }
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )

  // A11y (stub; web runtime provides the full bridge).
  linker.add_host_func(
    "mgstudio_host",
    "a11y_begin_update",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "a11y_push_node",
    fn(_args) { ok_i32(0) },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::I32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "a11y_end_update",
    fn(_args) { ok_i32(0) },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "a11y_actions_len",
    fn(_args) { ok_i32(0) },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "a11y_action_target",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "a11y_action_kind",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "a11y_actions_clear",
    fn(_args) { ok_i32(0) },
    func_type=ft([], [@types.ValueType::I32]),
  )

  // Window.
  linker.add_host_func(
    "mgstudio_host",
    "window_create",
    fn(args) {
      try {
        host_trace("host: window_create")
        let width = if args.length() >= 1 && args[0] is @types.Value::I32(w) {
          w
        } else {
          800
        }
        let height = if args.length() >= 2 && args[1] is @types.Value::I32(h) {
          h
        } else {
          600
        }
        let title = if args.length() >= 3 {
          match args[2] {
            I32(id) => string_table_get(ctx, id).unwrap_or("Moon Game Studio")
            _ => "Moon Game Studio"
          }
        } else {
          "Moon Game Studio"
        }
        let win = @win.Window::create(width, height, title)
        ctx.window = Some(win)
        ok_extern_ref(HANDLE_BASE + 1)
      } catch {
        _ => {
          @debug.debug("window_create failed")
          host_fail("window_create", "<error>")
        }
      }
    },
    func_type=ft(
      [@types.ValueType::I32, @types.ValueType::I32, @types.ValueType::I32],
      [@types.ValueType::ExternRef],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_run_loop",
    fn(args) {
      if args.length() == 0 {
        return ok_i32(0)
      }
      if args[0] is @types.Value::FuncRef(func_idx) {
        host_trace("host: window_run_loop start")
        guard ctx.store is Some(store) else { return ok_i32(0) }
        guard ctx.instance is Some(instance) else { return ok_i32(0) }
        let tick_idx = funcref_to_func_idx(instance, func_idx).unwrap_or(
          func_idx,
        )
        while true {
          let _ = match ctx.jit {
            Some(jm) =>
              try {
                if !call_jit_func_by_index(jm, tick_idx) {
                  raise @runtime.RuntimeError::LinkErrorDetail(
                    "JIT function not found: \{tick_idx}",
                  )
                }
                0
              } catch {
                jit_err => {
                  // Avoid Error::to_string here; see comment in debug_string.
                  host_trace("tick jit trapped")
                  jit_err |> ignore // keep the binding for debugging while avoiding to_string
                  raise @runtime.RuntimeError::LinkErrorDetail("JIT trapped")
                }
              }
            None =>
              try {
                @executor.call_func_by_index(store, instance, tick_idx, [])
                |> ignore
                0
              } catch {
                err => {
                  host_trace(
                    "tick trapped: " + @runtime.format_runtime_error(err),
                  )
                  raise err
                }
              }
          }
          if ctx.window is Some(win) && win.should_close() {
            break
          }
        }
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::FuncRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_poll_events",
    fn(_args) {
      ctx.window.map(fn(win) { win.poll_events() }) |> ignore
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_get_width",
    fn(_args) {
      if ctx.window is Some(win) {
        ok_i32(win.width())
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_get_height",
    fn(_args) {
      if ctx.window is Some(win) {
        ok_i32(win.height())
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_get_scale_factor",
    fn(_args) {
      if ctx.window is Some(win) {
        ok_f32(win.scale_factor())
      } else {
        ok_f32(1.0)
      }
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::F32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_should_close",
    fn(_args) {
      if ctx.window is Some(win) && !win.should_close() {
        ok_i32(0)
      } else {
        ok_i32(1)
      }
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_request_close",
    fn(_args) {
      ctx.window.map(fn(win) { win.request_close() }) |> ignore
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )

  // Time.
  linker.add_host_func(
    "mgstudio_host",
    "time_now",
    fn(_args) { ok_f32(c_time_now_seconds()) },
    func_type=ft([], [@types.ValueType::F32]),
  )

  // Input.
  linker.add_host_func(
    "mgstudio_host",
    "input_finish_frame",
    fn(_args) {
      ctx.window.map(fn(win) { win.input_finish_frame() }) |> ignore
      ok_i32(0)
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_has_cursor",
    fn(_args) {
      if ctx.window is Some(win) && win.input_has_cursor() {
        ok_i32(1)
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_mouse_x",
    fn(_args) {
      if ctx.window is Some(win) {
        ok_f32(win.input_mouse_x())
      } else {
        ok_f32(0.0)
      }
    },
    func_type=ft([], [@types.ValueType::F32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_mouse_y",
    fn(_args) {
      if ctx.window is Some(win) {
        ok_f32(win.input_mouse_y())
      } else {
        ok_f32(0.0)
      }
    },
    func_type=ft([], [@types.ValueType::F32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_wheel_x",
    fn(_args) {
      if ctx.window is Some(win) {
        ok_f32(win.input_wheel_x())
      } else {
        ok_f32(0.0)
      }
    },
    func_type=ft([], [@types.ValueType::F32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_wheel_y",
    fn(_args) {
      if ctx.window is Some(win) {
        ok_f32(win.input_wheel_y())
      } else {
        ok_f32(0.0)
      }
    },
    func_type=ft([], [@types.ValueType::F32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_is_key_down",
    fn(args) {
      if args.length() >= 1 && ctx.window is Some(win) {
        if args[0] is @types.Value::I32(id) &&
          string_table_get(ctx, id) is Some(code) &&
          macos_keycode_from_string(code) is Some(keycode) &&
          win.input_is_key_down(keycode) {
          return ok_i32(1)
        }
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_is_key_just_pressed",
    fn(args) {
      if args.length() >= 1 && ctx.window is Some(win) {
        if args[0] is @types.Value::I32(id) &&
          string_table_get(ctx, id) is Some(code) &&
          macos_keycode_from_string(code) is Some(keycode) &&
          win.input_is_key_just_pressed(keycode) {
          return ok_i32(1)
        }
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_is_key_just_released",
    fn(args) {
      if args.length() >= 1 && ctx.window is Some(win) {
        if args[0] is @types.Value::I32(id) &&
          string_table_get(ctx, id) is Some(code) &&
          macos_keycode_from_string(code) is Some(keycode) &&
          win.input_is_key_just_released(keycode) {
          return ok_i32(1)
        }
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_is_mouse_button_down",
    fn(args) {
      if args.length() >= 1 && ctx.window is Some(win) {
        if args[0] is @types.Value::I32(id) &&
          string_table_get(ctx, id) is Some(code) &&
          mouse_button_from_string(code) is Some(button) &&
          win.input_is_mouse_button_down(button) {
          return ok_i32(1)
        }
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_is_mouse_button_just_pressed",
    fn(args) {
      if args.length() >= 1 && ctx.window is Some(win) {
        if args[0] is @types.Value::I32(id) &&
          string_table_get(ctx, id) is Some(code) &&
          mouse_button_from_string(code) is Some(button) &&
          win.input_is_mouse_button_just_pressed(button) {
          return ok_i32(1)
        }
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_is_mouse_button_just_released",
    fn(args) {
      if args.length() >= 1 && ctx.window is Some(win) {
        if args[0] is @types.Value::I32(id) &&
          string_table_get(ctx, id) is Some(code) &&
          mouse_button_from_string(code) is Some(button) &&
          win.input_is_mouse_button_just_released(button) {
          return ok_i32(1)
        }
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )

  // Assets: minimally support textures so sprite examples can render.
  linker.add_host_func(
    "mgstudio_host",
    "asset_load_texture",
    fn(args) {
      try {
        if ctx.gpu is None {
          ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
        }
        if args.length() >= 2 &&
          args[0] is @types.Value::I32(path_id) &&
          args[1] is @types.Value::I32(nearest_i32) {
          let nearest = nearest_i32 != 0
          let rel = string_table_get(ctx, path_id).unwrap_or("")
          ok_i32(load_texture_from_assets(ctx, rel, nearest))
        } else {
          ok_i32(-1)
        }
      } catch {
        _ => {
          @debug.debug("asset_load_texture failed")
          host_fail("asset_load_texture", "<error>")
        }
      }
    },
    func_type=ft([@types.ValueType::I32, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_load_wgsl",
    fn(args) {
      try {
        if args.length() >= 1 && args[0] is @types.Value::I32(path_id) {
          let rel = string_table_get(ctx, path_id).unwrap_or("")
          if rel == "" {
            return ok_i32(-1)
          }
          let full_path = @rtcore.join_dir(
            ctx.assets_source.base,
            strip_leading_slashes(rel),
          ) catch {
            _ => join_fs_path(ctx.assets_source.base, rel)
          }
          let source = @fs.read_file_to_string(full_path) catch { _ => "" }
          if source == "" {
            ok_i32(-1)
          } else {
            ok_i32(shader_table_put(ctx, source))
          }
        } else {
          ok_i32(-1)
        }
      } catch {
        _ => {
          @debug.debug("asset_load_wgsl failed")
          host_fail("asset_load_wgsl", "<error>")
        }
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_load_font",
    fn(args) {
      try {
        if args.length() >= 1 && args[0] is @types.Value::I32(path_id) {
          let rel = string_table_get(ctx, path_id).unwrap_or("")
          let bytes = if rel == "" {
            Bytes::makei(0, _ => (0).to_byte())
          } else {
            let full_path = @rtcore.join_dir(
              ctx.assets_source.base,
              strip_leading_slashes(rel),
            ) catch {
              _ => join_fs_path(ctx.assets_source.base, rel)
            }
            @fs.read_file_to_bytes(full_path) catch {
              _ => Bytes::makei(0, _ => (0).to_byte())
            }
          }
          ok_i32(font_table_put(ctx, bytes))
        } else {
          ok_i32(-1)
        }
      } catch {
        _ => {
          @debug.debug("asset_load_font failed")
          host_fail("asset_load_font", "<error>")
        }
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_font_bytes_len",
    fn(args) {
      if args.length() >= 1 && args[0] is @types.Value::I32(font_id) {
        match font_table_get(ctx, font_id) {
          None => ok_i32(0)
          Some(b) => ok_i32(b.length())
        }
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_font_bytes_get",
    fn(args) {
      if args.length() >= 2 &&
        args[0] is @types.Value::I32(font_id) &&
        args[1] is @types.Value::I32(index) {
        match font_table_get(ctx, font_id) {
          None => ok_i32(0)
          Some(b) =>
            match b.get(index) {
              None => ok_i32(0)
              Some(v) => ok_i32(v.to_int())
            }
        }
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([@types.ValueType::I32, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_font_bytes_get_u32",
    fn(args) {
      if args.length() >= 2 &&
        args[0] is @types.Value::I32(font_id) &&
        args[1] is @types.Value::I32(index) &&
        index >= 0 {
        match font_table_get(ctx, font_id) {
          None => ok_i32(0)
          Some(b) => {
            let mut out : UInt = 0U
            for j in 0..<4 {
              match b.get(index + j) {
                None => ()
                Some(v) =>
                  out = out |
                    ((v.to_int().reinterpret_as_uint() & 0xFFU) << (j * 8))
              }
            }
            ok_i32(out.reinterpret_as_int())
          }
        }
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([@types.ValueType::I32, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )

  // Legacy text host APIs.
  //
  // The current Text2d pipeline runs entirely in the guest: glyph rasterization
  // uses `moon_swash`, and shaping/line-breaking/BiDi uses `moon_cosmic`,
  // sourcing font bytes via `asset_font_bytes_*`.
  //
  // We keep these stubs for backwards-compatibility with older guest modules.
  linker.add_host_func(
    "mgstudio_host",
    "font_rasterize_glyph",
    fn(_args) { ok_i32(-1) },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::F32,
        @types.ValueType::I32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "font_glyph_width",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "font_glyph_height",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "font_glyph_offset_x",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "font_glyph_offset_y",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "font_measure_advance",
    fn(_args) { ok_f32(0.0) },
    func_type=ft(
      [@types.ValueType::I32, @types.ValueType::F32, @types.ValueType::I32],
      [@types.ValueType::F32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_set_texture_sampler",
    fn(args) {
      try {
        if ctx.gpu is None {
          ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
        }
        if args.length() >= 2 &&
          args[0] is @types.Value::I32(texture_id) &&
          args[1] is @types.Value::I32(sampler_kind) {
          ctx.gpu.unwrap().set_texture_sampler(texture_id, sampler_kind)
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("asset_set_texture_sampler failed")
          host_fail("asset_set_texture_sampler", "<error>")
        }
      }
    },
    func_type=ft([@types.ValueType::I32, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_create_dynamic_texture",
    fn(args) {
      try {
        if ctx.gpu is None {
          ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
        }
        if args.length() >= 3 &&
          args[0] is @types.Value::I32(w) &&
          args[1] is @types.Value::I32(h) &&
          args[2] is @types.Value::I32(nearest_i32) {
          let nearest = nearest_i32 != 0
          let width = if w <= 0 { 1 } else { w }
          let height = if h <= 0 { 1 } else { h }
          // Initialize as transparent (RGBA=0). This is used by text atlases.
          let byte_len = width * height * 4
          let pixels = Bytes::makei(byte_len, _ => (0).to_byte())
          ok_i32(
            ctx.gpu
            .unwrap()
            .create_texture_rgba8(width, height, pixels, nearest),
          )
        } else {
          ok_i32(-1)
        }
      } catch {
        _ => {
          @debug.debug("asset_create_dynamic_texture failed")
          host_fail("asset_create_dynamic_texture", "<error>")
        }
      }
    },
    func_type=ft(
      [@types.ValueType::I32, @types.ValueType::I32, @types.ValueType::I32],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_update_texture_region",
    fn(_args) { ok_i32(0) },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_update_texture_region_bytes",
    fn(args) {
      if ctx.gpu is None {
        ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
      }
      if args.length() >= 6 &&
        args[0] is @types.Value::I32(texture_id) &&
        args[1] is @types.Value::I32(x) &&
        args[2] is @types.Value::I32(y) &&
        args[3] is @types.Value::I32(w) &&
        args[4] is @types.Value::I32(h) &&
        args[5] is @types.Value::I32(bytes_id) {
        match bytes_table_get(ctx, bytes_id) {
          None => ()
          Some(pixels) =>
            ctx.gpu
            .unwrap()
            .write_texture_region_rgba8(texture_id, x, y, w, h, pixels)
        }
      }
      ok_i32(0)
    },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_texture_width",
    fn(args) {
      if ctx.gpu is None {
        return ok_i32(0)
      }
      if args.length() >= 1 && args[0] is @types.Value::I32(texture_id) {
        ok_i32(ctx.gpu.unwrap().texture_width(texture_id))
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_texture_height",
    fn(args) {
      if ctx.gpu is None {
        return ok_i32(0)
      }
      if args.length() >= 1 && args[0] is @types.Value::I32(texture_id) {
        ok_i32(ctx.gpu.unwrap().texture_height(texture_id))
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_is_texture_loaded",
    fn(args) {
      if ctx.gpu is None {
        return ok_i32(0)
      }
      if args.length() >= 1 &&
        args[0] is @types.Value::I32(texture_id) &&
        ctx.gpu.unwrap().is_texture_loaded(texture_id) {
        ok_i32(1)
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_copy_texture_to_texture",
    fn(_args) { ok_i32(0) },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_load_folder",
    fn(args) {
      try {
        host_trace("host: asset_load_folder")
        if args.length() >= 1 && args[0] is @types.Value::I32(path_id) {
          let base_rel = string_table_get(ctx, path_id).unwrap_or("")
          let folder_id = ctx.next_folder_id.val
          ctx.next_folder_id.val = folder_id + 1
          let handles : Array[Int] = []
          let manifest_rel = join_fs_path(base_rel, "folder.txt")
          let manifest_full = @rtcore.join_dir(
            ctx.assets_source.base,
            strip_leading_slashes(manifest_rel),
          ) catch {
            _ => join_fs_path(ctx.assets_source.base, manifest_rel)
          }
          let manifest = @fs.read_file_to_string(manifest_full) catch {
            _ => ""
          }
          if manifest != "" {
            for entry in split_trimmed_lines(manifest) {
              let asset_rel = join_fs_path(base_rel, entry)
              handles.push(load_texture_from_assets(ctx, asset_rel, false))
            }
          }
          folder_table_set(ctx, folder_id, handles)
          folder_events_push(ctx, 3, folder_id)
          ok_i32(folder_id)
        } else {
          ok_i32(-1)
        }
      } catch {
        _ => {
          @debug.debug("asset_load_folder failed")
          host_fail("asset_load_folder", "<error>")
        }
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_poll_loaded_folder_event_kind",
    fn(_args) {
      let pos = ctx.folder_events_pos.val
      if pos >= ctx.folder_events.val.length() {
        ok_i32(-1)
      } else {
        ok_i32(ctx.folder_events.val[pos])
      }
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_poll_loaded_folder_event_id",
    fn(_args) {
      let pos = ctx.folder_events_pos.val
      if pos + 1 >= ctx.folder_events.val.length() {
        ctx.folder_events.val.clear()
        ctx.folder_events_pos.val = 0
        ok_i32(-1)
      } else {
        let id = ctx.folder_events.val[pos + 1]
        let next_pos = pos + 2
        if next_pos >= ctx.folder_events.val.length() {
          ctx.folder_events.val.clear()
          ctx.folder_events_pos.val = 0
        } else {
          ctx.folder_events_pos.val = next_pos
        }
        ok_i32(id)
      }
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_loaded_folder_handles_len",
    fn(args) {
      if args.length() >= 1 && args[0] is @types.Value::I32(folder_id) {
        match folder_table_get(ctx, folder_id) {
          None => ok_i32(0)
          Some(handles) => ok_i32(handles.length())
        }
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_loaded_folder_handles_get",
    fn(args) {
      if args.length() >= 2 &&
        args[0] is @types.Value::I32(folder_id) &&
        args[1] is @types.Value::I32(index) {
        match folder_table_get(ctx, folder_id) {
          None => ok_i32(-1)
          Some(handles) =>
            if index < 0 || index >= handles.length() {
              ok_i32(-1)
            } else {
              ok_i32(handles[index])
            }
        }
      } else {
        ok_i32(-1)
      }
    },
    func_type=ft([@types.ValueType::I32, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_request_device",
    fn(_args) {
      try {
        host_trace("host: gpu_request_device")
        if ctx.gpu is None {
          ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
        }
        ok_extern_ref(HANDLE_BASE + 2)
      } catch {
        _ => {
          @debug.debug("gpu_request_device failed")
          host_fail("gpu_request_device", "<error>")
        }
      }
    },
    func_type=ft([], [@types.ValueType::ExternRef]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_create_surface",
    fn(_args) {
      try {
        host_trace("host: gpu_create_surface")
        if ctx.gpu is None {
          ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
        }
        if ctx.window is Some(win) {
          ctx.gpu.unwrap().create_surface(win)
        }
        ok_extern_ref(HANDLE_BASE + 3)
      } catch {
        _ => {
          @debug.debug("gpu_create_surface failed")
          host_fail("gpu_create_surface", "<error>")
        }
      }
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::ExternRef]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_configure_surface",
    fn(args) {
      try {
        host_trace("host: gpu_configure_surface")
        if ctx.gpu is None {
          ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
        }
        if args.length() >= 4 &&
          args[2] is @types.Value::I32(width) &&
          args[3] is @types.Value::I32(height) {
          ctx.gpu.unwrap().configure_surface(width, height)
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("gpu_configure_surface failed")
          host_fail("gpu_configure_surface", "<error>")
        }
      }
    },
    func_type=ft(
      [
        @types.ValueType::ExternRef,
        @types.ValueType::ExternRef,
        @types.ValueType::I32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_begin_frame",
    fn(_args) {
      try {
        host_trace("host: gpu_begin_frame")
        if ctx.gpu is None {
          ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
        }
        if ctx.window is Some(win) {
          ctx.gpu.unwrap().ensure_surface_configured(win.width(), win.height())
        }
        ctx.gpu.unwrap().begin_frame()
        ok_extern_ref(HANDLE_BASE + 4)
      } catch {
        _ => {
          @debug.debug("gpu_begin_frame failed")
          host_fail("gpu_begin_frame", "<error>")
        }
      }
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::ExternRef]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_begin_pass",
    fn(args) {
      try {
        host_trace("host: gpu_begin_pass")
        if ctx.gpu is None {
          ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
        }
        if args.length() >= 15 &&
          args[0] is @types.Value::I32(target_id) &&
          args[1] is @types.Value::I32(width_logical) &&
          args[2] is @types.Value::I32(height_logical) &&
          args[3] is @types.Value::F32(clear_r) &&
          args[4] is @types.Value::F32(clear_g) &&
          args[5] is @types.Value::F32(clear_b) &&
          args[6] is @types.Value::F32(clear_a) &&
          args[7] is @types.Value::F32(camera_x) &&
          args[8] is @types.Value::F32(camera_y) &&
          args[9] is @types.Value::F32(camera_rot) &&
          args[10] is @types.Value::F32(camera_scale) &&
          args[11] is @types.Value::I32(vx) &&
          args[12] is @types.Value::I32(vy) &&
          args[13] is @types.Value::I32(vw) &&
          args[14] is @types.Value::I32(vh) {
          ctx.gpu
          .unwrap()
          .begin_pass(
            target_id, width_logical, height_logical, clear_r, clear_g, clear_b,
            clear_a, camera_x, camera_y, camera_rot, camera_scale, vx, vy, vw, vh,
          )
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("gpu_begin_pass failed")
          host_fail("gpu_begin_pass", "<error>")
        }
      }
    },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_set_scissor",
    fn(args) {
      try {
        host_trace("host: gpu_set_scissor")
        if ctx.gpu is None {
          ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
        }
        if args.length() >= 4 &&
          args[0] is @types.Value::I32(x) &&
          args[1] is @types.Value::I32(y) &&
          args[2] is @types.Value::I32(w) &&
          args[3] is @types.Value::I32(h) {
          ctx.gpu.unwrap().set_scissor(x, y, w, h)
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("gpu_set_scissor failed")
          host_fail("gpu_set_scissor", "<error>")
        }
      }
    },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_clear_scissor",
    fn(_args) {
      try {
        host_trace("host: gpu_clear_scissor")
        if ctx.gpu is None {
          ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
        }
        ctx.gpu.unwrap().clear_scissor()
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("gpu_clear_scissor failed")
          host_fail("gpu_clear_scissor", "<error>")
        }
      }
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_end_pass",
    fn(_args) {
      try {
        host_trace("host: gpu_end_pass")
        if ctx.gpu is Some(gpu) {
          gpu.end_pass()
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("gpu_end_pass failed")
          host_fail("gpu_end_pass", "<error>")
        }
      }
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_end_frame",
    fn(_args) {
      try {
        host_trace("host: gpu_end_frame")
        if ctx.gpu is Some(gpu) {
          gpu.end_frame()
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("gpu_end_frame failed")
          host_fail("gpu_end_frame", "<error>")
        }
      }
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_create_render_target",
    fn(args) {
      try {
        host_trace("host: gpu_create_render_target")
        if ctx.gpu is None {
          ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
        }
        if args.length() >= 3 &&
          args[0] is @types.Value::I32(w) &&
          args[1] is @types.Value::I32(h) &&
          args[2] is @types.Value::I32(nearest_i32) {
          let id = ctx.gpu.unwrap().create_render_target(w, h, nearest_i32 != 0)
          ok_i32(id)
        } else {
          ok_i32(-1)
        }
      } catch {
        _ => {
          @debug.debug("gpu_create_render_target failed")
          host_fail("gpu_create_render_target", "<error>")
        }
      }
    },
    func_type=ft(
      [@types.ValueType::I32, @types.ValueType::I32, @types.ValueType::I32],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_create_mesh_capsule",
    fn(args) {
      if ctx.gpu is None {
        ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
      }
      if args.length() >= 3 &&
        args[0] is @types.Value::F32(radius) &&
        args[1] is @types.Value::F32(half_len) &&
        args[2] is @types.Value::I32(segs) {
        ok_i32(ctx.gpu.unwrap().create_mesh_capsule(radius, half_len, segs))
      } else {
        ok_i32(-1)
      }
    },
    func_type=ft(
      [@types.ValueType::F32, @types.ValueType::F32, @types.ValueType::I32],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_create_mesh_rectangle",
    fn(args) {
      if ctx.gpu is None {
        ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
      }
      if args.length() >= 2 &&
        args[0] is @types.Value::F32(w) &&
        args[1] is @types.Value::F32(h) {
        ok_i32(ctx.gpu.unwrap().create_mesh_rectangle(w, h))
      } else {
        ok_i32(-1)
      }
    },
    func_type=ft([@types.ValueType::F32, @types.ValueType::F32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_create_mesh_triangles",
    fn(args) {
      if ctx.gpu is None {
        ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
      }
      if args.length() >= 1 && args[0] is @types.Value::I32(text_id) {
        match string_table_get(ctx, text_id) {
          Some(csv) =>
            match parse_f32_csv_list(csv) {
              Some(verts) =>
                ok_i32(ctx.gpu.unwrap().create_mesh_triangles_xy(verts))
              None => ok_i32(0)
            }
          None => ok_i32(0)
        }
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_draw_mesh",
    fn(args) {
      try {
        host_trace("host: gpu_draw_mesh")
        if ctx.gpu is None {
          ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
        }
        if args.length() >= 10 &&
          args[0] is @types.Value::I32(mesh_id) &&
          args[1] is @types.Value::F32(x) &&
          args[2] is @types.Value::F32(y) &&
          args[3] is @types.Value::F32(rot) &&
          args[4] is @types.Value::F32(sx) &&
          args[5] is @types.Value::F32(sy) &&
          args[6] is @types.Value::F32(r) &&
          args[7] is @types.Value::F32(g) &&
          args[8] is @types.Value::F32(b) &&
          args[9] is @types.Value::F32(a) {
          ctx.gpu.unwrap().draw_mesh(mesh_id, x, y, rot, sx, sy, r, g, b, a)
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("gpu_draw_mesh failed")
          host_fail("gpu_draw_mesh", "<error>")
        }
      }
    },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_draw_sprite_uv",
    fn(args) {
      try {
        host_trace("host: gpu_draw_sprite_uv")
        if ctx.gpu is None {
          ctx.gpu = Some(GpuBackend::new(assets_base=ctx.assets_source.base))
        }
        if args.length() >= 14 &&
          args[0] is @types.Value::I32(texture_id) &&
          args[1] is @types.Value::F32(x) &&
          args[2] is @types.Value::F32(y) &&
          args[3] is @types.Value::F32(rot) &&
          args[4] is @types.Value::F32(sx) &&
          args[5] is @types.Value::F32(sy) &&
          args[6] is @types.Value::F32(r) &&
          args[7] is @types.Value::F32(g) &&
          args[8] is @types.Value::F32(b) &&
          args[9] is @types.Value::F32(a) &&
          args[10] is @types.Value::F32(uv_min_x) &&
          args[11] is @types.Value::F32(uv_min_y) &&
          args[12] is @types.Value::F32(uv_max_x) &&
          args[13] is @types.Value::F32(uv_max_y) {
          ctx.gpu
          .unwrap()
          .draw_sprite_uv(
            texture_id, x, y, rot, sx, sy, r, g, b, a, uv_min_x, uv_min_y, uv_max_x,
            uv_max_y,
          )
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("gpu_draw_sprite_uv failed")
          host_fail("gpu_draw_sprite_uv", "<error>")
        }
      }
    },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_draw_gizmo_line",
    fn(_args) { ok_i32(0) },
    func_type=ft(
      [
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::I32,
        @types.ValueType::F32,
        @types.ValueType::F32,
      ],
      [@types.ValueType::I32],
    ),
  )
}

///|
pub fn add_moonbit_ffi_imports(
  linker : @runtime.Linker,
  ctx : HostContext,
) -> Unit {
  linker.add_host_func(
    "moonbit:ffi",
    "make_closure",
    fn(args) {
      if args.length() >= 2 && args[0] is @types.Value::FuncRef(func_idx) {
        let env = args[1]
        let id = alloc_closure(ctx, func_idx, env)
        [@types.Value::ExternRef(id)]
      } else {
        ok_extern_null()
      }
    },
    func_type=ft([@types.ValueType::FuncRef, @types.ValueType::AnyRef], [
      @types.ValueType::ExternRef,
    ]),
  )
}
