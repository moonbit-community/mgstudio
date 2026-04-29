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
// Bevy source: `bevy/crates/bevy_asset/src/processor/tests.rs`.
// Test-oriented helpers for processor matching.
fn asset_processor_normalize_extension(extension : String) -> String {
  if extension.length() > 0 && extension.code_unit_at(0) == 46 {
    extension[1:extension.length()].to_owned()
  } else {
    extension
  }
}

///|
pub fn[T] asset_processor_supports_extension(
  processor : LoadTransformAndSave[T],
  extension : String,
) -> Bool {
  let normalized = asset_processor_normalize_extension(extension)
  for supported in processor.extensions {
    if asset_processor_normalize_extension(supported) == normalized {
      return true
    }
  }
  false
}
