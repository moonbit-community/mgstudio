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
pub const VOLUMETRIC_FOG_SHADER_PATH : String = "pbr/volumetric_fog/volumetric_fog.wgsl"

///|
const VOLUMETRIC_FOG_BIND_GROUP_LAYOUT_MULTISAMPLED : UInt = 1U

///|
const VOLUMETRIC_FOG_BIND_GROUP_LAYOUT_DENSITY_TEXTURE : UInt = 2U

///|
const VOLUMETRIC_FOG_BIND_GROUP_LAYOUT_COUNT : Int = 4

///|
pub struct VolumetricFogBindGroupLayoutKey {
  priv bits : UInt
} derive(Eq, Debug)

///|
pub fn VolumetricFogBindGroupLayoutKey::VolumetricFogBindGroupLayoutKey() -> VolumetricFogBindGroupLayoutKey {
  { bits: 0U }
}

///|
pub fn VolumetricFogBindGroupLayoutKey::from_msaa_and_density(
  multisampled : Bool,
  has_density_texture : Bool,
) -> VolumetricFogBindGroupLayoutKey {
  let mut bits = 0U
  if multisampled {
    bits = bits | VOLUMETRIC_FOG_BIND_GROUP_LAYOUT_MULTISAMPLED
  }
  if has_density_texture {
    bits = bits | VOLUMETRIC_FOG_BIND_GROUP_LAYOUT_DENSITY_TEXTURE
  }
  { bits, }
}

///|
pub fn VolumetricFogBindGroupLayoutKey::bits(
  self : VolumetricFogBindGroupLayoutKey,
) -> UInt {
  self.bits
}

///|
pub fn VolumetricFogBindGroupLayoutKey::layout_index(
  self : VolumetricFogBindGroupLayoutKey,
) -> Int {
  self.bits.reinterpret_as_int()
}

///|
pub fn VolumetricFogBindGroupLayoutKey::is_multisampled(
  self : VolumetricFogBindGroupLayoutKey,
) -> Bool {
  (self.bits & VOLUMETRIC_FOG_BIND_GROUP_LAYOUT_MULTISAMPLED) != 0U
}

///|
pub fn VolumetricFogBindGroupLayoutKey::has_density_texture(
  self : VolumetricFogBindGroupLayoutKey,
) -> Bool {
  (self.bits & VOLUMETRIC_FOG_BIND_GROUP_LAYOUT_DENSITY_TEXTURE) != 0U
}

///|
pub fn VolumetricFogBindGroupLayoutKey::description(
  self : VolumetricFogBindGroupLayoutKey,
) -> String {
  if self.bits == 0U {
    return "volumetric lighting view bind group layout"
  }
  let labels : Array[String] = []
  if self.has_density_texture() {
    labels.push("density texture")
  }
  if self.is_multisampled() {
    labels.push("multisampled")
  }
  "volumetric lighting view bind group layout (" + labels.join(", ") + ")"
}

///|
fn volumetric_fog_bind_group_layout_key_from_bits(
  bits : Int,
) -> VolumetricFogBindGroupLayoutKey {
  { bits: bits.reinterpret_as_uint() }
}

///|
pub fn VolumetricFogBindGroupLayoutKey::bind_group_layout_descriptor(
  self : VolumetricFogBindGroupLayoutKey,
) -> @render_resource.BindGroupLayoutDescriptor {
  let entries : Array[@render_resource.BindGroupLayoutEntry] = [
    @render_resource.BindGroupLayoutEntry::new(
      0,
      @render_resource.SHADER_STAGE_VERTEX_FRAGMENT,
      BufferBinding(
        Uniform,
        true,
        VOLUMETRIC_FOG_UNIFORM_SIZE_BYTES.to_uint64(),
      ),
    ),
    @render_resource.BindGroupLayoutEntry::new(
      1,
      @render_resource.SHADER_STAGE_FRAGMENT,
      TextureBinding(Depth, D2, self.is_multisampled()),
    ),
  ]
  if self.has_density_texture() {
    entries.push(
      @render_resource.BindGroupLayoutEntry::new(
        2,
        @render_resource.SHADER_STAGE_FRAGMENT,
        TextureBinding(Float(true), D3, false),
      ),
    )
    entries.push(
      @render_resource.BindGroupLayoutEntry::new(
        3,
        @render_resource.SHADER_STAGE_FRAGMENT,
        SamplerBinding(Filtering),
      ),
    )
  }
  @render_resource.BindGroupLayoutDescriptor::new(self.description(), entries)
}

