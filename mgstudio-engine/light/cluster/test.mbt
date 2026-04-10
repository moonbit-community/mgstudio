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
pub const LIGHT_CLUSTER_TEST_MODULE_TAG : String = "bevy_light::cluster::test"

///|
pub struct LightClusterTestBridge {
  module_tag : String
}

///|
pub fn LightClusterTestBridge::default() -> LightClusterTestBridge {
  LightClusterTestBridge::{ module_tag: LIGHT_CLUSTER_TEST_MODULE_TAG }
}

///|
pub fn cluster_test_enabled() -> Bool {
  true
}

///|
pub fn light_cluster_test_bridge_enabled(
  bridge : LightClusterTestBridge,
) -> Bool {
  bridge.module_tag == LIGHT_CLUSTER_TEST_MODULE_TAG && cluster_test_enabled()
}

///|
pub fn light_cluster_test_bridge_module_tag(
  bridge : LightClusterTestBridge,
) -> String {
  bridge.module_tag
}
