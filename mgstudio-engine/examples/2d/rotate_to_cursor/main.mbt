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
struct Player {}

///|
let player_key : @ecs.ComponentKey[Player] = @ecs.register_component(
  debug_name="examples.2d.rotate_to_cursor.Player",
)

///|
pub impl @ecs.Component for Player with component() {
  player_key
}

///|
struct MainCamera {}

///|
let main_camera_key : @ecs.ComponentKey[MainCamera] = @ecs.register_component(
  debug_name="examples.2d.rotate_to_cursor.MainCamera",
)

///|
pub impl @ecs.Component for MainCamera with component() {
  main_camera_key
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(
    @app.FixedUpdate,
    @app.system(@app.system_param6(player_movement_system)),
  )
  .run()
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(
          asset_server.get().load("textures/simplespace/ship_C.png"),
        ),
        Player::{  },
      ),
    ),
  )
  ignore(commands.spawn((@sprite.Camera2d::default(), MainCamera::{  })))
}

///|
fn main_camera_entity(
  main_camera_query : @ecs.Query[@ecs.Comp[MainCamera], @ecs.All],
) -> @core.Entity? {
  let entity_ref : Ref[@core.Entity?] = Ref::new(None)
  try! main_camera_query.view(fn(entity, _camera) {
    if entity_ref.val is None {
      entity_ref.val = Some(entity)
    }
  })
  entity_ref.val
}

///|
fn player_movement_system(
  players : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[Player]],
  main_camera_query : @ecs.Query[@ecs.Comp[MainCamera], @ecs.All],
  camera_query : @ecs.Query[@ecs.Comp[@sprite.Camera], @ecs.All],
  projection_query : @ecs.Query[@ecs.Comp[@sprite.Projection], @ecs.All],
  transform_query : @ecs.Query[@ecs.Comp[@transform.Transform], @ecs.All],
  windows : @ecs.Query[
    @ecs.Comp[@window.Window],
    @ecs.With[@window.PrimaryWindow],
  ],
) -> Unit {
  guard main_camera_entity(main_camera_query) is Some(camera_entity) else {
    return
  }
  guard (try! camera_query.get(camera_entity)) is Some(camera_comp) else {
    return
  }
  let camera = camera_comp.value()
  guard (try! projection_query.get(camera_entity)) is Some(projection_comp) else {
    return
  }
  let projection = projection_comp.value()
  guard projection is Orthographic(orthographic_projection) else { return }
  guard (try! transform_query.get(camera_entity)) is Some(camera_transform_comp) else {
    return
  }
  let camera_transform = camera_transform_comp.value()
  guard (try! windows.single()) is Some(window_comp) else { return }
  let window = window_comp.value()
  guard @input.mouse_position() is Some(cursor_position) else { return }

  let window_size = @math.IVec2::new(
    window.width().to_int(),
    window.height().to_int(),
  )
  if window_size.x <= 0 || window_size.y <= 0 {
    return
  }
  guard @sprite_render.render2d_camera_viewport_to_world_2d(
      cursor_position,
      camera,
      orthographic_projection,
      camera_transform,
      window_size,
      window.scale_factor(),
    )
    is Some(cursor_world_pos) else {
    return
  }

  try! players.view(fn(_entity, player) {
    let player_ref = player.get_ref()
    player_ref.val.rotation = @math.Quat::from_rotation_z(
      @math.Vec2::new(
        cursor_world_pos.x - player_ref.val.translation.x,
        cursor_world_pos.y - player_ref.val.translation.y,
      ).to_angle() -
      @math.pi_half(),
    )
  })
}
