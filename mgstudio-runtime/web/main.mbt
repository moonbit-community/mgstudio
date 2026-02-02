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
extern "js" fn object_keys(obj : @js.Any) -> Array[String] =
  #| (obj) => Object.keys(obj)

///|
extern "js" fn object_assign(target : @js.Any, source : @js.Any) -> @js.Any =
  #| (target, source) => Object.assign(target, source)

///|
extern "js" fn call0_any(func : @js.Any) -> @js.Any =
  #| (func) => func()

///|
extern "js" fn is_function(value : @js.Any) -> Bool =
  #| (value) => typeof value === "function"

///|
extern "js" fn is_nullish(value : @js.Any) -> Bool =
  #| (value) => value == null

///|
extern "js" fn char_from_code(code : Int) -> String =
  #| (code) => String.fromCharCode(code)

///|
extern "js" fn has_webgpu() -> Bool =
  #| () => !!navigator.gpu

///|
extern "js" fn reload_page() -> Unit =
  #| () => window.location.reload()

///|
extern "js" fn reload_with_wasm_path(path : String) -> Unit =
  #| (path) => {
  #|   const url = new URL(window.location.href)
  #|   url.searchParams.set("wasm", path)
  #|   window.location.href = url.toString()
  #| }

///|
extern "js" fn get_wasm_path_from_url() -> String =
  #| () => {
  #|   const params = new URLSearchParams(window.location.search)
  #|   const value = params.get("wasm")
  #|   return value ? value.trim() : ""
  #| }

///|
extern "js" fn get_assets_source_from_url() -> String =
  #| () => {
  #|   const params = new URLSearchParams(window.location.search)
  #|   const value = params.get("assets_source")
  #|   return value ? value.trim() : ""
  #| }

///|
extern "js" fn get_data_source_from_url() -> String =
  #| () => {
  #|   const params = new URLSearchParams(window.location.search)
  #|   const value = params.get("data_source")
  #|   return value ? value.trim() : ""
  #| }

///|
extern "js" fn response_array_buffer(response : @js.Any) -> @js.Any =
  #| (response) => response.arrayBuffer()

///|
extern "js" fn instantiate_streaming(
  response : @js.Any,
  imports : @js.Any,
  options : @js.Any,
) -> @js.Any =
  #| async (response, imports, options) =>
  #|   await WebAssembly.instantiateStreaming(response, imports, options)

///|
extern "js" fn instantiate_bytes_with_options(
  bytes : @arraybuffer.Uint8Array,
  imports : @js.Any,
  options : @js.Any,
) -> @js.Any =
  #| async (bytes, imports, options) =>
  #|   await WebAssembly.instantiate(bytes, imports, options)

///|
extern "js" fn join_strings(values : Array[String], sep : String) -> String =
  #| (values, sep) => values.join(sep)

///|
extern "js" fn set_global_wasm_exports(exports : @js.Any) -> Unit =
  #| (exports) => { globalThis.__mgstudio_wasm_exports = exports }

///|
fn set_style(style : @js.Any, name : String, value : String) -> Unit {
  style._set(name, @js.any(value)) |> ignore
}

///|
fn set_text(element : @dom.Element, text : String) -> Unit {
  element.as_any()._set("textContent", @js.any(text)) |> ignore
}

///|
fn create_status_overlay(doc : @dom.Document) -> (String) -> Unit {
  let overlay = doc.createElement("div")
  let style : @js.Any = overlay.as_any()._get("style").cast()
  set_style(style, "position", "fixed")
  set_style(style, "left", "12px")
  set_style(style, "top", "12px")
  set_style(style, "padding", "8px 12px")
  set_style(style, "background", "rgba(0, 0, 0, 0.7)")
  set_style(style, "color", "#ffffff")
  set_style(style, "fontFamily", "monospace")
  set_style(style, "fontSize", "12px")
  set_style(style, "zIndex", "9999")
  set_text(overlay, "Loading...")
  if doc.body() is Some(body) {
    body.as_any()._call("appendChild", [overlay.as_any()]) |> ignore
  } else {
    doc
    .as_any()
    ._get("documentElement")
    ._call("appendChild", [overlay.as_any()])
    |> ignore
  }
  fn set_status(text : String) -> Unit {
    set_text(overlay, text)
  }

  set_status
}

///|
fn make_print_char() -> (Int) -> Unit {
  let mut buffer = ""
  fn handle(code : Int) -> Unit {
    let char = char_from_code(code)
    if char == "\n" {
      @js.log(@js.any(buffer))
      buffer = ""
    } else {
      buffer = buffer + char
    }
  }

  handle
}

///|
extern "js" fn make_closure(funcref : @js.Any, closure : @js.Any) -> @js.Any =
  #| (funcref, closure) => {
  #|   if (typeof funcref !== "function") {
  #|     return () => {}
  #|   }
  #|   if (typeof funcref.bind === "function") {
  #|     return funcref.bind(null, closure)
  #|   }
  #|   return (...args) => funcref(closure, ...args)
  #| }

///|
fn setup_menu(
  doc : @dom.Document,
  on_run : (String, @dom.Element) -> Unit,
  on_reload : () -> Unit,
) -> Bool {
  let menu = doc.getElementById("mgstudio-menu")
  if menu is Some(menu_el) {
    let buttons = menu_el.getElementsByTagName("button")
    for button in buttons {
      let wasm_target = button.getAttribute("data-wasm")
      let action = button.getAttribute("data-action")
      if wasm_target is Some(target) {
        button
        .as_event_target()
        .addEventListener("click", fn(_) { on_run(target, button) })
      } else if action is Some(value) && value == "reload" {
        button
        .as_event_target()
        .addEventListener("click", fn(_) { on_reload() })
      }
    }
    true
  } else {
    false
  }
}

