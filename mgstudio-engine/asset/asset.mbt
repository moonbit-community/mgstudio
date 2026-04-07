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
pub struct Handle[T] {
  id : Int
  phantom : T?
}

///|
pub struct AssetId[T] {
  id : Int
  phantom : T?
} derive(Eq, Show)

///|
pub fn[T] AssetId::new(id : Int) -> AssetId[T] {
  AssetId::{ id, phantom: None }
}

///|
pub fn[T] AssetId::index(self : AssetId[T]) -> Int {
  self.id
}

///|
pub fn[T] Handle::new(id : Int) -> Handle[T] {
  Handle::{ id, phantom: None }
}

///|
pub impl[T] ToJson for Handle[T] with to_json(self) {
  self.id.to_json()
}

///|
pub impl[T] @json.FromJson for Handle[T] with from_json(json, path) {
  let id : Int = @json.from_json(json, path~)
  Handle::new(id)
}

///|
pub fn[T] Handle::id(self : Handle[T]) -> Int {
  self.id
}

///|
pub fn[T] Handle::asset_id(self : Handle[T]) -> AssetId[T] {
  AssetId::new(self.id)
}

///|
pub fn[T] Handle::from_asset_id(asset_id : AssetId[T]) -> Handle[T] {
  Handle::new(asset_id.index())
}

///|
pub type Image = @image.Image

///|
pub type TextureFormat = @image.TextureFormat

///|
pub type ImageKind = @image.ImageKind

///|
pub type ImageArrayLayout = @image.ImageArrayLayout

///|
pub type ImageAddressMode = @image.ImageAddressMode

///|
pub type ImageCompareFunction = @image.ImageCompareFunction

///|
pub type ImageFilterMode = @image.ImageFilterMode

///|
pub type ImageSampler = @image.ImageSampler

///|
pub type ImageSamplerBorderColor = @image.ImageSamplerBorderColor

///|
pub type ImageSamplerDescriptor = @image.ImageSamplerDescriptor

///|
pub impl @image.TextureHandle for Handle[Image] with texture_id(self) {
  self.id()
}

///|
pub struct Blob {}

///|
pub struct AssetServer {
  paths : Ref[Array[String]]
  path_fingerprints : Ref[@hashmap.HashMap[String, Int]]
  typed_asset_paths : Ref[@hashmap.HashMap[String, Int]]
  pending_processed_asset_loads : Ref[Array[PendingProcessedAssetLoad]]
  pending_typed_asset_loads : Ref[Array[PendingTypedAssetLoad]]
  pending_acquired_loads : Ref[Array[PendingAcquiredLoad]]
  image_paths : Ref[Array[(String, Handle[Image])]]
  image_loaded_states : Ref[@hashmap.HashMap[Int, Bool]]
  pending_image_assets : Ref[@hashmap.HashMap[Int, Image]]
  image_array_layouts : Ref[Array[(Int, ImageArrayLayout)]]
  image_render_asset_usages : Ref[Array[(Int, RenderAssetUsages)]]
  image_srgb_settings : Ref[Array[(Int, Bool)]]
  image_usage_settings : Ref[Array[(Int, Int)]]
  gltf_mesh_asset_usages : Ref[Array[(String, RenderAssetUsages)]]
  default_sampler_nearest : Ref[Bool]
  mode : Ref[AssetMode]
  processed_file_path : Ref[String?]
}

///|
type AssetReadyCheck = (@ecs.World, Int) -> Bool

///|
type AssetLoadRelease = () -> Unit

///|
struct PendingAcquiredLoad {
  handle_id : Int
  is_ready : AssetReadyCheck
  release : AssetLoadRelease
}

///|
struct PendingTypedAssetLoad {
  type_name : String
  handle_id : Int
  path : AssetPath
}

///|
pub const ASSET_PLUGIN_ID : String = "bevy_asset::AssetPlugin"

///|
pub(all) struct AssetPlugin {
  default_sampler_nearest : Bool
  mode : AssetMode
  file_path : String?
  processed_file_path : String?
}

///|
pub struct AssetReader {
  read_fn : (String) -> Bytes?
  read_meta_fn : (String) -> Bytes?
  read_directory_fn : (String) -> Array[String]?
  is_directory_fn : (String) -> Bool
}

///|
pub struct AssetSourceBuilder {
  path : String
  reader_builder : ((AssetReader) -> AssetReader)?
}

///|
pub struct RenderAssetUsages {
  bits : Int
} derive(Eq, Show)

///|
const RENDER_ASSET_USAGE_MAIN_WORLD_BIT : Int = 1

///|
const RENDER_ASSET_USAGE_RENDER_WORLD_BIT : Int = 2

///|
pub fn RenderAssetUsages::main_world() -> RenderAssetUsages {
  RenderAssetUsages::{ bits: RENDER_ASSET_USAGE_MAIN_WORLD_BIT }
}

///|
pub fn RenderAssetUsages::render_world() -> RenderAssetUsages {
  RenderAssetUsages::{ bits: RENDER_ASSET_USAGE_RENDER_WORLD_BIT }
}

///|
pub fn RenderAssetUsages::all() -> RenderAssetUsages {
  RenderAssetUsages::{
    bits: RENDER_ASSET_USAGE_MAIN_WORLD_BIT |
    RENDER_ASSET_USAGE_RENDER_WORLD_BIT,
  }
}

///|
pub fn RenderAssetUsages::contains(
  self : RenderAssetUsages,
  other : RenderAssetUsages,
) -> Bool {
  let lhs = self.bits.reinterpret_as_uint()
  let rhs = other.bits.reinterpret_as_uint()
  (lhs & rhs) == rhs
}

///|
pub fn AssetPlugin::default() -> AssetPlugin {
  AssetPlugin::{
    default_sampler_nearest: false,
    mode: AssetMode::Unprocessed,
    file_path: None,
    processed_file_path: None,
  }
}

///|
pub fn AssetReader::new(
  read : (String) -> Bytes?,
  read_meta : (String) -> Bytes?,
  read_directory : (String) -> Array[String]?,
  is_directory : (String) -> Bool,
) -> AssetReader {
  AssetReader::{
    read_fn: read,
    read_meta_fn: read_meta,
    read_directory_fn: read_directory,
    is_directory_fn: is_directory,
  }
}

///|
pub fn AssetReader::read(self : AssetReader, path : String) -> Bytes? {
  (self.read_fn)(path)
}

///|
pub fn AssetReader::read_meta(self : AssetReader, path : String) -> Bytes? {
  (self.read_meta_fn)(path)
}

///|
pub fn AssetReader::read_directory(
  self : AssetReader,
  path : String,
) -> Array[String]? {
  (self.read_directory_fn)(path)
}

///|
pub fn AssetReader::is_directory(self : AssetReader, path : String) -> Bool {
  (self.is_directory_fn)(path)
}

///|
pub fn AssetSourceBuilder::platform_default(
  path : String,
  _watcher : Unit?,
) -> AssetSourceBuilder {
  AssetSourceBuilder::{ path, reader_builder: None }
}

///|
pub fn AssetSourceBuilder::with_reader(
  self : AssetSourceBuilder,
  reader_builder : (AssetReader) -> AssetReader,
) -> AssetSourceBuilder {
  AssetSourceBuilder::{ path: self.path, reader_builder: Some(reader_builder) }
}

///|
pub fn AssetPlugin::default_nearest() -> AssetPlugin {
  AssetPlugin::{
    default_sampler_nearest: true,
    mode: AssetMode::Unprocessed,
    file_path: None,
    processed_file_path: None,
  }
}

///|
pub fn AssetPlugin::with_default_sampler_nearest(
  self : AssetPlugin,
  enabled : Bool,
) -> AssetPlugin {
  AssetPlugin::{
    default_sampler_nearest: enabled,
    mode: self.mode,
    file_path: self.file_path,
    processed_file_path: self.processed_file_path,
  }
}

///|
pub fn AssetPlugin::with_mode(
  self : AssetPlugin,
  mode : AssetMode,
) -> AssetPlugin {
  AssetPlugin::{ ..self, mode, }
}

///|
pub fn AssetPlugin::with_file_path(
  self : AssetPlugin,
  file_path : String,
) -> AssetPlugin {
  AssetPlugin::{
    default_sampler_nearest: self.default_sampler_nearest,
    mode: self.mode,
    file_path: Some(file_path),
    processed_file_path: self.processed_file_path,
  }
}

