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
test "pbr prepass: render mesh lookup requires prepared render asset" {
  let world = @ecs.World::new()
  debug_inspect(render3d_prepass_render_mesh(world, 41) is None, content="true")

  let render_mesh_assets = @render_mesh.RenderMeshAssets::RenderMeshAssets()
  render_mesh_assets.insert(
    41,
    @render_mesh.RenderMesh::new(vertex_count=7, indexed=true, index_count=12),
  )
  world.insert_resource(
    @render_mesh.RenderMeshAssets::resource(),
    render_mesh_assets,
  )

  guard render3d_prepass_render_mesh(world, 41) is Some(render_mesh) else {
    fail("expected prepared render mesh")
  }
  debug_inspect(render_mesh.vertex_count(), content="7")
  debug_inspect(render_mesh.indexed(), content="true")
  debug_inspect(render3d_prepass_render_mesh(world, 42) is None, content="true")
}
