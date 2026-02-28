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
/// the wasm build. Real window/GPU/input implementations will be added later.
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
  mut app_loop_should_close : Bool
  mut task_pool_num_threads : Int?
  gamepad : Ref[@gamepad.Gilrs]
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
  // Default to mock gamepad backend to avoid platform-specific native backend
  // crashes (notably macOS CoreFoundation/IOKit watcher initialization).
  // Set MGSTUDIO_NATIVE_ENABLE_GAMEPAD=1 to opt back into native gamepad.
  let gamepad = match @sys.get_env_var("MGSTUDIO_NATIVE_ENABLE_GAMEPAD") {
    Some(v) if v.trim() != "" => @gamepad.Gilrs::new()
    _ => @gamepad.Gilrs::new_mock(0, update_state=false, default_filters=false)
  }
  ensure_dir_all(data_source.base)
  HostContext::{
    store: None,
    instance: None,
    jit: None,
    jit_globals_ptr: 0L,
    gpu: None,
    window: None,
    app_loop_should_close: false,
    task_pool_num_threads: None,
    gamepad: Ref::new(gamepad),
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
    "Digit1" => Some(18)
    "Digit2" => Some(19)
    "Digit3" => Some(20)
    "Digit4" => Some(21)
    "Digit6" => Some(22)
    "Digit5" => Some(23)
    "Digit7" => Some(26)
    "Digit8" => Some(28)
    "Digit9" => Some(25)
    "Digit0" => Some(29)
    "KeyM" => Some(46)
    "KeyN" => Some(45)
    "KeyJ" => Some(38)
    "KeyK" => Some(40)
    "KeyL" => Some(37)
    "KeyI" => Some(34)
    "KeyO" => Some(31)
    "KeyP" => Some(35)
    "KeyU" => Some(32)
    "Tab" => Some(48)
    "Enter" => Some(36)
    "Backspace" => Some(51)
    "ShiftLeft" => Some(56)
    "ShiftRight" => Some(60)
    "ControlLeft" => Some(59)
    "ControlRight" => Some(62)
    "ArrowLeft" => Some(123)
    "ArrowRight" => Some(124)
    "ArrowDown" => Some(125)
    "ArrowUp" => Some(126)
    "PageUp" => Some(116)
    "PageDown" => Some(121)
    "Space" => Some(49)
    "Escape" => Some(53)
    "Semicolon" => Some(41)
    "Comma" => Some(43)
    "Period" => Some(47)
    "Slash" => Some(44)
    "Minus" => Some(27)
    "Equal" => Some(24)
    "BracketLeft" => Some(33)
    "BracketRight" => Some(30)
    "Quote" => Some(39)
    "Backquote" => Some(50)
    "Backslash" => Some(42)
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
fn gamepad_button_from_index(index : Int) -> @gamepad.Button? {
  match index {
    0 => Some(@gamepad.Button::South)
    1 => Some(@gamepad.Button::East)
    2 => Some(@gamepad.Button::C)
    3 => Some(@gamepad.Button::North)
    4 => Some(@gamepad.Button::West)
    5 => Some(@gamepad.Button::Z)
    6 => Some(@gamepad.Button::LeftTrigger)
    7 => Some(@gamepad.Button::RightTrigger)
    8 => Some(@gamepad.Button::LeftTrigger2)
    9 => Some(@gamepad.Button::RightTrigger2)
    10 => Some(@gamepad.Button::Select)
    11 => Some(@gamepad.Button::Start)
    12 => Some(@gamepad.Button::Mode)
    13 => Some(@gamepad.Button::LeftThumb)
    14 => Some(@gamepad.Button::RightThumb)
    15 => Some(@gamepad.Button::DPadUp)
    16 => Some(@gamepad.Button::DPadDown)
    17 => Some(@gamepad.Button::DPadLeft)
    18 => Some(@gamepad.Button::DPadRight)
    _ => None
  }
}

///|
fn gamepad_axis_from_index(index : Int) -> @gamepad.Axis? {
  match index {
    0 => Some(@gamepad.Axis::LeftStickX)
    1 => Some(@gamepad.Axis::LeftStickY)
    2 => Some(@gamepad.Axis::LeftZ)
    3 => Some(@gamepad.Axis::RightStickX)
    4 => Some(@gamepad.Axis::RightStickY)
    5 => Some(@gamepad.Axis::RightZ)
    6 => Some(@gamepad.Axis::DPadX)
    7 => Some(@gamepad.Axis::DPadY)
    _ => None
  }
}

///|
fn gamepad_count(ctx : HostContext) -> Int {
  let mut count = 0
  for _pair in ctx.gamepad.val.gamepads() {
    count = count + 1
  }
  count
}

///|
fn gamepad_id_at(ctx : HostContext, index : Int) -> Int? {
  if index < 0 {
    return None
  }
  let mut i = 0
  for pair in ctx.gamepad.val.gamepads() {
    let (id, _) = pair
    if i == index {
      return Some(id.value())
    }
    i = i + 1
  }
  None
}

///|
fn gamepad_by_id(ctx : HostContext, gamepad_id : Int) -> @gamepad.Gamepad? {
  ctx.gamepad.val.gamepad(@gamepad.GamepadId::new(gamepad_id))
}

///|
fn gamepad_name(ctx : HostContext, gamepad_id : Int) -> String {
  if gamepad_by_id(ctx, gamepad_id) is Some(gamepad) {
    gamepad.name()
  } else {
    ""
  }
}

///|
fn gamepad_vendor_id(ctx : HostContext, gamepad_id : Int) -> Int {
  if gamepad_by_id(ctx, gamepad_id) is Some(gamepad) &&
    gamepad.vendor_id() is Some(vendor_id) {
    vendor_id
  } else {
    -1
  }
}

///|
fn gamepad_product_id(ctx : HostContext, gamepad_id : Int) -> Int {
  if gamepad_by_id(ctx, gamepad_id) is Some(gamepad) &&
    gamepad.product_id() is Some(product_id) {
    product_id
  } else {
    -1
  }
}

///|
fn gamepad_button_value(
  ctx : HostContext,
  gamepad_id : Int,
  button_index : Int,
) -> Float {
  if gamepad_by_id(ctx, gamepad_id) is Some(gamepad) &&
    gamepad_button_from_index(button_index) is Some(button) &&
    gamepad.button_data(button) is Some(data) {
    return Float::from_double(data.value())
  }
  Float::from_double(0.0 / 0.0)
}

///|
fn gamepad_button_pressed(
  ctx : HostContext,
  gamepad_id : Int,
  button_index : Int,
) -> Bool {
  if gamepad_by_id(ctx, gamepad_id) is Some(gamepad) &&
    gamepad_button_from_index(button_index) is Some(button) {
    return gamepad.is_pressed(button)
  }
  false
}

///|
fn gamepad_axis_value(
  ctx : HostContext,
  gamepad_id : Int,
  axis_index : Int,
) -> Float {
  if gamepad_by_id(ctx, gamepad_id) is Some(gamepad) &&
    gamepad_axis_from_index(axis_index) is Some(axis) {
    return Float::from_double(gamepad.value(axis))
  }
  Float::from_double(0.0 / 0.0)
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
fn ensure_gpu_backend(ctx : HostContext) -> Unit raise @runtime.RuntimeError {
  if ctx.gpu is None {
    let backend = GpuBackend::new(assets_base=ctx.assets_source.base) catch {
      err =>
        match err {
          GpuBackendError::Fatal(message) =>
            host_fail("gpu_backend_init", message)
        }
    }
    ctx.gpu = Some(backend)
  }
}

///|
fn load_texture_from_assets(
  ctx : HostContext,
  rel : String,
  nearest : Bool,
) -> Int raise {
  let file_bytes = if rel == "" {
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
  load_texture_from_bytes(ctx, file_bytes, nearest)
}

///|
fn load_texture_from_bytes(
  ctx : HostContext,
  bytes : Bytes,
  nearest : Bool,
) -> Int raise {
  ensure_gpu_backend(ctx)
  if @img.is_ktx2(bytes) {
    if @img.parse_ktx2_texture_for_stacked_upload(bytes) is Some(parsed) {
      return ctx.gpu
        .unwrap()
        .create_texture_stacked_2d_with_format(
          parsed.width,
          parsed.height_per_slice,
          parsed.slice_count,
          parsed.format_raw,
          parsed.levels,
          nearest,
        )
    }
  }
  let decoded = @img.decode_rgba8(bytes)
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
extern "C" fn c_time_now_millis() -> Float = "mgstudio_time_now"

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
    fn(args) raise @runtime.RuntimeError {
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

  // A11y (macOS NSAccessibility bridge).
  linker.add_host_func(
    "mgstudio_host",
    "a11y_begin_update",
    fn(args) raise @runtime.RuntimeError {
      try {
        if args.length() >= 1 &&
          args[0] is @types.Value::I32(root_id) &&
          ctx.window is Some(win) {
          win.a11y_begin_update(root_id)
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("a11y_begin_update failed")
          host_fail("a11y_begin_update", "<error>")
        }
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "a11y_push_node",
    fn(args) raise @runtime.RuntimeError {
      try {
        guard ctx.window is Some(win) else { return ok_i32(0) }
        if args.length() < 9 {
          return ok_i32(0)
        }
        guard args[0] is @types.Value::I32(node_id) else { return ok_i32(0) }
        guard args[1] is @types.Value::I32(parent_id) else { return ok_i32(0) }
        guard args[2] is @types.Value::I32(role_id) else { return ok_i32(0) }
        guard args[3] is @types.Value::F32(x) else { return ok_i32(0) }
        guard args[4] is @types.Value::F32(y) else { return ok_i32(0) }
        guard args[5] is @types.Value::F32(w) else { return ok_i32(0) }
        guard args[6] is @types.Value::F32(h) else { return ok_i32(0) }
        guard args[7] is @types.Value::I32(name_id) else { return ok_i32(0) }
        guard args[8] is @types.Value::I32(actions_mask) else {
          return ok_i32(0)
        }
        let name = string_table_get(ctx, name_id).unwrap_or("")
        win.a11y_push_node(
          node_id, parent_id, role_id, x, y, w, h, name, actions_mask,
        )
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("a11y_push_node failed")
          host_fail("a11y_push_node", "<error>")
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
        @types.ValueType::I32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "a11y_end_update",
    fn(_args) raise @runtime.RuntimeError {
      try {
        if ctx.window is Some(win) {
          win.a11y_end_update()
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("a11y_end_update failed")
          host_fail("a11y_end_update", "<error>")
        }
      }
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "a11y_apply_update",
    fn(args) {
      try {
        guard ctx.window is Some(win) else { return ok_i32(0) }
        guard args.length() >= 1 && args[0] is @types.Value::I32(payload_id) else {
          return ok_i32(0)
        }
        let payload = string_table_get(ctx, payload_id).unwrap_or("")
        if payload == "" {
          return ok_i32(0)
        }
        let json = @json.parse(payload)
        let update : @moon_accesskit.TreeUpdate = @json.from_json(json)

        // We keep the existing NSAccessibility bridge (begin/push/end), but the
        // engine->runtime boundary is now AccessKit TreeUpdate.
        win.a11y_begin_update(-1)
        let nodes_by_id : @hashmap.HashMap[UInt64, @moon_accesskit.Node] = @hashmap.HashMap::new()
        for nu in update.nodes() {
          nodes_by_id.set(nu.id().to_u64(), nu.node())
        }
        let root_id = match update.tree() {
          Some(t) => t.root_id().to_u64()
          None => 0UL
        }
        let focused_id = update.focus().to_u64()
        fn host_role(role : @moon_accesskit.Role) -> Int {
          match role {
            @moon_accesskit.Role::Window
            | @moon_accesskit.Role::Application
            | @moon_accesskit.Role::RootWebArea => 1
            @moon_accesskit.Role::Button
            | @moon_accesskit.Role::DefaultButton => 3
            @moon_accesskit.Role::Label
            | @moon_accesskit.Role::TextRun
            | @moon_accesskit.Role::Paragraph => 4
            @moon_accesskit.Role::Image => 5
            _ => 2
          }
        }

        fn name_for(node : @moon_accesskit.Node) -> String {
          if node.supports_action(@moon_accesskit.Action::SetValue) {
            match node.value() {
              Some(s) => s
              None => node.label().unwrap_or("")
            }
          } else {
            match node.label() {
              Some(s) => s
              None => node.value().unwrap_or("")
            }
          }
        }

        let stack : Array[(UInt64, UInt64, Bool)] = []
        stack.push((0UL, root_id, false))
        let visited : @hashmap.HashMap[UInt64, Bool] = @hashmap.HashMap::new()
        while stack.length() > 0 {
          let (parent_id, cur_id, hidden_ancestor) = stack.pop().unwrap()
          if visited.contains(cur_id) {
            continue
          }
          visited.set(cur_id, true)
          guard nodes_by_id.get(cur_id) is Some(node) else { continue }
          if hidden_ancestor || node.is_hidden() {
            continue
          }
          if cur_id != root_id {
            let parent_int = if parent_id == 0UL {
              -1
            } else {
              parent_id.to_int()
            }
            let node_int = cur_id.to_int()
            let supports_scroll = node.supports_action(
                @moon_accesskit.Action::ScrollUp,
              ) ||
              node.supports_action(@moon_accesskit.Action::ScrollDown) ||
              node.supports_action(@moon_accesskit.Action::ScrollLeft) ||
              node.supports_action(@moon_accesskit.Action::ScrollRight)
            let actions_mask = (if node.supports_action(
                  @moon_accesskit.Action::Focus,
                ) {
                1
              } else {
                0
              }) +
              (if node.supports_action(@moon_accesskit.Action::Click) {
                2
              } else {
                0
              }) +
              (if supports_scroll { 4 } else { 0 }) +
              (if node.supports_action(@moon_accesskit.Action::SetValue) {
                8
              } else {
                0
              })
            match node.bounds() {
              Some(b) => {
                let x = Float::from_double(b.x0)
                let y = Float::from_double(b.y0)
                let w = Float::from_double(b.x1 - b.x0)
                let h = Float::from_double(b.y1 - b.y0)
                win.a11y_push_node(
                  node_int,
                  parent_int,
                  host_role(node.role()),
                  x,
                  y,
                  w,
                  h,
                  name_for(node),
                  actions_mask,
                )
              }
              None => ()
            }
          }
          let children = node.children()
          for i in 0..<children.length() {
            stack.push((cur_id, children[i].to_u64(), false))
          }
        }
        win.a11y_end_update()
        if focused_id != 0UL && focused_id != root_id {
          win.a11y_set_focus(focused_id.to_int())
        }
        ok_i32(0)
      } catch {
        _ => {
          if host_trace_enabled() {
            @debug.debug("a11y_apply_update failed (ignored)")
          }
          ok_i32(0)
        }
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "a11y_actions_len",
    fn(_args) raise @runtime.RuntimeError {
      try {
        if ctx.window is Some(win) {
          return ok_i32(win.a11y_actions_len())
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("a11y_actions_len failed")
          host_fail("a11y_actions_len", "<error>")
        }
      }
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "a11y_action_target",
    fn(args) raise @runtime.RuntimeError {
      try {
        guard ctx.window is Some(win) else { return ok_i32(0) }
        if args.length() >= 1 && args[0] is @types.Value::I32(index) {
          return ok_i32(win.a11y_action_target(index))
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("a11y_action_target failed")
          host_fail("a11y_action_target", "<error>")
        }
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "a11y_action_kind",
    fn(args) raise @runtime.RuntimeError {
      try {
        guard ctx.window is Some(win) else { return ok_i32(0) }
        if args.length() >= 1 && args[0] is @types.Value::I32(index) {
          return ok_i32(win.a11y_action_kind(index))
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("a11y_action_kind failed")
          host_fail("a11y_action_kind", "<error>")
        }
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "a11y_action_value_len",
    fn(args) raise @runtime.RuntimeError {
      try {
        guard ctx.window is Some(win) else { return ok_i32(0) }
        if args.length() >= 1 && args[0] is @types.Value::I32(index) {
          return ok_i32(win.a11y_action_value_len(index))
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("a11y_action_value_len failed")
          host_fail("a11y_action_value_len", "<error>")
        }
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "a11y_action_value_code_unit",
    fn(args) raise @runtime.RuntimeError {
      try {
        guard ctx.window is Some(win) else { return ok_i32(0) }
        if args.length() >= 2 &&
          args[0] is @types.Value::I32(index) &&
          args[1] is @types.Value::I32(offset) {
          return ok_i32(win.a11y_action_value_code_unit(index, offset))
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("a11y_action_value_code_unit failed")
          host_fail("a11y_action_value_code_unit", "<error>")
        }
      }
    },
    func_type=ft([@types.ValueType::I32, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "a11y_actions_clear",
    fn(_args) raise @runtime.RuntimeError {
      try {
        if ctx.window is Some(win) {
          win.a11y_actions_clear()
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("a11y_actions_clear failed")
          host_fail("a11y_actions_clear", "<error>")
        }
      }
    },
    func_type=ft([], [@types.ValueType::I32]),
  )

  // Window.
  linker.add_host_func(
    "mgstudio_host",
    "window_create",
    fn(args) raise @runtime.RuntimeError {
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
    fn(args) raise @runtime.RuntimeError {
      host_trace("host: window_run_loop args_len=\{args.length()}")
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
        host_trace("host: window_run_loop tick_idx=\{tick_idx}")
        while true {
          host_trace("tick: call_jit begin")
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
          host_trace("tick: call_jit done")
          if ctx.window is Some(win) && win.should_close() {
            host_trace("tick: should_close true")
            break
          }
          if ctx.window is Some(_) {
            host_trace("tick: should_close false")
          }
        }
      } else {
        host_trace("host: window_run_loop arg0 is not funcref")
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::FuncRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "app_run_loop",
    fn(args) raise @runtime.RuntimeError {
      if args.length() == 0 {
        return ok_i32(0)
      }
      if args[0] is @types.Value::FuncRef(func_idx) {
        guard ctx.store is Some(store) else { return ok_i32(0) }
        guard ctx.instance is Some(instance) else { return ok_i32(0) }
        let tick_idx = funcref_to_func_idx(instance, func_idx).unwrap_or(
          func_idx,
        )
        ctx.app_loop_should_close = false
        while true {
          if ctx.app_loop_should_close {
            break
          }
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
                _ => raise @runtime.RuntimeError::LinkErrorDetail("JIT trapped")
              }
            None =>
              try {
                @executor.call_func_by_index(store, instance, tick_idx, [])
                |> ignore
                0
              } catch {
                err => raise err
              }
          }
        }
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::FuncRef, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "app_request_close",
    fn(_args) {
      ctx.app_loop_should_close = true
      ok_i32(0)
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "app_reset_close",
    fn(_args) {
      ctx.app_loop_should_close = false
      ok_i32(0)
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "task_pool_set_num_threads",
    fn(args) {
      if args.length() >= 1 && args[0] is @types.Value::I32(num_threads) {
        if num_threads > 0 {
          ctx.task_pool_num_threads = Some(num_threads)
        }
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "app_stdin_read_line_len",
    fn(_args) {
      // Native-wasmoon path keeps stdin unavailable for now.
      ok_i32(-1)
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "app_stdin_read_line_code_unit",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
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
  linker.add_host_func(
    "mgstudio_host",
    "window_set_title",
    fn(args) {
      if args.length() >= 2 &&
        args[1] is @types.Value::I32(title_id) &&
        string_table_get(ctx, title_id) is Some(title) {
        ctx.window.map(fn(win) { win.set_title(title) }) |> ignore
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::ExternRef, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_set_size",
    fn(args) {
      if args.length() >= 3 &&
        args[1] is @types.Value::I32(width) &&
        args[2] is @types.Value::I32(height) {
        ctx.window.map(fn(win) { win.set_size(width, height) }) |> ignore
      }
      ok_i32(0)
    },
    func_type=ft(
      [
        @types.ValueType::ExternRef,
        @types.ValueType::I32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_set_resizable",
    fn(args) {
      if args.length() >= 2 && args[1] is @types.Value::I32(resizable_i32) {
        let resizable = resizable_i32 != 0
        ctx.window.map(fn(win) { win.set_resizable(resizable) }) |> ignore
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::ExternRef, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_set_cursor_visible",
    fn(args) {
      if args.length() >= 2 && args[1] is @types.Value::I32(visible_i32) {
        let visible = visible_i32 != 0
        ctx.window.map(fn(win) { win.set_cursor_visible(visible) }) |> ignore
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::ExternRef, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_set_cursor_grab_mode",
    fn(args) {
      if args.length() >= 2 && args[1] is @types.Value::I32(mode) {
        ctx.window.map(fn(win) { win.set_cursor_grab_mode(mode) }) |> ignore
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::ExternRef, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_set_cursor_icon",
    fn(args) {
      if args.length() >= 2 && args[1] is @types.Value::I32(icon) {
        ctx.window.map(fn(win) { win.set_cursor_icon(icon) }) |> ignore
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::ExternRef, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_set_mode",
    fn(args) {
      if args.length() >= 2 && args[1] is @types.Value::I32(mode) {
        ctx.window.map(fn(win) { win.set_mode(mode) }) |> ignore
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::ExternRef, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_set_position",
    fn(args) {
      if args.length() >= 3 &&
        args[1] is @types.Value::I32(x) &&
        args[2] is @types.Value::I32(y) {
        ctx.window.map(fn(win) { win.set_position(x, y) }) |> ignore
      }
      ok_i32(0)
    },
    func_type=ft(
      [
        @types.ValueType::ExternRef,
        @types.ValueType::I32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_get_position_x",
    fn(_args) {
      if ctx.window is Some(win) {
        ok_i32(win.position_x())
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_get_position_y",
    fn(_args) {
      if ctx.window is Some(win) {
        ok_i32(win.position_y())
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )

  // Time.
  linker.add_host_func(
    "mgstudio_host",
    "time_now",
    fn(_args) { ok_f32(c_time_now_millis()) },
    func_type=ft([], [@types.ValueType::F32]),
  )

  // Input.
  linker.add_host_func(
    "mgstudio_host",
    "input_gamepad_poll",
    fn(_args) {
      ctx.gamepad.val.poll()
      while true {
        if ctx.gamepad.val.next_event() is Some(_) {
          continue
        }
        break
      }
      ctx.gamepad.val.inc()
      ok_i32(0)
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_gamepad_count",
    fn(_args) { ok_i32(gamepad_count(ctx)) },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_gamepad_id",
    fn(args) {
      if args.length() >= 1 &&
        args[0] is @types.Value::I32(index) &&
        gamepad_id_at(ctx, index) is Some(gamepad_id) {
        ok_i32(gamepad_id)
      } else {
        ok_i32(-1)
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_gamepad_connected",
    fn(args) {
      if args.length() >= 1 &&
        args[0] is @types.Value::I32(gamepad_id) &&
        ctx.gamepad.val.is_connected(@gamepad.GamepadId::new(gamepad_id)) {
        ok_i32(1)
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_gamepad_name_len",
    fn(args) {
      if args.length() >= 1 && args[0] is @types.Value::I32(gamepad_id) {
        ok_i32(gamepad_name(ctx, gamepad_id).length())
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_gamepad_name_code_unit",
    fn(args) {
      if args.length() >= 2 &&
        args[0] is @types.Value::I32(gamepad_id) &&
        args[1] is @types.Value::I32(offset) {
        let name = gamepad_name(ctx, gamepad_id)
        if offset >= 0 && offset < name.length() {
          return ok_i32(name.code_unit_at(offset).to_int())
        }
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::I32, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_gamepad_vendor_id",
    fn(args) {
      if args.length() >= 1 && args[0] is @types.Value::I32(gamepad_id) {
        ok_i32(gamepad_vendor_id(ctx, gamepad_id))
      } else {
        ok_i32(-1)
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_gamepad_product_id",
    fn(args) {
      if args.length() >= 1 && args[0] is @types.Value::I32(gamepad_id) {
        ok_i32(gamepad_product_id(ctx, gamepad_id))
      } else {
        ok_i32(-1)
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_gamepad_button_value",
    fn(args) {
      if args.length() >= 2 &&
        args[0] is @types.Value::I32(gamepad_id) &&
        args[1] is @types.Value::I32(button_index) {
        ok_f32(gamepad_button_value(ctx, gamepad_id, button_index))
      } else {
        ok_f32(Float::from_double(0.0 / 0.0))
      }
    },
    func_type=ft([@types.ValueType::I32, @types.ValueType::I32], [
      @types.ValueType::F32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_gamepad_button_pressed",
    fn(args) {
      if args.length() >= 2 &&
        args[0] is @types.Value::I32(gamepad_id) &&
        args[1] is @types.Value::I32(button_index) &&
        gamepad_button_pressed(ctx, gamepad_id, button_index) {
        ok_i32(1)
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
    "input_gamepad_axis_value",
    fn(args) {
      if args.length() >= 2 &&
        args[0] is @types.Value::I32(gamepad_id) &&
        args[1] is @types.Value::I32(axis_index) {
        ok_f32(gamepad_axis_value(ctx, gamepad_id, axis_index))
      } else {
        ok_f32(Float::from_double(0.0 / 0.0))
      }
    },
    func_type=ft([@types.ValueType::I32, @types.ValueType::I32], [
      @types.ValueType::F32,
    ]),
  )
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
    "input_touch_event_count",
    fn(_args) {
      if ctx.window is Some(win) {
        ok_i32(win.input_touch_event_count())
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_touch_event_id",
    fn(args) {
      if args.length() >= 1 &&
        args[0] is @types.Value::I32(index) &&
        ctx.window is Some(win) {
        ok_i32(win.input_touch_event_id(index))
      } else {
        ok_i32(-1)
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_touch_event_phase",
    fn(args) {
      if args.length() >= 1 &&
        args[0] is @types.Value::I32(index) &&
        ctx.window is Some(win) {
        ok_i32(win.input_touch_event_phase(index))
      } else {
        ok_i32(3)
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_touch_event_x",
    fn(args) {
      if args.length() >= 1 &&
        args[0] is @types.Value::I32(index) &&
        ctx.window is Some(win) {
        ok_f32(win.input_touch_event_x(index))
      } else {
        ok_f32(0.0)
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::F32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_touch_event_y",
    fn(args) {
      if args.length() >= 1 &&
        args[0] is @types.Value::I32(index) &&
        ctx.window is Some(win) {
        ok_f32(win.input_touch_event_y(index))
      } else {
        ok_f32(0.0)
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::F32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_drag_and_drop_event_count",
    fn(_args) { ok_i32(0) },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_drag_and_drop_event_kind",
    fn(_args) { ok_i32(-1) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_drag_and_drop_event_len",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_drag_and_drop_event_code_unit",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
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
    "input_is_key_repeated",
    fn(args) {
      if args.length() >= 1 && ctx.window is Some(win) {
        if args[0] is @types.Value::I32(id) &&
          string_table_get(ctx, id) is Some(code) &&
          macos_keycode_from_string(code) is Some(keycode) &&
          win.input_is_key_repeated(keycode) {
          return ok_i32(1)
        }
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_text_event_count",
    fn(_args) {
      if ctx.window is Some(win) {
        ok_i32(win.input_text_event_count())
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_text_event_len",
    fn(args) {
      if args.length() >= 1 &&
        args[0] is @types.Value::I32(index) &&
        ctx.window is Some(win) {
        ok_i32(win.input_text_event_len(index))
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_text_event_code_unit",
    fn(args) {
      if args.length() >= 2 &&
        args[0] is @types.Value::I32(index) &&
        args[1] is @types.Value::I32(offset) &&
        ctx.window is Some(win) {
        ok_i32(win.input_text_event_code_unit(index, offset))
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
    fn(args) raise @runtime.RuntimeError {
      try {
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
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
    "asset_load_texture_bytes",
    fn(args) raise @runtime.RuntimeError {
      try {
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
        }
        if args.length() >= 2 &&
          args[0] is @types.Value::I32(bytes_id) &&
          args[1] is @types.Value::I32(nearest_i32) {
          let nearest = nearest_i32 != 0
          let bytes = bytes_table_get(ctx, bytes_id).unwrap_or(
            Bytes::makei(0, _ => (0).to_byte()),
          )
          ok_i32(load_texture_from_bytes(ctx, bytes, nearest))
        } else {
          ok_i32(-1)
        }
      } catch {
        _ => {
          @debug.debug("asset_load_texture_bytes failed")
          host_fail("asset_load_texture_bytes", "<error>")
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
    fn(args) raise @runtime.RuntimeError {
      try {
        if args.length() >= 1 && args[0] is @types.Value::I32(path_id) {
          let rel = string_table_get(ctx, path_id).unwrap_or("")
          if rel == "" {
            return ok_i32(-1)
          }
          let source = load_wgsl_from_assets_base_required(
            ctx.assets_source.base,
            rel,
          ) catch {
            _ => ""
          }
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
    fn(args) raise @runtime.RuntimeError {
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
    "asset_load_bytes",
    fn(args) raise @runtime.RuntimeError {
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
          ok_i32(bytes_table_put(ctx, bytes))
        } else {
          ok_i32(-1)
        }
      } catch {
        _ => {
          @debug.debug("asset_load_bytes failed")
          host_fail("asset_load_bytes", "<error>")
        }
      }
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_bytes_len",
    fn(args) {
      if args.length() >= 1 && args[0] is @types.Value::I32(blob_id) {
        match bytes_table_get(ctx, blob_id) {
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
    "asset_bytes_get_u32",
    fn(args) {
      if args.length() >= 2 &&
        args[0] is @types.Value::I32(blob_id) &&
        args[1] is @types.Value::I32(index) &&
        index >= 0 {
        match bytes_table_get(ctx, blob_id) {
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
    fn(args) raise @runtime.RuntimeError {
      try {
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
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
    fn(args) raise @runtime.RuntimeError {
      try {
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
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
    "asset_create_dynamic_texture_mipped",
    fn(args) raise @runtime.RuntimeError {
      try {
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
        }
        if args.length() >= 4 &&
          args[0] is @types.Value::I32(w) &&
          args[1] is @types.Value::I32(h) &&
          args[2] is @types.Value::I32(_mip_count) &&
          args[3] is @types.Value::I32(nearest_i32) {
          let nearest = nearest_i32 != 0
          let width = if w <= 0 { 1 } else { w }
          let height = if h <= 0 { 1 } else { h }
          // Native MoonBit runtime fallback: create a regular RGBA8 texture.
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
          @debug.debug("asset_create_dynamic_texture_mipped failed")
          host_fail("asset_create_dynamic_texture_mipped", "<error>")
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
    fn(args) raise @runtime.RuntimeError {
      if ctx.gpu is None {
        ensure_gpu_backend(ctx)
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
    "asset_update_texture_region_mip_bytes",
    fn(args) raise @runtime.RuntimeError {
      if ctx.gpu is None {
        ensure_gpu_backend(ctx)
      }
      if args.length() >= 7 &&
        args[0] is @types.Value::I32(texture_id) &&
        args[1] is @types.Value::I32(x) &&
        args[2] is @types.Value::I32(y) &&
        args[3] is @types.Value::I32(w) &&
        args[4] is @types.Value::I32(h) &&
        args[5] is @types.Value::I32(_mip_level) &&
        args[6] is @types.Value::I32(bytes_id) {
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
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_create_texture_mip_view",
    fn(args) {
      if args.length() >= 2 &&
        args[0] is @types.Value::I32(texture_id) &&
        args[1] is @types.Value::I32(_mip_level) {
        // Native MoonBit runtime fallback: reuse the base texture handle.
        ok_i32(texture_id)
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
    "asset_supported_compressed_image_formats",
    fn(_args) raise @runtime.RuntimeError {
      try {
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
        }
        if ctx.gpu is Some(gpu) {
          ok_i32(gpu.supported_compressed_image_formats_mask())
        } else {
          ok_i32(0)
        }
      } catch {
        _ => {
          @debug.debug("asset_supported_compressed_image_formats failed")
          host_fail("asset_supported_compressed_image_formats", "<error>")
        }
      }
    },
    func_type=ft([], [@types.ValueType::I32]),
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
    "asset_save_texture_png",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_load_folder",
    fn(args) raise @runtime.RuntimeError {
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
    fn(_args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_request_device")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
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
    "gpu_get_queue",
    fn(_args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_get_queue")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
        }
        ok_extern_ref(HANDLE_BASE + 1)
      } catch {
        _ => {
          @debug.debug("gpu_get_queue failed")
          host_fail("gpu_get_queue", "<error>")
        }
      }
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::ExternRef]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_create_surface",
    fn(_args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_create_surface")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
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
    fn(args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_configure_surface")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
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
    fn(_args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_begin_frame")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
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
    fn(args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_begin_pass")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
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
          let mut viewport_depth_min = 0.0F
          let mut viewport_depth_max = 1.0F
          let mut clear_enabled = 1
          if args.length() > 15 {
            if args[15] is @types.Value::F32(v) {
              viewport_depth_min = v
              if args.length() > 16 && args[16] is @types.Value::F32(depth_max) {
                viewport_depth_max = depth_max
              }
              if args.length() > 17 &&
                args[17] is @types.Value::I32(v_clear_enabled) {
                clear_enabled = v_clear_enabled
              }
            } else if args[15] is @types.Value::I32(v) {
              clear_enabled = v
            }
          }
          ctx.gpu
          .unwrap()
          .begin_pass(
            target_id, width_logical, height_logical, clear_r, clear_g, clear_b,
            clear_a, camera_x, camera_y, camera_rot, camera_scale, vx, vy, vw, vh,
            viewport_depth_min, viewport_depth_max, clear_enabled,
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
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_begin_pass_3d",
    fn(args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_begin_pass_3d")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
        }
        if args.length() >= 21 &&
          args[0] is @types.Value::I32(target_id) &&
          args[1] is @types.Value::I32(width_logical) &&
          args[2] is @types.Value::I32(height_logical) &&
          args[3] is @types.Value::F32(clear_r) &&
          args[4] is @types.Value::F32(clear_g) &&
          args[5] is @types.Value::F32(clear_b) &&
          args[6] is @types.Value::F32(clear_a) &&
          args[7] is @types.Value::F32(camera_x) &&
          args[8] is @types.Value::F32(camera_y) &&
          args[9] is @types.Value::F32(camera_z) &&
          args[10] is @types.Value::F32(camera_rot_x) &&
          args[11] is @types.Value::F32(camera_rot_y) &&
          args[12] is @types.Value::F32(camera_rot_z) &&
          args[13] is @types.Value::F32(camera_rot_w) &&
          args[14] is @types.Value::F32(camera_fov_y) &&
          args[15] is @types.Value::F32(camera_near) &&
          args[16] is @types.Value::F32(camera_far) &&
          args[17] is @types.Value::I32(vx) &&
          args[18] is @types.Value::I32(vy) &&
          args[19] is @types.Value::I32(vw) &&
          args[20] is @types.Value::I32(vh) {
          let ambient_r = if args.length() > 21 &&
            args[21] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let ambient_g = if args.length() > 22 &&
            args[22] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let ambient_b = if args.length() > 23 &&
            args[23] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let ambient_brightness = if args.length() > 24 &&
            args[24] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let directional_dir_x = if args.length() > 25 &&
            args[25] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let directional_dir_y = if args.length() > 26 &&
            args[26] is @types.Value::F32(v) {
            v
          } else {
            -1.0F
          }
          let directional_dir_z = if args.length() > 27 &&
            args[27] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let directional_color_r = if args.length() > 28 &&
            args[28] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let directional_color_g = if args.length() > 29 &&
            args[29] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let directional_color_b = if args.length() > 30 &&
            args[30] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let directional_illuminance = if args.length() > 31 &&
            args[31] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let point_pos_x = if args.length() > 32 &&
            args[32] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let point_pos_y = if args.length() > 33 &&
            args[33] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let point_pos_z = if args.length() > 34 &&
            args[34] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let point_color_r = if args.length() > 35 &&
            args[35] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let point_color_g = if args.length() > 36 &&
            args[36] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let point_color_b = if args.length() > 37 &&
            args[37] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let point_intensity = if args.length() > 38 &&
            args[38] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let point_range = if args.length() > 39 &&
            args[39] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let spot_pos_x = if args.length() > 40 &&
            args[40] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let spot_pos_y = if args.length() > 41 &&
            args[41] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let spot_pos_z = if args.length() > 42 &&
            args[42] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let spot_dir_x = if args.length() > 43 &&
            args[43] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let spot_dir_y = if args.length() > 44 &&
            args[44] is @types.Value::F32(v) {
            v
          } else {
            -1.0F
          }
          let spot_dir_z = if args.length() > 45 &&
            args[45] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let spot_color_r = if args.length() > 46 &&
            args[46] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let spot_color_g = if args.length() > 47 &&
            args[47] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let spot_color_b = if args.length() > 48 &&
            args[48] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let spot_intensity = if args.length() > 49 &&
            args[49] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let spot_range = if args.length() > 50 &&
            args[50] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let spot_inner_angle = if args.length() > 51 &&
            args[51] is @types.Value::F32(v) {
            v
          } else {
            0.6F
          }
          let spot_outer_angle = if args.length() > 52 &&
            args[52] is @types.Value::F32(v) {
            v
          } else {
            0.8F
          }
          let sub_camera_view_scale_x = if args.length() > 53 &&
            args[53] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let sub_camera_view_scale_y = if args.length() > 54 &&
            args[54] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let sub_camera_view_bias_x = if args.length() > 55 &&
            args[55] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let sub_camera_view_bias_y = if args.length() > 56 &&
            args[56] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let previous_camera_x = if args.length() > 57 &&
            args[57] is @types.Value::F32(v) {
            v
          } else {
            camera_x
          }
          let previous_camera_y = if args.length() > 58 &&
            args[58] is @types.Value::F32(v) {
            v
          } else {
            camera_y
          }
          let previous_camera_z = if args.length() > 59 &&
            args[59] is @types.Value::F32(v) {
            v
          } else {
            camera_z
          }
          let previous_camera_rot_x = if args.length() > 60 &&
            args[60] is @types.Value::F32(v) {
            v
          } else {
            camera_rot_x
          }
          let previous_camera_rot_y = if args.length() > 61 &&
            args[61] is @types.Value::F32(v) {
            v
          } else {
            camera_rot_y
          }
          let previous_camera_rot_z = if args.length() > 62 &&
            args[62] is @types.Value::F32(v) {
            v
          } else {
            camera_rot_z
          }
          let previous_camera_rot_w = if args.length() > 63 &&
            args[63] is @types.Value::F32(v) {
            v
          } else {
            camera_rot_w
          }
          let pass_kind = if args.length() > 64 &&
            args[64] is @types.Value::I32(v) {
            v
          } else {
            0
          }
          let clear_enabled = if args.length() > 65 &&
            args[65] is @types.Value::I32(v) {
            v
          } else {
            1
          }
          ctx.gpu
          .unwrap()
          .begin_pass_3d(
            target_id, width_logical, height_logical, clear_r, clear_g, clear_b,
            clear_a, camera_x, camera_y, camera_z, camera_rot_x, camera_rot_y, camera_rot_z,
            camera_rot_w, camera_fov_y, camera_near, camera_far, vx, vy, vw, vh,
            ambient_r, ambient_g, ambient_b, ambient_brightness, directional_dir_x,
            directional_dir_y, directional_dir_z, directional_color_r, directional_color_g,
            directional_color_b, directional_illuminance, point_pos_x, point_pos_y,
            point_pos_z, point_color_r, point_color_g, point_color_b, point_intensity,
            point_range, spot_pos_x, spot_pos_y, spot_pos_z, spot_dir_x, spot_dir_y,
            spot_dir_z, spot_color_r, spot_color_g, spot_color_b, spot_intensity,
            spot_range, spot_inner_angle, spot_outer_angle, sub_camera_view_scale_x,
            sub_camera_view_scale_y, sub_camera_view_bias_x, sub_camera_view_bias_y,
            previous_camera_x, previous_camera_y, previous_camera_z, previous_camera_rot_x,
            previous_camera_rot_y, previous_camera_rot_z, previous_camera_rot_w,
            pass_kind, clear_enabled,
          )
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("gpu_begin_pass_3d failed")
          host_fail("gpu_begin_pass_3d", "<error>")
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
    "gpu_set_scissor",
    fn(args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_set_scissor")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
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
    fn(_args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_clear_scissor")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
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
    fn(_args) raise @runtime.RuntimeError {
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
    fn(_args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_end_frame")
        if ctx.gpu is Some(gpu) {
          gpu.end_frame()
        }
        host_trace("host: gpu_end_frame done")
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
    fn(args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_create_render_target")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
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
    "gpu_create_render_target_rgba16f",
    fn(args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_create_render_target_rgba16f")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
        }
        if args.length() >= 3 &&
          args[0] is @types.Value::I32(w) &&
          args[1] is @types.Value::I32(h) &&
          args[2] is @types.Value::I32(nearest_i32) {
          let id = ctx.gpu
            .unwrap()
            .create_render_target_rgba16f(w, h, nearest_i32 != 0)
          ok_i32(id)
        } else {
          ok_i32(-1)
        }
      } catch {
        _ => {
          @debug.debug("gpu_create_render_target_rgba16f failed")
          host_fail("gpu_create_render_target_rgba16f", "<error>")
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
    fn(args) raise @runtime.RuntimeError {
      if ctx.gpu is None {
        ensure_gpu_backend(ctx)
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
    fn(args) raise @runtime.RuntimeError {
      if ctx.gpu is None {
        ensure_gpu_backend(ctx)
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
    fn(args) raise @runtime.RuntimeError {
      if ctx.gpu is None {
        ensure_gpu_backend(ctx)
      }
      if args.length() >= 1 && args[0] is @types.Value::I32(text_id) {
        match string_table_get(ctx, text_id) {
          Some(csv) =>
            match parse_f32_csv_list(csv) {
              Some(verts) =>
                ok_i32(ctx.gpu.unwrap().create_mesh_triangles_xyuvrgba(verts))
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
    "gpu_create_mesh3d",
    fn(args) raise @runtime.RuntimeError {
      if ctx.gpu is None {
        ensure_gpu_backend(ctx)
      }
      if args.length() >= 1 && args[0] is @types.Value::I32(text_id) {
        let primitive_topology_kind = if args.length() >= 2 &&
          args[1] is @types.Value::I32(v) {
          v
        } else {
          0
        }
        match string_table_get(ctx, text_id) {
          Some(csv) =>
            match parse_f32_csv_list(csv) {
              Some(verts) =>
                ok_i32(
                  ctx.gpu
                  .unwrap()
                  .create_mesh3d_xyzuvrgba(verts, primitive_topology_kind),
                )
              None => ok_i32(0)
            }
          None => ok_i32(0)
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
    "gpu_create_mesh_triangles3d",
    fn(args) raise @runtime.RuntimeError {
      if ctx.gpu is None {
        ensure_gpu_backend(ctx)
      }
      if args.length() >= 1 && args[0] is @types.Value::I32(text_id) {
        match string_table_get(ctx, text_id) {
          Some(csv) =>
            match parse_f32_csv_list(csv) {
              Some(verts) =>
                ok_i32(ctx.gpu.unwrap().create_mesh3d_xyzuvrgba(verts, 0))
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
    fn(args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_draw_mesh")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
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
          let texture_id = if args.length() > 10 &&
            args[10] is @types.Value::I32(v) {
            v
          } else {
            -1
          }
          let uv_offset_x = if args.length() > 11 &&
            args[11] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let uv_offset_y = if args.length() > 12 &&
            args[12] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let uv_scale_x = if args.length() > 13 &&
            args[13] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let uv_scale_y = if args.length() > 14 &&
            args[14] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          ctx.gpu
          .unwrap()
          .draw_mesh(
            mesh_id, x, y, rot, sx, sy, r, g, b, a, texture_id, uv_offset_x, uv_offset_y,
            uv_scale_x, uv_scale_y,
          )
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
        @types.ValueType::I32,
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
    "gpu_draw_mesh3d",
    fn(args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_draw_mesh3d")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
        }
        if args.length() >= 48 &&
          args[0] is @types.Value::I32(mesh_id) &&
          args[1] is @types.Value::F32(x) &&
          args[2] is @types.Value::F32(y) &&
          args[3] is @types.Value::F32(z) &&
          args[4] is @types.Value::F32(rotation_x) &&
          args[5] is @types.Value::F32(rotation_y) &&
          args[6] is @types.Value::F32(rotation_z) &&
          args[7] is @types.Value::F32(rotation_w) &&
          args[8] is @types.Value::F32(scale_x) &&
          args[9] is @types.Value::F32(scale_y) &&
          args[10] is @types.Value::F32(scale_z) &&
          args[11] is @types.Value::F32(previous_x) &&
          args[12] is @types.Value::F32(previous_y) &&
          args[13] is @types.Value::F32(previous_z) &&
          args[14] is @types.Value::F32(previous_rotation_x) &&
          args[15] is @types.Value::F32(previous_rotation_y) &&
          args[16] is @types.Value::F32(previous_rotation_z) &&
          args[17] is @types.Value::F32(previous_rotation_w) &&
          args[18] is @types.Value::F32(previous_scale_x) &&
          args[19] is @types.Value::F32(previous_scale_y) &&
          args[20] is @types.Value::F32(previous_scale_z) &&
          args[21] is @types.Value::F32(color_r) &&
          args[22] is @types.Value::F32(color_g) &&
          args[23] is @types.Value::F32(color_b) &&
          args[24] is @types.Value::F32(color_a) &&
          args[25] is @types.Value::I32(texture_id) &&
          args[26] is @types.Value::F32(uv_offset_x) &&
          args[27] is @types.Value::F32(uv_offset_y) &&
          args[28] is @types.Value::F32(uv_scale_x) &&
          args[29] is @types.Value::F32(uv_scale_y) {
          let normal_texture_id = if args.length() > 30 &&
            args[30] is @types.Value::I32(v) {
            v
          } else {
            -1
          }
          let emissive_texture_id = if args.length() > 31 &&
            args[31] is @types.Value::I32(v) {
            v
          } else {
            -1
          }
          let metallic_roughness_texture_id = if args.length() > 32 &&
            args[32] is @types.Value::I32(v) {
            v
          } else {
            -1
          }
          let occlusion_texture_id = if args.length() > 33 &&
            args[33] is @types.Value::I32(v) {
            v
          } else {
            -1
          }
          let depth_texture_id = if args.length() > 34 &&
            args[34] is @types.Value::I32(v) {
            v
          } else {
            -1
          }
          let emissive_r = if args.length() > 35 &&
            args[35] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let emissive_g = if args.length() > 36 &&
            args[36] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let emissive_b = if args.length() > 37 &&
            args[37] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let unlit = if args.length() > 38 && args[38] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let metallic = if args.length() > 39 &&
            args[39] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let roughness = if args.length() > 40 &&
            args[40] is @types.Value::F32(v) {
            v
          } else {
            0.5F
          }
          let reflectance = if args.length() > 41 &&
            args[41] is @types.Value::F32(v) {
            v
          } else {
            0.5F
          }
          let parallax_depth_scale = if args.length() > 42 &&
            args[42] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let max_parallax_layer_count = if args.length() > 43 &&
            args[43] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let max_relief_mapping_search_steps = if args.length() > 44 &&
            args[44] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let anisotropy_texture_id = if args.length() > 45 &&
            args[45] is @types.Value::I32(v) {
            v
          } else {
            -1
          }
          let anisotropy_strength = if args.length() > 46 &&
            args[46] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let anisotropy_rotation = if args.length() > 47 &&
            args[47] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let specular_tint_texture_id = if args.length() > 48 &&
            args[48] is @types.Value::I32(v) {
            v
          } else {
            -1
          }
          let specular_tint_r = if args.length() > 49 &&
            args[49] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let specular_tint_g = if args.length() > 50 &&
            args[50] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let specular_tint_b = if args.length() > 51 &&
            args[51] is @types.Value::F32(v) {
            v
          } else {
            1.0F
          }
          let diffuse_transmission = if args.length() > 52 &&
            args[52] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let specular_transmission = if args.length() > 53 &&
            args[53] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let thickness = if args.length() > 54 &&
            args[54] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let ior = if args.length() > 55 && args[55] is @types.Value::F32(v) {
            v
          } else {
            1.5F
          }
          let transmission_source_texture_id = if args.length() > 56 &&
            args[56] is @types.Value::I32(v) {
            v
          } else {
            -1
          }
          let transmission_blur_taps = if args.length() > 57 &&
            args[57] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let transmission_steps = if args.length() > 58 &&
            args[58] is @types.Value::F32(v) {
            v
          } else {
            0.0F
          }
          let cull_mode = if args.length() > 59 &&
            args[59] is @types.Value::I32(v) {
            v
          } else {
            2
          }
          ctx.gpu
          .unwrap()
          .draw_mesh3d(
            mesh_id, x, y, z, rotation_x, rotation_y, rotation_z, rotation_w, scale_x,
            scale_y, scale_z, previous_x, previous_y, previous_z, previous_rotation_x,
            previous_rotation_y, previous_rotation_z, previous_rotation_w, previous_scale_x,
            previous_scale_y, previous_scale_z, color_r, color_g, color_b, color_a,
            texture_id, uv_offset_x, uv_offset_y, uv_scale_x, uv_scale_y, normal_texture_id,
            emissive_texture_id, metallic_roughness_texture_id, occlusion_texture_id,
            depth_texture_id, emissive_r, emissive_g, emissive_b, unlit, metallic,
            roughness, reflectance, parallax_depth_scale, max_parallax_layer_count,
            max_relief_mapping_search_steps, anisotropy_texture_id, anisotropy_strength,
            anisotropy_rotation, specular_tint_texture_id, specular_tint_r, specular_tint_g,
            specular_tint_b, diffuse_transmission, specular_transmission, thickness,
            ior, transmission_source_texture_id, transmission_blur_taps, transmission_steps,
            cull_mode,
          )
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("gpu_draw_mesh3d failed")
          host_fail("gpu_draw_mesh3d", "<error>")
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
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::I32,
        @types.ValueType::I32,
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
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::I32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::I32,
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
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_draw_motion_blur",
    fn(args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_draw_motion_blur")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
        }
        let scene_texture_id = if args.length() > 0 &&
          args[0] is @types.Value::I32(v) {
          v
        } else {
          -1
        }
        let velocity_texture_id = if args.length() > 1 &&
          args[1] is @types.Value::I32(v) {
          v
        } else {
          -1
        }
        let shutter_angle = if args.length() > 2 &&
          args[2] is @types.Value::F32(v) {
          v
        } else {
          0.0F
        }
        let samples = if args.length() > 3 && args[3] is @types.Value::I32(v) {
          v
        } else {
          0
        }
        ctx.gpu
        .unwrap()
        .draw_motion_blur(
          scene_texture_id, velocity_texture_id, shutter_angle, samples,
        )
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("gpu_draw_motion_blur failed")
          host_fail("gpu_draw_motion_blur", "<error>")
        }
      }
    },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::F32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_draw_bloom2d",
    fn(args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_draw_bloom2d")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
        }
        let scene_texture_id = if args.length() > 0 &&
          args[0] is @types.Value::I32(v) {
          v
        } else {
          -1
        }
        let enabled = if args.length() > 1 && args[1] is @types.Value::I32(v) {
          v
        } else {
          1
        }
        let intensity = if args.length() > 2 && args[2] is @types.Value::F32(v) {
          v
        } else {
          0.15F
        }
        let low_frequency_boost = if args.length() > 3 &&
          args[3] is @types.Value::F32(v) {
          v
        } else {
          0.7F
        }
        let low_frequency_boost_curvature = if args.length() > 4 &&
          args[4] is @types.Value::F32(v) {
          v
        } else {
          0.95F
        }
        let high_pass_frequency = if args.length() > 5 &&
          args[5] is @types.Value::F32(v) {
          v
        } else {
          1.0F
        }
        let threshold = if args.length() > 6 && args[6] is @types.Value::F32(v) {
          v
        } else {
          0.0F
        }
        let threshold_softness = if args.length() > 7 &&
          args[7] is @types.Value::F32(v) {
          v
        } else {
          0.0F
        }
        let composite_mode = if args.length() > 8 &&
          args[8] is @types.Value::I32(v) {
          v
        } else {
          0
        }
        let max_mip_dimension = if args.length() > 9 &&
          args[9] is @types.Value::I32(v) {
          v
        } else {
          512
        }
        let scale_x = if args.length() > 10 && args[10] is @types.Value::F32(v) {
          v
        } else {
          1.0F
        }
        let scale_y = if args.length() > 11 && args[11] is @types.Value::F32(v) {
          v
        } else {
          1.0F
        }
        let tonemapping_mode = if args.length() > 12 &&
          args[12] is @types.Value::I32(v) {
          v
        } else {
          0
        }
        let deband_dither_enabled = if args.length() > 13 &&
          args[13] is @types.Value::I32(v) {
          v
        } else {
          0
        }
        let view_width = if args.length() > 14 &&
          args[14] is @types.Value::I32(v) {
          v
        } else {
          1
        }
        let view_height = if args.length() > 15 &&
          args[15] is @types.Value::I32(v) {
          v
        } else {
          1
        }
        let agx_lut_texture_id = if args.length() > 16 &&
          args[16] is @types.Value::I32(v) {
          v
        } else {
          -1
        }
        let tony_lut_texture_id = if args.length() > 17 &&
          args[17] is @types.Value::I32(v) {
          v
        } else {
          -1
        }
        let blender_lut_texture_id = if args.length() > 18 &&
          args[18] is @types.Value::I32(v) {
          v
        } else {
          -1
        }
        ctx.gpu
        .unwrap()
        .draw_bloom2d(
          scene_texture_id, enabled, intensity, low_frequency_boost, low_frequency_boost_curvature,
          high_pass_frequency, threshold, threshold_softness, composite_mode, max_mip_dimension,
          scale_x, scale_y, tonemapping_mode, deband_dither_enabled, view_width,
          view_height, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
        )
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("gpu_draw_bloom2d failed")
          host_fail("gpu_draw_bloom2d", "<error>")
        }
      }
    },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::I32,
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
    "gpu_draw_sprite",
    fn(args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_draw_sprite")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
        }
        if args.length() >= 10 &&
          args[0] is @types.Value::I32(texture_id) &&
          args[1] is @types.Value::F32(x) &&
          args[2] is @types.Value::F32(y) &&
          args[3] is @types.Value::F32(rot) &&
          args[4] is @types.Value::F32(sx) &&
          args[5] is @types.Value::F32(sy) &&
          args[6] is @types.Value::F32(r) &&
          args[7] is @types.Value::F32(g) &&
          args[8] is @types.Value::F32(b) &&
          args[9] is @types.Value::F32(a) {
          ctx.gpu
          .unwrap()
          .draw_sprite_uv(
            texture_id, x, y, rot, sx, sy, r, g, b, a, 0.0, 0.0, 1.0, 1.0,
          )
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("gpu_draw_sprite failed")
          host_fail("gpu_draw_sprite", "<error>")
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
    fn(args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_draw_sprite_uv")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
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
    "gpu_draw_ui_rect",
    fn(args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_draw_ui_rect")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
        }
        if args.length() >= 23 &&
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
          args[13] is @types.Value::F32(uv_max_y) &&
          args[14] is @types.Value::I32(flags) &&
          args[15] is @types.Value::F32(radius_tl) &&
          args[16] is @types.Value::F32(radius_tr) &&
          args[17] is @types.Value::F32(radius_br) &&
          args[18] is @types.Value::F32(radius_bl) &&
          args[19] is @types.Value::F32(border_left) &&
          args[20] is @types.Value::F32(border_top) &&
          args[21] is @types.Value::F32(border_right) &&
          args[22] is @types.Value::F32(border_bottom) {
          ctx.gpu
          .unwrap()
          .draw_ui_rect(
            texture_id, x, y, rot, sx, sy, r, g, b, a, uv_min_x, uv_min_y, uv_max_x,
            uv_max_y, flags, radius_tl, radius_tr, radius_br, radius_bl, border_left,
            border_top, border_right, border_bottom,
          )
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("gpu_draw_ui_rect failed")
          host_fail("gpu_draw_ui_rect", "<error>")
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
        @types.ValueType::I32,
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
    "gpu_draw_ui_texture_slice",
    fn(args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_draw_ui_texture_slice")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
        }
        if args.length() >= 26 &&
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
          args[10] is @types.Value::F32(texture_slice_l) &&
          args[11] is @types.Value::F32(texture_slice_t) &&
          args[12] is @types.Value::F32(texture_slice_r) &&
          args[13] is @types.Value::F32(texture_slice_b) &&
          args[14] is @types.Value::F32(target_slice_l) &&
          args[15] is @types.Value::F32(target_slice_t) &&
          args[16] is @types.Value::F32(target_slice_r) &&
          args[17] is @types.Value::F32(target_slice_b) &&
          args[18] is @types.Value::F32(repeat_side_x) &&
          args[19] is @types.Value::F32(repeat_side_y) &&
          args[20] is @types.Value::F32(repeat_center_x) &&
          args[21] is @types.Value::F32(repeat_center_y) &&
          args[22] is @types.Value::F32(atlas_l) &&
          args[23] is @types.Value::F32(atlas_t) &&
          args[24] is @types.Value::F32(atlas_r) &&
          args[25] is @types.Value::F32(atlas_b) {
          ctx.gpu
          .unwrap()
          .draw_ui_texture_slice(
            texture_id, x, y, rot, sx, sy, r, g, b, a, texture_slice_l, texture_slice_t,
            texture_slice_r, texture_slice_b, target_slice_l, target_slice_t, target_slice_r,
            target_slice_b, repeat_side_x, repeat_side_y, repeat_center_x, repeat_center_y,
            atlas_l, atlas_t, atlas_r, atlas_b,
          )
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("gpu_draw_ui_texture_slice failed")
          host_fail("gpu_draw_ui_texture_slice", "<error>")
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
    "gpu_draw_ui_box_shadow",
    fn(args) raise @runtime.RuntimeError {
      try {
        host_trace("host: gpu_draw_ui_box_shadow")
        if ctx.gpu is None {
          ensure_gpu_backend(ctx)
        }
        if args.length() >= 18 &&
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
          args[10] is @types.Value::F32(size_x) &&
          args[11] is @types.Value::F32(size_y) &&
          args[12] is @types.Value::F32(radius_tl) &&
          args[13] is @types.Value::F32(radius_tr) &&
          args[14] is @types.Value::F32(radius_br) &&
          args[15] is @types.Value::F32(radius_bl) &&
          args[16] is @types.Value::F32(blur) &&
          args[17] is @types.Value::I32(samples) {
          ctx.gpu
          .unwrap()
          .draw_ui_box_shadow(
            texture_id, x, y, rot, sx, sy, r, g, b, a, size_x, size_y, radius_tl,
            radius_tr, radius_br, radius_bl, blur, samples,
          )
        }
        ok_i32(0)
      } catch {
        _ => {
          @debug.debug("gpu_draw_ui_box_shadow failed")
          host_fail("gpu_draw_ui_box_shadow", "<error>")
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
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::I32,
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
