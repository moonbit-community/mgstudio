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
/// Port of `bevy/examples/camera/2d_top_down_camera.rs`.

///|
const PLAYER_SPEED : Float = 100.0F

///|
const CAMERA_DECAY_RATE : Float = 2.0F

///|
priv struct TopDownCameraState {
  mut player : @core.Entity
  mut camera : @core.Entity
}

///|
let top_down_camera_state : Ref[TopDownCameraState] = Ref::new(TopDownCameraState::{
  player: @core.Entity::placeholder(),
  camera: @core.Entity::placeholder(),
})

///|
fn setup_scene(world : @ecs.World) -> Unit {
  @sprite.Mesh2dBundle::new(
    @sprite.Mesh2d::from_rectangle(@sprite.Rectangle::new(1000.0F, 700.0F)),
    @sprite.ColorMaterial::new(@sprite.Color::new(0.2F, 0.2F, 0.3F, 1.0F)),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let player = @sprite.Mesh2dBundle::new(
    @sprite.Mesh2d::from_circle(@sprite.Circle::new(25.0F)),
    @sprite.ColorMaterial::new(@sprite.Color::new(6.25F, 9.4F, 9.1F, 1.0F)),
    @math.Transform::from_xyz(0.0F, 0.0F, 2.0F),
  ).spawn(world)
  top_down_camera_state.val.player = player
}

///|
fn spawn_instructions(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let text_handle = @text.Text2dBundle::new(
      @text.Text2d::new(
        "Move the light with WASD.\nThe camera will smoothly track the light.",
      ),
      @text.TextFont::default().with_font(font).with_font_size(24.0F),
      @math.Transform::identity(),
    )
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()

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
    .with_bottom(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(text_entity, @ui.UiText::new(text_handle), tick)
}

///|
fn setup_camera(world : @ecs.World) -> Unit {
  let camera = @sprite.Camera2dBundle::new(
      @sprite.Camera::default(),
      @math.Transform::identity(),
    )
    .with_bloom2d(@sprite.Bloom2d::new())
    .spawn(world)
  top_down_camera_state.val.camera = camera
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in 2d_top_down_camera example")
  }
}

///|
fn move_player(world : @ecs.World) -> Unit {
  let player = top_down_camera_state.val.player
  if player.is_placeholder() {
    return
  }
  let tick = world.read_change_tick()
  let transform_store = @math.get_transform_store(world)
  guard transform_store.get(player) is Some(transform) else { return }

  let direction = @math.Vec2::zero()
  if @input.key_pressed(@window.KeyCode::KeyW) {
    direction.y = direction.y + 1.0F
  }
  if @input.key_pressed(@window.KeyCode::KeyS) {
    direction.y = direction.y - 1.0F
  }
  if @input.key_pressed(@window.KeyCode::KeyA) {
    direction.x = direction.x - 1.0F
  }
  if @input.key_pressed(@window.KeyCode::KeyD) {
    direction.x = direction.x + 1.0F
  }

  let delta_seconds = world_time(world).delta_seconds()
  let move_delta = direction
    .normalize_or_zero()
    .mul_scalar(PLAYER_SPEED * delta_seconds)
  let next_transform = transform.with_translation(
    transform.translation.add(@math.Vec3::new(move_delta.x, move_delta.y, 0.0F)),
  )
  transform_store.set(player, next_transform, tick) |> ignore
}

///|
fn update_camera(world : @ecs.World) -> Unit {
  let player = top_down_camera_state.val.player
  let camera = top_down_camera_state.val.camera
  if player.is_placeholder() || camera.is_placeholder() {
    return
  }
  let tick = world.read_change_tick()
  let transform_store = @math.get_transform_store(world)
  guard transform_store.get(player) is Some(player_transform) else { return }
  guard transform_store.get(camera) is Some(camera_transform) else { return }

  let translation = camera_transform.translation
  let delta_seconds = world_time(world).delta_seconds()
  translation.smooth_nudge(
    @math.Vec3::new(
      player_transform.translation.x,
      player_transform.translation.y,
      camera_transform.translation.z,
    ),
    CAMERA_DECAY_RATE,
    delta_seconds,
  )
  transform_store.set(
    camera,
    camera_transform.with_translation(translation),
    tick,
  )
  |> ignore
}

///|
fn main {
  top_down_camera_state.val.player = @core.Entity::placeholder()
  top_down_camera_state.val.camera = @core.Entity::placeholder()
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup_scene))
  .add_systems(@app.Startup, @app.system(spawn_instructions))
  .add_systems(@app.Startup, @app.system(setup_camera))
  .add_systems(@app.Update, @app.system(move_player))
  .add_systems(@app.Update, @app.system(update_camera))
  .run()
}
