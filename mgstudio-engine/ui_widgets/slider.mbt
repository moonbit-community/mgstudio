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
// Bevy source: `bevy/crates/bevy_ui_widgets/src/slider.rs`.
pub(all) enum TrackClick {
  Drag
  Step
  Snap
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn TrackClick::default() -> TrackClick {
  TrackClick::Drag
}

///|
pub struct Slider {
  track_click : TrackClick
} derive(ToJson, FromJson)

///|
pub fn Slider::default() -> Slider {
  Slider::{ track_click: TrackClick::default() }
}

///|
pub struct SliderThumb {} derive(ToJson, FromJson)

///|
pub struct SliderValue {
  value : Float
} derive(ToJson, FromJson)

///|
pub fn SliderValue::default() -> SliderValue {
  SliderValue::{ value: 0.0F }
}

///|
pub fn SliderValue::new(value : Float) -> SliderValue {
  SliderValue::{ value, }
}

///|
pub fn SliderValue::value(self : SliderValue) -> Float {
  self.value
}

///|
pub struct SliderRange {
  start : Float
  end : Float
} derive(ToJson, FromJson)

///|
pub fn SliderRange::default() -> SliderRange {
  SliderRange::{ start: 0.0F, end: 1.0F }
}

///|
pub fn SliderRange::new(start : Float, end : Float) -> SliderRange {
  SliderRange::{ start, end }
}

///|
pub fn SliderRange::start(self : SliderRange) -> Float {
  self.start
}

///|
pub fn SliderRange::end(self : SliderRange) -> Float {
  self.end
}

///|
pub fn SliderRange::span(self : SliderRange) -> Float {
  self.end - self.start
}

///|
pub fn SliderRange::center(self : SliderRange) -> Float {
  (self.start + self.end) * 0.5F
}

///|
pub fn SliderRange::clamp(self : SliderRange, value : Float) -> Float {
  value.clamp(min=self.start, max=self.end)
}

///|
pub fn SliderRange::thumb_position(self : SliderRange, value : Float) -> Float {
  if self.end > self.start {
    (value - self.start) / (self.end - self.start)
  } else {
    0.5F
  }
}

///|
pub struct SliderStep {
  value : Float
} derive(ToJson, FromJson)

///|
pub fn SliderStep::default() -> SliderStep {
  SliderStep::{ value: 1.0F }
}

///|
pub fn SliderStep::new(value : Float) -> SliderStep {
  SliderStep::{ value, }
}

///|
pub fn SliderStep::value(self : SliderStep) -> Float {
  self.value
}

///|
pub struct SliderPrecision {
  digits : Int
} derive(ToJson, FromJson)

///|
pub fn SliderPrecision::default() -> SliderPrecision {
  SliderPrecision::{ digits: 0 }
}

///|
pub fn SliderPrecision::new(digits : Int) -> SliderPrecision {
  SliderPrecision::{ digits, }
}

///|
pub fn SliderPrecision::round(self : SliderPrecision, value : Float) -> Float {
  let factor = @math.pow(10.0F, Float::from_int(self.digits))
  (value * factor).round() / factor
}

///|
pub let ecs_key_slider : @ecs.ComponentKey[Slider] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::Slider",
)

///|
pub let ecs_key_slider_thumb : @ecs.ComponentKey[SliderThumb] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::SliderThumb",
)

///|
pub let ecs_key_slider_value : @ecs.ComponentKey[SliderValue] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::SliderValue",
)

///|
pub let ecs_key_slider_range : @ecs.ComponentKey[SliderRange] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::SliderRange",
)

///|
pub let ecs_key_slider_step : @ecs.ComponentKey[SliderStep] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::SliderStep",
)

///|
pub let ecs_key_slider_precision : @ecs.ComponentKey[SliderPrecision] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::SliderPrecision",
)

///|
pub impl @ecs.Component for Slider with component() {
  ecs_key_slider
}

///|
pub impl @ecs.Component for SliderThumb with component() {
  ecs_key_slider_thumb
}

