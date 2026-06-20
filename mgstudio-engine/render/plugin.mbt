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
// Bevy source: `bevy/crates/bevy_render/src/lib.rs` (`RenderDebugFlags`).
pub struct RenderDebugFlags {
  allow_copies_from_indirect_parameters : Bool
}

///|
pub fn RenderDebugFlags::RenderDebugFlags() -> RenderDebugFlags {
  RenderDebugFlags::{ allow_copies_from_indirect_parameters: false }
}

///|
pub fn RenderDebugFlags::allow_copies_from_indirect_parameters(
  self : RenderDebugFlags,
) -> Bool {
  self.allow_copies_from_indirect_parameters
}

///|
pub fn RenderDebugFlags::with_allow_copies_from_indirect_parameters(
  _self : RenderDebugFlags,
  allow : Bool,
) -> RenderDebugFlags {
  RenderDebugFlags::{ allow_copies_from_indirect_parameters: allow }
}

///|
// Bevy source: `bevy/crates/bevy_render/src/lib.rs` (`RenderPlugin`).
pub struct RenderPlugin {
  render_creation : RenderCreation
  synchronous_pipeline_compilation : Bool
  debug_flags : RenderDebugFlags
}

///|
pub fn RenderPlugin::RenderPlugin() -> RenderPlugin {
  RenderPlugin::{
    render_creation: RenderCreation::default(),
    synchronous_pipeline_compilation: false,
    debug_flags: RenderDebugFlags::RenderDebugFlags(),
  }
}

///|
pub fn RenderPlugin::render_creation(self : RenderPlugin) -> RenderCreation {
  self.render_creation
}

///|
pub fn RenderPlugin::synchronous_pipeline_compilation(
  self : RenderPlugin,
) -> Bool {
  self.synchronous_pipeline_compilation
}

///|
pub fn RenderPlugin::debug_flags(self : RenderPlugin) -> RenderDebugFlags {
  self.debug_flags
}

///|
pub fn RenderPlugin::with_render_creation(
  self : RenderPlugin,
  render_creation : RenderCreation,
) -> RenderPlugin {
  RenderPlugin::{ ..self, render_creation, }
}

///|
pub fn RenderPlugin::with_synchronous_pipeline_compilation(
  self : RenderPlugin,
  synchronous_pipeline_compilation : Bool,
) -> RenderPlugin {
  RenderPlugin::{ ..self, synchronous_pipeline_compilation, }
}

///|
pub fn RenderPlugin::with_debug_flags(
  self : RenderPlugin,
  debug_flags : RenderDebugFlags,
) -> RenderPlugin {
  RenderPlugin::{ ..self, debug_flags, }
}

///|
pub impl @app.Plugin for RenderPlugin with fn name(_self) {
  "mgstudio.render.RenderPlugin"
}

///|
pub impl @app.Plugin for RenderPlugin with fn build(self, app) {
  render_plugin_install_with(app, self)
}
