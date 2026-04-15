// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_mesh/src/lib.rs`.
// Runtime owner split out of `mesh/mesh.mbt`.

///|
const MESH_PLUGIN_NAME : String = "mgstudio.mesh.MeshPlugin"

///|
pub struct MeshPlugin {}

///|
pub fn MeshPlugin::default() -> MeshPlugin {
  MeshPlugin::{  }
}

///|
pub impl @app.Plugin for MeshPlugin with name(_self) {
  MESH_PLUGIN_NAME
}

///|
pub impl @app.Plugin for MeshPlugin with build(_self, app) {
  mesh_plugin(app)
}

///|
pub fn mesh_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.init_resource(fn() {
    let assets : @asset.Assets[Mesh] = @asset.Assets::new()
    assets
  })
}

///|
pub(all) enum MeshGeometry {
  Geometry2d(Mesh2dGeometry)
  Geometry3d(Mesh3dGeometry)
}

///|
pub struct Mesh {
  geometry : MeshGeometry
}