///|
pub impl @ecs.Component for SliderValue with component() {
  ecs_key_slider_value
}

///|
pub impl @ecs.Component for SliderRange with component() {
  ecs_key_slider_range
}

///|
pub impl @ecs.Component for SliderStep with component() {
  ecs_key_slider_step
}

///|
pub impl @ecs.Component for SliderPrecision with component() {
  ecs_key_slider_precision
}

///|
pub struct SetSliderValue {
  mut entity : @core.Entity
  value : Float
} derive(ToJson, FromJson)

///|
let set_slider_value_event_key : @ecs.EventKey[SetSliderValue] = @ecs.register_event(
  debug_name="mgstudio_ui_widgets::SetSliderValue",
)

///|
pub impl @ecs.TriggerEvent for SetSliderValue with observer_event() {
  set_slider_value_event_key
}

///|
pub impl @ecs.TriggerEvent for SetSliderValue with observer_entity(self) {
  Some(self.entity)
}

///|
pub impl @ecs.TriggerEvent for SetSliderValue with set_observer_entity(
  event_ref,
  entity,
) {
  event_ref.val.entity = entity
}

///|
pub impl @ecs.TriggerEvent for SetSliderValue with auto_propagate(_self) {
  false
}

///|
pub impl @ecs.TriggerEvent for SetSliderValue with debug_name() {
  "SetSliderValue"
}

///|
fn slider_value_from_pointer(
  slider : Slider,
  current_value : Float,
  range : SliderRange,
  step : SliderStep,
  precision : SliderPrecision?,
  layout : @ui.UiLayout,
  pointer_position : @math.Vec2,
) -> Float {
  let rect = layout.rect()
  let size = rect.size()
  let is_vertical = size.y > size.x
  let axis_size = if is_vertical { size.y } else { size.x }
  let raw_click_value = if axis_size > 0.0F {
    let ratio = if is_vertical {
      ((rect.max.y - pointer_position.y) / size.y).clamp(min=0.0F, max=1.0F)
    } else {
      ((pointer_position.x - rect.min.x) / size.x).clamp(min=0.0F, max=1.0F)
    }
    range.start() + ratio * range.span()
  } else {
    range.center()
  }
  let stepped = match slider.track_click {
    TrackClick::Step =>
      if raw_click_value < current_value {
        current_value - step.value()
      } else {
        current_value + step.value()
      }
    TrackClick::Drag => raw_click_value
    TrackClick::Snap => raw_click_value
  }
  let rounded = match precision {
    Some(precision_comp) => precision_comp.round(stepped)
    None => stepped
  }
  range.clamp(rounded)
}

///|
fn slider_on_pointer_down(
  pointer : @app.OnPointer[@app.PointerDown],
  slider_query : @ecs.Query[
    (
      @ecs.Comp[Slider],
      @ecs.Comp[@ui.UiLayout],
      @ecs.Comp[SliderRange],
      @ecs.Has[InteractionDisabled],
    ),
    @ecs.All,
  ],
  commands : @app.Commands,
) -> Unit {
  guard pointer.target() is Some(entity) else { return }
  guard (slider_query.get(entity) catch { _ => None })
    is Some((slider_comp, layout_comp, range_comp, disabled)) else {
    return
  }
  if disabled.present() {
    return
  }
  let next_value = slider_value_from_pointer(
    slider_comp.value(),
    range_comp.value().start(),
    range_comp.value(),
    SliderStep::default(),
    None,
    layout_comp.value(),
    pointer.position(),
  )
  commands.trigger(ValueChange::{ source: entity, value: next_value })
}

