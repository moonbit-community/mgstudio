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
// Bevy source: `bevy/crates/bevy_pbr/src/cluster.rs`.

///|
pub struct ClusterConfig3d {
  dimensions_x : Int
  dimensions_y : Int
  dimensions_z : Int
}

///|
pub fn ClusterConfig3d::default() -> ClusterConfig3d {
  ClusterConfig3d::{ dimensions_x: 16, dimensions_y: 9, dimensions_z: 24 }
}

///|
pub fn ClusterConfig3d::with_dimensions(
  _self : ClusterConfig3d,
  dimensions_x : Int,
  dimensions_y : Int,
  dimensions_z : Int,
) -> ClusterConfig3d {
  ClusterConfig3d::{ dimensions_x, dimensions_y, dimensions_z }
}

///|
pub fn pbr_cluster_tile_count(config : ClusterConfig3d) -> Int {
  config.dimensions_x * config.dimensions_y * config.dimensions_z
}
