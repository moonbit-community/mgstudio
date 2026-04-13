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
fn image_wb_bytes(values : Array[Int]) -> Bytes {
  let out : Array[Byte] = []
  for value in values {
    out.push(value.to_byte())
  }
  Bytes::from_array(out)
}

///|
fn image_wb_has_extension(values : Array[String], expected : String) -> Bool {
  for value in values {
    if value == expected {
      return true
    }
  }
  false
}

///|
fn image_wb_has_format(
  values : Array[ImageContainerFormat],
  expected : ImageContainerFormat,
) -> Bool {
  for value in values {
    if value == expected {
      return true
    }
  }
  false
}

///|
test "image wb: container format detection by extension" {
  debug_inspect(
    image_container_format_from_extension("png") == ImageContainerFormat::Png,
    content="true",
  )
  debug_inspect(
    image_container_format_from_extension("jpeg") == ImageContainerFormat::Jpeg,
    content="true",
  )
  debug_inspect(
    image_container_format_from_extension("hdr") == ImageContainerFormat::Hdr,
    content="true",
  )
  debug_inspect(
    image_container_format_from_extension("basis") ==
    ImageContainerFormat::Basis,
    content="true",
  )
  debug_inspect(
    image_container_format_from_extension("foo") ==
    ImageContainerFormat::Unknown("foo"),
    content="true",
  )
  debug_inspect(
    image_container_format_from_extension("webp") == ImageContainerFormat::Webp,
    content="true",
  )
  debug_inspect(
    image_container_format_from_extension("gif") == ImageContainerFormat::Gif,
    content="true",
  )
}

///|
test "image wb: hdr and gpu-compressed classification" {
  debug_inspect(
    image_container_is_hdr(ImageContainerFormat::Hdr),
    content="true",
  )
  debug_inspect(
    image_container_is_hdr(ImageContainerFormat::Exr),
    content="true",
  )
  debug_inspect(
    !image_container_is_hdr(ImageContainerFormat::Png),
    content="true",
  )

  debug_inspect(
    image_container_is_gpu_compressed(ImageContainerFormat::Dds),
    content="true",
  )
  debug_inspect(
    image_container_is_gpu_compressed(ImageContainerFormat::Ktx2),
    content="true",
  )
  debug_inspect(
    image_container_is_gpu_compressed(ImageContainerFormat::Basis),
    content="true",
  )
  debug_inspect(
    !image_container_is_gpu_compressed(ImageContainerFormat::Jpeg),
    content="true",
  )
}

///|
test "image wb: basis/dds/ktx2/hdr/exr helpers" {
  debug_inspect(image_is_basis_extension("basis"), content="true")
  debug_inspect(!image_is_basis_extension("ktx2"), content="true")
  debug_inspect(basis_requires_transcode(BasisContainer::Basis), content="true")
  debug_inspect(
    !basis_requires_transcode(BasisContainer::Ktx2Basis),
    content="true",
  )

  debug_inspect(image_is_dds_extension("dds"), content="true")
  debug_inspect(image_is_ktx2_extension("ktx2"), content="true")
  debug_inspect(image_is_hdr_extension("hdr"), content="true")
  debug_inspect(image_is_exr_extension("exr"), content="true")
}

///|
test "image wb: default texture format helpers" {
  debug_inspect(
    dds_default_texture_format() == TextureFormat::Rgba8Unorm,
    content="true",
  )
  debug_inspect(
    ktx2_default_texture_format() == TextureFormat::Rgba8Unorm,
    content="true",
  )
  debug_inspect(
    hdr_default_texture_format() == TextureFormat::Rgba16Float,
    content="true",
  )
  debug_inspect(
    exr_default_texture_format() == TextureFormat::Rgba16Float,
    content="true",
  )
}

///|
test "image wb: compressed saver quality clamp and format eligibility" {
  let options = CompressedImageSaveOptions::default()
    .with_quality(-3)
    .with_quality(180)
    .with_format_hint("png")

  debug_inspect(options.quality == 100, content="true")
  debug_inspect(options.format_hint == "png", content="true")

  debug_inspect(
    image_can_use_compressed_saver(TextureFormat::Rgba8Unorm),
    content="true",
  )
  debug_inspect(
    image_can_use_compressed_saver(TextureFormat::Rgba8UnormSrgb),
    content="true",
  )
  debug_inspect(
    !image_can_use_compressed_saver(TextureFormat::Rgba16Float),
    content="true",
  )
  debug_inspect(
    !image_can_use_compressed_saver(TextureFormat::Rg16Float),
    content="true",
  )
}

