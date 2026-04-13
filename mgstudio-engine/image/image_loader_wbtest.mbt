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
