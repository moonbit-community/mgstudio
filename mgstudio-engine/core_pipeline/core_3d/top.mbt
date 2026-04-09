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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/core_3d/mod.rs`.
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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/core_3d/mod.rs`.
pub struct Hdr {} derive(ToJson, FromJson)

///|
pub fn Hdr::default() -> Hdr {
  Hdr::{  }
}

///|
pub let ecs_key_hdr : @ecs.ComponentKey[Hdr] = @ecs.register_component(
  debug_name="render3d.hdr",
)

///|
pub let ecs_key_msaa : @ecs.ComponentKey[Msaa] = @ecs.register_component(
  debug_name="render3d.msaa",
)

///|
pub impl @ecs.Component for Hdr with component() {
  ecs_key_hdr
}

///|
pub impl @ecs.Component for Msaa with component() {
  ecs_key_msaa
}
