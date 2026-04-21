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
const OVERRIDE_BUTTON_WIDTH : Float = 156.0F

///|
const OVERRIDE_BUTTON_HEIGHT : Float = 86.0F

///|
fn override_normal_color() -> @sprite.Color {
  @sprite.Color::srgb(0.72F, 0.34F, 0.32F)
}

///|
fn override_active_color() -> @sprite.Color {
  @sprite.Color::srgb(0.29F, 0.66F, 0.43F)
}

///|
fn override_focus_color() -> @sprite.Color {
  @sprite.Color::white()
}

///|
fn override_idle_border() -> @sprite.Color {
  @sprite.Color::srgb(0.08F, 0.08F, 0.08F)
}

///|
struct OverrideButton {
  label : String
}

///|
struct OverrideState {
  active : Bool
}

///|
struct OverrideFocusDisplay {}

///|
struct OverrideLastInputDisplay {}

///|
struct OverrideStatus {
  mut label : String
}

///|
let override_button_key : @ecs.ComponentKey[OverrideButton] = @ecs.register_component(
  debug_name="examples.ui.navigation.directional_navigation_overrides.OverrideButton",
)

///|
let override_state_key : @ecs.ComponentKey[OverrideState] = @ecs.register_component(
  debug_name="examples.ui.navigation.directional_navigation_overrides.OverrideState",
)

///|
let override_focus_display_key : @ecs.ComponentKey[OverrideFocusDisplay] = @ecs.register_component(
  debug_name="examples.ui.navigation.directional_navigation_overrides.OverrideFocusDisplay",
)

///|
let override_last_input_display_key : @ecs.ComponentKey[
  OverrideLastInputDisplay,
] = @ecs.register_component(
  debug_name="examples.ui.navigation.directional_navigation_overrides.OverrideLastInputDisplay",
)

///|
let override_status_key : @ecs.ResourceKey[OverrideStatus] = @ecs.register_resource(
  debug_name="examples.ui.navigation.directional_navigation_overrides.OverrideStatus",
)

///|
pub impl @ecs.Component for OverrideButton with component() {
  override_button_key
}

///|
pub impl @ecs.Component for OverrideState with component() {
  override_state_key
}

///|
pub impl @ecs.Component for OverrideFocusDisplay with component() {
  override_focus_display_key
}

///|
pub impl @ecs.Component for OverrideLastInputDisplay with component() {
  override_last_input_display_key
}

///|
pub impl @app.Resource for OverrideStatus with resource() {
  override_status_key
}

///|
fn override_button_node(left : Float, top : Float) -> @ui.Node {
  @ui.Node::default()
  .with_position_type(@ui.PositionType::Absolute)
  .with_left(@ui.Val::Px(left))
  .with_top(@ui.Val::Px(top))
  .with_width(@ui.Val::Px(OVERRIDE_BUTTON_WIDTH))
  .with_height(@ui.Val::Px(OVERRIDE_BUTTON_HEIGHT))
  .with_border(@ui.UiRect::all(@ui.Val::Px(4.0F)))
  .with_align_items(@ui.AlignItems::Center)
  .with_justify_content(@ui.JustifyContent::Center)
}

///|
fn override_font(
  font : @asset.Handle[@asset.Font],
  size : Float,
) -> @text.TextFont {
  @text.TextFont::default().with_font(font).with_font_size(size)
}

///|
fn override_status_node(bottom : Float) -> @ui.Node {
  @ui.Node::default()
  .with_position_type(@ui.PositionType::Absolute)
  .with_left(@ui.Val::Px(24.0F))
  .with_bottom(@ui.Val::Px(bottom))
  .with_width(@ui.Val::Px(340.0F))
  .with_padding(@ui.UiRect::all(@ui.Val::Px(12.0F)))
}

