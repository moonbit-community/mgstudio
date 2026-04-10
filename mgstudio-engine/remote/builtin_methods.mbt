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
// Bevy source: `bevy/crates/bevy_remote/src/builtin_methods.rs`.

///|
pub(all) enum RemoteBuiltinMethod {
  Inspect
  List
  Query
  Subscribe
} derive(Eq, Debug)

///|
pub fn remote_builtin_method_name(
  builtin_method : RemoteBuiltinMethod,
) -> String {
  match builtin_method {
    Inspect => "inspect"
    List => "list"
    Query => "query"
    Subscribe => "subscribe"
  }
}

///|
pub fn remote_builtin_methods() -> Array[RemoteBuiltinMethod] {
  [Inspect, List, Query, Subscribe]
}

///|
pub fn remote_builtin_method_parse(name : String) -> RemoteBuiltinMethod? {
  match name {
    "inspect" => Some(Inspect)
    "list" => Some(List)
    "query" => Some(Query)
    "subscribe" => Some(Subscribe)
    _ => None
  }
}
