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
priv struct WebHostContext {
  host : @js.Any
  init_fn : @js.Any
  mut init_started : Bool
  mut ready : Bool
  pending_steps : Ref[Array[FuncRef[() -> Unit]]]
}

///|
let web_host_context : Ref[WebHostContext?] = Ref::new(None)

///|
extern "js" fn get_global_config() -> @js.Any =
  #| () => globalThis.__MGSTUDIO_CONFIG || {}

///|
extern "js" fn get_object_string(obj : @js.Any, key : String) -> String =
  #| (obj, key) => {
  #|   if (!obj || typeof obj !== "object") return ""
  #|   const value = obj[key]
  #|   return typeof value === "string" ? value : ""
  #| }

///|
extern "js" fn call0_any(func : @js.Any) -> @js.Any =
  #| (func) => func()

///|
extern "js" fn is_function(value : @js.Any) -> Bool =
  #| (value) => typeof value === "function"

///|
extern "js" fn call_host_method(
  host : @js.Any,
  name : String,
  args : Array[@js.Any],
) -> @js.Any =
  #| (host, name, args) => {
  #|   const fn = host && host[name]
  #|   if (typeof fn !== "function") {
  #|     throw new Error(`mgstudio platform web host method missing: ${name}`)
  #|   }
  #|   return fn(...args)
  #| }

///|
extern "js" fn promise_then(promise : @js.Any, callback : @js.Any) -> Unit =
  #| (promise, callback) => { Promise.resolve(promise).then(() => callback()) }

///|
extern "js" fn promise_catch(promise : @js.Any, callback : @js.Any) -> Unit =
  #| (promise, callback) => { Promise.resolve(promise).catch((err) => callback(err)) }

///|
extern "js" fn console_error_text(text : String) -> Unit =
  #| (text) => { console.error(text) }

///|
extern "js" fn js_null() -> @js.Any =
  #| () => null

///|
fn config_string_compat(
  config : @js.Any,
  key : String,
  legacy_key : String,
  fallback : String,
) -> String {
  let value = get_object_string(config, key)
  if value != "" {
    return value
  }
  let legacy = get_object_string(config, legacy_key)
  if legacy == "" {
    fallback
  } else {
    legacy
  }
}

///|
fn web_canvas(config : @js.Any) -> @dom.Element? {
  let canvas_id = config_string_compat(config, "canvas_id", "canvasId", "")
  if canvas_id == "" {
    None
  } else {
    @dom.document().getElementById(canvas_id)
  }
}

///|
fn ensure_web_host_context() -> WebHostContext {
  if web_host_context.val is Some(context) {
    return context
  }
  let config = get_global_config()
  let assets_source = config_string_compat(
    config, "assets_source", "assetsSource", "./_mgstudio_assets/",
  )
  let data_source = config_string_compat(
    config, "data_source", "dataSource", "idb:mgstudio",
  )
  let host_bundle = @host.create_host(
    web_canvas(config),
    assets_source,
    data_source,
  )
  let context = WebHostContext::{
    host: host_bundle._get("mgstudio_host"),
    init_fn: host_bundle._get("init"),
    init_started: false,
    ready: false,
    pending_steps: Ref::new([]),
  }
  web_host_context.val = Some(context)
  context
}

///|
fn flush_pending_steps(context : WebHostContext) -> Unit {
  let pending = context.pending_steps.val
  let total = pending.length()
  for i in 0..<total {
    pending[i]()
  }
  pending.clear()
}

///|
pub fn run_after_ready(step : FuncRef[() -> Unit]) -> Unit {
  let context = ensure_web_host_context()
  if context.ready {
    step()
    return
  }
  context.pending_steps.val.push(step)
  if context.init_started {
    return
  }
  context.init_started = true
  if !is_function(context.init_fn) {
    context.ready = true
    flush_pending_steps(context)
    return
  }
  let init_promise = call0_any(context.init_fn)
  promise_then(
    init_promise,
    @js.from_fn0(fn() {
      let context = ensure_web_host_context()
      context.ready = true
      flush_pending_steps(context)
    }),
  )
  promise_catch(
    init_promise,
    @js.from_fn1(fn(err) {
      console_error_text(
        "platform_web init failed: " + @host.any_to_string_export(err),
      )
      let context = ensure_web_host_context()
      context.ready = true
      flush_pending_steps(context)
      js_null()
    }),
  )
}