///|
fn spawn_override_button(
  commands : @app.Commands,
  root : @core.Entity,
  font : @asset.Handle[@asset.Font],
  label : String,
  left : Float,
  top : Float,
) -> @core.Entity {
  let button = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Button::default(),
      @ui.AutoDirectionalNavigation::default(),
      OverrideButton::{ label, },
      OverrideState::{ active: false },
      override_button_node(left, top),
      @ui.BackgroundColor::new(override_normal_color()),
      @ui.BorderColor::new(override_idle_border()),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(button),
        @text.Text::new(label),
        override_font(font, 22.0F),
        @text.TextColor::new(@sprite.Color::white()),
      ),
    ),
  )
  ignore(
    commands
    .entity(button)
    .observe_pointer4(fn(
      _pointer : @app.OnPointer[@app.PointerClick],
      focus : @app.ResMut[@input_focus.InputFocus],
      buttons : @ecs.Query[@ecs.Mut[OverrideState], @ecs.With[OverrideState]],
      status : @app.ResMut[OverrideStatus],
    ) {
      focus.modify(fn(value) { value.set(button) })
      let state : @ecs.Mut[OverrideState]? = try buttons.get(button) catch {
        _ => None
      } noraise {
        value => value
      }
      if state is Some(state) {
        state.set(OverrideState::{ active: !state.value().active })
      }
      status.modify(fn(value) { value.label = "Last Input: Pointer Click" })
    }),
  )
  button
}

///|
fn setup_override_ui(
  commands : @app.Commands,
  focus : @app.ResMut[@input_focus.InputFocus],
  nav_map : @app.ResMut[@input_focus.DirectionalNavigationMap],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default())),
  )

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
        @text.Text::new(
          "Directional Navigation Overrides\n\nThe two button islands are too far apart for automatic navigation.\nManual edges bridge the middle buttons and loop the top and bottom buttons.",
        ),
        override_font(font, 18.0F),
        @text.TextColor::new(@sprite.Color::white()),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_left(@ui.Val::Px(24.0F))
        .with_top(@ui.Val::Px(24.0F))
        .with_width(@ui.Val::Px(360.0F))
        .with_padding(@ui.UiRect::all(@ui.Val::Px(12.0F))),
        @ui.BackgroundColor::new(
          @sprite.Color::srgba(0.08F, 0.08F, 0.08F, 0.82F),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        OverrideFocusDisplay::{  },
        @text.Text::new("Focused: None"),
        override_font(font, 20.0F),
        @text.TextColor::new(@sprite.Color::white()),
        override_status_node(88.0F),
        @ui.BackgroundColor::new(
          @sprite.Color::srgba(0.10F, 0.45F, 0.18F, 0.82F),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        OverrideLastInputDisplay::{  },
        @text.Text::new("Last Input: None"),
        override_font(font, 20.0F),
        @text.TextColor::new(@sprite.Color::white()),
        override_status_node(24.0F),
        @ui.BackgroundColor::new(
          @sprite.Color::srgba(0.38F, 0.16F, 0.52F, 0.82F),
        ),
      ),
    ),
  )

  let left_buttons = [
    spawn_override_button(commands, root, font, "Left Top", 300.0F, 150.0F),
    spawn_override_button(commands, root, font, "Left Mid", 300.0F, 284.0F),
    spawn_override_button(commands, root, font, "Left Bottom", 300.0F, 418.0F),
  ]
  let right_buttons = [
    spawn_override_button(commands, root, font, "Right Top", 730.0F, 150.0F),
    spawn_override_button(commands, root, font, "Right Mid", 730.0F, 284.0F),
    spawn_override_button(commands, root, font, "Right Bottom", 730.0F, 418.0F),
  ]

  nav_map.modify(fn(value) {
    value.add_edge(left_buttons[0], left_buttons[2], @math.CompassOctant::North)
    value.add_edge(left_buttons[2], left_buttons[0], @math.CompassOctant::South)
    value.add_edge(
      right_buttons[0],
      right_buttons[2],
      @math.CompassOctant::North,
    )
    value.add_edge(
      right_buttons[2],
      right_buttons[0],
      @math.CompassOctant::South,
    )
    value.add_symmetrical_edge(
      left_buttons[1],
      right_buttons[1],
      @math.CompassOctant::East,
    )
  })
  focus.modify(fn(value) { value.set(left_buttons[0]) })
}

