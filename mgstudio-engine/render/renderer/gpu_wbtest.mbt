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
test "renderer: interleaved 2d mesh csv keeps original vertex count" {
  let backend = GpuBackend::new()
  backend.meshes.clear()
  let vertices = [
    -1.0F,
    -1.0F,
    0.0F,
    0.0F,
    1.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    -1.0F,
    1.0F,
    0.0F,
    0.0F,
    1.0F,
    0.0F,
    1.0F,
    0.0F,
    1.0F,
    0.5F,
    1.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
  ]
  let mesh_id = backend.create_mesh_triangles_xyuvrgba(vertices)
  let ok = mesh_id > 0 &&
    backend.meshes.length() == 1 &&
    backend.meshes[0].id == mesh_id &&
    backend.meshes[0].vertex_count.reinterpret_as_int() == 3 &&
    backend.meshes[0].vertex_stride_bytes == 32UL
  inspect(ok, content="true")
}

///|
test "renderer: mesh2d uniform slot pool grows per draw slot" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_mesh_pipeline_rgba8(backend)
  let ok = ensure_mesh_uniform_slot(backend, 0) is Some(_) &&
    ensure_mesh_uniform_slot(backend, 2) is Some(_) &&
    backend.mesh_uniform_slots.length() == 3
  inspect(ok, content="true")
}

///|
test "renderer: mesh3d uniform slot pool grows per draw slot" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_mesh3d_pipeline_rgba8(backend, MESH3D_TOPOLOGY_TRIANGLE_LIST, 0)
  let ok = ensure_mesh3d_uniform_slot(backend, 0) is Some(_) &&
    ensure_mesh3d_uniform_slot(backend, 1) is Some(_) &&
    backend.mesh3d_uniform_slots.length() == 2
  inspect(ok, content="true")
}

///|
test "renderer: large mesh3d upload switches to u32 index buffers" {
  let backend = GpuBackend::new()
  backend.meshes.clear()
  let vertices : Array[Float] = []
  for i in 0..<65538 {
    let x = Float::from_int(i % 3)
    let y = Float::from_int(i / 3 % 3)
    vertices.push(x)
    vertices.push(y)
    vertices.push(0.0F)
    vertices.push(0.0F)
    vertices.push(0.0F)
    vertices.push(1.0F)
    vertices.push(1.0F)
    vertices.push(1.0F)
    vertices.push(1.0F)
  }
  let mesh_id = backend.create_mesh3d_xyzuvrgba(vertices, 0)
  let ok = mesh_id > 0 &&
    backend.meshes.length() == 1 &&
    backend.meshes[0].id == mesh_id &&
    backend.meshes[0].vertex_count == 65538U &&
    backend.meshes[0].index_count == 65538U &&
    backend.meshes[0].index_stride_bytes == 4UL &&
    backend.meshes[0].uses_u32_indices
  inspect(ok, content="true")
}

///|
test "renderer: present mode fallbacks align with bevy auto-vsync policy" {
  let candidates = surface_present_mode_candidates(
    SURFACE_PRESENT_MODE_AUTO_VSYNC,
  )
  let ok = candidates.length() == 2 &&
    candidates[0] == @wgpu.PRESENT_MODE_FIFO_RELAXED &&
    candidates[1] == @wgpu.PRESENT_MODE_FIFO
  inspect(ok, content="true")
}

///|
test "renderer: present mode fallbacks align with bevy auto-no-vsync policy" {
  let candidates = surface_present_mode_candidates(
    SURFACE_PRESENT_MODE_AUTO_NO_VSYNC,
  )
  let ok = candidates.length() == 3 &&
    candidates[0] == @wgpu.PRESENT_MODE_IMMEDIATE &&
    candidates[1] == @wgpu.PRESENT_MODE_MAILBOX &&
    candidates[2] == @wgpu.PRESENT_MODE_FIFO
  inspect(ok, content="true")
}

///|
test "renderer: present mode mailbox fallback keeps bevy ordering" {
  let candidates = surface_present_mode_candidates(SURFACE_PRESENT_MODE_MAILBOX)
  let ok = candidates.length() == 3 &&
    candidates[0] == @wgpu.PRESENT_MODE_MAILBOX &&
    candidates[1] == @wgpu.PRESENT_MODE_IMMEDIATE &&
    candidates[2] == @wgpu.PRESENT_MODE_FIFO
  inspect(ok, content="true")
}