///|
pub fn volumetric_fog_bind_group_layout_descriptors() -> Array[
  @render_resource.BindGroupLayoutDescriptor,
] {
  let descriptors : Array[@render_resource.BindGroupLayoutDescriptor] = []
  for bits in 0..<VOLUMETRIC_FOG_BIND_GROUP_LAYOUT_COUNT {
    descriptors.push(
      volumetric_fog_bind_group_layout_key_from_bits(bits).bind_group_layout_descriptor(),
    )
  }
  descriptors
}

///|
pub struct VolumetricFogPipeline {
  shader_path : String
  mesh_view_layouts : @mesh_view_layout.MeshPipelineViewLayouts
  volumetric_view_bind_group_layouts : Array[
    @render_resource.BindGroupLayoutDescriptor,
  ]
}

///|
let ecs_key_volumetric_fog_pipeline : @ecs.ResourceKey[VolumetricFogPipeline] = @ecs.register_resource(
  debug_name="mgstudio_pbr::VolumetricFogPipeline",
)

///|
pub impl @app.Resource for VolumetricFogPipeline with fn resource() {
  ecs_key_volumetric_fog_pipeline
}

///|
pub fn VolumetricFogPipeline::VolumetricFogPipeline() -> VolumetricFogPipeline {
  {
    shader_path: VOLUMETRIC_FOG_SHADER_PATH,
    mesh_view_layouts: @mesh_view_layout.render3d_mesh_pipeline_view_layouts(
      false, false,
    ),
    volumetric_view_bind_group_layouts: volumetric_fog_bind_group_layout_descriptors(),
  }
}

///|
pub fn VolumetricFogPipeline::shader_path(
  self : VolumetricFogPipeline,
) -> String {
  self.shader_path
}

///|
pub fn VolumetricFogPipeline::mesh_view_layouts(
  self : VolumetricFogPipeline,
) -> @mesh_view_layout.MeshPipelineViewLayouts {
  self.mesh_view_layouts
}

///|
pub fn VolumetricFogPipeline::volumetric_view_bind_group_layouts(
  self : VolumetricFogPipeline,
) -> Array[@render_resource.BindGroupLayoutDescriptor] {
  self.volumetric_view_bind_group_layouts
}

///|
fn volumetric_fog_shader_def_vals(
  shader_defs : Array[String],
) -> Array[@render_resource.ShaderDefVal] {
  let values : Array[@render_resource.ShaderDefVal] = []
  for shader_def in shader_defs {
    values.push(Flag(shader_def))
  }
  values
}

///|
fn volumetric_fog_blend_state() -> @render_resource.BlendState {
  BlendState(
    color=BlendComponent(
      src_factor=@wgpu.BLEND_FACTOR_ONE,
      dst_factor=@wgpu.BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
      operation=@wgpu.BLEND_OPERATION_ADD,
    ),
    alpha=BlendComponent(
      src_factor=@wgpu.BLEND_FACTOR_ZERO,
      dst_factor=@wgpu.BLEND_FACTOR_ONE,
      operation=@wgpu.BLEND_OPERATION_ADD,
    ),
  )
}

///|
pub struct VolumetricFogPipelineKey {
  mesh_pipeline_view_key : @mesh_view_layout.MeshPipelineViewLayoutKey
  target_format : UInt
  vertex_buffer_layout : @mesh.VertexBufferLayout
  has_density_texture : Bool
}

///|
pub fn VolumetricFogPipelineKey::VolumetricFogPipelineKey(
  mesh_pipeline_view_key~ : @mesh_view_layout.MeshPipelineViewLayoutKey,
  target_format~ : UInt,
  vertex_buffer_layout~ : @mesh.VertexBufferLayout,
  has_density_texture~ : Bool,
) -> VolumetricFogPipelineKey {
  {
    mesh_pipeline_view_key,
    target_format,
    vertex_buffer_layout,
    has_density_texture,
  }
}

///|
pub fn VolumetricFogPipelineKey::mesh_pipeline_view_key(
  self : VolumetricFogPipelineKey,
) -> @mesh_view_layout.MeshPipelineViewLayoutKey {
  self.mesh_pipeline_view_key
}

///|
pub fn VolumetricFogPipelineKey::target_format(
  self : VolumetricFogPipelineKey,
) -> UInt {
  self.target_format
}

