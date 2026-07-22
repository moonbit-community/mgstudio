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
/// Image package boundary aligned with Bevy-style image responsibilities.

///|
pub(all) struct Image {
  width : Int
  height : Int
  mut pixels : Bytes
  format : TextureFormat
  view_format : TextureFormat?
  sampler : ImageSampler
  kind : ImageKind
  mip_level_count : Int
  usage_bits : Int
  mut texture_descriptor_label : String?
  mut array_layout : ImageArrayLayout?
  mut texture_view_dimension : ImageTextureViewDimension?
}

///|
pub const IMAGE_USAGE_TEXTURE_BINDING : Int = 1

///|
pub const IMAGE_USAGE_COPY_DST : Int = 2

///|
pub const IMAGE_USAGE_COPY_SRC : Int = 4

///|
pub const IMAGE_USAGE_RENDER_ATTACHMENT : Int = 8

///|
pub const IMAGE_USAGE_STORAGE_BINDING : Int = 16

///|
const IMAGE_USAGE_ALL_MASK : Int = 31

///|
const IMAGE_USAGE_DEFAULT_SAMPLED : Int = IMAGE_USAGE_TEXTURE_BINDING |
  IMAGE_USAGE_COPY_DST |
  IMAGE_USAGE_COPY_SRC

///|
const IMAGE_USAGE_DEFAULT_TARGET : Int = IMAGE_USAGE_TEXTURE_BINDING |
  IMAGE_USAGE_COPY_DST |
  IMAGE_USAGE_RENDER_ATTACHMENT

///|
fn image_usage_sanitize(usage_bits : Int) -> Int {
  let usage = usage_bits.reinterpret_as_uint()
  let mask = IMAGE_USAGE_ALL_MASK.reinterpret_as_uint()
  (usage & mask).reinterpret_as_int()
}

///|
fn image_mip_count_sanitize(mip_level_count : Int) -> Int {
  if mip_level_count <= 0 {
    1
  } else {
    mip_level_count
  }
}

///|
pub fn Image::new(width : Int, height : Int, pixels : Bytes) -> Image {
  {
    width,
    height,
    pixels,
    format: Rgba8Unorm,
    view_format: None,
    sampler: ImageSampler::default(),
    kind: Data,
    mip_level_count: 1,
    usage_bits: IMAGE_USAGE_DEFAULT_SAMPLED,
    texture_descriptor_label: None,
    array_layout: None,
    texture_view_dimension: None,
  }
}

///|
pub fn Image::with_format(self : Image, format : TextureFormat) -> Image {
  {
    width: self.width,
    height: self.height,
    pixels: self.pixels,
    format,
    view_format: self.view_format,
    sampler: self.sampler,
    kind: self.kind,
    mip_level_count: self.mip_level_count,
    usage_bits: self.usage_bits,
    texture_descriptor_label: self.texture_descriptor_label,
    array_layout: self.array_layout,
    texture_view_dimension: self.texture_view_dimension,
  }
}

///|
pub fn Image::with_sampler(self : Image, sampler : ImageSampler) -> Image {
  {
    width: self.width,
    height: self.height,
    pixels: self.pixels,
    format: self.format,
    view_format: self.view_format,
    sampler,
    kind: self.kind,
    mip_level_count: self.mip_level_count,
    usage_bits: self.usage_bits,
    texture_descriptor_label: self.texture_descriptor_label,
    array_layout: self.array_layout,
    texture_view_dimension: self.texture_view_dimension,
  }
}

///|
pub fn Image::with_mip_level_count(
  self : Image,
  mip_level_count : Int,
) -> Image {
  {
    width: self.width,
    height: self.height,
    pixels: self.pixels,
    format: self.format,
    view_format: self.view_format,
    sampler: self.sampler,
    kind: self.kind,
    mip_level_count: image_mip_count_sanitize(mip_level_count),
    usage_bits: self.usage_bits,
    texture_descriptor_label: self.texture_descriptor_label,
    array_layout: self.array_layout,
    texture_view_dimension: self.texture_view_dimension,
  }
}

