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
pub(all) enum RenderPipelineCacheState {
  RenderPipelineOk(@wgpu.RenderPipeline)
  RenderPipelineErr(String)
}

///|
struct Mesh3dPipelineCacheEntry {
  color_format : UInt
  topology : UInt
  cull_mode : Int
  blend_kind : Int
  skinned : Bool
  forward_decal : Bool
  state : RenderPipelineCacheState
}

///|
fn mesh3d_pipeline_get(
  backend : GpuBackend,
  color_format : UInt,
  topology : UInt,
  cull_mode : Int,
  blend_kind : Int,
  skinned : Bool,
  forward_decal : Bool,
) -> @wgpu.RenderPipeline? {
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  for entry in backend.mesh3d_pipeline_cache {
    if entry.color_format == color_format &&
      entry.topology == topology &&
      entry.cull_mode == safe_cull_mode &&
      entry.blend_kind == blend_kind &&
      entry.skinned == skinned &&
      entry.forward_decal == forward_decal {
      match entry.state {
        RenderPipelineOk(pipeline) => return Some(pipeline)
        RenderPipelineErr(message) => {
          ignore(message)
          return None
        }
      }
    }
  }
  None
}

///|
fn mesh3d_pipeline_failed(
  backend : GpuBackend,
  color_format : UInt,
  topology : UInt,
  cull_mode : Int,
  blend_kind : Int,
  skinned : Bool,
  forward_decal : Bool,
) -> Bool {
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  for entry in backend.mesh3d_pipeline_cache {
    if entry.color_format == color_format &&
      entry.topology == topology &&
      entry.cull_mode == safe_cull_mode &&
      entry.blend_kind == blend_kind &&
      entry.skinned == skinned &&
      entry.forward_decal == forward_decal {
      match entry.state {
        RenderPipelineOk(_) => return false
        RenderPipelineErr(message) => {
          ignore(message)
          return true
        }
      }
    }
  }
  false
}

///|
fn mesh3d_pipeline_set(
  backend : GpuBackend,
  color_format : UInt,
  topology : UInt,
  cull_mode : Int,
  blend_kind : Int,
  skinned : Bool,
  forward_decal : Bool,
  pipeline : @wgpu.RenderPipeline,
) -> Unit {
  backend.mesh3d_pipeline_cache.push({
    color_format,
    topology,
    cull_mode: mesh3d_cull_mode_sanitize(cull_mode),
    blend_kind,
    skinned,
    forward_decal,
    state: RenderPipelineOk(pipeline),
  })
}

///|
fn mesh3d_pipeline_set_failed(
  backend : GpuBackend,
  color_format : UInt,
  topology : UInt,
  cull_mode : Int,
  blend_kind : Int,
  skinned : Bool,
  forward_decal : Bool,
  message : String,
) -> Unit {
  if mesh3d_pipeline_get(
      backend, color_format, topology, cull_mode, blend_kind, skinned, forward_decal,
    )
    is Some(_) {
    return
  }
  if mesh3d_pipeline_failed(
      backend, color_format, topology, cull_mode, blend_kind, skinned, forward_decal,
    ) {
    return
  }
  backend.mesh3d_pipeline_cache.push({
    color_format,
    topology,
    cull_mode: mesh3d_cull_mode_sanitize(cull_mode),
    blend_kind,
    skinned,
    forward_decal,
    state: RenderPipelineErr(message),
  })
}

///|
fn mesh3d_pipeline_cache_clear(backend : GpuBackend) -> Unit {
  for entry in backend.mesh3d_pipeline_cache {
    match entry.state {
      RenderPipelineOk(pipeline) => pipeline.release()
      RenderPipelineErr(message) => ignore(message)
    }
  }
  backend.mesh3d_pipeline_cache.clear()
}

///|
fn mesh3d_custom_pipeline_cache_clear(backend : GpuBackend) -> Unit {
  for cache_entry in backend.mesh3d_custom_pipeline_cache.iter() {
    let (_key, state) = cache_entry
    match state {
      RenderPipelineOk(pipeline) => pipeline.release()
      RenderPipelineErr(message) => ignore(message)
    }
  }
  backend.mesh3d_custom_pipeline_cache.clear()
}

///|
struct Mesh3dShadowPipelineCacheEntry {
  topology : UInt
  cull_mode : Int
  material_path : Bool
  skinned : Bool
  pipeline : @wgpu.RenderPipeline
}

///|
fn mesh3d_shadow_pipeline_get(
  backend : GpuBackend,
  topology : UInt,
  cull_mode : Int,
  material_path : Bool,
  skinned : Bool,
) -> @wgpu.RenderPipeline? {
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  for entry in backend.mesh3d_shadow_pipeline_cache {
    if entry.topology == topology &&
      entry.cull_mode == safe_cull_mode &&
      entry.material_path == material_path &&
      entry.skinned == skinned {
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
  skinned : Bool,
  pipeline : @wgpu.RenderPipeline,
) -> Unit {
  backend.mesh3d_shadow_pipeline_cache.push({
    topology,
    cull_mode: mesh3d_cull_mode_sanitize(cull_mode),
    material_path,
    skinned,
    pipeline,
  })
}
