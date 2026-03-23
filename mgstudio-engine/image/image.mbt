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
pub struct Image {
  width : Int
  height : Int
  pixels : Bytes
  format : TextureFormat
  view_format : TextureFormat?
  kind : ImageKind
}

///|
pub fn Image::new(width : Int, height : Int, pixels : Bytes) -> Image {
  Image::{
    width,
    height,
    pixels,
    format: TextureFormat::Rgba8Unorm,
    view_format: None,
    kind: ImageKind::Data,
  }
}

///|
pub(all) enum TextureFormat {
  Rgba8Unorm
  Rgba8UnormSrgb
  Rgba16Float
  Rg16Float
} derive(Eq, Show)

///|
pub fn TextureFormat::default() -> TextureFormat {
  TextureFormat::Rgba8Unorm
}

///|
pub(all) enum ImageKind {
  Data
  TargetTexture
} derive(Eq, Show)

///|
pub fn Image::new_target_texture(
  width : Int,
  height : Int,
  format : TextureFormat,
  view_format : TextureFormat?,
) -> Image {
  Image::{
    width,
    height,
    pixels: Bytes::new(0),
    format,
    view_format,
    kind: ImageKind::TargetTexture,
  }
}

///|
pub fn Image::is_target_texture(self : Image) -> Bool {
  self.kind == ImageKind::TargetTexture
}

///|
pub fn texture_format_raw(format : TextureFormat) -> Int {
  match format {
    TextureFormat::Rgba8Unorm =>
      @wgpu.TEXTURE_FORMAT_RGBA8_UNORM.reinterpret_as_int()
    TextureFormat::Rgba8UnormSrgb =>
      @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB.reinterpret_as_int()
    TextureFormat::Rgba16Float =>
      @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT.reinterpret_as_int()
    TextureFormat::Rg16Float =>
      @wgpu.TEXTURE_FORMAT_RG16_FLOAT.reinterpret_as_int()
  }
}

///|
pub(all) enum ImageArrayLayout {
  RowCount(Int)
  RowHeight(Int)
}

///|
pub(all) enum ImageAddressMode {
  ClampToEdge
  Repeat
  MirrorRepeat
  ClampToBorder
} derive(Eq, Show)

///|
pub fn ImageAddressMode::default() -> ImageAddressMode {
  ImageAddressMode::ClampToEdge
}

///|
pub(all) enum ImageFilterMode {
  Nearest
  Linear
} derive(Eq, Show)

///|
pub fn ImageFilterMode::default() -> ImageFilterMode {
  ImageFilterMode::Nearest
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
} derive(Eq, Show)

///|
pub(all) enum ImageSamplerBorderColor {
  TransparentBlack
  OpaqueBlack
  OpaqueWhite
  Zero
} derive(Eq, Show)

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
pub fn ImageSamplerDescriptor::default() -> ImageSamplerDescriptor {
  ImageSamplerDescriptor::{
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
  let descriptor = ImageSamplerDescriptor::default()
  descriptor.mag_filter = ImageFilterMode::Linear
  descriptor.min_filter = ImageFilterMode::Linear
  descriptor.mipmap_filter = ImageFilterMode::Linear
  descriptor
}

///|
pub fn ImageSamplerDescriptor::nearest() -> ImageSamplerDescriptor {
  ImageSamplerDescriptor::default()
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
  self.mag_filter = ImageFilterMode::Linear
  self.min_filter = ImageFilterMode::Linear
  self.mipmap_filter = ImageFilterMode::Linear
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
  ImageSampler::Default
}

///|
pub fn ImageSampler::linear() -> ImageSampler {
  ImageSampler::Descriptor(ImageSamplerDescriptor::linear())
}

///|
pub fn ImageSampler::nearest() -> ImageSampler {
  ImageSampler::Descriptor(ImageSamplerDescriptor::nearest())
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
fn image_sampler_runtime_args(
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
    ImageSampler::Default => false
    ImageSampler::Descriptor(descriptor) =>
      descriptor.mag_filter == ImageFilterMode::Nearest &&
      descriptor.min_filter == ImageFilterMode::Nearest
  }
}

///|
pub(open) trait TextureHandle {
  texture_id(self : Self) -> Int
}

///|
pub fn set_texture_sampler_with_id(
  texture_id : Int,
  sampler : ImageSampler,
  default_nearest? : Bool = false,
) -> Unit {
  let (
    address_mode_u,
    address_mode_v,
    address_mode_w,
    mag_filter,
    min_filter,
    mipmap_filter,
    lod_min_clamp,
    lod_max_clamp,
    compare,
    anisotropy_clamp,
    border_color,
  ) = image_sampler_runtime_args(sampler, default_nearest)
  @render.asset_set_texture_sampler(
    texture_id~,
    address_mode_u~,
    address_mode_v~,
    address_mode_w~,
    mag_filter~,
    min_filter~,
    mipmap_filter~,
    lod_min_clamp~,
    lod_max_clamp~,
    compare~,
    anisotropy_clamp~,
    border_color~,
  )
}

///|
pub fn[T : TextureHandle] set_texture_sampler(
  texture : T,
  sampler : ImageSampler,
  default_nearest? : Bool = false,
) -> Unit {
  set_texture_sampler_with_id(texture.texture_id(), sampler, default_nearest~)
}
