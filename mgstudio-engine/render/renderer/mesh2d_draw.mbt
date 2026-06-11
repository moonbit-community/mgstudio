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
const MESH2D_VERTEX_STRIDE_BYTES : UInt64 = 36UL

///|
const MESH2D_DEFAULT_VERTEX_SHADER_PATH : String = "sprite_render/mesh2d/mesh2d.wgsl"

///|
const MESH2D_COLOR_MATERIAL_SHADER_PATH : String = "sprite_render/mesh2d/color_material.wgsl"

///|
const MESH2D_WIREFRAME_SHADER_PATH : String = "sprite_render/mesh2d/wireframe2d.wgsl"

///|
const MESH2D_ALPHA_MODE_KIND_OPAQUE : Int = 0

///|
const MESH2D_ALPHA_MODE_KIND_MASK : Int = 1

///|
const MESH2D_ALPHA_MODE_KIND_BLEND : Int = 2

///|
const MESH2D_PER_OBJECT_BUFFER_BATCH_SIZE : Int = 128

///|
const MESH2D_PER_OBJECT_BUFFER_BATCH_SIZE_U64 : UInt64 = 128UL

///|
fn host_material2d_u32le_pack(xs : Array[UInt]) -> Bytes {
  let len = xs.length()
  Bytes::makei(len * 4, i => {
    let word = xs[i / 4]
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
fn host_material2d_f32le_pack(xs : Array[Float]) -> Bytes {
  host_material2d_u32le_pack(xs.map(f32_bits))
}

///|
pub(all) enum HostMaterial2dBindingValue {
  Uniform(Bytes)
  Texture(
    Int,
    HostMaterial2dTextureSampleType,
    HostMaterial2dTextureViewDimension
  )
  Sampler(Int)
}

///|
pub(all) enum HostMaterial2dTextureSampleType {
  Float
  UInt
} derive(Eq, Debug)

///|
pub(all) enum HostMaterial2dTextureViewDimension {
  D2
  D2Array
} derive(Eq, Debug)

///|
pub(all) struct HostMaterial2dBinding {
  binding : UInt
  value : HostMaterial2dBindingValue
}

///|
pub fn HostMaterial2dBinding::uniform(
  binding : UInt,
  bytes : Bytes,
) -> HostMaterial2dBinding {
  HostMaterial2dBinding::{ binding, value: Uniform(bytes) }
}

///|
pub fn HostMaterial2dBinding::texture(
  binding : UInt,
  texture_id : Int,
  sample_type? : HostMaterial2dTextureSampleType = HostMaterial2dTextureSampleType::Float,
  view_dimension? : HostMaterial2dTextureViewDimension = HostMaterial2dTextureViewDimension::D2,
) -> HostMaterial2dBinding {
  HostMaterial2dBinding::{
    binding,
    value: Texture(texture_id, sample_type, view_dimension),
  }
}

///|
pub fn HostMaterial2dBinding::sampler(
  binding : UInt,
  texture_id : Int,
) -> HostMaterial2dBinding {
  HostMaterial2dBinding::{ binding, value: Sampler(texture_id) }
}

///|
pub struct HostMaterial2dBindGroup {
  bindings : Array[HostMaterial2dBinding]
}

///|
pub fn HostMaterial2dBindGroup::new(
  bindings : Array[HostMaterial2dBinding],
) -> HostMaterial2dBindGroup {
  let normalized = bindings.copy()
  normalized.sort_by(fn(a, b) {
    if a.binding < b.binding {
      -1
    } else if a.binding > b.binding {
      1
    } else {
      0
    }
  })
  for i in 1..<normalized.length() {
    if normalized[i - 1].binding == normalized[i].binding {
      abort(
        "duplicate HostMaterial2d bind-group binding \{normalized[i].binding.to_string()}",
      )
    }
  }
  HostMaterial2dBindGroup::{ bindings: normalized }
}

///|
pub fn HostMaterial2dBindGroup::HostMaterial2dBindGroup() -> HostMaterial2dBindGroup {
  HostMaterial2dBindGroup::new([])
}

///|
fn host_material2d_color_material_bind_group(
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  alpha_mode_kind : Int,
  alpha_cutoff : Float,
  texture_id : Int,
  uv_offset_x : Float,
  uv_offset_y : Float,
  uv_scale_x : Float,
  uv_scale_y : Float,
) -> HostMaterial2dBindGroup {
  let flags = (if texture_id >= 0 { 1U } else { 0U }) |
    alpha_mode_kind.reinterpret_as_uint()
  let bindings : Array[HostMaterial2dBinding] = [
    HostMaterial2dBinding::uniform(
      0U,
      host_material2d_u32le_pack([
        f32_bits(color_r),
        f32_bits(color_g),
        f32_bits(color_b),
        f32_bits(color_a),
        f32_bits(uv_scale_x),
        f32_bits(0.0F),
        f32_bits(0.0F),
        f32_bits(0.0F),
        f32_bits(0.0F),
        f32_bits(uv_scale_y),
        f32_bits(0.0F),
        f32_bits(0.0F),
        f32_bits(uv_offset_x),
        f32_bits(uv_offset_y),
        f32_bits(1.0F),
        f32_bits(0.0F),
        flags,
        f32_bits(alpha_cutoff),
        0U,
        0U,
      ]),
    ),
    HostMaterial2dBinding::texture(1U, texture_id),
    HostMaterial2dBinding::sampler(2U, texture_id),
  ]
  HostMaterial2dBindGroup::new(bindings)
}

///|
fn host_material2d_wireframe_bind_group(
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
) -> HostMaterial2dBindGroup {
  HostMaterial2dBindGroup::new([
    HostMaterial2dBinding::uniform(
      0U,
      host_material2d_f32le_pack([color_r, color_g, color_b, color_a]),
    ),
  ])
}

///|
priv struct Mesh2dPipelineKey {
  color_format : @wgpu.TextureFormat
  primitive_topology : UInt
  blend_alpha : Bool
  with_depth : Bool
  hdr : Bool
  tonemap_in_shader : Bool
  deband_dither : Bool
  may_discard : Bool
  wireframe : Bool
  material_layout_key : String
  vertex_layout_key : String
  vertex_positions : Bool
  vertex_normals : Bool
  vertex_uvs : Bool
  vertex_tangents : Bool
  vertex_colors : Bool
  vertex_buffer_layout : @mesh.VertexBufferLayout
  vertex_shader_path : String
  fragment_shader_path : String
  descriptor_cache_key : String
  pipeline_descriptor : @render_resource.RenderPipelineDescriptor?
}

///|
fn mesh2d_align_up(value : UInt64, alignment : UInt64) -> UInt64 {
  if alignment == 0UL {
    return value
  }
  let remainder = value % alignment
  if remainder == 0UL {
    value
  } else {
    value + alignment - remainder
  }
}

///|
fn mesh2d_pipeline_cache_key(key : Mesh2dPipelineKey) -> String {
  let format_bits = key.color_format.raw.to_string()
  let topology_bits = key.primitive_topology.to_string()
  let blend_bits = if key.blend_alpha { "1" } else { "0" }
  let depth_bits = if key.with_depth { "1" } else { "0" }
  let hdr_bits = if key.hdr { "1" } else { "0" }
  let tonemap_bits = if key.tonemap_in_shader { "1" } else { "0" }
  let deband_bits = if key.deband_dither { "1" } else { "0" }
  let discard_bits = if key.may_discard { "1" } else { "0" }
  let wireframe_bits = if key.wireframe { "1" } else { "0" }
  "\{format_bits}_\{topology_bits}_\{blend_bits}\{depth_bits}\{hdr_bits}\{tonemap_bits}\{deband_bits}\{discard_bits}\{wireframe_bits}_\{key.material_layout_key}_\{key.vertex_layout_key}_\{key.vertex_shader_path}_\{key.fragment_shader_path}_\{key.descriptor_cache_key}"
}

///|
fn mesh2d_pipeline_define_keys(key : Mesh2dPipelineKey) -> Array[String] {
  let defines : Array[String] = []
  if key.vertex_positions {
    defines.push("VERTEX_POSITIONS")
  }
  if key.vertex_normals {
    defines.push("VERTEX_NORMALS")
  }
  if key.vertex_uvs {
    defines.push("VERTEX_UVS")
  }
  if key.vertex_tangents {
    defines.push("VERTEX_TANGENTS")
  }
  if key.vertex_colors {
    defines.push("VERTEX_COLORS")
  }
  if key.tonemap_in_shader {
    defines.push("TONEMAP_IN_SHADER")
    defines.push("TONEMAP_METHOD_NONE")
    if key.deband_dither {
      defines.push("DEBAND_DITHER")
    }
  }
  if key.may_discard {
    defines.push("MAY_DISCARD")
  }
  defines
}

///|
fn mesh2d_vertex_layouts_cache_key(
  layouts : Array[@mesh.VertexBufferLayout],
) -> String {
  let mut key = ""
  for layout in layouts {
    if key != "" {
      key = key + ";"
    }
    key = key + mesh2d_vertex_layout_cache_key(layout)
  }
  key
}

///|
fn mesh2d_option_string_cache_key(value : String?) -> String {
  match value {
    Some(text) => "some(\{text})"
    None => "none"
  }
}

///|
fn mesh2d_option_uint_cache_key(value : UInt?) -> String {
  match value {
    Some(bits) => "some(\{bits.to_string()})"
    None => "none"
  }
}

///|
fn mesh2d_shader_def_cache_key(def : @render_resource.ShaderDefVal) -> String {
  match def {
    Flag(name) => "flag:\{name}"
    Bool(name, value) => "bool:\{name}=\{value.to_string()}"
    Int(name, value) => "int:\{name}=\{value.to_string()}"
    UInt(name, value) => "uint:\{name}=\{value.to_string()}"
    String(name, value) => "string:\{name}=\{value}"
  }
}

///|
fn mesh2d_shader_defs_cache_key(
  defs : Array[@render_resource.ShaderDefVal],
) -> String {
  let mut key = ""
  for def in defs {
    if key != "" {
      key = key + ","
    }
    key = key + mesh2d_shader_def_cache_key(def)
  }
  key
}

///|
fn mesh2d_color_targets_cache_key(
  targets : Array[@render_resource.ColorTargetState?],
) -> String {
  let mut key = ""
  for target in targets {
    if key != "" {
      key = key + ","
    }
    let target_key = match target {
      Some(value) =>
        "target(\{value.format.to_string()}:\{value.write_mask.to_string()})"
      None => "none"
    }
    key = key + target_key
  }
  key
}

///|
fn mesh2d_descriptor_cache_key(
  descriptor : @render_resource.RenderPipelineDescriptor?,
) -> String {
  match descriptor {
    None => "descriptor:none"
    Some(desc) => {
      let fragment_key = match desc.fragment {
        Some(fragment) =>
          "fragment(\{mesh2d_option_string_cache_key(fragment.shader)}:\{mesh2d_shader_defs_cache_key(fragment.shader_defs)}:\{mesh2d_option_string_cache_key(fragment.entry_point)}:\{mesh2d_color_targets_cache_key(fragment.targets)})"
        None => "fragment:none"
      }
      let depth_key = match desc.depth_stencil {
        Some(depth) =>
          "depth(\{depth.format.to_string()}:\{depth.depth_write_enabled.to_string()}:\{depth.depth_compare.to_string()}:\{depth.bias_slope_scale.to_string()})"
        None => "depth:none"
      }
      "descriptor(\{mesh2d_option_string_cache_key(desc.label)}:\{mesh2d_option_string_cache_key(desc.vertex.shader)}:\{mesh2d_shader_defs_cache_key(desc.vertex.shader_defs)}:\{mesh2d_option_string_cache_key(desc.vertex.entry_point)}:\{mesh2d_vertex_layouts_cache_key(desc.vertex.buffers)}:\{desc.primitive.topology.to_string()}:\{desc.primitive.front_face.to_string()}:\{mesh2d_option_uint_cache_key(desc.primitive.cull_mode)}:\{mesh2d_option_uint_cache_key(desc.primitive.polygon_mode)}:\{depth_key}:\{desc.multisample.count.to_string()}:\{desc.multisample.mask.to_string()}:\{desc.multisample.alpha_to_coverage_enabled.to_string()}:\{fragment_key})"
    }
  }
}

///|
fn mesh2d_vertex_attribute_descriptor(
  attribute : @mesh.MeshVertexAttribute,
  shader_location : Int,
) -> @mesh.VertexAttributeDescriptor {
  @mesh.VertexAttributeDescriptor::new(
    shader_location~,
    id=attribute.id(),
    name=attribute.name(),
  )
}

///|
fn mesh2d_default_mesh_vertex_buffer_layout() -> @mesh.MeshVertexBufferLayout {
  @mesh.MeshVertexBufferLayout::new(
    attribute_ids=[
      @mesh.MeshVertexAttribute::position().id(),
      @mesh.MeshVertexAttribute::uv_0().id(),
      @mesh.MeshVertexAttribute::color().id(),
    ],
    layout=@mesh.VertexBufferLayout::new(
      array_stride=MESH2D_VERTEX_STRIDE_BYTES.to_int(),
      step_mode=@mesh.MeshVertexStepMode::Vertex,
      attributes=[
        @mesh.VertexAttribute::new(
          offset=0,
          format=@mesh.MeshVertexFormat::Float32x3,
          shader_location=0,
        ),
        @mesh.VertexAttribute::new(
          offset=12,
          format=@mesh.MeshVertexFormat::Float32x2,
          shader_location=2,
        ),
        @mesh.VertexAttribute::new(
          offset=20,
          format=@mesh.MeshVertexFormat::Float32x4,
          shader_location=4,
        ),
      ],
    ),
  )
}

///|
fn mesh2d_material_vertex_attribute_descriptors(
  layout : @mesh.MeshVertexBufferLayout,
) -> Array[@mesh.VertexAttributeDescriptor] {
  let descriptors : Array[@mesh.VertexAttributeDescriptor] = []
  if layout.contains(@mesh.MeshVertexAttribute::position().id()) {
    descriptors.push(
      mesh2d_vertex_attribute_descriptor(
        @mesh.MeshVertexAttribute::position(),
        0,
      ),
    )
  }
  if layout.contains(@mesh.MeshVertexAttribute::normal().id()) {
    descriptors.push(
      mesh2d_vertex_attribute_descriptor(@mesh.MeshVertexAttribute::normal(), 1),
    )
  }
  if layout.contains(@mesh.MeshVertexAttribute::uv_0().id()) {
    descriptors.push(
      mesh2d_vertex_attribute_descriptor(@mesh.MeshVertexAttribute::uv_0(), 2),
    )
  }
  if layout.contains(@mesh.MeshVertexAttribute::tangent().id()) {
    descriptors.push(
      mesh2d_vertex_attribute_descriptor(
        @mesh.MeshVertexAttribute::tangent(),
        3,
      ),
    )
  }
  if layout.contains(@mesh.MeshVertexAttribute::color().id()) {
    descriptors.push(
      mesh2d_vertex_attribute_descriptor(@mesh.MeshVertexAttribute::color(), 4),
    )
  }
  descriptors
}

///|
fn mesh2d_material_vertex_buffer_layout(
  layout : @mesh.MeshVertexBufferLayout,
) -> @mesh.VertexBufferLayout? {
  Some(layout.get_layout(mesh2d_material_vertex_attribute_descriptors(layout))) catch {
    _ => None
  }
}

///|
fn mesh2d_material_vertex_layout_cache_key(
  layout : @mesh.MeshVertexBufferLayout,
  vertex_buffer_layout : @mesh.VertexBufferLayout,
) -> String {
  let mut key = mesh2d_vertex_layout_cache_key(vertex_buffer_layout)
  for id in layout.attribute_ids() {
    key = key + ";\{id.value().to_string()}"
  }
  key
}

///|
test "mesh2d material vertex layout follows Bevy attribute descriptors" {
  let mesh_layout = @mesh.MeshVertexBufferLayout::new(
    attribute_ids=[
      @mesh.MeshVertexAttribute::position().id(),
      @mesh.MeshVertexAttribute::uv_0().id(),
    ],
    layout=@mesh.VertexBufferLayout::new(
      array_stride=20,
      step_mode=@mesh.MeshVertexStepMode::Vertex,
      attributes=[
        @mesh.VertexAttribute::new(
          offset=0,
          format=@mesh.MeshVertexFormat::Float32x3,
          shader_location=0,
        ),
        @mesh.VertexAttribute::new(
          offset=12,
          format=@mesh.MeshVertexFormat::Float32x2,
          shader_location=1,
        ),
      ],
    ),
  )
  let vertex_layout = mesh2d_material_vertex_buffer_layout(mesh_layout).unwrap()
  debug_inspect(vertex_layout.array_stride, content="20")
  debug_inspect(vertex_layout.attributes.length(), content="2")
  debug_inspect(vertex_layout.attributes[0].shader_location, content="0")
  debug_inspect(vertex_layout.attributes[1].shader_location, content="2")
  let key = mesh2d_pipeline_key_for_format(
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    mesh_layout,
    vertex_layout,
    false,
    true,
    false,
    false,
    false,
    false,
    "default",
    None,
    None,
    None,
  )
  let defines = mesh2d_pipeline_define_keys(key)
  debug_inspect(defines.contains("VERTEX_POSITIONS"), content="true")
  debug_inspect(defines.contains("VERTEX_UVS"), content="true")
  debug_inspect(defines.contains("VERTEX_COLORS"), content="false")
}

///|
test "mesh2d material vertex layout enables colors only when present" {
  let mesh_layout = mesh2d_default_mesh_vertex_buffer_layout()
  let vertex_layout = mesh2d_material_vertex_buffer_layout(mesh_layout).unwrap()
  debug_inspect(vertex_layout.attributes.length(), content="3")
  debug_inspect(vertex_layout.attributes[2].shader_location, content="4")
  let key = mesh2d_pipeline_key_for_format(
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    mesh_layout,
    vertex_layout,
    false,
    true,
    false,
    false,
    false,
    false,
    "default",
    None,
    None,
    None,
  )
  let defines = mesh2d_pipeline_define_keys(key)
  debug_inspect(defines.contains("VERTEX_COLORS"), content="true")
}

///|
test "mesh2d pipeline cache key tracks Bevy specialization inputs" {
  let mesh_layout = mesh2d_default_mesh_vertex_buffer_layout()
  let vertex_layout = mesh2d_material_vertex_buffer_layout(mesh_layout).unwrap()
  let base = mesh2d_pipeline_key_for_format(
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    mesh_layout,
    vertex_layout,
    false,
    true,
    false,
    false,
    false,
    false,
    "0:1;1:2",
    None,
    None,
    None,
  )
  let line_list = mesh2d_pipeline_key_for_format(
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    @wgpu.PRIMITIVE_TOPOLOGY_LINE_LIST,
    mesh_layout,
    vertex_layout,
    false,
    true,
    false,
    false,
    false,
    false,
    "0:1;1:2",
    None,
    None,
    None,
  )
  let different_material_layout = mesh2d_pipeline_key_for_format(
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    mesh_layout,
    vertex_layout,
    false,
    true,
    false,
    false,
    false,
    false,
    "0:1;1:2;2:3",
    None,
    None,
    None,
  )
  let custom_shader = mesh2d_pipeline_key_for_format(
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    mesh_layout,
    vertex_layout,
    false,
    true,
    false,
    false,
    false,
    false,
    "0:1;1:2",
    Some("shaders/custom_mesh2d_vertex.wgsl"),
    Some("shaders/custom_mesh2d_fragment.wgsl"),
    None,
  )
  debug_inspect(
    mesh2d_pipeline_cache_key(base) == mesh2d_pipeline_cache_key(line_list),
    content="false",
  )
  debug_inspect(
    mesh2d_pipeline_cache_key(base) ==
    mesh2d_pipeline_cache_key(different_material_layout),
    content="false",
  )
  debug_inspect(
    mesh2d_pipeline_cache_key(base) == mesh2d_pipeline_cache_key(custom_shader),
    content="false",
  )
}

///|
test "mesh2d pipeline cache key tracks descriptor specialization inputs" {
  let mesh_layout = mesh2d_default_mesh_vertex_buffer_layout()
  let vertex_layout = mesh2d_material_vertex_buffer_layout(mesh_layout).unwrap()
  let descriptor = @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor()
    .with_vertex(
      @render_resource.VertexState::new(
        Some("shaders/specialized_vertex.wgsl"),
        [@render_resource.ShaderDefVal::UInt("SPECIALIZED_MODE", 7U)],
        Some("vertex"),
        [],
      ),
    )
    .with_fragment(
      Some(
        @render_resource.FragmentState::new(
          Some("shaders/specialized_fragment.wgsl"),
          [@render_resource.ShaderDefVal::Flag("SPECIALIZED_FRAGMENT")],
          Some("fragment"),
          [],
        ),
      ),
    )
  let base = mesh2d_pipeline_key_for_format(
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    mesh_layout,
    vertex_layout,
    false,
    true,
    false,
    false,
    false,
    false,
    "0:1;1:2",
    None,
    None,
    None,
  )
  let specialized = mesh2d_pipeline_key_for_format(
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    mesh_layout,
    vertex_layout,
    false,
    true,
    false,
    false,
    false,
    false,
    "0:1;1:2",
    None,
    None,
    Some(descriptor),
  )
  debug_inspect(
    mesh2d_pipeline_cache_key(base) == mesh2d_pipeline_cache_key(specialized),
    content="false",
  )
  debug_inspect(
    specialized.vertex_shader_path,
    content="\"shaders/specialized_vertex.wgsl\"",
  )
  debug_inspect(
    specialized.fragment_shader_path,
    content="\"shaders/specialized_fragment.wgsl\"",
  )
}

///|
test "mesh2d material bind group cache separates layout from data" {
  let base = HostMaterial2dBindGroup::new([
    HostMaterial2dBinding::uniform(0U, host_material2d_f32le_pack([1.0F])),
    HostMaterial2dBinding::texture(1U, 7),
    HostMaterial2dBinding::sampler(2U, 7),
  ])
  let different_uniform = HostMaterial2dBindGroup::new([
    HostMaterial2dBinding::uniform(0U, host_material2d_f32le_pack([2.0F])),
    HostMaterial2dBinding::texture(1U, 7),
    HostMaterial2dBinding::sampler(2U, 7),
  ])
  let different_layout = HostMaterial2dBindGroup::new([
    HostMaterial2dBinding::uniform(0U, host_material2d_f32le_pack([1.0F])),
    HostMaterial2dBinding::texture(
      1U,
      7,
      sample_type=HostMaterial2dTextureSampleType::UInt,
    ),
    HostMaterial2dBinding::sampler(2U, 7),
  ])
  debug_inspect(
    host_material2d_bind_group_layout_key(base) ==
    host_material2d_bind_group_layout_key(different_uniform),
    content="true",
  )
  debug_inspect(
    host_material2d_bind_group_hash(base) ==
    host_material2d_bind_group_hash(different_uniform),
    content="false",
  )
  debug_inspect(
    host_material2d_bind_group_layout_key(base) ==
    host_material2d_bind_group_layout_key(different_layout),
    content="false",
  )
}

///|
fn ensure_mesh2d_instance_uniform_binding(
  backend : GpuBackend,
  required_size : UInt64,
) -> (@wgpu.Buffer, @wgpu.BindGroup)? {
  guard backend.mesh2d_mesh_bgl is Some(bgl) else { return None }
  if backend.mesh2d_instance_buf is Some(uniform_buf) &&
    backend.mesh2d_instance_bg is Some(uniform_bg) &&
    backend.mesh2d_instance_capacity >= required_size {
    return Some((uniform_buf, uniform_bg))
  }
  let mut next_capacity = if backend.mesh2d_instance_capacity > 0UL {
    backend.mesh2d_instance_capacity
  } else {
    mesh2d_align_up(
      MESH2D_UNIFORM_DYNAMIC_STRIDE_BYTES * 1024UL,
      MESH2D_UNIFORM_DYNAMIC_STRIDE_BYTES,
    )
  }
  while next_capacity < required_size {
    next_capacity = next_capacity * 2UL
  }
  let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
  let uniform_buf = backend.device.create_buffer(size=next_capacity, usage~)
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  let ok = builder.add_buffer(
    0U,
    uniform_buf,
    size=MESH2D_UNIFORM_STRIDE_BYTES * MESH2D_PER_OBJECT_BUFFER_BATCH_SIZE_U64,
  )
  if !ok {
    builder.free()
    return None
  }
  let uniform_bg = builder.finish(
    backend.device,
    bgl,
    label="mgstudio_mesh2d_instance_uniform_bg",
  )
  backend.mesh2d_instance_buf = Some(uniform_buf)
  backend.mesh2d_instance_bg = Some(uniform_bg)
  backend.mesh2d_instance_capacity = next_capacity
  Some((uniform_buf, uniform_bg))
}

///|
fn mesh2d_strip_fragment_entry(source : String) -> String raise GpuBackendError {
  match split_once_text(source, "@fragment\nfn fragment(") {
    Some((prefix, _)) => prefix
    None =>
      fatal(
        "wgpu: failed to strip mesh2d fragment entry from registered source",
      )
  }
}

///|
fn mesh2d_vertex_shader_path_or_default(path : String?) -> String {
  match path {
    Some(value) => value
    None => MESH2D_DEFAULT_VERTEX_SHADER_PATH
  }
}

///|
fn mesh2d_fragment_shader_path_or_default(path : String?) -> String {
  match path {
    Some(value) => value
    None => MESH2D_COLOR_MATERIAL_SHADER_PATH
  }
}

///|
fn host_material2d_binding_layout_kind_key(
  value : HostMaterial2dBindingValue,
) -> Int {
  match value {
    Uniform(_) => 1
    Texture(
      _,
      HostMaterial2dTextureSampleType::Float,
      HostMaterial2dTextureViewDimension::D2
    ) => 2
    Texture(
      _,
      HostMaterial2dTextureSampleType::Float,
      HostMaterial2dTextureViewDimension::D2Array
    ) => 4
    Texture(
      _,
      HostMaterial2dTextureSampleType::UInt,
      HostMaterial2dTextureViewDimension::D2
    ) => 5
    Texture(
      _,
      HostMaterial2dTextureSampleType::UInt,
      HostMaterial2dTextureViewDimension::D2Array
    ) => 6
    Sampler(_) => 3
  }
}

///|
fn host_material2d_layout_signature(
  bind_group : HostMaterial2dBindGroup,
) -> Array[(UInt, Int)] {
  let signature : Array[(UInt, Int)] = []
  for binding in bind_group.bindings {
    signature.push(
      (binding.binding, host_material2d_binding_layout_kind_key(binding.value)),
    )
  }
  signature
}

///|
fn host_material2d_layout_signature_eq(
  lhs : Array[(UInt, Int)],
  rhs : Array[(UInt, Int)],
) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for i in 0..<lhs.length() {
    if lhs[i] != rhs[i] {
      return false
    }
  }
  true
}

///|
fn host_material2d_layout_signature_key(
  signature : Array[(UInt, Int)],
) -> String {
  let mut data = ""
  for i in 0..<signature.length() {
    let binding = signature[i]
    if i > 0 {
      data = "\{data};"
    }
    data = "\{data}\{binding.0.to_string()}:\{binding.1.to_string()}"
  }
  data
}

///|
fn host_material2d_bind_group_layout_key(
  bind_group : HostMaterial2dBindGroup,
) -> String {
  host_material2d_layout_signature_key(
    host_material2d_layout_signature(bind_group),
  )
}

///|
fn mesh2d_cache_hash_mix(hash : UInt64, word : UInt64) -> UInt64 {
  hash * 11400714819323198485UL + word + 0x9E3779B97F4A7C15UL
}

///|
fn host_material2d_layout_signature_hash(
  signature : Array[(UInt, Int)],
) -> UInt64 {
  let mut hash = 1469598103934665603UL
  for entry in signature {
    let (binding, kind) = entry
    hash = mesh2d_cache_hash_mix(hash, binding.to_uint64())
    hash = mesh2d_cache_hash_mix(hash, kind.reinterpret_as_uint().to_uint64())
  }
  hash
}

///|
fn host_material2d_bind_group_hash(
  bind_group : HostMaterial2dBindGroup,
) -> UInt64 {
  let mut hash = 1469598103934665603UL
  for binding in bind_group.bindings {
    hash = mesh2d_cache_hash_mix(hash, binding.binding.to_uint64())
    match binding.value {
      Uniform(bytes) => {
        hash = mesh2d_cache_hash_mix(hash, 1UL)
        hash = mesh2d_cache_hash_mix(hash, bytes.length().to_uint64())
        for byte in bytes {
          hash = mesh2d_cache_hash_mix(hash, byte.to_uint64())
        }
      }
      Texture(texture_id, sample_type, view_dimension) => {
        hash = mesh2d_cache_hash_mix(hash, 2UL)
        hash = mesh2d_cache_hash_mix(
          hash,
          texture_id.reinterpret_as_uint().to_uint64(),
        )
        hash = mesh2d_cache_hash_mix(
          hash,
          host_material2d_texture_sample_type_key(sample_type),
        )
        hash = mesh2d_cache_hash_mix(
          hash,
          host_material2d_texture_view_dimension_key(view_dimension),
        )
      }
      Sampler(texture_id) => {
        hash = mesh2d_cache_hash_mix(hash, 3UL)
        hash = mesh2d_cache_hash_mix(
          hash,
          texture_id.reinterpret_as_uint().to_uint64(),
        )
      }
    }
  }
  hash
}

///|
fn host_material2d_texture_sample_type_key(
  sample_type : HostMaterial2dTextureSampleType,
) -> UInt64 {
  match sample_type {
    HostMaterial2dTextureSampleType::Float => 1UL
    HostMaterial2dTextureSampleType::UInt => 2UL
  }
}

///|
fn host_material2d_texture_view_dimension_key(
  view_dimension : HostMaterial2dTextureViewDimension,
) -> UInt64 {
  match view_dimension {
    HostMaterial2dTextureViewDimension::D2 => 1UL
    HostMaterial2dTextureViewDimension::D2Array => 2UL
  }
}

///|
fn bytes_eq(lhs : Bytes, rhs : Bytes) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for i in 0..<lhs.length() {
    if lhs[i] != rhs[i] {
      return false
    }
  }
  true
}

///|
fn host_material2d_binding_value_eq(
  lhs : HostMaterial2dBindingValue,
  rhs : HostMaterial2dBindingValue,
) -> Bool {
  match (lhs, rhs) {
    (Uniform(lhs), Uniform(rhs)) => bytes_eq(lhs, rhs)
    (
      Texture(lhs, lhs_sample, lhs_dimension),
      Texture(rhs, rhs_sample, rhs_dimension),
    ) =>
      lhs == rhs && lhs_sample == rhs_sample && lhs_dimension == rhs_dimension
    (Sampler(lhs), Sampler(rhs)) => lhs == rhs
    _ => false
  }
}

///|
fn host_material2d_bind_group_key_eq(
  cached : Array[HostMaterial2dBinding],
  bind_group : HostMaterial2dBindGroup,
) -> Bool {
  if cached.length() != bind_group.bindings.length() {
    return false
  }
  for i in 0..<cached.length() {
    let lhs = cached[i]
    let rhs = bind_group.bindings[i]
    if lhs.binding != rhs.binding ||
      !host_material2d_binding_value_eq(lhs.value, rhs.value) {
      return false
    }
  }
  true
}

///|
fn host_material2d_bind_group_cache_key(
  bind_group : HostMaterial2dBindGroup,
) -> Array[HostMaterial2dBinding] {
  let cloned : Array[HostMaterial2dBinding] = []
  for binding in bind_group.bindings {
    let cloned_value = match binding.value {
      Uniform(bytes) => Uniform(bytes)
      Texture(texture_id, sample_type, view_dimension) =>
        Texture(texture_id, sample_type, view_dimension)
      Sampler(texture_id) => Sampler(texture_id)
    }
    cloned.push(HostMaterial2dBinding::{
      binding: binding.binding,
      value: cloned_value,
    })
  }
  cloned
}

///|
fn host_material2d_default_layout_signature() -> Array[(UInt, Int)] {
  [(0U, 1), (1U, 2), (2U, 3)]
}

///|
fn load_wgsl_with_defines_required_mesh2d_material(
  vertex_shader_path : String?,
  fragment_shader_path : String?,
  define_keys : Array[String],
  pipeline_descriptor? : @render_resource.RenderPipelineDescriptor? = None,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  for key in define_keys {
    defines.set(key, true)
  }
  let value_defines = default_wgsl_value_defines()
  value_defines.set("MATERIAL_BIND_GROUP", wgsl_def_int(2))
  value_defines.set(
    "PER_OBJECT_BUFFER_BATCH_SIZE",
    wgsl_def_int(MESH2D_PER_OBJECT_BUFFER_BATCH_SIZE),
  )
  match pipeline_descriptor {
    Some(descriptor) => {
      let apply_defs = fn(shader_defs : Array[@render_resource.ShaderDefVal]) {
        for shader_def in shader_defs {
          match shader_def {
            Flag(name) => defines.set(name, true)
            Bool(name, value) => defines.set(name, value)
            Int(name, value) =>
              value_defines.set(name, @wgsl_common.ShaderDefValue::Int(value))
            UInt(name, value) =>
              value_defines.set(name, @wgsl_common.ShaderDefValue::UInt(value))
            String(name, value) =>
              value_defines.set(name, @wgsl_common.ShaderDefValue::Raw(value))
          }
        }
      }
      apply_defs(descriptor.vertex.shader_defs)
      match descriptor.fragment {
        Some(fragment) => apply_defs(fragment.shader_defs)
        None => ()
      }
    }
    None => ()
  }
  let mesh_source = registered_wgsl_source_required(
    mesh2d_vertex_shader_path_or_default(vertex_shader_path),
  )
  let material_source = registered_wgsl_source_required(
    mesh2d_fragment_shader_path_or_default(fragment_shader_path),
  )
  let combined_source = "\{mesh2d_strip_fragment_entry(mesh_source)}\n\{material_source}"
  preprocess_wgsl_source("", combined_source, defines, value_defines)
}

///|
fn ensure_mesh2d_resources(backend : GpuBackend) -> Unit raise GpuBackendError {
  if backend.mesh_pipeline_layout is None {
    let view_stage = ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT)
    let fragment_stage = ss(@wgpu.SHADER_STAGE_FRAGMENT)
    let view_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=4UL)
    let view_ok = view_builder.add_buffer(
        0U,
        view_stage,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        has_dynamic_offset=true,
      ) &&
      view_builder.add_buffer(1U, view_stage, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
      view_builder.add_texture(
        2U,
        fragment_stage,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_3D,
      ) &&
      view_builder.add_sampler(
        3U,
        fragment_stage,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      )
    if !view_ok {
      view_builder.free()
      fatal("wgpu: failed to build mesh2d view bind group layout")
    }
    let bgl_view = view_builder.finish(
      backend.device,
      label="mgstudio_mesh2d_view_bind_group_layout",
    )
    let mesh_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=1UL)
    let mesh_ok = mesh_builder.add_buffer(
      0U,
      view_stage,
      @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
      has_dynamic_offset=true,
    )
    if !mesh_ok {
      mesh_builder.free()
      fatal("wgpu: failed to build mesh2d bind group layout")
    }
    let bgl_mesh = mesh_builder.finish(
      backend.device,
      label="mgstudio_mesh2d_mesh_bind_group_layout",
    )
    let material_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=3UL)
    let material_ok = material_builder.add_buffer(
        0U,
        fragment_stage,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
      ) &&
      material_builder.add_texture(
        1U,
        fragment_stage,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        2U,
        fragment_stage,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      )
    if !material_ok {
      material_builder.free()
      fatal("wgpu: failed to build mesh2d material bind group layout")
    }
    let bgl_material = material_builder.finish(
      backend.device,
      label="mgstudio_mesh2d_material_bind_group_layout",
    )
    let pipeline_layout = create_pipeline_layout_3(
      backend.device,
      bgl_view,
      bgl_mesh,
      bgl_material,
    )
    pipeline_layout.set_label("mgstudio_mesh2d_pipeline_layout")
    let view_buf = backend.device.create_buffer(
      size=MESH2D_VIEW_BUFFER_SIZE,
      usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
    )
    let globals_buf = backend.device.create_buffer(
      size=MESH2D_GLOBALS_BUFFER_SIZE,
      usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
    )
    let lut_texture = backend.device.create_texture_u32(
      1U,
      1U,
      1U,
      @wgpu.TextureUsage::from_u64(
        @wgpu.TEXTURE_USAGE_TEXTURE_BINDING | @wgpu.TEXTURE_USAGE_COPY_DST,
      ),
      @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_3D),
      tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    )
    let lut_view = lut_texture.create_view_u32(
      tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
      @wgpu.TEXTURE_VIEW_DIMENSION_3D,
      @wgpu.TEXTURE_ASPECT_ALL,
      0U,
      1U,
      0U,
      1U,
    )
    let lut_sampler = backend.device.create_sampler_linear_clamp()
    let view_bg_builder = @wgpu.BindGroupBuilder::new(max_entries=4UL)
    let view_bg_ok = view_bg_builder.add_buffer(
        0U,
        view_buf,
        size=MESH2D_VIEW_BUFFER_SIZE,
      ) &&
      view_bg_builder.add_buffer(1U, globals_buf) &&
      view_bg_builder.add_texture_view(2U, lut_view) &&
      view_bg_builder.add_sampler(3U, lut_sampler)
    if !view_bg_ok {
      view_bg_builder.free()
      fatal("wgpu: failed to build mesh2d view bind group")
    }
    let view_bg = view_bg_builder.finish(
      backend.device,
      bgl_view,
      label="mgstudio_mesh2d_view_bind_group",
    )
    backend.mesh2d_view_bgl = Some(bgl_view)
    backend.mesh2d_mesh_bgl = Some(bgl_mesh)
    backend.mesh2d_material_bgl = Some(bgl_material)
    backend.mesh_pipeline_layout = Some(pipeline_layout)
    backend.mesh2d_view_buf = Some(view_buf)
    backend.mesh2d_globals_buf = Some(globals_buf)
    backend.mesh2d_lut_texture = Some(lut_texture)
    backend.mesh2d_lut_view = Some(lut_view)
    backend.mesh2d_lut_sampler = Some(lut_sampler)
    backend.mesh2d_view_bg = Some(view_bg)
    backend.mesh2d_instance_buf = None
    backend.mesh2d_instance_bg = None
    backend.mesh2d_instance_capacity = 0UL
    backend.mesh2d_instance_used = 0
    mesh2d_reset_pending_batch(backend)
    backend.mesh2d_pipeline_cache.clear()
    backend.mesh2d_pipeline_cache_index.clear()
    backend.mesh2d_material_layout_cache.clear()
    backend.mesh2d_material_layout_cache_index.clear()
    backend.mesh2d_material_bg_cache.clear()
    backend.mesh2d_material_bg_cache_index.clear()
    if ensure_mesh2d_instance_uniform_binding(
        backend,
        MESH2D_UNIFORM_DYNAMIC_STRIDE_BYTES,
      )
      is None {
      fatal("wgpu: failed to initialize mesh2d uniform bind group")
    }
  }
}

