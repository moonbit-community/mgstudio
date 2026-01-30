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
test "source_spec: normalize_logical_path ok" {
  let out = normalize_logical_path("textures/branding/logo.png")
  inspect(out, content="textures/branding/logo.png")
}

///|
test "source_spec: normalize_logical_path rejects traversal and absolute" {
  let traversal = normalize_logical_path("../x.txt") catch { _ => "<err>" }
  inspect(traversal, content="<err>")
  let absolute = normalize_logical_path("/x.txt") catch { _ => "<err>" }
  inspect(absolute, content="<err>")
}

///|
test "source_spec: join_url uses base and rejects traversal" {
  let ok = join_url("./assets/", "textures/a.png")
  inspect(ok, content="./assets/textures/a.png")
  let err = join_url("./assets/", "../x") catch { _ => "<err>" }
  inspect(err, content="<err>")
}

///|
test "source_spec: parse_url_source strips dir: and ensures trailing slash" {
  let s1 = parse_url_source(Some("dir:./assets"), "./assets/")
  inspect(s1.base, content="./assets/")
  let s2 = parse_url_source(Some("./assets"), "./assets/")
  inspect(s2.base, content="./assets/")
}
