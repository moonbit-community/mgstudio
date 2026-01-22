class $PanicError extends Error {}
function $panic() {
  throw new $PanicError();
}
function $bound_check(arr, index) {
  if (index < 0 || index >= arr.length) throw new Error("Index out of bounds");
}
function $compare_int(a, b) {
  return (a >= b) - (a <= b);
}
const moonbitlang$core$builtin$$random_seed = () => {
  if (globalThis.crypto?.getRandomValues) {
    const array = new Uint32Array(1);
    globalThis.crypto.getRandomValues(array);
    return array[0] | 0; // Convert to signed 32
  } else {
    return Math.floor(Math.random() * 0x100000000) | 0; // Fallback to Math.random
  }
};
function Result$Err$0$(param0) {
  this._0 = param0;
}
Result$Err$0$.prototype.$tag = 0;
function Result$Ok$0$(param0) {
  this._0 = param0;
}
Result$Ok$0$.prototype.$tag = 1;
function Error$moonbitlang$47$core$47$builtin$46$Failure$46$Failure(param0) {
  this._0 = param0;
}
Error$moonbitlang$47$core$47$builtin$46$Failure$46$Failure.prototype.$tag = 2;
const Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$IndexOutOfBounds = { $tag: 1 };
const Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$InvalidIndex = { $tag: 0 };
const moonbitlang$core$builtin$$int_to_string_js = (x, radix) => {
  return x.toString(radix);
};
function Result$Err$1$(param0) {
  this._0 = param0;
}
Result$Err$1$.prototype.$tag = 0;
function Result$Ok$1$(param0) {
  this._0 = param0;
}
Result$Ok$1$.prototype.$tag = 1;
const moonbitlang$core$builtin$$JSArray$push = (arr, val) => { arr.push(val); };
function $make_array_len_and_init(a, b) {
  const arr = new Array(a);
  arr.fill(b);
  return arr;
}
const moonbitlang$core$builtin$$JSArray$set_length = (arr, len) => { arr.length = len; };
const mizchi$js$core$$Any$_get = (obj, key) => obj[key];
const mizchi$js$core$$ffi_new_promise = (executor) => new Promise(executor);
function $64$mizchi$47$js$47$core$46$Promise$58$58$new$46$lambda$46$lambda$47$317$46$State$_try$47$229$2$(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
$64$mizchi$47$js$47$core$46$Promise$58$58$new$46$lambda$46$lambda$47$317$46$State$_try$47$229$2$.prototype.$tag = 0;
const mizchi$js$core$$Any$_call = (obj, key, args) => obj[key](...args);
function Result$Err$3$(param0) {
  this._0 = param0;
}
Result$Err$3$.prototype.$tag = 0;
function Result$Ok$3$(param0) {
  this._0 = param0;
}
Result$Ok$3$.prototype.$tag = 1;
const Option$None$4$ = { $tag: 0 };
function Option$Some$4$(param0) {
  this._0 = param0;
}
Option$Some$4$.prototype.$tag = 1;
function Result$Err$5$(param0) {
  this._0 = param0;
}
Result$Err$5$.prototype.$tag = 0;
function Result$Ok$5$(param0) {
  this._0 = param0;
}
Result$Ok$5$.prototype.$tag = 1;
function Result$Err$6$(param0) {
  this._0 = param0;
}
Result$Err$6$.prototype.$tag = 0;
function Result$Ok$6$(param0) {
  this._0 = param0;
}
Result$Ok$6$.prototype.$tag = 1;
function Result$Err$7$(param0) {
  this._0 = param0;
}
Result$Err$7$.prototype.$tag = 0;
function Result$Ok$7$(param0) {
  this._0 = param0;
}
Result$Ok$7$.prototype.$tag = 1;
const mizchi$js$core$$is_nullish = (v) => v == null;
const mizchi$js$core$$Any$_set = (obj, key, value) => { obj[key] = value };
const mizchi$js$core$$new_object = () => ({});
const mizchi$js$core$$from_entries = (entries) => Object.fromEntries(entries.map(e => [e._0, e._1]));
const mizchi$js$core$$array_from = (v) => Array.from(v);
const mizchi$js$core$$log = (message) => { console.log(message); };
const Option$None$8$ = { $tag: 0 };
function Option$Some$8$(param0) {
  this._0 = param0;
}
Option$Some$8$.prototype.$tag = 1;
const Option$None$9$ = { $tag: 0 };
function Option$Some$9$(param0) {
  this._0 = param0;
}
Option$Some$9$.prototype.$tag = 1;
const mizchi$js$builtins$arraybuffer$$ffi_uint8array_from_buffer = (buf, offset, len) => len !== undefined ? new Uint8Array(buf, offset, len) : new Uint8Array(buf, offset);
const mizchi$js$builtins$global$$undefined = () => undefined;
const Milky2018$mgstudio$45$runtime$45$web$webgpu$$preferred_canvas_format_raw = () => navigator.gpu.getPreferredCanvasFormat();
const Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_raw = () => GPUTextureUsage;
const Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_usage_raw = () => GPUBufferUsage;
const Milky2018$mgstudio$45$runtime$45$web$webgpu$$bit_or = (a, b) => a | b;
const Milky2018$mgstudio$45$runtime$45$web$webgpu$$canvas_get_context = (canvas) => canvas.getContext("webgpu");
const $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$TextureFormat$Rgba8Unorm = { $tag: 0 };
const $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$TextureFormat$Bgra8Unorm = { $tag: 1 };
function $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$TextureFormat$Other(param0) {
  this._0 = param0;
}
$64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$TextureFormat$Other.prototype.$tag = 2;
function $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$BindGroupResource$Sampler(param0) {
  this._0 = param0;
}
$64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$BindGroupResource$Sampler.prototype.$tag = 0;
function $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$BindGroupResource$TextureView(param0) {
  this._0 = param0;
}
$64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$BindGroupResource$TextureView.prototype.$tag = 1;
function $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$BindGroupResource$Buffer(param0) {
  this._0 = param0;
}
$64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$BindGroupResource$Buffer.prototype.$tag = 2;
const mizchi$js$web$http$$Response$clone = (v) => v.clone();
const mizchi$js$web$http$$ffi_fetch = (url, init) => fetch(url, init);
const mizchi$js$browser$dom$$window = () => window;
const mizchi$js$browser$dom$$document = () => document;
const mizchi$js$browser$dom$$Document$createElement = (self, tag) => self.createElement(tag);
const Milky2018$mgstudio$45$runtime$45$web$$object_keys = (obj) => Object.keys(obj);
const Milky2018$mgstudio$45$runtime$45$web$$object_assign = (target, source) => Object.assign(target, source);
const Milky2018$mgstudio$45$runtime$45$web$$call0_any = (func) => func();
const Milky2018$mgstudio$45$runtime$45$web$$is_function = (value) => typeof value === "function";
const Milky2018$mgstudio$45$runtime$45$web$$is_nullish = (value) => value == null;
const Milky2018$mgstudio$45$runtime$45$web$$char_from_code = (code) => String.fromCharCode(code);
const Milky2018$mgstudio$45$runtime$45$web$$has_webgpu = () => !!navigator.gpu;
const Milky2018$mgstudio$45$runtime$45$web$$reload_page = () => window.location.reload();
const Milky2018$mgstudio$45$runtime$45$web$$reload_with_run_target = (target) => {
   const url = new URL(window.location.href)
   url.searchParams.set("run", target)
   window.location.href = url.toString()
 };
const Milky2018$mgstudio$45$runtime$45$web$$get_run_target_from_url = () => {
   const params = new URLSearchParams(window.location.search)
   const target = params.get("run")
   return target ? target.trim() : ""
 };
const Milky2018$mgstudio$45$runtime$45$web$$response_array_buffer = (response) => response.arrayBuffer();
const Milky2018$mgstudio$45$runtime$45$web$$instantiate_streaming = async (response, imports, options) =>
   await WebAssembly.instantiateStreaming(response, imports, options);
const Milky2018$mgstudio$45$runtime$45$web$$instantiate_bytes_with_options = async (bytes, imports, options) =>
   await WebAssembly.instantiate(bytes, imports, options);
const Milky2018$mgstudio$45$runtime$45$web$$join_strings = (values, sep) => values.join(sep);
const Milky2018$mgstudio$45$runtime$45$web$$strip_run_prefix = (value) => value.startsWith("run_") ? value.slice(4) : value;
const Option$None$10$ = { $tag: 0 };
function Option$Some$10$(param0) {
  this._0 = param0;
}
Option$Some$10$.prototype.$tag = 1;
function Result$Err$11$(param0) {
  this._0 = param0;
}
Result$Err$11$.prototype.$tag = 0;
function Result$Ok$11$(param0) {
  this._0 = param0;
}
Result$Ok$11$.prototype.$tag = 1;
const Option$None$12$ = { $tag: 0 };
function Option$Some$12$(param0) {
  this._0 = param0;
}
Option$Some$12$.prototype.$tag = 1;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_0(param0) {
  this._0 = param0;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_0.prototype.$tag = 0;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_1(param0) {
  this._0 = param0;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_1.prototype.$tag = 1;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_2(param0, param1, param2, param3, param4) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_2.prototype.$tag = 2;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$_try$47$663(param0, param1, param2, param3, param4, param5) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
  this._5 = param5;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$_try$47$663.prototype.$tag = 3;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_4(param0) {
  this._0 = param0;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_4.prototype.$tag = 4;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_5(param0, param1, param2, param3) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_5.prototype.$tag = 5;
const Milky2018$mgstudio$45$runtime$45$web$$any_to_string = (value) => String(value);
const Milky2018$mgstudio$45$runtime$45$web$$js_undefined = () => undefined;
const Milky2018$mgstudio$45$runtime$45$web$$number_or = (value, fallback) => {
   const num = Number(value)
   return Number.isFinite(num) ? num : fallback
 };
const Milky2018$mgstudio$45$runtime$45$web$$create_checkerboard_data = (size) => {
   const data = new Uint8Array(size * size * 4)
   for (let y = 0; y < size; y += 1) {
     for (let x = 0; x < size; x += 1) {
       const offset = (y * size + x) * 4
       const checker = ((x >> 3) ^ (y >> 3)) & 1
       const base = checker ? 220 : 40
       data[offset] = base
       data[offset + 1] = 120
       data[offset + 2] = 255 - base
       data[offset + 3] = 255
     }
   }
   return data
 };
const Option$None$13$ = { $tag: 0 };
function Option$Some$13$(param0) {
  this._0 = param0;
}
Option$Some$13$.prototype.$tag = 1;
const Milky2018$mgstudio$45$runtime$45$web$$create_sprite_vertices = () => new Float32Array([
   -64.0, 64.0, 0.0, 0.0,
   -64.0, -64.0, 0.0, 1.0,
   64.0, -64.0, 1.0, 1.0,
   -64.0, 64.0, 0.0, 0.0,
   64.0, -64.0, 1.0, 1.0,
   64.0, 64.0, 1.0, 0.0,
 ]);
const Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish = (value) => value == null;
const Milky2018$mgstudio$45$runtime$45$web$$map_get = (map, key) => map.get(key);
const Milky2018$mgstudio$45$runtime$45$web$$js_null = () => null;
const Milky2018$mgstudio$45$runtime$45$web$$map_set = (map, key, value) => map.set(key, value);
const Milky2018$mgstudio$45$runtime$45$web$$write_texture = (queue, texture, data, bytesPerRow, width, height) => {
   queue.writeTexture({ texture }, data, { bytesPerRow }, [width, height, 1])
 };
const Option$None$14$ = { $tag: 0 };
function Option$Some$14$(param0) {
  this._0 = param0;
}
Option$Some$14$.prototype.$tag = 1;
const Option$None$15$ = { $tag: 0 };
function Option$Some$15$(param0) {
  this._0 = param0;
}
Option$Some$15$.prototype.$tag = 1;
const Milky2018$mgstudio$45$runtime$45$web$$get_canvas_pixel_size = (canvas) => {
   const dpr = window.devicePixelRatio || 1
   let width = canvas.clientWidth
   let height = canvas.clientHeight
   if (!width || !height) {
     const rect = canvas.getBoundingClientRect ? canvas.getBoundingClientRect() : null
     if (rect) {
       width = rect.width || width
       height = rect.height || height
     }
   }
   if (!width || !height) {
     width = window.innerWidth || canvas.width || 1
     height = window.innerHeight || canvas.height || 1
   }
   width = Math.max(1, Math.floor(width * dpr))
   height = Math.max(1, Math.floor(height * dpr))
   return { width, height }
 };
const Milky2018$mgstudio$45$runtime$45$web$$get_device_pixel_ratio = () => window.devicePixelRatio || 1;
const Option$None$16$ = { $tag: 0 };
function Option$Some$16$(param0) {
  this._0 = param0;
}
Option$Some$16$.prototype.$tag = 1;
const Option$None$17$ = { $tag: 0 };
function Option$Some$17$(param0) {
  this._0 = param0;
}
Option$Some$17$.prototype.$tag = 1;
const Milky2018$mgstudio$45$runtime$45$web$$new_array = () => [];
const Option$None$18$ = { $tag: 0 };
function Option$Some$18$(param0) {
  this._0 = param0;
}
Option$Some$18$.prototype.$tag = 1;
const Option$None$19$ = { $tag: 0 };
function Option$Some$19$(param0) {
  this._0 = param0;
}
Option$Some$19$.prototype.$tag = 1;
const Milky2018$mgstudio$45$runtime$45$web$$add_event_listener = (target, eventName, handler) => target.addEventListener(eventName, handler);
const Milky2018$mgstudio$45$runtime$45$web$$prevent_default = (event) => event.preventDefault();
const Milky2018$mgstudio$45$runtime$45$web$$set_add = (set, value) => set.add(value);
const Milky2018$mgstudio$45$runtime$45$web$$set_delete = (set, value) => set.delete(value);
const Milky2018$mgstudio$45$runtime$45$web$$set_has = (set, value) => set.has(value);
const Milky2018$mgstudio$45$runtime$45$web$$get_bounding_rect = (canvas) => canvas.getBoundingClientRect();
const Milky2018$mgstudio$45$runtime$45$web$$coerce_asset_path = (path) => {
   if (path == null) {
     throw new Error("Asset path is required")
   }
   let current = path
   for (let i = 0; i < 4; i += 1) {
     if (typeof current === "string") {
       return current
     }
     if (typeof current === "number" || typeof current === "bigint" || typeof current === "boolean") {
       return `${current}`
     }
     if (typeof current === "object") {
       if (typeof current.value === "string") {
         return current.value
       }
       if (typeof current.string === "string") {
         return current.string
       }
       if (typeof current.toString === "function") {
         try {
           current = current.toString()
           continue
         } catch {
         }
       }
       if (typeof current.valueOf === "function") {
         try {
           current = current.valueOf()
           continue
         } catch {
         }
       }
     }
     break
   }
   throw new Error(`Unsupported asset path type: ${typeof path}`)
 };
const Milky2018$mgstudio$45$runtime$45$web$$console_error = (value) => console.error(value);
const Milky2018$mgstudio$45$runtime$45$web$$create_capsule_mesh_data = (radius, halfLength, segments) => {
   const r = Number(radius) || 0.5
   const half = Number(halfLength) || 0.5
   const seg = Math.max(6, Math.floor(Number(segments) || 16))
   const points = []
   for (let i = 0; i <= seg; i += 1) {
     const angle = Math.PI - (i / seg) * Math.PI
     points.push([Math.cos(angle) * r, half + Math.sin(angle) * r])
   }
   for (let i = 0; i <= seg; i += 1) {
     const angle = -(i / seg) * Math.PI
     points.push([Math.cos(angle) * r, -half + Math.sin(angle) * r])
   }
   const vertexData = []
   const cx = 0
   const cy = 0
   const count = points.length
   for (let i = 0; i < count; i += 1) {
     const p0 = points[i]
     const p1 = points[(i + 1) % count]
     vertexData.push(cx, cy, p0[0], p0[1], p1[0], p1[1])
   }
   return new Float32Array(vertexData)
 };
const Milky2018$mgstudio$45$runtime$45$web$$create_rectangle_mesh_data = (width, height) => {
   const w = Number(width) || 1
   const h = Number(height) || 1
   const halfW = w / 2
   const halfH = h / 2
   return new Float32Array([
     -halfW, -halfH,
     halfW, -halfH,
     halfW, halfH,
     -halfW, -halfH,
     halfW, halfH,
     -halfW, halfH,
   ])
 };
const Milky2018$mgstudio$45$runtime$45$web$$dispatch_asset_error = (message) => {
   window.dispatchEvent(new CustomEvent("mgstudio-asset-error", { detail: message }))
 };
const Milky2018$mgstudio$45$runtime$45$web$$build_gizmo_vertices = (data, camX, camY, camRotation, camScale, width, height, lineWidth) => {
   let length = 0
   let getter = null
   if (Array.isArray(data) || ArrayBuffer.isView(data)) {
     length = data.length
     getter = (index) => data[index]
   } else if (data && typeof data.get === "function") {
     if (typeof data.length === "function") {
       length = Number(data.length())
     } else {
       length = Number(data.length)
     }
     getter = (index) => data.get(index)
   }
   if (!getter || !Number.isFinite(length) || length <= 0) {
     return new Float32Array(0)
   }
   const w = Number(width)
   const h = Number(height)
   if (!Number.isFinite(w) || !Number.isFinite(h) || w <= 0 || h <= 0) {
     return new Float32Array(0)
   }
   const safeScale = Number.isFinite(camScale) && camScale !== 0 ? camScale : 1
   const scaleX = 2 / w / safeScale
   const scaleY = 2 / h / safeScale
   const cos = Math.cos(-camRotation)
   const sin = Math.sin(-camRotation)
   const halfWidth = w * 0.5
   const halfHeight = h * 0.5
   const defaultWidth = Number.isFinite(lineWidth) && lineWidth > 0 ? lineWidth : 2
   const vertices = []
   const pushQuad = (sx, sy, ex, ey, sr, sg, sb, sa, er, eg, eb, ea, offX, offY) => {
     const p1x = sx + offX
     const p1y = sy + offY
     const p2x = sx - offX
     const p2y = sy - offY
     const p3x = ex - offX
     const p3y = ey - offY
     const p4x = ex + offX
     const p4y = ey + offY
     vertices.push(
       p1x, p1y, sr, sg, sb, sa,
       p2x, p2y, sr, sg, sb, sa,
       p3x, p3y, er, eg, eb, ea,
       p1x, p1y, sr, sg, sb, sa,
       p3x, p3y, er, eg, eb, ea,
       p4x, p4y, er, eg, eb, ea,
     )
   }
   for (let i = 0; i + 15 < length; i += 16) {
     const sx = Number(getter(i))
     const sy = Number(getter(i + 1))
     const sr = Number(getter(i + 2))
     const sg = Number(getter(i + 3))
     const sb = Number(getter(i + 4))
     const sa = Number(getter(i + 5))
     const ex = Number(getter(i + 6))
     const ey = Number(getter(i + 7))
     const er = Number(getter(i + 8))
     const eg = Number(getter(i + 9))
     const eb = Number(getter(i + 10))
     const ea = Number(getter(i + 11))
     const width = Number(getter(i + 12))
     const styleKind = Number(getter(i + 13))
     const gapScale = Number(getter(i + 14))
     const lineScale = Number(getter(i + 15))
     const thickness = Number.isFinite(width) && width > 0 ? width : defaultWidth
     const halfLine = thickness * 0.5
     const relSX = sx - camX
     const relSY = sy - camY
     const relEX = ex - camX
     const relEY = ey - camY
     const viewSX = relSX * cos - relSY * sin
     const viewSY = relSX * sin + relSY * cos
     const viewEX = relEX * cos - relEY * sin
     const viewEY = relEX * sin + relEY * cos
     const ndcSX = viewSX * scaleX
     const ndcSY = viewSY * scaleY
     const ndcEX = viewEX * scaleX
     const ndcEY = viewEY * scaleY
     const screenSX = ndcSX * halfWidth
     const screenSY = ndcSY * halfHeight
     const screenEX = ndcEX * halfWidth
     const screenEY = ndcEY * halfHeight
     const dx = screenEX - screenSX
     const dy = screenEY - screenSY
     const len = Math.hypot(dx, dy)
     if (!Number.isFinite(len) || len <= 0) {
       continue
     }
     const invLen = 1 / len
     const ux = dx * invLen
     const uy = dy * invLen
     const nx = -uy * halfLine
     const ny = ux * halfLine
     const offX = nx / halfWidth
     const offY = ny / halfHeight
     let dashLen = len
     let gapLen = 0
     if (styleKind === 1) {
       dashLen = thickness
       gapLen = thickness
     } else if (styleKind === 2) {
       const safeGap = Number.isFinite(gapScale) && gapScale > 0 ? gapScale : 1
       const safeLine = Number.isFinite(lineScale) && lineScale > 0 ? lineScale : 1
       dashLen = thickness * safeLine
       gapLen = thickness * safeGap
     }
     const step = dashLen + gapLen
     if (!Number.isFinite(step) || step <= 0 || dashLen >= len) {
       pushQuad(ndcSX, ndcSY, ndcEX, ndcEY, sr, sg, sb, sa, er, eg, eb, ea, offX, offY)
       continue
     }
     const dr = er - sr
     const dg = eg - sg
     const db = eb - sb
     const da = ea - sa
     let pos = 0
     while (pos < len) {
       const segLen = Math.min(dashLen, len - pos)
       if (segLen > 0) {
         const t0 = pos * invLen
         const t1 = (pos + segLen) * invLen
         const segSX = screenSX + ux * pos
         const segSY = screenSY + uy * pos
         const segEX = screenSX + ux * (pos + segLen)
         const segEY = screenSY + uy * (pos + segLen)
         const segNdcSX = segSX / halfWidth
         const segNdcSY = segSY / halfHeight
         const segNdcEX = segEX / halfWidth
         const segNdcEY = segEY / halfHeight
         const segSr = sr + dr * t0
         const segSg = sg + dg * t0
         const segSb = sb + db * t0
         const segSa = sa + da * t0
         const segEr = sr + dr * t1
         const segEg = sg + dg * t1
         const segEb = sb + db * t1
         const segEa = sa + da * t1
         pushQuad(
           segNdcSX,
           segNdcSY,
           segNdcEX,
           segNdcEY,
           segSr,
           segSg,
           segSb,
           segSa,
           segEr,
           segEg,
           segEb,
           segEa,
           offX,
           offY,
         )
       }
       pos += step
     }
   }
   return new Float32Array(vertices)
 };
const Option$None$20$ = { $tag: 0 };
function Option$Some$20$(param0) {
  this._0 = param0;
}
Option$Some$20$.prototype.$tag = 1;
const Milky2018$mgstudio$45$runtime$45$web$$math_cos = (value) => Math.cos(value);
const Milky2018$mgstudio$45$runtime$45$web$$math_sin = (value) => Math.sin(value);
const Milky2018$mgstudio$45$runtime$45$web$$float32array_from_array = (values) => new Float32Array(values);
const Milky2018$mgstudio$45$runtime$45$web$$append_canvas_to_body = (canvas) => document.body.appendChild(canvas);
const Milky2018$mgstudio$45$runtime$45$web$$create_canvas_element = () => document.createElement("canvas");
const Milky2018$mgstudio$45$runtime$45$web$$host_call0_any = (func) => func();
const Milky2018$mgstudio$45$runtime$45$web$$set_clear = (set) => set.clear();
const Milky2018$mgstudio$45$runtime$45$web$$copy_external_image_to_texture = (queue, image, texture, width, height) => {
   queue.copyExternalImageToTexture({ source: image }, { texture }, [width, height])
 };
const Milky2018$mgstudio$45$runtime$45$web$$create_image_bitmap = (blob) => createImageBitmap(blob, { premultiplyAlpha: "none", colorSpaceConversion: "none" });
const Milky2018$mgstudio$45$runtime$45$web$$is_external_asset_url = (text) => /^(https?:)?\/\//.test(text) || text.startsWith("data:");
const Milky2018$mgstudio$45$runtime$45$web$$strip_leading_slashes = (text) => text.replace(/^\/+/, "");
function Result$Err$21$(param0) {
  this._0 = param0;
}
Result$Err$21$.prototype.$tag = 0;
function Result$Ok$21$(param0) {
  this._0 = param0;
}
Result$Ok$21$.prototype.$tag = 1;
const Milky2018$mgstudio$45$runtime$45$web$$response_blob = (response) => response.blob();
function Result$Err$22$(param0) {
  this._0 = param0;
}
Result$Err$22$.prototype.$tag = 0;
function Result$Ok$22$(param0) {
  this._0 = param0;
}
Result$Ok$22$.prototype.$tag = 1;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_texture_from_path$46$State$State_0(param0, param1, param2, param3) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_texture_from_path$46$State$State_0.prototype.$tag = 0;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_texture_from_path$46$State$State_1(param0, param1, param2, param3, param4, param5) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
  this._5 = param5;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_texture_from_path$46$State$State_1.prototype.$tag = 1;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_texture_from_path$46$State$State_2(param0, param1, param2, param3, param4, param5, param6) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
  this._5 = param5;
  this._6 = param6;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_texture_from_path$46$State$State_2.prototype.$tag = 2;
const Milky2018$mgstudio$45$runtime$45$web$$response_text = (response) => response.text();
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wgsl_from_path$46$State$State_0(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wgsl_from_path$46$State$State_0.prototype.$tag = 0;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wgsl_from_path$46$State$State_1(param0, param1, param2, param3, param4, param5) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
  this._5 = param5;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wgsl_from_path$46$State$State_1.prototype.$tag = 1;
const Milky2018$mgstudio$45$runtime$45$web$$new_map = () => new Map();
const Milky2018$mgstudio$45$runtime$45$web$$request_adapter_any = () => navigator.gpu.requestAdapter();
const Milky2018$mgstudio$45$runtime$45$web$$request_device_any = (adapter) => adapter.requestDevice();
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$fn$47$1287$46$State$State_0(param0) {
  this._0 = param0;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$fn$47$1287$46$State$State_0.prototype.$tag = 0;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$fn$47$1287$46$State$_try$47$997(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$fn$47$1287$46$State$_try$47$997.prototype.$tag = 1;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_0(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_0.prototype.$tag = 0;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$_try$47$1000(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$_try$47$1000.prototype.$tag = 1;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_2(param0, param1, param2, param3, param4, param5) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
  this._5 = param5;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_2.prototype.$tag = 2;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$_try$47$1003(param0, param1, param2, param3, param4, param5) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
  this._5 = param5;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$_try$47$1003.prototype.$tag = 3;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_4(param0, param1, param2, param3, param4, param5, param6) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
  this._5 = param5;
  this._6 = param6;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_4.prototype.$tag = 4;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$_try$47$1006(param0, param1, param2, param3, param4, param5, param6) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
  this._5 = param5;
  this._6 = param6;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$_try$47$1006.prototype.$tag = 5;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_6(param0, param1, param2, param3, param4) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_6.prototype.$tag = 6;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_7(param0, param1, param2, param3, param4) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_7.prototype.$tag = 7;
const Option$None$23$ = { $tag: 0 };
function Option$Some$23$(param0) {
  this._0 = param0;
}
Option$Some$23$.prototype.$tag = 1;
const Option$None$24$ = { $tag: 0 };
function Option$Some$24$(param0) {
  this._0 = param0;
}
Option$Some$24$.prototype.$tag = 1;
const Option$None$25$ = { $tag: 0 };
function Option$Some$25$(param0) {
  this._0 = param0;
}
Option$Some$25$.prototype.$tag = 1;
const Milky2018$mgstudio$45$runtime$45$web$$new_set = () => new Set();
const Milky2018$mgstudio$45$runtime$45$web$$performance_now = () => performance.now();
const Milky2018$mgstudio$45$runtime$45$web$$push_gizmo_line = (target, sx, sy, sr, sg, sb, sa, ex, ey, er, eg, eb, ea, width, style, gapScale, lineScale) => {
   if (target && typeof target.push === "function") {
     target.push(sx, sy, sr, sg, sb, sa, ex, ey, er, eg, eb, ea, width, style, gapScale, lineScale)
   }
 };
const Milky2018$mgstudio$45$runtime$45$web$$request_animation_frame = (callback) => requestAnimationFrame(callback);
const Milky2018$mgstudio$45$runtime$45$web$$throw_error = (message) => { throw new Error(message) };
const Milky2018$mgstudio$45$runtime$45$web$$wrap_variadic = (func) => (...args) => func(args);
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1408$46$State$State_0(param0) {
  this._0 = param0;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1408$46$State$State_0.prototype.$tag = 0;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1408$46$State$_try$47$1077(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1408$46$State$_try$47$1077.prototype.$tag = 1;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1430$46$State$State_0(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1430$46$State$State_0.prototype.$tag = 0;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1430$46$State$_try$47$1074(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1430$46$State$_try$47$1074.prototype.$tag = 1;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1454$46$State$State_0(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1454$46$State$State_0.prototype.$tag = 0;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$main_async$46$State$State_0(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$main_async$46$State$State_0.prototype.$tag = 0;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$main_async$46$State$State_1(param0, param1, param2, param3, param4, param5) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
  this._5 = param5;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$main_async$46$State$State_1.prototype.$tag = 1;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$42$init$46$lambda$47$1502$46$State$State_0(param0) {
  this._0 = param0;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$42$init$46$lambda$47$1502$46$State$State_0.prototype.$tag = 0;
function $36$Milky2018$47$mgstudio$45$runtime$45$web$46$42$init$46$lambda$47$1502$46$State$_try$47$1140(param0) {
  this._0 = param0;
}
$36$Milky2018$47$mgstudio$45$runtime$45$web$46$42$init$46$lambda$47$1502$46$State$_try$47$1140.prototype.$tag = 1;
const $$$64$moonbitlang$47$core$47$builtin$46$StringBuilder$36$as$36$64$moonbitlang$47$core$47$builtin$46$Logger = { method_0: moonbitlang$core$builtin$$Logger$write_string$0$, method_1: moonbitlang$core$builtin$$Logger$write_substring$1$, method_2: moonbitlang$core$builtin$$Logger$write_view$0$, method_3: moonbitlang$core$builtin$$Logger$write_char$0$ };
function Error$$to_string(_e) {
  switch (_e.$tag) {
    case 0: {
      return moonbitlang$core$builtin$$Show$to_string$2$(_e);
    }
    case 1: {
      return moonbitlang$core$builtin$$Show$to_string$2$(_e);
    }
    default: {
      return moonbitlang$core$builtin$$Show$to_string$3$(_e);
    }
  }
}
const Milky2018$mgstudio$45$runtime$45$web$$mouse_button_name$46$constr$47$941 = "Left";
const Milky2018$mgstudio$45$runtime$45$web$$mouse_button_name$46$constr$47$942 = "Middle";
const Milky2018$mgstudio$45$runtime$45$web$$mouse_button_name$46$constr$47$943 = "Right";
const moonbitlang$core$builtin$$seed = moonbitlang$core$builtin$$random_seed();
function moonbitlang$core$builtin$$Logger$write_object$4$(self, obj) {
  moonbitlang$core$builtin$$Show$output$4$(obj, self);
}
function moonbitlang$core$builtin$$Show$output$5$(_x_5029, _x_5030) {
  if (_x_5029.$tag === 1) {
    _x_5030.method_table.method_0(_x_5030.self, "IndexOutOfBounds");
    return;
  } else {
    _x_5030.method_table.method_0(_x_5030.self, "InvalidIndex");
    return;
  }
}
function moonbitlang$core$builtin$$Show$output$6$(_x_5015, _x_5016) {
  const _Failure = _x_5015;
  const _$42$arg_5017 = _Failure._0;
  _x_5016.method_table.method_0(_x_5016.self, "Failure(");
  moonbitlang$core$builtin$$Logger$write_object$4$(_x_5016, _$42$arg_5017);
  _x_5016.method_table.method_0(_x_5016.self, ")");
}
function moonbitlang$core$builtin$$Hasher$consume4(self, input) {
  const _p = (self.acc >>> 0) + ((Math.imul(input, -1028477379) | 0) >>> 0) | 0;
  const _p$2 = 17;
  self.acc = Math.imul(_p << _p$2 | (_p >>> (32 - _p$2 | 0) | 0), 668265263) | 0;
}
function moonbitlang$core$builtin$$Hasher$combine_uint(self, value) {
  self.acc = (self.acc >>> 0) + (4 >>> 0) | 0;
  moonbitlang$core$builtin$$Hasher$consume4(self, value);
}
function moonbitlang$core$builtin$$StringBuilder$new$46$inner(size_hint) {
  return { val: "" };
}
function moonbitlang$core$builtin$$Logger$write_char$0$(self, ch) {
  const _bind = self;
  _bind.val = `${_bind.val}${String.fromCodePoint(ch)}`;
}
function moonbitlang$core$uint16$$UInt16$is_trailing_surrogate(self) {
  return moonbitlang$core$builtin$$Compare$op_ge$7$(self, 56320) && moonbitlang$core$builtin$$Compare$op_le$7$(self, 57343);
}
function moonbitlang$core$array$$Array$at$8$(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function moonbitlang$core$builtin$$SourceLocRepr$parse(repr) {
  const _bind = { str: repr, start: 0, end: repr.length };
  const _data = _bind.str;
  const _start = _bind.start;
  const _end = _start + (_bind.end - _bind.start | 0) | 0;
  let _cursor = _start;
  let accept_state = -1;
  let match_end = -1;
  let match_tag_saver_0 = -1;
  let match_tag_saver_1 = -1;
  let match_tag_saver_2 = -1;
  let match_tag_saver_3 = -1;
  let match_tag_saver_4 = -1;
  let tag_0 = -1;
  let tag_1 = -1;
  let tag_1_1 = -1;
  let tag_1_2 = -1;
  let tag_3 = -1;
  let tag_2 = -1;
  let tag_2_1 = -1;
  let tag_4 = -1;
  _L: {
    let join_dispatch_19;
    _L$2: {
      if (_cursor < _end) {
        const _p = _cursor;
        const next_char = _data.charCodeAt(_p);
        _cursor = _cursor + 1 | 0;
        if (next_char < 65) {
          if (next_char < 64) {
            break _L;
          } else {
            while (true) {
              tag_0 = _cursor;
              if (_cursor < _end) {
                _L$3: {
                  const _p$2 = _cursor;
                  const next_char$2 = _data.charCodeAt(_p$2);
                  _cursor = _cursor + 1 | 0;
                  if (next_char$2 < 55296) {
                    if (next_char$2 < 58) {
                      break _L$3;
                    } else {
                      if (next_char$2 > 58) {
                        break _L$3;
                      } else {
                        if (_cursor < _end) {
                          _L$4: {
                            const _p$3 = _cursor;
                            const next_char$3 = _data.charCodeAt(_p$3);
                            _cursor = _cursor + 1 | 0;
                            if (next_char$3 < 56319) {
                              if (next_char$3 < 55296) {
                                break _L$4;
                              } else {
                                join_dispatch_19 = 7;
                                break _L$2;
                              }
                            } else {
                              if (next_char$3 > 56319) {
                                if (next_char$3 < 65536) {
                                  break _L$4;
                                } else {
                                  break _L;
                                }
                              } else {
                                join_dispatch_19 = 8;
                                break _L$2;
                              }
                            }
                          }
                          join_dispatch_19 = 0;
                          break _L$2;
                        } else {
                          break _L;
                        }
                      }
                    }
                  } else {
                    if (next_char$2 > 56318) {
                      if (next_char$2 < 57344) {
                        if (_cursor < _end) {
                          const _p$3 = _cursor;
                          const next_char$3 = _data.charCodeAt(_p$3);
                          _cursor = _cursor + 1 | 0;
                          if (next_char$3 < 56320) {
                            break _L;
                          } else {
                            if (next_char$3 > 57343) {
                              break _L;
                            } else {
                              continue;
                            }
                          }
                        } else {
                          break _L;
                        }
                      } else {
                        if (next_char$2 > 65535) {
                          break _L;
                        } else {
                          break _L$3;
                        }
                      }
                    } else {
                      if (_cursor < _end) {
                        const _p$3 = _cursor;
                        const next_char$3 = _data.charCodeAt(_p$3);
                        _cursor = _cursor + 1 | 0;
                        if (next_char$3 < 56320) {
                          break _L;
                        } else {
                          if (next_char$3 > 65535) {
                            break _L;
                          } else {
                            continue;
                          }
                        }
                      } else {
                        break _L;
                      }
                    }
                  }
                }
                continue;
              } else {
                break _L;
              }
            }
          }
        } else {
          break _L;
        }
      } else {
        break _L;
      }
    }
    let _tmp = join_dispatch_19;
    _L$3: while (true) {
      const dispatch_19 = _tmp;
      _L$4: {
        _L$5: {
          switch (dispatch_19) {
            case 3: {
              tag_1_2 = tag_1_1;
              tag_1_1 = tag_1;
              tag_1 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      if (next_char < 48) {
                        break _L$6;
                      } else {
                        tag_1 = _cursor;
                        tag_2_1 = tag_2;
                        tag_2 = _cursor;
                        tag_3 = _cursor;
                        if (_cursor < _end) {
                          _L$7: {
                            const _p$2 = _cursor;
                            const next_char$2 = _data.charCodeAt(_p$2);
                            _cursor = _cursor + 1 | 0;
                            if (next_char$2 < 59) {
                              if (next_char$2 < 46) {
                                if (next_char$2 < 45) {
                                  break _L$7;
                                } else {
                                  break _L$4;
                                }
                              } else {
                                if (next_char$2 > 47) {
                                  if (next_char$2 < 58) {
                                    _tmp = 6;
                                    continue _L$3;
                                  } else {
                                    _tmp = 3;
                                    continue _L$3;
                                  }
                                } else {
                                  break _L$7;
                                }
                              }
                            } else {
                              if (next_char$2 > 55295) {
                                if (next_char$2 < 57344) {
                                  if (next_char$2 < 56319) {
                                    _tmp = 7;
                                    continue _L$3;
                                  } else {
                                    _tmp = 8;
                                    continue _L$3;
                                  }
                                } else {
                                  if (next_char$2 > 65535) {
                                    break _L;
                                  } else {
                                    break _L$7;
                                  }
                                }
                              } else {
                                break _L$7;
                              }
                            }
                          }
                          _tmp = 0;
                          continue _L$3;
                        } else {
                          break _L;
                        }
                      }
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        _tmp = 1;
                        continue _L$3;
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            case 2: {
              tag_1 = _cursor;
              tag_2 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      if (next_char < 48) {
                        break _L$6;
                      } else {
                        _tmp = 2;
                        continue _L$3;
                      }
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        _tmp = 3;
                        continue _L$3;
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            case 0: {
              tag_1 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      break _L$6;
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        _tmp = 1;
                        continue _L$3;
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            case 8: {
              if (_cursor < _end) {
                const _p = _cursor;
                const next_char = _data.charCodeAt(_p);
                _cursor = _cursor + 1 | 0;
                if (next_char < 56320) {
                  break _L;
                } else {
                  if (next_char > 57343) {
                    break _L;
                  } else {
                    _tmp = 0;
                    continue _L$3;
                  }
                }
              } else {
                break _L;
              }
            }
            case 4: {
              tag_1 = _cursor;
              tag_4 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      if (next_char < 48) {
                        break _L$6;
                      } else {
                        _tmp = 4;
                        continue _L$3;
                      }
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        tag_1_2 = tag_1_1;
                        tag_1_1 = tag_1;
                        tag_1 = _cursor;
                        if (_cursor < _end) {
                          _L$7: {
                            const _p$2 = _cursor;
                            const next_char$2 = _data.charCodeAt(_p$2);
                            _cursor = _cursor + 1 | 0;
                            if (next_char$2 < 55296) {
                              if (next_char$2 < 58) {
                                if (next_char$2 < 48) {
                                  break _L$7;
                                } else {
                                  tag_1 = _cursor;
                                  tag_2_1 = tag_2;
                                  tag_2 = _cursor;
                                  if (_cursor < _end) {
                                    _L$8: {
                                      const _p$3 = _cursor;
                                      const next_char$3 = _data.charCodeAt(_p$3);
                                      _cursor = _cursor + 1 | 0;
                                      if (next_char$3 < 55296) {
                                        if (next_char$3 < 58) {
                                          if (next_char$3 < 48) {
                                            break _L$8;
                                          } else {
                                            _tmp = 5;
                                            continue _L$3;
                                          }
                                        } else {
                                          if (next_char$3 > 58) {
                                            break _L$8;
                                          } else {
                                            _tmp = 3;
                                            continue _L$3;
                                          }
                                        }
                                      } else {
                                        if (next_char$3 > 56318) {
                                          if (next_char$3 < 57344) {
                                            _tmp = 8;
                                            continue _L$3;
                                          } else {
                                            if (next_char$3 > 65535) {
                                              break _L;
                                            } else {
                                              break _L$8;
                                            }
                                          }
                                        } else {
                                          _tmp = 7;
                                          continue _L$3;
                                        }
                                      }
                                    }
                                    _tmp = 0;
                                    continue _L$3;
                                  } else {
                                    break _L$5;
                                  }
                                }
                              } else {
                                if (next_char$2 > 58) {
                                  break _L$7;
                                } else {
                                  _tmp = 1;
                                  continue _L$3;
                                }
                              }
                            } else {
                              if (next_char$2 > 56318) {
                                if (next_char$2 < 57344) {
                                  _tmp = 8;
                                  continue _L$3;
                                } else {
                                  if (next_char$2 > 65535) {
                                    break _L;
                                  } else {
                                    break _L$7;
                                  }
                                }
                              } else {
                                _tmp = 7;
                                continue _L$3;
                              }
                            }
                          }
                          _tmp = 0;
                          continue _L$3;
                        } else {
                          break _L;
                        }
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            case 5: {
              tag_1 = _cursor;
              tag_2 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      if (next_char < 48) {
                        break _L$6;
                      } else {
                        _tmp = 5;
                        continue _L$3;
                      }
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        _tmp = 3;
                        continue _L$3;
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L$5;
              }
            }
            case 6: {
              tag_1 = _cursor;
              tag_2 = _cursor;
              tag_3 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 59) {
                    if (next_char < 46) {
                      if (next_char < 45) {
                        break _L$6;
                      } else {
                        break _L$4;
                      }
                    } else {
                      if (next_char > 47) {
                        if (next_char < 58) {
                          _tmp = 6;
                          continue _L$3;
                        } else {
                          _tmp = 3;
                          continue _L$3;
                        }
                      } else {
                        break _L$6;
                      }
                    }
                  } else {
                    if (next_char > 55295) {
                      if (next_char < 57344) {
                        if (next_char < 56319) {
                          _tmp = 7;
                          continue _L$3;
                        } else {
                          _tmp = 8;
                          continue _L$3;
                        }
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      break _L$6;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            case 7: {
              if (_cursor < _end) {
                const _p = _cursor;
                const next_char = _data.charCodeAt(_p);
                _cursor = _cursor + 1 | 0;
                if (next_char < 56320) {
                  break _L;
                } else {
                  if (next_char > 65535) {
                    break _L;
                  } else {
                    _tmp = 0;
                    continue _L$3;
                  }
                }
              } else {
                break _L;
              }
            }
            case 1: {
              tag_1_1 = tag_1;
              tag_1 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      if (next_char < 48) {
                        break _L$6;
                      } else {
                        _tmp = 2;
                        continue _L$3;
                      }
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        _tmp = 1;
                        continue _L$3;
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            default: {
              break _L;
            }
          }
        }
        tag_1 = tag_1_2;
        tag_2 = tag_2_1;
        match_tag_saver_0 = tag_0;
        match_tag_saver_1 = tag_1;
        match_tag_saver_2 = tag_2;
        match_tag_saver_3 = tag_3;
        match_tag_saver_4 = tag_4;
        accept_state = 0;
        match_end = _cursor;
        break _L;
      }
      tag_1_1 = tag_1_2;
      tag_1 = _cursor;
      tag_2 = tag_2_1;
      if (_cursor < _end) {
        _L$5: {
          const _p = _cursor;
          const next_char = _data.charCodeAt(_p);
          _cursor = _cursor + 1 | 0;
          if (next_char < 55296) {
            if (next_char < 58) {
              if (next_char < 48) {
                break _L$5;
              } else {
                _tmp = 4;
                continue;
              }
            } else {
              if (next_char > 58) {
                break _L$5;
              } else {
                _tmp = 1;
                continue;
              }
            }
          } else {
            if (next_char > 56318) {
              if (next_char < 57344) {
                _tmp = 8;
                continue;
              } else {
                if (next_char > 65535) {
                  break _L;
                } else {
                  break _L$5;
                }
              }
            } else {
              _tmp = 7;
              continue;
            }
          }
        }
        _tmp = 0;
        continue;
      } else {
        break _L;
      }
    }
  }
  if (accept_state === 0) {
    let start_line;
    let _try_err;
    _L$2: {
      _L$3: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_1 + 1 | 0, match_tag_saver_2);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          start_line = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err = _tmp;
          break _L$3;
        }
        break _L$2;
      }
      start_line = $panic();
    }
    let start_column;
    let _try_err$2;
    _L$3: {
      _L$4: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_2 + 1 | 0, match_tag_saver_3);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          start_column = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err$2 = _tmp;
          break _L$4;
        }
        break _L$3;
      }
      start_column = $panic();
    }
    let pkg;
    let _try_err$3;
    _L$4: {
      _L$5: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, _start + 1 | 0, match_tag_saver_0);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          pkg = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err$3 = _tmp;
          break _L$5;
        }
        break _L$4;
      }
      pkg = $panic();
    }
    let filename;
    let _try_err$4;
    _L$5: {
      _L$6: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_0 + 1 | 0, match_tag_saver_1);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          filename = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err$4 = _tmp;
          break _L$6;
        }
        break _L$5;
      }
      filename = $panic();
    }
    let end_line;
    let _try_err$5;
    _L$6: {
      _L$7: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_3 + 1 | 0, match_tag_saver_4);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          end_line = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err$5 = _tmp;
          break _L$7;
        }
        break _L$6;
      }
      end_line = $panic();
    }
    let end_column;
    let _try_err$6;
    _L$7: {
      _L$8: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_4 + 1 | 0, match_end);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          end_column = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err$6 = _tmp;
          break _L$8;
        }
        break _L$7;
      }
      end_column = $panic();
    }
    return { pkg: pkg, filename: filename, start_line: start_line, start_column: start_column, end_line: end_line, end_column: end_column };
  } else {
    return $panic();
  }
}
function moonbitlang$core$builtin$$Logger$write_string$0$(self, str) {
  const _bind = self;
  _bind.val = `${_bind.val}${str}`;
}
function moonbitlang$core$builtin$$Hasher$combine$4$(self, value) {
  moonbitlang$core$builtin$$Hash$hash_combine$4$(value, self);
}
function moonbitlang$core$builtin$$Compare$op_lt$7$(x, y) {
  return $compare_int(x, y) < 0;
}
function moonbitlang$core$builtin$$Compare$op_le$7$(x, y) {
  return $compare_int(x, y) <= 0;
}
function moonbitlang$core$builtin$$Compare$op_ge$7$(x, y) {
  return $compare_int(x, y) >= 0;
}
function moonbitlang$core$builtin$$Hasher$avalanche(self) {
  let acc = self.acc;
  acc = acc ^ (acc >>> 15 | 0);
  acc = Math.imul(acc, -2048144777) | 0;
  acc = acc ^ (acc >>> 13 | 0);
  acc = Math.imul(acc, -1028477379) | 0;
  acc = acc ^ (acc >>> 16 | 0);
  return acc;
}
function moonbitlang$core$builtin$$Hasher$finalize(self) {
  return moonbitlang$core$builtin$$Hasher$avalanche(self);
}
function moonbitlang$core$builtin$$Hasher$new$46$inner(seed) {
  return { acc: (seed >>> 0) + (374761393 >>> 0) | 0 };
}
function moonbitlang$core$builtin$$Hasher$new(seed$46$opt) {
  let seed;
  if (seed$46$opt === undefined) {
    seed = moonbitlang$core$builtin$$seed;
  } else {
    const _Some = seed$46$opt;
    seed = _Some;
  }
  return moonbitlang$core$builtin$$Hasher$new$46$inner(seed);
}
function moonbitlang$core$builtin$$Hash$hash$9$(self) {
  const _self = moonbitlang$core$builtin$$Hasher$new(undefined);
  moonbitlang$core$builtin$$Hasher$combine$4$(_self, self);
  return moonbitlang$core$builtin$$Hasher$finalize(_self);
}
function moonbitlang$core$string$$String$sub$46$inner(self, start, end) {
  const len = self.length;
  let end$2;
  if (end === undefined) {
    end$2 = len;
  } else {
    const _Some = end;
    const _end = _Some;
    end$2 = _end < 0 ? len + _end | 0 : _end;
  }
  const start$2 = start < 0 ? len + start | 0 : start;
  if (start$2 >= 0 && (start$2 <= end$2 && end$2 <= len)) {
    if (start$2 < len && moonbitlang$core$uint16$$UInt16$is_trailing_surrogate(self.charCodeAt(start$2))) {
      return new Result$Err$0$(Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$InvalidIndex);
    }
    if (end$2 < len && moonbitlang$core$uint16$$UInt16$is_trailing_surrogate(self.charCodeAt(end$2))) {
      return new Result$Err$0$(Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$InvalidIndex);
    }
    return new Result$Ok$0$({ str: self, start: start$2, end: end$2 });
  } else {
    return new Result$Err$0$(Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$IndexOutOfBounds);
  }
}
function moonbitlang$core$string$$String$sub(self, start$46$opt, end) {
  let start;
  if (start$46$opt === undefined) {
    start = 0;
  } else {
    const _Some = start$46$opt;
    start = _Some;
  }
  return moonbitlang$core$string$$String$sub$46$inner(self, start, end);
}
function moonbitlang$core$builtin$$Logger$write_substring$1$(self, value, start, len) {
  let _tmp;
  let _try_err;
  _L: {
    _L$2: {
      const _bind = moonbitlang$core$string$$String$sub$46$inner(value, start, start + len | 0);
      if (_bind.$tag === 1) {
        const _ok = _bind;
        _tmp = _ok._0;
      } else {
        const _err = _bind;
        const _tmp$2 = _err._0;
        _try_err = _tmp$2;
        break _L$2;
      }
      break _L;
    }
    _tmp = $panic();
  }
  moonbitlang$core$builtin$$Logger$write_view$0$(self, _tmp);
}
function moonbitlang$core$builtin$$Show$to_string$10$(self) {
  const logger = moonbitlang$core$builtin$$StringBuilder$new$46$inner(0);
  moonbitlang$core$builtin$$Show$output$11$(self, { self: logger, method_table: $$$64$moonbitlang$47$core$47$builtin$46$StringBuilder$36$as$36$64$moonbitlang$47$core$47$builtin$46$Logger });
  return logger.val;
}
function moonbitlang$core$builtin$$Show$to_string$12$(self) {
  const logger = moonbitlang$core$builtin$$StringBuilder$new$46$inner(0);
  moonbitlang$core$builtin$$Show$output$13$(self, { self: logger, method_table: $$$64$moonbitlang$47$core$47$builtin$46$StringBuilder$36$as$36$64$moonbitlang$47$core$47$builtin$46$Logger });
  return logger.val;
}
function moonbitlang$core$builtin$$Show$to_string$3$(self) {
  const logger = moonbitlang$core$builtin$$StringBuilder$new$46$inner(0);
  moonbitlang$core$builtin$$Show$output$6$(self, { self: logger, method_table: $$$64$moonbitlang$47$core$47$builtin$46$StringBuilder$36$as$36$64$moonbitlang$47$core$47$builtin$46$Logger });
  return logger.val;
}
function moonbitlang$core$builtin$$Show$to_string$2$(self) {
  const logger = moonbitlang$core$builtin$$StringBuilder$new$46$inner(0);
  moonbitlang$core$builtin$$Show$output$5$(self, { self: logger, method_table: $$$64$moonbitlang$47$core$47$builtin$46$StringBuilder$36$as$36$64$moonbitlang$47$core$47$builtin$46$Logger });
  return logger.val;
}
function moonbitlang$core$int$$Int$to_string$46$inner(self, radix) {
  return moonbitlang$core$builtin$$int_to_string_js(self, radix);
}
function moonbitlang$core$builtin$$fail$14$(msg, loc) {
  return new Result$Err$1$(new Error$moonbitlang$47$core$47$builtin$46$Failure$46$Failure(`${moonbitlang$core$builtin$$Show$to_string$12$(loc)} FAILED: ${msg}`));
}
function moonbitlang$core$builtin$$to_hex$46$to_hex_digit$124$3743(i) {
  if (i < 10) {
    const _p = 48;
    const _p$2 = (i + _p | 0) & 255;
    return _p$2;
  } else {
    const _p = 97;
    const _p$2 = (i + _p | 0) & 255;
    const _p$3 = 10;
    const _p$4 = (_p$2 - _p$3 | 0) & 255;
    return _p$4;
  }
}
function moonbitlang$core$byte$$Byte$to_hex(b) {
  const _self = moonbitlang$core$builtin$$StringBuilder$new$46$inner(0);
  const _p = 16;
  moonbitlang$core$builtin$$Logger$write_char$0$(_self, moonbitlang$core$builtin$$to_hex$46$to_hex_digit$124$3743((b / _p | 0) & 255));
  const _p$2 = 16;
  moonbitlang$core$builtin$$Logger$write_char$0$(_self, moonbitlang$core$builtin$$to_hex$46$to_hex_digit$124$3743((b % _p$2 | 0) & 255));
  const _p$3 = _self;
  return _p$3.val;
}
function moonbitlang$core$builtin$$output$46$flush_segment$124$3733(_env, seg, i) {
  const logger = _env._1;
  const self = _env._0;
  if (i > seg) {
    logger.method_table.method_1(logger.self, self, seg, i - seg | 0);
    return;
  } else {
    return;
  }
}
function moonbitlang$core$builtin$$Show$output$4$(self, logger) {
  logger.method_table.method_3(logger.self, 34);
  const _env = { _0: self, _1: logger };
  const len = self.length;
  let _tmp = 0;
  let _tmp$2 = 0;
  _L: while (true) {
    const i = _tmp;
    const seg = _tmp$2;
    if (i >= len) {
      moonbitlang$core$builtin$$output$46$flush_segment$124$3733(_env, seg, i);
      break;
    }
    const code = self.charCodeAt(i);
    let c;
    _L$2: {
      switch (code) {
        case 34: {
          c = code;
          break _L$2;
        }
        case 92: {
          c = code;
          break _L$2;
        }
        case 10: {
          moonbitlang$core$builtin$$output$46$flush_segment$124$3733(_env, seg, i);
          logger.method_table.method_0(logger.self, "\\n");
          _tmp = i + 1 | 0;
          _tmp$2 = i + 1 | 0;
          continue _L;
        }
        case 13: {
          moonbitlang$core$builtin$$output$46$flush_segment$124$3733(_env, seg, i);
          logger.method_table.method_0(logger.self, "\\r");
          _tmp = i + 1 | 0;
          _tmp$2 = i + 1 | 0;
          continue _L;
        }
        case 8: {
          moonbitlang$core$builtin$$output$46$flush_segment$124$3733(_env, seg, i);
          logger.method_table.method_0(logger.self, "\\b");
          _tmp = i + 1 | 0;
          _tmp$2 = i + 1 | 0;
          continue _L;
        }
        case 9: {
          moonbitlang$core$builtin$$output$46$flush_segment$124$3733(_env, seg, i);
          logger.method_table.method_0(logger.self, "\\t");
          _tmp = i + 1 | 0;
          _tmp$2 = i + 1 | 0;
          continue _L;
        }
        default: {
          if (moonbitlang$core$builtin$$Compare$op_lt$7$(code, 32)) {
            moonbitlang$core$builtin$$output$46$flush_segment$124$3733(_env, seg, i);
            logger.method_table.method_0(logger.self, "\\u{");
            logger.method_table.method_0(logger.self, moonbitlang$core$byte$$Byte$to_hex(code & 255));
            logger.method_table.method_3(logger.self, 125);
            _tmp = i + 1 | 0;
            _tmp$2 = i + 1 | 0;
            continue _L;
          } else {
            _tmp = i + 1 | 0;
            continue _L;
          }
        }
      }
    }
    moonbitlang$core$builtin$$output$46$flush_segment$124$3733(_env, seg, i);
    logger.method_table.method_3(logger.self, 92);
    logger.method_table.method_3(logger.self, c);
    _tmp = i + 1 | 0;
    _tmp$2 = i + 1 | 0;
    continue;
  }
  logger.method_table.method_3(logger.self, 34);
}
function moonbitlang$core$builtin$$Show$to_string$15$(self) {
  return self.str.substring(self.start, self.end);
}
function moonbitlang$core$builtin$$Logger$write_view$0$(self, str) {
  const _bind = self;
  _bind.val = `${_bind.val}${moonbitlang$core$builtin$$Show$to_string$15$(str)}`;
}
function moonbitlang$core$array$$Array$push$16$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$array$$Array$push$17$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$array$$Array$push$8$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$builtin$$Iter$next$18$(self) {
  const _func = self;
  return _func();
}
function moonbitlang$core$int$$Int$next_power_of_two(self) {
  if (self >= 0) {
    if (self <= 1) {
      return 1;
    }
    if (self > 1073741824) {
      return 1073741824;
    }
    return (2147483647 >> (Math.clz32(self - 1 | 0) - 1 | 0)) + 1 | 0;
  } else {
    return $panic();
  }
}
function moonbitlang$core$builtin$$Map$new$46$inner$19$(capacity) {
  const capacity$2 = moonbitlang$core$int$$Int$next_power_of_two(capacity);
  const _bind = capacity$2 - 1 | 0;
  const _bind$2 = (Math.imul(capacity$2, 13) | 0) / 16 | 0;
  const _bind$3 = $make_array_len_and_init(capacity$2, undefined);
  const _bind$4 = undefined;
  return { entries: _bind$3, size: 0, capacity: capacity$2, capacity_mask: _bind, grow_at: _bind$2, head: _bind$4, tail: -1 };
}
function moonbitlang$core$builtin$$Map$add_entry_to_tail$19$(self, idx, entry) {
  const _bind = self.tail;
  if (_bind === -1) {
    self.head = entry;
  } else {
    const _tmp = self.entries;
    $bound_check(_tmp, _bind);
    const _p = _tmp[_bind];
    let _tmp$2;
    if (_p === undefined) {
      _tmp$2 = $panic();
    } else {
      const _p$2 = _p;
      _tmp$2 = _p$2;
    }
    _tmp$2.next = entry;
  }
  self.tail = idx;
  const _tmp = self.entries;
  $bound_check(_tmp, idx);
  _tmp[idx] = entry;
  self.size = self.size + 1 | 0;
}
function moonbitlang$core$builtin$$Map$set_entry$19$(self, entry, new_idx) {
  const _tmp = self.entries;
  $bound_check(_tmp, new_idx);
  _tmp[new_idx] = entry;
  const _bind = entry.next;
  if (_bind === undefined) {
    self.tail = new_idx;
    return;
  } else {
    const _Some = _bind;
    const _next = _Some;
    _next.prev = new_idx;
    return;
  }
}
function moonbitlang$core$builtin$$Map$push_away$19$(self, idx, entry) {
  let _tmp = entry.psl + 1 | 0;
  let _tmp$2 = idx + 1 & self.capacity_mask;
  let _tmp$3 = entry;
  while (true) {
    const psl = _tmp;
    const idx$2 = _tmp$2;
    const entry$2 = _tmp$3;
    const _tmp$4 = self.entries;
    $bound_check(_tmp$4, idx$2);
    const _bind = _tmp$4[idx$2];
    if (_bind === undefined) {
      entry$2.psl = psl;
      moonbitlang$core$builtin$$Map$set_entry$19$(self, entry$2, idx$2);
      break;
    } else {
      const _Some = _bind;
      const _curr_entry = _Some;
      if (psl > _curr_entry.psl) {
        entry$2.psl = psl;
        moonbitlang$core$builtin$$Map$set_entry$19$(self, entry$2, idx$2);
        _tmp = _curr_entry.psl + 1 | 0;
        _tmp$2 = idx$2 + 1 & self.capacity_mask;
        _tmp$3 = _curr_entry;
        continue;
      } else {
        _tmp = psl + 1 | 0;
        _tmp$2 = idx$2 + 1 & self.capacity_mask;
        continue;
      }
    }
  }
}
function moonbitlang$core$builtin$$Map$set_with_hash$19$(self, key, value, hash) {
  if (self.size >= self.grow_at) {
    moonbitlang$core$builtin$$Map$grow$19$(self);
  }
  let _bind;
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const psl = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind$2 = _tmp$3[idx];
    if (_bind$2 === undefined) {
      _bind = { _0: idx, _1: psl };
      break;
    } else {
      const _Some = _bind$2;
      const _curr_entry = _Some;
      if (_curr_entry.hash === hash && _curr_entry.key === key) {
        _curr_entry.value = value;
        return undefined;
      }
      if (psl > _curr_entry.psl) {
        moonbitlang$core$builtin$$Map$push_away$19$(self, idx, _curr_entry);
        _bind = { _0: idx, _1: psl };
        break;
      }
      _tmp = psl + 1 | 0;
      _tmp$2 = idx + 1 & self.capacity_mask;
      continue;
    }
  }
  const _idx = _bind._0;
  const _psl = _bind._1;
  const _bind$2 = self.tail;
  const _bind$3 = undefined;
  const entry = { prev: _bind$2, next: _bind$3, psl: _psl, hash: hash, key: key, value: value };
  moonbitlang$core$builtin$$Map$add_entry_to_tail$19$(self, _idx, entry);
}
function moonbitlang$core$builtin$$Map$grow$19$(self) {
  const old_head = self.head;
  const new_capacity = self.capacity << 1;
  self.entries = $make_array_len_and_init(new_capacity, undefined);
  self.capacity = new_capacity;
  self.capacity_mask = new_capacity - 1 | 0;
  const _p = self.capacity;
  self.grow_at = (Math.imul(_p, 13) | 0) / 16 | 0;
  self.size = 0;
  self.head = undefined;
  self.tail = -1;
  let _tmp = old_head;
  while (true) {
    const _param = _tmp;
    if (_param === undefined) {
      return;
    } else {
      const _Some = _param;
      const _x = _Some;
      const _next = _x.next;
      const _key = _x.key;
      const _value = _x.value;
      const _hash = _x.hash;
      moonbitlang$core$builtin$$Map$set_with_hash$19$(self, _key, _value, _hash);
      _tmp = _next;
      continue;
    }
  }
}
function moonbitlang$core$builtin$$Map$set$19$(self, key, value) {
  moonbitlang$core$builtin$$Map$set_with_hash$19$(self, key, value, moonbitlang$core$builtin$$Hash$hash$9$(key));
}
function moonbitlang$core$builtin$$Map$from_array$19$(arr) {
  const length = arr.end - arr.start | 0;
  let capacity = moonbitlang$core$int$$Int$next_power_of_two(length);
  const _p = capacity;
  if (length > ((Math.imul(_p, 13) | 0) / 16 | 0)) {
    capacity = Math.imul(capacity, 2) | 0;
  }
  const m = moonbitlang$core$builtin$$Map$new$46$inner$19$(capacity);
  const _len = arr.end - arr.start | 0;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const e = arr.buf[arr.start + _i | 0];
      moonbitlang$core$builtin$$Map$set$19$(m, e._0, e._1);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return m;
}
function moonbitlang$core$builtin$$Map$iter$19$(self) {
  const curr_entry = { val: self.head };
  const _p = () => {
    const _bind = curr_entry.val;
    if (_bind === undefined) {
      return undefined;
    } else {
      const _Some = _bind;
      const _x = _Some;
      const _key = _x.key;
      const _value = _x.value;
      const _next = _x.next;
      curr_entry.val = _next;
      return { _0: _key, _1: _value };
    }
  };
  return _p;
}
function moonbitlang$core$builtin$$Map$iter2$19$(self) {
  return moonbitlang$core$builtin$$Map$iter$19$(self);
}
function moonbitlang$core$builtin$$Iter2$next$19$(self) {
  return moonbitlang$core$builtin$$Iter$next$18$(self);
}
function moonbitlang$core$builtin$$Hasher$combine_string(self, value) {
  const _end2395 = value.length;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < _end2395) {
      moonbitlang$core$builtin$$Hasher$combine_uint(self, value.charCodeAt(i));
      _tmp = i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function moonbitlang$core$builtin$$Hash$hash_combine$4$(self, hasher) {
  moonbitlang$core$builtin$$Hasher$combine_string(hasher, self);
}
function moonbitlang$core$double$$Double$to_int(self) {
  return self !== self ? 0 : self >= 2147483647 ? 2147483647 : self <= -2147483648 ? -2147483648 : self | 0;
}
function moonbitlang$core$builtin$$Show$output$20$(self, logger) {
  const pkg = self.pkg;
  const _data = pkg.str;
  const _start = pkg.start;
  const _end = _start + (pkg.end - pkg.start | 0) | 0;
  let _cursor = _start;
  let accept_state = -1;
  let match_end = -1;
  let match_tag_saver_0 = -1;
  let tag_0 = -1;
  let _bind;
  _L: {
    _L$2: {
      _L$3: while (true) {
        if (_cursor < _end) {
          _L$4: {
            _L$5: {
              const _p = _cursor;
              const next_char = _data.charCodeAt(_p);
              _cursor = _cursor + 1 | 0;
              if (next_char < 55296) {
                if (next_char < 47) {
                  break _L$5;
                } else {
                  if (next_char > 47) {
                    break _L$5;
                  } else {
                    _L$6: while (true) {
                      tag_0 = _cursor;
                      if (_cursor < _end) {
                        _L$7: {
                          const _p$2 = _cursor;
                          const next_char$2 = _data.charCodeAt(_p$2);
                          _cursor = _cursor + 1 | 0;
                          if (next_char$2 < 55296) {
                            if (next_char$2 < 47) {
                              break _L$7;
                            } else {
                              if (next_char$2 > 47) {
                                break _L$7;
                              } else {
                                while (true) {
                                  if (_cursor < _end) {
                                    _L$8: {
                                      const _p$3 = _cursor;
                                      const next_char$3 = _data.charCodeAt(_p$3);
                                      _cursor = _cursor + 1 | 0;
                                      if (next_char$3 < 56319) {
                                        if (next_char$3 < 55296) {
                                          break _L$8;
                                        } else {
                                          if (_cursor < _end) {
                                            const _p$4 = _cursor;
                                            const next_char$4 = _data.charCodeAt(_p$4);
                                            _cursor = _cursor + 1 | 0;
                                            if (next_char$4 < 56320) {
                                              break _L$2;
                                            } else {
                                              if (next_char$4 > 65535) {
                                                break _L$2;
                                              } else {
                                                continue;
                                              }
                                            }
                                          } else {
                                            break _L$2;
                                          }
                                        }
                                      } else {
                                        if (next_char$3 > 56319) {
                                          if (next_char$3 < 65536) {
                                            break _L$8;
                                          } else {
                                            break _L$2;
                                          }
                                        } else {
                                          if (_cursor < _end) {
                                            const _p$4 = _cursor;
                                            const next_char$4 = _data.charCodeAt(_p$4);
                                            _cursor = _cursor + 1 | 0;
                                            if (next_char$4 < 56320) {
                                              break _L$2;
                                            } else {
                                              if (next_char$4 > 57343) {
                                                break _L$2;
                                              } else {
                                                continue;
                                              }
                                            }
                                          } else {
                                            break _L$2;
                                          }
                                        }
                                      }
                                    }
                                    continue;
                                  } else {
                                    match_tag_saver_0 = tag_0;
                                    accept_state = 0;
                                    match_end = _cursor;
                                    break _L$2;
                                  }
                                }
                              }
                            }
                          } else {
                            if (next_char$2 > 56318) {
                              if (next_char$2 < 57344) {
                                if (_cursor < _end) {
                                  const _p$3 = _cursor;
                                  const next_char$3 = _data.charCodeAt(_p$3);
                                  _cursor = _cursor + 1 | 0;
                                  if (next_char$3 < 56320) {
                                    break _L$2;
                                  } else {
                                    if (next_char$3 > 57343) {
                                      break _L$2;
                                    } else {
                                      continue;
                                    }
                                  }
                                } else {
                                  break _L$2;
                                }
                              } else {
                                if (next_char$2 > 65535) {
                                  break _L$2;
                                } else {
                                  break _L$7;
                                }
                              }
                            } else {
                              if (_cursor < _end) {
                                const _p$3 = _cursor;
                                const next_char$3 = _data.charCodeAt(_p$3);
                                _cursor = _cursor + 1 | 0;
                                if (next_char$3 < 56320) {
                                  break _L$2;
                                } else {
                                  if (next_char$3 > 65535) {
                                    break _L$2;
                                  } else {
                                    continue;
                                  }
                                }
                              } else {
                                break _L$2;
                              }
                            }
                          }
                        }
                        continue;
                      } else {
                        break _L$2;
                      }
                    }
                  }
                }
              } else {
                if (next_char > 56318) {
                  if (next_char < 57344) {
                    if (_cursor < _end) {
                      const _p$2 = _cursor;
                      const next_char$2 = _data.charCodeAt(_p$2);
                      _cursor = _cursor + 1 | 0;
                      if (next_char$2 < 56320) {
                        break _L$2;
                      } else {
                        if (next_char$2 > 57343) {
                          break _L$2;
                        } else {
                          continue;
                        }
                      }
                    } else {
                      break _L$2;
                    }
                  } else {
                    if (next_char > 65535) {
                      break _L$2;
                    } else {
                      break _L$5;
                    }
                  }
                } else {
                  if (_cursor < _end) {
                    const _p$2 = _cursor;
                    const next_char$2 = _data.charCodeAt(_p$2);
                    _cursor = _cursor + 1 | 0;
                    if (next_char$2 < 56320) {
                      break _L$2;
                    } else {
                      if (next_char$2 > 65535) {
                        break _L$2;
                      } else {
                        continue;
                      }
                    }
                  } else {
                    break _L$2;
                  }
                }
              }
              break _L$4;
            }
            continue;
          }
        } else {
          break _L$2;
        }
      }
      break _L;
    }
    if (accept_state === 0) {
      let package_name;
      let _try_err;
      _L$3: {
        _L$4: {
          const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_0 + 1 | 0, match_end);
          if (_bind$2.$tag === 1) {
            const _ok = _bind$2;
            package_name = _ok._0;
          } else {
            const _err = _bind$2;
            const _tmp = _err._0;
            _try_err = _tmp;
            break _L$4;
          }
          break _L$3;
        }
        package_name = $panic();
      }
      let module_name;
      let _try_err$2;
      _L$4: {
        _L$5: {
          const _bind$2 = moonbitlang$core$string$$String$sub(_data, _start, match_tag_saver_0);
          if (_bind$2.$tag === 1) {
            const _ok = _bind$2;
            module_name = _ok._0;
          } else {
            const _err = _bind$2;
            const _tmp = _err._0;
            _try_err$2 = _tmp;
            break _L$5;
          }
          break _L$4;
        }
        module_name = $panic();
      }
      _bind = { _0: module_name, _1: package_name };
    } else {
      _bind = { _0: pkg, _1: undefined };
    }
  }
  const _module_name = _bind._0;
  const _package_name = _bind._1;
  if (_package_name === undefined) {
  } else {
    const _Some = _package_name;
    const _pkg_name = _Some;
    logger.method_table.method_2(logger.self, _pkg_name);
    logger.method_table.method_3(logger.self, 47);
  }
  logger.method_table.method_2(logger.self, self.filename);
  logger.method_table.method_3(logger.self, 58);
  logger.method_table.method_2(logger.self, self.start_line);
  logger.method_table.method_3(logger.self, 58);
  logger.method_table.method_2(logger.self, self.start_column);
  logger.method_table.method_3(logger.self, 45);
  logger.method_table.method_2(logger.self, self.end_line);
  logger.method_table.method_3(logger.self, 58);
  logger.method_table.method_2(logger.self, self.end_column);
  logger.method_table.method_3(logger.self, 64);
  logger.method_table.method_2(logger.self, _module_name);
}
function moonbitlang$core$builtin$$Show$output$13$(self, logger) {
  moonbitlang$core$builtin$$Show$output$20$(moonbitlang$core$builtin$$SourceLocRepr$parse(self), logger);
}
function moonbitlang$core$array$$Array$unsafe_truncate_to_length$17$(self, new_len) {
  moonbitlang$core$builtin$$JSArray$set_length(self, new_len);
}
function moonbitlang$core$array$$Array$clear$17$(self) {
  moonbitlang$core$array$$Array$unsafe_truncate_to_length$17$(self, 0);
}
function moonbitlang$core$builtin$$Show$output$11$(self, logger) {
  logger.method_table.method_0(logger.self, Error$$to_string(self));
}
function mizchi$js$core$$new$46$42$cont$47$395(_param) {}
function mizchi$js$core$$new$46$42$async_driver$47$396(_state) {
  const _$42$try$47$229 = _state;
  const reject = _$42$try$47$229._1;
  const _try_err = _$42$try$47$229._0;
  return reject(_try_err);
}
function mizchi$js$core$$Promise$new$14$(f) {
  return mizchi$js$core$$ffi_new_promise((resolve, reject) => {
    let _err;
    _L: {
      _L$2: {
        const _bind = f((a) => {
          resolve(a);
        }, (e) => {
          reject(e);
        }, mizchi$js$core$$new$46$42$cont$47$395, (_cont_param) => {
          const _bind$2 = mizchi$js$core$$new$46$42$async_driver$47$396(new $64$mizchi$47$js$47$core$46$Promise$58$58$new$46$lambda$46$lambda$47$317$46$State$_try$47$229$2$(_cont_param, reject));
          if (_bind$2 === -1) {
            return;
          } else {
            const _Some = _bind$2;
            const _payload = _Some;
            mizchi$js$core$$new$46$42$cont$47$395(_payload);
            return;
          }
        });
        let _bind$2;
        if (_bind.$tag === 1) {
          const _ok = _bind;
          _bind$2 = _ok._0;
        } else {
          const _err$2 = _bind;
          const _tmp = _err$2._0;
          _err = _tmp;
          break _L$2;
        }
        if (_bind$2 === -1) {
        }
        break _L;
      }
      mizchi$js$core$$new$46$42$async_driver$47$396(new $64$mizchi$47$js$47$core$46$Promise$58$58$new$46$lambda$46$lambda$47$317$46$State$_try$47$229$2$(_err, reject));
    }
  });
}
function mizchi$js$core$$Promise$wait$8$(self, _cont, _err_cont) {
  mizchi$js$core$$Any$_call(mizchi$js$core$$Any$_call(self, "then", [_cont]), "catch", [_err_cont]);
  return new Result$Ok$3$(Option$None$4$);
}
function mizchi$js$core$$Promise$wait$4$(self, _cont, _err_cont) {
  mizchi$js$core$$Any$_call(mizchi$js$core$$Any$_call(self, "then", [_cont]), "catch", [_err_cont]);
  return new Result$Ok$5$(undefined);
}
function mizchi$js$core$$Promise$wait$21$(self, _cont, _err_cont) {
  mizchi$js$core$$Any$_call(mizchi$js$core$$Any$_call(self, "then", [_cont]), "catch", [_err_cont]);
  return new Result$Ok$6$(undefined);
}
function mizchi$js$core$$Promise$wait$22$(self, _cont, _err_cont) {
  mizchi$js$core$$Any$_call(mizchi$js$core$$Any$_call(self, "then", [_cont]), "catch", [_err_cont]);
  return new Result$Ok$7$(undefined);
}
function mizchi$js$core$$identity_option$23$(v) {
  return mizchi$js$core$$is_nullish(v) ? Option$None$8$ : new Option$Some$8$(v);
}
function mizchi$js$core$$identity_option$24$(v) {
  return mizchi$js$core$$is_nullish(v) ? Option$None$9$ : new Option$Some$9$(v);
}
function mizchi$js$core$$identity_option$4$(v) {
  return mizchi$js$core$$is_nullish(v) ? undefined : v;
}
function mizchi$js$builtins$arraybuffer$$Uint8Array$from_array_buffer$46$inner(buffer, byte_offset, length) {
  return mizchi$js$builtins$arraybuffer$$ffi_uint8array_from_buffer(buffer, byte_offset, length);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPipeline$get_bind_group_layout(self, index) {
  return mizchi$js$core$$Any$_call(self, "getBindGroupLayout", [index]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$preferred_canvas_format() {
  return Milky2018$mgstudio$45$runtime$45$web$webgpu$$preferred_canvas_format_raw();
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_render_attachment() {
  return mizchi$js$core$$Any$_get(Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_raw(), "RENDER_ATTACHMENT");
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_texture_binding() {
  return mizchi$js$core$$Any$_get(Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_raw(), "TEXTURE_BINDING");
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_copy_dst() {
  return mizchi$js$core$$Any$_get(Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_raw(), "COPY_DST");
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_usage_vertex() {
  return mizchi$js$core$$Any$_get(Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_usage_raw(), "VERTEX");
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_usage_uniform() {
  return mizchi$js$core$$Any$_get(Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_usage_raw(), "UNIFORM");
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_usage_copy_dst() {
  return mizchi$js$core$$Any$_get(Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_usage_raw(), "COPY_DST");
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$combine_flags(a, b) {
  return Milky2018$mgstudio$45$runtime$45$web$webgpu$$bit_or(a, b);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$queue(self) {
  return mizchi$js$core$$Any$_get(self, "queue");
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_buffer(self, descriptor) {
  return mizchi$js$core$$Any$_call(self, "createBuffer", [descriptor]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_texture(self, descriptor) {
  return mizchi$js$core$$Any$_call(self, "createTexture", [descriptor]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_sampler(self, descriptor) {
  return mizchi$js$core$$Any$_call(self, "createSampler", [descriptor]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_bind_group(self, descriptor) {
  return mizchi$js$core$$Any$_call(self, "createBindGroup", [descriptor]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_shader_module(self, descriptor) {
  return mizchi$js$core$$Any$_call(self, "createShaderModule", [descriptor]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_render_pipeline(self, descriptor) {
  return mizchi$js$core$$Any$_call(self, "createRenderPipeline", [descriptor]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_command_encoder(self, descriptor) {
  let value;
  if (descriptor.$tag === 1) {
    const _Some = descriptor;
    value = _Some._0;
  } else {
    value = mizchi$js$builtins$global$$undefined();
  }
  return mizchi$js$core$$Any$_call(self, "createCommandEncoder", [value]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUCommandEncoder$begin_render_pass(self, descriptor) {
  return mizchi$js$core$$Any$_call(self, "beginRenderPass", [descriptor]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUCommandEncoder$finish(self) {
  return mizchi$js$core$$Any$_call(self, "finish", []);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUQueue$submit(self, command_buffers) {
  mizchi$js$core$$Any$_call(self, "submit", [command_buffers]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUQueue$write_buffer(self, buffer, offset, data) {
  mizchi$js$core$$Any$_call(self, "writeBuffer", [buffer, offset, data]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUTexture$create_view(self, descriptor) {
  let value;
  if (descriptor.$tag === 1) {
    const _Some = descriptor;
    value = _Some._0;
  } else {
    value = mizchi$js$builtins$global$$undefined();
  }
  return mizchi$js$core$$Any$_call(self, "createView", [value]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$get_canvas_context(canvas) {
  return Milky2018$mgstudio$45$runtime$45$web$webgpu$$canvas_get_context(canvas);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUCanvasContext$configure(self, descriptor) {
  mizchi$js$core$$Any$_call(self, "configure", [descriptor]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUCanvasContext$get_current_texture(self) {
  return mizchi$js$core$$Any$_call(self, "getCurrentTexture", []);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$set_pipeline(self, pipeline) {
  mizchi$js$core$$Any$_call(self, "setPipeline", [pipeline]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$set_bind_group(self, index, bind_group) {
  mizchi$js$core$$Any$_call(self, "setBindGroup", [index, bind_group]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$set_vertex_buffer(self, slot, buffer) {
  mizchi$js$core$$Any$_call(self, "setVertexBuffer", [slot, buffer]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$set_viewport(self, x, y, width, height, min_depth, max_depth) {
  mizchi$js$core$$Any$_call(self, "setViewport", [x, y, width, height, min_depth, max_depth]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$set_scissor_rect(self, x, y, width, height) {
  mizchi$js$core$$Any$_call(self, "setScissorRect", [x, y, width, height]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$draw(self, vertex_count, instance_count, first_vertex, first_instance) {
  mizchi$js$core$$Any$_call(self, "draw", [vertex_count, instance_count, first_vertex, first_instance]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$end(self) {
  mizchi$js$core$$Any$_call(self, "end", []);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_format_from_string(value) {
  return value === "rgba8unorm" ? $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$TextureFormat$Rgba8Unorm : value === "bgra8unorm" ? $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$TextureFormat$Bgra8Unorm : new $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$TextureFormat$Other(value);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$TextureFormat$to_js_string(self) {
  switch (self.$tag) {
    case 0: {
      return "rgba8unorm";
    }
    case 1: {
      return "bgra8unorm";
    }
    default: {
      const _Other = self;
      return _Other._0;
    }
  }
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$FilterMode$to_js_string(self) {
  if (self === 0) {
    return "linear";
  } else {
    return "nearest";
  }
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$BlendFactor$to_js_string(self) {
  if (self === 0) {
    return "src-alpha";
  } else {
    return "one-minus-src-alpha";
  }
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$VertexFormat$to_js_string(self) {
  if (self === 0) {
    return "float32x2";
  } else {
    return "float32x4";
  }
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$color(r, g, b, a) {
  return { r: r, g: g, b: b, a: a };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$Color$to_js(self) {
  return mizchi$js$core$$from_entries([{ _0: "r", _1: self.r }, { _0: "g", _1: self.g }, { _0: "b", _1: self.b }, { _0: "a", _1: self.a }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$color_attachment_clear(view, clear) {
  return { view: view, clear: clear, load_op: 0, store_op: 0 };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$ColorAttachment$to_js(self) {
  const _tmp = { _0: "view", _1: self.view };
  const _tmp$2 = { _0: "clearValue", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$Color$to_js(self.clear) };
  self.load_op;
  const _tmp$3 = { _0: "loadOp", _1: "clear" };
  self.store_op;
  return mizchi$js$core$$from_entries([_tmp, _tmp$2, _tmp$3, { _0: "storeOp", _1: "store" }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$render_pass_descriptor(color_attachments) {
  return { color_attachments: color_attachments };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$RenderPassDescriptor$to_js(self) {
  const attachments = [];
  const _arr = self.color_attachments;
  const _len = _arr.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const attachment = _arr[_i];
      moonbitlang$core$array$$Array$push$8$(attachments, Milky2018$mgstudio$45$runtime$45$web$webgpu$$ColorAttachment$to_js(attachment));
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return mizchi$js$core$$from_entries([{ _0: "colorAttachments", _1: attachments }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$surface_size(width, height) {
  return { width: width, height: height };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$surface_configuration(device, format, alpha_mode, usage, size) {
  return { device: device, format: format, alpha_mode: alpha_mode, usage: usage, size: size };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$SurfaceConfiguration$to_js(self) {
  const _tmp = { _0: "device", _1: self.device };
  const _tmp$2 = { _0: "format", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$TextureFormat$to_js_string(self.format) };
  self.alpha_mode;
  const _tmp$3 = { _0: "alphaMode", _1: "premultiplied" };
  const _tmp$4 = { _0: "usage", _1: self.usage };
  const _p = self.size;
  return mizchi$js$core$$from_entries([_tmp, _tmp$2, _tmp$3, _tmp$4, { _0: "size", _1: [_p.width, _p.height] }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_size(width, height) {
  return { width: width, height: height, depth_or_array_layers: 1 };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_descriptor(size, format, usage) {
  return { size: size, format: format, usage: usage };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$TextureDescriptor$to_js(self) {
  const _p = self.size;
  return mizchi$js$core$$from_entries([{ _0: "size", _1: [_p.width, _p.height, _p.depth_or_array_layers] }, { _0: "format", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$TextureFormat$to_js_string(self.format) }, { _0: "usage", _1: self.usage }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_descriptor(size, usage) {
  return { size: size, usage: usage };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$BufferDescriptor$to_js(self) {
  return mizchi$js$core$$from_entries([{ _0: "size", _1: self.size }, { _0: "usage", _1: self.usage }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$sampler_descriptor(mag_filter, min_filter) {
  return { mag_filter: mag_filter, min_filter: min_filter };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$SamplerDescriptor$to_js(self) {
  return mizchi$js$core$$from_entries([{ _0: "magFilter", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$FilterMode$to_js_string(self.mag_filter) }, { _0: "minFilter", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$FilterMode$to_js_string(self.min_filter) }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$shader_module_descriptor(code) {
  return { code: code };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$ShaderModuleDescriptor$to_js(self) {
  return mizchi$js$core$$from_entries([{ _0: "code", _1: self.code }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$vertex_attribute(shader_location, offset, format) {
  return { shader_location: shader_location, offset: offset, format: format };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$VertexAttribute$to_js(self) {
  return mizchi$js$core$$from_entries([{ _0: "shaderLocation", _1: self.shader_location }, { _0: "offset", _1: self.offset }, { _0: "format", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$VertexFormat$to_js_string(self.format) }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$vertex_buffer_layout(array_stride, attributes) {
  return { array_stride: array_stride, attributes: attributes };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$VertexBufferLayout$to_js(self) {
  const attrs = [];
  const _arr = self.attributes;
  const _len = _arr.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const attr = _arr[_i];
      moonbitlang$core$array$$Array$push$8$(attrs, Milky2018$mgstudio$45$runtime$45$web$webgpu$$VertexAttribute$to_js(attr));
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return mizchi$js$core$$from_entries([{ _0: "arrayStride", _1: self.array_stride }, { _0: "attributes", _1: attrs }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$vertex_state(shader_module, entry_point, buffers) {
  return { shader_module: shader_module, entry_point: entry_point, buffers: buffers };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$VertexState$to_js(self) {
  const buffer_defs = [];
  const _arr = self.buffers;
  const _len = _arr.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const buffer_def = _arr[_i];
      moonbitlang$core$array$$Array$push$8$(buffer_defs, Milky2018$mgstudio$45$runtime$45$web$webgpu$$VertexBufferLayout$to_js(buffer_def));
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return mizchi$js$core$$from_entries([{ _0: "module", _1: self.shader_module }, { _0: "entryPoint", _1: self.entry_point }, { _0: "buffers", _1: buffer_defs }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$blend_component(src_factor, dst_factor, operation) {
  return { src_factor: src_factor, dst_factor: dst_factor, operation: operation };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$BlendComponent$to_js(self) {
  const _tmp = { _0: "srcFactor", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$BlendFactor$to_js_string(self.src_factor) };
  const _tmp$2 = { _0: "dstFactor", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$BlendFactor$to_js_string(self.dst_factor) };
  self.operation;
  return mizchi$js$core$$from_entries([_tmp, _tmp$2, { _0: "operation", _1: "add" }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$blend_state(color, alpha) {
  return { color: color, alpha: alpha };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$BlendState$to_js(self) {
  return mizchi$js$core$$from_entries([{ _0: "color", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$BlendComponent$to_js(self.color) }, { _0: "alpha", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$BlendComponent$to_js(self.alpha) }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$color_target_state(format, blend) {
  return { format: format, blend: blend };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$ColorTargetState$to_js(self) {
  return mizchi$js$core$$from_entries([{ _0: "format", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$TextureFormat$to_js_string(self.format) }, { _0: "blend", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$BlendState$to_js(self.blend) }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$fragment_state(shader_module, entry_point, targets) {
  return { shader_module: shader_module, entry_point: entry_point, targets: targets };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$FragmentState$to_js(self) {
  const target_defs = [];
  const _arr = self.targets;
  const _len = _arr.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const target = _arr[_i];
      moonbitlang$core$array$$Array$push$8$(target_defs, Milky2018$mgstudio$45$runtime$45$web$webgpu$$ColorTargetState$to_js(target));
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return mizchi$js$core$$from_entries([{ _0: "module", _1: self.shader_module }, { _0: "entryPoint", _1: self.entry_point }, { _0: "targets", _1: target_defs }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$primitive_state(topology) {
  return { topology: topology };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$PrimitiveState$to_js(self) {
  self.topology;
  return mizchi$js$core$$from_entries([{ _0: "topology", _1: "triangle-list" }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$render_pipeline_descriptor(layout, vertex, fragment, primitive) {
  return { layout: layout, vertex: vertex, fragment: fragment, primitive: primitive };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$RenderPipelineDescriptor$to_js(self) {
  self.layout;
  return mizchi$js$core$$from_entries([{ _0: "layout", _1: "auto" }, { _0: "vertex", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$VertexState$to_js(self.vertex) }, { _0: "fragment", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$FragmentState$to_js(self.fragment) }, { _0: "primitive", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$PrimitiveState$to_js(self.primitive) }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$BindGroupResource$to_js(self) {
  switch (self.$tag) {
    case 0: {
      const _Sampler = self;
      const _value = _Sampler._0;
      return _value;
    }
    case 1: {
      const _TextureView = self;
      const _value$2 = _TextureView._0;
      return _value$2;
    }
    default: {
      const _Buffer = self;
      const _value$3 = _Buffer._0;
      return mizchi$js$core$$from_entries([{ _0: "buffer", _1: _value$3 }]);
    }
  }
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$bind_group_entry_sampler(binding, sampler) {
  return { binding: binding, resource: new $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$BindGroupResource$Sampler(sampler) };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$bind_group_entry_texture(binding, view) {
  return { binding: binding, resource: new $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$BindGroupResource$TextureView(view) };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$bind_group_entry_buffer(binding, buffer) {
  return { binding: binding, resource: new $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$BindGroupResource$Buffer(buffer) };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$BindGroupEntry$to_js(self) {
  return mizchi$js$core$$from_entries([{ _0: "binding", _1: self.binding }, { _0: "resource", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$BindGroupResource$to_js(self.resource) }]);
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$bind_group_descriptor(layout, entries) {
  return { layout: layout, entries: entries };
}
function Milky2018$mgstudio$45$runtime$45$web$webgpu$$BindGroupDescriptor$to_js(self) {
  const entry_defs = [];
  const _arr = self.entries;
  const _len = _arr.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const entry = _arr[_i];
      moonbitlang$core$array$$Array$push$8$(entry_defs, Milky2018$mgstudio$45$runtime$45$web$webgpu$$BindGroupEntry$to_js(entry));
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return mizchi$js$core$$from_entries([{ _0: "layout", _1: self.layout }, { _0: "entries", _1: entry_defs }]);
}
function mizchi$js$web$event$$EventTarget$addEventListener$46$inner(self, event_type, handler, capture, once, passive, signal) {
  const entries = [];
  moonbitlang$core$array$$Array$push$16$(entries, { _0: "capture", _1: capture });
  moonbitlang$core$array$$Array$push$16$(entries, { _0: "once", _1: once });
  moonbitlang$core$array$$Array$push$16$(entries, { _0: "passive", _1: passive });
  if (signal.$tag === 1) {
    const _Some = signal;
    const _v = _Some._0;
    moonbitlang$core$array$$Array$push$16$(entries, { _0: "signal", _1: _v });
  }
  mizchi$js$core$$Any$_call(self, "addEventListener", [event_type, handler, mizchi$js$core$$from_entries(entries)]);
}
function mizchi$js$web$http$$fetch$46$inner(url, method_, headers, cache, mode, body, credentials, integrity, keepalive, priority, redirect, referrer, referrerPolicy, signal, _cont, _err_cont) {
  const header_obj = mizchi$js$core$$new_object();
  const _it = moonbitlang$core$builtin$$Map$iter2$19$(headers);
  while (true) {
    const _bind = moonbitlang$core$builtin$$Iter2$next$19$(_it);
    if (_bind === undefined) {
      break;
    } else {
      const _Some = _bind;
      const _x = _Some;
      const _k = _x._0;
      const _v = _x._1;
      mizchi$js$core$$Any$_set(header_obj, _k, _v);
      continue;
    }
  }
  const entries = [];
  moonbitlang$core$array$$Array$push$16$(entries, { _0: "method", _1: method_ });
  moonbitlang$core$array$$Array$push$16$(entries, { _0: "headers", _1: header_obj });
  if (body.$tag === 1) {
    const _Some = body;
    const _v = _Some._0;
    moonbitlang$core$array$$Array$push$16$(entries, { _0: "body", _1: _v });
  }
  if (cache === undefined) {
  } else {
    const _Some = cache;
    const _v = _Some;
    moonbitlang$core$array$$Array$push$16$(entries, { _0: "cache", _1: _v });
  }
  if (mode === undefined) {
  } else {
    const _Some = mode;
    const _v = _Some;
    moonbitlang$core$array$$Array$push$16$(entries, { _0: "mode", _1: _v });
  }
  if (credentials === undefined) {
  } else {
    const _Some = credentials;
    const _v = _Some;
    moonbitlang$core$array$$Array$push$16$(entries, { _0: "credentials", _1: _v });
  }
  if (integrity === undefined) {
  } else {
    const _Some = integrity;
    const _v = _Some;
    moonbitlang$core$array$$Array$push$16$(entries, { _0: "integrity", _1: _v });
  }
  if (keepalive === -1) {
  } else {
    const _Some = keepalive;
    const _v = _Some;
    moonbitlang$core$array$$Array$push$16$(entries, { _0: "keepalive", _1: _v });
  }
  if (priority === undefined) {
  } else {
    const _Some = priority;
    const _v = _Some;
    moonbitlang$core$array$$Array$push$16$(entries, { _0: "priority", _1: _v });
  }
  if (redirect === undefined) {
  } else {
    const _Some = redirect;
    const _v = _Some;
    moonbitlang$core$array$$Array$push$16$(entries, { _0: "redirect", _1: _v });
  }
  if (referrer === undefined) {
  } else {
    const _Some = referrer;
    const _v = _Some;
    moonbitlang$core$array$$Array$push$16$(entries, { _0: "referrer", _1: _v });
  }
  if (referrerPolicy === undefined) {
  } else {
    const _Some = referrerPolicy;
    const _v = _Some;
    moonbitlang$core$array$$Array$push$16$(entries, { _0: "referrerPolicy", _1: _v });
  }
  if (signal.$tag === 1) {
    const _Some = signal;
    const _v = _Some._0;
    moonbitlang$core$array$$Array$push$16$(entries, { _0: "signal", _1: _v });
  }
  const init_obj = mizchi$js$core$$from_entries(entries);
  return mizchi$js$core$$Promise$wait$22$(mizchi$js$web$http$$ffi_fetch(url, init_obj), _cont, _err_cont);
}
function mizchi$js$web$http$$fetch(url, method_, headers$46$opt, cache, mode, body, credentials, integrity, keepalive, priority, redirect, referrer, referrerPolicy, signal, _cont, _err_cont) {
  let headers;
  if (headers$46$opt === undefined) {
    const _bind = [];
    headers = moonbitlang$core$builtin$$Map$from_array$19$({ buf: _bind, start: 0, end: 0 });
  } else {
    const _Some = headers$46$opt;
    headers = _Some;
  }
  return mizchi$js$web$http$$fetch$46$inner(url, method_, headers, cache, mode, body, credentials, integrity, keepalive, priority, redirect, referrer, referrerPolicy, signal, _cont, _err_cont);
}
function mizchi$js$browser$dom$$Element$getAttribute(self, name) {
  const v = mizchi$js$core$$Any$_call(self, "getAttribute", [name]);
  return mizchi$js$core$$identity_option$4$(v);
}
function mizchi$js$browser$dom$$Element$getElementsByTagName(self, tag_name) {
  const arr = mizchi$js$core$$Any$_call(self, "getElementsByTagName", [tag_name]);
  const _p = mizchi$js$core$$array_from(arr);
  const _p$2 = new Array(_p.length);
  const _p$3 = _p.length;
  let _tmp = 0;
  while (true) {
    const _p$4 = _tmp;
    if (_p$4 < _p$3) {
      const _p$5 = _p[_p$4];
      _p$2[_p$4] = _p$5;
      _tmp = _p$4 + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return _p$2;
}
function mizchi$js$browser$dom$$Document$getElementById(self, id) {
  const v = mizchi$js$core$$Any$_call(self, "getElementById", [id]);
  return mizchi$js$core$$identity_option$23$(v);
}
function mizchi$js$browser$dom$$Document$body(self) {
  const v = mizchi$js$core$$Any$_get(self, "body");
  return mizchi$js$core$$identity_option$24$(v);
}
function mizchi$js$browser$dom$$Document$setTitle(self, title) {
  mizchi$js$core$$Any$_set(self, "title", title);
}
function mizchi$js$web$webassembly$$WebAssemblyInstance$exports(self) {
  return mizchi$js$core$$Any$_get(self, "exports");
}
function Milky2018$mgstudio$45$runtime$45$web$$set_style(style, name, value) {
  mizchi$js$core$$Any$_set(style, name, value);
}
function Milky2018$mgstudio$45$runtime$45$web$$set_text(element, text) {
  mizchi$js$core$$Any$_set(element, "textContent", text);
}
function Milky2018$mgstudio$45$runtime$45$web$$create_status_overlay(doc) {
  const overlay = mizchi$js$browser$dom$$Document$createElement(doc, "div");
  const style = mizchi$js$core$$Any$_get(overlay, "style");
  Milky2018$mgstudio$45$runtime$45$web$$set_style(style, "position", "fixed");
  Milky2018$mgstudio$45$runtime$45$web$$set_style(style, "left", "12px");
  Milky2018$mgstudio$45$runtime$45$web$$set_style(style, "top", "12px");
  Milky2018$mgstudio$45$runtime$45$web$$set_style(style, "padding", "8px 12px");
  Milky2018$mgstudio$45$runtime$45$web$$set_style(style, "background", "rgba(0, 0, 0, 0.7)");
  Milky2018$mgstudio$45$runtime$45$web$$set_style(style, "color", "#ffffff");
  Milky2018$mgstudio$45$runtime$45$web$$set_style(style, "fontFamily", "monospace");
  Milky2018$mgstudio$45$runtime$45$web$$set_style(style, "fontSize", "12px");
  Milky2018$mgstudio$45$runtime$45$web$$set_style(style, "zIndex", "9999");
  Milky2018$mgstudio$45$runtime$45$web$$set_text(overlay, "Loading...");
  const _bind = mizchi$js$browser$dom$$Document$body(doc);
  if (_bind.$tag === 1) {
    const _Some = _bind;
    const _body = _Some._0;
    mizchi$js$core$$Any$_call(_body, "appendChild", [overlay]);
  } else {
    mizchi$js$core$$Any$_call(mizchi$js$core$$Any$_get(doc, "documentElement"), "appendChild", [overlay]);
  }
  const set_status = (text) => {
    Milky2018$mgstudio$45$runtime$45$web$$set_text(overlay, text);
  };
  return set_status;
}
function Milky2018$mgstudio$45$runtime$45$web$$make_print_char() {
  const buffer = { val: "" };
  const handle = (code) => {
    const char = Milky2018$mgstudio$45$runtime$45$web$$char_from_code(code);
    if (char === "\n") {
      mizchi$js$core$$log(buffer.val);
      buffer.val = "";
      return;
    } else {
      buffer.val = `${buffer.val}${char}`;
      return;
    }
  };
  return handle;
}
function Milky2018$mgstudio$45$runtime$45$web$$make_closure(funcref, closure) {
  return mizchi$js$core$$Any$_call(funcref, "bind", [mizchi$js$builtins$global$$undefined(), closure]);
}
function Milky2018$mgstudio$45$runtime$45$web$$setup_menu(doc, on_run, on_reload) {
  const menu = mizchi$js$browser$dom$$Document$getElementById(doc, "mgstudio-menu");
  if (menu.$tag === 1) {
    const _Some = menu;
    const _menu_el = _Some._0;
    const buttons = mizchi$js$browser$dom$$Element$getElementsByTagName(_menu_el, "button");
    const _len = buttons.length;
    let _tmp = 0;
    while (true) {
      const _i = _tmp;
      if (_i < _len) {
        const button = buttons[_i];
        const run_target = mizchi$js$browser$dom$$Element$getAttribute(button, "data-run");
        const action = mizchi$js$browser$dom$$Element$getAttribute(button, "data-action");
        if (run_target === undefined) {
          if (action === undefined) {
          } else {
            const _Some$2 = action;
            const _value = _Some$2;
            if (_value === "reload") {
              mizchi$js$web$event$$EventTarget$addEventListener$46$inner(button, "click", (_discard_) => {
                on_reload();
              }, false, false, false, Option$None$10$);
            }
          }
        } else {
          const _Some$2 = run_target;
          const _target = _Some$2;
          mizchi$js$web$event$$EventTarget$addEventListener$46$inner(button, "click", (_discard_) => {
            on_run(_target, button);
          }, false, false, false, Option$None$10$);
        }
        _tmp = _i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    return true;
  } else {
    return false;
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$load_wasm$46$42$async_driver$124$1145(_state) {
  let _tmp = _state;
  _L: while (true) {
    const _state$2 = _tmp;
    switch (_state$2.$tag) {
      case 0: {
        const _State_0 = _state$2;
        const _cont_param = _State_0._0;
        return new Result$Ok$11$(new Option$Some$12$(_cont_param));
      }
      case 1: {
        const _State_1 = _state$2;
        const _cont_param$2 = _State_1._0;
        _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_0(mizchi$js$core$$Any$_get(_cont_param$2, "instance"));
        continue _L;
      }
      case 2: {
        const _State_2 = _state$2;
        const _err_cont = _State_2._4;
        const _cont = _State_2._3;
        const wasm_options = _State_2._2;
        const imports = _State_2._1;
        const _cont_param$3 = _State_2._0;
        const bytes = mizchi$js$builtins$arraybuffer$$Uint8Array$from_array_buffer$46$inner(_cont_param$3, 0, undefined);
        const promise = Milky2018$mgstudio$45$runtime$45$web$$instantiate_bytes_with_options(bytes, imports, wasm_options);
        const _bind = mizchi$js$core$$Promise$wait$8$(promise, (_cont_param$4) => {
          let _err;
          _L$2: {
            const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$load_wasm$46$42$async_driver$124$1145(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_1(_cont_param$4));
            let _tmp$2;
            if (_bind$2.$tag === 1) {
              const _ok = _bind$2;
              _tmp$2 = _ok._0;
            } else {
              const _err$2 = _bind$2;
              const _tmp$3 = _err$2._0;
              _err = _tmp$3;
              break _L$2;
            }
            const _tmp$3 = _tmp$2;
            if (_tmp$3.$tag === 1) {
              const _Some = _tmp$3;
              const _payload = _Some._0;
              _cont(_payload);
              return;
            } else {
              return;
            }
          }
          _err_cont(_err);
        }, _err_cont);
        let _tmp$2;
        if (_bind.$tag === 1) {
          const _ok = _bind;
          _tmp$2 = _ok._0;
        } else {
          return _bind;
        }
        const _tmp$3 = _tmp$2;
        if (_tmp$3.$tag === 1) {
          const _Some = _tmp$3;
          const _payload = _Some._0;
          _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_1(_payload);
          continue _L;
        } else {
          return new Result$Ok$11$(Option$None$12$);
        }
      }
      case 3: {
        const _$42$try$47$663 = _state$2;
        const _err_cont$2 = _$42$try$47$663._5;
        const _cont$2 = _$42$try$47$663._4;
        const wasm_options$2 = _$42$try$47$663._3;
        const fallback = _$42$try$47$663._2;
        const imports$2 = _$42$try$47$663._1;
        const buffer_promise = Milky2018$mgstudio$45$runtime$45$web$$response_array_buffer(fallback);
        const _bind$2 = mizchi$js$core$$Promise$wait$21$(buffer_promise, (_cont_param$4) => {
          let _err;
          _L$2: {
            const _bind$3 = Milky2018$mgstudio$45$runtime$45$web$$load_wasm$46$42$async_driver$124$1145(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_2(_cont_param$4, imports$2, wasm_options$2, _cont$2, _err_cont$2));
            let _tmp$4;
            if (_bind$3.$tag === 1) {
              const _ok = _bind$3;
              _tmp$4 = _ok._0;
            } else {
              const _err$2 = _bind$3;
              const _tmp$5 = _err$2._0;
              _err = _tmp$5;
              break _L$2;
            }
            const _tmp$5 = _tmp$4;
            if (_tmp$5.$tag === 1) {
              const _Some = _tmp$5;
              const _payload = _Some._0;
              _cont$2(_payload);
              return;
            } else {
              return;
            }
          }
          _err_cont$2(_err);
        }, _err_cont$2);
        let _bind$3;
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          _bind$3 = _ok._0;
        } else {
          return _bind$2;
        }
        if (_bind$3 === undefined) {
          return new Result$Ok$11$(Option$None$12$);
        } else {
          const _Some = _bind$3;
          const _payload = _Some;
          _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_2(_payload, imports$2, wasm_options$2, _cont$2, _err_cont$2);
          continue _L;
        }
      }
      case 4: {
        const _State_4 = _state$2;
        const _cont_param$4 = _State_4._0;
        _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_0(mizchi$js$core$$Any$_get(_cont_param$4, "instance"));
        continue _L;
      }
      default: {
        const _State_5 = _state$2;
        const _err_cont$3 = _State_5._3;
        const _cont$3 = _State_5._2;
        const imports$3 = _State_5._1;
        const _cont_param$5 = _State_5._0;
        if (!_cont_param$5.ok) {
          const _bind$4 = moonbitlang$core$builtin$$fail$14$(`Failed to fetch runner.wasm: ${moonbitlang$core$int$$Int$to_string$46$inner(_cont_param$5.status, 10)}`, "@Milky2018/mgstudio-runtime-web:main.mbt:188:5-188:72");
          if (_bind$4.$tag === 1) {
            const _ok = _bind$4;
            _ok._0;
          } else {
            return _bind$4;
          }
        }
        const fallback$2 = mizchi$js$web$http$$Response$clone(_cont_param$5);
        const wasm_options$3 = mizchi$js$core$$from_entries([{ _0: "builtins", _1: ["js-string"] }, { _0: "importedStringConstants", _1: "_" }]);
        const promise$2 = Milky2018$mgstudio$45$runtime$45$web$$instantiate_streaming(_cont_param$5, imports$3, wasm_options$3);
        let _err;
        _L$2: {
          const _bind$4 = mizchi$js$core$$Promise$wait$8$(promise$2, (_cont_param$6) => {
            let _err$2;
            _L$3: {
              const _bind$5 = Milky2018$mgstudio$45$runtime$45$web$$load_wasm$46$42$async_driver$124$1145(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_4(_cont_param$6));
              let _tmp$4;
              if (_bind$5.$tag === 1) {
                const _ok = _bind$5;
                _tmp$4 = _ok._0;
              } else {
                const _err$3 = _bind$5;
                const _tmp$5 = _err$3._0;
                _err$2 = _tmp$5;
                break _L$3;
              }
              const _tmp$5 = _tmp$4;
              if (_tmp$5.$tag === 1) {
                const _Some = _tmp$5;
                const _payload = _Some._0;
                _cont$3(_payload);
                return;
              } else {
                return;
              }
            }
            _err_cont$3(_err$2);
          }, (_cont_param$6) => {
            let _err$2;
            _L$3: {
              const _bind$5 = Milky2018$mgstudio$45$runtime$45$web$$load_wasm$46$42$async_driver$124$1145(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$_try$47$663(_cont_param$6, imports$3, fallback$2, wasm_options$3, _cont$3, _err_cont$3));
              let _tmp$4;
              if (_bind$5.$tag === 1) {
                const _ok = _bind$5;
                _tmp$4 = _ok._0;
              } else {
                const _err$3 = _bind$5;
                const _tmp$5 = _err$3._0;
                _err$2 = _tmp$5;
                break _L$3;
              }
              const _tmp$5 = _tmp$4;
              if (_tmp$5.$tag === 1) {
                const _Some = _tmp$5;
                const _payload = _Some._0;
                _cont$3(_payload);
                return;
              } else {
                return;
              }
            }
            _err_cont$3(_err$2);
          });
          let _tmp$4;
          if (_bind$4.$tag === 1) {
            const _ok = _bind$4;
            _tmp$4 = _ok._0;
          } else {
            const _err$2 = _bind$4;
            const _tmp$5 = _err$2._0;
            _err = _tmp$5;
            break _L$2;
          }
          const _tmp$5 = _tmp$4;
          if (_tmp$5.$tag === 1) {
            const _Some = _tmp$5;
            const _payload = _Some._0;
            _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_4(_payload);
            continue _L;
          } else {
            return new Result$Ok$11$(Option$None$12$);
          }
        }
        _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$_try$47$663(_err, imports$3, fallback$2, wasm_options$3, _cont$3, _err_cont$3);
        continue _L;
      }
    }
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$load_wasm(imports, _cont, _err_cont) {
  const _bind = mizchi$js$web$http$$fetch("./runner.wasm", "GET", undefined, undefined, undefined, Option$None$4$, undefined, undefined, -1, undefined, undefined, undefined, undefined, Option$None$10$, (_cont_param) => {
    let _err;
    _L: {
      const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$load_wasm$46$42$async_driver$124$1145(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_5(_cont_param, imports, _cont, _err_cont));
      let _tmp;
      if (_bind$2.$tag === 1) {
        const _ok = _bind$2;
        _tmp = _ok._0;
      } else {
        const _err$2 = _bind$2;
        const _tmp$2 = _err$2._0;
        _err = _tmp$2;
        break _L;
      }
      const _tmp$2 = _tmp;
      if (_tmp$2.$tag === 1) {
        const _Some = _tmp$2;
        const _payload = _Some._0;
        _cont(_payload);
        return;
      } else {
        return;
      }
    }
    _err_cont(_err);
  }, _err_cont);
  let _bind$2;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    _bind$2 = _ok._0;
  } else {
    return _bind;
  }
  if (_bind$2 === undefined) {
    return new Result$Ok$11$(Option$None$12$);
  } else {
    const _Some = _bind$2;
    const _payload = _Some;
    return Milky2018$mgstudio$45$runtime$45$web$$load_wasm$46$42$async_driver$124$1145(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wasm$46$State$State_5(_payload, imports, _cont, _err_cont));
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$arg_any(args, index) {
  return index < args.length ? moonbitlang$core$array$$Array$at$8$(args, index) : Milky2018$mgstudio$45$runtime$45$web$$js_undefined();
}
function Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, index, fallback) {
  return Milky2018$mgstudio$45$runtime$45$web$$number_or(Milky2018$mgstudio$45$runtime$45$web$$arg_any(args, index), fallback);
}
function Milky2018$mgstudio$45$runtime$45$web$$create_sampler(state, nearest) {
  const _bind = state.gpu.device;
  if (_bind.$tag === 0) {
    return Option$None$13$;
  }
  const _bind$2 = state.gpu.device;
  if (_bind$2.$tag === 1) {
    const _Some = _bind$2;
    const _device = _Some._0;
    const filter = nearest ? 1 : 0;
    const descriptor = Milky2018$mgstudio$45$runtime$45$web$webgpu$$sampler_descriptor(filter, filter);
    return new Option$Some$13$(Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_sampler(_device, Milky2018$mgstudio$45$runtime$45$web$webgpu$$SamplerDescriptor$to_js(descriptor)));
  } else {
    return Option$None$13$;
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$get_shader_source(state, id) {
  const entry = Milky2018$mgstudio$45$runtime$45$web$$map_get(state.assets.shader_sources, id);
  return Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(entry) ? undefined : entry;
}
function Milky2018$mgstudio$45$runtime$45$web$$ensure_pipeline_resources(state) {
  const _bind = state.gpu.pipeline;
  if (_bind.$tag === 1) {
    return undefined;
  }
  const _bind$2 = state.gpu.device;
  if (_bind$2.$tag === 0) {
    return undefined;
  }
  const _bind$3 = state.gpu.device;
  if (_bind$3.$tag === 1) {
    const _Some = _bind$3;
    const _device = _Some._0;
    if (state.gpu.sprite_shader_id <= 0) {
      return undefined;
    }
    const shader_source = Milky2018$mgstudio$45$runtime$45$web$$get_shader_source(state, state.gpu.sprite_shader_id);
    if (shader_source === undefined) {
      return undefined;
    }
    const _p = state.gpu.format;
    const _p$2 = $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$TextureFormat$Bgra8Unorm;
    let format;
    if (_p === undefined) {
      format = _p$2;
    } else {
      const _p$3 = _p;
      format = _p$3;
    }
    let _tmp;
    if (shader_source === undefined) {
      _tmp = $panic();
    } else {
      const _p$3 = shader_source;
      _tmp = _p$3;
    }
    const shader_desc = Milky2018$mgstudio$45$runtime$45$web$webgpu$$shader_module_descriptor(_tmp);
    const shader_module = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_shader_module(_device, Milky2018$mgstudio$45$runtime$45$web$webgpu$$ShaderModuleDescriptor$to_js(shader_desc));
    const position_attr = Milky2018$mgstudio$45$runtime$45$web$webgpu$$vertex_attribute(0, 0, 0);
    const uv_attr = Milky2018$mgstudio$45$runtime$45$web$webgpu$$vertex_attribute(1, 8, 0);
    const vertex_layout = Milky2018$mgstudio$45$runtime$45$web$webgpu$$vertex_buffer_layout(16, [position_attr, uv_attr]);
    const vertex_state = Milky2018$mgstudio$45$runtime$45$web$webgpu$$vertex_state(shader_module, "vs_main", [vertex_layout]);
    const blend_component = Milky2018$mgstudio$45$runtime$45$web$webgpu$$blend_component(0, 1, 0);
    const blend_state = Milky2018$mgstudio$45$runtime$45$web$webgpu$$blend_state(blend_component, blend_component);
    const color_target = Milky2018$mgstudio$45$runtime$45$web$webgpu$$color_target_state(format, blend_state);
    const fragment_state = Milky2018$mgstudio$45$runtime$45$web$webgpu$$fragment_state(shader_module, "fs_main", [color_target]);
    const primitive_state = Milky2018$mgstudio$45$runtime$45$web$webgpu$$primitive_state(0);
    const pipeline_desc = Milky2018$mgstudio$45$runtime$45$web$webgpu$$render_pipeline_descriptor(0, vertex_state, fragment_state, primitive_state);
    const pipeline = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_render_pipeline(_device, Milky2018$mgstudio$45$runtime$45$web$webgpu$$RenderPipelineDescriptor$to_js(pipeline_desc));
    const vertices = Milky2018$mgstudio$45$runtime$45$web$$create_sprite_vertices();
    const vertex_size = mizchi$js$core$$Any$_get(vertices, "byteLength");
    const vertex_usage = Milky2018$mgstudio$45$runtime$45$web$webgpu$$combine_flags(Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_usage_vertex(), Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_usage_copy_dst());
    const vertex_desc = Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_descriptor(vertex_size, vertex_usage);
    const vertex_buffer = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_buffer(_device, Milky2018$mgstudio$45$runtime$45$web$webgpu$$BufferDescriptor$to_js(vertex_desc));
    Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUQueue$write_buffer(Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$queue(_device), vertex_buffer, 0, vertices);
    const uniform_usage = Milky2018$mgstudio$45$runtime$45$web$webgpu$$combine_flags(Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_usage_uniform(), Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_usage_copy_dst());
    const uniform_desc = Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_descriptor(64, uniform_usage);
    const uniform_buffer = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_buffer(_device, Milky2018$mgstudio$45$runtime$45$web$webgpu$$BufferDescriptor$to_js(uniform_desc));
    const texture_usage = Milky2018$mgstudio$45$runtime$45$web$webgpu$$combine_flags(Milky2018$mgstudio$45$runtime$45$web$webgpu$$combine_flags(Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_texture_binding(), Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_copy_dst()), Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_render_attachment());
    const texture_desc = Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_descriptor(Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_size(64, 64), $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$TextureFormat$Rgba8Unorm, texture_usage);
    const texture = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_texture(_device, Milky2018$mgstudio$45$runtime$45$web$webgpu$$TextureDescriptor$to_js(texture_desc));
    const pixel_data = Milky2018$mgstudio$45$runtime$45$web$$create_checkerboard_data(64);
    Milky2018$mgstudio$45$runtime$45$web$$write_texture(Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$queue(_device), texture, pixel_data, 256, 64, 64);
    const sampler = Milky2018$mgstudio$45$runtime$45$web$$create_sampler(state, true);
    if (sampler.$tag === 1) {
      const _Some$2 = sampler;
      const _sampler_value = _Some$2._0;
      const entry = mizchi$js$core$$from_entries([{ _0: "id", _1: state.gpu.fallback_texture_id }, { _0: "texture", _1: texture }, { _0: "view", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUTexture$create_view(texture, Option$None$4$) }, { _0: "sampler", _1: _sampler_value }, { _0: "bindGroup", _1: Milky2018$mgstudio$45$runtime$45$web$$js_null() }, { _0: "width", _1: 64 }, { _0: "height", _1: 64 }]);
      Milky2018$mgstudio$45$runtime$45$web$$map_set(state.gpu.textures, state.gpu.fallback_texture_id, entry);
    }
    state.gpu.pipeline = new Option$Some$14$(pipeline);
    state.gpu.vertex_buffer = new Option$Some$15$(vertex_buffer);
    state.gpu.vertex_count = 6;
    state.gpu.uniform_buffer = new Option$Some$15$(uniform_buffer);
    return;
  } else {
    return;
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$update_window_size(state) {
  const _bind = state.window;
  if (_bind === undefined) {
    return undefined;
  }
  const _bind$2 = state.window;
  if (_bind$2 === undefined) {
    return;
  } else {
    const _Some = _bind$2;
    const _window_state = _Some;
    const target = _window_state.canvas;
    const size = Milky2018$mgstudio$45$runtime$45$web$$get_canvas_pixel_size(target);
    const width = mizchi$js$core$$Any$_get(size, "width");
    const height = mizchi$js$core$$Any$_get(size, "height");
    const scale_factor = Milky2018$mgstudio$45$runtime$45$web$$get_device_pixel_ratio();
    if (width === _window_state.width && (height === _window_state.height && scale_factor === _window_state.scale_factor)) {
      return undefined;
    }
    _window_state.width = width;
    _window_state.height = height;
    _window_state.scale_factor = scale_factor;
    mizchi$js$core$$Any$_set(target, "width", width);
    mizchi$js$core$$Any$_set(target, "height", height);
    const _bind$3 = state.gpu.context;
    if (_bind$3.$tag === 1) {
      const _Some$2 = _bind$3;
      const _context = _Some$2._0;
      const _bind$4 = state.gpu.device;
      if (_bind$4.$tag === 1) {
        const _Some$3 = _bind$4;
        const _device = _Some$3._0;
        const usage = Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_render_attachment();
        const _p = state.gpu.format;
        const _p$2 = $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$TextureFormat$Bgra8Unorm;
        let _tmp;
        if (_p === undefined) {
          _tmp = _p$2;
        } else {
          const _p$3 = _p;
          _tmp = _p$3;
        }
        const config = Milky2018$mgstudio$45$runtime$45$web$webgpu$$surface_configuration(_device, _tmp, 0, usage, Milky2018$mgstudio$45$runtime$45$web$webgpu$$surface_size(width, height));
        Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUCanvasContext$configure(_context, Milky2018$mgstudio$45$runtime$45$web$webgpu$$SurfaceConfiguration$to_js(config));
        return;
      } else {
        return;
      }
    } else {
      return;
    }
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$begin_frame(state) {
  _L: {
    _L$2: {
      const _bind = state.gpu.context;
      if (_bind.$tag === 0) {
        break _L$2;
      } else {
        const _bind$2 = state.gpu.device;
        if (_bind$2.$tag === 0) {
          break _L$2;
        }
      }
      break _L;
    }
    return 0;
  }
  const _bind = state.gpu.context;
  if (_bind.$tag === 1) {
    const _Some = _bind;
    const _context = _Some._0;
    const _bind$2 = state.gpu.device;
    if (_bind$2.$tag === 1) {
      const _Some$2 = _bind$2;
      const _device = _Some$2._0;
      Milky2018$mgstudio$45$runtime$45$web$$update_window_size(state);
      Milky2018$mgstudio$45$runtime$45$web$$ensure_pipeline_resources(state);
      state.gpu.encoder = new Option$Some$16$(Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_command_encoder(_device, Option$None$4$));
      state.gpu.current_texture = new Option$Some$17$(Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUCanvasContext$get_current_texture(_context));
      return 1;
    }
  }
  return 0;
}
function Milky2018$mgstudio$45$runtime$45$web$$to_int(value) {
  return moonbitlang$core$double$$Double$to_int(value);
}
function Milky2018$mgstudio$45$runtime$45$web$$begin_pass(state, target_id, width, height, clear_r, clear_g, clear_b, clear_a, cam_x, cam_y, cam_rotation, cam_scale, viewport_x, viewport_y, viewport_width, viewport_height) {
  const _bind = state.gpu.encoder;
  if (_bind.$tag === 0) {
    return undefined;
  }
  const _bind$2 = state.gpu.encoder;
  if (_bind$2.$tag === 1) {
    const _Some = _bind$2;
    const _encoder = _Some._0;
    let view = Option$None$18$;
    if (target_id < 0) {
      const _bind$3 = state.gpu.current_texture;
      if (_bind$3.$tag === 1) {
        const _Some$2 = _bind$3;
        const _current_texture = _Some$2._0;
        view = new Option$Some$18$(Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUTexture$create_view(_current_texture, Option$None$4$));
      }
    } else {
      const target_entry = Milky2018$mgstudio$45$runtime$45$web$$map_get(state.gpu.textures, target_id);
      if (!Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(target_entry)) {
        const view_any = mizchi$js$core$$Any$_get(target_entry, "view");
        if (!Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(view_any)) {
          view = new Option$Some$18$(view_any);
        }
      }
    }
    const _bind$3 = view;
    if (_bind$3.$tag === 0) {
      return undefined;
    }
    const _bind$4 = view;
    if (_bind$4.$tag === 1) {
      const _Some$2 = _bind$4;
      const _view_value = _Some$2._0;
      const clear_color = Milky2018$mgstudio$45$runtime$45$web$webgpu$$color(clear_r, clear_g, clear_b, clear_a);
      const attachment = Milky2018$mgstudio$45$runtime$45$web$webgpu$$color_attachment_clear(_view_value, clear_color);
      const descriptor = Milky2018$mgstudio$45$runtime$45$web$webgpu$$render_pass_descriptor([attachment]);
      const pass = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUCommandEncoder$begin_render_pass(_encoder, Milky2018$mgstudio$45$runtime$45$web$webgpu$$RenderPassDescriptor$to_js(descriptor));
      const vp_width = viewport_width > 0 ? viewport_width : width;
      const vp_height = viewport_height > 0 ? viewport_height : height;
      const vp_x = viewport_width > 0 ? viewport_x : 0;
      const vp_y = viewport_height > 0 ? viewport_y : 0;
      Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$set_viewport(pass, vp_x, vp_y, vp_width, vp_height, 0, 1);
      Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$set_scissor_rect(pass, Milky2018$mgstudio$45$runtime$45$web$$to_int(vp_x), Milky2018$mgstudio$45$runtime$45$web$$to_int(vp_y), Milky2018$mgstudio$45$runtime$45$web$$to_int(vp_width), Milky2018$mgstudio$45$runtime$45$web$$to_int(vp_height));
      state.gpu.current_pass = new Option$Some$19$(pass);
      state.gpu.current_pass_info = { width: width > 0 ? width : 1, height: height > 0 ? height : 1, cam_x: cam_x, cam_y: cam_y, cam_rotation: cam_rotation, cam_scale: cam_scale };
      state.gpu.gizmo_lines = Milky2018$mgstudio$45$runtime$45$web$$new_array();
      return;
    } else {
      return;
    }
  } else {
    return;
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$mouse_button_name(button) {
  return button === 0 ? Milky2018$mgstudio$45$runtime$45$web$$mouse_button_name$46$constr$47$941 : button === 1 ? Milky2018$mgstudio$45$runtime$45$web$$mouse_button_name$46$constr$47$942 : button === 2 ? Milky2018$mgstudio$45$runtime$45$web$$mouse_button_name$46$constr$47$943 : undefined;
}
function Milky2018$mgstudio$45$runtime$45$web$$update_mouse_position(state, target, event) {
  const rect = Milky2018$mgstudio$45$runtime$45$web$$get_bounding_rect(target);
  const client_x = mizchi$js$core$$Any$_get(event, "clientX");
  const client_y = mizchi$js$core$$Any$_get(event, "clientY");
  const left = mizchi$js$core$$Any$_get(rect, "left");
  const top = mizchi$js$core$$Any$_get(rect, "top");
  state.input.mouse_x = client_x - left;
  state.input.mouse_y = client_y - top;
  state.input.has_cursor = true;
}
function Milky2018$mgstudio$45$runtime$45$web$$bind_pointer_events(state, target) {
  if (state.input.pointer_bound) {
    return undefined;
  }
  state.input.pointer_bound = true;
  Milky2018$mgstudio$45$runtime$45$web$$add_event_listener(target, "pointermove", (event) => {
    Milky2018$mgstudio$45$runtime$45$web$$update_mouse_position(state, target, event);
  });
  Milky2018$mgstudio$45$runtime$45$web$$add_event_listener(target, "pointerdown", (event) => {
    const button = mizchi$js$core$$Any$_get(event, "button");
    const name = Milky2018$mgstudio$45$runtime$45$web$$mouse_button_name(button);
    if (name === undefined) {
    } else {
      const _Some = name;
      const _label = _Some;
      if (!Milky2018$mgstudio$45$runtime$45$web$$set_has(state.input.mouse_buttons, _label)) {
        Milky2018$mgstudio$45$runtime$45$web$$set_add(state.input.mouse_buttons, _label);
        Milky2018$mgstudio$45$runtime$45$web$$set_add(state.input.mouse_just_pressed, _label);
      }
    }
    Milky2018$mgstudio$45$runtime$45$web$$update_mouse_position(state, target, event);
  });
  Milky2018$mgstudio$45$runtime$45$web$$add_event_listener(target, "pointerup", (event) => {
    const button = mizchi$js$core$$Any$_get(event, "button");
    const name = Milky2018$mgstudio$45$runtime$45$web$$mouse_button_name(button);
    if (name === undefined) {
    } else {
      const _Some = name;
      const _label = _Some;
      if (Milky2018$mgstudio$45$runtime$45$web$$set_delete(state.input.mouse_buttons, _label)) {
        Milky2018$mgstudio$45$runtime$45$web$$set_add(state.input.mouse_just_released, _label);
      }
    }
    Milky2018$mgstudio$45$runtime$45$web$$update_mouse_position(state, target, event);
  });
  Milky2018$mgstudio$45$runtime$45$web$$add_event_listener(target, "pointerleave", (_discard_) => {
    state.input.has_cursor = false;
  });
  Milky2018$mgstudio$45$runtime$45$web$$add_event_listener(target, "contextmenu", (event) => {
    Milky2018$mgstudio$45$runtime$45$web$$prevent_default(event);
  });
}
function Milky2018$mgstudio$45$runtime$45$web$$ensure_gizmo_pipeline(state) {
  const _bind = state.gpu.gizmo_pipeline;
  if (_bind.$tag === 1) {
    return undefined;
  }
  const _bind$2 = state.gpu.device;
  if (_bind$2.$tag === 0) {
    return undefined;
  }
  const _bind$3 = state.gpu.device;
  if (_bind$3.$tag === 1) {
    const _Some = _bind$3;
    const _device = _Some._0;
    if (state.gpu.gizmo_shader_id <= 0) {
      return undefined;
    }
    const shader_source = Milky2018$mgstudio$45$runtime$45$web$$get_shader_source(state, state.gpu.gizmo_shader_id);
    if (shader_source === undefined) {
      return undefined;
    }
    const _p = state.gpu.format;
    const _p$2 = $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$TextureFormat$Bgra8Unorm;
    let format;
    if (_p === undefined) {
      format = _p$2;
    } else {
      const _p$3 = _p;
      format = _p$3;
    }
    let _tmp;
    if (shader_source === undefined) {
      _tmp = $panic();
    } else {
      const _p$3 = shader_source;
      _tmp = _p$3;
    }
    const shader_desc = Milky2018$mgstudio$45$runtime$45$web$webgpu$$shader_module_descriptor(_tmp);
    const shader_module = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_shader_module(_device, Milky2018$mgstudio$45$runtime$45$web$webgpu$$ShaderModuleDescriptor$to_js(shader_desc));
    const position_attr = Milky2018$mgstudio$45$runtime$45$web$webgpu$$vertex_attribute(0, 0, 0);
    const color_attr = Milky2018$mgstudio$45$runtime$45$web$webgpu$$vertex_attribute(1, 8, 1);
    const vertex_layout = Milky2018$mgstudio$45$runtime$45$web$webgpu$$vertex_buffer_layout(24, [position_attr, color_attr]);
    const vertex_state = Milky2018$mgstudio$45$runtime$45$web$webgpu$$vertex_state(shader_module, "vs_main", [vertex_layout]);
    const blend_component = Milky2018$mgstudio$45$runtime$45$web$webgpu$$blend_component(0, 1, 0);
    const blend_state = Milky2018$mgstudio$45$runtime$45$web$webgpu$$blend_state(blend_component, blend_component);
    const color_target = Milky2018$mgstudio$45$runtime$45$web$webgpu$$color_target_state(format, blend_state);
    const fragment_state = Milky2018$mgstudio$45$runtime$45$web$webgpu$$fragment_state(shader_module, "fs_main", [color_target]);
    const primitive_state = Milky2018$mgstudio$45$runtime$45$web$webgpu$$primitive_state(0);
    const pipeline_desc = Milky2018$mgstudio$45$runtime$45$web$webgpu$$render_pipeline_descriptor(0, vertex_state, fragment_state, primitive_state);
    const pipeline = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_render_pipeline(_device, Milky2018$mgstudio$45$runtime$45$web$webgpu$$RenderPipelineDescriptor$to_js(pipeline_desc));
    state.gpu.gizmo_pipeline = new Option$Some$14$(pipeline);
    return;
  } else {
    return;
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$draw_gizmo_lines(state, data) {
  _L: {
    _L$2: {
      const _bind = state.gpu.current_pass;
      if (_bind.$tag === 0) {
        break _L$2;
      } else {
        const _bind$2 = state.gpu.current_pass_info;
        if (_bind$2 === undefined) {
          break _L$2;
        }
      }
      break _L;
    }
    return undefined;
  }
  _L$2: {
    _L$3: {
      const _bind = state.gpu.queue;
      if (_bind.$tag === 0) {
        break _L$3;
      } else {
        const _bind$2 = state.gpu.device;
        if (_bind$2.$tag === 0) {
          break _L$3;
        }
      }
      break _L$2;
    }
    return undefined;
  }
  Milky2018$mgstudio$45$runtime$45$web$$ensure_gizmo_pipeline(state);
  const _bind = state.gpu.gizmo_pipeline;
  if (_bind.$tag === 0) {
    return undefined;
  }
  const _bind$2 = state.gpu.current_pass;
  if (_bind$2.$tag === 1) {
    const _Some = _bind$2;
    const _pass = _Some._0;
    const _bind$3 = state.gpu.current_pass_info;
    if (_bind$3 === undefined) {
      return;
    } else {
      const _Some$2 = _bind$3;
      const _info = _Some$2;
      const _bind$4 = state.gpu.queue;
      if (_bind$4.$tag === 1) {
        const _Some$3 = _bind$4;
        const _queue = _Some$3._0;
        const vertex_data = Milky2018$mgstudio$45$runtime$45$web$$build_gizmo_vertices(data, _info.cam_x, _info.cam_y, _info.cam_rotation, _info.cam_scale, _info.width, _info.height, 2);
        const vertex_len = mizchi$js$core$$Any$_get(vertex_data, "length");
        if (vertex_len <= 0) {
          return undefined;
        }
        const vertex_count = Milky2018$mgstudio$45$runtime$45$web$$to_int(vertex_len / 6);
        if (vertex_count <= 0) {
          return undefined;
        }
        const vertex_size = mizchi$js$core$$Any$_get(vertex_data, "byteLength");
        let buffer_opt = state.gpu.gizmo_vertex_buffer;
        _L$3: {
          _L$4: {
            const _bind$5 = buffer_opt;
            if (_bind$5.$tag === 0) {
              break _L$4;
            } else {
              if (vertex_size > state.gpu.gizmo_vertex_capacity) {
                break _L$4;
              }
            }
            break _L$3;
          }
          const _bind$5 = state.gpu.device;
          if (_bind$5.$tag === 1) {
            const _Some$4 = _bind$5;
            const _device = _Some$4._0;
            const capacity = vertex_size < 256 ? 256 : vertex_size;
            const usage = Milky2018$mgstudio$45$runtime$45$web$webgpu$$combine_flags(Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_usage_vertex(), Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_usage_copy_dst());
            const desc = Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_descriptor(capacity, usage);
            const buffer = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_buffer(_device, Milky2018$mgstudio$45$runtime$45$web$webgpu$$BufferDescriptor$to_js(desc));
            state.gpu.gizmo_vertex_buffer = new Option$Some$15$(buffer);
            state.gpu.gizmo_vertex_capacity = capacity;
            buffer_opt = new Option$Some$15$(buffer);
          }
        }
        const _bind$5 = buffer_opt;
        if (_bind$5.$tag === 1) {
          const _Some$4 = _bind$5;
          const _buffer = _Some$4._0;
          const _bind$6 = state.gpu.gizmo_pipeline;
          if (_bind$6.$tag === 1) {
            const _Some$5 = _bind$6;
            const _pipeline = _Some$5._0;
            Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUQueue$write_buffer(_queue, _buffer, 0, vertex_data);
            Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$set_pipeline(_pass, _pipeline);
            Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$set_vertex_buffer(_pass, 0, _buffer);
            Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$draw(_pass, vertex_count, 1, 0, 0);
            return;
          } else {
            return;
          }
        } else {
          return;
        }
      } else {
        return;
      }
    }
  } else {
    return;
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$ensure_mesh_pipeline(state) {
  const _bind = state.gpu.mesh_pipeline;
  if (_bind.$tag === 1) {
    return undefined;
  }
  const _bind$2 = state.gpu.device;
  if (_bind$2.$tag === 0) {
    return undefined;
  }
  Milky2018$mgstudio$45$runtime$45$web$$ensure_pipeline_resources(state);
  const _bind$3 = state.gpu.uniform_buffer;
  if (_bind$3.$tag === 0) {
    return undefined;
  }
  const _bind$4 = state.gpu.device;
  if (_bind$4.$tag === 1) {
    const _Some = _bind$4;
    const _device = _Some._0;
    if (state.gpu.mesh_shader_id <= 0) {
      return undefined;
    }
    const shader_source = Milky2018$mgstudio$45$runtime$45$web$$get_shader_source(state, state.gpu.mesh_shader_id);
    if (shader_source === undefined) {
      return undefined;
    }
    const _p = state.gpu.format;
    const _p$2 = $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$TextureFormat$Bgra8Unorm;
    let format;
    if (_p === undefined) {
      format = _p$2;
    } else {
      const _p$3 = _p;
      format = _p$3;
    }
    let _tmp;
    if (shader_source === undefined) {
      _tmp = $panic();
    } else {
      const _p$3 = shader_source;
      _tmp = _p$3;
    }
    const shader_desc = Milky2018$mgstudio$45$runtime$45$web$webgpu$$shader_module_descriptor(_tmp);
    const shader_module = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_shader_module(_device, Milky2018$mgstudio$45$runtime$45$web$webgpu$$ShaderModuleDescriptor$to_js(shader_desc));
    const position_attr = Milky2018$mgstudio$45$runtime$45$web$webgpu$$vertex_attribute(0, 0, 0);
    const vertex_layout = Milky2018$mgstudio$45$runtime$45$web$webgpu$$vertex_buffer_layout(8, [position_attr]);
    const vertex_state = Milky2018$mgstudio$45$runtime$45$web$webgpu$$vertex_state(shader_module, "vs_main", [vertex_layout]);
    const blend_component = Milky2018$mgstudio$45$runtime$45$web$webgpu$$blend_component(0, 1, 0);
    const blend_state = Milky2018$mgstudio$45$runtime$45$web$webgpu$$blend_state(blend_component, blend_component);
    const color_target = Milky2018$mgstudio$45$runtime$45$web$webgpu$$color_target_state(format, blend_state);
    const fragment_state = Milky2018$mgstudio$45$runtime$45$web$webgpu$$fragment_state(shader_module, "fs_main", [color_target]);
    const primitive_state = Milky2018$mgstudio$45$runtime$45$web$webgpu$$primitive_state(0);
    const pipeline_desc = Milky2018$mgstudio$45$runtime$45$web$webgpu$$render_pipeline_descriptor(0, vertex_state, fragment_state, primitive_state);
    const pipeline = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_render_pipeline(_device, Milky2018$mgstudio$45$runtime$45$web$webgpu$$RenderPipelineDescriptor$to_js(pipeline_desc));
    state.gpu.mesh_pipeline = new Option$Some$14$(pipeline);
    const _bind$5 = state.gpu.uniform_buffer;
    if (_bind$5.$tag === 1) {
      const _Some$2 = _bind$5;
      const _uniform_buffer = _Some$2._0;
      const layout = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPipeline$get_bind_group_layout(pipeline, 0);
      const entries = [Milky2018$mgstudio$45$runtime$45$web$webgpu$$bind_group_entry_buffer(0, _uniform_buffer)];
      const bind_group_desc = Milky2018$mgstudio$45$runtime$45$web$webgpu$$bind_group_descriptor(layout, entries);
      const bind_group = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_bind_group(_device, Milky2018$mgstudio$45$runtime$45$web$webgpu$$BindGroupDescriptor$to_js(bind_group_desc));
      state.gpu.mesh_bind_group = new Option$Some$20$(bind_group);
      return;
    } else {
      return;
    }
  } else {
    return;
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$make_uniform_data(values) {
  return Milky2018$mgstudio$45$runtime$45$web$$float32array_from_array(values);
}
function Milky2018$mgstudio$45$runtime$45$web$$update_uniform_buffer(state, values) {
  const _bind = state.gpu.queue;
  if (_bind.$tag === 1) {
    const _Some = _bind;
    const _queue = _Some._0;
    const _bind$2 = state.gpu.uniform_buffer;
    if (_bind$2.$tag === 1) {
      const _Some$2 = _bind$2;
      const _uniform_buffer = _Some$2._0;
      const data = Milky2018$mgstudio$45$runtime$45$web$$make_uniform_data(values);
      Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUQueue$write_buffer(_queue, _uniform_buffer, 0, data);
      return;
    } else {
      return;
    }
  } else {
    return;
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$draw_mesh(state, mesh_id, x, y, rotation, scale_x, scale_y, r, g, b, a) {
  _L: {
    _L$2: {
      const _bind = state.gpu.current_pass;
      if (_bind.$tag === 0) {
        break _L$2;
      } else {
        const _bind$2 = state.gpu.current_pass_info;
        if (_bind$2 === undefined) {
          break _L$2;
        }
      }
      break _L;
    }
    return undefined;
  }
  Milky2018$mgstudio$45$runtime$45$web$$ensure_mesh_pipeline(state);
  _L$2: {
    _L$3: {
      const _bind = state.gpu.mesh_pipeline;
      if (_bind.$tag === 0) {
        break _L$3;
      } else {
        const _bind$2 = state.gpu.mesh_bind_group;
        if (_bind$2.$tag === 0) {
          break _L$3;
        }
      }
      break _L$2;
    }
    return undefined;
  }
  const mesh_entry = Milky2018$mgstudio$45$runtime$45$web$$map_get(state.gpu.meshes, mesh_id);
  if (Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(mesh_entry)) {
    return undefined;
  }
  const _bind = state.gpu.current_pass;
  if (_bind.$tag === 1) {
    const _Some = _bind;
    const _pass = _Some._0;
    const _bind$2 = state.gpu.current_pass_info;
    if (_bind$2 === undefined) {
      return;
    } else {
      const _Some$2 = _bind$2;
      const _info = _Some$2;
      const safe_scale = _info.cam_scale === 0 ? 1 : _info.cam_scale;
      const scale_x_base = _info.width > 0 ? 2 / _info.width / safe_scale : 0;
      const scale_y_base = _info.height > 0 ? 2 / _info.height / safe_scale : 0;
      const cos_value = Milky2018$mgstudio$45$runtime$45$web$$math_cos(rotation);
      const sin_value = Milky2018$mgstudio$45$runtime$45$web$$math_sin(rotation);
      const cam_cos = Milky2018$mgstudio$45$runtime$45$web$$math_cos(-_info.cam_rotation);
      const cam_sin = Milky2018$mgstudio$45$runtime$45$web$$math_sin(-_info.cam_rotation);
      Milky2018$mgstudio$45$runtime$45$web$$update_uniform_buffer(state, [x, y, cos_value, sin_value, _info.cam_x, _info.cam_y, cam_cos, cam_sin, scale_x_base, scale_y_base, scale_x, scale_y, r, g, b, a]);
      const _bind$3 = state.gpu.mesh_pipeline;
      if (_bind$3.$tag === 1) {
        const _Some$3 = _bind$3;
        const _mesh_pipeline = _Some$3._0;
        const _bind$4 = state.gpu.mesh_bind_group;
        if (_bind$4.$tag === 1) {
          const _Some$4 = _bind$4;
          const _mesh_bind_group = _Some$4._0;
          Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$set_pipeline(_pass, _mesh_pipeline);
          Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$set_bind_group(_pass, 0, _mesh_bind_group);
          const vertex_buffer = mizchi$js$core$$Any$_get(mesh_entry, "vertexBuffer");
          const vertex_count = mizchi$js$core$$Any$_get(mesh_entry, "vertexCount");
          Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$set_vertex_buffer(_pass, 0, vertex_buffer);
          Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$draw(_pass, vertex_count, 1, 0, 0);
          return;
        } else {
          return;
        }
      } else {
        return;
      }
    }
  } else {
    return;
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$ensure_bind_group_for_texture(state, entry) {
  _L: {
    _L$2: {
      const _bind = state.gpu.pipeline;
      if (_bind.$tag === 0) {
        break _L$2;
      } else {
        const _bind$2 = state.gpu.uniform_buffer;
        if (_bind$2.$tag === 0) {
          break _L$2;
        }
      }
      break _L;
    }
    return undefined;
  }
  const _bind = state.gpu.device;
  if (_bind.$tag === 0) {
    return undefined;
  }
  if (!Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(mizchi$js$core$$Any$_get(entry, "bindGroup"))) {
    return undefined;
  }
  if (Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(mizchi$js$core$$Any$_get(entry, "sampler")) || Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(mizchi$js$core$$Any$_get(entry, "view"))) {
    return undefined;
  }
  const _bind$2 = state.gpu.device;
  if (_bind$2.$tag === 1) {
    const _Some = _bind$2;
    const _device = _Some._0;
    const _bind$3 = state.gpu.pipeline;
    if (_bind$3.$tag === 1) {
      const _Some$2 = _bind$3;
      const _pipeline = _Some$2._0;
      const _bind$4 = state.gpu.uniform_buffer;
      if (_bind$4.$tag === 1) {
        const _Some$3 = _bind$4;
        const _uniform_buffer = _Some$3._0;
        const layout = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPipeline$get_bind_group_layout(_pipeline, 0);
        const sampler = mizchi$js$core$$Any$_get(entry, "sampler");
        const view = mizchi$js$core$$Any$_get(entry, "view");
        const entries = [Milky2018$mgstudio$45$runtime$45$web$webgpu$$bind_group_entry_sampler(0, sampler), Milky2018$mgstudio$45$runtime$45$web$webgpu$$bind_group_entry_texture(1, view), Milky2018$mgstudio$45$runtime$45$web$webgpu$$bind_group_entry_buffer(2, _uniform_buffer)];
        const bind_group_desc = Milky2018$mgstudio$45$runtime$45$web$webgpu$$bind_group_descriptor(layout, entries);
        const bind_group = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_bind_group(_device, Milky2018$mgstudio$45$runtime$45$web$webgpu$$BindGroupDescriptor$to_js(bind_group_desc));
        mizchi$js$core$$Any$_set(entry, "bindGroup", bind_group);
        return;
      } else {
        return;
      }
    } else {
      return;
    }
  } else {
    return;
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$ensure_pass_ready(state) {
  _L: {
    _L$2: {
      const _bind = state.gpu.current_pass;
      if (_bind.$tag === 0) {
        break _L$2;
      } else {
        const _bind$2 = state.gpu.current_pass_info;
        if (_bind$2 === undefined) {
          break _L$2;
        }
      }
      break _L;
    }
    return false;
  }
  _L$2: {
    _L$3: {
      const _bind = state.gpu.pipeline;
      if (_bind.$tag === 0) {
        break _L$3;
      } else {
        const _bind$2 = state.gpu.vertex_buffer;
        if (_bind$2.$tag === 0) {
          break _L$3;
        }
      }
      break _L$2;
    }
    return false;
  }
  const _bind = state.gpu.uniform_buffer;
  if (_bind.$tag === 0) {
    return false;
  }
  return true;
}
function Milky2018$mgstudio$45$runtime$45$web$$report_fallback_usage(state, id, reason) {
  if (Milky2018$mgstudio$45$runtime$45$web$$set_has(state.assets.loading_textures, id)) {
    return undefined;
  }
  if (Milky2018$mgstudio$45$runtime$45$web$$set_has(state.assets.fallback_reported, id)) {
    return undefined;
  }
  Milky2018$mgstudio$45$runtime$45$web$$set_add(state.assets.fallback_reported, id);
  const path_hint = Milky2018$mgstudio$45$runtime$45$web$$map_get(state.assets.texture_paths, id);
  const suffix = Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(path_hint) ? "" : ` (path: ${path_hint})`;
  const message = `Fallback texture used for id ${moonbitlang$core$int$$Int$to_string$46$inner(id, 10)}: ${reason}${suffix}`;
  Milky2018$mgstudio$45$runtime$45$web$$console_error(message);
  Milky2018$mgstudio$45$runtime$45$web$$dispatch_asset_error(message);
}
function Milky2018$mgstudio$45$runtime$45$web$$get_texture_entry(state, id) {
  const entry = Milky2018$mgstudio$45$runtime$45$web$$map_get(state.gpu.textures, id);
  if (!Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(entry)) {
    const view = mizchi$js$core$$Any$_get(entry, "view");
    const sampler = mizchi$js$core$$Any$_get(entry, "sampler");
    if (!Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(view) && !Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(sampler)) {
      return new Option$Some$4$(entry);
    }
  }
  const reason = Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(entry) ? "texture id not found" : "texture not ready";
  Milky2018$mgstudio$45$runtime$45$web$$report_fallback_usage(state, id, reason);
  const fallback_entry = Milky2018$mgstudio$45$runtime$45$web$$map_get(state.gpu.textures, state.gpu.fallback_texture_id);
  return Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(fallback_entry) ? Option$None$4$ : new Option$Some$4$(fallback_entry);
}
function Milky2018$mgstudio$45$runtime$45$web$$draw_sprite(state, texture_id, x, y, rotation, scale_x, scale_y, r, g, b, a) {
  if (!Milky2018$mgstudio$45$runtime$45$web$$ensure_pass_ready(state)) {
    return undefined;
  }
  const entry = Milky2018$mgstudio$45$runtime$45$web$$get_texture_entry(state, texture_id);
  if (entry.$tag === 0) {
    return undefined;
  }
  if (entry.$tag === 1) {
    const _Some = entry;
    const _entry_value = _Some._0;
    Milky2018$mgstudio$45$runtime$45$web$$ensure_bind_group_for_texture(state, _entry_value);
    const bind_group_any = mizchi$js$core$$Any$_get(_entry_value, "bindGroup");
    if (Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(bind_group_any)) {
      return undefined;
    }
    const _bind = state.gpu.current_pass;
    if (_bind.$tag === 1) {
      const _Some$2 = _bind;
      const _pass = _Some$2._0;
      const _bind$2 = state.gpu.current_pass_info;
      if (_bind$2 === undefined) {
        return;
      } else {
        const _Some$3 = _bind$2;
        const _info = _Some$3;
        const tex_width = mizchi$js$core$$Any$_get(_entry_value, "width");
        const tex_height = mizchi$js$core$$Any$_get(_entry_value, "height");
        const tex_scale_x = tex_width > 0 ? tex_width / 128 : 1;
        const tex_scale_y = tex_height > 0 ? tex_height / 128 : 1;
        const sprite_scale_x = scale_x * tex_scale_x;
        const sprite_scale_y = scale_y * tex_scale_y;
        const safe_scale = _info.cam_scale === 0 ? 1 : _info.cam_scale;
        const scale_x_base = _info.width > 0 ? 2 / _info.width / safe_scale : 0;
        const scale_y_base = _info.height > 0 ? 2 / _info.height / safe_scale : 0;
        const cos_value = Milky2018$mgstudio$45$runtime$45$web$$math_cos(rotation);
        const sin_value = Milky2018$mgstudio$45$runtime$45$web$$math_sin(rotation);
        const cam_cos = Milky2018$mgstudio$45$runtime$45$web$$math_cos(-_info.cam_rotation);
        const cam_sin = Milky2018$mgstudio$45$runtime$45$web$$math_sin(-_info.cam_rotation);
        Milky2018$mgstudio$45$runtime$45$web$$update_uniform_buffer(state, [x, y, cos_value, sin_value, _info.cam_x, _info.cam_y, cam_cos, cam_sin, scale_x_base, scale_y_base, sprite_scale_x, sprite_scale_y, r, g, b, a]);
        const _bind$3 = state.gpu.pipeline;
        if (_bind$3.$tag === 1) {
          const _Some$4 = _bind$3;
          const _pipeline = _Some$4._0;
          const _bind$4 = state.gpu.vertex_buffer;
          if (_bind$4.$tag === 1) {
            const _Some$5 = _bind$4;
            const _vertex_buffer = _Some$5._0;
            Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$set_pipeline(_pass, _pipeline);
            Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$set_bind_group(_pass, 0, bind_group_any);
            Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$set_vertex_buffer(_pass, 0, _vertex_buffer);
            Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$draw(_pass, state.gpu.vertex_count, 1, 0, 0);
            return;
          } else {
            return;
          }
        } else {
          return;
        }
      }
    } else {
      return;
    }
  } else {
    return;
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$ensure_canvas(canvas_opt) {
  if (canvas_opt.$tag === 1) {
    const _Some = canvas_opt;
    const _canvas = _Some._0;
    return _canvas;
  } else {
    const target = Milky2018$mgstudio$45$runtime$45$web$$create_canvas_element();
    Milky2018$mgstudio$45$runtime$45$web$$append_canvas_to_body(target);
    return target;
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$init_input(state) {
  if (state.input.initialized) {
    return undefined;
  }
  state.input.initialized = true;
  const win = mizchi$js$browser$dom$$window();
  Milky2018$mgstudio$45$runtime$45$web$$add_event_listener(win, "keydown", (event) => {
    const repeat_value = mizchi$js$core$$Any$_get(event, "repeat");
    if (repeat_value) {
      return undefined;
    }
    const code = Milky2018$mgstudio$45$runtime$45$web$$any_to_string(mizchi$js$core$$Any$_get(event, "code"));
    if (!Milky2018$mgstudio$45$runtime$45$web$$set_has(state.input.pressed, code)) {
      Milky2018$mgstudio$45$runtime$45$web$$set_add(state.input.pressed, code);
      Milky2018$mgstudio$45$runtime$45$web$$set_add(state.input.just_pressed, code);
      return;
    } else {
      return;
    }
  });
  Milky2018$mgstudio$45$runtime$45$web$$add_event_listener(win, "keyup", (event) => {
    const code = Milky2018$mgstudio$45$runtime$45$web$$any_to_string(mizchi$js$core$$Any$_get(event, "code"));
    if (Milky2018$mgstudio$45$runtime$45$web$$set_delete(state.input.pressed, code)) {
      Milky2018$mgstudio$45$runtime$45$web$$set_add(state.input.just_released, code);
      return;
    } else {
      return;
    }
  });
  Milky2018$mgstudio$45$runtime$45$web$$add_event_listener(win, "blur", (_discard_) => {
    Milky2018$mgstudio$45$runtime$45$web$$set_clear(state.input.pressed);
    Milky2018$mgstudio$45$runtime$45$web$$set_clear(state.input.just_pressed);
    Milky2018$mgstudio$45$runtime$45$web$$set_clear(state.input.just_released);
  });
}
function Milky2018$mgstudio$45$runtime$45$web$$resolve_asset_url(path) {
  const text = Milky2018$mgstudio$45$runtime$45$web$$coerce_asset_path(path);
  if (text.length === 0) {
    const _bind = moonbitlang$core$builtin$$fail$14$("Asset path is empty", "@Milky2018/mgstudio-runtime-web:host.mbt:706:5-706:32");
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _ok._0;
    } else {
      return _bind;
    }
  }
  let _tmp;
  if (Milky2018$mgstudio$45$runtime$45$web$$is_external_asset_url(text)) {
    _tmp = text;
  } else {
    const normalized = Milky2018$mgstudio$45$runtime$45$web$$strip_leading_slashes(text);
    _tmp = `./assets/${normalized}`;
  }
  return new Result$Ok$21$(_tmp);
}
function Milky2018$mgstudio$45$runtime$45$web$$load_texture_from_path$46$42$async_driver$124$1207(_state) {
  let _tmp = _state;
  _L: while (true) {
    const _state$2 = _tmp;
    switch (_state$2.$tag) {
      case 0: {
        const _State_0 = _state$2;
        const nearest = _State_0._3;
        const id = _State_0._2;
        const state = _State_0._1;
        const _cont_param = _State_0._0;
        Milky2018$mgstudio$45$runtime$45$web$$ensure_pipeline_resources(state);
        const _bind = state.gpu.device;
        if (_bind.$tag === 1) {
          const _Some = _bind;
          const _device = _Some._0;
          const _bind$2 = state.gpu.queue;
          if (_bind$2.$tag === 1) {
            const _Some$2 = _bind$2;
            const _queue = _Some$2._0;
            const width = mizchi$js$core$$Any$_get(_cont_param, "width");
            const height = mizchi$js$core$$Any$_get(_cont_param, "height");
            const texture_usage = Milky2018$mgstudio$45$runtime$45$web$webgpu$$combine_flags(Milky2018$mgstudio$45$runtime$45$web$webgpu$$combine_flags(Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_texture_binding(), Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_copy_dst()), Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_render_attachment());
            const texture_desc = Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_descriptor(Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_size(width, height), $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$TextureFormat$Rgba8Unorm, texture_usage);
            const texture = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_texture(_device, Milky2018$mgstudio$45$runtime$45$web$webgpu$$TextureDescriptor$to_js(texture_desc));
            Milky2018$mgstudio$45$runtime$45$web$$copy_external_image_to_texture(_queue, _cont_param, texture, width, height);
            const sampler = Milky2018$mgstudio$45$runtime$45$web$$create_sampler(state, nearest);
            if (sampler.$tag === 1) {
              const _Some$3 = sampler;
              const _sampler_value = _Some$3._0;
              const entry = mizchi$js$core$$from_entries([{ _0: "id", _1: id }, { _0: "texture", _1: texture }, { _0: "view", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUTexture$create_view(texture, Option$None$4$) }, { _0: "sampler", _1: _sampler_value }, { _0: "bindGroup", _1: Milky2018$mgstudio$45$runtime$45$web$$js_null() }, { _0: "width", _1: width }, { _0: "height", _1: height }]);
              Milky2018$mgstudio$45$runtime$45$web$$map_set(state.gpu.textures, id, entry);
              Milky2018$mgstudio$45$runtime$45$web$$ensure_bind_group_for_texture(state, entry);
            }
          }
        }
        Milky2018$mgstudio$45$runtime$45$web$$set_delete(state.assets.loading_textures, id);
        return new Result$Ok$22$(undefined);
      }
      case 1: {
        const _State_1 = _state$2;
        const _err_cont = _State_1._5;
        const _cont = _State_1._4;
        const nearest$2 = _State_1._3;
        const id$2 = _State_1._2;
        const state$2 = _State_1._1;
        const _cont_param$2 = _State_1._0;
        const _bind$2 = mizchi$js$core$$Promise$wait$8$(Milky2018$mgstudio$45$runtime$45$web$$create_image_bitmap(_cont_param$2), (_cont_param$3) => {
          let _err;
          _L$2: {
            const _bind$3 = Milky2018$mgstudio$45$runtime$45$web$$load_texture_from_path$46$42$async_driver$124$1207(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_texture_from_path$46$State$State_0(_cont_param$3, state$2, id$2, nearest$2));
            let _bind$4;
            if (_bind$3.$tag === 1) {
              const _ok = _bind$3;
              _bind$4 = _ok._0;
            } else {
              const _err$2 = _bind$3;
              const _tmp$2 = _err$2._0;
              _err = _tmp$2;
              break _L$2;
            }
            if (_bind$4 === -1) {
              return;
            } else {
              const _Some = _bind$4;
              const _payload = _Some;
              _cont(_payload);
              return;
            }
          }
          _err_cont(_err);
        }, _err_cont);
        let _tmp$2;
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          _tmp$2 = _ok._0;
        } else {
          return _bind$2;
        }
        const _tmp$3 = _tmp$2;
        if (_tmp$3.$tag === 1) {
          const _Some = _tmp$3;
          const _payload = _Some._0;
          _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_texture_from_path$46$State$State_0(_payload, state$2, id$2, nearest$2);
          continue _L;
        } else {
          return new Result$Ok$22$(-1);
        }
      }
      default: {
        const _State_2 = _state$2;
        const _err_cont$2 = _State_2._6;
        const _cont$2 = _State_2._5;
        const url = _State_2._4;
        const nearest$3 = _State_2._3;
        const id$3 = _State_2._2;
        const state$3 = _State_2._1;
        const _cont_param$3 = _State_2._0;
        if (!_cont_param$3.ok) {
          const _bind$3 = moonbitlang$core$builtin$$fail$14$(`Failed to load texture: ${url} (${moonbitlang$core$int$$Int$to_string$46$inner(_cont_param$3.status, 10)})`, "@Milky2018/mgstudio-runtime-web:host.mbt:1381:5-1387:6");
          if (_bind$3.$tag === 1) {
            const _ok = _bind$3;
            _ok._0;
          } else {
            return _bind$3;
          }
        }
        const _bind$3 = mizchi$js$core$$Promise$wait$8$(Milky2018$mgstudio$45$runtime$45$web$$response_blob(_cont_param$3), (_cont_param$4) => {
          let _err;
          _L$2: {
            const _bind$4 = Milky2018$mgstudio$45$runtime$45$web$$load_texture_from_path$46$42$async_driver$124$1207(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_texture_from_path$46$State$State_1(_cont_param$4, state$3, id$3, nearest$3, _cont$2, _err_cont$2));
            let _bind$5;
            if (_bind$4.$tag === 1) {
              const _ok = _bind$4;
              _bind$5 = _ok._0;
            } else {
              const _err$2 = _bind$4;
              const _tmp$4 = _err$2._0;
              _err = _tmp$4;
              break _L$2;
            }
            if (_bind$5 === -1) {
              return;
            } else {
              const _Some = _bind$5;
              const _payload = _Some;
              _cont$2(_payload);
              return;
            }
          }
          _err_cont$2(_err);
        }, _err_cont$2);
        let _tmp$4;
        if (_bind$3.$tag === 1) {
          const _ok = _bind$3;
          _tmp$4 = _ok._0;
        } else {
          return _bind$3;
        }
        const _tmp$5 = _tmp$4;
        if (_tmp$5.$tag === 1) {
          const _Some = _tmp$5;
          const _payload = _Some._0;
          _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_texture_from_path$46$State$State_1(_payload, state$3, id$3, nearest$3, _cont$2, _err_cont$2);
          continue _L;
        } else {
          return new Result$Ok$22$(-1);
        }
      }
    }
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$load_texture_from_path(state, id, path, nearest, _cont, _err_cont) {
  _L: {
    _L$2: {
      const _bind = state.gpu.device;
      if (_bind.$tag === 0) {
        break _L$2;
      } else {
        const _bind$2 = state.gpu.queue;
        if (_bind$2.$tag === 0) {
          break _L$2;
        }
      }
      break _L;
    }
    moonbitlang$core$array$$Array$push$17$(state.assets.pending_textures, { id: id, path: path, nearest: nearest });
    return new Result$Ok$22$(undefined);
  }
  const _bind = Milky2018$mgstudio$45$runtime$45$web$$resolve_asset_url(path);
  let url;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    url = _ok._0;
  } else {
    return _bind;
  }
  const _bind$2 = mizchi$js$web$http$$fetch(url, "GET", undefined, undefined, undefined, Option$None$4$, undefined, undefined, -1, undefined, undefined, undefined, undefined, Option$None$10$, (_cont_param) => {
    let _err;
    _L$2: {
      const _bind$3 = Milky2018$mgstudio$45$runtime$45$web$$load_texture_from_path$46$42$async_driver$124$1207(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_texture_from_path$46$State$State_2(_cont_param, state, id, nearest, url, _cont, _err_cont));
      let _bind$4;
      if (_bind$3.$tag === 1) {
        const _ok = _bind$3;
        _bind$4 = _ok._0;
      } else {
        const _err$2 = _bind$3;
        const _tmp = _err$2._0;
        _err = _tmp;
        break _L$2;
      }
      if (_bind$4 === -1) {
        return;
      } else {
        const _Some = _bind$4;
        const _payload = _Some;
        _cont(_payload);
        return;
      }
    }
    _err_cont(_err);
  }, _err_cont);
  let _bind$3;
  if (_bind$2.$tag === 1) {
    const _ok = _bind$2;
    _bind$3 = _ok._0;
  } else {
    return _bind$2;
  }
  if (_bind$3 === undefined) {
    return new Result$Ok$22$(-1);
  } else {
    const _Some = _bind$3;
    const _payload = _Some;
    return Milky2018$mgstudio$45$runtime$45$web$$load_texture_from_path$46$42$async_driver$124$1207(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_texture_from_path$46$State$State_2(_payload, state, id, nearest, url, _cont, _err_cont));
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$load_wgsl_from_path$46$42$async_driver$124$1252(_state) {
  let _tmp = _state;
  while (true) {
    const _state$2 = _tmp;
    if (_state$2.$tag === 0) {
      const _State_0 = _state$2;
      const id = _State_0._2;
      const state = _State_0._1;
      const _cont_param = _State_0._0;
      Milky2018$mgstudio$45$runtime$45$web$$map_set(state.assets.shader_sources, id, _cont_param);
      return new Result$Ok$5$(_cont_param);
    } else {
      const _State_1 = _state$2;
      const _err_cont = _State_1._5;
      const _cont = _State_1._4;
      const url = _State_1._3;
      const id = _State_1._2;
      const state = _State_1._1;
      const _cont_param = _State_1._0;
      if (!_cont_param.ok) {
        const _bind = moonbitlang$core$builtin$$fail$14$(`Failed to load shader: ${url} (${moonbitlang$core$int$$Int$to_string$46$inner(_cont_param.status, 10)})`, "@Milky2018/mgstudio-runtime-web:host.mbt:1438:5-1440:6");
        if (_bind.$tag === 1) {
          const _ok = _bind;
          _ok._0;
        } else {
          return _bind;
        }
      }
      const _bind = mizchi$js$core$$Promise$wait$4$(Milky2018$mgstudio$45$runtime$45$web$$response_text(_cont_param), (_cont_param$2) => {
        let _err;
        _L: {
          const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$load_wgsl_from_path$46$42$async_driver$124$1252(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wgsl_from_path$46$State$State_0(_cont_param$2, state, id));
          let _bind$3;
          if (_bind$2.$tag === 1) {
            const _ok = _bind$2;
            _bind$3 = _ok._0;
          } else {
            const _err$2 = _bind$2;
            const _tmp$2 = _err$2._0;
            _err = _tmp$2;
            break _L;
          }
          if (_bind$3 === undefined) {
            return;
          } else {
            const _Some = _bind$3;
            const _payload = _Some;
            _cont(_payload);
            return;
          }
        }
        _err_cont(_err);
      }, _err_cont);
      let _bind$2;
      if (_bind.$tag === 1) {
        const _ok = _bind;
        _bind$2 = _ok._0;
      } else {
        return _bind;
      }
      if (_bind$2 === undefined) {
        return new Result$Ok$5$(undefined);
      } else {
        const _Some = _bind$2;
        const _payload = _Some;
        _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wgsl_from_path$46$State$State_0(_payload, state, id);
        continue;
      }
    }
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$load_wgsl_from_path(state, id, path, _cont, _err_cont) {
  const _bind = Milky2018$mgstudio$45$runtime$45$web$$resolve_asset_url(path);
  let url;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    url = _ok._0;
  } else {
    return _bind;
  }
  const _bind$2 = mizchi$js$web$http$$fetch(url, "GET", undefined, undefined, undefined, Option$None$4$, undefined, undefined, -1, undefined, undefined, undefined, undefined, Option$None$10$, (_cont_param) => {
    let _err;
    _L: {
      const _bind$3 = Milky2018$mgstudio$45$runtime$45$web$$load_wgsl_from_path$46$42$async_driver$124$1252(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wgsl_from_path$46$State$State_1(_cont_param, state, id, url, _cont, _err_cont));
      let _bind$4;
      if (_bind$3.$tag === 1) {
        const _ok = _bind$3;
        _bind$4 = _ok._0;
      } else {
        const _err$2 = _bind$3;
        const _tmp = _err$2._0;
        _err = _tmp;
        break _L;
      }
      if (_bind$4 === undefined) {
        return;
      } else {
        const _Some = _bind$4;
        const _payload = _Some;
        _cont(_payload);
        return;
      }
    }
    _err_cont(_err);
  }, _err_cont);
  let _bind$3;
  if (_bind$2.$tag === 1) {
    const _ok = _bind$2;
    _bind$3 = _ok._0;
  } else {
    return _bind$2;
  }
  if (_bind$3 === undefined) {
    return new Result$Ok$5$(undefined);
  } else {
    const _Some = _bind$3;
    const _payload = _Some;
    return Milky2018$mgstudio$45$runtime$45$web$$load_wgsl_from_path$46$42$async_driver$124$1252(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$load_wgsl_from_path$46$State$State_1(_payload, state, id, url, _cont, _err_cont));
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$next_shader_id(state) {
  const id = state.assets.next_shader_id;
  state.assets.next_shader_id = id + 1 | 0;
  return id;
}
function Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$cont$124$1288(_param) {}
function Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$async_driver$124$1289(_state) {
  let _tmp = _state;
  while (true) {
    const _state$2 = _tmp;
    if (_state$2.$tag === 0) {
      const _State_0 = _state$2;
      _State_0._0;
      return undefined;
    } else {
      const _$42$try$47$997 = _state$2;
      const entry = _$42$try$47$997._2;
      const state = _$42$try$47$997._1;
      const _try_err = _$42$try$47$997._0;
      const message = `Texture load error: ${moonbitlang$core$builtin$$Show$to_string$10$(_try_err)}`;
      Milky2018$mgstudio$45$runtime$45$web$$console_error(message);
      Milky2018$mgstudio$45$runtime$45$web$$dispatch_asset_error(message);
      Milky2018$mgstudio$45$runtime$45$web$$set_delete(state.assets.loading_textures, entry.id);
      _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$fn$47$1287$46$State$State_0(undefined);
      continue;
    }
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$async_driver$124$1281(_state) {
  let _tmp = _state;
  _L: while (true) {
    const _state$2 = _tmp;
    switch (_state$2.$tag) {
      case 0: {
        const _State_0 = _state$2;
        const gizmo_id = _State_0._2;
        const state = _State_0._1;
        const _cont_param = _State_0._0;
        Milky2018$mgstudio$45$runtime$45$web$$set_delete(state.assets.loading_shaders, gizmo_id);
        if (_cont_param === "") {
          state.gpu.gizmo_shader_id = 0;
        }
        if (state.assets.pending_textures.length > 0) {
          const pending = [];
          const _arr = state.assets.pending_textures;
          const _len = _arr.length;
          let _tmp$2 = 0;
          while (true) {
            const _i = _tmp$2;
            if (_i < _len) {
              const item = _arr[_i];
              moonbitlang$core$array$$Array$push$17$(pending, item);
              _tmp$2 = _i + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          moonbitlang$core$array$$Array$clear$17$(state.assets.pending_textures);
          const _len$2 = pending.length;
          let _tmp$3 = 0;
          while (true) {
            const _i = _tmp$3;
            if (_i < _len$2) {
              const entry = pending[_i];
              let _err;
              _L$2: {
                _L$3: {
                  const _bind = Milky2018$mgstudio$45$runtime$45$web$$load_texture_from_path(state, entry.id, entry.path, entry.nearest, (_cont_param$2) => {
                    const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$async_driver$124$1289(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$fn$47$1287$46$State$State_0(_cont_param$2));
                    if (_bind$2 === -1) {
                      return;
                    } else {
                      const _Some = _bind$2;
                      const _payload = _Some;
                      Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$cont$124$1288(_payload);
                      return;
                    }
                  }, (_cont_param$2) => {
                    const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$async_driver$124$1289(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$fn$47$1287$46$State$_try$47$997(_cont_param$2, state, entry));
                    if (_bind$2 === -1) {
                      return;
                    } else {
                      const _Some = _bind$2;
                      const _payload = _Some;
                      Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$cont$124$1288(_payload);
                      return;
                    }
                  });
                  let _bind$2;
                  if (_bind.$tag === 1) {
                    const _ok = _bind;
                    _bind$2 = _ok._0;
                  } else {
                    const _err$2 = _bind;
                    const _tmp$4 = _err$2._0;
                    _err = _tmp$4;
                    break _L$3;
                  }
                  if (_bind$2 === -1) {
                  } else {
                    const _Some = _bind$2;
                    const _payload = _Some;
                    Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$async_driver$124$1289(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$fn$47$1287$46$State$State_0(_payload));
                  }
                  break _L$2;
                }
                Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$async_driver$124$1289(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$fn$47$1287$46$State$_try$47$997(_err, state, entry));
              }
              _tmp$3 = _i + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          return new Result$Ok$22$(undefined);
        } else {
          return new Result$Ok$22$(undefined);
        }
      }
      case 1: {
        const _$42$try$47$1000 = _state$2;
        const gizmo_id$2 = _$42$try$47$1000._2;
        const state$2 = _$42$try$47$1000._1;
        const _try_err = _$42$try$47$1000._0;
        const message = `Shader load error: ${moonbitlang$core$builtin$$Show$to_string$10$(_try_err)}`;
        Milky2018$mgstudio$45$runtime$45$web$$console_error(message);
        Milky2018$mgstudio$45$runtime$45$web$$dispatch_asset_error(message);
        _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_0("", state$2, gizmo_id$2);
        continue _L;
      }
      case 2: {
        const _State_2 = _state$2;
        const _err_cont = _State_2._5;
        const _cont = _State_2._4;
        const gizmo_id$3 = _State_2._3;
        const mesh_id = _State_2._2;
        const state$3 = _State_2._1;
        const _cont_param$2 = _State_2._0;
        Milky2018$mgstudio$45$runtime$45$web$$set_delete(state$3.assets.loading_shaders, mesh_id);
        if (_cont_param$2 === "") {
          state$3.gpu.mesh_shader_id = 0;
        }
        let _err;
        _L$2: {
          const _bind = Milky2018$mgstudio$45$runtime$45$web$$load_wgsl_from_path(state$3, gizmo_id$3, "shaders/gizmo_lines.wgsl", (_cont_param$3) => {
            let _err$2;
            _L$3: {
              const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$async_driver$124$1281(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_0(_cont_param$3, state$3, gizmo_id$3));
              let _bind$3;
              if (_bind$2.$tag === 1) {
                const _ok = _bind$2;
                _bind$3 = _ok._0;
              } else {
                const _err$3 = _bind$2;
                const _tmp$2 = _err$3._0;
                _err$2 = _tmp$2;
                break _L$3;
              }
              if (_bind$3 === -1) {
                return;
              } else {
                const _Some = _bind$3;
                const _payload = _Some;
                _cont(_payload);
                return;
              }
            }
            _err_cont(_err$2);
          }, (_cont_param$3) => {
            let _err$2;
            _L$3: {
              const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$async_driver$124$1281(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$_try$47$1000(_cont_param$3, state$3, gizmo_id$3));
              let _bind$3;
              if (_bind$2.$tag === 1) {
                const _ok = _bind$2;
                _bind$3 = _ok._0;
              } else {
                const _err$3 = _bind$2;
                const _tmp$2 = _err$3._0;
                _err$2 = _tmp$2;
                break _L$3;
              }
              if (_bind$3 === -1) {
                return;
              } else {
                const _Some = _bind$3;
                const _payload = _Some;
                _cont(_payload);
                return;
              }
            }
            _err_cont(_err$2);
          });
          let _bind$2;
          if (_bind.$tag === 1) {
            const _ok = _bind;
            _bind$2 = _ok._0;
          } else {
            const _err$2 = _bind;
            const _tmp$2 = _err$2._0;
            _err = _tmp$2;
            break _L$2;
          }
          if (_bind$2 === undefined) {
            return new Result$Ok$22$(-1);
          } else {
            const _Some = _bind$2;
            const _payload = _Some;
            _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_0(_payload, state$3, gizmo_id$3);
            continue _L;
          }
        }
        _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$_try$47$1000(_err, state$3, gizmo_id$3);
        continue _L;
      }
      case 3: {
        const _$42$try$47$1003 = _state$2;
        const _err_cont$2 = _$42$try$47$1003._5;
        const _cont$2 = _$42$try$47$1003._4;
        const gizmo_id$4 = _$42$try$47$1003._3;
        const mesh_id$2 = _$42$try$47$1003._2;
        const state$4 = _$42$try$47$1003._1;
        const _try_err$2 = _$42$try$47$1003._0;
        const message$2 = `Shader load error: ${moonbitlang$core$builtin$$Show$to_string$10$(_try_err$2)}`;
        Milky2018$mgstudio$45$runtime$45$web$$console_error(message$2);
        Milky2018$mgstudio$45$runtime$45$web$$dispatch_asset_error(message$2);
        _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_2("", state$4, mesh_id$2, gizmo_id$4, _cont$2, _err_cont$2);
        continue _L;
      }
      case 4: {
        const _State_4 = _state$2;
        const _err_cont$3 = _State_4._6;
        const _cont$3 = _State_4._5;
        const gizmo_id$5 = _State_4._4;
        const mesh_id$3 = _State_4._3;
        const sprite_id = _State_4._2;
        const state$5 = _State_4._1;
        const _cont_param$3 = _State_4._0;
        Milky2018$mgstudio$45$runtime$45$web$$set_delete(state$5.assets.loading_shaders, sprite_id);
        if (_cont_param$3 === "") {
          state$5.gpu.sprite_shader_id = 0;
        }
        let _err$2;
        _L$3: {
          const _bind = Milky2018$mgstudio$45$runtime$45$web$$load_wgsl_from_path(state$5, mesh_id$3, "shaders/mesh.wgsl", (_cont_param$4) => {
            let _err$3;
            _L$4: {
              const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$async_driver$124$1281(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_2(_cont_param$4, state$5, mesh_id$3, gizmo_id$5, _cont$3, _err_cont$3));
              let _bind$3;
              if (_bind$2.$tag === 1) {
                const _ok = _bind$2;
                _bind$3 = _ok._0;
              } else {
                const _err$4 = _bind$2;
                const _tmp$2 = _err$4._0;
                _err$3 = _tmp$2;
                break _L$4;
              }
              if (_bind$3 === -1) {
                return;
              } else {
                const _Some = _bind$3;
                const _payload = _Some;
                _cont$3(_payload);
                return;
              }
            }
            _err_cont$3(_err$3);
          }, (_cont_param$4) => {
            let _err$3;
            _L$4: {
              const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$async_driver$124$1281(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$_try$47$1003(_cont_param$4, state$5, mesh_id$3, gizmo_id$5, _cont$3, _err_cont$3));
              let _bind$3;
              if (_bind$2.$tag === 1) {
                const _ok = _bind$2;
                _bind$3 = _ok._0;
              } else {
                const _err$4 = _bind$2;
                const _tmp$2 = _err$4._0;
                _err$3 = _tmp$2;
                break _L$4;
              }
              if (_bind$3 === -1) {
                return;
              } else {
                const _Some = _bind$3;
                const _payload = _Some;
                _cont$3(_payload);
                return;
              }
            }
            _err_cont$3(_err$3);
          });
          let _bind$2;
          if (_bind.$tag === 1) {
            const _ok = _bind;
            _bind$2 = _ok._0;
          } else {
            const _err$3 = _bind;
            const _tmp$2 = _err$3._0;
            _err$2 = _tmp$2;
            break _L$3;
          }
          if (_bind$2 === undefined) {
            return new Result$Ok$22$(-1);
          } else {
            const _Some = _bind$2;
            const _payload = _Some;
            _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_2(_payload, state$5, mesh_id$3, gizmo_id$5, _cont$3, _err_cont$3);
            continue _L;
          }
        }
        _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$_try$47$1003(_err$2, state$5, mesh_id$3, gizmo_id$5, _cont$3, _err_cont$3);
        continue _L;
      }
      case 5: {
        const _$42$try$47$1006 = _state$2;
        const _err_cont$4 = _$42$try$47$1006._6;
        const _cont$4 = _$42$try$47$1006._5;
        const gizmo_id$6 = _$42$try$47$1006._4;
        const mesh_id$4 = _$42$try$47$1006._3;
        const sprite_id$2 = _$42$try$47$1006._2;
        const state$6 = _$42$try$47$1006._1;
        const _try_err$3 = _$42$try$47$1006._0;
        const message$3 = `Shader load error: ${moonbitlang$core$builtin$$Show$to_string$10$(_try_err$3)}`;
        Milky2018$mgstudio$45$runtime$45$web$$console_error(message$3);
        Milky2018$mgstudio$45$runtime$45$web$$dispatch_asset_error(message$3);
        _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_4("", state$6, sprite_id$2, mesh_id$4, gizmo_id$6, _cont$4, _err_cont$4);
        continue _L;
      }
      case 6: {
        const _State_6 = _state$2;
        const _err_cont$5 = _State_6._4;
        const _cont$5 = _State_6._3;
        const target = _State_6._2;
        const state$7 = _State_6._1;
        const _cont_param$4 = _State_6._0;
        if (Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(_cont_param$4)) {
          const _bind = moonbitlang$core$builtin$$fail$14$("WebGPU device unavailable", "@Milky2018/mgstudio-runtime-web:host.mbt:896:5-896:38");
          if (_bind.$tag === 1) {
            const _ok = _bind;
            _ok._0;
          } else {
            return _bind;
          }
        }
        const device = _cont_param$4;
        const context = Milky2018$mgstudio$45$runtime$45$web$webgpu$$get_canvas_context(target);
        const format = Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_format_from_string(Milky2018$mgstudio$45$runtime$45$web$webgpu$$preferred_canvas_format());
        state$7.gpu.device = new Option$Some$23$(device);
        state$7.gpu.queue = new Option$Some$24$(Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$queue(device));
        state$7.gpu.context = new Option$Some$25$(context);
        state$7.gpu.format = format;
        state$7.gpu.pipeline = Option$None$14$;
        state$7.gpu.vertex_buffer = Option$None$15$;
        state$7.gpu.vertex_count = 0;
        state$7.gpu.mesh_pipeline = Option$None$14$;
        state$7.gpu.mesh_bind_group = Option$None$20$;
        state$7.gpu.gizmo_pipeline = Option$None$14$;
        state$7.gpu.gizmo_vertex_buffer = Option$None$15$;
        state$7.gpu.gizmo_vertex_capacity = 0;
        state$7.gpu.gizmo_lines = Milky2018$mgstudio$45$runtime$45$web$$new_array();
        state$7.gpu.meshes = Milky2018$mgstudio$45$runtime$45$web$$new_map();
        state$7.gpu.next_mesh_id = 1;
        state$7.gpu.uniform_buffer = Option$None$15$;
        state$7.gpu.encoder = Option$None$16$;
        state$7.gpu.current_texture = Option$None$17$;
        state$7.gpu.current_pass = Option$None$19$;
        state$7.gpu.current_pass_info = undefined;
        state$7.gpu.textures = Milky2018$mgstudio$45$runtime$45$web$$new_map();
        state$7.gpu.next_texture_id = 1;
        state$7.gpu.fallback_texture_id = 0;
        state$7.gpu.sprite_shader_id = 0;
        state$7.gpu.mesh_shader_id = 0;
        state$7.gpu.gizmo_shader_id = 0;
        const sprite_id$3 = Milky2018$mgstudio$45$runtime$45$web$$next_shader_id(state$7);
        const mesh_id$5 = Milky2018$mgstudio$45$runtime$45$web$$next_shader_id(state$7);
        const gizmo_id$7 = Milky2018$mgstudio$45$runtime$45$web$$next_shader_id(state$7);
        state$7.gpu.sprite_shader_id = sprite_id$3;
        state$7.gpu.mesh_shader_id = mesh_id$5;
        state$7.gpu.gizmo_shader_id = gizmo_id$7;
        Milky2018$mgstudio$45$runtime$45$web$$set_add(state$7.assets.loading_shaders, sprite_id$3);
        Milky2018$mgstudio$45$runtime$45$web$$set_add(state$7.assets.loading_shaders, mesh_id$5);
        Milky2018$mgstudio$45$runtime$45$web$$set_add(state$7.assets.loading_shaders, gizmo_id$7);
        Milky2018$mgstudio$45$runtime$45$web$$map_set(state$7.assets.shader_paths, sprite_id$3, "shaders/sprite.wgsl");
        Milky2018$mgstudio$45$runtime$45$web$$map_set(state$7.assets.shader_paths, mesh_id$5, "shaders/mesh.wgsl");
        Milky2018$mgstudio$45$runtime$45$web$$map_set(state$7.assets.shader_paths, gizmo_id$7, "shaders/gizmo_lines.wgsl");
        let _err$3;
        _L$4: {
          const _bind = Milky2018$mgstudio$45$runtime$45$web$$load_wgsl_from_path(state$7, sprite_id$3, "shaders/sprite.wgsl", (_cont_param$5) => {
            let _err$4;
            _L$5: {
              const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$async_driver$124$1281(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_4(_cont_param$5, state$7, sprite_id$3, mesh_id$5, gizmo_id$7, _cont$5, _err_cont$5));
              let _bind$3;
              if (_bind$2.$tag === 1) {
                const _ok = _bind$2;
                _bind$3 = _ok._0;
              } else {
                const _err$5 = _bind$2;
                const _tmp$2 = _err$5._0;
                _err$4 = _tmp$2;
                break _L$5;
              }
              if (_bind$3 === -1) {
                return;
              } else {
                const _Some = _bind$3;
                const _payload = _Some;
                _cont$5(_payload);
                return;
              }
            }
            _err_cont$5(_err$4);
          }, (_cont_param$5) => {
            let _err$4;
            _L$5: {
              const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$async_driver$124$1281(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$_try$47$1006(_cont_param$5, state$7, sprite_id$3, mesh_id$5, gizmo_id$7, _cont$5, _err_cont$5));
              let _bind$3;
              if (_bind$2.$tag === 1) {
                const _ok = _bind$2;
                _bind$3 = _ok._0;
              } else {
                const _err$5 = _bind$2;
                const _tmp$2 = _err$5._0;
                _err$4 = _tmp$2;
                break _L$5;
              }
              if (_bind$3 === -1) {
                return;
              } else {
                const _Some = _bind$3;
                const _payload = _Some;
                _cont$5(_payload);
                return;
              }
            }
            _err_cont$5(_err$4);
          });
          let _bind$2;
          if (_bind.$tag === 1) {
            const _ok = _bind;
            _bind$2 = _ok._0;
          } else {
            const _err$4 = _bind;
            const _tmp$2 = _err$4._0;
            _err$3 = _tmp$2;
            break _L$4;
          }
          if (_bind$2 === undefined) {
            return new Result$Ok$22$(-1);
          } else {
            const _Some = _bind$2;
            const _payload = _Some;
            _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_4(_payload, state$7, sprite_id$3, mesh_id$5, gizmo_id$7, _cont$5, _err_cont$5);
            continue _L;
          }
        }
        _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$_try$47$1006(_err$3, state$7, sprite_id$3, mesh_id$5, gizmo_id$7, _cont$5, _err_cont$5);
        continue _L;
      }
      default: {
        const _State_7 = _state$2;
        const _err_cont$6 = _State_7._4;
        const _cont$6 = _State_7._3;
        const target$2 = _State_7._2;
        const state$8 = _State_7._1;
        const _cont_param$5 = _State_7._0;
        if (Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(_cont_param$5)) {
          const _bind = moonbitlang$core$builtin$$fail$14$("WebGPU adapter unavailable", "@Milky2018/mgstudio-runtime-web:host.mbt:892:5-892:39");
          if (_bind.$tag === 1) {
            const _ok = _bind;
            _ok._0;
          } else {
            return _bind;
          }
        }
        const _bind = mizchi$js$core$$Promise$wait$8$(Milky2018$mgstudio$45$runtime$45$web$$request_device_any(_cont_param$5), (_cont_param$6) => {
          let _err$4;
          _L$5: {
            const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$async_driver$124$1281(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_6(_cont_param$6, state$8, target$2, _cont$6, _err_cont$6));
            let _bind$3;
            if (_bind$2.$tag === 1) {
              const _ok = _bind$2;
              _bind$3 = _ok._0;
            } else {
              const _err$5 = _bind$2;
              const _tmp$2 = _err$5._0;
              _err$4 = _tmp$2;
              break _L$5;
            }
            if (_bind$3 === -1) {
              return;
            } else {
              const _Some = _bind$3;
              const _payload = _Some;
              _cont$6(_payload);
              return;
            }
          }
          _err_cont$6(_err$4);
        }, _err_cont$6);
        let _tmp$2;
        if (_bind.$tag === 1) {
          const _ok = _bind;
          _tmp$2 = _ok._0;
        } else {
          return _bind;
        }
        const _tmp$3 = _tmp$2;
        if (_tmp$3.$tag === 1) {
          const _Some = _tmp$3;
          const _payload = _Some._0;
          _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_6(_payload, state$8, target$2, _cont$6, _err_cont$6);
          continue _L;
        } else {
          return new Result$Ok$22$(-1);
        }
      }
    }
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$init_webgpu(state, target, _cont, _err_cont) {
  const _bind = mizchi$js$core$$Promise$wait$8$(Milky2018$mgstudio$45$runtime$45$web$$request_adapter_any(), (_cont_param) => {
    let _err;
    _L: {
      const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$async_driver$124$1281(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_7(_cont_param, state, target, _cont, _err_cont));
      let _bind$3;
      if (_bind$2.$tag === 1) {
        const _ok = _bind$2;
        _bind$3 = _ok._0;
      } else {
        const _err$2 = _bind$2;
        const _tmp = _err$2._0;
        _err = _tmp;
        break _L;
      }
      if (_bind$3 === -1) {
        return;
      } else {
        const _Some = _bind$3;
        const _payload = _Some;
        _cont(_payload);
        return;
      }
    }
    _err_cont(_err);
  }, _err_cont);
  let _tmp;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    _tmp = _ok._0;
  } else {
    return _bind;
  }
  const _tmp$2 = _tmp;
  if (_tmp$2.$tag === 1) {
    const _Some = _tmp$2;
    const _payload = _Some._0;
    return Milky2018$mgstudio$45$runtime$45$web$$init_webgpu$46$42$async_driver$124$1281(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$init_webgpu$46$State$State_7(_payload, state, target, _cont, _err_cont));
  } else {
    return new Result$Ok$22$(-1);
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$new_state() {
  return { window: undefined, should_close: false, assets: { pending_textures: [], fallback_reported: Milky2018$mgstudio$45$runtime$45$web$$new_set(), loading_textures: Milky2018$mgstudio$45$runtime$45$web$$new_set(), texture_paths: Milky2018$mgstudio$45$runtime$45$web$$new_map(), shader_sources: Milky2018$mgstudio$45$runtime$45$web$$new_map(), shader_paths: Milky2018$mgstudio$45$runtime$45$web$$new_map(), loading_shaders: Milky2018$mgstudio$45$runtime$45$web$$new_set(), next_shader_id: 1 }, input: { pressed: Milky2018$mgstudio$45$runtime$45$web$$new_set(), just_pressed: Milky2018$mgstudio$45$runtime$45$web$$new_set(), just_released: Milky2018$mgstudio$45$runtime$45$web$$new_set(), mouse_buttons: Milky2018$mgstudio$45$runtime$45$web$$new_set(), mouse_just_pressed: Milky2018$mgstudio$45$runtime$45$web$$new_set(), mouse_just_released: Milky2018$mgstudio$45$runtime$45$web$$new_set(), mouse_x: 0, mouse_y: 0, has_cursor: false, pointer_bound: false, initialized: false }, gpu: { device: Option$None$23$, queue: Option$None$24$, context: Option$None$25$, format: undefined, pipeline: Option$None$14$, vertex_buffer: Option$None$15$, vertex_count: 0, mesh_pipeline: Option$None$14$, mesh_bind_group: Option$None$20$, gizmo_pipeline: Option$None$14$, gizmo_vertex_buffer: Option$None$15$, gizmo_vertex_capacity: 0, gizmo_lines: Milky2018$mgstudio$45$runtime$45$web$$new_array(), meshes: Milky2018$mgstudio$45$runtime$45$web$$new_map(), next_mesh_id: 1, uniform_buffer: Option$None$15$, encoder: Option$None$16$, current_texture: Option$None$17$, current_pass: Option$None$19$, current_pass_info: undefined, textures: Milky2018$mgstudio$45$runtime$45$web$$new_map(), next_texture_id: 1, fallback_texture_id: 0, sprite_shader_id: 0, mesh_shader_id: 0, gizmo_shader_id: 0 } };
}
function Milky2018$mgstudio$45$runtime$45$web$$create_host$46$tick$124$26(_env) {
  const state = _env._1;
  const step = _env._0;
  if (state.should_close) {
    return undefined;
  }
  Milky2018$mgstudio$45$runtime$45$web$$host_call0_any(step);
  Milky2018$mgstudio$45$runtime$45$web$$request_animation_frame(() => {
    Milky2018$mgstudio$45$runtime$45$web$$create_host$46$tick$124$26(_env);
  });
}
function Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$cont$124$1409(_param) {}
function Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$async_driver$124$1410(_state) {
  let _tmp = _state;
  while (true) {
    const _state$2 = _tmp;
    if (_state$2.$tag === 0) {
      const _State_0 = _state$2;
      _State_0._0;
      return undefined;
    } else {
      const _$42$try$47$1077 = _state$2;
      const id = _$42$try$47$1077._2;
      const state = _$42$try$47$1077._1;
      const _try_err = _$42$try$47$1077._0;
      const message = `Texture load error: ${moonbitlang$core$builtin$$Show$to_string$10$(_try_err)}`;
      Milky2018$mgstudio$45$runtime$45$web$$console_error(message);
      Milky2018$mgstudio$45$runtime$45$web$$dispatch_asset_error(message);
      Milky2018$mgstudio$45$runtime$45$web$$set_delete(state.assets.loading_textures, id);
      _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1408$46$State$State_0(undefined);
      continue;
    }
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$cont$124$1431(_param) {}
function Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$async_driver$124$1432(_state) {
  let _tmp = _state;
  while (true) {
    const _state$2 = _tmp;
    if (_state$2.$tag === 0) {
      const _State_0 = _state$2;
      const id = _State_0._2;
      const state = _State_0._1;
      _State_0._0;
      Milky2018$mgstudio$45$runtime$45$web$$set_delete(state.assets.loading_shaders, id);
      return undefined;
    } else {
      const _$42$try$47$1074 = _state$2;
      const id = _$42$try$47$1074._2;
      const state = _$42$try$47$1074._1;
      const _try_err = _$42$try$47$1074._0;
      const message = `Shader load error: ${moonbitlang$core$builtin$$Show$to_string$10$(_try_err)}`;
      Milky2018$mgstudio$45$runtime$45$web$$console_error(message);
      Milky2018$mgstudio$45$runtime$45$web$$dispatch_asset_error(message);
      _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1430$46$State$State_0("", state, id);
      continue;
    }
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$async_driver$124$1457(_state) {
  const _State_0 = _state;
  const resolve = _State_0._2;
  const state = _State_0._1;
  _State_0._0;
  Milky2018$mgstudio$45$runtime$45$web$$init_input(state);
  return new Result$Ok$22$(resolve(undefined));
}
function Milky2018$mgstudio$45$runtime$45$web$$create_host(canvas_opt) {
  const state = Milky2018$mgstudio$45$runtime$45$web$$new_state();
  const default_canvas = Milky2018$mgstudio$45$runtime$45$web$$ensure_canvas(canvas_opt);
  const window_create = (width, height, title) => {
    const width_num = Milky2018$mgstudio$45$runtime$45$web$$to_int(Milky2018$mgstudio$45$runtime$45$web$$number_or(width, 800));
    const height_num = Milky2018$mgstudio$45$runtime$45$web$$to_int(Milky2018$mgstudio$45$runtime$45$web$$number_or(height, 600));
    mizchi$js$core$$Any$_set(default_canvas, "width", width_num);
    mizchi$js$core$$Any$_set(default_canvas, "height", height_num);
    if (!Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(title)) {
      const text = Milky2018$mgstudio$45$runtime$45$web$$any_to_string(title);
      const _p = "";
      if (!(text === _p)) {
        mizchi$js$browser$dom$$Document$setTitle(mizchi$js$browser$dom$$document(), text);
      }
    }
    const size = Milky2018$mgstudio$45$runtime$45$web$$get_canvas_pixel_size(default_canvas);
    const pixel_width = mizchi$js$core$$Any$_get(size, "width");
    const pixel_height = mizchi$js$core$$Any$_get(size, "height");
    const scale_factor = Milky2018$mgstudio$45$runtime$45$web$$get_device_pixel_ratio();
    mizchi$js$core$$Any$_set(default_canvas, "width", pixel_width);
    mizchi$js$core$$Any$_set(default_canvas, "height", pixel_height);
    state.window = { canvas: default_canvas, width: pixel_width, height: pixel_height, scale_factor: scale_factor };
    Milky2018$mgstudio$45$runtime$45$web$$bind_pointer_events(state, default_canvas);
    return 1;
  };
  const window_poll_events = (_discard_) => {
  };
  const window_get_width = (_discard_) => {
    Milky2018$mgstudio$45$runtime$45$web$$update_window_size(state);
    const _bind = state.window;
    if (_bind === undefined) {
      return 0;
    } else {
      const _Some = _bind;
      const _window_state = _Some;
      return _window_state.width;
    }
  };
  const window_get_height = (_discard_) => {
    Milky2018$mgstudio$45$runtime$45$web$$update_window_size(state);
    const _bind = state.window;
    if (_bind === undefined) {
      return 0;
    } else {
      const _Some = _bind;
      const _window_state = _Some;
      return _window_state.height;
    }
  };
  const window_get_scale_factor = (_discard_) => {
    Milky2018$mgstudio$45$runtime$45$web$$update_window_size(state);
    const _bind = state.window;
    if (_bind === undefined) {
      return 1;
    } else {
      const _Some = _bind;
      const _window_state = _Some;
      return _window_state.scale_factor;
    }
  };
  const window_should_close = (_discard_) => state.should_close;
  const window_request_close = (_discard_) => {
    state.should_close = true;
  };
  const window_run_loop = (step) => {
    const _env = { _0: step, _1: state };
    Milky2018$mgstudio$45$runtime$45$web$$request_animation_frame(() => {
      Milky2018$mgstudio$45$runtime$45$web$$create_host$46$tick$124$26(_env);
    });
  };
  const time_now = () => Milky2018$mgstudio$45$runtime$45$web$$performance_now();
  const input_is_key_down = (code) => {
    const text = Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(code) ? "" : Milky2018$mgstudio$45$runtime$45$web$$any_to_string(code);
    return Milky2018$mgstudio$45$runtime$45$web$$set_has(state.input.pressed, text);
  };
  const input_is_key_just_pressed = (code) => {
    const text = Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(code) ? "" : Milky2018$mgstudio$45$runtime$45$web$$any_to_string(code);
    return Milky2018$mgstudio$45$runtime$45$web$$set_has(state.input.just_pressed, text);
  };
  const input_is_key_just_released = (code) => {
    const text = Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(code) ? "" : Milky2018$mgstudio$45$runtime$45$web$$any_to_string(code);
    return Milky2018$mgstudio$45$runtime$45$web$$set_has(state.input.just_released, text);
  };
  const input_finish_frame = () => {
    Milky2018$mgstudio$45$runtime$45$web$$set_clear(state.input.just_pressed);
    Milky2018$mgstudio$45$runtime$45$web$$set_clear(state.input.just_released);
    Milky2018$mgstudio$45$runtime$45$web$$set_clear(state.input.mouse_just_pressed);
    Milky2018$mgstudio$45$runtime$45$web$$set_clear(state.input.mouse_just_released);
  };
  const input_is_mouse_button_down = (name) => {
    const text = Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(name) ? "" : Milky2018$mgstudio$45$runtime$45$web$$any_to_string(name);
    return Milky2018$mgstudio$45$runtime$45$web$$set_has(state.input.mouse_buttons, text);
  };
  const input_is_mouse_button_just_pressed = (name) => {
    const text = Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(name) ? "" : Milky2018$mgstudio$45$runtime$45$web$$any_to_string(name);
    return Milky2018$mgstudio$45$runtime$45$web$$set_has(state.input.mouse_just_pressed, text);
  };
  const input_is_mouse_button_just_released = (name) => {
    const text = Milky2018$mgstudio$45$runtime$45$web$$host_is_nullish(name) ? "" : Milky2018$mgstudio$45$runtime$45$web$$any_to_string(name);
    return Milky2018$mgstudio$45$runtime$45$web$$set_has(state.input.mouse_just_released, text);
  };
  const input_mouse_x = () => state.input.mouse_x;
  const input_mouse_y = () => state.input.mouse_y;
  const input_has_cursor = () => state.input.has_cursor;
  const debug_string = (value) => {
    Milky2018$mgstudio$45$runtime$45$web$$console_error(value);
  };
  const gpu_request_device = () => {
    const _bind = state.gpu.device;
    if (_bind.$tag === 0) {
      Milky2018$mgstudio$45$runtime$45$web$$throw_error("WebGPU device not initialized. Call create_host() first.");
      return 0;
    }
    return 1;
  };
  const gpu_get_queue = (_discard_) => 1;
  const gpu_create_surface = (_discard_) => {
    const _bind = state.window;
    if (_bind === undefined) {
      Milky2018$mgstudio$45$runtime$45$web$$throw_error("Unknown window id");
      return 0;
    }
    return 1;
  };
  const gpu_configure_surface = Milky2018$mgstudio$45$runtime$45$web$$wrap_variadic((args) => {
    _L: {
      _L$2: {
        const _bind = state.gpu.context;
        if (_bind.$tag === 0) {
          break _L$2;
        } else {
          const _bind$2 = state.gpu.device;
          if (_bind$2.$tag === 0) {
            break _L$2;
          }
        }
        break _L;
      }
      return undefined;
    }
    const _bind = state.window;
    if (_bind === undefined) {
      return;
    } else {
      const _Some = _bind;
      const _window_state = _Some;
      const width_int = Milky2018$mgstudio$45$runtime$45$web$$to_int(Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 2, _window_state.width + 0));
      const height_int = Milky2018$mgstudio$45$runtime$45$web$$to_int(Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 3, _window_state.height + 0));
      _window_state.width = width_int;
      _window_state.height = height_int;
      mizchi$js$core$$Any$_set(_window_state.canvas, "width", width_int);
      mizchi$js$core$$Any$_set(_window_state.canvas, "height", height_int);
      const _bind$2 = state.gpu.context;
      if (_bind$2.$tag === 1) {
        const _Some$2 = _bind$2;
        const _context = _Some$2._0;
        const _bind$3 = state.gpu.device;
        if (_bind$3.$tag === 1) {
          const _Some$3 = _bind$3;
          const _device = _Some$3._0;
          const usage = Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_render_attachment();
          const _p = state.gpu.format;
          const _p$2 = $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$TextureFormat$Bgra8Unorm;
          let _tmp;
          if (_p === undefined) {
            _tmp = _p$2;
          } else {
            const _p$3 = _p;
            _tmp = _p$3;
          }
          const config = Milky2018$mgstudio$45$runtime$45$web$webgpu$$surface_configuration(_device, _tmp, 0, usage, Milky2018$mgstudio$45$runtime$45$web$webgpu$$surface_size(width_int, height_int));
          Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUCanvasContext$configure(_context, Milky2018$mgstudio$45$runtime$45$web$webgpu$$SurfaceConfiguration$to_js(config));
          return;
        } else {
          return;
        }
      } else {
        return;
      }
    }
  });
  const asset_load_texture = (path, nearest) => {
    const id = state.gpu.next_texture_id;
    state.gpu.next_texture_id = id + 1 | 0;
    Milky2018$mgstudio$45$runtime$45$web$$set_add(state.assets.loading_textures, id);
    const path_text = Milky2018$mgstudio$45$runtime$45$web$$coerce_asset_path(path);
    const _p = "";
    if (!(path_text === _p)) {
      Milky2018$mgstudio$45$runtime$45$web$$map_set(state.assets.texture_paths, id, path_text);
    }
    const nearest_value = Milky2018$mgstudio$45$runtime$45$web$$number_or(nearest, 0) !== 0;
    let _err;
    _L: {
      _L$2: {
        const _bind = Milky2018$mgstudio$45$runtime$45$web$$load_texture_from_path(state, id, path, nearest_value, (_cont_param) => {
          const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$async_driver$124$1410(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1408$46$State$State_0(_cont_param));
          if (_bind$2 === -1) {
            return;
          } else {
            const _Some = _bind$2;
            const _payload = _Some;
            Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$cont$124$1409(_payload);
            return;
          }
        }, (_cont_param) => {
          const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$async_driver$124$1410(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1408$46$State$_try$47$1077(_cont_param, state, id));
          if (_bind$2 === -1) {
            return;
          } else {
            const _Some = _bind$2;
            const _payload = _Some;
            Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$cont$124$1409(_payload);
            return;
          }
        });
        let _bind$2;
        if (_bind.$tag === 1) {
          const _ok = _bind;
          _bind$2 = _ok._0;
        } else {
          const _err$2 = _bind;
          const _tmp = _err$2._0;
          _err = _tmp;
          break _L$2;
        }
        if (_bind$2 === -1) {
        } else {
          const _Some = _bind$2;
          const _payload = _Some;
          Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$async_driver$124$1410(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1408$46$State$State_0(_payload));
        }
        break _L;
      }
      Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$async_driver$124$1410(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1408$46$State$_try$47$1077(_err, state, id));
    }
    return id;
  };
  const asset_load_wgsl = (path) => {
    const id = Milky2018$mgstudio$45$runtime$45$web$$next_shader_id(state);
    Milky2018$mgstudio$45$runtime$45$web$$set_add(state.assets.loading_shaders, id);
    const path_text = Milky2018$mgstudio$45$runtime$45$web$$coerce_asset_path(path);
    const _p = "";
    if (!(path_text === _p)) {
      Milky2018$mgstudio$45$runtime$45$web$$map_set(state.assets.shader_paths, id, path_text);
    }
    let _err;
    _L: {
      _L$2: {
        const _bind = Milky2018$mgstudio$45$runtime$45$web$$load_wgsl_from_path(state, id, path_text, (_cont_param) => {
          const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$async_driver$124$1432(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1430$46$State$State_0(_cont_param, state, id));
          if (_bind$2 === -1) {
            return;
          } else {
            const _Some = _bind$2;
            const _payload = _Some;
            Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$cont$124$1431(_payload);
            return;
          }
        }, (_cont_param) => {
          const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$async_driver$124$1432(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1430$46$State$_try$47$1074(_cont_param, state, id));
          if (_bind$2 === -1) {
            return;
          } else {
            const _Some = _bind$2;
            const _payload = _Some;
            Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$cont$124$1431(_payload);
            return;
          }
        });
        let _bind$2;
        if (_bind.$tag === 1) {
          const _ok = _bind;
          _bind$2 = _ok._0;
        } else {
          const _err$2 = _bind;
          const _tmp = _err$2._0;
          _err = _tmp;
          break _L$2;
        }
        if (_bind$2 === undefined) {
        } else {
          const _Some = _bind$2;
          const _payload = _Some;
          Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$async_driver$124$1432(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1430$46$State$State_0(_payload, state, id));
        }
        break _L;
      }
      Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$async_driver$124$1432(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1430$46$State$_try$47$1074(_err, state, id));
    }
    return id;
  };
  const gpu_create_render_target = (width, height, nearest) => {
    const _bind = state.gpu.device;
    if (_bind.$tag === 0) {
      Milky2018$mgstudio$45$runtime$45$web$$throw_error("GPU device not ready");
      return 0;
    }
    Milky2018$mgstudio$45$runtime$45$web$$ensure_pipeline_resources(state);
    const id = state.gpu.next_texture_id;
    state.gpu.next_texture_id = id + 1 | 0;
    Milky2018$mgstudio$45$runtime$45$web$$map_set(state.assets.texture_paths, id, "<render-target>");
    const width_value = Milky2018$mgstudio$45$runtime$45$web$$number_or(width, 1);
    const height_value = Milky2018$mgstudio$45$runtime$45$web$$number_or(height, 1);
    const safe_width = width_value > 0 ? Milky2018$mgstudio$45$runtime$45$web$$to_int(width_value) : 1;
    const safe_height = height_value > 0 ? Milky2018$mgstudio$45$runtime$45$web$$to_int(height_value) : 1;
    const _bind$2 = state.gpu.device;
    if (_bind$2.$tag === 1) {
      const _Some = _bind$2;
      const _device = _Some._0;
      const _p = state.gpu.format;
      const _p$2 = $64$Milky2018$47$mgstudio$45$runtime$45$web$47$webgpu$46$TextureFormat$Bgra8Unorm;
      let format;
      if (_p === undefined) {
        format = _p$2;
      } else {
        const _p$3 = _p;
        format = _p$3;
      }
      const texture_usage = Milky2018$mgstudio$45$runtime$45$web$webgpu$$combine_flags(Milky2018$mgstudio$45$runtime$45$web$webgpu$$combine_flags(Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_texture_binding(), Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_render_attachment()), Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_usage_copy_dst());
      const texture_desc = Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_descriptor(Milky2018$mgstudio$45$runtime$45$web$webgpu$$texture_size(safe_width, safe_height), format, texture_usage);
      const texture = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_texture(_device, Milky2018$mgstudio$45$runtime$45$web$webgpu$$TextureDescriptor$to_js(texture_desc));
      const sampler = Milky2018$mgstudio$45$runtime$45$web$$create_sampler(state, Milky2018$mgstudio$45$runtime$45$web$$number_or(nearest, 0) !== 0);
      if (sampler.$tag === 1) {
        const _Some$2 = sampler;
        const _sampler_value = _Some$2._0;
        const entry = mizchi$js$core$$from_entries([{ _0: "id", _1: id }, { _0: "texture", _1: texture }, { _0: "view", _1: Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUTexture$create_view(texture, Option$None$4$) }, { _0: "sampler", _1: _sampler_value }, { _0: "bindGroup", _1: Milky2018$mgstudio$45$runtime$45$web$$js_null() }, { _0: "width", _1: safe_width }, { _0: "height", _1: safe_height }]);
        Milky2018$mgstudio$45$runtime$45$web$$map_set(state.gpu.textures, id, entry);
        Milky2018$mgstudio$45$runtime$45$web$$ensure_bind_group_for_texture(state, entry);
      }
    }
    return id;
  };
  const gpu_create_mesh_capsule = (radius, half_length, segments) => {
    const _bind = state.gpu.device;
    if (_bind.$tag === 0) {
      Milky2018$mgstudio$45$runtime$45$web$$throw_error("GPU device not ready");
      return 0;
    }
    Milky2018$mgstudio$45$runtime$45$web$$ensure_mesh_pipeline(state);
    const id = state.gpu.next_mesh_id;
    state.gpu.next_mesh_id = id + 1 | 0;
    const vertices = Milky2018$mgstudio$45$runtime$45$web$$create_capsule_mesh_data(Milky2018$mgstudio$45$runtime$45$web$$number_or(radius, 0.5), Milky2018$mgstudio$45$runtime$45$web$$number_or(half_length, 0.5), Milky2018$mgstudio$45$runtime$45$web$$to_int(Milky2018$mgstudio$45$runtime$45$web$$number_or(segments, 16)));
    const _bind$2 = state.gpu.device;
    if (_bind$2.$tag === 1) {
      const _Some = _bind$2;
      const _device = _Some._0;
      const vertex_size = mizchi$js$core$$Any$_get(vertices, "byteLength");
      const vertex_usage = Milky2018$mgstudio$45$runtime$45$web$webgpu$$combine_flags(Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_usage_vertex(), Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_usage_copy_dst());
      const vertex_desc = Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_descriptor(vertex_size, vertex_usage);
      const vertex_buffer = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_buffer(_device, Milky2018$mgstudio$45$runtime$45$web$webgpu$$BufferDescriptor$to_js(vertex_desc));
      Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUQueue$write_buffer(Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$queue(_device), vertex_buffer, 0, vertices);
      const vertex_len = mizchi$js$core$$Any$_get(vertices, "length");
      const vertex_count = Milky2018$mgstudio$45$runtime$45$web$$to_int(vertex_len / 2);
      const entry = mizchi$js$core$$from_entries([{ _0: "id", _1: id }, { _0: "vertexBuffer", _1: vertex_buffer }, { _0: "vertexCount", _1: vertex_count }]);
      Milky2018$mgstudio$45$runtime$45$web$$map_set(state.gpu.meshes, id, entry);
    }
    return id;
  };
  const gpu_create_mesh_rectangle = (width, height) => {
    const _bind = state.gpu.device;
    if (_bind.$tag === 0) {
      Milky2018$mgstudio$45$runtime$45$web$$throw_error("GPU device not ready");
      return 0;
    }
    Milky2018$mgstudio$45$runtime$45$web$$ensure_mesh_pipeline(state);
    const id = state.gpu.next_mesh_id;
    state.gpu.next_mesh_id = id + 1 | 0;
    const vertices = Milky2018$mgstudio$45$runtime$45$web$$create_rectangle_mesh_data(Milky2018$mgstudio$45$runtime$45$web$$number_or(width, 1), Milky2018$mgstudio$45$runtime$45$web$$number_or(height, 1));
    const _bind$2 = state.gpu.device;
    if (_bind$2.$tag === 1) {
      const _Some = _bind$2;
      const _device = _Some._0;
      const vertex_size = mizchi$js$core$$Any$_get(vertices, "byteLength");
      const vertex_usage = Milky2018$mgstudio$45$runtime$45$web$webgpu$$combine_flags(Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_usage_vertex(), Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_usage_copy_dst());
      const vertex_desc = Milky2018$mgstudio$45$runtime$45$web$webgpu$$buffer_descriptor(vertex_size, vertex_usage);
      const vertex_buffer = Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$create_buffer(_device, Milky2018$mgstudio$45$runtime$45$web$webgpu$$BufferDescriptor$to_js(vertex_desc));
      Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUQueue$write_buffer(Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUDevice$queue(_device), vertex_buffer, 0, vertices);
      const vertex_len = mizchi$js$core$$Any$_get(vertices, "length");
      const vertex_count = Milky2018$mgstudio$45$runtime$45$web$$to_int(vertex_len / 2);
      const entry = mizchi$js$core$$from_entries([{ _0: "id", _1: id }, { _0: "vertexBuffer", _1: vertex_buffer }, { _0: "vertexCount", _1: vertex_count }]);
      Milky2018$mgstudio$45$runtime$45$web$$map_set(state.gpu.meshes, id, entry);
    }
    return id;
  };
  const gpu_begin_frame = (_discard_) => Milky2018$mgstudio$45$runtime$45$web$$begin_frame(state);
  const gpu_begin_pass = Milky2018$mgstudio$45$runtime$45$web$$wrap_variadic((args) => {
    Milky2018$mgstudio$45$runtime$45$web$$begin_pass(state, Milky2018$mgstudio$45$runtime$45$web$$to_int(Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 0, -1)), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 1, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 2, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 3, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 4, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 5, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 6, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 7, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 8, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 9, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 10, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 11, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 12, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 13, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 14, 0));
  });
  const gpu_draw_sprite = Milky2018$mgstudio$45$runtime$45$web$$wrap_variadic((args) => {
    Milky2018$mgstudio$45$runtime$45$web$$draw_sprite(state, Milky2018$mgstudio$45$runtime$45$web$$to_int(Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 0, 0)), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 1, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 2, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 3, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 4, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 5, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 6, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 7, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 8, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 9, 1));
  });
  const gpu_draw_mesh = Milky2018$mgstudio$45$runtime$45$web$$wrap_variadic((args) => {
    Milky2018$mgstudio$45$runtime$45$web$$draw_mesh(state, Milky2018$mgstudio$45$runtime$45$web$$to_int(Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 0, 0)), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 1, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 2, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 3, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 4, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 5, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 6, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 7, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 8, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 9, 1));
  });
  const gpu_draw_gizmo_line = Milky2018$mgstudio$45$runtime$45$web$$wrap_variadic((args) => {
    Milky2018$mgstudio$45$runtime$45$web$$push_gizmo_line(state.gpu.gizmo_lines, Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 0, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 1, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 2, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 3, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 4, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 5, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 6, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 7, 0), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 8, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 9, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 10, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 11, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 12, 2), Milky2018$mgstudio$45$runtime$45$web$$to_int(Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 13, 0)), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 14, 1), Milky2018$mgstudio$45$runtime$45$web$$arg_number(args, 15, 1));
  });
  const gpu_end_pass = () => {
    const _bind = state.gpu.current_pass;
    if (_bind.$tag === 1) {
      Milky2018$mgstudio$45$runtime$45$web$$draw_gizmo_lines(state, state.gpu.gizmo_lines);
    }
    const _bind$2 = state.gpu.current_pass;
    if (_bind$2.$tag === 1) {
      const _Some = _bind$2;
      const _pass = _Some._0;
      Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$end(_pass);
    }
    state.gpu.current_pass = Option$None$19$;
    state.gpu.current_pass_info = undefined;
    state.gpu.gizmo_lines = Milky2018$mgstudio$45$runtime$45$web$$new_array();
  };
  const gpu_end_frame = (_discard_) => {
    _L: {
      _L$2: {
        const _bind = state.gpu.device;
        if (_bind.$tag === 0) {
          break _L$2;
        } else {
          const _bind$2 = state.gpu.queue;
          if (_bind$2.$tag === 0) {
            break _L$2;
          } else {
            const _bind$3 = state.gpu.encoder;
            if (_bind$3.$tag === 0) {
              break _L$2;
            }
          }
        }
        break _L;
      }
      return undefined;
    }
    const _bind = state.gpu.current_pass;
    if (_bind.$tag === 1) {
      const _Some = _bind;
      const _pass = _Some._0;
      Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPURenderPassEncoder$end(_pass);
    }
    const _bind$2 = state.gpu.encoder;
    if (_bind$2.$tag === 1) {
      const _Some = _bind$2;
      const _encoder = _Some._0;
      const _bind$3 = state.gpu.queue;
      if (_bind$3.$tag === 1) {
        const _Some$2 = _bind$3;
        const _queue = _Some$2._0;
        Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUQueue$submit(_queue, [Milky2018$mgstudio$45$runtime$45$web$webgpu$$GPUCommandEncoder$finish(_encoder)]);
      }
    }
    state.gpu.encoder = Option$None$16$;
    state.gpu.current_texture = Option$None$17$;
    state.gpu.current_pass = Option$None$19$;
    state.gpu.current_pass_info = undefined;
  };
  const mgstudio_host = mizchi$js$core$$from_entries([{ _0: "window_create", _1: window_create }, { _0: "window_poll_events", _1: window_poll_events }, { _0: "window_get_width", _1: window_get_width }, { _0: "window_get_height", _1: window_get_height }, { _0: "window_get_scale_factor", _1: window_get_scale_factor }, { _0: "window_should_close", _1: window_should_close }, { _0: "window_request_close", _1: window_request_close }, { _0: "window_run_loop", _1: window_run_loop }, { _0: "time_now", _1: time_now }, { _0: "input_is_key_down", _1: input_is_key_down }, { _0: "input_is_key_just_pressed", _1: input_is_key_just_pressed }, { _0: "input_is_key_just_released", _1: input_is_key_just_released }, { _0: "input_finish_frame", _1: input_finish_frame }, { _0: "input_is_mouse_button_down", _1: input_is_mouse_button_down }, { _0: "input_is_mouse_button_just_pressed", _1: input_is_mouse_button_just_pressed }, { _0: "input_is_mouse_button_just_released", _1: input_is_mouse_button_just_released }, { _0: "input_mouse_x", _1: input_mouse_x }, { _0: "input_mouse_y", _1: input_mouse_y }, { _0: "input_has_cursor", _1: input_has_cursor }, { _0: "debug_string", _1: debug_string }, { _0: "gpu_request_device", _1: gpu_request_device }, { _0: "gpu_get_queue", _1: gpu_get_queue }, { _0: "gpu_create_surface", _1: gpu_create_surface }, { _0: "gpu_configure_surface", _1: gpu_configure_surface }, { _0: "asset_load_texture", _1: asset_load_texture }, { _0: "asset_load_wgsl", _1: asset_load_wgsl }, { _0: "gpu_create_render_target", _1: gpu_create_render_target }, { _0: "gpu_create_mesh_capsule", _1: gpu_create_mesh_capsule }, { _0: "gpu_create_mesh_rectangle", _1: gpu_create_mesh_rectangle }, { _0: "gpu_begin_frame", _1: gpu_begin_frame }, { _0: "gpu_begin_pass", _1: gpu_begin_pass }, { _0: "gpu_draw_sprite", _1: gpu_draw_sprite }, { _0: "gpu_draw_mesh", _1: gpu_draw_mesh }, { _0: "gpu_draw_gizmo_line", _1: gpu_draw_gizmo_line }, { _0: "gpu_end_pass", _1: gpu_end_pass }, { _0: "gpu_end_frame", _1: gpu_end_frame }]);
  const init = () => mizchi$js$core$$Promise$new$14$((resolve, _reject, _cont, _err_cont) => {
    const _bind = Milky2018$mgstudio$45$runtime$45$web$$init_webgpu(state, default_canvas, (_cont_param) => {
      let _err;
      _L: {
        const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$async_driver$124$1457(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1454$46$State$State_0(_cont_param, state, resolve));
        let _bind$3;
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          _bind$3 = _ok._0;
        } else {
          const _err$2 = _bind$2;
          const _tmp = _err$2._0;
          _err = _tmp;
          break _L;
        }
        if (_bind$3 === -1) {
          return;
        } else {
          const _Some = _bind$3;
          const _payload = _Some;
          _cont(_payload);
          return;
        }
      }
      _err_cont(_err);
    }, _err_cont);
    let _bind$2;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _bind$2 = _ok._0;
    } else {
      return _bind;
    }
    if (_bind$2 === -1) {
      return new Result$Ok$22$(-1);
    } else {
      const _Some = _bind$2;
      const _payload = _Some;
      return Milky2018$mgstudio$45$runtime$45$web$$create_host$46$42$async_driver$124$1457(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$create_host$46$lambda$46$lambda$47$1454$46$State$State_0(_payload, state, resolve));
    }
  });
  return mizchi$js$core$$from_entries([{ _0: "mgstudio_host", _1: mgstudio_host }, { _0: "init", _1: init }]);
}
function Milky2018$mgstudio$45$runtime$45$web$$main_async$46$start_example$124$575(_env, name) {
  const set_status = _env._2;
  const running = _env._1;
  const exports = _env._0;
  const entry = mizchi$js$core$$Any$_get(exports, name);
  if (!Milky2018$mgstudio$45$runtime$45$web$$is_function(entry)) {
    set_status(`Missing export: ${name}`);
    return false;
  }
  running.val = true;
  Milky2018$mgstudio$45$runtime$45$web$$call0_any(entry);
  set_status(`Running: ${Milky2018$mgstudio$45$runtime$45$web$$strip_run_prefix(name)}`);
  return true;
}
function Milky2018$mgstudio$45$runtime$45$web$$main_async$46$42$async_driver$124$1472(_state) {
  let _tmp = _state;
  while (true) {
    const _state$2 = _tmp;
    if (_state$2.$tag === 0) {
      const _State_0 = _state$2;
      const set_status = _State_0._2;
      const doc = _State_0._1;
      const _cont_param = _State_0._0;
      const exports = mizchi$js$web$webassembly$$WebAssemblyInstance$exports(_cont_param);
      const export_names = Milky2018$mgstudio$45$runtime$45$web$$object_keys(exports);
      mizchi$js$core$$log(export_names);
      set_status("WASM loaded. Choose an example.");
      const running = { val: false };
      const _env = { _0: exports, _1: running, _2: set_status };
      const menu_found = Milky2018$mgstudio$45$runtime$45$web$$setup_menu(doc, (name, _button) => {
        if (running.val) {
          Milky2018$mgstudio$45$runtime$45$web$$reload_with_run_target(name);
          return undefined;
        }
        Milky2018$mgstudio$45$runtime$45$web$$main_async$46$start_example$124$575(_env, name);
      }, () => {
        Milky2018$mgstudio$45$runtime$45$web$$reload_page();
      });
      const auto_run = Milky2018$mgstudio$45$runtime$45$web$$get_run_target_from_url();
      const _p = "";
      if (!(auto_run === _p)) {
        Milky2018$mgstudio$45$runtime$45$web$$main_async$46$start_example$124$575(_env, auto_run);
      }
      return !menu_found ? new Result$Ok$22$(set_status(`WASM loaded. Exports: ${Milky2018$mgstudio$45$runtime$45$web$$join_strings(export_names, ", ")}`)) : new Result$Ok$22$(undefined);
    } else {
      const _State_1 = _state$2;
      const _err_cont = _State_1._5;
      const _cont = _State_1._4;
      const host = _State_1._3;
      const set_status = _State_1._2;
      const doc = _State_1._1;
      _State_1._0;
      set_status("WebGPU initialized.");
      const imports = mizchi$js$core$$new_object();
      Milky2018$mgstudio$45$runtime$45$web$$object_assign(imports, host);
      const spectest = mizchi$js$core$$from_entries([{ _0: "print_char", _1: Milky2018$mgstudio$45$runtime$45$web$$make_print_char() }]);
      mizchi$js$core$$Any$_set(imports, "spectest", spectest);
      const moonbit_ffi = mizchi$js$core$$from_entries([{ _0: "make_closure", _1: Milky2018$mgstudio$45$runtime$45$web$$make_closure }]);
      mizchi$js$core$$Any$_set(imports, "moonbit:ffi", moonbit_ffi);
      set_status("Loading WASM...");
      const _bind = Milky2018$mgstudio$45$runtime$45$web$$load_wasm(imports, (_cont_param) => {
        let _err;
        _L: {
          const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$main_async$46$42$async_driver$124$1472(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$main_async$46$State$State_0(_cont_param, doc, set_status));
          let _bind$3;
          if (_bind$2.$tag === 1) {
            const _ok = _bind$2;
            _bind$3 = _ok._0;
          } else {
            const _err$2 = _bind$2;
            const _tmp$2 = _err$2._0;
            _err = _tmp$2;
            break _L;
          }
          if (_bind$3 === -1) {
            return;
          } else {
            const _Some = _bind$3;
            const _payload = _Some;
            _cont(_payload);
            return;
          }
        }
        _err_cont(_err);
      }, _err_cont);
      let _tmp$2;
      if (_bind.$tag === 1) {
        const _ok = _bind;
        _tmp$2 = _ok._0;
      } else {
        return _bind;
      }
      const _tmp$3 = _tmp$2;
      if (_tmp$3.$tag === 1) {
        const _Some = _tmp$3;
        const _payload = _Some._0;
        _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$main_async$46$State$State_0(_payload, doc, set_status);
        continue;
      } else {
        return new Result$Ok$22$(-1);
      }
    }
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$main_async(_cont, _err_cont) {
  const doc = mizchi$js$browser$dom$$document();
  const win = mizchi$js$browser$dom$$window();
  const set_status = Milky2018$mgstudio$45$runtime$45$web$$create_status_overlay(doc);
  if (!Milky2018$mgstudio$45$runtime$45$web$$has_webgpu()) {
    set_status("WebGPU is not available in this browser.");
    return new Result$Ok$22$(undefined);
  }
  const format = Milky2018$mgstudio$45$runtime$45$web$webgpu$$preferred_canvas_format();
  mizchi$js$core$$log(`WebGPU format: ${format}`);
  mizchi$js$web$event$$EventTarget$addEventListener$46$inner(win, "mgstudio-asset-error", (event) => {
    const detail = mizchi$js$core$$Any$_get(event, "detail");
    const message = Milky2018$mgstudio$45$runtime$45$web$$is_nullish(detail) ? "Unknown asset error" : detail;
    set_status(`Asset error: ${message}`);
  }, false, false, false, Option$None$10$);
  const canvas_opt = mizchi$js$browser$dom$$Document$getElementById(doc, "mgstudio-canvas");
  if (canvas_opt.$tag === 0) {
    set_status("Missing canvas element.");
    return new Result$Ok$22$(undefined);
  }
  if (canvas_opt.$tag === 1) {
    const _Some = canvas_opt;
    const _canvas = _Some._0;
    const host = Milky2018$mgstudio$45$runtime$45$web$$create_host(new Option$Some$8$(_canvas));
    const init_promise = Milky2018$mgstudio$45$runtime$45$web$$call0_any(mizchi$js$core$$Any$_get(host, "init"));
    const _bind = mizchi$js$core$$Promise$wait$8$(init_promise, (_cont_param) => {
      let _err;
      _L: {
        const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$main_async$46$42$async_driver$124$1472(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$main_async$46$State$State_1(_cont_param, doc, set_status, host, _cont, _err_cont));
        let _bind$3;
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          _bind$3 = _ok._0;
        } else {
          const _err$2 = _bind$2;
          const _tmp = _err$2._0;
          _err = _tmp;
          break _L;
        }
        if (_bind$3 === -1) {
          return;
        } else {
          const _Some$2 = _bind$3;
          const _payload = _Some$2;
          _cont(_payload);
          return;
        }
      }
      _err_cont(_err);
    }, _err_cont);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    const _tmp$2 = _tmp;
    if (_tmp$2.$tag === 1) {
      const _Some$2 = _tmp$2;
      const _payload = _Some$2._0;
      return Milky2018$mgstudio$45$runtime$45$web$$main_async$46$42$async_driver$124$1472(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$main_async$46$State$State_1(_payload, doc, set_status, host, _cont, _err_cont));
    } else {
      return new Result$Ok$22$(-1);
    }
  } else {
    return new Result$Ok$22$(undefined);
  }
}
function Milky2018$mgstudio$45$runtime$45$web$$_init$42$46$42$cont$124$1503(_param) {}
function Milky2018$mgstudio$45$runtime$45$web$$_init$42$46$42$async_driver$124$1504(_state) {
  let _tmp = _state;
  while (true) {
    const _state$2 = _tmp;
    if (_state$2.$tag === 0) {
      const _State_0 = _state$2;
      _State_0._0;
      return undefined;
    } else {
      const _$42$try$47$1140 = _state$2;
      const _try_err = _$42$try$47$1140._0;
      mizchi$js$core$$log(_try_err);
      const doc = mizchi$js$browser$dom$$document();
      const set_status = Milky2018$mgstudio$45$runtime$45$web$$create_status_overlay(doc);
      _tmp = new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$42$init$46$lambda$47$1502$46$State$State_0(set_status(`Error: ${moonbitlang$core$builtin$$Show$to_string$10$(_try_err)}`));
      continue;
    }
  }
}
(() => {
  let _err;
  _L: {
    _L$2: {
      const _bind = Milky2018$mgstudio$45$runtime$45$web$$main_async((_cont_param) => {
        const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$_init$42$46$42$async_driver$124$1504(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$42$init$46$lambda$47$1502$46$State$State_0(_cont_param));
        if (_bind$2 === -1) {
          return;
        } else {
          const _Some = _bind$2;
          const _payload = _Some;
          Milky2018$mgstudio$45$runtime$45$web$$_init$42$46$42$cont$124$1503(_payload);
          return;
        }
      }, (_cont_param) => {
        const _bind$2 = Milky2018$mgstudio$45$runtime$45$web$$_init$42$46$42$async_driver$124$1504(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$42$init$46$lambda$47$1502$46$State$_try$47$1140(_cont_param));
        if (_bind$2 === -1) {
          return;
        } else {
          const _Some = _bind$2;
          const _payload = _Some;
          Milky2018$mgstudio$45$runtime$45$web$$_init$42$46$42$cont$124$1503(_payload);
          return;
        }
      });
      let _bind$2;
      if (_bind.$tag === 1) {
        const _ok = _bind;
        _bind$2 = _ok._0;
      } else {
        const _err$2 = _bind;
        const _tmp = _err$2._0;
        _err = _tmp;
        break _L$2;
      }
      if (_bind$2 === -1) {
      } else {
        const _Some = _bind$2;
        const _payload = _Some;
        Milky2018$mgstudio$45$runtime$45$web$$_init$42$46$42$async_driver$124$1504(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$42$init$46$lambda$47$1502$46$State$State_0(_payload));
      }
      break _L;
    }
    Milky2018$mgstudio$45$runtime$45$web$$_init$42$46$42$async_driver$124$1504(new $36$Milky2018$47$mgstudio$45$runtime$45$web$46$42$init$46$lambda$47$1502$46$State$_try$47$1140(_err));
  }
})();