///|
fn mesh2d_material_layout_from_cache(
  backend : GpuBackend,
  layout_key : Array[(UInt, Int)],
) -> (@wgpu.BindGroupLayout, @wgpu.PipelineLayout)? {
  if host_material2d_layout_signature_eq(
      layout_key,
      host_material2d_default_layout_signature(),
    ) {
    guard backend.mesh2d_material_bgl is Some(material_bgl) else { return None }
    guard backend.mesh_pipeline_layout is Some(pipeline_layout) else {
      return None
    }
    return Some((material_bgl, pipeline_layout))
  }
  let signature_hash = host_material2d_layout_signature_hash(layout_key)
  match backend.mesh2d_material_layout_cache_index.get(signature_hash) {
    Some(indices) =>
      for index in indices {
        if index < 0 || index >= backend.mesh2d_material_layout_cache.length() {
          continue
        }
        let entry = backend.mesh2d_material_layout_cache[index]
        if host_material2d_layout_signature_eq(entry.key, layout_key) {
          return Some((entry.bind_group_layout, entry.pipeline_layout))
        }
      }
    None => ()
  }
  None
}

///|
fn mesh2d_material_layout_cache_insert_index(
  backend : GpuBackend,
  layout_signature : Array[(UInt, Int)],
  cache_index : Int,
) -> Unit {
  let signature_hash = host_material2d_layout_signature_hash(layout_signature)
  match backend.mesh2d_material_layout_cache_index.get(signature_hash) {
    Some(indices) => {
      indices.push(cache_index)
      backend.mesh2d_material_layout_cache_index.set(signature_hash, indices)
    }
    None =>
      backend.mesh2d_material_layout_cache_index.set(signature_hash, [
        cache_index,
      ])
  }
}

