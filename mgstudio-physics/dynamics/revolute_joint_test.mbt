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
/// Ported from rapier/src/dynamics/joint/revolute_joint.rs (test_revolute_joint_angle).
test "revolute joint angle" {
  let revolute = RevoluteJointBuilder::new().build()
  let rot1 = @core.rotation_from_angle(1.0F)
  let deltas = [
    -@core.pi(),
    -@core.pi() / 2.0F,
    0.0F,
    @core.pi() / 2.0F,
    @core.pi(),
  ]
  for delta in deltas {
    let rot2 = @core.rotation_from_angle(1.0F + delta)
    let angle = revolute.angle(rot1, rot2)
    let diff = @core.abs(angle - delta)
    let pi_value = @core.pi()
    let near_pi = @core.abs(@core.abs(delta) - pi_value) < 1.0e-3F
    let diff_alt = @core.abs(angle + delta)
    if near_pi {
      inspect(diff < 1.0e-2F || diff_alt < 1.0e-2F, content="true")
    } else {
      inspect(diff < 1.0e-2F, content="true")
    }
  }
}
