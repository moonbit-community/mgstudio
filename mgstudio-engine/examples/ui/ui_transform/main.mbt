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
const MOVE_SPEED : Float = 180.0F

///|
const TRANSLATION_LIMIT : Float = 150.0F

///|
const SCALE_MIN : Float = 0.25F

///|
const SCALE_MAX : Float = 3.0F

///|
const ROTATION_STEP : Float = 0.39269908169872414F

///|
const SCALE_STEP : Float = 0.25F

///|
struct RotateButton {
  step : Float
}

///|
struct ScaleButton {
  delta : Float
}

///|
struct TargetNode {}

///|
struct ControlButton {}

///|
struct ButtonPressState {
  pressed : Bool
} derive(Eq, Show)

///|
let rotate_button_key : @ecs.ComponentKey[RotateButton] = @ecs.register_component(
  debug_name="examples.ui.ui_transform.RotateButton",
)

///|
let scale_button_key : @ecs.ComponentKey[ScaleButton] = @ecs.register_component(
  debug_name="examples.ui.ui_transform.ScaleButton",
)

///|
let target_node_key : @ecs.ComponentKey[TargetNode] = @ecs.register_component(
  debug_name="examples.ui.ui_transform.TargetNode",
)

///|
let control_button_key : @ecs.ComponentKey[ControlButton] = @ecs.register_component(
  debug_name="examples.ui.ui_transform.ControlButton",
)

///|
let button_press_state_key : @ecs.ComponentKey[ButtonPressState] = @ecs.register_component(
  debug_name="examples.ui.ui_transform.ButtonPressState",
)

///|
pub impl @ecs.Component for RotateButton with component() {
  rotate_button_key
}

///|
pub impl @ecs.Component for ScaleButton with component() {
  scale_button_key
}

///|
pub impl @ecs.Component for TargetNode with component() {
  target_node_key
}

///|
pub impl @ecs.Component for ControlButton with component() {
  control_button_key
}

///|
pub impl @ecs.Component for ButtonPressState with component() {
  button_press_state_key
}

///|
fn clamp_float(value : Float, min : Float, max : Float) -> Float {
  if value < min {
    min
  } else if value > max {
    max
  } else {
    value
  }
}

///|
fn normal_button_color() -> @sprite.Color {
  @sprite.Color::white()
}

///|
fn hovered_button_color() -> @sprite.Color {
  @sprite.Color::srgb(1.0F, 1.0F, 0.35F)
}

///|
fn pressed_button_color() -> @sprite.Color {
  @sprite.Color::srgb(1.0F, 0.2F, 0.2F)
}

///|
fn text_color() -> @sprite.Color {
  @sprite.Color::black()
}

///|
fn button_node() -> @ui.Node {
  @ui.Node::default()
  .with_width(@ui.Val::Px(80.0F))
  .with_height(@ui.Val::Px(80.0F))
  .with_align_items(@ui.AlignItems::Center)
  .with_justify_content(@ui.JustifyContent::Center)
}

///|
fn control_column_node() -> @ui.Node {
  @ui.Node::default()
  .with_flex_direction(@ui.FlexDirection::Column)
  .with_justify_content(@ui.JustifyContent::Center)
  .with_row_gap(@ui.Val::Px(10.0F))
}

///|
fn button_text_font(font : @asset.Handle[@asset.Font]) -> @text.TextFont {
  @text.TextFont::default().with_font(font).with_font_size(33.0F)
}

///|
fn button_transform(angle : Float) -> @transform.Transform {
  @transform.Transform::from_xy_rotation_scale(
    @math.Vec2::new(0.0F, 0.0F),
    angle,
    @math.Vec2::new(1.0F, 1.0F),
  )
}

///|
fn spawn_button_label(
  commands : @app.Commands,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
  text : String,
) -> Unit {
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(parent),
        @text.Text::new(text),
        button_text_font(font),
        @text.TextColor::new(text_color()),
      ),
    ),
  )
}

///|
fn spawn_control_button(
  commands : @app.Commands,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
  label : String,
  rotate_step? : Float = 0.0F,
  scale_delta? : Float = 0.0F,
) -> Unit {
  let button = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @ui.Button::default(),
      ControlButton::{  },
      ButtonPressState::{ pressed: false },
      button_node(),
      @ui.BackgroundColor::new(normal_button_color()),
      @ui.BorderColor::new(@sprite.Color::black()),
      @ui.BorderRadius::all(@ui.Val::Percent(100.0F)),
    ),
  )
  if rotate_step != 0.0F {
    commands
    .entity(button)
    .insert_component(RotateButton::{ step: rotate_step })
  }
  if scale_delta != 0.0F {
    commands
    .entity(button)
    .insert_component(ScaleButton::{ delta: scale_delta })
  }
  spawn_button_label(commands, button, font, label)
}

