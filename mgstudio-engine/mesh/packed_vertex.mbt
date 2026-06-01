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
// Bevy source: `bevy/crates/bevy_mesh/src/mesh.rs`
// (`attributes`, `get_vertex_size`, `count_vertices`,
// `create_packed_vertex_buffer_data`).

///|
pub fn MeshVertexFormat::size(self : MeshVertexFormat) -> Int {
  match self {
    Float32 | Sint32 | Uint32 => 4
    Float32x2 | Sint32x2 | Uint32x2 => 8
    Float32x3 | Sint32x3 | Uint32x3 => 12
    Float32x4 | Sint32x4 | Uint32x4 => 16
    Uint16x4 => 8
  }
}

///|
fn mesh_attribute_data_insert_sorted(
  attributes : Array[MeshAttributeData],
  data : MeshAttributeData,
) -> Unit {
  attributes.push(data)
  attributes.sort_by(fn(left, right) {
    let left_id = left.attribute().id().value()
    let right_id = right.attribute().id().value()
    if left_id < right_id {
      -1
    } else if left_id > right_id {
      1
    } else {
      0
    }
  })
}

///|
pub fn Mesh3dGeometry::attributes(
  self : Mesh3dGeometry,
) -> Array[MeshAttributeData] {
  let attributes : Array[MeshAttributeData] = []
  mesh_attribute_data_insert_sorted(
    attributes,
    MeshAttributeData::new(
      MeshVertexAttribute::position(),
      VertexAttributeValues::Float32x3(self.positions),
    ),
  )
  if self.normals is Some(normals) {
    mesh_attribute_data_insert_sorted(
      attributes,
      MeshAttributeData::new(
        MeshVertexAttribute::normal(),
        VertexAttributeValues::Float32x3(normals),
      ),
    )
  }
  if self.uvs is Some(uvs) {
    mesh_attribute_data_insert_sorted(
      attributes,
      MeshAttributeData::new(
        MeshVertexAttribute::uv_0(),
        VertexAttributeValues::Float32x2(uvs),
      ),
    )
  }
  if self.tangents is Some(tangents) {
    mesh_attribute_data_insert_sorted(
      attributes,
      MeshAttributeData::new(
        MeshVertexAttribute::tangent(),
        VertexAttributeValues::Float32x4(tangents),
      ),
    )
  }
  if self.colors is Some(colors) {
    mesh_attribute_data_insert_sorted(
      attributes,
      MeshAttributeData::new(
        MeshVertexAttribute::color(),
        VertexAttributeValues::Float32x4(colors),
      ),
    )
  }
  if self.joint_weights is Some(weights) {
    mesh_attribute_data_insert_sorted(
      attributes,
      MeshAttributeData::new(
        MeshVertexAttribute::joint_weight(),
        VertexAttributeValues::Float32x4(weights),
      ),
    )
  }
  if self.joint_indices is Some(indices) {
    mesh_attribute_data_insert_sorted(
      attributes,
      MeshAttributeData::new(
        MeshVertexAttribute::joint_index(),
        VertexAttributeValues::Uint16x4(indices),
      ),
    )
  }
  for custom_attribute in self.custom_attributes_vec3 {
    mesh_attribute_data_insert_sorted(
      attributes,
      MeshAttributeData::new(
        custom_attribute.attribute(),
        VertexAttributeValues::Float32x3(custom_attribute.values()),
      ),
    )
  }
  attributes
}

///|
fn mesh2d_positions_as_float32x3(
  positions : Array[@math.Vec2],
) -> Array[@math.Vec3] {
  let values : Array[@math.Vec3] = []
  for position in positions {
    values.push(@math.Vec3::new(position.x, position.y, 0.0F))
  }
  values
}

///|
pub fn Mesh2dGeometry::attributes(
  self : Mesh2dGeometry,
) -> Array[MeshAttributeData] {
  let attributes : Array[MeshAttributeData] = []
  mesh_attribute_data_insert_sorted(
    attributes,
    MeshAttributeData::new(
      MeshVertexAttribute::position(),
      VertexAttributeValues::Float32x3(
        mesh2d_positions_as_float32x3(self.positions),
      ),
    ),
  )
  if self.uvs is Some(uvs) {
    mesh_attribute_data_insert_sorted(
      attributes,
      MeshAttributeData::new(
        MeshVertexAttribute::uv_0(),
        VertexAttributeValues::Float32x2(uvs),
      ),
    )
  }
  if self.colors is Some(colors) {
    mesh_attribute_data_insert_sorted(
      attributes,
      MeshAttributeData::new(
        MeshVertexAttribute::color(),
        VertexAttributeValues::Float32x4(colors),
      ),
    )
  }
  for custom_attribute in self.custom_attributes {
    mesh_attribute_data_insert_sorted(attributes, custom_attribute)
  }
  attributes
}

///|
pub fn Mesh::attributes(self : Mesh) -> Array[MeshAttributeData] {
  match self.geometry {
    MeshGeometry::Geometry3d(geometry) => geometry.attributes()
    MeshGeometry::Geometry2d(geometry) => geometry.attributes()
  }
}

///|
pub fn Mesh::count_vertices(self : Mesh) -> Int {
  let attributes = self.attributes()
  if attributes.is_empty() {
    return 0
  }
  let mut count = attributes[0].values().len()
  for index in 1..<attributes.length() {
    count = count.min(attributes[index].values().len())
  }
  count
}

