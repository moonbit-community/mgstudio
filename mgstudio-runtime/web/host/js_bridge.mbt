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
extern "js" fn string_sink_reset_js() -> Unit =
  #| () => { globalThis.__mgstudio_string_sink_buf = "" }

///|
extern "js" fn string_sink_take_js() -> String =
  #| () => {
  #|   const out = globalThis.__mgstudio_string_sink_buf || ""
  #|   globalThis.__mgstudio_string_sink_buf = ""
  #|   return out
  #| }

///|
/// Bytes sink helpers (engine -> host).
///
/// We mirror the existing `string_sink_*` protocol but for raw bytes. This is
/// used for uploading RGBA8 data (e.g. glyph atlas updates) without passing
/// wasm `Bytes` across the boundary.
extern "js" fn bytes_sink_push_js(byte : Int) -> Unit =
  #| (byte) => {
  #|   const b = Number(byte) & 0xff
  #|   globalThis.__mgstudio_bytes_sink_buf = (globalThis.__mgstudio_bytes_sink_buf || [])
  #|   globalThis.__mgstudio_bytes_sink_buf.push(b)
  #| }

///|
extern "js" fn bytes_sink_push_u32_js(word : Int) -> Unit =
  #| (word) => {
  #|   const u = Number(word) >>> 0
  #|   globalThis.__mgstudio_bytes_sink_buf = (globalThis.__mgstudio_bytes_sink_buf || [])
  #|   globalThis.__mgstudio_bytes_sink_buf.push(u & 0xff, (u >>> 8) & 0xff, (u >>> 16) & 0xff, (u >>> 24) & 0xff)
  #| }

///|
extern "js" fn bytes_sink_reset_js() -> Unit =
  #| () => { globalThis.__mgstudio_bytes_sink_buf = [] }

///|
extern "js" fn bytes_sink_take_js() -> @js.Any =
  #| () => {
  #|   const arr = globalThis.__mgstudio_bytes_sink_buf || []
  #|   globalThis.__mgstudio_bytes_sink_buf = []
  #|   return new Uint8Array(arr)
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
  #|   if (typeof value === "object") {
  #|     try {
  #|       const name = typeof value.name === "string" ? value.name : ""
  #|       const message = typeof value.message === "string" ? value.message : ""
  #|       if (message.length > 0) {
  #|         return name.length > 0 ? `${name}: ${message}` : message
  #|       }
  #|     } catch {
  #|     }
  #|   }
  #|   // Decode MoonBit wasm `String` (typically an array of UTF-16 i16 code units).
  #|   // NOTE: some engines expose `length` as BigInt or via a getter; avoid strict typeof checks.
  #|   try {
  #|     let current = value
  #|     for (let i = 0; i < 4; i += 1) {
  #|       if (typeof current !== "object" || current == null) {
  #|         break
  #|       }
  #|       // Unwrap common wrapper shapes (defensive, for wasm reference objects).
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
extern "js" fn shader_module_get_compilation_info(
  shader_module_any : @js.Any,
) -> @js.Promise[@js.Any] =
  #| (shader_module_any) => {
  #|   if (!shader_module_any || typeof shader_module_any.getCompilationInfo !== "function") {
  #|     return Promise.resolve(null)
  #|   }
  #|   return shader_module_any.getCompilationInfo()
  #| }

///|
extern "js" fn shader_compilation_info_to_text(info : @js.Any) -> String =
  #| (info) => {
  #|   if (!info || !Array.isArray(info.messages)) return ""
  #|   const lines = []
  #|   for (const message of info.messages) {
  #|     const type = message?.type ?? "info"
  #|     const line = Number(message?.lineNum ?? 0)
  #|     const pos = Number(message?.linePos ?? 0)
  #|     const text = String(message?.message ?? "")
  #|     lines.push(`${type} L${line}:${pos} ${text}`)
  #|   }
  #|   return lines.join("\n")
  #| }

///|
extern "js" fn idb_open_kv_db(name : String) -> @js.Promise[@js.Any] =
  #| (name) => new Promise((resolve, reject) => {
  #|   if (typeof indexedDB === "undefined") {
  #|     reject(new Error("IndexedDB is not available"))
  #|     return
  #|   }
  #|   const dbName = `mgstudio:${name}`
  #|   const req = indexedDB.open(dbName, 1)
  #|   req.onupgradeneeded = () => {
  #|     const db = req.result
  #|     try {
  #|       if (!db.objectStoreNames.contains("kv")) {
  #|         db.createObjectStore("kv")
  #|       }
  #|     } catch (e) {
  #|       // ignore
  #|     }
  #|   }
  #|   req.onsuccess = () => resolve(req.result)
  #|   req.onerror = () => reject(req.error || new Error("IndexedDB open failed"))
  #| })

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
extern "js" fn bind_uncaptured_error_handler(
  device : @js.Any,
  handler : @js.Any,
) -> Unit =
  #| (device, handler) => {
  #|   if (!device) {
  #|     return
  #|   }
  #|   if (typeof device.addEventListener === "function") {
  #|     device.addEventListener("uncapturederror", handler)
  #|     return
  #|   }
  #|   // Fallback for implementations that only expose the property handler.
  #|   try {
  #|     device.onuncapturederror = handler
  #|   } catch {
  #|   }
  #| }

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
extern "js" fn url_search_param_enabled(name : String) -> Bool =
  #| (name) => {
  #|   try {
  #|     const raw = new URLSearchParams(window.location.search).get(name)
  #|     if (raw === null) return false
  #|     const value = String(raw).trim().toLowerCase()
  #|     if (value === "" || value === "1" || value === "true" || value === "on" || value === "yes") {
  #|       return true
  #|     }
  #|     return false
  #|   } catch (_e) {
  #|     return false
  #|   }
  #| }

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
extern "js" fn set_canvas_target_pixel_size(
  canvas : @js.Any,
  pixel_width : Int,
  pixel_height : Int,
) -> Unit =
  #| (canvas, pixelWidth, pixelHeight) => {
  #|   if (!canvas) return
  #|   const dpr = window.devicePixelRatio || 1
  #|   const pw = Math.max(1, Number(pixelWidth) | 0)
  #|   const ph = Math.max(1, Number(pixelHeight) | 0)
  #|   const cssW = Math.max(1, Math.round(pw / Math.max(1e-6, dpr)))
  #|   const cssH = Math.max(1, Math.round(ph / Math.max(1e-6, dpr)))
  #|   if (canvas.style) {
  #|     canvas.style.width = `${cssW}px`
  #|     canvas.style.height = `${cssH}px`
  #|   }
  #|   canvas.width = pw
  #|   canvas.height = ph
  #| }

///|
extern "js" fn set_document_title_js(title : String) -> Unit =
  #| (title) => {
  #|   if (typeof document === "object" && document) {
  #|     document.title = String(title ?? "")
  #|   }
  #| }

