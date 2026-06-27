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
// Bevy source: `bevy/crates/bevy_render/src/globals.rs`.

///|
const GLOBALS_PLUGIN_NAME : String = "mgstudio.render.GlobalsPlugin"

///|
pub const GLOBALS_UNIFORM_SIZE_BYTES : Int = 16

///|
pub struct GlobalsPlugin {}

///|
pub fn GlobalsPlugin::GlobalsPlugin() -> GlobalsPlugin {
  GlobalsPlugin::{  }
}

///|
pub impl @app.Plugin for GlobalsPlugin with fn name(_self) {
  GLOBALS_PLUGIN_NAME
}

///|
pub impl @app.Plugin for GlobalsPlugin with fn build(_self, app) {
  try_with_render_app(app, fn(render_app) {
    render_app
    .add_systems(
      render_startup_schedule_stage(),
      @app.system(init_globals_buffer).named(
        "mgstudio_render::init_globals_buffer",
      ),
    )
    .add_systems(
      render_schedule_stage(),
      @app.system(prepare_globals_buffer)
      .named("mgstudio_render::prepare_globals_buffer")
      .in_set(render_system_set_prepare_resources),
    )
  })
}

///|
pub struct GlobalsUniform {
  time : Float
  delta_time : Float
  frame_count : UInt
}

///|
pub fn GlobalsUniform::GlobalsUniform() -> GlobalsUniform {
  GlobalsUniform::{ time: 0.0F, delta_time: 0.0F, frame_count: 0U }
}

///|
pub fn GlobalsUniform::new(
  time : Float,
  delta_time : Float,
  frame_count : UInt,
) -> GlobalsUniform {
  GlobalsUniform::{ time, delta_time, frame_count }
}

///|
pub fn GlobalsUniform::time(self : GlobalsUniform) -> Float {
  self.time
}

///|
pub fn GlobalsUniform::delta_time(self : GlobalsUniform) -> Float {
  self.delta_time
}

///|
pub fn GlobalsUniform::frame_count(self : GlobalsUniform) -> UInt {
  self.frame_count
}

///|
fn globals_uniform_push_u32_le(out : Array[Byte], value : UInt) -> Unit {
  out.push((value & 0xFFU).to_byte())
  out.push(((value >> 8) & 0xFFU).to_byte())
  out.push(((value >> 16) & 0xFFU).to_byte())
  out.push(((value >> 24) & 0xFFU).to_byte())
}

///|
fn globals_uniform_push_f32_le(out : Array[Byte], value : Float) -> Unit {
  globals_uniform_push_u32_le(out, value.reinterpret_as_uint())
}

///|
pub fn GlobalsUniform::bytes(self : GlobalsUniform) -> Bytes {
  let out : Array[Byte] = []
  globals_uniform_push_f32_le(out, self.time)
  globals_uniform_push_f32_le(out, self.delta_time)
  globals_uniform_push_u32_le(out, self.frame_count)
  globals_uniform_push_u32_le(out, 0U)
  Bytes::from_array(out)
}

///|
pub struct GlobalsBuffer {
  mut value : GlobalsUniform
  mut gpu_buffer : @wgpu.Buffer?
  mut gpu_capacity : UInt64
}

///|
pub fn GlobalsBuffer::GlobalsBuffer() -> GlobalsBuffer {
  GlobalsBuffer::{
    value: GlobalsUniform::GlobalsUniform(),
    gpu_buffer: None,
    gpu_capacity: 0UL,
  }
}

///|
pub fn GlobalsBuffer::value(self : GlobalsBuffer) -> GlobalsUniform {
  self.value
}

///|
pub fn GlobalsBuffer::set(self : GlobalsBuffer, value : GlobalsUniform) -> Unit {
  self.value = value
}

///|
fn globals_buffer_non_zero_u64(value : UInt64) -> UInt64 {
  if value == 0UL {
    4UL
  } else {
    value
  }
}

///|
pub fn GlobalsBuffer::write_buffer(
  self : GlobalsBuffer,
  render_device : RenderDevice,
  render_queue : RenderQueue,
) -> Unit {
  let bytes = self.value.bytes()
  let required_size = globals_buffer_non_zero_u64(bytes.length().to_uint64())
  let device = render_device.wgpu_device()
  let queue = render_queue.wgpu_queue()
  let usage = @wgpu.BufferUsage::from_u64(
    @wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST,
  )
  let buffer = match self.gpu_buffer {
    Some(existing) if self.gpu_capacity >= required_size => existing
    Some(existing) => {
      existing.release()
      let next = device.create_buffer(size=required_size, usage~)
      next.set_label("globals_buffer")
      self.gpu_capacity = required_size
      next
    }
    None => {
      let next = device.create_buffer(size=required_size, usage~)
      next.set_label("globals_buffer")
      self.gpu_capacity = required_size
      next
    }
  }
  queue.write_buffer(buffer, 0UL, bytes)
  self.gpu_buffer = Some(buffer)
}

///|
pub fn GlobalsBuffer::binding(self : GlobalsBuffer) -> @wgpu.Buffer? {
  self.gpu_buffer
}

///|
pub fn GlobalsBuffer::gpu_capacity(self : GlobalsBuffer) -> UInt64 {
  self.gpu_capacity
}

///|
pub let globals_buffer_resource_key : @ecs.ResourceKey[GlobalsBuffer] = @ecs.register_resource(
  debug_name="mgstudio_render::GlobalsBuffer",
)

///|
pub impl @app.Resource for GlobalsBuffer with fn resource() {
  globals_buffer_resource_key
}

///|
pub fn init_globals_buffer(render_world : @ecs.World) -> Unit {
  if render_world.resource(GlobalsBuffer::resource()).is_present() {
    return
  }
  render_world.insert_resource(
    GlobalsBuffer::resource(),
    GlobalsBuffer::GlobalsBuffer(),
  )
}

///|
fn globals_frame_count_from_world(world : @ecs.World) -> UInt {
  ignore(world)
  @renderer.frame_count()
}

///|
fn globals_time_from_world(world : @ecs.World) -> (Float, Float) {
  match world.get_resource(@time.default_time_resource_key) {
    Some(time) => (time.elapsed_secs_wrapped(), time.delta_secs())
    None => (0.0F, 0.0F)
  }
}

///|
fn globals_buffer_mut_or_init(
  render_world : @ecs.World,
) -> @ecs.ResourceMut[GlobalsBuffer] {
  if render_world.get_resource(GlobalsBuffer::resource()) is None {
    render_world.insert_resource(
      GlobalsBuffer::resource(),
      GlobalsBuffer::GlobalsBuffer(),
    )
  }
  match render_world.get_resource_mut(GlobalsBuffer::resource()) {
    Some(value) => value
    None => abort("missing GlobalsBuffer resource")
  }
}

///|
pub fn prepare_globals_buffer(render_world : @ecs.World) -> Unit {
  guard render_world.get_resource(render_device_resource_key)
    is Some(render_device) else {
    return
  }
  guard render_world.get_resource(render_queue_resource_key)
    is Some(render_queue) else {
    return
  }
  let source_world = render_source_world(render_world)
  let (time, delta_time) = globals_time_from_world(source_world)
  let frame_count = globals_frame_count_from_world(source_world)
  globals_buffer_mut_or_init(render_world).modify(fn(buffer) {
    buffer.set(GlobalsUniform::new(time, delta_time, frame_count))
    buffer.write_buffer(render_device, render_queue)
  })
}
