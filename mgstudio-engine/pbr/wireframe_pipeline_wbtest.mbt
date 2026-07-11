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
fn wireframe_pipeline_test_descriptor() -> @material.RenderPipelineDescriptor {
  @material.RenderPipelineDescriptor::RenderPipelineDescriptor()
  .with_vertex(
    @material.VertexState::new(Some("base.wgsl"), [], Some("vertex"), [
      @mesh.VertexBufferLayout::new(
        array_stride=12,
        step_mode=@mesh.MeshVertexStepMode::Vertex,
        attributes=[],
      ),
    ]),
  )
  .with_fragment(
    Some(
      @material.FragmentState::new(Some("base.wgsl"), [], Some("fragment"), [
        Some(@material.ColorTargetState::new(1U, 0xffffffffffffffffUL)),
      ]),
    ),
  )
  .with_depth_stencil(Some(@material.DepthStencilState::DepthStencilState()))
}

///|
fn wireframe_pipeline_shader_defs_contain_flag(
  shader_defs : Array[@material.ShaderDefVal],
  name : String,
) -> Bool {
  for shader_def in shader_defs {
    match shader_def {
      @material.ShaderDefVal::Flag(flag) if flag == name => return true
      _ => ()
    }
  }
  false
}

///|
test "pbr: Wireframe3dPipeline thin specialization mirrors Bevy descriptor edits" {
  let pipeline = Wireframe3dPipeline::new()
  let key = WireframePipelineKey::new(
    @material.ErasedMeshPipelineKey::new(1UL, "MeshPipelineKey"),
    false,
    false,
    false,
  )
  let descriptor = try! pipeline.specialize(
    key,
    wireframe_pipeline_test_descriptor(),
  )

  debug_inspect(descriptor.label, content="Some(\"wireframe_3d_pipeline\")")
  debug_inspect(descriptor.immediate_size, content="16")
  debug_inspect(descriptor.vertex.shader, content="Some(\"base.wgsl\")")
  debug_inspect(descriptor.vertex.buffers.length(), content="1")
  debug_inspect(
    descriptor.fragment.unwrap().shader,
    content="Some(\"pbr/render/wireframe.wgsl\")",
  )
  debug_inspect(descriptor.primitive.polygon_mode, content="Some(1)")
  debug_inspect(descriptor.depth_stencil.unwrap().bias_slope_scale, content="1")
}

///|
test "pbr: Wireframe3dPipeline wide specialization mirrors Bevy descriptor edits" {
  let pipeline = Wireframe3dPipeline::new()
  let key = WireframePipelineKey::new(
    @material.ErasedMeshPipelineKey::new(1UL, "MeshPipelineKey"),
    true,
    true,
    true,
  )
  let descriptor = try! pipeline.specialize(
    key,
    wireframe_pipeline_test_descriptor(),
  )

  debug_inspect(
    descriptor.label,
    content="Some(\"wireframe_3d_wide_pipeline\")",
  )
  debug_inspect(descriptor.immediate_size, content="32")
  debug_inspect(
    descriptor.vertex.shader,
    content="Some(\"pbr/render/wireframe.wgsl\")",
  )
  debug_inspect(descriptor.vertex.entry_point, content="Some(\"vertex\")")
  debug_inspect(descriptor.vertex.buffers.length(), content="0")
  debug_inspect(
    wireframe_pipeline_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "WIREFRAME_WIDE",
    ),
    content="true",
  )
  debug_inspect(
    wireframe_pipeline_shader_defs_contain_flag(
      descriptor.vertex.shader_defs,
      "WIREFRAME_QUADS",
    ),
    content="true",
  )
  debug_inspect(
    wireframe_pipeline_shader_defs_contain_flag(
      descriptor.fragment.unwrap().shader_defs,
      "WIREFRAME_WIDE",
    ),
    content="true",
  )
  debug_inspect(
    descriptor.fragment.unwrap().entry_point,
    content="Some(\"fragment\")",
  )
  debug_inspect(descriptor.layout.length(), content="1")
  let wide_layout = descriptor.layout[0]
  debug_inspect(wide_layout.entries().length(), content="3")
  debug_inspect(
    wide_layout.entries()[0].kind()
    is @render_resource.BindingType::BufferBinding(
      @render_resource.BufferBindingType::Storage(true),
      false,
      0UL
    ),
    content="true",
  )
  debug_inspect(
    wide_layout.entries()[2].kind()
    is @render_resource.BindingType::BufferBinding(
      @render_resource.BufferBindingType::Uniform,
      true,
      16UL
    ),
    content="true",
  )
  debug_inspect(descriptor.primitive.polygon_mode, content="Some(1)")
}

///|
test "pbr: Wireframe3dPipeline wide thick mode keeps fill polygon mode" {
  let pipeline = Wireframe3dPipeline::new()
  let key = WireframePipelineKey::new(
    @material.ErasedMeshPipelineKey::new(1UL, "MeshPipelineKey"),
    true,
    false,
    false,
  )
  let descriptor = try! pipeline.specialize(
    key,
    wireframe_pipeline_test_descriptor(),
  )

  debug_inspect(descriptor.primitive.polygon_mode, content="None")
}
