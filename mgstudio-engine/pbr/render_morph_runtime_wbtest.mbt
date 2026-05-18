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
fn morph_runtime_wbtest_approx_eq(lhs : Float, rhs : Float) -> Bool {
  let delta = lhs - rhs
  if delta < 0.0F {
    -delta < 0.0001F
  } else {
    delta < 0.0001F
  }
}

///|
test "render3d morph runtime: target texture components mirror bevy position normal tangent layout" {
  let geometry = @mesh.Mesh3dGeometry::new_with_positions(
    [@math.Vec3::new(0.0F, 0.0F, 0.0F), @math.Vec3::new(1.0F, 0.0F, 0.0F)],
    None,
  ).with_morph_targets(
    Some([
      [@math.Vec3::new(0.1F, 0.2F, 0.3F), @math.Vec3::new(0.4F, 0.5F, 0.6F)],
    ]),
    morph_target_normals=Some([
      [@math.Vec3::new(0.7F, 0.8F, 0.9F), @math.Vec3::new(1.0F, 1.1F, 1.2F)],
    ]),
    morph_target_tangents=Some([
      [@math.Vec3::new(1.3F, 1.4F, 1.5F), @math.Vec3::new(1.6F, 1.7F, 1.8F)],
    ]),
  )
  guard render3d_morph_target_texture_components(geometry)
    is Some((width, height, depth, components)) else {
    fail("expected morph target texture")
  }
  inspect(width, content="1")
  inspect(height, content="18")
  inspect(depth, content="1")
  inspect(components.length(), content="18")
  debug_inspect(
    morph_runtime_wbtest_approx_eq(components[0], 0.1F),
    content="true",
  )
  debug_inspect(
    morph_runtime_wbtest_approx_eq(components[3], 0.7F),
    content="true",
  )
  debug_inspect(
    morph_runtime_wbtest_approx_eq(components[6], 1.3F),
    content="true",
  )
  debug_inspect(
    morph_runtime_wbtest_approx_eq(components[9], 0.4F),
    content="true",
  )
}
