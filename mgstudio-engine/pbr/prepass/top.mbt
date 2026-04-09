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
// Bevy source: `bevy/crates/bevy_pbr/src/prepass/mod.rs`.

///|
pub type DepthPrepass = @core_pipeline.DepthPrepass

///|
pub type NormalPrepass = @core_pipeline.NormalPrepass

///|
pub type MotionVectorPrepass = @core_pipeline.MotionVectorPrepass

///|
pub type DeferredPrepass = @core_pipeline.DeferredPrepass

///|
pub let ecs_key_depth_prepass : @ecs.ComponentKey[DepthPrepass] = @core_pipeline.ecs_key_depth_prepass

///|
pub let ecs_key_normal_prepass : @ecs.ComponentKey[NormalPrepass] = @core_pipeline.ecs_key_normal_prepass

///|
pub let ecs_key_motion_vector_prepass : @ecs.ComponentKey[MotionVectorPrepass] = @core_pipeline.ecs_key_motion_vector_prepass

///|
pub let ecs_key_deferred_prepass : @ecs.ComponentKey[DeferredPrepass] = @core_pipeline.ecs_key_deferred_prepass
