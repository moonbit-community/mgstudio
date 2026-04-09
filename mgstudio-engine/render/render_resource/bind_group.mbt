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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/bind_group.rs`.

///|
pub struct BindGroup {
  id : BindGroupId
  value : @wgpu.BindGroup
}

///|
pub fn BindGroup::new(value : @wgpu.BindGroup) -> BindGroup {
  BindGroup::{ id: next_bind_group_id(), value }
}

///|
pub fn BindGroup::from_wgpu(value : @wgpu.BindGroup) -> BindGroup {
  BindGroup::new(value)
}

///|
pub fn BindGroup::id(self : BindGroup) -> BindGroupId {
  self.id
}

///|
pub fn BindGroup::set_label(self : BindGroup, label : String) -> Unit {
  self.value.set_label(label)
}

///|
pub fn BindGroup::into_inner(self : BindGroup) -> @wgpu.BindGroup {
  self.value
}

///|
pub fn BindGroup::same_id(self : BindGroup, other : BindGroup) -> Bool {
  self.id == other.id
}