///|
pub fn VolumetricFogPipelineKey::vertex_buffer_layout(
  self : VolumetricFogPipelineKey,
) -> @mesh.VertexBufferLayout {
  self.vertex_buffer_layout
}

///|
pub fn VolumetricFogPipelineKey::has_density_texture(
  self : VolumetricFogPipelineKey,
) -> Bool {
  self.has_density_texture
}

///|
pub fn VolumetricFogPipelineKey::bind_group_layout_key(
  self : VolumetricFogPipelineKey,
) -> VolumetricFogBindGroupLayoutKey {
  VolumetricFogBindGroupLayoutKey::from_msaa_and_density(
    (
      self.mesh_pipeline_view_key.bits() &
      @mesh_view_layout.MESH_VIEW_LAYOUT_MULTISAMPLED
    ) !=
    0U,
    self.has_density_texture,
  )
}

///|
pub fn VolumetricFogPipelineKey::shader_defs(
  self : VolumetricFogPipelineKey,
) -> Array[String] {
  let defs : Array[String] = ["SHADOW_FILTER_METHOD_HARDWARE_2X2"]
  let bits = self.mesh_pipeline_view_key.bits()
  if (bits & @mesh_view_layout.MESH_VIEW_LAYOUT_MULTISAMPLED) != 0U {
    defs.push("MULTISAMPLED")
  }
  if (bits & @mesh_view_layout.MESH_VIEW_LAYOUT_ATMOSPHERE) != 0U {
    defs.push("ATMOSPHERE")
  }
  if self.has_density_texture {
    defs.push("DENSITY_TEXTURE")
  }
  defs
}

///|
pub fn VolumetricFogPipeline::specialize(
  self : VolumetricFogPipeline,
  key : VolumetricFogPipelineKey,
) -> @render_resource.RenderPipelineDescriptor {
  let bind_group_layout_key = key.bind_group_layout_key()
  let layout_index = bind_group_layout_key.layout_index()
  if layout_index < 0 ||
    layout_index >= self.volumetric_view_bind_group_layouts.length() {
    abort("volumetric fog bind group layout key out of range")
  }
  let shader_defs = volumetric_fog_shader_def_vals(key.shader_defs())
  let layout = self.mesh_view_layouts.get_view_layout(
    key.mesh_pipeline_view_key,
  )
  @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor()
  .with_label(Some("volumetric lighting pipeline"))
  .with_layout([
    layout.main_bind_group_layout_descriptor(),
    self.volumetric_view_bind_group_layouts[layout_index],
  ])
  .with_vertex(
    @render_resource.VertexState::new(
      Some(self.shader_path),
      shader_defs.copy(),
      None,
      [key.vertex_buffer_layout],
    ),
  )
  .with_primitive(
    @render_resource.PrimitiveState::PrimitiveState().with_cull_mode(
      Some(@wgpu.CULL_MODE_BACK),
    ),
  )
  .with_fragment(
    Some(
      @render_resource.FragmentState::new(
        Some(self.shader_path),
        shader_defs,
        None,
        [
          Some(
            @render_resource.ColorTargetState::new(
              key.target_format,
              @wgpu.COLOR_WRITE_MASK_ALL,
              blend=Some(volumetric_fog_blend_state()),
            ),
          ),
        ],
      ),
    ),
  )
}

///|
pub struct VolumetricFogRenderWorldEntity {
  priv render_entity : @core.Entity
  priv main_entity : @render.MainEntity
}

///|
pub fn VolumetricFogRenderWorldEntity::new(
  render_entity : @core.Entity,
  main_entity : @render.MainEntity,
) -> VolumetricFogRenderWorldEntity {
  { render_entity, main_entity }
}

///|
pub fn VolumetricFogRenderWorldEntity::render_entity(
  self : VolumetricFogRenderWorldEntity,
) -> @core.Entity {
  self.render_entity
}

///|
pub fn VolumetricFogRenderWorldEntity::main_entity(
  self : VolumetricFogRenderWorldEntity,
) -> @render.MainEntity {
  self.main_entity
}

///|
pub struct VolumetricFogRenderWorldStorageCounts {
  priv view_count : Int
  priv volume_count : Int
  priv transformed_volume_count : Int
  priv light_count : Int
}

///|
pub fn VolumetricFogRenderWorldStorageCounts::view_count(
  self : VolumetricFogRenderWorldStorageCounts,
) -> Int {
  self.view_count
}

