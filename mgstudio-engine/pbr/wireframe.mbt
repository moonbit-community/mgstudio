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
pub fn Wireframe::Wireframe() -> Wireframe {
  Wireframe::{  }
}

///|
/// Marker component aligned with Bevy's `NoWireframe`.
///
/// Meshes with this marker never render in wireframe regardless of
/// `WireframeConfig::global`.
pub struct NoWireframe {} derive(ToJson, FromJson)

///|
pub fn NoWireframe::NoWireframe() -> NoWireframe {
  NoWireframe::{  }
}

///|
/// Per-mesh wireframe color aligned with Bevy's `WireframeColor`.
pub struct WireframeColor {
  color : @color.Color
} derive(ToJson, FromJson)

///|
pub fn WireframeColor::WireframeColor() -> WireframeColor {
  WireframeColor::{ color: @color.Color::white() }
}

///|
pub fn WireframeColor::new(color : @color.Color) -> WireframeColor {
  WireframeColor::{ color, }
}

///|
pub fn WireframeColor::with_color(
  self : WireframeColor,
  color : @color.Color,
) -> WireframeColor {
  self |> ignore
  WireframeColor::{ color, }
}

///|
/// Sets the line width of the wireframe in screen-space pixels.
pub struct WireframeLineWidth {
  width : Float
} derive(ToJson, FromJson)

///|
pub fn WireframeLineWidth::WireframeLineWidth() -> WireframeLineWidth {
  WireframeLineWidth::{ width: 1.0F }
}

///|
pub fn WireframeLineWidth::new(width : Float) -> WireframeLineWidth {
  WireframeLineWidth::{ width, }
}

///|
pub fn WireframeLineWidth::with_width(
  self : WireframeLineWidth,
  width : Float,
) -> WireframeLineWidth {
  self |> ignore
  WireframeLineWidth::{ width, }
}

///|
/// Controls whether wireframe edges follow triangle or quad topology.
pub(all) enum WireframeTopology {
  Triangles
  Quads
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn WireframeTopology::default() -> WireframeTopology {
  Triangles
}

///|
pub struct WireframeMaterial {
  color : @color.Color
  line_width : Float
  topology : WireframeTopology
} derive(ToJson, FromJson)

///|
pub fn WireframeMaterial::WireframeMaterial() -> WireframeMaterial {
  WireframeMaterial::{
    color: @color.Color::white(),
    line_width: 1.0F,
    topology: WireframeTopology::default(),
  }
}

///|
pub fn WireframeMaterial::new(
  color : @color.Color,
  line_width : Float,
  topology : WireframeTopology,
) -> WireframeMaterial {
  WireframeMaterial::{ color, line_width, topology }
}

///|
pub impl @asset.Asset for WireframeMaterial with fn asset_debug_name() {
  "mgstudio_pbr::WireframeMaterial"
}

///|
pub impl @asset.Asset for WireframeMaterial with fn asset_as_image(_self) {
  None
}

///|
let wireframe_material_asset_resource_keys : @asset.AssetResourceKeys[
  WireframeMaterial,
] = @asset.register_asset_resource_keys(WireframeMaterial::asset_debug_name())

///|
pub impl @asset.Asset for WireframeMaterial with fn asset_resource_keys() {
  wireframe_material_asset_resource_keys
}

///|
pub struct Mesh3dWireframe {
  material : @asset.Handle[WireframeMaterial]
} derive(ToJson, FromJson)

///|
pub fn Mesh3dWireframe::new(
  material : @asset.Handle[WireframeMaterial],
) -> Mesh3dWireframe {
  Mesh3dWireframe::{ material, }
}

///|
pub fn Mesh3dWireframe::material(
  self : Mesh3dWireframe,
) -> @asset.Handle[WireframeMaterial] {
  self.material
}

///|
pub struct RenderWireframeMaterial {
  color : @color.Color
  line_width : Float
  topology : WireframeTopology
} derive(ToJson, FromJson)

///|
pub fn RenderWireframeMaterial::from_material(
  material : WireframeMaterial,
) -> RenderWireframeMaterial {
  RenderWireframeMaterial::{
    color: material.color,
    line_width: material.line_width,
    topology: material.topology,
  }
}

///|
pub struct WireframeEntitiesNeedingSpecialization {
  changed : Array[@core.Entity]
  removed : Array[@core.Entity]
}

///|
pub fn WireframeEntitiesNeedingSpecialization::WireframeEntitiesNeedingSpecialization() -> WireframeEntitiesNeedingSpecialization {
  WireframeEntitiesNeedingSpecialization::{ changed: [], removed: [] }
}

///|
pub impl @app.Resource for WireframeEntitiesNeedingSpecialization with fn resource() {
  ecs_key_wireframe_entities_needing_specialization
}

///|
pub struct WireframeConfig {
  global : Bool
  default_color : @color.Color
  default_line_width : Float
  default_topology : WireframeTopology
} derive(ToJson, FromJson)

///|
pub fn WireframeConfig::WireframeConfig() -> WireframeConfig {
  WireframeConfig::{
    global: false,
    default_color: @color.Color::white(),
    default_line_width: 1.0F,
    default_topology: WireframeTopology::default(),
  }
}

///|
pub fn WireframeConfig::new(
  global : Bool,
  default_color : @color.Color,
  default_line_width? : Float = 1.0F,
  default_topology? : WireframeTopology = WireframeTopology::default(),
) -> WireframeConfig {
  WireframeConfig::{
    global,
    default_color,
    default_line_width,
    default_topology,
  }
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
  default_color : @color.Color,
) -> WireframeConfig {
  WireframeConfig::{ ..self, default_color, }
}

///|
pub fn WireframeConfig::with_default_line_width(
  self : WireframeConfig,
  default_line_width : Float,
) -> WireframeConfig {
  WireframeConfig::{ ..self, default_line_width, }
}

///|
pub fn WireframeConfig::with_default_topology(
  self : WireframeConfig,
  default_topology : WireframeTopology,
) -> WireframeConfig {
  WireframeConfig::{ ..self, default_topology, }
}

///|
pub impl @app.Resource for WireframeConfig with fn resource() {
  ecs_key_wireframe_config
}

///|
const WIREFRAME_PLUGIN_NAME : String = "mgstudio.pbr.WireframePlugin"

///|
pub struct WireframePlugin {}

///|
pub fn WireframePlugin::WireframePlugin() -> WireframePlugin {
  WireframePlugin::{  }
}

///|
pub impl @app.Plugin for WireframePlugin with fn name(_self) {
  WIREFRAME_PLUGIN_NAME
}

///|
pub impl @app.Plugin for WireframePlugin with fn build(_self, app) {
  wireframe_plugin(app)
}

///|
fn init_wireframe_resources(world : @ecs.World) -> Unit {
  let wireframe_config = get_wireframe_config_resource(world)
  if !wireframe_config.is_present() {
    wireframe_config.insert(WireframeConfig::WireframeConfig())
  }
  if world.get_resource(WireframeEntitiesNeedingSpecialization::resource())
    is None {
    world.insert_resource(
      WireframeEntitiesNeedingSpecialization::resource(),
      WireframeEntitiesNeedingSpecialization::WireframeEntitiesNeedingSpecialization(),
    )
  }
}

///|
pub fn wireframe_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  wireframe_plugin_with(app, WireframePlugin::WireframePlugin())
}

