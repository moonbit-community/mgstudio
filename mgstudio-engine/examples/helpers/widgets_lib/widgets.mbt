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
const BUTTON_BORDER_WIDTH : Float = 1.0F

///|
const BUTTON_BORDER_RADIUS : Float = 6.0F

///|
const BUTTON_HORIZONTAL_PADDING : Float = 12.0F

///|
const BUTTON_VERTICAL_PADDING : Float = 6.0F

///|
const BUTTON_LABEL_FONT_SIZE : Float = 18.0F

///|
const OPTION_TITLE_WIDTH : Float = 150.0F

///|
let widget_click_event_registry : Ref[@hashmap.HashMap[String, @any.Any]] = Ref(
  @hashmap.HashMap([]),
)

///|
let widget_click_sender_registry : Ref[@hashmap.HashMap[String, @any.Any]] = Ref(
  @hashmap.HashMap([]),
)

///|
pub struct WidgetClickEvent[T] {
  value : T
}

///|
pub fn[T] WidgetClickEvent::new(value : T) -> WidgetClickEvent[T] {
  WidgetClickEvent::{ value, }
}

///|
pub fn[T] WidgetClickEvent::get(self : WidgetClickEvent[T]) -> T {
  self.value
}

///|
pub struct WidgetClickSender[T] {
  value : T
}

///|
pub fn[T] WidgetClickSender::new(value : T) -> WidgetClickSender[T] {
  WidgetClickSender::{ value, }
}

///|
pub fn[T] WidgetClickSender::get(self : WidgetClickSender[T]) -> T {
  self.value
}

///|
pub struct RadioButton {}

///|
pub struct RadioButtonText {}

///|
let radio_button_key : @ecs.ComponentKey[RadioButton] = @ecs.register_component(
  debug_name="examples.helpers.widgets_lib.RadioButton",
)

///|
let radio_button_text_key : @ecs.ComponentKey[RadioButtonText] = @ecs.register_component(
  debug_name="examples.helpers.widgets_lib.RadioButtonText",
)

///|
pub impl @ecs.Component for RadioButton with component() {
  radio_button_key
}

///|
pub impl @ecs.Component for RadioButtonText with component() {
  radio_button_text_key
}

///|
pub fn[T] widget_click_event_key() -> @ecs.MessageKey[WidgetClickEvent[T]] {
  let probe : T? = None
  let type_name = "examples.helpers.widgets_lib.WidgetClickEvent<\{@any.of(probe).type_name()}>"
  match widget_click_event_registry.val.get(type_name) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None => abort("widget click event registry mismatch for \{type_name}")
      }
    None => {
      let key : @ecs.MessageKey[WidgetClickEvent[T]] = @ecs.register_message(
        debug_name=type_name,
      )
      widget_click_event_registry.val.set(type_name, @any.of(key))
      key
    }
  }
}

///|
pub fn[T] widget_click_sender_key() -> @ecs.ComponentKey[WidgetClickSender[T]] {
  let probe : T? = None
  let type_name = "examples.helpers.widgets_lib.WidgetClickSender<\{@any.of(probe).type_name()}>"
  match widget_click_sender_registry.val.get(type_name) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None => abort("widget click sender registry mismatch for \{type_name}")
      }
    None => {
      let key : @ecs.ComponentKey[WidgetClickSender[T]] = @ecs.register_component(
        debug_name=type_name,
      )
      widget_click_sender_registry.val.set(type_name, @any.of(key))
      key
    }
  }
}

///|
pub impl[T] @ecs.Message for WidgetClickEvent[T] with message() {
  widget_click_event_key()
}

///|
pub impl[T] @ecs.Component for WidgetClickSender[T] with component() {
  widget_click_sender_key()
}

///|
fn white() -> @sprite.Color {
  @sprite.Color::white()
}

///|
fn black() -> @sprite.Color {
  @sprite.Color::black()
}

///|
fn button_padding() -> @ui.UiRect {
  @ui.UiRect::new(
    @ui.Val::Px(BUTTON_HORIZONTAL_PADDING),
    @ui.Val::Px(BUTTON_VERTICAL_PADDING),
    @ui.Val::Px(BUTTON_HORIZONTAL_PADDING),
    @ui.Val::Px(BUTTON_VERTICAL_PADDING),
  )
}

///|
fn button_border(left_width : Float) -> @ui.UiRect {
  @ui.UiRect::new(
    @ui.Val::Px(left_width),
    @ui.Val::Px(BUTTON_BORDER_WIDTH),
    @ui.Val::Px(BUTTON_BORDER_WIDTH),
    @ui.Val::Px(BUTTON_BORDER_WIDTH),
  )
}

///|
fn option_button_border_radius(
  is_first : Bool,
  is_last : Bool,
) -> @ui.BorderRadius {
  let radius = @ui.Val::Px(BUTTON_BORDER_RADIUS)
  let zero = @ui.Val::Px(0.0F)
  @ui.BorderRadius::new(
    if is_first {
      radius
    } else {
      zero
    },
    if is_last {
      radius
    } else {
      zero
    },
    if is_last {
      radius
    } else {
      zero
    },
    if is_first {
      radius
    } else {
      zero
    },
  )
}

