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
extern "js" fn string_sink_push(code_unit : Int) -> Unit =
  #| (codeUnit) => {
  #|   const c = Number(codeUnit) & 0xffff
  #|   globalThis.__mgstudio_string_sink_buf = (globalThis.__mgstudio_string_sink_buf || "") + String.fromCharCode(c)
  #| }

///|
extern "js" fn any_to_string(value : @js.Any) -> String =
  #| (value) => {
  #|   if (value == null) {
  #|     return ""
  #|   }
  #|   if (typeof value === "string") {
  #|     return value
  #|   }
  #|   if (typeof value === "number" || typeof value === "bigint" || typeof value === "boolean") {
  #|     return `${value}`
  #|   }
  #|   // Fallback: some browsers expose wasm-gc references as fully opaque JS objects
  #|   // (often with a null prototype). In that case, ask the guest to push UTF-16
  #|   // code units back to the host.
  #|   try {
  #|     if (typeof value === "object" && value != null && Object.getPrototypeOf(value) === null) {
  #|       const exports = globalThis.__mgstudio_wasm_exports
  #|       const fn = exports && exports.mgstudio_host_string_to_js
  #|       if (typeof fn === "function") {
  #|         globalThis.__mgstudio_string_sink_buf = ""
  #|         fn(value)
  #|         const out = globalThis.__mgstudio_string_sink_buf || ""
  #|         globalThis.__mgstudio_string_sink_buf = ""
  #|         return out
  #|       }
  #|     }
  #|   } catch {
  #|   }
  #|   // Decode MoonBit wasm-gc `String` (typically an array of UTF-16 i16 code units).
  #|   // NOTE: some engines expose `length` as BigInt or via a getter; avoid strict typeof checks.
  #|   try {
  #|     let current = value
  #|     for (let i = 0; i < 4; i += 1) {
  #|       if (typeof current !== "object" || current == null) {
  #|         break
  #|       }
  #|       // Unwrap common wrapper shapes (defensive, for wasm-gc reference objects).
  #|       try {
  #|         if ("value" in current && current.value !== current) {
  #|           current = current.value
  #|           continue
  #|         }
  #|         if ("val" in current && current.val !== current) {
  #|           current = current.val
  #|           continue
  #|         }
  #|         if ("string" in current && current.string !== current) {
  #|           current = current.string
  #|           continue
  #|         }
  #|         if ("_0" in current && current._0 !== current) {
  #|           current = current._0
  #|           continue
  #|         }
  #|       } catch {
  #|       }
  #|       break
  #|     }
  #|     if (typeof current === "object" && current != null) {
  #|       let getFn = null
  #|       if (typeof current.get === "function") {
  #|         getFn = current.get
  #|       } else {
  #|         const proto = Object.getPrototypeOf(current)
  #|         if (proto && typeof proto.get === "function") {
  #|           getFn = proto.get
  #|         } else if (
  #|           typeof WebAssembly === "object" &&
  #|           typeof WebAssembly.Array === "function" &&
  #|           WebAssembly.Array.prototype &&
  #|           typeof WebAssembly.Array.prototype.get === "function"
  #|         ) {
  #|           getFn = WebAssembly.Array.prototype.get
  #|         }
  #|       }
  #|       if (!getFn) {
  #|         throw new Error("no get")
  #|       }
  #|       let len = current.length
  #|       if (typeof len === "function") {
  #|         len = len.call(current)
  #|       }
  #|       len = Number(len)
  #|       if (Number.isFinite(len) && len >= 0) {
  #|         if (len === 0) {
  #|           return ""
  #|         }
  #|         let out = ""
  #|         const CHUNK = 1024
  #|         for (let i = 0; i < len; i += CHUNK) {
  #|           const end = Math.min(len, i + CHUNK)
  #|           const codes = new Array(end - i)
  #|           for (let j = i; j < end; j += 1) {
  #|             codes[j - i] = getFn.call(current, j) & 0xffff
  #|           }
  #|           out += String.fromCharCode(...codes)
  #|         }
  #|         return out
  #|       }
  #|     }
  #|   } catch {
  #|   }
  #|   // Avoid crashing on GC objects that disallow primitive conversion.
  #|   try {
  #|     return String(value)
  #|   } catch {
  #|     return ""
  #|   }
  #| }

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
extern "js" fn get_device_pixel_ratio() -> Double =
  #| () => window.devicePixelRatio || 1

///|
extern "js" fn get_canvas_pixel_size(canvas : @js.Any) -> @js.Any =
  #| (canvas) => {
  #|   const dpr = window.devicePixelRatio || 1
  #|   let width = canvas.clientWidth
  #|   let height = canvas.clientHeight
  #|   if (!width || !height) {
  #|     const rect = canvas.getBoundingClientRect ? canvas.getBoundingClientRect() : null
  #|     if (rect) {
  #|       width = rect.width || width
  #|       height = rect.height || height
  #|     }
  #|   }
  #|   if (!width || !height) {
  #|     width = window.innerWidth || canvas.width || 1
  #|     height = window.innerHeight || canvas.height || 1
  #|   }
  #|   width = Math.max(1, Math.floor(width * dpr))
  #|   height = Math.max(1, Math.floor(height * dpr))
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
  #|   // Fallback: some browsers expose wasm-gc references as fully opaque JS objects
  #|   // (often with a null prototype). In that case, ask the guest to push UTF-16
  #|   // code units back to the host.
  #|   try {
  #|     if (typeof path === "object" && path != null && Object.getPrototypeOf(path) === null) {
  #|       const exports = globalThis.__mgstudio_wasm_exports
  #|       const fn = exports && exports.mgstudio_host_string_to_js
  #|       if (typeof fn === "function") {
  #|         globalThis.__mgstudio_string_sink_buf = ""
  #|         fn(path)
  #|         const out = globalThis.__mgstudio_string_sink_buf || ""
  #|         globalThis.__mgstudio_string_sink_buf = ""
  #|         return out
  #|       }
  #|     }
  #|   } catch {
  #|   }
  #|   let current = path
  #|   for (let i = 0; i < 4; i += 1) {
  #|     if (typeof current === "string") {
  #|       return current
  #|     }
  #|     // Unwrap common wrapper shapes (defensive, for wasm-gc reference objects).
  #|     if (typeof current === "object" && current != null) {
  #|       try {
  #|         if ("value" in current && current.value !== current) {
  #|           current = current.value
  #|           continue
  #|         }
  #|         if ("val" in current && current.val !== current) {
  #|           current = current.val
  #|           continue
  #|         }
  #|         if ("string" in current && current.string !== current) {
  #|           current = current.string
  #|           continue
  #|         }
  #|         if ("_0" in current && current._0 !== current) {
  #|           current = current._0
  #|           continue
  #|         }
  #|       } catch {
  #|       }
  #|     }
  #|     // MoonBit wasm-gc String is typically `array (mut i16)`.
  #|     // Different engines may expose the `get` method on the instance or prototype.
  #|     if (typeof current === "object" && current != null) {
  #|       let getFn = null
  #|       if (typeof current.get === "function") {
  #|         getFn = current.get
  #|       } else {
  #|         const proto = Object.getPrototypeOf(current)
  #|         if (proto && typeof proto.get === "function") {
  #|           getFn = proto.get
  #|         } else if (
  #|           typeof WebAssembly === "object" &&
  #|           typeof WebAssembly.Array === "function" &&
  #|           WebAssembly.Array.prototype &&
  #|           typeof WebAssembly.Array.prototype.get === "function"
  #|         ) {
  #|           getFn = WebAssembly.Array.prototype.get
  #|         }
  #|       }
  #|       if (getFn) {
  #|         let len = current.length
  #|         if (typeof len === "function") {
  #|           len = len.call(current)
  #|         }
  #|         len = Number(len)
  #|         if (Number.isFinite(len) && len >= 0) {
  #|           let out = ""
  #|           const CHUNK = 1024
  #|           for (let start = 0; start < len; start += CHUNK) {
  #|             const end = Math.min(len, start + CHUNK)
  #|             const codes = new Array(end - start)
  #|             for (let j = start; j < end; j += 1) {
  #|               codes[j - start] = getFn.call(current, j) & 0xffff
  #|             }
  #|             out += String.fromCharCode(...codes)
  #|           }
  #|           return out
  #|         }
  #|       }
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
  #|   let tag = ""
  #|   try {
  #|     tag = Object.prototype.toString.call(path)
  #|   } catch {
  #|   }
  #|   let protoTag = ""
  #|   try {
  #|     protoTag = Object.prototype.toString.call(Object.getPrototypeOf(path))
  #|   } catch {
  #|   }
  #|   let keys = ""
  #|   let protoKeys = ""
  #|   try {
  #|     const own = Reflect.ownKeys(path).map((k) => String(k)).slice(0, 12)
  #|     keys = own.join(",")
  #|   } catch {
  #|   }
  #|   try {
  #|     const proto = Object.getPrototypeOf(path)
  #|     if (proto) {
  #|       const own = Reflect.ownKeys(proto).map((k) => String(k)).slice(0, 12)
  #|       protoKeys = own.join(",")
  #|     }
  #|   } catch {
  #|   }
  #|   let ctor = ""
  #|   try {
  #|     ctor = path && path.constructor && path.constructor.name ? path.constructor.name : ""
  #|   } catch {
  #|   }
  #|   let hasGet = false
  #|   let hasLength = false
  #|   try {
  #|     hasGet = !!path && typeof path.get === "function"
  #|     hasLength = !!path && "length" in path
  #|   } catch {
  #|   }
  #|   throw new Error(`Unsupported asset path type: ${typeof path} ${tag} ctor=${ctor} proto=${protoTag} keys=[${keys}] protoKeys=[${protoKeys}] hasGet=${hasGet} hasLength=${hasLength}`)
  #| }