///|
fn call_host(name : String, args : Array[@js.Any]) -> @js.Any {
  let context = ensure_web_host_context()
  call_host_method(context.host, name, args)
}

///|
fn call_unit(name : String, args : Array[@js.Any]) -> Unit {
  call_host(name, args) |> ignore
}

///|
fn call_int(name : String, args : Array[@js.Any]) -> Int {
  call_host(name, args).cast()
}

///|
fn call_float(name : String, args : Array[@js.Any]) -> Float {
  call_host(name, args).cast()
}

///|
fn call_bool(name : String, args : Array[@js.Any]) -> Bool {
  call_host(name, args).cast()
}

///|
pub fn a11y_action_kind(_arg0 : Int) -> Int {
  call_int("a11y_action_kind", [@js.any(_arg0)])
}

///|
pub fn a11y_action_target(_arg0 : Int) -> Int {
  call_int("a11y_action_target", [@js.any(_arg0)])
}

///|
pub fn a11y_action_value_code_unit(_arg0 : Int, _arg1 : Int) -> Int {
  call_int("a11y_action_value_code_unit", [@js.any(_arg0), @js.any(_arg1)])
}

///|
pub fn a11y_action_value_len(_arg0 : Int) -> Int {
  call_int("a11y_action_value_len", [@js.any(_arg0)])
}

///|
pub fn a11y_actions_clear() -> Unit {
  call_unit("a11y_actions_clear", [])
  ()
}

///|
pub fn a11y_actions_len() -> Int {
  call_int("a11y_actions_len", [])
}

///|
pub fn a11y_apply_update(_arg0 : Int) -> Unit {
  call_unit("a11y_apply_update", [@js.any(_arg0)])
  ()
}

///|
pub fn a11y_begin_update(_arg0 : Int) -> Unit {
  call_unit("a11y_begin_update", [@js.any(_arg0)])
  ()
}

///|
pub fn a11y_end_update() -> Unit {
  call_unit("a11y_end_update", [])
  ()
}

///|
pub fn a11y_push_node(
  _arg0 : Int,
  _arg1 : Int,
  _arg2 : Int,
  _arg3 : Float,
  _arg4 : Float,
  _arg5 : Float,
  _arg6 : Float,
  _arg7 : Int,
  _arg8 : Int,
) -> Unit {
  call_unit("a11y_push_node", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
    @js.any(_arg3),
    @js.any(_arg4),
    @js.any(_arg5),
    @js.any(_arg6),
    @js.any(_arg7),
    @js.any(_arg8),
  ])
  ()
}

///|
pub fn asset_copy_texture_to_texture(
  _arg0 : Int,
  _arg1 : Int,
  _arg2 : Int,
  _arg3 : Int,
) -> Unit {
  call_unit("asset_copy_texture_to_texture", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
    @js.any(_arg3),
  ])
  ()
}

///|
pub fn asset_create_dynamic_texture(
  _arg0 : Int,
  _arg1 : Int,
  _arg2 : Bool,
) -> Int {
  call_int("asset_create_dynamic_texture", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
  ])
}

///|
pub fn asset_font_bytes_get(_arg0 : Int, _arg1 : Int) -> Int {
  call_int("asset_font_bytes_get", [@js.any(_arg0), @js.any(_arg1)])
}

///|
pub fn asset_font_bytes_get_u32(_arg0 : Int, _arg1 : Int) -> Int {
  call_int("asset_font_bytes_get_u32", [@js.any(_arg0), @js.any(_arg1)])
}

///|
pub fn asset_font_bytes_len(_arg0 : Int) -> Int {
  call_int("asset_font_bytes_len", [@js.any(_arg0)])
}

