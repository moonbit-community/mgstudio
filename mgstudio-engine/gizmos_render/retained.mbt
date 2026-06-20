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
let gpu_line_gizmo_render_asset_resource_keys : @render.RenderAssetResourceKeys[
  GpuLineGizmo,
] = @render.register_render_asset_resource_keys(
  "mgstudio_gizmos_render::GpuLineGizmo",
)

///|
pub impl @render.RenderAssetResource for GpuLineGizmo with fn render_asset_resource_debug_name() {
  "mgstudio_gizmos_render::GpuLineGizmo"
}

///|
pub impl @render.RenderAssetResource for GpuLineGizmo with fn render_asset_resource_keys() {
  gpu_line_gizmo_render_asset_resource_keys
}

///|
pub struct GpuLineGizmo {
  list_position_buffer : @wgpu.Buffer
  list_color_buffer : @wgpu.Buffer
  list_vertex_count : Int
  strip_position_buffer : @wgpu.Buffer
  strip_color_buffer : @wgpu.Buffer
  strip_vertex_count : Int
}

///|
pub fn GpuLineGizmo::list_position_buffer(self : GpuLineGizmo) -> @wgpu.Buffer {
  self.list_position_buffer
}

///|
pub fn GpuLineGizmo::list_color_buffer(self : GpuLineGizmo) -> @wgpu.Buffer {
  self.list_color_buffer
}

///|
pub fn GpuLineGizmo::list_vertex_count(self : GpuLineGizmo) -> Int {
  self.list_vertex_count
}

///|
pub fn GpuLineGizmo::strip_position_buffer(self : GpuLineGizmo) -> @wgpu.Buffer {
  self.strip_position_buffer
}

///|
pub fn GpuLineGizmo::strip_color_buffer(self : GpuLineGizmo) -> @wgpu.Buffer {
  self.strip_color_buffer
}

///|
pub fn GpuLineGizmo::strip_vertex_count(self : GpuLineGizmo) -> Int {
  self.strip_vertex_count
}

///|
pub fn GpuLineGizmo::release(self : GpuLineGizmo) -> Unit {
  self.list_position_buffer.release()
  self.list_color_buffer.release()
  self.strip_position_buffer.release()
  self.strip_color_buffer.release()
}

///|
const LINE_GIZMO_VEC3_SIZE_BYTES : Int = 12

///|
const LINE_GIZMO_RGBA_SIZE_BYTES : Int = 16

///|
pub const LINE_GIZMO_UNIFORM_SIZE_BYTES : Int = 80

///|
fn line_gizmo_f32_bits(value : Float) -> UInt {
  value.reinterpret_as_uint()
}

///|
fn line_gizmo_push_u32_le(out : Array[Byte], value : UInt) -> Unit {
  out.push((value & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 8) & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 16) & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 24) & 0xFFU).reinterpret_as_int().to_byte())
}

///|
fn line_gizmo_push_f32_le(out : Array[Byte], value : Float) -> Unit {
  line_gizmo_push_u32_le(out, line_gizmo_f32_bits(value))
}

///|
pub fn line_gizmo_uniform_bytes(uniform : LineGizmoUniform) -> Bytes {
  let world_from_local = uniform.world_from_local
  let translation = world_from_local.transform_point3(@math.Vec3::zero())
  let x_axis = world_from_local
    .transform_point3(@math.Vec3::new(1.0F, 0.0F, 0.0F))
    .sub(translation)
  let y_axis = world_from_local
    .transform_point3(@math.Vec3::new(0.0F, 1.0F, 0.0F))
    .sub(translation)
  let z_axis = world_from_local
    .transform_point3(@math.Vec3::new(0.0F, 0.0F, 1.0F))
    .sub(translation)
  let out : Array[Byte] = []
  line_gizmo_push_f32_le(out, x_axis.x)
  line_gizmo_push_f32_le(out, y_axis.x)
  line_gizmo_push_f32_le(out, z_axis.x)
  line_gizmo_push_f32_le(out, translation.x)
  line_gizmo_push_f32_le(out, x_axis.y)
  line_gizmo_push_f32_le(out, y_axis.y)
  line_gizmo_push_f32_le(out, z_axis.y)
  line_gizmo_push_f32_le(out, translation.y)
  line_gizmo_push_f32_le(out, x_axis.z)
  line_gizmo_push_f32_le(out, y_axis.z)
  line_gizmo_push_f32_le(out, z_axis.z)
  line_gizmo_push_f32_le(out, translation.z)
  line_gizmo_push_f32_le(out, uniform.line_width)
  line_gizmo_push_f32_le(out, uniform.depth_bias)
  line_gizmo_push_u32_le(out, uniform.joints_resolution.reinterpret_as_uint())
  line_gizmo_push_f32_le(out, uniform.gap_scale)
  line_gizmo_push_f32_le(out, uniform.line_scale)
  line_gizmo_push_u32_le(out, 0U)
  line_gizmo_push_u32_le(out, 0U)
  line_gizmo_push_u32_le(out, 0U)
  Bytes::from_array(out)
}

