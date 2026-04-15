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
pub type Image = @image.Image

///|
pub type TextureFormat = @image.TextureFormat

///|
pub type ImageKind = @image.ImageKind

///|
pub type ImageFormatSetting = @image.ImageFormatSetting

///|
pub type ImageContainerFormat = @image.ImageContainerFormat

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
  gltf_loader_settings : Ref[Array[(String, ImageLoaderSettings)]]
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
priv struct AssetLoaderEntry {
  load : (AssetServer, String) -> @any.Any
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
    gltf_loader_settings: Ref::new([]),
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
let asset_reload_hook_registry : Array[AssetReloadHook] = []

///|
let asset_ready_checker_registry : Ref[
  @hashmap.HashMap[String, AssetReadyCheck],
] = Ref::new(@hashmap.HashMap::new())

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
  @ecs.register_resource(debug_name="mgstudio_asset::AssetServer")
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
pub fn asset_text_to_bytes(text : String) -> Bytes {
  @utf8.encode(text[:])
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
fn image_container_supports_rgba_decode(
  container : ImageContainerFormat,
) -> Bool {
  match container {
    ImageContainerFormat::Basis => false
    ImageContainerFormat::Dds => false
    ImageContainerFormat::Ktx2 => false
    _ => true
  }
}

///|
fn image_from_loaded_texture_bytes(
  path : String,
  bytes : Bytes,
  is_srgb : Bool,
  format_setting : ImageFormatSetting,
  texture_format_override : TextureFormat?,
) -> Image? {
  let container = @image.image_loader_container_from_input(
    path,
    Some(bytes),
    format_setting,
  )
  if container is Some(container) &&
    !image_container_supports_rgba_decode(container) {
    return None
  }
  if ktx2_decode_uncompressed_3d_payload(bytes) is Some(_) ||
    ktx2_decode_2d_payload(bytes) is Some(_) {
    return None
  }
  let (width, height, pixels) = if decode_texture_image_with_container(
      bytes, container,
    )
    is Some(decoded) {
    (decoded.width, decoded.height, decoded.pixels)
  } else if texture_dimensions_from_bytes(bytes) is Some(dims) {
    (dims.0, dims.1, source_bytes_to_rgba8(bytes, dims.0, dims.1))
  } else {
    (1, 1, source_bytes_to_rgba8(bytes, 1, 1))
  }
  let texture_format = match texture_format_override {
    Some(format) => format
    None => image_data_texture_format(is_srgb)
  }
  Some(
    Image::new(clamp_dim(width), clamp_dim(height), pixels).with_format(
      texture_format,
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
fn image_loader_settings_clone(
  settings : ImageLoaderSettings,
) -> ImageLoaderSettings {
  ImageLoaderSettings::{
    format: settings.format,
    texture_format: settings.texture_format,
    sampler: settings.sampler,
    override_sampler: settings.override_sampler,
    is_srgb: settings.is_srgb,
    array_layout: settings.array_layout,
    asset_usage: settings.asset_usage,
    load_meshes: settings.load_meshes,
    load_materials: settings.load_materials,
    load_cameras: settings.load_cameras,
    load_lights: settings.load_lights,
    load_animations: settings.load_animations,
    include_source: settings.include_source,
  }
}

///|
fn AssetServer::set_gltf_loader_settings(
  self : AssetServer,
  asset_path : String,
  settings : ImageLoaderSettings,
) -> Unit {
  let next : Array[(String, ImageLoaderSettings)] = []
  for entry in self.gltf_loader_settings.val {
    if entry.0 != asset_path {
      next.push(entry)
    }
  }
  next.push((asset_path, image_loader_settings_clone(settings)))
  self.gltf_loader_settings.val = next
}

///|
pub fn AssetServer::gltf_loader_settings_for_asset_path(
  self : AssetServer,
  asset_path : String,
) -> ImageLoaderSettings {
  for entry in self.gltf_loader_settings.val {
    if entry.0 == asset_path {
      return image_loader_settings_clone(entry.1)
    }
  }
  ImageLoaderSettings::default()
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
  path : String,
  bytes : Bytes,
  is_srgb : Bool,
  format_setting : ImageFormatSetting,
  texture_format_override : TextureFormat?,
) -> Unit {
  match
    image_from_loaded_texture_bytes(
      path, bytes, is_srgb, format_setting, texture_format_override,
    ) {
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
  @render_texture.asset_set_texture_sampler(
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
  self.update_pending_image_asset_from_bytes(
    handle,
    canonical_path,
    bytes,
    settings.is_srgb,
    settings.format,
    settings.texture_format,
  )
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
  self.set_gltf_loader_settings(formatted_path, settings)
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
  self.update_pending_image_asset_from_bytes(
    handle,
    "",
    bytes,
    true,
    ImageFormatSetting::Guess,
    None,
  )
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
