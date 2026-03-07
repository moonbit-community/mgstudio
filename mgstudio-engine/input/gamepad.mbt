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
const GAMEPAD_BUTTON_COUNT : Int = 20

///|
const GAMEPAD_AXIS_COUNT : Int = 9

///|
pub(all) enum GamepadButton {
  South
  East
  C
  North
  West
  Z
  LeftTrigger
  RightTrigger
  LeftTrigger2
  RightTrigger2
  Select
  Start
  Mode
  LeftThumb
  RightThumb
  DPadUp
  DPadDown
  DPadLeft
  DPadRight
  Other(Int)
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn GamepadButton::to_index(self : GamepadButton) -> Int {
  match self {
    South => 0
    East => 1
    C => 2
    North => 3
    West => 4
    Z => 5
    LeftTrigger => 6
    RightTrigger => 7
    LeftTrigger2 => 8
    RightTrigger2 => 9
    Select => 10
    Start => 11
    Mode => 12
    LeftThumb => 13
    RightThumb => 14
    DPadUp => 15
    DPadDown => 16
    DPadLeft => 17
    DPadRight => 18
    Other(index) => index
  }
}

///|
pub fn GamepadButton::all() -> Array[GamepadButton] {
  [
    South,
    East,
    C,
    North,
    West,
    Z,
    LeftTrigger,
    RightTrigger,
    LeftTrigger2,
    RightTrigger2,
    Select,
    Start,
    Mode,
    LeftThumb,
    RightThumb,
    DPadUp,
    DPadDown,
    DPadLeft,
    DPadRight,
  ]
}

///|
pub impl ButtonInputButton for GamepadButton with button_id(self) {
  self.to_json().stringify()
}

///|
fn gamepad_button_from_index(index : Int) -> GamepadButton {
  match index {
    0 => GamepadButton::South
    1 => GamepadButton::East
    2 => GamepadButton::C
    3 => GamepadButton::North
    4 => GamepadButton::West
    5 => GamepadButton::Z
    6 => GamepadButton::LeftTrigger
    7 => GamepadButton::RightTrigger
    8 => GamepadButton::LeftTrigger2
    9 => GamepadButton::RightTrigger2
    10 => GamepadButton::Select
    11 => GamepadButton::Start
    12 => GamepadButton::Mode
    13 => GamepadButton::LeftThumb
    14 => GamepadButton::RightThumb
    15 => GamepadButton::DPadUp
    16 => GamepadButton::DPadDown
    17 => GamepadButton::DPadLeft
    18 => GamepadButton::DPadRight
    _ => GamepadButton::Other(index)
  }
}

///|
pub(all) enum GamepadAxis {
  LeftStickX
  LeftStickY
  LeftZ
  RightStickX
  RightStickY
  RightZ
  Other(Int)
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn GamepadAxis::to_index(self : GamepadAxis) -> Int {
  match self {
    LeftStickX => 0
    LeftStickY => 1
    LeftZ => 2
    RightStickX => 3
    RightStickY => 4
    RightZ => 5
    Other(index) => index
  }
}

///|
pub fn GamepadAxis::all() -> Array[GamepadAxis] {
  [LeftStickX, LeftStickY, LeftZ, RightStickX, RightStickY, RightZ]
}

///|
fn gamepad_axis_from_index(index : Int) -> GamepadAxis {
  match index {
    0 => GamepadAxis::LeftStickX
    1 => GamepadAxis::LeftStickY
    2 => GamepadAxis::LeftZ
    3 => GamepadAxis::RightStickX
    4 => GamepadAxis::RightStickY
    5 => GamepadAxis::RightZ
    _ => GamepadAxis::Other(index)
  }
}

///|
pub(all) enum GamepadInput {
  Axis(GamepadAxis)
  Button(GamepadButton)
} derive(Eq, Show, ToJson, FromJson)

///|
pub(open) trait IntoGamepadInput {
  into_gamepad_input(self : Self) -> GamepadInput
}

///|
pub impl IntoGamepadInput for GamepadInput with into_gamepad_input(self) {
  self
}

///|
pub impl IntoGamepadInput for GamepadButton with into_gamepad_input(self) {
  GamepadInput::Button(self)
}

///|
pub impl IntoGamepadInput for GamepadAxis with into_gamepad_input(self) {
  GamepadInput::Axis(self)
}

///|
pub struct Gamepad {
  vendor_id : Int?
  product_id : Int?
  digital : ButtonInput[GamepadButton]
  analog : Axis[GamepadInput]
} derive(ToJson, FromJson)

///|
pub fn Gamepad::vendor_id(self : Gamepad) -> Int? {
  self.vendor_id
}

///|
pub fn Gamepad::product_id(self : Gamepad) -> Int? {
  self.product_id
}

///|
pub fn[T : IntoGamepadInput] Gamepad::get(self : Gamepad, input : T) -> Float? {
  self.analog.get(IntoGamepadInput::into_gamepad_input(input))
}

///|
pub fn[T : IntoGamepadInput] Gamepad::get_unclamped(
  self : Gamepad,
  input : T,
) -> Float? {
  self.analog.get_unclamped(IntoGamepadInput::into_gamepad_input(input))
}

///|
pub fn Gamepad::left_stick(self : Gamepad) -> @math.Vec2 {
  @math.Vec2::new(
    self.get(GamepadAxis::LeftStickX).unwrap_or(0.0F),
    self.get(GamepadAxis::LeftStickY).unwrap_or(0.0F),
  )
}

///|
pub fn Gamepad::right_stick(self : Gamepad) -> @math.Vec2 {
  @math.Vec2::new(
    self.get(GamepadAxis::RightStickX).unwrap_or(0.0F),
    self.get(GamepadAxis::RightStickY).unwrap_or(0.0F),
  )
}

///|
pub fn Gamepad::dpad(self : Gamepad) -> @math.Vec2 {
  @math.Vec2::new(
    self.get(GamepadButton::DPadRight).unwrap_or(0.0F) -
    self.get(GamepadButton::DPadLeft).unwrap_or(0.0F),
    self.get(GamepadButton::DPadUp).unwrap_or(0.0F) -
    self.get(GamepadButton::DPadDown).unwrap_or(0.0F),
  )
}

///|
pub fn Gamepad::pressed(self : Gamepad, button : GamepadButton) -> Bool {
  self.digital.pressed(button)
}

///|
pub fn Gamepad::any_pressed(
  self : Gamepad,
  button_inputs : Array[GamepadButton],
) -> Bool {
  self.digital.any_pressed(button_inputs)
}

///|
pub fn Gamepad::all_pressed(
  self : Gamepad,
  button_inputs : Array[GamepadButton],
) -> Bool {
  self.digital.all_pressed(button_inputs)
}

///|
pub fn Gamepad::just_pressed(self : Gamepad, button : GamepadButton) -> Bool {
  self.digital.just_pressed(button)
}

///|
pub fn Gamepad::any_just_pressed(
  self : Gamepad,
  button_inputs : Array[GamepadButton],
) -> Bool {
  self.digital.any_just_pressed(button_inputs)
}

///|
pub fn Gamepad::all_just_pressed(
  self : Gamepad,
  button_inputs : Array[GamepadButton],
) -> Bool {
  self.digital.all_just_pressed(button_inputs)
}

///|
pub fn Gamepad::just_released(self : Gamepad, button : GamepadButton) -> Bool {
  self.digital.just_released(button)
}

///|
pub fn Gamepad::any_just_released(
  self : Gamepad,
  button_inputs : Array[GamepadButton],
) -> Bool {
  self.digital.any_just_released(button_inputs)
}

///|
pub fn Gamepad::all_just_released(
  self : Gamepad,
  button_inputs : Array[GamepadButton],
) -> Bool {
  self.digital.all_just_released(button_inputs)
}

///|
pub fn Gamepad::get_pressed(self : Gamepad) -> Array[GamepadButton] {
  self.digital.get_pressed()
}

///|
pub fn Gamepad::get_just_pressed(self : Gamepad) -> Array[GamepadButton] {
  self.digital.get_just_pressed()
}

///|
pub fn Gamepad::get_just_released(self : Gamepad) -> Array[GamepadButton] {
  self.digital.get_just_released()
}

///|
pub fn Gamepad::get_analog_axes(self : Gamepad) -> Array[GamepadInput] {
  self.analog.all_axes()
}

///|
pub fn Gamepad::digital(self : Gamepad) -> ButtonInput[GamepadButton] {
  self.digital
}

///|
pub fn Gamepad::digital_mut(self : Gamepad) -> ButtonInput[GamepadButton] {
  self.digital
}

///|
pub fn Gamepad::analog(self : Gamepad) -> Axis[GamepadInput] {
  self.analog
}

///|
pub fn Gamepad::analog_mut(self : Gamepad) -> Axis[GamepadInput] {
  self.analog
}

///|
pub struct GamepadConnectionInfo {
  name : String
  vendor_id : Int?
  product_id : Int?
} derive(Eq, ToJson, FromJson)

///|
pub fn GamepadConnectionInfo::new(
  name : String,
  vendor_id : Int?,
  product_id : Int?,
) -> GamepadConnectionInfo {
  GamepadConnectionInfo::{ name, vendor_id, product_id }
}

///|
pub(all) enum GamepadConnection {
  Connected(GamepadConnectionInfo)
  Disconnected
} derive(Eq, ToJson, FromJson)

///|
pub struct GamepadConnectionEvent {
  gamepad : @core.Entity
  connection : GamepadConnection
} derive(Eq, ToJson, FromJson)

///|
pub fn GamepadConnectionEvent::new(
  gamepad : @core.Entity,
  connection : GamepadConnection,
) -> GamepadConnectionEvent {
  GamepadConnectionEvent::{ gamepad, connection }
}

///|
pub fn GamepadConnectionEvent::connected(self : GamepadConnectionEvent) -> Bool {
  match self.connection {
    Connected(_) => true
    Disconnected => false
  }
}

///|
pub fn GamepadConnectionEvent::disconnected(
  self : GamepadConnectionEvent,
) -> Bool {
  !self.connected()
}

///|
pub struct RawGamepadButtonChangedEvent {
  gamepad : @core.Entity
  button : GamepadButton
  value : Float
} derive(Eq, ToJson, FromJson)

///|
pub fn RawGamepadButtonChangedEvent::new(
  gamepad : @core.Entity,
  button : GamepadButton,
  value : Float,
) -> RawGamepadButtonChangedEvent {
  RawGamepadButtonChangedEvent::{ gamepad, button, value }
}

///|
pub struct RawGamepadAxisChangedEvent {
  gamepad : @core.Entity
  axis : GamepadAxis
  value : Float
} derive(Eq, ToJson, FromJson)

///|
pub fn RawGamepadAxisChangedEvent::new(
  gamepad : @core.Entity,
  axis : GamepadAxis,
  value : Float,
) -> RawGamepadAxisChangedEvent {
  RawGamepadAxisChangedEvent::{ gamepad, axis, value }
}

///|
pub(all) enum RawGamepadEvent {
  Connection(GamepadConnectionEvent)
  Button(RawGamepadButtonChangedEvent)
  Axis(RawGamepadAxisChangedEvent)
} derive(Eq, ToJson, FromJson)

///|
pub struct GamepadButtonChangedEvent {
  entity : @core.Entity
  button : GamepadButton
  state : ButtonState
  value : Float
} derive(Eq, ToJson, FromJson)

///|
pub fn GamepadButtonChangedEvent::new(
  entity : @core.Entity,
  button : GamepadButton,
  state : ButtonState,
  value : Float,
) -> GamepadButtonChangedEvent {
  GamepadButtonChangedEvent::{ entity, button, state, value }
}

///|
pub struct GamepadAxisChangedEvent {
  entity : @core.Entity
  axis : GamepadAxis
  value : Float
} derive(Eq, ToJson, FromJson)

///|
pub fn GamepadAxisChangedEvent::new(
  entity : @core.Entity,
  axis : GamepadAxis,
  value : Float,
) -> GamepadAxisChangedEvent {
  GamepadAxisChangedEvent::{ entity, axis, value }
}

///|
pub struct GamepadButtonStateChangedEvent {
  entity : @core.Entity
  button : GamepadButton
  state : ButtonState
} derive(Eq, ToJson, FromJson)

///|
pub fn GamepadButtonStateChangedEvent::new(
  entity : @core.Entity,
  button : GamepadButton,
  state : ButtonState,
) -> GamepadButtonStateChangedEvent {
  GamepadButtonStateChangedEvent::{ entity, button, state }
}

///|
pub(all) enum GamepadEvent {
  Connection(GamepadConnectionEvent)
  Button(GamepadButtonChangedEvent)
  Axis(GamepadAxisChangedEvent)
} derive(Eq, ToJson, FromJson)

///|
pub(all) struct GamepadRumbleIntensity {
  strong_motor : Float
  weak_motor : Float
} derive(Eq, ToJson, FromJson)

///|
pub fn GamepadRumbleIntensity::max() -> GamepadRumbleIntensity {
  GamepadRumbleIntensity::{ strong_motor: 1.0F, weak_motor: 1.0F }
}

///|
pub fn GamepadRumbleIntensity::weak_max() -> GamepadRumbleIntensity {
  GamepadRumbleIntensity::{ strong_motor: 0.0F, weak_motor: 1.0F }
}

///|
pub fn GamepadRumbleIntensity::strong_max() -> GamepadRumbleIntensity {
  GamepadRumbleIntensity::{ strong_motor: 1.0F, weak_motor: 0.0F }
}

///|
pub fn GamepadRumbleIntensity::weak_motor(
  intensity : Float,
) -> GamepadRumbleIntensity {
  GamepadRumbleIntensity::{ strong_motor: 0.0F, weak_motor: intensity }
}

///|
pub fn GamepadRumbleIntensity::strong_motor(
  intensity : Float,
) -> GamepadRumbleIntensity {
  GamepadRumbleIntensity::{ strong_motor: intensity, weak_motor: 0.0F }
}

///|
pub(all) enum GamepadRumbleRequest {
  Add(
    duration~ : @core.Duration,
    intensity~ : GamepadRumbleIntensity,
    gamepad~ : @core.Entity
  )
  Stop(gamepad~ : @core.Entity)
} derive(Eq, ToJson, FromJson)

///|
pub fn GamepadRumbleRequest::gamepad(
  self : GamepadRumbleRequest,
) -> @core.Entity {
  match self {
    Add(gamepad~, ..) => gamepad
    Stop(gamepad~) => gamepad
  }
}

///|
pub(all) suberror AxisSettingsError {
  LiveZoneLowerBoundOutOfRange(Float)
  DeadZoneLowerBoundOutOfRange(Float)
  DeadZoneUpperBoundOutOfRange(Float)
  LiveZoneUpperBoundOutOfRange(Float)
  LiveZoneLowerBoundGreaterThanDeadZoneLowerBound(Float, Float)
  DeadZoneUpperBoundGreaterThanLiveZoneUpperBound(Float, Float)
  Threshold(Float)
}

///|
pub(all) suberror ButtonSettingsError {
  ReleaseThresholdOutOfRange(Float)
  PressThresholdOutOfRange(Float)
  ReleaseThresholdGreaterThanPressThreshold(Float, Float)
}

///|
pub struct ButtonSettings {
  mut press_threshold : Float
  mut release_threshold : Float
} derive(Eq, ToJson, FromJson)

///|
pub impl Default for ButtonSettings with default() {
  ButtonSettings::{ press_threshold: 0.75F, release_threshold: 0.65F }
}

///|
pub fn ButtonSettings::new(
  press_threshold : Float,
  release_threshold : Float,
) -> Result[ButtonSettings, ButtonSettingsError] {
  if release_threshold < 0.0F || release_threshold > 1.0F {
    Err(ButtonSettingsError::ReleaseThresholdOutOfRange(release_threshold))
  } else if press_threshold < 0.0F || press_threshold > 1.0F {
    Err(ButtonSettingsError::PressThresholdOutOfRange(press_threshold))
  } else if release_threshold > press_threshold {
    Err(
      ButtonSettingsError::ReleaseThresholdGreaterThanPressThreshold(
        press_threshold, release_threshold,
      ),
    )
  } else {
    Ok(ButtonSettings::{ press_threshold, release_threshold })
  }
}

///|
pub fn ButtonSettings::is_pressed(self : ButtonSettings, value : Float) -> Bool {
  value >= self.press_threshold
}

///|
pub fn ButtonSettings::is_released(
  self : ButtonSettings,
  value : Float,
) -> Bool {
  value <= self.release_threshold
}

///|
pub fn ButtonSettings::press_threshold(self : ButtonSettings) -> Float {
  self.press_threshold
}

///|
pub fn ButtonSettings::try_set_press_threshold(
  self : ButtonSettings,
  value : Float,
) -> Result[Unit, ButtonSettingsError] {
  if value >= self.release_threshold && value <= 1.0F {
    self.press_threshold = value
    Ok(())
  } else if value < 0.0F || value > 1.0F {
    Err(ButtonSettingsError::PressThresholdOutOfRange(value))
  } else {
    Err(
      ButtonSettingsError::ReleaseThresholdGreaterThanPressThreshold(
        value,
        self.release_threshold,
      ),
    )
  }
}

///|
pub fn ButtonSettings::set_press_threshold(
  self : ButtonSettings,
  value : Float,
) -> Float {
  self.try_set_press_threshold(value) |> ignore
  self.press_threshold
}

///|
pub fn ButtonSettings::release_threshold(self : ButtonSettings) -> Float {
  self.release_threshold
}

///|
pub fn ButtonSettings::try_set_release_threshold(
  self : ButtonSettings,
  value : Float,
) -> Result[Unit, ButtonSettingsError] {
  if value >= 0.0F && value <= self.press_threshold {
    self.release_threshold = value
    Ok(())
  } else if value < 0.0F || value > 1.0F {
    Err(ButtonSettingsError::ReleaseThresholdOutOfRange(value))
  } else {
    Err(
      ButtonSettingsError::ReleaseThresholdGreaterThanPressThreshold(
        self.press_threshold,
        value,
      ),
    )
  }
}

///|
pub fn ButtonSettings::set_release_threshold(
  self : ButtonSettings,
  value : Float,
) -> Float {
  self.try_set_release_threshold(value) |> ignore
  self.release_threshold
}

///|
pub struct AxisSettings {
  mut livezone_upperbound : Float
  mut deadzone_upperbound : Float
  mut deadzone_lowerbound : Float
  mut livezone_lowerbound : Float
  mut threshold : Float
} derive(Eq, ToJson, FromJson)

///|
pub impl Default for AxisSettings with default() {
  AxisSettings::{
    livezone_upperbound: 1.0F,
    deadzone_upperbound: 0.05F,
    deadzone_lowerbound: -0.05F,
    livezone_lowerbound: -1.0F,
    threshold: 0.01F,
  }
}

///|
pub fn AxisSettings::new(
  livezone_lowerbound : Float,
  deadzone_lowerbound : Float,
  deadzone_upperbound : Float,
  livezone_upperbound : Float,
  threshold : Float,
) -> Result[AxisSettings, AxisSettingsError] {
  if livezone_lowerbound < -1.0F || livezone_lowerbound > 0.0F {
    Err(AxisSettingsError::LiveZoneLowerBoundOutOfRange(livezone_lowerbound))
  } else if deadzone_lowerbound < -1.0F || deadzone_lowerbound > 0.0F {
    Err(AxisSettingsError::DeadZoneLowerBoundOutOfRange(deadzone_lowerbound))
  } else if deadzone_upperbound < 0.0F || deadzone_upperbound > 1.0F {
    Err(AxisSettingsError::DeadZoneUpperBoundOutOfRange(deadzone_upperbound))
  } else if livezone_upperbound < 0.0F || livezone_upperbound > 1.0F {
    Err(AxisSettingsError::LiveZoneUpperBoundOutOfRange(livezone_upperbound))
  } else if livezone_lowerbound > deadzone_lowerbound {
    Err(
      AxisSettingsError::LiveZoneLowerBoundGreaterThanDeadZoneLowerBound(
        livezone_lowerbound, deadzone_lowerbound,
      ),
    )
  } else if deadzone_upperbound > livezone_upperbound {
    Err(
      AxisSettingsError::DeadZoneUpperBoundGreaterThanLiveZoneUpperBound(
        livezone_upperbound, deadzone_upperbound,
      ),
    )
  } else if threshold < 0.0F || threshold > 2.0F {
    Err(AxisSettingsError::Threshold(threshold))
  } else {
    Ok(AxisSettings::{
      livezone_upperbound,
      deadzone_upperbound,
      deadzone_lowerbound,
      livezone_lowerbound,
      threshold,
    })
  }
}

///|
pub fn AxisSettings::livezone_upperbound(self : AxisSettings) -> Float {
  self.livezone_upperbound
}

///|
pub fn AxisSettings::try_set_livezone_upperbound(
  self : AxisSettings,
  value : Float,
) -> Result[Unit, AxisSettingsError] {
  if value < 0.0F || value > 1.0F {
    Err(AxisSettingsError::LiveZoneUpperBoundOutOfRange(value))
  } else if value < self.deadzone_upperbound {
    Err(
      AxisSettingsError::DeadZoneUpperBoundGreaterThanLiveZoneUpperBound(
        value,
        self.deadzone_upperbound,
      ),
    )
  } else {
    self.livezone_upperbound = value
    Ok(())
  }
}

///|
pub fn AxisSettings::set_livezone_upperbound(
  self : AxisSettings,
  value : Float,
) -> Float {
  self.try_set_livezone_upperbound(value) |> ignore
  self.livezone_upperbound
}

///|
pub fn AxisSettings::deadzone_upperbound(self : AxisSettings) -> Float {
  self.deadzone_upperbound
}

///|
pub fn AxisSettings::try_set_deadzone_upperbound(
  self : AxisSettings,
  value : Float,
) -> Result[Unit, AxisSettingsError] {
  if value < 0.0F || value > 1.0F {
    Err(AxisSettingsError::DeadZoneUpperBoundOutOfRange(value))
  } else if self.livezone_upperbound < value {
    Err(
      AxisSettingsError::DeadZoneUpperBoundGreaterThanLiveZoneUpperBound(
        self.livezone_upperbound,
        value,
      ),
    )
  } else {
    self.deadzone_upperbound = value
    Ok(())
  }
}

///|
pub fn AxisSettings::set_deadzone_upperbound(
  self : AxisSettings,
  value : Float,
) -> Float {
  self.try_set_deadzone_upperbound(value) |> ignore
  self.deadzone_upperbound
}

///|
pub fn AxisSettings::livezone_lowerbound(self : AxisSettings) -> Float {
  self.livezone_lowerbound
}

///|
pub fn AxisSettings::try_set_livezone_lowerbound(
  self : AxisSettings,
  value : Float,
) -> Result[Unit, AxisSettingsError] {
  if value < -1.0F || value > 0.0F {
    Err(AxisSettingsError::LiveZoneLowerBoundOutOfRange(value))
  } else if value > self.deadzone_lowerbound {
    Err(
      AxisSettingsError::LiveZoneLowerBoundGreaterThanDeadZoneLowerBound(
        value,
        self.deadzone_lowerbound,
      ),
    )
  } else {
    self.livezone_lowerbound = value
    Ok(())
  }
}

///|
pub fn AxisSettings::set_livezone_lowerbound(
  self : AxisSettings,
  value : Float,
) -> Float {
  self.try_set_livezone_lowerbound(value) |> ignore
  self.livezone_lowerbound
}

///|
pub fn AxisSettings::deadzone_lowerbound(self : AxisSettings) -> Float {
  self.deadzone_lowerbound
}

///|
pub fn AxisSettings::try_set_deadzone_lowerbound(
  self : AxisSettings,
  value : Float,
) -> Result[Unit, AxisSettingsError] {
  if value < -1.0F || value > 0.0F {
    Err(AxisSettingsError::DeadZoneLowerBoundOutOfRange(value))
  } else if self.livezone_lowerbound > value {
    Err(
      AxisSettingsError::LiveZoneLowerBoundGreaterThanDeadZoneLowerBound(
        self.livezone_lowerbound,
        value,
      ),
    )
  } else {
    self.deadzone_lowerbound = value
    Ok(())
  }
}

///|
pub fn AxisSettings::set_deadzone_lowerbound(
  self : AxisSettings,
  value : Float,
) -> Float {
  self.try_set_deadzone_lowerbound(value) |> ignore
  self.deadzone_lowerbound
}

///|
pub fn AxisSettings::threshold(self : AxisSettings) -> Float {
  self.threshold
}

///|
pub fn AxisSettings::try_set_threshold(
  self : AxisSettings,
  value : Float,
) -> Result[Unit, AxisSettingsError] {
  if value < 0.0F || value > 2.0F {
    Err(AxisSettingsError::Threshold(value))
  } else {
    self.threshold = value
    Ok(())
  }
}

///|
pub fn AxisSettings::set_threshold(self : AxisSettings, value : Float) -> Float {
  self.try_set_threshold(value) |> ignore
  self.threshold
}

///|
pub struct ButtonAxisSettings {
  high : Float
  low : Float
  threshold : Float
} derive(Eq, ToJson, FromJson)

///|
pub impl Default for ButtonAxisSettings with default() {
  ButtonAxisSettings::{ high: 0.95F, low: 0.05F, threshold: 0.01F }
}

///|
pub struct GamepadSettings {
  default_button_settings : ButtonSettings
  default_axis_settings : AxisSettings
  default_button_axis_settings : ButtonAxisSettings
  button_settings : Array[(GamepadButton, ButtonSettings)]
  axis_settings : Array[(GamepadAxis, AxisSettings)]
  button_axis_settings : Array[(GamepadButton, ButtonAxisSettings)]
} derive(ToJson, FromJson)

///|
pub impl Default for GamepadSettings with default() {
  GamepadSettings::{
    default_button_settings: ButtonSettings::default(),
    default_axis_settings: AxisSettings::default(),
    default_button_axis_settings: ButtonAxisSettings::default(),
    button_settings: [],
    axis_settings: [],
    button_axis_settings: [],
  }
}

///|
fn lookup_button_settings(
  overrides : Array[(GamepadButton, ButtonSettings)],
  button : GamepadButton,
) -> ButtonSettings? {
  for entry in overrides {
    if entry.0 == button {
      return Some(entry.1)
    }
  }
  None
}

///|
fn lookup_axis_settings(
  overrides : Array[(GamepadAxis, AxisSettings)],
  axis : GamepadAxis,
) -> AxisSettings? {
  for entry in overrides {
    if entry.0 == axis {
      return Some(entry.1)
    }
  }
  None
}

///|
fn lookup_button_axis_settings(
  overrides : Array[(GamepadButton, ButtonAxisSettings)],
  button : GamepadButton,
) -> ButtonAxisSettings? {
  for entry in overrides {
    if entry.0 == button {
      return Some(entry.1)
    }
  }
  None
}

///|
pub fn GamepadSettings::get_button_settings(
  self : GamepadSettings,
  button : GamepadButton,
) -> ButtonSettings {
  lookup_button_settings(self.button_settings, button).unwrap_or(
    self.default_button_settings,
  )
}

///|
pub fn GamepadSettings::get_axis_settings(
  self : GamepadSettings,
  axis : GamepadAxis,
) -> AxisSettings {
  lookup_axis_settings(self.axis_settings, axis).unwrap_or(
    self.default_axis_settings,
  )
}

///|
pub fn GamepadSettings::get_button_axis_settings(
  self : GamepadSettings,
  button : GamepadButton,
) -> ButtonAxisSettings {
  lookup_button_axis_settings(self.button_axis_settings, button).unwrap_or(
    self.default_button_axis_settings,
  )
}

///|
priv enum ScaledAxisWithDeadZonePosition {
  BelowLow
  Low(Float)
  Dead
  High(Float)
  AboveHigh
}

///|
priv struct FilteredAxisPosition {
  scaled : ScaledAxisWithDeadZonePosition
  raw : Float
}

///|
priv enum ScaledAxisPosition {
  ClampedLow
  Scaled(Float)
  ClampedHigh
}

///|
priv struct FilteredButtonAxisPosition {
  scaled : ScaledAxisPosition
  raw : Float
}

///|
fn float_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn linear_remapping(
  value : Float,
  old_start : Float,
  old_end : Float,
  new_start : Float,
  new_end : Float,
) -> Float {
  (value - old_start) / (old_end - old_start) * (new_end - new_start) +
  new_start
}

///|
fn ScaledAxisWithDeadZonePosition::to_f32(
  self : ScaledAxisWithDeadZonePosition,
) -> Float {
  match self {
    BelowLow => -1.0F
    Low(scaled) => scaled
    Dead => 0.0F
    High(scaled) => scaled
    AboveHigh => 1.0F
  }
}

///|
fn ScaledAxisPosition::to_f32(self : ScaledAxisPosition) -> Float {
  match self {
    ClampedLow => 0.0F
    Scaled(scaled) => scaled
    ClampedHigh => 1.0F
  }
}

///|
fn AxisSettings::clamp(self : AxisSettings, raw_value : Float) -> Float {
  if raw_value >= self.deadzone_lowerbound &&
    raw_value <= self.deadzone_upperbound {
    0.0F
  } else if raw_value >= self.livezone_upperbound {
    1.0F
  } else if raw_value <= self.livezone_lowerbound {
    -1.0F
  } else {
    raw_value
  }
}

///|
fn AxisSettings::should_register_change(
  self : AxisSettings,
  new_raw_value : Float,
  old_raw_value : Float?,
) -> Bool {
  match old_raw_value {
    None => true
    Some(old_value) => float_abs(new_raw_value - old_value) >= self.threshold
  }
}

///|
fn AxisSettings::get_axis_position_from_value(
  self : AxisSettings,
  value : Float,
) -> ScaledAxisWithDeadZonePosition {
  if value < self.deadzone_upperbound && value > self.deadzone_lowerbound {
    ScaledAxisWithDeadZonePosition::Dead
  } else if value > self.livezone_upperbound {
    ScaledAxisWithDeadZonePosition::AboveHigh
  } else if value < self.livezone_lowerbound {
    ScaledAxisWithDeadZonePosition::BelowLow
  } else if value >= self.deadzone_upperbound {
    ScaledAxisWithDeadZonePosition::High(
      linear_remapping(
        value,
        self.deadzone_upperbound,
        self.livezone_upperbound,
        0.0F,
        1.0F,
      ),
    )
  } else if value <= self.deadzone_lowerbound {
    ScaledAxisWithDeadZonePosition::Low(
      linear_remapping(
        value,
        self.livezone_lowerbound,
        self.deadzone_lowerbound,
        -1.0F,
        0.0F,
      ),
    )
  } else {
    ScaledAxisWithDeadZonePosition::Dead
  }
}

///|
fn AxisSettings::filter(
  self : AxisSettings,
  new_raw_value : Float,
  old_raw_value : Float?,
) -> FilteredAxisPosition? {
  let clamped_unscaled = self.clamp(new_raw_value)
  if self.should_register_change(clamped_unscaled, old_raw_value) {
    Some(FilteredAxisPosition::{
      scaled: self.get_axis_position_from_value(clamped_unscaled),
      raw: new_raw_value,
    })
  } else {
    None
  }
}

///|
fn ButtonAxisSettings::clamp(
  self : ButtonAxisSettings,
  raw_value : Float,
) -> Float {
  if raw_value <= self.low {
    0.0F
  } else if raw_value >= self.high {
    1.0F
  } else {
    raw_value
  }
}

///|
fn ButtonAxisSettings::should_register_change(
  self : ButtonAxisSettings,
  new_raw_value : Float,
  old_raw_value : Float?,
) -> Bool {
  match old_raw_value {
    None => true
    Some(old_value) => float_abs(new_raw_value - old_value) >= self.threshold
  }
}

///|
fn ButtonAxisSettings::get_axis_position_from_value(
  self : ButtonAxisSettings,
  value : Float,
) -> ScaledAxisPosition {
  if value <= self.low {
    ScaledAxisPosition::ClampedLow
  } else if value >= self.high {
    ScaledAxisPosition::ClampedHigh
  } else {
    ScaledAxisPosition::Scaled(
      linear_remapping(value, self.low, self.high, 0.0F, 1.0F),
    )
  }
}

///|
fn ButtonAxisSettings::filter(
  self : ButtonAxisSettings,
  new_raw_value : Float,
  old_raw_value : Float?,
) -> FilteredButtonAxisPosition? {
  let clamped_unscaled = self.clamp(new_raw_value)
  if self.should_register_change(clamped_unscaled, old_raw_value) {
    Some(FilteredButtonAxisPosition::{
      scaled: self.get_axis_position_from_value(clamped_unscaled),
      raw: new_raw_value,
    })
  } else {
    None
  }
}

///|
fn default_gamepad_analog() -> Axis[GamepadInput] {
  let analog : Axis[GamepadInput] = Axis::new()
  for button in GamepadButton::all() {
    analog.set(GamepadInput::Button(button), 0.0F) |> ignore
  }
  for axis in GamepadAxis::all() {
    analog.set(GamepadInput::Axis(axis), 0.0F) |> ignore
  }
  analog
}

///|
pub impl Default for Gamepad with default() {
  Gamepad::{
    vendor_id: None,
    product_id: None,
    digital: ButtonInput::new(),
    analog: default_gamepad_analog(),
  }
}

///|
pub let ecs_key_gamepad : @ecs.ComponentKey[Gamepad] = @ecs.register_component(
  debug_name="input.gamepad",
)

///|
pub impl @ecs.Component for Gamepad with component() {
  ecs_key_gamepad
}

///|
pub let ecs_key_gamepad_settings : @ecs.ComponentKey[GamepadSettings] = @ecs.register_component(
  debug_name="input.gamepad_settings",
)

///|
pub impl @ecs.Component for GamepadSettings with component() {
  ecs_key_gamepad_settings
}

///|
priv struct RunningRumble {
  deadline_ms : Int64
  intensity : GamepadRumbleIntensity
} derive(Eq, ToJson, FromJson)

///|
priv struct AppliedRumble {
  strong_motor : Float
  weak_motor : Float
  deadline_ms : Int64
} derive(Eq, ToJson, FromJson)

///|
priv struct RunningRumbleEntry {
  entity : @core.Entity
  mut rumbles : Array[RunningRumble]
  mut last_applied : AppliedRumble?
} derive(Eq, ToJson, FromJson)

///|
struct RunningRumbleEffects {
  mut entries : Array[RunningRumbleEntry]
} derive(Eq, ToJson, FromJson)

///|
impl Default for RunningRumbleEffects with default() {
  RunningRumbleEffects::{ entries: [] }
}

///|
let running_rumble_effects_resource_key : @ecs.ResourceKey[RunningRumbleEffects] = @ecs.register_resource(
  debug_name="bevy_input::RunningRumbleEffects",
)

///|
pub impl @app.Resource for RunningRumbleEffects with resource() {
  running_rumble_effects_resource_key
}

///|
priv struct GamepadSnapshot {
  host_id : Int
  entity : @core.Entity
  name : String
  vendor_id : Int?
  product_id : Int?
  connected : Bool
  button_values : Array[Float]
  axis_values : Array[Float]
}

///|
fn host_input_gamepad_poll() -> Unit {
  @native_input.gamepad_poll()
}

///|
fn host_input_gamepad_count() -> Int {
  @native_input.gamepad_count()
}

///|
fn host_input_gamepad_id(index : Int) -> Int {
  @native_input.gamepad_id(index)
}

///|
fn host_input_gamepad_connected(gamepad_id : Int) -> Bool {
  @native_input.gamepad_connected(gamepad_id)
}

///|
fn host_input_gamepad_ff_supported(gamepad_id : Int) -> Bool {
  @native_input.gamepad_ff_supported(gamepad_id)
}

///|
fn host_input_gamepad_name_len(gamepad_id : Int) -> Int {
  @native_input.gamepad_name_len(gamepad_id)
}

///|
fn host_input_gamepad_name_code_unit(gamepad_id~ : Int, offset~ : Int) -> Int {
  @native_input.gamepad_name_code_unit(gamepad_id~, offset~)
}

///|
fn host_input_gamepad_vendor_id(gamepad_id : Int) -> Int {
  @native_input.gamepad_vendor_id(gamepad_id)
}

///|
fn host_input_gamepad_product_id(gamepad_id : Int) -> Int {
  @native_input.gamepad_product_id(gamepad_id)
}

///|
fn host_input_gamepad_button_value(gamepad_id~ : Int, button~ : Int) -> Float {
  @native_input.gamepad_button_value(gamepad_id~, button~)
}

///|
fn host_input_gamepad_axis_value(gamepad_id~ : Int, axis~ : Int) -> Float {
  @native_input.gamepad_axis_value(gamepad_id~, axis~)
}

///|
fn host_input_gamepad_set_rumble(
  gamepad_id : Int,
  strong_motor : Float,
  weak_motor : Float,
  duration_ms : Int64,
) -> @native_input.GamepadRumbleResult {
  @native_input.gamepad_set_rumble(
    gamepad_id, strong_motor, weak_motor, duration_ms,
  )
}

///|
let current_gamepads_ref : Ref[Array[GamepadSnapshot]] = Ref::new([])

///|
let previous_gamepads_ref : Ref[Array[GamepadSnapshot]] = Ref::new([])

///|
let host_gamepad_entities_ref : Ref[Array[(Int, @core.Entity)]] = Ref::new([])

///|
let gamepad_event_message_key : @ecs.MessageKey[GamepadEvent] = @ecs.register_message(
  debug_name="input.gamepad.GamepadEvent",
)

///|
let raw_gamepad_event_message_key : @ecs.MessageKey[RawGamepadEvent] = @ecs.register_message(
  debug_name="input.gamepad.RawGamepadEvent",
)

///|
let gamepad_connection_event_message_key : @ecs.MessageKey[
  GamepadConnectionEvent,
] = @ecs.register_message(debug_name="input.gamepad.GamepadConnectionEvent")

///|
let raw_gamepad_axis_changed_event_message_key : @ecs.MessageKey[
  RawGamepadAxisChangedEvent,
] = @ecs.register_message(debug_name="input.gamepad.RawGamepadAxisChangedEvent")

///|
let gamepad_axis_changed_event_message_key : @ecs.MessageKey[
  GamepadAxisChangedEvent,
] = @ecs.register_message(debug_name="input.gamepad.GamepadAxisChangedEvent")

///|
let raw_gamepad_button_changed_event_message_key : @ecs.MessageKey[
  RawGamepadButtonChangedEvent,
] = @ecs.register_message(
  debug_name="input.gamepad.RawGamepadButtonChangedEvent",
)

///|
let gamepad_button_changed_event_message_key : @ecs.MessageKey[
  GamepadButtonChangedEvent,
] = @ecs.register_message(debug_name="input.gamepad.GamepadButtonChangedEvent")

///|
let gamepad_button_state_changed_event_message_key : @ecs.MessageKey[
  GamepadButtonStateChangedEvent,
] = @ecs.register_message(
  debug_name="input.gamepad.GamepadButtonStateChangedEvent",
)

///|
let gamepad_rumble_request_message_key : @ecs.MessageKey[GamepadRumbleRequest] = @ecs.register_message(
  debug_name="input.gamepad.GamepadRumbleRequest",
)

///|
let input_gamepad_poll_system_set : @app.SystemSet = @app.system_set(
  "input.gamepad.poll",
)

///|
let input_gamepad_connection_system_set : @app.SystemSet = @app.system_set(
  "input.gamepad.connection",
)

///|
let input_gamepad_event_processing_system_set : @app.SystemSet = @app.system_set(
  "input.gamepad.event_processing",
)

///|
let input_gamepad_rumble_system_set : @app.SystemSet = @app.system_set(
  "input.gamepad.rumble",
)

///|
fn float_is_nan(value : Float) -> Bool {
  value != value
}

///|
fn optional_device_id(value : Int) -> Int? {
  if value < 0 {
    None
  } else {
    Some(value)
  }
}

///|
fn host_gamepad_name(gamepad_id : Int) -> String {
  let len = host_input_gamepad_name_len(gamepad_id)
  if len <= 0 {
    return ""
  }
  let chars : Array[Char] = []
  for i in 0..<len {
    let code_unit = host_input_gamepad_name_code_unit(gamepad_id~, offset=i)
    if code_unit.to_char() is Some(ch) {
      chars.push(ch)
    } else {
      chars.push(Int::unsafe_to_char(0xFFFD))
    }
  }
  String::from_array(chars)
}

///|
fn mapped_gamepad_entity(host_id : Int) -> @core.Entity? {
  for entry in host_gamepad_entities_ref.val {
    if entry.0 == host_id {
      return Some(entry.1)
    }
  }
  None
}

///|
fn remember_gamepad_entity(host_id : Int, entity : @core.Entity) -> Unit {
  for i in 0..<host_gamepad_entities_ref.val.length() {
    if host_gamepad_entities_ref.val[i].0 == host_id {
      host_gamepad_entities_ref.val[i] = (host_id, entity)
      return
    }
  }
  host_gamepad_entities_ref.val.push((host_id, entity))
}

///|
fn ensure_gamepad_entity(world : @ecs.World, host_id : Int) -> @core.Entity {
  if mapped_gamepad_entity(host_id) is Some(entity) && world.is_alive(entity) {
    entity
  } else {
    let entity = world.spawn_empty()
    remember_gamepad_entity(host_id, entity)
    entity
  }
}

///|
fn mapped_host_gamepad_id(entity : @core.Entity) -> Int? {
  for entry in host_gamepad_entities_ref.val {
    if entry.1 == entity {
      return Some(entry.0)
    }
  }
  None
}

///|
fn clamp_rumble_motor(value : Float) -> Float {
  if value <= 0.0F {
    0.0F
  } else if value >= 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn duration_millis(duration : @core.Duration) -> Int64 {
  duration.as_millis()
}

///|
fn deadline_after(now_ms : Int64, duration : @core.Duration) -> Int64 {
  let duration_ms = duration_millis(duration)
  if duration_ms <= 0L {
    now_ms
  } else if now_ms >= 9_223_372_036_854_775_807L - duration_ms {
    9_223_372_036_854_775_807L
  } else {
    now_ms + duration_ms
  }
}

///|
fn current_real_time_millis(real_time : @app.Res[@time.Real]) -> Int64 {
  @core.Duration::from_secs_f32(real_time.get().elapsed_seconds()).as_millis()
}

///|
fn running_rumble_entry_index(
  effects : RunningRumbleEffects,
  entity : @core.Entity,
) -> Int? {
  for i in 0..<effects.entries.length() {
    if effects.entries[i].entity == entity {
      return Some(i)
    }
  }
  None
}

///|
fn ensure_running_rumble_entry_index(
  effects : RunningRumbleEffects,
  entity : @core.Entity,
) -> Int {
  match running_rumble_entry_index(effects, entity) {
    Some(index) => index
    None => {
      effects.entries.push(RunningRumbleEntry::{
        entity,
        rumbles: [],
        last_applied: None,
      })
      effects.entries.length() - 1
    }
  }
}

///|
fn prune_expired_rumbles(entry : RunningRumbleEntry, now_ms : Int64) -> Unit {
  let kept : Array[RunningRumble] = []
  for rumble in entry.rumbles {
    if rumble.deadline_ms > now_ms {
      kept.push(rumble)
    }
  }
  entry.rumbles = kept
}

///|
fn desired_rumble(entry : RunningRumbleEntry) -> AppliedRumble? {
  if entry.rumbles.length() == 0 {
    return None
  }

  let mut strong_motor = 0.0F
  let mut weak_motor = 0.0F
  let mut deadline_ms = 0L
  for rumble in entry.rumbles {
    strong_motor = clamp_rumble_motor(
      strong_motor + rumble.intensity.strong_motor,
    )
    weak_motor = clamp_rumble_motor(weak_motor + rumble.intensity.weak_motor)
    if rumble.deadline_ms > deadline_ms {
      deadline_ms = rumble.deadline_ms
    }
  }

  Some(AppliedRumble::{ strong_motor, weak_motor, deadline_ms })
}

///|
fn read_gamepad_snapshot(
  host_id : Int,
  entity : @core.Entity,
) -> GamepadSnapshot {
  let button_values : Array[Float] = []
  let axis_values : Array[Float] = []
  for i in 0..<GAMEPAD_BUTTON_COUNT {
    button_values.push(
      host_input_gamepad_button_value(gamepad_id=host_id, button=i),
    )
  }
  for i in 0..<GAMEPAD_AXIS_COUNT {
    axis_values.push(host_input_gamepad_axis_value(gamepad_id=host_id, axis=i))
  }
  GamepadSnapshot::{
    host_id,
    entity,
    name: host_gamepad_name(host_id),
    vendor_id: optional_device_id(host_input_gamepad_vendor_id(host_id)),
    product_id: optional_device_id(host_input_gamepad_product_id(host_id)),
    connected: host_input_gamepad_connected(host_id),
    button_values,
    axis_values,
  }
}

///|
fn find_gamepad_snapshot(
  snapshots : Array[GamepadSnapshot],
  host_id : Int,
) -> GamepadSnapshot? {
  for snapshot in snapshots {
    if snapshot.host_id == host_id {
      return Some(snapshot)
    }
  }
  None
}

///|
fn should_emit_value_change(previous : Float?, current : Float) -> Bool {
  if float_is_nan(current) {
    return false
  }
  match previous {
    None => current != 0.0F
    Some(prev) =>
      if float_is_nan(prev) {
        current != 0.0F
      } else {
        prev != current
      }
  }
}

///|
fn emit_raw_connection_event(
  world : @ecs.World,
  event : GamepadConnectionEvent,
) -> Unit {
  world.send_message(gamepad_connection_event_message_key, event) |> ignore
  world.send_message(
    raw_gamepad_event_message_key,
    RawGamepadEvent::Connection(event),
  )
  |> ignore
}

///|
fn emit_raw_button_changed_event(
  world : @ecs.World,
  event : RawGamepadButtonChangedEvent,
) -> Unit {
  world.send_message(raw_gamepad_button_changed_event_message_key, event)
  |> ignore
  world.send_message(
    raw_gamepad_event_message_key,
    RawGamepadEvent::Button(event),
  )
  |> ignore
}

///|
fn emit_raw_axis_changed_event(
  world : @ecs.World,
  event : RawGamepadAxisChangedEvent,
) -> Unit {
  world.send_message(raw_gamepad_axis_changed_event_message_key, event)
  |> ignore
  world.send_message(
    raw_gamepad_event_message_key,
    RawGamepadEvent::Axis(event),
  )
  |> ignore
}

///|
fn emit_initial_raw_events(
  snapshot : GamepadSnapshot,
  world : @ecs.World,
) -> Unit {
  for i in 0..<snapshot.button_values.length() {
    let value = snapshot.button_values[i]
    if should_emit_value_change(None, value) {
      emit_raw_button_changed_event(
        world,
        RawGamepadButtonChangedEvent::new(
          snapshot.entity,
          gamepad_button_from_index(i),
          value,
        ),
      )
    }
  }
  for i in 0..<snapshot.axis_values.length() {
    let value = snapshot.axis_values[i]
    if should_emit_value_change(None, value) {
      emit_raw_axis_changed_event(
        world,
        RawGamepadAxisChangedEvent::new(
          snapshot.entity,
          gamepad_axis_from_index(i),
          value,
        ),
      )
    }
  }
}

///|
fn emit_changed_raw_events(
  previous : GamepadSnapshot,
  current : GamepadSnapshot,
  world : @ecs.World,
) -> Unit {
  for i in 0..<current.button_values.length() {
    let current_value = current.button_values[i]
    let previous_value = if i < previous.button_values.length() {
      Some(previous.button_values[i])
    } else {
      None
    }
    if should_emit_value_change(previous_value, current_value) {
      emit_raw_button_changed_event(
        world,
        RawGamepadButtonChangedEvent::new(
          current.entity,
          gamepad_button_from_index(i),
          current_value,
        ),
      )
    }
  }
  for i in 0..<current.axis_values.length() {
    let current_value = current.axis_values[i]
    let previous_value = if i < previous.axis_values.length() {
      Some(previous.axis_values[i])
    } else {
      None
    }
    if should_emit_value_change(previous_value, current_value) {
      emit_raw_axis_changed_event(
        world,
        RawGamepadAxisChangedEvent::new(
          current.entity,
          gamepad_axis_from_index(i),
          current_value,
        ),
      )
    }
  }
}

///|
fn rebuild_gamepad_events(
  previous_gamepads : Array[GamepadSnapshot],
  current_gamepads : Array[GamepadSnapshot],
  world : @ecs.World,
) -> Unit {
  for current in current_gamepads {
    if !current.connected {
      continue
    }
    match find_gamepad_snapshot(previous_gamepads, current.host_id) {
      Some(previous) if previous.entity == current.entity => ()
      _ => {
        emit_raw_connection_event(
          world,
          GamepadConnectionEvent::new(
            current.entity,
            GamepadConnection::Connected(
              GamepadConnectionInfo::new(
                current.name,
                current.vendor_id,
                current.product_id,
              ),
            ),
          ),
        )
        emit_initial_raw_events(current, world)
      }
    }
  }

  for previous in previous_gamepads {
    if previous.connected &&
      find_gamepad_snapshot(current_gamepads, previous.host_id) is None {
      emit_raw_connection_event(
        world,
        GamepadConnectionEvent::new(
          previous.entity,
          GamepadConnection::Disconnected,
        ),
      )
    }
  }

  for current in current_gamepads {
    guard current.connected else { continue }
    if find_gamepad_snapshot(previous_gamepads, current.host_id)
      is Some(previous) &&
      previous.entity == current.entity {
      emit_changed_raw_events(previous, current, world)
    }
  }
}

///|
fn current_gamepad_world_abort_missing() -> @ecs.World {
  match @app.current_world() {
    Some(world) => world
    None => abort("Missing current world while processing gamepad events")
  }
}

///|
fn gamepad_connection_system(
  connection_events : @ecs.MessageReader[GamepadConnectionEvent],
) -> Unit {
  let world = current_gamepad_world_abort_missing()
  for connection_event in (try! connection_events.read()) {
    let entity = connection_event.gamepad
    guard world.is_alive(entity) else { continue }
    match connection_event.connection {
      Connected(info) => {
        try! world.set_component(entity, @ecs.Name::new(info.name))
        try! world.set_component(entity, Gamepad::{
          vendor_id: info.vendor_id,
          product_id: info.product_id,
          digital: ButtonInput::new(),
          analog: default_gamepad_analog(),
        })
      }
      Disconnected => try! (world.remove(entity, ecs_key_gamepad) |> ignore)
    }
  }
}

///|
priv struct GamepadProcessedEventWriters {
  gamepad_events : @ecs.MessageWriter[GamepadEvent]
  axis_events : @ecs.MessageWriter[GamepadAxisChangedEvent]
  button_events : @ecs.MessageWriter[GamepadButtonChangedEvent]
  button_state_events : @ecs.MessageWriter[GamepadButtonStateChangedEvent]
}

///|
impl @app.SystemParam for GamepadProcessedEventWriters with init_state(world) {
  @app.system_param_empty_state(world)
}

///|
impl @app.SystemParam for GamepadProcessedEventWriters with get(_state) {
  let world = current_gamepad_world_abort_missing()
  GamepadProcessedEventWriters::{
    gamepad_events: world.message_writer(gamepad_event_message_key),
    axis_events: world.message_writer(gamepad_axis_changed_event_message_key),
    button_events: world.message_writer(
      gamepad_button_changed_event_message_key,
    ),
    button_state_events: world.message_writer(
      gamepad_button_state_changed_event_message_key,
    ),
  }
}

///|
impl @app.SystemParam for GamepadProcessedEventWriters with store(self, state) {
  @app.system_param_store_no_state(self, state)
}

///|
fn gamepad_event_processing_system(
  gamepads : @ecs.Query2ValueMutFiltered[GamepadSettings, Gamepad, @ecs.All],
  raw_events : @ecs.MessageReader[RawGamepadEvent],
  outputs : GamepadProcessedEventWriters,
) -> Unit {
  try! gamepads.view_mut(fn(_entity, _settings, gamepad_mut) {
    let gamepad_ref = gamepad_mut.get_ref()
    let gamepad = gamepad_ref.val
    let digital = gamepad.digital
    digital.clear()
    gamepad_ref.val = Gamepad::{ ..gamepad, digital, }
  })

  for raw_event in (try! raw_events.read()) {
    match raw_event {
      Connection(connection_event) =>
        outputs.gamepad_events.write(GamepadEvent::Connection(connection_event))
        |> ignore
      Axis(axis_event) =>
        try! (gamepads.with_mut(axis_event.gamepad, fn(settings, gamepad_mut) {
          let old_value = gamepad_mut.get_ref().val.analog.get(
            GamepadInput::Axis(axis_event.axis),
          )
          if settings
            .get_axis_settings(axis_event.axis)
            .filter(axis_event.value, old_value)
            is Some(filtered_value) {
            gamepad_mut.get_ref().val.analog.set(
              GamepadInput::Axis(axis_event.axis),
              filtered_value.raw,
            )
            |> ignore
            let event = GamepadAxisChangedEvent::new(
              axis_event.gamepad,
              axis_event.axis,
              filtered_value.scaled.to_f32(),
            )
            outputs.axis_events.write(event) |> ignore
            outputs.gamepad_events.write(GamepadEvent::Axis(event)) |> ignore
          }
        })
        |> ignore)
      Button(button_event) =>
        try! (gamepads.with_mut(button_event.gamepad, fn(
          settings,
          gamepad_mut,
        ) {
          let gamepad_ref = gamepad_mut.get_ref()
          let old_value = gamepad_ref.val.analog.get(
            GamepadInput::Button(button_event.button),
          )
          if settings
            .get_button_axis_settings(button_event.button)
            .filter(button_event.value, old_value)
            is Some(filtered_value) {
            let button_settings = settings.get_button_settings(
              button_event.button,
            )
            gamepad_ref.val.analog.set(
              GamepadInput::Button(button_event.button),
              filtered_value.raw,
            )
            |> ignore
            let was_pressed = gamepad_ref.val.digital.pressed(
              button_event.button,
            )

            if button_settings.is_released(filtered_value.raw) {
              if was_pressed {
                outputs.button_state_events.write(
                  GamepadButtonStateChangedEvent::new(
                    button_event.gamepad,
                    button_event.button,
                    ButtonState::Released,
                  ),
                )
                |> ignore
              }
              gamepad_ref.val.digital.release(button_event.button)
            } else if button_settings.is_pressed(filtered_value.raw) {
              if !was_pressed {
                outputs.button_state_events.write(
                  GamepadButtonStateChangedEvent::new(
                    button_event.gamepad,
                    button_event.button,
                    ButtonState::Pressed,
                  ),
                )
                |> ignore
              }
              gamepad_ref.val.digital.press(button_event.button)
            }

            let button_state = if gamepad_ref.val.digital.pressed(
                button_event.button,
              ) {
              ButtonState::Pressed
            } else {
              ButtonState::Released
            }
            let event = GamepadButtonChangedEvent::new(
              button_event.gamepad,
              button_event.button,
              button_state,
              filtered_value.scaled.to_f32(),
            )
            outputs.button_events.write(event) |> ignore
            outputs.gamepad_events.write(GamepadEvent::Button(event)) |> ignore
          }
        })
        |> ignore)
    }
  }
}

///|
fn gamepad_rumble_system(
  requests : @ecs.MessageReader[GamepadRumbleRequest],
  running_rumbles : @app.ResMut[RunningRumbleEffects],
  real_time : @app.Res[@time.Real],
) -> Unit {
  let now_ms = current_real_time_millis(real_time)
  let effects_ref = running_rumbles.get_ref()

  for i in 0..<effects_ref.val.entries.length() {
    let entry = effects_ref.val.entries[i]
    prune_expired_rumbles(entry, now_ms)
    effects_ref.val.entries[i] = entry
  }

  for request in (try! requests.read()) {
    let entity = request.gamepad()
    let host_id = match mapped_host_gamepad_id(entity) {
      Some(host_id) => host_id
      None => continue
    }
    let index = ensure_running_rumble_entry_index(effects_ref.val, entity)
    let entry = effects_ref.val.entries[index]

    match request {
      Add(duration~, intensity~, ..) => {
        if duration.is_zero() ||
          !host_input_gamepad_connected(host_id) ||
          !host_input_gamepad_ff_supported(host_id) {
          continue
        }
        entry.rumbles.push(RunningRumble::{
          deadline_ms: deadline_after(now_ms, duration),
          intensity: GamepadRumbleIntensity::{
            strong_motor: clamp_rumble_motor(intensity.strong_motor),
            weak_motor: clamp_rumble_motor(intensity.weak_motor),
          },
        })
      }
      Stop(..) => entry.rumbles.clear()
    }
    effects_ref.val.entries[index] = entry
  }

  for i in 0..<effects_ref.val.entries.length() {
    let entry = effects_ref.val.entries[i]
    prune_expired_rumbles(entry, now_ms)
    match desired_rumble(entry) {
      Some(desired) => {
        let should_apply = match entry.last_applied {
          Some(applied) =>
            applied.strong_motor != desired.strong_motor ||
            applied.weak_motor != desired.weak_motor ||
            applied.deadline_ms != desired.deadline_ms
          None => true
        }
        if !should_apply {
          continue
        }

        let host_id = match mapped_host_gamepad_id(entry.entity) {
          Some(host_id) => host_id
          None => {
            entry.rumbles.clear()
            entry.last_applied = None
            continue
          }
        }
        let duration_ms = desired.deadline_ms - now_ms
        match
          host_input_gamepad_set_rumble(
            host_id,
            desired.strong_motor,
            desired.weak_motor,
            duration_ms,
          ) {
          @native_input.GamepadRumbleResult::Applied =>
            entry.last_applied = Some(desired)
          @native_input.GamepadRumbleResult::Unsupported
          | @native_input.GamepadRumbleResult::NotFound => {
            entry.rumbles.clear()
            entry.last_applied = None
          }
        }
      }
      None =>
        if entry.last_applied is Some(_) {
          if mapped_host_gamepad_id(entry.entity) is Some(host_id) {
            ignore(host_input_gamepad_set_rumble(host_id, 0.0F, 0.0F, 0L))
          }
          entry.last_applied = None
        }
    }
    effects_ref.val.entries[i] = entry
  }

  let kept_entries : Array[RunningRumbleEntry] = []
  for entry in effects_ref.val.entries {
    if entry.rumbles.length() > 0 || entry.last_applied is Some(_) {
      kept_entries.push(entry)
    }
  }
  effects_ref.val.entries = kept_entries
}

///|
pub impl @ecs.Message for GamepadEvent with message() {
  gamepad_event_message_key
}

///|
pub impl @ecs.Message for GamepadConnectionEvent with message() {
  gamepad_connection_event_message_key
}

///|
pub impl @ecs.Message for RawGamepadAxisChangedEvent with message() {
  raw_gamepad_axis_changed_event_message_key
}

///|
pub impl @ecs.Message for GamepadAxisChangedEvent with message() {
  gamepad_axis_changed_event_message_key
}

///|
pub impl @ecs.Message for RawGamepadButtonChangedEvent with message() {
  raw_gamepad_button_changed_event_message_key
}

///|
pub impl @ecs.Message for GamepadButtonChangedEvent with message() {
  gamepad_button_changed_event_message_key
}

///|
pub impl @ecs.Message for GamepadButtonStateChangedEvent with message() {
  gamepad_button_state_changed_event_message_key
}

///|
pub impl @ecs.Message for RawGamepadEvent with message() {
  raw_gamepad_event_message_key
}

///|
pub impl @ecs.Message for GamepadRumbleRequest with message() {
  gamepad_rumble_request_message_key
}

///|
pub fn input_gamepad_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  try! app
  .world()
  .register_required_components(ecs_key_gamepad, ecs_key_gamepad_settings)

  app
  .init_resource(fn() { RunningRumbleEffects::default() })
  .add_message(gamepad_event_message_key)
  .add_message(raw_gamepad_event_message_key)
  .add_message(gamepad_connection_event_message_key)
  .add_message(raw_gamepad_axis_changed_event_message_key)
  .add_message(gamepad_axis_changed_event_message_key)
  .add_message(raw_gamepad_button_changed_event_message_key)
  .add_message(gamepad_button_changed_event_message_key)
  .add_message(gamepad_button_state_changed_event_message_key)
  .add_message(gamepad_rumble_request_message_key)
  .add_pre_update_system_config(
    @app.system(input_poll_gamepad_system).in_set(input_gamepad_poll_system_set),
  )
  .add_pre_update_system_config(
    @app.system(@app.system_param(gamepad_connection_system))
    .in_set(input_gamepad_connection_system_set)
    .after(input_gamepad_poll_system_set),
  )
  .add_pre_update_system_config(
    @app.system(@app.system_param3(gamepad_event_processing_system))
    .in_set(input_gamepad_event_processing_system_set)
    .after(input_gamepad_connection_system_set),
  )
  .add_post_update_system_config(
    @app.system(@app.system_param3(gamepad_rumble_system)).in_set(
      input_gamepad_rumble_system_set,
    ),
  )
}

///|
pub fn input_poll_gamepad_system(world : @ecs.World) -> Unit {
  host_input_gamepad_poll()

  previous_gamepads_ref.val = current_gamepads_ref.val

  let next_gamepads : Array[GamepadSnapshot] = []
  let n = host_input_gamepad_count()
  for i in 0..<n {
    let host_id = host_input_gamepad_id(i)
    if host_id >= 0 {
      let entity = ensure_gamepad_entity(world, host_id)
      let snapshot = read_gamepad_snapshot(host_id, entity)
      if snapshot.connected {
        next_gamepads.push(snapshot)
      }
    }
  }

  current_gamepads_ref.val = next_gamepads
  rebuild_gamepad_events(
    previous_gamepads_ref.val,
    current_gamepads_ref.val,
    world,
  )
}

///|
pub fn input_gamepad_finish_frame() -> Unit {
  previous_gamepads_ref.val = current_gamepads_ref.val
}
