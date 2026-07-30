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
type Color = @color.Color

///|
pub let ecs_key_wireframe2d : @ecs.ComponentKey[Wireframe2d] = @ecs.register_component(
  debug_name="sprite_render.mesh2d.wireframe2d",
)

///|
pub let ecs_key_no_wireframe2d : @ecs.ComponentKey[NoWireframe2d] = @ecs.register_component(
  debug_name="sprite_render.mesh2d.no_wireframe2d",
)

///|
pub let ecs_key_wireframe2d_color : @ecs.ComponentKey[Wireframe2dColor] = @ecs.register_component(
  debug_name="sprite_render.mesh2d.wireframe2d_color",
)

///|
pub let ecs_key_mesh2d_wireframe : @ecs.ComponentKey[Mesh2dWireframe] = @ecs.register_component(
  debug_name="sprite_render.mesh2d.mesh2d_wireframe",
)

///|
pub let ecs_key_wireframe2d_config : @ecs.ResourceKey[Wireframe2dConfig] = @ecs.register_resource(
  debug_name="sprite_render.mesh2d.wireframe2d_config",
)

///|
let ecs_key_global_wireframe_material : @ecs.ResourceKey[
  GlobalWireframeMaterial,
] = @ecs.register_resource(
  debug_name="sprite_render.mesh2d.global_wireframe_material",
)

///|
let ecs_key_wireframe_entities_needing_specialization : @ecs.ResourceKey[
  WireframeEntitiesNeedingSpecialization,
] = @ecs.register_resource(
  debug_name="sprite_render.mesh2d.wireframe_entities_needing_specialization",
)

///|
pub fn get_wireframe2d_config_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[Wireframe2dConfig] {
  world.resource(ecs_key_wireframe2d_config)
}

///|
/// Marker component aligned with Bevy's `Wireframe2d`.
///
/// Meshes with this marker render wireframes regardless of
/// `Wireframe2dConfig::global`.
pub struct Wireframe2d {}

///|
#warnings("-unnecessary_annotation")
pub fn Wireframe2d::Wireframe2d() -> Wireframe2d {
  Wireframe2d::{  }
}

///|
pub impl @ecs.Component for Wireframe2d with fn component() {
  ecs_key_wireframe2d
}

///|
/// Marker component aligned with Bevy's `NoWireframe2d`.
///
/// Meshes with this marker never render wireframes regardless of
/// `Wireframe2dConfig::global`.
pub struct NoWireframe2d {}

///|
#warnings("-unnecessary_annotation")
pub fn NoWireframe2d::NoWireframe2d() -> NoWireframe2d {
  NoWireframe2d::{  }
}

///|
pub impl @ecs.Component for NoWireframe2d with fn component() {
  ecs_key_no_wireframe2d
}

///|
/// Per-mesh wireframe color aligned with Bevy's `Wireframe2dColor`.
pub struct Wireframe2dColor {
  color : Color
}

///|
pub fn Wireframe2dColor::Wireframe2dColor() -> Wireframe2dColor {
  { color: Color::white() }
}

///|
pub fn Wireframe2dColor::new(color : Color) -> Wireframe2dColor {
  { color, }
}

///|
pub fn Wireframe2dColor::with_color(
  self : Wireframe2dColor,
  color : Color,
) -> Wireframe2dColor {
  self |> ignore
  { color, }
}

///|
pub impl @ecs.Component for Wireframe2dColor with fn component() {
  ecs_key_wireframe2d_color
}

///|
fn wireframe2d_encode_color(color : Color) -> Json {
  (color.r, color.g, color.b, color.a) |> ToJson::to_json
}

///|
fn wireframe2d_decode_color(json : Json) -> Color {
  let (r, g, b, a) : (Float, Float, Float, Float) = try! @json.from_json(json)
  Color::new(r, g, b, a)
}

///|
pub impl ToJson for Wireframe2d with fn to_json(self) {
  self |> ignore
  0 |> ToJson::to_json
}

///|
pub impl @json.FromJson for Wireframe2d with fn from_json(_json, _path) {
  Wireframe2d()
}