///|
fn radio_button_background_color(selected : Bool) -> @sprite.Color {
  if selected {
    white()
  } else {
    black()
  }
}

///|
fn radio_button_foreground_color(selected : Bool) -> @sprite.Color {
  if selected {
    black()
  } else {
    white()
  }
}

///|
pub fn main_ui_node() -> @ui.Node {
  @ui.Node::default()
  .with_flex_direction(@ui.FlexDirection::Column)
  .with_position_type(@ui.PositionType::Absolute)
  .with_row_gap(@ui.Val::Px(6.0F))
  .with_left(@ui.Val::Px(10.0F))
  .with_bottom(@ui.Val::Px(10.0F))
}

///|
pub fn ui_text(
  label : String,
  color : @sprite.Color,
) -> (@text.Text, @text.TextFont, @text.TextColor) {
  (
    @text.Text::new(label),
    @text.TextFont::default().with_font_size(BUTTON_LABEL_FONT_SIZE),
    @text.TextColor::new(color),
  )
}

///|
pub fn[T] spawn_action_button(
  commands : @app.Commands,
  parent : @core.Entity,
  value : T,
  label : String,
) -> @core.Entity {
  let (text, text_font, text_color) = ui_text(label, white())
  let button = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @ui.Button::default(),
      @ui.Node::default()
      .with_border(@ui.UiRect::all(@ui.Val::Px(BUTTON_BORDER_WIDTH)))
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center)
      .with_padding(button_padding())
      .with_border_radius(
        @ui.BorderRadius::all(@ui.Val::Px(BUTTON_BORDER_RADIUS)),
      ),
      @ui.BorderColor::new(white()),
      @ui.BackgroundColor::new(black()),
      WidgetClickSender::new(value),
    ),
  )
  ignore(
    commands.spawn(
      (@hierarchy.Parent::new(button), text, text_font, text_color),
    ),
  )
  button
}

///|
pub fn[T] spawn_option_button(
  commands : @app.Commands,
  parent : @core.Entity,
  option_value : T,
  option_name : String,
  is_selected : Bool,
  is_first : Bool,
  is_last : Bool,
) -> @core.Entity {
  let foreground_color = radio_button_foreground_color(is_selected)
  let (text, text_font, text_color) = ui_text(option_name, foreground_color)
  let button = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @ui.Button::default(),
      @ui.Node::default()
      .with_border(
        button_border(if is_first { BUTTON_BORDER_WIDTH } else { 0.0F }),
      )
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center)
      .with_padding(button_padding())
      .with_border_radius(option_button_border_radius(is_first, is_last)),
      @ui.BorderColor::new(white()),
      @ui.BackgroundColor::new(radio_button_background_color(is_selected)),
      RadioButton::{  },
      WidgetClickSender::new(option_value),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(button),
        text,
        text_font,
        text_color,
        RadioButtonText::{  },
        WidgetClickSender::new(option_value),
      ),
    ),
  )
  button
}

///|
pub fn[T] spawn_option_buttons(
  commands : @app.Commands,
  parent : @core.Entity,
  title : String,
  options : Array[(T, String)],
  selected_index : Int,
) -> @core.Entity {
  let (text, text_font, text_color) = ui_text(title, white())
  let row = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @ui.Node::default().with_align_items(@ui.AlignItems::Center),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(row),
        @ui.Node::default().with_width(@ui.Val::Px(OPTION_TITLE_WIDTH)),
        text,
        text_font,
        text_color,
      ),
    ),
  )

  for index in 0..<options.length() {
    let (option_value, option_name) = options[index]
    ignore(
      spawn_option_button(
        commands,
        row,
        option_value,
        option_name,
        index == selected_index,
        index == 0,
        index == options.length() - 1,
      ),
    )
  }
  row
}

///|
pub fn[T] handle_ui_interactions(
  interactions : @ecs.Query[
    (@ecs.Comp[@ui.Interaction], @ecs.Comp[WidgetClickSender[T]]),
    @ecs.With[@ui.Button],
  ],
  widget_click_events : @ecs.MessageWriter[WidgetClickEvent[T]],
) -> Unit {
  try! interactions.for_each(fn(_entity, data) {
    let (interaction, click_sender) = data
    if interaction.value() == @ui.Interaction::Pressed {
      ignore(
        widget_click_events.write(
          WidgetClickEvent::new(click_sender.value().get()),
        ),
      )
    }
  })
}

///|
pub fn update_ui_radio_button(
  background_color : @ecs.Mut[@ui.BackgroundColor],
  selected : Bool,
) -> Unit {
  background_color.set(
    @ui.BackgroundColor::new(radio_button_background_color(selected)),
  )
}

///|
pub fn update_ui_radio_button_text(
  text_color : @ecs.Mut[@text.TextColor],
  selected : Bool,
) -> Unit {
  text_color.set(@text.TextColor::new(radio_button_foreground_color(selected)))
}
