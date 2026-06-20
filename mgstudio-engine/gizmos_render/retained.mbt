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
// Bevy source: `bevy/crates/bevy_gizmos_render/src/retained.rs`.

///|
pub struct LineGizmoUniform {
  world_from_local : @math.Affine3
  line_width : Float
  depth_bias : Float
  joints_resolution : Int
  gap_scale : Float
  line_scale : Float
}

///|
pub let ecs_key_line_gizmo_uniform : @ecs.ComponentKey[LineGizmoUniform] = @ecs.register_component(
  debug_name="mgstudio_gizmos_render::LineGizmoUniform",
)

///|
pub impl @ecs.Component for LineGizmoUniform with fn component() {
  ecs_key_line_gizmo_uniform
}

///|
pub fn LineGizmoUniform::world_from_local(
  self : LineGizmoUniform,
) -> @math.Affine3 {
  self.world_from_local
}

///|
pub fn LineGizmoUniform::line_width(self : LineGizmoUniform) -> Float {
  self.line_width
}

///|
pub fn LineGizmoUniform::depth_bias(self : LineGizmoUniform) -> Float {
  self.depth_bias
}

///|
pub fn LineGizmoUniform::joints_resolution(self : LineGizmoUniform) -> Int {
  self.joints_resolution
}

///|
pub fn LineGizmoUniform::gap_scale(self : LineGizmoUniform) -> Float {
  self.gap_scale
}

///|
pub fn LineGizmoUniform::line_scale(self : LineGizmoUniform) -> Float {
  self.line_scale
}

///|
pub struct RetainedLineGizmo {
  entity : @core.Entity
}

///|
pub fn RetainedLineGizmo::new(entity : @core.Entity) -> RetainedLineGizmo {
  RetainedLineGizmo::{ entity, }
}

///|
priv struct ExtractedLineGizmo {
  uniform : LineGizmoUniform
  mesh_config : @gizmos.GizmoMeshConfig
  main_entity : @render.MainEntity
}

///|
fn retained_line_joints_resolution(joints : @sprite.GizmoLineJoint) -> Int {
  match joints {
    Round(resolution) => resolution
    _ => 0
  }
}

///|
fn retained_line_style_parts(style : @sprite.GizmoLineStyle) -> (Float, Float) {
  match style {
    Dashed(gap_scale~, line_scale~) => {
      if gap_scale <= 0.0F {
        @app.log_warn_once(
          "gizmos_render.retained.dashed_gap_scale", "When using gizmos with the line style `GizmoLineStyle::Dashed{..}` the gap scale should be greater than zero.",
        )
      }
      if line_scale <= 0.0F {
        @app.log_warn_once(
          "gizmos_render.retained.dashed_line_scale", "When using gizmos with the line style `GizmoLineStyle::Dashed{..}` the line scale should be greater than zero.",
        )
      }
      (gap_scale, line_scale)
    }
    _ => (1.0F, 1.0F)
  }
}

///|
fn line_gizmo_render_config(
  uniform : LineGizmoUniform,
  mesh_config : @gizmos.GizmoMeshConfig,
) -> @sprite.GizmoConfig {
  {
    enabled: true,
    line: {
      width: uniform.line_width,
      perspective: mesh_config.line_perspective(),
      style: mesh_config.line_style(),
      joints: mesh_config.line_joints(),
    },
    depth_bias: uniform.depth_bias,
    render_layers: mesh_config.render_layers(),
  }
}

///|
fn queue_line_gizmo_list_3d(
  world_from_local : @math.Affine3,
  config : @sprite.GizmoConfig,
  positions : Array[@math.Vec3],
  colors : Array[@color.LinearRgba],
) -> Int {
  let mut queued = 0
  let pair_count = positions.length() / 2
  for pair in 0..<pair_count {
    let start_index = pair * 2
    let end_index = start_index + 1
    @sprite.gizmos_push_retained_line_3d(
      config,
      world_from_local.transform_point3(positions[start_index]),
      world_from_local.transform_point3(positions[end_index]),
      colors[start_index],
      colors[end_index],
    )
    queued = queued + 1
  }
  queued
}

///|
fn queue_line_gizmo_strip_3d(
  world_from_local : @math.Affine3,
  config : @sprite.GizmoConfig,
  positions : Array[@math.Vec3],
  colors : Array[@color.LinearRgba],
) -> Int {
  if positions.length() < 2 {
    return 0
  }
  let mut queued = 0
  for index in 0..<(positions.length() - 1) {
    @sprite.gizmos_push_retained_line_3d(
      config,
      world_from_local.transform_point3(positions[index]),
      world_from_local.transform_point3(positions[index + 1]),
      colors[index],
      colors[index + 1],
    )
    queued = queued + 1
  }
  queued
}

///|
fn line_gizmo_vec2(point : @math.Vec3) -> @math.Vec2 {
  @math.Vec2::new(point.x, point.y)
}

///|
fn queue_line_gizmo_list_2d(
  world_from_local : @math.Affine3,
  config : @sprite.GizmoConfig,
  positions : Array[@math.Vec3],
  colors : Array[@color.LinearRgba],
) -> Int {
  let mut queued = 0
  let pair_count = positions.length() / 2
  for pair in 0..<pair_count {
    let start_index = pair * 2
    let end_index = start_index + 1
    @sprite.gizmos_push_retained_line_2d(
      config,
      line_gizmo_vec2(world_from_local.transform_point3(positions[start_index])),
      line_gizmo_vec2(world_from_local.transform_point3(positions[end_index])),
      colors[start_index],
      colors[end_index],
    )
    queued = queued + 1
  }
  queued
}

