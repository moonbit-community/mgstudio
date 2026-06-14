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
// Bevy source: `bevy/crates/bevy_pbr/src/volumetric_fog/render.rs`.

///|
fn volumetric_fog_sanitize_non_negative(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn volumetric_fog_sanitize_int(value : Int, min_ : Int) -> Int {
  if value < min_ {
    min_
  } else {
    value
  }
}

///|
fn volumetric_fog_identity_matrix_row_major() -> Array[Float] {
  [
    1.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F,
    0.0F, 0.0F, 1.0F,
  ]
}

///|
fn volumetric_fog_color_to_vec3(color : @color.Color) -> @math.Vec3 {
  let tuple = color.to_linear_rgba_tuple()
  @math.Vec3::new(tuple.0, tuple.1, tuple.2)
}

///|
fn volumetric_fog_affine_transform_vector3(
  transform : @math.Affine3,
  vector : @math.Vec3,
) -> @math.Vec3 {
  transform.matrix3.mul_vec3(vector)
}

///|
fn volumetric_fog_abs(value : Float) -> Float {
  if value < 0.0F {
    0.0F - value
  } else {
    value
  }
}

///|
pub struct VolumetricFogMat4 {
  x_axis : @math.Vec4
  y_axis : @math.Vec4
  z_axis : @math.Vec4
  w_axis : @math.Vec4
}

///|
pub fn VolumetricFogMat4::identity() -> VolumetricFogMat4 {
  VolumetricFogMat4::{
    x_axis: @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
    y_axis: @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
    z_axis: @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    w_axis: @math.Vec4::new(0.0F, 0.0F, 0.0F, 1.0F),
  }
}

///|
pub fn VolumetricFogMat4::from_cols(
  x_axis : @math.Vec4,
  y_axis : @math.Vec4,
  z_axis : @math.Vec4,
  w_axis : @math.Vec4,
) -> VolumetricFogMat4 {
  VolumetricFogMat4::{ x_axis, y_axis, z_axis, w_axis }
}

///|
pub fn VolumetricFogMat4::from_affine3(
  transform : @math.Affine3,
) -> VolumetricFogMat4 {
  VolumetricFogMat4::{
    x_axis: @math.Vec4::new(
      transform.matrix3.x_axis.x,
      transform.matrix3.x_axis.y,
      transform.matrix3.x_axis.z,
      0.0F,
    ),
    y_axis: @math.Vec4::new(
      transform.matrix3.y_axis.x,
      transform.matrix3.y_axis.y,
      transform.matrix3.y_axis.z,
      0.0F,
    ),
    z_axis: @math.Vec4::new(
      transform.matrix3.z_axis.x,
      transform.matrix3.z_axis.y,
      transform.matrix3.z_axis.z,
      0.0F,
    ),
    w_axis: @math.Vec4::new(
      transform.translation.x,
      transform.translation.y,
      transform.translation.z,
      1.0F,
    ),
  }
}

///|
fn volumetric_fog_mat4_mul_vec4(
  matrix : VolumetricFogMat4,
  vector : @math.Vec4,
) -> @math.Vec4 {
  @math.Vec4::new(
    matrix.x_axis.x * vector.x +
    matrix.y_axis.x * vector.y +
    matrix.z_axis.x * vector.z +
    matrix.w_axis.x * vector.w,
    matrix.x_axis.y * vector.x +
    matrix.y_axis.y * vector.y +
    matrix.z_axis.y * vector.z +
    matrix.w_axis.y * vector.w,
    matrix.x_axis.z * vector.x +
    matrix.y_axis.z * vector.y +
    matrix.z_axis.z * vector.z +
    matrix.w_axis.z * vector.w,
    matrix.x_axis.w * vector.x +
    matrix.y_axis.w * vector.y +
    matrix.z_axis.w * vector.z +
    matrix.w_axis.w * vector.w,
  )
}

///|
pub fn VolumetricFogMat4::mul(
  self : VolumetricFogMat4,
  other : VolumetricFogMat4,
) -> VolumetricFogMat4 {
  VolumetricFogMat4::from_cols(
    volumetric_fog_mat4_mul_vec4(self, other.x_axis),
    volumetric_fog_mat4_mul_vec4(self, other.y_axis),
    volumetric_fog_mat4_mul_vec4(self, other.z_axis),
    volumetric_fog_mat4_mul_vec4(self, other.w_axis),
  )
}

///|
pub fn VolumetricFogMat4::mul_affine3(
  self : VolumetricFogMat4,
  transform : @math.Affine3,
) -> VolumetricFogMat4 {
  self.mul(VolumetricFogMat4::from_affine3(transform))
}

///|
pub fn VolumetricFogMat4::to_row_major_array(
  self : VolumetricFogMat4,
) -> Array[Float] {
  [
    self.x_axis.x,
    self.y_axis.x,
    self.z_axis.x,
    self.w_axis.x,
    self.x_axis.y,
    self.y_axis.y,
    self.z_axis.y,
    self.w_axis.y,
    self.x_axis.z,
    self.y_axis.z,
    self.z_axis.z,
    self.w_axis.z,
    self.x_axis.w,
    self.y_axis.w,
    self.z_axis.w,
    self.w_axis.w,
  ]
}

///|
pub fn volumetric_fog_uvw_from_local() -> VolumetricFogMat4 {
  VolumetricFogMat4::from_cols(
    @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    @math.Vec4::new(0.5F, 0.5F, 0.5F, 1.0F),
  )
}

///|
pub fn volumetric_fog_camera_is_inside(local_from_view : @math.Affine3) -> Bool {
  let translation = local_from_view.translation
  volumetric_fog_abs(translation.x) <= 0.5F &&
  volumetric_fog_abs(translation.y) <= 0.5F &&
  volumetric_fog_abs(translation.z) <= 0.5F
}

///|
pub fn volumetric_fog_far_planes(
  view_from_local : @math.Affine3,
) -> Array[@math.Vec4] {
  let far_planes : Array[@math.Vec4] = [
    @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
  ]
  let mut next_index = 0
  let local_normals = [
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    @math.Vec3::new(-1.0F, 0.0F, 0.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
    @math.Vec3::new(0.0F, -1.0F, 0.0F),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec3::new(0.0F, 0.0F, -1.0F),
  ]
  for local_normal in local_normals {
    let view_normal = volumetric_fog_affine_transform_vector3(
      view_from_local, local_normal,
    ).normalize_or_zero()
    if view_normal.z <= 0.0F {
      continue
    }
    let view_position = view_from_local.transform_point3(
      local_normal.neg().mul_scalar(0.5F),
    )
    far_planes[next_index] = @math.Vec4::new(
      view_normal.x,
      view_normal.y,
      view_normal.z,
      0.0F - view_normal.dot(view_position),
    )
    next_index = next_index + 1
    if next_index == far_planes.length() {
      break
    }
  }
  far_planes
}

///|
pub fn volumetric_fog_clip_from_local(
  interior : Bool,
  clip_from_view : VolumetricFogMat4,
  view_from_local : @math.Affine3,
) -> VolumetricFogMat4 {
  if !interior {
    return clip_from_view.mul_affine3(view_from_local)
  }
  let z_near = clip_from_view.w_axis.z
  VolumetricFogMat4::from_cols(
    @math.Vec4::new(z_near, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, z_near, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, z_near, z_near),
  )
}

///|
pub struct VolumetricFogBindGroupLayoutKey {
  multisampled : Bool
  density_texture : Bool
}

///|
pub fn VolumetricFogBindGroupLayoutKey::VolumetricFogBindGroupLayoutKey() -> VolumetricFogBindGroupLayoutKey {
  VolumetricFogBindGroupLayoutKey::{
    multisampled: false,
    density_texture: false,
  }
}

///|
pub fn volumetric_fog_bind_group_layout_index(
  key : VolumetricFogBindGroupLayoutKey,
) -> Int {
  let mut bits = 0
  if key.multisampled {
    bits = bits | 1
  }
  if key.density_texture {
    bits = bits | 2
  }
  bits
}

///|
pub struct VolumetricFogPipelineKey {
  mesh_pipeline_view_key : @mesh_view_layout.MeshPipelineViewLayoutKey
  target_format : @wgpu.TextureFormat
  has_density_texture : Bool
}

///|
pub fn VolumetricFogPipelineKey::VolumetricFogPipelineKey() -> VolumetricFogPipelineKey {
  VolumetricFogPipelineKey::{
    mesh_pipeline_view_key: @mesh_view_layout.MeshPipelineViewLayoutKey::MeshPipelineViewLayoutKey(),
    target_format: @wgpu.TextureFormat::from_u32(
      @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    ),
    has_density_texture: false,
  }
}

///|
pub fn VolumetricFogPipelineKey::new(
  mesh_pipeline_view_key : @mesh_view_layout.MeshPipelineViewLayoutKey,
  target_format : @wgpu.TextureFormat,
  has_density_texture : Bool,
) -> VolumetricFogPipelineKey {
  VolumetricFogPipelineKey::{
    mesh_pipeline_view_key,
    target_format,
    has_density_texture,
  }
}

///|
pub struct VolumetricFogPipeline {
  shader_label : String
  bind_group_layout_count : Int
}

///|
pub fn VolumetricFogPipeline::VolumetricFogPipeline() -> VolumetricFogPipeline {
  VolumetricFogPipeline::{
    shader_label: "pbr/volumetric_fog.wgsl",
    bind_group_layout_count: 4,
  }
}

///|
pub struct ViewVolumetricFogPipelines {
  textureless : Int
  textured : Int
}

///|
let ecs_key_view_volumetric_fog_pipelines : @ecs.ComponentKey[
  ViewVolumetricFogPipelines,
] = @ecs.register_component(
  debug_name="mgstudio_pbr::ViewVolumetricFogPipelines",
)

///|
pub impl @ecs.Component for ViewVolumetricFogPipelines with fn component() {
  ecs_key_view_volumetric_fog_pipelines
}

///|
pub fn ViewVolumetricFogPipelines::ViewVolumetricFogPipelines() -> ViewVolumetricFogPipelines {
  ViewVolumetricFogPipelines::{ textureless: -1, textured: -1 }
}

///|
pub fn view_volumetric_fog_pipelines(
  textureless : Int,
  textured : Int,
) -> ViewVolumetricFogPipelines {
  ViewVolumetricFogPipelines::{ textureless, textured }
}

///|
pub struct VolumetricFogPipelineDescriptor {
  label : String
  shader_defs : Array[String]
  bind_group_layout_index : Int
  target_format : @wgpu.TextureFormat
  cull_mode_back : Bool
  blend_color_src_one : Bool
  blend_color_dst_one_minus_src_alpha : Bool
  blend_alpha_src_zero : Bool
  blend_alpha_dst_one : Bool
}

///|
pub fn VolumetricFogPipelineDescriptor::shader_defs(
  self : VolumetricFogPipelineDescriptor,
) -> Array[String] {
  self.shader_defs
}

///|
pub fn VolumetricFogPipelineDescriptor::bind_group_layout_index(
  self : VolumetricFogPipelineDescriptor,
) -> Int {
  self.bind_group_layout_index
}

///|
pub fn VolumetricFogPipelineDescriptor::target_format(
  self : VolumetricFogPipelineDescriptor,
) -> @wgpu.TextureFormat {
  self.target_format
}

///|
pub fn VolumetricFogPipelineDescriptor::uses_bevy_blend_state(
  self : VolumetricFogPipelineDescriptor,
) -> Bool {
  self.cull_mode_back &&
  self.blend_color_src_one &&
  self.blend_color_dst_one_minus_src_alpha &&
  self.blend_alpha_src_zero &&
  self.blend_alpha_dst_one
}

///|
pub struct VolumetricFogUniform {
  clip_from_local_row_major : Array[Float]
  uvw_from_world_row_major : Array[Float]
  far_planes : Array[@math.Vec4]
  fog_color : @math.Vec3
  light_tint : @math.Vec3
  ambient_color : @math.Vec3
  ambient_intensity : Float
  step_count : Int
  bounding_radius : Float
  absorption : Float
  scattering : Float
  density : Float
  density_texture_offset : @math.Vec3
  scattering_asymmetry : Float
  light_intensity : Float
  jitter_strength : Float
}

///|
pub fn VolumetricFogUniform::VolumetricFogUniform() -> VolumetricFogUniform {
  VolumetricFogUniform::{
    clip_from_local_row_major: volumetric_fog_identity_matrix_row_major(),
    uvw_from_world_row_major: volumetric_fog_identity_matrix_row_major(),
    far_planes: [
      @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    ],
    fog_color: @math.Vec3::new(1.0F, 1.0F, 1.0F),
    light_tint: @math.Vec3::new(1.0F, 1.0F, 1.0F),
    ambient_color: @math.Vec3::new(1.0F, 1.0F, 1.0F),
    ambient_intensity: 0.1F,
    step_count: 64,
    bounding_radius: 1.0F,
    absorption: 0.3F,
    scattering: 0.3F,
    density: 0.1F,
    density_texture_offset: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    scattering_asymmetry: 0.0F,
    light_intensity: 1.0F,
    jitter_strength: 0.0F,
  }
}

///|
pub fn VolumetricFogUniform::with_step_count(
  self : VolumetricFogUniform,
  step_count : Int,
) -> VolumetricFogUniform {
  VolumetricFogUniform::{
    ..self,
    step_count: volumetric_fog_sanitize_int(step_count, 1),
  }
}

///|
pub fn VolumetricFogUniform::with_density(
  self : VolumetricFogUniform,
  density : Float,
) -> VolumetricFogUniform {
  VolumetricFogUniform::{
    ..self,
    density: volumetric_fog_sanitize_non_negative(density),
  }
}

///|
pub fn VolumetricFogUniform::with_jitter_strength(
  self : VolumetricFogUniform,
  jitter_strength : Float,
) -> VolumetricFogUniform {
  VolumetricFogUniform::{
    ..self,
    jitter_strength: volumetric_fog_sanitize_non_negative(jitter_strength),
  }
}

///|
pub struct ViewFogVolume {
  density_texture : @asset.Handle[@asset.Image]?
  uniform_buffer_offset : Int
  exterior : Bool
}

///|
pub fn ViewFogVolume::ViewFogVolume() -> ViewFogVolume {
  ViewFogVolume::{
    density_texture: None,
    uniform_buffer_offset: 0,
    exterior: true,
  }
}

///|
pub fn ViewFogVolume::has_density_texture(self : ViewFogVolume) -> Bool {
  self.density_texture is Some(_)
}

///|
pub struct ViewVolumetricFog {
  volumes : Array[ViewFogVolume]
}

///|
let ecs_key_view_volumetric_fog : @ecs.ComponentKey[ViewVolumetricFog] = @ecs.register_component(
  debug_name="mgstudio_pbr::ViewVolumetricFog",
)

///|
pub impl @ecs.Component for ViewVolumetricFog with fn component() {
  ecs_key_view_volumetric_fog
}

///|
pub fn ViewVolumetricFog::ViewVolumetricFog() -> ViewVolumetricFog {
  ViewVolumetricFog::{ volumes: [] }
}

///|
pub fn ViewVolumetricFog::push(
  self : ViewVolumetricFog,
  volume : ViewFogVolume,
) -> Unit {
  self.volumes.push(volume)
}

///|
pub fn ViewVolumetricFog::count(self : ViewVolumetricFog) -> Int {
  self.volumes.length()
}

///|
pub struct VolumetricFogUniformBuffer {
  mut uniforms : Array[VolumetricFogUniform]
}

///|
let ecs_key_volumetric_fog_uniform_buffer : @ecs.ResourceKey[
  VolumetricFogUniformBuffer,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::VolumetricFogUniformBuffer",
)

///|
pub impl @app.Resource for VolumetricFogUniformBuffer with fn resource() {
  ecs_key_volumetric_fog_uniform_buffer
}

///|
pub fn VolumetricFogUniformBuffer::VolumetricFogUniformBuffer() -> VolumetricFogUniformBuffer {
  VolumetricFogUniformBuffer::{ uniforms: [] }
}

///|
pub fn VolumetricFogUniformBuffer::clear(
  self : VolumetricFogUniformBuffer,
) -> Unit {
  self.uniforms = []
}

///|
pub fn VolumetricFogUniformBuffer::push(
  self : VolumetricFogUniformBuffer,
  uniform : VolumetricFogUniform,
) -> Int {
  let offset = self.uniforms.length()
  self.uniforms.push(uniform)
  offset
}

///|
pub fn VolumetricFogUniformBuffer::count(
  self : VolumetricFogUniformBuffer,
) -> Int {
  self.uniforms.length()
}

///|
pub fn VolumetricFogUniformBuffer::uniform_at(
  self : VolumetricFogUniformBuffer,
  index : Int,
) -> VolumetricFogUniform? {
  if index < 0 || index >= self.uniforms.length() {
    None
  } else {
    Some(self.uniforms[index])
  }
}

///|
pub struct PreparedVolumetricFogView {
  view_fog : ViewVolumetricFog
  uniform_count : Int
}

///|
pub fn PreparedVolumetricFogView::PreparedVolumetricFogView() -> PreparedVolumetricFogView {
  PreparedVolumetricFogView::{
    view_fog: ViewVolumetricFog::ViewVolumetricFog(),
    uniform_count: 0,
  }
}

///|
pub fn prepare_volumetric_fog_view_uniforms(
  uniform_buffer : VolumetricFogUniformBuffer,
  volumetric_fog : VolumetricFog,
  world_from_view : @math.Affine3,
  clip_from_view : VolumetricFogMat4,
  fog_volumes : Array[(FogVolume, @math.Affine3)],
) -> PreparedVolumetricFogView {
  let view_fog = ViewVolumetricFog::ViewVolumetricFog()
  for entry in fog_volumes {
    let fog_volume = entry.0
    let local_from_world = entry.1.inverse()
    let local_from_view = local_from_world.mul(world_from_view)
    let view_from_local = local_from_view.inverse()
    let interior = volumetric_fog_camera_is_inside(local_from_view)
    let clip_from_local = volumetric_fog_clip_from_local(
      interior, clip_from_view, view_from_local,
    )
    let bounding_radius = volumetric_fog_affine_transform_vector3(
      view_from_local,
      @math.Vec3::splat(0.5F),
    ).length()
    let uniform = VolumetricFogUniform::{
      clip_from_local_row_major: clip_from_local.to_row_major_array(),
      uvw_from_world_row_major: volumetric_fog_uvw_from_local()
      .mul_affine3(local_from_world)
      .to_row_major_array(),
      far_planes: volumetric_fog_far_planes(view_from_local),
      fog_color: volumetric_fog_color_to_vec3(fog_volume.fog_color),
      light_tint: volumetric_fog_color_to_vec3(fog_volume.light_tint),
      ambient_color: volumetric_fog_color_to_vec3(volumetric_fog.ambient_color),
      ambient_intensity: volumetric_fog.ambient_intensity,
      step_count: volumetric_fog.step_count,
      bounding_radius,
      absorption: fog_volume.absorption,
      scattering: fog_volume.scattering,
      density: fog_volume.density_factor,
      density_texture_offset: fog_volume.density_texture_offset,
      scattering_asymmetry: fog_volume.scattering_asymmetry,
      light_intensity: fog_volume.light_intensity,
      jitter_strength: volumetric_fog.jitter,
    }
    let uniform_buffer_offset = uniform_buffer.push(uniform)
    view_fog.push(ViewFogVolume::{
      density_texture: fog_volume.density_texture,
      uniform_buffer_offset,
      exterior: !interior,
    })
  }
  PreparedVolumetricFogView::{ view_fog, uniform_count: fog_volumes.length() }
}

///|

///|
pub fn volumetric_fog_select_pipeline(
  pipelines : ViewVolumetricFogPipelines,
  key : VolumetricFogPipelineKey,
) -> Int {
  if key.has_density_texture {
    pipelines.textured
  } else {
    pipelines.textureless
  }
}

///|
pub fn volumetric_fog_specialize_pipeline(
  key : VolumetricFogPipelineKey,
) -> VolumetricFogPipelineDescriptor {
  let shader_defs = ["SHADOW_FILTER_METHOD_HARDWARE_2X2"]
  let bind_group_layout_key = VolumetricFogBindGroupLayoutKey::{
    multisampled: key.mesh_pipeline_view_key.multisampled(),
    density_texture: key.has_density_texture,
  }
  if key.mesh_pipeline_view_key.multisampled() {
    shader_defs.push("MULTISAMPLED")
  }
  if key.mesh_pipeline_view_key.atmosphere() {
    shader_defs.push("ATMOSPHERE")
  }
  if key.has_density_texture {
    shader_defs.push("DENSITY_TEXTURE")
  }
  VolumetricFogPipelineDescriptor::{
    label: "volumetric lighting pipeline",
    shader_defs,
    bind_group_layout_index: volumetric_fog_bind_group_layout_index(
      bind_group_layout_key,
    ),
    target_format: key.target_format,
    cull_mode_back: true,
    blend_color_src_one: true,
    blend_color_dst_one_minus_src_alpha: true,
    blend_alpha_src_zero: true,
    blend_alpha_dst_one: true,
  }
}

///|
pub fn volumetric_fog_default_settings() -> VolumetricFog {
  VolumetricFog()
}

///|
pub fn fog_volume_default_settings() -> FogVolume {
  FogVolume()
}

///|
pub fn volumetric_fog_with_step_count(
  fog : VolumetricFog,
  step_count : Int,
) -> VolumetricFog {
  fog.with_step_count(step_count)
}

///|
pub fn fog_volume_with_density(
  volume : FogVolume,
  density_factor : Float,
) -> FogVolume {
  volume.with_density_factor(density_factor)
}