///|
extern "js" fn set_canvas_cursor_visible_js(
  canvas : @js.Any,
  visible : Bool,
) -> Unit =
  #| (canvas, visible) => {
  #|   if (!canvas || !canvas.style) return
  #|   canvas.style.cursor = visible ? "" : "none"
  #| }

///|
extern "js" fn set_canvas_cursor_grab_mode_js(
  canvas : @js.Any,
  mode : Int,
) -> Unit =
  #| (canvas, mode) => {
  #|   if (!canvas) return
  #|   const m = Number(mode) | 0
  #|   const doc = typeof document === "object" ? document : null
  #|   if (!doc) return
  #|   const hasPointerLockApi =
  #|     typeof doc.exitPointerLock === "function" &&
  #|     typeof canvas.requestPointerLock === "function"
  #|   if (!hasPointerLockApi) return
  #|   if (m === 1 || m === 2) {
  #|     // Web has pointer lock, but no separate "confined" mode.
  #|     if (doc.pointerLockElement === canvas) return
  #|     try {
  #|       const p = canvas.requestPointerLock()
  #|       if (p && typeof p.catch === "function") p.catch(() => {})
  #|     } catch (_) {}
  #|     return
  #|   }
  #|   if (doc.pointerLockElement === canvas) {
  #|     try {
  #|       doc.exitPointerLock()
  #|     } catch (_) {}
  #|   }
  #| }

///|
extern "js" fn set_window_mode_js(canvas : @js.Any, mode : Int) -> Unit =
  #| (canvas, mode) => {
  #|   const m = Number(mode) | 0
  #|   const doc = typeof document === "object" ? document : null
  #|   if (!doc || !canvas) return
  #|   if (m === 0) {
  #|     if (doc.fullscreenElement && typeof doc.exitFullscreen === "function") {
  #|       const p = doc.exitFullscreen()
  #|       if (p && typeof p.catch === "function") p.catch(() => {})
  #|     }
  #|     return
  #|   }
  #|   if (doc.fullscreenElement === canvas) return
  #|   // Web cannot provide native-exclusive fullscreen; mode=2 maps to the
  #|   // same fullscreen request path as borderless mode.
  #|   if (typeof canvas.requestFullscreen === "function") {
  #|     const p = canvas.requestFullscreen()
  #|     if (p && typeof p.catch === "function") p.catch(() => {})
  #|   }
  #| }

///|
extern "js" fn window_move_to_js(x : Int, y : Int) -> Unit =
  #| (x, y) => {
  #|   if (typeof window !== "object" || !window) return
  #|   if (typeof window.moveTo !== "function") return
  #|   try {
  #|     window.moveTo(Number(x) | 0, Number(y) | 0)
  #|   } catch (_) {}
  #| }

///|
extern "js" fn window_screen_x_js() -> Int =
  #| () => {
  #|   if (typeof window !== "object" || !window) return 0
  #|   const x = typeof window.screenX === "number" ? window.screenX : 0
  #|   return x | 0
  #| }

///|
extern "js" fn window_screen_y_js() -> Int =
  #| () => {
  #|   if (typeof window !== "object" || !window) return 0
  #|   const y = typeof window.screenY === "number" ? window.screenY : 0
  #|   return y | 0
  #| }

///|
extern "js" fn get_bounding_rect(canvas : @js.Any) -> @js.Any =
  #| (canvas) => canvas.getBoundingClientRect()

///|
extern "js" fn prevent_default(event : @js.Any) -> Unit =
  #| (event) => event.preventDefault()

///|
extern "js" fn keyboard_event_character(event : @js.Any) -> String =
  #| (event) => {
  #|   if (!event || typeof event !== "object") {
  #|     return ""
  #|   }
  #|   if (event.ctrlKey || event.metaKey) {
  #|     return ""
  #|   }
  #|   const key = typeof event.key === "string" ? event.key : ""
  #|   if (!key || key === "Dead" || key === "Unidentified") {
  #|     return ""
  #|   }
  #|   const nonTextKeys = new Set([
  #|     "Alt", "AltGraph", "CapsLock", "Control", "Fn", "FnLock", "Meta",
  #|     "NumLock", "ScrollLock", "Shift", "Super", "Hyper", "Symbol",
  #|     "SymbolLock", "Tab", "Enter", "Escape", "Backspace", "Delete", "Insert",
  #|     "Home", "End", "PageUp", "PageDown", "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight",
  #|     "PrintScreen", "Pause", "ContextMenu",
  #|   ])
  #|   if (nonTextKeys.has(key)) {
  #|     return ""
  #|   }
  #|   if (/^F\\d{1,2}$/.test(key)) {
  #|     return ""
  #|   }
  #|   return key
  #| }

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
  #|     // Unwrap common wrapper shapes (defensive, for wasm reference objects).
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
  #|     // MoonBit wasm String is typically `array (mut i16)`.
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
extern "js" fn wgsl_extract_import_specs(source : String) -> Array[String] =
  #| (source) => {
  #|   const specs = []
  #|   const lines = String(source || "").split(/\r?\n/)
  #|   for (const lineRaw of lines) {
  #|     const line = String(lineRaw).trim()
  #|     if (!line.startsWith("#import ")) {
  #|       continue
  #|     }
  #|     const spec = line.slice("#import ".length).trim()
  #|     if (spec.length > 0) {
  #|       specs.push(spec)
  #|     }
  #|   }
  #|   return specs
  #| }

///|
extern "js" fn wgsl_import_spec_to_rel_path(spec : String) -> String =
  #| (specRaw) => {
  #|   let spec = String(specRaw || "").trim()
  #|   if (spec.length === 0) {
  #|     return ""
  #|   }
  #|   const asIndex = spec.indexOf(" as ")
  #|   if (asIndex >= 0) {
  #|     spec = spec.slice(0, asIndex).trim()
  #|   }
  #|   const braceIndex = spec.indexOf("::{")
  #|   if (braceIndex >= 0) {
  #|     spec = spec.slice(0, braceIndex).trim()
  #|   }
  #|   spec = spec.replace(/;+$/, "").trim()
  #|   if (spec.length === 0) {
  #|     return ""
  #|   }
  #|   const segs = spec.split("::")
  #|   if (segs.length === 0) {
  #|     return ""
  #|   }
  #|   const last = segs[segs.length - 1] || ""
  #|   if (/^[A-Z]/.test(last)) {
  #|     segs.pop()
  #|   }
  #|   if (segs.length === 0) {
  #|     return ""
  #|   }
  #|   return "shaders/bevy/" + segs.join("/") + ".wgsl"
  #| }

///|
extern "js" fn wgsl_import_spec_to_alias(specRaw : String) -> String =
  #| (specRaw) => {
  #|   let spec = String(specRaw || "").trim().replace(/;+$/, "")
  #|   if (spec.length === 0) {
  #|     return ""
  #|   }
  #|   const asMatch = /\s+as\s+([A-Za-z_][A-Za-z0-9_]*)\s*$/.exec(spec)
  #|   if (asMatch && asMatch[1]) {
  #|     return asMatch[1]
  #|   }
  #|   const braceIndex = spec.indexOf("::{")
  #|   if (braceIndex >= 0) {
  #|     spec = spec.slice(0, braceIndex).trim()
  #|   }
  #|   const segs = spec.split("::").filter((s) => s.length > 0)
  #|   if (segs.length === 0) {
  #|     return ""
  #|   }
  #|   return segs[segs.length - 1]
  #| }

