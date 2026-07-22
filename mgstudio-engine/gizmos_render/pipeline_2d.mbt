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
// Bevy source: `bevy/crates/bevy_gizmos_render/src/pipeline_2d.rs`.

///|
pub struct LineGizmo2dPlugin {}

///|
const LINE_GIZMO_2D_PLUGIN_NAME : String = "mgstudio.gizmos_render.LineGizmo2dPlugin"

///|
#warnings("-unnecessary_annotation")
pub fn LineGizmo2dPlugin::LineGizmo2dPlugin() -> LineGizmo2dPlugin {
  LineGizmo2dPlugin::{  }
}

///|
pub struct LineGizmo2dPipelineKey {
  msaa_samples : UInt
  target_format : UInt
  strip : Bool
  line_style : @gizmos.GizmoLineStyle
}

///|
pub fn LineGizmo2dPipelineKey::new(
  msaa_samples~ : UInt,
  target_format~ : UInt,
  strip~ : Bool,
  line_style~ : @gizmos.GizmoLineStyle,
) -> LineGizmo2dPipelineKey {
  { msaa_samples, target_format, strip, line_style }
}

///|
pub fn LineGizmo2dPipelineKey::strip(self : LineGizmo2dPipelineKey) -> Bool {
  self.strip
}

///|
pub fn LineGizmo2dPipelineKey::line_style(
  self : LineGizmo2dPipelineKey,
) -> @gizmos.GizmoLineStyle {
  self.line_style
}

///|
pub struct LineJointGizmo2dPipelineKey {
  msaa_samples : UInt
  target_format : UInt
  joints : @gizmos.GizmoLineJoint
}

///|
pub fn LineJointGizmo2dPipelineKey::new(
  msaa_samples~ : UInt,
  target_format~ : UInt,
  joints~ : @gizmos.GizmoLineJoint,
) -> LineJointGizmo2dPipelineKey {
  { msaa_samples, target_format, joints }
}

///|
pub fn LineJointGizmo2dPipelineKey::joints(
  self : LineJointGizmo2dPipelineKey,
) -> @gizmos.GizmoLineJoint {
  self.joints
}

///|
pub struct LineGizmoPipelinePlan {
  label : String
  shader_path : String
  fragment_entry_point : String
  vertex_entry_point : String?
  shader_defs : Array[@render.ShaderDefVal]
  vertex_buffer_layouts : Array[@mesh.VertexBufferLayout]
  depth_format : UInt
  depth_write_enabled : Bool
  depth_compare : UInt
  target_format : UInt
  msaa_samples : UInt
  indexed : Bool
}

///|
pub fn LineGizmoPipelinePlan::label(self : LineGizmoPipelinePlan) -> String {
  self.label
}

///|
pub fn LineGizmoPipelinePlan::shader_path(
  self : LineGizmoPipelinePlan,
) -> String {
  self.shader_path
}

///|
pub fn LineGizmoPipelinePlan::fragment_entry_point(
  self : LineGizmoPipelinePlan,
) -> String {
  self.fragment_entry_point
}

///|
pub fn LineGizmoPipelinePlan::vertex_entry_point(
  self : LineGizmoPipelinePlan,
) -> String? {
  self.vertex_entry_point
}

///|
pub fn LineGizmoPipelinePlan::shader_defs(
  self : LineGizmoPipelinePlan,
) -> Array[@render.ShaderDefVal] {
  self.shader_defs
}

///|
pub fn LineGizmoPipelinePlan::vertex_buffer_layouts(
  self : LineGizmoPipelinePlan,
) -> Array[@mesh.VertexBufferLayout] {
  self.vertex_buffer_layouts
}

///|
pub fn LineGizmoPipelinePlan::depth_format(
  self : LineGizmoPipelinePlan,
) -> UInt {
  self.depth_format
}

///|
pub fn LineGizmoPipelinePlan::depth_write_enabled(
  self : LineGizmoPipelinePlan,
) -> Bool {
  self.depth_write_enabled
}

///|
pub fn LineGizmoPipelinePlan::depth_compare(
  self : LineGizmoPipelinePlan,
) -> UInt {
  self.depth_compare
}

///|
pub fn LineGizmoPipelinePlan::target_format(
  self : LineGizmoPipelinePlan,
) -> UInt {
  self.target_format
}

///|
pub fn LineGizmoPipelinePlan::msaa_samples(
  self : LineGizmoPipelinePlan,
) -> UInt {
  self.msaa_samples
}

///|
pub fn LineGizmoPipelinePlan::indexed(self : LineGizmoPipelinePlan) -> Bool {
  self.indexed
}

///|
pub fn line_gizmo_fragment_entry_point(
  line_style : @gizmos.GizmoLineStyle,
) -> String {
  match line_style {
    Solid => "fragment_solid"
    Dotted => "fragment_dotted"
    Dashed(_) => "fragment_dashed"
  }
}

///|
pub fn line_joint_gizmo_vertex_entry_point(
  joints : @gizmos.GizmoLineJoint,
) -> String {
  match joints {
    Miter => "vertex_miter"
    Round(_) => "vertex_round"
    None | Bevel => "vertex_bevel"
  }
}

///|
pub fn line_gizmo_2d_pipeline_plan(
  key : LineGizmo2dPipelineKey,
) -> LineGizmoPipelinePlan {
  {
    label: "LineGizmo Pipeline 2D",
    shader_path: "gizmos_render/lines.wgsl",
    fragment_entry_point: line_gizmo_fragment_entry_point(key.line_style),
    vertex_entry_point: None,
    shader_defs: [],
    vertex_buffer_layouts: line_gizmo_vertex_buffer_layouts(key.strip),
    depth_format: @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
    depth_write_enabled: false,
    depth_compare: @wgpu.COMPARE_FUNCTION_ALWAYS,
    target_format: key.target_format,
    msaa_samples: key.msaa_samples,
    indexed: false,
  }
}

///|
pub fn line_joint_gizmo_2d_pipeline_plan(
  key : LineJointGizmo2dPipelineKey,
) -> LineGizmoPipelinePlan {
  {
    label: "LineJointGizmo Pipeline 2D",
    shader_path: "gizmos_render/line_joints.wgsl",
    fragment_entry_point: "fragment",
    vertex_entry_point: Some(line_joint_gizmo_vertex_entry_point(key.joints)),
    shader_defs: [],
    vertex_buffer_layouts: line_joint_gizmo_vertex_buffer_layouts(),
    depth_format: @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
    depth_write_enabled: false,
    depth_compare: @wgpu.COMPARE_FUNCTION_ALWAYS,
    target_format: key.target_format,
    msaa_samples: key.msaa_samples,
    indexed: false,
  }
}

///|
pub fn line_gizmo_2d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  line_gizmo_2d_plugin_with(app, LineGizmo2dPlugin())
}

///|
pub fn line_gizmo_2d_plugin_with(
  app : @app.App[@ecs.World],
  plugin : LineGizmo2dPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  @sprite_render.sprite_render_plugin(app)
}

///|
pub impl @app.Plugin for LineGizmo2dPlugin with fn name(_self) {
  LINE_GIZMO_2D_PLUGIN_NAME
}

///|
pub impl @app.Plugin for LineGizmo2dPlugin with fn build(self, app) {
  line_gizmo_2d_plugin_with(app, self)
}
