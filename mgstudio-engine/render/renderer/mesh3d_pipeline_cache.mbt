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
const MESH3D_PIPELINE_BLEND_OPAQUE : Int = 0

///|
const MESH3D_PIPELINE_BLEND_ALPHA : Int = 1

///|
const MESH3D_PIPELINE_BLEND_PREMULTIPLIED_ALPHA : Int = 2

///|
const MESH3D_PIPELINE_BLEND_MULTIPLY : Int = 3

///|
struct Mesh3dPipelineCacheEntry {
  color_format : UInt
  topology : UInt
  cull_mode : Int
  blend_kind : Int
  skinned : Bool
  pipeline : @wgpu.RenderPipeline
}

///|
fn mesh3d_pipeline_get(
  backend : GpuBackend,
  color_format : UInt,
  topology : UInt,
  cull_mode : Int,
  blend_kind : Int,
  skinned : Bool,
) -> @wgpu.RenderPipeline? {
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  for entry in backend.mesh3d_pipeline_cache {
    if entry.color_format == color_format &&
      entry.topology == topology &&
      entry.cull_mode == safe_cull_mode &&
      entry.blend_kind == blend_kind &&
      entry.skinned == skinned {
      return Some(entry.pipeline)
    }
  }
  None
}

///|
fn mesh3d_pipeline_set(
  backend : GpuBackend,
  color_format : UInt,
  topology : UInt,
  cull_mode : Int,
  blend_kind : Int,
  skinned : Bool,
  pipeline : @wgpu.RenderPipeline,
) -> Unit {
  backend.mesh3d_pipeline_cache.push({
    color_format,
    topology,
    cull_mode: mesh3d_cull_mode_sanitize(cull_mode),
    blend_kind,
    skinned,
    pipeline,
  })
}

///|
fn mesh3d_pipeline_cache_clear(backend : GpuBackend) -> Unit {
  for entry in backend.mesh3d_pipeline_cache {
    entry.pipeline.release()
  }
  backend.mesh3d_pipeline_cache.clear()
}

///|
fn mesh3d_custom_pipeline_cache_clear(backend : GpuBackend) -> Unit {
  for entry in backend.mesh3d_custom_pipeline_cache {
    entry.pipeline.release()
  }
  backend.mesh3d_custom_pipeline_cache.clear()
}

///|
struct Mesh3dShadowPipelineCacheEntry {
  topology : UInt
  cull_mode : Int
  material_path : Bool
  pipeline : @wgpu.RenderPipeline
}

///|
fn mesh3d_shadow_pipeline_get(
  backend : GpuBackend,
  topology : UInt,
  cull_mode : Int,
  material_path : Bool,
) -> @wgpu.RenderPipeline? {
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  for entry in backend.mesh3d_shadow_pipeline_cache {
    if entry.topology == topology &&
      entry.cull_mode == safe_cull_mode &&
      entry.material_path == material_path {
      return Some(entry.pipeline)
    }
  }
  None
}

///|
fn mesh3d_shadow_pipeline_set(
  backend : GpuBackend,
  topology : UInt,
  cull_mode : Int,
  material_path : Bool,
  pipeline : @wgpu.RenderPipeline,
) -> Unit {
  backend.mesh3d_shadow_pipeline_cache.push({
    topology,
    cull_mode: mesh3d_cull_mode_sanitize(cull_mode),
    material_path,
    pipeline,
  })
}
