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
    backend.meshes[0].vertex_stride_bytes == MESH2D_VERTEX_STRIDE_BYTES
  inspect(ok, content="true")
}

///|
test "renderer: mesh2d resources initialize expected bind groups" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_mesh2d_resources(backend)
  let ok = backend.mesh2d_view_bg is Some(_) &&
    backend.mesh2d_instance_bg is Some(_) &&
    backend.mesh2d_material_bgl is Some(_) &&
    backend.mesh2d_instance_capacity >= MESH2D_UNIFORM_DYNAMIC_STRIDE_BYTES
  inspect(ok, content="true")
}

///|
test "renderer: mesh2d dynamic uniform pool grows by required capacity" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_mesh2d_resources(backend)
  let grow_required = backend.mesh2d_instance_capacity +
    MESH2D_UNIFORM_DYNAMIC_STRIDE_BYTES
  let ok = ensure_mesh2d_instance_uniform_binding(
      backend,
      MESH2D_UNIFORM_DYNAMIC_STRIDE_BYTES,
    )
    is Some(_) &&
    ensure_mesh2d_instance_uniform_binding(backend, grow_required) is Some(_) &&
    backend.mesh2d_instance_capacity >= grow_required
  inspect(ok, content="true")
}

///|
test "renderer: mesh2d color material uniform bytes match Bevy size" {
  let bytes = mesh2d_color_material_uniform_bytes(
    1.0F,
    0.5F,
    0.25F,
    0.75F,
    9,
    0.1F,
    0.2F,
    2.0F,
    3.0F,
    MESH2D_ALPHA_MODE_KIND_MASK,
    0.33F,
  )
  inspect(bytes.length(), content="80")
}

///|
test "renderer: mesh3d uniform slot pool grows per draw slot" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_mesh3d_pipeline_rgba8(backend, MESH3D_TOPOLOGY_TRIANGLE_LIST, 0)
  let ok = ensure_mesh3d_uniform_slot(backend, 0) is Some(_) &&
    ensure_mesh3d_uniform_slot(backend, 1) is Some(_) &&
    backend.mesh3d_bgl_view is Some(_) &&
    backend.mesh3d_view_buf is Some(_) &&
    backend.mesh3d_uniform_slots.length() == 2
  inspect(ok, content="true")
}

///|
test "renderer: motion vector resources initialize prepass-style bind groups" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_mesh3d_motion_vector_pipeline(backend)
  let ok = backend.mesh3d_motion_vector_bgl_view is Some(_) &&
    backend.mesh3d_motion_vector_bgl_empty is Some(_) &&
    backend.mesh3d_motion_vector_bgl_mesh is Some(_) &&
    backend.mesh3d_motion_vector_view_buf is Some(_) &&
    backend.mesh3d_motion_vector_globals_buf is Some(_) &&
    backend.mesh3d_motion_vector_previous_view_buf is Some(_) &&
    backend.mesh3d_motion_vector_visibility_ranges_buf is Some(_) &&
    backend.mesh3d_motion_vector_view_bg is Some(_) &&
    backend.mesh3d_motion_vector_mesh_buf is Some(_) &&
    backend.mesh3d_motion_vector_mesh_bg is Some(_)
  inspect(ok, content="true")
}

