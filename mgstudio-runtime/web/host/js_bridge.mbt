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
extern "js" fn window_prompt_line(message : String) -> @js.Any =
  #| (message) => {
  #|   if (typeof window === "undefined" || typeof window.prompt !== "function") {
  #|     return null
  #|   }
  #|   return window.prompt(message)
  #| }

///|
extern "js" fn download_canvas_png(canvas : @js.Any, filename : String) -> Unit =
  #| (canvas, filename) => {
  #|   if (!canvas || typeof canvas.toDataURL !== "function") {
  #|     return
  #|   }
  #|   const dataUrl = canvas.toDataURL("image/png")
  #|   const a = document.createElement("a")
  #|   a.href = dataUrl
  #|   a.download = filename || "screenshot.png"
  #|   document.body.appendChild(a)
  #|   a.click()
  #|   document.body.removeChild(a)
  #| }

///|
extern "js" fn add_event_listener(
  target : @js.Any,
  event_name : String,
  handler : @js.Any,
) -> Unit =
  #| (target, eventName, handler) => {
  #|   if (!target || typeof target.addEventListener !== "function") return
  #|   if (eventName === "wheel" || eventName === "touchstart" || eventName === "touchmove") {
  #|     target.addEventListener(eventName, handler, { passive: false })
  #|     return
  #|   }
  #|   target.addEventListener(eventName, handler)
  #| }

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
  #|   const responsive =
  #|     canvas.dataset &&
  #|     String(canvas.dataset.mgstudioSizeMode || "").toLowerCase() === "responsive"
  #|   if (canvas.style && !responsive) {
  #|     const cssW = Math.max(1, Math.round(pw / Math.max(1e-6, dpr)))
  #|     const cssH = Math.max(1, Math.round(ph / Math.max(1e-6, dpr)))
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
extern "js" fn set_canvas_cursor_icon_js(canvas : @js.Any, icon : Int) -> Unit =
  #| (canvas, icon) => {
  #|   if (!canvas || !canvas.style) return
  #|   const i = Number(icon) | 0
  #|   if (i === 1) {
  #|     canvas.style.cursor = "ew-resize"
  #|   } else {
  #|     canvas.style.cursor = ""
  #|   }
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
extern "js" fn prepare_canvas_for_input(canvas : @js.Any) -> Unit =
  #| (canvas) => {
  #|   if (!canvas || typeof canvas !== "object") return
  #|   if (!canvas.hasAttribute("tabindex")) {
  #|     canvas.setAttribute("tabindex", "0")
  #|   }
  #|   if (canvas.style) {
  #|     canvas.style.outline = "none"
  #|   }
  #|   const focusCanvas = () => {
  #|     if (typeof canvas.focus !== "function") return
  #|     try {
  #|       canvas.focus({ preventScroll: true })
  #|     } catch (_err) {
  #|       try { canvas.focus() } catch (_e) {}
  #|     }
  #|   }
  #|   if (!canvas.__mgstudioInputFocusBound) {
  #|     canvas.addEventListener("pointerdown", focusCanvas)
  #|     canvas.addEventListener("mousedown", focusCanvas)
  #|     canvas.__mgstudioInputFocusBound = true
  #|   }
  #| }

///|
extern "js" fn should_capture_keyboard_event(
  event : @js.Any,
  canvas : @js.Any,
) -> Bool =
  #| (event, canvas) => {
  #|   if (!event || !canvas) return false
  #|   const target = event.target
  #|   if (target && typeof target === "object") {
  #|     const tag = String(target.tagName || "").toUpperCase()
  #|     if (target.isContentEditable || tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") {
  #|       return false
  #|     }
  #|   }
  #|   const doc =
  #|     (typeof document === "object" && document) ||
  #|     canvas.ownerDocument ||
  #|     null
  #|   if (!doc) return false
  #|   if (doc.activeElement === canvas) return true
  #|   if (doc.pointerLockElement === canvas) return true
  #|   if (target === canvas) return true
  #|   if (typeof event.composedPath === "function") {
  #|     const path = event.composedPath()
  #|     if (Array.isArray(path) && path.includes(canvas)) {
  #|       return true
  #|     }
  #|   }
  #|   const active = doc.activeElement
  #|   if (active == null || active === doc.body || active === doc.documentElement) {
  #|     return true
  #|   }
  #|   return false
  #| }

///|
extern "js" fn pointer_lock_active_for_target(target : @js.Any) -> Bool =
  #| (target) => {
  #|   if (!target) return false
  #|   const doc =
  #|     (typeof document === "object" && document) ||
  #|     target.ownerDocument ||
  #|     null
  #|   if (!doc) return false
  #|   return doc.pointerLockElement === target
  #| }

///|
extern "js" fn pointer_event_set_capture(
  target : @js.Any,
  event : @js.Any,
) -> Unit =
  #| (target, event) => {
  #|   if (!target || !event) return
  #|   if (typeof target.setPointerCapture !== "function") return
  #|   const pointerId = Number(event.pointerId)
  #|   if (!Number.isFinite(pointerId)) return
  #|   try {
  #|     target.setPointerCapture(pointerId)
  #|   } catch (_err) {
  #|   }
  #| }

