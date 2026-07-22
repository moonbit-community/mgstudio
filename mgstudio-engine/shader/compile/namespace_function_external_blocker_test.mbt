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
test "compile: transitive fully qualified module function call is flattened" {
  clear_registered_shader_sources()
  register_shader_source(
    "shader/compile/types_blocker.wgsl",
    (
      #|#define_import_path test::types
      #|struct Fog { mode: u32 }
      #|
    ),
  )
  register_shader_source(
    "shader/compile/fog_blocker.wgsl",
    (
      #|#define_import_path test::fog
      #|#import test::types::Fog
      #|fn linear_fog(
      #|  fog_params: Fog,
      #|  input_color: vec4<f32>,
      #|  distance: f32,
      #|  scattering: vec3<f32>,
      #|) -> vec4<f32> {
      #|  return input_color;
      #|}
      #|
    ),
  )
  register_shader_source(
    "shader/compile/pbr_functions_blocker.wgsl",
    (
      #|#define_import_path test::pbr_functions
      #|#import test::types
      #|#ifdef DISTANCE_FOG
      #|fn apply_fog(
      #|  fog_params: types::Fog,
      #|  input_color: vec4<f32>,
      #|  distance: f32,
      #|  scattering: vec3<f32>,
      #|) -> vec4<f32> {
      #|  return test::fog::linear_fog(
      #|    fog_params, input_color, distance, scattering,
      #|  );
      #|}
      #|#endif
      #|
    ),
  )
  register_shader_source(
    "shader/compile/fog_blocker_root.wgsl",
    (
      #|#define_import_path test::root
      #|#import test::pbr_functions
      #|#import test::types
      #|fn fragment(
      #|  fog_params: types::Fog,
      #|  input_color: vec4<f32>,
      #|  distance: f32,
      #|  scattering: vec3<f32>,
      #|) -> vec4<f32> {
      #|  return pbr_functions::apply_fog(
      #|    fog_params, input_color, distance, scattering,
      #|  );
      #|}
      #|
    ),
  )
  let source = try
    load_preprocessed_wgsl(
      "",
      "shader/compile/fog_blocker_root.wgsl",
      HashMap([("DISTANCE_FOG", true)]),
      default_shader_value_defines(),
    )
  catch {
    err =>
      fail(
        "expected qualified module function compose success: \{err.message()}",
      )
  } noraise {
    source => source
  }
  assert_true(source.contains("fn fragment"))
  assert_false(source.contains("test::fog::linear_fog"))
}
