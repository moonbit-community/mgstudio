// Copyright 2026 International Digital Economy Academy
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
fn animation_test_bytes_hex(bytes : Bytes) -> String {
  let parts : Array[String] = []
  for byte in bytes {
    parts.push(byte.to_hex())
  }
  parts.join("")
}

///|
test "animation target id: blake3 kernel matches official empty hash" {
  debug_inspect(
    animation_test_bytes_hex(blake3_root_hash(Bytes::new(0))),
    content="\"af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262\"",
  )
}
