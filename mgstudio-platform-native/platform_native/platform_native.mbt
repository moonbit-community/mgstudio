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
pub(all) suberror PlatformError {
  InitFailed(String)
  GpuFailed(String)
}

///|
priv struct PlatformContext {
  mut gpu : GpuBackend?
  mut window : @win.Window?
  assets_source : @rtcore.SourceSpec
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
}

///|
let platform_ctx : Ref[PlatformContext?] = Ref::new(None)

///|
const HANDLE_BASE : Int = 10_000

///|
extern "C" fn c_time_now_seconds() -> Float = "mgstudio_time_now"

///|
fn platform_trace(msg : String) -> Unit {
  match @sys.get_env_var("MGSTUDIO_PLATFORM_TRACE") {
    Some(v) if v.trim() != "" => @debug.debug(msg)
    _ => ()
  }
}

///|
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

///|
fn read_env_source_specs() -> (@rtcore.SourceSpec, @rtcore.SourceSpec) raise {
  let assets_spec = @sys.get_env_var("MGSTUDIO_ASSETS_SOURCE").unwrap_or(
    "dir:.",
  )
  let data_spec = @sys.get_env_var("MGSTUDIO_DATA_SOURCE").unwrap_or(
    "dir:./tmp/data",
  )
  let assets = @rtcore.parse_dir_source(Some(assets_spec), ".")
  let data = @rtcore.parse_dir_source(Some(data_spec), "./tmp/data")
  (assets, data)
}

///|
fn ensure_context() -> PlatformContext raise {
  if platform_ctx.val is Some(ctx) {
    return ctx
  }
  let (assets_source, data_source) = read_env_source_specs() catch {
    err => raise PlatformError::InitFailed(err.to_string())
  }
  ensure_dir_all(data_source.base)
  let ctx = PlatformContext::{
    gpu: None,
    window: None,
    assets_source,
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
  }
  platform_ctx.val = Some(ctx)
  ctx
}

///|
fn string_table_get(ctx : PlatformContext, id : Int) -> String? {
  if id <= 0 {
    return None
  }
  let entries = ctx.strings.val
  for i in 0..<entries.length() {
    if entries[i].0 == id {
      return Some(entries[i].1)
    }
  }
  None
}

///|
fn string_table_put(ctx : PlatformContext, text : String) -> Int {
  if text == "" {
    return 0
  }
  let id = ctx.next_string_id.val
  ctx.next_string_id.val = id + 1
  ctx.strings.val.push((id, text))
  id
}

