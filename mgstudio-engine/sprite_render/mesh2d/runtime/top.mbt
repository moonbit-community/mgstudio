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
pub(all) struct PhaseEntityRef {
  render_entity : @core.Entity
  main_entity : @core.Entity
}

///|
pub fn phase_entity_ref_for_main(main_entity : @core.Entity) -> PhaseEntityRef {
  PhaseEntityRef::{ render_entity: main_entity, main_entity }
}

///|
pub fn phase_entity_ref_placeholder() -> PhaseEntityRef {
  let placeholder = @core.Entity::placeholder()
  PhaseEntityRef::{ render_entity: placeholder, main_entity: placeholder }
}

///|
fn cmp_int(lhs : Int, rhs : Int) -> Int {
  if lhs < rhs {
    -1
  } else if lhs > rhs {
    1
  } else {
    0
  }
}

///|
pub fn phase_entity_ref_cmp(lhs : PhaseEntityRef, rhs : PhaseEntityRef) -> Int {
  let render_id = cmp_int(lhs.render_entity.id, rhs.render_entity.id)
  if render_id != 0 {
    return render_id
  }
  let render_generation = cmp_int(
    lhs.render_entity.generation,
    rhs.render_entity.generation,
  )
  if render_generation != 0 {
    return render_generation
  }
  let main_id = cmp_int(lhs.main_entity.id, rhs.main_entity.id)
  if main_id != 0 {
    return main_id
  }
  cmp_int(lhs.main_entity.generation, rhs.main_entity.generation)
}

///|
pub suberror Mesh2dPipelineKeyError {
  UnsupportedTargetFormat(UInt)
}

///|
pub const MESH2D_PIPELINE_KEY_TONEMAP_IN_SHADER : Int = 1

///|
pub const MESH2D_PIPELINE_KEY_DEBAND_DITHER : Int = 1 << 1

///|
pub const MESH2D_PIPELINE_KEY_BLEND_ALPHA : Int = 1 << 2

///|
pub const MESH2D_PIPELINE_KEY_MAY_DISCARD : Int = 1 << 3

///|
pub const MESH2D_PIPELINE_KEY_SRGB_COMPOSITING : Int = 1 << 4

///|
pub const MESH2D_PIPELINE_KEY_OKLAB_COMPOSITING : Int = 1 << 5

///|
pub const MESH2D_PIPELINE_KEY_COLOR_TARGET_FORMAT_MASK_BITS : UInt = 0b11111U

///|
pub const MESH2D_PIPELINE_KEY_COLOR_TARGET_FORMAT_SHIFT_BITS : Int = 6

///|
pub const MESH2D_PIPELINE_KEY_MSAA_MASK_BITS : Int = 0b111

///|
pub const MESH2D_PIPELINE_KEY_MSAA_SHIFT_BITS : Int = 29

///|
pub const MESH2D_PRIMITIVE_TOPOLOGY_LINE_STRIP : UInt = 2U

///|
pub const MESH2D_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST : UInt = 3U

///|
pub const MESH2D_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP : UInt = 4U

///|
pub const MESH2D_PIPELINE_KEY_PRIMITIVE_TOPOLOGY_MASK_BITS : UInt = 0b111U

///|
pub const MESH2D_PIPELINE_KEY_PRIMITIVE_TOPOLOGY_SHIFT_BITS : Int = 26

///|
pub const MESH2D_PIPELINE_KEY_INDEX_FORMAT_SHIFT_BITS : Int = 18

///|
pub const MESH2D_PIPELINE_KEY_TONEMAP_METHOD_MASK_BITS : Int = 0b1111

///|
pub const MESH2D_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS : Int = 22

///|
pub const MESH2D_PIPELINE_KEY_TONEMAP_METHOD_NONE : Int = 0 <<
  MESH2D_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS

///|
pub const MESH2D_PIPELINE_KEY_TONEMAP_METHOD_REINHARD : Int = 1 <<
  MESH2D_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS

///|
pub const MESH2D_PIPELINE_KEY_TONEMAP_METHOD_REINHARD_LUMINANCE : Int = 2 <<
  MESH2D_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS

///|
pub const MESH2D_PIPELINE_KEY_TONEMAP_METHOD_ACES_FITTED : Int = 3 <<
  MESH2D_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS

///|
pub const MESH2D_PIPELINE_KEY_TONEMAP_METHOD_AGX : Int = 4 <<
  MESH2D_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS

///|
pub const MESH2D_PIPELINE_KEY_TONEMAP_METHOD_SOMEWHAT_BORING_DISPLAY_TRANSFORM : Int = 5 <<
  MESH2D_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS

///|
pub const MESH2D_PIPELINE_KEY_TONEMAP_METHOD_TONY_MC_MAPFACE : Int = 6 <<
  MESH2D_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS

///|
pub const MESH2D_PIPELINE_KEY_TONEMAP_METHOD_BLENDER_FILMIC : Int = 7 <<
  MESH2D_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS

///|
pub const MESH2D_PIPELINE_KEY_TONEMAP_METHOD_PBR_NEUTRAL : Int = 8 <<
  MESH2D_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS

