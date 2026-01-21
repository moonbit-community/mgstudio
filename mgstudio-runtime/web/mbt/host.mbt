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
/// Browser host runtime implemented in MoonBit.
extern "js" fn console_error(value : @js.Any) -> Unit =
  #| (value) => console.error(value)

///|
extern "js" fn throw_error(message : String) -> Unit =
  #| (message) => { throw new Error(message) }

///|
extern "js" fn any_to_string(value : @js.Any) -> String =
  #| (value) => String(value)

///|
extern "js" fn host_is_nullish(value : @js.Any) -> Bool =
  #| (value) => value == null

///|
extern "js" fn js_null() -> @js.Any =
  #| () => null

///|
extern "js" fn js_undefined() -> @js.Any =
  #| () => undefined

///|
extern "js" fn host_call0_any(func : @js.Any) -> @js.Any =
  #| (func) => func()

///|
extern "js" fn number_or(value : @js.Any, fallback : Double) -> Double =
  #| (value, fallback) => {
  #|   const num = Number(value)
  #|   return Number.isFinite(num) ? num : fallback
  #| }

///|
extern "js" fn request_animation_frame(callback : @js.Any) -> Unit =
  #| (callback) => requestAnimationFrame(callback)

///|
extern "js" fn add_event_listener(
  target : @js.Any,
  event_name : String,
  handler : @js.Any,
) -> Unit =
  #| (target, eventName, handler) => target.addEventListener(eventName, handler)

///|
extern "js" fn wrap_variadic(func : @js.Any) -> @js.Any =
  #| (func) => (...args) => func(args)

///|
extern "js" fn performance_now() -> Double =
  #| () => performance.now()

///|
extern "js" fn get_canvas_pixel_size(canvas : @js.Any) -> @js.Any =
  #| (canvas) => {
  #|   const dpr = window.devicePixelRatio || 1
  #|   const width = Math.max(1, Math.floor(canvas.clientWidth * dpr))
  #|   const height = Math.max(1, Math.floor(canvas.clientHeight * dpr))
  #|   return { width, height }
  #| }

///|
extern "js" fn get_bounding_rect(canvas : @js.Any) -> @js.Any =
  #| (canvas) => canvas.getBoundingClientRect()

///|
extern "js" fn prevent_default(event : @js.Any) -> Unit =
  #| (event) => event.preventDefault()

///|
extern "js" fn coerce_asset_path(path : @js.Any) -> String =
  #| (path) => {
  #|   if (path == null) {
  #|     throw new Error("Asset path is required")
  #|   }
  #|   let current = path
  #|   for (let i = 0; i < 4; i += 1) {
  #|     if (typeof current === "string") {
  #|       return current
  #|     }
  #|     if (typeof current === "number" || typeof current === "bigint" || typeof current === "boolean") {
  #|       return `${current}`
  #|     }
  #|     if (typeof current === "object") {
  #|       if (typeof current.value === "string") {
  #|         return current.value
  #|       }
  #|       if (typeof current.string === "string") {
  #|         return current.string
  #|       }
  #|       if (typeof current.toString === "function") {
  #|         try {
  #|           current = current.toString()
  #|           continue
  #|         } catch {
  #|         }
  #|       }
  #|       if (typeof current.valueOf === "function") {
  #|         try {
  #|           current = current.valueOf()
  #|           continue
  #|         } catch {
  #|         }
  #|       }
  #|     }
  #|     break
  #|   }
  #|   throw new Error(`Unsupported asset path type: ${typeof path}`)
  #| }

///|
extern "js" fn is_external_asset_url(text : String) -> Bool =
  #| (text) => /^(https?:)?\/\//.test(text) || text.startsWith("data:")

///|
extern "js" fn strip_leading_slashes(text : String) -> String =
  #| (text) => text.replace(/^\/+/, "")

///|
extern "js" fn new_map() -> @js.Any =
  #| () => new Map()

///|
extern "js" fn new_set() -> @js.Any =
  #| () => new Set()

///|
extern "js" fn map_set(map : @js.Any, key : @js.Any, value : @js.Any) -> Unit =
  #| (map, key, value) => map.set(key, value)

///|
extern "js" fn map_get(map : @js.Any, key : @js.Any) -> @js.Any =
  #| (map, key) => map.get(key)

///|
extern "js" fn set_add(set : @js.Any, value : @js.Any) -> Unit =
  #| (set, value) => set.add(value)

///|
extern "js" fn set_has(set : @js.Any, value : @js.Any) -> Bool =
  #| (set, value) => set.has(value)

///|
extern "js" fn set_delete(set : @js.Any, value : @js.Any) -> Bool =
  #| (set, value) => set.delete(value)

///|
extern "js" fn set_clear(set : @js.Any) -> Unit =
  #| (set) => set.clear()

///|
extern "js" fn dispatch_asset_error(message : String) -> Unit =
  #| (message) => {
  #|   window.dispatchEvent(new CustomEvent("mgstudio-asset-error", { detail: message }))
  #| }

///|
extern "js" fn create_canvas_element() -> @js.Any =
  #| () => document.createElement("canvas")

///|
extern "js" fn append_canvas_to_body(canvas : @js.Any) -> Unit =
  #| (canvas) => document.body.appendChild(canvas)

///|
extern "js" fn create_checkerboard_data(size : Int) -> @js.Any =
  #| (size) => {
  #|   const data = new Uint8Array(size * size * 4)
  #|   for (let y = 0; y < size; y += 1) {
  #|     for (let x = 0; x < size; x += 1) {
  #|       const offset = (y * size + x) * 4
  #|       const checker = ((x >> 3) ^ (y >> 3)) & 1
  #|       const base = checker ? 220 : 40
  #|       data[offset] = base
  #|       data[offset + 1] = 120
  #|       data[offset + 2] = 255 - base
  #|       data[offset + 3] = 255
  #|     }
  #|   }
  #|   return data
  #| }

///|
extern "js" fn create_sprite_vertices() -> @js.Any =
  #| () => new Float32Array([
  #|   -64.0, 64.0, 0.0, 0.0,
  #|   -64.0, -64.0, 0.0, 1.0,
  #|   64.0, -64.0, 1.0, 1.0,
  #|   -64.0, 64.0, 0.0, 0.0,
  #|   64.0, -64.0, 1.0, 1.0,
  #|   64.0, 64.0, 1.0, 0.0,
  #| ])

///|
extern "js" fn create_rectangle_mesh_data(
  width : Double,
  height : Double,
) -> @js.Any =
  #| (width, height) => {
  #|   const w = Number(width) || 1
  #|   const h = Number(height) || 1
  #|   const halfW = w / 2
  #|   const halfH = h / 2
  #|   return new Float32Array([
  #|     -halfW, -halfH,
  #|     halfW, -halfH,
  #|     halfW, halfH,
  #|     -halfW, -halfH,
  #|     halfW, halfH,
  #|     -halfW, halfH,
  #|   ])
  #| }

///|
extern "js" fn create_capsule_mesh_data(
  radius : Double,
  half_length : Double,
  segments : Int,
) -> @js.Any =
  #| (radius, halfLength, segments) => {
  #|   const r = Number(radius) || 0.5
  #|   const half = Number(halfLength) || 0.5
  #|   const seg = Math.max(6, Math.floor(Number(segments) || 16))
  #|   const points = []
  #|   for (let i = 0; i <= seg; i += 1) {
  #|     const angle = Math.PI - (i / seg) * Math.PI
  #|     points.push([Math.cos(angle) * r, half + Math.sin(angle) * r])
  #|   }
  #|   for (let i = 0; i <= seg; i += 1) {
  #|     const angle = -(i / seg) * Math.PI
  #|     points.push([Math.cos(angle) * r, -half + Math.sin(angle) * r])
  #|   }
  #|   const vertexData = []
  #|   const cx = 0
  #|   const cy = 0
  #|   const count = points.length
  #|   for (let i = 0; i < count; i += 1) {
  #|     const p0 = points[i]
  #|     const p1 = points[(i + 1) % count]
  #|     vertexData.push(cx, cy, p0[0], p0[1], p1[0], p1[1])
  #|   }
  #|   return new Float32Array(vertexData)
  #| }

