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
pub(open) trait WidgetValue {
  fn widget_debug_name() -> String
  fn widget_click_event_key() -> @ecs.MessageKey[WidgetClickEvent[Self]]
  fn widget_click_sender_key() -> @ecs.ComponentKey[WidgetClickSender[Self]]
}

///|
pub struct WidgetClickEvent[T] {
  value : T
}

///|
pub fn[T] WidgetClickEvent::new(value : T) -> WidgetClickEvent[T] {
  { value, }
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
  { value, }
}

///|
pub fn[T] WidgetClickSender::get(self : WidgetClickSender[T]) -> T {
  self.value
}

///|
pub(all) struct RadioButton {}

///|
pub(all) struct RadioButtonText {}

///|
let radio_button_key : @ecs.ComponentKey[RadioButton] = @ecs.register_component(
  debug_name="examples.helpers.widgets_lib.RadioButton",
)

///|
let radio_button_text_key : @ecs.ComponentKey[RadioButtonText] = @ecs.register_component(
  debug_name="examples.helpers.widgets_lib.RadioButtonText",
)

///|
pub impl @ecs.Component for RadioButton with fn component() {
  radio_button_key
}

///|
pub impl @ecs.Component for RadioButtonText with fn component() {
  radio_button_text_key
}

///|
let visibility_widget_click_event_key : @ecs.MessageKey[
  WidgetClickEvent[@visibility.Visibility],
] = @ecs.register_message(
  debug_name="examples.helpers.widgets_lib.WidgetClickEvent<mgstudio_visibility::Visibility>",
)

///|
let visibility_widget_click_sender_key : @ecs.ComponentKey[
  WidgetClickSender[@visibility.Visibility],
] = @ecs.register_component(
  debug_name="examples.helpers.widgets_lib.WidgetClickSender<mgstudio_visibility::Visibility>",
)

///|
pub impl WidgetValue for @visibility.Visibility with fn widget_debug_name() {
  "mgstudio_visibility::Visibility"
}

///|
pub impl WidgetValue for @visibility.Visibility with fn widget_click_event_key() {
  visibility_widget_click_event_key
}

///|
pub impl WidgetValue for @visibility.Visibility with fn widget_click_sender_key() {
  visibility_widget_click_sender_key
}

///|
pub fn[T : WidgetValue] widget_click_event_key() -> @ecs.MessageKey[
  WidgetClickEvent[T],
] {
  T::widget_click_event_key()
}

///|
pub fn[T : WidgetValue] widget_click_sender_key() -> @ecs.ComponentKey[
  WidgetClickSender[T],
] {
  T::widget_click_sender_key()
}

///|
pub impl[T : WidgetValue] @ecs.Message for WidgetClickEvent[T] with fn message() {
  widget_click_event_key()
}

///|
pub impl[T : WidgetValue] @ecs.Component for WidgetClickSender[T] with fn component() {
  widget_click_sender_key()
}

///|
fn white() -> @color.Color {
  @color.Color::white()
}

///|
fn black() -> @color.Color {
  @color.Color::black()
}

///|
fn button_padding() -> @ui.UiRect {
  @ui.UiRect::new(
    Px(BUTTON_HORIZONTAL_PADDING),
    Px(BUTTON_VERTICAL_PADDING),
    Px(BUTTON_HORIZONTAL_PADDING),
    Px(BUTTON_VERTICAL_PADDING),
  )
}

///|
fn button_border(left_width : Float) -> @ui.UiRect {
  @ui.UiRect::new(
    Px(left_width),
    Px(BUTTON_BORDER_WIDTH),
    Px(BUTTON_BORDER_WIDTH),
    Px(BUTTON_BORDER_WIDTH),
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
fn radio_button_background_color(selected : Bool) -> @color.Color {
  if selected {
    white()
  } else {
    black()
  }
}

///|
fn radio_button_foreground_color(selected : Bool) -> @color.Color {
  if selected {
    black()
  } else {
    white()
  }
}

///|
pub fn main_ui_node() -> @ui.Node {
  @ui.Node::Node()
  .with_flex_direction(Column)
  .with_position_type(Absolute)
  .with_row_gap(Px(6.0F))
  .with_left(Px(10.0F))
  .with_bottom(Px(10.0F))
}

///|
pub fn ui_text(
  label : String,
  color : @color.Color,
) -> (@text.Text, @text.TextFont, @text.TextColor) {
  (
    @text.Text::new(label),
    @text.TextFont::TextFont().with_font_size(BUTTON_LABEL_FONT_SIZE),
    @text.TextColor::new(color),
  )
}

///|
pub fn[T : WidgetValue] spawn_action_button(
  commands : @app.Commands,
  parent : @core.Entity,
  value : T,
  label : String,
) -> @core.Entity {
  let (text, text_font, text_color) = ui_text(label, white())
  let button = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @ui.Button::Button(),
      @ui.Node::Node()
      .with_border(@ui.UiRect::all(Px(BUTTON_BORDER_WIDTH)))
      .with_justify_content(Center)
      .with_align_items(Center)
      .with_padding(button_padding())
      .with_border_radius(@ui.BorderRadius::all(Px(BUTTON_BORDER_RADIUS))),
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
pub fn[T : WidgetValue] spawn_option_button(
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
      @ui.Button::Button(),
      @ui.Node::Node()
      .with_border(
        button_border(if is_first { BUTTON_BORDER_WIDTH } else { 0.0F }),
      )
      .with_justify_content(Center)
      .with_align_items(Center)
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
pub fn[T : WidgetValue] spawn_option_buttons(
  commands : @app.Commands,
  parent : @core.Entity,
  title : String,
  options : Array[(T, String)],
) -> @core.Entity {
  let (text, text_font, text_color) = ui_text(title, white())
  let row = commands.spawn(
    (@hierarchy.Parent::new(parent), @ui.Node::Node().with_align_items(Center)),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(row),
        @ui.Node::Node().with_width(Px(OPTION_TITLE_WIDTH)),
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
        index == 0,
        index == 0,
        index == options.length() - 1,
      ),
    )
  }
  row
}

///|
pub fn[T : WidgetValue] handle_ui_interactions(
  interactions : @ecs.Query[
    (@ecs.Read[@ui.Interaction], @ecs.Read[WidgetClickSender[T]]),
    @ecs.With[@ui.Button],
  ],
  widget_click_events : @ecs.MessageWriter[WidgetClickEvent[T]],
) -> Unit {
  try! interactions.for_each(fn(_entity, data) {
    let (interaction, click_sender) = data
    if interaction.value() == Pressed {
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
  background_color : @ecs.Write[@ui.BackgroundColor],
  selected : Bool,
) -> Unit {
  background_color.set(
    @ui.BackgroundColor::new(radio_button_background_color(selected)),
  )
}

///|
pub fn update_ui_radio_button_text(
  text_color : @ecs.Write[@text.TextColor],
  selected : Bool,
) -> Unit {
  text_color.set(@text.TextColor::new(radio_button_foreground_color(selected)))
}