///|
pub const MESH2D_PIPELINE_KEY_STRIP_INDEX_FORMAT_NONE : Int = 0 <<
  MESH2D_PIPELINE_KEY_INDEX_FORMAT_SHIFT_BITS

///|
pub const MESH2D_PIPELINE_KEY_STRIP_INDEX_FORMAT_U32 : Int = 1 <<
  MESH2D_PIPELINE_KEY_INDEX_FORMAT_SHIFT_BITS

///|
pub const MESH2D_PIPELINE_KEY_STRIP_INDEX_FORMAT_U16 : Int = 2 <<
  MESH2D_PIPELINE_KEY_INDEX_FORMAT_SHIFT_BITS

///|
pub fn mesh2d_primitive_topology_is_strip(primitive_topology : UInt) -> Bool {
  primitive_topology == MESH2D_PRIMITIVE_TOPOLOGY_LINE_STRIP ||
  primitive_topology == MESH2D_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP
}

///|
pub fn mesh2d_texture_format_to_code(format_raw : UInt) -> Int? {
  match format_raw {
    @wgpu.TEXTURE_FORMAT_R8_UNORM => Some(0)
    @wgpu.TEXTURE_FORMAT_R8_SNORM => Some(1)
    @wgpu.TEXTURE_FORMAT_RG8_UNORM => Some(2)
    @wgpu.TEXTURE_FORMAT_RG8_SNORM => Some(3)
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM => Some(4)
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB => Some(5)
    @wgpu.TEXTURE_FORMAT_RGBA8_SNORM => Some(6)
    @wgpu.TEXTURE_FORMAT_BGRA8_UNORM => Some(7)
    @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB => Some(8)
    @wgpu.TEXTURE_FORMAT_R16_UNORM => Some(9)
    @wgpu.TEXTURE_FORMAT_R16_SNORM => Some(10)
    @wgpu.TEXTURE_FORMAT_R16_FLOAT => Some(11)
    @wgpu.TEXTURE_FORMAT_RG16_FLOAT => Some(12)
    @wgpu.TEXTURE_FORMAT_RG16_UNORM => Some(13)
    @wgpu.TEXTURE_FORMAT_RG16_SNORM => Some(14)
    @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT => Some(15)
    @wgpu.TEXTURE_FORMAT_RGBA16_UNORM => Some(16)
    @wgpu.TEXTURE_FORMAT_RGBA16_SNORM => Some(17)
    @wgpu.TEXTURE_FORMAT_R32_FLOAT => Some(18)
    @wgpu.TEXTURE_FORMAT_RG32_FLOAT => Some(19)
    @wgpu.TEXTURE_FORMAT_RGBA32_FLOAT => Some(20)
    @wgpu.TEXTURE_FORMAT_RGB10_A2_UNORM => Some(21)
    @wgpu.TEXTURE_FORMAT_RG11_B10_UFLOAT => Some(22)
    _ => None
  }
}

///|
pub fn mesh2d_pipeline_key_bits_for_target_format(
  format_raw : UInt,
) -> Int raise Mesh2dPipelineKeyError {
  match mesh2d_texture_format_to_code(format_raw) {
    Some(code) =>
      (
        code &
        MESH2D_PIPELINE_KEY_COLOR_TARGET_FORMAT_MASK_BITS.reinterpret_as_int()
      ) <<
      MESH2D_PIPELINE_KEY_COLOR_TARGET_FORMAT_SHIFT_BITS
    None => raise Mesh2dPipelineKeyError::UnsupportedTargetFormat(format_raw)
  }
}

///|
fn mesh2d_msaa_trailing_zero_bits(msaa_samples : Int) -> Int {
  let mut samples = if msaa_samples < 1 { 1 } else { msaa_samples }
  let mut trailing = 0
  while samples > 1 && trailing < MESH2D_PIPELINE_KEY_MSAA_MASK_BITS {
    if samples % 2 != 0 {
      return trailing
    }
    samples = samples / 2
    trailing = trailing + 1
  }
  trailing
}

///|
pub fn mesh2d_pipeline_key_bits_for_msaa_samples(msaa_samples : Int) -> Int {
  (
    mesh2d_msaa_trailing_zero_bits(msaa_samples) &
    MESH2D_PIPELINE_KEY_MSAA_MASK_BITS
  ) <<
  MESH2D_PIPELINE_KEY_MSAA_SHIFT_BITS
}

///|
pub fn mesh2d_pipeline_key_bits_for_tonemapping(
  tonemapping : @post_process.Tonemapping,
) -> Int {
  match tonemapping {
    None => MESH2D_PIPELINE_KEY_TONEMAP_METHOD_NONE
    Reinhard => MESH2D_PIPELINE_KEY_TONEMAP_METHOD_REINHARD
    ReinhardLuminance => MESH2D_PIPELINE_KEY_TONEMAP_METHOD_REINHARD_LUMINANCE
    AcesFitted => MESH2D_PIPELINE_KEY_TONEMAP_METHOD_ACES_FITTED
    AgX => MESH2D_PIPELINE_KEY_TONEMAP_METHOD_AGX
    SomewhatBoringDisplayTransform =>
      MESH2D_PIPELINE_KEY_TONEMAP_METHOD_SOMEWHAT_BORING_DISPLAY_TRANSFORM
    TonyMcMapface => MESH2D_PIPELINE_KEY_TONEMAP_METHOD_TONY_MC_MAPFACE
    BlenderFilmic => MESH2D_PIPELINE_KEY_TONEMAP_METHOD_BLENDER_FILMIC
    PbrNeutral => MESH2D_PIPELINE_KEY_TONEMAP_METHOD_PBR_NEUTRAL
  }
}

