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
/// Core render pipeline-facing API boundary.
/// Runtime implementation currently lives in `Milky2018/mgstudio/pbr`.

///|
pub type DepthPrepass = @pbr.DepthPrepass

///|
pub type NormalPrepass = @pbr.NormalPrepass

///|
pub type MotionVectorPrepass = @pbr.MotionVectorPrepass

///|
pub type DeferredPrepass = @pbr.DeferredPrepass

///|
pub type Hdr = @pbr.Hdr

///|
pub type Msaa = @pbr.Msaa

///|
pub let ecs_key_depth_prepass : @ecs.ComponentKey[DepthPrepass] = @pbr.ecs_key_depth_prepass

///|
pub let ecs_key_normal_prepass : @ecs.ComponentKey[NormalPrepass] = @pbr.ecs_key_normal_prepass

///|
pub let ecs_key_motion_vector_prepass : @ecs.ComponentKey[MotionVectorPrepass] = @pbr.ecs_key_motion_vector_prepass

///|
pub let ecs_key_deferred_prepass : @ecs.ComponentKey[DeferredPrepass] = @pbr.ecs_key_deferred_prepass

///|
pub let ecs_key_hdr : @ecs.ComponentKey[Hdr] = @pbr.ecs_key_hdr

///|
pub let ecs_key_msaa : @ecs.ComponentKey[Msaa] = @pbr.ecs_key_msaa
