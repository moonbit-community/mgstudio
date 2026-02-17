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
fn parse_module_name(src : String) -> String? {
  // Minimal JSON string scan for: "name": "<module-name>"
  let s = src.view()
  let key = "\"name\"".view()
  let mut i = 0
  while i + key.length() <= s.length() {
    if (try! s[i:i + key.length()]) == key {
      // Seek ':' then the first '"' and the closing '"'.
      let mut j = i + key.length()
      while j < s.length() && s.code_unit_at(j).to_int() != ':'.to_int() {
        j = j + 1
      }
      if j >= s.length() {
        return None
      }
      while j < s.length() && s.code_unit_at(j).to_int() != '"'.to_int() {
        j = j + 1
      }
      if j >= s.length() {
        return None
      }
      let start = j + 1
      let mut end = start
      while end < s.length() && s.code_unit_at(end).to_int() != '"'.to_int() {
        end = end + 1
      }
      if end >= s.length() {
        return None
      }
      return Some(try! s[start:end].to_string())
    }
    i = i + 1
  }
  None
}