///|
extern "js" fn float32array_from_array(values : Array[Double]) -> @js.Any =
  #| (values) => new Float32Array(values)

///|
extern "js" fn math_cos(value : Double) -> Double =
  #| (value) => Math.cos(value)

///|
extern "js" fn math_sin(value : Double) -> Double =
  #| (value) => Math.sin(value)

///|
extern "js" fn request_adapter_any() -> @js.Promise[@js.Any] =
  #| () => navigator.gpu.requestAdapter()

///|
extern "js" fn request_device_any(adapter : @js.Any) -> @js.Promise[@js.Any] =
  #| (adapter) => adapter.requestDevice()

///|
extern "js" fn copy_external_image_to_texture(
  queue : @js.Any,
  image : @js.Any,
  texture : @js.Any,
  width : Int,
  height : Int,
) -> Unit =
  #| (queue, image, texture, width, height) => {
  #|   queue.copyExternalImageToTexture({ source: image }, { texture }, [width, height])
  #| }

///|
extern "js" fn write_texture(
  queue : @js.Any,
  texture : @js.Any,
  data : @js.Any,
  bytes_per_row : Int,
  width : Int,
  height : Int,
) -> Unit =
  #| (queue, texture, data, bytesPerRow, width, height) => {
  #|   queue.writeTexture({ texture }, data, { bytesPerRow }, [width, height, 1])
  #| }

///|
extern "js" fn create_image_bitmap(blob : @js.Any) -> @js.Promise[@js.Any] =
  #| (blob) => createImageBitmap(blob, { premultiplyAlpha: "none", colorSpaceConversion: "none" })

///|
extern "js" fn response_blob(response : @js.Any) -> @js.Promise[@js.Any] =
  #| (response) => response.blob()

///|
extern "js" fn sprite_shader_code() -> String =
  #| () => `
  #| struct VertexOut {
  #|   @builtin(position) position : vec4<f32>,
  #|   @location(0) uv : vec2<f32>,
  #| };
  #| 
  #| struct TransformData {
  #|   model : vec4<f32>,
  #|   view : vec4<f32>,
  #|   scale : vec4<f32>,
  #|   color : vec4<f32>,
  #| };
  #| 
  #| @group(0) @binding(0) var samp : sampler;
  #| @group(0) @binding(1) var tex : texture_2d<f32>;
  #| @group(0) @binding(2) var<uniform> u_transform : TransformData;
  #| 
  #| @vertex
  #| fn vs_main(
  #|   @location(0) position : vec2<f32>,
  #|   @location(1) uv : vec2<f32>
  #| ) -> VertexOut {
  #|   var out : VertexOut;
  #|   let cosv = u_transform.model.z;
  #|   let sinv = u_transform.model.w;
  #|   let scaled = vec2<f32>(
  #|     position.x * u_transform.scale.z,
  #|     position.y * u_transform.scale.w
  #|   );
  #|   let rotated = vec2<f32>(
  #|     scaled.x * cosv - scaled.y * sinv,
  #|     scaled.x * sinv + scaled.y * cosv
  #|   );
  #|   let translated = rotated + u_transform.model.xy;
  #|   let cam_cos = u_transform.view.z;
  #|   let cam_sin = u_transform.view.w;
  #|   let rel = translated - u_transform.view.xy;
  #|   let view_pos = vec2<f32>(
  #|     rel.x * cam_cos - rel.y * cam_sin,
  #|     rel.x * cam_sin + rel.y * cam_cos
  #|   );
  #|   let ndc = vec2<f32>(
  #|     view_pos.x * u_transform.scale.x,
  #|     view_pos.y * u_transform.scale.y
  #|   );
  #|   out.position = vec4<f32>(ndc, 0.0, 1.0);
  #|   out.uv = uv;
  #|   return out;
  #| }
  #| 
  #| @fragment
  #| fn fs_main(@location(0) uv : vec2<f32>) -> @location(0) vec4<f32> {
  #|   return textureSample(tex, samp, uv) * u_transform.color;
  #| }
  #| `

///|
extern "js" fn mesh_shader_code() -> String =
  #| () => `
  #| struct VertexOut {
  #|   @builtin(position) position : vec4<f32>,
  #| };
  #| 
  #| struct TransformData {
  #|   model : vec4<f32>,
  #|   view : vec4<f32>,
  #|   scale : vec4<f32>,
  #|   color : vec4<f32>,
  #| };
  #| 
  #| @group(0) @binding(0) var<uniform> u_transform : TransformData;
  #| 
  #| @vertex
  #| fn vs_main(@location(0) position : vec2<f32>) -> VertexOut {
  #|   var out : VertexOut;
  #|   let cosv = u_transform.model.z;
  #|   let sinv = u_transform.model.w;
  #|   let scaled = vec2<f32>(
  #|     position.x * u_transform.scale.z,
  #|     position.y * u_transform.scale.w
  #|   );
  #|   let rotated = vec2<f32>(
  #|     scaled.x * cosv - scaled.y * sinv,
  #|     scaled.x * sinv + scaled.y * cosv
  #|   );
  #|   let translated = rotated + u_transform.model.xy;
  #|   let cam_cos = u_transform.view.z;
  #|   let cam_sin = u_transform.view.w;
  #|   let rel = translated - u_transform.view.xy;
  #|   let view_pos = vec2<f32>(
  #|     rel.x * cam_cos - rel.y * cam_sin,
  #|     rel.x * cam_sin + rel.y * cam_cos
  #|   );
  #|   let ndc = vec2<f32>(
  #|     view_pos.x * u_transform.scale.x,
  #|     view_pos.y * u_transform.scale.y
  #|   );
  #|   out.position = vec4<f32>(ndc, 0.0, 1.0);
  #|   return out;
  #| }
  #| 
  #| @fragment
  #| fn fs_main() -> @location(0) vec4<f32> {
  #|   return u_transform.color;
  #| }
  #| `

///|
struct PendingTexture {
  id : Int
  path : @js.Any
  nearest : Bool
}

///|
struct PassInfo {
  width : Double
  height : Double
  cam_x : Double
  cam_y : Double
  cam_rotation : Double
  cam_scale : Double
}

///|
struct WindowState {
  canvas : @js.Any
  mut width : Int
  mut height : Int
}

///|
struct AssetsState {
  pending_textures : Array[PendingTexture]
  fallback_reported : @js.Any
  loading_textures : @js.Any
  texture_paths : @js.Any
}

///|
struct InputState {
  pressed : @js.Any
  just_pressed : @js.Any
  just_released : @js.Any
  mouse_buttons : @js.Any
  mouse_just_pressed : @js.Any
  mouse_just_released : @js.Any
  mut mouse_x : Double
  mut mouse_y : Double
  mut has_cursor : Bool
  mut pointer_bound : Bool
  mut initialized : Bool
}