///|
test "image wb: image loader settings defaults" {
  let settings = ImageLoaderSettings::default()
  debug_inspect(
    settings.format == ImageFormatSetting::FromExtension,
    content="true",
  )
  debug_inspect(settings.texture_format == None, content="true")
  debug_inspect(settings.is_srgb, content="true")
  debug_inspect(
    match settings.sampler {
      ImageSampler::Default => true
      _ => false
    },
    content="true",
  )
  debug_inspect(
    match settings.array_layout {
      None => true
      _ => false
    },
    content="true",
  )
}

///|
test "image wb: extension extraction and lookup from path" {
  debug_inspect(
    image_extension_from_path("textures/FOX.KTX2") == Some("ktx2"),
    content="true",
  )
  debug_inspect(
    image_extension_from_path("textures/no_ext") == None,
    content="true",
  )
  debug_inspect(
    image_loader_container_from_path(
      "textures/fox.png",
      ImageFormatSetting::FromExtension,
    ) ==
    Some(ImageContainerFormat::Png),
    content="true",
  )
  debug_inspect(
    image_loader_container_from_path(
      "textures/fox.unknown",
      ImageFormatSetting::FromExtension,
    ) ==
    None,
    content="true",
  )
  debug_inspect(
    image_loader_container_from_path(
      "textures/fox.any",
      ImageFormatSetting::Format(ImageContainerFormat::Dds),
    ) ==
    Some(ImageContainerFormat::Dds),
    content="true",
  )
  debug_inspect(
    image_loader_container_from_path(
      "textures/fox.png",
      ImageFormatSetting::Guess,
    ) ==
    None,
    content="true",
  )
}

///|
test "image wb: array layout layer counting" {
  debug_inspect(
    image_array_layout_layers(1024, ImageArrayLayout::RowCount(4)) == Some(4),
    content="true",
  )
  debug_inspect(
    image_array_layout_layers(1024, ImageArrayLayout::RowHeight(256)) == Some(4),
    content="true",
  )
  debug_inspect(
    image_array_layout_layers(1024, ImageArrayLayout::RowHeight(300)) == None,
    content="true",
  )
  debug_inspect(
    image_array_layout_layers(0, ImageArrayLayout::RowCount(1)) == None,
    content="true",
  )
  debug_inspect(
    image_array_layout_layers(100, ImageArrayLayout::RowCount(0)) == None,
    content="true",
  )
}

///|
test "image wb: supported image formats and file extensions" {
  let formats = image_loader_supported_formats()
  debug_inspect(
    image_wb_has_format(formats, ImageContainerFormat::Png),
    content="true",
  )
  debug_inspect(
    image_wb_has_format(formats, ImageContainerFormat::Ktx2),
    content="true",
  )
  debug_inspect(
    image_wb_has_format(formats, ImageContainerFormat::Webp),
    content="true",
  )
  debug_inspect(
    image_wb_has_format(formats, ImageContainerFormat::Gif),
    content="true",
  )

  let extensions = image_loader_supported_file_extensions()
  debug_inspect(image_wb_has_extension(extensions, "png"), content="true")
  debug_inspect(image_wb_has_extension(extensions, "ktx2"), content="true")
  debug_inspect(image_wb_has_extension(extensions, "jpeg"), content="true")
  debug_inspect(image_wb_has_extension(extensions, "webp"), content="true")
}

