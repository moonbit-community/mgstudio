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
fn mesh3d_pipeline_get_rgba8(
  backend : GpuBackend,
  topology : UInt,
  transparent : Bool,
) -> @wgpu.RenderPipeline? {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    if transparent {
      backend.mesh3d_pipeline_line_list_transparent
    } else {
      backend.mesh3d_pipeline_line_list
    }
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    if transparent {
      backend.mesh3d_pipeline_line_strip_transparent
    } else {
      backend.mesh3d_pipeline_line_strip
    }
  } else if transparent {
    backend.mesh3d_pipeline_transparent
  } else {
    backend.mesh3d_pipeline
  }
}

///|
fn mesh3d_pipeline_set_rgba8(
  backend : GpuBackend,
  topology : UInt,
  transparent : Bool,
  pipeline : @wgpu.RenderPipeline?,
) -> Unit {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    if transparent {
      backend.mesh3d_pipeline_line_list_transparent = pipeline
    } else {
      backend.mesh3d_pipeline_line_list = pipeline
    }
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    if transparent {
      backend.mesh3d_pipeline_line_strip_transparent = pipeline
    } else {
      backend.mesh3d_pipeline_line_strip = pipeline
    }
  } else if transparent {
    backend.mesh3d_pipeline_transparent = pipeline
  } else {
    backend.mesh3d_pipeline = pipeline
  }
}

///|
fn mesh3d_rgba8_pipeline_cache_clear(backend : GpuBackend) -> Unit {
  if backend.mesh3d_pipeline is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_transparent is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_line_list is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_line_list_transparent is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_line_strip is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_line_strip_transparent is Some(old) {
    old.release()
  }
  backend.mesh3d_pipeline = None
  backend.mesh3d_pipeline_transparent = None
  backend.mesh3d_pipeline_line_list = None
  backend.mesh3d_pipeline_line_list_transparent = None
  backend.mesh3d_pipeline_line_strip = None
  backend.mesh3d_pipeline_line_strip_transparent = None
  backend.mesh3d_pipeline_rgba8_cull_mode = -1
}

///|
fn mesh3d_pipeline_get_surface(
  backend : GpuBackend,
  topology : UInt,
  transparent : Bool,
) -> @wgpu.RenderPipeline? {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    if transparent {
      backend.mesh3d_pipeline_surface_line_list_transparent
    } else {
      backend.mesh3d_pipeline_surface_line_list
    }
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    if transparent {
      backend.mesh3d_pipeline_surface_line_strip_transparent
    } else {
      backend.mesh3d_pipeline_surface_line_strip
    }
  } else if transparent {
    backend.mesh3d_pipeline_surface_transparent
  } else {
    backend.mesh3d_pipeline_surface
  }
}

///|
fn mesh3d_pipeline_set_surface(
  backend : GpuBackend,
  topology : UInt,
  transparent : Bool,
  pipeline : @wgpu.RenderPipeline?,
) -> Unit {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    if transparent {
      backend.mesh3d_pipeline_surface_line_list_transparent = pipeline
    } else {
      backend.mesh3d_pipeline_surface_line_list = pipeline
    }
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    if transparent {
      backend.mesh3d_pipeline_surface_line_strip_transparent = pipeline
    } else {
      backend.mesh3d_pipeline_surface_line_strip = pipeline
    }
  } else if transparent {
    backend.mesh3d_pipeline_surface_transparent = pipeline
  } else {
    backend.mesh3d_pipeline_surface = pipeline
  }
}

///|
fn mesh3d_surface_pipeline_cache_clear(backend : GpuBackend) -> Unit {
  if backend.mesh3d_pipeline_surface is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_transparent is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_line_list is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_line_list_transparent is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_line_strip is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_line_strip_transparent is Some(old) {
    old.release()
  }
  backend.mesh3d_pipeline_surface = None
  backend.mesh3d_pipeline_surface_transparent = None
  backend.mesh3d_pipeline_surface_line_list = None
  backend.mesh3d_pipeline_surface_line_list_transparent = None
  backend.mesh3d_pipeline_surface_line_strip = None
  backend.mesh3d_pipeline_surface_line_strip_transparent = None
  backend.mesh3d_pipeline_surface_cull_mode = -1
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