///|
fn mesh2d_material_layout_for_bind_group(
  backend : GpuBackend,
  bind_group : HostMaterial2dBindGroup,
) -> (@wgpu.BindGroupLayout, @wgpu.PipelineLayout)? {
  let layout_signature = host_material2d_layout_signature(bind_group)
  let layout_key_string = host_material2d_layout_signature_key(layout_signature)
  if mesh2d_material_layout_from_cache(backend, layout_signature)
    is Some(layout_info) {
    return Some(layout_info)
  }
  guard backend.mesh2d_view_bgl is Some(view_bgl) else { return None }
  guard backend.mesh2d_mesh_bgl is Some(mesh_bgl) else { return None }
  let fragment_stage = ss(@wgpu.SHADER_STAGE_FRAGMENT)
  let builder = @wgpu.BindGroupLayoutBuilder::new(
    max_entries=bind_group.bindings.length().to_uint64(),
  )
  let mut ok = true
  for binding in bind_group.bindings {
    let binding_index = binding.binding
    match binding.value {
      Uniform(bytes) =>
        ok = ok &&
          builder.add_buffer(
            binding_index,
            fragment_stage,
            @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
            min_binding_size=bytes.length().to_uint64(),
          )
      Texture(_, sample_type, view_dimension) =>
        ok = ok &&
          builder.add_texture(
            binding_index,
            fragment_stage,
            host_material2d_texture_sample_type_to_wgpu(sample_type),
            host_material2d_texture_view_dimension_to_wgpu(view_dimension),
          )
      Sampler(_) =>
        ok = ok &&
          builder.add_sampler(
            binding_index,
            fragment_stage,
            @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
          )
    }
  }
  if !ok {
    builder.free()
    return None
  }
  let material_bgl = if bind_group.bindings.length() == 0 {
    builder.free()
    backend.device.create_bind_group_layout_empty()
  } else {
    builder.finish(
      backend.device,
      label="mgstudio_mesh2d_material_bind_group_layout_\{layout_key_string}",
    )
  }
  let pipeline_layout = create_pipeline_layout_3(
    backend.device,
    view_bgl,
    mesh_bgl,
    material_bgl,
  )
  pipeline_layout.set_label(
    "mgstudio_mesh2d_pipeline_layout_\{layout_key_string}",
  )
  backend.mesh2d_material_layout_cache.push(Mesh2dMaterialLayoutCacheEntry::{
    key: layout_signature,
    bind_group_layout: material_bgl,
    pipeline_layout,
  })
  mesh2d_material_layout_cache_insert_index(
    backend,
    layout_signature,
    backend.mesh2d_material_layout_cache.length() - 1,
  )
  Some((material_bgl, pipeline_layout))
}

