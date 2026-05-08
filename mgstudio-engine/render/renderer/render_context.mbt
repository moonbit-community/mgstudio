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
/// Global native GPU entry points.
///
/// This file is split from gpu.mbt to keep module boundaries closer to Bevy:
/// the backend implementation lives on `GpuBackend`, while runtime-facing entry points
/// (surface/frame binding + shared preprocess payload types) live here.
pub type NativeGpuDevice = Int

///|
pub type NativeGpuQueue = Int

///|
pub type NativeGpuSurface = Int

///|
pub type NativeGpuFrame = Int

///|
pub(all) struct PendingCommandBuffersInner {
  mut buffers : Array[@wgpu.CommandBuffer]
  mut encoders : Array[@wgpu.CommandEncoder]
}

///|
fn pending_command_buffers_inner_default() -> PendingCommandBuffersInner {
  { buffers: [], encoders: [] }
}

///|
/// A resource-shaped container for command buffers and command encoders pending
/// submission to the render queue.
///
/// This mirrors Bevy's `PendingCommandBuffers`: encoders are finished during
/// `take`, preserving the order in which render systems queued their work.
pub struct PendingCommandBuffers {
  inner : WgpuWrapper[PendingCommandBuffersInner]
}

///|
pub fn PendingCommandBuffers::default() -> PendingCommandBuffers {
  { inner: WgpuWrapper::new(pending_command_buffers_inner_default()) }
}

///|
pub fn PendingCommandBuffers::new() -> PendingCommandBuffers {
  PendingCommandBuffers::default()
}

///|
pub fn PendingCommandBuffers::push(
  self : PendingCommandBuffers,
  buffers : Array[@wgpu.CommandBuffer],
) -> Unit {
  let inner = self.inner.get()
  for buffer in buffers {
    inner.buffers.push(buffer)
  }
}

///|
pub fn PendingCommandBuffers::push_one(
  self : PendingCommandBuffers,
  buffer : @wgpu.CommandBuffer,
) -> Unit {
  self.inner.get().buffers.push(buffer)
}

///|
pub fn PendingCommandBuffers::push_encoder(
  self : PendingCommandBuffers,
  encoder : @wgpu.CommandEncoder,
) -> Unit {
  self.inner.get().encoders.push(encoder)
}

///|
pub fn PendingCommandBuffers::take(
  self : PendingCommandBuffers,
) -> Array[@wgpu.CommandBuffer] {
  let inner = self.inner.get()
  for encoder in inner.encoders {
    inner.buffers.push(encoder.finish())
  }
  inner.encoders = []
  let buffers = inner.buffers
  inner.buffers = []
  buffers
}

///|
pub fn PendingCommandBuffers::is_empty(self : PendingCommandBuffers) -> Bool {
  let inner = self.inner.get()
  inner.buffers.length() == 0 && inner.encoders.length() == 0
}

///|
pub fn PendingCommandBuffers::length(self : PendingCommandBuffers) -> Int {
  let inner = self.inner.get()
  inner.buffers.length() + inner.encoders.length()
}

///|
pub fn PendingCommandBuffers::len(self : PendingCommandBuffers) -> Int {
  self.length()
}

///|
pub(all) struct RenderContextStateInner {
  mut command_encoder : @wgpu.CommandEncoder?
  mut command_buffers : Array[@wgpu.CommandBuffer]
  mut render_device : RenderDevice?
}

///|
fn render_context_state_inner_default() -> RenderContextStateInner {
  { command_encoder: None, command_buffers: [], render_device: None }
}

///|
/// Render-context state used to accumulate one system's command encoder and
/// finished command buffers before they are moved into `PendingCommandBuffers`.
pub struct RenderContextState {
  inner : WgpuWrapper[RenderContextStateInner]
}

///|
pub fn RenderContextState::default() -> RenderContextState {
  { inner: WgpuWrapper::new(render_context_state_inner_default()) }
}

///|
pub fn RenderContextState::new() -> RenderContextState {
  RenderContextState::default()
}

///|
pub fn RenderContextState::set_render_device(
  self : RenderContextState,
  render_device : RenderDevice,
) -> Unit {
  self.inner.get().render_device = Some(render_device)
}

///|
fn RenderContextState::flush_encoder(self : RenderContextState) -> Unit {
  let inner = self.inner.get()
  if inner.command_encoder is Some(encoder) {
    inner.command_buffers.push(encoder.finish())
    inner.command_encoder = None
  }
}