///|
pub fn asset_is_texture_loaded(_arg0 : Int) -> Bool {
  call_bool("asset_is_texture_loaded", [@js.any(_arg0)])
}

///|
pub fn asset_load_folder(_arg0 : Int) -> Int {
  call_int("asset_load_folder", [@js.any(_arg0)])
}

///|
pub fn asset_load_font(_arg0 : Int) -> Int {
  call_int("asset_load_font", [@js.any(_arg0)])
}

///|
pub fn asset_load_texture(_arg0 : Int, _arg1 : Bool) -> Int {
  call_int("asset_load_texture", [@js.any(_arg0), @js.any(_arg1)])
}

///|
pub fn asset_load_wgsl(_arg0 : Int) -> Int {
  call_int("asset_load_wgsl", [@js.any(_arg0)])
}

///|
pub fn asset_loaded_folder_handles_get(_arg0 : Int, _arg1 : Int) -> Int {
  call_int("asset_loaded_folder_handles_get", [@js.any(_arg0), @js.any(_arg1)])
}

///|
pub fn asset_loaded_folder_handles_len(_arg0 : Int) -> Int {
  call_int("asset_loaded_folder_handles_len", [@js.any(_arg0)])
}

///|
pub fn asset_poll_loaded_folder_event_id() -> Int {
  call_int("asset_poll_loaded_folder_event_id", [])
}

///|
pub fn asset_poll_loaded_folder_event_kind() -> Int {
  call_int("asset_poll_loaded_folder_event_kind", [])
}

///|
pub fn asset_set_texture_sampler(_arg0 : Int, _arg1 : Int) -> Unit {
  call_unit("asset_set_texture_sampler", [@js.any(_arg0), @js.any(_arg1)])
  ()
}

///|
pub fn asset_texture_height(_arg0 : Int) -> Int {
  call_int("asset_texture_height", [@js.any(_arg0)])
}

///|
pub fn asset_texture_width(_arg0 : Int) -> Int {
  call_int("asset_texture_width", [@js.any(_arg0)])
}

///|
pub fn asset_update_texture_region(
  _arg0 : Int,
  _arg1 : Int,
  _arg2 : Int,
  _arg3 : Int,
  _arg4 : Int,
  _arg5 : Int,
) -> Unit {
  call_unit("asset_update_texture_region", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
    @js.any(_arg3),
    @js.any(_arg4),
    @js.any(_arg5),
  ])
  ()
}

///|
pub fn asset_update_texture_region_bytes(
  _arg0 : Int,
  _arg1 : Int,
  _arg2 : Int,
  _arg3 : Int,
  _arg4 : Int,
  _arg5 : Int,
) -> Unit {
  call_unit("asset_update_texture_region_bytes", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
    @js.any(_arg3),
    @js.any(_arg4),
    @js.any(_arg5),
  ])
  ()
}

///|
pub fn bytes_drop(_arg0 : Int) -> Unit {
  call_unit("bytes_drop", [@js.any(_arg0)])
  ()
}

///|
pub fn bytes_sink_push(_arg0 : Int) -> Unit {
  call_unit("bytes_sink_push", [@js.any(_arg0)])
  ()
}

///|
pub fn bytes_sink_push_u32(_arg0 : Int) -> Unit {
  call_unit("bytes_sink_push_u32", [@js.any(_arg0)])
  ()
}

///|
pub fn bytes_sink_reset() -> Unit {
  call_unit("bytes_sink_reset", [])
  ()
}

///|
pub fn bytes_sink_take() -> Int {
  call_int("bytes_sink_take", [])
}

///|
pub fn debug_string(_arg0 : Int) -> Unit {
  call_unit("debug_string", [@js.any(_arg0)])
  ()
}

///|
pub fn font_glyph_height(_arg0 : Int) -> Int {
  call_int("font_glyph_height", [@js.any(_arg0)])
}

///|
pub fn font_glyph_offset_x(_arg0 : Int) -> Int {
  call_int("font_glyph_offset_x", [@js.any(_arg0)])
}

