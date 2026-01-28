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
pub struct Image {
  width : Int
  height : Int
  pixels : Bytes
}

///|
pub fn Image::new(width : Int, height : Int, pixels : Bytes) -> Image {
  Image::{ width, height, pixels }
}

///|
pub struct Shader {
  source : String
}

///|
pub fn Shader::new(source : String) -> Shader {
  Shader::{ source, }
}

///|
pub struct AssetServer {
  paths : Array[String]
}

///|
pub fn AssetServer::new() -> AssetServer {
  AssetServer::{ paths: [] }
}

///|
let asset_image_paths : Ref[Array[(String, Handle[Image])]] = Ref::new([])

///|
fn asset_register_image_path(path : String, handle : Handle[Image]) -> Unit {
  asset_image_paths.val.push((path, handle))
}

///|
pub fn AssetServer::get_handle(
  _self : AssetServer,
  path : String,
) -> Handle[Image]? {
  let count = asset_image_paths.val.length()
  for i in 0..<count {
    let entry = asset_image_paths.val[i]
    if entry.0 == path {
      return Some(entry.1)
    }
  }
  None
}

///|
let asset_default_nearest : Ref[Bool] = Ref::new(false)

///|
pub fn asset_set_default_sampler_nearest(enabled : Bool) -> Unit {
  asset_default_nearest.val = enabled
}

///|
pub fn host_asset_load_texture(path : String, nearest : Bool) -> Int {
  @core.with_host_string_id(path, fn(path_id) {
    host_asset_load_texture_id(path_id, nearest)
  })
}

///|
fn host_asset_load_texture_id(path_id : Int, nearest : Bool) -> Int = "mgstudio_host" "asset_load_texture"

///|
pub fn host_asset_load_wgsl(path : String) -> Int {
  @core.with_host_string_id(path, fn(path_id) {
    host_asset_load_wgsl_id(path_id)
  })
}

///|
fn host_asset_load_wgsl_id(path_id : Int) -> Int = "mgstudio_host" "asset_load_wgsl"

///|
pub fn host_asset_create_dynamic_texture(
  width : Int,
  height : Int,
  nearest : Bool,
) -> Int = "mgstudio_host" "asset_create_dynamic_texture"

///|
pub fn host_asset_update_texture_region(
  texture_id : Int,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  glyph_id : Int,
) -> Unit = "mgstudio_host" "asset_update_texture_region"

///|
pub fn host_asset_texture_width(texture_id : Int) -> Int = "mgstudio_host" "asset_texture_width"

///|
pub fn host_asset_texture_height(texture_id : Int) -> Int = "mgstudio_host" "asset_texture_height"

///|
pub fn host_asset_is_texture_loaded(texture_id : Int) -> Bool = "mgstudio_host" "asset_is_texture_loaded"

///|
pub fn host_asset_copy_texture_to_texture(
  dst_texture_id : Int,
  dst_x : Int,
  dst_y : Int,
  src_texture_id : Int,
) -> Unit = "mgstudio_host" "asset_copy_texture_to_texture"

///|
pub fn AssetServer::load(self : AssetServer, path : String) -> Handle[Image] {
  let id = host_asset_load_texture(path, asset_default_nearest.val)
  self.paths.push(path)
  let handle = Handle::new(id)
  asset_register_image_path(path, handle)
  handle
}

///|
pub fn AssetServer::load_nearest(
  self : AssetServer,
  path : String,
) -> Handle[Image] {
  let id = host_asset_load_texture(path, true)
  self.paths.push(path)
  let handle = Handle::new(id)
  asset_register_image_path(path, handle)
  handle
}

///|
pub fn AssetServer::load_wgsl(
  self : AssetServer,
  path : String,
) -> Handle[Shader] {
  let id = host_asset_load_wgsl(path)
  self.paths.push(path)
  Handle::new(id)
}

///|
pub fn asset_create_dynamic_texture(
  size : @math.UVec2,
  nearest : Bool,
) -> Handle[Image] {
  let id = host_asset_create_dynamic_texture(size.x, size.y, nearest)
  Handle::new(id)
}

///|
pub fn asset_update_texture_region(
  texture : Handle[Image],
  rect : @math.URect,
  glyph_id : Int,
) -> Unit {
  let size = rect.size()
  host_asset_update_texture_region(
    texture.id(),
    rect.min.x,
    rect.min.y,
    size.x,
    size.y,
    glyph_id,
  )
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
  host_asset_copy_texture_to_texture(dst.id(), dst_pos.x, dst_pos.y, src.id())
}

///|
pub fn[W] asset_system(_world : W) -> Unit {
  asset_update_loaded_folders()
}

///|
pub fn[W] asset_plugin(app : @app.App[W]) -> @app.App[W] {
  app.add_pre_update_system(asset_system)
}

///|
pub fn[W] asset_plugin_nearest(app : @app.App[W]) -> @app.App[W] {
  asset_set_default_sampler_nearest(true)
  app.add_pre_update_system(asset_system)
}
