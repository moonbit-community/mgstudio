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
fn camera_runtime_approx_eq(a : Float, b : Float) -> Bool {
  let delta = a - b
  if delta < 0.0F {
    -delta < 0.001F
  } else {
    delta < 0.001F
  }
}

///|
test "render3d: projection runtime updates changed orthographic projection at stable viewport" {
  let (runtime_projection, runtime_update) = @render.render3d_projection_runtime_update(
    Orthographic(
      @camera_projection3d.OrthographicProjection3d::default_3d()
      .with_scaling_mode(FixedVertical(6.0F))
      .with_scale(2.0F),
    ),
    Some({
      last_view_width: 800.0F,
      last_view_height: 400.0F,
      is_orthographic: true,
      orthographic_first_slice_depth: 0.0F,
    }),
    true,
    @camera_camera.Camera::Camera(),
    @math.IVec2::new(800, 400),
    1.0F,
  )
  let runtime_is_orthographic = match runtime_update {
    Some(update) => update.is_orthographic
    None => false
  }
  let runtime_first_slice_depth = match runtime_update {
    Some(update) => update.orthographic_first_slice_depth
    None => 0.0F
  }
  let ok = match runtime_projection {
    Orthographic(orthographic) => {
      let area = orthographic.area()
      let clip_from_view = orthographic.get_clip_from_view()
      let row_two = clip_from_view.row(2)
      let expected_first_slice_depth = if row_two.z.abs() <= 1.0e-6F {
        (row_two.w - 1.0F) / 1.0e-6F
      } else {
        (row_two.w - 1.0F) / row_two.z
      }
      camera_runtime_approx_eq(area.min.x, -12.0F) &&
      camera_runtime_approx_eq(area.max.x, 12.0F) &&
      camera_runtime_approx_eq(area.min.y, -6.0F) &&
      camera_runtime_approx_eq(area.max.y, 6.0F) &&
      runtime_is_orthographic &&
      camera_runtime_approx_eq(
        runtime_first_slice_depth, expected_first_slice_depth,
      )
    }
    Perspective(_) => false
    Custom(_) => false
  }
  debug_inspect(ok, content="true")
}

///|
// Bevy source: `bevy/crates/bevy_render/src/camera.rs` --
// `register_required_components::<Camera, SyncToRenderWorld>()`.
test "render camera: sync marker is required on Camera by the render side" {
  let world = @ecs.World::new()
  defer world.close()
  @render.ensure_camera_sync_to_render_world(world)
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  debug_inspect(
    (try! world.get_by_key(entity, @render.ecs_key_sync_to_render_world))
    is Some(_),
    content="true",
  )
}
