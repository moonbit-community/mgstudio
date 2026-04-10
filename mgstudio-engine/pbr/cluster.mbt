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
pub const CLUSTER_MODULE_TAG : String = @pbr_cluster.CLUSTER_MODULE_TAG

///|
pub fn pbr_cluster_module_tag() -> String {
  CLUSTER_MODULE_TAG
}

///|
pub fn pbr_cluster_runtime_available() -> Bool {
  true
}

///|
pub type ClusterConfig3d = @pbr_cluster.ClusterConfig3d

///|
pub fn pbr_cluster_config_default() -> ClusterConfig3d {
  ClusterConfig3d::default()
}

///|
pub fn pbr_cluster_tile_count(config : ClusterConfig3d) -> Int {
  @pbr_cluster.pbr_cluster_tile_count(config)
}
