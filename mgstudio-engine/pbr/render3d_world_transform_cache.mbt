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
type Render3dWorldTransformCache = @pbr_render.Render3dWorldTransformCache

///|
fn render3d_transform_point(
  transform : @transform.Transform,
  local_point : @math.Vec3,
) -> @math.Vec3 {
  @pbr_render.render3d_transform_point(transform, local_point)
}

///|
fn render3d_world_transform_cache_ref() -> Ref[Render3dWorldTransformCache] {
  @pbr_render.render3d_world_transform_cache_ref()
}

///|
fn render3d_world_transform_cache_begin_frame(
  cache_ref : Ref[Render3dWorldTransformCache],
) -> Unit {
  @pbr_render.render3d_world_transform_cache_begin_frame(cache_ref)
}

///|
fn render3d_entity_world_transform_cached(
  world : @ecs.World,
  entity : @core.Entity,
  cache_ref : Ref[Render3dWorldTransformCache],
) -> @transform.Transform {
  @pbr_render.render3d_entity_world_transform_cached(world, entity, cache_ref)
}

///|
fn render3d_entity_world_transform_from_components(
  world : @ecs.World,
  entity : @core.Entity,
  local_transform : @transform.Transform,
  cache_ref : Ref[Render3dWorldTransformCache],
) -> @transform.Transform {
  @pbr_render.render3d_entity_world_transform_from_components(
    world, entity, local_transform, cache_ref,
  )
}
