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
pub fn a11y_action_kind(_arg0 : Int) -> Int {
  0
}

///|
pub fn a11y_action_target(_arg0 : Int) -> Int {
  0
}

///|
pub fn a11y_action_value_code_unit(_arg0 : Int, _arg1 : Int) -> Int {
  0
}

///|
pub fn a11y_action_value_len(_arg0 : Int) -> Int {
  0
}

///|
pub fn a11y_actions_clear() -> Unit {
  ()
}

///|
pub fn a11y_actions_len() -> Int {
  0
}

///|
pub fn a11y_apply_update(_arg0 : Int) -> Unit {
  ()
}

///|
pub fn a11y_begin_update(_arg0 : Int) -> Unit {
  ()
}

///|
pub fn a11y_end_update() -> Unit {
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
  ()
}

///|
pub fn asset_copy_texture_to_texture(
  _arg0 : Int,
  _arg1 : Int,
  _arg2 : Int,
  _arg3 : Int,
) -> Unit {
  ()
}

///|
pub fn asset_create_dynamic_texture(
  _arg0 : Int,
  _arg1 : Int,
  _arg2 : Bool,
) -> Int {
  0
}

///|
pub fn asset_font_bytes_get(_arg0 : Int, _arg1 : Int) -> Int {
  0
}

///|
pub fn asset_font_bytes_get_u32(_arg0 : Int, _arg1 : Int) -> Int {
  0
}

///|
pub fn asset_font_bytes_len(_arg0 : Int) -> Int {
  0
}

///|
pub fn asset_is_texture_loaded(_arg0 : Int) -> Bool {
  false
}

///|
pub fn asset_load_folder(_arg0 : Int) -> Int {
  0
}

///|
pub fn asset_load_font(_arg0 : Int) -> Int {
  0
}

///|
pub fn asset_load_texture(_arg0 : Int, _arg1 : Bool) -> Int {
  0
}

///|
pub fn asset_load_wgsl(_arg0 : Int) -> Int {
  0
}

///|
pub fn asset_loaded_folder_handles_get(_arg0 : Int, _arg1 : Int) -> Int {
  0
}

///|
pub fn asset_loaded_folder_handles_len(_arg0 : Int) -> Int {
  0
}

///|
pub fn asset_poll_loaded_folder_event_id() -> Int {
  0
}

///|
pub fn asset_poll_loaded_folder_event_kind() -> Int {
  0
}

///|
pub fn asset_set_texture_sampler(_arg0 : Int, _arg1 : Int) -> Unit {
  ()
}

///|
pub fn asset_texture_height(_arg0 : Int) -> Int {
  0
}

///|
pub fn asset_texture_width(_arg0 : Int) -> Int {
  0
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
  ()
}

///|
pub fn bytes_drop(_arg0 : Int) -> Unit {
  ()
}

///|
pub fn bytes_sink_push(_arg0 : Int) -> Unit {
  ()
}

///|
pub fn bytes_sink_push_u32(_arg0 : Int) -> Unit {
  ()
}

///|
pub fn bytes_sink_reset() -> Unit {
  ()
}

///|
pub fn bytes_sink_take() -> Int {
  0
}

///|
pub fn debug_string(_arg0 : Int) -> Unit {
  ()
}

///|
pub fn font_glyph_height(_arg0 : Int) -> Int {
  0
}

///|
pub fn font_glyph_offset_x(_arg0 : Int) -> Int {
  0
}

///|
pub fn font_glyph_offset_y(_arg0 : Int) -> Int {
  0
}

///|
pub fn font_glyph_width(_arg0 : Int) -> Int {
  0
}

///|
pub fn font_measure_advance(_arg0 : Int, _arg1 : Float, _arg2 : Int) -> Float {
  0.0
}

///|
pub fn font_rasterize_glyph(
  _arg0 : Int,
  _arg1 : Float,
  _arg2 : Int,
  _arg3 : Int,
) -> Int {
  0
}

