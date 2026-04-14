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
// Bevy source: `bevy/crates/bevy_render/src/settings.rs`.

///|
pub(all) enum WgpuSettingsPriority {
  Compatibility
  Functionality
  WebGL2
} derive(Eq, Debug)

///|
pub fn WgpuSettingsPriority::default() -> WgpuSettingsPriority {
  Functionality
}

///|
pub struct WgpuSettings {
  device_label : String?
  backends : String?
  power_preference : String
  priority : WgpuSettingsPriority
  features_mask : UInt64
  disabled_features_mask : UInt64
  limits_profile : String
  constrained_limits_profile : String?
  force_fallback_adapter : Bool
  adapter_name : String?
} derive(Eq, Debug)

///|
pub fn WgpuSettings::default() -> WgpuSettings {
  WgpuSettings::{
    device_label: None,
    backends: Some("all"),
    power_preference: "high_performance",
    priority: Functionality,
    features_mask: 0UL,
    disabled_features_mask: 0UL,
    limits_profile: "default",
    constrained_limits_profile: None,
    force_fallback_adapter: false,
    adapter_name: None,
  }
}

///|
pub fn WgpuSettings::with_priority(
  self : WgpuSettings,
  priority : WgpuSettingsPriority,
) -> WgpuSettings {
  WgpuSettings::{ ..self, priority, }
}

///|
pub fn WgpuSettings::with_backends(
  self : WgpuSettings,
  backends : String?,
) -> WgpuSettings {
  WgpuSettings::{ ..self, backends, }
}

///|
pub fn WgpuSettings::with_power_preference(
  self : WgpuSettings,
  power_preference : String,
) -> WgpuSettings {
  WgpuSettings::{ ..self, power_preference, }
}

///|
pub fn WgpuSettings::with_adapter_name(
  self : WgpuSettings,
  adapter_name : String?,
) -> WgpuSettings {
  WgpuSettings::{ ..self, adapter_name, }
}

///|
pub fn WgpuSettings::with_force_fallback_adapter(
  self : WgpuSettings,
  force_fallback_adapter : Bool,
) -> WgpuSettings {
  WgpuSettings::{ ..self, force_fallback_adapter, }
}

///|
pub struct RenderResources {
  device_id : Int
  queue_id : Int
  adapter_name : String
} derive(Eq, Debug)

///|
pub fn RenderResources::new(
  device_id~ : Int,
  queue_id~ : Int,
  adapter_name~ : String,
) -> RenderResources {
  RenderResources::{ device_id, queue_id, adapter_name }
}

///|
pub(all) enum RenderCreation {
  Manual(RenderResources)
  Automatic(WgpuSettings)
} derive(Eq, Debug)

///|
pub fn RenderCreation::manual(resources : RenderResources) -> RenderCreation {
  Manual(resources)
}

///|
pub fn RenderCreation::automatic(settings : WgpuSettings) -> RenderCreation {
  Automatic(settings)
}

///|
pub fn host_gpu_set_mesh3d_gpu_instance_builder_enabled(enabled : Bool) -> Unit {
  @renderer.set_mesh3d_gpu_instance_builder_enabled(enabled)
}

///|
pub fn host_gpu_mesh3d_indirect_first_instance_supported() -> Bool {
  @renderer.mesh3d_indirect_first_instance_supported()
}

///|
pub fn host_gpu_mesh3d_gpu_culling_supported() -> Bool {
  @renderer.mesh3d_gpu_culling_supported()
}

///|
pub fn host_gpu_mesh3d_preprocess_disabled() -> Bool {
  @renderer.mesh3d_preprocess_disabled()
}

///|
pub fn host_gpu_read_only_binding_type_uniform(
  required_storage_buffers : Int,
) -> Bool {
  @renderer.read_only_binding_type_uniform(required_storage_buffers)
}