///|
pub fn line_gizmo_vertex_buffer_layouts(
  strip : Bool,
) -> Array[@mesh.VertexBufferLayout] {
  let position_layout = @mesh.VertexBufferLayout::new(
    array_stride=LINE_GIZMO_VEC3_SIZE_BYTES,
    step_mode=@mesh.MeshVertexStepMode::Instance,
    attributes=[
      @mesh.VertexAttribute::new(
        offset=0,
        format=@mesh.MeshVertexFormat::Float32x3,
        shader_location=0,
      ),
    ],
  )
  let color_layout = @mesh.VertexBufferLayout::new(
    array_stride=LINE_GIZMO_RGBA_SIZE_BYTES,
    step_mode=@mesh.MeshVertexStepMode::Instance,
    attributes=[
      @mesh.VertexAttribute::new(
        offset=0,
        format=@mesh.MeshVertexFormat::Float32x4,
        shader_location=2,
      ),
    ],
  )
  if strip {
    [
      position_layout,
      @mesh.VertexBufferLayout::new(
        array_stride=LINE_GIZMO_VEC3_SIZE_BYTES,
        step_mode=@mesh.MeshVertexStepMode::Instance,
        attributes=[
          @mesh.VertexAttribute::new(
            offset=0,
            format=@mesh.MeshVertexFormat::Float32x3,
            shader_location=1,
          ),
        ],
      ),
      color_layout,
      @mesh.VertexBufferLayout::new(
        array_stride=LINE_GIZMO_RGBA_SIZE_BYTES,
        step_mode=@mesh.MeshVertexStepMode::Instance,
        attributes=[
          @mesh.VertexAttribute::new(
            offset=0,
            format=@mesh.MeshVertexFormat::Float32x4,
            shader_location=3,
          ),
        ],
      ),
    ]
  } else {
    [
      @mesh.VertexBufferLayout::new(
        array_stride=LINE_GIZMO_VEC3_SIZE_BYTES * 2,
        step_mode=@mesh.MeshVertexStepMode::Instance,
        attributes=[
          @mesh.VertexAttribute::new(
            offset=0,
            format=@mesh.MeshVertexFormat::Float32x3,
            shader_location=0,
          ),
          @mesh.VertexAttribute::new(
            offset=LINE_GIZMO_VEC3_SIZE_BYTES,
            format=@mesh.MeshVertexFormat::Float32x3,
            shader_location=1,
          ),
        ],
      ),
      @mesh.VertexBufferLayout::new(
        array_stride=LINE_GIZMO_RGBA_SIZE_BYTES * 2,
        step_mode=@mesh.MeshVertexStepMode::Instance,
        attributes=[
          @mesh.VertexAttribute::new(
            offset=0,
            format=@mesh.MeshVertexFormat::Float32x4,
            shader_location=2,
          ),
          @mesh.VertexAttribute::new(
            offset=LINE_GIZMO_RGBA_SIZE_BYTES,
            format=@mesh.MeshVertexFormat::Float32x4,
            shader_location=3,
          ),
        ],
      ),
    ]
  }
}