///|
pub fn RenderContextState::command_encoder(
  self : RenderContextState,
) -> @wgpu.CommandEncoder {
  let inner = self.inner.get()
  match inner.command_encoder {
    Some(encoder) => encoder
    None => {
      guard inner.render_device is Some(render_device) else {
        abort("RenderDevice must be set before accessing command_encoder")
      }
      let encoder = render_device.create_command_encoder()
      inner.command_encoder = Some(encoder)
      encoder
    }
  }
}

///|
pub fn RenderContextState::add_command_buffer(
  self : RenderContextState,
  command_buffer : @wgpu.CommandBuffer,
) -> Unit {
  self.flush_encoder()
  self.inner.get().command_buffers.push(command_buffer)
}

///|
pub fn RenderContextState::finish(
  self : RenderContextState,
) -> Array[@wgpu.CommandBuffer] {
  self.flush_encoder()
  let inner = self.inner.get()
  let buffers = inner.command_buffers
  inner.command_buffers = []
  inner.render_device = None
  buffers
}

///|
pub fn RenderContextState::is_empty(self : RenderContextState) -> Bool {
  let inner = self.inner.get()
  inner.command_encoder is None && inner.command_buffers.length() == 0
}

///|
pub const SURFACE_PRESENT_MODE_AUTO_VSYNC : Int = 0

///|
pub const SURFACE_PRESENT_MODE_AUTO_NO_VSYNC : Int = 1

///|
pub const SURFACE_PRESENT_MODE_FIFO : Int = 2

///|
pub const SURFACE_PRESENT_MODE_FIFO_RELAXED : Int = 3

///|
pub const SURFACE_PRESENT_MODE_IMMEDIATE : Int = 4

///|
pub const SURFACE_PRESENT_MODE_MAILBOX : Int = 5

///|
pub const SURFACE_COMPOSITE_ALPHA_MODE_AUTO : Int = 0

///|
pub const SURFACE_COMPOSITE_ALPHA_MODE_OPAQUE : Int = 1

///|
pub const SURFACE_COMPOSITE_ALPHA_MODE_PRE_MULTIPLIED : Int = 2

///|
pub const SURFACE_COMPOSITE_ALPHA_MODE_POST_MULTIPLIED : Int = 3

///|
pub const SURFACE_COMPOSITE_ALPHA_MODE_INHERIT : Int = 4

///|
pub const SURFACE_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY : Int = 2

///|
const DEFAULT_ASSETS_DIR : String = "./assets"

///|
priv struct RenderContextRuntimeState {
  mut backend : GpuBackend?
}

///|
fn render_context_runtime_state_default() -> RenderContextRuntimeState {
  RenderContextRuntimeState::{ backend: None }
}

///|
let render_context_runtime_state_ref : Ref[RenderContextRuntimeState] = Ref(
  render_context_runtime_state_default(),
)

///|
fn env_or_default(key : String, default_value : String) -> String {
  match @sys.get_env_var(key) {
    Some(value) if value != "" => value
    _ => default_value
  }
}

///|
pub fn mesh3d_preprocess_disabled() -> Bool {
  match @sys.get_env_var("MGSTUDIO_RENDER3D_DISABLE_GPU_PREPROCESS") {
    Some(flag) => flag == "1"
    None => false
  }
}

///|
fn debug_runtime_error(context : String, err : Error) -> Unit {
  match err {
    Fatal(message) => debug("[renderer] \{context}: Fatal(\{message})")
    _ => debug("[renderer] \{context}: \{err.to_string()}")
  }
}

///|
fn ensure_backend() -> GpuBackend? {
  let state = render_context_runtime_state_ref.val
  if state.backend is Some(backend) {
    return Some(backend)
  }
  let assets_base = env_or_default("MGSTUDIO_ASSETS_DIR", DEFAULT_ASSETS_DIR)
  let backend = GpuBackend::new(assets_base~) catch { _ => return None }
  state.backend = Some(backend)
  Some(backend)
}

///|
pub fn render_context_backend_for_test() -> GpuBackend? {
  render_context_runtime_state_ref.val.backend
}

///|
pub fn render_context_set_backend_for_test(backend : GpuBackend?) -> Unit {
  render_context_runtime_state_ref.val.backend = backend
}

///|
pub fn debug_string(value~ : String) -> Unit {
  debug(value)
}
