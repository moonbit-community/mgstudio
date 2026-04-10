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
// Bevy source: `bevy/crates/bevy_solari/src/realtime/prepare.rs`.

///|
pub const LIGHT_TILE_BLOCKS : Int64 = 128L

///|
pub const LIGHT_TILE_SAMPLES_PER_BLOCK : Int64 = 1024L

///|
pub const WORLD_CACHE_SIZE : Int64 = 1_048_576L

///|
pub struct SolariLightingResources {
  world_cache_buffer_id : Int
  light_tile_buffer_id : Int
}

///|
pub fn SolariLightingResources::default() -> SolariLightingResources {
  SolariLightingResources::{
    world_cache_buffer_id: -1,
    light_tile_buffer_id: -1,
  }
}

///|
pub fn prepare_solari_lighting_resources(_world : @ecs.World) -> Unit {
  ()
}
