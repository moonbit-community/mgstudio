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
/// Bevy source: `bevy/crates/bevy_render/src/renderer/wgpu_wrapper.rs`.
///
/// Native MoonBit builds do not need the wasm atomics `SendWrapper` branch,
/// so this is a direct transparent wrapper. Keeping the wrapper in the public
/// renderer model lets `RenderDevice`, `RenderQueue`, and render-context state
/// follow the same ownership shape as Bevy.
pub struct WgpuWrapper[T] {
  mut value : T
}

///|
pub fn[T] WgpuWrapper::new(value : T) -> WgpuWrapper[T] {
  { value, }
}

///|
pub fn[T] WgpuWrapper::get(self : WgpuWrapper[T]) -> T {
  self.value
}

///|
pub fn[T] WgpuWrapper::set(self : WgpuWrapper[T], value : T) -> Unit {
  self.value = value
}

///|
pub fn[T] WgpuWrapper::into_inner(self : WgpuWrapper[T]) -> T {
  self.value
}

///|
fn create_pipeline_layout_3(
  device : @wgpu.Device,
  bind_group_layout0 : @wgpu.BindGroupLayout,
  bind_group_layout1 : @wgpu.BindGroupLayout,
  bind_group_layout2 : @wgpu.BindGroupLayout,
) -> @wgpu.PipelineLayout {
  device.create_pipeline_layout_many([
    bind_group_layout0, bind_group_layout1, bind_group_layout2,
  ])
}

///|
fn command_encoder_begin_render_pass_depth_u32(
  encoder : @wgpu.CommandEncoder,
  depth_view : @wgpu.TextureView,
  depth_load_op_u32~ : UInt,
  depth_store_op_u32~ : UInt,
  depth_clear_value_f32~ : Float,
  stencil_load_op_u32~ : UInt,
  stencil_store_op_u32~ : UInt,
  stencil_clear_value_u32~ : UInt,
  depth_read_only~ : Bool,
  stencil_read_only~ : Bool,
) -> @wgpu.RenderPass {
  encoder.begin_render_pass_depth_u32(
    depth_view,
    depth_load_op_u32~,
    depth_store_op_u32~,
    depth_clear_value_f32~,
    stencil_load_op_u32~,
    stencil_store_op_u32~,
    stencil_clear_value_u32~,
    depth_read_only~,
    stencil_read_only~,
  )
}

///|
fn create_pipeline_layout_4(
  device : @wgpu.Device,
  bind_group_layout0 : @wgpu.BindGroupLayout,
  bind_group_layout1 : @wgpu.BindGroupLayout,
  bind_group_layout2 : @wgpu.BindGroupLayout,
  bind_group_layout3 : @wgpu.BindGroupLayout,
) -> @wgpu.PipelineLayout {
  device.create_pipeline_layout_many([
    bind_group_layout0, bind_group_layout1, bind_group_layout2, bind_group_layout3,
  ])
}
