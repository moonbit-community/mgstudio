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
/// Owns prepass / hdr / msaa ECS surfaces aligned with `bevy_core_pipeline`.

///|
pub(all) enum Msaa {
  Off
  Sample2
  Sample4
  Sample8
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn Msaa::default() -> Msaa {
  Msaa::Sample4
}

///|
pub fn Msaa::samples(self : Msaa) -> Int {
  match self {
    Off => 1
    Sample2 => 2
    Sample4 => 4
    Sample8 => 8
  }
}

///|
pub fn Msaa::from_samples(samples : Int) -> Msaa {
  if samples <= 1 {
    Msaa::Off
  } else if samples <= 2 {
    Msaa::Sample2
  } else if samples <= 4 {
    Msaa::Sample4
  } else {
    Msaa::Sample8
  }
}

///|
pub struct DepthPrepass {} derive(ToJson, FromJson)

///|
pub fn DepthPrepass::default() -> DepthPrepass {
  DepthPrepass::{  }
}

///|
pub struct NormalPrepass {} derive(ToJson, FromJson)

///|
pub fn NormalPrepass::default() -> NormalPrepass {
  NormalPrepass::{  }
}

///|
pub struct MotionVectorPrepass {} derive(ToJson, FromJson)

///|
pub fn MotionVectorPrepass::default() -> MotionVectorPrepass {
  MotionVectorPrepass::{  }
}

///|
pub struct DeferredPrepass {} derive(ToJson, FromJson)

///|
pub fn DeferredPrepass::default() -> DeferredPrepass {
  DeferredPrepass::{  }
}

///|
pub struct Hdr {} derive(ToJson, FromJson)

///|
pub fn Hdr::default() -> Hdr {
  Hdr::{  }
}

///|
pub let ecs_key_depth_prepass : @ecs.ComponentKey[DepthPrepass] = @ecs.register_component(
  debug_name="render3d.depth_prepass",
)

///|
pub let ecs_key_normal_prepass : @ecs.ComponentKey[NormalPrepass] = @ecs.register_component(
  debug_name="render3d.normal_prepass",
)

///|
pub let ecs_key_motion_vector_prepass : @ecs.ComponentKey[MotionVectorPrepass] = @ecs.register_component(
  debug_name="render3d.motion_vector_prepass",
)

///|
pub let ecs_key_deferred_prepass : @ecs.ComponentKey[DeferredPrepass] = @ecs.register_component(
  debug_name="render3d.deferred_prepass",
)

///|
pub let ecs_key_hdr : @ecs.ComponentKey[Hdr] = @ecs.register_component(
  debug_name="render3d.hdr",
)

///|
pub let ecs_key_msaa : @ecs.ComponentKey[Msaa] = @ecs.register_component(
  debug_name="render3d.msaa",
)

///|
pub impl @ecs.Component for DepthPrepass with component() {
  ecs_key_depth_prepass
}

///|
pub impl @ecs.Component for NormalPrepass with component() {
  ecs_key_normal_prepass
}

///|
pub impl @ecs.Component for MotionVectorPrepass with component() {
  ecs_key_motion_vector_prepass
}

///|
pub impl @ecs.Component for DeferredPrepass with component() {
  ecs_key_deferred_prepass
}

///|
pub impl @ecs.Component for Hdr with component() {
  ecs_key_hdr
}

///|
pub impl @ecs.Component for Msaa with component() {
  ecs_key_msaa
}
