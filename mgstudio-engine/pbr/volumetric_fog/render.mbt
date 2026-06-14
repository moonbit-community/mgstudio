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
const VOLUMETRIC_FOG_UNIFORM_SIZE_BYTES : Int = 288

///|
const VOLUMETRIC_FOG_UNIFORM_DYNAMIC_STRIDE_BYTES : Int = 512

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
fn volumetric_fog_u32le_pack(words : Array[UInt]) -> Bytes {
  Bytes::makei(words.length() * 4, i => {
    let word = words[i / 4]
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
fn volumetric_fog_push_f32(words : Array[UInt], value : Float) -> Unit {
  words.push(value.reinterpret_as_uint())
}

///|
fn volumetric_fog_push_vec3(words : Array[UInt], value : @math.Vec3) -> Unit {
  volumetric_fog_push_f32(words, value.x)
  volumetric_fog_push_f32(words, value.y)
  volumetric_fog_push_f32(words, value.z)
}

///|
fn volumetric_fog_push_vec4(words : Array[UInt], value : @math.Vec4) -> Unit {
  volumetric_fog_push_f32(words, value.x)
  volumetric_fog_push_f32(words, value.y)
  volumetric_fog_push_f32(words, value.z)
  volumetric_fog_push_f32(words, value.w)
}

///|
fn volumetric_fog_push_mat4_cols(
  words : Array[UInt],
  values : Array[Float],
) -> Unit {
  for index in 0..<16 {
    let value = if index < values.length() { values[index] } else { 0.0F }
    volumetric_fog_push_f32(words, value)
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
pub fn VolumetricFogMat4::to_cols_array(
  self : VolumetricFogMat4,
) -> Array[Float] {
  [
    self.x_axis.x,
    self.x_axis.y,
    self.x_axis.z,
    self.x_axis.w,
    self.y_axis.x,
    self.y_axis.y,
    self.y_axis.z,
    self.y_axis.w,
    self.z_axis.x,
    self.z_axis.y,
    self.z_axis.z,
    self.z_axis.w,
    self.w_axis.x,
    self.w_axis.y,
    self.w_axis.z,
    self.w_axis.w,
  ]
}

///|
fn volumetric_fog_uvw_from_local() -> VolumetricFogMat4 {
  VolumetricFogMat4::from_cols(
    @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    @math.Vec4::new(0.5F, 0.5F, 0.5F, 1.0F),
  )
}

///|
fn volumetric_fog_camera_is_inside(local_from_view : @math.Affine3) -> Bool {
  let translation = local_from_view.translation
  volumetric_fog_abs(translation.x) <= 0.5F &&
  volumetric_fog_abs(translation.y) <= 0.5F &&
  volumetric_fog_abs(translation.z) <= 0.5F
}

///|
fn volumetric_fog_far_planes(
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
fn volumetric_fog_clip_from_local(
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
struct VolumetricFogUniform {
  clip_from_local : Array[Float]
  uvw_from_world : Array[Float]
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
fn VolumetricFogUniform::bytes(self : VolumetricFogUniform) -> Bytes {
  let words : Array[UInt] = []
  volumetric_fog_push_mat4_cols(words, self.clip_from_local)
  volumetric_fog_push_mat4_cols(words, self.uvw_from_world)
  for index in 0..<3 {
    let plane = if index < self.far_planes.length() {
      self.far_planes[index]
    } else {
      @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F)
    }
    volumetric_fog_push_vec4(words, plane)
  }
  volumetric_fog_push_vec3(words, self.fog_color)
  words.push(0U)
  volumetric_fog_push_vec3(words, self.light_tint)
  words.push(0U)
  volumetric_fog_push_vec3(words, self.ambient_color)
  volumetric_fog_push_f32(words, self.ambient_intensity)
  words.push(self.step_count.reinterpret_as_uint())
  volumetric_fog_push_f32(words, self.bounding_radius)
  volumetric_fog_push_f32(words, self.absorption)
  volumetric_fog_push_f32(words, self.scattering)
  volumetric_fog_push_f32(words, self.density)
  words.push(0U)
  words.push(0U)
  words.push(0U)
  volumetric_fog_push_vec3(words, self.density_texture_offset)
  volumetric_fog_push_f32(words, self.scattering_asymmetry)
  volumetric_fog_push_f32(words, self.light_intensity)
  volumetric_fog_push_f32(words, self.jitter_strength)
  while words.length() * 4 < VOLUMETRIC_FOG_UNIFORM_SIZE_BYTES {
    words.push(0U)
  }
  volumetric_fog_u32le_pack(words)
}

///|
pub struct ViewFogVolume {
  priv density_texture : @asset.Handle[@asset.Image]?
  priv uniform_buffer_offset : UInt
  priv exterior : Bool
}

///|
pub fn ViewFogVolume::has_density_texture(self : ViewFogVolume) -> Bool {
  self.density_texture is Some(_)
}

///|
pub fn ViewFogVolume::uniform_buffer_offset(self : ViewFogVolume) -> UInt {
  self.uniform_buffer_offset
}

///|
pub fn ViewFogVolume::density_texture_id(self : ViewFogVolume) -> Int {
  match self.density_texture {
    Some(texture) => texture.id()
    None => -1
  }
}

///|
pub fn ViewFogVolume::exterior(self : ViewFogVolume) -> Bool {
  self.exterior
}

///|
pub struct ViewVolumetricFog {
  priv volumes : Array[ViewFogVolume]
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
fn ViewVolumetricFog::ViewVolumetricFog() -> ViewVolumetricFog {
  ViewVolumetricFog::{ volumes: [] }
}

///|
fn ViewVolumetricFog::push(
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
pub fn ViewVolumetricFog::volumes(
  self : ViewVolumetricFog,
) -> ArrayView[ViewFogVolume] {
  self.volumes[:]
}

///|
pub struct VolumetricFogUniformBuffer {
  priv mut uniforms : Array[VolumetricFogUniform]
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
fn VolumetricFogUniformBuffer::push(
  self : VolumetricFogUniformBuffer,
  uniform : VolumetricFogUniform,
) -> UInt {
  let offset = self.uniforms.length() *
    VOLUMETRIC_FOG_UNIFORM_DYNAMIC_STRIDE_BYTES
  self.uniforms.push(uniform)
  offset.reinterpret_as_uint()
}

///|
pub fn VolumetricFogUniformBuffer::count(
  self : VolumetricFogUniformBuffer,
) -> Int {
  self.uniforms.length()
}

///|
pub fn VolumetricFogUniformBuffer::bytes(
  self : VolumetricFogUniformBuffer,
) -> Bytes {
  let bytes : Array[Byte] = []
  for uniform in self.uniforms {
    let uniform_bytes = uniform.bytes()
    for index in 0..<uniform_bytes.length() {
      match uniform_bytes.get(index) {
        Some(byte) => bytes.push(byte)
        None => ()
      }
    }
    while bytes.length() % VOLUMETRIC_FOG_UNIFORM_DYNAMIC_STRIDE_BYTES != 0 {
      bytes.push((0).to_byte())
    }
  }
  Bytes::from_array(bytes)
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
  fog_volumes_with_local_from_world : Array[(FogVolume, @math.Affine3)],
) -> PreparedVolumetricFogView {
  let view_fog = ViewVolumetricFog::ViewVolumetricFog()
  for entry in fog_volumes_with_local_from_world {
    let fog_volume = entry.0
    let local_from_world = entry.1
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
      clip_from_local: clip_from_local.to_cols_array(),
      uvw_from_world: volumetric_fog_uvw_from_local()
      .mul_affine3(local_from_world)
      .to_cols_array(),
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
  PreparedVolumetricFogView::{
    view_fog,
    uniform_count: fog_volumes_with_local_from_world.length(),
  }
}