///|
pub fn Image::with_texture_usage_bits(self : Image, usage_bits : Int) -> Image {
  {
    width: self.width,
    height: self.height,
    pixels: self.pixels,
    format: self.format,
    view_format: self.view_format,
    sampler: self.sampler,
    kind: self.kind,
    mip_level_count: self.mip_level_count,
    usage_bits: image_usage_sanitize(usage_bits),
    texture_descriptor_label: self.texture_descriptor_label,
    array_layout: self.array_layout,
    texture_view_dimension: self.texture_view_dimension,
  }
}

///|
pub fn Image::with_added_texture_usage(self : Image, usage_bits : Int) -> Image {
  let current = self.usage_bits.reinterpret_as_uint()
  let add = image_usage_sanitize(usage_bits).reinterpret_as_uint()
  self.with_texture_usage_bits((current | add).reinterpret_as_int())
}

///|
pub fn Image::width(self : Image) -> Int {
  self.width
}

///|
pub fn Image::height(self : Image) -> Int {
  self.height
}

///|
pub fn Image::mip_level_count(self : Image) -> Int {
  self.mip_level_count
}

///|
pub fn Image::format(self : Image) -> TextureFormat {
  self.format
}

///|
pub fn Image::view_format(self : Image) -> TextureFormat? {
  self.view_format
}

///|
pub fn Image::pixel_byte_len(self : Image) -> Int {
  self.pixels.length()
}

///|
pub fn Image::data(self : Image) -> Bytes {
  self.pixels
}

///|
pub fn Image::texture_usage_bits(self : Image) -> Int {
  self.usage_bits
}

///|
pub fn Image::texture_descriptor_label(self : Image) -> String? {
  self.texture_descriptor_label
}

///|
pub fn Image::set_texture_descriptor_label(
  self : Image,
  label : String?,
) -> Unit {
  self.texture_descriptor_label = label
}

///|
pub fn Image::with_texture_descriptor_label(
  self : Image,
  label : String?,
) -> Image {
  {
    width: self.width,
    height: self.height,
    pixels: self.pixels,
    format: self.format,
    view_format: self.view_format,
    sampler: self.sampler,
    kind: self.kind,
    mip_level_count: self.mip_level_count,
    usage_bits: self.usage_bits,
    texture_descriptor_label: label,
    array_layout: self.array_layout,
    texture_view_dimension: self.texture_view_dimension,
  }
}

///|
pub fn Image::texture_view_dimension(
  self : Image,
) -> ImageTextureViewDimension? {
  self.texture_view_dimension
}

///|
pub fn Image::array_layout(self : Image) -> ImageArrayLayout? {
  self.array_layout
}

///|
pub fn Image::with_array_layout(
  self : Image,
  array_layout : ImageArrayLayout?,
) -> Image {
  {
    width: self.width,
    height: self.height,
    pixels: self.pixels,
    format: self.format,
    view_format: self.view_format,
    sampler: self.sampler,
    kind: self.kind,
    mip_level_count: self.mip_level_count,
    usage_bits: self.usage_bits,
    texture_descriptor_label: self.texture_descriptor_label,
    array_layout,
    texture_view_dimension: self.texture_view_dimension,
  }
}

///|
pub fn Image::set_texture_view_dimension(
  self : Image,
  dimension : ImageTextureViewDimension?,
) -> Unit {
  self.texture_view_dimension = dimension
}

///|
pub fn Image::with_texture_view_dimension(
  self : Image,
  texture_view_dimension : ImageTextureViewDimension?,
) -> Image {
  {
    width: self.width,
    height: self.height,
    pixels: self.pixels,
    format: self.format,
    view_format: self.view_format,
    sampler: self.sampler,
    kind: self.kind,
    mip_level_count: self.mip_level_count,
    usage_bits: self.usage_bits,
    texture_descriptor_label: self.texture_descriptor_label,
    array_layout: self.array_layout,
    texture_view_dimension,
  }
}