///|
fn create_mesh2d_pipeline(
  backend : GpuBackend,
  key : Mesh2dPipelineKey,
  material_pipeline_layout : @wgpu.PipelineLayout,
  label : String,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  let wgsl = load_wgsl_with_defines_required_mesh2d_material(
    Some(key.vertex_shader_path),
    Some(key.fragment_shader_path),
    mesh2d_pipeline_define_keys(key),
    pipeline_descriptor=key.pipeline_descriptor,
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(
      sm,
      layout=material_pipeline_layout,
    )
    let vertex_entry = match key.pipeline_descriptor {
      Some(desc) =>
        match desc.vertex.entry_point {
          Some(entry) => entry
          None => "vertex"
        }
      None => "vertex"
    }
    let fragment_entry = match key.pipeline_descriptor {
      Some(desc) =>
        match desc.fragment {
          Some(fragment) =>
            match fragment.entry_point {
              Some(entry) => entry
              None => "fragment"
            }
          None => "fragment"
        }
      None => "fragment"
    }
    builder.set_entry_points(vertex_entry, fragment_entry)
    mesh2d_render_pipeline_builder_set_color_targets(
      builder,
      key.color_format,
      key.pipeline_descriptor,
    )
    let topology = match key.pipeline_descriptor {
      Some(desc) => desc.primitive.topology
      None => key.primitive_topology
    }
    builder.set_topology_u32(topology)
    match key.pipeline_descriptor {
      Some(desc) =>
        match desc.primitive.polygon_mode {
          Some(mode) => builder.set_polygon_mode_u32(mode)
          None =>
            if key.wireframe {
              builder.set_polygon_mode_u32(@wgpu.POLYGON_MODE_LINE)
            }
        }
      None =>
        if key.wireframe {
          builder.set_polygon_mode_u32(@wgpu.POLYGON_MODE_LINE)
        }
    }
    match key.pipeline_descriptor {
      Some(desc) =>
        match desc.primitive.cull_mode {
          Some(mode) => builder.set_cull_mode_u32(mode)
          None => ()
        }
      None => ()
    }
    if key.blend_alpha {
      builder.enable_alpha_blend()
    } else {
      builder.disable_blend()
    }
    match key.pipeline_descriptor {
      Some(desc) =>
        match desc.depth_stencil {
          Some(depth) =>
            builder.set_depth_stencil(
              tf(depth.format),
              depth_write_enabled=depth.depth_write_enabled,
              depth_compare_u32=depth.depth_compare,
            )
          None =>
            if key.with_depth {
              builder.set_depth_stencil(
                tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
                depth_write_enabled=!key.blend_alpha,
                depth_compare_u32=@wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
              )
            }
        }
      None =>
        if key.with_depth {
          builder.set_depth_stencil(
            tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
            depth_write_enabled=!key.blend_alpha,
            depth_compare_u32=@wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
          )
        }
    }
    match key.pipeline_descriptor {
      Some(desc) =>
        if desc.multisample.count != 1U {
          builder.set_multisample(desc.multisample.count)
        }
      None => ()
    }
    let vertex_layout = mesh2d_descriptor_vertex_buffer_layout(
      key.pipeline_descriptor,
      key.vertex_buffer_layout,
    )
    mesh2d_render_pipeline_builder_set_vertex_layout(builder, vertex_layout)
    builder.create_pipeline(backend.device)
  } catch {
    err => {
      err |> ignore
      sm.release()
      fatal("wgpu: failed to build mesh2d bevy render pipeline")
    }
  }
  pipeline.set_label(label)
  sm.release()
  pipeline
}

///|
fn mesh2d_render_pipeline_builder_set_color_targets(
  builder : @wgpu.RenderPipelineDescBuilder,
  fallback_format : @wgpu.TextureFormat,
  descriptor : @render_resource.RenderPipelineDescriptor?,
) -> Unit raise @wgpu.RenderPipelineDescError {
  guard descriptor is Some(desc) else {
    builder.set_color_target_format(fallback_format)
    return
  }
  guard desc.fragment is Some(fragment) else {
    builder.set_color_target_count(0U)
    return
  }
  if fragment.targets.length() == 0 {
    builder.set_color_target_format(fallback_format)
    return
  }
  builder.set_color_target_count(
    fragment.targets.length().reinterpret_as_uint(),
  )
  for index in 0..<fragment.targets.length() {
    let index_u = index.reinterpret_as_uint()
    match fragment.targets[index] {
      Some(target) => {
        builder.set_color_target_format_at(index_u, tf(target.format))
        builder.set_color_target_write_mask_at(index_u, target.write_mask)
      }
      None => builder.set_color_target_unused_at(index_u)
    }
  }
}

///|
fn mesh2d_descriptor_vertex_buffer_layout(
  descriptor : @render_resource.RenderPipelineDescriptor?,
  fallback : @mesh.VertexBufferLayout,
) -> @mesh.VertexBufferLayout {
  match descriptor {
    Some(desc) =>
      if desc.vertex.buffers.length() > 0 {
        desc.vertex.buffers[0]
      } else {
        fallback
      }
    None => fallback
  }
}

///|
fn mesh2d_vertex_layout_cache_key(layout : @mesh.VertexBufferLayout) -> String {
  let mut key = "\{layout.array_stride.to_string()}:\{to_repr(layout.step_mode).to_string()}"
  for attribute in layout.attributes {
    key = key +
      "|\{attribute.offset.to_string()}:\{to_repr(attribute.format).to_string()}:\{attribute.shader_location.to_string()}"
  }
  key
}

///|
fn mesh2d_render_pipeline_builder_set_vertex_layout(
  builder : @wgpu.RenderPipelineDescBuilder,
  layout : @mesh.VertexBufferLayout,
) -> Unit raise @wgpu.RenderPipelineDescError {
  builder.set_vertex_buffer_layout(
    layout.array_stride.to_uint64(),
    mesh_vertex_step_mode_to_wgpu(layout.step_mode),
  )
  for attribute in layout.attributes {
    builder.add_vertex_attribute(
      mesh_vertex_format_to_wgpu(attribute.format),
      attribute.offset.to_uint64(),
      attribute.shader_location.reinterpret_as_uint(),
    )
  }
}

///|
fn mesh2d_registered_pipeline_cache_key(
  format : @wgpu.TextureFormat,
  topology : UInt,
  with_depth : Bool,
  descriptor : Mesh2dRegisteredPipelineDescriptor,
  layout : @mesh.VertexBufferLayout,
) -> String {
  let depth_bits = if with_depth { "1" } else { "0" }
  "mesh2d-pipeline:\{descriptor.pipeline_id.to_string()}:\{format.raw.to_string()}:\{topology.to_string()}:\{depth_bits}:\{descriptor.shader_path}:\{mesh2d_vertex_layout_cache_key(layout)}"
}

///|
fn mesh2d_pipeline_layout_without_material(
  backend : GpuBackend,
) -> @wgpu.PipelineLayout? raise GpuBackendError {
  ensure_mesh2d_resources(backend)
  match backend.mesh2d_pipeline_layout_without_material {
    Some(layout) => Some(layout)
    None => {
      guard backend.mesh2d_view_bgl is Some(view_bgl) else { return None }
      guard backend.mesh2d_mesh_bgl is Some(mesh_bgl) else { return None }
      let layout = backend.device.create_pipeline_layout_many([
        view_bgl, mesh_bgl,
      ])
      layout.set_label("mgstudio_mesh2d_pipeline_layout_without_material")
      backend.mesh2d_pipeline_layout_without_material = Some(layout)
      Some(layout)
    }
  }
}

