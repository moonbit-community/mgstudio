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
test "render view: window BGRA8 SRGB target format normalizes like Bevy" {
  inspect(
    normalize_bgra8_for_render_target(
      target_is_window=true,
      @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB,
    ) ==
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB,
    content="true",
  )
  inspect(
    normalize_bgra8_for_render_target(
      target_is_window=true,
      @wgpu.TEXTURE_FORMAT_BGRA8_UNORM,
    ) ==
    @wgpu.TEXTURE_FORMAT_BGRA8_UNORM,
    content="true",
  )
  inspect(
    normalize_bgra8_for_render_target(
      target_is_window=false,
      @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB,
    ) ==
    @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB,
    content="true",
  )
}

///|
test "render view: extracted target format follows Bevy HDR and compositing rules" {
  inspect(
    extracted_view_target_format_raw(
      output_texture_format_raw=@wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB,
      hdr=true,
      compositing_space=Some(@camera_compositing_space.CompositingSpace::Srgb),
    ) ==
    @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
    content="true",
  )
  inspect(
    extracted_view_target_format_raw(
      output_texture_format_raw=@wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB,
      compositing_space=Some(@camera_compositing_space.CompositingSpace::Srgb),
    ) ==
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    content="true",
  )
  inspect(
    extracted_view_target_format_raw(
      output_texture_format_raw=@wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB,
      compositing_space=Some(@camera_compositing_space.CompositingSpace::Oklab),
    ) ==
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB,
    content="true",
  )
}
