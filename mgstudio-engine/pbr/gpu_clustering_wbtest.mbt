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
test "render3d: gpu clustering registers all embedded shader sources" {
  @shader_source.clear_embedded_shader_sources()
  gpu_clustering_register_embedded_assets()

  debug_inspect(
    @shader_source.embedded_shader_source("pbr/cluster/cluster.wgsl") is Some(_),
    content="true",
  )
  debug_inspect(
    @shader_source.embedded_shader_source("pbr/cluster/cluster_z_slice.wgsl")
    is Some(_),
    content="true",
  )
  debug_inspect(
    @shader_source.embedded_shader_source("pbr/cluster/cluster_raster.wgsl")
    is Some(_),
    content="true",
  )
  debug_inspect(
    @shader_source.embedded_shader_source("pbr/cluster/cluster_allocate.wgsl")
    is Some(_),
    content="true",
  )
}
