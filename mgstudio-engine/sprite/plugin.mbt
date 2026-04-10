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
// Bridge surface is provided by `lib.mbt` in this package.
pub struct SpritePlugin {}

///|
pub fn sprite_plugin_id() -> String {
  SPRITE_PLUGIN_ID
}

///|
pub fn sprite_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : SpritePlugin,
) -> @app.App[@ecs.World] {
  sprite_plugin(app)
}

///|
pub fn SpritePlugin::default() -> SpritePlugin {
  SpritePlugin::{  }
}
