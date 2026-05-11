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
extenum @ecs.EcsPayload += {
  EcsPayload_render_view_visibility_RenderVisibilityRanges(
    RenderVisibilityRanges
  )
  EcsPayload_render_view_visibility_RenderVisibleEntities(RenderVisibleEntities)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderVisibilityRanges with to_ecs_payload(
  self,
) {
  EcsPayload_render_view_visibility_RenderVisibilityRanges(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderVisibilityRanges with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_render_view_visibility_RenderVisibilityRanges(value) =>
      Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RenderVisibleEntities with to_ecs_payload(
  self,
) {
  EcsPayload_render_view_visibility_RenderVisibleEntities(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderVisibleEntities with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_render_view_visibility_RenderVisibleEntities(value) =>
      Some(value)
    _ => None
  }
}
