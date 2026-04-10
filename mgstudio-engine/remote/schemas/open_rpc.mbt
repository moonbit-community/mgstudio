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
// Bevy source: `bevy/crates/bevy_remote/src/schemas/open_rpc.rs`.

///|
pub struct RemoteOpenRpcMethod {
  name : String
  summary : String?
}

///|
pub struct RemoteOpenRpcDocument {
  title : String
  version : String
  methods : Array[RemoteOpenRpcMethod]
}

///|
pub fn RemoteOpenRpcDocument::default() -> RemoteOpenRpcDocument {
  RemoteOpenRpcDocument::{
    title: "mgstudio-remote",
    version: "1.0",
    methods: [],
  }
}

///|
pub fn RemoteOpenRpcMethod::new(name : String) -> RemoteOpenRpcMethod {
  RemoteOpenRpcMethod::{ name, summary: None }
}

///|
pub fn RemoteOpenRpcMethod::with_summary(
  self : RemoteOpenRpcMethod,
  summary : String,
) -> RemoteOpenRpcMethod {
  RemoteOpenRpcMethod::{ ..self, summary: Some(summary) }
}

///|
pub fn RemoteOpenRpcDocument::add_method(
  self : RemoteOpenRpcDocument,
  rpc_method : RemoteOpenRpcMethod,
) -> RemoteOpenRpcDocument {
  let methods = self.methods
  methods.push(rpc_method)
  RemoteOpenRpcDocument::{ ..self, methods, }
}
