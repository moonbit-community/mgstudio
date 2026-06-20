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

///|
test "render view: shadow LOD origin defaults to zero" {
  let origin = RenderShadowLodOrigin::RenderShadowLodOrigin()
  inspect(origin.is_default(), content="true")
  let custom = RenderShadowLodOrigin::new(@math.Vec3::new(1.0F, 2.0F, 3.0F))
  inspect(custom.is_default(), content="false")
}

///|
test "render view: view uniform bytes follow WGSL shader layout size" {
  let bytes = ViewUniform::ViewUniform().bytes()
  inspect(bytes.length(), content="784")
  inspect(VIEW_UNIFORM_SIZE_BYTES, content="784")
  inspect(COLOR_GRADING_UNIFORM_SIZE_BYTES, content="160")
}

///|
test "render view: default view uniform preserves Bevy color grading defaults" {
  let bytes = ViewUniform::ViewUniform().bytes()
  let post_saturation_offset = 448 + 16 + 16 + 16 + 96 + 16 + 48 + 80 + 16
  inspect(bytes[post_saturation_offset].to_int() & 0xFF, content="0")
  inspect(bytes[post_saturation_offset + 1].to_int() & 0xFF, content="0")
  inspect(bytes[post_saturation_offset + 2].to_int() & 0xFF, content="128")
  inspect(bytes[post_saturation_offset + 3].to_int() & 0xFF, content="63")
}

///|
test "render view: ViewUniforms offsets advance by shader layout size" {
  let uniforms = ViewUniforms::ViewUniforms()
  inspect(uniforms.len(), content="0")
  inspect(uniforms.push(ViewUniform::ViewUniform()), content="0")
  inspect(uniforms.push(ViewUniform::ViewUniform()), content="784")
  inspect(uniforms.len(), content="2")
  let offset = ViewUniformOffset::new(784U)
  inspect(offset.offset(), content="784")
}

///|
test "render view: ViewUniforms writes real GPU buffer binding" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let queue = device.queue()
  let uniforms = ViewUniforms::ViewUniforms()
  uniforms.write_buffer(device, queue)
  inspect(uniforms.binding() is None, content="true")
  ignore(uniforms.push(ViewUniform::ViewUniform()))
  uniforms.write_buffer(device, queue)
  inspect(uniforms.binding() is Some(_), content="true")
  inspect(
    uniforms.gpu_capacity() >= VIEW_UNIFORM_SIZE_BYTES.to_uint64(),
    content="true",
  )
  device.release()
  adapter.release()
  instance.release()
}