///|
pub fn AssetPlugin::with_processed_file_path(
  self : AssetPlugin,
  processed_file_path : String,
) -> AssetPlugin {
  AssetPlugin::{ ..self, processed_file_path: Some(processed_file_path) }
}

///|
fn asset_register_source_builder(
  source_id : AssetSourceId,
  builder : AssetSourceBuilder,
) -> Unit {
  let next : Array[(AssetSourceId, AssetSourceBuilder)] = []
  let mut replaced = false
  for entry in asset_source_builder_registry.val {
    if entry.0 == source_id {
      next.push((source_id, builder))
      replaced = true
    } else {
      next.push(entry)
    }
  }
  if !replaced {
    next.push((source_id, builder))
  }
  asset_source_builder_registry.val = next
}

///|
fn asset_registered_source_dir_entries() -> Array[(String, String)] {
  let entries : Array[(String, String)] = []
  for entry in asset_source_builder_registry.val {
    if entry.0 is AssetSourceId::Named(source_name) {
      if resolve_assets_dir_override(Some(entry.1.path)) is Some(resolved) {
        entries.push((source_name, resolved))
      }
    }
  }
  entries
}

///|
fn asset_registered_source_reader_entries() -> Array[
  (AssetSourceId, AssetSourceBuilder),
] {
  let entries : Array[(AssetSourceId, AssetSourceBuilder)] = []
  for entry in asset_source_builder_registry.val {
    if entry.1.reader_builder is Some(_) {
      entries.push(entry)
    }
  }
  entries
}

///|
pub fn register_asset_source(
  app : @app.App[@ecs.World],
  source_id : AssetSourceId,
  builder : AssetSourceBuilder,
) -> @app.App[@ecs.World] {
  asset_register_source_builder(source_id, builder)
  app
}

///|
pub fn[P : IntoAssetPath] embedded_asset(
  app : @app.App[@ecs.World],
  asset_path : P,
  source_path : String,
) -> @app.App[@ecs.World] {
  register_embedded_asset_bytes(
    asset_path_string(asset_path),
    load_asset_file_bytes(source_path),
  )
  app
}

///|
priv struct AssetLoaderEntry {
  load : (AssetServer, String) -> @any.Any
}

///|
pub(all) struct ImageLoaderSettings {
  mut sampler : ImageSampler
  mut is_srgb : Bool
  mut array_layout : ImageArrayLayout?
  mut asset_usage : RenderAssetUsages
  mut load_meshes : RenderAssetUsages
}

///|
pub fn ImageLoaderSettings::default() -> ImageLoaderSettings {
  ImageLoaderSettings::{
    sampler: ImageSampler::Default,
    is_srgb: true,
    array_layout: None,
    asset_usage: RenderAssetUsages::all(),
    load_meshes: RenderAssetUsages::all(),
  }
}

///|
fn asset_server_standalone() -> AssetServer {
  AssetServer::{
    paths: Ref::new([]),
    path_fingerprints: Ref::new(@hashmap.HashMap::new()),
    typed_asset_paths: Ref::new(@hashmap.HashMap::new()),
    pending_processed_asset_loads: Ref::new([]),
    pending_typed_asset_loads: Ref::new([]),
    pending_acquired_loads: Ref::new([]),
    image_paths: Ref::new([]),
    image_loaded_states: Ref::new(@hashmap.HashMap::new()),
    pending_image_assets: Ref::new(@hashmap.HashMap::new()),
    image_array_layouts: Ref::new([]),
    image_render_asset_usages: Ref::new([]),
    image_srgb_settings: Ref::new([]),
    image_usage_settings: Ref::new([]),
    gltf_mesh_asset_usages: Ref::new([]),
    default_sampler_nearest: Ref::new(false),
    mode: Ref::new(AssetMode::Unprocessed),
    processed_file_path: Ref::new(None),
  }
}