///|
fn create_mesh2d_registered_pipeline(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  topology : UInt,
  with_depth : Bool,
  descriptor : Mesh2dRegisteredPipelineDescriptor,
  layout : @mesh.VertexBufferLayout,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  guard mesh2d_pipeline_layout_without_material(backend)
    is Some(pipeline_layout) else {
    return None
  }
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    descriptor.shader_path,
    @hashmap.HashMap([]),
    default_wgsl_value_defines(),
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(
      sm,
      layout=pipeline_layout,
    )
    builder.set_entry_points("vertex", "fragment")
    builder.set_color_target_format(format)
    builder.enable_alpha_blend()
    builder.set_topology_u32(topology)
    builder.set_cull_mode_u32(@wgpu.CULL_MODE_BACK)
    if with_depth {
      builder.set_depth_stencil(
        tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
        depth_write_enabled=false,
        depth_compare_u32=@wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
      )
    }
    mesh2d_render_pipeline_builder_set_vertex_layout(builder, layout)
    builder.create_pipeline(backend.device)
  } catch {
    err => {
      err |> ignore
      sm.release()
      return None
    }
  }
  pipeline.set_label("mgstudio_mesh2d_registered_pipeline")
  sm.release()
  Some(pipeline)
}

///|
fn mesh2d_registered_pipeline_for_draw(
  backend : GpuBackend,
  mesh : GpuMeshInfo,
  descriptor : Mesh2dRegisteredPipelineDescriptor,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  guard mesh.vertex_layout is Some(vertex_layout) else { return None }
  let format = match current_pass_color_format(backend) {
    Some(v) => v
    None => tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
  }
  let cache_key = mesh2d_registered_pipeline_cache_key(
    format,
    mesh.primitive_topology,
    backend.pass_has_depth,
    descriptor,
    vertex_layout,
  )
  match backend.mesh2d_pipeline_cache_index.get(cache_key) {
    Some(index) =>
      if index >= 0 && index < backend.mesh2d_pipeline_cache.length() {
        let entry = backend.mesh2d_pipeline_cache[index]
        if entry.key == cache_key {
          return Some(entry.pipeline)
        }
      }
    None => ()
  }
  guard create_mesh2d_registered_pipeline(
      backend,
      format,
      mesh.primitive_topology,
      backend.pass_has_depth,
      descriptor,
      vertex_layout,
    )
    is Some(pipeline) else {
    return None
  }
  backend.mesh2d_pipeline_cache.push(Mesh2dPipelineCacheEntry::{
    key: cache_key,
    pipeline,
  })
  backend.mesh2d_pipeline_cache_index.set(
    cache_key,
    backend.mesh2d_pipeline_cache.length() - 1,
  )
  Some(pipeline)
}

///|
pub fn GpuBackend::register_mesh2d_pipeline_descriptor(
  self : GpuBackend,
  pipeline_id : UInt64,
  shader_path : String,
) -> Unit {
  if pipeline_id == 0UL {
    return
  }
  self.mesh2d_pipeline_descriptors[pipeline_id] = Mesh2dRegisteredPipelineDescriptor::{
    pipeline_id,
    shader_path,
  }
}

///|
fn GpuBackend::mesh2d_pipeline_descriptor(
  self : GpuBackend,
  pipeline_id : UInt64,
) -> Mesh2dRegisteredPipelineDescriptor? {
  self.mesh2d_pipeline_descriptors.get(pipeline_id)
}

///|
fn mesh2d_view_uniform_bytes(pass_state : GpuPassState) -> Bytes {
  let safe_width = if pass_state.width_logical <= 0.0F {
    1.0F
  } else {
    pass_state.width_logical
  }
  let safe_height = if pass_state.height_logical <= 0.0F {
    1.0F
  } else {
    pass_state.height_logical
  }
  let safe_camera_scale = if pass_state.camera_scale == 0.0F {
    1.0F
  } else {
    pass_state.camera_scale
  }
  let cam_cos = cosf(pass_state.camera_rot)
  let cam_sin = sinf(pass_state.camera_rot)
  let ndc_scale_x = 2.0F / safe_width / safe_camera_scale
  let ndc_scale_y = 2.0F / safe_height / safe_camera_scale
  let clip_x_axis_x = cam_cos * ndc_scale_x
  let clip_x_axis_y = cam_sin * ndc_scale_y
  let clip_y_axis_x = -cam_sin * ndc_scale_x
  let clip_y_axis_y = cam_cos * ndc_scale_y
  let clip_w_axis_x = (
      -pass_state.camera_x * cam_cos + pass_state.camera_y * cam_sin
    ) *
    ndc_scale_x
  let clip_w_axis_y = (
      -pass_state.camera_x * cam_sin - pass_state.camera_y * cam_cos
    ) *
    ndc_scale_y
  let floats : Array[Float] = [
    clip_x_axis_x, clip_x_axis_y, 0.0F, 0.0F, clip_y_axis_x, clip_y_axis_y, 0.0F,
    0.0F, 0.0F, 0.0F, 1.0F, 0.0F, clip_w_axis_x, clip_w_axis_y, 0.0F, 1.0F,
  ]
  let target_float_count = (MESH2D_VIEW_BUFFER_SIZE / 4UL).to_int()
  for _ in floats.length()..<target_float_count {
    floats.push(0.0F)
  }
  f32le_pack(floats)
}

///|
fn mesh2d_globals_uniform_bytes() -> Bytes {
  Bytes::makei(MESH2D_GLOBALS_BUFFER_SIZE.to_int(), _ => (0).to_byte())
}

///|
fn mesh2d_sync_view_uniforms_for_current_pass(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  guard backend.pass_state is Some(pass_state) else { return }
  ensure_mesh2d_resources(backend)
  guard backend.mesh2d_view_buf is Some(view_buf) &&
    backend.mesh2d_globals_buf is Some(globals_buf) else {
    return
  }
  backend.queue.write_buffer(
    view_buf,
    0UL,
    mesh2d_view_uniform_bytes(pass_state),
  )
  backend.queue.write_buffer(globals_buf, 0UL, mesh2d_globals_uniform_bytes())
}

///|
fn mesh2d_instance_uniform_bytes(
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  flags : UInt,
  tag : UInt,
) -> Bytes {
  let cosr = cosf(rotation)
  let sinr = sinf(rotation)
  let safe_scale_x = if scale_x == 0.0F { 1.0F } else { scale_x }
  let safe_scale_y = if scale_y == 0.0F { 1.0F } else { scale_y }
  let world_x_axis_x = scale_x * cosr
  let world_x_axis_y = scale_x * sinr
  let world_y_axis_x = -scale_y * sinr
  let world_y_axis_y = scale_y * cosr
  let inverse_transpose_x_axis_x = cosr / safe_scale_x
  let inverse_transpose_x_axis_y = sinr / safe_scale_x
  let inverse_transpose_y_axis_x = -sinr / safe_scale_y
  let inverse_transpose_y_axis_y = cosr / safe_scale_y
  // Matches bevy_math::Affine3Ext::to_transpose + inverse_transpose_3x3 packing.
  let words : Array[UInt] = [
    f32_bits(world_x_axis_x),
    f32_bits(world_y_axis_x),
    f32_bits(0.0F),
    f32_bits(x),
    f32_bits(world_x_axis_y),
    f32_bits(world_y_axis_y),
    f32_bits(0.0F),
    f32_bits(y),
    f32_bits(0.0F),
    f32_bits(0.0F),
    f32_bits(1.0F),
    f32_bits(0.0F),
    f32_bits(inverse_transpose_x_axis_x),
    f32_bits(inverse_transpose_x_axis_y),
    f32_bits(0.0F),
    f32_bits(inverse_transpose_y_axis_x),
    f32_bits(inverse_transpose_y_axis_y),
    f32_bits(0.0F),
    f32_bits(0.0F),
    f32_bits(0.0F),
    f32_bits(1.0F),
    flags,
    tag,
    0U,
  ]
  u32le_pack(words)
}

///|
fn resolve_mesh2d_material_texture(
  backend : GpuBackend,
  id : Int,
) -> GpuTextureInfo raise GpuBackendError {
  if id < 0 {
    return ensure_default_texture(backend)
  }
  match find_texture(backend, id) {
    Some(texture) => texture
    None => ensure_default_texture(backend)
  }
}

///|
fn host_material2d_texture_sample_type_to_wgpu(
  sample_type : HostMaterial2dTextureSampleType,
) -> UInt {
  match sample_type {
    HostMaterial2dTextureSampleType::Float => @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT
    HostMaterial2dTextureSampleType::UInt => @wgpu.TEXTURE_SAMPLE_TYPE_UINT
  }
}

///|
fn host_material2d_texture_view_dimension_to_wgpu(
  view_dimension : HostMaterial2dTextureViewDimension,
) -> UInt {
  match view_dimension {
    HostMaterial2dTextureViewDimension::D2 => @wgpu.TEXTURE_VIEW_DIMENSION_2D
    HostMaterial2dTextureViewDimension::D2Array =>
      @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY
  }
}

///|
fn mesh2d_material_texture_view_for_binding(
  texture : GpuTextureInfo,
  view_dimension : HostMaterial2dTextureViewDimension,
) -> @wgpu.TextureView {
  match view_dimension {
    HostMaterial2dTextureViewDimension::D2 =>
      match texture.sample_view {
        Some(sampled) =>
          if texture.format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) ||
            texture.format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB) {
            texture.view
          } else {
            sampled
          }
        None => texture.view
      }
    HostMaterial2dTextureViewDimension::D2Array =>
      match texture.sample_view {
        Some(sampled) => sampled
        None => texture.view
      }
  }
}

///|
fn mesh2d_material_bind_group_cache_insert_index(
  backend : GpuBackend,
  bind_group_hash : UInt64,
  cache_index : Int,
) -> Unit {
  match backend.mesh2d_material_bg_cache_index.get(bind_group_hash) {
    Some(indices) => {
      indices.push(cache_index)
      backend.mesh2d_material_bg_cache_index.set(bind_group_hash, indices)
    }
    None =>
      backend.mesh2d_material_bg_cache_index.set(bind_group_hash, [cache_index])
  }
}

///|
fn mesh2d_material_bind_group_for_draw(
  backend : GpuBackend,
  bind_group : HostMaterial2dBindGroup,
) -> (@wgpu.BindGroupLayout, @wgpu.BindGroup)? raise GpuBackendError {
  guard mesh2d_material_layout_for_bind_group(backend, bind_group)
    is Some((material_bgl, _)) else {
    return None
  }
  let cache_key = host_material2d_bind_group_cache_key(bind_group)
  let bind_group_hash = host_material2d_bind_group_hash(bind_group)
  match backend.mesh2d_material_bg_cache_index.get(bind_group_hash) {
    Some(indices) =>
      for index in indices {
        if index < 0 || index >= backend.mesh2d_material_bg_cache.length() {
          continue
        }
        let entry = backend.mesh2d_material_bg_cache[index]
        if host_material2d_bind_group_key_eq(entry.key, bind_group) {
          for uniform_buffer in entry.uniform_buffers {
            uniform_buffer |> ignore
          }
          return Some((material_bgl, entry.bind_group))
        }
      }
    None => ()
  }
  let uniform_buffers : Array[@wgpu.Buffer] = []
  let builder = @wgpu.BindGroupBuilder::new(
    max_entries=bind_group.bindings.length().to_uint64(),
  )
  let mut ok = true
  for binding in bind_group.bindings {
    match binding.value {
      Uniform(bytes) => {
        let uniform_buffer = backend.device.create_buffer_init(
          usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
          bytes,
        )
        uniform_buffers.push(uniform_buffer)
        ok = ok &&
          builder.add_buffer(
            binding.binding,
            uniform_buffer,
            size=bytes.length().to_uint64(),
          )
      }
      Texture(texture_id, _sample_type, view_dimension) => {
        let texture = resolve_mesh2d_material_texture(backend, texture_id)
        ok = ok &&
          builder.add_texture_view(
            binding.binding,
            mesh2d_material_texture_view_for_binding(texture, view_dimension),
          )
      }
      Sampler(texture_id) => {
        let texture = resolve_mesh2d_material_texture(backend, texture_id)
        ok = ok && builder.add_sampler(binding.binding, texture.sampler)
      }
    }
  }
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    material_bgl,
    label="mgstudio_mesh2d_material_bg",
  )
  backend.mesh2d_material_bg_cache.push(Mesh2dMaterialBindGroupCacheEntry::{
    key: cache_key,
    bind_group,
    uniform_buffers,
  })
  mesh2d_material_bind_group_cache_insert_index(
    backend,
    bind_group_hash,
    backend.mesh2d_material_bg_cache.length() - 1,
  )
  Some((material_bgl, bind_group))
}

