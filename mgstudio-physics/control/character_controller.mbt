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
pub fn CharacterLength::relative(value : @core.Real) -> CharacterLength {
  CharacterLength::Relative(value)
}

///|
pub struct CharacterCollision {}

///|
pub struct EffectiveMovement {
  translation : @core.Vec2
  grounded : Bool
}

///|
pub fn EffectiveMovement::translation(self : EffectiveMovement) -> @core.Vec2 {
  self.translation
}

///|
pub fn EffectiveMovement::is_grounded(self : EffectiveMovement) -> Bool {
  self.grounded
}

///|
pub struct KinematicCharacterController {
  max_slope_climb_angle : @core.Real
  snap_to_ground : CharacterLength?
}

///|
pub fn KinematicCharacterController::new() -> KinematicCharacterController {
  { max_slope_climb_angle: 0.78F, snap_to_ground: None }
}

///|
pub fn KinematicCharacterController::with_max_slope_climb_angle(
  self : KinematicCharacterController,
  angle : @core.Real,
) -> KinematicCharacterController {
  { max_slope_climb_angle: angle, snap_to_ground: self.snap_to_ground }
}

///|
pub fn KinematicCharacterController::with_snap_to_ground(
  self : KinematicCharacterController,
  snap : CharacterLength?,
) -> KinematicCharacterController {
  { max_slope_climb_angle: self.max_slope_climb_angle, snap_to_ground: snap }
}

///|
pub fn KinematicCharacterController::move_shape(
  self : KinematicCharacterController,
  dt : @core.Real,
  query : @query.QueryPipeline,
  shape : @collision.Shape,
  position : @core.Isometry2,
  translation : @core.Vec2,
  handle_collision : (CharacterCollision) -> Unit,
) -> EffectiveMovement {
  self.max_slope_climb_angle |> ignore
  dt |> ignore
  query |> ignore
  shape |> ignore
  position |> ignore
  handle_collision(CharacterCollision::{  })
  let grounded = translation.y <= 0.0F || self.snap_to_ground is Some(_)
  { translation, grounded }
}