///|
pub fn font_glyph_offset_y(_arg0 : Int) -> Int {
  call_int("font_glyph_offset_y", [@js.any(_arg0)])
}

///|
pub fn font_glyph_width(_arg0 : Int) -> Int {
  call_int("font_glyph_width", [@js.any(_arg0)])
}

///|
pub fn font_measure_advance(_arg0 : Int, _arg1 : Float, _arg2 : Int) -> Float {
  call_float("font_measure_advance", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
  ])
}

///|
pub fn font_rasterize_glyph(
  _arg0 : Int,
  _arg1 : Float,
  _arg2 : Int,
  _arg3 : Int,
) -> Int {
  call_int("font_rasterize_glyph", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
    @js.any(_arg3),
  ])
}

///|
pub fn gpu_begin_frame(_arg0 : Int) -> Int {
  call_int("gpu_begin_frame", [@js.any(_arg0)])
}

///|
pub fn gpu_begin_pass(
  _arg0 : Int,
  _arg1 : Int,
  _arg2 : Int,
  _arg3 : Float,
  _arg4 : Float,
  _arg5 : Float,
  _arg6 : Float,
  _arg7 : Float,
  _arg8 : Float,
  _arg9 : Float,
  _arg10 : Float,
  _arg11 : Int,
  _arg12 : Int,
  _arg13 : Int,
  _arg14 : Int,
) -> Unit {
  call_unit("gpu_begin_pass", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
    @js.any(_arg3),
    @js.any(_arg4),
    @js.any(_arg5),
    @js.any(_arg6),
    @js.any(_arg7),
    @js.any(_arg8),
    @js.any(_arg9),
    @js.any(_arg10),
    @js.any(_arg11),
    @js.any(_arg12),
    @js.any(_arg13),
    @js.any(_arg14),
  ])
  ()
}

///|
pub fn gpu_begin_pass_3d(
  _arg0 : Int,
  _arg1 : Int,
  _arg2 : Int,
  _arg3 : Float,
  _arg4 : Float,
  _arg5 : Float,
  _arg6 : Float,
  _arg7 : Float,
  _arg8 : Float,
  _arg9 : Float,
  _arg10 : Float,
  _arg11 : Float,
  _arg12 : Float,
  _arg13 : Float,
  _arg14 : Float,
  _arg15 : Float,
  _arg16 : Float,
  _arg17 : Int,
  _arg18 : Int,
  _arg19 : Int,
  _arg20 : Int,
  _arg21 : Float,
  _arg22 : Float,
  _arg23 : Float,
  _arg24 : Float,
  _arg25 : Float,
  _arg26 : Float,
  _arg27 : Float,
  _arg28 : Float,
  _arg29 : Float,
  _arg30 : Float,
  _arg31 : Float,
  _arg32 : Float,
  _arg33 : Float,
  _arg34 : Float,
  _arg35 : Float,
  _arg36 : Float,
  _arg37 : Float,
  _arg38 : Float,
  _arg39 : Float,
  _arg40 : Float,
  _arg41 : Float,
  _arg42 : Float,
  _arg43 : Float,
  _arg44 : Float,
  _arg45 : Float,
  _arg46 : Float,
  _arg47 : Float,
  _arg48 : Float,
  _arg49 : Float,
  _arg50 : Float,
  _arg51 : Float,
  _arg52 : Float,
) -> Unit {
  call_unit("gpu_begin_pass_3d", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
    @js.any(_arg3),
    @js.any(_arg4),
    @js.any(_arg5),
    @js.any(_arg6),
    @js.any(_arg7),
    @js.any(_arg8),
    @js.any(_arg9),
    @js.any(_arg10),
    @js.any(_arg11),
    @js.any(_arg12),
    @js.any(_arg13),
    @js.any(_arg14),
    @js.any(_arg15),
    @js.any(_arg16),
    @js.any(_arg17),
    @js.any(_arg18),
    @js.any(_arg19),
    @js.any(_arg20),
    @js.any(_arg21),
    @js.any(_arg22),
    @js.any(_arg23),
    @js.any(_arg24),
    @js.any(_arg25),
    @js.any(_arg26),
    @js.any(_arg27),
    @js.any(_arg28),
    @js.any(_arg29),
    @js.any(_arg30),
    @js.any(_arg31),
    @js.any(_arg32),
    @js.any(_arg33),
    @js.any(_arg34),
    @js.any(_arg35),
    @js.any(_arg36),
    @js.any(_arg37),
    @js.any(_arg38),
    @js.any(_arg39),
    @js.any(_arg40),
    @js.any(_arg41),
    @js.any(_arg42),
    @js.any(_arg43),
    @js.any(_arg44),
    @js.any(_arg45),
    @js.any(_arg46),
    @js.any(_arg47),
    @js.any(_arg48),
    @js.any(_arg49),
    @js.any(_arg50),
    @js.any(_arg51),
    @js.any(_arg52),
  ])
  ()
}

