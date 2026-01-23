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
/// Rolling Adler-32 checksum.
///
/// Ported from `yazi/src/lib.rs` (Apache-2.0 OR MIT).
pub struct Adler32 {
  mut state : UInt
}

///|
pub fn Adler32::new() -> Adler32 {
  Adler32::{ state: 1 }
}

///|
pub fn Adler32::from_buf(buf : Bytes) -> Adler32 {
  let a = Adler32::new()
  a.update(buf)
  a
}

///|
pub fn Adler32::update(self : Adler32, buf : Bytes) -> Unit {
  let mut s1 : UInt = self.state & 0xFFFF
  let mut s2 : UInt = (self.state >> 16) & 0xFFFF
  let n = buf.length()
  // RFC1950 suggests modulo each 5552 bytes; upstream uses 5550.
  let mut i = 0
  while i < n {
    let chunk_end = if i + 5550 <= n { i + 5550 } else { n }
    while i < chunk_end {
      let b = buf[i].to_int().reinterpret_as_uint()
      s1 = s1 + b
      s2 = s2 + s1
      i = i + 1
    }
    s1 = s1 % 65521
    s2 = s2 % 65521
  }
  self.state = (s2 << 16) | s1
}

///|
pub fn Adler32::finish(self : Adler32) -> UInt {
  self.state
}
