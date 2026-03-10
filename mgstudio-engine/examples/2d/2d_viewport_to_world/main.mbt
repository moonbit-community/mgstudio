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
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(viewport_to_world_setup))
  .add_systems(@app.FixedUpdate, @app.system(viewport_to_world_controls))
  .add_systems(@app.PostUpdate, @app.system(viewport_to_world_draw_cursor))
  .run()
}

///|
priv struct ViewportToWorldState {
  mut camera : @core.Entity
  mut camera_transform : @math.Transform
  mut camera_scale : Float
  mut viewport : @sprite.Viewport
}

///|
let viewport_state : Ref[ViewportToWorldState] = Ref::new(ViewportToWorldState::{
  camera: @core.Entity::placeholder(),
  camera_transform: @math.Transform::identity(),
  camera_scale: 1.0F,
  viewport: @sprite.Viewport::new(
    @math.IVec2::new(0, 0),
    @math.IVec2::new(1, 1),
  ),
})

///|
fn viewport_default(width : Int, height : Int) -> @sprite.Viewport {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  let size_x = safe_width * 3 / 4
  let size_y = safe_height * 3 / 4
  let pos_x = safe_width / 8
  let pos_y = safe_height / 8
  @sprite.Viewport::new(
    @math.IVec2::new(pos_x, pos_y),
    @math.IVec2::new(size_x, size_y),
  )
}

///|
fn spawn_ui_text_handle(
  content : String,
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  color : @sprite.Color,
) -> @text.TextHandle {
  @text.Text2dBundle::new(
    @text.Text2d::new(content),
    @text.TextFont::default().with_font(font).with_font_size(font_size),
    @math.Transform::identity(),
  )
  .with_color(@text.TextColor::new(color))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
  .spawn()
}

///|
fn spawn_help_overlay(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let text_handle = spawn_ui_text_handle(
    "Move the mouse to see the circle follow your cursor.\n" +
    "Use the arrow keys to move the camera.\n" +
    "Use the comma and period keys to zoom in and out.\n" +
    "Use the WASD keys to move the viewport.\n" +
    "Use the IJKL keys to resize the viewport.",
    font,
    18.0F,
    @sprite.Color::white(),
  )
  let tick = world.read_change_tick()
  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
    tick,
  )
  let text_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    text_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(text_entity, @ui.UiText::new(text_handle), tick)
}

///|
fn viewport_to_world_setup(world : @ecs.World) -> Unit {
  let width = @window.window_width()
  let height = @window.window_height()
  let viewport = viewport_default(width, height)
  let camera = @sprite.Camera::default().with_viewport(viewport)
  let camera_transform = @math.Transform::identity()
  let camera_entity = @sprite.Camera2dBundle::new(camera, camera_transform).spawn(
    world,
  )
  viewport_state.val.camera = camera_entity
  viewport_state.val.camera_transform = camera_transform
  viewport_state.val.camera_scale = 1.0F
  viewport_state.val.viewport = viewport

  spawn_help_overlay(world)

  @sprite.Mesh2dBundle::new(
    @sprite.Mesh2d::from_rectangle(@sprite.Rectangle::new(40.0F, 20.0F)),
    @sprite.ColorMaterial::new(@sprite.Color::new(0.0F, 0.5019608F, 0.0F, 1.0F)),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  @sprite.Mesh2dBundle::new(
    @sprite.Mesh2d::from_rectangle(@sprite.Rectangle::new(50000.0F, 50000.0F)),
    @sprite.ColorMaterial::new(@sprite.Color::new(0.01F, 0.01F, 0.01F, 1.0F)),
    @math.Transform::from_xyz(0.0F, 0.0F, -200.0F),
  ).spawn(world)
  |> ignore
}

///|
fn viewport_to_world_draw_cursor(world : @ecs.World) -> Unit {
  if viewport_state.val.camera.is_placeholder() {
    return
  }

  let camera_entity = viewport_state.val.camera
  let camera_store = world.component(@sprite.ecs_key_camera)
  let projection_store = world.component(@sprite.ecs_key_projection)
  let transform_store = world.component(@math.ecs_key_transform)

  guard camera_store.get(camera_entity) is Some(camera) else { return }
  guard projection_store.get(camera_entity) is Some(projection) else { return }
  guard projection is Orthographic(orthographic_projection) else { return }
  guard transform_store.get(camera_entity) is Some(camera_transform) else {
    return
  }

  let width = @window.window_width()
  let height = @window.window_height()
  if width <= 0 || height <= 0 {
    return
  }

  let window_size = @math.IVec2::new(width, height)
  let scale_factor = @window.window_scale_factor()
  let gizmos = @sprite.Gizmos::new()

  if @input.mouse_position() is Some(screen_pos) {
    if @sprite.render2d_camera_viewport_to_world_2d(
        screen_pos, camera, orthographic_projection, camera_transform, window_size,
        scale_factor,
      )
      is Some(world_pos) {
      let white = @sprite.Color::white()
      let red = @sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F)
      let cursor_iso = @sprite.Isometry2d::new(world_pos, 0.0F)
      gizmos.circle_2d(cursor_iso, 10.0F, white) |> ignore

      if @sprite.render2d_camera_world_to_viewport_2d(
          world_pos, camera, orthographic_projection, camera_transform, window_size,
          scale_factor,
        )
        is Some(viewport_pos) {
        if @sprite.render2d_camera_viewport_to_world_2d(
            viewport_pos, camera, orthographic_projection, camera_transform, window_size,
            scale_factor,
          )
          is Some(world_check) {
          let check_iso = @sprite.Isometry2d::new(world_check, 0.0F)
          gizmos.circle_2d(check_iso, 8.0F, red) |> ignore
        }
      }
    }
  }
}