///|
fn string_table_drop(ctx : PlatformContext, id : Int) -> Unit {
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
fn bytes_table_get(ctx : PlatformContext, id : Int) -> Bytes? {
  if id <= 0 {
    return None
  }
  let entries = ctx.bytes.val
  for i in 0..<entries.length() {
    if entries[i].0 == id {
      return Some(entries[i].1)
    }
  }
  None
}

///|
fn bytes_table_put(ctx : PlatformContext, data : Bytes) -> Int {
  if data.length() == 0 {
    return 0
  }
  let id = ctx.next_bytes_id.val
  ctx.next_bytes_id.val = id + 1
  ctx.bytes.val.push((id, data))
  id
}

///|
fn bytes_table_drop(ctx : PlatformContext, id : Int) -> Unit {
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
fn font_table_get(ctx : PlatformContext, id : Int) -> Bytes? {
  if id <= 0 {
    return None
  }
  let entries = ctx.fonts.val
  for i in 0..<entries.length() {
    if entries[i].0 == id {
      return Some(entries[i].1)
    }
  }
  None
}

///|
fn font_table_put(ctx : PlatformContext, data : Bytes) -> Int {
  let id = ctx.next_font_id.val
  ctx.next_font_id.val = id + 1
  ctx.fonts.val.push((id, data))
  id
}

///|
fn shader_table_put(ctx : PlatformContext, source : String) -> Int {
  let id = ctx.next_shader_id.val
  ctx.next_shader_id.val = id + 1
  ctx.shaders.val.push((id, source))
  id
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
fn strip_leading_slashes(text : String) -> String {
  let n = text.length()
  let mut i = 0
  while i < n && text.code_unit_at(i).to_int() == 47 {
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
    let v = @strconv.parse_double(s) catch { _ => return None }
    out.push(Float::from_double(v))
  }
  Some(out)
}

///|
fn join_fs_path(base : String, entry : String) -> String {
  if base == "" {
    return entry
  }
  if entry == "" {
    return base
  }
  @path.Path(base).join(@path.Path(entry)).to_string()
}

///|
fn ensure_gpu_backend(ctx : PlatformContext) -> Unit raise {
  if ctx.gpu is Some(_) {
    return
  }
  let gpu = GpuBackend::new(assets_base=ctx.assets_source.base) catch {
    err => raise PlatformError::GpuFailed(err.to_string())
  }
  ctx.gpu = Some(gpu)
}

///|
fn load_texture_from_assets(
  ctx : PlatformContext,
  rel_path : String,
  nearest : Bool,
) -> Int raise {
  ensure_gpu_backend(ctx)
  let rel = rel_path.trim().to_string()
  let full_path = if rel == "" {
    ""
  } else {
    @rtcore.join_dir(ctx.assets_source.base, strip_leading_slashes(rel)) catch {
      _ => join_fs_path(ctx.assets_source.base, rel)
    }
  }
  let raw = if full_path == "" {
    Bytes::makei(0, _ => (0).to_byte())
  } else {
    @fs.read_file_to_bytes(full_path) catch {
      _ => Bytes::makei(0, _ => (0).to_byte())
    }
  }
  let pixels = match @img.decode_rgba8(raw) {
    Some(img) => {
      let width = img.width()
      let height = img.height()
      let data = img.pixels_rgba8()
      img.destroy()
      (width, height, data)
    }
    None => {
      let fallback = Bytes::makei(4, _ => (255).to_byte())
      (1, 1, fallback)
    }
  }
  ctx.gpu.unwrap().create_texture_rgba8(pixels.0, pixels.1, pixels.2, nearest)
}

///|
fn folder_table_set(
  ctx : PlatformContext,
  folder_id : Int,
  handles : Array[Int],
) -> Unit {
  let entries = ctx.folders.val
  for i in 0..<entries.length() {
    if entries[i].0 == folder_id {
      entries[i] = (folder_id, handles)
      return
    }
  }
  entries.push((folder_id, handles))
}

///|
fn folder_table_get(ctx : PlatformContext, folder_id : Int) -> Array[Int]? {
  let entries = ctx.folders.val
  for i in 0..<entries.length() {
    if entries[i].0 == folder_id {
      return Some(entries[i].1)
    }
  }
  None
}

///|
fn folder_events_push(
  ctx : PlatformContext,
  kind : Int,
  folder_id : Int,
) -> Unit {
  let pos = ctx.folder_events_pos.val
  if pos >= ctx.folder_events.val.length() {
    ctx.folder_events.val.clear()
    ctx.folder_events_pos.val = 0
  }
  ctx.folder_events.val.push(kind)
  ctx.folder_events.val.push(folder_id)
}

///|
pub fn string_sink_reset() -> Unit {
  let ctx = ensure_context() catch { _ => return }
  ctx.string_sink.val.clear()
}

///|
pub fn string_sink_push(code_unit : Int) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if code_unit < 0 || code_unit > 0xFFFF {
    return
  }
  ctx.string_sink.val.push(Int::unsafe_to_char(code_unit))
}

///|
pub fn string_sink_take() -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  if ctx.string_sink.val.length() == 0 {
    return 0
  }
  let text = String::from_array(ctx.string_sink.val)
  ctx.string_sink.val.clear()
  string_table_put(ctx, text)
}

///|
pub fn string_drop(id : Int) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  string_table_drop(ctx, id)
}

///|
pub fn bytes_sink_reset() -> Unit {
  let ctx = ensure_context() catch { _ => return }
  ctx.bytes_sink.val.clear()
}

///|
pub fn bytes_sink_push(byte : Int) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if byte < 0 || byte > 255 {
    return
  }
  ctx.bytes_sink.val.push(byte.to_byte())
}

///|
pub fn bytes_sink_push_u32(word : Int) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  let u = word.reinterpret_as_uint()
  for i in 0..<4 {
    let b = ((u >> (i * 8)) & 0xFFU).reinterpret_as_int()
    ctx.bytes_sink.val.push(b.to_byte())
  }
}

///|
pub fn bytes_sink_take() -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  if ctx.bytes_sink.val.length() == 0 {
    return 0
  }
  let id = bytes_table_put(ctx, Bytes::from_array(ctx.bytes_sink.val))
  ctx.bytes_sink.val.clear()
  id
}

///|
pub fn bytes_drop(id : Int) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  bytes_table_drop(ctx, id)
}

///|
pub fn debug_string(value_id : Int) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  match string_table_get(ctx, value_id) {
    Some(text) => @debug.debug(text)
    None => ()
  }
}

///|
pub fn a11y_begin_update(root_id : Int) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.window is Some(win) {
    win.a11y_begin_update(root_id)
  }
}

///|
pub fn a11y_push_node(
  node_id : Int,
  parent_id : Int,
  role_id : Int,
  x : Float,
  y : Float,
  width : Float,
  height : Float,
  name_id : Int,
  actions_mask : Int,
) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  let name = string_table_get(ctx, name_id).unwrap_or("")
  if ctx.window is Some(win) {
    win.a11y_push_node(
      node_id, parent_id, role_id, x, y, width, height, name, actions_mask,
    )
  }
}

///|
pub fn a11y_end_update() -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.window is Some(win) {
    win.a11y_end_update()
  }
}