///|
extern "js" fn is_external_asset_url(text : String) -> Bool =
  #| (text) => /^(https?:)?\/\//.test(text) || text.startsWith("data:")

///|
extern "js" fn strip_leading_slashes(text : String) -> String =
  #| (text) => text.replace(/^\/+/, "")

///|
extern "js" fn split_trimmed_lines(text : String) -> Array[String] =
  #| (text) => String(text || "")
  #|   .split(/\r?\n/)
  #|   .map((line) => String(line).trim())
  #|   .filter((line) => line.length > 0 && !line.startsWith("#"))

///|
extern "js" fn new_map() -> @js.Any =
  #| () => new Map()

///|
extern "js" fn new_set() -> @js.Any =
  #| () => new Set()

///|
extern "js" fn new_array() -> @js.Any =
  #| () => []

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
extern "js" fn float32array_from_csv(text : String) -> @js.Any =
  #| (text) => {
  #|   const source = String(text || "").trim()
  #|   if (!source) {
  #|     return new Float32Array(0)
  #|   }
  #|   const parts = source.split(/[,\s]+/).filter((p) => p.length > 0)
  #|   const out = new Float32Array(parts.length)
  #|   for (let i = 0; i < parts.length; i += 1) {
  #|     const value = Number(parts[i])
  #|     out[i] = Number.isFinite(value) ? value : 0
  #|   }
  #|   return out
  #| }

///|
extern "js" fn build_gizmo_vertices(
  data : @js.Any,
  cam_x : Double,
  cam_y : Double,
  cam_rotation : Double,
  cam_scale : Double,
  width : Double,
  height : Double,
  line_width : Double,
) -> @js.Any =
  #| (data, camX, camY, camRotation, camScale, width, height, lineWidth) => {
  #|   let length = 0
  #|   let getter = null
  #|   if (Array.isArray(data) || ArrayBuffer.isView(data)) {
  #|     length = data.length
  #|     getter = (index) => data[index]
  #|   } else if (data && typeof data.get === "function") {
  #|     if (typeof data.length === "function") {
  #|       length = Number(data.length())
  #|     } else {
  #|       length = Number(data.length)
  #|     }
  #|     getter = (index) => data.get(index)
  #|   }
  #|   if (!getter || !Number.isFinite(length) || length <= 0) {
  #|     return new Float32Array(0)
  #|   }
  #|   const w = Number(width)
  #|   const h = Number(height)
  #|   if (!Number.isFinite(w) || !Number.isFinite(h) || w <= 0 || h <= 0) {
  #|     return new Float32Array(0)
  #|   }
  #|   const safeScale = Number.isFinite(camScale) && camScale !== 0 ? camScale : 1
  #|   const scaleX = 2 / w / safeScale
  #|   const scaleY = 2 / h / safeScale
  #|   const cos = Math.cos(-camRotation)
  #|   const sin = Math.sin(-camRotation)
  #|   const halfWidth = w * 0.5
  #|   const halfHeight = h * 0.5
  #|   const defaultWidth = Number.isFinite(lineWidth) && lineWidth > 0 ? lineWidth : 2
  #|   const vertices = []
  #|   const pushQuad = (sx, sy, ex, ey, sr, sg, sb, sa, er, eg, eb, ea, offX, offY) => {
  #|     const p1x = sx + offX
  #|     const p1y = sy + offY
  #|     const p2x = sx - offX
  #|     const p2y = sy - offY
  #|     const p3x = ex - offX
  #|     const p3y = ey - offY
  #|     const p4x = ex + offX
  #|     const p4y = ey + offY
  #|     vertices.push(
  #|       p1x, p1y, sr, sg, sb, sa,
  #|       p2x, p2y, sr, sg, sb, sa,
  #|       p3x, p3y, er, eg, eb, ea,
  #|       p1x, p1y, sr, sg, sb, sa,
  #|       p3x, p3y, er, eg, eb, ea,
  #|       p4x, p4y, er, eg, eb, ea,
  #|     )
  #|   }
  #|   for (let i = 0; i + 15 < length; i += 16) {
  #|     const sx = Number(getter(i))
  #|     const sy = Number(getter(i + 1))
  #|     const sr = Number(getter(i + 2))
  #|     const sg = Number(getter(i + 3))
  #|     const sb = Number(getter(i + 4))
  #|     const sa = Number(getter(i + 5))
  #|     const ex = Number(getter(i + 6))
  #|     const ey = Number(getter(i + 7))
  #|     const er = Number(getter(i + 8))
  #|     const eg = Number(getter(i + 9))
  #|     const eb = Number(getter(i + 10))
  #|     const ea = Number(getter(i + 11))
  #|     const width = Number(getter(i + 12))
  #|     const styleKind = Number(getter(i + 13))
  #|     const gapScale = Number(getter(i + 14))
  #|     const lineScale = Number(getter(i + 15))
  #|     const thickness = Number.isFinite(width) && width > 0 ? width : defaultWidth
  #|     const halfLine = thickness * 0.5
  #|     const relSX = sx - camX
  #|     const relSY = sy - camY
  #|     const relEX = ex - camX
  #|     const relEY = ey - camY
  #|     const viewSX = relSX * cos - relSY * sin
  #|     const viewSY = relSX * sin + relSY * cos
  #|     const viewEX = relEX * cos - relEY * sin
  #|     const viewEY = relEX * sin + relEY * cos
  #|     const ndcSX = viewSX * scaleX
  #|     const ndcSY = viewSY * scaleY
  #|     const ndcEX = viewEX * scaleX
  #|     const ndcEY = viewEY * scaleY
  #|     const screenSX = ndcSX * halfWidth
  #|     const screenSY = ndcSY * halfHeight
  #|     const screenEX = ndcEX * halfWidth
  #|     const screenEY = ndcEY * halfHeight
  #|     const dx = screenEX - screenSX
  #|     const dy = screenEY - screenSY
  #|     const len = Math.hypot(dx, dy)
  #|     if (!Number.isFinite(len) || len <= 0) {
  #|       continue
  #|     }
  #|     const invLen = 1 / len
  #|     const ux = dx * invLen
  #|     const uy = dy * invLen
  #|     const nx = -uy * halfLine
  #|     const ny = ux * halfLine
  #|     const offX = nx / halfWidth
  #|     const offY = ny / halfHeight
  #|     let dashLen = len
  #|     let gapLen = 0
  #|     if (styleKind === 1) {
  #|       dashLen = thickness
  #|       gapLen = thickness
  #|     } else if (styleKind === 2) {
  #|       const safeGap = Number.isFinite(gapScale) && gapScale > 0 ? gapScale : 1
  #|       const safeLine = Number.isFinite(lineScale) && lineScale > 0 ? lineScale : 1
  #|       dashLen = thickness * safeLine
  #|       gapLen = thickness * safeGap
  #|     }
  #|     const step = dashLen + gapLen
  #|     if (!Number.isFinite(step) || step <= 0 || dashLen >= len) {
  #|       pushQuad(ndcSX, ndcSY, ndcEX, ndcEY, sr, sg, sb, sa, er, eg, eb, ea, offX, offY)
  #|       continue
  #|     }
  #|     const dr = er - sr
  #|     const dg = eg - sg
  #|     const db = eb - sb
  #|     const da = ea - sa
  #|     let pos = 0
  #|     while (pos < len) {
  #|       const segLen = Math.min(dashLen, len - pos)
  #|       if (segLen > 0) {
  #|         const t0 = pos * invLen
  #|         const t1 = (pos + segLen) * invLen
  #|         const segSX = screenSX + ux * pos
  #|         const segSY = screenSY + uy * pos
  #|         const segEX = screenSX + ux * (pos + segLen)
  #|         const segEY = screenSY + uy * (pos + segLen)
  #|         const segNdcSX = segSX / halfWidth
  #|         const segNdcSY = segSY / halfHeight
  #|         const segNdcEX = segEX / halfWidth
  #|         const segNdcEY = segEY / halfHeight
  #|         const segSr = sr + dr * t0
  #|         const segSg = sg + dg * t0
  #|         const segSb = sb + db * t0
  #|         const segSa = sa + da * t0
  #|         const segEr = sr + dr * t1
  #|         const segEg = sg + dg * t1
  #|         const segEb = sb + db * t1
  #|         const segEa = sa + da * t1
  #|         pushQuad(
  #|           segNdcSX,
  #|           segNdcSY,
  #|           segNdcEX,
  #|           segNdcEY,
  #|           segSr,
  #|           segSg,
  #|           segSb,
  #|           segSa,
  #|           segEr,
  #|           segEg,
  #|           segEb,
  #|           segEa,
  #|           offX,
  #|           offY,
  #|         )
  #|       }
  #|       pos += step
  #|     }
  #|   }
  #|   return new Float32Array(vertices)
  #| }

