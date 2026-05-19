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
fn host_vertex_layout_test_descriptor(
  attribute : @asset_mesh.MeshVertexAttribute,
  shader_location : Int,
) -> @asset_mesh.VertexAttributeDescriptor {
  @asset_mesh.VertexAttributeDescriptor::new(
    shader_location~,
    id=attribute.id(),
    name=attribute.name(),
  )
}

///|
fn host_vertex_layout_test_source_layout(
  skinned? : Bool = false,
) -> @asset_mesh.MeshVertexBufferLayoutRef {
  let layouts = @asset_mesh.MeshVertexBufferLayouts::default()
  let attribute_ids = [
    @asset_mesh.MeshVertexAttribute::position().id(),
    @asset_mesh.MeshVertexAttribute::normal().id(),
    @asset_mesh.MeshVertexAttribute::uv_0().id(),
    @asset_mesh.MeshVertexAttribute::color().id(),
  ]
  let attributes = [
    @asset_mesh.VertexAttribute::new(
      offset=0,
      format=@asset_mesh.MeshVertexFormat::Float32x3,
      shader_location=0,
    ),
    @asset_mesh.VertexAttribute::new(
      offset=12,
      format=@asset_mesh.MeshVertexFormat::Float32x3,
      shader_location=1,
    ),
    @asset_mesh.VertexAttribute::new(
      offset=24,
      format=@asset_mesh.MeshVertexFormat::Float32x2,
      shader_location=2,
    ),
    @asset_mesh.VertexAttribute::new(
      offset=32,
      format=@asset_mesh.MeshVertexFormat::Float32x4,
      shader_location=5,
    ),
  ]
  let mut stride = 48
  if skinned {
    stride = 72
    attribute_ids.push(@asset_mesh.MeshVertexAttribute::joint_index().id())
    attribute_ids.push(@asset_mesh.MeshVertexAttribute::joint_weight().id())
    attributes.push(
      @asset_mesh.VertexAttribute::new(
        offset=48,
        format=@asset_mesh.MeshVertexFormat::Uint16x4,
        shader_location=6,
      ),
    )
    attributes.push(
      @asset_mesh.VertexAttribute::new(
        offset=56,
        format=@asset_mesh.MeshVertexFormat::Float32x4,
        shader_location=7,
      ),
    )
  }
  layouts.insert(
    @asset_mesh.MeshVertexBufferLayout::new(
      attribute_ids~,
      layout=@asset_mesh.VertexBufferLayout::new(
        array_stride=stride,
        step_mode=@asset_mesh.MeshVertexStepMode::Vertex,
        attributes~,
      ),
    ),
  )
}

///|
test "render mesh host vertex layout matches fixed renderer upload stride" {
  let layouts = @asset_mesh.MeshVertexBufferLayouts::default()
  let host_layout = render_mesh3d_host_vertex_buffer_layout(
    layouts,
    host_vertex_layout_test_source_layout(),
  )
  let expected = @asset_mesh.MeshVertexBufferLayout::new(
    attribute_ids=[
      @asset_mesh.MeshVertexAttribute::position().id(),
      @asset_mesh.MeshVertexAttribute::normal().id(),
      @asset_mesh.MeshVertexAttribute::uv_0().id(),
      @asset_mesh.MeshVertexAttribute::color().id(),
    ],
    layout=@asset_mesh.VertexBufferLayout::new(
      array_stride=80,
      step_mode=@asset_mesh.MeshVertexStepMode::Vertex,
      attributes=[
        @asset_mesh.VertexAttribute::new(
          offset=0,
          format=@asset_mesh.MeshVertexFormat::Float32x3,
          shader_location=0,
        ),
        @asset_mesh.VertexAttribute::new(
          offset=12,
          format=@asset_mesh.MeshVertexFormat::Float32x3,
          shader_location=1,
        ),
        @asset_mesh.VertexAttribute::new(
          offset=24,
          format=@asset_mesh.MeshVertexFormat::Float32x2,
          shader_location=2,
        ),
        @asset_mesh.VertexAttribute::new(
          offset=32,
          format=@asset_mesh.MeshVertexFormat::Float32x4,
          shader_location=5,
        ),
      ],
    ),
  )
  debug_inspect(host_layout.layout().equal(expected), content="true")
  debug_inspect(
    host_layout
    .layout()
    .contains(@asset_mesh.MeshVertexAttribute::joint_index().id()),
    content="false",
  )
}

///|
test "render mesh host vertex layout preserves skinned semantics with renderer offsets" {
  let layouts = @asset_mesh.MeshVertexBufferLayouts::default()
  let host_layout = render_mesh3d_host_vertex_buffer_layout(
    layouts,
    host_vertex_layout_test_source_layout(skinned=true),
  )
  debug_inspect(
    host_layout
    .layout()
    .contains(@asset_mesh.MeshVertexAttribute::joint_index().id()),
    content="true",
  )
  match
    host_layout
    .layout()
    .get_layout([
      host_vertex_layout_test_descriptor(
        @asset_mesh.MeshVertexAttribute::position(),
        0,
      ),
      host_vertex_layout_test_descriptor(
        @asset_mesh.MeshVertexAttribute::uv_0(),
        1,
      ),
      host_vertex_layout_test_descriptor(
        @asset_mesh.MeshVertexAttribute::joint_index(),
        5,
      ),
      host_vertex_layout_test_descriptor(
        @asset_mesh.MeshVertexAttribute::joint_weight(),
        6,
      ),
    ]) {
    Ok(prepass_layout) => {
      let expected_prepass_layout = @asset_mesh.VertexBufferLayout::new(
        array_stride=80,
        step_mode=@asset_mesh.MeshVertexStepMode::Vertex,
        attributes=[
          @asset_mesh.VertexAttribute::new(
            offset=0,
            format=@asset_mesh.MeshVertexFormat::Float32x3,
            shader_location=0,
          ),
          @asset_mesh.VertexAttribute::new(
            offset=24,
            format=@asset_mesh.MeshVertexFormat::Float32x2,
            shader_location=1,
          ),
          @asset_mesh.VertexAttribute::new(
            offset=48,
            format=@asset_mesh.MeshVertexFormat::Uint32x4,
            shader_location=5,
          ),
          @asset_mesh.VertexAttribute::new(
            offset=64,
            format=@asset_mesh.MeshVertexFormat::Float32x4,
            shader_location=6,
          ),
        ],
      )
      debug_inspect(
        prepass_layout.equal(expected_prepass_layout),
        content="true",
      )
    }
    Err(_) => abort("expected renderer host prepass layout")
  }
}