///|
pub fn a11y_apply_update(payload_id : Int) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  guard ctx.window is Some(win) else { return }
  let payload = string_table_get(ctx, payload_id).unwrap_or("")
  if payload == "" {
    return
  }
  let json = @json.parse(payload) catch { _ => return }
  let update : @moon_accesskit.TreeUpdate = @json.from_json(json) catch {
    _ => return
  }
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
      @moon_accesskit.Role::Button | @moon_accesskit.Role::DefaultButton => 3
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
        Some(v) => v
        None => node.label().unwrap_or("")
      }
    } else {
      match node.label() {
        Some(v) => v
        None => node.value().unwrap_or("")
      }
    }
  }
  win.a11y_begin_update(-1)
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
      let parent_int = if parent_id == 0UL { -1 } else { parent_id.to_int() }
      let node_int = cur_id.to_int()
      let supports_scroll = node.supports_action(
          @moon_accesskit.Action::ScrollUp,
        ) ||
        node.supports_action(@moon_accesskit.Action::ScrollDown) ||
        node.supports_action(@moon_accesskit.Action::ScrollLeft) ||
        node.supports_action(@moon_accesskit.Action::ScrollRight)
      let actions_mask = (if node.supports_action(@moon_accesskit.Action::Focus) {
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
      if node.bounds() is Some(b) {
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
}

///|
pub fn a11y_actions_len() -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  match ctx.window {
    Some(win) => win.a11y_actions_len()
    None => 0
  }
}

///|
pub fn a11y_action_target(index : Int) -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  match ctx.window {
    Some(win) => win.a11y_action_target(index)
    None => 0
  }
}

///|
pub fn a11y_action_kind(index : Int) -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  match ctx.window {
    Some(win) => win.a11y_action_kind(index)
    None => 0
  }
}

///|
pub fn a11y_action_value_len(index : Int) -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  match ctx.window {
    Some(win) => win.a11y_action_value_len(index)
    None => 0
  }
}

///|
pub fn a11y_action_value_code_unit(index : Int, offset : Int) -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  match ctx.window {
    Some(win) => win.a11y_action_value_code_unit(index, offset)
    None => 0
  }
}

///|
pub fn a11y_actions_clear() -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.window is Some(win) {
    win.a11y_actions_clear()
  }
}

///|
pub fn window_create(width : Int, height : Int, title_id : Int) -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  let title = string_table_get(ctx, title_id).unwrap_or("Moon Game Studio")
  let win = @win.Window::create(width, height, title)
  ctx.window = Some(win)
  HANDLE_BASE + 1
}

///|
pub fn window_poll_events(_window : Int) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.window is Some(win) {
    win.poll_events()
  }
}

///|
pub fn window_get_width(_window : Int) -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  match ctx.window {
    Some(win) => win.width()
    None => 0
  }
}

///|
pub fn window_get_height(_window : Int) -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  match ctx.window {
    Some(win) => win.height()
    None => 0
  }
}

///|
pub fn window_get_scale_factor(_window : Int) -> Float {
  let ctx = ensure_context() catch { _ => return 1.0 }
  match ctx.window {
    Some(win) => win.scale_factor()
    None => 1.0
  }
}

///|
pub fn window_should_close(_window : Int) -> Bool {
  let ctx = ensure_context() catch { _ => return true }
  match ctx.window {
    Some(win) => win.should_close()
    None => true
  }
}

///|
pub fn window_request_close(_window : Int) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.window is Some(win) {
    win.request_close()
  }
}

///|
pub fn window_run_loop(step : FuncRef[() -> Unit]) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  platform_trace("platform native run loop start")
  while true {
    step()
    if ctx.window is Some(win) && win.should_close() {
      break
    }
  }
}

///|
pub fn time_now() -> Float {
  c_time_now_seconds()
}

///|
pub fn input_finish_frame() -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.window is Some(win) {
    win.input_finish_frame()
  }
}

///|
pub fn input_has_cursor() -> Bool {
  let ctx = ensure_context() catch { _ => return false }
  match ctx.window {
    Some(win) => win.input_has_cursor()
    None => false
  }
}

///|
pub fn input_mouse_x() -> Float {
  let ctx = ensure_context() catch { _ => return 0.0 }
  match ctx.window {
    Some(win) => win.input_mouse_x()
    None => 0.0
  }
}

///|
pub fn input_mouse_y() -> Float {
  let ctx = ensure_context() catch { _ => return 0.0 }
  match ctx.window {
    Some(win) => win.input_mouse_y()
    None => 0.0
  }
}

///|
pub fn input_wheel_x() -> Float {
  let ctx = ensure_context() catch { _ => return 0.0 }
  match ctx.window {
    Some(win) => win.input_wheel_x()
    None => 0.0
  }
}

///|
pub fn input_wheel_y() -> Float {
  let ctx = ensure_context() catch { _ => return 0.0 }
  match ctx.window {
    Some(win) => win.input_wheel_y()
    None => 0.0
  }
}