///|
extern "js" fn pointer_event_release_capture(
  target : @js.Any,
  event : @js.Any,
) -> Unit =
  #| (target, event) => {
  #|   if (!target || !event) return
  #|   if (typeof target.releasePointerCapture !== "function") return
  #|   const pointerId = Number(event.pointerId)
  #|   if (!Number.isFinite(pointerId)) return
  #|   try {
  #|     if (typeof target.hasPointerCapture === "function" && !target.hasPointerCapture(pointerId)) {
  #|       return
  #|     }
  #|     target.releasePointerCapture(pointerId)
  #|   } catch (_err) {
  #|   }
  #| }

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
extern "js" fn wgsl_ensure_compose_helper() -> Unit =
  #| () => {
  #|   if (globalThis.__mgstudioWgslHelper) {
  #|     return
  #|   }
  #|   const isIdent = (text) => /^[A-Za-z_][A-Za-z0-9_]*$/.test(String(text || ""))
  #|   const isUpperIdent = (text) => /^[A-Z][A-Za-z0-9_]*$/.test(String(text || ""))
  #|   const normalizeShaderPath = (textRaw) => {
  #|     let text = String(textRaw || "").trim().replace(/^["']|["']$/g, "")
  #|     text = text.replace(/^\/+/, "")
  #|     while (text.startsWith("./")) {
  #|       text = text.slice(2)
  #|     }
  #|     if (text.startsWith("assets/")) {
  #|       text = text.slice("assets/".length)
  #|     }
  #|     return text
  #|   }
  #|   const splitModulePath = (specRaw) => String(specRaw || "").split("::").map((s) => s.trim()).filter((s) => s.length > 0)
  #|   const normalizeAlias = (aliasRaw) => {
  #|     const alias = String(aliasRaw || "").trim()
  #|     if (!isIdent(alias)) {
  #|       return ""
  #|     }
  #|     return alias
  #|   }
  #|   const countBraceDelta = (textRaw) => {
  #|     let delta = 0
  #|     const text = String(textRaw || "")
  #|     for (let i = 0; i < text.length; i += 1) {
  #|       const ch = text[i]
  #|       if (ch === "{") {
  #|         delta += 1
  #|       } else if (ch === "}") {
  #|         delta -= 1
  #|       }
  #|     }
  #|     return delta
  #|   }
  #|   const tokenizeImportSpec = (specRaw) => {
  #|     const spec = String(specRaw || "")
  #|     const tokens = []
  #|     let idx = 0
  #|     while (idx < spec.length) {
  #|       const ch = spec[idx]
  #|       if (/\s/.test(ch)) {
  #|         idx += 1
  #|         continue
  #|       }
  #|       if (ch === "/" && idx + 1 < spec.length && spec[idx + 1] === "/") {
  #|         break
  #|       }
  #|       if (ch === ",") {
  #|         tokens.push({ kind: "comma" })
  #|         idx += 1
  #|         continue
  #|       }
  #|       if (ch === ";") {
  #|         tokens.push({ kind: "semicolon" })
  #|         idx += 1
  #|         continue
  #|       }
  #|       if (ch === "{") {
  #|         tokens.push({ kind: "lbrace" })
  #|         idx += 1
  #|         continue
  #|       }
  #|       if (ch === "}") {
  #|         tokens.push({ kind: "rbrace" })
  #|         idx += 1
  #|         continue
  #|       }
  #|       if (ch === ":") {
  #|         if (idx + 1 < spec.length && spec[idx + 1] === ":") {
  #|           tokens.push({ kind: "scope" })
  #|           idx += 2
  #|           continue
  #|         }
  #|         throw new Error("wgpu: malformed WGSL import: expected `::`")
  #|       }
  #|       if (ch === "\"") {
  #|         const start = idx
  #|         idx += 1
  #|         while (idx < spec.length && spec[idx] !== "\"") {
  #|           idx += 1
  #|         }
  #|         if (idx >= spec.length) {
  #|           throw new Error("wgpu: malformed WGSL import: unterminated quote")
  #|         }
  #|         idx += 1
  #|         tokens.push({ kind: "ident", text: spec.slice(start, idx) })
  #|         continue
  #|       }
  #|       if (/[A-Za-z_]/.test(ch)) {
  #|         const start = idx
  #|         idx += 1
  #|         while (idx < spec.length && /[A-Za-z0-9_]/.test(spec[idx])) {
  #|           idx += 1
  #|         }
  #|         const ident = spec.slice(start, idx)
  #|         if (ident === "as") {
  #|           tokens.push({ kind: "as" })
  #|         } else {
  #|           tokens.push({ kind: "ident", text: ident })
  #|         }
  #|         continue
  #|       }
  #|       throw new Error("wgpu: malformed WGSL import: unexpected token `" + ch + "`")
  #|     }
  #|     return tokens
  #|   }
  #|   const parseImportSpec = (specRaw) => {
  #|     const tokens = tokenizeImportSpec(specRaw)
  #|     const out = []
  #|     const cursor = { value: 0 }
  #|     const parseSegment = () => {
  #|       const tok = tokens[cursor.value]
  #|       if (!tok || tok.kind !== "ident") {
  #|         throw new Error("wgpu: malformed WGSL import segment")
  #|       }
  #|       cursor.value += 1
  #|       return String(tok.text || "")
  #|     }
  #|     const parseItem = (prefixRaw) => {
  #|       const segment = parseSegment()
  #|       let path = ""
  #|       const prefix = String(prefixRaw || "")
  #|       if (prefix.length > 0) {
  #|         path = prefix + "::" + segment
  #|       } else {
  #|         path = segment
  #|       }
  #|       while (cursor.value < tokens.length) {
  #|         const tok = tokens[cursor.value]
  #|         if (!tok || tok.kind !== "scope") {
  #|           break
  #|         }
  #|         cursor.value += 1
  #|         const afterScope = tokens[cursor.value]
  #|         if (afterScope && afterScope.kind === "lbrace") {
  #|           cursor.value += 1
  #|           while (cursor.value < tokens.length) {
  #|             const nextTok = tokens[cursor.value]
  #|             if (nextTok && nextTok.kind === "rbrace") {
  #|               cursor.value += 1
  #|               break
  #|             }
  #|             parseItem(path)
  #|             const sepTok = tokens[cursor.value]
  #|             if (sepTok && sepTok.kind === "comma") {
  #|               cursor.value += 1
  #|               continue
  #|             }
  #|             if (sepTok && sepTok.kind === "rbrace") {
  #|               cursor.value += 1
  #|               break
  #|             }
  #|             throw new Error("wgpu: malformed WGSL import block")
  #|           }
  #|           return
  #|         }
  #|         const nextSegment = parseSegment()
  #|         path = path + "::" + nextSegment
  #|       }
  #|       let usedName = ""
  #|       if (cursor.value < tokens.length && tokens[cursor.value].kind === "as") {
  #|         cursor.value += 1
  #|         usedName = parseSegment()
  #|       } else {
  #|         const parts = path.split("::")
  #|         if (parts.length > 0) {
  #|           usedName = String(parts[parts.length - 1] || "").trim().replace(/^"|"$/g, "")
  #|         }
  #|       }
  #|       out.push({
  #|         module_spec: path,
  #|         used_name: normalizeAlias(usedName),
  #|       })
  #|     }
  #|     while (cursor.value < tokens.length) {
  #|       const tok = tokens[cursor.value]
  #|       if (tok.kind === "comma") {
  #|         cursor.value += 1
  #|         continue
  #|       }
  #|       if (tok.kind === "semicolon") {
  #|         break
  #|       }
  #|       parseItem("")
  #|       if (cursor.value < tokens.length && tokens[cursor.value].kind === "comma") {
  #|         cursor.value += 1
  #|       }
  #|     }
  #|     return out
  #|   }
  #|   const extractImportEntries = (sourceRaw) => {
  #|     const source = String(sourceRaw || "")
  #|     const lines = source.split(/\r?\n/)
  #|     const out = []
  #|     for (let i = 0; i < lines.length; i += 1) {
  #|       const line = String(lines[i] || "")
  #|       const trimmed = line.trim()
  #|       if (!trimmed.startsWith("#import ")) {
  #|         continue
  #|       }
  #|       let statement = trimmed.slice("#import ".length)
  #|       let depth = countBraceDelta(statement)
  #|       while (depth > 0 && i + 1 < lines.length) {
  #|         i += 1
  #|         const nextLine = String(lines[i] || "")
  #|         statement += "\n" + nextLine.trim()
  #|         depth += countBraceDelta(nextLine)
  #|       }
  #|       const entries = parseImportSpec(statement)
  #|       for (const entry of entries) {
  #|         out.push(entry)
  #|       }
  #|     }
  #|     return out
  #|   }
  #|   const stripImportDefineLines = (sourceRaw) => {
  #|     const source = String(sourceRaw || "")
  #|     const lines = source.split(/\r?\n/)
  #|     const out = []
  #|     for (let i = 0; i < lines.length; i += 1) {
  #|       const line = String(lines[i] || "")
  #|       const trimmed = line.trim()
  #|       if (trimmed.startsWith("#define_import_path")) {
  #|         continue
  #|       }
  #|       if (trimmed.startsWith("#import ")) {
  #|         let depth = countBraceDelta(trimmed.slice("#import ".length))
  #|         while (depth > 0 && i + 1 < lines.length) {
  #|           i += 1
  #|           depth += countBraceDelta(lines[i])
  #|         }
  #|         continue
  #|       }
  #|       out.push(line)
  #|     }
  #|     return out.join("\n")
  #|   }
  #|   const stripModuleAliases = (sourceRaw, aliasesRaw) => {
  #|     const source = String(sourceRaw || "")
  #|     const aliases = Array.isArray(aliasesRaw) ? aliasesRaw : []
  #|     const dedup = Array.from(new Set(aliases.map((a) => normalizeAlias(a)).filter((a) => a.length > 0)))
  #|     if (dedup.length === 0) {
  #|       return source
  #|     }
  #|     const escapeRegExp = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
  #|     let out = source
  #|     for (const alias of dedup) {
  #|       const pattern = new RegExp("\\b" + escapeRegExp(alias) + "\\s*::\\s*", "g")
  #|       out = out.replace(pattern, "")
  #|     }
  #|     return out
  #|   }
  #|   const parseDefLiteral = (valueRaw) => {
  #|     const text = String(valueRaw || "").trim()
  #|     if (text.length === 0) {
  #|       return null
  #|     }
  #|     if (/^(true|false)$/i.test(text)) {
  #|       return { kind: "bool", value: /^true$/i.test(text) }
  #|     }
  #|     const numMatch = /^([+-]?(?:0[xX][0-9A-Fa-f]+|\d+))([uU]?)$/.exec(text)
  #|     if (!numMatch) {
  #|       return null
  #|     }
  #|     const body = numMatch[1]
  #|     const kind = numMatch[2] ? "uint" : "int"
  #|     let value = 0
  #|     if (/^[-+]?0[xX]/.test(body)) {
  #|       value = Number.parseInt(body, 16)
  #|     } else {
  #|       value = Number.parseInt(body, 10)
  #|     }
  #|     if (!Number.isFinite(value)) {
  #|       return null
  #|     }
  #|     if (kind === "uint") {
  #|       value = Math.max(0, Math.trunc(value))
  #|     } else {
  #|       value = Math.trunc(value)
  #|     }
  #|     return { kind, value }
  #|   }
  #|   const coerceDefValue = (valueRaw) => {
  #|     if (typeof valueRaw === "boolean") {
  #|       return { kind: "bool", value: valueRaw }
  #|     }
  #|     if (typeof valueRaw === "number" && Number.isFinite(valueRaw)) {
  #|       const value = Math.trunc(valueRaw)
  #|       return value >= 0
  #|         ? { kind: "uint", value }
  #|         : { kind: "int", value }
  #|     }
  #|     if (typeof valueRaw === "string") {
  #|       return parseDefLiteral(valueRaw)
  #|     }
  #|     if (valueRaw && typeof valueRaw === "object") {
  #|       const kindRaw = String(valueRaw.kind || valueRaw.type || "").trim().toLowerCase()
  #|       if (kindRaw === "bool" || kindRaw === "boolean") {
  #|         return { kind: "bool", value: !!(valueRaw.value ?? valueRaw.bool ?? valueRaw.bool_value) }
  #|       }
  #|       if (kindRaw === "int" || kindRaw === "i32") {
  #|         const num = Number(valueRaw.value ?? valueRaw.int ?? valueRaw.int_value)
  #|         if (Number.isFinite(num)) {
  #|           return { kind: "int", value: Math.trunc(num) }
  #|         }
  #|       }
  #|       if (kindRaw === "uint" || kindRaw === "u32") {
  #|         const num = Number(valueRaw.value ?? valueRaw.uint ?? valueRaw.uint_value)
  #|         if (Number.isFinite(num)) {
  #|           return { kind: "uint", value: Math.max(0, Math.trunc(num)) }
  #|         }
  #|       }
  #|       if ("bool" in valueRaw) {
  #|         return { kind: "bool", value: !!valueRaw.bool }
  #|       }
  #|       if ("int" in valueRaw) {
  #|         const num = Number(valueRaw.int)
  #|         if (Number.isFinite(num)) {
  #|           return { kind: "int", value: Math.trunc(num) }
  #|         }
  #|       }
  #|       if ("uint" in valueRaw) {
  #|         const num = Number(valueRaw.uint)
  #|         if (Number.isFinite(num)) {
  #|           return { kind: "uint", value: Math.max(0, Math.trunc(num)) }
  #|         }
  #|       }
  #|       if ("value" in valueRaw) {
  #|         return coerceDefValue(valueRaw.value)
  #|       }
  #|     }
  #|     return null
  #|   }
  #|   const normalizeShaderDefs = (defsRaw) => {
  #|     const out = {}
  #|     const setEntry = (keyRaw, valueRaw) => {
  #|       const key = String(keyRaw || "").trim()
  #|       if (!isIdent(key)) {
  #|         return
  #|       }
  #|       const value = coerceDefValue(valueRaw)
  #|       if (value) {
  #|         out[key] = value
  #|       }
  #|     }
  #|     const parseLegacy = (textRaw) => {
  #|       const text = String(textRaw || "").trim()
  #|       if (text.length === 0) {
  #|         return
  #|       }
  #|       const eqIndex = text.indexOf("=")
  #|       if (eqIndex < 0) {
  #|         setEntry(text, true)
  #|         return
  #|       }
  #|       const key = text.slice(0, eqIndex).trim()
  #|       const value = text.slice(eqIndex + 1).trim()
  #|       if (key.length === 0) {
  #|         return
  #|       }
  #|       const parsed = parseDefLiteral(value)
  #|       if (parsed) {
  #|         out[key] = parsed
  #|       } else {
  #|         out[key] = { kind: "bool", value: true }
  #|       }
  #|     }
  #|     if (Array.isArray(defsRaw)) {
  #|       for (const item of defsRaw) {
  #|         if (typeof item === "string") {
  #|           parseLegacy(item)
  #|           continue
  #|         }
  #|         if (item && typeof item === "object") {
  #|           const key = item.key ?? item.name
  #|           if (typeof key === "string") {
  #|             setEntry(key, item.value ?? item)
  #|           }
  #|         }
  #|       }
  #|       return out
  #|     }
  #|     if (defsRaw instanceof Map) {
  #|       for (const [key, value] of defsRaw.entries()) {
  #|         setEntry(key, value)
  #|       }
  #|       return out
  #|     }
  #|     if (defsRaw && typeof defsRaw === "object") {
  #|       for (const [key, value] of Object.entries(defsRaw)) {
  #|         setEntry(key, value)
  #|       }
  #|       return out
  #|     }
  #|     return out
  #|   }
  #|   const shaderDefNumericValue = (entry) => {
  #|     if (!entry) {
  #|       return 0
  #|     }
  #|     if (entry.kind === "bool") {
  #|       return entry.value ? 1 : 0
  #|     }
  #|     if (entry.kind === "uint") {
  #|       return Math.max(0, Math.trunc(Number(entry.value || 0)))
  #|     }
  #|     if (entry.kind === "int") {
  #|       return Math.trunc(Number(entry.value || 0))
  #|     }
  #|     return 0
  #|   }
  #|   const shaderDefStringValue = (entry) => {
  #|     if (!entry) {
  #|       return ""
  #|     }
  #|     if (entry.kind === "bool") {
  #|       return entry.value ? "true" : "false"
  #|     }
  #|     if (entry.kind === "uint") {
  #|       return Math.max(0, Math.trunc(Number(entry.value || 0))).toString()
  #|     }
  #|     if (entry.kind === "int") {
  #|       return Math.trunc(Number(entry.value || 0)).toString()
  #|     }
  #|     return ""
  #|   }
  #|   const evaluateIfExpression = (exprRaw, defs) => {
  #|     let expr = String(exprRaw || "").trim()
  #|     if (expr.length === 0) {
  #|       return false
  #|     }
  #|     expr = expr
  #|       .replace(/\bdefined\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)/g, (_m, name) => (Object.prototype.hasOwnProperty.call(defs, name) ? "1" : "0"))
  #|       .replace(/\bdefined\s+([A-Za-z_][A-Za-z0-9_]*)/g, (_m, name) => (Object.prototype.hasOwnProperty.call(defs, name) ? "1" : "0"))
  #|     const tokenRe = /\s+|0[xX][0-9A-Fa-f]+[uU]?|\d+[uU]?|&&|\|\||==|!=|<=|>=|<<|>>|[()!~%^*\/+\-&|<>]|[A-Za-z_][A-Za-z0-9_]*/gy
  #|     const sanitized = []
  #|     let index = 0
  #|     while (index < expr.length) {
  #|       tokenRe.lastIndex = index
  #|       const match = tokenRe.exec(expr)
  #|       if (!match) {
  #|         return false
  #|       }
  #|       const token = match[0]
  #|       index = tokenRe.lastIndex
  #|       if (/^\s+$/.test(token)) {
  #|         continue
  #|       }
  #|       if (/^[A-Za-z_][A-Za-z0-9_]*$/.test(token)) {
  #|         sanitized.push(shaderDefNumericValue(defs[token]).toString())
  #|         continue
  #|       }
  #|       if (/^(?:0[xX][0-9A-Fa-f]+|\d+)[uU]$/.test(token)) {
  #|         sanitized.push(token.slice(0, token.length - 1))
  #|         continue
  #|       }
  #|       sanitized.push(token)
  #|     }
  #|     if (sanitized.length === 0) {
  #|       return false
  #|     }
  #|     const finalExpr = sanitized.join(" ")
  #|     try {
  #|       const value = Function("\"use strict\"; return (" + finalExpr + ");")()
  #|       if (typeof value === "boolean") {
  #|         return value
  #|       }
  #|       if (typeof value === "number") {
  #|         return Number.isFinite(value) && value !== 0
  #|       }
  #|       return false
  #|     } catch {
  #|       return false
  #|     }
  #|   }
  #|   const applyPreprocessor = (sourceRaw, defsRaw) => {
  #|     const source = String(sourceRaw || "")
  #|     const defs = normalizeShaderDefs(defsRaw)
  #|     const lines = source.split(/\r?\n/)
  #|     const frames = []
  #|     const out = []
  #|     const currentActive = () => (frames.length > 0 ? frames[frames.length - 1].active : true)
  #|     const directiveBody = (lineRaw) => {
  #|       const line = String(lineRaw || "").trim()
  #|       if (!line.startsWith("#")) {
  #|         return ""
  #|       }
  #|       let body = line.slice(1)
  #|       const commentIndex = body.indexOf("//")
  #|       if (commentIndex >= 0) {
  #|         body = body.slice(0, commentIndex)
  #|       }
  #|       return body.trim()
  #|     }
  #|     const directiveArg = (lineRaw, directive) => {
  #|       const body = directiveBody(lineRaw)
  #|       if (!body.startsWith(directive)) {
  #|         return null
  #|       }
  #|       const rest = body.slice(directive.length)
  #|       if (rest.length === 0) {
  #|         return ""
  #|       }
  #|       if (!/^\s/.test(rest)) {
  #|         return null
  #|       }
  #|       return rest.trim()
  #|     }
  #|     const isDirectiveKeyword = (lineRaw, keyword) => directiveBody(lineRaw) === keyword
  #|     for (const lineRaw of lines) {
  #|       const line = String(lineRaw || "")
  #|       const trimmed = line.trim()
  #|       const ifdefName = directiveArg(trimmed, "ifdef")
  #|       if (ifdefName !== null) {
  #|         const parent = currentActive()
  #|         const cond = Object.prototype.hasOwnProperty.call(defs, ifdefName)
  #|         frames.push({ parent, branch_taken: cond, active: parent && cond })
  #|         continue
  #|       }
  #|       const ifndefName = directiveArg(trimmed, "ifndef")
  #|       if (ifndefName !== null) {
  #|         const parent = currentActive()
  #|         const cond = !Object.prototype.hasOwnProperty.call(defs, ifndefName)
  #|         frames.push({ parent, branch_taken: cond, active: parent && cond })
  #|         continue
  #|       }
  #|       const ifExpr = directiveArg(trimmed, "if")
  #|       if (ifExpr !== null) {
  #|         const parent = currentActive()
  #|         const cond = evaluateIfExpression(ifExpr, defs)
  #|         frames.push({ parent, branch_taken: cond, active: parent && cond })
  #|         continue
  #|       }
  #|       const elseIfdefName = directiveArg(trimmed, "else ifdef")
  #|       if (elseIfdefName !== null) {
  #|         if (frames.length > 0) {
  #|           const frame = frames[frames.length - 1]
  #|           const cond = !frame.branch_taken && Object.prototype.hasOwnProperty.call(defs, elseIfdefName)
  #|           frame.active = frame.parent && cond
  #|           frame.branch_taken = frame.branch_taken || cond
  #|         }
  #|         continue
  #|       }
  #|       const elseIfndefName = directiveArg(trimmed, "else ifndef")
  #|       if (elseIfndefName !== null) {
  #|         if (frames.length > 0) {
  #|           const frame = frames[frames.length - 1]
  #|           const cond = !frame.branch_taken && !Object.prototype.hasOwnProperty.call(defs, elseIfndefName)
  #|           frame.active = frame.parent && cond
  #|           frame.branch_taken = frame.branch_taken || cond
  #|         }
  #|         continue
  #|       }
  #|       const elseIfExpr = directiveArg(trimmed, "else if")
  #|       if (elseIfExpr !== null) {
  #|         if (frames.length > 0) {
  #|           const frame = frames[frames.length - 1]
  #|           const cond = !frame.branch_taken && evaluateIfExpression(elseIfExpr, defs)
  #|           frame.active = frame.parent && cond
  #|           frame.branch_taken = frame.branch_taken || cond
  #|         }
  #|         continue
  #|       }
  #|       if (isDirectiveKeyword(trimmed, "else")) {
  #|         if (frames.length > 0) {
  #|           const frame = frames[frames.length - 1]
  #|           const cond = !frame.branch_taken
  #|           frame.active = frame.parent && cond
  #|           frame.branch_taken = frame.branch_taken || cond
  #|         }
  #|         continue
  #|       }
  #|       if (isDirectiveKeyword(trimmed, "endif")) {
  #|         if (frames.length > 0) {
  #|           frames.pop()
  #|         }
  #|         continue
  #|       }
  #|       if (currentActive()) {
  #|         out.push(line)
  #|       }
  #|     }
  #|     let merged = out.join("\n")
  #|     merged = merged.replace(/#\{([A-Za-z_][A-Za-z0-9_]*)\}/g, (all, key) => {
  #|       if (!Object.prototype.hasOwnProperty.call(defs, key)) {
  #|         return all
  #|       }
  #|       const text = shaderDefStringValue(defs[key])
  #|       if (text.length === 0) {
  #|         return all
  #|       }
  #|       return text
  #|     })
  #|     return merged
  #|   }
  #|   const coerceModuleIndexPath = (pathRaw) => {
  #|     let text = String(pathRaw || "").trim().replace(/^["']|["']$/g, "")
  #|     if (text.length === 0) {
  #|       return ""
  #|     }
  #|     if (text.includes("::")) {
  #|       text = "shaders/bevy/" + text.replace(/::/g, "/") + ".wgsl"
  #|     } else {
  #|       if (!text.endsWith(".wgsl")) {
  #|         text = text + ".wgsl"
  #|       }
  #|       if (!text.startsWith("shaders/")) {
  #|         if (text.startsWith("bevy/")) {
  #|           text = "shaders/" + text
  #|         } else {
  #|           text = "shaders/bevy/" + text
  #|         }
  #|       }
  #|     }
  #|     return normalizeShaderPath(text)
  #|   }
  #|   const coerceModuleIndexKey = (keyRaw) => {
  #|     let key = String(keyRaw || "").trim().replace(/^["']|["']$/g, "")
  #|     if (key.length === 0) {
  #|       return ""
  #|     }
  #|     key = normalizeShaderPath(key)
  #|     if (!key.includes("::") && key.endsWith(".wgsl")) {
  #|       if (key.startsWith("shaders/bevy/")) {
  #|         key = key.slice("shaders/bevy/".length)
  #|       }
  #|       key = key.slice(0, key.length - ".wgsl".length).replace(/\//g, "::")
  #|     }
  #|     return key
  #|   }
  #|   const parseModuleIndexText = (textRaw) => {
  #|     const map = new Map()
  #|     const add = (keyRaw, valueRaw) => {
  #|       const key = coerceModuleIndexKey(keyRaw)
  #|       const value = coerceModuleIndexPath(valueRaw)
  #|       if (key.length === 0 || value.length === 0) {
  #|         return
  #|       }
  #|       map.set(key, value)
  #|     }
  #|     const ingest = (node) => {
  #|       if (!node) {
  #|         return
  #|       }
  #|       if (Array.isArray(node)) {
  #|         for (const item of node) {
  #|           if (Array.isArray(item) && item.length >= 2) {
  #|             add(item[0], item[1])
  #|             continue
  #|           }
  #|           ingest(item)
  #|         }
  #|         return
  #|       }
  #|       if (typeof node === "object") {
  #|         const key = node.module ?? node.name ?? node.key
  #|         const path = node.path ?? node.file ?? node.rel_path ?? node.value
  #|         if (typeof key === "string" && typeof path === "string") {
  #|           add(key, path)
  #|         }
  #|         for (const [k, v] of Object.entries(node)) {
  #|           if (typeof v === "string") {
  #|             add(k, v)
  #|           } else {
  #|             ingest(v)
  #|           }
  #|         }
  #|       }
  #|     }
  #|     const text = String(textRaw || "").trim()
  #|     if (text.length > 0) {
  #|       try {
  #|         ingest(JSON.parse(text))
  #|       } catch {
  #|       }
  #|       if (map.size === 0) {
  #|         const lines = text.split(/\r?\n/)
  #|         for (const lineRaw of lines) {
  #|           const line = String(lineRaw || "").trim()
  #|           if (line.length === 0 || line.startsWith("#") || line.startsWith("//")) {
  #|             continue
  #|           }
  #|           const m = /^(.+?)(?:=>|->|=|,|\s+)(.+)$/.exec(line)
  #|           if (!m) {
  #|             continue
  #|           }
  #|           add(m[1], m[2])
  #|         }
  #|       }
  #|     }
  #|     return map
  #|   }
  #|   const resolveImportCandidates = (moduleSpecRaw, _aliasHintRaw, moduleIndexRaw) => {
  #|     const moduleSpec = String(moduleSpecRaw || "").trim().replace(/;+$/, "").trim()
  #|     const out = []
  #|     const seen = new Set()
  #|     const pushCandidate = (pathRaw, moduleKeyRaw, exactRaw) => {
  #|       const path = coerceModuleIndexPath(pathRaw)
  #|       if (path.length === 0 || seen.has(path)) {
  #|         return
  #|       }
  #|       seen.add(path)
  #|       const moduleKey = String(moduleKeyRaw || "").trim()
  #|       out.push({ path, exact: !!exactRaw, module_key: moduleKey })
  #|     }
  #|     const lookupModulePath = (index, keyRaw) => {
  #|       const key = String(keyRaw || "").trim()
  #|       if (key.length === 0) {
  #|         return ""
  #|       }
  #|       if (index instanceof Map) {
  #|         const value = index.get(key)
  #|         if (typeof value === "string") {
  #|           return value
  #|         }
  #|       } else if (index && typeof index === "object") {
  #|         const value = index[key]
  #|         if (typeof value === "string") {
  #|           return value
  #|         }
  #|       }
  #|       return ""
  #|     }
  #|     if (moduleSpec.length === 0) {
  #|       return out
  #|     }
  #|     if (moduleSpec.startsWith("\"") || moduleSpec.startsWith("'")) {
  #|       const quote = moduleSpec[0]
  #|       const closeIndex = moduleSpec.indexOf(quote, 1)
  #|       if (closeIndex > 0) {
  #|         const rawPath = moduleSpec.slice(1, closeIndex)
  #|         pushCandidate(rawPath, moduleSpec)
  #|         return out
  #|       }
  #|     }
  #|     const parts = splitModulePath(moduleSpec)
  #|     if (parts.length === 0) {
  #|       return out
  #|     }
  #|     const moduleIndex = moduleIndexRaw ?? null
  #|     for (let i = parts.length; i >= 1; i -= 1) {
  #|       const key = parts.slice(0, i).join("::")
  #|       const indexedPath = lookupModulePath(moduleIndex, key)
  #|       if (indexedPath.length > 0) {
  #|         pushCandidate(indexedPath, key, i === parts.length)
  #|       }
  #|     }
  #|     for (let i = parts.length; i >= 1; i -= 1) {
  #|       const key = parts.slice(0, i).join("::")
  #|       const fallbackPath = "shaders/bevy/" + parts.slice(0, i).join("/") + ".wgsl"
  #|       pushCandidate(fallbackPath, key, i === parts.length)
  #|     }
  #|     return out
  #|   }
  #|   const importLeafSymbol = (moduleSpecRaw) => {
  #|     const moduleSpec = String(moduleSpecRaw || "").trim().replace(/;+$/, "").trim()
  #|     if (moduleSpec.length === 0) {
  #|       return ""
  #|     }
  #|     if (moduleSpec.startsWith("\"") || moduleSpec.startsWith("'")) {
  #|       return ""
  #|     }
  #|     const parts = splitModulePath(moduleSpec)
  #|     if (parts.length === 0) {
  #|       return ""
  #|     }
  #|     return String(parts[parts.length - 1] || "").trim()
  #|   }
  #|   const symbolLooksLikeType = (symbolRaw) => {
  #|     const symbol = String(symbolRaw || "").trim()
  #|     return /^[A-Z]/.test(symbol)
  #|   }
  #|   const stripTopLevelFunctions = (sourceRaw) => {
  #|     const source = String(sourceRaw || "")
  #|     const lines = source.split(/\r?\n/)
  #|     const firstFnIndex = (() => {
  #|       for (let i = 0; i < lines.length; i += 1) {
  #|         const trimmed = String(lines[i] || "").trimStart()
  #|         if (trimmed.startsWith("fn ")) {
  #|           return i
  #|         }
  #|         if (trimmed.startsWith("@")) {
  #|           let j = i + 1
  #|           while (j < lines.length && String(lines[j] || "").trim().length === 0) {
  #|             j += 1
  #|           }
  #|           if (j < lines.length && String(lines[j] || "").trimStart().startsWith("fn ")) {
  #|             return i
  #|           }
  #|         }
  #|       }
  #|       return -1
  #|     })()
  #|     if (firstFnIndex <= 0) {
  #|       return source
  #|     }
  #|     let out = lines.slice(0, firstFnIndex).join("\n")
  #|     if (out.length > 0 && !out.endsWith("\n")) {
  #|       out += "\n"
  #|     }
  #|     return out
  #|   }
  #|   const shaderDefEnabled = (defs, key) => {
  #|     if (!Object.prototype.hasOwnProperty.call(defs, key)) {
  #|       return false
  #|     }
  #|     const entry = defs[key]
  #|     if (!entry || typeof entry !== "object") {
  #|       return false
  #|     }
  #|     if (entry.kind === "bool") {
  #|       return !!entry.value
  #|     }
  #|     if (entry.kind === "int" || entry.kind === "uint") {
  #|       return Number(entry.value || 0) !== 0
  #|     }
  #|     return false
  #|   }
  #|   const shouldSkipImportForDefs = (moduleSpecRaw, defsRaw) => {
  #|     const moduleSpec = String(moduleSpecRaw || "").trim().replace(/;+$/, "").trim()
  #|     if (moduleSpec.length === 0) {
  #|       return false
  #|     }
  #|     const defs = normalizeShaderDefs(defsRaw)
  #|     const environmentMapEnabled = shaderDefEnabled(defs, "ENVIRONMENT_MAP")
  #|     const irradianceVolumeEnabled = shaderDefEnabled(defs, "IRRADIANCE_VOLUME") || shaderDefEnabled(defs, "IRRADIANCE_VOLUMES_ARE_USABLE")
  #|     const ssrEnabled = shaderDefEnabled(defs, "SCREEN_SPACE_REFLECTIONS")
  #|     if (moduleSpec.includes("atmosphere::") && !shaderDefEnabled(defs, "ATMOSPHERE")) {
  #|       return true
  #|     }
  #|     if (moduleSpec.includes("environment_map") && !environmentMapEnabled) {
  #|       return true
  #|     }
  #|     if (moduleSpec.includes("irradiance_volume") && !irradianceVolumeEnabled) {
  #|       return true
  #|     }
  #|     if (moduleSpec.includes("light_probe") && !(environmentMapEnabled || irradianceVolumeEnabled)) {
  #|       return true
  #|     }
  #|     if (moduleSpec.includes("lightmap") && !shaderDefEnabled(defs, "LIGHTMAP")) {
  #|       return true
  #|     }
  #|     if (moduleSpec.includes("ssr") && !ssrEnabled) {
  #|       return true
  #|     }
  #|     if (moduleSpec.includes("raymarch") && !ssrEnabled) {
  #|       return true
  #|     }
  #|     if (moduleSpec.includes("ssao::") && !shaderDefEnabled(defs, "SCREEN_SPACE_AMBIENT_OCCLUSION")) {
  #|       return true
  #|     }
  #|     return false
  #|   }
  #|   const shaderDefsKey = (defsRaw) => {
  #|     const defs = normalizeShaderDefs(defsRaw)
  #|     const keys = Object.keys(defs).sort()
  #|     const parts = []
  #|     for (const key of keys) {
  #|       const entry = defs[key]
  #|       parts.push(key + ":" + entry.kind + ":" + shaderDefStringValue(entry))
  #|     }
  #|     return parts.join("|")
  #|   }
  #|   globalThis.__mgstudioWgslHelper = {
  #|     extractImportEntries,
  #|     resolveImportCandidates,
  #|     importLeafSymbol,
  #|     symbolLooksLikeType,
  #|     stripTopLevelFunctions,
  #|     shouldSkipImportForDefs,
  #|     stripImportDefineLines,
  #|     stripModuleAliases,
  #|     normalizeShaderDefs,
  #|     shaderDefsKey,
  #|     applyPreprocessor,
  #|     parseModuleIndexText,
  #|   }
  #| }