///|
fn override_direction_from_gamepads(
  gamepads : @ecs.Query[@ecs.Comp[@input.Gamepad], @ecs.All],
) -> @math.CompassOctant? {
  let result : Ref[@math.CompassOctant?] = Ref::new(None)
  try! gamepads.view(fn(_entity, gamepad) {
    if result.val is Some(_) {
      return
    }
    let value = gamepad.value()
    if value.just_pressed(@input.GamepadButton::DPadUp) {
      result.val = Some(@math.CompassOctant::North)
    } else if value.just_pressed(@input.GamepadButton::DPadDown) {
      result.val = Some(@math.CompassOctant::South)
    } else if value.just_pressed(@input.GamepadButton::DPadLeft) {
      result.val = Some(@math.CompassOctant::West)
    } else if value.just_pressed(@input.GamepadButton::DPadRight) {
      result.val = Some(@math.CompassOctant::East)
    }
  })
  result.val
}

///|
fn override_direction_text(direction : @math.CompassOctant) -> String {
  match direction {
    North => "North"
    NorthEast => "NorthEast"
    East => "East"
    SouthEast => "SouthEast"
    South => "South"
    SouthWest => "SouthWest"
    West => "West"
    NorthWest => "NorthWest"
  }
}

///|
fn navigate_override_ui(
  navigator : @ui.AutoDirectionalNavigator,
  gamepads : @ecs.Query[@ecs.Comp[@input.Gamepad], @ecs.All],
  status : @app.ResMut[OverrideStatus],
) -> Unit {
  let direction = if @input.key_just_pressed(@window.KeyCode::ArrowUp) {
    Some(@math.CompassOctant::North)
  } else if @input.key_just_pressed(@window.KeyCode::ArrowDown) {
    Some(@math.CompassOctant::South)
  } else if @input.key_just_pressed(@window.KeyCode::ArrowLeft) {
    Some(@math.CompassOctant::West)
  } else if @input.key_just_pressed(@window.KeyCode::ArrowRight) {
    Some(@math.CompassOctant::East)
  } else {
    override_direction_from_gamepads(gamepads)
  }
  guard direction is Some(direction) else { return }
  let next_focus = try navigator.navigate(direction) catch {
    _ => None
  } noraise {
    value => Some(value)
  }
  status.modify(fn(value) {
    value.label = if next_focus is Some(_) {
      "Last Input: Navigate \{override_direction_text(direction)}"
    } else {
      "Last Input: Blocked \{override_direction_text(direction)}"
    }
  })
}

///|
fn override_activate_from_gamepads(
  gamepads : @ecs.Query[@ecs.Comp[@input.Gamepad], @ecs.All],
) -> Bool {
  let pressed = Ref::new(false)
  try! gamepads.view(fn(_entity, gamepad) {
    if pressed.val {
      return
    }
    if gamepad.value().just_pressed(@input.GamepadButton::South) {
      pressed.val = true
    }
  })
  pressed.val
}

///|
fn activate_override_button(world : @ecs.World) -> Unit {
  let activate = @input.key_just_pressed(@window.KeyCode::Enter) ||
    @input.key_just_pressed(@window.KeyCode::Space) ||
    override_activate_from_gamepads(@ecs.query(world))
  if !activate {
    return
  }
  let focused = match
    (try! world.get_resource(@input_focus.InputFocus::resource())) {
    Some(focus) => focus.get()
    None => None
  }
  guard focused is Some(entity) else { return }
  let state_query : @ecs.Query[
    @ecs.Mut[OverrideState],
    @ecs.With[OverrideState],
  ] = @ecs.query_filtered(world, @ecs.With::new(OverrideState::component()))
  let label_query : @ecs.Query[
    @ecs.Comp[OverrideButton],
    @ecs.With[OverrideButton],
  ] = @ecs.query_filtered(world, @ecs.With::new(OverrideButton::component()))
  let status_ref = match
    (try! world.get_resource_mut(OverrideStatus::resource())) {
    Some(status_ref) => status_ref
    None => return
  }
  let state : @ecs.Mut[OverrideState]? = try state_query.get(entity) catch {
    _ => None
  } noraise {
    value => value
  }
  let label : @ecs.Comp[OverrideButton]? = try label_query.get(entity) catch {
    _ => None
  } noraise {
    value => value
  }
  if state is Some(state) {
    state.set(OverrideState::{ active: !state.value().active })
    let button_label = match label {
      Some(label) => label.value().label
      None => "Unknown"
    }
    status_ref.modify(fn(value) {
      value.label = "Last Input: Activate \{button_label}"
    })
  }
}

