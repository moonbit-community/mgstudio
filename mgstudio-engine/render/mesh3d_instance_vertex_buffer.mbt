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
pub struct Mesh3dInstanceVertexBufferData {
  buffer_id : Int
  bytes : Bytes
  length : Int
}

///|
pub fn Mesh3dInstanceVertexBufferData::new(
  buffer_id~ : Int,
  bytes~ : Bytes,
  length~ : Int,
) -> Mesh3dInstanceVertexBufferData {
  Mesh3dInstanceVertexBufferData::{ buffer_id, bytes, length }
}

///|
pub fn Mesh3dInstanceVertexBufferData::buffer_id(
  self : Mesh3dInstanceVertexBufferData,
) -> Int {
  self.buffer_id
}

///|
pub fn Mesh3dInstanceVertexBufferData::bytes(
  self : Mesh3dInstanceVertexBufferData,
) -> Bytes {
  self.bytes
}

///|
pub fn Mesh3dInstanceVertexBufferData::length(
  self : Mesh3dInstanceVertexBufferData,
) -> Int {
  self.length
}

///|
pub let mesh3d_instance_vertex_buffer_data_key : @ecs.ComponentKey[
  Mesh3dInstanceVertexBufferData,
] = @ecs.register_component(
  debug_name="mgstudio_render::Mesh3dInstanceVertexBufferData",
)

///|
pub impl @ecs.Component for Mesh3dInstanceVertexBufferData with fn component() {
  mesh3d_instance_vertex_buffer_data_key
}