///|
extern "js" fn wgsl_extract_import_entries(source : String) -> @js.Any =
  #| (source) => globalThis.__mgstudioWgslHelper.extractImportEntries(source)

///|
extern "js" fn wgsl_resolve_import_candidates(
  module_spec : String,
  alias_hint : String,
  module_index : @js.Any,
) -> @js.Any =
  #| (moduleSpec, aliasHint, moduleIndex) => globalThis.__mgstudioWgslHelper.resolveImportCandidates(moduleSpec, aliasHint, moduleIndex)

///|
extern "js" fn wgsl_import_leaf_symbol(module_spec : String) -> String =
  #| (moduleSpec) => globalThis.__mgstudioWgslHelper.importLeafSymbol(moduleSpec)

///|
extern "js" fn wgsl_symbol_looks_like_type(symbol : String) -> Bool =
  #| (symbol) => globalThis.__mgstudioWgslHelper.symbolLooksLikeType(symbol)

///|
extern "js" fn wgsl_strip_top_level_functions(source : String) -> String =
  #| (source) => globalThis.__mgstudioWgslHelper.stripTopLevelFunctions(source)

///|
extern "js" fn wgsl_should_skip_import_for_defs(
  module_spec : String,
  shader_defs : @js.Any,
) -> Bool =
  #| (moduleSpec, shaderDefs) => globalThis.__mgstudioWgslHelper.shouldSkipImportForDefs(moduleSpec, shaderDefs)