///|
fn update_override_focus_display(world : @ecs.World) -> Unit {
  let focused = match
    (try! world.get_resource(@input_focus.InputFocus::resource())) {
    Some(focus) => focus.get()
    None => None
  }
  let label_query : @ecs.Query[
    @ecs.Comp[OverrideButton],
    @ecs.With[OverrideButton],
  ] = @ecs.query_filtered(world, @ecs.With::new(OverrideButton::component()))
  let display_query : @ecs.Query[
    @ecs.Mut[@text.Text],
    @ecs.With[OverrideFocusDisplay],
  ] = @ecs.query_filtered(
    world,
    @ecs.With::new(OverrideFocusDisplay::component()),
  )
  let label = match focused {
    Some(entity) =>
      match
        (try label_query.get(entity) catch {
          _ => None
        } noraise {
          value => value
        }) {
        Some(button) => button.value().label
        None => "Unknown"
      }
    None => "None"
  }
  try! display_query.view(fn(_entity, text) {
    text.set(@text.Text::new("Focused: \{label}"))
  })
}

///|
fn update_override_last_input_display(world : @ecs.World) -> Unit {
  let label = match (try! world.get_resource(OverrideStatus::resource())) {
    Some(status) => status.label
    None => "Last Input: None"
  }
  let display_query : @ecs.Query[
    @ecs.Mut[@text.Text],
    @ecs.With[OverrideLastInputDisplay],
  ] = @ecs.query_filtered(
    world,
    @ecs.With::new(OverrideLastInputDisplay::component()),
  )
  try! display_query.view(fn(_entity, text) { text.set(@text.Text::new(label)) })
}

///|
fn update_override_button_visuals(world : @ecs.World) -> Unit {
  let focused = match
    (try! world.get_resource(@input_focus.InputFocus::resource())) {
    Some(focus) => focus.get()
    None => None
  }
  let query : @ecs.Query[
    (@core.Entity, @ecs.Mut[@ui.BackgroundColor], @ecs.Mut[@ui.BorderColor]),
    @ecs.With[OverrideButton],
  ] = @ecs.query_filtered(world, @ecs.With::new(OverrideButton::component()))
  try! query.view(fn(_query_entity, data) {
    let (entity, background, border) = data
    let state : OverrideState? = try world.entity(entity).get() catch {
      _ => None
    } noraise {
      value => value
    }
    background.set(
      @ui.BackgroundColor::new(
        if state is Some(state) && state.active {
          override_active_color()
        } else {
          override_normal_color()
        },
      ),
    )
    border.set(
      @ui.BorderColor::new(
        if focused == Some(entity) {
          override_focus_color()
        } else {
          override_idle_border()
        },
      ),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_plugins(@input_focus.InputDispatchPlugin::default())
  .add_plugins(@input_focus.DirectionalNavigationPlugin::default())
  .insert_resource(OverrideStatus::{ label: "Last Input: None" })
  .insert_resource(
    @input_focus.AutoNavigationConfig::new(0.1F, Some(200.0F), true),
  )
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup_override_ui)))
  .add_systems(
    @app.PreUpdate,
    @app.system(@app.system_param3(navigate_override_ui)),
  )
  .add_systems(@app.PreUpdate, @app.system(activate_override_button))
  .add_systems(@app.Update, @app.system(update_override_focus_display))
  .add_systems(@app.Update, @app.system(update_override_last_input_display))
  .add_systems(@app.Update, @app.system(update_override_button_visuals))
  .run()
}
