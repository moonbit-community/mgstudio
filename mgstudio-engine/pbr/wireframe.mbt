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
/// Marker component aligned with Bevy's `Wireframe`.
///
/// Meshes with this marker render in wireframe regardless of
/// `WireframeConfig::global`.
pub struct Wireframe {} derive(ToJson, FromJson)

///|
pub fn Wireframe::default() -> Wireframe {
  Wireframe::{  }
}

///|
/// Marker component aligned with Bevy's `NoWireframe`.
///
/// Meshes with this marker never render in wireframe regardless of
/// `WireframeConfig::global`.
pub struct NoWireframe {} derive(ToJson, FromJson)

///|
pub fn NoWireframe::default() -> NoWireframe {
  NoWireframe::{  }
}

///|
/// Per-mesh wireframe color aligned with Bevy's `WireframeColor`.
pub struct WireframeColor {
  color : @sprite.Color
} derive(ToJson, FromJson)

///|
pub fn WireframeColor::default() -> WireframeColor {
  WireframeColor::{ color: @sprite.Color::white() }
}

///|
pub fn WireframeColor::new(color : @sprite.Color) -> WireframeColor {
  WireframeColor::{ color, }
}

///|
pub fn WireframeColor::with_color(
  self : WireframeColor,
  color : @sprite.Color,
) -> WireframeColor {
  self |> ignore
  WireframeColor::{ color, }
}

///|
pub struct WireframeConfig {
  global : Bool
  default_color : @sprite.Color
} derive(ToJson, FromJson)

///|
pub fn WireframeConfig::default() -> WireframeConfig {
  WireframeConfig::{ global: false, default_color: @sprite.Color::white() }
}

///|
pub fn WireframeConfig::new(
  global : Bool,
  default_color : @sprite.Color,
) -> WireframeConfig {
  WireframeConfig::{ global, default_color }
}

///|
pub fn WireframeConfig::with_global(
  self : WireframeConfig,
  global : Bool,
) -> WireframeConfig {
  WireframeConfig::{ ..self, global, }
}

///|
pub fn WireframeConfig::with_default_color(
  self : WireframeConfig,
  default_color : @sprite.Color,
) -> WireframeConfig {
  WireframeConfig::{ ..self, default_color, }
}

///|
pub impl @app.Resource for WireframeConfig with resource() {
  ecs_key_wireframe_config
}

///|
const WIREFRAME_PLUGIN_NAME : String = "mgstudio.pbr.WireframePlugin"

///|
pub struct WireframePlugin {}

///|
pub fn WireframePlugin::default() -> WireframePlugin {
  WireframePlugin::{  }
}

///|
pub impl @app.Plugin for WireframePlugin with name(_self) {
  WIREFRAME_PLUGIN_NAME
}

///|
pub impl @app.Plugin for WireframePlugin with build(_self, app) {
  wireframe_plugin(app)
}

///|
fn init_wireframe_resources(world : @ecs.World) -> Unit {
  let wireframe_config = get_wireframe_config_resource(world)
  if !wireframe_config.is_present() {
    wireframe_config.insert(WireframeConfig::default())
  }
}

///|
pub fn wireframe_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  wireframe_plugin_with(app, WireframePlugin::default())
}

///|
pub fn wireframe_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : WireframePlugin,
) -> @app.App[@ecs.World] {
  app.add_startup_system(init_wireframe_resources)
}

///|
priv struct WireframeMeshCacheEntry {
  source_mesh_handle_id : Int
  wireframe_mesh_id : Int
}

///|
priv struct Render3dWireframeMeshCache {
  mut entries : Array[WireframeMeshCacheEntry]
}

///|
let render3d_wireframe_mesh_cache_key : @ecs.ResourceKey[
  Render3dWireframeMeshCache,
] = @ecs.register_resource(debug_name="mgstudio.render3d.wireframe_mesh_cache")

///|
impl @app.Resource for Render3dWireframeMeshCache with resource() {
  render3d_wireframe_mesh_cache_key
}

