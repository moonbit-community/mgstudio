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
const BUTTON_WIDTH : Float = 140.0F

///|
const BUTTON_HEIGHT : Float = 80.0F

///|
fn nav_normal_color() -> @sprite.Color {
  @sprite.Color::srgb(0.23F, 0.45F, 0.88F)
}

///|
fn nav_active_color() -> @sprite.Color {
  @sprite.Color::srgb(0.24F, 0.72F, 0.44F)
}

///|
fn nav_focus_color() -> @sprite.Color {
  @sprite.Color::white()
}

///|
fn nav_idle_border() -> @sprite.Color {
  @sprite.Color::srgb(0.08F, 0.08F, 0.08F)
}

///|
struct NavButton {
  label : String
}

///|
struct ActivatedButton {
  active : Bool
}

///|
struct FocusDisplay {}

///|
struct LastInputDisplay {}

///|
struct NavigationStatus {
  mut label : String
}

///|
let nav_button_key : @ecs.ComponentKey[NavButton] = @ecs.register_component(
  debug_name="examples.ui.navigation.directional_navigation.NavButton",
)

///|
let activated_button_key : @ecs.ComponentKey[ActivatedButton] = @ecs.register_component(
  debug_name="examples.ui.navigation.directional_navigation.ActivatedButton",
)

///|
let focus_display_key : @ecs.ComponentKey[FocusDisplay] = @ecs.register_component(
  debug_name="examples.ui.navigation.directional_navigation.FocusDisplay",
)

///|
let last_input_display_key : @ecs.ComponentKey[LastInputDisplay] = @ecs.register_component(
  debug_name="examples.ui.navigation.directional_navigation.LastInputDisplay",
)

///|
let navigation_status_key : @ecs.ResourceKey[NavigationStatus] = @ecs.register_resource(
  debug_name="examples.ui.navigation.directional_navigation.NavigationStatus",
)

///|
pub impl @ecs.Component for NavButton with component() {
  nav_button_key
}

///|
pub impl @ecs.Component for ActivatedButton with component() {
  activated_button_key
}

///|
pub impl @ecs.Component for FocusDisplay with component() {
  focus_display_key
}

///|
pub impl @ecs.Component for LastInputDisplay with component() {
  last_input_display_key
}

///|
pub impl @app.Resource for NavigationStatus with resource() {
  navigation_status_key
}

///|
fn button_node(left : Float, top : Float) -> @ui.Node {
  @ui.Node::default()
  .with_position_type(@ui.PositionType::Absolute)
  .with_left(@ui.Val::Px(left))
  .with_top(@ui.Val::Px(top))
  .with_width(@ui.Val::Px(BUTTON_WIDTH))
  .with_height(@ui.Val::Px(BUTTON_HEIGHT))
  .with_border(@ui.UiRect::all(@ui.Val::Px(4.0F)))
  .with_align_items(@ui.AlignItems::Center)
  .with_justify_content(@ui.JustifyContent::Center)
}

///|
fn text_font(font : @asset.Handle[@asset.Font], size : Float) -> @text.TextFont {
  @text.TextFont::default().with_font(font).with_font_size(size)
}

///|
fn status_node(bottom : Float) -> @ui.Node {
  @ui.Node::default()
  .with_position_type(@ui.PositionType::Absolute)
  .with_left(@ui.Val::Px(24.0F))
  .with_bottom(@ui.Val::Px(bottom))
  .with_width(@ui.Val::Px(320.0F))
  .with_padding(@ui.UiRect::all(@ui.Val::Px(12.0F)))
}

///|
fn instruction_node() -> @ui.Node {
  @ui.Node::default()
  .with_position_type(@ui.PositionType::Absolute)
  .with_left(@ui.Val::Px(24.0F))
  .with_top(@ui.Val::Px(24.0F))
  .with_width(@ui.Val::Px(320.0F))
  .with_padding(@ui.UiRect::all(@ui.Val::Px(12.0F)))
}

