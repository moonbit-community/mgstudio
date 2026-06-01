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
fn sampler_tag(sampler : @image.ImageSampler) -> Int {
  match sampler {
    @image.ImageSampler::Default => 0
    @image.ImageSampler::Descriptor(descriptor) =>
      if descriptor.min_filter == @image.ImageFilterMode::Nearest {
        1
      } else {
        2
      }
  }
}

///|
test "image boundary re-exports sampler constructors" {
  debug_inspect(sampler_tag(@image.ImageSampler::default()), content="0")
  debug_inspect(sampler_tag(@image.ImageSampler::nearest()), content="1")
  debug_inspect(sampler_tag(@image.ImageSampler::linear()), content="2")
}

///|
test "image texture formats follow current wgpu constants" {
  debug_inspect(
    @image.texture_format(@image.TextureFormat::Rgba8Unorm).to_u32() ==
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    content="true",
  )
  debug_inspect(
    @image.texture_format(@image.TextureFormat::Rgba8UnormSrgb).to_u32() ==
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB,
    content="true",
  )
  debug_inspect(
    @image.texture_format(@image.TextureFormat::Rgba16Uint).to_u32() ==
    @wgpu.TEXTURE_FORMAT_RGBA16_UINT,
    content="true",
  )
  debug_inspect(
    @image.texture_format(@image.TextureFormat::Rgba16Float).to_u32() ==
    @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
    content="true",
  )
  debug_inspect(
    @image.texture_format(@image.TextureFormat::Rg16Float).to_u32() ==
    @wgpu.TEXTURE_FORMAT_RG16_FLOAT,
    content="true",
  )
}
