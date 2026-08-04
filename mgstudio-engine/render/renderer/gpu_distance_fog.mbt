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
// Bevy source: `bevy/crates/bevy_pbr/src/fog.rs` (render-world `GpuFog`
// uniform written by `prepare_fog` and read at mesh-view binding 13 as the
// `Fog` struct in `mesh_view_types.wgsl`).

///|
fn mesh3d_fog_uniform_bytes(
  base_color_r : Float,
  base_color_g : Float,
  base_color_b : Float,
  base_color_a : Float,
  directional_light_color_r : Float,
  directional_light_color_g : Float,
  directional_light_color_b : Float,
  directional_light_color_a : Float,
  be_x : Float,
  be_y : Float,
  be_z : Float,
  directional_light_exponent : Float,
  bi_x : Float,
  bi_y : Float,
  bi_z : Float,
  mode : UInt,
) -> Bytes {
  u32le_pack([
    f32_bits(base_color_r),
    f32_bits(base_color_g),
    f32_bits(base_color_b),
    f32_bits(base_color_a),
    f32_bits(directional_light_color_r),
    f32_bits(directional_light_color_g),
    f32_bits(directional_light_color_b),
    f32_bits(directional_light_color_a),
    f32_bits(be_x),
    f32_bits(be_y),
    f32_bits(be_z),
    f32_bits(directional_light_exponent),
    f32_bits(bi_x),
    f32_bits(bi_y),
    f32_bits(bi_z),
    mode,
  ])
}

///|
pub fn GpuBackend::prepare_mesh3d_fog(
  self : GpuBackend,
  base_color_r : Float,
  base_color_g : Float,
  base_color_b : Float,
  base_color_a : Float,
  directional_light_color_r : Float,
  directional_light_color_g : Float,
  directional_light_color_b : Float,
  directional_light_color_a : Float,
  be_x : Float,
  be_y : Float,
  be_z : Float,
  directional_light_exponent : Float,
  bi_x : Float,
  bi_y : Float,
  bi_z : Float,
  mode : UInt,
) -> Unit raise GpuBackendError {
  ensure_mesh3d_view_binding_buffers(self)
  guard self.mesh3d_fog_buf is Some(buffer) else {
    fatal("wgpu: missing mesh3d fog buffer")
  }
  self.queue.write_buffer(
    buffer,
    0UL,
    mesh3d_fog_uniform_bytes(
      base_color_r, base_color_g, base_color_b, base_color_a, directional_light_color_r,
      directional_light_color_g, directional_light_color_b, directional_light_color_a,
      be_x, be_y, be_z, directional_light_exponent, bi_x, bi_y, bi_z, mode,
    ),
  )
}

///|
pub fn prepare_mesh3d_fog(
  base_color_r~ : Float,
  base_color_g~ : Float,
  base_color_b~ : Float,
  base_color_a~ : Float,
  directional_light_color_r~ : Float,
  directional_light_color_g~ : Float,
  directional_light_color_b~ : Float,
  directional_light_color_a~ : Float,
  be_x~ : Float,
  be_y~ : Float,
  be_z~ : Float,
  directional_light_exponent~ : Float,
  bi_x~ : Float,
  bi_y~ : Float,
  bi_z~ : Float,
  mode~ : UInt,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_mesh3d_fog(
      base_color_r, base_color_g, base_color_b, base_color_a, directional_light_color_r,
      directional_light_color_g, directional_light_color_b, directional_light_color_a,
      be_x, be_y, be_z, directional_light_exponent, bi_x, bi_y, bi_z, mode,
    ) catch {
      err => debug_runtime_error("prepare_mesh3d_fog", err)
    }
  }
}