///|
extern "js" fn push_gizmo_line(
  target : @js.Any,
  start_x : Double,
  start_y : Double,
  start_r : Double,
  start_g : Double,
  start_b : Double,
  start_a : Double,
  end_x : Double,
  end_y : Double,
  end_r : Double,
  end_g : Double,
  end_b : Double,
  end_a : Double,
  line_width : Double,
  style_kind : Int,
  gap_scale : Double,
  line_scale : Double,
) -> Unit =
  #| (target, sx, sy, sr, sg, sb, sa, ex, ey, er, eg, eb, ea, width, style, gapScale, lineScale) => {
  #|   if (target && typeof target.push === "function") {
  #|     target.push(sx, sy, sr, sg, sb, sa, ex, ey, er, eg, eb, ea, width, style, gapScale, lineScale)
  #|   }
  #| }

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
extern "js" fn write_texture_region(
  queue : @js.Any,
  texture : @js.Any,
  data : @js.Any,
  width : Int,
  height : Int,
  x : Int,
  y : Int,
) -> Unit =
  #| (queue, texture, data, width, height, x, y) => {
  #|   const bytesPerRow = width * 4
  #|   const aligned = bytesPerRow % 256 === 0
  #|     ? bytesPerRow
  #|     : Math.ceil(bytesPerRow / 256) * 256
  #|   let upload = data
  #|   if (aligned !== bytesPerRow) {
  #|     upload = new Uint8Array(aligned * height)
  #|     for (let row = 0; row < height; row += 1) {
  #|       const srcStart = row * bytesPerRow
  #|       const dstStart = row * aligned
  #|       upload.set(data.subarray(srcStart, srcStart + bytesPerRow), dstStart)
  #|     }
  #|   }
  #|   queue.writeTexture(
  #|     { texture, origin: { x, y } },
  #|     upload,
  #|     { bytesPerRow: aligned },
  #|     [width, height, 1],
  #|   )
  #| }

///|
extern "js" fn create_image_bitmap(blob : @js.Any) -> @js.Promise[@js.Any] =
  #| (blob) => createImageBitmap(blob, { premultiplyAlpha: "none", colorSpaceConversion: "none" })

///|
extern "js" fn response_blob(response : @js.Any) -> @js.Promise[@js.Any] =
  #| (response) => response.blob()

///|
extern "js" fn response_text(response : @js.Any) -> @js.Promise[String] =
  #| (response) => response.text()

///|
extern "js" fn load_font_face(
  family : String,
  url : String,
) -> @js.Promise[@js.Any] =
  #| (family, url) => {
  #|   const face = new FontFace(family, `url(${url})`)
  #|   return face.load().then(() => {
  #|     document.fonts.add(face)
  #|     return face
  #|   })
  #| }

///|
extern "js" fn rasterize_glyph(
  family : String,
  font_size : Double,
  codepoint : Int,
  smoothing : Bool,
) -> @js.Any =
  #| (() => {
  #|   let canvas = null
  #|   let ctx = null
  #|   const ensure = () => {
  #|     if (!canvas) {
  #|       if (typeof OffscreenCanvas !== "undefined") {
  #|         canvas = new OffscreenCanvas(1, 1)
  #|       } else {
  #|         canvas = document.createElement("canvas")
  #|       }
  #|     }
  #|     if (!ctx) {
  #|       ctx = canvas.getContext("2d")
  #|     }
  #|     return ctx
  #|   }
  #|   return (family, fontSize, codepoint, smoothing) => {
  #|     const context = ensure()
  #|     if (!context) {
  #|       return null
  #|     }
  #|     const size = Math.max(1, Number(fontSize) || 16)
  #|     const text = String.fromCodePoint(Number(codepoint) || 0)
  #|     const fontFamily = family && family.length ? family : "sans-serif"
  #|     const font = `${size}px "${fontFamily}"`
  #|     context.font = font
  #|     context.textBaseline = "alphabetic"
  #|     context.textAlign = "left"
  #|     const metrics = context.measureText(text)
  #|     const left = Math.ceil(metrics.actualBoundingBoxLeft || 0)
  #|     const right = Math.ceil(
  #|       metrics.actualBoundingBoxRight || metrics.width || 0,
  #|     )
  #|     const ascent = Math.ceil(metrics.actualBoundingBoxAscent || size)
  #|     const descent = Math.ceil(metrics.actualBoundingBoxDescent || 0)
  #|     const width = Math.max(1, left + right)
  #|     const height = Math.max(1, ascent + descent)
  #|     canvas.width = width
  #|     canvas.height = height
  #|     context.clearRect(0, 0, width, height)
  #|     context.font = font
  #|     context.textBaseline = "alphabetic"
  #|     context.textAlign = "left"
  #|     context.imageSmoothingEnabled = !!smoothing
  #|     context.fillStyle = "white"
  #|     context.fillText(text, left, ascent)
  #|     const imageData = context.getImageData(0, 0, width, height)
  #|     const data = new Uint8Array(imageData.data.buffer.slice(0))
  #|     return {
  #|       width,
  #|       height,
  #|       offsetX: left,
  #|       offsetY: ascent,
  #|       data,
  #|     }
  #|   }
  #| })()

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
struct SpriteBatch {
  texture_id : Int
  first_instance : Int
  mut instance_count : Int
}

///|
struct WindowState {
  canvas : @js.Any
  mut width : Int
  mut height : Int
  mut scale_factor : Double
}

///|
struct AssetsState {
  pending_textures : Array[PendingTexture]
  fallback_reported : @js.Any
  loading_textures : @js.Any
  texture_paths : @js.Any
  shader_sources : @js.Any
  shader_paths : @js.Any
  loading_shaders : @js.Any
  mut next_shader_id : Int
  mut next_font_id : Int
  fonts : @js.Any
  loading_fonts : @js.Any
  mut next_glyph_id : Int
  glyphs : @js.Any
  mut next_folder_id : Int
  folders : @js.Any
  mut folder_events : Array[Int]
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
  mut format : @webgpu.TextureFormat?
  mut pipeline : @webgpu.GPURenderPipeline?
  mut vertex_buffer : @webgpu.GPUBuffer?
  mut vertex_count : Int
  mut mesh_pipeline : @webgpu.GPURenderPipeline?
  mut mesh_bind_group : @webgpu.GPUBindGroup?
  mut gizmo_pipeline : @webgpu.GPURenderPipeline?
  mut gizmo_vertex_buffer : @webgpu.GPUBuffer?
  mut gizmo_vertex_capacity : Int
  mut gizmo_lines : @js.Any
  mut meshes : @js.Any
  mut next_mesh_id : Int
  mut uniform_buffer : @webgpu.GPUBuffer?
  mut sprite_uniform_buffer : @webgpu.GPUBuffer?
  mut sprite_instance_buffer : @webgpu.GPUBuffer?
  mut sprite_instance_capacity : Int
  mut sprite_globals_bind_group : @webgpu.GPUBindGroup?
  sprite_instance_data : Array[Double]
  sprite_batches : Array[SpriteBatch]
  mut sprite_instance_count : Int
  mut encoder : @webgpu.GPUCommandEncoder?
  mut current_texture : @webgpu.GPUTexture?
  mut current_pass : @webgpu.GPURenderPassEncoder?
  mut current_pass_info : PassInfo?
  mut textures : @js.Any
  mut next_texture_id : Int
  mut fallback_texture_id : Int
  mut sprite_shader_id : Int
  mut mesh_shader_id : Int
  mut gizmo_shader_id : Int
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
      shader_sources: new_map(),
      shader_paths: new_map(),
      loading_shaders: new_set(),
      next_shader_id: 1,
      next_font_id: 1,
      fonts: new_map(),
      loading_fonts: new_set(),
      next_glyph_id: 1,
      glyphs: new_map(),
      next_folder_id: 1,
      folders: new_map(),
      folder_events: [],
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
      gizmo_pipeline: None,
      gizmo_vertex_buffer: None,
      gizmo_vertex_capacity: 0,
      gizmo_lines: new_array(),
      meshes: new_map(),
      next_mesh_id: 1,
      uniform_buffer: None,
      sprite_uniform_buffer: None,
      sprite_instance_buffer: None,
      sprite_instance_capacity: 0,
      sprite_globals_bind_group: None,
      sprite_instance_data: [],
      sprite_batches: [],
      sprite_instance_count: 0,
      encoder: None,
      current_texture: None,
      current_pass: None,
      current_pass_info: None,
      textures: new_map(),
      next_texture_id: 1,
      fallback_texture_id: 0,
      sprite_shader_id: 0,
      mesh_shader_id: 0,
      gizmo_shader_id: 0,
    },
  }
}

///|
fn to_int(value : Double) -> Int {
  value.to_int()
}

///|
fn ints_to_csv(values : Array[Int]) -> String {
  let mut out = ""
  let n = values.length()
  for i in 0..<n {
    if i > 0 {
      out = out + ","
    }
    out = out + values[i].to_string()
  }
  out
}

