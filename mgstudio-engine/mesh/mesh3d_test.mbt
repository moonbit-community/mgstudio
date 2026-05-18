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
fn mesh3d_test_rectangle() -> Mesh3dGeometry {
  Mesh3dGeometry::new(
    [
      @math.Vec3::new(-1.0F, -2.0F, 0.0F),
      @math.Vec3::new(1.0F, -2.0F, 0.0F),
      @math.Vec3::new(1.0F, 2.0F, 0.0F),
      @math.Vec3::new(-1.0F, -2.0F, 0.0F),
      @math.Vec3::new(1.0F, 2.0F, 0.0F),
      @math.Vec3::new(-1.0F, 2.0F, 0.0F),
    ],
    [
      @math.Vec2::new(0.0F, 1.0F),
      @math.Vec2::new(1.0F, 1.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 0.0F),
    ],
    None,
  )
}

///|
fn mesh3d_test_line_strip() -> Mesh3dGeometry {
  Mesh3dGeometry::new_with_topology(
    [
      @math.Vec3::new(2.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 2.0F, 0.0F),
      @math.Vec3::new(-2.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, -2.0F, 0.0F),
      @math.Vec3::new(2.0F, 0.0F, 0.0F),
    ],
    [
      @math.Vec2::zero(),
      @math.Vec2::zero(),
      @math.Vec2::zero(),
      @math.Vec2::zero(),
      @math.Vec2::zero(),
    ],
    None,
    Mesh3dPrimitiveTopology::LineStrip,
  )
}

///|
test "mesh: Mesh3dGeometry::flatten_interleaved_xyz_normal_uv_rgba emits flat triangle normals" {
  let geometry = mesh3d_test_rectangle()
  match geometry.flatten_interleaved_xyz_normal_uv_rgba() {
    Some(values) => {
      debug_inspect(values.length(), content="72")
      debug_inspect(
        (values[3], values[4], values[5], values[15], values[16], values[17]),
        content="(0, 0, 1, 0, 0, 1)",
      )
    }
    None => abort("expected normal-aware flatten data")
  }
}

///|
test "mesh: Mesh3dGeometry::flatten_interleaved_xyz_normal_uv_rgba gives default line normal" {
  let geometry = mesh3d_test_line_strip()
  match geometry.flatten_interleaved_xyz_normal_uv_rgba() {
    Some(values) => {
      debug_inspect(values.length() % 12, content="0")
      debug_inspect((values[3], values[4], values[5]), content="(0, 0, 1)")
    }
    None => abort("expected line-strip normal-aware flatten data")
  }
}

///|
test "mesh: Mesh3dGeometry vertex-order flatten preserves indexed source vertices" {
  let geometry = Mesh3dGeometry::new(
    [
      @math.Vec3::new(-1.0F, -1.0F, 0.0F),
      @math.Vec3::new(1.0F, -1.0F, 0.0F),
      @math.Vec3::new(1.0F, 1.0F, 0.0F),
      @math.Vec3::new(-1.0F, 1.0F, 0.0F),
    ],
    [
      @math.Vec2::new(0.0F, 1.0F),
      @math.Vec2::new(1.0F, 1.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 0.0F),
    ],
    Some([0, 1, 2, 0, 2, 3]),
  )
  match geometry.flatten_interleaved_xyz_normal_uv_rgba_joints_weights() {
    Some(index_expanded) =>
      debug_inspect(index_expanded.length(), content="120")
    None => abort("expected index-expanded flatten data")
  }
  match
    geometry.flatten_interleaved_xyz_normal_uv_rgba_joints_weights_vertices() {
    Some(vertex_order) => debug_inspect(vertex_order.length(), content="80")
    None => abort("expected vertex-order flatten data")
  }
}

///|
test "mesh: Mesh3dGeometry standard attributes use vertex attribute ids" {
  let geometry = Mesh3dGeometry::new_with_positions(
    [@math.Vec3::new(1.0F, 2.0F, 3.0F)],
    None,
  )
  geometry.insert_indices(Some([0]))
  ignore(
    geometry.insert_attribute(
      MeshVertexAttribute::normal(),
      VertexAttributeValues::Float32x3([@math.Vec3::new(0.0F, 1.0F, 0.0F)]),
    ),
  )
  ignore(
    geometry.insert_attribute(
      MeshVertexAttribute::uv_0(),
      VertexAttributeValues::Float32x2([@math.Vec2::new(0.25F, 0.75F)]),
    ),
  )
  debug_inspect(
    geometry.contains_attribute(MeshVertexAttribute::position().id()),
    content="true",
  )
  debug_inspect(
    geometry.contains_attribute(MeshVertexAttribute::normal().id()),
    content="true",
  )
  debug_inspect(
    geometry.contains_attribute(MeshVertexAttribute::uv_0().id()),
    content="true",
  )
  guard geometry.attribute(MeshVertexAttribute::normal().id())
    is Some(VertexAttributeValues::Float32x3(normals)) else {
    abort("missing normal attribute")
  }
  debug_inspect(normals[0].y.to_double(), content="1")
  debug_inspect(geometry.has_indices(), content="true")
}

