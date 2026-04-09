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
pub struct RemotePlugin {}

///|
pub fn RemotePlugin::default() -> RemotePlugin {
  RemotePlugin::{  }
}

///|
pub fn remote_plugin(_plugin : RemotePlugin) -> @app.Plugin[@ecs.World] {
  fn(app : @app.App[@ecs.World]) { app }
}