///|
test "renderer: motion vector prepass buffers match bevy struct sizes" {
  let pass_state = GpuPassState::{
    target_id: -1,
    target_layer: -1,
    secondary_target_id: -1,
    width_logical: 128.0F,
    height_logical: 128.0F,
    is_3d: true,
    camera_x: 1.0F,
    camera_y: 2.0F,
    camera_rot: 0.0F,
    camera_scale: 1.0F,
    camera_z: 3.0F,
    camera_exposure: 1.0F,
    camera_rot_x: 0.0F,
    camera_rot_y: 0.0F,
    camera_rot_z: 0.0F,
    camera_rot_w: 1.0F,
    clip_from_world: gpu_clip_matrix_identity(),
    unjittered_clip_from_world: gpu_clip_matrix_identity(),
    previous_clip_from_world: gpu_clip_matrix_identity(),
    pass_kind: PASS_KIND_BASE_MOTION_VECTOR,
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
    directional_dir_z: -1.0F,
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
    spot_dir_z: -1.0F,
    spot_color_r: 0.0F,
    spot_color_g: 0.0F,
    spot_color_b: 0.0F,
    spot_intensity: 0.0F,
    spot_range: 0.0F,
    spot_inner_angle: 0.0F,
    spot_outer_angle: 0.0F,
    point_shadow_near: 0.0F,
  }
  let mesh_bytes = mesh3d_motion_vector_mesh_uniform_bytes(
    0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 1.0F, 1.0F, 1.0F, 0.0F, 0.0F, 0.0F,
    0.0F, 0.0F, 0.0F, 1.0F, 1.0F, 1.0F, 1.0F,
  )
  inspect(
    mesh3d_motion_vector_view_uniform_bytes(pass_state).length(),
    content="1024",
  )
  inspect(
    mesh3d_motion_vector_previous_view_uniform_bytes(pass_state).length(),
    content="320",
  )
  inspect(mesh_bytes.length(), content="176")
}

///|
test "renderer: motion vector shader reads canonical Bevy prepass bindings" {
  let wgsl = load_wgsl_required_mesh3d_motion_vector_prepass("assets")
  inspect(
    wgsl.contains("@group(0) @binding(0) var<uniform> view: View;"),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(0) @binding(2) var<uniform> previous_view_uniforms: PreviousViewUniforms;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(0) @binding(14) var<storage> visibility_ranges: array<vec4<f32>>;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains("@group(2) @binding(0) var<uniform> mesh: array<Mesh, 1u>;"),
    content="true",
  )
  inspect(wgsl.contains("fn vertex(vertex_no_morph: Vertex)"), content="true")
  inspect(wgsl.contains("fn fragment(in: VertexOutput)"), content="true")
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
    vertices.push(0.0F)
    vertices.push(0.0F)
    vertices.push(1.0F)
    vertices.push(1.0F)
    vertices.push(1.0F)
    vertices.push(1.0F)
  }
  let mesh_id = backend.create_mesh3d_xyznuvrgba(vertices, 0)
  let ok = mesh_id > 0 &&
    backend.meshes.length() == 1 &&
    backend.meshes[0].id == mesh_id &&
    backend.meshes[0].vertex_count == 65538U &&
    backend.meshes[0].index_count == 65538U &&
    backend.meshes[0].vertex_stride_bytes == MESH3D_VERTEX_STRIDE_BYTES &&
    backend.meshes[0].index_stride_bytes == 4UL &&
    backend.meshes[0].uses_u32_indices
  inspect(ok, content="true")
}