///|
fn queue_line_gizmo_strip_2d(
  world_from_local : @math.Affine3,
  config : @sprite.GizmoConfig,
  positions : Array[@math.Vec3],
  colors : Array[@color.LinearRgba],
) -> Int {
  if positions.length() < 2 {
    return 0
  }
  let mut queued = 0
  for index in 0..<(positions.length() - 1) {
    @sprite.gizmos_push_retained_line_2d(
      config,
      line_gizmo_vec2(world_from_local.transform_point3(positions[index])),
      line_gizmo_vec2(world_from_local.transform_point3(positions[index + 1])),
      colors[index],
      colors[index + 1],
    )
    queued = queued + 1
  }
  queued
}

///|
fn line_gizmo_assets(
  render_world : @ecs.World,
) -> @asset.Assets[@gizmos.GizmoAsset]? {
  let source_world = @render.render_source_world(render_world)
  let assets_key : @ecs.ResourceKey[@asset.Assets[@gizmos.GizmoAsset]] = @asset.assets_resource_key()
  source_world.get_resource(assets_key)
}

///|
pub fn queue_line_gizmos_3d(render_world : @ecs.World) -> Int {
  guard line_gizmo_assets(render_world) is Some(gizmo_assets) else { return 0 }
  let query : @ecs.Query[
    (@ecs.Read[LineGizmoUniform], @ecs.Read[@gizmos.GizmoMeshConfig]),
    @ecs.All,
  ] = @ecs.query(render_world)
  let mut queued = 0
  try! query.view(fn(_entity, data) {
    let (uniform_comp, mesh_config_comp) = data
    let uniform = uniform_comp.value()
    let mesh_config = mesh_config_comp.value()
    guard gizmo_assets.get(mesh_config.handle()) is Some(gizmo_asset) else {
      return
    }
    let config = line_gizmo_render_config(uniform, mesh_config)
    let buffer = gizmo_asset.buffer()
    queued = queued +
      queue_line_gizmo_list_3d(
        uniform.world_from_local(),
        config,
        buffer.list_positions(),
        buffer.list_colors(),
      )
    queued = queued +
      queue_line_gizmo_strip_3d(
        uniform.world_from_local(),
        config,
        buffer.strip_positions(),
        buffer.strip_colors(),
      )
  })
  queued
}

///|
pub fn queue_line_gizmos_2d(render_world : @ecs.World) -> Int {
  guard line_gizmo_assets(render_world) is Some(gizmo_assets) else { return 0 }
  let query : @ecs.Query[
    (@ecs.Read[LineGizmoUniform], @ecs.Read[@gizmos.GizmoMeshConfig]),
    @ecs.All,
  ] = @ecs.query(render_world)
  let mut queued = 0
  try! query.view(fn(_entity, data) {
    let (uniform_comp, mesh_config_comp) = data
    let uniform = uniform_comp.value()
    let mesh_config = mesh_config_comp.value()
    guard gizmo_assets.get(mesh_config.handle()) is Some(gizmo_asset) else {
      return
    }
    let config = line_gizmo_render_config(uniform, mesh_config)
    let buffer = gizmo_asset.buffer()
    queued = queued +
      queue_line_gizmo_list_2d(
        uniform.world_from_local(),
        config,
        buffer.list_positions(),
        buffer.list_colors(),
      )
    queued = queued +
      queue_line_gizmo_strip_2d(
        uniform.world_from_local(),
        config,
        buffer.strip_positions(),
        buffer.strip_colors(),
      )
  })
  queued
}

///|
pub fn extract_line_gizmos(render_world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(render_world)
  let query : @ecs.Query[
    (
      @ecs.Read[@gizmos.Gizmo],
      @ecs.Read[@transform.GlobalTransform],
      @ecs.Read[@camera_render_layers.RenderLayers]?,
    ),
    @ecs.All,
  ] = @ecs.query(source_world)
  let values : Array[ExtractedLineGizmo] = []
  try! query.view(fn(entity, data) {
    let (gizmo_comp, transform_comp, render_layers_comp) = data
    let gizmo = gizmo_comp.value()
    let line_config = gizmo.line_config
    let (gap_scale, line_scale) = retained_line_style_parts(line_config.style)
    let render_layers = match render_layers_comp {
      Some(layers_comp) => layers_comp.value()
      None => @camera_render_layers.RenderLayers::RenderLayers()
    }
    values.push(ExtractedLineGizmo::{
      uniform: LineGizmoUniform::{
        world_from_local: transform_comp.value().affine(),
        line_width: line_config.width,
        depth_bias: gizmo.depth_bias,
        joints_resolution: retained_line_joints_resolution(line_config.joints),
        gap_scale,
        line_scale,
      },
      mesh_config: @gizmos.GizmoMeshConfig::new(
        line_perspective=line_config.perspective,
        line_style=line_config.style,
        line_joints=line_config.joints,
        render_layers~,
        handle=gizmo.handle,
      ),
      main_entity: @render.MainEntity::new(entity),
    })
  })
  for value in values {
    let render_entity = render_world.spawn()
    try! render_world.set(render_entity, value.uniform)
    try! render_world.set(render_entity, value.mesh_config)
    try! render_world.set(render_entity, value.main_entity)
    try! render_world.set(
      render_entity,
      @render.TemporaryRenderEntity::TemporaryRenderEntity(),
    )
  }
}
