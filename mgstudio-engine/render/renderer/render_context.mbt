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
let render_context_runtime_state_ref : Ref[RenderContextRuntimeState] = Ref::new(
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
  debug("[renderer] \{context}: \{err.to_string()}")
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
