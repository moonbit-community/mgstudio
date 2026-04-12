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
// Bevy source alignment: `bevy_pbr/src/prepass/mod.rs` + `prepass.wgsl` data-facing toggles.

pub struct PrepassBindings3d {
  depth : Bool
  normal : Bool
  motion_vector : Bool
  deferred : Bool
}

///|
pub fn PrepassBindings3d::default() -> PrepassBindings3d {
  PrepassBindings3d::{
    depth: false,
    normal: false,
    motion_vector: false,
    deferred: false,
  }
}

///|
pub fn PrepassBindings3d::with_depth(
  self : PrepassBindings3d,
  depth : Bool,
) -> PrepassBindings3d {
  PrepassBindings3d::{ ..self, depth, }
}

///|
pub fn PrepassBindings3d::with_normal(
  self : PrepassBindings3d,
  normal : Bool,
) -> PrepassBindings3d {
  PrepassBindings3d::{ ..self, normal, }
}

///|
pub fn PrepassBindings3d::with_motion_vector(
  self : PrepassBindings3d,
  motion_vector : Bool,
) -> PrepassBindings3d {
  PrepassBindings3d::{ ..self, motion_vector, }
}

///|
pub fn PrepassBindings3d::with_deferred(
  self : PrepassBindings3d,
  deferred : Bool,
) -> PrepassBindings3d {
  PrepassBindings3d::{ ..self, deferred, }
}

///|
pub fn PrepassBindings3d::any_enabled(self : PrepassBindings3d) -> Bool {
  self.depth || self.normal || self.motion_vector || self.deferred
}

///|
pub struct PrepassPluginState {
  enabled : Bool
  view_count : Int
}

///|
pub fn PrepassPluginState::default() -> PrepassPluginState {
  PrepassPluginState::{ enabled: true, view_count: 0 }
}
