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
/// Ported from rapier/src/dynamics/rigid_body_components.rs (test_interpolate_velocity).
test "interpolate velocity" {
  let multipliers = [-2.0F, -1.0F, 0.0F, 1.0F, 2.0F]
  let dt = 0.016F
  let local_com = @core.Vec2::new(0.25F, -0.5F)
  for mult in multipliers {
    let curr_pos = @core.Isometry2::new(
      @core.Vec2::new(mult, mult * 2.0F),
      @core.Rot2::from_angle(0.5F),
    )
    let next_pos = @core.Isometry2::new(
      @core.Vec2::new(mult + 1.0F, mult * 2.0F + 1.0F),
      @core.Rot2::from_angle(1.0F),
    )
    let rb_pos = RigidBodyPosition::new(curr_pos, next_pos)
    let vel = rb_pos.interpolate_velocity(1.0F / dt, local_com)
    let interp_pos = vel.integrate(dt, curr_pos, local_com)
    let dx = @core.abs(interp_pos.translation.x - next_pos.translation.x)
    let dy = @core.abs(interp_pos.translation.y - next_pos.translation.y)
    inspect(dx < 1.0e-3F, content="true")
    inspect(dy < 1.0e-3F, content="true")
  }
}