///|
pub impl ToJson for NoWireframe2d with fn to_json(self) {
  self |> ignore
  0 |> ToJson::to_json
}

///|
pub impl @json.FromJson for NoWireframe2d with fn from_json(_json, _path) {
  NoWireframe2d()
}

///|
pub impl ToJson for Wireframe2dColor with fn to_json(self) {
  wireframe2d_encode_color(self.color)
}

///|
pub impl @json.FromJson for Wireframe2dColor with fn from_json(json, _path) {
  Wireframe2dColor::new(wireframe2d_decode_color(json))
}

///|
pub struct Wireframe2dConfig {
  global : Bool
  default_color : Color
} derive(ToJson, FromJson)

///|
pub struct Wireframe2dMaterial {
  mut color : Color
}

///|
pub fn Wireframe2dMaterial::Wireframe2dMaterial() -> Wireframe2dMaterial {
  { color: Color::white() }
}

///|
pub fn Wireframe2dMaterial::new(color : Color) -> Wireframe2dMaterial {
  { color, }
}

///|
pub fn Wireframe2dMaterial::color(self : Wireframe2dMaterial) -> Color {
  self.color
}

///|
pub impl @asset.Asset for Wireframe2dMaterial with fn asset_debug_name() {
  "mgstudio_sprite_render::Wireframe2dMaterial"
}

///|
pub impl @asset.Asset for Wireframe2dMaterial with fn asset_as_image(_self) {
  None
}

///|
let wireframe2d_material_asset_resource_keys : @asset.AssetResourceKeys[
  Wireframe2dMaterial,
] = @asset.register_asset_resource_keys(Wireframe2dMaterial::asset_debug_name())

///|
pub impl @asset.Asset for Wireframe2dMaterial with fn asset_resource_keys() {
  wireframe2d_material_asset_resource_keys
}

///|
pub struct Mesh2dWireframe {
  handle : @asset.Handle[Wireframe2dMaterial]
}

///|
pub fn Mesh2dWireframe::new(
  handle : @asset.Handle[Wireframe2dMaterial],
) -> Mesh2dWireframe {
  { handle, }
}

///|
pub fn Mesh2dWireframe::handle(
  self : Mesh2dWireframe,
) -> @asset.Handle[Wireframe2dMaterial] {
  self.handle
}

///|
pub impl @ecs.Component for Mesh2dWireframe with fn component() {
  ecs_key_mesh2d_wireframe
}

///|
pub struct WireframeEntitiesNeedingSpecialization {
  changed : Array[@core.Entity]
  removed : Array[@core.Entity]
}

///|
pub fn WireframeEntitiesNeedingSpecialization::WireframeEntitiesNeedingSpecialization() -> WireframeEntitiesNeedingSpecialization {
  { changed: [], removed: [] }
}

///|
struct GlobalWireframeMaterial {
  handle : @asset.Handle[Wireframe2dMaterial]
}

///|
fn GlobalWireframeMaterial::new(
  handle : @asset.Handle[Wireframe2dMaterial],
) -> GlobalWireframeMaterial {
  { handle, }
}

///|
pub impl @app.Resource for GlobalWireframeMaterial with fn resource() {
  ecs_key_global_wireframe_material
}

///|
pub struct Wireframe2dPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn Wireframe2dPlugin::Wireframe2dPlugin() -> Wireframe2dPlugin {
  Wireframe2dPlugin::{  }
}

///|
pub impl @app.Plugin for Wireframe2dPlugin with fn name(_self) {
  "mgstudio.sprite_render.Wireframe2dPlugin"
}

///|
pub impl @app.Plugin for Wireframe2dPlugin with fn build(_self, app) {
  wireframe2d_plugin_install(app)
}

///|
pub fn Wireframe2dConfig::Wireframe2dConfig() -> Wireframe2dConfig {
  { global: false, default_color: Color::white() }
}

///|
pub fn Wireframe2dConfig::new(
  global : Bool,
  default_color : Color,
) -> Wireframe2dConfig {
  { global, default_color }
}

///|
pub fn Wireframe2dConfig::with_global(
  self : Wireframe2dConfig,
  global : Bool,
) -> Wireframe2dConfig {
  { ..self, global, }
}