///|
extern "js" fn wgsl_strip_module_aliases(
  source : String,
  aliases : Array[String],
) -> String =
  #| (source, aliases) => globalThis.__mgstudioWgslHelper.stripModuleAliases(source, aliases)

///|
extern "js" fn wgsl_strip_import_define_lines(source : String) -> String =
  #| (source) => globalThis.__mgstudioWgslHelper.stripImportDefineLines(source)

///|
extern "js" fn wgsl_shader_defs_from_legacy(defines : Array[String]) -> @js.Any =
  #| (defines) => globalThis.__mgstudioWgslHelper.normalizeShaderDefs(defines)

///|
extern "js" fn wgsl_apply_preprocessor(
  source : String,
  shader_defs : @js.Any,
) -> String =
  #| (source, shaderDefs) => globalThis.__mgstudioWgslHelper.applyPreprocessor(source, shaderDefs)

///|
extern "js" fn wgsl_parse_module_index_text(text : String) -> @js.Any =
  #| (text) => globalThis.__mgstudioWgslHelper.parseModuleIndexText(text)

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
  #| (map, key, value) => {
  #|   const normalizeKey = globalThis.__mgstudioNormalizeMapKey || (globalThis.__mgstudioNormalizeMapKey = ((input) => {
  #|     if (input == null) {
  #|       return input
  #|     }
  #|     const kind = typeof input
  #|     if (kind === "string" || kind === "number" || kind === "boolean" || kind === "bigint" || kind === "symbol") {
  #|       return input
  #|     }
  #|     const decodeWasmString = (value) => {
  #|       try {
  #|         let current = value
  #|         for (let i = 0; i < 4; i += 1) {
  #|           if (typeof current !== "object" || current == null) {
  #|             break
  #|           }
  #|           if ("value" in current && current.value !== current) {
  #|             current = current.value
  #|             continue
  #|           }
  #|           if ("val" in current && current.val !== current) {
  #|             current = current.val
  #|             continue
  #|           }
  #|           if ("string" in current && current.string !== current) {
  #|             current = current.string
  #|             continue
  #|           }
  #|           if ("_0" in current && current._0 !== current) {
  #|             current = current._0
  #|             continue
  #|           }
  #|           break
  #|         }
  #|         if (typeof current !== "object" || current == null) {
  #|           return null
  #|         }
  #|         let getFn = null
  #|         if (typeof current.get === "function") {
  #|           getFn = current.get
  #|         } else {
  #|           const proto = Object.getPrototypeOf(current)
  #|           if (proto && typeof proto.get === "function") {
  #|             getFn = proto.get
  #|           } else if (
  #|             typeof WebAssembly === "object" &&
  #|             typeof WebAssembly.Array === "function" &&
  #|             WebAssembly.Array.prototype &&
  #|             typeof WebAssembly.Array.prototype.get === "function"
  #|           ) {
  #|             getFn = WebAssembly.Array.prototype.get
  #|           }
  #|         }
  #|         if (!getFn) {
  #|           return null
  #|         }
  #|         let len = current.length
  #|         if (typeof len === "function") {
  #|           len = len.call(current)
  #|         }
  #|         len = Number(len)
  #|         if (!Number.isFinite(len) || len < 0) {
  #|           return null
  #|         }
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
  #|       } catch {
  #|         return null
  #|       }
  #|     }
  #|     const decoded = decodeWasmString(input)
  #|     return decoded == null ? input : decoded
  #|   }))
  #|   map.set(normalizeKey(key), value)
  #| }

