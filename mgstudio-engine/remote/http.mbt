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
// Bevy source-shape anchor (`bevy_remote/src/http.rs`).

///|
pub(all) enum RemoteHttpMethod {
  Get
  Post
  Put
  Delete
} derive(Eq, Show)

///|
pub struct RemoteHttpRequest {
  http_method : RemoteHttpMethod
  path : String
  body : String?
}

///|
pub fn RemoteHttpRequest::new(
  http_method : RemoteHttpMethod,
  path : String,
  body? : String? = None,
) -> RemoteHttpRequest {
  RemoteHttpRequest::{ http_method, path, body }
}

///|
pub struct RemoteHttpResponse {
  status : Int
  body : String
}

///|
pub fn RemoteHttpResponse::ok(body : String) -> RemoteHttpResponse {
  RemoteHttpResponse::{ status: 200, body }
}

///|
pub fn RemoteHttpResponse::not_found() -> RemoteHttpResponse {
  RemoteHttpResponse::{ status: 404, body: "not found" }
}

///|
pub fn remote_http_default_bind_address() -> String {
  "127.0.0.1:0"
}