///|
extern "js" fn wgsl_strip_module_aliases(
  source : String,
  aliases : Array[String],
) -> String =
  #| (source, aliases) => {
  #|   const text = String(source || "")
  #|   const list = Array.isArray(aliases) ? aliases : []
  #|   const dedup = Array.from(new Set(list.map((a) => String(a || "").trim()).filter((a) => /^[A-Za-z_][A-Za-z0-9_]*$/.test(a))))
  #|   if (dedup.length === 0) {
  #|     return text
  #|   }
  #|   const escapeRegExp = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
  #|   let out = text
  #|   for (const alias of dedup) {
  #|     const pattern = new RegExp("\\b" + escapeRegExp(alias) + "\\s*::\\s*", "g")
  #|     out = out.replace(pattern, "")
  #|   }
  #|   return out
  #| }

///|
extern "js" fn wgsl_strip_import_define_lines(source : String) -> String =
  #| (source) => {
  #|   const out = []
  #|   const lines = String(source || "").split(/\r?\n/)
  #|   for (const lineRaw of lines) {
  #|     const line = String(lineRaw)
  #|     const trimmed = line.trim()
  #|     if (trimmed.startsWith("#import ") || trimmed.startsWith("#define_import_path")) {
  #|       continue
  #|     }
  #|     out.push(line)
  #|   }
  #|   return out.join("\n")
  #| }

///|
extern "js" fn wgsl_apply_ifdefs(
  source : String,
  defines : Array[String],
) -> String =
  #| (source, defines) => {
  #|   const defineSet = new Set((defines || []).map((d) => String(d)))
  #|   const activeStack = [true]
  #|   const frameStack = []
  #|   const out = []
  #|   const lines = String(source || "").split(/\r?\n/)
  #|   for (const lineRaw of lines) {
  #|     const line = String(lineRaw)
  #|     const trimmed = line.trim()
  #|     if (trimmed.startsWith("#ifdef ")) {
  #|       const name = trimmed.slice("#ifdef ".length).trim()
  #|       const cond = defineSet.has(name)
  #|       const parent = activeStack[activeStack.length - 1]
  #|       activeStack.push(parent && cond)
  #|       frameStack.push({ parent, branchTaken: cond })
  #|       continue
  #|     }
  #|     if (trimmed.startsWith("#ifndef ")) {
  #|       const name = trimmed.slice("#ifndef ".length).trim()
  #|       const cond = !defineSet.has(name)
  #|       const parent = activeStack[activeStack.length - 1]
  #|       activeStack.push(parent && cond)
  #|       frameStack.push({ parent, branchTaken: cond })
  #|       continue
  #|     }
  #|     if (trimmed.startsWith("#else ifdef ")) {
  #|       if (frameStack.length > 0) {
  #|         const idx = frameStack.length - 1
  #|         const frame = frameStack[idx]
  #|         const name = trimmed.slice("#else ifdef ".length).trim()
  #|         const cond = !frame.branchTaken && defineSet.has(name)
  #|         activeStack[activeStack.length - 1] = frame.parent && cond
  #|         frame.branchTaken = frame.branchTaken || cond
  #|       }
  #|       continue
  #|     }
  #|     if (trimmed.startsWith("#else ifndef ")) {
  #|       if (frameStack.length > 0) {
  #|         const idx = frameStack.length - 1
  #|         const frame = frameStack[idx]
  #|         const name = trimmed.slice("#else ifndef ".length).trim()
  #|         const cond = !frame.branchTaken && !defineSet.has(name)
  #|         activeStack[activeStack.length - 1] = frame.parent && cond
  #|         frame.branchTaken = frame.branchTaken || cond
  #|       }
  #|       continue
  #|     }
  #|     if (trimmed === "#else") {
  #|       if (frameStack.length > 0) {
  #|         const idx = frameStack.length - 1
  #|         const frame = frameStack[idx]
  #|         const cond = !frame.branchTaken
  #|         activeStack[activeStack.length - 1] = frame.parent && cond
  #|         frame.branchTaken = frame.branchTaken || cond
  #|       }
  #|       continue
  #|     }
  #|     if (trimmed === "#endif") {
  #|       if (activeStack.length > 1) {
  #|         activeStack.pop()
  #|       }
  #|       if (frameStack.length > 0) {
  #|         frameStack.pop()
  #|       }
  #|       continue
  #|     }
  #|     if (activeStack[activeStack.length - 1]) {
  #|       out.push(line)
  #|     }
  #|   }
  #|   return out.join("\n")
  #| }

///|
/// WebGPU backend lowering for Bevy motion-blur WGSL:
/// Browsers currently reject some `textureSample` calls in non-uniform control
/// flow. Bevy's native `wgpu` path lowers these internally; this mirrors that
/// behavior on the web runtime while keeping source WGSL unchanged.
extern "js" fn wgsl_lower_motion_blur_texture_samples_for_webgpu(
  source : String,
) -> String =
  #| (source) => {
  #|   let out = String(source || "")
  #|   const replacements = [
  #|     [
  #|       /\btextureSample\s*\(\s*screen_texture\s*,\s*texture_sampler\s*,\s*in\.uv\s*\)/g,
  #|       "textureSampleLevel(screen_texture, texture_sampler, in.uv, 0.0)",
  #|     ],
  #|     [
  #|       /\btextureSample\s*\(\s*motion_vectors\s*,\s*texture_sampler\s*,\s*in\.uv\s*\)\s*\.rg/g,
  #|       "textureSampleLevel(motion_vectors, texture_sampler, in.uv, 0.0).rg",
  #|     ],
  #|     [
  #|       /\btextureSample\s*\(\s*depth\s*,\s*texture_sampler\s*,\s*in\.uv\s*\)/g,
  #|       "textureLoad(depth, frag_coords, 0)",
  #|     ],
  #|     [
  #|       /\btextureSample\s*\(\s*screen_texture\s*,\s*texture_sampler\s*,\s*sample_uv\s*\)/g,
  #|       "textureSampleLevel(screen_texture, texture_sampler, sample_uv, 0.0)",
  #|     ],
  #|     [
  #|       /\btextureSample\s*\(\s*motion_vectors\s*,\s*texture_sampler\s*,\s*sample_uv\s*\)\s*\.rg/g,
  #|       "textureSampleLevel(motion_vectors, texture_sampler, sample_uv, 0.0).rg",
  #|     ],
  #|     [
  #|       /\btextureSample\s*\(\s*depth\s*,\s*texture_sampler\s*,\s*sample_uv\s*\)/g,
  #|       "textureLoad(depth, sample_coords, 0)",
  #|     ],
  #|   ]
  #|   for (const [pattern, replacement] of replacements) {
  #|     out = out.replace(pattern, replacement)
  #|   }
  #|   return out
  #| }

