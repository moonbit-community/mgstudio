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
/// yazi: DEFLATE (RFC 1951) + zlib wrapper (RFC 1950).
///
/// This is a MoonBit port of `dfrg/yazi` (Apache-2.0 OR MIT).
pub(all) enum Format {
  Raw
  Zlib
}

///|
suberror YaziError {
  Underflow
  InvalidBitstream
  Overflow
  Finished
}

///|
pub struct Adler32 {
  value : UInt
}

///|
pub fn Adler32::new() -> Adler32 {
  Adler32::{ value: 1 }
}

///|
pub fn Adler32::update(self : Adler32, buf : Bytes) -> Unit {
  // TODO: full port. For now keep API shape; used by zlib verification.
  let _ = buf
  let _ = self

}

///|
pub fn Adler32::finish(self : Adler32) -> UInt {
  self.value
}

///|
pub fn YaziError::to_string(self : YaziError) -> String {
  match self {
    YaziError::Underflow => "Underflow"
    YaziError::InvalidBitstream => "InvalidBitstream"
    YaziError::Overflow => "Overflow"
    YaziError::Finished => "Finished"
  }
}