///|
pub fn Image::reinterpret_stacked_2d_as_array(
  self : Image,
  layers : Int,
) -> Bool {
  if layers <= 0 || self.height <= 0 || self.height % layers != 0 {
    false
  } else {
    self.array_layout = Some(RowCount(layers))
    true
  }
}

///|
pub(all) enum TextureFormat {
  Rgba8Unorm
  Rgba8UnormSrgb
  Bgra8Unorm
  Bgra8UnormSrgb
  Rgba16Uint
  Rgba16Float
  Rgba32Float
  Rg16Float
} derive(Eq, Debug)

///|
pub fn TextureFormat::default() -> TextureFormat {
  Rgba8Unorm
}

///|
pub(all) enum ImageKind {
  Data
  TargetTexture
} derive(Eq, Debug)

///|
pub fn Image::new_target_texture(
  width : Int,
  height : Int,
  format : TextureFormat,
  view_format : TextureFormat?,
) -> Image {
  {
    width,
    height,
    pixels: Bytes::new(0),
    format,
    view_format,
    sampler: ImageSampler::default(),
    kind: TargetTexture,
    mip_level_count: 1,
    usage_bits: IMAGE_USAGE_DEFAULT_TARGET,
    texture_descriptor_label: None,
    array_layout: None,
    texture_view_dimension: None,
  }
}

///|
pub fn Image::is_target_texture(self : Image) -> Bool {
  self.kind == TargetTexture
}

///|
pub fn texture_format(format : TextureFormat) -> @wgpu.TextureFormat {
  match format {
    Rgba8Unorm =>
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
    Rgba8UnormSrgb =>
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB)
    Bgra8Unorm =>
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_BGRA8_UNORM)
    Bgra8UnormSrgb =>
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB)
    Rgba16Uint =>
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RGBA16_UINT)
    Rgba16Float =>
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
    Rgba32Float =>
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RGBA32_FLOAT)
    Rg16Float => @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RG16_FLOAT)
  }
}

///|
pub(all) enum ImageArrayLayout {
  RowCount(Int)
  RowHeight(Int)
} derive(Eq, Debug)

///|
pub(all) enum ImageTextureViewDimension {
  D1
  D2
  D2Array
  Cube
  CubeArray
  D3
} derive(Eq, Debug)

///|
pub(all) enum ImageAddressMode {
  ClampToEdge
  Repeat
  MirrorRepeat
  ClampToBorder
} derive(Eq, Debug)

///|
pub fn ImageAddressMode::default() -> ImageAddressMode {
  ClampToEdge
}

///|
pub(all) enum ImageFilterMode {
  Nearest
  Linear
} derive(Eq, Debug)

///|
pub fn ImageFilterMode::default() -> ImageFilterMode {
  Nearest
}

///|
pub(all) enum ImageCompareFunction {
  Never
  Less
  Equal
  LessEqual
  Greater
  NotEqual
  GreaterEqual
  Always
} derive(Eq, Debug)

///|
pub(all) enum ImageSamplerBorderColor {
  TransparentBlack
  OpaqueBlack
  OpaqueWhite
  Zero
} derive(Eq, Debug)

///|
pub(all) struct ImageSamplerDescriptor {
  mut label : String?
  mut address_mode_u : ImageAddressMode
  mut address_mode_v : ImageAddressMode
  mut address_mode_w : ImageAddressMode
  mut mag_filter : ImageFilterMode
  mut min_filter : ImageFilterMode
  mut mipmap_filter : ImageFilterMode
  mut lod_min_clamp : Float
  mut lod_max_clamp : Float
  mut compare : ImageCompareFunction?
  mut anisotropy_clamp : Int
  mut border_color : ImageSamplerBorderColor?
}

///|
pub fn ImageSamplerDescriptor::ImageSamplerDescriptor() -> ImageSamplerDescriptor {
  {
    label: None,
    address_mode_u: ImageAddressMode::default(),
    address_mode_v: ImageAddressMode::default(),
    address_mode_w: ImageAddressMode::default(),
    mag_filter: ImageFilterMode::default(),
    min_filter: ImageFilterMode::default(),
    mipmap_filter: ImageFilterMode::default(),
    lod_min_clamp: 0.0F,
    lod_max_clamp: 32.0F,
    compare: None,
    anisotropy_clamp: 1,
    border_color: None,
  }
}