///|
pub fn VolumetricFogRenderWorldStorageCounts::volume_count(
  self : VolumetricFogRenderWorldStorageCounts,
) -> Int {
  self.volume_count
}

///|
pub fn VolumetricFogRenderWorldStorageCounts::transformed_volume_count(
  self : VolumetricFogRenderWorldStorageCounts,
) -> Int {
  self.transformed_volume_count
}

///|
pub fn VolumetricFogRenderWorldStorageCounts::light_count(
  self : VolumetricFogRenderWorldStorageCounts,
) -> Int {
  self.light_count
}

///|
pub fn register_volumetric_fog_render_world_components(
  render_world : @ecs.World,
) -> Unit {
  let registrator = render_world.components_registrator()
  ignore(registrator.register_component_by_key(@render.ecs_key_main_entity))
  ignore(registrator.register_component_by_key(@light.ecs_key_volumetric_fog))
  ignore(registrator.register_component_by_key(@light.ecs_key_fog_volume))
  ignore(registrator.register_component_by_key(@light.ecs_key_volumetric_light))
  ignore(
    registrator.register_component_by_key(@transform.ecs_key_global_transform),
  )
  ignore(
    registrator.register_component_by_key(
      ViewVolumetricFogPipelines::component(),
    ),
  )
  ignore(registrator.register_component_by_key(ViewVolumetricFog::component()))
}

///|
pub fn volumetric_fog_render_world_entity(
  render_world : @ecs.World,
  render_entity : @core.Entity,
) -> VolumetricFogRenderWorldEntity? {
  match
    (try! render_world.get_by_key(render_entity, @render.ecs_key_main_entity)) {
    Some(main_entity) =>
      Some(VolumetricFogRenderWorldEntity::new(render_entity, main_entity))
    None => None
  }
}

///|
pub fn volumetric_fog_render_world_storage_counts(
  render_world : @ecs.World,
) -> VolumetricFogRenderWorldStorageCounts {
  let mut view_count = 0
  let mut volume_count = 0
  let mut transformed_volume_count = 0
  let mut light_count = 0
  render_world.for_each_component(@light.ecs_key_volumetric_fog, fn(
    _entity,
    _volumetric_fog,
  ) {
    view_count = view_count + 1
  })
  render_world.for_each_component(@light.ecs_key_fog_volume, fn(
    entity,
    _fog_volume,
  ) {
    volume_count = volume_count + 1
    if (try! render_world.contains_by_key(
        entity, @transform.ecs_key_global_transform,
      )) {
      transformed_volume_count = transformed_volume_count + 1
    }
  })
  render_world.for_each_component(@light.ecs_key_volumetric_light, fn(
    _entity,
    _volumetric_light,
  ) {
    light_count = light_count + 1
  })
  { view_count, volume_count, transformed_volume_count, light_count }
}

///|
pub fn volumetric_fog_render_world_volume_inputs(
  render_world : @ecs.World,
) -> Array[(@light.FogVolume, @math.Affine3)] {
  let inputs : Array[(@light.FogVolume, @math.Affine3)] = []
  render_world.for_each_component(@light.ecs_key_fog_volume, fn(
    entity,
    fog_volume,
  ) {
    match
      (try! render_world.get_by_key(entity, @transform.ecs_key_global_transform)) {
      Some(global_transform) =>
        inputs.push((fog_volume, global_transform.affine().inverse()))
      None => ()
    }
  })
  inputs
}

///|
fn volumetric_fog_extract_render_entity(
  source_world : @ecs.World,
  source_entity : @core.Entity,
) -> @core.Entity? {
  match
    (try! source_world.get_by_key(source_entity, @render.ecs_key_render_entity)) {
    Some(render_entity) => Some(render_entity.id())
    None => None
  }
}

///|
fn remove_volumetric_fog_render_view_state(
  render_world : @ecs.World,
  render_entity : @core.Entity,
) -> Unit {
  ignore(
    render_world.remove_by_key(render_entity, @light.ecs_key_volumetric_fog) catch {
      _ => false
    },
  )
  ignore(
    render_world.remove_by_key(
      render_entity,
      ViewVolumetricFogPipelines::component(),
    ) catch {
      _ => false
    },
  )
  ignore(
    render_world.remove_by_key(render_entity, ViewVolumetricFog::component()) catch {
      _ => false
    },
  )
}

