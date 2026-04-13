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
pub type HalfSpace = @pbr_render.HalfSpace

///|
pub const VIEW_FRUSTUM_NEAR_PLANE_IDX : Int = @pbr_render.VIEW_FRUSTUM_NEAR_PLANE_IDX

///|
pub const VIEW_FRUSTUM_FAR_PLANE_IDX : Int = @pbr_render.VIEW_FRUSTUM_FAR_PLANE_IDX

///|
pub type ViewFrustum = @pbr_render.ViewFrustum

///|
pub type Frustum = @pbr_render.Frustum

///|
pub const VIEW_FRUSTUM_PLANE_COUNT : Int = 6

///|
pub fn render3d_frustum_plane_count() -> Int {
  VIEW_FRUSTUM_PLANE_COUNT
}

///|
pub fn render3d_frustum_plane_index_clamp(index : Int) -> Int {
  if index < 0 {
    0
  } else if index >= VIEW_FRUSTUM_PLANE_COUNT {
    VIEW_FRUSTUM_PLANE_COUNT - 1
  } else {
    index
  }
}

///|
pub fn render3d_update_frusta_system(world : @ecs.World) -> Unit {
  @pbr_render.render3d_update_frusta_system_by_projection_key(
    world,
    ecs_key_projection,
    fn(projection, transform) { projection.compute_frustum(transform) },
  )
}