///|
test "renderer: custom mesh3d forward shader consumes normal-aware vertex layout" {
  let wgsl = load_wgsl_from_assets_base_required(
    "assets", "shaders/custom/mesh3d_forward.wgsl",
  )
  inspect(wgsl.contains("struct Mesh3dViewUniform {"), content="true")
  inspect(wgsl.contains("struct Mesh3dLightsUniform {"), content="true")
  inspect(wgsl.contains("struct Mesh3dViewBindings {"), content="true")
  inspect(wgsl.contains("struct Mesh3dTransformUniform {"), content="true")
  inspect(wgsl.contains("struct Mesh3dMaterialUniform {"), content="true")
  inspect(
    wgsl.contains(
      "@group(0) @binding(0) var<uniform> u_view : Mesh3dViewBindings;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(0) @binding(1) var u_transmission_source_texture : texture_2d<f32>;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(2) @binding(0) var<uniform> u_draw : Mesh3dDrawUniform;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(1) @binding(1) var u_base_color_texture : texture_2d<f32>;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains("@group(1) @binding(2) var u_base_color_sampler : sampler;"),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(1) @binding(9) var u_normal_map_texture : texture_2d<f32>;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains("@group(1) @binding(10) var u_normal_map_sampler : sampler;"),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(1) @binding(29) var u_specular_tint_texture : texture_2d<f32>;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(1) @binding(30) var u_specular_tint_sampler : sampler;",
    ),
    content="true",
  )
  inspect(wgsl.contains("uv_transform : mat3x3<f32>,"), content="true")
  inspect(wgsl.contains("reflectance : vec3<f32>,"), content="true")
  inspect(wgsl.contains("flags : u32,"), content="true")
  inspect(wgsl.contains("uv_transform_mode : f32,"), content="true")
  inspect(wgsl.contains("world_position : vec4<f32>,"), content="true")
  inspect(wgsl.contains("ambient_color : vec4<f32>,"), content="true")
  inspect(
    wgsl.contains("directional_light_direction_to_light : vec4<f32>,"),
    content="true",
  )
  inspect(
    wgsl.contains("point_light_shadow_params : vec4<f32>,"),
    content="true",
  )
  inspect(wgsl.contains("spot_light_custom_data : vec4<f32>,"), content="true")
  inspect(
    wgsl.contains("STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT"),
    content="true",
  )
  inspect(
    wgsl.contains("STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MASK"),
    content="true",
  )
  inspect(
    wgsl.contains("STANDARD_MATERIAL_FLAGS_TWO_COMPONENT_NORMAL_MAP"),
    content="true",
  )
  inspect(
    wgsl.contains("STANDARD_MATERIAL_FLAGS_FLIP_NORMAL_MAP_Y"),
    content="true",
  )
  inspect(wgsl.contains("material_flag_enabled("), content="true")
  inspect(wgsl.contains("apply_normal_mapping("), content="true")
  inspect(wgsl.contains("discard;"), content="true")
  inspect(!wgsl.contains("has_normal_map ="), content="true")
  inspect(!wgsl.contains("emissive_params"), content="true")
  inspect(!wgsl.contains("material_params"), content="true")
  inspect(!wgsl.contains("parallax_params"), content="true")
  inspect(!wgsl.contains("anisotropy_params"), content="true")
  inspect(!wgsl.contains("transmission_params"), content="true")
  inspect(wgsl.contains("@location(1) normal : vec3<f32>"), content="true")
  inspect(wgsl.contains("@location(2) uv : vec2<f32>"), content="true")
  inspect(wgsl.contains("@location(3) color : vec4<f32>"), content="true")
  inspect(
    wgsl.contains("@location(3) world_normal : vec3<f32>"),
    content="true",
  )
}

///|
test "renderer: mesh3d normal map fallback texture is flat normal blue" {
  let backend = GpuBackend::new()
  let previous_backend = backend_ref.val
  backend_ref.val = Some(backend)
  let fallback_texture = ensure_normal_map_fallback_texture(backend)
  inspect(
    fallback_texture.format_raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    content="true",
  )
  let capture = screenshot_capture_texture_sync(texture_id=fallback_texture.id)
  inspect(capture is Some(_), content="true")
  inspect(
    capture.map(fn(value) {
      [
        value.pixels[0].to_uint(),
        value.pixels[1].to_uint(),
        value.pixels[2].to_uint(),
        value.pixels[3].to_uint(),
      ]
    }),
    content="Some([128, 128, 255, 255])",
  )
  backend_ref.val = previous_backend
}

