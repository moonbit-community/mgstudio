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
// Bevy source: `bevy/crates/bevy_sprite_render/src/text2d/mod.rs`.
pub let text_set_render_extract : @app.SystemSet = @sprite_render.render2d_set_extract

///|
pub let text_set_render_prepare : @app.SystemSet = @sprite_render.render2d_set_prepare

///|
pub let text_set_render_queue : @app.SystemSet = @sprite_render.render2d_set_queue

///|
pub let text_set_render_transparent_2d : @app.SystemSet = @sprite_render.render2d_set_transparent_2d

///|
pub fn text_runtime_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
}

///|
pub fn text_render_system(_world : @ecs.World) -> Unit {
  ()
}

///|
pub fn text_render_transparent_2d_queue_system(_world : @ecs.World) -> Unit {
  ()
}