///|
fn mesh3d_test_read_u32_le(bytes : Bytes, offset : Int) -> UInt {
  let b0 = bytes.get(offset).unwrap().to_int() & 0xFF
  let b1 = bytes.get(offset + 1).unwrap().to_int() & 0xFF
  let b2 = bytes.get(offset + 2).unwrap().to_int() & 0xFF
  let b3 = bytes.get(offset + 3).unwrap().to_int() & 0xFF
  (b0 & 0xFF).reinterpret_as_uint() |
  ((b1 & 0xFF).reinterpret_as_uint() << 8) |
  ((b2 & 0xFF).reinterpret_as_uint() << 16) |
  ((b3 & 0xFF).reinterpret_as_uint() << 24)
}

///|
fn mesh3d_test_read_f32_le(bytes : Bytes, offset : Int) -> Float {
  Float::reinterpret_from_uint(mesh3d_test_read_u32_le(bytes, offset))
}

///|
test "mesh: attributes and packed vertex buffer follow Bevy attribute id order" {
  let geometry = Mesh3dGeometry::new_with_positions(
    [@math.Vec3::new(1.0F, 2.0F, 3.0F), @math.Vec3::new(4.0F, 5.0F, 6.0F)],
    Some([0, 1]),
  )
  ignore(
    geometry.insert_attribute(
      MeshVertexAttribute::uv_0(),
      VertexAttributeValues::Float32x2([
        @math.Vec2::new(0.25F, 0.5F),
        @math.Vec2::new(0.75F, 1.0F),
      ]),
    ),
  )
  ignore(
    geometry.insert_attribute(
      MeshVertexAttribute::normal(),
      VertexAttributeValues::Float32x3([
        @math.Vec3::new(0.0F, 0.0F, 1.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ]),
    ),
  )
  let mesh = Mesh::from_3d_geometry(geometry)
  let attributes = mesh.attributes()
  debug_inspect(attributes.length(), content="3")
  debug_inspect(attributes[0].attribute().name(), content="\"Vertex_Position\"")
  debug_inspect(attributes[1].attribute().name(), content="\"Vertex_Normal\"")
  debug_inspect(attributes[2].attribute().name(), content="\"Vertex_Uv\"")
  debug_inspect(mesh.count_vertices(), content="2")
  debug_inspect(mesh.get_vertex_size(), content="32")
  debug_inspect(mesh.get_vertex_buffer_size(), content="64")
  let packed = mesh.create_packed_vertex_buffer_data()
  debug_inspect(packed.length(), content="64")
  debug_inspect(mesh3d_test_read_f32_le(packed, 0).to_double(), content="1")
  debug_inspect(mesh3d_test_read_f32_le(packed, 12).to_double(), content="0")
  debug_inspect(mesh3d_test_read_f32_le(packed, 20).to_double(), content="1")
  debug_inspect(mesh3d_test_read_f32_le(packed, 24).to_double(), content="0.25")
  debug_inspect(mesh3d_test_read_f32_le(packed, 32).to_double(), content="4")
  debug_inspect(mesh3d_test_read_f32_le(packed, 60).to_double(), content="1")
}

///|
test "mesh: vertex buffer layout mirrors Bevy attribute id order" {
  let geometry = Mesh3dGeometry::new_with_positions(
    [@math.Vec3::new(1.0F, 2.0F, 3.0F)],
    Some([0]),
  )
  ignore(
    geometry.insert_attribute(
      MeshVertexAttribute::uv_0(),
      VertexAttributeValues::Float32x2([@math.Vec2::new(0.25F, 0.5F)]),
    ),
  )
  ignore(
    geometry.insert_attribute(
      MeshVertexAttribute::normal(),
      VertexAttributeValues::Float32x3([@math.Vec3::new(0.0F, 0.0F, 1.0F)]),
    ),
  )
  let layouts = MeshVertexBufferLayouts::default()
  let layout_ref = Mesh::from_3d_geometry(geometry).get_mesh_vertex_buffer_layout(
    layouts,
  )
  let mesh_layout = layout_ref.layout()
  let layout = mesh_layout.layout()
  debug_inspect(layouts.len(), content="1")
  debug_inspect(layout_ref.index(), content="0")
  debug_inspect(mesh_layout.attribute_ids()[0].value(), content="0")
  debug_inspect(mesh_layout.attribute_ids()[1].value(), content="1")
  debug_inspect(mesh_layout.attribute_ids()[2].value(), content="2")
  debug_inspect(layout.array_stride, content="32")
  debug_inspect(layout.step_mode is MeshVertexStepMode::Vertex, content="true")
  debug_inspect(layout.attributes[0].offset, content="0")
  debug_inspect(layout.attributes[0].shader_location, content="0")
  debug_inspect(layout.attributes[1].offset, content="12")
  debug_inspect(layout.attributes[1].shader_location, content="1")
  debug_inspect(layout.attributes[2].offset, content="24")
  debug_inspect(layout.attributes[2].shader_location, content="2")
  debug_inspect(
    mesh_layout.contains(MeshVertexAttribute::normal().id()),
    content="true",
  )
}

///|
test "mesh: specialized vertex buffer layout remaps shader locations" {
  let layout = MeshVertexBufferLayout::new(
    attribute_ids=[
      MeshVertexAttribute::position().id(),
      MeshVertexAttribute::normal().id(),
      MeshVertexAttribute::uv_0().id(),
    ],
    layout=VertexBufferLayout::new(
      array_stride=32,
      step_mode=MeshVertexStepMode::Vertex,
      attributes=[
        VertexAttribute::new(
          offset=0,
          format=MeshVertexFormat::Float32x3,
          shader_location=0,
        ),
        VertexAttribute::new(
          offset=12,
          format=MeshVertexFormat::Float32x3,
          shader_location=1,
        ),
        VertexAttribute::new(
          offset=24,
          format=MeshVertexFormat::Float32x2,
          shader_location=2,
        ),
      ],
    ),
  )
  let specialized = layout.get_layout([
    VertexAttributeDescriptor::new(
      shader_location=7,
      id=MeshVertexAttribute::uv_0().id(),
      name="Vertex_Uv",
    ),
    VertexAttributeDescriptor::new(
      shader_location=3,
      id=MeshVertexAttribute::position().id(),
      name="Vertex_Position",
    ),
  ])
  match specialized {
    Ok(vertex_layout) => {
      debug_inspect(vertex_layout.array_stride, content="32")
      debug_inspect(vertex_layout.attributes.length(), content="2")
      debug_inspect(vertex_layout.attributes[0].offset, content="24")
      debug_inspect(vertex_layout.attributes[0].shader_location, content="7")
      debug_inspect(vertex_layout.attributes[1].offset, content="0")
      debug_inspect(vertex_layout.attributes[1].shader_location, content="3")
    }
    Err(_) => abort("expected specialized layout")
  }
}

///|
test "mesh: specialized vertex buffer layout reports missing attributes" {
  let layout = MeshVertexBufferLayout::new(
    attribute_ids=[MeshVertexAttribute::position().id()],
    layout=VertexBufferLayout::new(
      array_stride=12,
      step_mode=MeshVertexStepMode::Vertex,
      attributes=[
        VertexAttribute::new(
          offset=0,
          format=MeshVertexFormat::Float32x3,
          shader_location=0,
        ),
      ],
    ),
  )
  match
    layout.get_layout([
      VertexAttributeDescriptor::new(
        shader_location=2,
        id=MeshVertexAttribute::uv_0().id(),
        name="Vertex_Uv",
      ),
    ]) {
    Ok(_) => abort("expected missing attribute")
    Err(error) => {
      debug_inspect(error.id.value(), content="2")
      debug_inspect(error.name, content="\"Vertex_Uv\"")
      debug_inspect(error.pipeline_type is None, content="true")
    }
  }
}

///|
test "mesh: vertex buffer layout store deduplicates structural layouts" {
  let layouts = MeshVertexBufferLayouts::default()
  let layout = MeshVertexBufferLayout::new(
    attribute_ids=[MeshVertexAttribute::position().id()],
    layout=VertexBufferLayout::new(
      array_stride=12,
      step_mode=MeshVertexStepMode::Vertex,
      attributes=[
        VertexAttribute::new(
          offset=0,
          format=MeshVertexFormat::Float32x3,
          shader_location=0,
        ),
      ],
    ),
  )
  let first = layouts.insert(layout)
  let second = layouts.insert(first.layout())
  debug_inspect(layouts.len(), content="1")
  debug_inspect(first.index(), content="0")
  debug_inspect(second.index(), content="0")
}
