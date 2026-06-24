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
test "pbr: render material shader paths are extracted from mesh material metadata" {
  let shader_paths = RenderMaterialShaderPaths::RenderMaterialShaderPaths()
  let material = MeshMaterial3d::new(@asset.Handle::new(42))
    .with_extension_vertex_shader_path(Some("shaders/extended.vert.wgsl"))
    .with_extension_fragment_shader_path(Some("shaders/extended.frag.wgsl"))
  shader_paths.extract_mesh_material(material)
  shader_paths.extract_mesh_material(material)

  let paths = shader_paths.paths()
  debug_inspect(paths.length(), content="2")
  debug_inspect(paths.contains("shaders/extended.vert.wgsl"), content="true")
  debug_inspect(paths.contains("shaders/extended.frag.wgsl"), content="true")
}