///|
fn join_asset_path(base : String, entry : String) -> String {
  if base == "" {
    entry
  } else {
    let normalized = strip_leading_slashes(entry)
    let n = base.length()
    if n > 0 && base.code_unit_at(n - 1).to_int() == 47 { // '/'
      base + normalized
    } else {
      base + "/" + normalized
    }
  }
}

///|
fn next_shader_id(state : State) -> Int {
  let id = state.assets.next_shader_id
  state.assets.next_shader_id = id + 1
  id
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
    let scale_factor = get_device_pixel_ratio()
    if width == window_state.width &&
      height == window_state.height &&
      scale_factor == window_state.scale_factor {
      return
    }
    window_state.width = width
    window_state.height = height
    window_state.scale_factor = scale_factor
    target._set("width", @js.any(width)) |> ignore
    target._set("height", @js.any(height)) |> ignore
    if state.gpu.context is Some(context) && state.gpu.device is Some(device) {
      let usage = @webgpu.texture_usage_render_attachment()
      let config = @webgpu.surface_configuration(
        device,
        state.gpu.format.unwrap_or(@webgpu.TextureFormat::Bgra8Unorm),
        @webgpu.AlphaMode::Premultiplied,
        usage,
        @webgpu.surface_size(width, height),
      )
      context.configure(config.to_js())
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
  let client_x : Double = event._get("clientX").cast()
  let client_y : Double = event._get("clientY").cast()
  let left : Double = rect._get("left").cast()
  let top : Double = rect._get("top").cast()
  state.input.mouse_x = client_x - left
  state.input.mouse_y = client_y - top
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
  let format = @webgpu.texture_format_from_string(
    @webgpu.preferred_canvas_format(),
  )
  state.gpu.device = Some(device)
  state.gpu.queue = Some(device.queue())
  state.gpu.context = Some(context)
  state.gpu.format = Some(format)
  state.gpu.pipeline = None
  state.gpu.vertex_buffer = None
  state.gpu.vertex_count = 0
  state.gpu.mesh_pipeline = None
  state.gpu.mesh_bind_group = None
  state.gpu.gizmo_pipeline = None
  state.gpu.gizmo_vertex_buffer = None
  state.gpu.gizmo_vertex_capacity = 0
  state.gpu.gizmo_lines = new_array()
  state.gpu.meshes = new_map()
  state.gpu.next_mesh_id = 1
  state.gpu.uniform_buffer = None
  state.gpu.sprite_uniform_buffer = None
  state.gpu.sprite_instance_buffer = None
  state.gpu.sprite_instance_capacity = 0
  state.gpu.sprite_globals_bind_group = None
  state.gpu.sprite_instance_data.clear()
  state.gpu.sprite_batches.clear()
  state.gpu.sprite_instance_count = 0
  state.gpu.encoder = None
  state.gpu.current_texture = None
  state.gpu.current_pass = None
  state.gpu.current_pass_info = None
  state.gpu.textures = new_map()
  state.gpu.next_texture_id = 1
  state.gpu.fallback_texture_id = 0
  state.gpu.sprite_shader_id = 0
  state.gpu.mesh_shader_id = 0
  state.gpu.gizmo_shader_id = 0
  let sprite_id = next_shader_id(state)
  let mesh_id = next_shader_id(state)
  let gizmo_id = next_shader_id(state)
  state.gpu.sprite_shader_id = sprite_id
  state.gpu.mesh_shader_id = mesh_id
  state.gpu.gizmo_shader_id = gizmo_id
  set_add(state.assets.loading_shaders, @js.any(sprite_id))
  set_add(state.assets.loading_shaders, @js.any(mesh_id))
  set_add(state.assets.loading_shaders, @js.any(gizmo_id))
  map_set(
    state.assets.shader_paths,
    @js.any(sprite_id),
    @js.any("shaders/sprite.wgsl"),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(mesh_id),
    @js.any("shaders/mesh.wgsl"),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(gizmo_id),
    @js.any("shaders/gizmo_lines.wgsl"),
  )
  let sprite_source = load_wgsl_from_path(
    state, sprite_id, "shaders/sprite.wgsl",
  ) catch {
    err => {
      let message = "Shader load error: " + err.to_string()
      console_error(@js.any(message))
      dispatch_asset_error(message)
      ""
    }
  }
  set_delete(state.assets.loading_shaders, @js.any(sprite_id)) |> ignore
  if sprite_source == "" {
    state.gpu.sprite_shader_id = 0
  }
  let mesh_source = load_wgsl_from_path(state, mesh_id, "shaders/mesh.wgsl") catch {
    err => {
      let message = "Shader load error: " + err.to_string()
      console_error(@js.any(message))
      dispatch_asset_error(message)
      ""
    }
  }
  set_delete(state.assets.loading_shaders, @js.any(mesh_id)) |> ignore
  if mesh_source == "" {
    state.gpu.mesh_shader_id = 0
  }
  let gizmo_source = load_wgsl_from_path(
    state, gizmo_id, "shaders/gizmo_lines.wgsl",
  ) catch {
    err => {
      let message = "Shader load error: " + err.to_string()
      console_error(@js.any(message))
      dispatch_asset_error(message)
      ""
    }
  }
  set_delete(state.assets.loading_shaders, @js.any(gizmo_id)) |> ignore
  if gizmo_source == "" {
    state.gpu.gizmo_shader_id = 0
  }
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
    let filter = if nearest {
      @webgpu.FilterMode::Nearest
    } else {
      @webgpu.FilterMode::Linear
    }
    let descriptor = @webgpu.sampler_descriptor(filter, filter)
    Some(device.create_sampler(descriptor.to_js()))
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
    if state.gpu.sprite_shader_id <= 0 {
      return
    }
    let shader_source = get_shader_source(state, state.gpu.sprite_shader_id)
    if shader_source is None {
      return
    }
    let format = state.gpu.format.unwrap_or(@webgpu.TextureFormat::Bgra8Unorm)
    let shader_desc = @webgpu.shader_module_descriptor(shader_source.unwrap())
    let shader_module = device.create_shader_module(shader_desc.to_js())
    let position_attr = @webgpu.vertex_attribute(
      0,
      0,
      @webgpu.VertexFormat::Float32x2,
    )
    let uv_attr = @webgpu.vertex_attribute(
      1,
      8,
      @webgpu.VertexFormat::Float32x2,
    )
    let vertex_layout = @webgpu.vertex_buffer_layout(16, [
      position_attr, uv_attr,
    ])
    let vertex_state = @webgpu.vertex_state(shader_module, "vs_main", [
      vertex_layout,
    ])
    let blend_component = @webgpu.blend_component(
      @webgpu.BlendFactor::SrcAlpha,
      @webgpu.BlendFactor::OneMinusSrcAlpha,
      @webgpu.BlendOperation::Add,
    )
    let blend_state = @webgpu.blend_state(blend_component, blend_component)
    let color_target = @webgpu.color_target_state(format, blend_state)
    let fragment_state = @webgpu.fragment_state(shader_module, "fs_main", [
      color_target,
    ])
    let primitive_state = @webgpu.primitive_state(
      @webgpu.PrimitiveTopology::TriangleList,
    )
    let pipeline_desc = @webgpu.render_pipeline_descriptor(
      @webgpu.PipelineLayout::Auto,
      vertex_state,
      fragment_state,
      primitive_state,
    )
    let pipeline = device.create_render_pipeline(pipeline_desc.to_js())
    let vertices = create_sprite_vertices()
    let vertex_size : Int = vertices._get("byteLength").cast()
    let vertex_usage = @webgpu.combine_flags(
      @webgpu.buffer_usage_vertex(),
      @webgpu.buffer_usage_copy_dst(),
    )
    let vertex_desc = @webgpu.buffer_descriptor(vertex_size, vertex_usage)
    let vertex_buffer = device.create_buffer(vertex_desc.to_js())
    device.queue().write_buffer(vertex_buffer, 0, vertices)
    let uniform_usage = @webgpu.combine_flags(
      @webgpu.buffer_usage_uniform(),
      @webgpu.buffer_usage_copy_dst(),
    )
    let uniform_desc = @webgpu.buffer_descriptor(80, uniform_usage)
    let uniform_buffer = device.create_buffer(uniform_desc.to_js())
    let sprite_uniform_desc = @webgpu.buffer_descriptor(32, uniform_usage)
    let sprite_uniform_buffer = device.create_buffer(
      sprite_uniform_desc.to_js(),
    )
    let instance_usage = @webgpu.combine_flags(
      @webgpu.buffer_usage_storage(),
      @webgpu.buffer_usage_copy_dst(),
    )
    let instance_capacity = 65536
    let instance_desc = @webgpu.buffer_descriptor(
      instance_capacity, instance_usage,
    )
    let sprite_instance_buffer = device.create_buffer(instance_desc.to_js())
    let fallback_size = 64
    let texture_usage = @webgpu.combine_flags(
      @webgpu.combine_flags(
        @webgpu.texture_usage_texture_binding(),
        @webgpu.texture_usage_copy_dst(),
      ),
      @webgpu.texture_usage_render_attachment(),
    )
    let texture_desc = @webgpu.texture_descriptor(
      @webgpu.texture_size(fallback_size, fallback_size),
      @webgpu.TextureFormat::Rgba8Unorm,
      texture_usage,
    )
    let texture = device.create_texture(texture_desc.to_js())
    let pixel_data = create_checkerboard_data(fallback_size)
    write_texture(
      device.queue().as_any(),
      texture.as_any(),
      pixel_data,
      fallback_size * 4,
      fallback_size,
      fallback_size,
    )
    let sampler = create_sampler(state, true)
    if sampler is Some(sampler_value) {
      let entry = @js.from_entries([
        ("id", @js.any(state.gpu.fallback_texture_id)),
        ("texture", texture.as_any()),
        ("view", texture.create_view().as_any()),
        ("sampler", sampler_value.as_any()),
        ("bindGroup", js_null()),
        ("width", @js.any(fallback_size)),
        ("height", @js.any(fallback_size)),
      ])
      map_set(state.gpu.textures, @js.any(state.gpu.fallback_texture_id), entry)
    }
    state.gpu.pipeline = Some(pipeline)
    state.gpu.vertex_buffer = Some(vertex_buffer)
    state.gpu.vertex_count = 6
    state.gpu.uniform_buffer = Some(uniform_buffer)
    state.gpu.sprite_uniform_buffer = Some(sprite_uniform_buffer)
    state.gpu.sprite_instance_buffer = Some(sprite_instance_buffer)
    state.gpu.sprite_instance_capacity = instance_capacity
    state.gpu.sprite_globals_bind_group = None
    state.gpu.sprite_instance_data.clear()
    state.gpu.sprite_batches.clear()
    state.gpu.sprite_instance_count = 0
  }
}

