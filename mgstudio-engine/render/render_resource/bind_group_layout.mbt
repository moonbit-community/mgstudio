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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/bind_group_layout.rs`.

///|
pub struct BindGroupLayout {
  id : BindGroupLayoutId
  value : @wgpu.BindGroupLayout
}

///|
pub struct BindGroupLayoutEntry {
  binding : Int
  visibility : UInt
  kind : BindingType
}

///|
pub struct BindGroupLayoutDescriptor {
  entries : Array[BindGroupLayoutEntry]
}

///|
pub fn BindGroupLayout::new(value : @wgpu.BindGroupLayout) -> BindGroupLayout {
  BindGroupLayout::{ id: next_bind_group_layout_id(), value }
}

///|
pub fn BindGroupLayout::from_wgpu(
  value : @wgpu.BindGroupLayout,
) -> BindGroupLayout {
  BindGroupLayout::new(value)
}

///|
pub fn BindGroupLayout::id(self : BindGroupLayout) -> BindGroupLayoutId {
  self.id
}

///|
pub fn BindGroupLayout::set_label(
  self : BindGroupLayout,
  label : String,
) -> Unit {
  self.value.set_label(label)
}

///|
pub fn BindGroupLayout::into_inner(
  self : BindGroupLayout,
) -> @wgpu.BindGroupLayout {
  self.value
}

///|
pub fn BindGroupLayoutEntry::new(
  binding : Int,
  visibility : UInt,
  kind : BindingType,
) -> BindGroupLayoutEntry {
  BindGroupLayoutEntry::{ binding, visibility, kind }
}

///|
pub fn BindGroupLayoutEntry::binding(self : BindGroupLayoutEntry) -> Int {
  self.binding
}

///|
pub fn BindGroupLayoutEntry::visibility(self : BindGroupLayoutEntry) -> UInt {
  self.visibility
}

///|
pub fn BindGroupLayoutEntry::kind(self : BindGroupLayoutEntry) -> BindingType {
  self.kind
}

///|
pub fn BindGroupLayoutDescriptor::new(
  entries : Array[BindGroupLayoutEntry],
) -> BindGroupLayoutDescriptor {
  BindGroupLayoutDescriptor::{ entries, }
}

///|
pub fn BindGroupLayoutDescriptor::entries(
  self : BindGroupLayoutDescriptor,
) -> Array[BindGroupLayoutEntry] {
  self.entries
}