///|
pub fn input_is_key_down(code_id : Int) -> Bool {
  let ctx = ensure_context() catch { _ => return false }
  guard ctx.window is Some(win) else { return false }
  let code = string_table_get(ctx, code_id).unwrap_or("")
  macos_keycode_from_string(code) is Some(keycode) &&
  win.input_is_key_down(keycode)
}

///|
pub fn input_is_key_just_pressed(code_id : Int) -> Bool {
  let ctx = ensure_context() catch { _ => return false }
  guard ctx.window is Some(win) else { return false }
  let code = string_table_get(ctx, code_id).unwrap_or("")
  macos_keycode_from_string(code) is Some(keycode) &&
  win.input_is_key_just_pressed(keycode)
}

///|
pub fn input_is_key_just_released(code_id : Int) -> Bool {
  let ctx = ensure_context() catch { _ => return false }
  guard ctx.window is Some(win) else { return false }
  let code = string_table_get(ctx, code_id).unwrap_or("")
  macos_keycode_from_string(code) is Some(keycode) &&
  win.input_is_key_just_released(keycode)
}

///|
pub fn input_is_mouse_button_down(button_id : Int) -> Bool {
  let ctx = ensure_context() catch { _ => return false }
  guard ctx.window is Some(win) else { return false }
  let button = string_table_get(ctx, button_id).unwrap_or("")
  mouse_button_from_string(button) is Some(v) &&
  win.input_is_mouse_button_down(v)
}

///|
pub fn input_is_mouse_button_just_pressed(button_id : Int) -> Bool {
  let ctx = ensure_context() catch { _ => return false }
  guard ctx.window is Some(win) else { return false }
  let button = string_table_get(ctx, button_id).unwrap_or("")
  mouse_button_from_string(button) is Some(v) &&
  win.input_is_mouse_button_just_pressed(v)
}

///|
pub fn input_is_mouse_button_just_released(button_id : Int) -> Bool {
  let ctx = ensure_context() catch { _ => return false }
  guard ctx.window is Some(win) else { return false }
  let button = string_table_get(ctx, button_id).unwrap_or("")
  mouse_button_from_string(button) is Some(v) &&
  win.input_is_mouse_button_just_released(v)
}

///|
pub fn asset_load_texture(path_id : Int, nearest : Bool) -> Int {
  let ctx = ensure_context() catch { _ => return -1 }
  let rel = string_table_get(ctx, path_id).unwrap_or("")
  load_texture_from_assets(ctx, rel, nearest) catch {
    _ => -1
  }
}

///|
pub fn asset_load_wgsl(path_id : Int) -> Int {
  let ctx = ensure_context() catch { _ => return -1 }
  let rel = string_table_get(ctx, path_id).unwrap_or("")
  if rel == "" {
    return -1
  }
  let full_path = @rtcore.join_dir(
    ctx.assets_source.base,
    strip_leading_slashes(rel),
  ) catch {
    _ => join_fs_path(ctx.assets_source.base, rel)
  }
  let source = @fs.read_file_to_string(full_path) catch { _ => "" }
  if source == "" {
    -1
  } else {
    shader_table_put(ctx, source)
  }
}

///|
pub fn asset_load_font(path_id : Int) -> Int {
  let ctx = ensure_context() catch { _ => return -1 }
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
  font_table_put(ctx, bytes)
}

///|
pub fn asset_font_bytes_len(font_id : Int) -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  match font_table_get(ctx, font_id) {
    Some(b) => b.length()
    None => 0
  }
}

///|
pub fn asset_font_bytes_get(font_id : Int, index : Int) -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  match font_table_get(ctx, font_id) {
    Some(b) =>
      match b.get(index) {
        Some(v) => v.to_int()
        None => 0
      }
    None => 0
  }
}

///|
pub fn asset_font_bytes_get_u32(font_id : Int, index : Int) -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  if index < 0 {
    return 0
  }
  match font_table_get(ctx, font_id) {
    Some(b) => {
      let mut out : UInt = 0U
      for j in 0..<4 {
        if b.get(index + j) is Some(v) {
          out = out | ((v.to_int().reinterpret_as_uint() & 0xFFU) << (j * 8))
        }
      }
      out.reinterpret_as_int()
    }
    None => 0
  }
}

///|
pub fn font_rasterize_glyph(
  _font_id : Int,
  _font_size : Float,
  _glyph_code : Int,
  _smoothing : Int,
) -> Int {
  -1
}

///|
pub fn font_glyph_width(_glyph_id : Int) -> Int {
  0
}

///|
pub fn font_glyph_height(_glyph_id : Int) -> Int {
  0
}

///|
pub fn font_glyph_offset_x(_glyph_id : Int) -> Int {
  0
}

///|
pub fn font_glyph_offset_y(_glyph_id : Int) -> Int {
  0
}

///|
pub fn font_measure_advance(
  _font_id : Int,
  _font_size : Float,
  _codepoint : Int,
) -> Float {
  0.0
}