///|
fn mesh2d_pipeline_key_for_format(
  format : @wgpu.TextureFormat,
  primitive_topology : UInt,
  mesh_vertex_layout : @mesh.MeshVertexBufferLayout,
  vertex_buffer_layout : @mesh.VertexBufferLayout,
  blend_alpha : Bool,
  with_depth : Bool,
  tonemap_in_shader : Bool,
  deband_dither : Bool,
  may_discard : Bool,
  wireframe : Bool,
  material_layout_key : String,
  vertex_shader_path : String?,
  fragment_shader_path : String?,
  pipeline_descriptor : @render_resource.RenderPipelineDescriptor?,
) -> Mesh2dPipelineKey {
  let hdr = format == tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
  let resolved_vertex_shader_path = match pipeline_descriptor {
    Some(desc) =>
      match desc.vertex.shader {
        Some(shader) => shader
        None => mesh2d_vertex_shader_path_or_default(vertex_shader_path)
      }
    None => mesh2d_vertex_shader_path_or_default(vertex_shader_path)
  }
  let resolved_fragment_shader_path = match pipeline_descriptor {
    Some(desc) =>
      match desc.fragment {
        Some(fragment) =>
          match fragment.shader {
            Some(shader) => shader
            None => mesh2d_fragment_shader_path_or_default(fragment_shader_path)
          }
        None => mesh2d_fragment_shader_path_or_default(fragment_shader_path)
      }
    None => mesh2d_fragment_shader_path_or_default(fragment_shader_path)
  }
  Mesh2dPipelineKey::{
    color_format: format,
    primitive_topology,
    blend_alpha,
    with_depth,
    hdr,
    tonemap_in_shader,
    deband_dither,
    may_discard,
    wireframe,
    material_layout_key,
    vertex_layout_key: mesh2d_material_vertex_layout_cache_key(
      mesh_vertex_layout, vertex_buffer_layout,
    ),
    vertex_positions: mesh_vertex_layout.contains(
      @mesh.MeshVertexAttribute::position().id(),
    ),
    vertex_normals: mesh_vertex_layout.contains(
      @mesh.MeshVertexAttribute::normal().id(),
    ),
    vertex_uvs: mesh_vertex_layout.contains(
      @mesh.MeshVertexAttribute::uv_0().id(),
    ),
    vertex_tangents: mesh_vertex_layout.contains(
      @mesh.MeshVertexAttribute::tangent().id(),
    ),
    vertex_colors: mesh_vertex_layout.contains(
      @mesh.MeshVertexAttribute::color().id(),
    ),
    vertex_buffer_layout,
    vertex_shader_path: resolved_vertex_shader_path,
    fragment_shader_path: resolved_fragment_shader_path,
    descriptor_cache_key: mesh2d_descriptor_cache_key(pipeline_descriptor),
    pipeline_descriptor,
  }
}

///|
fn mesh2d_pipeline_blend_alpha(alpha_mode_kind : Int) -> Bool {
  alpha_mode_kind == MESH2D_ALPHA_MODE_KIND_BLEND
}

///|
fn mesh2d_pipeline_may_discard(alpha_mode_kind : Int) -> Bool {
  alpha_mode_kind == MESH2D_ALPHA_MODE_KIND_MASK
}

///|
fn mesh2d_get_or_create_pipeline(
  backend : GpuBackend,
  key : Mesh2dPipelineKey,
  material_pipeline_layout : @wgpu.PipelineLayout,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let cache_key = mesh2d_pipeline_cache_key(key)
  match backend.mesh2d_pipeline_cache_index.get(cache_key) {
    Some(index) =>
      if index >= 0 && index < backend.mesh2d_pipeline_cache.length() {
        let entry = backend.mesh2d_pipeline_cache[index]
        if entry.key == cache_key {
          return Some(entry.pipeline)
        }
      }
    None => ()
  }
  let pipeline_label = if key.blend_alpha {
    "mgstudio_mesh2d_transparent_pipeline"
  } else if key.wireframe {
    "mgstudio_mesh2d_wireframe_pipeline"
  } else {
    "mgstudio_mesh2d_opaque_pipeline"
  }
  let pipeline = create_mesh2d_pipeline(
    backend, key, material_pipeline_layout, pipeline_label,
  )
  backend.mesh2d_pipeline_cache.push(Mesh2dPipelineCacheEntry::{
    key: cache_key,
    pipeline,
  })
  backend.mesh2d_pipeline_cache_index.set(
    cache_key,
    backend.mesh2d_pipeline_cache.length() - 1,
  )
  let uses_default_shaders = key.vertex_shader_path ==
    MESH2D_DEFAULT_VERTEX_SHADER_PATH &&
    key.fragment_shader_path == MESH2D_COLOR_MATERIAL_SHADER_PATH
  if uses_default_shaders &&
    key.color_format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    backend.mesh_pipeline = Some(pipeline)
  } else if uses_default_shaders {
    backend.mesh_pipeline_surface = Some(pipeline)
    backend.mesh_pipeline_surface_format = Some(key.color_format)
  }
  Some(pipeline)
}

///|
fn mesh_pipeline_for_draw(
  backend : GpuBackend,
  mesh : GpuMeshInfo,
  alpha_mode_kind : Int,
  material_bind_group : HostMaterial2dBindGroup,
  wireframe : Bool,
  vertex_shader_path : String?,
  fragment_shader_path : String?,
  pipeline_descriptor : @render_resource.RenderPipelineDescriptor?,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let format = match current_pass_color_format(backend) {
    Some(v) => v
    None => tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
  }
  let material_layout_key = host_material2d_bind_group_layout_key(
    material_bind_group,
  )
  guard mesh2d_material_layout_for_bind_group(backend, material_bind_group)
    is Some((_, material_pipeline_layout)) else {
    return None
  }
  guard mesh.mesh_vertex_layout is Some(mesh_vertex_layout) else { return None }
  guard mesh2d_material_vertex_buffer_layout(mesh_vertex_layout)
    is Some(vertex_buffer_layout) else {
    return None
  }
  mesh2d_get_or_create_pipeline(
    backend,
    mesh2d_pipeline_key_for_format(
      format,
      mesh.primitive_topology,
      mesh_vertex_layout,
      vertex_buffer_layout,
      mesh2d_pipeline_blend_alpha(alpha_mode_kind),
      backend.pass_has_depth,
      false,
      false,
      mesh2d_pipeline_may_discard(alpha_mode_kind),
      wireframe,
      material_layout_key,
      vertex_shader_path,
      fragment_shader_path,
      pipeline_descriptor,
    ),
    material_pipeline_layout,
  )
}

///|
fn mesh2d_reset_pending_batch(backend : GpuBackend) -> Unit {
  backend.mesh2d_batch_active = false
  backend.mesh2d_batch_mesh_id = -1
  backend.mesh2d_batch_alpha_mode_kind = MESH2D_ALPHA_MODE_KIND_OPAQUE
  backend.mesh2d_batch_wireframe = false
  backend.mesh2d_batch_vertex_shader_path = ""
  backend.mesh2d_batch_fragment_shader_path = ""
  backend.mesh2d_batch_pipeline_cache_key = ""
  backend.mesh2d_batch_material_hash = 0UL
  backend.mesh2d_batch_material_key.clear()
  backend.mesh2d_batch_uniform_base_offset = 0
  backend.mesh2d_batch_instance_count = 0U
  backend.mesh2d_batch_pipeline = None
  backend.mesh2d_batch_material_bg = None
}

///|
fn mesh2d_pending_batch_matches(
  backend : GpuBackend,
  mesh_id : Int,
  alpha_mode_kind : Int,
  material_bind_group : HostMaterial2dBindGroup,
  material_bind_group_hash : UInt64,
  wireframe : Bool,
  vertex_shader_path : String,
  fragment_shader_path : String,
  pipeline_cache_key : String,
) -> Bool {
  backend.mesh2d_batch_active &&
  backend.mesh2d_batch_mesh_id == mesh_id &&
  backend.mesh2d_batch_alpha_mode_kind == alpha_mode_kind &&
  backend.mesh2d_batch_wireframe == wireframe &&
  backend.mesh2d_batch_vertex_shader_path == vertex_shader_path &&
  backend.mesh2d_batch_fragment_shader_path == fragment_shader_path &&
  backend.mesh2d_batch_pipeline_cache_key == pipeline_cache_key &&
  backend.mesh2d_batch_material_hash == material_bind_group_hash &&
  host_material2d_bind_group_key_eq(
    backend.mesh2d_batch_material_key,
    material_bind_group,
  )
}

///|
fn flush_mesh2d_batches(backend : GpuBackend) -> Unit {
  if !backend.mesh2d_batch_active {
    return
  }
  if backend.mesh2d_batch_instance_count == 0U {
    mesh2d_reset_pending_batch(backend)
    return
  }
  guard backend.frame is Some(frame) else {
    mesh2d_reset_pending_batch(backend)
    return
  }
  guard frame.pass is Some(pass) else {
    mesh2d_reset_pending_batch(backend)
    return
  }
  guard backend.mesh2d_batch_pipeline is Some(pipeline) else {
    mesh2d_reset_pending_batch(backend)
    return
  }
  guard backend.mesh2d_batch_material_bg is Some(material_bg) else {
    mesh2d_reset_pending_batch(backend)
    return
  }
  guard backend.mesh2d_view_bg is Some(view_bg) else {
    mesh2d_reset_pending_batch(backend)
    return
  }
  guard backend.mesh2d_instance_bg is Some(instance_uniform_bg) else {
    mesh2d_reset_pending_batch(backend)
    return
  }
  guard find_mesh(backend, backend.mesh2d_batch_mesh_id) is Some(mesh) else {
    mesh2d_reset_pending_batch(backend)
    return
  }
  if mesh.mesh_vertex_layout is None {
    mesh2d_reset_pending_batch(backend)
    return
  }
  let uniform_dynamic_offset = backend.mesh2d_batch_uniform_base_offset.reinterpret_as_uint()
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, view_bg, [0U])
  pass.set_bind_group(1U, instance_uniform_bg, [uniform_dynamic_offset])
  pass.set_bind_group(2U, material_bg, [])
  pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, mesh.vertex_buf.size())
  render_diagnostics_record_mesh2d_executed_draw()
  if mesh.index_count > 0U {
    gpu_mesh_bind_index_buffer(pass, mesh)
    pass.draw_indexed(
      mesh.index_count,
      backend.mesh2d_batch_instance_count,
      mesh.index_start,
      mesh.vertex_start.reinterpret_as_int(),
      0U,
    )
  } else {
    pass.draw(
      mesh.vertex_count,
      backend.mesh2d_batch_instance_count,
      mesh.vertex_start,
      0U,
    )
  }
  mesh2d_reset_pending_batch(backend)
}

