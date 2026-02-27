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
const FIRST_SPRITE_INDEX : Int = 1

///|
const LAST_SPRITE_INDEX : Int = 6

///|
const LEFT_FPS : Float = 10.0F

///|
const RIGHT_FPS : Float = 20.0F

///|
const SPRITE_SCALE : Float = 6.0F

///|
const LEFT_SPRITE_X : Float = -70.0F

///|
const RIGHT_SPRITE_X : Float = 70.0F

///|
priv struct SpriteAnimationState {
  mut left_sprite : @core.Entity
  mut right_sprite : @core.Entity
  mut left_frame_timer : @time.Timer
  mut right_frame_timer : @time.Timer
}

///|
let animation_state : Ref[SpriteAnimationState] = Ref::new(SpriteAnimationState::{
  left_sprite: @core.Entity::placeholder(),
  right_sprite: @core.Entity::placeholder(),
  left_frame_timer: @time.Timer::from_seconds(
    1.0F / LEFT_FPS,
    @time.TimerMode::Once,
  ),
  right_frame_timer: @time.Timer::from_seconds(
    1.0F / RIGHT_FPS,
    @time.TimerMode::Once,
  ),
})

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(sprite_animation_setup)
  .add_system(execute_animations)
  .add_system(trigger_animations)
  .run()
}

///|
fn timer_from_fps(fps : Float) -> @time.Timer {
  @time.Timer::from_seconds(1.0F / fps, @time.TimerMode::Once)
}

///|
fn spawn_help_overlay(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let text_handle = @text.Text2dBundle::new(
      @text.Text2d::new(
        "Left Arrow: Animate Left Sprite\nRight Arrow: Animate Right Sprite",
      ),
      @text.TextFont::default().with_font(font).with_font_size(20.0F),
      @math.Transform::identity(),
    )
    .with_color(@text.TextColor::new(@render2d.Color::white()))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()

  let tick = world.read_change_tick()
  let root = world.spawn_empty()
  world.get_ui_root_store().insert(root, @ui.UiRoot::default(), tick)
  world
  .get_node_store()
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
    tick,
  )

  let text_entity = world.spawn_empty()
  world
  .get_parent_store()
  .insert(text_entity, @hierarchy.Parent::new(root), tick)
  world
  .get_node_store()
  .insert(
    text_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .get_ui_text_store()
  .insert(text_entity, @ui.UiText::new(text_handle), tick)
}

///|
fn spawn_animated_sprite(
  world : @ecs_world.World,
  texture : @asset.Handle[@asset.Image],
  layout : @asset.Handle[@asset.TextureAtlasLayout],
  x : Float,
) -> @core.Entity {
  let sprite = @render2d.Sprite::from_atlas_image(
    texture,
    @asset.TextureAtlas::new(layout, FIRST_SPRITE_INDEX),
  )
  let transform = @math.Transform::identity()
    .with_scale(@math.Vec3::new(SPRITE_SCALE, SPRITE_SCALE, SPRITE_SCALE))
    .with_translation(@math.Vec3::new(x, 0.0F, 0.0F))
  @render2d.SpriteBundle::new(sprite, transform).spawn(world)
}

///|
fn sprite_animation_setup(world : @ecs_world.World) -> Unit {
  animation_state.val.left_sprite = @core.Entity::placeholder()
  animation_state.val.right_sprite = @core.Entity::placeholder()
  animation_state.val.left_frame_timer = timer_from_fps(LEFT_FPS)
  animation_state.val.right_frame_timer = timer_from_fps(RIGHT_FPS)

  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore

  spawn_help_overlay(world)

  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("textures/rpg/chars/gabe/gabe-idle-run.png")
  let layout = @asset.TextureAtlasLayout::from_grid(
    @math.UVec2::new(24, 24),
    7,
    1,
  )
  let layout_handle = @asset.asset_add_texture_atlas_layout(layout)

  let left_sprite = spawn_animated_sprite(
    world,
    texture,
    layout_handle,
    LEFT_SPRITE_X,
  )
  let right_sprite = spawn_animated_sprite(
    world,
    texture,
    layout_handle,
    RIGHT_SPRITE_X,
  )

  animation_state.val.left_sprite = left_sprite
  animation_state.val.right_sprite = right_sprite
}

///|
fn trigger_animations(_world : @ecs_world.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::ArrowLeft) {
    animation_state.val.left_frame_timer = timer_from_fps(LEFT_FPS)
  }

  if @input.key_just_pressed(@window.KeyCode::ArrowRight) {
    animation_state.val.right_frame_timer = timer_from_fps(RIGHT_FPS)
  }
}

///|
fn execute_animation_step(
  world : @ecs_world.World,
  entity : @core.Entity,
  frame_timer : @time.Timer,
  fps : Float,
  delta_seconds : Float,
) -> @time.Timer {
  if entity.is_placeholder() {
    return frame_timer
  }

  let next_timer = frame_timer.tick(delta_seconds)
  if !next_timer.just_finished() {
    return next_timer
  }

  let sprite_store = world.get_sprite_store()
  guard sprite_store.get(entity) is Some(sprite) else { return next_timer }
  guard sprite.texture_atlas is Some(atlas) else { return next_timer }

  let tick = world.read_change_tick()
  if atlas.index == LAST_SPRITE_INDEX {
    let next_atlas = atlas.with_index(FIRST_SPRITE_INDEX)
    sprite_store.set(entity, sprite.with_texture_atlas(Some(next_atlas)), tick)
    |> ignore
    next_timer
  } else {
    let next_atlas = atlas.with_index(atlas.index + 1)
    sprite_store.set(entity, sprite.with_texture_atlas(Some(next_atlas)), tick)
    |> ignore
    timer_from_fps(fps)
  }
}

///|
fn execute_animations(world : @ecs_world.World) -> Unit {
  let delta_seconds = @time.time_delta_seconds()

  animation_state.val.left_frame_timer = execute_animation_step(
    world,
    animation_state.val.left_sprite,
    animation_state.val.left_frame_timer,
    LEFT_FPS,
    delta_seconds,
  )

  animation_state.val.right_frame_timer = execute_animation_step(
    world,
    animation_state.val.right_sprite,
    animation_state.val.right_frame_timer,
    RIGHT_FPS,
    delta_seconds,
  )
}
