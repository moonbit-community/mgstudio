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
pub let text_set_render_extract : @app.SystemSet = @text.text_set_render_extract

///|
pub let text_set_render_prepare : @app.SystemSet = @text.text_set_render_prepare

///|
pub let text_set_render_queue : @app.SystemSet = @text.text_set_render_queue

///|
pub let text_set_render_transparent_2d : @app.SystemSet = @text.text_set_render_transparent_2d

///|
pub fn text_runtime_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @text.text_runtime_plugin(app)
}

///|
pub fn text_render_system(world : @ecs.World) -> Unit {
  @text.text_render_system(world)
}

///|
pub fn text_render_transparent_2d_queue_system(world : @ecs.World) -> Unit {
  @text.text_render_transparent_2d_queue_system(world)
}