///|
pub fn wireframe_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : WireframePlugin,
) -> @app.App[@ecs.World] {
  @asset.init_asset(app, fn() { WireframeMaterial::WireframeMaterial() }).add_startup_system(
    init_wireframe_resources,
  )
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
impl @app.Resource for Render3dWireframeMeshCache with fn resource() {
  render3d_wireframe_mesh_cache_key
}

///|
fn render3d_wireframe_mesh_cache_mut_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[Render3dWireframeMeshCache] {
  if world.get_resource(Render3dWireframeMeshCache::resource()) is None {
    world.insert_resource(Render3dWireframeMeshCache::resource(), {
      entries: [],
    })
  }
  match world.get_resource_mut(Render3dWireframeMeshCache::resource()) {
    Some(cache) => cache
    None => abort("Missing Render3dWireframeMeshCache resource")
  }
}

///|
fn render3d_wireframe_mesh_cache_get(
  world : @ecs.World,
  source_mesh_handle_id : Int,
) -> Int? {
  let cache = render3d_wireframe_mesh_cache_mut_or_init(world)
  for item in cache.peek().entries {
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
  let cache = render3d_wireframe_mesh_cache_mut_or_init(world)
  let next : Array[WireframeMeshCacheEntry] = []
  let mut replaced = false
  for item in cache.peek().entries {
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
  cache.modify(fn(value) { value.entries = next })
}

///|
fn render3d_upload_wireframe_geometry(geometry : @mesh.Mesh3dGeometry) -> Int? {
  guard geometry.flatten_interleaved_xyz_normal_uv_rgba_joints_weights_vertices()
    is Some(vertices_double) else {
    return None
  }
  let vertices = vertices_double.map(fn(value) { Float::from_double(value) })
  let mesh_id = @render.host_gpu_create_mesh3d_xyznuvrgba(
    vertices_xyznuvrgba=vertices,
    primitive_topology=geometry.primitive_topology().to_int(),
  )
  if mesh_id <= 0 {
    None
  } else {
    Some(mesh_id)
  }
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
              guard render3d_upload_wireframe_geometry(wireframe_geometry)
                is Some(wireframe_mesh_id) else {
                return None
              }
              render3d_wireframe_mesh_cache_set(
                world, source_mesh_handle_id, wireframe_mesh_id,
              )
              Some(wireframe_mesh_id)
            }
            None => None
          }
        @mesh.Mesh3dPrimitiveTopology::LineList => {
          guard render3d_upload_wireframe_geometry(geometry3d) is Some(mesh_id) else {
            return None
          }
          render3d_wireframe_mesh_cache_set(
            world, source_mesh_handle_id, mesh_id,
          )
          Some(mesh_id)
        }
        @mesh.Mesh3dPrimitiveTopology::LineStrip => {
          guard render3d_upload_wireframe_geometry(geometry3d) is Some(mesh_id) else {
            return None
          }
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
) -> @color.Color {
  if mesh.payload.wireframe_color is Some(color_component) {
    color_component.color
  } else if wireframe_config is Some(config) {
    config.default_color
  } else {
    @color.Color::white()
  }
}

///|
fn render3d_mesh_wireframe_line_width(
  mesh : ExtractedMesh3d,
  wireframe_config : WireframeConfig?,
) -> Float {
  if mesh.payload.wireframe_line_width is Some(width_component) {
    width_component.width
  } else if wireframe_config is Some(config) {
    config.default_line_width
  } else {
    1.0F
  }
}

///|
fn render3d_mesh_wireframe_topology(
  mesh : ExtractedMesh3d,
  wireframe_config : WireframeConfig?,
) -> WireframeTopology {
  if mesh.payload.wireframe_topology is Some(topology) {
    topology
  } else if wireframe_config is Some(config) {
    config.default_topology
  } else {
    WireframeTopology::default()
  }
}