///|
pub fn line_joint_gizmo_vertex_buffer_layouts() -> Array[
  @mesh.VertexBufferLayout,
] {
  [
    @mesh.VertexBufferLayout::new(
      array_stride=LINE_GIZMO_VEC3_SIZE_BYTES,
      step_mode=@mesh.MeshVertexStepMode::Instance,
      attributes=[
        @mesh.VertexAttribute::new(
          offset=0,
          format=@mesh.MeshVertexFormat::Float32x3,
          shader_location=0,
        ),
      ],
    ),
    @mesh.VertexBufferLayout::new(
      array_stride=LINE_GIZMO_VEC3_SIZE_BYTES,
      step_mode=@mesh.MeshVertexStepMode::Instance,
      attributes=[
        @mesh.VertexAttribute::new(
          offset=0,
          format=@mesh.MeshVertexFormat::Float32x3,
          shader_location=1,
        ),
      ],
    ),
    @mesh.VertexBufferLayout::new(
      array_stride=LINE_GIZMO_VEC3_SIZE_BYTES,
      step_mode=@mesh.MeshVertexStepMode::Instance,
      attributes=[
        @mesh.VertexAttribute::new(
          offset=0,
          format=@mesh.MeshVertexFormat::Float32x3,
          shader_location=2,
        ),
      ],
    ),
    @mesh.VertexBufferLayout::new(
      array_stride=LINE_GIZMO_RGBA_SIZE_BYTES,
      step_mode=@mesh.MeshVertexStepMode::Instance,
      attributes=[
        @mesh.VertexAttribute::new(
          offset=0,
          format=@mesh.MeshVertexFormat::Float32x4,
          shader_location=3,
        ),
      ],
    ),
  ]
}

///|
fn line_gizmo_vertex_buffer_usage() -> @wgpu.BufferUsage {
  @wgpu.BufferUsage::from_u64(
    @wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST,
  )
}

///|
pub fn line_gizmo_position_bytes(positions : Array[@math.Vec3]) -> Bytes {
  let out = Buffer::Buffer(
    size_hint=positions.length() * LINE_GIZMO_VEC3_SIZE_BYTES,
  )
  for position in positions {
    out.write_float_le(position.x)
    out.write_float_le(position.y)
    out.write_float_le(position.z)
  }
  out.to_bytes()
}

///|
pub fn line_gizmo_color_bytes(colors : Array[@color.LinearRgba]) -> Bytes {
  let out = Buffer::Buffer(
    size_hint=colors.length() * LINE_GIZMO_RGBA_SIZE_BYTES,
  )
  for color in colors {
    let (r, g, b, a) = color.to_linear_rgba_tuple()
    out.write_float_le(r)
    out.write_float_le(g)
    out.write_float_le(b)
    out.write_float_le(a)
  }
  out.to_bytes()
}

///|
pub fn prepare_gpu_line_gizmo(
  device : @wgpu.Device,
  gizmo : @gizmos.GizmoAsset,
) -> GpuLineGizmo {
  let buffer = gizmo.buffer()
  let usage = line_gizmo_vertex_buffer_usage()
  GpuLineGizmo::{
    list_position_buffer: device.create_buffer_init(
      usage~,
      line_gizmo_position_bytes(buffer.list_positions()),
    ),
    list_color_buffer: device.create_buffer_init(
      usage~,
      line_gizmo_color_bytes(buffer.list_colors()),
    ),
    list_vertex_count: buffer.list_positions().length(),
    strip_position_buffer: device.create_buffer_init(
      usage~,
      line_gizmo_position_bytes(buffer.strip_positions()),
    ),
    strip_color_buffer: device.create_buffer_init(
      usage~,
      line_gizmo_color_bytes(buffer.strip_colors()),
    ),
    strip_vertex_count: buffer.strip_positions().length(),
  }
}

///|
pub(all) enum LineGizmoRenderDimension {
  Dim2
  Dim3
} derive(Eq, Debug)

///|
pub(all) enum LineGizmoPhaseKind {
  LineList
  LineStrip
  LineJoint
} derive(Eq, Debug)

///|
pub struct LineGizmoPhasePipelineKey {
  dimension : LineGizmoRenderDimension
  kind : LineGizmoPhaseKind
  perspective : Bool
  line_style : @gizmos.GizmoLineStyle
  line_joints : @gizmos.GizmoLineJoint
}