///|
pub fn mesh2d_pipeline_key_bits_for_view(
  msaa_samples : Int,
  target_format_raw : UInt,
  hdr : Bool,
  compositing_space : @camera_compositing_space.CompositingSpace?,
  tonemapping : @post_process.Tonemapping?,
  deband_dither : @post_process.DebandDither?,
) -> Int raise Mesh2dPipelineKeyError {
  let mut view_key = mesh2d_pipeline_key_bits_for_msaa_samples(msaa_samples) |
    mesh2d_pipeline_key_bits_for_target_format(target_format_raw)
  match compositing_space {
    Some(Srgb) => view_key = view_key | MESH2D_PIPELINE_KEY_SRGB_COMPOSITING
    Some(Oklab) => view_key = view_key | MESH2D_PIPELINE_KEY_OKLAB_COMPOSITING
    Some(Linear) | None => ()
  }
  if !hdr {
    match tonemapping {
      Some(mode) =>
        view_key = view_key |
          MESH2D_PIPELINE_KEY_TONEMAP_IN_SHADER |
          mesh2d_pipeline_key_bits_for_tonemapping(mode)
      None => ()
    }
    match deband_dither {
      Some(Enabled) => view_key = view_key | MESH2D_PIPELINE_KEY_DEBAND_DITHER
      Some(Disabled) | None => ()
    }
  }
  view_key
}

///|
pub fn mesh2d_pipeline_key_bits_for_primitive(
  primitive_topology : UInt,
  index_count : Int,
  uses_u32_indices : Bool,
) -> Int {
  let primitive_bits = (primitive_topology &
    MESH2D_PIPELINE_KEY_PRIMITIVE_TOPOLOGY_MASK_BITS).reinterpret_as_int() <<
    MESH2D_PIPELINE_KEY_PRIMITIVE_TOPOLOGY_SHIFT_BITS
  let strip_index_bits = if mesh2d_primitive_topology_is_strip(
      primitive_topology,
    ) {
    if index_count <= 0 {
      MESH2D_PIPELINE_KEY_STRIP_INDEX_FORMAT_NONE
    } else if uses_u32_indices {
      MESH2D_PIPELINE_KEY_STRIP_INDEX_FORMAT_U32
    } else {
      MESH2D_PIPELINE_KEY_STRIP_INDEX_FORMAT_U16
    }
  } else {
    MESH2D_PIPELINE_KEY_STRIP_INDEX_FORMAT_NONE
  }
  primitive_bits | strip_index_bits
}

///|
test "mesh2d pipeline key encodes target format and msaa" {
  debug_inspect(
    try! mesh2d_pipeline_key_bits_for_target_format(
      @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
    ),
    content="960",
  )
  debug_inspect(
    mesh2d_pipeline_key_bits_for_msaa_samples(4),
    content="1073741824",
  )
}

///|
test "mesh2d pipeline key encodes Bevy view bits" {
  debug_inspect(
    try! mesh2d_pipeline_key_bits_for_view(
      4,
      @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
      false,
      Some(@camera_compositing_space.CompositingSpace::Srgb),
      Some(@post_process.Tonemapping::AgX),
      Some(@post_process.DebandDither::Enabled),
    ),
    content="1090520019",
  )
  debug_inspect(
    try! mesh2d_pipeline_key_bits_for_view(
      1,
      @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
      true,
      Some(@camera_compositing_space.CompositingSpace::Oklab),
      Some(@post_process.Tonemapping::TonyMcMapface),
      Some(@post_process.DebandDither::Enabled),
    ),
    content="288",
  )
}

///|
test "mesh2d pipeline key encodes primitive topology" {
  debug_inspect(
    mesh2d_pipeline_key_bits_for_primitive(
      MESH2D_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
      0,
      false,
    ),
    content="201326592",
  )
}

///|
test "mesh2d pipeline key encodes strip index format only for strips" {
  debug_inspect(
    mesh2d_pipeline_key_bits_for_primitive(
      MESH2D_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP,
      6,
      false,
    ),
    content="268959744",
  )
  debug_inspect(
    mesh2d_pipeline_key_bits_for_primitive(
      MESH2D_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
      6,
      true,
    ),
    content="201326592",
  )
}

///|
pub(all) struct Mesh2dDrawPayload {
  mesh_id : Int
  transform : @transform.Transform
  layers : @camera_render_layers.RenderLayers
  wireframe : Bool
  wireframe_color : @color.Color
}

///|
pub(all) struct ExtractedMesh2d {
  entity : PhaseEntityRef
  payload : Mesh2dDrawPayload
}
