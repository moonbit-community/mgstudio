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
/// Errors for yazi (deflate/zlib).
///
/// Ported from `yazi/src/lib.rs` (Apache-2.0 OR MIT).
///
/// Note: upstream uses the type name `Error`, but MoonBit reserves `Error`.
/// We use `YaziError` instead.
suberror YaziError {
  Underflow
  InvalidBitstream
  Overflow
  Finished
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