///|
pub fn LineGizmoPhasePipelineKey::new(
  dimension : LineGizmoRenderDimension,
  kind : LineGizmoPhaseKind,
  perspective : Bool,
  line_style : @gizmos.GizmoLineStyle,
  line_joints : @gizmos.GizmoLineJoint,
) -> LineGizmoPhasePipelineKey {
  LineGizmoPhasePipelineKey::{
    dimension,
    kind,
    perspective,
    line_style,
    line_joints,
  }
}

///|
pub fn LineGizmoPhasePipelineKey::dimension(
  self : LineGizmoPhasePipelineKey,
) -> LineGizmoRenderDimension {
  self.dimension
}

///|
pub fn LineGizmoPhasePipelineKey::kind(
  self : LineGizmoPhasePipelineKey,
) -> LineGizmoPhaseKind {
  self.kind
}

///|
pub fn LineGizmoPhasePipelineKey::perspective(
  self : LineGizmoPhasePipelineKey,
) -> Bool {
  self.perspective
}

///|
pub fn LineGizmoPhasePipelineKey::line_style(
  self : LineGizmoPhasePipelineKey,
) -> @gizmos.GizmoLineStyle {
  self.line_style
}

///|
pub fn LineGizmoPhasePipelineKey::line_joints(
  self : LineGizmoPhasePipelineKey,
) -> @gizmos.GizmoLineJoint {
  self.line_joints
}

///|
pub struct LineGizmoPhaseItem {
  render_entity : @core.Entity
  main_entity : @render.MainEntity
  renderer_entity : @render.MainEntity
  handle_id : Int
  draw_function : @material.DrawFunctionId
  pipeline_key : LineGizmoPhasePipelineKey
  batch_start : Int
  batch_end : Int
  indexed : Bool
}

///|
pub fn LineGizmoPhaseItem::render_entity(
  self : LineGizmoPhaseItem,
) -> @core.Entity {
  self.render_entity
}

///|
pub fn LineGizmoPhaseItem::main_entity(
  self : LineGizmoPhaseItem,
) -> @render.MainEntity {
  self.main_entity
}

///|
pub fn LineGizmoPhaseItem::renderer_entity(
  self : LineGizmoPhaseItem,
) -> @render.MainEntity {
  self.renderer_entity
}

///|
pub fn LineGizmoPhaseItem::handle_id(self : LineGizmoPhaseItem) -> Int {
  self.handle_id
}

///|
pub fn LineGizmoPhaseItem::draw_function(
  self : LineGizmoPhaseItem,
) -> @material.DrawFunctionId {
  self.draw_function
}

///|
pub fn LineGizmoPhaseItem::pipeline_key(
  self : LineGizmoPhaseItem,
) -> LineGizmoPhasePipelineKey {
  self.pipeline_key
}

///|
pub fn LineGizmoPhaseItem::batch_range(self : LineGizmoPhaseItem) -> (Int, Int) {
  (self.batch_start, self.batch_end)
}

///|
pub fn LineGizmoPhaseItem::indexed(self : LineGizmoPhaseItem) -> Bool {
  self.indexed
}

///|
pub struct LineGizmoPhaseItems {
  items : Array[LineGizmoPhaseItem]
}

///|
pub fn LineGizmoPhaseItems::LineGizmoPhaseItems() -> LineGizmoPhaseItems {
  LineGizmoPhaseItems::{ items: [] }
}

///|
pub let ecs_res_key_line_gizmo_phase_items : @ecs.ResourceKey[
  LineGizmoPhaseItems,
] = @ecs.register_resource(
  debug_name="mgstudio_gizmos_render::LineGizmoPhaseItems",
)

///|
pub impl @app.Resource for LineGizmoPhaseItems with fn resource() {
  ecs_res_key_line_gizmo_phase_items
}

///|
pub fn LineGizmoPhaseItems::clear(self : LineGizmoPhaseItems) -> Unit {
  self.items.clear()
}

///|
pub fn LineGizmoPhaseItems::push(
  self : LineGizmoPhaseItems,
  item : LineGizmoPhaseItem,
) -> Unit {
  self.items.push(item)
}