///|
test "image wb: format guess from magic bytes" {
  debug_inspect(
    image_guess_container_from_bytes(
      image_wb_bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
    ) ==
    Some(ImageContainerFormat::Png),
    content="true",
  )
  debug_inspect(
    image_guess_container_from_bytes(image_wb_bytes([0xFF, 0xD8, 0xFF, 0xEE])) ==
    Some(ImageContainerFormat::Jpeg),
    content="true",
  )
  debug_inspect(
    image_guess_container_from_bytes(
      image_wb_bytes([
        0xAB, 0x4B, 0x54, 0x58, 0x20, 0x32, 0x30, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A,
      ]),
    ) ==
    Some(ImageContainerFormat::Ktx2),
    content="true",
  )
  debug_inspect(
    image_guess_container_from_bytes(
      image_wb_bytes([0x44, 0x44, 0x53, 0x20, 0x7C]),
    ) ==
    Some(ImageContainerFormat::Dds),
    content="true",
  )
  debug_inspect(
    image_guess_container_from_bytes(
      image_wb_bytes([
        0x52, 0x49, 0x46, 0x46, 0x01, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50,
      ]),
    ) ==
    Some(ImageContainerFormat::Webp),
    content="true",
  )
  debug_inspect(
    image_guess_container_from_bytes(image_wb_bytes([0x00, 0x00, 0x01, 0x00])) ==
    Some(ImageContainerFormat::Ico),
    content="true",
  )
  debug_inspect(
    image_guess_container_from_bytes(
      image_wb_bytes([0x66, 0x61, 0x72, 0x62, 0x66, 0x65, 0x6C, 0x64]),
    ) ==
    Some(ImageContainerFormat::Farbfeld),
    content="true",
  )
  debug_inspect(
    image_guess_container_from_bytes(image_wb_bytes([0x71, 0x6F, 0x69, 0x66])) ==
    Some(ImageContainerFormat::Qoi),
    content="true",
  )
  debug_inspect(
    image_guess_container_from_bytes(image_wb_bytes([0x49, 0x49, 0x2A, 0x00])) ==
    Some(ImageContainerFormat::Tiff),
    content="true",
  )
  debug_inspect(
    image_guess_container_from_bytes(image_wb_bytes([0x50, 0x36])) ==
    Some(ImageContainerFormat::Pnm),
    content="true",
  )
  debug_inspect(
    image_guess_container_from_bytes(image_wb_bytes([0x00, 0x01, 0x02])) == None,
    content="true",
  )
}

///|
test "image wb: format resolution from path + bytes + setting" {
  let png_magic = image_wb_bytes([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  ])
  debug_inspect(
    image_loader_container_from_input(
      "textures/no_extension",
      Some(png_magic),
      ImageFormatSetting::Guess,
    ) ==
    Some(ImageContainerFormat::Png),
    content="true",
  )
  debug_inspect(
    image_loader_container_from_input(
      "textures/no_extension",
      None,
      ImageFormatSetting::Guess,
    ) ==
    None,
    content="true",
  )
  debug_inspect(
    image_loader_container_from_input(
      "textures/fox.jpeg",
      None,
      ImageFormatSetting::FromExtension,
    ) ==
    Some(ImageContainerFormat::Jpeg),
    content="true",
  )
}

///|
test "image wb: image loader type exposes supported formats/extensions" {
  let loader = ImageLoader::new(7)
  debug_inspect(loader.supported_compressed_formats() == 7, content="true")
  debug_inspect(
    image_wb_has_format(loader.supported_formats(), ImageContainerFormat::Png),
    content="true",
  )
  debug_inspect(
    image_wb_has_extension(loader.extensions(), "jpeg"),
    content="true",
  )
  debug_inspect(
    image_wb_has_extension(loader.extensions(), "webp"),
    content="true",
  )
}

///|
test "image wb: image loader error message helpers" {
  let file_error = FileTextureError::{ error: "decode failed", path: "foo.png" }
  debug_inspect(
    file_texture_error_message(file_error) ==
    "Error reading image file foo.png: decode failed.",
    content="true",
  )
  debug_inspect(
    image_loader_error_message(ImageLoaderError::Io("eof")) ==
    "Failed to load image bytes: eof",
    content="true",
  )
  debug_inspect(
    image_loader_error_message(ImageLoaderError::FileTexture(file_error)) ==
    "Could not load texture file: Error reading image file foo.png: decode failed.",
    content="true",
  )
  debug_inspect(
    image_loader_error_message(ImageLoaderError::ArrayLayout("zero rows")) ==
    "Invalid array layout: zero rows",
    content="true",
  )
}
