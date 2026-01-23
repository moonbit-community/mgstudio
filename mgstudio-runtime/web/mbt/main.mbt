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
extern "js" fn reload_with_run_target(target : String) -> Unit =
  #| (target) => {
  #|   const url = new URL(window.location.href)
  #|   url.searchParams.set("run", target)
  #|   window.location.href = url.toString()
  #| }

///|
extern "js" fn get_run_target_from_url() -> String =
  #| () => {
  #|   const params = new URLSearchParams(window.location.search)
  #|   const target = params.get("run")
  #|   return target ? target.trim() : ""
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
extern "js" fn strip_run_prefix(value : String) -> String =
  #| (value) => value.startsWith("run_") ? value.slice(4) : value

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
fn make_closure(funcref : @js.Any, closure : @js.Any) -> @js.Any {
  funcref._call("bind", [@js.undefined(), closure]).cast()
}

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
      let run_target = button.getAttribute("data-run")
      let action = button.getAttribute("data-action")
      if run_target is Some(target) {
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
async fn load_wasm(imports : @js.Any) -> @webassembly.WebAssemblyInstance {
  let response = @http.fetch("./runner.wasm", method_="GET")
  if !response.ok {
    fail("Failed to fetch runner.wasm: " + response.status.to_string())
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
    let host = create_host(Some(canvas))
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
    set_status("Loading WASM...")
    let instance = load_wasm(imports)
    let exports = instance.exports()
    set_global_wasm_exports(exports)
    let export_names = object_keys(exports)
    @js.log(@js.any(export_names))
    set_status("WASM loaded. Choose an example.")
    let mut running = false
    let start_example = fn(name : String) -> Bool {
      let entry = exports._get(name).cast()
      if !is_function(entry) {
        set_status("Missing export: " + name)
        return false
      }
      running = true
      call0_any(entry) |> ignore
      set_status("Running: " + strip_run_prefix(name))
      true
    }
    let menu_found = setup_menu(
      doc,
      fn(name, _button) {
        if running {
          reload_with_run_target(name)
          return
        }
        start_example(name) |> ignore
      },
      fn() { reload_page() },
    )
    let auto_run = get_run_target_from_url()
    if auto_run != "" {
      start_example(auto_run) |> ignore
    }
    if !menu_found {
      set_status("WASM loaded. Exports: " + join_strings(export_names, ", "))
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