///|
pub fn asset_set_texture_sampler(texture_id : Int, sampler_kind : Int) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  ensure_gpu_backend(ctx) catch {
    _ => return
  }
  ctx.gpu.unwrap().set_texture_sampler(texture_id, sampler_kind) catch {
    _ => ()
  }
}

///|
pub fn asset_create_dynamic_texture(
  width : Int,
  height : Int,
  nearest : Bool,
) -> Int {
  let ctx = ensure_context() catch { _ => return -1 }
  ensure_gpu_backend(ctx) catch {
    _ => return -1
  }
  let w = if width <= 0 { 1 } else { width }
  let h = if height <= 0 { 1 } else { height }
  let pixels = Bytes::makei(w * h * 4, _ => (0).to_byte())
  ctx.gpu.unwrap().create_texture_rgba8(w, h, pixels, nearest) catch {
    _ => -1
  }
}

///|
pub fn asset_update_texture_region(
  _texture_id : Int,
  _x : Int,
  _y : Int,
  _width : Int,
  _height : Int,
  _glyph_id : Int,
) -> Unit {
  ()
}

///|
pub fn asset_update_texture_region_bytes(
  texture_id : Int,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  bytes_id : Int,
) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  ensure_gpu_backend(ctx) catch {
    _ => return
  }
  if bytes_table_get(ctx, bytes_id) is Some(pixels) {
    ctx.gpu
    .unwrap()
    .write_texture_region_rgba8(texture_id, x, y, width, height, pixels)
  }
}

///|
pub fn asset_texture_width(texture_id : Int) -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  match ctx.gpu {
    Some(gpu) => gpu.texture_width(texture_id)
    None => 0
  }
}

///|
pub fn asset_texture_height(texture_id : Int) -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  match ctx.gpu {
    Some(gpu) => gpu.texture_height(texture_id)
    None => 0
  }
}

///|
pub fn asset_is_texture_loaded(texture_id : Int) -> Bool {
  let ctx = ensure_context() catch { _ => return false }
  match ctx.gpu {
    Some(gpu) => gpu.is_texture_loaded(texture_id)
    None => false
  }
}

///|
pub fn asset_copy_texture_to_texture(
  dst_texture_id : Int,
  dst_x : Int,
  dst_y : Int,
  src_texture_id : Int,
) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  ensure_gpu_backend(ctx) catch {
    _ => return
  }
  let gpu = ctx.gpu.unwrap()
  let w = gpu.texture_width(src_texture_id)
  let h = gpu.texture_height(src_texture_id)
  if w <= 0 || h <= 0 {
    return
  }
  let byte_len = w * h * 4
  let pixels = Bytes::makei(byte_len, _ => (0).to_byte())
  gpu.write_texture_region_rgba8(dst_texture_id, dst_x, dst_y, w, h, pixels)
}

///|
pub fn asset_load_folder(path_id : Int) -> Int {
  let ctx = ensure_context() catch { _ => return -1 }
  let base_rel = string_table_get(ctx, path_id).unwrap_or("").trim().to_string()
  if base_rel == "" {
    return -1
  }
  let folder_id = ctx.next_folder_id.val
  ctx.next_folder_id.val = folder_id + 1
  let manifest_rel = join_fs_path(base_rel, "folder.txt")
  let manifest_path = @rtcore.join_dir(
    ctx.assets_source.base,
    strip_leading_slashes(manifest_rel),
  ) catch {
    _ => join_fs_path(ctx.assets_source.base, manifest_rel)
  }
  let manifest = @fs.read_file_to_string(manifest_path) catch { _ => "" }
  let handles : Array[Int] = []
  for line in manifest.split("\n") {
    let entry = line.to_string().trim().to_string()
    if entry == "" || entry.has_prefix("#") {
      continue
    }
    let rel = join_fs_path(base_rel, entry)
    let id = load_texture_from_assets(ctx, rel, false) catch { _ => -1 }
    if id >= 0 {
      handles.push(id)
    }
  }
  folder_table_set(ctx, folder_id, handles)
  folder_events_push(ctx, 3, folder_id)
  folder_id
}

///|
pub fn asset_poll_loaded_folder_event_kind() -> Int {
  let ctx = ensure_context() catch { _ => return -1 }
  let pos = ctx.folder_events_pos.val
  if pos >= ctx.folder_events.val.length() {
    -1
  } else {
    ctx.folder_events.val[pos]
  }
}

///|
pub fn asset_poll_loaded_folder_event_id() -> Int {
  let ctx = ensure_context() catch { _ => return -1 }
  let pos = ctx.folder_events_pos.val
  if pos + 1 >= ctx.folder_events.val.length() {
    ctx.folder_events.val.clear()
    ctx.folder_events_pos.val = 0
    -1
  } else {
    let id = ctx.folder_events.val[pos + 1]
    let next_pos = pos + 2
    if next_pos >= ctx.folder_events.val.length() {
      ctx.folder_events.val.clear()
      ctx.folder_events_pos.val = 0
    } else {
      ctx.folder_events_pos.val = next_pos
    }
    id
  }
}