///|
test "renderer: mesh3d runtime flags infer two-component normal map format" {
  let backend = GpuBackend::new()
  let fallback_texture = ensure_normal_map_fallback_texture(backend)
  let two_component_texture = GpuTextureInfo::{
    ..fallback_texture,
    id: 42,
    format_raw: @wgpu.TEXTURE_FORMAT_RG8_UNORM,
  }
  let flags = mesh3d_runtime_material_flags(0U, 42, two_component_texture)
  inspect((flags & (1U << 6)) != 0U, content="true")
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
  let targets : Array[@naga_oil.WgslImportTarget] = []
  @naga_oil.collect_wgsl_import_targets(
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
test "renderer: canonical prepass import preprocessing keeps motion-vector bindings narrow" {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  defines.set("PREPASS_FRAGMENT", true)
  defines.set("MOTION_VECTOR_PREPASS", true)
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths("assets")
  let preprocessed = load_wgsl_preprocessed(
    "assets", "shaders/bevy_pbr/prepass/prepass.wgsl", defines, value_defines, visited,
    modules,
  )
  inspect(
    preprocessed.contains("@group(0) @binding(0) var<uniform> view: View;"),
    content="true",
  )
  inspect(
    preprocessed.contains(
      "@group(0) @binding(2) var<uniform> previous_view_uniforms: PreviousViewUniforms;",
    ),
    content="true",
  )
  inspect(preprocessed.contains("point_shadow_textures"), content="false")
  inspect(preprocessed.contains("environment_map_sampler"), content="false")
}

///|
test "renderer: view item imports keep dependent ColorGrading declarations" {
  register_renderer_test_shaders()
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let value_defines = default_wgsl_value_defines()
  let modules = copy_registered_wgsl_import_module_paths()

  let sprite_visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let sprite_preprocessed = load_wgsl_preprocessed(
    "", "shaders/bevy_sprite_render/render/sprite_view_bindings.wgsl", defines, value_defines,
    sprite_visited, modules,
  )
  inspect(sprite_preprocessed.contains("struct ColorGrading"), content="true")
  inspect(sprite_preprocessed.contains("struct View"), content="true")
  inspect(
    sprite_preprocessed.contains(
      "@group(0) @binding(0) var<uniform> view: View;",
    ),
    content="true",
  )

  let mesh2d_visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let mesh2d_preprocessed = load_wgsl_preprocessed(
    "", "shaders/bevy_sprite_render/mesh2d/mesh2d_view_bindings.wgsl", defines, value_defines,
    mesh2d_visited, modules,
  )
  inspect(mesh2d_preprocessed.contains("struct ColorGrading"), content="true")
  inspect(mesh2d_preprocessed.contains("struct View"), content="true")
  inspect(
    mesh2d_preprocessed.contains(
      "@group(0) @binding(0) var<uniform> view: View;",
    ),
    content="true",
  )
  clear_registered_wgsl_source_registry()
}

///|
test "renderer: registered wgsl sources satisfy strict mesh2d preprocessing" {
  clear_registered_wgsl_source_registry()
  register_wgsl_source(
    "shaders/bevy_render/maths.wgsl", "#define_import_path bevy_render::maths\nconst PI_2: f32 = 6.28318;\n",
  )
  register_wgsl_source(
    "shaders/bevy_sprite_render/mesh2d/mesh2d_functions.wgsl", "#define_import_path bevy_sprite::mesh2d_functions\n#import bevy_render::maths::PI_2\nfn twice_pi() -> f32 {\n  return PI_2;\n}\n",
  )
  register_wgsl_source(
    "shaders/bevy_sprite_render/mesh2d/mesh2d.wgsl", "#import bevy_sprite::mesh2d_functions as mesh_functions\nfn demo() -> f32 {\n  return mesh_functions::twice_pi();\n}\n",
  )
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = copy_registered_wgsl_import_module_paths()
  let preprocessed = load_wgsl_preprocessed(
    "", "shaders/bevy_sprite_render/mesh2d/mesh2d.wgsl", defines, value_defines,
    visited, modules,
  )
  inspect(preprocessed.contains("const PI_2"), content="true")
  inspect(preprocessed.contains("return twice_pi();"), content="true")
  inspect(preprocessed.contains("mesh_functions::"), content="false")
  clear_registered_wgsl_source_registry()
}

///|
fn resolve_wgsl_import_module_path_for_test(
  assets_base : String,
  import_path : String,
  modules : @hashmap.HashMap[String, String],
) -> String {
  guard @naga_oil.resolve_wgsl_import_module(assets_base, import_path, modules)
    is Some(resolved_module) else {
    return ""
  }
  resolved_module.module_path
}

///|
fn register_renderer_test_shader_source(path : String) -> Unit {
  let full_path = @path.Path::join("assets", path).normalize().to_string()
  let source = @fs.read_file_to_string(full_path) catch {
    _ => abort("failed to load renderer test shader source: " + path)
  }
  register_wgsl_source(path, source)
}

///|
fn register_renderer_test_shaders() -> Unit {
  clear_registered_wgsl_source_registry()
  let paths = [
    "shaders/bevy_sprite_render/render/sprite.wgsl", "shaders/bevy_sprite_render/render/sprite_view_bindings.wgsl",
    "shaders/bevy_sprite_render/mesh2d/color_material.wgsl", "shaders/bevy_sprite_render/mesh2d/mesh2d.wgsl",
    "shaders/bevy_sprite_render/mesh2d/mesh2d_bindings.wgsl", "shaders/bevy_sprite_render/mesh2d/mesh2d_functions.wgsl",
    "shaders/bevy_sprite_render/mesh2d/mesh2d_types.wgsl", "shaders/bevy_sprite_render/mesh2d/mesh2d_vertex_output.wgsl",
    "shaders/bevy_sprite_render/mesh2d/mesh2d_view_bindings.wgsl", "shaders/bevy_sprite_render/mesh2d/mesh2d_view_types.wgsl",
    "shaders/bevy_post_process/bloom/bloom.wgsl", "shaders/bevy_core_pipeline/fullscreen_vertex_shader/fullscreen.wgsl",
    "shaders/bevy_core_pipeline/tonemapping/tonemapping.wgsl", "shaders/bevy_core_pipeline/tonemapping/lut_bindings.wgsl",
    "shaders/bevy_core_pipeline/tonemapping/tonemapping_shared.wgsl", "shaders/bevy_render/color_operations.wgsl",
    "shaders/bevy_render/globals.wgsl", "shaders/bevy_render/maths.wgsl", "shaders/bevy_render/view/view.wgsl",
    "shaders/bevy_ui_render/ui.wgsl", "shaders/bevy_ui_render/ui_texture_slice.wgsl",
    "shaders/bevy_ui_render/box_shadow.wgsl",
  ]
  for path in paths {
    register_renderer_test_shader_source(path)
  }
}

///|
fn gpu_test_pass_state(target_id : Int) -> GpuPassState {
  GpuPassState::{
    target_id,
    target_layer: -1,
    secondary_target_id: -1,
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
  register_renderer_test_shaders()
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
test "renderer: rg16f render target preserves Bevy motion-vector texture format" {
  let backend = GpuBackend::new(assets_base="assets")
  let target_id = backend.create_render_target_rg16f(128, 128, false)
  let ok = match find_texture(backend, target_id) {
    Some(texture) => texture.format_raw == @wgpu.TEXTURE_FORMAT_RG16_FLOAT
    None => false
  }
  inspect(ok, content="true")
}

///|
test "renderer: ui node shader loads canonical bevy ui module with anti alias define" {
  register_renderer_test_shaders()
  let with_anti_alias = load_ui_node_wgsl(true)
  let without_anti_alias = load_ui_node_wgsl(false)
  inspect(
    with_anti_alias.contains("@group(0) @binding(0) var<uniform> view: View;"),
    content="true",
  )
  inspect(with_anti_alias.contains("bevy_ui::"), content="false")
  inspect(
    with_anti_alias.contains("antialias(border_distance)"),
    content="true",
  )
  inspect(
    without_anti_alias.contains("let t = 1.0 - step(0.0, border_distance);"),
    content="true",
  )
}

///|
test "renderer: ui node batching expands rects to vertices and splits anti alias batches" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_ui_resources(backend)
  let texture_id = backend.create_texture_rgba8(
    1,
    1,
    Bytes::makei(4, _ => (255).to_byte()),
    false,
  )
  ui_enqueue_rect(
    backend,
    texture_id,
    0.0F,
    0.0F,
    0.0F,
    20.0F,
    10.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1 | 4,
    2.0F,
    2.0F,
    2.0F,
    2.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
  )
  ui_enqueue_rect(
    backend, texture_id, 8.0F, 4.0F, 0.0F, 20.0F, 10.0F, 1.0F, 1.0F, 1.0F, 1.0F,
    0.0F, 0.0F, 1.0F, 1.0F, 1, 2.0F, 2.0F, 2.0F, 2.0F, 0.0F, 0.0F, 0.0F, 0.0F,
  )
  inspect(backend.ui_vertex_count.reinterpret_as_int(), content="12")
  inspect(backend.ui_vertex_data.length(), content="264")
  inspect(backend.ui_batches.length(), content="2")
  inspect(
    backend.ui_batches[0].instance_count.reinterpret_as_int(),
    content="6",
  )
  inspect(backend.ui_batches[0].anti_alias, content="true")
  inspect(
    backend.ui_batches[1].instance_count.reinterpret_as_int(),
    content="6",
  )
  inspect(backend.ui_batches[1].anti_alias, content="false")
}

///|
test "renderer: ui texture slice shader loads canonical bevy ui texture slice module" {
  register_renderer_test_shaders()
  let wgsl = load_ui_texture_slice_wgsl()
  inspect(
    wgsl.contains("@group(0) @binding(0)\nvar<uniform> view: View;"),
    content="true",
  )
  inspect(
    wgsl.contains("@group(0) @binding(1)\nvar<uniform> globals: Globals;"),
    content="true",
  )
  inspect(
    wgsl.contains("@group(1) @binding(0) var sprite_texture: texture_2d<f32>;"),
    content="true",
  )
  inspect(wgsl.contains("bevy_render::"), content="false")
}

///|
test "renderer: ui texture slice batching expands rects to vertices and merges by texture" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_ui_slice_resources(backend)
  let texture_a = backend.create_texture_rgba8(
    1,
    1,
    Bytes::makei(4, _ => (255).to_byte()),
    false,
  )
  let texture_b = backend.create_texture_rgba8(
    1,
    1,
    Bytes::makei(4, _ => (127).to_byte()),
    false,
  )
  ui_enqueue_texture_slice(
    backend, texture_a, 0.0F, 0.0F, 0.0F, 20.0F, 10.0F, 1.0F, 1.0F, 1.0F, 1.0F, 0.1F,
    0.1F, 0.9F, 0.9F, 0.1F, 0.1F, 0.9F, 0.9F, 1.0F, 1.0F, 1.0F, 1.0F, 0.0F, 0.0F,
    1.0F, 1.0F,
  )
  ui_enqueue_texture_slice(
    backend, texture_a, 8.0F, 4.0F, 0.0F, 20.0F, 10.0F, 1.0F, 1.0F, 1.0F, 1.0F, 0.1F,
    0.1F, 0.9F, 0.9F, 0.1F, 0.1F, 0.9F, 0.9F, 1.0F, 1.0F, 1.0F, 1.0F, 0.0F, 0.0F,
    1.0F, 1.0F,
  )
  ui_enqueue_texture_slice(
    backend, texture_b, 16.0F, 8.0F, 0.0F, 20.0F, 10.0F, 1.0F, 1.0F, 1.0F, 1.0F,
    0.1F, 0.1F, 0.9F, 0.9F, 0.1F, 0.1F, 0.9F, 0.9F, 1.0F, 1.0F, 1.0F, 1.0F, 0.0F,
    0.0F, 1.0F, 1.0F,
  )
  inspect(backend.ui_slice_view_bg is Some(_), content="true")
  inspect(backend.ui_slice_vertex_count.reinterpret_as_int(), content="18")
  inspect(backend.ui_slice_vertex_data.length(), content="450")
  inspect(backend.ui_slice_batches.length(), content="2")
  inspect(
    backend.ui_slice_batches[0].instance_count.reinterpret_as_int(),
    content="12",
  )
  inspect(
    backend.ui_slice_batches[1].instance_count.reinterpret_as_int(),
    content="6",
  )
}

///|
test "renderer: ui box shadow shader loads canonical bevy ui box shadow module" {
  register_renderer_test_shaders()
  let wgsl = load_ui_box_shadow_wgsl(16)
  inspect(wgsl.contains("const SAMPLES: i32 = "), content="true")
  inspect(load_ui_box_shadow_wgsl(8) == wgsl, content="false")
  inspect(
    wgsl.contains("@group(0) @binding(0) var<uniform> view: View;"),
    content="true",
  )
  inspect(wgsl.contains("bevy_render::"), content="false")
}

///|
test "renderer: ui box shadow batching expands rects to vertices and merges by samples" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_ui_shadow_resources(backend)
  ui_enqueue_box_shadow(
    backend, 0.0F, 0.0F, 0.0F, 24.0F, 16.0F, 1.0F, 1.0F, 1.0F, 0.5F, 18.0F, 10.0F,
    2.0F, 2.0F, 2.0F, 2.0F, 4.0F, 16,
  )
  ui_enqueue_box_shadow(
    backend, 8.0F, 4.0F, 0.0F, 24.0F, 16.0F, 1.0F, 1.0F, 1.0F, 0.5F, 18.0F, 10.0F,
    2.0F, 2.0F, 2.0F, 2.0F, 4.0F, 16,
  )
  ui_enqueue_box_shadow(
    backend, 16.0F, 8.0F, 0.0F, 24.0F, 16.0F, 1.0F, 1.0F, 1.0F, 0.5F, 18.0F, 10.0F,
    2.0F, 2.0F, 2.0F, 2.0F, 4.0F, 8,
  )
  inspect(backend.ui_shadow_view_bg is Some(_), content="true")
  inspect(backend.ui_shadow_vertex_count.reinterpret_as_int(), content="18")
  inspect(backend.ui_shadow_vertex_data.length(), content="324")
  inspect(backend.ui_shadow_batches.length(), content="2")
  inspect(backend.ui_shadow_batches[0].samples, content="16")
  inspect(
    backend.ui_shadow_batches[0].instance_count.reinterpret_as_int(),
    content="12",
  )
  inspect(backend.ui_shadow_batches[1].samples, content="8")
  inspect(
    backend.ui_shadow_batches[1].instance_count.reinterpret_as_int(),
    content="6",
  )
}

///|
test "renderer: ui box shadow pipeline specializes by sample count" {
  register_renderer_test_shaders()
  let backend = GpuBackend::new(assets_base="assets")
  let target_id = backend.create_render_target_rgba16f(128, 128, false)
  backend.pass_state = Some(gpu_test_pass_state(target_id))
  let ok = ui_shadow_pipeline_for_current_pass(backend, 16) is Some(_) &&
    ui_shadow_pipeline_for_current_pass(backend, 8) is Some(_) &&
    backend.ui_shadow_pipeline_cache.length() == 2
  inspect(ok, content="true")
}

///|
test "renderer: mesh pipeline specializes to hdr render target format" {
  register_renderer_test_shaders()
  let backend = GpuBackend::new(assets_base="assets")
  let target_id = backend.create_render_target_rgba16f(128, 128, false)
  backend.pass_state = Some(gpu_test_pass_state(target_id))
  ensure_mesh2d_resources(backend)
  let format = match current_pass_color_format(backend) {
    Some(v) => v
    None => tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
  }
  mesh2d_get_or_create_pipeline(
    backend,
    mesh2d_pipeline_key_for_format(
      format,
      @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
      true,
      false,
      false,
      false,
    ),
  )
  |> ignore
  let ok = match backend.mesh_pipeline_surface_format {
    Some(format) => format == tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
    None => false
  }
  inspect(ok, content="true")
}

///|
test "renderer: bloom final composite uses hdr scene target format even from rgba8 final pass" {
  register_renderer_test_shaders()
  let backend = GpuBackend::new(assets_base="assets")
  let final_target_id = backend.create_render_target_with_format(
    128,
    128,
    false,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
  let scene_texture_id = backend.create_render_target_rgba16f(128, 128, false)
  backend.pass_state = Some(gpu_test_pass_state(final_target_id))
  bloom_final_composite_pipeline_for_scene_texture(backend, scene_texture_id, 0)
  |> ignore
  let ok = match backend.bloom_upsample_final_pipeline_format {
    Some(format) => format == tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
    None => false
  }
  inspect(ok, content="true")
}

///|
test "renderer: tonemapping final pipeline specializes to current final target without bloom composite" {
  register_renderer_test_shaders()
  let backend = GpuBackend::new(assets_base="assets")
  let target_id = backend.create_render_target_with_format(
    128,
    128,
    false,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
  backend.pass_state = Some(gpu_test_pass_state(target_id))
  let ok = match
    tonemapping_pipeline_for_format(
      backend,
      tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
      0,
      false,
    ) {
    Some(_) =>
      backend.tonemapping_pipeline_cache.length() == 1 &&
      backend.bloom_upsample_final_pipeline_format is None
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
