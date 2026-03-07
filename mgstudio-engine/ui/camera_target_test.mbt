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
test "ui: default ui camera marker overrides lower order fallback camera" {
  let world = @ecs.World::new()
  let tick = world.increment_change_tick()
  get_ui_context_resource(world).insert(
    UiContext::new(
      @asset.Handle::new(1),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      None,
      @math.Transform::identity(),
      1.0F,
      None,
      false,
    ),
    tick,
  )

  let fallback = world.spawn_empty()
  @render2d.get_camera2d_store(world).insert(
    fallback,
    @render2d.Camera2d::default(),
    tick,
  )
  @render2d.get_camera_store(world).insert(
    fallback,
    @render2d.Camera::default().with_order(0),
    tick,
  )

  let marked = world.spawn_empty()
  @render2d.get_camera2d_store(world).insert(
    marked,
    @render2d.Camera2d::default(),
    tick,
  )
  @render2d.get_camera_store(world).insert(
    marked,
    @render2d.Camera::default().with_order(10),
    tick,
  )
  get_is_default_ui_camera_store(world).insert(
    marked,
    IsDefaultUiCamera::default(),
    tick,
  )

  ui_update_context_system(world)
  inspect(
    get_ui_context_resource(world).get().unwrap().camera_entity == Some(marked),
    content="true",
  )
}

///|
test "ui: fallback ui camera selection ignores image targets and picks lowest order" {
  let world = @ecs.World::new()
  let tick = world.increment_change_tick()
  get_ui_context_resource(world).insert(
    UiContext::new(
      @asset.Handle::new(1),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      None,
      @math.Transform::identity(),
      1.0F,
      None,
      false,
    ),
    tick,
  )

  let image_camera = world.spawn_empty()
  @render2d.get_camera2d_store(world).insert(
    image_camera,
    @render2d.Camera2d::default(),
    tick,
  )
  @render2d.get_camera_store(world).insert(
    image_camera,
    @render2d.Camera::default().with_order(-5),
    tick,
  )
  @render2d.get_render_target_store(world).insert(
    image_camera,
    @render2d.RenderTarget::Image(@asset.Handle::new(1)),
    tick,
  )

  let high_order = world.spawn_empty()
  @render2d.get_camera2d_store(world).insert(
    high_order,
    @render2d.Camera2d::default(),
    tick,
  )
  @render2d.get_camera_store(world).insert(
    high_order,
    @render2d.Camera::default().with_order(5),
    tick,
  )

  let low_order = world.spawn_empty()
  @render2d.get_camera2d_store(world).insert(
    low_order,
    @render2d.Camera2d::default(),
    tick,
  )
  @render2d.get_camera_store(world).insert(
    low_order,
    @render2d.Camera::default().with_order(1),
    tick,
  )

  ui_update_context_system(world)
  inspect(
    get_ui_context_resource(world).get().unwrap().camera_entity ==
    Some(low_order),
    content="true",
  )
}
