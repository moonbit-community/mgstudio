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
test "sprite 3d gizmo shapes emit expected line segments" {
  gizmos_reset()
  let gizmos : Gizmos[DefaultGizmoConfigGroup] = {
    config: GizmoConfig::default(),
    config_group: DefaultGizmoConfigGroup::{  },
  }

  gizmos.grid_3d(
    @math.Isometry3d::identity(),
    @math.IVec2::new(1, 1),
    @math.Vec2::new(1.0F, 1.0F),
    Color::white(),
  )
  inspect(gizmo_state.val.lines_3d.length(), content="4")

  gizmos.cross_3d(@math.Vec3::zero(), 1.0F, Color::white())
  inspect(gizmo_state.val.lines_3d.length(), content="7")

  gizmos.rect_3d(
    @math.Isometry3d::identity(),
    @math.Vec2::new(2.0F, 2.0F),
    Color::white(),
  )
  inspect(gizmo_state.val.lines_3d.length(), content="11")

  gizmos.arc_3d(@math.Isometry3d::identity(), HALF_PI, 1.0F, Color::white())
  inspect(gizmo_state.val.lines_3d.length(), content="19")

  gizmos.circle_3d(@math.Isometry3d::identity(), 1.0F, Color::white())
  inspect(gizmo_state.val.lines_3d.length(), content="51")

  gizmos.sphere_3d(@math.Isometry3d::identity(), 1.0F, Color::white())
  inspect(gizmo_state.val.lines_3d.length(), content="147")

  gizmos.cuboid_3d(
    @transform.Transform::identity(),
    @math.Vec3::new(2.0F, 2.0F, 2.0F),
    Color::white(),
  )
  inspect(gizmo_state.val.lines_3d.length(), content="159")

  gizmos.curve_gradient_3d([
    (@math.Vec3::new(0.0F, 0.0F, 0.0F), Color::white()),
    (@math.Vec3::new(1.0F, 0.0F, 0.0F), Color::black()),
    (@math.Vec3::new(1.0F, 1.0F, 0.0F), Color::white()),
  ])
  inspect(gizmo_state.val.lines_3d.length(), content="161")

  gizmos_reset()
}