///|
fn extract_volumetric_fog_from_worlds(
  source_world : @ecs.World,
  render_world : @ecs.World,
) -> Unit {
  register_volumetric_fog_render_world_components(render_world)
  let view_targets : Array[(@core.Entity, @light.VolumetricFog)] = []
  let fog_volumes : Array[
    (@core.Entity, @light.FogVolume, @transform.GlobalTransform),
  ] = []
  let volumetric_lights : Array[(@core.Entity, @light.VolumetricLight)] = []
  source_world.for_each_component(@light.ecs_key_volumetric_fog, fn(
    source_entity,
    volumetric_fog,
  ) {
    match volumetric_fog_extract_render_entity(source_world, source_entity) {
      Some(render_entity) => view_targets.push((render_entity, volumetric_fog))
      None => ()
    }
  })
  source_world.for_each_component(@light.ecs_key_fog_volume, fn(
    source_entity,
    fog_volume,
  ) {
    guard (try! source_world.get_by_key(
        source_entity, @transform.ecs_key_global_transform,
      ))
      is Some(global_transform) else {
      return
    }
    match volumetric_fog_extract_render_entity(source_world, source_entity) {
      Some(render_entity) =>
        fog_volumes.push((render_entity, fog_volume, global_transform))
      None => ()
    }
  })
  source_world.for_each_component(@light.ecs_key_volumetric_light, fn(
    source_entity,
    volumetric_light,
  ) {
    match volumetric_fog_extract_render_entity(source_world, source_entity) {
      Some(render_entity) =>
        volumetric_lights.push((render_entity, volumetric_light))
      None => ()
    }
  })

  if volumetric_lights.length() == 0 {
    for entry in view_targets {
      remove_volumetric_fog_render_view_state(render_world, entry.0)
    }
    for entry in fog_volumes {
      ignore(
        render_world.remove_by_key(entry.0, @light.ecs_key_fog_volume) catch {
          _ => false
        },
      )
    }
    return
  }

  for entry in view_targets {
    try! render_world.set_by_key(
      entry.0,
      @light.ecs_key_volumetric_fog,
      entry.1,
    )
  }
  for entry in fog_volumes {
    try! render_world.set_by_key(entry.0, @light.ecs_key_fog_volume, entry.1)
    try! render_world.set_by_key(
      entry.0,
      @transform.ecs_key_global_transform,
      entry.2,
    )
  }
  for entry in volumetric_lights {
    try! render_world.set_by_key(
      entry.0,
      @light.ecs_key_volumetric_light,
      entry.1,
    )
  }
}

///|
pub fn extract_volumetric_fog(render_world : @ecs.World) -> Unit {
  extract_volumetric_fog_from_worlds(
    @render.render_source_world(render_world),
    render_world,
  )
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
  priv x_axis : @math.Vec4
  priv y_axis : @math.Vec4
  priv z_axis : @math.Vec4
  priv w_axis : @math.Vec4
}

///|
pub fn VolumetricFogMat4::from_cols(
  x_axis : @math.Vec4,
  y_axis : @math.Vec4,
  z_axis : @math.Vec4,
  w_axis : @math.Vec4,
) -> VolumetricFogMat4 {
  { x_axis, y_axis, z_axis, w_axis }
}

///|
fn VolumetricFogMat4::from_affine3(
  transform : @math.Affine3,
) -> VolumetricFogMat4 {
  {
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
fn VolumetricFogMat4::mul(
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
fn VolumetricFogMat4::mul_affine3(
  self : VolumetricFogMat4,
  transform : @math.Affine3,
) -> VolumetricFogMat4 {
  self.mul(VolumetricFogMat4::from_affine3(transform))
}

///|
fn VolumetricFogMat4::to_cols_array(self : VolumetricFogMat4) -> Array[Float] {
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
pub(all) struct ViewVolumetricFogPipelines {
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
  { volumes: [] }
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
  { uniforms: [] }
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
pub fn prepare_volumetric_fog_view_uniforms(
  uniform_buffer : VolumetricFogUniformBuffer,
  volumetric_fog : VolumetricFog,
  world_from_view : @math.Affine3,
  clip_from_view : VolumetricFogMat4,
  fog_volumes_with_local_from_world : Array[(FogVolume, @math.Affine3)],
) -> ViewVolumetricFog {
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
    view_fog.push({
      density_texture: fog_volume.density_texture,
      uniform_buffer_offset,
      exterior: !interior,
    })
  }
  view_fog
}
