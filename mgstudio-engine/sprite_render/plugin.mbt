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
pub struct SpriteRenderPlugin {}

///|
pub fn SpriteRenderPlugin::default() -> SpriteRenderPlugin {
  SpriteRenderPlugin::{  }
}

///|
pub impl @app.Plugin for SpriteRenderPlugin with name(_self) {
  "mgstudio.sprite_render.SpriteRenderPlugin"
}

///|
pub impl @app.Plugin for SpriteRenderPlugin with build(_self, app) {
  sprite_render_plugin_ecs(app)
}
