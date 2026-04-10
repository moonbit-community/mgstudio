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
// Bevy source: `bevy/crates/bevy_light/src/cluster/test.rs`.
// Bridge helper for clustered-light module test wiring.

///|
///|
pub struct LightClusterTestBridge {
}

///|
pub fn LightClusterTestBridge::default() -> LightClusterTestBridge {
  LightClusterTestBridge::{  }
}

///|
pub fn cluster_test_enabled() -> Bool {
  true
}

///|
pub fn light_cluster_test_bridge_enabled(
  _ : LightClusterTestBridge,
) -> Bool {
  cluster_test_enabled()
}

