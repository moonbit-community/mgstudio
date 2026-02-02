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
async fn read_file_text(path : String) -> String? {
  try {
    let f = @fs.open(path, mode=@fs.Mode::ReadOnly)
    defer f.close()
    Some(f.read_all().text())
  } catch {
    _ => None
  }
}

///|
async fn write_file_text(path : String, content : String) -> Unit {
  // 0o644
  let f = @fs.create(path, permission=420)
  defer f.close()
  f.write(content)
}