///|
pub fn gpu_clear_scissor() -> Unit {
  call_unit("gpu_clear_scissor", [])
  ()
}

///|
pub fn gpu_configure_surface(
  _arg0 : Int,
  _arg1 : Int,
  _arg2 : Int,
  _arg3 : Int,
) -> Unit {
  call_unit("gpu_configure_surface", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
    @js.any(_arg3),
  ])
  ()
}

///|
pub fn gpu_create_mesh_capsule(
  _arg0 : Float,
  _arg1 : Float,
  _arg2 : Int,
) -> Int {
  call_int("gpu_create_mesh_capsule", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
  ])
}

///|
pub fn gpu_create_mesh_rectangle(_arg0 : Float, _arg1 : Float) -> Int {
  call_int("gpu_create_mesh_rectangle", [@js.any(_arg0), @js.any(_arg1)])
}

///|
pub fn gpu_create_mesh_triangles(_arg0 : Int) -> Int {
  call_int("gpu_create_mesh_triangles", [@js.any(_arg0)])
}

///|
pub fn gpu_create_mesh_triangles3d(_arg0 : Int) -> Int {
  call_int("gpu_create_mesh_triangles3d", [@js.any(_arg0)])
}

///|
pub fn gpu_create_render_target(_arg0 : Int, _arg1 : Int, _arg2 : Bool) -> Int {
  call_int("gpu_create_render_target", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
  ])
}

///|
pub fn gpu_create_surface(_arg0 : Int) -> Int {
  call_int("gpu_create_surface", [@js.any(_arg0)])
}

///|
pub fn gpu_draw_gizmo_line(
  _arg0 : Float,
  _arg1 : Float,
  _arg2 : Float,
  _arg3 : Float,
  _arg4 : Float,
  _arg5 : Float,
  _arg6 : Float,
  _arg7 : Float,
  _arg8 : Float,
  _arg9 : Float,
  _arg10 : Float,
  _arg11 : Float,
  _arg12 : Float,
  _arg13 : Int,
  _arg14 : Float,
  _arg15 : Float,
) -> Unit {
  call_unit("gpu_draw_gizmo_line", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
    @js.any(_arg3),
    @js.any(_arg4),
    @js.any(_arg5),
    @js.any(_arg6),
    @js.any(_arg7),
    @js.any(_arg8),
    @js.any(_arg9),
    @js.any(_arg10),
    @js.any(_arg11),
    @js.any(_arg12),
    @js.any(_arg13),
    @js.any(_arg14),
    @js.any(_arg15),
  ])
  ()
}

///|
pub fn gpu_draw_mesh(
  _arg0 : Int,
  _arg1 : Float,
  _arg2 : Float,
  _arg3 : Float,
  _arg4 : Float,
  _arg5 : Float,
  _arg6 : Float,
  _arg7 : Float,
  _arg8 : Float,
  _arg9 : Float,
  _arg10 : Int,
  _arg11 : Float,
  _arg12 : Float,
  _arg13 : Float,
  _arg14 : Float,
) -> Unit {
  call_unit("gpu_draw_mesh", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
    @js.any(_arg3),
    @js.any(_arg4),
    @js.any(_arg5),
    @js.any(_arg6),
    @js.any(_arg7),
    @js.any(_arg8),
    @js.any(_arg9),
    @js.any(_arg10),
    @js.any(_arg11),
    @js.any(_arg12),
    @js.any(_arg13),
    @js.any(_arg14),
  ])
  ()
}