///|
struct GpuState {
  mut device : @webgpu.GPUDevice?
  mut queue : @webgpu.GPUQueue?
  mut context : @webgpu.GPUCanvasContext?
  mut format : String?
  mut pipeline : @webgpu.GPURenderPipeline?
  mut vertex_buffer : @webgpu.GPUBuffer?
  mut vertex_count : Int
  mut mesh_pipeline : @webgpu.GPURenderPipeline?
  mut mesh_bind_group : @webgpu.GPUBindGroup?
  mut meshes : @js.Any
  mut next_mesh_id : Int
  mut uniform_buffer : @webgpu.GPUBuffer?
  mut encoder : @webgpu.GPUCommandEncoder?
  mut current_texture : @webgpu.GPUTexture?
  mut current_pass : @webgpu.GPURenderPassEncoder?
  mut current_pass_info : PassInfo?
  mut textures : @js.Any
  mut next_texture_id : Int
  mut fallback_texture_id : Int
}

///|
struct State {
  mut window : WindowState?
  mut should_close : Bool
  assets : AssetsState
  input : InputState
  gpu : GpuState
}

///|
fn new_state() -> State {
  State::{
    window: None,
    should_close: false,
    assets: AssetsState::{
      pending_textures: [],
      fallback_reported: new_set(),
      loading_textures: new_set(),
      texture_paths: new_map(),
    },
    input: InputState::{
      pressed: new_set(),
      just_pressed: new_set(),
      just_released: new_set(),
      mouse_buttons: new_set(),
      mouse_just_pressed: new_set(),
      mouse_just_released: new_set(),
      mouse_x: 0,
      mouse_y: 0,
      has_cursor: false,
      pointer_bound: false,
      initialized: false,
    },
    gpu: GpuState::{
      device: None,
      queue: None,
      context: None,
      format: None,
      pipeline: None,
      vertex_buffer: None,
      vertex_count: 0,
      mesh_pipeline: None,
      mesh_bind_group: None,
      meshes: new_map(),
      next_mesh_id: 1,
      uniform_buffer: None,
      encoder: None,
      current_texture: None,
      current_pass: None,
      current_pass_info: None,
      textures: new_map(),
      next_texture_id: 1,
      fallback_texture_id: 0,
    },
  }
}

///|
fn to_int(value : Double) -> Int {
  value.to_int()
}

///|
fn resolve_asset_url(path : @js.Any) -> String raise {
  let text = coerce_asset_path(path)
  if text.length() == 0 {
    fail("Asset path is empty")
  }
  if is_external_asset_url(text) {
    text
  } else {
    let normalized = strip_leading_slashes(text)
    "./assets/" + normalized
  }
}

///|
fn ensure_canvas(canvas_opt : @dom.Element?) -> @js.Any {
  if canvas_opt is Some(canvas) {
    canvas.as_any()
  } else {
    let target = create_canvas_element()
    append_canvas_to_body(target)
    target
  }
}

///|
fn update_window_size(state : State) -> Unit {
  if state.window is None {
    return
  }
  if state.window is Some(window_state) {
    let target = window_state.canvas
    let size = get_canvas_pixel_size(target)
    let width : Int = size._get("width").cast()
    let height : Int = size._get("height").cast()
    if width == window_state.width && height == window_state.height {
      return
    }
    window_state.width = width
    window_state.height = height
    target._set("width", @js.any(width)) |> ignore
    target._set("height", @js.any(height)) |> ignore
    if state.gpu.context is Some(context) && state.gpu.device is Some(device) {
      let usage = @webgpu.texture_usage_render_attachment()
      let descriptor = @js.from_entries([
        ("device", device.as_any()),
        ("format", @js.any(state.gpu.format.unwrap_or("bgra8unorm"))),
        ("alphaMode", @js.any("premultiplied")),
        ("usage", @js.any(usage)),
        ("size", @js.any([width, height])),
      ])
      context.configure(descriptor)
    }
  }
}

///|
fn init_input(state : State) -> Unit {
  if state.input.initialized {
    return
  }
  state.input.initialized = true
  let win = @dom.window().as_any()
  add_event_listener(
    win,
    "keydown",
    @js.from_fn1(fn(event : @js.Any) {
      let repeat_value : Bool = event._get("repeat").cast()
      if repeat_value {
        return
      }
      let code = any_to_string(event._get("code").cast())
      if !set_has(state.input.pressed, @js.any(code)) {
        set_add(state.input.pressed, @js.any(code))
        set_add(state.input.just_pressed, @js.any(code))
      }
    }),
  )
  add_event_listener(
    win,
    "keyup",
    @js.from_fn1(fn(event : @js.Any) {
      let code = any_to_string(event._get("code").cast())
      if set_delete(state.input.pressed, @js.any(code)) {
        set_add(state.input.just_released, @js.any(code))
      }
    }),
  )
  add_event_listener(
    win,
    "blur",
    @js.from_fn1(fn(_ : @js.Any) {
      set_clear(state.input.pressed)
      set_clear(state.input.just_pressed)
      set_clear(state.input.just_released)
    }),
  )
}

///|
fn mouse_button_name(button : Int) -> String? {
  if button == 0 {
    Some("Left")
  } else if button == 1 {
    Some("Middle")
  } else if button == 2 {
    Some("Right")
  } else {
    None
  }
}

///|
fn update_mouse_position(
  state : State,
  target : @js.Any,
  event : @js.Any,
) -> Unit {
  let rect = get_bounding_rect(target)
  let rect_width : Double = rect._get("width").cast()
  let rect_height : Double = rect._get("height").cast()
  let target_width : Double = target._get("width").cast()
  let target_height : Double = target._get("height").cast()
  let scale_x = if rect_width > 0 { target_width / rect_width } else { 1 }
  let scale_y = if rect_height > 0 { target_height / rect_height } else { 1 }
  let client_x : Double = event._get("clientX").cast()
  let client_y : Double = event._get("clientY").cast()
  let left : Double = rect._get("left").cast()
  let top : Double = rect._get("top").cast()
  state.input.mouse_x = (client_x - left) * scale_x
  state.input.mouse_y = (client_y - top) * scale_y
  state.input.has_cursor = true
}

///|
fn bind_pointer_events(state : State, target : @js.Any) -> Unit {
  if state.input.pointer_bound {
    return
  }
  state.input.pointer_bound = true
  add_event_listener(
    target,
    "pointermove",
    @js.from_fn1(fn(event : @js.Any) {
      update_mouse_position(state, target, event)
    }),
  )
  add_event_listener(
    target,
    "pointerdown",
    @js.from_fn1(fn(event : @js.Any) {
      let button : Int = event._get("button").cast()
      let name = mouse_button_name(button)
      if name is Some(label) {
        if !set_has(state.input.mouse_buttons, @js.any(label)) {
          set_add(state.input.mouse_buttons, @js.any(label))
          set_add(state.input.mouse_just_pressed, @js.any(label))
        }
      }
      update_mouse_position(state, target, event)
    }),
  )
  add_event_listener(
    target,
    "pointerup",
    @js.from_fn1(fn(event : @js.Any) {
      let button : Int = event._get("button").cast()
      let name = mouse_button_name(button)
      if name is Some(label) {
        if set_delete(state.input.mouse_buttons, @js.any(label)) {
          set_add(state.input.mouse_just_released, @js.any(label))
        }
      }
      update_mouse_position(state, target, event)
    }),
  )
  add_event_listener(
    target,
    "pointerleave",
    @js.from_fn1(fn(_ : @js.Any) { state.input.has_cursor = false }),
  )
  add_event_listener(
    target,
    "contextmenu",
    @js.from_fn1(fn(event : @js.Any) { prevent_default(event) }),
  )
}

