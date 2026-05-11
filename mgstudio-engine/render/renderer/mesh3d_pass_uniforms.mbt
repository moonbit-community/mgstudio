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
fn mesh3d_pass_uniform_state_matches(
  state : Mesh3dPassUniformState,
  frame_count : UInt,
  camera_key_hi : Int,
  camera_key_lo : Int,
  pass_kind : Int,
) -> Bool {
  state.frame_count == frame_count &&
  state.camera_key_hi == camera_key_hi &&
  state.camera_key_lo == camera_key_lo &&
  state.pass_kind == pass_kind
}

///|
fn mesh3d_pass_uniform_state_get_or_create(
  backend : GpuBackend,
  pass_state : GpuPassState,
  camera_key_hi : Int,
  camera_key_lo : Int,
  pass_kind : Int,
) -> Mesh3dPassUniformState? {
  for state in backend.mesh3d_pass_uniform_states {
    if mesh3d_pass_uniform_state_matches(
        state,
        backend.frame_count,
        camera_key_hi,
        camera_key_lo,
        pass_kind,
      ) {
      return Some(state)
    }
  }
  guard backend.frame is Some(frame) else { return None }
  let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
  let view_buffer = backend.device.create_buffer(
    size=MESH3D_VIEW_BUFFER_SIZE,
    usage~,
  )
  let lights_buffer = backend.device.create_buffer(
    size=MESH3D_LIGHTS_BUFFER_SIZE,
    usage~,
  )
  backend.queue.write_buffer(
    view_buffer,
    0UL,
    mesh3d_view_uniform_bytes(pass_state),
  )
  backend.queue.write_buffer(
    lights_buffer,
    0UL,
    mesh3d_lights_uniform_bytes(pass_state),
  )
  frame.transient_buffers.push(view_buffer)
  frame.transient_buffers.push(lights_buffer)
  let state = Mesh3dPassUniformState::{
    frame_count: backend.frame_count,
    camera_key_hi,
    camera_key_lo,
    pass_kind,
    view_buffer,
    lights_buffer,
    shadow_view_bind_group: None,
  }
  backend.mesh3d_pass_uniform_states.push(state)
  Some(state)
}

///|
fn mesh3d_shadow_view_bind_group_for_pass_uniforms(
  backend : GpuBackend,
  uniforms : Mesh3dPassUniformState,
) -> @wgpu.BindGroup? raise GpuBackendError {
  match uniforms.shadow_view_bind_group {
    Some(bind_group) => return Some(bind_group)
    None => ()
  }
  ensure_mesh3d_shadow_pipeline_layout_resources(backend)
  ensure_mesh3d_view_binding_buffers(backend)
  guard backend.frame is Some(frame) else { return None }
  guard backend.mesh3d_shadow_bgl_view is Some(view_bgl) else { return None }
  guard backend.mesh3d_globals_buf is Some(globals_buf) else { return None }
  guard backend.mesh3d_visibility_ranges_buf is Some(visibility_ranges_buf) else {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=3UL)
  let ok = builder.add_buffer(
      0U,
      uniforms.view_buffer,
      size=MESH3D_VIEW_BUFFER_SIZE,
    ) &&
    builder.add_buffer(1U, globals_buf, size=MESH3D_GLOBALS_BUFFER_SIZE) &&
    builder.add_buffer(
      14U,
      visibility_ranges_buf,
      size=MESH3D_VISIBILITY_RANGES_BUFFER_SIZE,
    )
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    view_bgl,
    label="mgstudio_mesh3d_shadow_view_bg",
  )
  frame.transient_bind_groups.push(bind_group)
  uniforms.shadow_view_bind_group = Some(bind_group)
  Some(bind_group)
}