///|
fn viewport_to_world_controls(world : @ecs.World) -> Unit {
  if viewport_state.val.camera.is_placeholder() {
    return
  }
  let fspeed = 600.0F * @time.time_fixed_delta_seconds()
  let uspeed = fspeed.to_int()

  update_camera_transform(world, fspeed)
  update_camera_scale(world, @time.time_fixed_delta_seconds())

  let width = @window.window_width()
  let height = @window.window_height()
  if width <= 0 || height <= 0 {
    return
  }
  update_camera_viewport(world, width, height, uspeed)
}

///|
fn update_camera_transform(world : @ecs.World, fspeed : Float) -> Unit {
  let camera_transform = viewport_state.val.camera_transform
  let mut x = camera_transform.translation.x
  let mut y = camera_transform.translation.y
  if @input.key_pressed(@window.KeyCode::ArrowUp) {
    y = y + fspeed
  }
  if @input.key_pressed(@window.KeyCode::ArrowDown) {
    y = y - fspeed
  }
  if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    x = x - fspeed
  }
  if @input.key_pressed(@window.KeyCode::ArrowRight) {
    x = x + fspeed
  }
  if x != camera_transform.translation.x || y != camera_transform.translation.y {
    let next_camera = @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(x, y),
      camera_transform.rotation_z(),
      @math.Vec2::new(camera_transform.scale.x, camera_transform.scale.y),
      z=camera_transform.translation.z,
    )
    viewport_state.val.camera_transform = next_camera
    let tick = world.read_change_tick()
    world
    .component(@math.ecs_key_transform)
    .set(viewport_state.val.camera, next_camera, tick)
    |> ignore
  }
}

///|
fn update_camera_scale(world : @ecs.World, delta : Float) -> Unit {
  let mut scale = viewport_state.val.camera_scale
  if @input.key_pressed(@window.KeyCode::Comma) {
    scale = scale * @math.pow(4.0F, delta)
  }
  if @input.key_pressed(@window.KeyCode::Period) {
    scale = scale * @math.pow(0.25F, delta)
  }
  if scale != viewport_state.val.camera_scale {
    viewport_state.val.camera_scale = scale
    let tick = world.read_change_tick()
    let projection_store = world.component(@sprite.ecs_key_projection)
    projection_store.set(
      viewport_state.val.camera,
      @sprite.Projection::Orthographic(
        @sprite.OrthographicProjection::new(scale),
      ),
      tick,
    )
    |> ignore
  }
}

///|
fn update_camera_viewport(
  world : @ecs.World,
  width : Int,
  height : Int,
  uspeed : Int,
) -> Unit {
  let window_size = @math.IVec2::new(width, height)
  let mut viewport = viewport_state.val.viewport
  if viewport.physical_size.x > width || viewport.physical_size.y > height {
    viewport = @sprite.Viewport::new(
      viewport.physical_position,
      @math.IVec2::new(width * 3 / 4, height * 3 / 4),
    )
  }
  let mut position = viewport.physical_position
  let mut size = viewport.physical_size
  if @input.key_pressed(@window.KeyCode::KeyW) {
    position = position.saturating_sub(@math.IVec2::new(0, uspeed))
  }
  if @input.key_pressed(@window.KeyCode::KeyS) {
    position = position.add(@math.IVec2::new(0, uspeed))
  }
  if @input.key_pressed(@window.KeyCode::KeyA) {
    position = position.saturating_sub(@math.IVec2::new(uspeed, 0))
  }
  if @input.key_pressed(@window.KeyCode::KeyD) {
    position = position.add(@math.IVec2::new(uspeed, 0))
  }
  let max_position = window_size.saturating_sub(size)
  position = position.min(max_position)
  if @input.key_pressed(@window.KeyCode::KeyI) {
    size = size.saturating_sub(@math.IVec2::new(0, uspeed))
  }
  if @input.key_pressed(@window.KeyCode::KeyK) {
    size = size.add(@math.IVec2::new(0, uspeed))
  }
  if @input.key_pressed(@window.KeyCode::KeyJ) {
    size = size.saturating_sub(@math.IVec2::new(uspeed, 0))
  }
  if @input.key_pressed(@window.KeyCode::KeyL) {
    size = size.add(@math.IVec2::new(uspeed, 0))
  }
  let min_size = @math.IVec2::new(20, 20)
  let max_size = window_size.saturating_sub(position)
  size = size.min(max_size).max(min_size)
  viewport = @sprite.Viewport::new(position, size)
  let old_viewport = viewport_state.val.viewport
  let position_changed = viewport.physical_position.x !=
    old_viewport.physical_position.x ||
    viewport.physical_position.y != old_viewport.physical_position.y
  let size_changed = viewport.physical_size.x != old_viewport.physical_size.x ||
    viewport.physical_size.y != old_viewport.physical_size.y
  let viewport_changed = position_changed || size_changed
  if !viewport_changed {
    return
  }
  viewport_state.val.viewport = viewport
  let tick = world.read_change_tick()
  let camera_store = world.component(@sprite.ecs_key_camera)
  if camera_store.get(viewport_state.val.camera) is Some(camera) {
    camera_store.set(
      viewport_state.val.camera,
      camera.with_viewport(viewport),
      tick,
    )
    |> ignore
  }
}