///|
extern "js" fn poll_gamepads_snapshot_js() -> @js.Any =
  #| () => {
  #|   const nav = typeof navigator === "object" && navigator ? navigator : null
  #|   if (!nav || typeof nav.getGamepads !== "function") {
  #|     return []
  #|   }
  #|   let pads = []
  #|   try {
  #|     pads = nav.getGamepads() || []
  #|   } catch {
  #|     pads = []
  #|   }
  #|   const out = []
  #|   for (let i = 0; i < pads.length; i += 1) {
  #|     const gp = pads[i]
  #|     if (!gp || gp.connected === false) {
  #|       continue
  #|     }
  #|     const idText = String(gp.id || "")
  #|     const idMatch = /^([0-9a-fA-F]{4})-([0-9a-fA-F]{4})/.exec(idText)
  #|     const vendorId = idMatch ? parseInt(idMatch[1], 16) : -1
  #|     const productId = idMatch ? parseInt(idMatch[2], 16) : -1
  #|     const buttonValues = []
  #|     const buttonPressed = []
  #|     const buttons = gp.buttons || []
  #|     for (let b = 0; b < buttons.length; b += 1) {
  #|       const bt = buttons[b]
  #|       buttonValues.push(Number(bt && bt.value != null ? bt.value : NaN))
  #|       buttonPressed.push(!!(bt && bt.pressed))
  #|     }
  #|     const axisValues = []
  #|     const axes = gp.axes || []
  #|     for (let a = 0; a < axes.length; a += 1) {
  #|       axisValues.push(Number(axes[a]))
  #|     }
  #|     out.push({
  #|       id: Number(gp.index) | 0,
  #|       name: idText,
  #|       vendor_id: Number.isFinite(vendorId) ? (vendorId | 0) : -1,
  #|       product_id: Number.isFinite(productId) ? (productId | 0) : -1,
  #|       button_values: buttonValues,
  #|       button_pressed: buttonPressed,
  #|       axis_values: axisValues,
  #|     })
  #|   }
  #|   return out
  #| }

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
extern "js" fn array_len(arr : @js.Any) -> Int =
  #| (arr) => {
  #|   if (!arr || typeof arr.length !== "number") {
  #|     return 0
  #|   }
  #|   return Number(arr.length) | 0
  #| }

///|
extern "js" fn array_get(arr : @js.Any, index : Int) -> @js.Any =
  #| (arr, index) => {
  #|   const i = Number(index) | 0
  #|   if (!arr || i < 0 || i >= arr.length) {
  #|     return null
  #|   }
  #|   return arr[i]
  #| }

///|
extern "js" fn map_set(map : @js.Any, key : @js.Any, value : @js.Any) -> Unit =
  #| (map, key, value) => map.set(key, value)

///|
extern "js" fn map_get(map : @js.Any, key : @js.Any) -> @js.Any =
  #| (map, key) => map.get(key)

///|
extern "js" fn map_delete(map : @js.Any, key : @js.Any) -> Bool =
  #| (map, key) => map.delete(key)

///|
extern "js" fn map_values(map : @js.Any) -> @js.Any =
  #| (map) => Array.from(map.values())

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
extern "js" fn a11y_actions_len_js() -> Int =
  #| () => {
  #|   const arr = globalThis.__mgstudio_a11y_actions || []
  #|   return arr.length | 0
  #| }

///|
extern "js" fn a11y_actions_target_js(index : Int) -> Int =
  #| (index) => {
  #|   const i = Number(index) | 0
  #|   const arr = globalThis.__mgstudio_a11y_actions || []
  #|   const it = arr[i]
  #|   return it ? (Number(it[0]) | 0) : 0
  #| }

///|
extern "js" fn a11y_actions_kind_js(index : Int) -> Int =
  #| (index) => {
  #|   const i = Number(index) | 0
  #|   const arr = globalThis.__mgstudio_a11y_actions || []
  #|   const it = arr[i]
  #|   return it ? (Number(it[1]) | 0) : 0
  #| }

///|
extern "js" fn a11y_actions_value_len_js(index : Int) -> Int =
  #| (index) => {
  #|   const i = Number(index) | 0
  #|   const arr = globalThis.__mgstudio_a11y_actions || []
  #|   const it = arr[i]
  #|   const value = it && it.length > 2 ? String(it[2] ?? "") : ""
  #|   return value.length | 0
  #| }

///|
extern "js" fn a11y_actions_value_code_unit_js(
  index : Int,
  offset : Int,
) -> Int =
  #| (index, offset) => {
  #|   const i = Number(index) | 0
  #|   const j = Number(offset) | 0
  #|   const arr = globalThis.__mgstudio_a11y_actions || []
  #|   const it = arr[i]
  #|   const value = it && it.length > 2 ? String(it[2] ?? "") : ""
  #|   if (j < 0 || j >= value.length) return 0
  #|   return value.charCodeAt(j) | 0
  #| }

///|
extern "js" fn a11y_actions_clear_js() -> Unit =
  #| () => { globalThis.__mgstudio_a11y_actions = [] }

///|
/// Ensure (and position) the a11y DOM overlay above the canvas.
extern "js" fn a11y_begin_update_js(canvas : @js.Any, root_id : Int) -> @js.Any =
  #| (canvas, rootId) => {
  #|   if (!canvas || typeof document !== "object") return null
  #|   let container = globalThis.__mgstudio_a11y_container
  #|   if (!container) {
  #|     container = document.createElement("div")
  #|     container.id = "mgstudio-a11y"
  #|     container.style.position = "absolute"
  #|     // Keep the root as a structural container only. Interactive hit areas
  #|     // are on child nodes; setting width/height to 0 avoids swallowing
  #|     // canvas input while keeping absolute children targetable.
  #|     container.style.pointerEvents = "auto"
  #|     container.style.overflow = "visible"
  #|     container.style.opacity = "1"
  #|     container.style.zIndex = "2147483647"
  #|     document.body.appendChild(container)
  #|     globalThis.__mgstudio_a11y_container = container
  #|   }
  #|   const rect = canvas.getBoundingClientRect()
  #|   const left = rect.left + (window.scrollX || 0)
  #|   const top = rect.top + (window.scrollY || 0)
  #|   container.style.left = `${left}px`
  #|   container.style.top = `${top}px`
  #|   container.style.width = `0px`
  #|   container.style.height = `0px`
  #|   const rid = Number(rootId) | 0
  #|   if (rid) globalThis.__mgstudio_a11y_root_id = rid
  #|   // Persistent node lookup across frames (to preserve focus).
  #|   if (!globalThis.__mgstudio_a11y_nodes) {
  #|     globalThis.__mgstudio_a11y_nodes = new Map()
  #|   }
  #|   // Per-frame bookkeeping.
  #|   globalThis.__mgstudio_a11y_frame_seen = new Set()
  #|   globalThis.__mgstudio_a11y_frame_order = []
  #|   return container
  #| }