///|
let asset_loader_registry : Ref[@hashmap.HashMap[String, AssetLoaderEntry]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
let asset_builtin_loaders_registered : Ref[Bool] = Ref::new(false)

///|
let asset_source_builder_registry : Ref[
  Array[(AssetSourceId, AssetSourceBuilder)],
] = Ref::new([])

///|
type AssetReloadHook = (@ecs.World, AssetServer, String) -> Unit

///|
let asset_reload_hook_registry : Array[AssetReloadHook] = []

///|
let asset_ready_checker_registry : Ref[
  @hashmap.HashMap[String, AssetReadyCheck],
] = Ref::new(@hashmap.HashMap::new())

///|
fn[T] asset_loader_type_name(probe : Handle[T]) -> String {
  @any.of(probe).type_name()
}

///|
pub fn asset_register_reload_hook(
  hook : (@ecs.World, AssetServer, String) -> Unit,
) -> Unit {
  asset_reload_hook_registry.push(hook)
}

///|
pub fn[T] asset_register_loader(
  load : (AssetServer, String) -> Handle[T],
) -> Unit {
  let probe : Handle[T] = Handle::new(0)
  let type_name = asset_loader_type_name(probe)
  asset_loader_registry.val.set(type_name, AssetLoaderEntry::{
    load: fn(asset_server, path) { @any.of(load(asset_server, path)) },
  })
}

///|
pub fn[T] asset_register_ready_checker(
  check_ready : (@ecs.World, Handle[T]) -> Bool,
) -> Unit {
  let probe : Handle[T] = Handle::new(0)
  let type_name = asset_loader_type_name(probe)
  asset_ready_checker_registry.val.set(type_name, fn(world, handle_id) {
    check_ready(world, Handle::new(handle_id))
  })
}

///|
fn[T] asset_registered_ready_check(_probe : Handle[T]) -> AssetReadyCheck {
  let probe : Handle[T] = Handle::new(0)
  let type_name = asset_loader_type_name(probe)
  match asset_ready_checker_registry.val.get(type_name) {
    Some(check_ready) => check_ready
    None => {
      let key : @ecs.ResourceKey[Assets[T]] = assets_resource_key()
      fn(world, handle_id) {
        match (try! world.get_resource(key)) {
          Some(assets) => assets.contains(Handle::new(handle_id))
          None => false
        }
      }
    }
  }
}

///|
fn asset_register_builtin_loaders() -> Unit {
  if asset_builtin_loaders_registered.val {
    return
  }
  asset_builtin_loaders_registered.val = true
  asset_register_loader(fn(asset_server, path) { asset_server.load_image(path) })
  asset_register_loader(fn(asset_server, path) { asset_server.load_bytes(path) })
  asset_register_loader(fn(asset_server, path) { asset_server.load_font(path) })
  asset_register_loader(fn(asset_server, path) {
    asset_server.load_folder(path)
  })
}

///|
pub fn asset_server_resource_key() -> @ecs.ResourceKey[AssetServer] {
  @ecs.register_resource(debug_name="bevy_asset::AssetServer")
}

///|
pub impl @app.Resource for AssetServer with resource() {
  asset_server_resource_key()
}

///|
let asset_world_override_ref : Ref[@ecs.World?] = Ref::new(None)

///|
fn asset_current_world() -> @ecs.World? {
  match asset_world_override_ref.val {
    Some(world) => Some(world)
    None => @app.current_world()
  }
}

///|
pub fn[T] asset_with_world(world : @ecs.World, f : () -> T) -> T {
  let previous = asset_world_override_ref.val
  asset_world_override_ref.val = Some(world)
  let result = f()
  asset_world_override_ref.val = previous
  result
}

///|
fn asset_server_from_active_world() -> AssetServer? {
  match asset_current_world() {
    Some(world) => try! world.get_resource(asset_server_resource_key())
    None => None
  }
}

///|
fn asset_server_or_abort() -> AssetServer {
  match asset_server_from_active_world() {
    Some(server) => server
    None =>
      abort(
        "asset helper functions require an active app world; use a world-owned AssetServer resource or keep a local AssetServer handle",
      )
  }
}

///|
fn asset_world_or_abort() -> @ecs.World {
  match asset_current_world() {
    Some(world) => world
    None =>
      abort(
        "asset helper functions require an active app world; query world-owned asset resources explicitly outside scheduled systems",
      )
  }
}

///|
pub fn[T : @app.Resource] asset_resource_or_abort() -> T {
  let world = asset_world_or_abort()
  match (try! world.get_resource(T::resource())) {
    Some(value) => value
    None =>
      abort(
        "Missing asset-related resource \{T::resource().debug_name()} in the active world",
      )
  }
}

///|
pub fn[T : @app.Resource] asset_resource_ref_or_abort() -> Ref[T] {
  let world = asset_world_or_abort()
  match (try! world.get_resource_ref(T::resource())) {
    Some(value) => value
    None =>
      abort(
        "Missing asset-related resource \{T::resource().debug_name()} in the active world",
      )
  }
}

///|
pub fn[T : @app.Resource] asset_resource_ref_mut_or_abort() -> Ref[T] {
  let world = asset_world_or_abort()
  match (try! world.get_resource_ref_mut(T::resource())) {
    Some(value) => value
    None =>
      abort(
        "Missing asset-related resource \{T::resource().debug_name()} in the active world",
      )
  }
}

///|
pub fn[T] asset_assets_or_abort() -> Assets[T] {
  asset_resource_or_abort()
}

///|
pub fn[T] asset_assets_ref_or_abort() -> Ref[Assets[T]] {
  asset_resource_ref_or_abort()
}

///|
pub fn[T] asset_assets_ref_mut_or_abort() -> Ref[Assets[T]] {
  asset_resource_ref_mut_or_abort()
}

///|
pub fn AssetServer::new() -> AssetServer {
  asset_register_builtin_loaders()
  match asset_server_from_active_world() {
    Some(server) => server
    None => asset_server_standalone()
  }
}

///|
pub(all) enum AssetSourceId {
  Default
  Named(String)
} derive(Eq, Hash, Show)

///|
pub(all) suberror ParseAssetPathError {
  InvalidSourceSyntax
  InvalidLabelSyntax
  MissingSource
  MissingLabel
}

///|
pub struct AssetPath {
  source : AssetSourceId
  path : String
  label : String?
} derive(Eq, Hash, Show)

///|
pub type ParsedAssetPath = AssetPath

///|
pub(open) trait IntoAssetPath {
  into_asset_path(self : Self) -> AssetPath
}

///|
pub(open) trait AssetLoadGuard {
  release(self : Self) -> Unit
}

///|
pub(all) enum AssetLoaderKind {
  Texture
  Wgsl
  Bytes
  Font
  Folder
}

///|
const NATIVE_LOADER_KIND_TEXTURE : Int = 0

///|
const NATIVE_LOADER_KIND_WGSL : Int = 1

///|
const NATIVE_LOADER_KIND_BYTES : Int = 2

///|
const NATIVE_LOADER_KIND_FONT : Int = 3

///|
const NATIVE_LOADER_KIND_FOLDER : Int = 4

///|
fn string_last_index_of_char(input : String, code_unit : Int) -> Int {
  let mut out = -1
  for i in 0..<input.length() {
    if input.code_unit_at(i).to_int() == code_unit {
      out = i
    }
  }
  out
}

///|
fn string_find_substring(input : String, pattern : String) -> Int {
  let n = input.length()
  let m = pattern.length()
  if m <= 0 {
    return 0
  }
  if n < m {
    return -1
  }
  for i in 0..<(n - m + 1) {
    let mut matched = true
    for j in 0..<m {
      if input.code_unit_at(i + j) != pattern.code_unit_at(j) {
        matched = false
        break
      }
    }
    if matched {
      return i
    }
  }
  -1
}

///|
fn asset_parse_path_error_message(error : ParseAssetPathError) -> String {
  match error {
    ParseAssetPathError::InvalidSourceSyntax =>
      "asset source must not contain `#`"
    ParseAssetPathError::InvalidLabelSyntax =>
      "asset label must not contain `://`"
    ParseAssetPathError::MissingSource =>
      "asset source must contain at least one character before `://`"
    ParseAssetPathError::MissingLabel =>
      "asset label must contain at least one character after `#`"
  }
}

///|
pub fn asset_try_parse_path(
  path : String,
) -> AssetPath raise ParseAssetPathError {
  let hash_index = string_last_index_of_char(path, 35)
  let scheme_index = string_find_substring(path, "://")
  if hash_index >= 0 && scheme_index > hash_index {
    raise ParseAssetPathError::InvalidSourceSyntax
  }
  let (without_label, label) = if hash_index >= 0 {
    if hash_index + 1 >= path.length() {
      raise ParseAssetPathError::MissingLabel
    }
    let base = if hash_index > 0 { path[0:hash_index].to_string() } else { "" }
    let parsed_label = path[hash_index + 1:path.length()].to_string()
    if string_find_substring(parsed_label, "://") >= 0 {
      raise ParseAssetPathError::InvalidLabelSyntax
    }
    (base, Some(parsed_label))
  } else {
    (path, None)
  }

  if scheme_index == 0 {
    raise ParseAssetPathError::MissingSource
  }

  let source_scheme_index = string_find_substring(without_label, "://")
  if source_scheme_index == 0 {
    raise ParseAssetPathError::MissingSource
  }

  if string_last_index_of_char(without_label, 35) >= 0 {
    raise ParseAssetPathError::InvalidSourceSyntax
  }

  if source_scheme_index > 0 {
    let source_name = without_label[0:source_scheme_index].to_string()
    let relative_path = if source_scheme_index + 3 < without_label.length() {
      without_label[source_scheme_index + 3:without_label.length()].to_string()
    } else {
      ""
    }
    AssetPath::{
      source: AssetSourceId::Named(source_name),
      path: relative_path,
      label,
    }
  } else {
    AssetPath::{ source: AssetSourceId::Default, path: without_label, label }
  }
}

///|
pub fn asset_parse_path(path : String) -> AssetPath {
  asset_try_parse_path(path) catch {
    error =>
      abort(
        "invalid asset path syntax: \{asset_parse_path_error_message(error)}",
      )
  }
}

///|
pub fn asset_format_path(parsed : AssetPath) -> String {
  let base = match parsed.source {
    AssetSourceId::Default => parsed.path
    AssetSourceId::Named(name) => "\{name}://\{parsed.path}"
  }
  match parsed.label {
    Some(label) if label.length() > 0 => "\{base}#\{label}"
    _ => base
  }
}

///|
pub fn AssetSourceId::from(name : String) -> AssetSourceId {
  if name == "" {
    AssetSourceId::Default
  } else {
    AssetSourceId::Named(name)
  }
}

///|
pub fn AssetPath::from_path(path : String) -> AssetPath {
  AssetPath::{ source: AssetSourceId::Default, path, label: None }
}

///|
pub fn AssetPath::with_source(
  self : AssetPath,
  source : AssetSourceId,
) -> AssetPath {
  AssetPath::{ source, path: self.path, label: self.label }
}

///|
pub fn AssetPath::with_label(self : AssetPath, label : String?) -> AssetPath {
  AssetPath::{ source: self.source, path: self.path, label }
}

///|
pub impl IntoAssetPath for String with into_asset_path(self) {
  asset_parse_path(self)
}

///|
pub impl IntoAssetPath for AssetPath with into_asset_path(self) {
  self
}

///|
fn[P : IntoAssetPath] asset_path_string(path : P) -> String {
  asset_format_path(path.into_asset_path())
}

///|
pub fn asset_strip_label(path : String) -> String {
  let parsed = asset_parse_path(path)
  asset_format_path(AssetPath::{
    source: parsed.source,
    path: parsed.path,
    label: None,
  })
}

///|
fn asset_loader_kind_to_raw(kind : AssetLoaderKind) -> Int {
  match kind {
    AssetLoaderKind::Texture => NATIVE_LOADER_KIND_TEXTURE
    AssetLoaderKind::Wgsl => NATIVE_LOADER_KIND_WGSL
    AssetLoaderKind::Bytes => NATIVE_LOADER_KIND_BYTES
    AssetLoaderKind::Font => NATIVE_LOADER_KIND_FONT
    AssetLoaderKind::Folder => NATIVE_LOADER_KIND_FOLDER
  }
}

///|
fn asset_loader_kind_from_raw(raw : Int) -> AssetLoaderKind {
  if raw == NATIVE_LOADER_KIND_TEXTURE {
    return AssetLoaderKind::Texture
  }
  if raw == NATIVE_LOADER_KIND_WGSL {
    return AssetLoaderKind::Wgsl
  }
  if raw == NATIVE_LOADER_KIND_FONT {
    return AssetLoaderKind::Font
  }
  if raw == NATIVE_LOADER_KIND_FOLDER {
    return AssetLoaderKind::Folder
  }
  AssetLoaderKind::Bytes
}

///|
pub const COMPRESSED_IMAGE_FORMAT_NONE : Int = 0

///|
pub const COMPRESSED_IMAGE_FORMAT_ASTC_LDR : Int = 1

///|
pub const COMPRESSED_IMAGE_FORMAT_BC : Int = 2

///|
pub const COMPRESSED_IMAGE_FORMAT_ETC2 : Int = 4

///|
pub const IMAGE_USAGE_TEXTURE_BINDING : Int = 1

///|
pub const IMAGE_USAGE_COPY_DST : Int = 2

///|
pub const IMAGE_USAGE_COPY_SRC : Int = 4

///|
pub const IMAGE_USAGE_RENDER_ATTACHMENT : Int = 8

///|
const IMAGE_USAGE_ALL_MASK : Int = 15

///|
const IMAGE_USAGE_DEFAULT_SAMPLED : Int = 3

///|
const IMAGE_USAGE_DEFAULT_DYNAMIC : Int = 15

///|
fn string_contains(input : String, pattern : String) -> Bool {
  string_find_substring(input, pattern) >= 0
}

///|
fn bytes_to_text(bytes : Bytes) -> String {
  let chars : Array[Char] = []
  for byte in bytes {
    let code = byte.to_int() & 0xFF
    if code.to_char() is Some(ch) {
      chars.push(ch)
    } else {
      chars.push(Int::unsafe_to_char(0xFFFD))
    }
  }
  String::from_array(chars)
}

///|
fn load_optional_asset_text(path : String) -> String? {
  if path.length() >= 5 &&
    path[path.length() - 5:path.length()].to_string() == ".meta" {
    let base_path = path[0:path.length() - 5].to_string()
    if load_asset_meta_bytes(base_path) is Some(bytes) {
      return Some(bytes_to_text(bytes))
    }
    return None
  }
  let bytes = load_asset_file_bytes(path)
  if bytes.length() > 0 {
    return Some(bytes_to_text(bytes))
  }
  None
}

///|
pub fn[P : IntoAssetPath] load_asset_source_bytes(path : P) -> Bytes {
  let parsed = path.into_asset_path()
  load_asset_file_bytes(asset_canonical_path(asset_format_path(parsed)))
}

///|
pub fn[P : IntoAssetPath] load_optional_asset_source_text(path : P) -> String? {
  let parsed = path.into_asset_path()
  load_optional_asset_text(asset_canonical_path(asset_format_path(parsed)))
}

///|
fn meta_image_filter_mode(
  content : String,
  field_name : String,
) -> ImageFilterMode? {
  if string_contains(content, "\{field_name}: Nearest") {
    return Some(ImageFilterMode::Nearest)
  }
  if string_contains(content, "\{field_name}: Linear") {
    return Some(ImageFilterMode::Linear)
  }
  None
}

///|
fn meta_image_address_mode(
  content : String,
  field_name : String,
) -> ImageAddressMode? {
  if string_contains(content, "\{field_name}: ClampToEdge") {
    return Some(ImageAddressMode::ClampToEdge)
  }
  if string_contains(content, "\{field_name}: Repeat") {
    return Some(ImageAddressMode::Repeat)
  }
  if string_contains(content, "\{field_name}: MirrorRepeat") {
    return Some(ImageAddressMode::MirrorRepeat)
  }
  if string_contains(content, "\{field_name}: ClampToBorder") {
    return Some(ImageAddressMode::ClampToBorder)
  }
  None
}

///|
fn meta_render_asset_usages(content : String) -> RenderAssetUsages? {
  guard string_contains(content, "asset_usage: RenderAssetUsages(") else {
    return None
  }
  let has_main_world = string_contains(content, "MAIN_WORLD")
  let has_render_world = string_contains(content, "RENDER_WORLD")
  if has_main_world && has_render_world {
    return Some(RenderAssetUsages::all())
  }
  if has_main_world {
    return Some(RenderAssetUsages::main_world())
  }
  if has_render_world {
    return Some(RenderAssetUsages::render_world())
  }
  None
}

///|
fn image_meta_path(path : String) -> String {
  "\{path}.meta"
}

///|
fn apply_image_meta_settings(
  settings : ImageLoaderSettings,
  content : String,
) -> Unit {
  if string_contains(content, "is_srgb: false") {
    settings.is_srgb = false
  } else if string_contains(content, "is_srgb: true") {
    settings.is_srgb = true
  }
  if meta_render_asset_usages(content) is Some(asset_usage) {
    settings.asset_usage = asset_usage
  }

  let address_mode_u = meta_image_address_mode(content, "address_mode_u")
  let address_mode_v = meta_image_address_mode(content, "address_mode_v")
  let address_mode_w = meta_image_address_mode(content, "address_mode_w")
  let mag_filter = meta_image_filter_mode(content, "mag_filter")
  let min_filter = meta_image_filter_mode(content, "min_filter")
  let mipmap_filter = meta_image_filter_mode(content, "mipmap_filter")
  let has_descriptor = address_mode_u is Some(_) ||
    address_mode_v is Some(_) ||
    address_mode_w is Some(_) ||
    mag_filter is Some(_) ||
    min_filter is Some(_) ||
    mipmap_filter is Some(_)
  if !has_descriptor {
    return
  }

  let descriptor = ImageSamplerDescriptor::default()
  if address_mode_u is Some(value) {
    descriptor.address_mode_u = value
  }
  if address_mode_v is Some(value) {
    descriptor.address_mode_v = value
  }
  if address_mode_w is Some(value) {
    descriptor.address_mode_w = value
  }
  if mag_filter is Some(value) {
    descriptor.mag_filter = value
  }
  if min_filter is Some(value) {
    descriptor.min_filter = value
  }
  if mipmap_filter is Some(value) {
    descriptor.mipmap_filter = value
  }
  settings.sampler = ImageSampler::Descriptor(descriptor)
}

///|
pub fn asset_canonical_path(path : String) -> String {
  asset_strip_label(path)
}

///|
fn AssetServer::record_path(self : AssetServer, path : String) -> Unit {
  let canonical_path = asset_canonical_path(path)
  for existing_path in self.paths.val {
    if existing_path == canonical_path {
      return
    }
  }
  self.paths.val.push(canonical_path)
  self.path_fingerprints.val.set(
    canonical_path,
    bytes_fingerprint(load_asset_file_bytes(canonical_path)),
  )
}

///|
fn AssetServer::register_image_path(
  self : AssetServer,
  path : String,
  handle : Handle[Image],
) -> Unit {
  self.image_paths.val.push((path, handle))
}

///|
fn AssetServer::track_image_handle(
  self : AssetServer,
  handle : Handle[Image],
) -> Unit {
  self.image_loaded_states.val.set(handle.id(), false)
}

///|
fn AssetServer::set_image_array_layout(
  self : AssetServer,
  image : Handle[Image],
  array_layout : ImageArrayLayout?,
) -> Unit {
  let next : Array[(Int, ImageArrayLayout)] = []
  for pair in self.image_array_layouts.val {
    if pair.0 != image.id() {
      next.push(pair)
    }
  }
  if array_layout is Some(layout) {
    next.push((image.id(), layout))
  }
  self.image_array_layouts.val = next
}

///|
fn AssetServer::set_image_is_srgb(
  self : AssetServer,
  image : Handle[Image],
  is_srgb : Bool,
) -> Unit {
  let next : Array[(Int, Bool)] = []
  for pair in self.image_srgb_settings.val {
    if pair.0 != image.id() {
      next.push(pair)
    }
  }
  next.push((image.id(), is_srgb))
  self.image_srgb_settings.val = next
}

///|
fn AssetServer::set_image_render_asset_usages(
  self : AssetServer,
  image : Handle[Image],
  asset_usage : RenderAssetUsages,
) -> Unit {
  let next : Array[(Int, RenderAssetUsages)] = []
  for pair in self.image_render_asset_usages.val {
    if pair.0 != image.id() {
      next.push(pair)
    }
  }
  next.push((image.id(), asset_usage))
  self.image_render_asset_usages.val = next
}

///|
fn asset_image_usage_sanitize(usage_bits : Int) -> Int {
  let usage = usage_bits.reinterpret_as_uint()
  let mask = IMAGE_USAGE_ALL_MASK.reinterpret_as_uint()
  (usage & mask).reinterpret_as_int()
}

///|
fn image_data_texture_format(is_srgb : Bool) -> TextureFormat {
  if is_srgb {
    TextureFormat::Rgba8UnormSrgb
  } else {
    TextureFormat::Rgba8Unorm
  }
}

///|
fn image_from_loaded_texture_bytes(bytes : Bytes, is_srgb : Bool) -> Image? {
  if ktx2_decode_uncompressed_3d_payload(bytes) is Some(_) ||
    ktx2_decode_2d_payload(bytes) is Some(_) {
    return None
  }
  let (width, height, pixels) = if decode_texture_image(bytes) is Some(decoded) {
    (decoded.width, decoded.height, decoded.pixels)
  } else if texture_dimensions_from_bytes(bytes) is Some(dims) {
    (dims.0, dims.1, source_bytes_to_rgba8(bytes, dims.0, dims.1))
  } else {
    (1, 1, source_bytes_to_rgba8(bytes, 1, 1))
  }
  Some(
    Image::new(clamp_dim(width), clamp_dim(height), pixels).with_format(
      image_data_texture_format(is_srgb),
    ),
  )
}

///|
fn AssetServer::set_image_usage_bits(
  self : AssetServer,
  image : Handle[Image],
  usage_bits : Int,
) -> Unit {
  let safe_usage_bits = asset_image_usage_sanitize(usage_bits)
  let next : Array[(Int, Int)] = []
  for pair in self.image_usage_settings.val {
    if pair.0 != image.id() {
      next.push(pair)
    }
  }
  next.push((image.id(), safe_usage_bits))
  self.image_usage_settings.val = next
}

///|
fn AssetServer::set_gltf_mesh_asset_usage(
  self : AssetServer,
  asset_path : String,
  asset_usage : RenderAssetUsages,
) -> Unit {
  let next : Array[(String, RenderAssetUsages)] = []
  for entry in self.gltf_mesh_asset_usages.val {
    if entry.0 != asset_path {
      next.push(entry)
    }
  }
  next.push((asset_path, asset_usage))
  self.gltf_mesh_asset_usages.val = next
}

///|
pub fn AssetServer::gltf_mesh_asset_usage(
  self : AssetServer,
  asset_path : String,
) -> RenderAssetUsages {
  for entry in self.gltf_mesh_asset_usages.val {
    if entry.0 == asset_path {
      return entry.1
    }
  }
  RenderAssetUsages::all()
}

///|
fn AssetServer::set_pending_image_asset(
  self : AssetServer,
  image : Handle[Image],
  asset : Image,
) -> Unit {
  if self
    .render_asset_usages_for_image(image)
    .contains(RenderAssetUsages::main_world()) {
    self.pending_image_assets.val.set(image.id(), asset)
  } else {
    self.pending_image_assets.val.remove(image.id()) |> ignore
  }
}

///|
fn AssetServer::update_pending_image_asset_from_bytes(
  self : AssetServer,
  image : Handle[Image],
  bytes : Bytes,
  is_srgb : Bool,
) -> Unit {
  match image_from_loaded_texture_bytes(bytes, is_srgb) {
    Some(asset) => self.set_pending_image_asset(image, asset)
    None => self.pending_image_assets.val.remove(image.id()) |> ignore
  }
}

///|
fn AssetServer::image_array_layout(
  self : AssetServer,
  image : Handle[Image],
) -> ImageArrayLayout? {
  for pair in self.image_array_layouts.val {
    if pair.0 == image.id() {
      return Some(pair.1)
    }
  }
  None
}

///|
fn AssetServer::image_is_srgb(
  self : AssetServer,
  image : Handle[Image],
) -> Bool {
  for pair in self.image_srgb_settings.val {
    if pair.0 == image.id() {
      return pair.1
    }
  }
  true
}

///|
fn AssetServer::render_asset_usages_for_image(
  self : AssetServer,
  image : Handle[Image],
) -> RenderAssetUsages {
  for pair in self.image_render_asset_usages.val {
    if pair.0 == image.id() {
      return pair.1
    }
  }
  RenderAssetUsages::all()
}

///|
fn AssetServer::image_usage_bits(
  self : AssetServer,
  image : Handle[Image],
) -> Int {
  for pair in self.image_usage_settings.val {
    if pair.0 == image.id() {
      return pair.1
    }
  }
  IMAGE_USAGE_DEFAULT_SAMPLED
}

///|
pub fn asset_image_array_layout(image : Handle[Image]) -> ImageArrayLayout? {
  asset_server_or_abort().image_array_layout(image)
}

///|
pub fn asset_image_is_srgb(image : Handle[Image]) -> Bool {
  asset_server_or_abort().image_is_srgb(image)
}

///|
pub fn asset_image_usage_bits(image : Handle[Image]) -> Int {
  asset_server_or_abort().image_usage_bits(image)
}

///|
pub fn asset_image_set_usage_bits(
  image : Handle[Image],
  usage_bits : Int,
) -> Unit {
  asset_server_or_abort().set_image_usage_bits(image, usage_bits)
}

///|
pub fn asset_image_add_usage(image : Handle[Image], usage_bits : Int) -> Unit {
  let current = asset_image_usage_bits(image).reinterpret_as_uint()
  let add = asset_image_usage_sanitize(usage_bits).reinterpret_as_uint()
  let next = (current | add).reinterpret_as_int()
  asset_server_or_abort().set_image_usage_bits(image, next)
}

///|
pub fn asset_image_remove_usage(
  image : Handle[Image],
  usage_bits : Int,
) -> Unit {
  let current = asset_image_usage_bits(image).reinterpret_as_uint()
  let remove = asset_image_usage_sanitize(usage_bits).reinterpret_as_uint()
  let next = (current & (IMAGE_USAGE_ALL_MASK.reinterpret_as_uint() ^ remove)).reinterpret_as_int()
  asset_server_or_abort().set_image_usage_bits(image, next)
}

///|
pub fn asset_image_has_usage(image : Handle[Image], usage_bits : Int) -> Bool {
  let current = asset_image_usage_bits(image).reinterpret_as_uint()
  let required = asset_image_usage_sanitize(usage_bits).reinterpret_as_uint()
  (current & required) == required
}

///|
pub fn[P : IntoAssetPath] AssetServer::get_handle(
  self : AssetServer,
  path : P,
) -> Handle[Image]? {
  let canonical = asset_canonical_path(asset_path_string(path))
  let count = self.image_paths.val.length()
  for i in 0..<count {
    let entry = self.image_paths.val[i]
    if entry.0 == canonical {
      return Some(entry.1)
    }
  }
  None
}

///|
pub fn asset_register_loader_extension(
  extension : String,
  kind : AssetLoaderKind,
) -> Unit {
  host_asset_register_loader_extension(
    extension~,
    kind=asset_loader_kind_to_raw(kind),
  )
}

///|
pub fn asset_remove_loader_extension(extension : String) -> Unit {
  host_asset_remove_loader_extension(extension~)
}

///|
pub fn asset_loader_kind_for_path(path : String) -> AssetLoaderKind {
  asset_loader_kind_from_raw(host_asset_loader_kind_for_path(path~))
}

///|
pub fn asset_set_default_sampler_nearest(enabled : Bool) -> Unit {
  asset_server_or_abort().default_sampler_nearest.val = enabled
}

///|
let asset_transparent_texture_handle : Ref[Handle[Image]?] = Ref::new(None)

///|
/// Returns a lazily-created 1x1 fully transparent texture handle.
///
/// This is used to match Bevy's `TRANSPARENT_IMAGE_HANDLE` behavior in widgets
/// (e.g. `ImageNode::default()`).
pub fn asset_transparent_texture() -> Handle[Image] {
  match asset_transparent_texture_handle.val {
    Some(h) => h
    None => {
      let size = @math.UVec2::new(1, 1)
      let handle = asset_create_dynamic_texture(size, false)
      let rect = @math.URect::new(
        @math.UVec2::new(0, 0),
        @math.UVec2::new(1, 1),
      )
      // moonbitlang/parser may not accept method calls on integer literals.
      let u : Int = 0
      let b : Byte = u.to_byte()
      let bytes = Bytes::from_array([b, b, b, b])
      asset_update_texture_region_rgba8(handle, rect, bytes)
      asset_transparent_texture_handle.val = Some(handle)
      handle
    }
  }
}

///|
let asset_white_texture_handle : Ref[Handle[Image]?] = Ref::new(None)

///|
/// Returns a lazily-created 1x1 opaque white texture handle.
pub fn asset_white_texture() -> Handle[Image] {
  match asset_white_texture_handle.val {
    Some(h) => h
    None => {
      let size = @math.UVec2::new(1, 1)
      let handle = asset_create_dynamic_texture(size, false)
      let rect = @math.URect::new(
        @math.UVec2::new(0, 0),
        @math.UVec2::new(1, 1),
      )
      let white_u : Int = 255
      let white_b : Byte = white_u.to_byte()
      let bytes = Bytes::from_array([white_b, white_b, white_b, white_b])
      asset_update_texture_region_rgba8(handle, rect, bytes)
      asset_white_texture_handle.val = Some(handle)
      handle
    }
  }
}

///|
pub fn host_asset_load_texture(path~ : String, nearest~ : Bool) -> Int {
  load_texture(path~, nearest~)
}

///|
pub fn host_asset_load_texture_bytes(bytes~ : Bytes, nearest~ : Bool) -> Int {
  load_texture_bytes(bytes~, nearest~)
}

///|
pub fn host_asset_load_wgsl(path~ : String) -> Int {
  load_wgsl(path~)
}

///|
pub fn host_asset_load_bytes(path~ : String) -> Int {
  load_bytes(path~)
}

///|
pub fn host_asset_load_with_registered_loader(
  path~ : String,
  nearest~ : Bool,
) -> Int {
  load_with_registered_loader(path~, nearest~)
}

///|
pub fn host_asset_register_loader_extension(
  extension~ : String,
  kind~ : Int,
) -> Unit {
  register_loader_extension(extension~, kind~)
}

///|
pub fn host_asset_remove_loader_extension(extension~ : String) -> Unit {
  remove_loader_extension(extension~)
}

///|
pub fn host_asset_loader_kind_for_path(path~ : String) -> Int {
  loader_kind_for_path(path~)
}

///|
pub fn host_asset_bytes_len(blob_id : Int) -> Int {
  bytes_len(blob_id)
}

///|
pub fn host_asset_bytes_get_u32(blob_id~ : Int, index~ : Int) -> Int {
  bytes_get_u32(blob_id~, index~)
}

///|
pub fn host_asset_create_dynamic_texture(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int {
  create_dynamic_texture(width~, height~, nearest~)
}

///|
pub fn host_asset_create_dynamic_texture_mipped(
  width~ : Int,
  height~ : Int,
  mip_level_count~ : Int,
  nearest~ : Bool,
) -> Int {
  create_dynamic_texture_mipped(width~, height~, mip_level_count~, nearest~)
}

///|
pub fn host_asset_update_texture_region(
  texture_id~ : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  glyph_id~ : Int,
) -> Unit {
  update_texture_region(texture_id~, x~, y~, width~, height~, glyph_id~)
}

///|
pub fn host_asset_update_texture_region_bytes(
  texture_id~ : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  bytes~ : Bytes,
) -> Unit {
  update_texture_region_bytes(texture_id~, x~, y~, width~, height~, bytes~)
}

///|
pub fn host_asset_update_texture_region_mip_bytes(
  texture_id~ : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  mip_level~ : Int,
  bytes~ : Bytes,
) -> Unit {
  update_texture_region_mip_bytes(
    texture_id~,
    x~,
    y~,
    width~,
    height~,
    mip_level~,
    bytes~,
  )
}

///|
pub fn host_asset_create_texture_mip_view(
  texture_id~ : Int,
  mip_level~ : Int,
) -> Int {
  create_texture_mip_view(texture_id~, mip_level~)
}

///|
pub fn host_asset_texture_width(texture_id : Int) -> Int {
  texture_width(texture_id)
}

///|
pub fn host_asset_texture_height(texture_id : Int) -> Int {
  texture_height(texture_id)
}

///|
pub fn host_asset_is_texture_loaded(texture_id : Int) -> Bool {
  is_texture_loaded(texture_id)
}

///|
pub fn host_asset_supported_compressed_image_formats() -> Int {
  supported_compressed_image_formats()
}

///|
pub fn host_asset_copy_texture_to_texture(
  dst_texture_id~ : Int,
  dst_x~ : Int,
  dst_y~ : Int,
  src_texture_id~ : Int,
) -> Unit {
  copy_texture_to_texture(dst_texture_id~, dst_x~, dst_y~, src_texture_id~)
}

///|
pub fn host_asset_set_texture_sampler(
  texture_id~ : Int,
  address_mode_u~ : Int,
  address_mode_v~ : Int,
  address_mode_w~ : Int,
  mag_filter~ : Int,
  min_filter~ : Int,
  mipmap_filter~ : Int,
  lod_min_clamp~ : Float,
  lod_max_clamp~ : Float,
  compare~ : Int,
  anisotropy_clamp~ : Int,
  border_color~ : Int,
) -> Unit {
  @render.asset_set_texture_sampler(
    texture_id~,
    address_mode_u~,
    address_mode_v~,
    address_mode_w~,
    mag_filter~,
    min_filter~,
    mipmap_filter~,
    lod_min_clamp~,
    lod_max_clamp~,
    compare~,
    anisotropy_clamp~,
    border_color~,
  )
}

///|
pub fn host_asset_save_rgba8_png(
  width~ : Int,
  height~ : Int,
  pixels~ : Bytes,
  path~ : String,
) -> Unit {
  save_rgba8_png(width~, height~, pixels~, path~)
}

///|
pub fn host_asset_save_bytes(path~ : String, bytes~ : Bytes) -> Unit {
  save_asset_file_bytes(path, bytes)
}

///|
pub fn[P : IntoAssetPath] AssetServer::load_image(
  self : AssetServer,
  path : P,
) -> Handle[Image] {
  let canonical_path = asset_canonical_path(asset_path_string(path))
  let settings = self.image_loader_settings_for_path(canonical_path)
  self.load_image_with_settings(canonical_path, settings)
}

///|
pub fn[P : IntoAssetPath] AssetServer::load_nearest(
  self : AssetServer,
  path : P,
) -> Handle[Image] {
  let canonical_path = asset_canonical_path(asset_path_string(path))
  let settings = self.image_loader_settings_for_path(canonical_path)
  settings.sampler = ImageSampler::nearest()
  self.load_image_with_settings(canonical_path, settings)
}

///|
fn image_sampler_is_nearest(sampler : ImageSampler) -> Bool {
  @image.image_sampler_is_nearest(sampler)
}

///|
fn AssetServer::image_loader_settings_for_path(
  self : AssetServer,
  canonical_path : String,
) -> ImageLoaderSettings {
  self |> ignore
  let settings = ImageLoaderSettings::default()
  if load_optional_asset_text(image_meta_path(canonical_path)) is Some(content) {
    apply_image_meta_settings(settings, content)
  }
  settings
}

///|
fn AssetServer::image_sampler_uses_nearest(
  self : AssetServer,
  sampler : ImageSampler,
) -> Bool {
  match sampler {
    ImageSampler::Default => self.default_sampler_nearest.val
    _ => image_sampler_is_nearest(sampler)
  }
}

///|
fn AssetServer::load_image_with_settings(
  self : AssetServer,
  canonical_path : String,
  settings : ImageLoaderSettings,
) -> Handle[Image] {
  if self.get_handle(canonical_path) is Some(handle) {
    return handle
  }
  let bytes = load_asset_file_bytes(canonical_path)
  let id = host_asset_load_texture(
    path=canonical_path,
    nearest=self.image_sampler_uses_nearest(settings.sampler),
  )
  self.record_path(canonical_path)
  let handle = Handle::new(id)
  self.register_image_path(canonical_path, handle)
  self.track_image_handle(handle)
  if settings.sampler is Descriptor(_) {
    asset_set_texture_sampler(handle, settings.sampler)
  }
  self.set_image_array_layout(handle, settings.array_layout)
  self.set_image_is_srgb(handle, settings.is_srgb)
  self.set_image_usage_bits(handle, IMAGE_USAGE_DEFAULT_SAMPLED)
  self.set_image_render_asset_usages(handle, settings.asset_usage)
  self.update_pending_image_asset_from_bytes(handle, bytes, settings.is_srgb)
  handle
}

///|
fn asset_image_handle_type_name() -> String {
  let probe : Handle[Image] = Handle::new(0)
  asset_loader_type_name(probe)
}

///|
pub fn[T, P : IntoAssetPath] AssetServer::load(
  self : AssetServer,
  path : P,
) -> Handle[T] {
  asset_register_builtin_loaders()
  let asset_probe : Assets[T] = Assets::new()
  let asset_type_name = @any.of(asset_probe).type_name()
  if typed_asset_loader_registry.val.contains(asset_type_name) {
    return self.load_registered_asset(path)
  }
  let formatted_path = asset_path_string(path)
  let probe : Handle[T] = Handle::new(0)
  let type_name = asset_loader_type_name(probe)
  match asset_loader_registry.val.get(type_name) {
    Some(entry) =>
      match (entry.load)(self, formatted_path).try_to() {
        Some(handle) => handle
        None =>
          abort(
            "asset loader registry returned a mismatched handle type for \{type_name}",
          )
      }
    None =>
      abort(
        "No asset loader is registered for \{type_name}; load the plugin that owns this asset type before calling AssetServer::load",
      )
  }
}

///|
pub fn[T, P : IntoAssetPath, G : AssetLoadGuard] AssetServer::load_acquire(
  self : AssetServer,
  path : P,
  load_guard : G,
) -> Handle[T] {
  let handle = self.load(path)
  let ready : AssetReadyCheck = asset_registered_ready_check(handle)
  let release : AssetLoadRelease = fn() { load_guard.release() }
  match asset_current_world() {
    Some(world) =>
      if ready(world, handle.id()) {
        release()
      } else {
        self.pending_acquired_loads.val.push(PendingAcquiredLoad::{
          handle_id: handle.id(),
          is_ready: ready,
          release,
        })
      }
    None => release()
  }
  handle
}

///|
pub fn[T, P : IntoAssetPath] AssetServer::load_with_settings(
  self : AssetServer,
  path : P,
  configure : (ImageLoaderSettings) -> Unit,
) -> Handle[T] {
  let formatted_path = asset_path_string(path)
  let probe : Handle[T] = Handle::new(0)
  let type_name = asset_loader_type_name(probe)
  if type_name == asset_image_handle_type_name() {
    let canonical_path = asset_canonical_path(formatted_path)
    if self.get_handle(canonical_path) is Some(handle) {
      return @any.of(handle).try_to().unwrap()
    }
    let settings = self.image_loader_settings_for_path(canonical_path)
    configure(settings)
    return @any.of(self.load_image_with_settings(canonical_path, settings))
      .try_to()
      .unwrap()
  }
  let settings = ImageLoaderSettings::default()
  configure(settings)
  self.set_gltf_mesh_asset_usage(formatted_path, settings.load_meshes)
  self.load(formatted_path)
}

///|
pub fn AssetServer::load_texture_bytes(
  self : AssetServer,
  bytes : Bytes,
  nearest : Bool,
) -> Handle[Image] {
  let id = host_asset_load_texture_bytes(bytes~, nearest~)
  let handle = Handle::new(id)
  self.track_image_handle(handle)
  self.set_image_usage_bits(handle, IMAGE_USAGE_DEFAULT_SAMPLED)
  self.set_image_render_asset_usages(handle, RenderAssetUsages::all())
  self.update_pending_image_asset_from_bytes(handle, bytes, true)
  handle
}

///|
pub fn asset_supported_compressed_image_formats() -> Int {
  host_asset_supported_compressed_image_formats()
}

///|
pub fn asset_compressed_image_formats_contains(
  supported_formats : Int,
  required_format : Int,
) -> Bool {
  let required = required_format.reinterpret_as_uint()
  if required == COMPRESSED_IMAGE_FORMAT_NONE.reinterpret_as_uint() {
    return true
  }
  let supported = supported_formats.reinterpret_as_uint()
  (supported & required) == required
}

///|
pub fn AssetServer::load_bytes(
  self : AssetServer,
  path : String,
) -> Handle[Blob] {
  let canonical_path = asset_canonical_path(path)
  let id = host_asset_load_bytes(path=canonical_path)
  self.record_path(canonical_path)
  Blob::{  } |> ignore
  Handle::new(id)
}

///|
pub fn AssetServer::load_with_registered_loader(
  self : AssetServer,
  path : String,
  nearest : Bool,
) -> Int {
  let canonical_path = asset_canonical_path(path)
  let id = host_asset_load_with_registered_loader(path=canonical_path, nearest~)
  self.record_path(canonical_path)
  id
}

///|
pub fn asset_blob_read_bytes(blob : Handle[Blob]) -> Bytes? {
  let len = host_asset_bytes_len(blob.id())
  if len <= 0 {
    return None
  }
  let bytes : Array[Byte] = []
  let mut i = 0
  while i < len {
    let u = host_asset_bytes_get_u32(blob_id=blob.id(), index=i).reinterpret_as_uint()
    bytes.push((u & 0xFFU).reinterpret_as_int().to_byte())
    if i + 1 < len {
      bytes.push(((u >> 8) & 0xFFU).reinterpret_as_int().to_byte())
    }
    if i + 2 < len {
      bytes.push(((u >> 16) & 0xFFU).reinterpret_as_int().to_byte())
    }
    if i + 3 < len {
      bytes.push(((u >> 24) & 0xFFU).reinterpret_as_int().to_byte())
    }
    i = i + 4
  }
  Some(Bytes::from_array(bytes))
}

///|
pub fn asset_blob_read_text(blob : Handle[Blob]) -> String? {
  guard asset_blob_read_bytes(blob) is Some(bytes) else { return None }
  let chars : Array[Char] = []
  for byte in bytes {
    let code = byte.to_int() & 0xFF
    if code.to_char() is Some(ch) {
      chars.push(ch)
    } else {
      chars.push(Int::unsafe_to_char(0xFFFD))
    }
  }
  Some(String::from_array(chars))
}

///|
pub fn asset_create_dynamic_texture(
  size : @math.UVec2,
  nearest : Bool,
) -> Handle[Image] {
  asset_create_dynamic_texture_with_mips(size, 1, nearest)
}

///|
pub fn asset_create_dynamic_texture_with_mips(
  size : @math.UVec2,
  mip_level_count : Int,
  nearest : Bool,
) -> Handle[Image] {
  let safe_mip_level_count = if mip_level_count <= 0 {
    1
  } else {
    mip_level_count
  }
  let id = host_asset_create_dynamic_texture_mipped(
    width=size.x,
    height=size.y,
    mip_level_count=safe_mip_level_count,
    nearest~,
  )
  let handle = Handle::new(id)
  let asset_server = AssetServer::new()
  asset_server.track_image_handle(handle)
  asset_server.set_image_usage_bits(handle, IMAGE_USAGE_DEFAULT_DYNAMIC)
  handle
}

///|
pub fn asset_update_texture_region(
  texture : Handle[Image],
  rect : @math.URect,
  glyph_id : Int,
) -> Unit {
  let size = rect.size()
  host_asset_update_texture_region(
    texture_id=texture.id(),
    x=rect.min.x,
    y=rect.min.y,
    width=size.x,
    height=size.y,
    glyph_id~,
  )
}

///|
pub fn asset_update_texture_region_rgba8(
  texture : Handle[Image],
  rect : @math.URect,
  pixels_rgba8 : Bytes,
) -> Unit {
  asset_update_texture_region_rgba8_mip(texture, rect, 0, pixels_rgba8)
}

///|
pub fn asset_update_texture_region_rgba8_mip(
  texture : Handle[Image],
  rect : @math.URect,
  mip_level : Int,
  pixels_rgba8 : Bytes,
) -> Unit {
  let size = rect.size()
  let safe_mip_level = if mip_level < 0 { 0 } else { mip_level }
  host_asset_update_texture_region_mip_bytes(
    texture_id=texture.id(),
    x=rect.min.x,
    y=rect.min.y,
    width=size.x,
    height=size.y,
    mip_level=safe_mip_level,
    bytes=pixels_rgba8,
  )
}

///|
pub fn asset_create_texture_mip_view(
  texture : Handle[Image],
  mip_level : Int,
) -> Handle[Image] {
  let safe_mip_level = if mip_level < 0 { 0 } else { mip_level }
  let id = host_asset_create_texture_mip_view(
    texture_id=texture.id(),
    mip_level=safe_mip_level,
  )
  let handle = Handle::new(id)
  let asset_server = AssetServer::new()
  asset_server.track_image_handle(handle)
  asset_server.set_image_usage_bits(handle, asset_image_usage_bits(texture))
  handle
}

///|
fn asset_update_image_event_messages(world : @ecs.World) -> Unit {
  guard (try! world.get_resource(asset_server_resource_key()))
    is Some(asset_server) else {
    return
  }

  let message_key : @ecs.MessageKey[AssetEvent[Image]] = @ecs.Message::message()
  if !world.contains_message(message_key) {
    world.init_message(message_key)
  }

  let became_loaded : Array[Int] = []
  for entry in asset_server.image_loaded_states.val.iter() {
    let (image_id, was_loaded) = entry
    if !was_loaded && host_asset_is_texture_loaded(image_id) {
      became_loaded.push(image_id)
    }
  }

  for image_id in became_loaded {
    asset_server.image_loaded_states.val.set(image_id, true)
    ignore(
      world.send_message(message_key, AssetEvent::Added(Handle::new(image_id))),
    )
  }
}

///|
fn asset_poll_modified_paths(asset_server : AssetServer) -> Array[String] {
  let modified_paths : Array[String] = []
  for path in asset_server.paths.val {
    let next_fingerprint = bytes_fingerprint(load_asset_file_bytes(path))
    match asset_server.path_fingerprints.val.get(path) {
      Some(previous_fingerprint) =>
        if previous_fingerprint != next_fingerprint {
          asset_server.path_fingerprints.val.set(path, next_fingerprint)
          modified_paths.push(path)
        }
      None => asset_server.path_fingerprints.val.set(path, next_fingerprint)
    }
  }
  modified_paths
}

///|
fn asset_reload_modified_paths(world : @ecs.World) -> Unit {
  guard (try! world.get_resource(asset_server_resource_key()))
    is Some(asset_server) else {
    return
  }
  let modified_paths = asset_poll_modified_paths(asset_server)
  if modified_paths.length() == 0 {
    return
  }
  for path in modified_paths {
    for hook in asset_reload_hook_registry {
      hook(world, asset_server, path)
    }
  }
}

///|
fn asset_sync_loaded_image_assets(world : @ecs.World) -> Unit {
  guard (try! world.get_resource(asset_server_resource_key()))
    is Some(asset_server) else {
    return
  }
  let key : @ecs.ResourceKey[Assets[Image]] = assets_resource_key()
  guard (try! world.get_resource_ref_mut(key)) is Some(images_ref) else {
    return
  }

  let synced : Array[Int] = []
  asset_with_world(world, fn() {
    for entry in asset_server.pending_image_assets.val.iter() {
      let (image_id, image) = entry
      if host_asset_is_texture_loaded(image_id) {
        let handle : Handle[Image] = Handle::new(image_id)
        image_asset_sync_metadata(handle, image)
        ignore(assets_store_insert_silent(images_ref.val, handle, image))
        synced.push(image_id)
      }
    }
  })

  for image_id in synced {
    asset_server.pending_image_assets.val.remove(image_id) |> ignore
  }
}

///|
fn asset_sync_dirty_image_assets(world : @ecs.World) -> Unit {
  let key : @ecs.ResourceKey[Assets[Image]] = assets_resource_key()
  guard (try! world.get_resource_ref_mut(key)) is Some(images_ref) else {
    return
  }
  for handle in assets_drain_dirty(images_ref.val) {
    if images_ref.val.get(handle) is Some(image) {
      image_asset_sync_dirty(handle, image)
    }
  }
}

///|
fn asset_release_ready_acquired_loads(
  world : @ecs.World,
  asset_server : AssetServer,
) -> Unit {
  let remaining : Array[PendingAcquiredLoad] = []
  for pending in asset_server.pending_acquired_loads.val {
    if (pending.is_ready)(world, pending.handle_id) {
      (pending.release)()
    } else {
      remaining.push(pending)
    }
  }
  asset_server.pending_acquired_loads.val.clear()
  for pending in remaining {
    asset_server.pending_acquired_loads.val.push(pending)
  }
}

///|
pub fn asset_texture_width(texture : Handle[Image]) -> Int {
  host_asset_texture_width(texture.id())
}

///|
pub fn asset_texture_height(texture : Handle[Image]) -> Int {
  host_asset_texture_height(texture.id())
}

///|
pub fn asset_is_texture_loaded(texture : Handle[Image]) -> Bool {
  host_asset_is_texture_loaded(texture.id())
}

///|
pub fn asset_copy_texture_to_texture(
  dst : Handle[Image],
  dst_pos : @math.UVec2,
  src : Handle[Image],
) -> Unit {
  host_asset_copy_texture_to_texture(
    dst_texture_id=dst.id(),
    dst_x=dst_pos.x,
    dst_y=dst_pos.y,
    src_texture_id=src.id(),
  )
}

///|
pub fn asset_save_texture_png(texture : Handle[Image], path : String) -> Unit {
  save_texture_png(texture_id=texture.id(), path~)
}

///|
pub fn asset_system(world : @ecs.World) -> Unit {
  asset_with_world(world, fn() {
    let asset_server = asset_server_or_abort()
    asset_reload_modified_paths(world)
    asset_update_loaded_folders(world)
    asset_process_pending_processed_asset_loads(world, asset_server)
    asset_process_pending_typed_asset_loads(world, asset_server)
    asset_sync_dirty_image_assets(world)
    asset_update_event_messages(world)
    asset_sync_loaded_image_assets(world)
    asset_update_image_event_messages(world)
    asset_release_ready_acquired_loads(world, asset_server)
  })
}

///|
fn asset_plugin_with_server(
  app : @app.App[@ecs.World],
  asset_server : AssetServer,
  file_path : String?,
  mode : AssetMode,
  processed_file_path : String?,
) -> @app.App[@ecs.World] {
  asset_register_builtin_loaders()
  set_runtime_assets_dir_override(resolve_assets_dir_override(file_path))
  set_runtime_asset_source_dir_overrides(asset_registered_source_dir_entries())
  set_runtime_asset_source_readers(asset_registered_source_reader_entries())
  asset_server.mode.val = mode
  asset_server.processed_file_path.val = resolve_assets_dir_override(
    processed_file_path,
  )
  app
  .insert_resource(asset_server)
  .init_resource(fn() {
    let assets : Assets[LoadedFolder] = Assets::new()
    assets
  })
  .init_resource(fn() {
    let assets : Assets[Image] = Assets::new()
    assets
  })
  .init_resource(fn() {
    let assets : Assets[TextureAtlasLayout] = Assets::new()
    assets
  })
  .add_pre_update_system(asset_system)
}

///|
pub fn asset_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  asset_plugin_with_server(
    app,
    asset_server_standalone(),
    None,
    AssetMode::Unprocessed,
    None,
  )
}

///|
pub fn asset_plugin_nearest(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  let asset_server = asset_server_standalone()
  asset_server.default_sampler_nearest.val = true
  asset_plugin_with_server(
    app,
    asset_server,
    None,
    AssetMode::Unprocessed,
    None,
  )
}

///|
pub impl @app.PluginReplacement for AssetPlugin with replacement_id(_self) {
  ASSET_PLUGIN_ID
}

///|
pub impl @app.PluginReplacement for AssetPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    let asset_server = asset_server_standalone()
    asset_server.default_sampler_nearest.val = self.default_sampler_nearest
    asset_plugin_with_server(
      app,
      asset_server,
      self.file_path,
      self.mode,
      self.processed_file_path,
    )
  }
}
