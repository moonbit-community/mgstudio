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
pub fn[T] Handle::new(id : Int) -> Handle[T] {
  Handle::{ id, phantom: None }
}

///|
pub fn[T] Handle::id(self : Handle[T]) -> Int {
  self.id
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
let asset_default_nearest : Ref[Bool] = @ref.new(false)

///|
pub fn asset_set_default_sampler_nearest(enabled : Bool) -> Unit {
  asset_default_nearest.val = enabled
}

///|
pub fn host_asset_load_texture(path : String, nearest : Bool) -> Int = "mgstudio_host" "asset_load_texture"

///|
pub fn host_asset_load_wgsl(path : String) -> Int = "mgstudio_host" "asset_load_wgsl"

///|
pub fn AssetServer::load(self : AssetServer, path : String) -> Handle[Image] {
  let id = host_asset_load_texture(path, asset_default_nearest.val)
  self.paths.push(path)
  Handle::new(id)
}

///|
pub fn AssetServer::load_nearest(
  self : AssetServer,
  path : String,
) -> Handle[Image] {
  let id = host_asset_load_texture(path, true)
  self.paths.push(path)
  Handle::new(id)
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
pub fn asset_system() -> Unit {

}

///|
pub fn asset_plugin(app : @app.App) -> @app.App {
  app.add_system(asset_system)
}

///|
pub fn asset_plugin_nearest(app : @app.App) -> @app.App {
  asset_set_default_sampler_nearest(true)
  app.add_system(asset_system)
}
