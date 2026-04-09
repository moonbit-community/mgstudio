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
/// Core render pipeline-facing API boundary.
/// Aggregates the stable ECS-facing surfaces split across `core_3d`,
/// `prepass`, and `deferred`.

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/lib.rs`.
pub using @core_3d {type Hdr}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/lib.rs`.
pub using @core_3d {type Msaa}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/lib.rs`.
pub using @deferred {type DeferredPrepass}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/lib.rs`.
pub using @prepass {type DepthPrepass}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/lib.rs`.
pub using @prepass {type MotionVectorPrepass}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/lib.rs`.
pub using @prepass {type NormalPrepass}

///|
pub let ecs_key_deferred_prepass : @ecs.ComponentKey[DeferredPrepass] = @deferred.ecs_key_deferred_prepass

///|
pub let ecs_key_depth_prepass : @ecs.ComponentKey[DepthPrepass] = @prepass.ecs_key_depth_prepass

///|
pub let ecs_key_hdr : @ecs.ComponentKey[Hdr] = @core_3d.ecs_key_hdr

///|
pub let ecs_key_motion_vector_prepass : @ecs.ComponentKey[MotionVectorPrepass] = @prepass.ecs_key_motion_vector_prepass

///|
pub let ecs_key_msaa : @ecs.ComponentKey[Msaa] = @core_3d.ecs_key_msaa

///|
pub let ecs_key_normal_prepass : @ecs.ComponentKey[NormalPrepass] = @prepass.ecs_key_normal_prepass