///|
async fn init_webgpu(state : State, target : @js.Any) -> Unit {
  let adapter_any = request_adapter_any().wait()
  if host_is_nullish(adapter_any) {
    fail("WebGPU adapter unavailable")
  }
  let device_any = request_device_any(adapter_any).wait()
  if host_is_nullish(device_any) {
    fail("WebGPU device unavailable")
  }
  let device : @webgpu.GPUDevice = device_any.cast()
  let context = @webgpu.get_canvas_context(target)
  let format = @webgpu.preferred_canvas_format()
  state.gpu.device = Some(device)
  state.gpu.queue = Some(device.queue())
  state.gpu.context = Some(context)
  state.gpu.format = Some(format)
  state.gpu.pipeline = None
  state.gpu.vertex_buffer = None
  state.gpu.vertex_count = 0
  state.gpu.mesh_pipeline = None
  state.gpu.mesh_bind_group = None
  state.gpu.meshes = new_map()
  state.gpu.next_mesh_id = 1
  state.gpu.uniform_buffer = None
  state.gpu.encoder = None
  state.gpu.current_texture = None
  state.gpu.current_pass = None
  state.gpu.current_pass_info = None
  state.gpu.textures = new_map()
  state.gpu.next_texture_id = 1
  state.gpu.fallback_texture_id = 0
  if state.assets.pending_textures.length() > 0 {
    let pending : Array[PendingTexture] = []
    for item in state.assets.pending_textures {
      pending.push(item)
    }
    state.assets.pending_textures.clear()
    for entry in pending {
      @js.run_async(async fn() noraise {
        let result = load_texture_from_path(
          state,
          entry.id,
          entry.path,
          entry.nearest,
        ) catch {
          err => {
            let message = "Texture load error: " + err.to_string()
            console_error(@js.any(message))
            dispatch_asset_error(message)
            set_delete(state.assets.loading_textures, @js.any(entry.id))
            |> ignore
          }
        }
        result |> ignore
      })
    }
  }
}

///|
fn create_sampler(state : State, nearest : Bool) -> @webgpu.GPUSampler? {
  if state.gpu.device is None {
    return None
  }
  if state.gpu.device is Some(device) {
    let filter = if nearest { "nearest" } else { "linear" }
    let descriptor = @js.from_entries([
      ("magFilter", @js.any(filter)),
      ("minFilter", @js.any(filter)),
    ])
    Some(device.create_sampler(descriptor))
  } else {
    None
  }
}