///|
fn ensure_bind_group_for_texture(state : State, entry : @js.Any) -> Unit {
  if state.gpu.pipeline is None {
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
    let layout = pipeline.get_bind_group_layout(0)
    let sampler : @webgpu.GPUSampler = entry._get("sampler").cast()
    let view : @webgpu.GPUTextureView = entry._get("view").cast()
    let entries = [
      @webgpu.bind_group_entry_sampler(0, sampler),
      @webgpu.bind_group_entry_texture(1, view),
    ]
    let bind_group_desc = @webgpu.bind_group_descriptor(layout, entries)
    let bind_group = device.create_bind_group(bind_group_desc.to_js())
    entry._set("bindGroup", bind_group.as_any()) |> ignore
  }
}

///|
fn ensure_sprite_globals_bind_group(state : State) -> Unit {
  if state.gpu.pipeline is None ||
    state.gpu.sprite_uniform_buffer is None ||
    state.gpu.sprite_instance_buffer is None {
    return
  }
  if state.gpu.device is None {
    return
  }
  if state.gpu.sprite_globals_bind_group is Some(_) {
    return
  }
  if state.gpu.device is Some(device) && state.gpu.pipeline is Some(pipeline) {
    let layout = pipeline.get_bind_group_layout(1)
    let uniform_buffer = state.gpu.sprite_uniform_buffer.unwrap()
    let instance_buffer = state.gpu.sprite_instance_buffer.unwrap()
    let entries = [
      @webgpu.bind_group_entry_buffer(0, uniform_buffer),
      @webgpu.bind_group_entry_buffer(1, instance_buffer),
    ]
    let bind_group_desc = @webgpu.bind_group_descriptor(layout, entries)
    let bind_group = device.create_bind_group(bind_group_desc.to_js())
    state.gpu.sprite_globals_bind_group = Some(bind_group)
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
    if state.gpu.mesh_shader_id <= 0 {
      return
    }
    let shader_source = get_shader_source(state, state.gpu.mesh_shader_id)
    if shader_source is None {
      return
    }
    let format = state.gpu.format.unwrap_or(@webgpu.TextureFormat::Bgra8Unorm)
    let shader_desc = @webgpu.shader_module_descriptor(shader_source.unwrap())
    let shader_module = device.create_shader_module(shader_desc.to_js())
    let position_attr = @webgpu.vertex_attribute(
      0,
      0,
      @webgpu.VertexFormat::Float32x2,
    )
    let vertex_layout = @webgpu.vertex_buffer_layout(8, [position_attr])
    let vertex_state = @webgpu.vertex_state(shader_module, "vs_main", [
      vertex_layout,
    ])
    let blend_component = @webgpu.blend_component(
      @webgpu.BlendFactor::SrcAlpha,
      @webgpu.BlendFactor::OneMinusSrcAlpha,
      @webgpu.BlendOperation::Add,
    )
    let blend_state = @webgpu.blend_state(blend_component, blend_component)
    let color_target = @webgpu.color_target_state(format, blend_state)
    let fragment_state = @webgpu.fragment_state(shader_module, "fs_main", [
      color_target,
    ])
    let primitive_state = @webgpu.primitive_state(
      @webgpu.PrimitiveTopology::TriangleList,
    )
    let pipeline_desc = @webgpu.render_pipeline_descriptor(
      @webgpu.PipelineLayout::Auto,
      vertex_state,
      fragment_state,
      primitive_state,
    )
    let pipeline = device.create_render_pipeline(pipeline_desc.to_js())
    state.gpu.mesh_pipeline = Some(pipeline)
    if state.gpu.uniform_buffer is Some(uniform_buffer) {
      let layout = pipeline.get_bind_group_layout(0)
      let entries = [@webgpu.bind_group_entry_buffer(0, uniform_buffer)]
      let bind_group_desc = @webgpu.bind_group_descriptor(layout, entries)
      let bind_group = device.create_bind_group(bind_group_desc.to_js())
      state.gpu.mesh_bind_group = Some(bind_group)
    }
  }
}