///|
fn slider_on_pointer_click(
  pointer : @app.OnPointer[@app.PointerClick],
  slider_query : @ecs.Query[
    (
      @ecs.Comp[Slider],
      @ecs.Comp[@ui.UiLayout],
      @ecs.Comp[SliderRange],
      @ecs.Has[InteractionDisabled],
    ),
    @ecs.All,
  ],
  commands : @app.Commands,
) -> Unit {
  guard pointer.target() is Some(entity) else { return }
  guard (slider_query.get(entity) catch { _ => None })
    is Some((slider_comp, layout_comp, range_comp, disabled)) else {
    return
  }
  if disabled.present() {
    return
  }
  let next_value = slider_value_from_pointer(
    slider_comp.value(),
    range_comp.value().start(),
    range_comp.value(),
    SliderStep::default(),
    None,
    layout_comp.value(),
    pointer.position(),
  )
  commands.trigger(ValueChange::{ source: entity, value: next_value })
}

///|
fn slider_on_key_input(
  keyboard : @input.ButtonInput[@window.KeyCode],
  focus : @app.Res[@input_focus.InputFocus],
  slider_query : @ecs.Query[
    (
      @ecs.Has[Slider],
      @ecs.Comp[SliderRange],
      @ecs.Comp[SliderValue]?,
      @ecs.Has[InteractionDisabled],
    ),
    @ecs.All,
  ],
  commands : @app.Commands,
) -> Unit {
  guard focus.get().get() is Some(entity) else { return }
  guard (slider_query.get(entity) catch { _ => None })
    is Some((is_slider, range_comp, value_comp, disabled)) else {
    return
  }
  if !is_slider.present() || disabled.present() {
    return
  }
  let range = range_comp.value()
  let step = 1.0F
  let current = match value_comp {
    Some(value) => value.value().value()
    None => range.start()
  }
  let step_direction = if keyboard.just_pressed(@window.KeyCode::ArrowLeft) ||
    keyboard.just_pressed(@window.KeyCode::ArrowDown) ||
    keyboard.just_pressed(@window.KeyCode::PageDown) {
    -step
  } else if keyboard.just_pressed(@window.KeyCode::ArrowRight) ||
    keyboard.just_pressed(@window.KeyCode::ArrowUp) ||
    keyboard.just_pressed(@window.KeyCode::PageUp) {
    step
  } else {
    0.0F
  }
  let next = if step_direction != 0.0F {
    range.clamp(current + step_direction)
  } else {
    return
  }
  commands.trigger(ValueChange::{ source: entity, value: next })
}

///|
fn slider_on_set_value(
  event : @ecs.On[SetSliderValue],
  slider_query : @ecs.Query[
    (
      @ecs.Has[Slider],
      @ecs.Has[InteractionDisabled],
      @ecs.Comp[SliderRange],
      @ecs.Comp[SliderPrecision]?,
    ),
    @ecs.All,
  ],
  commands : @app.Commands,
) -> Unit {
  let payload = event.event()
  let entity = payload.entity
  guard (slider_query.get(entity) catch { _ => None })
    is Some((is_slider, disabled, range_comp, precision_comp)) else {
    return
  }
  if !is_slider.present() || disabled.present() {
    return
  }
  let clamped = range_comp.value().clamp(payload.value)
  let rounded = match precision_comp {
    Some(precision) => precision.value().round(clamped)
    None => clamped
  }
  commands.trigger(ValueChange::{ source: entity, value: rounded })
}

///|
pub fn slider_self_update(
  event : @ecs.On[ValueChange[Float]],
  slider_query : @ecs.Query[@ecs.Has[Slider], @ecs.All],
  commands : @app.Commands,
) -> Unit {
  let payload = event.event()
  let entity = payload.source
  guard (slider_query.get(entity) catch { _ => None }) is Some(is_slider) else {
    return
  }
  if !is_slider.present() {
    return
  }
  commands.entity(entity).insert_component(SliderValue::new(payload.value))
}

///|
pub fn slider_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .add_systems(
    @app.Update,
    @app.system(@app.system_param4(slider_on_key_input)),
  )
  .add_pointer_observer3(slider_on_pointer_down)
  .add_pointer_observer3(slider_on_pointer_click)
  .add_observer3(slider_on_set_value)
}
