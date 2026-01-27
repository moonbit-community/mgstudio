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
pub fn viewport_to_world_2d_run() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = [
    fn(app : @app.App[@ecs_world.World]) -> @app.App[@ecs_world.World] {
      @window.window_plugin(app)
    },
    fn(app : @app.App[@ecs_world.World]) -> @app.App[@ecs_world.World] {
      @time.time_plugin(app)
    },
    fn(app : @app.App[@ecs_world.World]) -> @app.App[@ecs_world.World] {
      @asset.asset_plugin(app)
    },
    fn(app : @app.App[@ecs_world.World]) -> @app.App[@ecs_world.World] {
      @render2d.render2d_plugin(app)
    },
    fn(app : @app.App[@ecs_world.World]) -> @app.App[@ecs_world.World] {
      @input.input_plugin(app)
    },
  ]
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(fn(_world : @ecs_world.World) {
    viewport_to_world_setup()
  })
  .add_system_param(viewport_to_world_update)
  .run()
}

///|
priv struct ViewportToWorldState {
  mut camera_handle : @render2d.CameraHandle
  mut camera_transform : @math.Transform
  mut camera_scale : Float
  mut viewport : @render2d.Viewport
}

///|
let viewport_state : Ref[ViewportToWorldState] = Ref::new(ViewportToWorldState::{
  camera_handle: @render2d.CameraHandle::new(-1),
  camera_transform: @math.Transform::identity(),
  camera_scale: 1.0F,
  viewport: @render2d.Viewport::new(
    @math.IVec2::new(0, 0),
    @math.IVec2::new(1, 1),
  ),
})

///|
fn viewport_to_world_setup() -> Unit {
  let asset_server = @asset.AssetServer::new()
  let anchor_texture = asset_server.load("branding/bevy_bird_dark.png")
  let anchor_sprite = @render2d.Sprite::new(@render2d.Color::white())
  let anchor_transform = @math.Transform::identity()
  @render2d.SpriteBundle::new(anchor_sprite, anchor_transform, anchor_texture).spawn()
  |> ignore
  let green = @render2d.Color::new(0.0F, 1.0F, 0.0F, 1.0F)
  let marker_mesh = @render2d.Mesh2d::from_rectangle(
    @render2d.Rectangle::new(40.0F, 20.0F),
  )
  let marker_material = @render2d.ColorMaterial::new(green)
  let marker_transform = @math.Transform::identity()
  @render2d.Mesh2dBundle::new(marker_mesh, marker_material, marker_transform).spawn()
  |> ignore
  let width = @window.window_width()
  let height = @window.window_height()
  let viewport = viewport_default(width, height)
  let camera = @render2d.Camera2d::default().with_viewport(viewport)
  let camera_transform = @math.Transform::identity()
  let camera_handle = @render2d.Camera2dBundle::new(camera, camera_transform).spawn()
  viewport_state.val.camera_handle = camera_handle
  viewport_state.val.camera_transform = camera_transform
  viewport_state.val.camera_scale = 1.0F
  viewport_state.val.viewport = viewport
  @render2d.render2d_set_camera_transform_handle(
    camera_handle, camera_transform,
  )
  @render2d.render2d_set_camera_viewport_handle(camera_handle, Some(viewport))
}

///|
fn viewport_to_world_update(gizmos : @render2d.Gizmos) -> Unit {
  let delta = @time.time_delta_seconds()
  let speed = 600.0F * delta
  let speed_i = speed.to_int()
  update_camera_transform(speed)
  update_camera_scale(delta)
  update_camera_viewport(speed_i)
  draw_viewport_outline(gizmos)
  if @input.mouse_position() is Some(screen_pos) {
    if @render2d.render2d_viewport_to_world_2d(screen_pos) is Some(world_pos) {
      let white = @render2d.Color::white()
      let red = @render2d.Color::new(1.0F, 0.2F, 0.2F, 1.0F)
      let cursor_iso = @render2d.Isometry2d::new(world_pos, 0.0F)
      gizmos.circle_2d(cursor_iso, 10.0F, white) |> ignore
      if @render2d.render2d_world_to_viewport(world_pos) is Some(viewport_pos) {
        if @render2d.render2d_viewport_to_world_2d(viewport_pos)
          is Some(world_check) {
          let check_iso = @render2d.Isometry2d::new(world_check, 0.0F)
          gizmos.circle_2d(check_iso, 8.0F, red) |> ignore
        }
      }
    }
  }
}

///|
fn update_camera_transform(speed : Float) -> Unit {
  let camera_transform = viewport_state.val.camera_transform
  let mut x = camera_transform.translation.x
  let mut y = camera_transform.translation.y
  if @input.key_pressed(@window.KeyCode::ArrowUp) {
    y = y + speed
  }
  if @input.key_pressed(@window.KeyCode::ArrowDown) {
    y = y - speed
  }
  if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    x = x - speed
  }
  if @input.key_pressed(@window.KeyCode::ArrowRight) {
    x = x + speed
  }
  if x != camera_transform.translation.x || y != camera_transform.translation.y {
    let next_camera = @math.Transform::new(
      @math.Vec2::new(x, y),
      camera_transform.rotation,
      camera_transform.scale,
    )
    viewport_state.val.camera_transform = next_camera
    @render2d.render2d_set_camera_transform_handle(
      viewport_state.val.camera_handle,
      next_camera,
    )
  }
}