///|
/// Add one accessible element to the overlay.
extern "js" fn a11y_push_node_js(
  container : @js.Any,
  node_id : Int,
  parent_id : Int,
  role_id : Int,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  label : String,
  value : String,
  actions_mask : Int,
) -> Unit =
  #| (container, nodeId, parentId, roleId, x, y, w, h, label, value, actionsMask) => {
  #|   if (!container) return
  #|   const id = Number(nodeId) | 0
  #|   const pid = Number(parentId) | 0
  #|   const role = Number(roleId) | 0
  #|   const mask = Number(actionsMask) | 0
  #|   const labelText = String(label || "")
  #|   const valueText = String(value || "")
  #|   const MASK_FOCUS = 1
  #|   const MASK_DEFAULT = 2
  #|   const MASK_SCROLL = 4
  #|   const MASK_SET_VALUE = 8
  #|   const ACTION_FOCUS = 1
  #|   const ACTION_DEFAULT = 2
  #|   const ACTION_SCROLL_UP = 3
  #|   const ACTION_SCROLL_DOWN = 4
  #|   const ACTION_SCROLL_LEFT = 5
  #|   const ACTION_SCROLL_RIGHT = 6
  #|   const ACTION_SET_VALUE = 7
  #|   const nodes = globalThis.__mgstudio_a11y_nodes
  #|   const seen = globalThis.__mgstudio_a11y_frame_seen
  #|   const order = globalThis.__mgstudio_a11y_frame_order
  #|   if (order && Array.isArray(order)) order.push(id)
  #|   if (seen && typeof seen.add === "function") seen.add(id)
  #|   const tag = (mask & MASK_SET_VALUE) !== 0 ? "input" : ((role === 3) ? "button" : "div")
  #|   let el = nodes && typeof nodes.get === "function" ? nodes.get(id) : null
  #|   if (!el || String(el.tagName || "").toLowerCase() !== tag) {
  #|     const next = document.createElement(tag)
  #|     if (el && el.parentNode) {
  #|       el.parentNode.replaceChild(next, el)
  #|     }
  #|     el = next
  #|     if (nodes && typeof nodes.set === "function") {
  #|       nodes.set(id, el)
  #|     }
  #|     // Init-once styles and listeners.
  #|   el.style.position = "absolute"
  #|     el.style.opacity = "0"
  #|   el.style.background = "transparent"
  #|   el.style.border = "0"
  #|   el.style.padding = "0"
  #|   el.style.margin = "0"
  #|   el.style.color = "transparent"
  #|     if (tag === "button") {
  #|       // Avoid implicit "submit" semantics when the overlay lives inside a form.
  #|       el.type = "button"
  #|     } else if (tag === "input") {
  #|       el.type = "text"
  #|       el.autocomplete = "off"
  #|       el.spellcheck = false
  #|     }
  #|     el.addEventListener("focus", () => {
  #|       const m = Number(el.dataset && el.dataset.mgstudioActionsMask) | 0
  #|       if ((m & MASK_FOCUS) === 0) return
  #|       globalThis.__mgstudio_a11y_actions = (globalThis.__mgstudio_a11y_actions || [])
  #|       globalThis.__mgstudio_a11y_actions.push([id, ACTION_FOCUS])
  #|     })
  #|     el.addEventListener("click", () => {
  #|       const m = Number(el.dataset && el.dataset.mgstudioActionsMask) | 0
  #|       if ((m & MASK_DEFAULT) === 0) return
  #|       globalThis.__mgstudio_a11y_actions = (globalThis.__mgstudio_a11y_actions || [])
  #|       globalThis.__mgstudio_a11y_actions.push([id, ACTION_DEFAULT])
  #|     })
  #|     el.addEventListener("keydown", (ev) => {
  #|       const m = Number(el.dataset && el.dataset.mgstudioActionsMask) | 0
  #|       const key = ev && ev.key
  #|       if ((m & MASK_DEFAULT) !== 0 && (key === "Enter" || key === " ")) {
  #|         ev.preventDefault()
  #|         globalThis.__mgstudio_a11y_actions = (globalThis.__mgstudio_a11y_actions || [])
  #|         globalThis.__mgstudio_a11y_actions.push([id, ACTION_DEFAULT])
  #|         return
  #|       }
  #|       if ((m & MASK_SCROLL) !== 0) {
  #|         let k = 0
  #|         if (key === "ArrowUp" || key === "PageUp") k = ACTION_SCROLL_UP
  #|         else if (key === "ArrowDown" || key === "PageDown") k = ACTION_SCROLL_DOWN
  #|         else if (key === "ArrowLeft") k = ACTION_SCROLL_LEFT
  #|         else if (key === "ArrowRight") k = ACTION_SCROLL_RIGHT
  #|         if (k !== 0) {
  #|           ev.preventDefault()
  #|           globalThis.__mgstudio_a11y_actions = (globalThis.__mgstudio_a11y_actions || [])
  #|           globalThis.__mgstudio_a11y_actions.push([id, k])
  #|         }
  #|       }
  #|     })
  #|     el.addEventListener("wheel", (ev) => {
  #|       const m = Number(el.dataset && el.dataset.mgstudioActionsMask) | 0
  #|       if ((m & MASK_SCROLL) === 0) return
  #|       const dx = Number(ev && ev.deltaX) || 0
  #|       const dy = Number(ev && ev.deltaY) || 0
  #|       let k = 0
  #|       if (Math.abs(dy) >= Math.abs(dx)) {
  #|         k = dy >= 0 ? ACTION_SCROLL_DOWN : ACTION_SCROLL_UP
  #|       } else {
  #|         k = dx >= 0 ? ACTION_SCROLL_RIGHT : ACTION_SCROLL_LEFT
  #|       }
  #|       if (k !== 0) {
  #|         ev.preventDefault()
  #|         globalThis.__mgstudio_a11y_actions = (globalThis.__mgstudio_a11y_actions || [])
  #|         globalThis.__mgstudio_a11y_actions.push([id, k])
  #|       }
  #|     }, { passive: false })
  #|     el.addEventListener("input", () => {
  #|       const m = Number(el.dataset && el.dataset.mgstudioActionsMask) | 0
  #|       if ((m & MASK_SET_VALUE) === 0) return
  #|       globalThis.__mgstudio_a11y_actions = (globalThis.__mgstudio_a11y_actions || [])
  #|       globalThis.__mgstudio_a11y_actions.push([id, ACTION_SET_VALUE, String(el.value || "")])
  #|     })
  #|     el.addEventListener("change", () => {
  #|       const m = Number(el.dataset && el.dataset.mgstudioActionsMask) | 0
  #|       if ((m & MASK_SET_VALUE) === 0) return
  #|       globalThis.__mgstudio_a11y_actions = (globalThis.__mgstudio_a11y_actions || [])
  #|       globalThis.__mgstudio_a11y_actions.push([id, ACTION_SET_VALUE, String(el.value || "")])
  #|     })
  #|     if ((mask & MASK_SET_VALUE) !== 0) {
  #|       el.addEventListener("blur", () => {
  #|         const m = Number(el.dataset && el.dataset.mgstudioActionsMask) | 0
  #|         if ((m & MASK_SET_VALUE) === 0) return
  #|         globalThis.__mgstudio_a11y_actions = (globalThis.__mgstudio_a11y_actions || [])
  #|         globalThis.__mgstudio_a11y_actions.push([id, ACTION_SET_VALUE, String(el.value || "")])
  #|       })
  #|     }
  #|     container.appendChild(el)
  #|   }
  #|   // Per-frame dynamic styles / attributes.
  #|   // Keep nodes visually hidden every frame (important across hot reloads /
  #|   // reused DOM nodes), while still focusable for accessibility actions.
  #|   el.style.position = "absolute"
  #|   el.style.opacity = "0"
  #|   el.style.background = "transparent"
  #|   el.style.border = "0"
  #|   el.style.padding = "0"
  #|   el.style.margin = "0"
  #|   el.style.color = "transparent"
  #|   el.style.textShadow = "none"
  #|   el.style.caretColor = "transparent"
  #|   el.style.fontSize = "0px"
  #|   el.style.lineHeight = "0"
  #|   if (tag === "input" && (mask & MASK_SET_VALUE) !== 0) {
  #|     const focused = typeof document === "object" && document.activeElement === el
  #|     if (!focused && String(el.value || "") !== valueText) {
  #|       el.value = valueText
  #|       }
  #|   }
  #|   el.style.left = `${Number(x)}px`
  #|   el.style.top = `${Number(y)}px`
  #|   el.style.width = `${Math.max(0, Number(w))}px`
  #|   el.style.height = `${Math.max(0, Number(h))}px`
  #|   el.style.pointerEvents = mask !== 0 ? "auto" : "none"
  #|   el.dataset.mgstudioNodeId = String(id)
  #|   el.dataset.mgstudioParentId = String(pid)
  #|   el.dataset.mgstudioRoleId = String(role)
  #|   el.dataset.mgstudioActionsMask = String(mask)
  #|   // ARIA roles (rough mapping to host role ids).
  #|   const ariaRole =
  #|     (role === 1) ? "application" :
  #|     (role === 2) ? "group" :
  #|     (role === 4) ? "text" :
  #|     (role === 5) ? "img" :
  #|     null
  #|   if (tag !== "button") {
  #|     if (ariaRole) el.setAttribute("role", ariaRole)
  #|     else el.removeAttribute("role")
  #|   }
  #|   const accessibleName = labelText !== "" ? labelText : valueText
  #|   if (accessibleName !== "") {
  #|     el.setAttribute("aria-label", accessibleName)
  #|   } else {
  #|     el.removeAttribute("aria-label")
  #|   }
  #|   // Keep overlay nodes non-visual; accessibility comes from ARIA attrs
  #|   // and input value, not from rendered DOM text.
  #|   el.textContent = ""
  #|   // Focusable when it has any actions.
  #|   el.tabIndex = mask !== 0 ? 0 : -1
  #| }

