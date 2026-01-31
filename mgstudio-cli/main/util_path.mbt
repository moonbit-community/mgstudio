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
fn is_absolute_path(path : String) -> Bool {
  @path.Path(path).is_absolute()
}

///|
fn path_basename(path : String) -> String {
  @path.Path(path).basename().to_string()
}

///|
fn path_join(dir : String, file : String) -> String {
  @path.Path(dir).join(file).to_string()
}

///|
fn path_dirname(path : String) -> String {
  @path.Path(path).dirname().to_string()
}