///|
test "renderer: composite alpha mode mapping matches wgpu native constants" {
  let ok = surface_alpha_mode_resolve(SURFACE_COMPOSITE_ALPHA_MODE_AUTO) ==
    @wgpu.COMPOSITE_ALPHA_MODE_AUTO &&
    surface_alpha_mode_resolve(SURFACE_COMPOSITE_ALPHA_MODE_OPAQUE) ==
    @wgpu.COMPOSITE_ALPHA_MODE_OPAQUE &&
    surface_alpha_mode_resolve(SURFACE_COMPOSITE_ALPHA_MODE_PRE_MULTIPLIED) ==
    @wgpu.COMPOSITE_ALPHA_MODE_PREMULTIPLIED &&
    surface_alpha_mode_resolve(SURFACE_COMPOSITE_ALPHA_MODE_POST_MULTIPLIED) ==
    @wgpu.COMPOSITE_ALPHA_MODE_UNPREMULTIPLIED &&
    surface_alpha_mode_resolve(SURFACE_COMPOSITE_ALPHA_MODE_INHERIT) ==
    @wgpu.COMPOSITE_ALPHA_MODE_INHERIT
  inspect(ok, content="true")
}

///|
test "renderer: grouped wgsl imports resolve Bevy module files" {
  let assets_base = "assets"
  let modules = build_wgsl_import_module_paths(assets_base)
  let targets : Array[WgslImportTarget] = []
  collect_wgsl_import_targets(
    "bevy_render::{\n  color_operations::{hsv_to_rgb, rgb_to_hsv},\n  maths::{PI_2, powsafe},\n}",
    "", targets,
  )
  inspect(targets.length(), content="4")
  inspect(
    resolve_wgsl_import_module_path_for_test(
      assets_base,
      targets[0].raw_path,
      modules,
    ),
    content="bevy_render::color_operations",
  )
  inspect(
    resolve_wgsl_import_module_path_for_test(
      assets_base,
      targets[1].raw_path,
      modules,
    ),
    content="bevy_render::color_operations",
  )
  inspect(
    resolve_wgsl_import_module_path_for_test(
      assets_base,
      targets[2].raw_path,
      modules,
    ),
    content="bevy_render::maths",
  )
  inspect(
    resolve_wgsl_import_module_path_for_test(
      assets_base,
      targets[3].raw_path,
      modules,
    ),
    content="bevy_render::maths",
  )
}

///|
test "renderer: preprocess_wgsl_source supports multiline grouped imports" {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths("assets")
  let preprocessed = preprocess_wgsl_source(
    "assets", "#import bevy_render::{\n  color_operations::{hsv_to_rgb, rgb_to_hsv},\n  maths::{PI_2, powsafe},\n}\nfn demo(color: vec3<f32>) -> vec3<f32> {\n  let h = rgb_to_hsv(color);\n  return hsv_to_rgb(vec3<f32>(h.x + PI_2, h.y, powsafe(h.z, 1.0)));\n}\n",
    defines, value_defines, visited, modules,
  )
  inspect(preprocessed.contains("fn rgb_to_hsv"), content="true")
  inspect(preprocessed.contains("fn hsv_to_rgb"), content="true")
  inspect(preprocessed.contains("const PI_2"), content="true")
  inspect(preprocessed.contains("bevy_render::"), content="false")
}

///|
test "renderer: preprocess_wgsl_source strips module aliases" {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths("assets")
  let preprocessed = preprocess_wgsl_source(
    "assets", "#import bevy_render::maths as maths\nfn demo() -> f32 {\n  return maths::PI_2;\n}\n",
    defines, value_defines, visited, modules,
  )
  inspect(preprocessed.contains("return PI_2;"), content="true")
  inspect(preprocessed.contains("maths::PI_2"), content="false")
}

///|
fn resolve_wgsl_import_module_path_for_test(
  assets_base : String,
  import_path : String,
  modules : @hashmap.HashMap[String, String],
) -> String {
  guard resolve_wgsl_import_module(assets_base, import_path, modules)
    is Some(resolved_module) else {
    return ""
  }
  resolved_module.module_path
}

