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
pub struct CollisionPipeline {}

///|
pub fn CollisionPipeline::new() -> CollisionPipeline {
  CollisionPipeline::{  }
}

///|
pub fn CollisionPipeline::step(
  self : CollisionPipeline,
  prediction_distance : @core.Real,
  islands : @dynamics.IslandManager,
  broad_phase : @collision.BroadPhaseBvh,
  narrow_phase : @collision.NarrowPhase,
  bodies : @dynamics.RigidBodySet,
  colliders : @collision.ColliderSet,
  physics_hooks : Unit,
  event_handler : Unit,
) -> Unit {
  self |> ignore
  prediction_distance |> ignore
  islands |> ignore
  broad_phase |> ignore
  physics_hooks |> ignore
  event_handler |> ignore
  narrow_phase.update(bodies, colliders)
}
