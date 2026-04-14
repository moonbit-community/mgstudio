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
// Bevy source: `bevy/crates/bevy_asset/src/id.rs`.
pub struct AssetId[_] {
  id : Int
} derive(Eq, Debug)

///|
pub fn[T] AssetId::new(id : Int) -> AssetId[T] {
  AssetId::{ id, }
}

///|
pub fn[T] AssetId::index(self : AssetId[T]) -> Int {
  self.id
}