///|
fn gpu_test_pass_state(target_id : Int) -> GpuPassState {
  GpuPassState::{
    target_id,
    target_layer: -1,
    width_logical: 128.0F,
    height_logical: 128.0F,
    is_3d: false,
    camera_x: 0.0F,
    camera_y: 0.0F,
    camera_rot: 0.0F,
    camera_scale: 1.0F,
    camera_z: 0.0F,
    camera_exposure: 1.0F,
    camera_rot_x: 0.0F,
    camera_rot_y: 0.0F,
    camera_rot_z: 0.0F,
    camera_rot_w: 1.0F,
    clip_from_world: GpuClipMatrix::{
      x_axis_x: 1.0F,
      x_axis_y: 0.0F,
      x_axis_z: 0.0F,
      x_axis_w: 0.0F,
      y_axis_x: 0.0F,
      y_axis_y: 1.0F,
      y_axis_z: 0.0F,
      y_axis_w: 0.0F,
      z_axis_x: 0.0F,
      z_axis_y: 0.0F,
      z_axis_z: 1.0F,
      z_axis_w: 0.0F,
      w_axis_x: 0.0F,
      w_axis_y: 0.0F,
      w_axis_z: 0.0F,
      w_axis_w: 1.0F,
    },
    unjittered_clip_from_world: GpuClipMatrix::{
      x_axis_x: 1.0F,
      x_axis_y: 0.0F,
      x_axis_z: 0.0F,
      x_axis_w: 0.0F,
      y_axis_x: 0.0F,
      y_axis_y: 1.0F,
      y_axis_z: 0.0F,
      y_axis_w: 0.0F,
      z_axis_x: 0.0F,
      z_axis_y: 0.0F,
      z_axis_z: 1.0F,
      z_axis_w: 0.0F,
      w_axis_x: 0.0F,
      w_axis_y: 0.0F,
      w_axis_z: 0.0F,
      w_axis_w: 1.0F,
    },
    previous_clip_from_world: GpuClipMatrix::{
      x_axis_x: 1.0F,
      x_axis_y: 0.0F,
      x_axis_z: 0.0F,
      x_axis_w: 0.0F,
      y_axis_x: 0.0F,
      y_axis_y: 1.0F,
      y_axis_z: 0.0F,
      y_axis_w: 0.0F,
      z_axis_x: 0.0F,
      z_axis_y: 0.0F,
      z_axis_z: 1.0F,
      z_axis_w: 0.0F,
      w_axis_x: 0.0F,
      w_axis_y: 0.0F,
      w_axis_z: 0.0F,
      w_axis_w: 1.0F,
    },
    pass_kind: 0,
    viewport_x: 0U,
    viewport_y: 0U,
    viewport_w: 128U,
    viewport_h: 128U,
    viewport_depth_min: 0.0F,
    viewport_depth_max: 1.0F,
    ambient_r: 0.0F,
    ambient_g: 0.0F,
    ambient_b: 0.0F,
    ambient_brightness: 0.0F,
    directional_dir_x: 0.0F,
    directional_dir_y: 0.0F,
    directional_dir_z: 0.0F,
    directional_color_r: 0.0F,
    directional_color_g: 0.0F,
    directional_color_b: 0.0F,
    directional_illuminance: 0.0F,
    point_pos_x: 0.0F,
    point_pos_y: 0.0F,
    point_pos_z: 0.0F,
    point_color_r: 0.0F,
    point_color_g: 0.0F,
    point_color_b: 0.0F,
    point_intensity: 0.0F,
    point_range: 0.0F,
    spot_pos_x: 0.0F,
    spot_pos_y: 0.0F,
    spot_pos_z: 0.0F,
    spot_dir_x: 0.0F,
    spot_dir_y: 0.0F,
    spot_dir_z: 0.0F,
    spot_color_r: 0.0F,
    spot_color_g: 0.0F,
    spot_color_b: 0.0F,
    spot_intensity: 0.0F,
    spot_range: 0.0F,
    spot_inner_angle: 0.0F,
    spot_outer_angle: 0.0F,
    point_shadow_near: 0.1F,
  }
}

///|
test "renderer: sprite pipeline specializes to hdr render target format" {
  let backend = GpuBackend::new(assets_base="assets")
  let target_id = backend.create_render_target_rgba16f(128, 128, false)
  backend.pass_state = Some(gpu_test_pass_state(target_id))
  sprite_pipeline_for_current_pass(backend) |> ignore
  let ok = match backend.sprite_pipeline_surface_format {
    Some(format) => format == tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
    None => false
  }
  inspect(ok, content="true")
}

///|
test "renderer: mesh pipeline specializes to hdr render target format" {
  let backend = GpuBackend::new(assets_base="assets")
  let target_id = backend.create_render_target_rgba16f(128, 128, false)
  backend.pass_state = Some(gpu_test_pass_state(target_id))
  mesh_pipeline_for_current_pass(backend) |> ignore
  let ok = match backend.mesh_pipeline_surface_format {
    Some(format) => format == tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
    None => false
  }
  inspect(ok, content="true")
}