///|
pub fn gpu_draw_mesh3d(
  _arg0 : Int,
  _arg1 : Float,
  _arg2 : Float,
  _arg3 : Float,
  _arg4 : Float,
  _arg5 : Float,
  _arg6 : Float,
  _arg7 : Float,
  _arg8 : Float,
  _arg9 : Float,
  _arg10 : Float,
  _arg11 : Float,
  _arg12 : Float,
  _arg13 : Float,
  _arg14 : Float,
  _arg15 : Int,
  _arg16 : Float,
  _arg17 : Float,
  _arg18 : Float,
  _arg19 : Float,
  _arg20 : Int,
  _arg21 : Int,
  _arg22 : Int,
  _arg23 : Int,
  _arg24 : Float,
  _arg25 : Float,
  _arg26 : Float,
  _arg27 : Float,
  _arg28 : Float,
  _arg29 : Float,
  _arg30 : Float,
) -> Unit {
  call_unit("gpu_draw_mesh3d", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
    @js.any(_arg3),
    @js.any(_arg4),
    @js.any(_arg5),
    @js.any(_arg6),
    @js.any(_arg7),
    @js.any(_arg8),
    @js.any(_arg9),
    @js.any(_arg10),
    @js.any(_arg11),
    @js.any(_arg12),
    @js.any(_arg13),
    @js.any(_arg14),
    @js.any(_arg15),
    @js.any(_arg16),
    @js.any(_arg17),
    @js.any(_arg18),
    @js.any(_arg19),
    @js.any(_arg20),
    @js.any(_arg21),
    @js.any(_arg22),
    @js.any(_arg23),
    @js.any(_arg24),
    @js.any(_arg25),
    @js.any(_arg26),
    @js.any(_arg27),
    @js.any(_arg28),
    @js.any(_arg29),
    @js.any(_arg30),
  ])
  ()
}

///|
pub fn gpu_draw_sprite(
  _arg0 : Int,
  _arg1 : Float,
  _arg2 : Float,
  _arg3 : Float,
  _arg4 : Float,
  _arg5 : Float,
  _arg6 : Float,
  _arg7 : Float,
  _arg8 : Float,
  _arg9 : Float,
) -> Unit {
  call_unit("gpu_draw_sprite", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
    @js.any(_arg3),
    @js.any(_arg4),
    @js.any(_arg5),
    @js.any(_arg6),
    @js.any(_arg7),
    @js.any(_arg8),
    @js.any(_arg9),
  ])
  ()
}

///|
pub fn gpu_draw_sprite_uv(
  _arg0 : Int,
  _arg1 : Float,
  _arg2 : Float,
  _arg3 : Float,
  _arg4 : Float,
  _arg5 : Float,
  _arg6 : Float,
  _arg7 : Float,
  _arg8 : Float,
  _arg9 : Float,
  _arg10 : Float,
  _arg11 : Float,
  _arg12 : Float,
  _arg13 : Float,
) -> Unit {
  call_unit("gpu_draw_sprite_uv", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
    @js.any(_arg3),
    @js.any(_arg4),
    @js.any(_arg5),
    @js.any(_arg6),
    @js.any(_arg7),
    @js.any(_arg8),
    @js.any(_arg9),
    @js.any(_arg10),
    @js.any(_arg11),
    @js.any(_arg12),
    @js.any(_arg13),
  ])
  ()
}

