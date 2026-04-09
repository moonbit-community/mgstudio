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
pub fn GpuBackend::set_scissor(
  self : GpuBackend,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  flush_mesh2d_batches(self)
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  let sx = if x < 0 { 0U } else { x.reinterpret_as_uint() }
  let sy = if y < 0 { 0U } else { y.reinterpret_as_uint() }
  let sw = if width < 0 { 0U } else { width.reinterpret_as_uint() }
  let sh = if height < 0 { 0U } else { height.reinterpret_as_uint() }
  let target_id = match self.pass_state {
    Some(ps) => ps.target_id
    None => -1
  }
  let (clamped_x, clamped_y, clamped_w, clamped_h) = clamp_scissor_to_target(
    self, target_id, sx, sy, sw, sh,
  )
  pass.set_scissor_rect(clamped_x, clamped_y, clamped_w, clamped_h)
}

///|
pub fn GpuBackend::clear_scissor(
  self : GpuBackend,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  guard self.pass_state is Some(pass_state) else { return }
  flush_mesh2d_batches(self)
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  let (sx, sy, sw, sh) = clamp_scissor_to_target(
    self,
    pass_state.target_id,
    pass_state.viewport_x,
    pass_state.viewport_y,
    pass_state.viewport_w,
    pass_state.viewport_h,
  )
  pass.set_scissor_rect(sx, sy, sw, sh)
}

///|
pub fn GpuBackend::end_pass(self : GpuBackend) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  if frame.pass is Some(pass) {
    flush_mesh2d_batches(self)
    flush_ui_shadow_batches(self)
    flush_ui_slice_batches(self)
    flush_ui_batches(self)
    flush_sprite_batches(self)
    render_pass_timing_end_active_pass()
    pass.end()
    pass.release()
    frame.pass = None
  }
  self.pass_state = None
  self.pass_has_depth = false
}

///|
pub fn set_scissor(x~ : Int, y~ : Int, width~ : Int, height~ : Int) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.set_scissor(x, y, width, height) catch {
      _ => ()
    }
  }
}

///|
pub fn clear_scissor() -> Unit {
  if ensure_backend() is Some(backend) {
    backend.clear_scissor() catch {
      _ => ()
    }
  }
}

///|
pub fn end_pass() -> Unit {
  if ensure_backend() is Some(backend) {
    backend.end_pass() catch {
      err => debug_runtime_error("end_pass", err)
    }
  }
}
