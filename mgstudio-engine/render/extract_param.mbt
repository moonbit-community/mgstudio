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
// Bevy source: `bevy/crates/bevy_render/src/extract_param.rs`.

///|
pub struct Extract[T] {
  item : T
}

///|
pub fn[T] Extract::new(item : T) -> Extract[T] {
  Extract::{ item, }
}

///|
pub fn[T] Extract::item(self : Extract[T]) -> T {
  self.item
}

///|
pub fn[T, U] Extract::map(self : Extract[T], f : (T) -> U) -> Extract[U] {
  Extract::{ item: f(self.item) }
}

///|
pub fn[T] extract_param_from_source_world(
  world : @ecs.World,
  read : (@ecs.World) -> T,
) -> Extract[T] {
  Extract::{ item: read(render_source_world(world)) }
}

///|
pub fn extract_param_source_world(world : @ecs.World) -> @ecs.World {
  render_source_world(world)
}

///|
pub fn extract_param_render_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  render_plugin(app)
}
