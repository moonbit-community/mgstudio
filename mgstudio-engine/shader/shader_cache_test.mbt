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

  debug_inspect(data.processed_shader_count(), content="1")
  debug_inspect(data.get_processed_shader(ab), content="Some(\"module-ab\")")
  debug_inspect(data.get_processed_shader(ba), content="None")
  debug_inspect(data.get_processed_shader(abb), content="None")
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

  debug_inspect(data.pipeline_count(), content="2")
  debug_inspect(
    data.resolved_import(@shader.ShaderImport::Custom("bevy_render::view")),
    content="Some(\"shader-view\")",
  )
  debug_inspect(data.dependent_count(), content="2")
}

///|
test "shader cache source keeps fully composed source variants" {
  debug_inspect(
    @shader.ShaderCacheSource::Wgsl("fn main() {}"),
    content="Wgsl(\"fn main() {}\")",
  )
  debug_inspect(
    @shader.ShaderCacheSource::SpirV(@utf8.encode("SPV")),
    content="SpirV(<Bytes: [0x53, 0x50, 0x56]>)",
  )
}

///|
fn shader_cache_dummy_load_module(
  _device : Int,
  source : @shader.ShaderCacheSource,
  _validate : @shader.ValidateShader,
) -> String raise @shader.ShaderCacheError {
  match source {
    Wgsl(text) =>
      if text == "" {
        raise @shader.ShaderCacheError::CreateShaderModule(
          "empty WGSL source in shader cache test",
        )
      } else {
        text
      }
    SpirV(_) => "spirv"
  }
}

///|
fn shader_cache_test_shader(
  import_path : @shader.ShaderImport,
  imports : Array[@shader.ShaderImport],
) -> @shader.Shader {
  @shader.Shader::{
    path: import_path.module_name(),
    source: @shader.Source::Wgsl("fn main() {}"),
    import_path,
    imports,
    additional_imports: [],
    shader_defs: [],
    file_dependencies: [],
    validate_shader: @shader.ValidateShader::Disabled,
  }
}

///|
test "shader cache lifecycle tracks waiting imports and dependent invalidation" {
  let cache : @shader.ShaderCache[String, Int] = @shader.ShaderCache::new(
    0, shader_cache_dummy_load_module,
  )
  let base_id : @asset.AssetId[@shader.Shader] = @asset.AssetId::new(1)
  let child_id : @asset.AssetId[@shader.Shader] = @asset.AssetId::new(2)

  ignore(
    cache.set_shader(
      child_id,
      shader_cache_test_shader(@shader.ShaderImport::Custom("test::child"), [
        @shader.ShaderImport::Custom("test::base"),
      ]),
    ),
  )
  let child_data_before = match cache.data.get(child_id.index()) {
    Some(data) => data
    None => @shader.ShaderData::default()
  }
  child_data_before.track_pipeline(7)
  cache.data.set(child_id.index(), child_data_before)

  debug_inspect(cache.contains_shader(child_id), content="true")
  debug_inspect(
    cache.waiting_on_import.contains(@shader.ShaderImport::Custom("test::base")),
    content="true",
  )

  ignore(
    cache.set_shader(
      base_id,
      shader_cache_test_shader(@shader.ShaderImport::Custom("test::base"), []),
    ),
  )

  let child_data_after = match cache.data.get(child_id.index()) {
    Some(data) => data
    None => abort("expected child shader data after import resolution")
  }
  debug_inspect(
    child_data_after.resolved_import(@shader.ShaderImport::Custom("test::base")),
    content="Some(1)",
  )
  debug_inspect(
    cache.waiting_on_import.contains(@shader.ShaderImport::Custom("test::base")),
    content="false",
  )

  let invalidated = cache.remove(base_id)
  debug_inspect(invalidated.length(), content="1")
  debug_inspect(invalidated[0], content="7")
  debug_inspect(cache.contains_shader(base_id), content="false")
}

///|
test "shader cache error messages match lifecycle surface" {
  debug_inspect(
    @shader.ShaderCacheError::ShaderImportNotYetAvailable.message(),
    content="\"Shader import not yet available.\"",
  )
  debug_inspect(
    @shader.ShaderCacheError::CreateShaderModule("bad pipeline").message(),
    content="\"Could not create shader module: bad pipeline\"",
  )
}
