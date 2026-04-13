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
const TAU : Float = 6.283185307179586F

///|
const FRAC_PI_2 : Float = 1.5707963267948966F

///|
const LOOP_LENGTH : Float = 4.0F

///|
const CELL_SIZE : Float = 220.0F

///|
const DEFAULT_CONTAINER_SIZE : Float = 150.0F

///|
struct InstructionsText {}

///|
pub(all) enum MotionKind {
  Move
  Scale
  Rotate
} derive(Eq, Debug)

///|
struct AnimationMotion {
  kind : MotionKind
} derive(Eq, Debug)

///|
struct Container {}

///|
struct AnimationState {
  mut paused_at : Float
  mut paused_total : Float
  mut playing : Bool
  mut t : Float
}

///|
struct OverflowDebugSettings {
  mut overflow_index : Int
  mut size_index : Int
}

///|
let instructions_text_key : @ecs.ComponentKey[InstructionsText] = @ecs.register_component(
  debug_name="examples.ui.scroll_and_overflow.overflow_debug.InstructionsText",
)

///|
let animation_motion_key : @ecs.ComponentKey[AnimationMotion] = @ecs.register_component(
  debug_name="examples.ui.scroll_and_overflow.overflow_debug.AnimationMotion",
)

///|
let container_key : @ecs.ComponentKey[Container] = @ecs.register_component(
  debug_name="examples.ui.scroll_and_overflow.overflow_debug.Container",
)

///|
let animation_state_key : @ecs.ResourceKey[AnimationState] = @ecs.register_resource(
  debug_name="examples.ui.scroll_and_overflow.overflow_debug.AnimationState",
)

///|
let overflow_settings_key : @ecs.ResourceKey[OverflowDebugSettings] = @ecs.register_resource(
  debug_name="examples.ui.scroll_and_overflow.overflow_debug.OverflowDebugSettings",
)

///|
pub impl @ecs.Component for InstructionsText with component() {
  instructions_text_key
}

///|
pub impl @ecs.Component for AnimationMotion with component() {
  animation_motion_key
}

///|
pub impl @ecs.Component for Container with component() {
  container_key
}

///|
pub impl @app.Resource for AnimationState with resource() {
  animation_state_key
}

///|
pub impl @app.Resource for OverflowDebugSettings with resource() {
  overflow_settings_key
}

///|
impl Default for AnimationState with default() {
  AnimationState::{
    paused_at: 0.0F,
    paused_total: 0.0F,
    playing: true,
    t: 0.0F,
  }
}

///|
impl Default for OverflowDebugSettings with default() {
  OverflowDebugSettings::{ overflow_index: 3, size_index: 0 }
}

///|
fn max_float(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn container_size(index : Int) -> Float {
  match index % 3 {
    0 => 150.0F
    1 => 110.0F
    _ => 200.0F
  }
}

///|
fn overflow_at(index : Int) -> @ui.Overflow {
  match index % 4 {
    0 => @ui.Overflow::new(@ui.OverflowAxis::Visible, @ui.OverflowAxis::Visible)
    1 => @ui.Overflow::new(@ui.OverflowAxis::Visible, @ui.OverflowAxis::Clip)
    2 => @ui.Overflow::new(@ui.OverflowAxis::Clip, @ui.OverflowAxis::Visible)
    _ => @ui.Overflow::new(@ui.OverflowAxis::Clip, @ui.OverflowAxis::Clip)
  }
}

///|
fn overflow_label(overflow : @ui.Overflow) -> String {
  let axis = fn(value : @ui.OverflowAxis) -> String {
    match value {
      @ui.OverflowAxis::Visible => "Visible"
      @ui.OverflowAxis::Hidden => "Hidden"
      @ui.OverflowAxis::Clip => "Clip"
      @ui.OverflowAxis::Scroll => "Scroll"
    }
  }
  "Overflow(\{axis(overflow.x)}, \{axis(overflow.y)})"
}

///|
fn motion_title(kind : MotionKind) -> String {
  match kind {
    Move => "Move"
    Scale => "Scale"
    Rotate => "Rotate"
  }
}

///|
fn instructions_text(
  settings : OverflowDebugSettings,
  animation : AnimationState,
) -> String {
  let size_text = container_size(settings.size_index).to_string()
  let overflow_text = overflow_label(overflow_at(settings.overflow_index))
  let playing_text = if animation.playing { "Playing" } else { "Paused" }
  "Next Overflow Setting (O)\nNext Container Size (S)\nToggle Animation (Space)\n\n\{overflow_text}\nContainer size: \{size_text} px\nAnimation: \{playing_text}"
}

///|
fn root_node() -> @ui.Node {
  @ui.Node::default()
  .with_width(@ui.Val::Percent(100.0F))
  .with_height(@ui.Val::Percent(100.0F))
}

///|
fn demo_grid_node() -> @ui.Node {
  @ui.Node::default()
  .with_display(@ui.Display::Grid)
  .with_grid_template_columns([
    @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(3), [
      @ui.GridTrack::Px(CELL_SIZE),
    ]),
  ])
  .with_grid_template_rows([
    @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(2), [
      @ui.GridTrack::Px(CELL_SIZE),
    ]),
  ])
  .with_row_gap(@ui.Val::Px(40.0F))
  .with_column_gap(@ui.Val::Px(40.0F))
}

