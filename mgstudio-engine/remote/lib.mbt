// Copyright 2026 International Digital Economy Academy
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
/// Remote-control boundary aligned with Bevy's `bevy_remote` crate.
/// Transport and protocol backends are not implemented yet in mgstudio.

///|
pub struct RemotePlugin {
  enabled : Bool
  bind_address : String
}

///|
pub fn RemotePlugin::default() -> RemotePlugin {
  RemotePlugin::{ enabled: true, bind_address: "127.0.0.1:0" }
}

///|
pub fn RemotePlugin::with_enabled(
  self : RemotePlugin,
  enabled : Bool,
) -> RemotePlugin {
  RemotePlugin::{ ..self, enabled, }
}

///|
pub fn RemotePlugin::with_bind_address(
  self : RemotePlugin,
  bind_address : String,
) -> RemotePlugin {
  RemotePlugin::{ ..self, bind_address, }
}

///|
pub fn RemotePlugin::enabled(self : RemotePlugin) -> Bool {
  self.enabled
}

///|
pub fn RemotePlugin::bind_address(self : RemotePlugin) -> String {
  self.bind_address
}

///|
pub fn remote_plugin(_plugin : RemotePlugin) -> @app.Plugin[@ecs.World] {
  fn(app : @app.App[@ecs.World]) { app }
}