///|
extern "js" fn map_get(map : @js.Any, key : @js.Any) -> @js.Any =
  #| (map, key) => {
  #|   const normalizeKey = globalThis.__mgstudioNormalizeMapKey || ((value) => value)
  #|   return map.get(normalizeKey(key))
  #| }

///|
extern "js" fn map_delete(map : @js.Any, key : @js.Any) -> Bool =
  #| (map, key) => {
  #|   const normalizeKey = globalThis.__mgstudioNormalizeMapKey || ((value) => value)
  #|   return map.delete(normalizeKey(key))
  #| }

///|
extern "js" fn map_values(map : @js.Any) -> @js.Any =
  #| (map) => Array.from(map.values())

///|
extern "js" fn set_add(set : @js.Any, value : @js.Any) -> Unit =
  #| (set, value) => {
  #|   const normalizeKey = globalThis.__mgstudioNormalizeMapKey || ((item) => item)
  #|   set.add(normalizeKey(value))
  #| }

///|
extern "js" fn set_has(set : @js.Any, value : @js.Any) -> Bool =
  #| (set, value) => {
  #|   const normalizeKey = globalThis.__mgstudioNormalizeMapKey || ((item) => item)
  #|   return set.has(normalizeKey(value))
  #| }

///|
extern "js" fn set_delete(set : @js.Any, value : @js.Any) -> Bool =
  #| (set, value) => {
  #|   const normalizeKey = globalThis.__mgstudioNormalizeMapKey || ((item) => item)
  #|   return set.delete(normalizeKey(value))
  #| }

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
extern "js" fn mesh3d_xyzuvrgba_to_xyznormal(
  src : @js.Any,
  primitive_topology_kind : Int,
) -> @js.Any =
  #| (src, primitiveTopologyKind) => {
  #|   const input = src && typeof src.length === "number" ? src : new Float32Array(0)
  #|   const vcount = Math.floor(input.length / 9)
  #|   if (vcount <= 0) {
  #|     return new Float32Array(0)
  #|   }
  #|   const topo = Number(primitiveTopologyKind) | 0
  #|   let usable = vcount
  #|   if (topo === 0) {
  #|     usable = vcount - (vcount % 3)
  #|   } else if (topo === 1) {
  #|     usable = vcount - (vcount % 2)
  #|   }
  #|   if (usable <= 0) {
  #|     return new Float32Array(0)
  #|   }
  #|   const out = new Float32Array(usable * 6)
  #|   const setNormal = (vi, nx, ny, nz) => {
  #|     const o = vi * 6
  #|     out[o + 3] = nx
  #|     out[o + 4] = ny
  #|     out[o + 5] = nz
  #|   }
  #|   for (let i = 0; i < usable; i += 1) {
  #|     const s = i * 9
  #|     const d = i * 6
  #|     out[d + 0] = Number(input[s + 0]) || 0
  #|     out[d + 1] = Number(input[s + 1]) || 0
  #|     out[d + 2] = Number(input[s + 2]) || 0
  #|     out[d + 3] = 0
  #|     out[d + 4] = 0
  #|     out[d + 5] = 1
  #|   }
  #|   if (topo === 0) {
  #|     for (let i = 0; i + 2 < usable; i += 3) {
  #|       const a = i * 6
  #|       const b = (i + 1) * 6
  #|       const c = (i + 2) * 6
  #|       const p0x = out[a + 0], p0y = out[a + 1], p0z = out[a + 2]
  #|       const p1x = out[b + 0], p1y = out[b + 1], p1z = out[b + 2]
  #|       const p2x = out[c + 0], p2y = out[c + 1], p2z = out[c + 2]
  #|       const e1x = p1x - p0x, e1y = p1y - p0y, e1z = p1z - p0z
  #|       const e2x = p2x - p0x, e2y = p2y - p0y, e2z = p2z - p0z
  #|       let nx = e1y * e2z - e1z * e2y
  #|       let ny = e1z * e2x - e1x * e2z
  #|       let nz = e1x * e2y - e1y * e2x
  #|       const len = Math.hypot(nx, ny, nz)
  #|       if (!(len > 1e-8)) {
  #|         nx = 0
  #|         ny = 0
  #|         nz = 1
  #|       } else {
  #|         nx /= len
  #|         ny /= len
  #|         nz /= len
  #|       }
  #|       setNormal(i, nx, ny, nz)
  #|       setNormal(i + 1, nx, ny, nz)
  #|       setNormal(i + 2, nx, ny, nz)
  #|     }
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
extern "js" fn mesh3d_bevy_view_uniform_bytes(
  camera_x : Double,
  camera_y : Double,
  camera_z : Double,
  camera_rot_x : Double,
  camera_rot_y : Double,
  camera_rot_z : Double,
  camera_rot_w : Double,
  camera_fov_y : Double,
  camera_near : Double,
  camera_far : Double,
  width_logical : Double,
  height_logical : Double,
  viewport_x : Double,
  viewport_y : Double,
  viewport_w : Double,
  viewport_h : Double,
  sub_view_scale_x : Double,
  sub_view_scale_y : Double,
  sub_view_bias_x : Double,
  sub_view_bias_y : Double,
) -> @js.Any =
  #| (
  #|   cameraX,
  #|   cameraY,
  #|   cameraZ,
  #|   cameraRotX,
  #|   cameraRotY,
  #|   cameraRotZ,
  #|   cameraRotW,
  #|   cameraFovY,
  #|   cameraNear,
  #|   cameraFar,
  #|   widthLogical,
  #|   heightLogical,
  #|   viewportX,
  #|   viewportY,
  #|   viewportW,
  #|   viewportH,
  #|   subViewScaleX,
  #|   subViewScaleY,
  #|   subViewBiasX,
  #|   subViewBiasY,
  #| ) => {
  #|   const n = (value, fallback = 0.0) => {
  #|     const v = Number(value)
  #|     return Number.isFinite(v) ? v : fallback
  #|   }
  #|   const quatNormalize4 = (qx, qy, qz, qw) => {
  #|     const x0 = n(qx)
  #|     const y0 = n(qy)
  #|     const z0 = n(qz)
  #|     const w0 = n(qw)
  #|     const norm2 = Math.max(x0 * x0 + y0 * y0 + z0 * z0 + w0 * w0, 1.0e-8)
  #|     const inv = 1.0 / Math.sqrt(norm2)
  #|     return [x0 * inv, y0 * inv, z0 * inv, w0 * inv]
  #|   }
  #|   const quatToRowMat3 = (qx, qy, qz, qw) => {
  #|     const [x, y, z, w] = quatNormalize4(qx, qy, qz, qw)
  #|     return [
  #|       1.0 - 2.0 * (y * y + z * z),
  #|       2.0 * (x * y - w * z),
  #|       2.0 * (x * z + w * y),
  #|       2.0 * (x * y + w * z),
  #|       1.0 - 2.0 * (x * x + z * z),
  #|       2.0 * (y * z - w * x),
  #|       2.0 * (x * z - w * y),
  #|       2.0 * (y * z + w * x),
  #|       1.0 - 2.0 * (x * x + y * y),
  #|     ]
  #|   }
  #|   const mat4RowMul = (a, b) => {
  #|     const out = new Float32Array(16)
  #|     for (let r = 0; r < 4; r += 1) {
  #|       for (let c = 0; c < 4; c += 1) {
  #|         out[r * 4 + c] =
  #|           a[r * 4 + 0] * b[c] +
  #|           a[r * 4 + 1] * b[4 + c] +
  #|           a[r * 4 + 2] * b[8 + c] +
  #|           a[r * 4 + 3] * b[12 + c]
  #|       }
  #|     }
  #|     return out
  #|   }
  #|   const mat4RowToCol = (m) => [
  #|     m[0], m[4], m[8], m[12],
  #|     m[1], m[5], m[9], m[13],
  #|     m[2], m[6], m[10], m[14],
  #|     m[3], m[7], m[11], m[15],
  #|   ]
  #|   const camX = n(cameraX)
  #|   const camY = n(cameraY)
  #|   const camZ = n(cameraZ)
  #|   const [qx, qy, qz, qw] = quatNormalize4(
  #|     cameraRotX,
  #|     cameraRotY,
  #|     cameraRotZ,
  #|     cameraRotW,
  #|   )
  #|   const r = quatToRowMat3(qx, qy, qz, qw)
  #|   const worldFromViewRow = new Float32Array([
  #|     r[0], r[1], r[2], camX,
  #|     r[3], r[4], r[5], camY,
  #|     r[6], r[7], r[8], camZ,
  #|     0.0, 0.0, 0.0, 1.0,
  #|   ])
  #|   const rt = [
  #|     r[0], r[3], r[6],
  #|     r[1], r[4], r[7],
  #|     r[2], r[5], r[8],
  #|   ]
  #|   const tx = -(rt[0] * camX + rt[1] * camY + rt[2] * camZ)
  #|   const ty = -(rt[3] * camX + rt[4] * camY + rt[5] * camZ)
  #|   const tz = -(rt[6] * camX + rt[7] * camY + rt[8] * camZ)
  #|   const viewFromWorldRow = new Float32Array([
  #|     rt[0], rt[1], rt[2], tx,
  #|     rt[3], rt[4], rt[5], ty,
  #|     rt[6], rt[7], rt[8], tz,
  #|     0.0, 0.0, 0.0, 1.0,
  #|   ])
  #|   const width = n(widthLogical, 1.0)
  #|   const height = n(heightLogical, 1.0)
  #|   const aspect = height > 0.0 ? width / height : 1.0
  #|   const fovY = n(cameraFovY)
  #|   const near = Math.max(n(cameraNear), 1.0e-4)
  #|   const far = Math.max(n(cameraFar), near + 1.0e-4)
  #|   let clipFromViewRow = null
  #|   if (fovY > 0.0) {
  #|     const f = 1.0 / Math.tan(0.5 * Math.max(fovY, 1.0e-3))
  #|     clipFromViewRow = new Float32Array([
  #|       f / Math.max(aspect, 1.0e-3), 0.0, 0.0, 0.0,
  #|       0.0, f, 0.0, 0.0,
  #|       0.0, 0.0, 0.0, near,
  #|       0.0, 0.0, -1.0, 0.0,
  #|     ])
  #|   } else {
  #|     const halfH = Math.max(-fovY, 1.0e-5)
  #|     const halfW = Math.max(halfH * Math.max(aspect, 1.0e-3), 1.0e-5)
  #|     const left = -halfW
  #|     const right = halfW
  #|     const bottom = -halfH
  #|     const top = halfH
  #|     const w = Math.max(right - left, 1.0e-5)
  #|     const h = Math.max(top - bottom, 1.0e-5)
  #|     const d = Math.max(far - near, 1.0e-5)
  #|     const cw = -right - left
  #|     const ch = -top - bottom
  #|     clipFromViewRow = new Float32Array([
  #|       2.0 / w, 0.0, 0.0, cw / w,
  #|       0.0, 2.0 / h, 0.0, ch / h,
  #|       0.0, 0.0, 1.0 / d, far / d,
  #|       0.0, 0.0, 0.0, 1.0,
  #|     ])
  #|   }
  #|   const subX = n(subViewScaleX, 1.0)
  #|   const subY = n(subViewScaleY, 1.0)
  #|   const subBiasX = n(subViewBiasX)
  #|   const subBiasY = n(subViewBiasY)
  #|   for (let c = 0; c < 4; c += 1) {
  #|     clipFromViewRow[c] = subX * clipFromViewRow[c] + subBiasX * clipFromViewRow[12 + c]
  #|     clipFromViewRow[4 + c] =
  #|       subY * clipFromViewRow[4 + c] + subBiasY * clipFromViewRow[12 + c]
  #|   }
  #|   const clipFromWorldRow = mat4RowMul(clipFromViewRow, viewFromWorldRow)
  #|   const clipFromWorldCol = mat4RowToCol(clipFromWorldRow)
  #|   const worldFromViewCol = mat4RowToCol(worldFromViewRow)
  #|   const viewFromWorldCol = mat4RowToCol(viewFromWorldRow)
  #|   const clipFromViewCol = mat4RowToCol(clipFromViewRow)
  #|   const identityCol = [
  #|     1.0, 0.0, 0.0, 0.0,
  #|     0.0, 1.0, 0.0, 0.0,
  #|     0.0, 0.0, 1.0, 0.0,
  #|     0.0, 0.0, 0.0, 1.0,
  #|   ]
  #|   const out = new Float32Array(192)
  #|   for (let i = 0; i < 16; i += 1) {
  #|     out[i] = clipFromWorldCol[i]
  #|     out[16 + i] = clipFromWorldCol[i]
  #|     out[32 + i] = identityCol[i]
  #|     out[48 + i] = worldFromViewCol[i]
  #|     out[64 + i] = viewFromWorldCol[i]
  #|     out[80 + i] = clipFromViewCol[i]
  #|     out[96 + i] = identityCol[i]
  #|   }
  #|   out[112] = camX
  #|   out[113] = camY
  #|   out[114] = camZ
  #|   // Bevy camera default exposure (Exposure::BLENDER: ev100=9.7)
  #|   out[115] = 0.0010019079
  #|   out[116] = n(viewportX)
  #|   out[117] = n(viewportY)
  #|   out[118] = n(viewportW)
  #|   out[119] = n(viewportH)
  #|   out[120] = n(viewportX)
  #|   out[121] = n(viewportY)
  #|   out[122] = n(viewportW)
  #|   out[123] = n(viewportH)
  #|   return out
  #| }