///|

///|
async fn load_wasm(
  imports : @js.Any,
  wasm_path : String,
) -> @webassembly.WebAssemblyInstance {
  let response = @http.fetch(wasm_path, method_="GET")
  if !response.ok {
    fail(
      "Failed to fetch wasm (" + wasm_path + "): " + response.status.to_string(),
    )
  }
  let fallback = response.clone()
  // Keep Web instantiation options empty to match the Native (wasmoon) ABI.
  // In particular, we do NOT enable the JS builtin string mode here.
  let wasm_options = @js.new_object()
  let instance = try {
    let promise : @js.Promise[@js.Any] = instantiate_streaming(
      response.as_any(),
      imports,
      wasm_options,
    ).cast()
    let result = promise.wait()
    result._get("instance").cast()
  } catch {
    _ => {
      let buffer_promise : @js.Promise[@arraybuffer.ArrayBuffer] = response_array_buffer(
        fallback.as_any(),
      ).cast()
      let buffer = buffer_promise.wait()
      let bytes = @arraybuffer.Uint8Array::from_array_buffer(buffer)
      let promise : @js.Promise[@js.Any] = instantiate_bytes_with_options(
        bytes, imports, wasm_options,
      ).cast()
      let result = promise.wait()
      result._get("instance").cast()
    }
  }
  instance
}

///|
async fn main_async() -> Unit {
  let doc = @dom.document()
  let win = @dom.window()
  let set_status = create_status_overlay(doc)
  if !has_webgpu() {
    set_status("WebGPU is not available in this browser.")
    return
  }
  let format = @webgpu.preferred_canvas_format()
  @js.log(@js.any("WebGPU format: " + format))
  win
  .as_event_target()
  .addEventListener("mgstudio-asset-error", fn(event) {
    let detail : @js.Any = event._get("detail").cast()
    let message = if is_nullish(detail) {
      "Unknown asset error"
    } else {
      detail.cast()
    }
    set_status("Asset error: " + message)
  })
  let canvas_opt = doc.getElementById("mgstudio-canvas")
  if canvas_opt is None {
    set_status("Missing canvas element.")
    return
  }
  if canvas_opt is Some(canvas) {
    let assets_source = get_assets_source_from_url()
    let data_source = get_data_source_from_url()
    let assets_source_final = if assets_source != "" {
      assets_source
    } else {
      // `mgstudio serve` stages the final overlay assets under `./_mgstudio_assets/`.
      // Default to it so opening the served root without query params works.
      "dir:./_mgstudio_assets/"
    }
    let data_source_final = if data_source != "" {
      data_source
    } else {
      "idb:mgstudio"
    }
    let host = create_host(Some(canvas), assets_source_final, data_source_final)
    let init_promise : @js.Promise[@js.Any] = call0_any(
      host._get("init").cast(),
    ).cast()
    init_promise.wait() |> ignore
    set_status("WebGPU initialized.")
    let imports = @js.new_object()
    object_assign(imports, host) |> ignore
    let spectest = @js.from_entries([
      ("print_char", @js.from_fn1(make_print_char())),
    ])
    imports._set("spectest", spectest) |> ignore
    let moonbit_ffi = @js.from_entries([
      ("make_closure", @js.from_fn2(make_closure)),
    ])
    imports._set("moonbit:ffi", moonbit_ffi) |> ignore
    let mut running = false
    let start_example = async fn(wasm_path : String) -> Bool noraise {
      set_status("Loading WASM: " + wasm_path)
      let instance = load_wasm(imports, wasm_path) catch {
        err => {
          set_status("Failed to load wasm: " + any_to_string(@js.any(err)))
          return false
        }
      }
      let exports = instance.exports()
      set_global_wasm_exports(exports)
      let export_names = object_keys(exports)
      @js.log(@js.any(export_names))
      let entry = exports._get("game_app").cast()
      if !is_function(entry) {
        set_status(
          "Missing export: game_app (available: " +
          join_strings(export_names, ", ") +
          ")",
        )
        return false
      }
      running = true
      call0_any(entry) |> ignore
      set_status("Running: " + wasm_path)
      true
    }
    let menu_found = setup_menu(
      doc,
      fn(wasm_path, _button) {
        if running {
          reload_with_wasm_path(wasm_path)
          return
        }
        @js.run_async(async fn() noraise { start_example(wasm_path) |> ignore })
      },
      fn() { reload_page() },
    )
    let auto_wasm = get_wasm_path_from_url()
    if auto_wasm != "" {
      start_example(auto_wasm) |> ignore
    } else {
      set_status("Choose an example.")
    }
    if !menu_found {
      set_status("Missing menu element. Append ?wasm=<path> to auto-run.")
    }
  }
}

///|
fn main {
  @js.run_async(async fn() noraise {
    let result = main_async() catch {
      err => {
        @js.log(@js.any(err))
        let doc = @dom.document()
        let set_status = create_status_overlay(doc)
        // `err.to_string()` can fail when the caught value is a JS exception.
        set_status("Error: " + any_to_string(@js.any(err)))
      }
    }
    result |> ignore
  })
}