///|
pub fn gpu_draw_ui_box_shadow(
  _arg0 : Int,
  _arg1 : Float,
  _arg2 : Float,
  _arg3 : Float,
  _arg4 : Float,
  _arg5 : Float,
  _arg6 : Float,
  _arg7 : Float,
  _arg8 : Float,
  _arg9 : Float,
  _arg10 : Float,
  _arg11 : Float,
  _arg12 : Float,
  _arg13 : Float,
  _arg14 : Float,
  _arg15 : Float,
  _arg16 : Float,
  _arg17 : Int,
) -> Unit {
  call_unit("gpu_draw_ui_box_shadow", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
    @js.any(_arg3),
    @js.any(_arg4),
    @js.any(_arg5),
    @js.any(_arg6),
    @js.any(_arg7),
    @js.any(_arg8),
    @js.any(_arg9),
    @js.any(_arg10),
    @js.any(_arg11),
    @js.any(_arg12),
    @js.any(_arg13),
    @js.any(_arg14),
    @js.any(_arg15),
    @js.any(_arg16),
    @js.any(_arg17),
  ])
  ()
}

///|
pub fn gpu_draw_ui_rect(
  _arg0 : Int,
  _arg1 : Float,
  _arg2 : Float,
  _arg3 : Float,
  _arg4 : Float,
  _arg5 : Float,
  _arg6 : Float,
  _arg7 : Float,
  _arg8 : Float,
  _arg9 : Float,
  _arg10 : Float,
  _arg11 : Float,
  _arg12 : Float,
  _arg13 : Float,
  _arg14 : Int,
  _arg15 : Float,
  _arg16 : Float,
  _arg17 : Float,
  _arg18 : Float,
  _arg19 : Float,
  _arg20 : Float,
  _arg21 : Float,
  _arg22 : Float,
) -> Unit {
  call_unit("gpu_draw_ui_rect", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
    @js.any(_arg3),
    @js.any(_arg4),
    @js.any(_arg5),
    @js.any(_arg6),
    @js.any(_arg7),
    @js.any(_arg8),
    @js.any(_arg9),
    @js.any(_arg10),
    @js.any(_arg11),
    @js.any(_arg12),
    @js.any(_arg13),
    @js.any(_arg14),
    @js.any(_arg15),
    @js.any(_arg16),
    @js.any(_arg17),
    @js.any(_arg18),
    @js.any(_arg19),
    @js.any(_arg20),
    @js.any(_arg21),
    @js.any(_arg22),
  ])
  ()
}

///|
pub fn gpu_draw_ui_texture_slice(
  _arg0 : Int,
  _arg1 : Float,
  _arg2 : Float,
  _arg3 : Float,
  _arg4 : Float,
  _arg5 : Float,
  _arg6 : Float,
  _arg7 : Float,
  _arg8 : Float,
  _arg9 : Float,
  _arg10 : Float,
  _arg11 : Float,
  _arg12 : Float,
  _arg13 : Float,
  _arg14 : Float,
  _arg15 : Float,
  _arg16 : Float,
  _arg17 : Float,
  _arg18 : Float,
  _arg19 : Float,
  _arg20 : Float,
  _arg21 : Float,
  _arg22 : Float,
  _arg23 : Float,
  _arg24 : Float,
  _arg25 : Float,
) -> Unit {
  call_unit("gpu_draw_ui_texture_slice", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
    @js.any(_arg3),
    @js.any(_arg4),
    @js.any(_arg5),
    @js.any(_arg6),
    @js.any(_arg7),
    @js.any(_arg8),
    @js.any(_arg9),
    @js.any(_arg10),
    @js.any(_arg11),
    @js.any(_arg12),
    @js.any(_arg13),
    @js.any(_arg14),
    @js.any(_arg15),
    @js.any(_arg16),
    @js.any(_arg17),
    @js.any(_arg18),
    @js.any(_arg19),
    @js.any(_arg20),
    @js.any(_arg21),
    @js.any(_arg22),
    @js.any(_arg23),
    @js.any(_arg24),
    @js.any(_arg25),
  ])
  ()
}

///|
pub fn gpu_end_frame(_arg0 : Int) -> Unit {
  call_unit("gpu_end_frame", [@js.any(_arg0)])
  ()
}

///|
pub fn gpu_end_pass() -> Unit {
  call_unit("gpu_end_pass", [])
  ()
}

///|
pub fn gpu_get_queue(_arg0 : Int) -> Int {
  call_int("gpu_get_queue", [@js.any(_arg0)])
}