///|
pub fn Wireframe2dConfig::with_default_color(
  self : Wireframe2dConfig,
  default_color : Color,
) -> Wireframe2dConfig {
  { ..self, default_color, }
}

///|
pub impl @app.Resource for Wireframe2dConfig with fn resource() {
  ecs_key_wireframe2d_config
}

///|
pub impl @app.Resource for WireframeEntitiesNeedingSpecialization with fn resource() {
  ecs_key_wireframe_entities_needing_specialization
}

///|
fn wireframe2d_material_assets_mut(
  world : @ecs.World,
) -> @ecs.ResourceMut[@asset.Assets[Wireframe2dMaterial]]? {
  let key : @ecs.ResourceKey[@asset.Assets[Wireframe2dMaterial]] = @asset.assets_resource_key()
  world.get_resource_mut(key)
}

///|
fn wireframe2d_material_assets(
  world : @ecs.World,
) -> @asset.Assets[Wireframe2dMaterial]? {
  let key : @ecs.ResourceKey[@asset.Assets[Wireframe2dMaterial]] = @asset.assets_resource_key()
  world.get_resource(key)
}

///|
fn setup_global_wireframe_material(world : @ecs.World) -> Unit {
  let wireframe_config = get_wireframe2d_config_resource(world)
  if !wireframe_config.is_present() {
    wireframe_config.insert(Wireframe2dConfig())
  }
  if world.get_resource(WireframeEntitiesNeedingSpecialization::resource())
    is None {
    world.insert_resource(
      WireframeEntitiesNeedingSpecialization::resource(),
      WireframeEntitiesNeedingSpecialization(),
    )
  }
  let config = wireframe_config.get().unwrap_or(Wireframe2dConfig())
  guard wireframe2d_material_assets_mut(world) is Some(materials) else {
    return
  }
  let handle = materials.modify(fn(assets) {
    assets.add(Wireframe2dMaterial::new(config.default_color))
  })
  world.insert_resource(
    GlobalWireframeMaterial::resource(),
    GlobalWireframeMaterial::new(handle),
  )
}

///|
fn get_wireframe_material(
  maybe_color : Wireframe2dColor?,
  materials : @asset.Assets[Wireframe2dMaterial],
  global_material : GlobalWireframeMaterial,
) -> @asset.Handle[Wireframe2dMaterial] {
  if maybe_color is Some(wireframe_color) {
    materials.add(Wireframe2dMaterial::new(wireframe_color.color))
  } else {
    global_material.handle
  }
}

///|
fn sync_global_wireframe_material(world : @ecs.World) -> Unit {
  guard get_wireframe2d_config_resource(world).get() is Some(config) else {
    return
  }
  guard world.get_resource(GlobalWireframeMaterial::resource())
    is Some(global_material) else {
    return
  }
  guard wireframe2d_material_assets_mut(world) is Some(materials) else {
    return
  }
  ignore(
    materials.modify(fn(assets) {
      guard assets.get_mut(global_material.handle) is Some(material) else {
        return false
      }
      material.color = config.default_color
      true
    }),
  )
}

///|
fn[T] wireframe2d_has_component(
  world : @ecs.World,
  entity : @core.Entity,
  key : @ecs.ComponentKey[T],
) -> Bool {
  (try! world.get_by_key(entity, key)) is Some(_)
}

///|
fn remove_mesh2d_wireframe_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  if wireframe2d_has_component(world, entity, ecs_key_mesh2d_wireframe) {
    try! (world.remove_by_key(entity, ecs_key_mesh2d_wireframe) |> ignore)
    if world.get_resource_mut(
        WireframeEntitiesNeedingSpecialization::resource(),
      )
      is Some(needs) {
      needs.modify(fn(value) { value.removed.push(entity) })
    }
  }
}

