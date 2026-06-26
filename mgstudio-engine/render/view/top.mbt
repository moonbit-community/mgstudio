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
// Bevy source: `bevy/crates/bevy_render/src/view/mod.rs`.

///|
const VIEW_PLUGIN_NAME : String = "mgstudio.render.view.ViewPlugin"

///|
pub struct ViewPlugin {}

///|
pub fn ViewPlugin::ViewPlugin() -> ViewPlugin {
  ViewPlugin::{  }
}

///|
pub impl @app.Plugin for ViewPlugin with fn name(_self) {
  VIEW_PLUGIN_NAME
}

///|
pub impl @app.Plugin for ViewPlugin with fn build(_self, app) {
  app
}

///|
pub impl @app.Plugin for ViewPlugin with fn finish(_self, app) {
  let next = app
  ignore(
    next.modify_sub_app(@app.RenderApp, fn(render_app) {
      init_view_uniforms(render_app.world())
      init_view_target_attachments(render_app.world())
      render_app
    }),
  )
  next
}

///|
// Bevy source: `bevy/crates/bevy_render/src/view/mod.rs`.
pub(all) enum Msaa {
  Off
  Sample2
  Sample4
  Sample8
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn Msaa::default() -> Msaa {
  Msaa::Sample4
}

///|
pub fn Msaa::samples(self : Msaa) -> Int {
  match self {
    Off => 1
    Sample2 => 2
    Sample4 => 4
    Sample8 => 8
  }
}

///|
pub fn Msaa::from_samples(samples : Int) -> Msaa {
  match samples {
    1 => Msaa::Off
    2 => Msaa::Sample2
    4 => Msaa::Sample4
    8 => Msaa::Sample8
    _ => abort("Unsupported MSAA sample count: \{samples}")
  }
}

///|
pub struct RenderShadowLodOrigin {
  origin : @math.Vec3
}

///|
pub fn RenderShadowLodOrigin::RenderShadowLodOrigin() -> RenderShadowLodOrigin {
  RenderShadowLodOrigin::{ origin: @math.Vec3::zero() }
}

///|
pub fn RenderShadowLodOrigin::new(origin : @math.Vec3) -> RenderShadowLodOrigin {
  RenderShadowLodOrigin::{ origin, }
}

///|
pub fn RenderShadowLodOrigin::origin(
  self : RenderShadowLodOrigin,
) -> @math.Vec3 {
  self.origin
}

///|
pub fn RenderShadowLodOrigin::is_default(self : RenderShadowLodOrigin) -> Bool {
  self.origin.length_squared() == 0.0F
}

///|
pub const COLOR_GRADING_UNIFORM_SIZE_BYTES : Int = 160

///|
pub const VIEW_UNIFORM_SIZE_BYTES : Int = 784

///|
pub(all) struct ViewUniformMat3 {
  x_axis : @math.Vec3
  y_axis : @math.Vec3
  z_axis : @math.Vec3
}

///|
pub fn ViewUniformMat3::identity() -> ViewUniformMat3 {
  ViewUniformMat3::{
    x_axis: @math.Vec3::new(1.0F, 0.0F, 0.0F),
    y_axis: @math.Vec3::new(0.0F, 1.0F, 0.0F),
    z_axis: @math.Vec3::new(0.0F, 0.0F, 1.0F),
  }
}

///|
pub(all) struct ViewUniformMat4 {
  x_axis : @math.Vec4
  y_axis : @math.Vec4
  z_axis : @math.Vec4
  w_axis : @math.Vec4
}

///|
pub fn ViewUniformMat4::identity() -> ViewUniformMat4 {
  ViewUniformMat4::{
    x_axis: @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
    y_axis: @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
    z_axis: @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    w_axis: @math.Vec4::new(0.0F, 0.0F, 0.0F, 1.0F),
  }
}

///|
pub(all) struct ColorGradingUniform {
  balance : ViewUniformMat3
  saturation : @math.Vec3
  contrast : @math.Vec3
  gamma : @math.Vec3
  gain : @math.Vec3
  lift : @math.Vec3
  midtone_range : @math.Vec2
  exposure : Float
  hue : Float
  post_saturation : Float
}

///|
pub fn ColorGradingUniform::ColorGradingUniform() -> ColorGradingUniform {
  ColorGradingUniform::{
    balance: ViewUniformMat3::identity(),
    saturation: @math.Vec3::splat(1.0F),
    contrast: @math.Vec3::splat(1.0F),
    gamma: @math.Vec3::splat(1.0F),
    gain: @math.Vec3::splat(1.0F),
    lift: @math.Vec3::zero(),
    midtone_range: @math.Vec2::new(0.2F, 0.7F),
    exposure: 0.0F,
    hue: 0.0F,
    post_saturation: 1.0F,
  }
}

///|
pub(all) struct ViewUniform {
  clip_from_world : ViewUniformMat4
  unjittered_clip_from_world : ViewUniformMat4
  world_from_clip : ViewUniformMat4
  world_from_view : ViewUniformMat4
  view_from_world : ViewUniformMat4
  clip_from_view : ViewUniformMat4
  view_from_clip : ViewUniformMat4
  world_position : @math.Vec3
  exposure : Float
  viewport : @math.Vec4
  main_pass_viewport : @math.Vec4
  frustum : Array[@math.Vec4]
  lod_view_world_position : @math.Vec3
  color_grading : ColorGradingUniform
  mip_bias : Float
  frame_count : UInt
}

///|
pub fn ViewUniform::ViewUniform() -> ViewUniform {
  ViewUniform::{
    clip_from_world: ViewUniformMat4::identity(),
    unjittered_clip_from_world: ViewUniformMat4::identity(),
    world_from_clip: ViewUniformMat4::identity(),
    world_from_view: ViewUniformMat4::identity(),
    view_from_world: ViewUniformMat4::identity(),
    clip_from_view: ViewUniformMat4::identity(),
    view_from_clip: ViewUniformMat4::identity(),
    world_position: @math.Vec3::zero(),
    exposure: 0.0F,
    viewport: @math.Vec4::splat(0.0F),
    main_pass_viewport: @math.Vec4::splat(0.0F),
    frustum: [
      @math.Vec4::splat(0.0F),
      @math.Vec4::splat(0.0F),
      @math.Vec4::splat(0.0F),
      @math.Vec4::splat(0.0F),
      @math.Vec4::splat(0.0F),
      @math.Vec4::splat(0.0F),
    ],
    lod_view_world_position: @math.Vec3::zero(),
    color_grading: ColorGradingUniform::ColorGradingUniform(),
    mip_bias: 0.0F,
    frame_count: 0U,
  }
}

///|
fn view_uniform_push_u32_le(out : Array[Byte], value : UInt) -> Unit {
  out.push((value & 0xFFU).to_byte())
  out.push(((value >> 8) & 0xFFU).to_byte())
  out.push(((value >> 16) & 0xFFU).to_byte())
  out.push(((value >> 24) & 0xFFU).to_byte())
}

///|
fn view_uniform_push_f32_le(out : Array[Byte], value : Float) -> Unit {
  view_uniform_push_u32_le(out, value.reinterpret_as_uint())
}

///|
fn view_uniform_push_vec2(out : Array[Byte], value : @math.Vec2) -> Unit {
  view_uniform_push_f32_le(out, value.x)
  view_uniform_push_f32_le(out, value.y)
}

///|
fn view_uniform_push_vec3(out : Array[Byte], value : @math.Vec3) -> Unit {
  view_uniform_push_f32_le(out, value.x)
  view_uniform_push_f32_le(out, value.y)
  view_uniform_push_f32_le(out, value.z)
}

///|
fn view_uniform_push_vec4(out : Array[Byte], value : @math.Vec4) -> Unit {
  view_uniform_push_f32_le(out, value.x)
  view_uniform_push_f32_le(out, value.y)
  view_uniform_push_f32_le(out, value.z)
  view_uniform_push_f32_le(out, value.w)
}

///|
fn view_uniform_push_mat3(out : Array[Byte], value : ViewUniformMat3) -> Unit {
  view_uniform_push_vec3(out, value.x_axis)
  view_uniform_push_f32_le(out, 0.0F)
  view_uniform_push_vec3(out, value.y_axis)
  view_uniform_push_f32_le(out, 0.0F)
  view_uniform_push_vec3(out, value.z_axis)
  view_uniform_push_f32_le(out, 0.0F)
}

///|
fn view_uniform_push_mat4(out : Array[Byte], value : ViewUniformMat4) -> Unit {
  view_uniform_push_vec4(out, value.x_axis)
  view_uniform_push_vec4(out, value.y_axis)
  view_uniform_push_vec4(out, value.z_axis)
  view_uniform_push_vec4(out, value.w_axis)
}

///|
fn ColorGradingUniform::write_bytes(
  self : ColorGradingUniform,
  out : Array[Byte],
) -> Unit {
  view_uniform_push_mat3(out, self.balance)
  view_uniform_push_vec3(out, self.saturation)
  view_uniform_push_f32_le(out, 0.0F)
  view_uniform_push_vec3(out, self.contrast)
  view_uniform_push_f32_le(out, 0.0F)
  view_uniform_push_vec3(out, self.gamma)
  view_uniform_push_f32_le(out, 0.0F)
  view_uniform_push_vec3(out, self.gain)
  view_uniform_push_f32_le(out, 0.0F)
  view_uniform_push_vec3(out, self.lift)
  view_uniform_push_f32_le(out, 0.0F)
  view_uniform_push_vec2(out, self.midtone_range)
  view_uniform_push_f32_le(out, self.exposure)
  view_uniform_push_f32_le(out, self.hue)
  view_uniform_push_f32_le(out, self.post_saturation)
  view_uniform_push_f32_le(out, 0.0F)
  view_uniform_push_f32_le(out, 0.0F)
  view_uniform_push_f32_le(out, 0.0F)
}

///|
pub fn ViewUniform::bytes(self : ViewUniform) -> Bytes {
  let out : Array[Byte] = []
  view_uniform_push_mat4(out, self.clip_from_world)
  view_uniform_push_mat4(out, self.unjittered_clip_from_world)
  view_uniform_push_mat4(out, self.world_from_clip)
  view_uniform_push_mat4(out, self.world_from_view)
  view_uniform_push_mat4(out, self.view_from_world)
  view_uniform_push_mat4(out, self.clip_from_view)
  view_uniform_push_mat4(out, self.view_from_clip)
  view_uniform_push_vec3(out, self.world_position)
  view_uniform_push_f32_le(out, self.exposure)
  view_uniform_push_vec4(out, self.viewport)
  view_uniform_push_vec4(out, self.main_pass_viewport)
  for i in 0..<6 {
    if i < self.frustum.length() {
      view_uniform_push_vec4(out, self.frustum[i])
    } else {
      view_uniform_push_vec4(out, @math.Vec4::splat(0.0F))
    }
  }
  view_uniform_push_vec3(out, self.lod_view_world_position)
  view_uniform_push_f32_le(out, 0.0F)
  self.color_grading.write_bytes(out)
  view_uniform_push_f32_le(out, self.mip_bias)
  view_uniform_push_u32_le(out, self.frame_count)
  view_uniform_push_u32_le(out, 0U)
  view_uniform_push_u32_le(out, 0U)
  Bytes::from_array(out)
}

///|
pub(all) struct ViewUniforms {
  uniforms : @render_resource.DynamicUniformBuffer[ViewUniform]
  mut gpu_buffer : @wgpu.Buffer?
  mut gpu_capacity : UInt64
}

///|
pub fn ViewUniforms::ViewUniforms() -> ViewUniforms {
  ViewUniforms::{
    uniforms: @render_resource.DynamicUniformBuffer::new(),
    gpu_buffer: None,
    gpu_capacity: 0UL,
  }
}

///|
pub fn ViewUniforms::push(self : ViewUniforms, uniform : ViewUniform) -> UInt {
  let offset = (self.uniforms.len() * VIEW_UNIFORM_SIZE_BYTES).reinterpret_as_uint()
  self.uniforms.push(uniform)
  offset
}

///|
pub fn ViewUniforms::clear(self : ViewUniforms) -> Unit {
  self.uniforms.clear()
}

///|
pub fn ViewUniforms::len(self : ViewUniforms) -> Int {
  self.uniforms.len()
}

///|
fn view_uniforms_non_zero_u64(value : UInt64) -> UInt64 {
  if value == 0UL {
    4UL
  } else {
    value
  }
}

///|
fn ViewUniforms::buffer_bytes(self : ViewUniforms) -> Bytes {
  let out : Array[Byte] = []
  for uniform in self.uniforms.values() {
    let bytes = uniform.bytes()
    for byte in bytes {
      out.push(byte)
    }
  }
  Bytes::from_array(out)
}

///|
pub fn ViewUniforms::write_buffer(
  self : ViewUniforms,
  device : @wgpu.Device,
  queue : @wgpu.Queue,
) -> Unit {
  let bytes = self.buffer_bytes()
  if bytes.length() == 0 {
    return
  }
  let required_size = view_uniforms_non_zero_u64(bytes.length().to_uint64())
  let mut usage_bits = @wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST
  if device.limits_max_storage_buffers_per_shader_stage_u32() > 0U {
    usage_bits = usage_bits | @wgpu.BUFFER_USAGE_STORAGE
  }
  let usage = @wgpu.BufferUsage::from_u64(usage_bits)
  let buffer = match self.gpu_buffer {
    Some(existing) if self.gpu_capacity >= required_size => existing
    Some(existing) => {
      existing.release()
      let next = device.create_buffer(size=required_size, usage~)
      next.set_label("view_uniforms_buffer")
      self.gpu_capacity = required_size
      next
    }
    None => {
      let next = device.create_buffer(size=required_size, usage~)
      next.set_label("view_uniforms_buffer")
      self.gpu_capacity = required_size
      next
    }
  }
  queue.write_buffer(buffer, 0UL, bytes)
  self.gpu_buffer = Some(buffer)
}

///|
pub fn ViewUniforms::binding(self : ViewUniforms) -> @wgpu.Buffer? {
  self.gpu_buffer
}

///|
pub fn ViewUniforms::gpu_capacity(self : ViewUniforms) -> UInt64 {
  self.gpu_capacity
}

///|
pub fn init_view_uniforms(world : @ecs.World) -> Unit {
  if world.resource(view_uniforms_resource_key).is_present() {
    return
  }
  world.insert_resource(
    view_uniforms_resource_key,
    ViewUniforms::ViewUniforms(),
  )
}

///|
pub let view_uniforms_resource_key : @ecs.ResourceKey[ViewUniforms] = @ecs.register_resource(
  debug_name="mgstudio_render::ViewUniforms",
)

///|
pub impl @app.Resource for ViewUniforms with fn resource() {
  view_uniforms_resource_key
}

///|
pub struct ViewTargetAttachments {
  attachments : @hashmap.HashMap[
    @camera_render_target.NormalizedRenderTarget,
    @render_texture.OutputColorAttachment,
  ]
}

///|
pub fn ViewTargetAttachments::ViewTargetAttachments() -> ViewTargetAttachments {
  ViewTargetAttachments::{ attachments: @hashmap.HashMap([]) }
}

///|
pub fn ViewTargetAttachments::len(self : ViewTargetAttachments) -> Int {
  self.attachments.length()
}

///|
pub fn ViewTargetAttachments::is_empty(self : ViewTargetAttachments) -> Bool {
  self.len() == 0
}

///|
pub fn ViewTargetAttachments::insert(
  self : ViewTargetAttachments,
  target : @camera_render_target.NormalizedRenderTarget,
  attachment : @render_texture.OutputColorAttachment,
) -> Unit {
  self.attachments.set(target, attachment)
}

///|
pub fn ViewTargetAttachments::get(
  self : ViewTargetAttachments,
  target : @camera_render_target.NormalizedRenderTarget,
) -> @render_texture.OutputColorAttachment? {
  self.attachments.get(target)
}

///|
pub fn ViewTargetAttachments::clear(self : ViewTargetAttachments) -> Unit {
  self.attachments.clear()
}

///|
pub let view_target_attachments_resource_key : @ecs.ResourceKey[
  ViewTargetAttachments,
] = @ecs.register_resource(debug_name="mgstudio_render::ViewTargetAttachments")

///|
pub fn init_view_target_attachments(world : @ecs.World) -> Unit {
  if world.resource(view_target_attachments_resource_key).is_present() {
    return
  }
  world.insert_resource(
    view_target_attachments_resource_key,
    ViewTargetAttachments::ViewTargetAttachments(),
  )
}

///|
pub impl @app.Resource for ViewTargetAttachments with fn resource() {
  view_target_attachments_resource_key
}

///|
pub(all) struct ViewUniformOffset {
  offset : UInt
}

///|
pub fn ViewUniformOffset::new(offset : UInt) -> ViewUniformOffset {
  ViewUniformOffset::{ offset, }
}

///|
pub fn ViewUniformOffset::offset(self : ViewUniformOffset) -> UInt {
  self.offset
}

///|
pub let ecs_key_view_uniform_offset : @ecs.ComponentKey[ViewUniformOffset] = @ecs.register_component(
  debug_name="mgstudio_render::ViewUniformOffset",
)

///|
pub impl @ecs.Component for ViewUniformOffset with fn component() {
  ecs_key_view_uniform_offset
}

///|
pub let render_shadow_lod_origin_resource_key : @ecs.ResourceKey[
  RenderShadowLodOrigin,
] = @ecs.register_resource(debug_name="mgstudio_render::RenderShadowLodOrigin")

///|
pub impl @app.Resource for RenderShadowLodOrigin with fn resource() {
  render_shadow_lod_origin_resource_key
}

///|
pub let ecs_key_msaa : @ecs.ComponentKey[Msaa] = @ecs.register_component(
  debug_name="render.view.msaa",
)

///|
pub impl @ecs.Component for Msaa with fn component() {
  ecs_key_msaa
}

///|
pub struct NoIndirectDrawing {} derive(ToJson, FromJson)

///|
pub fn NoIndirectDrawing::NoIndirectDrawing() -> NoIndirectDrawing {
  NoIndirectDrawing::{  }
}

///|
pub let ecs_key_no_indirect_drawing : @ecs.ComponentKey[NoIndirectDrawing] = @ecs.register_component(
  debug_name="render.view.no_indirect_drawing",
)

///|
pub impl @ecs.Component for NoIndirectDrawing with fn component() {
  ecs_key_no_indirect_drawing
}

///|
pub struct ExtractedView {
  retained_view_entity : RetainedViewEntity
  target_format_raw : UInt
  viewport_x : Int
  viewport_y : Int
  viewport_z : Int
  viewport_w : Int
  invert_culling : Bool
}

///|
pub fn ExtractedView::new(
  retained_view_entity : RetainedViewEntity,
  target_format_raw? : UInt = @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB,
  viewport_x? : Int = 0,
  viewport_y? : Int = 0,
  viewport_z? : Int = 0,
  viewport_w? : Int = 0,
  invert_culling? : Bool = false,
) -> ExtractedView {
  ExtractedView::{
    retained_view_entity,
    target_format_raw,
    viewport_x,
    viewport_y,
    viewport_z,
    viewport_w,
    invert_culling,
  }
}

///|
pub fn ExtractedView::retained_view_entity(
  self : ExtractedView,
) -> RetainedViewEntity {
  self.retained_view_entity
}

///|
pub fn ExtractedView::target_format_raw(self : ExtractedView) -> UInt {
  self.target_format_raw
}

///|
pub fn ExtractedView::viewport_x(self : ExtractedView) -> Int {
  self.viewport_x
}

///|
pub fn ExtractedView::viewport_y(self : ExtractedView) -> Int {
  self.viewport_y
}

///|
pub fn ExtractedView::viewport_z(self : ExtractedView) -> Int {
  self.viewport_z
}

///|
pub fn ExtractedView::viewport_w(self : ExtractedView) -> Int {
  self.viewport_w
}

///|
pub fn ExtractedView::invert_culling(self : ExtractedView) -> Bool {
  self.invert_culling
}

///|
pub let ecs_key_extracted_view : @ecs.ComponentKey[ExtractedView] = @ecs.register_component(
  debug_name="render.view.extracted_view",
)

///|
pub impl @ecs.Component for ExtractedView with fn component() {
  ecs_key_extracted_view
}

///|
pub struct RetainedViewEntity {
  main_entity : @core.Entity
  auxiliary_entity : @core.Entity
  subview_index : Int
} derive(Eq, Debug, Hash)

///|
pub fn RetainedViewEntity::new(
  main_entity : @core.Entity,
  auxiliary_entity? : @core.Entity? = None,
  subview_index? : Int = 0,
) -> RetainedViewEntity {
  RetainedViewEntity::{
    main_entity,
    auxiliary_entity: auxiliary_entity.unwrap_or(@core.Entity::placeholder()),
    subview_index,
  }
}

///|
pub fn RetainedViewEntity::main_entity(
  self : RetainedViewEntity,
) -> @core.Entity {
  self.main_entity
}

///|
pub fn RetainedViewEntity::auxiliary_entity(
  self : RetainedViewEntity,
) -> @core.Entity {
  self.auxiliary_entity
}

///|
pub fn RetainedViewEntity::subview_index(self : RetainedViewEntity) -> Int {
  self.subview_index
}

///|
pub fn retained_view_entity_equals(
  lhs : RetainedViewEntity,
  rhs : RetainedViewEntity,
) -> Bool {
  lhs.main_entity == rhs.main_entity &&
  lhs.auxiliary_entity == rhs.auxiliary_entity &&
  lhs.subview_index == rhs.subview_index
}

///|
pub fn retained_view_entity_contains(
  views : Array[RetainedViewEntity],
  view : RetainedViewEntity,
) -> Bool {
  for current in views {
    if retained_view_entity_equals(current, view) {
      return true
    }
  }
  false
}

///|
// Bevy source: `bevy/crates/bevy_render/src/camera.rs::normalize_bgra8`.
pub fn normalize_bgra8_for_render_target(
  target_is_window~ : Bool,
  format_raw : UInt,
) -> UInt {
  if target_is_window && format_raw == @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB {
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB
  } else {
    format_raw
  }
}

///|
// Bevy source: `bevy/crates/bevy_render/src/camera.rs::extract_cameras`.
pub fn extracted_view_target_format_raw(
  output_texture_format_raw? : UInt = @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB,
  hdr? : Bool = false,
  compositing_space? : @camera_compositing_space.CompositingSpace? = None,
) -> UInt {
  if hdr {
    @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT
  } else {
    match compositing_space {
      Some(@camera_compositing_space.CompositingSpace::Srgb) =>
        @wgpu.TEXTURE_FORMAT_RGBA8_UNORM
      _ => output_texture_format_raw
    }
  }
}

///|
pub fn view_visibility_range_always_visible() -> @visibility.VisibilityRange {
  @visibility.VisibilityRange::always_visible()
}

///|
pub fn view_visibility_range_invisible() -> @visibility.VisibilityRange {
  @visibility.VisibilityRange::invisible()
}
