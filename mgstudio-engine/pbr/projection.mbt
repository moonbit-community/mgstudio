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
// Compatibility projection surface for `Milky2018/mgstudio/pbr`.
// Canonical Bevy `bevy_camera/src/projection.rs` ownership lives in
// `Milky2018/mgstudio/camera/projection3d`.

///|
pub type PerspectiveProjection3d = @camera_projection3d.PerspectiveProjection3d

///|
pub type OrthographicProjection3d = @camera_projection3d.OrthographicProjection3d

///|
pub type OrthographicScalingMode3d = @camera_projection3d.OrthographicScalingMode3d

///|
pub type SubCameraView3d = @camera_projection3d.SubCameraView3d

///|
pub type ProjectionMatrix3d = @camera_projection3d.ProjectionMatrix3d

///|
pub type CustomProjection3d = @camera_projection3d.CustomProjection3d

///|
pub type Projection = @camera_projection3d.Projection

///|
pub type ProjectionRuntime3d = @camera_projection3d.ProjectionRuntime3d

///|
pub fn render3d_perspective_projection_compute_frustum(
  projection : PerspectiveProjection3d,
  camera_transform : @transform.Transform,
) -> Frustum {
  @camera_projection3d.render3d_perspective_projection_compute_frustum(
    projection, camera_transform,
  )
}

///|
pub fn render3d_orthographic_projection_compute_frustum(
  projection : OrthographicProjection3d,
  camera_transform : @transform.Transform,
) -> Frustum {
  @camera_projection3d.render3d_orthographic_projection_compute_frustum(
    projection, camera_transform,
  )
}

///|
fn render3d_projection_near(
  projection : Projection,
  clip_from_view : ProjectionMatrix3d,
) -> Float {
  match projection {
    Perspective(perspective) =>
      @camera_projection3d.maxf(0.0001F, perspective.near)
    Orthographic(orthographic) => orthographic.near
    Custom(_) =>
      @camera_projection3d.render3d_projection_near_from_clip_matrix(
        clip_from_view,
      )
  }
}

///|
fn render3d_camera_pass_projection(
  projection : Projection,
  sub_camera_view : SubCameraView3d?,
  temporal_jitter : TemporalJitter?,
  view_width : Int,
  view_height : Int,
) -> @pbr_render.Render3dPassProjection {
  let unjittered_clip_from_view = match sub_camera_view {
    Some(sub_view) => projection.get_clip_from_view_for_sub(sub_view)
    None => projection.get_clip_from_view()
  }
  let clip_from_view = match temporal_jitter {
    Some(temporal_jitter) =>
      @camera_projection3d.render3d_projection_matrix_apply_temporal_jitter(
        unjittered_clip_from_view, temporal_jitter, view_width, view_height,
      )
    None => unjittered_clip_from_view
  }
  @pbr_render.render3d_pass_projection(
    clip_from_view,
    unjittered_clip_from_view,
    render3d_projection_near(projection, unjittered_clip_from_view),
    projection.far(),
  )
}

///|
fn render3d_projection_runtime_projection(
  projection : Projection,
  camera : @camera_camera.Camera,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> Projection {
  match
    @pbr_render.render3d_camera_viewport_rect_logical(
      camera, target_size, scale_factor,
    ) {
    Some((_, _, viewport_width, viewport_height)) =>
      projection.update(viewport_width, viewport_height)
    None => projection
  }
}

///|
// Bevy source: `bevy/crates/bevy_render/src/camera.rs::camera_system`.
pub fn render3d_camera_system(world : @ecs.World) -> Unit {
  let projection_updates : Array[(@core.Entity, Projection)] = []
  let camera_updates : Array[(@core.Entity, @camera_camera.Camera)] = []
  let camera_query : @ecs.Query[
    (
      @core.Entity,
      @ecs.Read[@camera_camera.Camera],
      @ecs.Read[Projection],
      @ecs.Optional[@camera_camera.RenderTarget],
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! camera_query.view(fn(_query_entity, data) {
    let (entity, camera_read, projection_read, target_opt) = data
    let target = match target_opt.value() {
      Some(v) => v
      None => @camera_camera.RenderTarget::Screen
    }
    match @pbr_render.render3d_target_info(world, target) {
      Some(target_info) => {
        let mut camera = camera_read.value()
        if camera.viewport is Some(viewport) {
          camera = camera.with_viewport(
            @pbr_render.render3d_clamp_viewport(
              viewport,
              target_info.target_size,
            ),
          )
        }
        let viewport_size = camera.physical_viewport_size()
        let computed = @camera_camera.ComputedCameraValues::new(
          Some(
            @camera_camera.RenderTargetInfo::new(
              target_info.target_size,
              target_info.scale_factor,
            ),
          ),
          viewport_size,
        )
        let camera_with_computed = camera.with_computed(computed)
        let projection = projection_read.value()
        match camera_with_computed.logical_viewport_size() {
          Some(logical_size) =>
            if logical_size.x != 0.0F && logical_size.y != 0.0F {
              projection_updates.push(
                (entity, projection.update(logical_size.x, logical_size.y)),
              )
            }
          None => ()
        }
        camera_updates.push((entity, camera_with_computed))
      }
      None => ()
    }
  })
  for update in projection_updates {
    try! world.set_by_key(update.0, ecs_key_projection, update.1)
  }
  for update in camera_updates {
    try! world.set_by_key(update.0, @camera_camera.ecs_key_camera, update.1)
  }
}

///|
fn render3d_projection_runtime_update(
  projection : Projection,
  runtime : ProjectionRuntime3d?,
  force_update : Bool,
  camera : @camera_camera.Camera,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> (Projection, ProjectionRuntime3d?) {
  match
    @pbr_render.render3d_camera_viewport_rect_logical(
      camera, target_size, scale_factor,
    ) {
    Some((_, _, viewport_width, viewport_height)) => {
      let updated_projection = projection.update(
        viewport_width, viewport_height,
      )
      let is_orthographic = !updated_projection.is_perspective()
      let orthographic_first_slice_depth = if is_orthographic {
        let clip_from_view = updated_projection.get_clip_from_view()
        let row_two = clip_from_view.row(2)
        let safe_row_two_z = if row_two.z.abs() <= 1.0e-6F {
          1.0e-6F
        } else {
          row_two.z
        }
        (row_two.w - 1.0F) / safe_row_two_z
      } else {
        0.0F
      }
      let next_runtime = ProjectionRuntime3d::{
        last_view_width: viewport_width,
        last_view_height: viewport_height,
        is_orthographic,
        orthographic_first_slice_depth,
      }
      if runtime is Some(previous_runtime) &&
        previous_runtime.last_view_width == viewport_width &&
        previous_runtime.last_view_height == viewport_height &&
        previous_runtime.is_orthographic == is_orthographic &&
        previous_runtime.orthographic_first_slice_depth ==
        orthographic_first_slice_depth &&
        !force_update {
        (projection, None)
      } else {
        (updated_projection, Some(next_runtime))
      }
    }
    None => (projection, None)
  }
}
