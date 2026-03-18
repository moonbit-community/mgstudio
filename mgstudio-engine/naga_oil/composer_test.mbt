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
fn empty_bool_defines() -> @hashmap.HashMap[String, Bool] {
  @hashmap.HashMap::new()
}

///|
fn register_composer_test_shader_source(path : String) -> Unit {
  let full_path = @path.Path::join("assets", path).normalize().to_string()
  let source = @fs.read_file_to_string(full_path) catch {
    _ => abort("failed to load composer test shader source: " + path)
  }
  @naga_oil.register_wgsl_source(path, source)
}

///|
fn register_composer_test_shaders() -> Unit {
  @naga_oil.clear_registered_wgsl_source_registry()
  let paths = [
    "shaders/bevy/bevy_sprite_render/render/sprite.wgsl", "shaders/bevy/bevy_sprite_render/render/sprite_view_bindings.wgsl",
    "shaders/bevy/bevy_sprite_render/mesh2d/color_material.wgsl", "shaders/bevy/bevy_sprite_render/mesh2d/mesh2d.wgsl",
    "shaders/bevy/bevy_sprite_render/mesh2d/mesh2d_view_bindings.wgsl",
    "shaders/bevy/bevy_sprite_render/mesh2d/mesh2d_bindings.wgsl", "shaders/bevy/bevy_sprite_render/mesh2d/mesh2d_functions.wgsl",
    "shaders/bevy/bevy_sprite_render/mesh2d/mesh2d_types.wgsl", "shaders/bevy/bevy_sprite_render/mesh2d/mesh2d_vertex_output.wgsl",
    "shaders/bevy/bevy_render/view/view.wgsl", "shaders/bevy/bevy_render/globals.wgsl",
    "shaders/bevy/bevy_render/maths.wgsl",
  ]
  for path in paths {
    register_composer_test_shader_source(path)
  }
}

///|
test "naga_oil: composer preprocess supports multiline grouped imports" {
  let value_defines = @naga_oil.default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = @naga_oil.build_wgsl_import_module_paths("assets")
  let preprocessed = @naga_oil.Composer::default().preprocess_wgsl_source(
    "assets",
    "#import bevy_render::{\n  color_operations::{hsv_to_rgb, rgb_to_hsv},\n  maths::{PI_2, powsafe},\n}\nfn demo(color: vec3<f32>) -> vec3<f32> {\n  let h = rgb_to_hsv(color);\n  return hsv_to_rgb(vec3<f32>(h.x + PI_2, h.y, powsafe(h.z, 1.0)));\n}\n",
    empty_bool_defines(),
    value_defines,
    visited,
    modules,
  ) catch {
    err => abort("expected composer preprocess success: " + err.message())
  }
  inspect(preprocessed.contains("fn rgb_to_hsv"), content="true")
  inspect(preprocessed.contains("fn hsv_to_rgb"), content="true")
  inspect(preprocessed.contains("const PI_2"), content="true")
  inspect(preprocessed.contains("bevy_render::"), content="false")
}

///|
test "naga_oil: composer preprocess strips module aliases" {
  let value_defines = @naga_oil.default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = @naga_oil.build_wgsl_import_module_paths("assets")
  let preprocessed = @naga_oil.Composer::default().preprocess_wgsl_source(
    "assets",
    "#import bevy_render::maths as maths\nfn demo() -> f32 {\n  return maths::PI_2;\n}\n",
    empty_bool_defines(),
    value_defines,
    visited,
    modules,
  ) catch {
    err => abort("expected composer preprocess success: " + err.message())
  }
  inspect(preprocessed.contains("return PI_2;"), content="true")
  inspect(preprocessed.contains("maths::PI_2"), content="false")
}

///|
test "naga_oil: composer item imports keep dependent view declarations" {
  register_composer_test_shaders()
  let value_defines = @naga_oil.default_wgsl_value_defines()
  let modules = @naga_oil.copy_registered_wgsl_import_module_paths()

  let sprite_visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let sprite_preprocessed = @naga_oil.Composer::default().load_wgsl_preprocessed(
    "",
    "shaders/bevy/bevy_sprite_render/render/sprite_view_bindings.wgsl",
    empty_bool_defines(),
    value_defines,
    sprite_visited,
    modules,
  ) catch {
    err =>
      abort("expected sprite composer preprocess success: " + err.message())
  }
  inspect(sprite_preprocessed.contains("struct ColorGrading"), content="true")
  inspect(sprite_preprocessed.contains("struct View"), content="true")

  let mesh2d_visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let mesh2d_preprocessed = @naga_oil.Composer::default().load_wgsl_preprocessed(
    "",
    "shaders/bevy/bevy_sprite_render/mesh2d/mesh2d_view_bindings.wgsl",
    empty_bool_defines(),
    value_defines,
    mesh2d_visited,
    modules,
  ) catch {
    err =>
      abort("expected mesh2d composer preprocess success: " + err.message())
  }
  inspect(mesh2d_preprocessed.contains("struct ColorGrading"), content="true")
  inspect(mesh2d_preprocessed.contains("struct View"), content="true")
  @naga_oil.clear_registered_wgsl_source_registry()
}

///|
test "naga_oil: composer registered sources satisfy strict mesh2d preprocessing" {
  @naga_oil.clear_registered_wgsl_source_registry()
  @naga_oil.register_wgsl_source(
    "shaders/bevy/bevy_render/maths.wgsl", "#define_import_path bevy_render::maths\nconst PI_2: f32 = 6.28318;\n",
  )
  @naga_oil.register_wgsl_source(
    "shaders/bevy/bevy_sprite_render/mesh2d/mesh2d_functions.wgsl", "#define_import_path bevy_sprite::mesh2d_functions\n#import bevy_render::maths::PI_2\nfn twice_pi() -> f32 {\n  return PI_2;\n}\n",
  )
  @naga_oil.register_wgsl_source(
    "shaders/bevy/bevy_sprite_render/mesh2d/mesh2d.wgsl", "#import bevy_sprite::mesh2d_functions as mesh_functions\nfn demo() -> f32 {\n  return mesh_functions::twice_pi();\n}\n",
  )
  let value_defines = @naga_oil.default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = @naga_oil.copy_registered_wgsl_import_module_paths()
  let preprocessed = @naga_oil.Composer::default().load_wgsl_preprocessed(
    "",
    "shaders/bevy/bevy_sprite_render/mesh2d/mesh2d.wgsl",
    empty_bool_defines(),
    value_defines,
    visited,
    modules,
  ) catch {
    err =>
      abort("expected registered-source preprocess success: " + err.message())
  }
  inspect(preprocessed.contains("const PI_2"), content="true")
  inspect(preprocessed.contains("return twice_pi();"), content="true")
  inspect(preprocessed.contains("mesh_functions::"), content="false")
  @naga_oil.clear_registered_wgsl_source_registry()
}