///|
fn spawn_static_panel_button(
  commands : @app.Commands,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
  label : String,
  angle : Float,
) -> Unit {
  let entity = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      button_node(),
      @ui.BackgroundColor::new(@sprite.Color::white()),
      button_transform(angle),
    ),
  )
  spawn_button_label(commands, entity, font, label)
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default())),
  )

  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let icon = asset_server.get().load_image("branding/icon.png")

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @transform.Transform::identity(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center),
      @ui.BackgroundColor::new(@sprite.Color::black()),
    ),
  )

  let content = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::SpaceEvenly)
      .with_column_gap(@ui.Val::Px(25.0F)),
    ),
  )

  let left_column = commands.spawn(
    (@hierarchy.Parent::new(content), control_column_node()),
  )
  spawn_control_button(
    commands,
    left_column,
    font,
    "<--",
    rotate_step=-ROTATION_STEP,
  )
  spawn_control_button(
    commands,
    left_column,
    font,
    "-",
    scale_delta=-SCALE_STEP,
  )

  let target = commands.spawn(
    (
      @hierarchy.Parent::new(content),
      TargetNode::{  },
      @transform.Transform::identity(),
      @ui.Node::default()
      .with_width(@ui.Val::Px(300.0F))
      .with_height(@ui.Val::Px(300.0F))
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_justify_content(@ui.JustifyContent::SpaceBetween)
      .with_align_items(@ui.AlignItems::Center),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.33F, 0.33F, 0.33F)),
    ),
  )

  spawn_static_panel_button(commands, target, font, "Top", 0.0F)

  let middle_row = commands.spawn(
    (
      @hierarchy.Parent::new(target),
      @ui.Node::{
        ..@ui.Node::default()
        .with_justify_content(@ui.JustifyContent::SpaceBetween)
        .with_align_items(@ui.AlignItems::Center),
        align_self: @ui.AlignSelf::Stretch,
      },
    ),
  )
  spawn_static_panel_button(
    commands,
    middle_row,
    font,
    "Left",
    -1.5707963267948966F,
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(middle_row),
        @ui.Node::default()
        .with_width(@ui.Val::Px(100.0F))
        .with_height(@ui.Val::Px(100.0F)),
        @ui.ImageNode::new(icon),
      ),
    ),
  )
  spawn_static_panel_button(
    commands, middle_row, font, "Right", 1.5707963267948966F,
  )

  spawn_static_panel_button(
    commands, target, font, "Bottom", 3.141592653589793F,
  )

  let right_column = commands.spawn(
    (@hierarchy.Parent::new(content), control_column_node()),
  )
  spawn_control_button(
    commands,
    right_column,
    font,
    "-->",
    rotate_step=ROTATION_STEP,
  )
  spawn_control_button(
    commands,
    right_column,
    font,
    "+",
    scale_delta=SCALE_STEP,
  )
}

///|
fn interaction_color(interaction : @ui.Interaction) -> @sprite.Color {
  match interaction {
    Pressed => pressed_button_color()
    Hovered => hovered_button_color()
    None => normal_button_color()
  }
}

///|
fn button_system(world : @ecs.World) -> Unit {
  let mut target_transform : @ecs.Mut[@transform.Transform]? = None
  world.for_each_component(target_node_key, fn(entity, _target) {
    if target_transform is None {
      target_transform = try! world.get_mut(
        entity,
        key=@transform.Transform::component(),
      )
    }
  })
  world.for_each_component(@ui.ecs_key_interaction, fn(entity, interaction) {
    guard (try! world.contains_by_key(entity, control_button_key)) else {
      return
    }
    let entity_mut = try! world.entity_mut(entity)
    if (try! entity_mut.get_mut(key=@ui.ecs_key_background_color))
      is Some(background) {
      background.set(@ui.BackgroundColor::new(interaction_color(interaction)))
    }
    guard (try! entity_mut.get_mut(key=button_press_state_key))
      is Some(button_state) else {
      return
    }
    let is_pressed = interaction == @ui.Interaction::Pressed
    let was_pressed = button_state.value().pressed
    if is_pressed && !was_pressed {
      if target_transform is Some(transform) {
        let transform_ref = transform.get_ref()
        if (try! world.get_by_key(entity, rotate_button_key))
          is Some(rotate_button) {
          transform_ref.val.rotate_z(rotate_button.step)
        }
        if (try! world.get_by_key(entity, scale_button_key))
          is Some(scale_button) {
          let next_x = clamp_float(
            transform_ref.val.scale.x + scale_button.delta,
            SCALE_MIN,
            SCALE_MAX,
          )
          let next_y = clamp_float(
            transform_ref.val.scale.y + scale_button.delta,
            SCALE_MIN,
            SCALE_MAX,
          )
          transform_ref.val.scale = @math.Vec3::new(
            next_x,
            next_y,
            transform_ref.val.scale.z,
          )
        }
      }
    }
    button_state.set(ButtonPressState::{ pressed: is_pressed })
  })
}

///|
fn translation_system(
  keyboard : @input.ButtonInput[@window.KeyCode],
  time : @app.Res[@time.Time[Unit]],
  target : @app.Single[@ecs.Mut[@transform.Transform], @ecs.With[TargetNode]],
) -> Unit {
  let mut dx = 0.0F
  let mut dy = 0.0F
  if keyboard.pressed(@window.KeyCode::ArrowLeft) {
    dx -= MOVE_SPEED * time.get().delta_seconds()
  }
  if keyboard.pressed(@window.KeyCode::ArrowRight) {
    dx += MOVE_SPEED * time.get().delta_seconds()
  }
  if keyboard.pressed(@window.KeyCode::ArrowUp) {
    dy -= MOVE_SPEED * time.get().delta_seconds()
  }
  if keyboard.pressed(@window.KeyCode::ArrowDown) {
    dy += MOVE_SPEED * time.get().delta_seconds()
  }
  if dx == 0.0F && dy == 0.0F {
    return
  }
  let target_transform = target.get()
  let transform_ref = target_transform.get_ref()
  transform_ref.val.translation.x = clamp_float(
    transform_ref.val.translation.x + dx,
    -TRANSLATION_LIMIT,
    TRANSLATION_LIMIT,
  )
  transform_ref.val.translation.y = clamp_float(
    transform_ref.val.translation.y + dy,
    -TRANSLATION_LIMIT,
    TRANSLATION_LIMIT,
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(button_system))
  .add_systems(@app.Update, @app.system(@app.system_param3(translation_system)))
  .run()
}
