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
// Bevy source: `bevy/crates/bevy_pbr/src/prepass/prepass_bindings.rs`.

///|
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
pub fn render3d_prepass_bindings_for_entity(
  world : @ecs.World,
  entity : @core.Entity,
) -> PrepassBindings3d {
  let entity_ref = try! world.entity(entity)
  let has_depth : DepthPrepass? = try! entity_ref.get()
  let has_normal : NormalPrepass? = try! entity_ref.get()
  let has_motion_vector : MotionVectorPrepass? = try! entity_ref.get()
  let has_deferred : DeferredPrepass? = try! entity_ref.get()
  PrepassBindings3d::{
    depth: has_depth is Some(_),
    normal: has_normal is Some(_),
    motion_vector: has_motion_vector is Some(_),
    deferred: has_deferred is Some(_),
  }
}

///|
pub fn render3d_prepass_any_enabled(bindings : PrepassBindings3d) -> Bool {
  bindings.depth ||
  bindings.normal ||
  bindings.motion_vector ||
  bindings.deferred
}