///|
extern "js" fn mesh3d_bevy_lights_uniform_bytes(
  ambient_r : Double,
  ambient_g : Double,
  ambient_b : Double,
  ambient_brightness : Double,
  directional_dir_x : Double,
  directional_dir_y : Double,
  directional_dir_z : Double,
  directional_color_r : Double,
  directional_color_g : Double,
  directional_color_b : Double,
  directional_illuminance : Double,
  point_intensity : Double,
  point_range : Double,
  spot_intensity : Double,
  spot_range : Double,
  camera_fov_y : Double,
  camera_near : Double,
  camera_far : Double,
  viewport_w : Double,
  viewport_h : Double,
) -> @js.Any =
  #| (
  #|   ambientR,
  #|   ambientG,
  #|   ambientB,
  #|   ambientBrightness,
  #|   directionalDirX,
  #|   directionalDirY,
  #|   directionalDirZ,
  #|   directionalColorR,
  #|   directionalColorG,
  #|   directionalColorB,
  #|   directionalIlluminance,
  #|   pointIntensity,
  #|   pointRange,
  #|   spotIntensity,
  #|   spotRange,
  #|   cameraFovY,
  #|   cameraNear,
  #|   cameraFar,
  #|   viewportW,
  #|   viewportH,
  #| ) => {
  #|   const n = (value, fallback = 0.0) => {
  #|     const v = Number(value)
  #|     return Number.isFinite(v) ? v : fallback
  #|   }
  #|   const pointEnabled = n(pointIntensity) > 0.0 && n(pointRange) > 0.0
  #|   const spotEnabled = n(spotIntensity) > 0.0 && n(spotRange) > 0.0
  #|   const out = new Uint8Array(256)
  #|   const dv = new DataView(out.buffer, out.byteOffset, out.byteLength)
  #|   const writeF32 = (offset, value) => dv.setFloat32(offset, n(value), true)
  #|   const writeU32 = (offset, value) => dv.setUint32(offset, Number(value) >>> 0, true)
  #|   const ambientScale = n(ambientBrightness)
  #|   writeF32(160, n(ambientR) * ambientScale)
  #|   writeF32(164, n(ambientG) * ambientScale)
  #|   writeF32(168, n(ambientB) * ambientScale)
  #|   writeF32(172, 1.0)
  #|   // Single-cluster fallback path for runtime compatibility with Bevy's clustered lighting shader logic.
  #|   writeU32(176, 1)
  #|   writeU32(180, 1)
  #|   writeU32(184, 1)
  #|   writeU32(188, 1)
  #|   const invViewportW = 1.0 / Math.max(n(viewportW, 1.0), 1.0)
  #|   const invViewportH = 1.0 / Math.max(n(viewportH, 1.0), 1.0)
  #|   writeF32(192, invViewportW)
  #|   writeF32(196, invViewportH)
  #|   const near = Math.max(n(cameraNear), 1.0e-4)
  #|   const far = Math.max(n(cameraFar), near + 1.0e-4)
  #|   if (n(cameraFovY) > 0.0) {
  #|     const logRatio = Math.max(Math.log(far / near), 1.0e-5)
  #|     writeF32(200, 1.0 / logRatio)
  #|     writeF32(204, Math.log(near) / logRatio)
  #|   } else {
  #|     writeF32(200, -near)
  #|     let denom = -far - -near
  #|     if (Math.abs(denom) < 1.0e-5) {
  #|       denom = denom < 0.0 ? -1.0e-5 : 1.0e-5
  #|     }
  #|     writeF32(204, 1.0 / denom)
  #|   }
  #|   const illum = n(directionalIlluminance)
  #|   if (illum > 0.0) {
  #|     writeF32(80, n(directionalColorR) * illum)
  #|     writeF32(84, n(directionalColorG) * illum)
  #|     writeF32(88, n(directionalColorB) * illum)
  #|     writeF32(92, 1.0)
  #|     writeF32(96, -n(directionalDirX))
  #|     writeF32(100, -n(directionalDirY))
  #|     writeF32(104, -n(directionalDirZ))
  #|     writeU32(208, 1)
  #|   } else {
  #|     writeU32(208, 0)
  #|   }
  #|   const pointCount = pointEnabled ? 1 : 0
  #|   writeU32(212, (0 - pointCount) >>> 0)
  #|   writeU32(216, 1)
  #|   return out
  #| }

