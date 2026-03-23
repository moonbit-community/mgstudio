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
fn seed_ui_context(world : @ecs.World) -> Unit {
  let mut camera_entity : @core.Entity? = None
  @sprite.get_camera_store(world).for_each(fn(entity, _camera) {
    if camera_entity is None {
      camera_entity = Some(entity)
    }
  })
  @ui.get_ui_context_resource(world).insert(
    @ui.UiContext::new(
      @asset.Handle::new(1),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1280.0F, 720.0F),
      camera_entity,
      @transform.Transform::identity(),
      1.0F,
      None,
      false,
    ),
  )
}

///|
fn seed_primary_window(world : @ecs.World) -> Unit {
  let entity = world.spawn()
  let window = @window.Window::default()
  window.resolution.set_physical_resolution(1280, 720)
  window.resolution.set_scale_factor(1.0F)
  try! world.set_component(entity, window)
  try! world.set_component(entity, @window.PrimaryWindow::{  })
}

///|
fn run_ui_extract_pipeline(world : @ecs.World) -> Unit {
  @ui.ui_propagate_target_cameras_system(world)
  @text.ui_text_sync_ecs_system(world)
  @ui.ui_image_content_size_system(world)
  @ui.ui_layout_system(world)
  @ui.ui_clip_system(world)
  @ui.ui_stack_system(world)
  @ui_render.ui_render_extract_system(world)
  @sprite.render_extract_system_ecs(world)
  @sprite.render_prepare_system(world)
  @sprite.render_queue_system(world)
}

///|
test "examples ui button: seeded ui context produces queued ui draw items" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    @mgstudio.default_plugins(),
  )
  let world = app.world()
  @sprite.init_render_state_system(world)

  setup(world)
  seed_ui_context(world)

  let camera_count = Ref::new(0)
  @sprite.get_camera2d_store(world).for_each(fn(_entity, _camera) {
    camera_count.val = camera_count.val + 1
  })
  inspect(camera_count.val, content="1")
  inspect(world.query1(@sprite.ecs_key_camera2d).count(), content="1")

  run_ui_extract_pipeline(world)

  inspect(@sprite.render2d_prepared_camera_count(world), content="Some(1)")
  inspect(@sprite.render2d_queued_draw_item_count(world), content="Some(2)")
}

///|
test "examples ui button: runtime ui context also produces queued ui draw items" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    @mgstudio.default_plugins(),
  )
  let world = app.world()
  @sprite.init_render_state_system(world)
  seed_primary_window(world)
  setup(world)

  @ui.ui_update_context_system(world)
  inspect(
    @ui.get_ui_context_resource(world).get().unwrap().camera_entity is Some(_),
    content="true",
  )

  run_ui_extract_pipeline(world)

  inspect(@sprite.render2d_prepared_camera_count(world), content="Some(1)")
  inspect(@sprite.render2d_queued_draw_item_count(world), content="Some(2)")
}

///|
test "examples ui button: scheduled update queues ui draw items" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@mgstudio.default_plugins())
    .add_systems(@app.Startup, @app.system(setup))
  app = app.update()

  let world = app.world()
  let button_entities : Array[@core.Entity] = []
  world
  .query_entities_filtered(@ecs.With::new(@ui.ecs_key_button))
  .view(fn(entity) { button_entities.push(entity) })
  let layout_store = @ui.get_ui_layout_store(world)
  let layout = layout_store.get(button_entities[0]).unwrap()
  let layout_size = layout.rect.size()
  inspect(@sprite.render2d_diagnostic_prepared_camera_count(), content="1")
  inspect(
    @sprite.render2d_diagnostic_queued_draw_item_count() > 0,
    content="true",
  )
  inspect(
    @ui.get_ui_context_resource(world).get().unwrap().camera_entity is Some(_),
    content="true",
  )
  inspect(layout_size.x > 0.0F && layout_size.y > 0.0F, content="true")
}