///|
pub fn GpuBackend::create_mesh_rectangle(
  self : GpuBackend,
  width : Float,
  height : Float,
) -> Int {
  let id = alloc_id(self)
  let hw = width * 0.5F
  let hh = height * 0.5F
  let vertices_xyuvrgba : Array[Float] = [
    -hw,
    -hh,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    hw,
    -hh,
    1.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    hw,
    hh,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    -hw,
    hh,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
  ]
  let vertices = mesh2d_interleaved_xyzuv_from_xyuvrgba(vertices_xyuvrgba)
  let indices_u16 : Array[Int] = [0, 1, 2, 0, 2, 3]
  let vb_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let vb_bytes = f32le_pack(vertices)
  let vb = self.device.create_buffer_init(usage=vb_usage, vb_bytes)
  let ib_usage = bu(@wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let ib_bytes = u16le_pack(indices_u16)
  let ib = self.device.create_buffer_init(usage=ib_usage, ib_bytes)
  let mesh_vertex_layout = mesh2d_default_mesh_vertex_buffer_layout()
  let info = GpuMeshInfo::{
    id,
    index_count: 6U,
    vertex_count: 4U,
    index_start: 0U,
    vertex_start: 0U,
    index_slab_id: -1,
    vertex_slab_id: -1,
    primitive_topology: @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    vertex_stride_bytes: MESH2D_VERTEX_STRIDE_BYTES,
    mesh_vertex_layout: Some(mesh_vertex_layout),
    vertex_layout: Some(mesh_vertex_layout.layout()),
    index_stride_bytes: 2UL,
    uses_u32_indices: false,
    vertex_buf: vb,
    index_buf: ib,
  }
  self.meshes.push(info)
  id
}

///|
pub fn GpuBackend::create_mesh_capsule(
  self : GpuBackend,
  radius : Float,
  half_length : Float,
  segments : Int,
) -> Int {
  let id = alloc_id(self)
  // Simple triangulated capsule: rectangle body + two semicircle fans.
  let segs = if segments < 4 { 4 } else { segments }
  let verts_xy : Array[Float] = []
  let inds : Array[Int] = []

  // Base rectangle vertices (4).
  let hw = half_length
  let hh = radius
  let base0 = 0
  verts_xy.push(-hw)
  verts_xy.push(-hh)
  verts_xy.push(hw)
  verts_xy.push(-hh)
  verts_xy.push(hw)
  verts_xy.push(hh)
  verts_xy.push(-hw)
  verts_xy.push(hh)
  inds.push(base0 + 0)
  inds.push(base0 + 1)
  inds.push(base0 + 2)
  inds.push(base0 + 0)
  inds.push(base0 + 2)
  inds.push(base0 + 3)

  // Left semicircle.
  let center_l = verts_xy.length() / 2
  verts_xy.push(-hw)
  verts_xy.push(0.0F)
  for i in 0..<(segs + 1) {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(segs.to_double())
    let ang = PI * (t + 0.5F) // from 90deg to 270deg
    verts_xy.push(-hw + cosf(ang) * radius)
    verts_xy.push(sinf(ang) * radius)
  }
  for i in 0..<segs {
    inds.push(center_l)
    inds.push(center_l + 1 + i)
    inds.push(center_l + 1 + i + 1)
  }

  // Right semicircle.
  let center_r = verts_xy.length() / 2
  verts_xy.push(hw)
  verts_xy.push(0.0F)
  for i in 0..<(segs + 1) {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(segs.to_double())
    let ang = PI * (t - 0.5F) // from -90deg to 90deg
    verts_xy.push(hw + cosf(ang) * radius)
    verts_xy.push(sinf(ang) * radius)
  }
  for i in 0..<segs {
    inds.push(center_r)
    inds.push(center_r + 1 + i)
    inds.push(center_r + 1 + i + 1)
  }
  let verts_xyuvrgba = mesh_interleaved_xyuvrgba_from_xy(verts_xy)
  let verts = mesh2d_interleaved_xyzuv_from_xyuvrgba(verts_xyuvrgba)
  let vb_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let vb = self.device.create_buffer_init(usage=vb_usage, f32le_pack(verts))
  let ib_usage = bu(@wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let ib = self.device.create_buffer_init(usage=ib_usage, u16le_pack(inds))
  let mesh_vertex_layout = mesh2d_default_mesh_vertex_buffer_layout()
  let info = GpuMeshInfo::{
    id,
    index_count: inds.length().reinterpret_as_uint(),
    vertex_count: (verts.length() / 9).reinterpret_as_uint(),
    index_start: 0U,
    vertex_start: 0U,
    index_slab_id: -1,
    vertex_slab_id: -1,
    primitive_topology: @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    vertex_stride_bytes: MESH2D_VERTEX_STRIDE_BYTES,
    mesh_vertex_layout: Some(mesh_vertex_layout),
    vertex_layout: Some(mesh_vertex_layout.layout()),
    index_stride_bytes: 2UL,
    uses_u32_indices: false,
    vertex_buf: vb,
    index_buf: ib,
  }
  self.meshes.push(info)
  id
}

///|
pub fn GpuBackend::create_mesh_triangles_xy(
  self : GpuBackend,
  vertices_xy : Array[Float],
) -> Int {
  let vertices = mesh_interleaved_xyuvrgba_from_xy(vertices_xy)
  self.create_mesh_triangles_xyuvrgba(vertices)
}

///|
fn mesh_interleaved_xyuvrgba_from_xy(
  vertices_xy : Array[Float],
) -> Array[Float] {
  let vcount = vertices_xy.length() / 2
  if vcount <= 0 {
    return []
  }
  let mut min_x = vertices_xy[0]
  let mut max_x = vertices_xy[0]
  let mut min_y = vertices_xy[1]
  let mut max_y = vertices_xy[1]
  for i in 0..<vcount {
    let x = vertices_xy[i * 2]
    let y = vertices_xy[i * 2 + 1]
    if x < min_x {
      min_x = x
    }
    if x > max_x {
      max_x = x
    }
    if y < min_y {
      min_y = y
    }
    if y > max_y {
      max_y = y
    }
  }
  let width = if max_x - min_x == 0.0F { 1.0F } else { max_x - min_x }
  let height = if max_y - min_y == 0.0F { 1.0F } else { max_y - min_y }
  let out : Array[Float] = []
  for i in 0..<vcount {
    let x = vertices_xy[i * 2]
    let y = vertices_xy[i * 2 + 1]
    out.push(x)
    out.push(y)
    out.push((x - min_x) / width)
    out.push((y - min_y) / height)
    out.push(1.0F)
    out.push(1.0F)
    out.push(1.0F)
    out.push(1.0F)
  }
  out
}

///|
fn mesh2d_interleaved_xyzuv_from_xyuvrgba(
  vertices_xyuvrgba : Array[Float],
) -> Array[Float] {
  let vcount = vertices_xyuvrgba.length() / 8
  let out : Array[Float] = []
  for i in 0..<vcount {
    let base = i * 8
    out.push(vertices_xyuvrgba[base])
    out.push(vertices_xyuvrgba[base + 1])
    out.push(0.0F)
    out.push(vertices_xyuvrgba[base + 2])
    out.push(vertices_xyuvrgba[base + 3])
    out.push(vertices_xyuvrgba[base + 4])
    out.push(vertices_xyuvrgba[base + 5])
    out.push(vertices_xyuvrgba[base + 6])
    out.push(vertices_xyuvrgba[base + 7])
  }
  out
}

///|
pub fn GpuBackend::create_mesh_triangles_xyuvrgba(
  self : GpuBackend,
  vertices : Array[Float],
) -> Int {
  let vcount = vertices.length() / 8
  if vcount <= 0 {
    return 0
  }
  let usable_vcount = vcount - vcount % 3
  if usable_vcount <= 0 || usable_vcount > 65535 {
    return 0
  }
  let indices_u16 : Array[Int] = []
  for i in 0..<usable_vcount {
    indices_u16.push(i)
  }
  let id = alloc_id(self)
  let trimmed_vertices = if usable_vcount == vcount {
    vertices
  } else {
    let out : Array[Float] = []
    for i in 0..<(usable_vcount * 8) {
      out.push(vertices[i])
    }
    out
  }
  let vb_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let mesh2d_vertices = mesh2d_interleaved_xyzuv_from_xyuvrgba(trimmed_vertices)
  let vb = self.device.create_buffer_init(
    usage=vb_usage,
    f32le_pack(mesh2d_vertices),
  )
  let ib_usage = bu(@wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let ib = self.device.create_buffer_init(
    usage=ib_usage,
    u16le_pack(indices_u16),
  )
  let mesh_vertex_layout = mesh2d_default_mesh_vertex_buffer_layout()
  let info = GpuMeshInfo::{
    id,
    index_count: indices_u16.length().reinterpret_as_uint(),
    vertex_count: usable_vcount.reinterpret_as_uint(),
    index_start: 0U,
    vertex_start: 0U,
    index_slab_id: -1,
    vertex_slab_id: -1,
    primitive_topology: @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    vertex_stride_bytes: MESH2D_VERTEX_STRIDE_BYTES,
    mesh_vertex_layout: Some(mesh_vertex_layout),
    vertex_layout: Some(mesh_vertex_layout.layout()),
    index_stride_bytes: 2UL,
    uses_u32_indices: false,
    vertex_buf: vb,
    index_buf: ib,
  }
  self.meshes.push(info)
  id
}

///|
fn mesh2d_prefix_bytes(bytes : Bytes, byte_len : Int) -> Bytes {
  if byte_len >= bytes.length() {
    bytes
  } else {
    Bytes::makei(byte_len, i => bytes[i])
  }
}

///|
pub fn GpuBackend::create_mesh2d_vertex_buffer(
  self : GpuBackend,
  vertex_bytes : Bytes,
  vertex_count : Int,
  indices : Array[Int],
  primitive_topology_kind : Int,
  mesh_vertex_layout : @mesh.MeshVertexBufferLayout,
) -> Int {
  let vertex_layout = mesh_vertex_layout.layout()
  if vertex_layout.array_stride <= 0 || vertex_count <= 0 {
    return 0
  }
  let primitive_topology = mesh3d_topology_from_kind(primitive_topology_kind)
  let vertex_count_from_bytes = vertex_bytes.length() /
    vertex_layout.array_stride
  let clamped_vertex_count = vertex_count.min(vertex_count_from_bytes)
  if clamped_vertex_count <= 0 {
    return 0
  }
  let indexed = indices.length() > 0
  let usable_vertex_count = if indexed {
    clamped_vertex_count
  } else {
    mesh3d_usable_non_indexed_vertex_count(
      clamped_vertex_count, primitive_topology,
    )
  }
  if usable_vertex_count <= 0 {
    return 0
  }
  if indexed && !mesh3d_indices_valid(indices, usable_vertex_count) {
    return 0
  }
  let id = alloc_id(self)
  let vb_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let vb = self.device.create_buffer_init(
    usage=vb_usage,
    mesh2d_prefix_bytes(
      vertex_bytes,
      usable_vertex_count * vertex_layout.array_stride,
    ),
  )
  let uses_u32_indices = indexed && mesh3d_indices_use_u32(indices)
  let index_stride_bytes = if uses_u32_indices { 4UL } else { 2UL }
  let ib = if indexed {
    let ib_usage = bu(@wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST)
    self.device.create_buffer_init(
      usage=ib_usage,
      mesh3d_index_bytes(indices, uses_u32_indices),
    )
  } else {
    self.create_mesh3d_empty_index_buffer()
  }
  let info = GpuMeshInfo::{
    id,
    index_count: if indexed {
      indices.length().reinterpret_as_uint()
    } else {
      0U
    },
    vertex_count: usable_vertex_count.reinterpret_as_uint(),
    index_start: 0U,
    vertex_start: 0U,
    index_slab_id: -1,
    vertex_slab_id: -1,
    primitive_topology,
    vertex_stride_bytes: vertex_layout.array_stride.to_uint64(),
    mesh_vertex_layout: Some(mesh_vertex_layout),
    vertex_layout: Some(vertex_layout),
    index_stride_bytes,
    uses_u32_indices,
    vertex_buf: vb,
    index_buf: ib,
  }
  self.meshes.push(info)
  id
}

///|
pub fn GpuBackend::draw_mesh(
  self : GpuBackend,
  mesh_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  alpha_mode_kind : Int,
  alpha_cutoff : Float,
  texture_id : Int,
  uv_offset_x : Float,
  uv_offset_y : Float,
  uv_scale_x : Float,
  uv_scale_y : Float,
  vertex_shader_path? : String? = None,
  fragment_shader_path? : String? = None,
) -> Unit raise GpuBackendError {
  let material_bind_group = host_material2d_color_material_bind_group(
    color_r, color_g, color_b, color_a, alpha_mode_kind, alpha_cutoff, texture_id,
    uv_offset_x, uv_offset_y, uv_scale_x, uv_scale_y,
  )
  self.draw_mesh_material(
    mesh_id,
    x,
    y,
    rotation,
    scale_x,
    scale_y,
    alpha_mode_kind,
    material_bind_group,
    vertex_shader_path~,
    fragment_shader_path~,
  )
}

///|
fn GpuBackend::draw_mesh_material_with_options(
  self : GpuBackend,
  mesh_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  alpha_mode_kind : Int,
  material_bind_group : HostMaterial2dBindGroup,
  vertex_shader_path? : String? = None,
  fragment_shader_path? : String? = None,
  wireframe? : Bool = false,
  pipeline_descriptor? : @render_resource.RenderPipelineDescriptor? = None,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else {
    render_diagnostics_record_mesh2d_drop_no_frame()
    return
  }
  guard frame.pass is Some(_) else {
    render_diagnostics_record_mesh2d_drop_no_pass()
    return
  }
  guard self.pass_state is Some(_) else {
    render_diagnostics_record_mesh2d_drop_no_pass_state()
    return
  }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard find_mesh(self, mesh_id) is Some(mesh) else {
    render_diagnostics_record_mesh2d_drop_missing_mesh()
    return
  }
  guard mesh.mesh_vertex_layout is Some(mesh_vertex_layout) else {
    render_diagnostics_record_mesh2d_drop_bad_stride()
    return
  }
  guard mesh2d_material_vertex_buffer_layout(mesh_vertex_layout)
    is Some(vertex_buffer_layout) else {
    render_diagnostics_record_mesh2d_drop_bad_stride()
    return
  }
  ensure_mesh2d_resources(self)
  let resolved_vertex_shader_path = mesh2d_vertex_shader_path_or_default(
    vertex_shader_path,
  )
  let resolved_fragment_shader_path = mesh2d_fragment_shader_path_or_default(
    fragment_shader_path,
  )
  let pipeline_cache_key = mesh2d_pipeline_cache_key(
    mesh2d_pipeline_key_for_format(
      match current_pass_color_format(self) {
        Some(v) => v
        None => tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
      },
      mesh.primitive_topology,
      mesh_vertex_layout,
      vertex_buffer_layout,
      mesh2d_pipeline_blend_alpha(alpha_mode_kind),
      self.pass_has_depth,
      false,
      false,
      mesh2d_pipeline_may_discard(alpha_mode_kind),
      wireframe,
      host_material2d_bind_group_layout_key(material_bind_group),
      Some(resolved_vertex_shader_path),
      Some(resolved_fragment_shader_path),
      pipeline_descriptor,
    ),
  )
  guard mesh_pipeline_for_draw(
      self,
      mesh,
      alpha_mode_kind,
      material_bind_group,
      wireframe,
      Some(resolved_vertex_shader_path),
      Some(resolved_fragment_shader_path),
      pipeline_descriptor,
    )
    is Some(pipeline) else {
    render_diagnostics_record_mesh2d_drop_no_pipeline()
    return
  }
  guard mesh2d_material_bind_group_for_draw(self, material_bind_group)
    is Some((_, material_bg)) else {
    render_diagnostics_record_mesh2d_drop_no_uniform_buf()
    return
  }
  let material_bind_group_hash = host_material2d_bind_group_hash(
    material_bind_group,
  )
  if self.mesh2d_batch_active &&
    self.mesh2d_batch_instance_count.reinterpret_as_int() >=
    MESH2D_PER_OBJECT_BUFFER_BATCH_SIZE {
    flush_mesh2d_batches(self)
  }
  if !mesh2d_pending_batch_matches(
      self, mesh_id, alpha_mode_kind, material_bind_group, material_bind_group_hash,
      wireframe, resolved_vertex_shader_path, resolved_fragment_shader_path, pipeline_cache_key,
    ) {
    flush_mesh2d_batches(self)
    self.mesh2d_batch_active = true
    self.mesh2d_batch_mesh_id = mesh_id
    self.mesh2d_batch_alpha_mode_kind = alpha_mode_kind
    self.mesh2d_batch_wireframe = wireframe
    self.mesh2d_batch_vertex_shader_path = resolved_vertex_shader_path
    self.mesh2d_batch_fragment_shader_path = resolved_fragment_shader_path
    self.mesh2d_batch_pipeline_cache_key = pipeline_cache_key
    self.mesh2d_batch_material_hash = material_bind_group_hash
    self.mesh2d_batch_material_key = host_material2d_bind_group_cache_key(
      material_bind_group,
    )
    self.mesh2d_batch_instance_count = 0U
    self.mesh2d_batch_pipeline = Some(pipeline)
    self.mesh2d_batch_material_bg = Some(material_bg)
    self.mesh2d_batch_uniform_base_offset = mesh2d_align_up(
      self.mesh2d_instance_used.to_uint64(),
      MESH2D_UNIFORM_DYNAMIC_STRIDE_BYTES,
    ).to_int()
  }
  let uniform_write_offset = self.mesh2d_batch_uniform_base_offset +
    self.mesh2d_batch_instance_count.reinterpret_as_int() *
    MESH2D_UNIFORM_STRIDE_BYTES.to_int()
  let next_instance_used = uniform_write_offset +
    MESH2D_UNIFORM_STRIDE_BYTES.to_int()
  let required_binding_end = self.mesh2d_batch_uniform_base_offset.to_uint64() +
    MESH2D_UNIFORM_STRIDE_BYTES * MESH2D_PER_OBJECT_BUFFER_BATCH_SIZE_U64
  if next_instance_used < 0 {
    render_diagnostics_record_mesh2d_drop_no_uniform_buf()
    mesh2d_reset_pending_batch(self)
    return
  }
  let required_capacity = {
    let next_used_u64 = next_instance_used.to_uint64()
    if next_used_u64 > required_binding_end {
      next_used_u64
    } else {
      required_binding_end
    }
  }
  guard ensure_mesh2d_instance_uniform_binding(self, required_capacity)
    is Some((instance_uniform_buf, _)) else {
    render_diagnostics_record_mesh2d_drop_no_uniform_buf()
    mesh2d_reset_pending_batch(self)
    return
  }
  if next_instance_used > self.mesh2d_instance_used {
    self.mesh2d_instance_used = next_instance_used
  }
  self.queue.write_buffer(
    instance_uniform_buf,
    uniform_write_offset.to_uint64(),
    mesh2d_instance_uniform_bytes(x, y, rotation, scale_x, scale_y, 0U, 0U),
  )
  self.mesh2d_batch_instance_count = self.mesh2d_batch_instance_count + 1U
}

///|
pub fn GpuBackend::draw_mesh_material(
  self : GpuBackend,
  mesh_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  alpha_mode_kind : Int,
  material_bind_group : HostMaterial2dBindGroup,
  vertex_shader_path? : String? = None,
  fragment_shader_path? : String? = None,
  pipeline_descriptor? : @render_resource.RenderPipelineDescriptor? = None,
) -> Unit raise GpuBackendError {
  self.draw_mesh_material_with_options(
    mesh_id,
    x,
    y,
    rotation,
    scale_x,
    scale_y,
    alpha_mode_kind,
    material_bind_group,
    vertex_shader_path~,
    fragment_shader_path~,
    wireframe=false,
    pipeline_descriptor~,
  )
}

///|
pub fn draw_mesh(
  mesh_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  alpha_mode_kind~ : Int,
  alpha_cutoff~ : Float,
  texture_id~ : Int,
  uv_offset_x~ : Float,
  uv_offset_y~ : Float,
  uv_scale_x~ : Float,
  uv_scale_y~ : Float,
  vertex_shader_path? : String? = None,
  fragment_shader_path? : String? = None,
) -> Unit {
  let material_bind_group = host_material2d_color_material_bind_group(
    color_r, color_g, color_b, color_a, alpha_mode_kind, alpha_cutoff, texture_id,
    uv_offset_x, uv_offset_y, uv_scale_x, uv_scale_y,
  )
  draw_mesh_material(
    mesh_id~,
    x~,
    y~,
    rotation~,
    scale_x~,
    scale_y~,
    alpha_mode_kind~,
    material_bind_group~,
    vertex_shader_path~,
    fragment_shader_path~,
  )
}

///|
pub fn GpuBackend::draw_mesh2d_pipeline(
  self : GpuBackend,
  mesh_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  pipeline_id : UInt64,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else {
    render_diagnostics_record_mesh2d_drop_no_frame()
    return
  }
  guard frame.pass is Some(pass) else {
    render_diagnostics_record_mesh2d_drop_no_pass()
    return
  }
  guard self.pass_state is Some(_) else {
    render_diagnostics_record_mesh2d_drop_no_pass_state()
    return
  }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  flush_mesh2d_batches(self)
  guard find_mesh(self, mesh_id) is Some(mesh) else {
    render_diagnostics_record_mesh2d_drop_missing_mesh()
    return
  }
  guard mesh.vertex_layout is Some(_) else {
    render_diagnostics_record_mesh2d_drop_bad_stride()
    return
  }
  ensure_mesh2d_resources(self)
  guard self.mesh2d_pipeline_descriptor(pipeline_id) is Some(descriptor) else {
    render_diagnostics_record_mesh2d_drop_no_pipeline()
    return
  }
  guard mesh2d_registered_pipeline_for_draw(self, mesh, descriptor)
    is Some(pipeline) else {
    render_diagnostics_record_mesh2d_drop_no_pipeline()
    return
  }
  guard self.mesh2d_view_bg is Some(view_bg) else {
    render_diagnostics_record_mesh2d_drop_no_uniform_buf()
    return
  }
  let uniform_base_offset = mesh2d_align_up(
    self.mesh2d_instance_used.to_uint64(),
    MESH2D_UNIFORM_DYNAMIC_STRIDE_BYTES,
  ).to_int()
  let next_instance_used = uniform_base_offset +
    MESH2D_UNIFORM_STRIDE_BYTES.to_int()
  if next_instance_used < 0 {
    render_diagnostics_record_mesh2d_drop_no_uniform_buf()
    return
  }
  guard ensure_mesh2d_instance_uniform_binding(
      self,
      next_instance_used.to_uint64(),
    )
    is Some((instance_uniform_buf, instance_uniform_bg)) else {
    render_diagnostics_record_mesh2d_drop_no_uniform_buf()
    return
  }
  if next_instance_used > self.mesh2d_instance_used {
    self.mesh2d_instance_used = next_instance_used
  }
  self.queue.write_buffer(
    instance_uniform_buf,
    uniform_base_offset.to_uint64(),
    mesh2d_instance_uniform_bytes(x, y, rotation, scale_x, scale_y, 0U, 0U),
  )
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, view_bg, [0U])
  pass.set_bind_group(1U, instance_uniform_bg, [
    uniform_base_offset.reinterpret_as_uint(),
  ])
  pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, mesh.vertex_buf.size())
  render_diagnostics_record_mesh2d_executed_draw()
  if mesh.index_count == 0U {
    pass.draw(mesh.vertex_count, 1U, mesh.vertex_start, 0U)
  } else {
    gpu_mesh_bind_index_buffer(pass, mesh)
    pass.draw_indexed(
      mesh.index_count,
      1U,
      mesh.index_start,
      mesh.vertex_start.reinterpret_as_int(),
      0U,
    )
  }
}

///|
pub fn draw_mesh_wireframe(
  mesh_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
) -> Unit {
  render_diagnostics_record_mesh2d_draw(mesh_id)
  if ensure_backend() is Some(backend) {
    let alpha_mode_kind = if color_a < 1.0F {
      MESH2D_ALPHA_MODE_KIND_BLEND
    } else {
      MESH2D_ALPHA_MODE_KIND_OPAQUE
    }
    let material_bind_group = host_material2d_wireframe_bind_group(
      color_r, color_g, color_b, color_a,
    )
    backend.draw_mesh_material_with_options(
      mesh_id,
      x,
      y,
      rotation,
      scale_x,
      scale_y,
      alpha_mode_kind,
      material_bind_group,
      vertex_shader_path=None,
      fragment_shader_path=Some(MESH2D_WIREFRAME_SHADER_PATH),
      wireframe=true,
    ) catch {
      err => debug_runtime_error("draw_mesh_wireframe", err)
    }
  }
}

///|
pub fn draw_mesh_material(
  mesh_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  alpha_mode_kind~ : Int,
  material_bind_group~ : HostMaterial2dBindGroup,
  vertex_shader_path? : String? = None,
  fragment_shader_path? : String? = None,
  pipeline_descriptor? : @render_resource.RenderPipelineDescriptor? = None,
) -> Unit {
  render_diagnostics_record_mesh2d_draw(mesh_id)
  if ensure_backend() is Some(backend) {
    backend.draw_mesh_material(
      mesh_id,
      x,
      y,
      rotation,
      scale_x,
      scale_y,
      alpha_mode_kind,
      material_bind_group,
      vertex_shader_path~,
      fragment_shader_path~,
      pipeline_descriptor~,
    ) catch {
      err => debug_runtime_error("draw_mesh_material", err)
    }
  }
}

///|
pub fn register_mesh2d_pipeline_descriptor(
  pipeline_id~ : UInt64,
  shader_path~ : String,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.register_mesh2d_pipeline_descriptor(pipeline_id, shader_path)
  }
}