///|
extern "js" fn mesh3d_bevy_clustered_uniform_payload_bytes(
  point_pos_x : Double,
  point_pos_y : Double,
  point_pos_z : Double,
  point_color_r : Double,
  point_color_g : Double,
  point_color_b : Double,
  point_intensity : Double,
  point_range : Double,
  spot_pos_x : Double,
  spot_pos_y : Double,
  spot_pos_z : Double,
  spot_dir_x : Double,
  spot_dir_y : Double,
  spot_dir_z : Double,
  spot_color_r : Double,
  spot_color_g : Double,
  spot_color_b : Double,
  spot_intensity : Double,
  spot_range : Double,
  spot_inner_angle : Double,
  spot_outer_angle : Double,
  point_shadow_enabled : Double,
  point_shadow_depth_bias : Double,
) -> @js.Any =
  #| (
  #|   pointPosX,
  #|   pointPosY,
  #|   pointPosZ,
  #|   pointColorR,
  #|   pointColorG,
  #|   pointColorB,
  #|   pointIntensity,
  #|   pointRange,
  #|   spotPosX,
  #|   spotPosY,
  #|   spotPosZ,
  #|   spotDirX,
  #|   spotDirY,
  #|   spotDirZ,
  #|   spotColorR,
  #|   spotColorG,
  #|   spotColorB,
  #|   spotIntensity,
  #|   spotRange,
  #|   spotInnerAngle,
  #|   spotOuterAngle,
  #|   pointShadowEnabled,
  #|   pointShadowDepthBias,
  #| ) => {
  #|   const n = (value, fallback = 0.0) => {
  #|     const v = Number(value)
  #|     return Number.isFinite(v) ? v : fallback
  #|   }
  #|   const CLUSTERED_LIGHT_STRIDE = 80
  #|   const CLUSTERED_LIGHT_CAPACITY = 204
  #|   const CLUSTERED_LIGHT_BUFFER_BYTES = CLUSTERED_LIGHT_STRIDE * CLUSTERED_LIGHT_CAPACITY
  #|   const CLUSTER_INDEX_LISTS_BYTES = 1024 * 16
  #|   const CLUSTER_OFFSETS_BYTES = 1024 * 16
  #|   const POINT_LIGHT_FLAG_SHADOWS_ENABLED = 1 << 0
  #|   const POINT_LIGHT_FLAG_SPOT_LIGHT_Y_NEGATIVE = 1 << 1
  #|   const POINT_LIGHT_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE = 1 << 3
  #|   // Bevy scales user bias by texel size and sqrt(2) before uploading.
  #|   // Use the default point-shadow map size (1024) for parity in examples:
  #|   // 0.6 * (2.0 / 1024.0) * sqrt(2.0)
  #|   const POINT_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS = 0.0016568542494923806
  #|   const MAX_U32 = 0xFFFFFFFF
  #|   const FOUR_PI = 4.0 * Math.PI
  #|   const clusteredLights = new Uint8Array(CLUSTERED_LIGHT_BUFFER_BYTES)
  #|   const clusteredLightsView = new DataView(
  #|     clusteredLights.buffer,
  #|     clusteredLights.byteOffset,
  #|     clusteredLights.byteLength,
  #|   )
  #|   const writeLightF32 = (offset, value) =>
  #|     clusteredLightsView.setFloat32(offset, n(value), true)
  #|   const writeLightU32 = (offset, value) =>
  #|     clusteredLightsView.setUint32(offset, Number(value) >>> 0, true)
  #|   const pointEnabled = n(pointIntensity) > 0.0 && n(pointRange) > 0.0
  #|   const pointShadowsEnabled = n(pointShadowEnabled) > 0.5
  #|   const spotEnabled = n(spotIntensity) > 0.0 && n(spotRange) > 0.0
  #|   let nextLightId = 0
  #|   const writeClusteredLight = (
  #|     index,
  #|     lightCustomData,
  #|     colorInverseSquareRange,
  #|     positionRadius,
  #|     flags,
  #|     shadowDepthBias,
  #|     shadowNormalBias,
  #|     spotLightTanAngle,
  #|     softShadowSize,
  #|     shadowMapNearZ,
  #|   ) => {
  #|     const base = index * CLUSTERED_LIGHT_STRIDE
  #|     if (base < 0 || base + CLUSTERED_LIGHT_STRIDE > clusteredLights.length) {
  #|       return
  #|     }
  #|     writeLightF32(base + 0, lightCustomData[0])
  #|     writeLightF32(base + 4, lightCustomData[1])
  #|     writeLightF32(base + 8, lightCustomData[2])
  #|     writeLightF32(base + 12, lightCustomData[3])
  #|     writeLightF32(base + 16, colorInverseSquareRange[0])
  #|     writeLightF32(base + 20, colorInverseSquareRange[1])
  #|     writeLightF32(base + 24, colorInverseSquareRange[2])
  #|     writeLightF32(base + 28, colorInverseSquareRange[3])
  #|     writeLightF32(base + 32, positionRadius[0])
  #|     writeLightF32(base + 36, positionRadius[1])
  #|     writeLightF32(base + 40, positionRadius[2])
  #|     writeLightF32(base + 44, positionRadius[3])
  #|     writeLightU32(base + 48, flags)
  #|     writeLightF32(base + 52, shadowDepthBias)
  #|     writeLightF32(base + 56, shadowNormalBias)
  #|     writeLightF32(base + 60, spotLightTanAngle)
  #|     writeLightF32(base + 64, softShadowSize)
  #|     writeLightF32(base + 68, shadowMapNearZ)
  #|     writeLightU32(base + 72, MAX_U32)
  #|     writeLightF32(base + 76, 0.0)
  #|   }
  #|   if (pointEnabled) {
  #|     const range = Math.max(n(pointRange), 1.0e-4)
  #|     const shadowMapNearZ = 0.1
  #|     const intensityScale = n(pointIntensity) / FOUR_PI
  #|     let flags = POINT_LIGHT_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE
  #|     if (pointShadowsEnabled) {
  #|       flags = flags | POINT_LIGHT_FLAG_SHADOWS_ENABLED
  #|     }
  #|     writeClusteredLight(
  #|       nextLightId,
  #|       [0.0, -1.0, shadowMapNearZ, 0.0],
  #|       [
  #|         n(pointColorR) * intensityScale,
  #|         n(pointColorG) * intensityScale,
  #|         n(pointColorB) * intensityScale,
  #|         1.0 / (range * range),
  #|       ],
  #|       [n(pointPosX), n(pointPosY), n(pointPosZ), 0.0],
  #|       flags,
  #|       pointShadowsEnabled ? n(pointShadowDepthBias) : 0.0,
  #|       POINT_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS,
  #|       0.0,
  #|       0.0,
  #|       shadowMapNearZ,
  #|     )
  #|     nextLightId += 1
  #|   }
  #|   if (spotEnabled) {
  #|     const range = Math.max(n(spotRange), 1.0e-4)
  #|     const intensityScale = n(spotIntensity) / FOUR_PI
  #|     const dirX0 = n(spotDirX)
  #|     const dirY0 = n(spotDirY)
  #|     const dirZ0 = n(spotDirZ)
  #|     const dirLength = Math.hypot(dirX0, dirY0, dirZ0)
  #|     const dirLengthSafe = dirLength > 1.0e-6 ? dirLength : 1.0
  #|     const dirX = dirX0 / dirLengthSafe
  #|     const dirY = dirY0 / dirLengthSafe
  #|     const dirZ = dirZ0 / dirLengthSafe
  #|     const inner = n(spotInnerAngle)
  #|     const outer = Math.max(inner, n(spotOuterAngle))
  #|     const cosOuter = Math.cos(outer)
  #|     const spotScale = 1.0 / Math.max(Math.cos(inner) - cosOuter, 1.0e-4)
  #|     const spotOffset = -cosOuter * spotScale
  #|     let flags = POINT_LIGHT_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE
  #|     if (dirY < 0.0) {
  #|       flags = flags | POINT_LIGHT_FLAG_SPOT_LIGHT_Y_NEGATIVE
  #|     }
  #|     writeClusteredLight(
  #|       nextLightId,
  #|       [dirX, dirZ, spotScale, spotOffset],
  #|       [
  #|         n(spotColorR) * intensityScale,
  #|         n(spotColorG) * intensityScale,
  #|         n(spotColorB) * intensityScale,
  #|         1.0 / (range * range),
  #|       ],
  #|       [n(spotPosX), n(spotPosY), n(spotPosZ), 0.0],
  #|       flags,
  #|       0.0,
  #|       0.0,
  #|       Math.tan(outer),
  #|       0.0,
  #|       0.1,
  #|     )
  #|   }
  #|   const clusterIndexLists = new Uint8Array(CLUSTER_INDEX_LISTS_BYTES)
  #|   const clusterIndexListsView = new DataView(
  #|     clusterIndexLists.buffer,
  #|     clusterIndexLists.byteOffset,
  #|     clusterIndexLists.byteLength,
  #|   )
  #|   const pointCount = pointEnabled ? 1 : 0
  #|   const spotCount = spotEnabled ? 1 : 0
  #|   if (pointCount + spotCount > 0) {
  #|     let packed = 0
  #|     if (pointCount > 0) {
  #|       packed = packed | 0
  #|     }
  #|     if (spotCount > 0) {
  #|       const spotLightId = pointCount
  #|       packed = packed | ((spotLightId & 0xFF) << 8)
  #|     }
  #|     clusterIndexListsView.setUint32(0, packed >>> 0, true)
  #|   }
  #|   const clusterOffsetsAndCounts = new Uint8Array(CLUSTER_OFFSETS_BYTES)
  #|   const clusterOffsetsView = new DataView(
  #|     clusterOffsetsAndCounts.buffer,
  #|     clusterOffsetsAndCounts.byteOffset,
  #|     clusterOffsetsAndCounts.byteLength,
  #|   )
  #|   // [offset:14 bits | point_count:9 bits | spot_count:9 bits], offset is 0 for single-cluster fallback.
  #|   const rawOffsetsAndCounts = ((pointCount & 0x1FF) << 9) | (spotCount & 0x1FF)
  #|   clusterOffsetsView.setUint32(0, rawOffsetsAndCounts >>> 0, true)
  #|   return {
  #|     clusteredLights,
  #|     clusterIndexLists,
  #|     clusterOffsetsAndCounts,
  #|   }
  #| }

