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
/// Host bytes interop helpers.
///
/// Similar to `with_host_string_id`, but for raw bytes (e.g. RGBA8 uploads).
/// We avoid passing wasm-gc `Bytes` across the host boundary directly.

///|
fn host_bytes_sink_reset() -> Unit = "mgstudio_host" "bytes_sink_reset"

///|
fn host_bytes_sink_push(byte : Int) -> Unit = "mgstudio_host" "bytes_sink_push"

///|
fn host_bytes_sink_take() -> Int = "mgstudio_host" "bytes_sink_take"

///|
fn host_bytes_drop(id : Int) -> Unit = "mgstudio_host" "bytes_drop"

///|
pub fn[T] with_host_bytes_id(data : Bytes, f : (Int) -> T) -> T {
  if data.length() == 0 {
    return f(0)
  }
  host_bytes_sink_reset()
  let n = data.length()
  for i in 0..<n {
    let b = match data.get(i) {
      None => 0
      Some(v) => v.to_int()
    }
    host_bytes_sink_push(b)
  }
  let id = host_bytes_sink_take()
  let out = f(id)
  if id > 0 {
    host_bytes_drop(id)
  }
  out
}