///|
fn set_mesh2d_wireframe_component(
  world : @ecs.World,
  entity : @core.Entity,
  handle : @asset.Handle[Wireframe2dMaterial],
) -> Unit {
  let next = Mesh2dWireframe::new(handle)
  let current_wireframe = try! world.get_by_key(
    entity, ecs_key_mesh2d_wireframe,
  )
  let changed = match current_wireframe {
    Some(current) => current.handle.id() != handle.id()
    None => true
  }
  try! (world.set_by_key(entity, ecs_key_mesh2d_wireframe, next) |> ignore)
  if changed {
    if world.get_resource_mut(
        WireframeEntitiesNeedingSpecialization::resource(),
      )
      is Some(needs) {
      needs.modify(fn(value) { value.changed.push(entity) })
    }
  }
}

///|
fn apply_wireframe_material(world : @ecs.World) -> Unit {
  guard world.get_resource(GlobalWireframeMaterial::resource())
    is Some(global_material) else {
    return
  }
  guard wireframe2d_material_assets_mut(world) is Some(materials_ref) else {
    return
  }
  let material_key = ecs_key_mesh2d_wireframe
  let query : @ecs.Query[@ecs.Read[Wireframe2d], @ecs.All] = @ecs.query(world)
  let no_wireframe_entities : Array[@core.Entity] = []
  world.for_each_component(ecs_key_no_wireframe2d, fn(entity, _value) {
    no_wireframe_entities.push(entity)
  })
  for entity in no_wireframe_entities {
    remove_mesh2d_wireframe_component(world, entity)
  }
  let material_to_spawn : Array[
    (@core.Entity, @asset.Handle[Wireframe2dMaterial]),
  ] = []
  try! query.view(fn(entity, _wireframe) {
    let maybe_color = try! world.get_by_key(entity, ecs_key_wireframe2d_color)
    let handle = materials_ref.modify(fn(materials) {
      get_wireframe_material(maybe_color, materials, global_material)
    })
    material_to_spawn.push((entity, handle))
  })
  for item in material_to_spawn {
    let (entity, handle) = item
    set_mesh2d_wireframe_component(world, entity, handle)
  }
  world.for_each_component(material_key, fn(entity, _value) {
    if !wireframe2d_has_component(world, entity, ecs_key_wireframe2d) &&
      !wireframe2d_has_component(world, entity, @mesh.ecs_key_mesh2d) {
      remove_mesh2d_wireframe_component(world, entity)
    }
  })
}

///|
fn apply_global_wireframe_material(world : @ecs.World) -> Unit {
  guard get_wireframe2d_config_resource(world).get() is Some(config) else {
    return
  }
  guard world.get_resource(GlobalWireframeMaterial::resource())
    is Some(global_material) else {
    return
  }
  guard wireframe2d_material_assets_mut(world) is Some(materials_ref) else {
    return
  }
  let mesh_entities : Array[@core.Entity] = []
  world.for_each_component(@mesh.ecs_key_mesh2d, fn(entity, _mesh) {
    mesh_entities.push(entity)
  })
  for entity in mesh_entities {
    if wireframe2d_has_component(world, entity, ecs_key_wireframe2d) ||
      wireframe2d_has_component(world, entity, ecs_key_no_wireframe2d) {
      continue
    }
    if config.global {
      let maybe_color = try! world.get_by_key(entity, ecs_key_wireframe2d_color)
      let handle = materials_ref.modify(fn(materials) {
        get_wireframe_material(maybe_color, materials, global_material)
      })
      set_mesh2d_wireframe_component(world, entity, handle)
    } else {
      remove_mesh2d_wireframe_component(world, entity)
    }
  }
}

///|
fn wireframe2d_plugin_install(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  @asset.init_asset(app, fn() { Wireframe2dMaterial::Wireframe2dMaterial() })
  .add_startup_system(setup_global_wireframe_material)
  .add_systems(
    Update,
    (
      @app.system(sync_global_wireframe_material),
      @app.system(apply_wireframe_material),
      @app.system(apply_global_wireframe_material),
    )
    |> @app.chain(),
  )
}

///|
pub fn wireframe2d_material_color(
  world : @ecs.World,
  wireframe : Mesh2dWireframe,
) -> Color {
  match wireframe2d_material_assets(world) {
    Some(materials) =>
      match materials.get(wireframe.handle) {
        Some(material) => material.color
        None => Color::white()
      }
    None => Color::white()
  }
}
