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
// Bevy source: `bevy/crates/bevy_gizmos_render/src/pipeline_3d.rs`.

///|
pub struct LineGizmo3dPlugin {}

///|
const LINE_GIZMO_3D_PLUGIN_NAME : String = "mgstudio.gizmos_render.LineGizmo3dPlugin"

///|
pub fn LineGizmo3dPlugin::LineGizmo3dPlugin() -> LineGizmo3dPlugin {
  LineGizmo3dPlugin::{  }
}

///|
pub struct LineGizmo3dPipelineKey {
  msaa_samples : UInt
  target_format : UInt
  strip : Bool
  perspective : Bool
  line_style : @gizmos.GizmoLineStyle
}

///|
pub fn LineGizmo3dPipelineKey::new(
  msaa_samples~ : UInt,
  target_format~ : UInt,
  strip~ : Bool,
  perspective~ : Bool,
  line_style~ : @gizmos.GizmoLineStyle,
) -> LineGizmo3dPipelineKey {
  LineGizmo3dPipelineKey::{
    msaa_samples,
    target_format,
    strip,
    perspective,
    line_style,
  }
}

///|
pub fn LineGizmo3dPipelineKey::perspective(
  self : LineGizmo3dPipelineKey,
) -> Bool {
  self.perspective
}

///|
pub struct LineJointGizmo3dPipelineKey {
  msaa_samples : UInt
  target_format : UInt
  perspective : Bool
  joints : @gizmos.GizmoLineJoint
}

///|
pub fn LineJointGizmo3dPipelineKey::new(
  msaa_samples~ : UInt,
  target_format~ : UInt,
  perspective~ : Bool,
  joints~ : @gizmos.GizmoLineJoint,
) -> LineJointGizmo3dPipelineKey {
  LineJointGizmo3dPipelineKey::{
    msaa_samples,
    target_format,
    perspective,
    joints,
  }
}

///|
fn line_gizmo_3d_shader_defs(perspective : Bool) -> Array[@render.ShaderDefVal] {
  if perspective {
    [@render.ShaderDefVal::Flag("PERSPECTIVE")]
  } else {
    []
  }
}

///|
pub fn line_gizmo_3d_pipeline_plan(
  key : LineGizmo3dPipelineKey,
) -> LineGizmoPipelinePlan {
  LineGizmoPipelinePlan::{
    label: "LineGizmo 3d Pipeline",
    shader_path: "gizmos_render/lines.wgsl",
    fragment_entry_point: line_gizmo_fragment_entry_point(key.line_style),
    vertex_entry_point: None,
    shader_defs: line_gizmo_3d_shader_defs(key.perspective),
    vertex_buffer_layouts: line_gizmo_vertex_buffer_layouts(key.strip),
    depth_format: @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
    depth_write_enabled: true,
    depth_compare: @wgpu.COMPARE_FUNCTION_GREATER,
    target_format: key.target_format,
    msaa_samples: key.msaa_samples,
    indexed: true,
  }
}

///|
pub fn line_joint_gizmo_3d_pipeline_plan(
  key : LineJointGizmo3dPipelineKey,
) -> LineGizmoPipelinePlan {
  LineGizmoPipelinePlan::{
    label: "LineJointGizmo 3d Pipeline",
    shader_path: "gizmos_render/line_joints.wgsl",
    fragment_entry_point: "fragment",
    vertex_entry_point: Some(line_joint_gizmo_vertex_entry_point(key.joints)),
    shader_defs: line_gizmo_3d_shader_defs(key.perspective),
    vertex_buffer_layouts: line_joint_gizmo_vertex_buffer_layouts(),
    depth_format: @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
    depth_write_enabled: true,
    depth_compare: @wgpu.COMPARE_FUNCTION_GREATER,
    target_format: key.target_format,
    msaa_samples: key.msaa_samples,
    indexed: true,
  }
}

///|
pub fn line_gizmo_3d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  line_gizmo_3d_plugin_with(app, LineGizmo3dPlugin::LineGizmo3dPlugin())
}

///|
pub fn line_gizmo_3d_plugin_with(
  app : @app.App[@ecs.World],
  plugin : LineGizmo3dPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  @pbr.render3d_plugin(app)
}

///|
pub impl @app.Plugin for LineGizmo3dPlugin with fn name(_self) {
  LINE_GIZMO_3D_PLUGIN_NAME
}

///|
pub impl @app.Plugin for LineGizmo3dPlugin with fn build(self, app) {
  line_gizmo_3d_plugin_with(app, self)
}
