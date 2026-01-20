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
pub struct AssetServer {
  mut next_id : Int
}

///|
pub fn AssetServer::new() -> AssetServer {
  AssetServer::{ next_id: 0 }
}

///|
pub fn AssetServer::load(self : AssetServer, path : String) -> Handle[Image] {
  path |> ignore
  let id = self.next_id
  self.next_id = self.next_id + 1
  Handle::new(id)
}
