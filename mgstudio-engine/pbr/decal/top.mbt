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
// Bevy source: `bevy/crates/bevy_pbr/src/decal/mod.rs`.

///|
pub const CLUSTERED_DECAL_PLUGIN_ID : String = "bevy_pbr::ClusteredDecalPlugin"

///|
pub struct DecalPluginState {
  forward_enabled : Bool
  clustered_enabled : Bool
}

///|
pub fn DecalPluginState::default() -> DecalPluginState {
  DecalPluginState::{ forward_enabled: true, clustered_enabled: true }
}

///|
pub fn DecalPluginState::forward_enabled(self : DecalPluginState) -> Bool {
  self.forward_enabled
}

///|
pub fn DecalPluginState::clustered_enabled(self : DecalPluginState) -> Bool {
  self.clustered_enabled
}

///|
pub fn forward_decal() -> ForwardDecal {
  ForwardDecal::default()
}

///|
pub fn clustered_decal() -> ClusteredDecal {
  ClusteredDecal::default()
}

///|
pub fn clustered_decal_with_tag(tag : Int) -> ClusteredDecal {
  ClusteredDecal::default().with_tag(tag)
}

///|
pub fn clustered_decal_with_base_color_texture(
  texture : @asset.Handle[@asset.Image]?,
) -> ClusteredDecal {
  ClusteredDecal::default().with_base_color_texture(texture)
}