///|
fn spawn_directional_button(
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
      NavButton::{ label, },
      ActivatedButton::{ active: false },
      button_node(left, top),
      @ui.BackgroundColor::new(nav_normal_color()),
      @ui.BorderColor::new(nav_idle_border()),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(button),
        @text.Text::new(label),
        text_font(font, 24.0F),
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
      buttons : @ecs.Query[
        @ecs.Mut[ActivatedButton],
        @ecs.With[ActivatedButton],
      ],
      status : @app.ResMut[NavigationStatus],
    ) {
      focus.modify(fn(value) { value.set(button) })
      let state : @ecs.Mut[ActivatedButton]? = try buttons.get(button) catch {
        _ => None
      } noraise {
        value => value
      }
      if state is Some(state) {
        state.set(ActivatedButton::{ active: !state.value().active })
      }
      status.modify(fn(value) { value.label = "Last Input: Pointer Click" })
    }),
  )
  button
}

///|
fn setup(
  commands : @app.Commands,
  focus : @app.ResMut[@input_focus.InputFocus],
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
          "Automatic Directional Navigation\n\nArrow keys or D-pad move focus.\nEnter, Space, or South toggles the focused button.\nPointer clicks also move focus.",
        ),
        text_font(font, 18.0F),
        @text.TextColor::new(@sprite.Color::white()),
        instruction_node(),
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
        FocusDisplay::{  },
        @text.Text::new("Focused: None"),
        text_font(font, 20.0F),
        @text.TextColor::new(@sprite.Color::white()),
        status_node(88.0F),
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
        LastInputDisplay::{  },
        @text.Text::new("Last Input: None"),
        text_font(font, 20.0F),
        @text.TextColor::new(@sprite.Color::white()),
        status_node(24.0F),
        @ui.BackgroundColor::new(
          @sprite.Color::srgba(0.38F, 0.16F, 0.52F, 0.82F),
        ),
      ),
    ),
  )

  let positions : Array[(String, Float, Float)] = [
    ("One", 360.0F, 110.0F),
    ("Two", 530.0F, 128.0F),
    ("Three", 718.0F, 96.0F),
    ("Four", 392.0F, 245.0F),
    ("Five", 612.0F, 262.0F),
    ("Six", 468.0F, 382.0F),
    ("Seven", 682.0F, 404.0F),
    ("Eight", 332.0F, 505.0F),
    ("Nine", 556.0F, 526.0F),
    ("Ten", 770.0F, 492.0F),
  ]
  let mut first_button = None
  for position in positions {
    let (label, left, top) = position
    let button = spawn_directional_button(
      commands, root, font, label, left, top,
    )
    if first_button is None {
      first_button = Some(button)
    }
  }
  if first_button is Some(button) {
    focus.modify(fn(value) { value.set(button) })
  }
}