///|
pub fn asset_loaded_folder_handles_len(folder_id : Int) -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  match folder_table_get(ctx, folder_id) {
    Some(handles) => handles.length()
    None => 0
  }
}

///|
pub fn asset_loaded_folder_handles_get(folder_id : Int, index : Int) -> Int {
  let ctx = ensure_context() catch { _ => return -1 }
  match folder_table_get(ctx, folder_id) {
    Some(handles) =>
      match handles.get(index) {
        Some(v) => v
        None => -1
      }
    None => -1
  }
}

///|
pub fn gpu_request_device() -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  ensure_gpu_backend(ctx) catch {
    _ => return 0
  }
  HANDLE_BASE + 10
}

///|
pub fn gpu_get_queue(_device : Int) -> Int {
  HANDLE_BASE + 13
}

///|
pub fn gpu_create_surface(_window : Int) -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  ensure_gpu_backend(ctx) catch {
    _ => return 0
  }
  if ctx.window is Some(win) {
    ctx.gpu.unwrap().create_surface(win)
  }
  HANDLE_BASE + 11
}

///|
pub fn gpu_configure_surface(
  _device : Int,
  _surface : Int,
  width : Int,
  height : Int,
) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  ensure_gpu_backend(ctx) catch {
    _ => return
  }
  ctx.gpu.unwrap().configure_surface(width, height)
}

///|
pub fn gpu_begin_frame(_surface : Int) -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  ensure_gpu_backend(ctx) catch {
    _ => return 0
  }
  if ctx.window is Some(win) {
    ctx.gpu.unwrap().ensure_surface_configured(win.width(), win.height())
  }
  ctx.gpu.unwrap().begin_frame()
  HANDLE_BASE + 12
}

///|
pub fn gpu_end_frame(_frame : Int) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.gpu is Some(gpu) {
    gpu.end_frame() catch {
      _ => ()
    }
  }
}

///|
pub fn gpu_begin_pass(
  target_id : Int,
  width : Int,
  height : Int,
  clear_r : Float,
  clear_g : Float,
  clear_b : Float,
  clear_a : Float,
  camera_x : Float,
  camera_y : Float,
  camera_rotation : Float,
  camera_scale : Float,
  viewport_x : Int,
  viewport_y : Int,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.gpu is Some(gpu) {
    gpu.begin_pass(
      target_id, width, height, clear_r, clear_g, clear_b, clear_a, camera_x, camera_y,
      camera_rotation, camera_scale, viewport_x, viewport_y, viewport_width, viewport_height,
    ) catch {
      _ => ()
    }
  }
}

///|
pub fn gpu_begin_pass_3d(
  target_id : Int,
  width : Int,
  height : Int,
  clear_r : Float,
  clear_g : Float,
  clear_b : Float,
  clear_a : Float,
  camera_x : Float,
  camera_y : Float,
  camera_z : Float,
  camera_rot_x : Float,
  camera_rot_y : Float,
  camera_rot_z : Float,
  camera_rot_w : Float,
  camera_fov_y : Float,
  camera_near : Float,
  camera_far : Float,
  viewport_x : Int,
  viewport_y : Int,
  viewport_width : Int,
  viewport_height : Int,
  ambient_r : Float,
  ambient_g : Float,
  ambient_b : Float,
  ambient_brightness : Float,
  directional_dir_x : Float,
  directional_dir_y : Float,
  directional_dir_z : Float,
  directional_color_r : Float,
  directional_color_g : Float,
  directional_color_b : Float,
  directional_illuminance : Float,
  point_pos_x : Float,
  point_pos_y : Float,
  point_pos_z : Float,
  point_color_r : Float,
  point_color_g : Float,
  point_color_b : Float,
  point_intensity : Float,
  point_range : Float,
  spot_pos_x : Float,
  spot_pos_y : Float,
  spot_pos_z : Float,
  spot_dir_x : Float,
  spot_dir_y : Float,
  spot_dir_z : Float,
  spot_color_r : Float,
  spot_color_g : Float,
  spot_color_b : Float,
  spot_intensity : Float,
  spot_range : Float,
  spot_inner_angle : Float,
  spot_outer_angle : Float,
) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.gpu is Some(gpu) {
    gpu.begin_pass_3d(
      target_id, width, height, clear_r, clear_g, clear_b, clear_a, camera_x, camera_y,
      camera_z, camera_rot_x, camera_rot_y, camera_rot_z, camera_rot_w, camera_fov_y,
      camera_near, camera_far, viewport_x, viewport_y, viewport_width, viewport_height,
      ambient_r, ambient_g, ambient_b, ambient_brightness, directional_dir_x, directional_dir_y,
      directional_dir_z, directional_color_r, directional_color_g, directional_color_b,
      directional_illuminance, point_pos_x, point_pos_y, point_pos_z, point_color_r,
      point_color_g, point_color_b, point_intensity, point_range, spot_pos_x, spot_pos_y,
      spot_pos_z, spot_dir_x, spot_dir_y, spot_dir_z, spot_color_r, spot_color_g,
      spot_color_b, spot_intensity, spot_range, spot_inner_angle, spot_outer_angle,
    ) catch {
      _ => ()
    }
  }
}