///|
/// Finalize a11y overlay update: reparent and prune nodes while preserving focus.
extern "js" fn a11y_end_update_js(container : @js.Any) -> Unit =
  #| (container) => {
  #|   if (!container) return
  #|   const nodes = globalThis.__mgstudio_a11y_nodes
  #|   const seen = globalThis.__mgstudio_a11y_frame_seen
  #|   const order = globalThis.__mgstudio_a11y_frame_order || []
  #|   if (!nodes || typeof nodes.forEach !== "function") return
  #|   // Prune unseen nodes (remove from DOM and map).
  #|   nodes.forEach((el, id) => {
  #|     if (!seen || !seen.has(id)) {
  #|       try { if (el && el.parentNode) el.parentNode.removeChild(el) } catch {}
  #|       try { nodes.delete(id) } catch {}
  #|     }
  #|   })
  #|   // Rebuild parent->children lists in the order nodes were pushed this frame.
  #|   const childrenByParent = new Map()
  #|   for (let i = 0; i < order.length; i += 1) {
  #|     const id = Number(order[i]) | 0
  #|     const el = nodes.get(id)
  #|     if (!el) continue
  #|     const pid = Number(el.dataset && el.dataset.mgstudioParentId) | 0
  #|     let arr = childrenByParent.get(pid)
  #|     if (!arr) { arr = []; childrenByParent.set(pid, arr) }
  #|     arr.push(el)
  #|   }
  #|   childrenByParent.forEach((children, pid) => {
  #|     const parentEl = nodes.get(pid) || container
  #|     for (let i = 0; i < children.length; i += 1) {
  #|       parentEl.appendChild(children[i])
  #|     }
  #|   })
  #| }

///|
extern "js" fn a11y_focus_node_js(node_id : Int) -> Unit =
  #| (nodeId) => {
  #|   const nodes = globalThis.__mgstudio_a11y_nodes
  #|   if (!nodes || typeof nodes.get !== "function") return
  #|   const id = Number(nodeId) | 0
  #|   const el = nodes.get(id)
  #|   if (!el || typeof el.focus !== "function") return
  #|   try {
  #|     el.focus({ preventScroll: true })
  #|   } catch (_) {
  #|     try { el.focus() } catch (_) {}
  #|   }
  #| }

///|
extern "js" fn create_solid_rgba_data(
  width : Int,
  height : Int,
  r : Int,
  g : Int,
  b : Int,
  a : Int,
) -> @js.Any =
  #| (width, height, r, g, b, a) => {
  #|   const w = Math.max(1, Number(width) | 0)
  #|   const h = Math.max(1, Number(height) | 0)
  #|   const rr = Number(r) | 0
  #|   const gg = Number(g) | 0
  #|   const bb = Number(b) | 0
  #|   const aa = Number(a) | 0
  #|   const data = new Uint8Array(w * h * 4)
  #|   for (let i = 0; i < data.length; i += 4) {
  #|     data[i] = rr
  #|     data[i + 1] = gg
  #|     data[i + 2] = bb
  #|     data[i + 3] = aa
  #|   }
  #|   return data
  #| }