///|
pub fn LineGizmoPhaseItems::len(self : LineGizmoPhaseItems) -> Int {
  self.items.length()
}

///|
pub fn LineGizmoPhaseItems::items(
  self : LineGizmoPhaseItems,
) -> Array[LineGizmoPhaseItem] {
  self.items.copy()
}

///|
pub struct LineGizmoEntities {
  line_gizmo_renderer : @render.MainEntity
  line_strip_gizmo_renderer : @render.MainEntity
  line_joint_gizmo_renderer : @render.MainEntity
}

///|
pub fn LineGizmoEntities::new(
  line_gizmo_renderer : @render.MainEntity,
  line_strip_gizmo_renderer : @render.MainEntity,
  line_joint_gizmo_renderer : @render.MainEntity,
) -> LineGizmoEntities {
  LineGizmoEntities::{
    line_gizmo_renderer,
    line_strip_gizmo_renderer,
    line_joint_gizmo_renderer,
  }
}

///|
pub fn LineGizmoEntities::line_gizmo_renderer(
  self : LineGizmoEntities,
) -> @render.MainEntity {
  self.line_gizmo_renderer
}

///|
pub fn LineGizmoEntities::line_strip_gizmo_renderer(
  self : LineGizmoEntities,
) -> @render.MainEntity {
  self.line_strip_gizmo_renderer
}

///|
pub fn LineGizmoEntities::line_joint_gizmo_renderer(
  self : LineGizmoEntities,
) -> @render.MainEntity {
  self.line_joint_gizmo_renderer
}

///|
pub let ecs_res_key_line_gizmo_entities : @ecs.ResourceKey[LineGizmoEntities] = @ecs.register_resource(
  debug_name="mgstudio_gizmos_render::LineGizmoEntities",
)

///|
pub impl @app.Resource for LineGizmoEntities with fn resource() {
  ecs_res_key_line_gizmo_entities
}

///|
pub fn ensure_line_gizmo_entities(world : @ecs.World) -> LineGizmoEntities {
  match world.get_resource(ecs_res_key_line_gizmo_entities) {
    Some(entities) => entities
    None => {
      let entities = LineGizmoEntities::new(
        @render.MainEntity::new(world.spawn()),
        @render.MainEntity::new(world.spawn()),
        @render.MainEntity::new(world.spawn()),
      )
      world.insert_resource(ecs_res_key_line_gizmo_entities, entities)
      entities
    }
  }
}

///|
pub struct LineGizmoDrawFunctions {
  draw_functions : @material.DrawFunctions
  line_gizmo_2d : @material.DrawFunctionId
  line_strip_gizmo_2d : @material.DrawFunctionId
  line_joint_gizmo_2d : @material.DrawFunctionId
  line_gizmo_3d : @material.DrawFunctionId
  line_strip_gizmo_3d : @material.DrawFunctionId
  line_joint_gizmo_3d : @material.DrawFunctionId
}

///|
pub fn LineGizmoDrawFunctions::LineGizmoDrawFunctions() -> LineGizmoDrawFunctions {
  let draw_functions = @material.DrawFunctions::new()
  let line_gizmo_2d = draw_functions.register("DrawLineGizmo2d")
  let line_strip_gizmo_2d = draw_functions.register("DrawLineGizmo2dStrip")
  let line_joint_gizmo_2d = draw_functions.register("DrawLineJointGizmo2d")
  let line_gizmo_3d = draw_functions.register("DrawLineGizmo3d")
  let line_strip_gizmo_3d = draw_functions.register("DrawLineGizmo3dStrip")
  let line_joint_gizmo_3d = draw_functions.register("DrawLineJointGizmo3d")
  LineGizmoDrawFunctions::{
    draw_functions,
    line_gizmo_2d,
    line_strip_gizmo_2d,
    line_joint_gizmo_2d,
    line_gizmo_3d,
    line_strip_gizmo_3d,
    line_joint_gizmo_3d,
  }
}

///|
pub let ecs_res_key_line_gizmo_draw_functions : @ecs.ResourceKey[
  LineGizmoDrawFunctions,
] = @ecs.register_resource(
  debug_name="mgstudio_gizmos_render::DrawFunctions<LineGizmo>",
)