///|
pub fn gpu_set_scissor(x : Int, y : Int, width : Int, height : Int) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.gpu is Some(gpu) {
    gpu.set_scissor(x, y, width, height) catch {
      _ => ()
    }
  }
}

///|
pub fn gpu_clear_scissor() -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.gpu is Some(gpu) {
    gpu.clear_scissor() catch {
      _ => ()
    }
  }
}

///|
pub fn gpu_end_pass() -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.gpu is Some(gpu) {
    gpu.end_pass() catch {
      _ => ()
    }
  }
}

///|
pub fn gpu_create_render_target(
  width : Int,
  height : Int,
  nearest : Bool,
) -> Int {
  let ctx = ensure_context() catch { _ => return -1 }
  ensure_gpu_backend(ctx) catch {
    _ => return -1
  }
  ctx.gpu.unwrap().create_render_target(width, height, nearest) catch {
    _ => -1
  }
}

///|
pub fn gpu_create_mesh_capsule(
  radius : Float,
  half_length : Float,
  segments : Int,
) -> Int {
  let ctx = ensure_context() catch { _ => return -1 }
  ensure_gpu_backend(ctx) catch {
    _ => return -1
  }
  ctx.gpu.unwrap().create_mesh_capsule(radius, half_length, segments)
}

///|
pub fn gpu_create_mesh_rectangle(width : Float, height : Float) -> Int {
  let ctx = ensure_context() catch { _ => return -1 }
  ensure_gpu_backend(ctx) catch {
    _ => return -1
  }
  ctx.gpu.unwrap().create_mesh_rectangle(width, height)
}

///|
pub fn gpu_create_mesh_triangles(text_id : Int) -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  ensure_gpu_backend(ctx) catch {
    _ => return 0
  }
  let csv = string_table_get(ctx, text_id).unwrap_or("")
  match parse_f32_csv_list(csv) {
    Some(verts) => ctx.gpu.unwrap().create_mesh_triangles_xyuvrgba(verts)
    None => 0
  }
}

///|
pub fn gpu_create_mesh_triangles3d(text_id : Int) -> Int {
  let ctx = ensure_context() catch { _ => return 0 }
  ensure_gpu_backend(ctx) catch {
    _ => return 0
  }
  let csv = string_table_get(ctx, text_id).unwrap_or("")
  match parse_f32_csv_list(csv) {
    Some(verts) => ctx.gpu.unwrap().create_mesh_triangles_xyzuvrgba(verts)
    None => 0
  }
}

///|
pub fn gpu_draw_sprite(
  texture_id : Int,
  x : Float,
  y : Float,
  rot : Float,
  sx : Float,
  sy : Float,
  r : Float,
  g : Float,
  b : Float,
  a : Float,
) -> Unit {
  gpu_draw_sprite_uv(
    texture_id, x, y, rot, sx, sy, r, g, b, a, 0.0, 0.0, 1.0, 1.0,
  )
}

///|
pub fn gpu_draw_sprite_uv(
  texture_id : Int,
  x : Float,
  y : Float,
  rot : Float,
  sx : Float,
  sy : Float,
  r : Float,
  g : Float,
  b : Float,
  a : Float,
  uv_min_x : Float,
  uv_min_y : Float,
  uv_max_x : Float,
  uv_max_y : Float,
) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.gpu is Some(gpu) {
    gpu.draw_sprite_uv(
      texture_id, x, y, rot, sx, sy, r, g, b, a, uv_min_x, uv_min_y, uv_max_x, uv_max_y,
    ) catch {
      _ => ()
    }
  }
}

///|
pub fn gpu_draw_ui_rect(
  texture_id : Int,
  x : Float,
  y : Float,
  rot : Float,
  sx : Float,
  sy : Float,
  r : Float,
  g : Float,
  b : Float,
  a : Float,
  uv_min_x : Float,
  uv_min_y : Float,
  uv_max_x : Float,
  uv_max_y : Float,
  flags : Int,
  radius_tl : Float,
  radius_tr : Float,
  radius_br : Float,
  radius_bl : Float,
  border_left : Float,
  border_top : Float,
  border_right : Float,
  border_bottom : Float,
) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.gpu is Some(gpu) {
    gpu.draw_ui_rect(
      texture_id, x, y, rot, sx, sy, r, g, b, a, uv_min_x, uv_min_y, uv_max_x, uv_max_y,
      flags, radius_tl, radius_tr, radius_br, radius_bl, border_left, border_top,
      border_right, border_bottom,
    ) catch {
      _ => ()
    }
  }
}