///|
extern "js" fn create_zero_rgba_data(width : Int, height : Int) -> @js.Any =
  #| (width, height) => {
  #|   const w = Math.max(1, Number(width) | 0)
  #|   const h = Math.max(1, Number(height) | 0)
  #|   return new Uint8Array(w * h * 4)
  #| }

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
  #|   const pushVertex = (arr, x, y, u, v) => {
  #|     arr.push(x, y, u, v, 1, 1, 1, 1)
  #|   }
  #|   const data = []
  #|   pushVertex(data, -halfW, -halfH, 0, 0)
  #|   pushVertex(data, halfW, -halfH, 1, 0)
  #|   pushVertex(data, halfW, halfH, 1, 1)
  #|   pushVertex(data, -halfW, -halfH, 0, 0)
  #|   pushVertex(data, halfW, halfH, 1, 1)
  #|   pushVertex(data, -halfW, halfH, 0, 1)
  #|   return new Float32Array(data)
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
  #|   const minX = -r
  #|   const maxX = r
  #|   const minY = -(half + r)
  #|   const maxY = half + r
  #|   const invW = 1 / Math.max(1e-6, maxX - minX)
  #|   const invH = 1 / Math.max(1e-6, maxY - minY)
  #|   const pushVertex = (x, y) => {
  #|     vertexData.push(
  #|       x,
  #|       y,
  #|       (x - minX) * invW,
  #|       (y - minY) * invH,
  #|       1,
  #|       1,
  #|       1,
  #|       1,
  #|     )
  #|   }
  #|   const cx = 0
  #|   const cy = 0
  #|   const count = points.length
  #|   for (let i = 0; i < count; i += 1) {
  #|     const p0 = points[i]
  #|     const p1 = points[(i + 1) % count]
  #|     pushVertex(cx, cy)
  #|     pushVertex(p0[0], p0[1])
  #|     pushVertex(p1[0], p1[1])
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
extern "js" fn motion_blur_settings_uniform_bytes(
  shutter_angle : Double,
  samples : Int,
) -> @js.Any =
  #| (shutterAngle, samples) => {
  #|   const clamped = Math.max(0, Math.min(64, Number(samples) | 0)) >>> 0
  #|   const buf = new ArrayBuffer(16)
  #|   const view = new DataView(buf)
  #|   view.setFloat32(0, Number(shutterAngle) || 0, true)
  #|   view.setUint32(4, clamped, true)
  #|   view.setUint32(8, 0, true)
  #|   view.setUint32(12, 0, true)
  #|   return new Uint8Array(buf)
  #| }

///|
extern "js" fn motion_blur_globals_uniform_bytes(frame_count : Int) -> @js.Any =
  #| (frameCount) => {
  #|   const frame = Number(frameCount) >>> 0
  #|   const buf = new ArrayBuffer(16)
  #|   const view = new DataView(buf)
  #|   view.setFloat32(0, 0, true)
  #|   view.setFloat32(4, 0, true)
  #|   view.setUint32(8, frame, true)
  #|   view.setUint32(12, 0, true)
  #|   return new Uint8Array(buf)
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
extern "js" fn math_atan2(y : Double, x : Double) -> Double =
  #| (y, x) => Math.atan2(y, x)

///|
extern "js" fn math_pow(base : Double, exponent : Double) -> Double =
  #| (base, exponent) => Math.pow(base, exponent)

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
extern "js" fn copy_texture_to_texture_region(
  device : @js.Any,
  queue : @js.Any,
  src_texture : @js.Any,
  dst_texture : @js.Any,
  width : Int,
  height : Int,
  x : Int,
  y : Int,
) -> Unit =
  #| (device, queue, srcTexture, dstTexture, width, height, x, y) => {
  #|   const encoder = device.createCommandEncoder()
  #|   encoder.copyTextureToTexture(
  #|     { texture: srcTexture },
  #|     { texture: dstTexture, origin: { x, y } },
  #|     [width, height, 1],
  #|   )
  #|   queue.submit([encoder.finish()])
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
extern "js" fn write_texture_mip(
  queue : @js.Any,
  texture : @js.Any,
  data : @js.Any,
  bytes_per_row : Int,
  rows_per_image : Int,
  width : Int,
  height : Int,
  mip_level : Int,
) -> Unit =
  #| (queue, texture, data, bytesPerRow, rowsPerImage, width, height, mipLevel) => {
  #|   queue.writeTexture(
  #|     { texture, mipLevel },
  #|     data,
  #|     { bytesPerRow, rowsPerImage },
  #|     [width, height, 1],
  #|   )
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
extern "js" fn is_ktx2_uint8array(data : @js.Any) -> Bool =
  #| (data) => {
  #|   if (!(data instanceof Uint8Array) || data.length < 12) {
  #|     return false
  #|   }
  #|   return (
  #|     data[0] === 0xab &&
  #|     data[1] === 0x4b &&
  #|     data[2] === 0x54 &&
  #|     data[3] === 0x58 &&
  #|     data[4] === 0x20 &&
  #|     data[5] === 0x32 &&
  #|     data[6] === 0x30 &&
  #|     data[7] === 0xbb &&
  #|     data[8] === 0x0d &&
  #|     data[9] === 0x0a &&
  #|     data[10] === 0x1a &&
  #|     data[11] === 0x0a
  #|   )
  #| }

