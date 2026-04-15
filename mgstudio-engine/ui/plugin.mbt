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
pub struct UiPlugin {}

///|
pub fn UiPlugin::default() -> UiPlugin {
  UiPlugin::{  }
}

///|
pub impl @app.Plugin for UiPlugin with name(_self) {
  "mgstudio.ui.UiPlugin"
}

///|
pub impl @app.Plugin for UiPlugin with build(_self, app) {
  ui_plugin(app)
}