///|
pub impl @app.Resource for LineGizmoDrawFunctions with fn resource() {
  ecs_res_key_line_gizmo_draw_functions
}

///|
pub fn LineGizmoDrawFunctions::line_gizmo_2d(
  self : LineGizmoDrawFunctions,
) -> @material.DrawFunctionId {
  self.line_gizmo_2d
}

///|
pub fn LineGizmoDrawFunctions::line_strip_gizmo_2d(
  self : LineGizmoDrawFunctions,
) -> @material.DrawFunctionId {
  self.line_strip_gizmo_2d
}

///|
pub fn LineGizmoDrawFunctions::line_joint_gizmo_2d(
  self : LineGizmoDrawFunctions,
) -> @material.DrawFunctionId {
  self.line_joint_gizmo_2d
}

///|
pub fn LineGizmoDrawFunctions::line_gizmo_3d(
  self : LineGizmoDrawFunctions,
) -> @material.DrawFunctionId {
  self.line_gizmo_3d
}

///|
pub fn LineGizmoDrawFunctions::line_strip_gizmo_3d(
  self : LineGizmoDrawFunctions,
) -> @material.DrawFunctionId {
  self.line_strip_gizmo_3d
}

///|
pub fn LineGizmoDrawFunctions::line_joint_gizmo_3d(
  self : LineGizmoDrawFunctions,
) -> @material.DrawFunctionId {
  self.line_joint_gizmo_3d
}

