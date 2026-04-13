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
test "pbr meshlet: runtime defaults to unavailable on current path" {
  inspect(meshlet_runtime_available(), content="false")
  inspect(meshlet_runtime_status() is RuntimeUnavailable, content="true")
}

///|
test "pbr meshlet: required feature mask includes texture atomics" {
  let required = meshlet_required_wgpu_features()
  inspect(required == @renderer.meshlet_required_rust_features_u64(), content="true")
  inspect((required & 0x0000000010000000UL) != 0UL, content="true")
  inspect((required & 0x0000400000000000UL) != 0UL, content="true")
}

///|
test "pbr meshlet: plugin clamps cluster buffer slots" {
  let plugin = MeshletPlugin::new(MESHLET_MAX_CLUSTER_BUFFER_SLOTS + 100)
  inspect(plugin.cluster_buffer_slots(), content="33554432")
}

///|
test "pbr meshlet: plugin state includes missing feature mask" {
  let state = MeshletPluginState::default()
  inspect(state.runtime_status is RuntimeUnavailable, content="true")
  inspect(
    (state.missing_required_features & meshlet_required_wgpu_features()) != 0UL,
    content="true",
  )
}
