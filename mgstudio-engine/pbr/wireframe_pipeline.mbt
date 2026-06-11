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
pub struct Wireframe3dPipeline {
  shader : String
  wide_bind_group_layout_descriptor : @material.BindGroupLayoutDescriptor
}

///|
pub fn Wireframe3dPipeline::new(
  shader? : String = "pbr/render/wireframe.wgsl",
  wide_bind_group_layout_descriptor? : @material.BindGroupLayoutDescriptor = @material.BindGroupLayoutDescriptor::BindGroupLayoutDescriptor(),
) -> Wireframe3dPipeline {
  Wireframe3dPipeline::{ shader, wide_bind_group_layout_descriptor }
}

///|
pub fn Wireframe3dPipeline::shader(self : Wireframe3dPipeline) -> String {
  self.shader
}

///|
pub fn Wireframe3dPipeline::wide_bind_group_layout_descriptor(
  self : Wireframe3dPipeline,
) -> @material.BindGroupLayoutDescriptor {
  self.wide_bind_group_layout_descriptor
}

///|
pub suberror WireframePipelineSpecializationError {
  MissingDepthStencilState
  MissingFragmentState
}

///|
fn wireframe_shader_def(name : String) -> @material.ShaderDefVal {
  @material.ShaderDefVal::Flag(name)
}

///|
pub fn Wireframe3dPipeline::specialize(
  self : Wireframe3dPipeline,
  key : WireframePipelineKey,
  base_descriptor : @material.RenderPipelineDescriptor,
) -> @material.RenderPipelineDescriptor raise WireframePipelineSpecializationError {
  let mut descriptor = base_descriptor
  let depth_stencil = match descriptor.depth_stencil {
    Some(value) => value
    None => raise MissingDepthStencilState
  }
  descriptor = descriptor.with_depth_stencil(
    Some(
      depth_stencil.with_bias_slope_scale(
        if descriptor.primitive.topology ==
          @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST {
          1.0F
        } else {
          depth_stencil.bias_slope_scale
        },
      ),
    ),
  )
  if key.wide() {
    let fragment = match descriptor.fragment {
      Some(value) => value
      None => raise MissingFragmentState
    }
    let vertex_defs = descriptor.vertex.shader_defs
    vertex_defs.push(wireframe_shader_def("WIREFRAME_WIDE"))
    if key.quads() {
      vertex_defs.push(wireframe_shader_def("WIREFRAME_QUADS"))
    }
    let fragment_defs = fragment.shader_defs
    fragment_defs.push(wireframe_shader_def("WIREFRAME_WIDE"))
    let layout = descriptor.layout
    layout.push(self.wide_bind_group_layout_descriptor)
    descriptor
    .with_label(Some("wireframe_3d_wide_pipeline"))
    .with_layout(layout)
    .with_vertex(
      @material.VertexState::new(
        Some(self.shader),
        vertex_defs,
        Some("vertex"),
        [],
      ),
    )
    .with_fragment(
      Some(
        @material.FragmentState::new(
          Some(self.shader),
          fragment_defs,
          Some("fragment"),
          fragment.targets,
        ),
      ),
    )
    .with_immediate_size(32U)
    .with_primitive(
      descriptor.primitive.with_polygon_mode(
        if key.line_mode() {
          Some(@wgpu.POLYGON_MODE_LINE)
        } else {
          None
        },
      ),
    )
  } else {
    let fragment = match descriptor.fragment {
      Some(value) => value
      None => raise MissingFragmentState
    }
    descriptor
    .with_label(Some("wireframe_3d_pipeline"))
    .with_fragment(Some(fragment.with_shader(Some(self.shader))))
    .with_immediate_size(16U)
    .with_primitive(
      descriptor.primitive.with_polygon_mode(Some(@wgpu.POLYGON_MODE_LINE)),
    )
  }
}
