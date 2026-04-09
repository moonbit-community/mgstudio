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
// Bevy source-shape anchor (`bevy_camera/src/projection.rs`).

///|
pub type PerspectiveProjection = @pbr.PerspectiveProjection3d

///|
pub type OrthographicProjection2d = @sprite.OrthographicProjection

///|
pub fn orthographic_projection_2d_default() -> OrthographicProjection2d {
  @sprite.OrthographicProjection::default_2d()
}

///|
pub fn orthographic_projection_2d_with_scale(
  scale : Float,
) -> OrthographicProjection2d {
  @sprite.OrthographicProjection::new(scale)
}

///|
pub fn perspective_projection_3d_default() -> PerspectiveProjection {
  @pbr.PerspectiveProjection3d::default()
}
