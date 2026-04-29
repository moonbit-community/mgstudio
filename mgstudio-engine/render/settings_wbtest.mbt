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
test "render settings: default render creation is automatic" {
  match RenderCreation::default() {
    Automatic(settings) => {
      debug_inspect(
        settings.priority == WgpuSettingsPriority::default(),
        content="true",
      )
      debug_inspect(settings.force_fallback_adapter, content="false")
    }
    Manual(_) => abort("default render creation should be automatic")
  }
}

///|
test "render settings: bevy renderer resources use distinct world keys" {
  let device_key = render_device_resource_key()
  let queue_key = render_queue_resource_key()
  let adapter_key = render_adapter_resource_key()
  let adapter_info_key = render_adapter_info_resource_key()
  let instance_key = render_instance_resource_key()
  let pipeline_cache_key = pipeline_cache_resource_key()
  debug_inspect(device_key.id() != queue_key.id(), content="true")
  debug_inspect(device_key.id() != adapter_key.id(), content="true")
  debug_inspect(adapter_key.id() != adapter_info_key.id(), content="true")
  debug_inspect(instance_key.id() != pipeline_cache_key.id(), content="true")
}