///|
fn update_camera_scale(delta : Float) -> Unit {
  let mut scale = viewport_state.val.camera_scale
  if @input.key_pressed(@window.KeyCode::Comma) {
    scale = scale * @math.pow(4.0F, delta)
  }
  if @input.key_pressed(@window.KeyCode::Period) {
    scale = scale * @math.pow(0.25F, delta)
  }
  if scale != viewport_state.val.camera_scale {
    viewport_state.val.camera_scale = scale
    @render2d.render2d_set_camera_scale_handle(
      viewport_state.val.camera_handle,
      scale,
    )
  }
}

///|
fn update_camera_viewport(speed_i : Int) -> Unit {
  let width = @window.window_width()
  let height = @window.window_height()
  if width <= 0 || height <= 0 {
    return
  }
  let window_size = @math.IVec2::new(width, height)
  let mut viewport = viewport_state.val.viewport
  if viewport.physical_size.x > width || viewport.physical_size.y > height {
    viewport = viewport_default(width, height)
  } else {
    let mut position = viewport.physical_position
    let mut size = viewport.physical_size
    if @input.key_pressed(@window.KeyCode::KeyW) {
      position = position.saturating_sub(@math.IVec2::new(0, speed_i))
    }
    if @input.key_pressed(@window.KeyCode::KeyS) {
      position = position.add(@math.IVec2::new(0, speed_i))
    }
    if @input.key_pressed(@window.KeyCode::KeyA) {
      position = position.saturating_sub(@math.IVec2::new(speed_i, 0))
    }
    if @input.key_pressed(@window.KeyCode::KeyD) {
      position = position.add(@math.IVec2::new(speed_i, 0))
    }
    let max_position = window_size.saturating_sub(size)
    position = position.min(max_position)
    if @input.key_pressed(@window.KeyCode::KeyI) {
      size = size.saturating_sub(@math.IVec2::new(0, speed_i))
    }
    if @input.key_pressed(@window.KeyCode::KeyK) {
      size = size.add(@math.IVec2::new(0, speed_i))
    }
    if @input.key_pressed(@window.KeyCode::KeyJ) {
      size = size.saturating_sub(@math.IVec2::new(speed_i, 0))
    }
    if @input.key_pressed(@window.KeyCode::KeyL) {
      size = size.add(@math.IVec2::new(speed_i, 0))
    }
    let min_size = @math.IVec2::new(20, 20)
    let max_size = window_size.saturating_sub(position)
    size = size.min(max_size).max(min_size)
    viewport = @render2d.Viewport::new(position, size)
  }
  viewport_state.val.viewport = viewport
  @render2d.render2d_set_camera_viewport_handle(
    viewport_state.val.camera_handle,
    Some(viewport),
  )
}

///|
fn draw_viewport_outline(gizmos : @render2d.Gizmos) -> Unit {
  let viewport = viewport_state.val.viewport
  let width = viewport.physical_size.x
  let height = viewport.physical_size.y
  if width <= 0 || height <= 0 {
    return
  }
  let scale_factor = @window.window_scale_factor()
  let scale = if scale_factor <= 0.0F { 1.0F } else { scale_factor }
  let pos_x = Float::from_double(viewport.physical_position.x.to_double()) /
    scale
  let pos_y = Float::from_double(viewport.physical_position.y.to_double()) /
    scale
  let size_x = Float::from_double(width.to_double()) / scale
  let size_y = Float::from_double(height.to_double()) / scale
  let top_left = @math.Vec2::new(pos_x, pos_y)
  let top_right = @math.Vec2::new(pos_x + size_x, pos_y)
  let bottom_right = @math.Vec2::new(pos_x + size_x, pos_y + size_y)
  let bottom_left = @math.Vec2::new(pos_x, pos_y + size_y)
  if @render2d.render2d_viewport_to_world_2d(top_left) is Some(world_tl) {
    if @render2d.render2d_viewport_to_world_2d(top_right) is Some(world_tr) {
      if @render2d.render2d_viewport_to_world_2d(bottom_right) is Some(world_br) {
        if @render2d.render2d_viewport_to_world_2d(bottom_left)
          is Some(world_bl) {
          let base_config = @render2d.gizmo_config()
          let dashed_line = @render2d.GizmoLineConfig::{
            ..base_config.line,
            style: @render2d.GizmoLineStyle::Dashed(
              gap_scale=1.0F,
              line_scale=2.0F,
            ),
          }
          @render2d.gizmo_set_config(@render2d.GizmoConfig::{
            ..base_config,
            line: dashed_line,
          })
          let outline_color = @render2d.Color::new(0.8F, 0.8F, 0.8F, 1.0F)
          gizmos.line_2d(world_tl, world_tr, outline_color)
          gizmos.line_2d(world_tr, world_br, outline_color)
          gizmos.line_2d(world_br, world_bl, outline_color)
          gizmos.line_2d(world_bl, world_tl, outline_color)
          @render2d.gizmo_set_config(base_config)
        }
      }
    }
  }
}

///|
fn viewport_default(width : Int, height : Int) -> @render2d.Viewport {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  let size_x = safe_width * 3 / 4
  let size_y = safe_height * 3 / 4
  let pos_x = safe_width / 8
  let pos_y = safe_height / 8
  @render2d.Viewport::new(
    @math.IVec2::new(pos_x, pos_y),
    @math.IVec2::new(size_x, size_y),
  )
}