///|
pub fn ImageSamplerDescriptor::linear() -> ImageSamplerDescriptor {
  let descriptor = ImageSamplerDescriptor::ImageSamplerDescriptor()
  descriptor.mag_filter = Linear
  descriptor.min_filter = Linear
  descriptor.mipmap_filter = Linear
  descriptor
}

///|
pub fn ImageSamplerDescriptor::nearest() -> ImageSamplerDescriptor {
  ImageSamplerDescriptor()
}

///|
pub fn ImageSamplerDescriptor::set_filter(
  self : ImageSamplerDescriptor,
  filter : ImageFilterMode,
) -> ImageSamplerDescriptor {
  self.mag_filter = filter
  self.min_filter = filter
  self.mipmap_filter = filter
  self
}

///|
pub fn ImageSamplerDescriptor::set_address_mode(
  self : ImageSamplerDescriptor,
  address_mode : ImageAddressMode,
) -> ImageSamplerDescriptor {
  self.address_mode_u = address_mode
  self.address_mode_v = address_mode
  self.address_mode_w = address_mode
  self
}

///|
pub fn ImageSamplerDescriptor::set_anisotropic_filter(
  self : ImageSamplerDescriptor,
  anisotropy_clamp : Int,
) -> ImageSamplerDescriptor {
  self.mag_filter = Linear
  self.min_filter = Linear
  self.mipmap_filter = Linear
  self.anisotropy_clamp = anisotropy_clamp
  self
}

///|
pub(all) enum ImageSampler {
  Default
  Descriptor(ImageSamplerDescriptor)
}

///|
pub fn ImageSampler::default() -> ImageSampler {
  Default
}

///|
pub fn ImageSampler::linear() -> ImageSampler {
  Descriptor(ImageSamplerDescriptor::linear())
}

///|
pub fn ImageSampler::nearest() -> ImageSampler {
  Descriptor(ImageSamplerDescriptor::nearest())
}

///|
const IMAGE_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE : Int = 0

///|
const IMAGE_SAMPLER_ADDRESS_MODE_REPEAT : Int = 1

///|
const IMAGE_SAMPLER_ADDRESS_MODE_MIRROR_REPEAT : Int = 2

///|
const IMAGE_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER : Int = 3

///|
const IMAGE_SAMPLER_FILTER_MODE_NEAREST : Int = 0

///|
const IMAGE_SAMPLER_FILTER_MODE_LINEAR : Int = 1

///|
const IMAGE_SAMPLER_COMPARE_UNDEFINED : Int = -1

///|
const IMAGE_SAMPLER_COMPARE_NEVER : Int = 0

///|
const IMAGE_SAMPLER_COMPARE_LESS : Int = 1

///|
const IMAGE_SAMPLER_COMPARE_EQUAL : Int = 2

///|
const IMAGE_SAMPLER_COMPARE_LESS_EQUAL : Int = 3

///|
const IMAGE_SAMPLER_COMPARE_GREATER : Int = 4

///|
const IMAGE_SAMPLER_COMPARE_NOT_EQUAL : Int = 5

///|
const IMAGE_SAMPLER_COMPARE_GREATER_EQUAL : Int = 6

///|
const IMAGE_SAMPLER_COMPARE_ALWAYS : Int = 7

///|
const IMAGE_SAMPLER_BORDER_COLOR_UNDEFINED : Int = -1

///|
const IMAGE_SAMPLER_BORDER_COLOR_TRANSPARENT_BLACK : Int = 0

///|
const IMAGE_SAMPLER_BORDER_COLOR_OPAQUE_BLACK : Int = 1

///|
const IMAGE_SAMPLER_BORDER_COLOR_OPAQUE_WHITE : Int = 2

///|
const IMAGE_SAMPLER_BORDER_COLOR_ZERO : Int = 3

