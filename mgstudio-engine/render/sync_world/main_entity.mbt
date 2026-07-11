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
// Bevy source: `bevy/crates/bevy_render/src/sync_world.rs::MainEntity`.
pub struct MainEntity {
  entity : @core.Entity
} derive(Eq, Hash, Debug)

///|
pub fn MainEntity::new(entity : @core.Entity) -> MainEntity {
  MainEntity::{ entity, }
}

///|
pub fn MainEntity::id(self : MainEntity) -> @core.Entity {
  self.entity
}

///|
pub let ecs_key_main_entity : @ecs.ComponentKey[MainEntity] = @ecs.register_component(
  debug_name="mgstudio_render::MainEntity",
)

///|
pub impl @ecs.Component for MainEntity with fn component() {
  ecs_key_main_entity
}
