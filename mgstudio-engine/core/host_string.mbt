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
/// Host string interop helpers.
///
/// We do not pass wasm `String` across the host boundary. Instead, the guest
/// interns strings into the host via the `string_sink_*` protocol and passes an
/// `Int` handle (string id) to other host calls.

///|
fn host_string_sink_reset() -> Unit = "mgstudio_host" "string_sink_reset"

///|
fn host_string_sink_push(code_unit : Int) -> Unit = "mgstudio_host" "string_sink_push"

///|
fn host_string_sink_take() -> Int = "mgstudio_host" "string_sink_take"

///|
fn host_string_drop(id : Int) -> Unit = "mgstudio_host" "string_drop"

///|
pub fn[T] with_host_string_id(text : String, f : (Int) -> T) -> T {
  // NOTE: Avoid `String` equality (`==`) in wasm guest code for now.
  // `Milky2018/wasmoon` currently traps on string equality (unreachable).
  if text.length() == 0 {
    return f(0)
  }
  host_string_sink_reset()
  let n = text.length()
  for i in 0..<n {
    host_string_sink_push(text.code_unit_at(i).to_int())
  }
  let id = host_string_sink_take()
  let out = f(id)
  if id > 0 {
    host_string_drop(id)
  }
  out
}