///|
fn image_address_mode_runtime_raw(mode : ImageAddressMode) -> Int {
  match mode {
    ClampToEdge => IMAGE_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
    Repeat => IMAGE_SAMPLER_ADDRESS_MODE_REPEAT
    MirrorRepeat => IMAGE_SAMPLER_ADDRESS_MODE_MIRROR_REPEAT
    ClampToBorder => IMAGE_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER
  }
}

///|
fn image_filter_mode_runtime_raw(mode : ImageFilterMode) -> Int {
  match mode {
    Nearest => IMAGE_SAMPLER_FILTER_MODE_NEAREST
    Linear => IMAGE_SAMPLER_FILTER_MODE_LINEAR
  }
}

///|
fn image_compare_function_runtime_raw(compare : ImageCompareFunction?) -> Int {
  match compare {
    None => IMAGE_SAMPLER_COMPARE_UNDEFINED
    Some(compare) =>
      match compare {
        Never => IMAGE_SAMPLER_COMPARE_NEVER
        Less => IMAGE_SAMPLER_COMPARE_LESS
        Equal => IMAGE_SAMPLER_COMPARE_EQUAL
        LessEqual => IMAGE_SAMPLER_COMPARE_LESS_EQUAL
        Greater => IMAGE_SAMPLER_COMPARE_GREATER
        NotEqual => IMAGE_SAMPLER_COMPARE_NOT_EQUAL
        GreaterEqual => IMAGE_SAMPLER_COMPARE_GREATER_EQUAL
        Always => IMAGE_SAMPLER_COMPARE_ALWAYS
      }
  }
}

///|
fn image_sampler_border_color_runtime_raw(
  border_color : ImageSamplerBorderColor?,
) -> Int {
  match border_color {
    None => IMAGE_SAMPLER_BORDER_COLOR_UNDEFINED
    Some(color) =>
      match color {
        TransparentBlack => IMAGE_SAMPLER_BORDER_COLOR_TRANSPARENT_BLACK
        OpaqueBlack => IMAGE_SAMPLER_BORDER_COLOR_OPAQUE_BLACK
        OpaqueWhite => IMAGE_SAMPLER_BORDER_COLOR_OPAQUE_WHITE
        Zero => IMAGE_SAMPLER_BORDER_COLOR_ZERO
      }
  }
}

///|
fn image_sampler_descriptor_runtime_args(
  descriptor : ImageSamplerDescriptor,
) -> (Int, Int, Int, Int, Int, Int, Float, Float, Int, Int, Int) {
  (
    image_address_mode_runtime_raw(descriptor.address_mode_u),
    image_address_mode_runtime_raw(descriptor.address_mode_v),
    image_address_mode_runtime_raw(descriptor.address_mode_w),
    image_filter_mode_runtime_raw(descriptor.mag_filter),
    image_filter_mode_runtime_raw(descriptor.min_filter),
    image_filter_mode_runtime_raw(descriptor.mipmap_filter),
    descriptor.lod_min_clamp,
    descriptor.lod_max_clamp,
    image_compare_function_runtime_raw(descriptor.compare),
    descriptor.anisotropy_clamp,
    image_sampler_border_color_runtime_raw(descriptor.border_color),
  )
}

///|
pub fn image_sampler_runtime_args(
  sampler : ImageSampler,
  default_nearest : Bool,
) -> (Int, Int, Int, Int, Int, Int, Float, Float, Int, Int, Int) {
  match sampler {
    Default =>
      if default_nearest {
        image_sampler_descriptor_runtime_args(ImageSamplerDescriptor::nearest())
      } else {
        image_sampler_descriptor_runtime_args(ImageSamplerDescriptor::linear())
      }
    Descriptor(descriptor) => image_sampler_descriptor_runtime_args(descriptor)
  }
}

///|
pub fn image_sampler_is_nearest(sampler : ImageSampler) -> Bool {
  match sampler {
    Default => false
    Descriptor(descriptor) =>
      descriptor.mag_filter == Nearest && descriptor.min_filter == Nearest
  }
}