///|
extern "js" fn mesh3d_bevy_mesh_uniform_bytes(
  x : Double,
  y : Double,
  z : Double,
  rotation_x : Double,
  rotation_y : Double,
  rotation_z : Double,
  rotation_w : Double,
  scale_x : Double,
  scale_y : Double,
  scale_z : Double,
  previous_x : Double,
  previous_y : Double,
  previous_z : Double,
  previous_rotation_x : Double,
  previous_rotation_y : Double,
  previous_rotation_z : Double,
  previous_rotation_w : Double,
  previous_scale_x : Double,
  previous_scale_y : Double,
  previous_scale_z : Double,
) -> @js.Any =
  #| (
  #|   x,
  #|   y,
  #|   z,
  #|   rotationX,
  #|   rotationY,
  #|   rotationZ,
  #|   rotationW,
  #|   scaleX,
  #|   scaleY,
  #|   scaleZ,
  #|   previousX,
  #|   previousY,
  #|   previousZ,
  #|   previousRotationX,
  #|   previousRotationY,
  #|   previousRotationZ,
  #|   previousRotationW,
  #|   previousScaleX,
  #|   previousScaleY,
  #|   previousScaleZ,
  #| ) => {
  #|   const n = (value, fallback = 0.0) => {
  #|     const v = Number(value)
  #|     return Number.isFinite(v) ? v : fallback
  #|   }
  #|   const quatNormalize4 = (qx, qy, qz, qw) => {
  #|     const x0 = n(qx)
  #|     const y0 = n(qy)
  #|     const z0 = n(qz)
  #|     const w0 = n(qw)
  #|     const norm2 = Math.max(x0 * x0 + y0 * y0 + z0 * z0 + w0 * w0, 1.0e-8)
  #|     const inv = 1.0 / Math.sqrt(norm2)
  #|     return [x0 * inv, y0 * inv, z0 * inv, w0 * inv]
  #|   }
  #|   const quatToRowMat3 = (qx, qy, qz, qw) => {
  #|     const [x, y, z, w] = quatNormalize4(qx, qy, qz, qw)
  #|     return [
  #|       1.0 - 2.0 * (y * y + z * z),
  #|       2.0 * (x * y - w * z),
  #|       2.0 * (x * z + w * y),
  #|       2.0 * (x * y + w * z),
  #|       1.0 - 2.0 * (x * x + z * z),
  #|       2.0 * (y * z - w * x),
  #|       2.0 * (x * z - w * y),
  #|       2.0 * (y * z + w * x),
  #|       1.0 - 2.0 * (x * x + y * y),
  #|     ]
  #|   }
  #|   const buildModelRows = (px, py, pz, qx, qy, qz, qw, sx, sy, sz) => {
  #|     const r = quatToRowMat3(qx, qy, qz, qw)
  #|     return [
  #|       r[0] * n(sx, 1.0), r[1] * n(sy, 1.0), r[2] * n(sz, 1.0), n(px),
  #|       r[3] * n(sx, 1.0), r[4] * n(sy, 1.0), r[5] * n(sz, 1.0), n(py),
  #|       r[6] * n(sx, 1.0), r[7] * n(sy, 1.0), r[8] * n(sz, 1.0), n(pz),
  #|     ]
  #|   }
  #|   const safeReciprocal = (value) => {
  #|     const v = n(value, 1.0)
  #|     return Math.abs(v) > 1.0e-8 ? 1.0 / v : 0.0
  #|   }
  #|   const buildLocalFromWorldTransposeCols = (qx, qy, qz, qw, sx, sy, sz) => {
  #|     const r = quatToRowMat3(qx, qy, qz, qw)
  #|     const invSx = safeReciprocal(sx)
  #|     const invSy = safeReciprocal(sy)
  #|     const invSz = safeReciprocal(sz)
  #|     const m00 = r[0] * invSx
  #|     const m01 = r[1] * invSy
  #|     const m02 = r[2] * invSz
  #|     const m10 = r[3] * invSx
  #|     const m11 = r[4] * invSy
  #|     const m12 = r[5] * invSz
  #|     const m20 = r[6] * invSx
  #|     const m21 = r[7] * invSy
  #|     const m22 = r[8] * invSz
  #|     return [
  #|       m00, m10, m20,
  #|       m01, m11, m21,
  #|       m02, m12, m22,
  #|     ]
  #|   }
  #|   const out = new Uint8Array(192)
  #|   const dv = new DataView(out.buffer, out.byteOffset, out.byteLength)
  #|   const writeF32 = (offset, value) => dv.setFloat32(offset, n(value), true)
  #|   const writeU32 = (offset, value) => dv.setUint32(offset, Number(value) >>> 0, true)
  #|   const writeF32s = (offset, values) => {
  #|     for (let i = 0; i < values.length; i += 1) {
  #|       writeF32(offset + i * 4, values[i])
  #|     }
  #|   }
  #|   const worldRows = buildModelRows(
  #|     x,
  #|     y,
  #|     z,
  #|     rotationX,
  #|     rotationY,
  #|     rotationZ,
  #|     rotationW,
  #|     scaleX,
  #|     scaleY,
  #|     scaleZ,
  #|   )
  #|   const previousRows = buildModelRows(
  #|     previousX,
  #|     previousY,
  #|     previousZ,
  #|     previousRotationX,
  #|     previousRotationY,
  #|     previousRotationZ,
  #|     previousRotationW,
  #|     previousScaleX,
  #|     previousScaleY,
  #|     previousScaleZ,
  #|   )
  #|   writeF32s(0, worldRows)
  #|   writeF32s(48, previousRows)
  #|   const localFromWorldTransposeCols = buildLocalFromWorldTransposeCols(
  #|     rotationX,
  #|     rotationY,
  #|     rotationZ,
  #|     rotationW,
  #|     scaleX,
  #|     scaleY,
  #|     scaleZ,
  #|   )
  #|   writeF32s(96, [
  #|     localFromWorldTransposeCols[0],
  #|     localFromWorldTransposeCols[1],
  #|     localFromWorldTransposeCols[2],
  #|     localFromWorldTransposeCols[3],
  #|     localFromWorldTransposeCols[4],
  #|     localFromWorldTransposeCols[5],
  #|     localFromWorldTransposeCols[6],
  #|     localFromWorldTransposeCols[7],
  #|   ])
  #|   writeF32(128, localFromWorldTransposeCols[8])
  #|   // Match Bevy mesh flags defaults:
  #|   // - LOD index = u16::MAX (no LOD)
  #|   // - SHADOW_RECEIVER
  #|   // - SIGN_DETERMINANT_MODEL_3X3 when determinant is positive.
  #|   let flags = 0x0000FFFF | (1 << 29)
  #|   const determinantSign = n(scaleX, 1.0) * n(scaleY, 1.0) * n(scaleZ, 1.0)
  #|   if (determinantSign >= 0.0) {
  #|     flags = flags | (1 << 31)
  #|   }
  #|   writeU32(132, flags >>> 0)
  #|   writeU32(136, 0) // lightmap_uv_rect.x
  #|   writeU32(140, 0) // lightmap_uv_rect.y
  #|   writeU32(144, 0) // first_vertex_index
  #|   writeU32(148, 0) // current_skin_index
  #|   writeU32(152, 0) // material_and_lightmap_bind_group_slot
  #|   writeU32(156, 0) // tag
  #|   writeU32(160, 0) // pad
  #|   return out
  #| }

///|
extern "js" fn mesh3d_bevy_material_uniform_bytes(
  color_r : Double,
  color_g : Double,
  color_b : Double,
  color_a : Double,
  emissive_r : Double,
  emissive_g : Double,
  emissive_b : Double,
  reflectance : Double,
  roughness : Double,
  metallic : Double,
  diffuse_transmission : Double,
  specular_transmission : Double,
  thickness : Double,
  ior : Double,
  anisotropy_strength : Double,
  unlit : Double,
  parallax_depth_scale : Double,
  max_parallax_layer_count : Double,
  max_relief_mapping_search_steps : Double,
) -> @js.Any =
  #| (
  #|   colorR,
  #|   colorG,
  #|   colorB,
  #|   colorA,
  #|   emissiveR,
  #|   emissiveG,
  #|   emissiveB,
  #|   reflectance,
  #|   roughness,
  #|   metallic,
  #|   diffuseTransmission,
  #|   specularTransmission,
  #|   thickness,
  #|   ior,
  #|   anisotropyStrength,
  #|   unlit,
  #|   parallaxDepthScale,
  #|   maxParallaxLayerCount,
  #|   maxReliefMappingSearchSteps,
  #| ) => {
  #|   const n = (value, fallback = 0.0) => {
  #|     const v = Number(value)
  #|     return Number.isFinite(v) ? v : fallback
  #|   }
  #|   const out = new Uint8Array(256)
  #|   const dv = new DataView(out.buffer, out.byteOffset, out.byteLength)
  #|   const writeF32 = (offset, value) => dv.setFloat32(offset, n(value), true)
  #|   const writeU32 = (offset, value) => dv.setUint32(offset, Number(value) >>> 0, true)
  #|   const writeF32s = (offset, values) => {
  #|     for (let i = 0; i < values.length; i += 1) {
  #|       writeF32(offset + i * 4, values[i])
  #|     }
  #|   }
  #|   writeF32s(0, [n(colorR), n(colorG), n(colorB), n(colorA, 1.0)])
  #|   writeF32s(16, [n(emissiveR), n(emissiveG), n(emissiveB), 1.0])
  #|   writeF32s(32, [1.0, 1.0, 1.0, 1.0])
  #|   writeF32s(48, [
  #|     1.0, 0.0, 0.0, 0.0,
  #|     0.0, 1.0, 0.0, 0.0,
  #|     0.0, 0.0, 1.0, 0.0,
  #|   ])
  #|   const r = n(reflectance, 0.5)
  #|   writeF32s(96, [r, r, r, n(roughness, 1.0)])
  #|   writeF32(112, n(metallic))
  #|   writeF32(116, n(diffuseTransmission))
  #|   writeF32(120, n(specularTransmission))
  #|   writeF32(124, n(thickness))
  #|   writeF32(128, n(ior, 1.5))
  #|   writeF32(132, 1.0)
  #|   writeF32(144, n(anisotropyStrength))
  #|   const flags = n(unlit) > 0.5 ? (1 << 5) : 0
  #|   writeU32(156, flags)
  #|   writeF32(160, 0.5)
  #|   writeF32(164, n(parallaxDepthScale))
  #|   writeF32(168, n(maxParallaxLayerCount))
  #|   writeF32(172, 1.0)
  #|   writeU32(176, Math.max(0, Math.floor(n(maxReliefMappingSearchSteps))) >>> 0)
  #|   writeU32(180, 1)
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
extern "js" fn write_texture_region_mip(
  queue : @js.Any,
  texture : @js.Any,
  data : @js.Any,
  width : Int,
  height : Int,
  x : Int,
  y : Int,
  mip_level : Int,
) -> Unit =
  #| (queue, texture, data, width, height, x, y, mipLevel) => {
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
  #|     { texture, mipLevel, origin: { x, y } },
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
  #|     // Stacked-2D upload path requires a stable slice count across mips.
  #|     // True 3D KTX2 textures can reduce depth per mip (slice count shrinks),
  #|     // which can't be represented by a regular 2D mip chain. In that case,
  #|     // keep mip 0 only; that's sufficient for tonemapping LUT usage.
  #|     if (mipSliceCount !== sliceCount) {
  #|       if (mip === 0) {
  #|         return null
  #|       }
  #|       break
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