///|
fn demo_cell_node() -> @ui.Node {
  @ui.Node::default()
  .with_width(@ui.Val::Px(CELL_SIZE))
  .with_height(@ui.Val::Px(CELL_SIZE))
  .with_flex_direction(@ui.FlexDirection::Column)
  .with_align_items(@ui.AlignItems::Center)
  .with_justify_content(@ui.JustifyContent::Center)
  .with_row_gap(@ui.Val::Px(12.0F))
}

///|
fn clipped_container_node(size : Float, overflow : @ui.Overflow) -> @ui.Node {
  @ui.Node::default()
  .with_width(@ui.Val::Px(size))
  .with_height(@ui.Val::Px(size))
  .with_align_items(@ui.AlignItems::Center)
  .with_justify_content(@ui.JustifyContent::Center)
  .with_overflow(overflow)
}

///|
fn title_font(font : @asset.Handle[@asset.Font]) -> @text.TextFont {
  @text.TextFont::default().with_font(font).with_font_size(18.0F)
}

///|
fn content_font(font : @asset.Handle[@asset.Font]) -> @text.TextFont {
  @text.TextFont::default().with_font(font).with_font_size(100.0F)
}

///|
fn spawn_demo_cell(
  commands : @app.Commands,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
  motion_kind : MotionKind,
  content : ContentKind,
  image : @asset.Handle[@image.Image],
  overflow : @ui.Overflow,
) -> Unit {
  let cell = commands.spawn((@hierarchy.Parent::new(parent), demo_cell_node()))
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(cell),
        @text.Text::new(
          "\{content_title(content)} / \{motion_title(motion_kind)}",
        ),
        title_font(font),
        @text.TextColor::new(@sprite.Color::white()),
      ),
    ),
  )
  let clipped = commands.spawn(
    (
      @hierarchy.Parent::new(cell),
      Container::{  },
      clipped_container_node(DEFAULT_CONTAINER_SIZE, overflow),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.25F, 0.25F, 0.25F)),
    ),
  )
  match content {
    Image =>
      ignore(
        commands.spawn(
          (
            @hierarchy.Parent::new(clipped),
            AnimationMotion::{ kind: motion_kind },
            @transform.Transform::identity(),
            @ui.Node::default()
            .with_width(@ui.Val::Px(360.0F))
            .with_height(@ui.Val::Px(120.0F)),
            @ui.ImageNode::new(image),
          ),
        ),
      )
    Text =>
      ignore(
        commands.spawn(
          (
            @hierarchy.Parent::new(clipped),
            AnimationMotion::{ kind: motion_kind },
            @transform.Transform::identity(),
            @text.Text::new("Bevy"),
            content_font(font),
            @text.TextColor::new(@sprite.Color::white()),
          ),
        ),
      )
  }
}

///|
pub(all) enum ContentKind {
  Image
  Text
} derive(Eq, Debug)

///|
fn content_title(content : ContentKind) -> String {
  match content {
    Image => "Image"
    Text => "Text"
  }
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default())),
  )

  commands.insert_resource(AnimationState::default())
  commands.insert_resource(OverflowDebugSettings::default())

  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let image = asset_server.get().load_image("branding/bevy_logo_dark_big.png")
  let overflow = overflow_at(OverflowDebugSettings::default().overflow_index)

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      root_node(),
      @ui.BackgroundColor::new(@sprite.Color::black()),
    ),
  )

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        InstructionsText::{  },
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.Val::Px(12.0F))
        .with_left(@ui.Val::Px(12.0F)),
        @text.Text::new(
          instructions_text(
            OverflowDebugSettings::default(),
            AnimationState::default(),
          ),
        ),
        @text.TextFont::default().with_font(font).with_font_size(20.0F),
        @text.TextColor::new(@sprite.Color::white()),
      ),
    ),
  )

  let center = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center),
    ),
  )
  let grid = commands.spawn((@hierarchy.Parent::new(center), demo_grid_node()))
  spawn_demo_cell(
    commands,
    grid,
    font,
    MotionKind::Move,
    ContentKind::Image,
    image,
    overflow,
  )
  spawn_demo_cell(
    commands,
    grid,
    font,
    MotionKind::Scale,
    ContentKind::Image,
    image,
    overflow,
  )
  spawn_demo_cell(
    commands,
    grid,
    font,
    MotionKind::Rotate,
    ContentKind::Image,
    image,
    overflow,
  )
  spawn_demo_cell(
    commands,
    grid,
    font,
    MotionKind::Move,
    ContentKind::Text,
    image,
    overflow,
  )
  spawn_demo_cell(
    commands,
    grid,
    font,
    MotionKind::Scale,
    ContentKind::Text,
    image,
    overflow,
  )
  spawn_demo_cell(
    commands,
    grid,
    font,
    MotionKind::Rotate,
    ContentKind::Text,
    image,
    overflow,
  )
}