///|
test "renderer: bloom2d final composite uses hdr scene target format even from rgba8 final pass" {
  let backend = GpuBackend::new(assets_base="assets")
  let final_target_id = backend.create_render_target_with_format(
    128,
    128,
    false,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
  let scene_texture_id = backend.create_render_target_rgba16f(128, 128, false)
  backend.pass_state = Some(gpu_test_pass_state(final_target_id))
  bloom2d_final_composite_pipeline_for_scene_texture(
    backend, scene_texture_id, 0,
  )
  |> ignore
  let ok = match backend.bloom2d_upsample_final_pipeline_format {
    Some(format) => format == tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
    None => false
  }
  inspect(ok, content="true")
}

///|
test "renderer: tonemapping2d final pipeline specializes to current final target without bloom composite" {
  let backend = GpuBackend::new(assets_base="assets")
  let target_id = backend.create_render_target_with_format(
    128,
    128,
    false,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
  backend.pass_state = Some(gpu_test_pass_state(target_id))
  bloom2d_pipeline_for_current_pass(backend) |> ignore
  let ok = match backend.bloom2d_final_pipeline {
    Some(_) => backend.bloom2d_upsample_final_pipeline_format is None
    None => false
  }
  inspect(ok, content="true")
}

///|
test "renderer: sampler cache key includes compare anisotropy and lod" {
  let key0 = image_sampler_cache_key(
    IMAGE_SAMPLER_ADDRESS_MODE_REPEAT,
    IMAGE_SAMPLER_ADDRESS_MODE_REPEAT,
    IMAGE_SAMPLER_ADDRESS_MODE_REPEAT,
    IMAGE_SAMPLER_FILTER_MODE_LINEAR,
    IMAGE_SAMPLER_FILTER_MODE_LINEAR,
    IMAGE_SAMPLER_FILTER_MODE_LINEAR,
    0.0F,
    32.0F,
    IMAGE_SAMPLER_COMPARE_UNDEFINED,
    1,
    IMAGE_SAMPLER_BORDER_COLOR_UNDEFINED,
  )
  let key1 = image_sampler_cache_key(
    IMAGE_SAMPLER_ADDRESS_MODE_REPEAT,
    IMAGE_SAMPLER_ADDRESS_MODE_REPEAT,
    IMAGE_SAMPLER_ADDRESS_MODE_REPEAT,
    IMAGE_SAMPLER_FILTER_MODE_LINEAR,
    IMAGE_SAMPLER_FILTER_MODE_LINEAR,
    IMAGE_SAMPLER_FILTER_MODE_LINEAR,
    0.0F,
    32.0F,
    IMAGE_SAMPLER_COMPARE_ALWAYS,
    4,
    IMAGE_SAMPLER_BORDER_COLOR_UNDEFINED,
  )
  inspect(key0 == key1, content="false")
}

///|
test "renderer: unsupported border color validation raises exact blocker" {
  let result = try {
    image_sampler_border_color_validate(IMAGE_SAMPLER_BORDER_COLOR_OPAQUE_WHITE)
    "ok"
  } catch {
    err =>
      match err {
        Fatal(message) => message
      }
  }
  inspect(result.contains("ImageSamplerBorderColor is blocked"), content="true")
}

///|
test "renderer: screenshot capture swizzles bgra8 into rgba8" {
  let pixels = Bytes::from_array([
    (3).to_byte(),
    (2).to_byte(),
    (1).to_byte(),
    (255).to_byte(),
  ])
  let converted = screenshot_capture_pixels_rgba8(
    @wgpu.TEXTURE_FORMAT_BGRA8_UNORM,
    1,
    1,
    pixels,
  )
  inspect(
    converted.map(fn(value) {
      [
        value[0].to_uint(),
        value[1].to_uint(),
        value[2].to_uint(),
        value[3].to_uint(),
      ]
    }),
    content="Some([1, 2, 3, 255])",
  )
}

///|
test "renderer: screenshot capture reads rgba8 texture bytes" {
  let backend = GpuBackend::new()
  let previous_backend = backend_ref.val
  backend_ref.val = Some(backend)
  let texture_id = backend.create_texture_rgba8(
    1,
    1,
    Bytes::from_array([
      (9).to_byte(),
      (8).to_byte(),
      (7).to_byte(),
      (255).to_byte(),
    ]),
    true,
  )
  let capture = screenshot_capture_texture_sync(texture_id~)
  inspect(capture is Some(_), content="true")
  inspect(capture.map(fn(value) { value.width }), content="Some(1)")
  inspect(capture.map(fn(value) { value.height }), content="Some(1)")
  inspect(
    capture.map(fn(value) {
      [
        value.pixels[0].to_uint(),
        value.pixels[1].to_uint(),
        value.pixels[2].to_uint(),
        value.pixels[3].to_uint(),
      ]
    }),
    content="Some([9, 8, 7, 255])",
  )
  backend_ref.val = previous_backend
}

///|
test "renderer: sprite uv axis metrics preserves flipped spans" {
  let (signed_scale, region_extent) = sprite_uv_axis_metrics(1.0F, 0.0F, 128)
  let ok = signed_scale == -1.0F && region_extent == 128.0F
  inspect(ok, content="true")
}

///|
test "renderer: sprite uv axis metrics keeps zero span safe" {
  let (signed_scale, region_extent) = sprite_uv_axis_metrics(0.5F, 0.5F, 128)
  let ok = signed_scale == 1.0F && region_extent == 128.0F
  inspect(ok, content="true")
}
