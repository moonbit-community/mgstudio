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
// Bevy source: `bevy/crates/bevy_state/src/app.rs`.

///|
pub type StateAppPlugin = StatesPlugin

///|
pub fn state_app_plugin(plugin : StateAppPlugin) -> @app.Plugin[@ecs.World] {
  states_plugin(plugin)
}

///|
pub fn[S : @app.States] state_app_insert(
  app : @app.App[@ecs.World],
  state : S,
) -> @app.App[@ecs.World] {
  insert_state_app(app, state)
}