///|
extern "js" fn parse_ktx2_stacked_upload(
  data : @js.Any,
) -> @js.Promise[@js.Any] =
  #| async (data) => {
  #|   if (!(data instanceof Uint8Array) || data.length < 80) {
  #|     return null
  #|   }
  #|   const u8 = data
  #|   const dv = new DataView(u8.buffer, u8.byteOffset, u8.byteLength)
  #|   const readU32 = (off) => {
  #|     if (off < 0 || off + 4 > u8.length) return null
  #|     return dv.getUint32(off, true)
  #|   }
  #|   const readU64AsInt = (off) => {
  #|     if (off < 0 || off + 8 > u8.length) return null
  #|     const lo = dv.getUint32(off, true)
  #|     const hi = dv.getUint32(off + 4, true)
  #|     if (hi !== 0) return null
  #|     return lo
  #|   }
  #|   const vkFormat = readU32(12)
  #|   const pixelWidth = readU32(20)
  #|   const pixelHeight = readU32(24)
  #|   const pixelDepth = readU32(28)
  #|   const layerCount = readU32(32)
  #|   const faceCount = readU32(36)
  #|   const levelCountRaw = readU32(40)
  #|   const supercompression = readU32(44)
  #|   if (
  #|     vkFormat == null ||
  #|     pixelWidth == null ||
  #|     pixelHeight == null ||
  #|     pixelDepth == null ||
  #|     layerCount == null ||
  #|     faceCount == null ||
  #|     levelCountRaw == null ||
  #|     supercompression == null
  #|   ) {
  #|     return null
  #|   }
  #|   const formatInfo = (() => {
  #|     switch (vkFormat) {
  #|       case 97:
  #|         return { format: "rgba16float", blockWidth: 1, blockHeight: 1, blockBytes: 8 }
  #|       case 123:
  #|         return { format: "rgb9e5ufloat", blockWidth: 1, blockHeight: 1, blockBytes: 4 }
  #|       case 146:
  #|         return { format: "bc7-rgba-unorm", blockWidth: 4, blockHeight: 4, blockBytes: 16 }
  #|       case 148:
  #|         return { format: "etc2-rgba8unorm", blockWidth: 4, blockHeight: 4, blockBytes: 16 }
  #|       case 158:
  #|         return { format: "astc-4x4-unorm", blockWidth: 4, blockHeight: 4, blockBytes: 16 }
  #|       default:
  #|         return null
  #|     }
  #|   })()
  #|   if (!formatInfo) {
  #|     return null
  #|   }
  #|   const width = Math.max(1, pixelWidth | 0)
  #|   const heightPerSlice = Math.max(1, pixelHeight | 0)
  #|   const depth = Math.max(1, pixelDepth | 0)
  #|   const layers = Math.max(1, layerCount | 0)
  #|   const faces = Math.max(1, faceCount | 0)
  #|   const sliceCount = layers * faces * depth
  #|   if (!Number.isFinite(sliceCount) || sliceCount <= 0) {
  #|     return null
  #|   }
  #|   let levelCount = levelCountRaw | 0
  #|   if (levelCount <= 0) {
  #|     levelCount = 1
  #|   }
  #|   const levelIndices = []
  #|   let offset = 80
  #|   for (let i = 0; i < levelCount; i += 1) {
  #|     const byteOffset = readU64AsInt(offset)
  #|     const byteLength = readU64AsInt(offset + 8)
  #|     const uncompressedByteLength = readU64AsInt(offset + 16)
  #|     if (
  #|       byteOffset == null ||
  #|       byteLength == null ||
  #|       uncompressedByteLength == null
  #|     ) {
  #|       return null
  #|     }
  #|     levelIndices.push({ byteOffset, byteLength, uncompressedByteLength })
  #|     offset += 24
  #|   }
  #|
  #|   const ceilDiv = (v, d) => Math.floor((v + d - 1) / d)
  #|   const levelLayout = (mipWidth, mipHeight) => {
  #|     const blocksW = Math.max(1, ceilDiv(mipWidth, formatInfo.blockWidth))
  #|     const blocksH = Math.max(1, ceilDiv(mipHeight, formatInfo.blockHeight))
  #|     const bytesPerRow = blocksW * formatInfo.blockBytes
  #|     const rowsPerImage = blocksH
  #|     const expectedBytes = bytesPerRow * rowsPerImage
  #|     if (bytesPerRow <= 0 || rowsPerImage <= 0 || expectedBytes <= 0) {
  #|       return null
  #|     }
  #|     return { bytesPerRow, rowsPerImage, expectedBytes }
  #|   }
  #|   const decodeZstd = async (compressed, expectedSize) => {
  #|     if (typeof DecompressionStream !== "function") {
  #|       return null
  #|     }
  #|     try {
  #|       const ds = new DecompressionStream("zstd")
  #|       const stream = new Blob([compressed]).stream().pipeThrough(ds)
  #|       const out = new Uint8Array(await new Response(stream).arrayBuffer())
  #|       if (expectedSize > 0 && out.length !== expectedSize) {
  #|         return null
  #|       }
  #|       return out
  #|     } catch (_) {
  #|       return null
  #|     }
  #|   }
  #|
  #|   const widths = []
  #|   const heights = []
  #|   const bytesPerRows = []
  #|   const rowsPerImages = []
  #|   const levels = []
  #|
  #|   for (let mip = 0; mip < levelIndices.length; mip += 1) {
  #|     const mipWidth = Math.max(1, width >> mip)
  #|     const mipHeightPerSlice = Math.max(1, heightPerSlice >> mip)
  #|     const mipDepth = Math.max(1, depth >> mip)
  #|     const mipSliceCount = layers * faces * mipDepth
  #|     if (levelIndices.length > 1 && mipSliceCount !== sliceCount) {
  #|       return null
  #|     }
  #|     const mipHeight = mipHeightPerSlice * sliceCount
  #|     const layout = levelLayout(mipWidth, mipHeight)
  #|     if (!layout) {
  #|       return null
  #|     }
  #|     const level = levelIndices[mip]
  #|     const start = level.byteOffset | 0
  #|     const end = start + (level.byteLength | 0)
  #|     if (start < 0 || end < start || end > u8.length) {
  #|       return null
  #|     }
  #|     const levelBytes = u8.subarray(start, end)
  #|     let decoded = null
  #|     if (supercompression === 0) {
  #|       decoded = levelBytes
  #|     } else if (supercompression === 2) {
  #|       const expectedUncompressed = level.uncompressedByteLength > 0
  #|         ? level.uncompressedByteLength
  #|         : layout.expectedBytes
  #|       decoded = await decodeZstd(levelBytes, expectedUncompressed)
  #|     } else {
  #|       return null
  #|     }
  #|     if (!(decoded instanceof Uint8Array) || decoded.length < layout.expectedBytes) {
  #|       return null
  #|     }
  #|     levels.push(decoded.slice(0, layout.expectedBytes))
  #|     widths.push(mipWidth)
  #|     heights.push(mipHeight)
  #|     bytesPerRows.push(layout.bytesPerRow)
  #|     rowsPerImages.push(layout.rowsPerImage)
  #|   }
  #|
  #|   return {
  #|     width,
  #|     heightPerSlice,
  #|     sliceCount,
  #|     format: formatInfo.format,
  #|     levels,
  #|     widths,
  #|     heights,
  #|     bytesPerRows,
  #|     rowsPerImages,
  #|   }
  #| }

///|
extern "js" fn create_image_bitmap(blob : @js.Any) -> @js.Promise[@js.Any] =
  #| (blob) => createImageBitmap(blob, { premultiplyAlpha: "none", colorSpaceConversion: "none" })

///|
extern "js" fn blob_from_uint8array(data : @js.Any) -> @js.Any =
  #| (data) => new Blob([data])

///|
extern "js" fn response_array_buffer(
  response : @js.Any,
) -> @js.Promise[@arraybuffer.ArrayBuffer] =
  #| (response) => response.arrayBuffer()

///|
extern "js" fn response_text(response : @js.Any) -> @js.Promise[String] =
  #| (response) => response.text()

///|
extern "js" fn uint8array_from_array_buffer(
  buf : @arraybuffer.ArrayBuffer,
) -> @js.Any =
  #| (buf) => new Uint8Array(buf)

///|
extern "js" fn uint8array_get_u8(arr : @js.Any, index : Int) -> Int =
  #| (arr, index) => {
  #|   const i = Number(index) | 0
  #|   if (!arr || i < 0 || i >= arr.length) return 0
  #|   return Number(arr[i]) & 0xff
  #| }

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
extern "js" fn measure_glyph_advance(
  family : String,
  font_size : Double,
  codepoint : Int,
) -> Double =
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
  #|   return (family, fontSize, codepoint) => {
  #|     const context = ensure()
  #|     if (!context) {
  #|       return 0
  #|     }
  #|     const size = Math.max(1, Number(fontSize) || 16)
  #|     const text = String.fromCodePoint(Number(codepoint) || 0)
  #|     const fontFamily = family && family.length ? family : "sans-serif"
  #|     const font = `${size}px "${fontFamily}"`
  #|     context.font = font
  #|     const metrics = context.measureText(text)
  #|     const width = Number(metrics.width) || 0
  #|     return width > 0 ? width : 0
  #|   }
  #| })()

///|