///|
fn ensure_pipeline_resources(state : State) -> Unit {
  if state.gpu.pipeline is Some(_) {
    return
  }
  if state.gpu.device is None {
    return
  }
  if state.gpu.device is Some(device) {
    let format = state.gpu.format.unwrap_or("bgra8unorm")
    let shader_module = device.create_shader_module(
      @js.from_entries([("code", @js.any(sprite_shader_code()))]),
    )
    let pipeline = device.create_render_pipeline(
      @js.from_entries([
        ("layout", @js.any("auto")),
        (
          "vertex",
          @js.from_entries([
            ("module", shader_module.as_any()),
            ("entryPoint", @js.any("vs_main")),
            (
              "buffers",
              @js.any([
                @js.from_entries([
                  ("arrayStride", @js.any(16)),
                  (
                    "attributes",
                    @js.any([
                      @js.from_entries([
                        ("shaderLocation", @js.any(0)),
                        ("offset", @js.any(0)),
                        ("format", @js.any("float32x2")),
                      ]),
                      @js.from_entries([
                        ("shaderLocation", @js.any(1)),
                        ("offset", @js.any(8)),
                        ("format", @js.any("float32x2")),
                      ]),
                    ]),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
        (
          "fragment",
          @js.from_entries([
            ("module", shader_module.as_any()),
            ("entryPoint", @js.any("fs_main")),
            (
              "targets",
              @js.any([
                @js.from_entries([
                  ("format", @js.any(format)),
                  (
                    "blend",
                    @js.from_entries([
                      (
                        "color",
                        @js.from_entries([
                          ("srcFactor", @js.any("src-alpha")),
                          ("dstFactor", @js.any("one-minus-src-alpha")),
                          ("operation", @js.any("add")),
                        ]),
                      ),
                      (
                        "alpha",
                        @js.from_entries([
                          ("srcFactor", @js.any("src-alpha")),
                          ("dstFactor", @js.any("one-minus-src-alpha")),
                          ("operation", @js.any("add")),
                        ]),
                      ),
                    ]),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
        (
          "primitive",
          @js.from_entries([("topology", @js.any("triangle-list"))]),
        ),
      ]),
    )
    let vertices = create_sprite_vertices()
    let vertex_buffer = device.create_buffer(
      @js.from_entries([
        ("size", vertices._get("byteLength")),
        (
          "usage",
          @js.any(
            @webgpu.combine_flags(
              @webgpu.buffer_usage_vertex(),
              @webgpu.buffer_usage_copy_dst(),
            ),
          ),
        ),
      ]),
    )
    device.queue().write_buffer(vertex_buffer, 0, vertices)
    let uniform_buffer = device.create_buffer(
      @js.from_entries([
        ("size", @js.any(64)),
        (
          "usage",
          @js.any(
            @webgpu.combine_flags(
              @webgpu.buffer_usage_uniform(),
              @webgpu.buffer_usage_copy_dst(),
            ),
          ),
        ),
      ]),
    )
    let texture_size = 64
    let texture = device.create_texture(
      @js.from_entries([
        ("size", @js.any([texture_size, texture_size, 1])),
        ("format", @js.any("rgba8unorm")),
        (
          "usage",
          @js.any(
            @webgpu.combine_flags(
              @webgpu.combine_flags(
                @webgpu.texture_usage_texture_binding(),
                @webgpu.texture_usage_copy_dst(),
              ),
              @webgpu.texture_usage_render_attachment(),
            ),
          ),
        ),
      ]),
    )
    let pixel_data = create_checkerboard_data(texture_size)
    write_texture(
      device.queue().as_any(),
      texture.as_any(),
      pixel_data,
      texture_size * 4,
      texture_size,
      texture_size,
    )
    let sampler = create_sampler(state, true)
    if sampler is Some(sampler_value) {
      let entry = @js.from_entries([
        ("id", @js.any(state.gpu.fallback_texture_id)),
        ("texture", texture.as_any()),
        ("view", texture.create_view().as_any()),
        ("sampler", sampler_value.as_any()),
        ("bindGroup", js_null()),
        ("width", @js.any(texture_size)),
        ("height", @js.any(texture_size)),
      ])
      map_set(state.gpu.textures, @js.any(state.gpu.fallback_texture_id), entry)
    }
    state.gpu.pipeline = Some(pipeline)
    state.gpu.vertex_buffer = Some(vertex_buffer)
    state.gpu.vertex_count = 6
    state.gpu.uniform_buffer = Some(uniform_buffer)
  }
}

///|
fn ensure_bind_group_for_texture(state : State, entry : @js.Any) -> Unit {
  if state.gpu.pipeline is None || state.gpu.uniform_buffer is None {
    return
  }
  if state.gpu.device is None {
    return
  }
  if !host_is_nullish(entry._get("bindGroup")) {
    return
  }
  if host_is_nullish(entry._get("sampler")) ||
    host_is_nullish(entry._get("view")) {
    return
  }
  if state.gpu.device is Some(device) && state.gpu.pipeline is Some(pipeline) {
    if state.gpu.uniform_buffer is Some(uniform_buffer) {
      let layout = pipeline.get_bind_group_layout(0)
      let entries : Array[@js.Any] = [
        @js.from_entries([
          ("binding", @js.any(0)),
          ("resource", entry._get("sampler")),
        ]),
        @js.from_entries([
          ("binding", @js.any(1)),
          ("resource", entry._get("view")),
        ]),
        @js.from_entries([
          ("binding", @js.any(2)),
          ("resource", @js.from_entries([("buffer", uniform_buffer.as_any())])),
        ]),
      ]
      let bind_group = device.create_bind_group(
        @js.from_entries([
          ("layout", layout.as_any()),
          ("entries", @js.any(entries)),
        ]),
      )
      entry._set("bindGroup", bind_group.as_any()) |> ignore
    }
  }
}

///|
fn ensure_mesh_pipeline(state : State) -> Unit {
  if state.gpu.mesh_pipeline is Some(_) {
    return
  }
  if state.gpu.device is None {
    return
  }
  ensure_pipeline_resources(state)
  if state.gpu.uniform_buffer is None {
    return
  }
  if state.gpu.device is Some(device) {
    let format = state.gpu.format.unwrap_or("bgra8unorm")
    let shader_module = device.create_shader_module(
      @js.from_entries([("code", @js.any(mesh_shader_code()))]),
    )
    let pipeline = device.create_render_pipeline(
      @js.from_entries([
        ("layout", @js.any("auto")),
        (
          "vertex",
          @js.from_entries([
            ("module", shader_module.as_any()),
            ("entryPoint", @js.any("vs_main")),
            (
              "buffers",
              @js.any([
                @js.from_entries([
                  ("arrayStride", @js.any(8)),
                  (
                    "attributes",
                    @js.any([
                      @js.from_entries([
                        ("shaderLocation", @js.any(0)),
                        ("offset", @js.any(0)),
                        ("format", @js.any("float32x2")),
                      ]),
                    ]),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
        (
          "fragment",
          @js.from_entries([
            ("module", shader_module.as_any()),
            ("entryPoint", @js.any("fs_main")),
            (
              "targets",
              @js.any([
                @js.from_entries([
                  ("format", @js.any(format)),
                  (
                    "blend",
                    @js.from_entries([
                      (
                        "color",
                        @js.from_entries([
                          ("srcFactor", @js.any("src-alpha")),
                          ("dstFactor", @js.any("one-minus-src-alpha")),
                          ("operation", @js.any("add")),
                        ]),
                      ),
                      (
                        "alpha",
                        @js.from_entries([
                          ("srcFactor", @js.any("src-alpha")),
                          ("dstFactor", @js.any("one-minus-src-alpha")),
                          ("operation", @js.any("add")),
                        ]),
                      ),
                    ]),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
        (
          "primitive",
          @js.from_entries([("topology", @js.any("triangle-list"))]),
        ),
      ]),
    )
    state.gpu.mesh_pipeline = Some(pipeline)
    if state.gpu.uniform_buffer is Some(uniform_buffer) {
      let layout = pipeline.get_bind_group_layout(0)
      let bind_group = device.create_bind_group(
        @js.from_entries([
          ("layout", layout.as_any()),
          (
            "entries",
            @js.any([
              @js.from_entries([
                ("binding", @js.any(0)),
                (
                  "resource",
                  @js.from_entries([("buffer", uniform_buffer.as_any())]),
                ),
              ]),
            ]),
          ),
        ]),
      )
      state.gpu.mesh_bind_group = Some(bind_group)
    }
  }
}

///|
fn report_fallback_usage(state : State, id : Int, reason : String) -> Unit {
  if set_has(state.assets.loading_textures, @js.any(id)) {
    return
  }
  if set_has(state.assets.fallback_reported, @js.any(id)) {
    return
  }
  set_add(state.assets.fallback_reported, @js.any(id))
  let path_hint = map_get(state.assets.texture_paths, @js.any(id))
  let suffix = if host_is_nullish(path_hint) {
    ""
  } else {
    " (path: " + path_hint.cast() + ")"
  }
  let message = "Fallback texture used for id " +
    id.to_string() +
    ": " +
    reason +
    suffix
  console_error(@js.any(message))
  dispatch_asset_error(message)
}

///|
fn get_texture_entry(state : State, id : Int) -> @js.Any? {
  let entry = map_get(state.gpu.textures, @js.any(id))
  if !host_is_nullish(entry) {
    let view = entry._get("view")
    let sampler = entry._get("sampler")
    if !host_is_nullish(view) && !host_is_nullish(sampler) {
      return Some(entry)
    }
  }
  let reason = if host_is_nullish(entry) {
    "texture id not found"
  } else {
    "texture not ready"
  }
  report_fallback_usage(state, id, reason)
  let fallback_entry = map_get(
    state.gpu.textures,
    @js.any(state.gpu.fallback_texture_id),
  )
  if host_is_nullish(fallback_entry) {
    None
  } else {
    Some(fallback_entry)
  }
}

///|
async fn load_texture_from_path(
  state : State,
  id : Int,
  path : @js.Any,
  nearest : Bool,
) -> Unit {
  if state.gpu.device is None || state.gpu.queue is None {
    state.assets.pending_textures.push(PendingTexture::{ id, path, nearest })
    return
  }
  let url = resolve_asset_url(path)
  let response = @http.fetch(url, method_="GET")
  if !response.ok {
    fail(
      "Failed to load texture: " +
      url +
      " (" +
      response.status.to_string() +
      ")",
    )
  }
  let blob : @js.Any = response_blob(response.as_any()).wait()
  let image = create_image_bitmap(blob).wait()
  ensure_pipeline_resources(state)
  if state.gpu.device is Some(device) && state.gpu.queue is Some(queue) {
    let width : Int = image._get("width").cast()
    let height : Int = image._get("height").cast()
    let texture = device.create_texture(
      @js.from_entries([
        ("size", @js.any([width, height, 1])),
        ("format", @js.any("rgba8unorm")),
        (
          "usage",
          @js.any(
            @webgpu.combine_flags(
              @webgpu.combine_flags(
                @webgpu.texture_usage_texture_binding(),
                @webgpu.texture_usage_copy_dst(),
              ),
              @webgpu.texture_usage_render_attachment(),
            ),
          ),
        ),
      ]),
    )
    copy_external_image_to_texture(
      queue.as_any(),
      image,
      texture.as_any(),
      width,
      height,
    )
    let sampler = create_sampler(state, nearest)
    if sampler is Some(sampler_value) {
      let entry = @js.from_entries([
        ("id", @js.any(id)),
        ("texture", texture.as_any()),
        ("view", texture.create_view().as_any()),
        ("sampler", sampler_value.as_any()),
        ("bindGroup", js_null()),
        ("width", @js.any(width)),
        ("height", @js.any(height)),
      ])
      map_set(state.gpu.textures, @js.any(id), entry)
      ensure_bind_group_for_texture(state, entry)
    }
  }
  set_delete(state.assets.loading_textures, @js.any(id)) |> ignore
}

///|
fn make_uniform_data(values : Array[Double]) -> @js.Any {
  float32array_from_array(values)
}

///|
fn arg_any(args : Array[@js.Any], index : Int) -> @js.Any {
  if index < args.length() {
    args[index]
  } else {
    js_undefined()
  }
}

///|
fn arg_number(args : Array[@js.Any], index : Int, fallback : Double) -> Double {
  number_or(arg_any(args, index), fallback)
}

///|
fn ensure_pass_ready(state : State) -> Bool {
  if state.gpu.current_pass is None || state.gpu.current_pass_info is None {
    return false
  }
  if state.gpu.pipeline is None || state.gpu.vertex_buffer is None {
    return false
  }
  if state.gpu.uniform_buffer is None {
    return false
  }
  true
}

///|
fn update_uniform_buffer(state : State, values : Array[Double]) -> Unit {
  if state.gpu.queue is Some(queue) &&
    state.gpu.uniform_buffer is Some(uniform_buffer) {
    let data = make_uniform_data(values)
    queue.write_buffer(uniform_buffer, 0, data)
  }
}

///|
fn begin_frame(state : State) -> Int {
  if state.gpu.context is None || state.gpu.device is None {
    return 0
  }
  if state.gpu.context is Some(context) && state.gpu.device is Some(device) {
    update_window_size(state)
    ensure_pipeline_resources(state)
    state.gpu.encoder = Some(device.create_command_encoder())
    state.gpu.current_texture = Some(context.get_current_texture())
    return 1
  }
  0
}

///|
fn begin_pass(
  state : State,
  target_id : Int,
  width : Double,
  height : Double,
  clear_r : Double,
  clear_g : Double,
  clear_b : Double,
  clear_a : Double,
  cam_x : Double,
  cam_y : Double,
  cam_rotation : Double,
  cam_scale : Double,
) -> Unit {
  if state.gpu.encoder is None {
    return
  }
  if state.gpu.encoder is Some(encoder) {
    let mut view : @webgpu.GPUTextureView? = None
    if target_id < 0 {
      if state.gpu.current_texture is Some(current_texture) {
        view = Some(current_texture.create_view())
      }
    } else {
      let target_entry = map_get(state.gpu.textures, @js.any(target_id))
      if !host_is_nullish(target_entry) {
        let view_any = target_entry._get("view")
        if !host_is_nullish(view_any) {
          view = Some(view_any.cast())
        }
      }
    }
    if view is None {
      return
    }
    if view is Some(view_value) {
      let pass = encoder.begin_render_pass(
        @js.from_entries([
          (
            "colorAttachments",
            @js.any([
              @js.from_entries([
                ("view", view_value.as_any()),
                (
                  "clearValue",
                  @js.from_entries([
                    ("r", @js.any(clear_r)),
                    ("g", @js.any(clear_g)),
                    ("b", @js.any(clear_b)),
                    ("a", @js.any(clear_a)),
                  ]),
                ),
                ("loadOp", @js.any("clear")),
                ("storeOp", @js.any("store")),
              ]),
            ]),
          ),
        ]),
      )
      state.gpu.current_pass = Some(pass)
      state.gpu.current_pass_info = Some(PassInfo::{
        width: if width > 0 {
          width
        } else {
          1
        },
        height: if height > 0 {
          height
        } else {
          1
        },
        cam_x,
        cam_y,
        cam_rotation,
        cam_scale,
      })
    }
  }
}

///|
fn draw_sprite(
  state : State,
  texture_id : Int,
  x : Double,
  y : Double,
  rotation : Double,
  scale_x : Double,
  scale_y : Double,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> Unit {
  if !ensure_pass_ready(state) {
    return
  }
  let entry = get_texture_entry(state, texture_id)
  if entry is None {
    return
  }
  if entry is Some(entry_value) {
    ensure_bind_group_for_texture(state, entry_value)
    let bind_group_any = entry_value._get("bindGroup")
    if host_is_nullish(bind_group_any) {
      return
    }
    if state.gpu.current_pass is Some(pass) &&
      state.gpu.current_pass_info is Some(info) {
      let tex_width : Double = entry_value._get("width").cast()
      let tex_height : Double = entry_value._get("height").cast()
      let base_size = 128.0
      let tex_scale_x = if tex_width > 0 { tex_width / base_size } else { 1 }
      let tex_scale_y = if tex_height > 0 { tex_height / base_size } else { 1 }
      let sprite_scale_x = scale_x * tex_scale_x
      let sprite_scale_y = scale_y * tex_scale_y
      let scale_x_base = if info.width > 0 {
        2.0 / info.width * info.cam_scale
      } else {
        0.0
      }
      let scale_y_base = if info.height > 0 {
        2.0 / info.height * info.cam_scale
      } else {
        0.0
      }
      let cos_value : Double = math_cos(rotation)
      let sin_value : Double = math_sin(rotation)
      let cam_cos : Double = math_cos(-info.cam_rotation)
      let cam_sin : Double = math_sin(-info.cam_rotation)
      update_uniform_buffer(state, [
        x,
        y,
        cos_value,
        sin_value,
        info.cam_x,
        info.cam_y,
        cam_cos,
        cam_sin,
        scale_x_base,
        scale_y_base,
        sprite_scale_x,
        sprite_scale_y,
        r,
        g,
        b,
        a,
      ])
      if state.gpu.pipeline is Some(pipeline) &&
        state.gpu.vertex_buffer is Some(vertex_buffer) {
        pass.set_pipeline(pipeline)
        pass.set_bind_group(0, bind_group_any.cast())
        pass.set_vertex_buffer(0, vertex_buffer)
        pass.draw(state.gpu.vertex_count, 1, 0, 0)
      }
    }
  }
}

///|
fn draw_mesh(
  state : State,
  mesh_id : Int,
  x : Double,
  y : Double,
  rotation : Double,
  scale_x : Double,
  scale_y : Double,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> Unit {
  if state.gpu.current_pass is None || state.gpu.current_pass_info is None {
    return
  }
  ensure_mesh_pipeline(state)
  if state.gpu.mesh_pipeline is None || state.gpu.mesh_bind_group is None {
    return
  }
  let mesh_entry = map_get(state.gpu.meshes, @js.any(mesh_id))
  if host_is_nullish(mesh_entry) {
    return
  }
  if state.gpu.current_pass is Some(pass) &&
    state.gpu.current_pass_info is Some(info) {
    let scale_x_base = if info.width > 0 {
      2.0 / info.width * info.cam_scale
    } else {
      0.0
    }
    let scale_y_base = if info.height > 0 {
      2.0 / info.height * info.cam_scale
    } else {
      0.0
    }
    let cos_value : Double = math_cos(rotation)
    let sin_value : Double = math_sin(rotation)
    let cam_cos : Double = math_cos(-info.cam_rotation)
    let cam_sin : Double = math_sin(-info.cam_rotation)
    update_uniform_buffer(state, [
      x,
      y,
      cos_value,
      sin_value,
      info.cam_x,
      info.cam_y,
      cam_cos,
      cam_sin,
      scale_x_base,
      scale_y_base,
      scale_x,
      scale_y,
      r,
      g,
      b,
      a,
    ])
    if state.gpu.mesh_pipeline is Some(mesh_pipeline) &&
      state.gpu.mesh_bind_group is Some(mesh_bind_group) {
      pass.set_pipeline(mesh_pipeline)
      pass.set_bind_group(0, mesh_bind_group)
      let vertex_buffer : @webgpu.GPUBuffer = mesh_entry
        ._get("vertexBuffer")
        .cast()
      let vertex_count : Int = mesh_entry._get("vertexCount").cast()
      pass.set_vertex_buffer(0, vertex_buffer)
      pass.draw(vertex_count, 1, 0, 0)
    }
  }
}

///|
pub fn create_host(canvas_opt : @dom.Element?) -> @js.Any {
  let state = new_state()
  let default_canvas = ensure_canvas(canvas_opt)
  let window_create = @js.from_fn3(fn(width, height, title) {
    let target = default_canvas
    let width_num = to_int(number_or(width, 800))
    let height_num = to_int(number_or(height, 600))
    target._set("width", @js.any(width_num)) |> ignore
    target._set("height", @js.any(height_num)) |> ignore
    if !host_is_nullish(title) {
      let text = any_to_string(title)
      if text != "" {
        @dom.document().setTitle(text)
      }
    }
    let size = get_canvas_pixel_size(target)
    let pixel_width : Int = size._get("width").cast()
    let pixel_height : Int = size._get("height").cast()
    target._set("width", @js.any(pixel_width)) |> ignore
    target._set("height", @js.any(pixel_height)) |> ignore
    state.window = Some(WindowState::{
      canvas: target,
      width: pixel_width,
      height: pixel_height,
    })
    bind_pointer_events(state, target)
    1
  })
  let window_poll_events = @js.from_fn1(fn(_ : @js.Any) { () })
  let window_get_width = @js.from_fn1(fn(_ : @js.Any) {
    update_window_size(state)
    if state.window is Some(window_state) {
      window_state.width
    } else {
      0
    }
  })
  let window_get_height = @js.from_fn1(fn(_ : @js.Any) {
    update_window_size(state)
    if state.window is Some(window_state) {
      window_state.height
    } else {
      0
    }
  })
  let window_should_close = @js.from_fn1(fn(_ : @js.Any) { state.should_close })
  let window_request_close = @js.from_fn1(fn(_ : @js.Any) {
    state.should_close = true
  })
  let window_run_loop = @js.from_fn1(fn(step : @js.Any) {
    fn tick() {
      if state.should_close {
        return
      }
      host_call0_any(step) |> ignore
      request_animation_frame(@js.from_fn0(fn() { tick() }))
    }

    request_animation_frame(@js.from_fn0(fn() { tick() }))
  })
  let time_now = @js.from_fn0(fn() { performance_now() })
  let input_is_key_down = @js.from_fn1(fn(code) {
    let text = if host_is_nullish(code) { "" } else { any_to_string(code) }
    set_has(state.input.pressed, @js.any(text))
  })
  let input_is_key_just_pressed = @js.from_fn1(fn(code) {
    let text = if host_is_nullish(code) { "" } else { any_to_string(code) }
    set_has(state.input.just_pressed, @js.any(text))
  })
  let input_is_key_just_released = @js.from_fn1(fn(code) {
    let text = if host_is_nullish(code) { "" } else { any_to_string(code) }
    set_has(state.input.just_released, @js.any(text))
  })
  let input_finish_frame = @js.from_fn0(fn() {
    set_clear(state.input.just_pressed)
    set_clear(state.input.just_released)
    set_clear(state.input.mouse_just_pressed)
    set_clear(state.input.mouse_just_released)
  })
  let input_is_mouse_button_down = @js.from_fn1(fn(name) {
    let text = if host_is_nullish(name) { "" } else { any_to_string(name) }
    set_has(state.input.mouse_buttons, @js.any(text))
  })
  let input_is_mouse_button_just_pressed = @js.from_fn1(fn(name) {
    let text = if host_is_nullish(name) { "" } else { any_to_string(name) }
    set_has(state.input.mouse_just_pressed, @js.any(text))
  })
  let input_is_mouse_button_just_released = @js.from_fn1(fn(name) {
    let text = if host_is_nullish(name) { "" } else { any_to_string(name) }
    set_has(state.input.mouse_just_released, @js.any(text))
  })
  let input_mouse_x = @js.from_fn0(fn() { state.input.mouse_x })
  let input_mouse_y = @js.from_fn0(fn() { state.input.mouse_y })
  let input_has_cursor = @js.from_fn0(fn() { state.input.has_cursor })
  let debug_string = @js.from_fn1(fn(value) { console_error(value) })
  let gpu_request_device = @js.from_fn0(fn() {
    if state.gpu.device is None {
      throw_error("WebGPU device not initialized. Call create_host() first.")
      return 0
    }
    1
  })
  let gpu_get_queue = @js.from_fn1(fn(_ : @js.Any) { 1 })
  let gpu_create_surface = @js.from_fn1(fn(_ : @js.Any) {
    if state.window is None {
      throw_error("Unknown window id")
      return 0
    }
    1
  })
  let gpu_configure_surface = wrap_variadic(
    @js.from_fn1(fn(args) {
      if state.gpu.context is None || state.gpu.device is None {
        return
      }
      if state.window is Some(window_state) {
        let width_int = to_int(
          arg_number(args, 2, window_state.width.to_double()),
        )
        let height_int = to_int(
          arg_number(args, 3, window_state.height.to_double()),
        )
        window_state.width = width_int
        window_state.height = height_int
        window_state.canvas._set("width", @js.any(width_int)) |> ignore
        window_state.canvas._set("height", @js.any(height_int)) |> ignore
        if state.gpu.context is Some(context) &&
          state.gpu.device is Some(device) {
          let usage = @webgpu.texture_usage_render_attachment()
          let descriptor = @js.from_entries([
            ("device", device.as_any()),
            ("format", @js.any(state.gpu.format.unwrap_or("bgra8unorm"))),
            ("alphaMode", @js.any("premultiplied")),
            ("usage", @js.any(usage)),
            ("size", @js.any([width_int, height_int])),
          ])
          context.configure(descriptor)
        }
      }
    }),
  )
  let asset_load_texture = @js.from_fn2(fn(path, nearest) {
    let id = state.gpu.next_texture_id
    state.gpu.next_texture_id = id + 1
    set_add(state.assets.loading_textures, @js.any(id))
    let path_text = coerce_asset_path(path)
    if path_text != "" {
      map_set(state.assets.texture_paths, @js.any(id), @js.any(path_text))
    }
    let nearest_value = number_or(nearest, 0) != 0
    @js.run_async(async fn() noraise {
      let result = load_texture_from_path(state, id, path, nearest_value) catch {
        err => {
          let message = "Texture load error: " + err.to_string()
          console_error(@js.any(message))
          dispatch_asset_error(message)
          set_delete(state.assets.loading_textures, @js.any(id)) |> ignore
        }
      }
      result |> ignore
    })
    id
  })
  let gpu_create_render_target = @js.from_fn3(fn(width, height, nearest) {
    if state.gpu.device is None {
      throw_error("GPU device not ready")
      return 0
    }
    ensure_pipeline_resources(state)
    let id = state.gpu.next_texture_id
    state.gpu.next_texture_id = id + 1
    map_set(state.assets.texture_paths, @js.any(id), @js.any("<render-target>"))
    let width_value = number_or(width, 1)
    let height_value = number_or(height, 1)
    let safe_width = if width_value > 0 { to_int(width_value) } else { 1 }
    let safe_height = if height_value > 0 { to_int(height_value) } else { 1 }
    if state.gpu.device is Some(device) {
      let format = state.gpu.format.unwrap_or("bgra8unorm")
      let texture = device.create_texture(
        @js.from_entries([
          ("size", @js.any([safe_width, safe_height, 1])),
          ("format", @js.any(format)),
          (
            "usage",
            @js.any(
              @webgpu.combine_flags(
                @webgpu.combine_flags(
                  @webgpu.texture_usage_texture_binding(),
                  @webgpu.texture_usage_render_attachment(),
                ),
                @webgpu.texture_usage_copy_dst(),
              ),
            ),
          ),
        ]),
      )
      let sampler = create_sampler(state, number_or(nearest, 0) != 0)
      if sampler is Some(sampler_value) {
        let entry = @js.from_entries([
          ("id", @js.any(id)),
          ("texture", texture.as_any()),
          ("view", texture.create_view().as_any()),
          ("sampler", sampler_value.as_any()),
          ("bindGroup", js_null()),
          ("width", @js.any(safe_width)),
          ("height", @js.any(safe_height)),
        ])
        map_set(state.gpu.textures, @js.any(id), entry)
        ensure_bind_group_for_texture(state, entry)
      }
    }
    id
  })
  let gpu_create_mesh_capsule = @js.from_fn3(fn(radius, half_length, segments) {
    if state.gpu.device is None {
      throw_error("GPU device not ready")
      return 0
    }
    ensure_mesh_pipeline(state)
    let id = state.gpu.next_mesh_id
    state.gpu.next_mesh_id = id + 1
    let vertices = create_capsule_mesh_data(
      number_or(radius, 0.5),
      number_or(half_length, 0.5),
      to_int(number_or(segments, 16)),
    )
    if state.gpu.device is Some(device) {
      let vertex_buffer = device.create_buffer(
        @js.from_entries([
          ("size", vertices._get("byteLength")),
          (
            "usage",
            @js.any(
              @webgpu.combine_flags(
                @webgpu.buffer_usage_vertex(),
                @webgpu.buffer_usage_copy_dst(),
              ),
            ),
          ),
        ]),
      )
      device.queue().write_buffer(vertex_buffer, 0, vertices)
      let vertex_len : Double = vertices._get("length").cast()
      let vertex_count = to_int(vertex_len / 2)
      let entry = @js.from_entries([
        ("id", @js.any(id)),
        ("vertexBuffer", vertex_buffer.as_any()),
        ("vertexCount", @js.any(vertex_count)),
      ])
      map_set(state.gpu.meshes, @js.any(id), entry)
    }
    id
  })
  let gpu_create_mesh_rectangle = @js.from_fn2(fn(width, height) {
    if state.gpu.device is None {
      throw_error("GPU device not ready")
      return 0
    }
    ensure_mesh_pipeline(state)
    let id = state.gpu.next_mesh_id
    state.gpu.next_mesh_id = id + 1
    let vertices = create_rectangle_mesh_data(
      number_or(width, 1),
      number_or(height, 1),
    )
    if state.gpu.device is Some(device) {
      let vertex_buffer = device.create_buffer(
        @js.from_entries([
          ("size", vertices._get("byteLength")),
          (
            "usage",
            @js.any(
              @webgpu.combine_flags(
                @webgpu.buffer_usage_vertex(),
                @webgpu.buffer_usage_copy_dst(),
              ),
            ),
          ),
        ]),
      )
      device.queue().write_buffer(vertex_buffer, 0, vertices)
      let vertex_len : Double = vertices._get("length").cast()
      let vertex_count = to_int(vertex_len / 2)
      let entry = @js.from_entries([
        ("id", @js.any(id)),
        ("vertexBuffer", vertex_buffer.as_any()),
        ("vertexCount", @js.any(vertex_count)),
      ])
      map_set(state.gpu.meshes, @js.any(id), entry)
    }
    id
  })
  let gpu_begin_frame = @js.from_fn1(fn(_ : @js.Any) { begin_frame(state) })
  let gpu_begin_pass = wrap_variadic(
    @js.from_fn1(fn(args) {
      begin_pass(
        state,
        to_int(arg_number(args, 0, -1)),
        arg_number(args, 1, 1),
        arg_number(args, 2, 1),
        arg_number(args, 3, 0),
        arg_number(args, 4, 0),
        arg_number(args, 5, 0),
        arg_number(args, 6, 1),
        arg_number(args, 7, 0),
        arg_number(args, 8, 0),
        arg_number(args, 9, 0),
        arg_number(args, 10, 1),
      )
    }),
  )
  let gpu_draw_sprite = wrap_variadic(
    @js.from_fn1(fn(args) {
      draw_sprite(
        state,
        to_int(arg_number(args, 0, 0)),
        arg_number(args, 1, 0),
        arg_number(args, 2, 0),
        arg_number(args, 3, 0),
        arg_number(args, 4, 1),
        arg_number(args, 5, 1),
        arg_number(args, 6, 1),
        arg_number(args, 7, 1),
        arg_number(args, 8, 1),
        arg_number(args, 9, 1),
      )
    }),
  )
  let gpu_draw_mesh = wrap_variadic(
    @js.from_fn1(fn(args) {
      draw_mesh(
        state,
        to_int(arg_number(args, 0, 0)),
        arg_number(args, 1, 0),
        arg_number(args, 2, 0),
        arg_number(args, 3, 0),
        arg_number(args, 4, 1),
        arg_number(args, 5, 1),
        arg_number(args, 6, 1),
        arg_number(args, 7, 1),
        arg_number(args, 8, 1),
        arg_number(args, 9, 1),
      )
    }),
  )
  let gpu_end_pass = @js.from_fn0(fn() {
    if state.gpu.current_pass is Some(pass) {
      pass.end()
    }
    state.gpu.current_pass = None
    state.gpu.current_pass_info = None
  })
  let gpu_end_frame = @js.from_fn1(fn(_ : @js.Any) {
    if state.gpu.device is None ||
      state.gpu.queue is None ||
      state.gpu.encoder is None {
      return
    }
    if state.gpu.current_pass is Some(pass) {
      pass.end()
    }
    if state.gpu.encoder is Some(encoder) && state.gpu.queue is Some(queue) {
      queue.submit([encoder.finish()])
    }
    state.gpu.encoder = None
    state.gpu.current_texture = None
    state.gpu.current_pass = None
    state.gpu.current_pass_info = None
  })
  let mgstudio_host = @js.from_entries([
    ("window_create", window_create),
    ("window_poll_events", window_poll_events),
    ("window_get_width", window_get_width),
    ("window_get_height", window_get_height),
    ("window_should_close", window_should_close),
    ("window_request_close", window_request_close),
    ("window_run_loop", window_run_loop),
    ("time_now", time_now),
    ("input_is_key_down", input_is_key_down),
    ("input_is_key_just_pressed", input_is_key_just_pressed),
    ("input_is_key_just_released", input_is_key_just_released),
    ("input_finish_frame", input_finish_frame),
    ("input_is_mouse_button_down", input_is_mouse_button_down),
    ("input_is_mouse_button_just_pressed", input_is_mouse_button_just_pressed),
    ("input_is_mouse_button_just_released", input_is_mouse_button_just_released),
    ("input_mouse_x", input_mouse_x),
    ("input_mouse_y", input_mouse_y),
    ("input_has_cursor", input_has_cursor),
    ("debug_string", debug_string),
    ("gpu_request_device", gpu_request_device),
    ("gpu_get_queue", gpu_get_queue),
    ("gpu_create_surface", gpu_create_surface),
    ("gpu_configure_surface", gpu_configure_surface),
    ("asset_load_texture", asset_load_texture),
    ("gpu_create_render_target", gpu_create_render_target),
    ("gpu_create_mesh_capsule", gpu_create_mesh_capsule),
    ("gpu_create_mesh_rectangle", gpu_create_mesh_rectangle),
    ("gpu_begin_frame", gpu_begin_frame),
    ("gpu_begin_pass", gpu_begin_pass),
    ("gpu_draw_sprite", gpu_draw_sprite),
    ("gpu_draw_mesh", gpu_draw_mesh),
    ("gpu_end_pass", gpu_end_pass),
    ("gpu_end_frame", gpu_end_frame),
  ])
  let init = @js.from_fn0(fn() {
    @js.from_async(async fn() {
      let target = default_canvas
      init_webgpu(state, target)
      init_input(state)
    })
  })
  @js.from_entries([("mgstudio_host", mgstudio_host), ("init", init)])
}
