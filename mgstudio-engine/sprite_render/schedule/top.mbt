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
// Bevy source: `bevy/crates/bevy_sprite_render/src/lib.rs` render schedule wiring.

///|
pub let render2d_set_extract : @app.SystemSet = @app.system_set(
  "mgstudio.render2d.extract",
)

///|
pub let render2d_set_extract_materials : @app.SystemSet = @app.system_set(
  "mgstudio.render2d.extract_materials",
)

///|
pub let render2d_set_prepare_materials : @app.SystemSet = @app.system_set(
  "mgstudio.render2d.prepare_materials",
)

///|
pub let render2d_set_prepare : @app.SystemSet = @app.system_set(
  "mgstudio.render2d.prepare",
)

///|
pub let render2d_set_queue : @app.SystemSet = @app.system_set(
  "mgstudio.render2d.queue",
)

///|
pub let render2d_set_transparent_2d : @app.SystemSet = render2d_set_queue

///|
pub let render2d_set_render : @app.SystemSet = @app.system_set(
  "mgstudio.render2d.render",
)
