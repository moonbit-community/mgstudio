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
fn projection_approx_eq(a : Float, b : Float) -> Bool {
  let delta = a - b
  if delta < 0.0F {
    -delta < 0.0001F
  } else {
    delta < 0.0001F
  }
}

///|
test "render3d: perspective projection getters expose configured values" {
  let projection = PerspectiveProjection3d::default()
    .with_fov(1.2F)
    .with_near(0.3F)
    .with_far(250.0F)
    .with_aspect_ratio(1.6F)
  inspect(projection_approx_eq(projection.fov(), 1.2F), content="true")
  inspect(projection_approx_eq(projection.near(), 0.3F), content="true")
  inspect(projection_approx_eq(projection.far(), 250.0F), content="true")
  inspect(projection_approx_eq(projection.aspect_ratio(), 1.6F), content="true")
}

///|
test "render3d: projection preserves configured orthographic values" {
  let orthographic = OrthographicProjection3d::default()
    .with_scale(2.5F)
    .with_scaling_mode(FixedVertical(7.5F))
  let projection = Projection::Orthographic(orthographic)
  let ok = match projection {
    Projection::Orthographic(value) => {
      let scaling_mode_ok = match value.scaling_mode() {
        FixedVertical(height) => projection_approx_eq(height, 7.5F)
        _ => false
      }
      projection_approx_eq(value.scale(), 2.5F) && scaling_mode_ok
    }
    Projection::Perspective(_) => false
  }
  inspect(ok, content="true")
}

///|
test "render3d: standard material stores full affine uv transform" {
  let uv_transform = @transform.Affine2::from_translation(
    @math.Vec2::new(0.25F, -0.5F),
  ).mul(@transform.Affine2::from_scale(@math.Vec2::new(2.0F, 3.0F)))
  let material = StandardMaterial::default().with_uv_transform(uv_transform)
  let point = material.uv_transform.transform_point2(
    @math.Vec2::new(0.5F, 0.25F),
  )
  inspect(projection_approx_eq(point.x, 1.25F), content="true")
  inspect(projection_approx_eq(point.y, 0.25F), content="true")
}