///|
fn update_controls(
  keyboard : @input.ButtonInput[@window.KeyCode],
  state : @app.ResMut[AnimationState],
  settings : @app.ResMut[OverflowDebugSettings],
) -> Unit {
  let state_ref = state.get_ref()
  let settings_ref = settings.get_ref()
  if keyboard.just_pressed(@window.KeyCode::Space) {
    state_ref.val.playing = !state_ref.val.playing
    if !state_ref.val.playing {
      state_ref.val.paused_at = state_ref.val.t * LOOP_LENGTH
    }
  }
  if keyboard.just_pressed(@window.KeyCode::KeyO) {
    settings_ref.val.overflow_index = settings_ref.val.overflow_index + 1
  }
  if keyboard.just_pressed(@window.KeyCode::KeyS) {
    settings_ref.val.size_index = settings_ref.val.size_index + 1
  }
}

///|
fn update_animation(
  state : @app.ResMut[AnimationState],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let state_ref = state.get_ref()
  if state_ref.val.playing {
    state_ref.val.t = (time.get().elapsed_secs() - state_ref.val.paused_total) %
      LOOP_LENGTH /
      LOOP_LENGTH
  } else {
    state_ref.val.paused_total = time.get().elapsed_secs() -
      state_ref.val.paused_at
    state_ref.val.t = state_ref.val.paused_at / LOOP_LENGTH
  }
}

///|
fn update_motion_transforms(
  motions : @ecs.Query[
    (@ecs.Comp[AnimationMotion], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
  state : @app.Res[AnimationState],
) -> Unit {
  let t = state.get().t
  try! motions.view(fn(_entity, data) {
    let (motion, transform) = data
    let next = match motion.value().kind {
      Move =>
        @transform.Transform::from_xy_rotation_scale(
          @math.Vec2::new(
            @math.sin(t * TAU - FRAC_PI_2) * 75.0F,
            -@math.cos(t * TAU - FRAC_PI_2) * 75.0F,
          ),
          0.0F,
          @math.Vec2::new(1.0F, 1.0F),
        )
      Scale =>
        @transform.Transform::from_xy_rotation_scale(
          @math.Vec2::new(0.0F, 0.0F),
          0.0F,
          @math.Vec2::new(
            1.0F + 0.5F * max_float(@math.cos(t * TAU), 0.0F),
            1.0F +
            0.5F * max_float(@math.cos(t * TAU + 3.141592653589793F), 0.0F),
          ),
        )
      Rotate =>
        @transform.Transform::from_xy_rotation_scale(
          @math.Vec2::new(0.0F, 0.0F),
          @math.cos(t * TAU) * 0.7853981633974483F,
          @math.Vec2::new(1.0F, 1.0F),
        )
    }
    transform.set(next)
  })
}

///|
fn apply_container_settings(
  containers : @ecs.Query[@ecs.Mut[@ui.Node], @ecs.With[Container]],
  settings : @app.Res[OverflowDebugSettings],
) -> Unit {
  let overflow = overflow_at(settings.get().overflow_index)
  let size = container_size(settings.get().size_index)
  try! containers.view(fn(_entity, node) {
    let current = node.value()
    node.set(@ui.Node::{
      ..current,
      width: @ui.Val::Px(size),
      height: @ui.Val::Px(size),
      overflow,
    })
  })
}

///|
fn update_instructions(
  text : @app.Single[@ecs.Mut[@text.Text], @ecs.With[InstructionsText]],
  settings : @app.Res[OverflowDebugSettings],
  state : @app.Res[AnimationState],
) -> Unit {
  text
  .get()
  .set(@text.Text::new(instructions_text(settings.get(), state.get())))
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param3(update_controls)))
  .add_systems(@app.Update, @app.system(@app.system_param2(update_animation)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(update_motion_transforms)),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(apply_container_settings)),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(update_instructions)),
  )
  .run()
}
