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
pub struct PickingPlugin {}

///|
pub fn PickingPlugin::default() -> PickingPlugin {
  PickingPlugin::{  }
}

///|
pub struct PointerInputPlugin {}

///|
pub fn PointerInputPlugin::default() -> PointerInputPlugin {
  PointerInputPlugin::{  }
}

///|
pub struct InteractionPlugin {}

///|
pub fn InteractionPlugin::default() -> InteractionPlugin {
  InteractionPlugin::{  }
}

///|
pub struct DefaultPickingPlugins {}

///|
pub fn DefaultPickingPlugins::default() -> DefaultPickingPlugins {
  DefaultPickingPlugins::{  }
}

///|
pub impl @app.Plugin for PickingPlugin with name(_self) {
  "mgstudio.picking.PickingPlugin"
}

///|
pub impl @app.Plugin for PickingPlugin with build(_self, app) {
  picking_plugin(app)
}

///|
pub impl @app.Plugin for PointerInputPlugin with name(_self) {
  "mgstudio.picking.PointerInputPlugin"
}

///|
pub impl @app.Plugin for PointerInputPlugin with build(_self, app) {
  picking_input_plugin(app)
}

///|
pub impl @app.Plugin for InteractionPlugin with name(_self) {
  "mgstudio.picking.InteractionPlugin"
}

///|
pub impl @app.Plugin for InteractionPlugin with build(_self, app) {
  picking_interaction_plugin(app)
}

///|
pub impl @app.PluginGroup for DefaultPickingPlugins with name(_self) {
  "mgstudio.picking.DefaultPickingPlugins"
}

///|
pub impl @app.PluginGroup for DefaultPickingPlugins with build(_self) {
  @app.PluginGroupBuilder::start_named("mgstudio.picking.DefaultPickingPlugins")
  .add(PointerInputPlugin::default())
  .add(PickingPlugin::default())
  .add(InteractionPlugin::default())
}
