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
fn strip_dir_prefix(spec : String) -> String {
  if spec.has_prefix("dir:") {
    (try! spec[4:spec.length()]).to_string()
  } else {
    spec
  }
}

///|
fn ensure_trailing_slash(text : String) -> String {
  if text == "" {
    ""
  } else if text is [.., '/'] {
    text
  } else {
    text + "/"
  }
}