///|
pub fn Mesh::get_vertex_size(self : Mesh) -> Int {
  let mut size = 0
  for attribute in self.attributes() {
    size = size + attribute.attribute().format().size()
  }
  size
}

///|
pub fn Mesh::get_vertex_buffer_size(self : Mesh) -> Int {
  self.get_vertex_size() * self.count_vertices()
}

///|
pub fn Mesh::get_mesh_vertex_buffer_layout(
  self : Mesh,
  mesh_vertex_buffer_layouts : MeshVertexBufferLayouts,
) -> MeshVertexBufferLayoutRef {
  let mesh_attributes = self.attributes()
  let attributes : Array[VertexAttribute] = []
  let attribute_ids : Array[MeshVertexAttributeId] = []
  let mut accumulated_offset = 0
  for index in 0..<mesh_attributes.length() {
    let data = mesh_attributes[index]
    attribute_ids.push(data.attribute().id())
    attributes.push(
      VertexAttribute::new(
        offset=accumulated_offset,
        format=data.attribute().format(),
        shader_location=index,
      ),
    )
    accumulated_offset = accumulated_offset + data.attribute().format().size()
  }
  mesh_vertex_buffer_layouts.insert(
    MeshVertexBufferLayout::new(
      attribute_ids~,
      layout=VertexBufferLayout::new(
        array_stride=accumulated_offset,
        step_mode=MeshVertexStepMode::Vertex,
        attributes~,
      ),
    ),
  )
}

///|
fn mesh_push_u16_le(out : Array[Byte], value : UInt) -> Unit {
  out.push(value.to_byte())
  out.push((value >> 8).to_byte())
}

///|
fn mesh_push_u32_le(out : Array[Byte], value : UInt) -> Unit {
  out.push(value.to_byte())
  out.push((value >> 8).to_byte())
  out.push((value >> 16).to_byte())
  out.push((value >> 24).to_byte())
}

///|
fn mesh_push_f32_le(out : Array[Byte], value : Float) -> Unit {
  mesh_push_u32_le(out, value.reinterpret_as_uint())
}

///|
fn mesh_push_i32_le(out : Array[Byte], value : Int) -> Unit {
  mesh_push_u32_le(out, value.reinterpret_as_uint())
}

///|
fn mesh_push_u32_value_le(out : Array[Byte], value : UInt) -> Unit {
  mesh_push_u32_le(out, value)
}

///|
fn mesh_push_u16_value_le(out : Array[Byte], value : Int) -> Unit {
  mesh_push_u16_le(out, (value & 0xFFFF).reinterpret_as_uint())
}

///|
fn mesh_push_attribute_value_at(
  out : Array[Byte],
  values : VertexAttributeValues,
  index : Int,
) -> Unit {
  match values {
    Float32(items) => mesh_push_f32_le(out, items[index])
    Sint32(items) => mesh_push_i32_le(out, items[index])
    Uint32(items) => mesh_push_u32_value_le(out, items[index])
    Float32x2(items) => {
      let value = items[index]
      mesh_push_f32_le(out, value.x)
      mesh_push_f32_le(out, value.y)
    }
    Sint32x2(items) => {
      let value = items[index]
      mesh_push_i32_le(out, value.x)
      mesh_push_i32_le(out, value.y)
    }
    Uint32x2(items) => {
      let value = items[index]
      mesh_push_u32_value_le(out, value.x.reinterpret_as_uint())
      mesh_push_u32_value_le(out, value.y.reinterpret_as_uint())
    }
    Float32x3(items) => {
      let value = items[index]
      mesh_push_f32_le(out, value.x)
      mesh_push_f32_le(out, value.y)
      mesh_push_f32_le(out, value.z)
    }
    Sint32x3(items) => {
      let (x, y, z) = items[index]
      mesh_push_i32_le(out, x)
      mesh_push_i32_le(out, y)
      mesh_push_i32_le(out, z)
    }
    Uint32x3(items) => {
      let (x, y, z) = items[index]
      mesh_push_u32_value_le(out, x)
      mesh_push_u32_value_le(out, y)
      mesh_push_u32_value_le(out, z)
    }
    Float32x4(items) => {
      let value = items[index]
      mesh_push_f32_le(out, value.x)
      mesh_push_f32_le(out, value.y)
      mesh_push_f32_le(out, value.z)
      mesh_push_f32_le(out, value.w)
    }
    Sint32x4(items) => {
      let (x, y, z, w) = items[index]
      mesh_push_i32_le(out, x)
      mesh_push_i32_le(out, y)
      mesh_push_i32_le(out, z)
      mesh_push_i32_le(out, w)
    }
    Uint32x4(items) => {
      let (x, y, z, w) = items[index]
      mesh_push_u32_value_le(out, x)
      mesh_push_u32_value_le(out, y)
      mesh_push_u32_value_le(out, z)
      mesh_push_u32_value_le(out, w)
    }
    Uint16x4(items) => {
      let value = items[index]
      mesh_push_u16_value_le(out, value.x)
      mesh_push_u16_value_le(out, value.y)
      mesh_push_u16_value_le(out, value.z)
      mesh_push_u16_value_le(out, value.w)
    }
  }
}

///|
pub fn Mesh::create_packed_vertex_buffer_data(self : Mesh) -> Bytes {
  let attributes = self.attributes()
  let vertex_count = self.count_vertices()
  let out : Array[Byte] = []
  for vertex_index in 0..<vertex_count {
    for attribute in attributes {
      mesh_push_attribute_value_at(out, attribute.values(), vertex_index)
    }
  }
  Bytes::from_array(out)
}
