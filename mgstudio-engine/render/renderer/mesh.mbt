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
/// Shared mesh lookup and index-buffer binding helpers.
///
/// Split from gpu_postprocess2d.mbt so bloom no longer owns generic mesh access.

///|
fn find_mesh(backend : GpuBackend, id : Int) -> GpuMeshInfo? {
  for m in backend.meshes {
    if m.id == id {
      return Some(m)
    }
  }
  None
}

///|
fn find_mesh_index(backend : GpuBackend, id : Int) -> Int? {
  for i in 0..<backend.meshes.length() {
    if backend.meshes[i].id == id {
      return Some(i)
    }
  }
  None
}

///|
fn gpu_mesh_bind_index_buffer(
  pass : @wgpu.RenderPass,
  mesh : GpuMeshInfo,
) -> Unit {
  let index_bytes = mesh.index_count.reinterpret_as_int().to_uint64() *
    mesh.index_stride_bytes
  if mesh.uses_u32_indices {
    pass.set_index_buffer_u32(mesh.index_buf, 0UL, index_bytes)
  } else {
    pass.set_index_buffer_u16(mesh.index_buf, 0UL, index_bytes)
  }
}

///|
fn parse_f32_csv(csv : String) -> Array[Float]? {
  let trimmed = csv.trim().to_owned()
  if trimmed == "" {
    return Some([])
  }
  let values : Array[Float] = []
  for part in csv.split(",") {
    let token = part.trim().to_owned()
    if token == "" {
      continue
    }
    let parsed = @string.parse_double(token) catch { _ => return None }
    values.push(Float::from_double(parsed))
  }
  Some(values)
}

///|
pub fn create_mesh_capsule(
  radius~ : Float,
  half_length~ : Float,
  segments~ : Int,
) -> Int {
  if ensure_backend() is Some(backend) {
    return backend.create_mesh_capsule(radius, half_length, segments)
  }
  0
}

///|
pub fn create_mesh_rectangle(width~ : Float, height~ : Float) -> Int {
  if ensure_backend() is Some(backend) {
    return backend.create_mesh_rectangle(width, height)
  }
  0
}

///|
pub fn create_mesh_triangles(vertices_xy_csv~ : String) -> Int {
  if parse_f32_csv(vertices_xy_csv) is Some(vertices) {
    if ensure_backend() is Some(backend) {
      let mesh_id = backend.create_mesh_triangles_xy(vertices)
      if mesh_id <= 0 {
        debug(
          "[renderer] create_mesh_triangles failed: parsed_values=\{vertices.length().to_string()}",
        )
      }
      return mesh_id
    }
  } else {
    debug(
      "[renderer] create_mesh_triangles parse failed: csv_len=\{vertices_xy_csv.length().to_string()}",
    )
  }
  0
}

///|
pub fn create_mesh_triangles_xyuvrgba(vertices_xyuvrgba_csv~ : String) -> Int {
  if parse_f32_csv(vertices_xyuvrgba_csv) is Some(vertices) {
    if ensure_backend() is Some(backend) {
      let mesh_id = backend.create_mesh_triangles_xyuvrgba(vertices)
      if mesh_id <= 0 {
        debug(
          "[renderer] create_mesh_triangles_xyuvrgba failed: parsed_values=\{vertices.length().to_string()}",
        )
      }
      return mesh_id
    }
  } else {
    debug(
      "[renderer] create_mesh_triangles_xyuvrgba parse failed: csv_len=\{vertices_xyuvrgba_csv.length().to_string()}",
    )
  }
  0
}

///|
pub fn create_mesh3d(
  vertices_xyzuvrgba_csv~ : String,
  primitive_topology~ : Int,
) -> Int {
  if parse_f32_csv(vertices_xyzuvrgba_csv) is Some(vertices) {
    return create_mesh3d_xyznuvrgba(
      vertices_xyznuvrgba=vertices,
      primitive_topology~,
    )
  } else {
    debug(
      "[renderer] create_mesh3d parse failed: csv_len=\{vertices_xyzuvrgba_csv.length().to_string()}, topology=\{primitive_topology.to_string()}",
    )
  }
  0
}

///|
pub fn create_mesh3d_xyznuvrgba(
  vertices_xyznuvrgba~ : Array[Float],
  primitive_topology~ : Int,
) -> Int {
  if ensure_backend() is Some(backend) {
    let mesh_id = backend.create_mesh3d_xyznuvrgba(
      vertices_xyznuvrgba, primitive_topology,
    )
    if mesh_id <= 0 {
      debug(
        "[renderer] create_mesh3d_xyznuvrgba failed: values=\{vertices_xyznuvrgba.length().to_string()}, topology=\{primitive_topology.to_string()}",
      )
    }
    return mesh_id
  }
  0
}

///|
pub fn update_mesh3d_xyznuvrgba(
  mesh_id~ : Int,
  vertices_xyznuvrgba~ : Array[Float],
  primitive_topology~ : Int,
) -> Bool {
  if ensure_backend() is Some(backend) {
    return backend.update_mesh3d_xyznuvrgba(
      mesh_id, vertices_xyznuvrgba, primitive_topology,
    )
  }
  false
}