///|
pub fn draw_mesh2d_pipeline(
  mesh_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  pipeline_id~ : UInt64,
) -> Unit {
  render_diagnostics_record_mesh2d_draw(mesh_id)
  if ensure_backend() is Some(backend) {
    backend.draw_mesh2d_pipeline(
      mesh_id, x, y, rotation, scale_x, scale_y, pipeline_id,
    ) catch {
      err => debug_runtime_error("draw_mesh2d_pipeline", err)
    }
  }
}

///|
pub fn draw_gizmo_line(
  start_x~ : Float,
  start_y~ : Float,
  start_r~ : Float,
  start_g~ : Float,
  start_b~ : Float,
  start_a~ : Float,
  end_x~ : Float,
  end_y~ : Float,
  end_r~ : Float,
  end_g~ : Float,
  end_b~ : Float,
  end_a~ : Float,
  line_width~ : Float,
  style_kind~ : Int,
  gap_scale~ : Float,
  line_scale~ : Float,
) -> Unit {
  let line_width_value = if line_width < 1.0F { 1.0F } else { line_width }
  style_kind |> ignore
  gap_scale |> ignore
  line_scale |> ignore
  let dx = end_x - start_x
  let dy = end_y - start_y
  let length = Float::sqrt(dx * dx + dy * dy)
  if length <= 0.0F {
    return
  }
  let center_x = (start_x + end_x) * 0.5F
  let center_y = (start_y + end_y) * 0.5F
  let rotation = atan2f(dy, dx)
  let color_r = (start_r + end_r) * 0.5F
  let color_g = (start_g + end_g) * 0.5F
  let color_b = (start_b + end_b) * 0.5F
  let color_a = (start_a + end_a) * 0.5F
  if ensure_backend() is Some(backend) {
    try {
      let mesh_id = if backend.mesh2d_gizmo_line_mesh_id > 0 {
        backend.mesh2d_gizmo_line_mesh_id
      } else {
        let created = backend.create_mesh_rectangle(1.0F, 1.0F)
        if created > 0 {
          backend.mesh2d_gizmo_line_mesh_id = created
        }
        created
      }
      if mesh_id > 0 {
        let alpha_mode_kind = if color_a < 1.0F {
          MESH2D_ALPHA_MODE_KIND_BLEND
        } else {
          MESH2D_ALPHA_MODE_KIND_OPAQUE
        }
        backend.draw_mesh(
          mesh_id, center_x, center_y, rotation, length, line_width_value, color_r,
          color_g, color_b, color_a, alpha_mode_kind, 0.5F, -1, 0.0F, 0.0F, 1.0F,
          1.0F,
        )
      }
    } catch {
      err => debug_runtime_error("draw_gizmo_line", err)
    }
  }
}

///|
