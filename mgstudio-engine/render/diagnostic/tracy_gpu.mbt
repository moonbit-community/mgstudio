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
// Bevy source: `bevy/crates/bevy_render/src/diagnostic/tracy_gpu.rs`.

///|
pub struct TracyGpuContext {
  backend : String
  created_at_us : Float
  enabled : Bool
}

///|
pub fn TracyGpuContext::new(
  backend : String,
  enabled : Bool,
) -> TracyGpuContext {
  TracyGpuContext::{ backend, created_at_us: @time.host_time_now(), enabled }
}

///|
pub fn TracyGpuContext::default() -> TracyGpuContext {
  TracyGpuContext::new("unsupported", false)
}

///|
pub fn TracyGpuContext::backend(self : TracyGpuContext) -> String {
  self.backend
}

///|
pub fn TracyGpuContext::created_at_us(self : TracyGpuContext) -> Float {
  self.created_at_us
}

///|
pub fn TracyGpuContext::enabled(self : TracyGpuContext) -> Bool {
  self.enabled
}

///|
pub fn tracy_gpu_context_enabled() -> Bool {
  false
}

///|
pub fn new_tracy_gpu_context() -> TracyGpuContext {
  TracyGpuContext::default()
}