///|
pub fn gpu_request_device() -> Int {
  call_int("gpu_request_device", [])
}

///|
pub fn gpu_set_scissor(
  _arg0 : Int,
  _arg1 : Int,
  _arg2 : Int,
  _arg3 : Int,
) -> Unit {
  call_unit("gpu_set_scissor", [
    @js.any(_arg0),
    @js.any(_arg1),
    @js.any(_arg2),
    @js.any(_arg3),
  ])
  ()
}

///|
pub fn input_finish_frame() -> Unit {
  call_unit("input_finish_frame", [])
  ()
}

///|
pub fn input_has_cursor() -> Bool {
  call_bool("input_has_cursor", [])
}

///|
pub fn input_is_key_down(_arg0 : Int) -> Bool {
  call_bool("input_is_key_down", [@js.any(_arg0)])
}

///|
pub fn input_is_key_just_pressed(_arg0 : Int) -> Bool {
  call_bool("input_is_key_just_pressed", [@js.any(_arg0)])
}

///|
pub fn input_is_key_just_released(_arg0 : Int) -> Bool {
  call_bool("input_is_key_just_released", [@js.any(_arg0)])
}

///|
pub fn input_is_mouse_button_down(_arg0 : Int) -> Bool {
  call_bool("input_is_mouse_button_down", [@js.any(_arg0)])
}

///|
pub fn input_is_mouse_button_just_pressed(_arg0 : Int) -> Bool {
  call_bool("input_is_mouse_button_just_pressed", [@js.any(_arg0)])
}

///|
pub fn input_is_mouse_button_just_released(_arg0 : Int) -> Bool {
  call_bool("input_is_mouse_button_just_released", [@js.any(_arg0)])
}

///|
pub fn input_mouse_x() -> Float {
  call_float("input_mouse_x", [])
}

///|
pub fn input_mouse_y() -> Float {
  call_float("input_mouse_y", [])
}

///|
pub fn input_wheel_x() -> Float {
  call_float("input_wheel_x", [])
}

///|
pub fn input_wheel_y() -> Float {
  call_float("input_wheel_y", [])
}

///|
pub fn string_drop(_arg0 : Int) -> Unit {
  call_unit("string_drop", [@js.any(_arg0)])
  ()
}

///|
pub fn string_sink_push(_arg0 : Int) -> Unit {
  call_unit("string_sink_push", [@js.any(_arg0)])
  ()
}

///|
pub fn string_sink_reset() -> Unit {
  call_unit("string_sink_reset", [])
  ()
}

///|
pub fn string_sink_take() -> Int {
  call_int("string_sink_take", [])
}

///|
pub fn time_now() -> Float {
  call_float("time_now", [])
}

///|
pub fn window_create(_arg0 : Int, _arg1 : Int, _arg2 : Int) -> Int {
  call_int("window_create", [@js.any(_arg0), @js.any(_arg1), @js.any(_arg2)])
}

///|
pub fn window_get_height(_arg0 : Int) -> Int {
  call_int("window_get_height", [@js.any(_arg0)])
}

///|
pub fn window_get_scale_factor(_arg0 : Int) -> Float {
  call_float("window_get_scale_factor", [@js.any(_arg0)])
}

///|
pub fn window_get_width(_arg0 : Int) -> Int {
  call_int("window_get_width", [@js.any(_arg0)])
}

///|
pub fn window_poll_events(_arg0 : Int) -> Unit {
  call_unit("window_poll_events", [@js.any(_arg0)])
  ()
}

///|
pub fn window_request_close(_arg0 : Int) -> Unit {
  call_unit("window_request_close", [@js.any(_arg0)])
  ()
}

///|
pub fn window_run_loop(_arg0 : FuncRef[() -> Unit]) -> Unit {
  call_unit("window_run_loop", [@js.from_fn0(fn() { _arg0() })])
  ()
}

///|
pub fn window_should_close(_arg0 : Int) -> Bool {
  call_bool("window_should_close", [@js.any(_arg0)])
}