///|
pub fn LineGizmoDrawFunctions::len(self : LineGizmoDrawFunctions) -> Int {
  self.draw_functions.len()
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
fn gpu_line_gizmo_assets(
  render_world : @ecs.World,
) -> @render.RenderAssets[GpuLineGizmo]? {
  let key : @ecs.ResourceKey[@render.RenderAssets[GpuLineGizmo]] = @render.RenderAssets::resource()
  render_world.get_resource(key)
}

///|
pub fn ensure_line_gizmo_phase_items(world : @ecs.World) -> LineGizmoPhaseItems {
  match world.get_resource(ecs_res_key_line_gizmo_phase_items) {
    Some(items) => items
    None => {
      let items = LineGizmoPhaseItems::LineGizmoPhaseItems()
      world.insert_resource(ecs_res_key_line_gizmo_phase_items, items)
      items
    }
  }
}

///|
pub fn ensure_line_gizmo_draw_functions(
  world : @ecs.World,
) -> LineGizmoDrawFunctions {
  match world.get_resource(ecs_res_key_line_gizmo_draw_functions) {
    Some(functions) => functions
    None => {
      let functions = LineGizmoDrawFunctions::LineGizmoDrawFunctions()
      world.insert_resource(ecs_res_key_line_gizmo_draw_functions, functions)
      functions
    }
  }
}

///|
pub fn line_gizmo_phase_items_for_counts(
  render_entity : @core.Entity,
  main_entity : @render.MainEntity,
  line_gizmo_entities : LineGizmoEntities,
  draw_functions : LineGizmoDrawFunctions,
  dimension : LineGizmoRenderDimension,
  mesh_config : @gizmos.GizmoMeshConfig,
  list_vertex_count : Int,
  strip_vertex_count : Int,
) -> Array[LineGizmoPhaseItem] {
  let items : Array[LineGizmoPhaseItem] = []
  let (line_draw, strip_draw, joint_draw, indexed) = match dimension {
    Dim2 =>
      (
        draw_functions.line_gizmo_2d(),
        draw_functions.line_strip_gizmo_2d(),
        draw_functions.line_joint_gizmo_2d(),
        false,
      )
    Dim3 =>
      (
        draw_functions.line_gizmo_3d(),
        draw_functions.line_strip_gizmo_3d(),
        draw_functions.line_joint_gizmo_3d(),
        true,
      )
  }
  if list_vertex_count > 0 {
    items.push(LineGizmoPhaseItem::{
      render_entity,
      main_entity,
      renderer_entity: line_gizmo_entities.line_gizmo_renderer(),
      handle_id: mesh_config.handle().id(),
      draw_function: line_draw,
      pipeline_key: LineGizmoPhasePipelineKey::new(
        dimension,
        LineList,
        mesh_config.line_perspective(),
        mesh_config.line_style(),
        mesh_config.line_joints(),
      ),
      batch_start: 0,
      batch_end: 1,
      indexed,
    })
  }
  if strip_vertex_count >= 2 {
    items.push(LineGizmoPhaseItem::{
      render_entity,
      main_entity,
      renderer_entity: line_gizmo_entities.line_strip_gizmo_renderer(),
      handle_id: mesh_config.handle().id(),
      draw_function: strip_draw,
      pipeline_key: LineGizmoPhasePipelineKey::new(
        dimension,
        LineStrip,
        mesh_config.line_perspective(),
        mesh_config.line_style(),
        mesh_config.line_joints(),
      ),
      batch_start: 0,
      batch_end: 1,
      indexed,
    })
  }
  if strip_vertex_count >= 3 &&
    !(mesh_config.line_joints() is @gizmos.GizmoLineJoint::None) {
    items.push(LineGizmoPhaseItem::{
      render_entity,
      main_entity,
      renderer_entity: line_gizmo_entities.line_joint_gizmo_renderer(),
      handle_id: mesh_config.handle().id(),
      draw_function: joint_draw,
      pipeline_key: LineGizmoPhasePipelineKey::new(
        dimension,
        LineJoint,
        mesh_config.line_perspective(),
        mesh_config.line_style(),
        mesh_config.line_joints(),
      ),
      batch_start: 0,
      batch_end: 1,
      indexed,
    })
  }
  items
}

///|
fn queue_line_gizmo_phase_items(
  render_world : @ecs.World,
  dimension : LineGizmoRenderDimension,
) -> Int {
  guard gpu_line_gizmo_assets(render_world) is Some(gpu_line_gizmos) else {
    return 0
  }
  let phase_items = ensure_line_gizmo_phase_items(render_world)
  phase_items.clear()
  let line_gizmo_entities = ensure_line_gizmo_entities(render_world)
  let draw_functions = ensure_line_gizmo_draw_functions(render_world)
  let query : @ecs.Query[
    (
      @ecs.Read[LineGizmoUniform],
      @ecs.Read[@gizmos.GizmoMeshConfig],
      @ecs.Read[@render.MainEntity],
    ),
    @ecs.All,
  ] = @ecs.query(render_world)
  let mut queued = 0
  try! query.view(fn(render_entity, data) {
    let (_uniform_comp, mesh_config_comp, main_entity_comp) = data
    let mesh_config = mesh_config_comp.value()
    guard gpu_line_gizmos.get(mesh_config.handle().id()) is Some(gpu_line_gizmo) else {
      return
    }
    let items = line_gizmo_phase_items_for_counts(
      render_entity,
      main_entity_comp.value(),
      line_gizmo_entities,
      draw_functions,
      dimension,
      mesh_config,
      gpu_line_gizmo.list_vertex_count(),
      gpu_line_gizmo.strip_vertex_count(),
    )
    for item in items {
      phase_items.push(item)
      queued = queued + 1
    }
  })
  queued
}

///|
pub fn queue_line_gizmo_phase_items_3d(render_world : @ecs.World) -> Int {
  queue_line_gizmo_phase_items(render_world, Dim3)
}

///|
pub fn queue_line_gizmo_phase_items_2d(render_world : @ecs.World) -> Int {
  queue_line_gizmo_phase_items(render_world, Dim2)
}

///|
pub fn init_line_gizmo_render_resources(render_world : @ecs.World) -> Unit {
  ensure_line_gizmo_entities(render_world) |> ignore
  ensure_line_gizmo_draw_functions(render_world) |> ignore
  ensure_line_gizmo_phase_items(render_world) |> ignore
  let render_assets_key : @ecs.ResourceKey[@render.RenderAssets[GpuLineGizmo]] = @render.RenderAssets::resource()
  if render_world.get_resource(render_assets_key) is None {
    render_world.insert_resource(render_assets_key, @render.RenderAssets::new())
  }
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
