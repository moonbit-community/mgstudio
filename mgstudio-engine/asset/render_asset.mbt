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
// Bevy source: `bevy/crates/bevy_asset/src/render_asset.rs`.
pub struct RenderAssetUsages {
  bits : Int
} derive(Eq, Debug)

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