///|
fn ensure_gizmo_pipeline(state : State) -> Unit {
  if state.gpu.gizmo_pipeline is Some(_) {
    return
  }
  if state.gpu.device is None {
    return
  }
  if state.gpu.device is Some(device) {
    if state.gpu.gizmo_shader_id <= 0 {
      return
    }
    let shader_source = get_shader_source(state, state.gpu.gizmo_shader_id)
    if shader_source is None {
      return
    }
    let format = state.gpu.format.unwrap_or(@webgpu.TextureFormat::Bgra8Unorm)
    let shader_desc = @webgpu.shader_module_descriptor(shader_source.unwrap())
    let shader_module = device.create_shader_module(shader_desc.to_js())
    let position_attr = @webgpu.vertex_attribute(
      0,
      0,
      @webgpu.VertexFormat::Float32x2,
    )
    let color_attr = @webgpu.vertex_attribute(
      1,
      8,
      @webgpu.VertexFormat::Float32x4,
    )
    let vertex_layout = @webgpu.vertex_buffer_layout(24, [
      position_attr, color_attr,
    ])
    let vertex_state = @webgpu.vertex_state(shader_module, "vs_main", [
      vertex_layout,
    ])
    let blend_component = @webgpu.blend_component(
      @webgpu.BlendFactor::SrcAlpha,
      @webgpu.BlendFactor::OneMinusSrcAlpha,
      @webgpu.BlendOperation::Add,
    )
    let blend_state = @webgpu.blend_state(blend_component, blend_component)
    let color_target = @webgpu.color_target_state(format, blend_state)
    let fragment_state = @webgpu.fragment_state(shader_module, "fs_main", [
      color_target,
    ])
    let primitive_state = @webgpu.primitive_state(
      @webgpu.PrimitiveTopology::TriangleList,
    )
    let pipeline_desc = @webgpu.render_pipeline_descriptor(
      @webgpu.PipelineLayout::Auto,
      vertex_state,
      fragment_state,
      primitive_state,
    )
    let pipeline = device.create_render_pipeline(pipeline_desc.to_js())
    state.gpu.gizmo_pipeline = Some(pipeline)
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
fn get_shader_source(state : State, id : Int) -> String? {
  let entry = map_get(state.assets.shader_sources, @js.any(id))
  if host_is_nullish(entry) {
    None
  } else {
    Some(entry.cast())
  }
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
    let texture_usage = @webgpu.combine_flags(
      @webgpu.combine_flags(
        @webgpu.texture_usage_texture_binding(),
        @webgpu.texture_usage_copy_dst(),
      ),
      @webgpu.texture_usage_render_attachment(),
    )
    let texture_desc = @webgpu.texture_descriptor(
      @webgpu.texture_size(width, height),
      @webgpu.TextureFormat::Rgba8Unorm,
      texture_usage,
    )
    let texture = device.create_texture(texture_desc.to_js())
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
async fn load_wgsl_from_path(state : State, id : Int, path : String) -> String {
  let url = resolve_asset_url(@js.any(path))
  let response = @http.fetch(url, method_="GET")
  if !response.ok {
    fail(
      "Failed to load shader: " + url + " (" + response.status.to_string() + ")",
    )
  }
  let source = response_text(response.as_any()).wait()
  map_set(state.assets.shader_sources, @js.any(id), @js.any(source))
  source
}

///|
async fn fetch_text_from_url(url : String) -> String {
  let response = @http.fetch(url, method_="GET")
  if !response.ok {
    fail("Failed to fetch: " + url + " (" + response.status.to_string() + ")")
  }
  response_text(response.as_any()).wait()
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
  viewport_x : Double,
  viewport_y : Double,
  viewport_width : Double,
  viewport_height : Double,
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
      let clear_color = @webgpu.color(clear_r, clear_g, clear_b, clear_a)
      let attachment = @webgpu.color_attachment_clear(view_value, clear_color)
      let descriptor = @webgpu.render_pass_descriptor([attachment])
      let pass = encoder.begin_render_pass(descriptor.to_js())
      let vp_width = if viewport_width > 0 { viewport_width } else { width }
      let vp_height = if viewport_height > 0 { viewport_height } else { height }
      let vp_x = if viewport_width > 0 { viewport_x } else { 0 }
      let vp_y = if viewport_height > 0 { viewport_y } else { 0 }
      pass.set_viewport(vp_x, vp_y, vp_width, vp_height, 0, 1)
      pass.set_scissor_rect(
        to_int(vp_x),
        to_int(vp_y),
        to_int(vp_width),
        to_int(vp_height),
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
      state.gpu.gizmo_lines = new_array()
      state.gpu.sprite_instance_data.clear()
      state.gpu.sprite_batches.clear()
      state.gpu.sprite_instance_count = 0
      ensure_pipeline_resources(state)
      if state.gpu.queue is Some(queue) &&
        state.gpu.sprite_uniform_buffer is Some(sprite_uniform_buffer) {
        let safe_scale = if cam_scale == 0 { 1.0 } else { cam_scale }
        let scale_x_base = if width > 0 {
          2.0 / width / safe_scale
        } else {
          0.0
        }
        let scale_y_base = if height > 0 {
          2.0 / height / safe_scale
        } else {
          0.0
        }
        let cam_cos : Double = math_cos(-cam_rotation)
        let cam_sin : Double = math_sin(-cam_rotation)
        // Globals: view(x,y,cos,sin) + ndc_scale(x,y,_,_)
        let globals = make_uniform_data([
          cam_x, cam_y, cam_cos, cam_sin, scale_x_base, scale_y_base, 0.0, 0.0,
        ])
        queue.write_buffer(sprite_uniform_buffer, 0, globals)
      }
    }
  }
}

///|
fn flush_sprite_batches(state : State) -> Unit {
  if state.gpu.current_pass is None || state.gpu.current_pass_info is None {
    return
  }
  if state.gpu.sprite_instance_count <= 0 {
    return
  }
  if state.gpu.device is None || state.gpu.queue is None {
    return
  }
  ensure_pipeline_resources(state)
  if state.gpu.pipeline is None ||
    state.gpu.vertex_buffer is None ||
    state.gpu.sprite_instance_buffer is None ||
    state.gpu.sprite_uniform_buffer is None {
    return
  }
  if state.gpu.device is Some(device) && state.gpu.queue is Some(queue) {
    let required_bytes = state.gpu.sprite_instance_data.length() * 4
    if required_bytes <= 0 {
      return
    }
    if required_bytes > state.gpu.sprite_instance_capacity {
      let capacity = if required_bytes < 256 { 256 } else { required_bytes }
      let usage = @webgpu.combine_flags(
        @webgpu.buffer_usage_storage(),
        @webgpu.buffer_usage_copy_dst(),
      )
      let desc = @webgpu.buffer_descriptor(capacity, usage)
      let buffer = device.create_buffer(desc.to_js())
      state.gpu.sprite_instance_buffer = Some(buffer)
      state.gpu.sprite_instance_capacity = capacity
      state.gpu.sprite_globals_bind_group = None
    }
    ensure_sprite_globals_bind_group(state)
    if state.gpu.sprite_instance_buffer is Some(instance_buffer) &&
      state.gpu.sprite_globals_bind_group is Some(globals_bind_group) &&
      state.gpu.pipeline is Some(pipeline) &&
      state.gpu.vertex_buffer is Some(vertex_buffer) &&
      state.gpu.current_pass is Some(pass) {
      let instance_data = float32array_from_array(
        state.gpu.sprite_instance_data,
      )
      queue.write_buffer(instance_buffer, 0, instance_data)
      pass.set_pipeline(pipeline)
      pass.set_vertex_buffer(0, vertex_buffer)
      pass.set_bind_group(1, globals_bind_group)
      for batch in state.gpu.sprite_batches {
        let entry = get_texture_entry(state, batch.texture_id)
        if entry is None {
          continue
        }
        if entry is Some(entry_value) {
          ensure_bind_group_for_texture(state, entry_value)
          let bind_group_any = entry_value._get("bindGroup")
          if host_is_nullish(bind_group_any) {
            continue
          }
          pass.set_bind_group(0, bind_group_any.cast())
          pass.draw(
            state.gpu.vertex_count,
            batch.instance_count,
            0,
            batch.first_instance,
          )
        }
      }
      state.gpu.sprite_instance_data.clear()
      state.gpu.sprite_batches.clear()
      state.gpu.sprite_instance_count = 0
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
  draw_sprite_uv(
    state, texture_id, x, y, rotation, scale_x, scale_y, r, g, b, a, 0.0, 0.0, 1.0,
    1.0,
  )
}

///|
fn draw_sprite_uv(
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
  uv_min_x : Double,
  uv_min_y : Double,
  uv_max_x : Double,
  uv_max_y : Double,
) -> Unit {
  if !ensure_pass_ready(state) {
    return
  }
  let entry = get_texture_entry(state, texture_id)
  if entry is None {
    return
  }
  if entry is Some(entry_value) {
    let tex_width : Double = entry_value._get("width").cast()
    let tex_height : Double = entry_value._get("height").cast()
    let raw_uv_scale_x = uv_max_x - uv_min_x
    let raw_uv_scale_y = uv_max_y - uv_min_y
    let uv_scale_x = if raw_uv_scale_x <= 0 { 1.0 } else { raw_uv_scale_x }
    let uv_scale_y = if raw_uv_scale_y <= 0 { 1.0 } else { raw_uv_scale_y }
    let region_width = tex_width * uv_scale_x
    let region_height = tex_height * uv_scale_y
    let base_size = 128.0
    let tex_scale_x = if region_width > 0 {
      region_width / base_size
    } else {
      1
    }
    let tex_scale_y = if region_height > 0 {
      region_height / base_size
    } else {
      1
    }
    let sprite_scale_x = scale_x * tex_scale_x
    let sprite_scale_y = scale_y * tex_scale_y
    let cos_value : Double = math_cos(rotation)
    let sin_value : Double = math_sin(rotation)
    let actual_texture_id : Int = entry_value._get("id").cast()
    let first_instance = state.gpu.sprite_instance_count
    state.gpu.sprite_instance_count = first_instance + 1

    // Instance layout: model(x,y,cos,sin), scale(x,y,_,_), color, uv(min_x,min_y,scale_x,scale_y)
    state.gpu.sprite_instance_data.push(x)
    state.gpu.sprite_instance_data.push(y)
    state.gpu.sprite_instance_data.push(cos_value)
    state.gpu.sprite_instance_data.push(sin_value)
    state.gpu.sprite_instance_data.push(sprite_scale_x)
    state.gpu.sprite_instance_data.push(sprite_scale_y)
    state.gpu.sprite_instance_data.push(0.0)
    state.gpu.sprite_instance_data.push(0.0)
    state.gpu.sprite_instance_data.push(r)
    state.gpu.sprite_instance_data.push(g)
    state.gpu.sprite_instance_data.push(b)
    state.gpu.sprite_instance_data.push(a)
    state.gpu.sprite_instance_data.push(uv_min_x)
    state.gpu.sprite_instance_data.push(uv_min_y)
    state.gpu.sprite_instance_data.push(uv_scale_x)
    state.gpu.sprite_instance_data.push(uv_scale_y)
    let batch_count = state.gpu.sprite_batches.length()
    if batch_count > 0 &&
      state.gpu.sprite_batches[batch_count - 1].texture_id == actual_texture_id {
      state.gpu.sprite_batches[batch_count - 1].instance_count = state.gpu.sprite_batches[batch_count -
        1].instance_count +
        1
    } else {
      state.gpu.sprite_batches.push(SpriteBatch::{
        texture_id: actual_texture_id,
        first_instance,
        instance_count: 1,
      })
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
  flush_sprite_batches(state)
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
    let safe_scale = if info.cam_scale == 0 { 1.0 } else { info.cam_scale }
    let scale_x_base = if info.width > 0 {
      2.0 / info.width / safe_scale
    } else {
      0.0
    }
    let scale_y_base = if info.height > 0 {
      2.0 / info.height / safe_scale
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
      0.0,
      0.0,
      1.0,
      1.0,
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
fn draw_gizmo_lines(state : State, data : @js.Any) -> Unit {
  if state.gpu.current_pass is None || state.gpu.current_pass_info is None {
    return
  }
  if state.gpu.queue is None || state.gpu.device is None {
    return
  }
  ensure_gizmo_pipeline(state)
  if state.gpu.gizmo_pipeline is None {
    return
  }
  if state.gpu.current_pass is Some(pass) &&
    state.gpu.current_pass_info is Some(info) &&
    state.gpu.queue is Some(queue) {
    let vertex_data = build_gizmo_vertices(
      data,
      info.cam_x,
      info.cam_y,
      info.cam_rotation,
      info.cam_scale,
      info.width,
      info.height,
      2.0,
    )
    let vertex_len : Double = vertex_data._get("length").cast()
    if vertex_len <= 0 {
      return
    }
    let vertex_count = to_int(vertex_len / 6.0)
    if vertex_count <= 0 {
      return
    }
    let vertex_size : Int = vertex_data._get("byteLength").cast()
    let mut buffer_opt = state.gpu.gizmo_vertex_buffer
    if buffer_opt is None || vertex_size > state.gpu.gizmo_vertex_capacity {
      if state.gpu.device is Some(device) {
        let capacity = if vertex_size < 256 { 256 } else { vertex_size }
        let usage = @webgpu.combine_flags(
          @webgpu.buffer_usage_vertex(),
          @webgpu.buffer_usage_copy_dst(),
        )
        let desc = @webgpu.buffer_descriptor(capacity, usage)
        let buffer = device.create_buffer(desc.to_js())
        state.gpu.gizmo_vertex_buffer = Some(buffer)
        state.gpu.gizmo_vertex_capacity = capacity
        buffer_opt = Some(buffer)
      }
    }
    if buffer_opt is Some(buffer) && state.gpu.gizmo_pipeline is Some(pipeline) {
      queue.write_buffer(buffer, 0, vertex_data)
      pass.set_pipeline(pipeline)
      pass.set_vertex_buffer(0, buffer)
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
    let scale_factor = get_device_pixel_ratio()
    target._set("width", @js.any(pixel_width)) |> ignore
    target._set("height", @js.any(pixel_height)) |> ignore
    state.window = Some(WindowState::{
      canvas: target,
      width: pixel_width,
      height: pixel_height,
      scale_factor,
    })
    init_input(state)
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
  let window_get_scale_factor = @js.from_fn1(fn(_ : @js.Any) {
    update_window_size(state)
    if state.window is Some(window_state) {
      window_state.scale_factor
    } else {
      1.0
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
  let debug_string = @js.from_fn1(fn(value) {
    console_error(@js.any(any_to_string(value)))
    0
  })
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
          let config = @webgpu.surface_configuration(
            device,
            state.gpu.format.unwrap_or(@webgpu.TextureFormat::Bgra8Unorm),
            @webgpu.AlphaMode::Premultiplied,
            usage,
            @webgpu.surface_size(width_int, height_int),
          )
          context.configure(config.to_js())
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
      // Always pass the coerced JS string to avoid relying on wasm-gc string interop here.
      let result = load_texture_from_path(
        state,
        id,
        @js.any(path_text),
        nearest_value,
      ) catch {
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
  let asset_load_wgsl = @js.from_fn1(fn(path) {
    let id = next_shader_id(state)
    set_add(state.assets.loading_shaders, @js.any(id))
    let path_text = coerce_asset_path(path)
    if path_text != "" {
      map_set(state.assets.shader_paths, @js.any(id), @js.any(path_text))
    }
    @js.run_async(async fn() noraise {
      let result = load_wgsl_from_path(state, id, path_text) catch {
        err => {
          let message = "Shader load error: " + err.to_string()
          console_error(@js.any(message))
          dispatch_asset_error(message)
          ""
        }
      }
      set_delete(state.assets.loading_shaders, @js.any(id)) |> ignore
      result |> ignore
    })
    id
  })
  let asset_load_font = @js.from_fn1(fn(path) {
    let id = state.assets.next_font_id
    state.assets.next_font_id = id + 1
    let path_text = coerce_asset_path(path)
    if path_text == "" {
      return id
    }
    let url = resolve_asset_url(@js.any(path_text)) catch {
      err => {
        let message = "Font load error: " + err.to_string()
        console_error(@js.any(message))
        dispatch_asset_error(message)
        ""
      }
    }
    if url == "" {
      return id
    }
    let family = "mgstudio-font-" + id.to_string()
    let entry = @js.from_entries([
      ("id", @js.any(id)),
      ("family", @js.any(family)),
      ("loaded", @js.any(false)),
    ])
    map_set(state.assets.fonts, @js.any(id), entry)
    set_add(state.assets.loading_fonts, @js.any(id))
    @js.run_async(async fn() noraise {
      let result = load_font_face(family, url).wait() catch {
        err => {
          let message = "Font load error: " + err.to_string()
          console_error(@js.any(message))
          dispatch_asset_error(message)
          js_null()
        }
      }
      if !host_is_nullish(result) {
        entry._set("loaded", @js.any(true)) |> ignore
      }
      set_delete(state.assets.loading_fonts, @js.any(id)) |> ignore
      result |> ignore
    })
    id
  })
  let font_rasterize_glyph = wrap_variadic(
    @js.from_fn1(fn(args) {
      let font_id = to_int(arg_number(args, 0, -1))
      let font_size = arg_number(args, 1, 16)
      let codepoint = to_int(arg_number(args, 2, 0))
      let smoothing = arg_number(args, 3, 1) != 0
      let entry = map_get(state.assets.fonts, @js.any(font_id))
      if host_is_nullish(entry) {
        dispatch_asset_error("Font rasterize error: font id not found")
        return ""
      }
      let family = any_to_string(entry._get("family"))
      let result = rasterize_glyph(family, font_size, codepoint, smoothing)
      if host_is_nullish(result) {
        dispatch_asset_error("Font rasterize error: rasterizer unavailable")
        return ""
      }
      let glyph_id = state.assets.next_glyph_id
      state.assets.next_glyph_id = glyph_id + 1
      let width = to_int(number_or(result._get("width"), 0))
      let height = to_int(number_or(result._get("height"), 0))
      let offset_x = to_int(number_or(result._get("offsetX"), 0))
      let offset_y = to_int(number_or(result._get("offsetY"), 0))
      let data = result._get("data")
      let glyph_entry = @js.from_entries([
        ("width", @js.any(width)),
        ("height", @js.any(height)),
        ("offsetX", @js.any(offset_x)),
        ("offsetY", @js.any(offset_y)),
        ("data", data),
      ])
      map_set(state.assets.glyphs, @js.any(glyph_id), glyph_entry)
      glyph_id.to_string() +
      "," +
      width.to_string() +
      "," +
      height.to_string() +
      "," +
      offset_x.to_string() +
      "," +
      offset_y.to_string()
    }),
  )
  let asset_set_texture_sampler = @js.from_fn2(fn(texture_id, sampler_kind) {
    let id = to_int(number_or(texture_id, -1))
    let entry = map_get(state.gpu.textures, @js.any(id))
    if host_is_nullish(entry) {
      return
    }
    let nearest = number_or(sampler_kind, 0) != 0
    let sampler = create_sampler(state, nearest)
    if sampler is Some(sampler_value) {
      entry._set("sampler", sampler_value.as_any()) |> ignore
      entry._set("bindGroup", js_null()) |> ignore
      ensure_bind_group_for_texture(state, entry)
    }
  })
  let asset_create_dynamic_texture = @js.from_fn3(fn(width, height, nearest) {
    if state.gpu.device is None {
      throw_error("GPU device not ready")
      return 0
    }
    ensure_pipeline_resources(state)
    let id = state.gpu.next_texture_id
    state.gpu.next_texture_id = id + 1
    map_set(
      state.assets.texture_paths,
      @js.any(id),
      @js.any("<dynamic-texture>"),
    )
    let width_value = number_or(width, 1)
    let height_value = number_or(height, 1)
    let safe_width = if width_value > 0 { to_int(width_value) } else { 1 }
    let safe_height = if height_value > 0 { to_int(height_value) } else { 1 }
    if state.gpu.device is Some(device) {
      let texture_usage = @webgpu.combine_flags(
        @webgpu.combine_flags(
          @webgpu.texture_usage_texture_binding(),
          @webgpu.texture_usage_copy_dst(),
        ),
        @webgpu.texture_usage_render_attachment(),
      )
      let texture_desc = @webgpu.texture_descriptor(
        @webgpu.texture_size(safe_width, safe_height),
        @webgpu.TextureFormat::Rgba8Unorm,
        texture_usage,
      )
      let texture = device.create_texture(texture_desc.to_js())
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
  let asset_update_texture_region = wrap_variadic(
    @js.from_fn1(fn(args) {
      let texture_id = to_int(arg_number(args, 0, -1))
      let x = to_int(arg_number(args, 1, 0))
      let y = to_int(arg_number(args, 2, 0))
      let width = to_int(arg_number(args, 3, 0))
      let height = to_int(arg_number(args, 4, 0))
      let glyph_id = to_int(arg_number(args, 5, -1))
      let texture_entry = map_get(state.gpu.textures, @js.any(texture_id))
      if host_is_nullish(texture_entry) {
        dispatch_asset_error("Texture update error: texture id not found")
        return
      }
      let glyph_entry = map_get(state.assets.glyphs, @js.any(glyph_id))
      if host_is_nullish(glyph_entry) {
        dispatch_asset_error("Texture update error: glyph id not found")
        return
      }
      let glyph_width = to_int(number_or(glyph_entry._get("width"), 0))
      let glyph_height = to_int(number_or(glyph_entry._get("height"), 0))
      let target_width = if width > 0 { width } else { glyph_width }
      let target_height = if height > 0 { height } else { glyph_height }
      if target_width <= 0 || target_height <= 0 {
        return
      }
      if state.gpu.queue is Some(queue) {
        let data = glyph_entry._get("data")
        write_texture_region(
          queue.as_any(),
          texture_entry._get("texture"),
          data,
          target_width,
          target_height,
          x,
          y,
        )
      }
    }),
  )
  let asset_load_folder = @js.from_fn1(fn(_path : @js.Any) {
    let id = state.assets.next_folder_id
    state.assets.next_folder_id = id + 1
    let empty_handles : Array[Int] = []
    map_set(state.assets.folders, @js.any(id), @js.any(empty_handles))
    let path_text = coerce_asset_path(_path)
    @js.run_async(async fn() noraise {
      let handles : Array[Int] = []
      if path_text != "" {
        let manifest_path = join_asset_path(path_text, "folder.txt")
        let url = resolve_asset_url(@js.any(manifest_path)) catch {
          err => {
            let message = "Folder load error: " + err.to_string()
            console_error(@js.any(message))
            dispatch_asset_error(message)
            ""
          }
        }
        if url != "" {
          let manifest = fetch_text_from_url(url) catch {
            err => {
              let message = "Folder load error: " + err.to_string()
              console_error(@js.any(message))
              dispatch_asset_error(message)
              ""
            }
          }
          if manifest != "" {
            for entry in split_trimmed_lines(manifest) {
              let asset_path = join_asset_path(path_text, entry)
              let tex_id = state.gpu.next_texture_id
              state.gpu.next_texture_id = tex_id + 1
              set_add(state.assets.loading_textures, @js.any(tex_id))
              if asset_path != "" {
                map_set(
                  state.assets.texture_paths,
                  @js.any(tex_id),
                  @js.any(asset_path),
                )
              }
              let result = load_texture_from_path(
                state,
                tex_id,
                @js.any(asset_path),
                false,
              ) catch {
                err => {
                  let message = "Texture load error: " + err.to_string()
                  console_error(@js.any(message))
                  dispatch_asset_error(message)
                  set_delete(state.assets.loading_textures, @js.any(tex_id))
                  |> ignore
                }
              }
              result |> ignore
              handles.push(tex_id)
            }
          }
        }
      }
      map_set(state.assets.folders, @js.any(id), @js.any(handles))
      state.assets.folder_events.push(3)
      state.assets.folder_events.push(id)
    })
    id
  })
  let asset_poll_loaded_folder_events = @js.from_fn0(fn() {
    let events = state.assets.folder_events
    state.assets.folder_events = []
    ints_to_csv(events)
  })
  let asset_get_loaded_folder_handles = @js.from_fn1(fn(folder_id) {
    let id = to_int(number_or(folder_id, -1))
    let entry = map_get(state.assets.folders, @js.any(id))
    if host_is_nullish(entry) {
      ""
    } else {
      ints_to_csv(entry.cast())
    }
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
      let format = state.gpu.format.unwrap_or(@webgpu.TextureFormat::Bgra8Unorm)
      let texture_usage = @webgpu.combine_flags(
        @webgpu.combine_flags(
          @webgpu.texture_usage_texture_binding(),
          @webgpu.texture_usage_render_attachment(),
        ),
        @webgpu.texture_usage_copy_dst(),
      )
      let texture_desc = @webgpu.texture_descriptor(
        @webgpu.texture_size(safe_width, safe_height),
        format,
        texture_usage,
      )
      let texture = device.create_texture(texture_desc.to_js())
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
      let vertex_size : Int = vertices._get("byteLength").cast()
      let vertex_usage = @webgpu.combine_flags(
        @webgpu.buffer_usage_vertex(),
        @webgpu.buffer_usage_copy_dst(),
      )
      let vertex_desc = @webgpu.buffer_descriptor(vertex_size, vertex_usage)
      let vertex_buffer = device.create_buffer(vertex_desc.to_js())
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
      let vertex_size : Int = vertices._get("byteLength").cast()
      let vertex_usage = @webgpu.combine_flags(
        @webgpu.buffer_usage_vertex(),
        @webgpu.buffer_usage_copy_dst(),
      )
      let vertex_desc = @webgpu.buffer_descriptor(vertex_size, vertex_usage)
      let vertex_buffer = device.create_buffer(vertex_desc.to_js())
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
  let gpu_create_mesh_triangles = @js.from_fn1(fn(vertices_xy) {
    if state.gpu.device is None {
      throw_error("GPU device not ready")
      return 0
    }
    ensure_mesh_pipeline(state)
    let id = state.gpu.next_mesh_id
    state.gpu.next_mesh_id = id + 1
    let vertices = float32array_from_csv(any_to_string(vertices_xy))
    if state.gpu.device is Some(device) {
      let vertex_size : Int = vertices._get("byteLength").cast()
      let vertex_usage = @webgpu.combine_flags(
        @webgpu.buffer_usage_vertex(),
        @webgpu.buffer_usage_copy_dst(),
      )
      let vertex_desc = @webgpu.buffer_descriptor(vertex_size, vertex_usage)
      let vertex_buffer = device.create_buffer(vertex_desc.to_js())
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
        arg_number(args, 11, 0),
        arg_number(args, 12, 0),
        arg_number(args, 13, 0),
        arg_number(args, 14, 0),
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
  let gpu_draw_sprite_uv = wrap_variadic(
    @js.from_fn1(fn(args) {
      draw_sprite_uv(
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
        arg_number(args, 10, 0),
        arg_number(args, 11, 0),
        arg_number(args, 12, 1),
        arg_number(args, 13, 1),
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
  let gpu_draw_gizmo_line = wrap_variadic(
    @js.from_fn1(fn(args) {
      push_gizmo_line(
        state.gpu.gizmo_lines,
        arg_number(args, 0, 0),
        arg_number(args, 1, 0),
        arg_number(args, 2, 1),
        arg_number(args, 3, 1),
        arg_number(args, 4, 1),
        arg_number(args, 5, 1),
        arg_number(args, 6, 0),
        arg_number(args, 7, 0),
        arg_number(args, 8, 1),
        arg_number(args, 9, 1),
        arg_number(args, 10, 1),
        arg_number(args, 11, 1),
        arg_number(args, 12, 2),
        to_int(arg_number(args, 13, 0)),
        arg_number(args, 14, 1),
        arg_number(args, 15, 1),
      )
    }),
  )
  let gpu_end_pass = @js.from_fn0(fn() {
    if state.gpu.current_pass is Some(_) {
      flush_sprite_batches(state)
      draw_gizmo_lines(state, state.gpu.gizmo_lines)
    }
    if state.gpu.current_pass is Some(pass) {
      pass.end()
    }
    state.gpu.current_pass = None
    state.gpu.current_pass_info = None
    state.gpu.gizmo_lines = new_array()
  })
  let gpu_end_frame = @js.from_fn1(fn(_ : @js.Any) {
    if state.gpu.device is None ||
      state.gpu.queue is None ||
      state.gpu.encoder is None {
      return
    }
    if state.gpu.current_pass is Some(pass) {
      flush_sprite_batches(state)
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
    ("window_get_scale_factor", window_get_scale_factor),
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
    (
      "string_sink_push",
      @js.from_fn1(fn(code_unit) {
        string_sink_push(to_int(number_or(code_unit, 0)))
      }),
    ),
    ("asset_load_texture", asset_load_texture),
    ("asset_load_wgsl", asset_load_wgsl),
    ("asset_load_font", asset_load_font),
    ("font_rasterize_glyph", font_rasterize_glyph),
    ("asset_set_texture_sampler", asset_set_texture_sampler),
    ("asset_create_dynamic_texture", asset_create_dynamic_texture),
    ("asset_update_texture_region", asset_update_texture_region),
    ("asset_load_folder", asset_load_folder),
    ("asset_poll_loaded_folder_events", asset_poll_loaded_folder_events),
    ("asset_get_loaded_folder_handles", asset_get_loaded_folder_handles),
    ("gpu_create_render_target", gpu_create_render_target),
    ("gpu_create_mesh_capsule", gpu_create_mesh_capsule),
    ("gpu_create_mesh_rectangle", gpu_create_mesh_rectangle),
    ("gpu_create_mesh_triangles", gpu_create_mesh_triangles),
    ("gpu_begin_frame", gpu_begin_frame),
    ("gpu_begin_pass", gpu_begin_pass),
    ("gpu_draw_sprite", gpu_draw_sprite),
    ("gpu_draw_sprite_uv", gpu_draw_sprite_uv),
    ("gpu_draw_mesh", gpu_draw_mesh),
    ("gpu_draw_gizmo_line", gpu_draw_gizmo_line),
    ("gpu_end_pass", gpu_end_pass),
    ("gpu_end_frame", gpu_end_frame),
  ])
  let init = @js.from_fn0(fn() {
    @js.Promise::new(async fn(resolve, _reject) {
      let target = default_canvas
      init_webgpu(state, target)
      init_input(state)
      resolve(())
    })
  })
  @js.from_entries([("mgstudio_host", mgstudio_host), ("init", init)])
}