///|
fn navigation_direction_from_gamepads(
  gamepads : @ecs.Query[@ecs.Comp[@input.Gamepad], @ecs.All],
) -> @math.CompassOctant? {
  let result : Ref[@math.CompassOctant?] = Ref(None)
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
fn navigation_direction_text(direction : @math.CompassOctant) -> String {
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
fn navigate_ui(
  navigator : @ui.AutoDirectionalNavigator,
  gamepads : @ecs.Query[@ecs.Comp[@input.Gamepad], @ecs.All],
  status : @app.ResMut[NavigationStatus],
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
    navigation_direction_from_gamepads(gamepads)
  }
  guard direction is Some(direction) else { return }
  let next_focus = try navigator.navigate(direction) catch {
    _ => None
  } noraise {
    value => Some(value)
  }
  status.modify(fn(value) {
    value.label = if next_focus is Some(_) {
      "Last Input: Navigate \{navigation_direction_text(direction)}"
    } else {
      "Last Input: Blocked \{navigation_direction_text(direction)}"
    }
  })
}

///|
fn activate_from_gamepads(
  gamepads : @ecs.Query[@ecs.Comp[@input.Gamepad], @ecs.All],
) -> Bool {
  let pressed = Ref(false)
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
fn activate_focused_button(world : @ecs.World) -> Unit {
  let activate = @input.key_just_pressed(@window.KeyCode::Enter) ||
    @input.key_just_pressed(@window.KeyCode::Space) ||
    activate_from_gamepads(@ecs.query(world))
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
    @ecs.Mut[ActivatedButton],
    @ecs.With[ActivatedButton],
  ] = @ecs.query_filtered(world, @ecs.With::new(ActivatedButton::component()))
  let label_query : @ecs.Query[@ecs.Comp[NavButton], @ecs.With[NavButton]] = @ecs.query_filtered(
    world,
    @ecs.With::new(NavButton::component()),
  )
  let status_ref = match
    (try! world.get_resource_mut(NavigationStatus::resource())) {
    Some(status_ref) => status_ref
    None => return
  }
  let state : @ecs.Mut[ActivatedButton]? = try state_query.get(entity) catch {
    _ => None
  } noraise {
    value => value
  }
  let label : @ecs.Comp[NavButton]? = try label_query.get(entity) catch {
    _ => None
  } noraise {
    value => value
  }
  if state is Some(state) {
    state.set(ActivatedButton::{ active: !state.value().active })
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
fn update_focus_display(world : @ecs.World) -> Unit {
  let focused = match
    (try! world.get_resource(@input_focus.InputFocus::resource())) {
    Some(focus) => focus.get()
    None => None
  }
  let label_query : @ecs.Query[@ecs.Comp[NavButton], @ecs.With[NavButton]] = @ecs.query_filtered(
    world,
    @ecs.With::new(NavButton::component()),
  )
  let display_query : @ecs.Query[@ecs.Mut[@text.Text], @ecs.With[FocusDisplay]] = @ecs.query_filtered(
    world,
    @ecs.With::new(FocusDisplay::component()),
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
fn update_last_input_display(world : @ecs.World) -> Unit {
  let label = match (try! world.get_resource(NavigationStatus::resource())) {
    Some(status) => status.label
    None => "Last Input: None"
  }
  let display_query : @ecs.Query[
    @ecs.Mut[@text.Text],
    @ecs.With[LastInputDisplay],
  ] = @ecs.query_filtered(world, @ecs.With::new(LastInputDisplay::component()))
  try! display_query.view(fn(_entity, text) { text.set(@text.Text::new(label)) })
}

///|
fn update_button_visuals(world : @ecs.World) -> Unit {
  let focused = match
    (try! world.get_resource(@input_focus.InputFocus::resource())) {
    Some(focus) => focus.get()
    None => None
  }
  let query : @ecs.Query[
    (@core.Entity, @ecs.Mut[@ui.BackgroundColor], @ecs.Mut[@ui.BorderColor]),
    @ecs.With[NavButton],
  ] = @ecs.query_filtered(world, @ecs.With::new(NavButton::component()))
  try! query.view(fn(_query_entity, data) {
    let (entity, background, border) = data
    let activated : ActivatedButton? = try world.entity(entity).get() catch {
      _ => None
    } noraise {
      value => value
    }
    let active = match activated {
      Some(activated) => activated.active
      None => false
    }
    background.set(
      @ui.BackgroundColor::new(
        if active {
          nav_active_color()
        } else {
          nav_normal_color()
        },
      ),
    )
    border.set(
      @ui.BorderColor::new(
        if focused == Some(entity) {
          nav_focus_color()
        } else {
          nav_idle_border()
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
  .insert_resource(NavigationStatus::{ label: "Last Input: None" })
  .insert_resource(
    @input_focus.AutoNavigationConfig::new(0.1F, Some(500.0F), true),
  )
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.PreUpdate, @app.system(@app.system_param3(navigate_ui)))
  .add_systems(@app.PreUpdate, @app.system(activate_focused_button))
  .add_systems(@app.Update, @app.system(update_focus_display))
  .add_systems(@app.Update, @app.system(update_last_input_display))
  .add_systems(@app.Update, @app.system(update_button_visuals))
  .run()
}
