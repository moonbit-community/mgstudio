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
test "shader cache data preserves shader-def sequence as cache key" {
  let data : ShaderData[String, Int] = ShaderData::default()
  let ab = [@shader.shader_def("A"), @shader.ShaderDefVal::UInt("MODE", 2U)]
  let ba = [@shader.ShaderDefVal::UInt("MODE", 2U), @shader.shader_def("A")]
  let abb = [
    @shader.shader_def("A"),
    @shader.ShaderDefVal::UInt("MODE", 2U),
    @shader.shader_def("A"),
  ]
  data.cache_processed_shader(ab, "module-ab")

  inspect(data.processed_shader_count(), content="1")
  inspect(data.get_processed_shader(ab), content="Some(\"module-ab\")")
  inspect(data.get_processed_shader(ba), content="None")
  inspect(data.get_processed_shader(abb), content="None")
}

///|
test "shader cache data tracks pipelines imports and dependents" {
  let data : ShaderData[String, String] = ShaderData::default()
  data.track_pipeline(3)
  data.track_pipeline(3)
  data.track_pipeline(8)
  data.resolve_import(
    @shader.ShaderImport::Custom("bevy_render::view"),
    "shader-view",
  )
  data.track_dependent("shader-a")
  data.track_dependent("shader-a")
  data.track_dependent("shader-b")

  inspect(data.pipeline_count(), content="2")
  inspect(
    data.resolved_import(@shader.ShaderImport::Custom("bevy_render::view")),
    content="Some(\"shader-view\")",
  )
  inspect(data.dependent_count(), content="2")
}

///|
test "shader cache source keeps fully composed source variants" {
  inspect(
    @shader.ShaderCacheSource::Wgsl("fn main() {}"),
    content="Wgsl(\"fn main() {}\")",
  )
  inspect(
    @shader.ShaderCacheSource::SpirV(@utf8.encode("SPV")),
    content="SpirV(b\"SPV\")",
  )
}