///|
fn render3d_wireframe_mesh_cache_ref_or_init(
  world : @ecs.World,
) -> Ref[Render3dWireframeMeshCache] {
  if (try! world.get_resource(Render3dWireframeMeshCache::resource())) is None {
    world.insert_resource(Render3dWireframeMeshCache::resource(), {
      entries: [],
    })
  }
  match (try! world.get_resource_mut(Render3dWireframeMeshCache::resource())) {
    Some(cache) => Ref::new(cache.peek())
    None => abort("Missing Render3dWireframeMeshCache resource")
  }
}

///|
fn render3d_wireframe_mesh_cache_get(
  world : @ecs.World,
  source_mesh_handle_id : Int,
) -> Int? {
  let cache_ref = render3d_wireframe_mesh_cache_ref_or_init(world)
  for item in cache_ref.val.entries {
    if item.source_mesh_handle_id == source_mesh_handle_id {
      return Some(item.wireframe_mesh_id)
    }
  }
  None
}

///|
fn render3d_wireframe_mesh_cache_set(
  world : @ecs.World,
  source_mesh_handle_id : Int,
  wireframe_mesh_id : Int,
) -> Unit {
  let cache_ref = render3d_wireframe_mesh_cache_ref_or_init(world)
  let next : Array[WireframeMeshCacheEntry] = []
  let mut replaced = false
  for item in cache_ref.val.entries {
    if item.source_mesh_handle_id == source_mesh_handle_id {
      if !replaced {
        next.push({ source_mesh_handle_id, wireframe_mesh_id })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ source_mesh_handle_id, wireframe_mesh_id })
  }
  cache_ref.val.entries = next
}

///|
fn render3d_wireframe_mesh_id(
  world : @ecs.World,
  mesh_handle : @asset.Handle[@mesh.Mesh],
) -> Int? {
  let source_mesh_handle_id = mesh_handle.id()
  if render3d_wireframe_mesh_cache_get(world, source_mesh_handle_id)
    is Some(mesh_id) {
    return Some(mesh_id)
  }
  let source_mesh = match @sprite.render_mesh_asset_get(mesh_handle) {
    Some(mesh_asset) => mesh_asset
    None => return None
  }
  match source_mesh.geometry {
    @mesh.MeshGeometry::Geometry3d(geometry3d) =>
      match geometry3d.primitive_topology() {
        @mesh.Mesh3dPrimitiveTopology::TriangleList =>
          match geometry3d.to_wireframe_line_list() {
            Some(wireframe_geometry) => {
              let wireframe_handle = @sprite.render_mesh_asset_add(
                @mesh.Mesh::from_3d_geometry(wireframe_geometry),
              )
              let wireframe_mesh_id = @sprite_render.render2d_upload_mesh_handle(
                wireframe_handle,
              )
              render3d_wireframe_mesh_cache_set(
                world, source_mesh_handle_id, wireframe_mesh_id,
              )
              Some(wireframe_mesh_id)
            }
            None => None
          }
        @mesh.Mesh3dPrimitiveTopology::LineList => {
          let mesh_id = @sprite_render.render2d_upload_mesh_handle(mesh_handle)
          render3d_wireframe_mesh_cache_set(
            world, source_mesh_handle_id, mesh_id,
          )
          Some(mesh_id)
        }
        @mesh.Mesh3dPrimitiveTopology::LineStrip => {
          let mesh_id = @sprite_render.render2d_upload_mesh_handle(mesh_handle)
          render3d_wireframe_mesh_cache_set(
            world, source_mesh_handle_id, mesh_id,
          )
          Some(mesh_id)
        }
      }
    _ => None
  }
}

///|
fn render3d_mesh_should_draw_wireframe(
  mesh : ExtractedMesh3d,
  wireframe_config : WireframeConfig?,
) -> Bool {
  guard wireframe_config is Some(config) else { return false }
  if mesh.payload.has_no_wireframe {
    false
  } else if mesh.payload.has_wireframe {
    true
  } else {
    config.global
  }
}

///|
fn render3d_mesh_wireframe_color(
  mesh : ExtractedMesh3d,
  wireframe_config : WireframeConfig?,
) -> @sprite.Color {
  if mesh.payload.wireframe_color is Some(color_component) {
    color_component.color
  } else if wireframe_config is Some(config) {
    config.default_color
  } else {
    @sprite.Color::white()
  }
}