///|
pub fn gpu_draw_ui_texture_slice(
  texture_id : Int,
  x : Float,
  y : Float,
  rot : Float,
  sx : Float,
  sy : Float,
  r : Float,
  g : Float,
  b : Float,
  a : Float,
  texture_slice_l : Float,
  texture_slice_t : Float,
  texture_slice_r : Float,
  texture_slice_b : Float,
  target_slice_l : Float,
  target_slice_t : Float,
  target_slice_r : Float,
  target_slice_b : Float,
  repeat_side_x : Float,
  repeat_side_y : Float,
  repeat_center_x : Float,
  repeat_center_y : Float,
  atlas_l : Float,
  atlas_t : Float,
  atlas_r : Float,
  atlas_b : Float,
) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.gpu is Some(gpu) {
    gpu.draw_ui_texture_slice(
      texture_id, x, y, rot, sx, sy, r, g, b, a, texture_slice_l, texture_slice_t,
      texture_slice_r, texture_slice_b, target_slice_l, target_slice_t, target_slice_r,
      target_slice_b, repeat_side_x, repeat_side_y, repeat_center_x, repeat_center_y,
      atlas_l, atlas_t, atlas_r, atlas_b,
    ) catch {
      _ => ()
    }
  }
}

///|
pub fn gpu_draw_ui_box_shadow(
  texture_id : Int,
  x : Float,
  y : Float,
  rot : Float,
  sx : Float,
  sy : Float,
  r : Float,
  g : Float,
  b : Float,
  a : Float,
  size_x : Float,
  size_y : Float,
  radius_tl : Float,
  radius_tr : Float,
  radius_br : Float,
  radius_bl : Float,
  blur : Float,
  samples : Int,
) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.gpu is Some(gpu) {
    gpu.draw_ui_box_shadow(
      texture_id, x, y, rot, sx, sy, r, g, b, a, size_x, size_y, radius_tl, radius_tr,
      radius_br, radius_bl, blur, samples,
    ) catch {
      _ => ()
    }
  }
}

///|
pub fn gpu_draw_gizmo_line(
  _start_x : Float,
  _start_y : Float,
  _start_r : Float,
  _start_g : Float,
  _start_b : Float,
  _start_a : Float,
  _end_x : Float,
  _end_y : Float,
  _end_r : Float,
  _end_g : Float,
  _end_b : Float,
  _end_a : Float,
  _line_width : Float,
  _style_kind : Int,
  _gap_scale : Float,
  _line_scale : Float,
) -> Unit {
  ()
}

///|
pub fn gpu_draw_mesh(
  mesh_id : Int,
  x : Float,
  y : Float,
  rot : Float,
  sx : Float,
  sy : Float,
  r : Float,
  g : Float,
  b : Float,
  a : Float,
  texture_id : Int,
  uv_offset_x : Float,
  uv_offset_y : Float,
  uv_scale_x : Float,
  uv_scale_y : Float,
) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.gpu is Some(gpu) {
    gpu.draw_mesh(
      mesh_id, x, y, rot, sx, sy, r, g, b, a, texture_id, uv_offset_x, uv_offset_y,
      uv_scale_x, uv_scale_y,
    ) catch {
      _ => ()
    }
  }
}

///|
pub fn gpu_draw_mesh3d(
  mesh_id : Int,
  x : Float,
  y : Float,
  z : Float,
  rotation_x : Float,
  rotation_y : Float,
  rotation_z : Float,
  rotation_w : Float,
  scale_x : Float,
  scale_y : Float,
  scale_z : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  texture_id : Int,
  uv_offset_x : Float,
  uv_offset_y : Float,
  uv_scale_x : Float,
  uv_scale_y : Float,
  normal_texture_id : Int,
  emissive_texture_id : Int,
  metallic_roughness_texture_id : Int,
  occlusion_texture_id : Int,
  emissive_r : Float,
  emissive_g : Float,
  emissive_b : Float,
  unlit : Float,
  metallic : Float,
  roughness : Float,
  reflectance : Float,
) -> Unit {
  let ctx = ensure_context() catch { _ => return }
  if ctx.gpu is Some(gpu) {
    gpu.draw_mesh3d(
      mesh_id, x, y, z, rotation_x, rotation_y, rotation_z, rotation_w, scale_x,
      scale_y, scale_z, color_r, color_g, color_b, color_a, texture_id, uv_offset_x,
      uv_offset_y, uv_scale_x, uv_scale_y, normal_texture_id, emissive_texture_id,
      metallic_roughness_texture_id, occlusion_texture_id, emissive_r, emissive_g,
      emissive_b, unlit, metallic, roughness, reflectance,
    ) catch {
      _ => ()
    }
  }
}

///|
pub fn run_after_ready(step : FuncRef[() -> Unit]) -> Unit {
  step()
}
