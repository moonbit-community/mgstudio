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
pub fn shader_register_wgsl_runtime_source(
  world : @ecs.World,
  path : String,
) -> Unit {
  let sources = @shader.shader_runtime_load_wgsl_sources(world, path)
  for source in sources {
    @renderer.host_gpu_register_wgsl_source(source.0, source.1)
  }
}

///|
pub fn shader_register_wesl_runtime_source(
  world : @ecs.World,
  path : String,
  shader_defs : Array[@shader.ShaderDefVal],
) -> Unit raise @shader.ShaderCacheError {
  match @shader.shader_runtime_compile_wesl_source(world, path, shader_defs) {
    Some(compiled) => @renderer.host_gpu_register_wgsl_source(path, compiled)
    None => ()
  }
}

///|
pub fn shader_register_runtime_source(
  world : @ecs.World,
  path : String,
  shader_defs : Array[@shader.ShaderDefVal],
) -> Unit raise @shader.ShaderCacheError {
  if @shader.shader_path_is_wesl(path) {
    shader_register_wesl_runtime_source(world, path, shader_defs)
    return
  }
  shader_register_wgsl_runtime_source(world, path)
}
