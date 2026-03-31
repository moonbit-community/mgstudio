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
struct MainCamera {}

///|
let main_camera_key : @ecs.ComponentKey[MainCamera] = @ecs.register_component(
  debug_name="examples.2d.2d_viewport_to_world.MainCamera",
)

///|
pub impl @ecs.Component for MainCamera with component() {
  main_camera_key
}

///|
fn main {
  let draw_cursor_system = @app.system(@app.system_param5(draw_cursor)).after(
    @transform.transform_set_propagate,
  )
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .add_systems(@app.FixedUpdate, @app.system(@app.system_param6(controls)))
  .add_systems(@app.PostUpdate, draw_cursor_system)
  .run()
}

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
fn spawn_help_overlay(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_left(@ui.Val::Px(12.0F))
        .with_top(@ui.Val::Px(12.0F)),
        @text.Text::new(
          "Move the mouse to see the circle follow your cursor.\n" +
          "Use the arrow keys to move the camera.\n" +
          "Use the comma and period keys to zoom in and out.\n" +
          "Use the WASD keys to move the viewport.\n" +
          "Use the IJKL keys to resize the viewport.",
        ),
        @text.TextFont::default().with_font(font).with_font_size(18.0F),
        @text.TextColor::new(@sprite.Color::white()),
        @text.TextLayout::new_with_justify(@text.Justify::Left),
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@sprite.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let viewport = viewport_default(
    @window.window_width(),
    @window.window_height(),
  )
  ignore(
    commands.spawn(
      (
        @sprite.Camera2d::default(),
        @sprite.Camera::default().with_viewport(viewport),
        MainCamera::{  },
      ),
    ),
  )

  spawn_help_overlay(commands, asset_server)

  ignore(
    commands.spawn(
      (
        @sprite.Mesh2d::new(
          meshes.get_ref().val.add(
            @sprite.mesh2d_geometry_rectangle(
              @sprite.Rectangle::new(40.0F, 20.0F),
            ).to_mesh(),
          ),
        ),
        @sprite.MeshMaterial2d::new(
          materials.get_ref().val.add(
            @sprite.ColorMaterialAsset::from_color(
              @sprite.Color::new(0.0F, 0.5019608F, 0.0F, 1.0F),
            ),
          ),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @sprite.Mesh2d::new(
          meshes.get_ref().val.add(
            @sprite.mesh2d_geometry_rectangle(
              @sprite.Rectangle::new(50000.0F, 50000.0F),
            ).to_mesh(),
          ),
        ),
        @sprite.MeshMaterial2d::new(
          materials.get_ref().val.add(
            @sprite.ColorMaterialAsset::from_color(
              @sprite.Color::new(0.01F, 0.01F, 0.01F, 1.0F),
            ),
          ),
        ),
        @transform.Transform::from_xyz(0.0F, 0.0F, -200.0F),
      ),
    ),
  )
}

///|
fn main_camera_entity(
  camera_query : @ecs.Query[@ecs.Comp[MainCamera], @ecs.All],
) -> @core.Entity? {
  let entity_ref : Ref[@core.Entity?] = Ref::new(None)
  try! camera_query.view(fn(entity, _camera) {
    if entity_ref.val is None {
      entity_ref.val = Some(entity)
    }
  })
  entity_ref.val
}

///|
fn draw_cursor(
  main_camera : @ecs.Query[@ecs.Comp[MainCamera], @ecs.All],
  camera_query : @ecs.Query[@ecs.Comp[@sprite.Camera], @ecs.All],
  transform_query : @ecs.Query[@ecs.Comp[@transform.Transform], @ecs.All],
  projection_query : @ecs.Query[@ecs.Comp[@sprite.Projection], @ecs.All],
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
) -> Unit {
  guard main_camera_entity(main_camera) is Some(camera_entity) else { return }
  guard (camera_query.get(camera_entity) catch { _ => None })
    is Some(camera_comp) else {
    return
  }
  let camera = camera_comp.value()
  guard (projection_query.get(camera_entity) catch { _ => None })
    is Some(projection_comp) else {
    return
  }
  let projection = projection_comp.value()
  guard projection is Orthographic(orthographic_projection) else { return }
  guard (transform_query.get(camera_entity) catch { _ => None })
    is Some(camera_transform_comp) else {
    return
  }
  let camera_transform = camera_transform_comp.value()

  let width = @window.window_width()
  let height = @window.window_height()
  if width <= 0 || height <= 0 {
    return
  }

  let window_size = @math.IVec2::new(width, height)
  let scale_factor = @window.window_scale_factor()

  if @input.mouse_position() is Some(screen_pos) {
    if @sprite_render.render2d_camera_viewport_to_world_2d(
        screen_pos, camera, orthographic_projection, camera_transform, window_size,
        scale_factor,
      )
      is Some(world_pos) {
      let white = @sprite.Color::white()
      let red = @sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F)
      let cursor_iso = @sprite.Isometry2d::new(world_pos, 0.0F)
      gizmos.circle_2d(cursor_iso, 10.0F, white) |> ignore

      if @sprite_render.render2d_camera_world_to_viewport_2d(
          world_pos, camera, orthographic_projection, camera_transform, window_size,
          scale_factor,
        )
        is Some(viewport_pos) {
        if @sprite_render.render2d_camera_viewport_to_world_2d(
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
fn controls(
  main_camera : @ecs.Query[@ecs.Comp[MainCamera], @ecs.All],
  camera_query : @ecs.Query[@ecs.Mut[@sprite.Camera], @ecs.All],
  transform_query : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.All],
  projection_query : @ecs.Query[@ecs.Mut[@sprite.Projection], @ecs.All],
  input : @input.ButtonInput[@window.KeyCode],
  time : @app.Res[@time.Time[@time.Fixed]],
) -> Unit {
  guard main_camera_entity(main_camera) is Some(camera_entity) else { return }
  let fspeed = 600.0F * time.get().delta_seconds()
  let uspeed = fspeed.to_int()

  ignore(
    if (transform_query.get(camera_entity) catch { _ => None })
      is Some(camera_transform) {
      let transform_ref = camera_transform.get_ref()
      let mut x = transform_ref.val.translation.x
      let mut y = transform_ref.val.translation.y
      if input.pressed(@window.KeyCode::ArrowUp) {
        y = y + fspeed
      }
      if input.pressed(@window.KeyCode::ArrowDown) {
        y = y - fspeed
      }
      if input.pressed(@window.KeyCode::ArrowLeft) {
        x = x - fspeed
      }
      if input.pressed(@window.KeyCode::ArrowRight) {
        x = x + fspeed
      }
      if x != transform_ref.val.translation.x ||
        y != transform_ref.val.translation.y {
        transform_ref.val = @transform.Transform::from_xy_rotation_scale(
          @math.Vec2::new(x, y),
          transform_ref.val.rotation_z(),
          @math.Vec2::new(transform_ref.val.scale.x, transform_ref.val.scale.y),
          z=transform_ref.val.translation.z,
        )
      }
    },
  )

  ignore(
    if (projection_query.get(camera_entity) catch { _ => None })
      is Some(camera_projection) {
      let projection_ref = camera_projection.get_ref()
      match projection_ref.val {
        @sprite.Projection::Orthographic(orthographic) => {
          let mut scale = orthographic.scale
          if input.pressed(@window.KeyCode::Comma) {
            scale = scale * @math.pow(4.0F, time.get().delta_seconds())
          }
          if input.pressed(@window.KeyCode::Period) {
            scale = scale * @math.pow(0.25F, time.get().delta_seconds())
          }
          if scale != orthographic.scale {
            projection_ref.val = @sprite.Projection::Orthographic(
              @sprite.OrthographicProjection::new(scale),
            )
          }
        }
      }
    },
  )

  let width = @window.window_width()
  let height = @window.window_height()
  if width <= 0 || height <= 0 {
    return
  }

  ignore(
    if (camera_query.get(camera_entity) catch { _ => None })
      is Some(camera_component) {
      let camera_ref = camera_component.get_ref()
      let window_size = @math.IVec2::new(width, height)
      let current_viewport = match camera_ref.val.viewport {
        Some(viewport) => viewport
        None => viewport_default(width, height)
      }
      let mut viewport = current_viewport
      if viewport.physical_size.x > width || viewport.physical_size.y > height {
        viewport = @sprite.Viewport::new(
          viewport.physical_position,
          @math.IVec2::new(width * 3 / 4, height * 3 / 4),
        )
      }

      let mut position = viewport.physical_position
      let mut size = viewport.physical_size
      if input.pressed(@window.KeyCode::KeyW) {
        position = position.saturating_sub(@math.IVec2::new(0, uspeed))
      }
      if input.pressed(@window.KeyCode::KeyS) {
        position = position.add(@math.IVec2::new(0, uspeed))
      }
      if input.pressed(@window.KeyCode::KeyA) {
        position = position.saturating_sub(@math.IVec2::new(uspeed, 0))
      }
      if input.pressed(@window.KeyCode::KeyD) {
        position = position.add(@math.IVec2::new(uspeed, 0))
      }
      let max_position = window_size.saturating_sub(size)
      position = position.min(max_position)

      if input.pressed(@window.KeyCode::KeyI) {
        size = size.saturating_sub(@math.IVec2::new(0, uspeed))
      }
      if input.pressed(@window.KeyCode::KeyK) {
        size = size.add(@math.IVec2::new(0, uspeed))
      }
      if input.pressed(@window.KeyCode::KeyJ) {
        size = size.saturating_sub(@math.IVec2::new(uspeed, 0))
      }
      if input.pressed(@window.KeyCode::KeyL) {
        size = size.add(@math.IVec2::new(uspeed, 0))
      }

      let min_size = @math.IVec2::new(20, 20)
      let max_size = window_size.saturating_sub(position)
      size = size.min(max_size).max(min_size)
      let next_viewport = @sprite.Viewport::new(position, size)
      let changed = next_viewport.physical_position.x !=
        current_viewport.physical_position.x ||
        next_viewport.physical_position.y !=
        current_viewport.physical_position.y ||
        next_viewport.physical_size.x != current_viewport.physical_size.x ||
        next_viewport.physical_size.y != current_viewport.physical_size.y
      if changed {
        camera_ref.val = camera_ref.val.with_viewport(next_viewport)
      }
    },
  )
}
