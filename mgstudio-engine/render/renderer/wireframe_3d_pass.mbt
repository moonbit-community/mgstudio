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
// Bevy source: `bevy/crates/bevy_pbr/src/wireframe.rs::wireframe_3d`.
fn GpuBackend::begin_wireframe_3d_pass(
  self : GpuBackend,
) -> Bool raise GpuBackendError {
  guard self.frame is Some(frame) else { return false }
  guard frame.pass is None else { return false }
  guard self.pass_state is Some(pass_state) else { return false }
  guard pass_state.is_3d else { return false }
  guard target_color_attachment(
      self,
      pass_state.target_id,
      pass_state.target_layer,
      pass_state.msaa_sample_count,
    )
    is Some((color_view, color_resolve_view)) else {
    return false
  }
  guard pass_state.view_depth_view is Some(depth_view) else { return false }
  let builder = @wgpu.RenderPassDescBuilder::new(1U) catch {
    _ => fatal("wgpu: failed to create wireframe_3d render pass descriptor")
  }
  builder.set_color_attachment(
    0U,
    color_view,
    load_op_u32=@wgpu.LOAD_OP_LOAD,
    store_op_u32=@wgpu.STORE_OP_STORE,
    clear_r_f32=0.0F,
    clear_g_f32=0.0F,
    clear_b_f32=0.0F,
    clear_a_f32=0.0F,
  ) catch {
    _ => fatal("wgpu: failed to set wireframe_3d color attachment")
  }
  match color_resolve_view {
    Some(resolve_view) =>
      builder.set_color_attachment_resolve_target(0U, resolve_view) catch {
        _ => fatal("wgpu: failed to set wireframe_3d resolve target")
      }
    None => ()
  }
  builder.set_depth_stencil_attachment(
    depth_view,
    depth_load_op_u32=@wgpu.LOAD_OP_LOAD,
    depth_store_op_u32=@wgpu.STORE_OP_STORE,
    depth_clear_value_f32=0.0F,
    depth_read_only=false,
    stencil_load_op_u32=@wgpu.LOAD_OP_LOAD,
    stencil_store_op_u32=@wgpu.STORE_OP_STORE,
    stencil_clear_value_u32=0U,
    stencil_read_only=true,
  ) catch {
    _ => fatal("wgpu: failed to set wireframe_3d depth attachment")
  }
  let pass = builder.begin(frame.encoder) catch {
    _ => fatal("wgpu: failed to begin wireframe_3d render pass")
  }
  pass.set_viewport(
    Float::from_double(pass_state.viewport_x.to_double()),
    Float::from_double(pass_state.viewport_y.to_double()),
    Float::from_double(pass_state.viewport_w.to_double()),
    Float::from_double(pass_state.viewport_h.to_double()),
    pass_state.viewport_depth_min,
    pass_state.viewport_depth_max,
  )
  let (sx, sy, sw, sh) = clamp_scissor_to_target(
    self,
    pass_state.target_id,
    pass_state.viewport_x,
    pass_state.viewport_y,
    pass_state.viewport_w,
    pass_state.viewport_h,
  )
  pass.set_scissor_rect(sx, sy, sw, sh)
  frame.pass = Some(pass)
  self.pass_has_depth = true
  render_pass_timing_begin_active_pass(RENDER_PASS_PHASE_3D_MAIN)
  @app.timeline_trace_emit_counter_int("wireframe_3d_tracked_passes", 1)
  true
}

///|
pub fn begin_wireframe_3d_pass() -> Bool {
  guard ensure_backend() is Some(backend) else { return false }
  backend.begin_wireframe_3d_pass() catch {
    err => {
      debug_runtime_error("begin_wireframe_3d_pass", err)
      false
    }
  }
}