///|
pub fn gpu_begin_frame(_arg0 : Int) -> Int {
  0
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
  ()
}

///|
pub fn gpu_clear_scissor() -> Unit {
  ()
}

///|
pub fn gpu_configure_surface(
  _arg0 : Int,
  _arg1 : Int,
  _arg2 : Int,
  _arg3 : Int,
) -> Unit {
  ()
}

///|
pub fn gpu_create_mesh_capsule(
  _arg0 : Float,
  _arg1 : Float,
  _arg2 : Int,
) -> Int {
  0
}

///|
pub fn gpu_create_mesh_rectangle(_arg0 : Float, _arg1 : Float) -> Int {
  0
}

///|
pub fn gpu_create_mesh_triangles(_arg0 : Int) -> Int {
  0
}

///|
pub fn gpu_create_mesh_triangles3d(_arg0 : Int) -> Int {
  0
}

///|
pub fn gpu_create_render_target(_arg0 : Int, _arg1 : Int, _arg2 : Bool) -> Int {
  0
}

///|
pub fn gpu_create_surface(_arg0 : Int) -> Int {
  0
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
  ()
}

///|
pub fn gpu_end_frame(_arg0 : Int) -> Unit {
  ()
}

///|
pub fn gpu_end_pass() -> Unit {
  ()
}

///|
pub fn gpu_get_queue(_arg0 : Int) -> Int {
  0
}

///|
pub fn gpu_request_device() -> Int {
  0
}

///|
pub fn gpu_set_scissor(
  _arg0 : Int,
  _arg1 : Int,
  _arg2 : Int,
  _arg3 : Int,
) -> Unit {
  ()
}

///|
pub fn input_finish_frame() -> Unit {
  ()
}

///|
pub fn input_has_cursor() -> Bool {
  false
}

///|
pub fn input_is_key_down(_arg0 : Int) -> Bool {
  false
}

///|
pub fn input_is_key_just_pressed(_arg0 : Int) -> Bool {
  false
}

///|
pub fn input_is_key_just_released(_arg0 : Int) -> Bool {
  false
}

///|
pub fn input_is_mouse_button_down(_arg0 : Int) -> Bool {
  false
}

///|
pub fn input_is_mouse_button_just_pressed(_arg0 : Int) -> Bool {
  false
}

///|
pub fn input_is_mouse_button_just_released(_arg0 : Int) -> Bool {
  false
}

///|
pub fn input_mouse_x() -> Float {
  0.0
}

///|
pub fn input_mouse_y() -> Float {
  0.0
}

///|
pub fn input_wheel_x() -> Float {
  0.0
}

///|
pub fn input_wheel_y() -> Float {
  0.0
}

///|
pub fn string_drop(_arg0 : Int) -> Unit {
  ()
}

///|
pub fn string_sink_push(_arg0 : Int) -> Unit {
  ()
}

///|
pub fn string_sink_reset() -> Unit {
  ()
}

///|
pub fn string_sink_take() -> Int {
  0
}

///|
pub fn time_now() -> Float {
  0.0
}

///|
pub fn window_create(_arg0 : Int, _arg1 : Int, _arg2 : Int) -> Int {
  0
}

///|
pub fn window_get_height(_arg0 : Int) -> Int {
  0
}

///|
pub fn window_get_scale_factor(_arg0 : Int) -> Float {
  0.0
}

///|
pub fn window_get_width(_arg0 : Int) -> Int {
  0
}

///|
pub fn window_poll_events(_arg0 : Int) -> Unit {
  ()
}

///|
pub fn window_request_close(_arg0 : Int) -> Unit {
  ()
}

///|
pub fn window_run_loop(_arg0 : FuncRef[() -> Unit]) -> Unit {
  ()
}

///|
pub fn window_should_close(_arg0 : Int) -> Bool {
  false
}

///|
pub fn run_after_ready(step : FuncRef[() -> Unit]) -> Unit {
  step()
}
