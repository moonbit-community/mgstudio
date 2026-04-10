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
// Bevy source: `bevy/crates/bevy_anti_alias/src/fxaa/node.rs`.
// Bridge node-level FXAA activation helper.

///|
pub fn fxaa_node_enabled(world : @ecs.World, entity : @core.Entity) -> Bool {
  match (try! world.entity(entity).get() : Fxaa?) {
    Some(_) => true
    None => false
  }
}
