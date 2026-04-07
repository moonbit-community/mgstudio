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

///|
const PI : Float = 3.141592653589793F

///|
const OPTION_ADJUSTMENT_SPEED : Float = 0.003F

///|
const BUTTON_WIDTH : Float = 200.0F

///|
pub(all) enum SelectedColorGradingSection {
  Highlights
  Midtones
  Shadows
} derive(Eq)

///|
pub(all) enum SelectedGlobalColorGradingOption {
  Exposure
  Temperature
  Tint
  Hue
} derive(Eq)

///|
pub(all) enum SelectedSectionColorGradingOption {
  Saturation
  Contrast
  Gamma
  Gain
  Lift
} derive(Eq)

///|
pub(all) enum SelectedColorGradingOption {
  Global(SelectedGlobalColorGradingOption)
  Section(SelectedColorGradingSection, SelectedSectionColorGradingOption)
} derive(Eq)

///|
fn SelectedColorGradingOption::default() -> SelectedColorGradingOption {
  SelectedColorGradingOption::Global(SelectedGlobalColorGradingOption::Exposure)
}

///|
pub(all) enum ColorGradingOptionWidgetType {
  Button
  Label
  Value
} derive(Eq)

///|
struct ColorGradingOptionWidget {
  widget_type : ColorGradingOptionWidgetType
  option : SelectedColorGradingOption
}

///|
struct HelpText {}

///|
struct ColorGradingCamera {}

///|
let selected_color_grading_option_resource_key : @ecs.ResourceKey[
  SelectedColorGradingOption,
] = @ecs.register_resource(
  debug_name="examples.3d.color_grading.SelectedColorGradingOption",
)

///|
let color_grading_option_widget_component_key : @ecs.ComponentKey[
  ColorGradingOptionWidget,
] = @ecs.register_component(
  debug_name="examples.3d.color_grading.ColorGradingOptionWidget",
)

///|
let help_text_component_key : @ecs.ComponentKey[HelpText] = @ecs.register_component(
  debug_name="examples.3d.color_grading.HelpText",
)

///|
let color_grading_camera_component_key : @ecs.ComponentKey[ColorGradingCamera] = @ecs.register_component(
  debug_name="examples.3d.color_grading.ColorGradingCamera",
)

///|
let color_grading_button_press_set : @app.SystemSet = @app.system_set(
  "examples.3d.color_grading.handle_button_presses",
)

///|
let color_grading_adjust_set : @app.SystemSet = @app.system_set(
  "examples.3d.color_grading.adjust_color_grading_option",
)

///|
impl @app.Resource for SelectedColorGradingOption with resource() {
  selected_color_grading_option_resource_key
}

///|
impl @ecs.Component for ColorGradingOptionWidget with component() {
  color_grading_option_widget_component_key
}

///|
impl @ecs.Component for HelpText with component() {
  help_text_component_key
}

///|
impl @ecs.Component for ColorGradingCamera with component() {
  color_grading_camera_component_key
}

///|
fn global_option_name(option : SelectedGlobalColorGradingOption) -> String {
  match option {
    Exposure => "Exposure"
    Temperature => "Temperature"
    Tint => "Tint"
    Hue => "Hue"
  }
}

///|
fn section_name(section : SelectedColorGradingSection) -> String {
  match section {
    Highlights => "Highlights"
    Midtones => "Midtones"
    Shadows => "Shadows"
  }
}

///|
fn section_option_name(option : SelectedSectionColorGradingOption) -> String {
  match option {
    Saturation => "Saturation"
    Contrast => "Contrast"
    Gamma => "Gamma"
    Gain => "Gain"
    Lift => "Lift"
  }
}

///|
fn selected_option_display(option : SelectedColorGradingOption) -> String {
  match option {
    Global(global_option) => "\"\{global_option_name(global_option)}\""
    Section(section, section_option) =>
      "\"\{section_option_name(section_option)}\" for \"\{section_name(section)}\""
  }
}

///|
fn selected_option_button_label(option : SelectedColorGradingOption) -> String {
  match option {
    Global(global_option) => global_option_name(global_option)
    Section(_, section_option) => section_option_name(section_option)
  }
}

///|
fn SelectedGlobalColorGradingOption::get(
  self : SelectedGlobalColorGradingOption,
  global : @post_process.ColorGradingGlobal,
) -> Float {
  match self {
    Exposure => global.exposure
    Temperature => global.temperature
    Tint => global.tint
    Hue => global.hue
  }
}

///|
fn SelectedGlobalColorGradingOption::set(
  self : SelectedGlobalColorGradingOption,
  global : @post_process.ColorGradingGlobal,
  value : Float,
) -> @post_process.ColorGradingGlobal {
  match self {
    Exposure => global.exposure = value
    Temperature => global.temperature = value
    Tint => global.tint = value
    Hue => global.hue = value
  }
  global
}

///|
fn SelectedSectionColorGradingOption::get(
  self : SelectedSectionColorGradingOption,
  section : @post_process.ColorGradingSection,
) -> Float {
  match self {
    Saturation => section.saturation
    Contrast => section.contrast
    Gamma => section.gamma
    Gain => section.gain
    Lift => section.lift
  }
}

///|
fn SelectedSectionColorGradingOption::set(
  self : SelectedSectionColorGradingOption,
  section : @post_process.ColorGradingSection,
  value : Float,
) -> @post_process.ColorGradingSection {
  match self {
    Saturation => section.saturation = value
    Contrast => section.contrast = value
    Gamma => section.gamma = value
    Gain => section.gain = value
    Lift => section.lift = value
  }
  section
}

///|
fn SelectedColorGradingOption::get(
  self : SelectedColorGradingOption,
  color_grading : @post_process.ColorGrading,
) -> Float {
  match self {
    Global(option) => option.get(color_grading.global)
    Section(Highlights, option) => option.get(color_grading.highlights)
    Section(Midtones, option) => option.get(color_grading.midtones)
    Section(Shadows, option) => option.get(color_grading.shadows)
  }
}

///|
fn SelectedColorGradingOption::set(
  self : SelectedColorGradingOption,
  color_grading : @post_process.ColorGrading,
  value : Float,
) -> @post_process.ColorGrading {
  match self {
    Global(option) =>
      color_grading.global = option.set(color_grading.global, value)
    Section(Highlights, option) =>
      color_grading.highlights = option.set(color_grading.highlights, value)
    Section(Midtones, option) =>
      color_grading.midtones = option.set(color_grading.midtones, value)
    Section(Shadows, option) =>
      color_grading.shadows = option.set(color_grading.shadows, value)
  }
  color_grading
}

///|
fn selected_button_color() -> @sprite.Color {
  @sprite.Color::white()
}

///|
fn normal_button_color() -> @sprite.Color {
  @sprite.Color::black()
}

///|
fn format_with_three_decimals(value : Float) -> String {
  let scaled = Float::round(value * 1000.0F).to_int()
  let negative = scaled < 0
  let magnitude = if negative { -scaled } else { scaled }
  let whole = magnitude / 1000
  let fractional = magnitude % 1000
  let fractional_string = if fractional < 10 {
    "00\{fractional.to_string()}"
  } else if fractional < 100 {
    "0\{fractional.to_string()}"
  } else {
    fractional.to_string()
  }
  let prefix = if negative { "-" } else { "" }
  "\{prefix}\{whole.to_string()}.\{fractional_string}"
}

///|
fn option_value_text(
  option : SelectedColorGradingOption,
  color_grading : @post_process.ColorGrading,
) -> String {
  format_with_three_decimals(option.get(color_grading))
}

///|
fn create_help_text(option : SelectedColorGradingOption) -> String {
  "Press Left/Right to adjust \{selected_option_display(option)}"
}

///|
fn[T] first_marked_entity(
  world : @ecs.World,
  component_key : @ecs.ComponentKey[T],
) -> @core.Entity? {
  let result : Ref[@core.Entity?] = Ref::new(None)
  try! world
  .query_entities_filtered(@ecs.With::new(component_key))
  .view(fn(_query_entity, entity) {
    if result.val is None {
      result.val = Some(entity)
    }
  })
  result.val
}

///|
fn color_grading_camera_entity(world : @ecs.World) -> @core.Entity? {
  first_marked_entity(world, ColorGradingCamera::component())
}

///|
fn color_grading_camera_value(
  world : @ecs.World,
) -> (@core.Entity, @post_process.ColorGrading)? {
  guard color_grading_camera_entity(world) is Some(entity) else { return None }
  guard (try! world.get_by_key(entity, @post_process.ecs_key_color_grading))
    is Some(color_grading) else {
    return None
  }
  Some((entity, color_grading))
}

///|
fn spawn_row(
  world : @ecs.World,
  parent : @core.Entity,
  node : @ui.Node,
) -> @core.Entity {
  let row = world.spawn_empty()
  try! world.set_by_key(
    row,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(row, @ui.ecs_key_node, node)
  row
}

///|
fn spawn_row_label(
  world : @ecs.World,
  row : @core.Entity,
  font : @asset.Handle[@asset.Font],
  label : String,
) -> Unit {
  let label_entity = world.spawn_empty()
  try! world.set_by_key(
    label_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(row),
  )
  try! world.set_by_key(
    label_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(row),
  )
  try! world.set_by_key(
    label_entity,
    @ui.ecs_key_node,
    @ui.Node::default().with_width(@ui.Val::Px(125.0F)),
  )
  try! world.set_by_key(
    label_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(row),
  )
  try! world.set_by_key(
    label_entity,
    @ui.ecs_key_node,
    @ui.Node::default().with_width(@ui.Val::Px(125.0F)),
  )
  try! world.set_by_key(
    label_entity,
    @text.ecs_key_text,
    @text.Text::new(label),
  )
  try! world.set_by_key(
    label_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(row),
  )
  try! world.set_by_key(
    label_entity,
    @ui.ecs_key_node,
    @ui.Node::default().with_width(@ui.Val::Px(125.0F)),
  )
  try! world.set_by_key(
    label_entity,
    @text.ecs_key_text,
    @text.Text::new(label),
  )
  try! world.set_by_key(
    label_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(15.0F),
  )
  try! world.set_by_key(
    label_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
}

///|
fn spawn_option_button(
  world : @ecs.World,
  row : @core.Entity,
  font : @asset.Handle[@asset.Font],
  option : SelectedColorGradingOption,
  color_grading : @post_process.ColorGrading,
) -> Unit {
  let button = world.spawn_empty()
  try! world.set_by_key(
    button,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(row),
  )
  try! world.set_by_key(button, @ui.ecs_key_button, @ui.Button::default())
  try! world.set_by_key(
    button,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F)))
    .with_width(@ui.Val::Px(BUTTON_WIDTH))
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center)
    .with_padding(
      @ui.UiRect::new(
        @ui.Val::Px(12.0F),
        @ui.Val::Px(6.0F),
        @ui.Val::Px(12.0F),
        @ui.Val::Px(6.0F),
      ),
    )
    .with_margin(
      @ui.UiRect::new(
        @ui.Val::Px(0.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(12.0F),
        @ui.Val::Px(0.0F),
      ),
    ),
  )
  try! world.set_by_key(
    button,
    @ui.ecs_key_border_radius,
    @ui.BorderRadius::all(@ui.Val::Percent(100.0F)),
  )
  try! world.set_by_key(button, @ui.ecs_key_button, @ui.Button::default())
  try! world.set_by_key(
    button,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F)))
    .with_width(@ui.Val::Px(BUTTON_WIDTH))
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center)
    .with_padding(
      @ui.UiRect::new(
        @ui.Val::Px(12.0F),
        @ui.Val::Px(6.0F),
        @ui.Val::Px(12.0F),
        @ui.Val::Px(6.0F),
      ),
    )
    .with_margin(
      @ui.UiRect::new(
        @ui.Val::Px(0.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(12.0F),
        @ui.Val::Px(0.0F),
      ),
    ),
  )
  try! world.set_by_key(
    button,
    @ui.ecs_key_border_radius,
    @ui.BorderRadius::all(@ui.Val::Percent(100.0F)),
  )
  try! world.set_by_key(
    button,
    @ui.ecs_key_border_color,
    @ui.BorderColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(button, @ui.ecs_key_button, @ui.Button::default())
  try! world.set_by_key(
    button,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F)))
    .with_width(@ui.Val::Px(BUTTON_WIDTH))
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center)
    .with_padding(
      @ui.UiRect::new(
        @ui.Val::Px(12.0F),
        @ui.Val::Px(6.0F),
        @ui.Val::Px(12.0F),
        @ui.Val::Px(6.0F),
      ),
    )
    .with_margin(
      @ui.UiRect::new(
        @ui.Val::Px(0.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(12.0F),
        @ui.Val::Px(0.0F),
      ),
    ),
  )
  try! world.set_by_key(
    button,
    @ui.ecs_key_border_radius,
    @ui.BorderRadius::all(@ui.Val::Percent(100.0F)),
  )
  try! world.set_by_key(
    button,
    @ui.ecs_key_border_color,
    @ui.BorderColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(
    button,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(normal_button_color()),
  )
  try! world.set_by_key(button, @ui.ecs_key_button, @ui.Button::default())
  try! world.set_by_key(
    button,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F)))
    .with_width(@ui.Val::Px(BUTTON_WIDTH))
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center)
    .with_padding(
      @ui.UiRect::new(
        @ui.Val::Px(12.0F),
        @ui.Val::Px(6.0F),
        @ui.Val::Px(12.0F),
        @ui.Val::Px(6.0F),
      ),
    )
    .with_margin(
      @ui.UiRect::new(
        @ui.Val::Px(0.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(12.0F),
        @ui.Val::Px(0.0F),
      ),
    ),
  )
  try! world.set_by_key(
    button,
    @ui.ecs_key_border_radius,
    @ui.BorderRadius::all(@ui.Val::Percent(100.0F)),
  )
  try! world.set_by_key(
    button,
    @ui.ecs_key_border_color,
    @ui.BorderColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(
    button,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(normal_button_color()),
  )
  try! world.set_by_key(button, ColorGradingOptionWidget::component(), {
    widget_type: ColorGradingOptionWidgetType::Button,
    option,
  })

  let label_entity = world.spawn_empty()
  try! world.set_by_key(
    label_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(button),
  )
  try! world.set_by_key(label_entity, @ui.ecs_key_node, @ui.Node::default())
  try! world.set_by_key(
    label_entity,
    @text.ecs_key_text,
    @text.Text::new(selected_option_button_label(option)),
  )
  try! world.set_by_key(label_entity, @ui.ecs_key_node, @ui.Node::default())
  try! world.set_by_key(
    label_entity,
    @text.ecs_key_text,
    @text.Text::new(selected_option_button_label(option)),
  )
  try! world.set_by_key(
    label_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(15.0F),
  )
  try! world.set_by_key(
    label_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(label_entity, @ui.ecs_key_node, @ui.Node::default())
  try! world.set_by_key(
    label_entity,
    @text.ecs_key_text,
    @text.Text::new(selected_option_button_label(option)),
  )
  try! world.set_by_key(
    label_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(15.0F),
  )
  try! world.set_by_key(
    label_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(label_entity, ColorGradingOptionWidget::component(), {
    widget_type: ColorGradingOptionWidgetType::Label,
    option,
  })

  let spacer = world.spawn_empty()
  try! world.set_by_key(
    spacer,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(button),
  )
  try! world.set_by_key(
    spacer,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(button),
  )
  try! world.set_by_key(
    spacer,
    @ui.ecs_key_node,
    @ui.Node::default().with_flex_grow(1.0F),
  )

  let value_entity = world.spawn_empty()
  try! world.set_by_key(
    value_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(button),
  )
  try! world.set_by_key(value_entity, @ui.ecs_key_node, @ui.Node::default())
  try! world.set_by_key(
    value_entity,
    @text.ecs_key_text,
    @text.Text::new(option_value_text(option, color_grading)),
  )
  try! world.set_by_key(
    value_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(15.0F),
  )
  try! world.set_by_key(
    value_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(value_entity, @ui.ecs_key_node, @ui.Node::default())
  try! world.set_by_key(
    value_entity,
    @text.ecs_key_text,
    @text.Text::new(option_value_text(option, color_grading)),
  )
  try! world.set_by_key(
    value_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(15.0F),
  )
  try! world.set_by_key(
    value_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(value_entity, ColorGradingOptionWidget::component(), {
    widget_type: ColorGradingOptionWidgetType::Value,
    option,
  })
}

///|
fn add_buttons(
  world : @ecs.World,
  font : @asset.Handle[@asset.Font],
  color_grading : @post_process.ColorGrading,
) -> Unit {
  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
  )

  let panel = world.spawn_empty()
  try! world.set_by_key(
    panel,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    panel,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_bottom(@ui.Val::Px(12.0F))
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_row_gap(@ui.Val::Px(6.0F)),
  )

  let global_row = spawn_row(world, panel, @ui.Node::default())
  spawn_row_label(world, global_row, font, "")
  for
    option in [
      SelectedGlobalColorGradingOption::Exposure,
      SelectedGlobalColorGradingOption::Temperature,
      SelectedGlobalColorGradingOption::Tint,
      SelectedGlobalColorGradingOption::Hue,
    ] {
    spawn_option_button(
      world,
      global_row,
      font,
      SelectedColorGradingOption::Global(option),
      color_grading,
    )
  }

  for
    section in [
      SelectedColorGradingSection::Highlights,
      SelectedColorGradingSection::Midtones,
      SelectedColorGradingSection::Shadows,
    ] {
    let row = spawn_row(
      world,
      panel,
      @ui.Node::default().with_align_items(@ui.AlignItems::Center),
    )
    spawn_row_label(world, row, font, section_name(section))
    for
      option in [
        SelectedSectionColorGradingOption::Saturation,
        SelectedSectionColorGradingOption::Contrast,
        SelectedSectionColorGradingOption::Gamma,
        SelectedSectionColorGradingOption::Gain,
        SelectedSectionColorGradingOption::Lift,
      ] {
      spawn_option_button(
        world,
        row,
        font,
        SelectedColorGradingOption::Section(section, option),
        color_grading,
      )
    }
  }

  let help_entity = world.spawn_empty()
  try! world.set_by_key(
    help_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    help_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    help_entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(
    help_entity,
    @text.ecs_key_text,
    @text.Text::new(create_help_text(SelectedColorGradingOption::default())),
  )
  try! world.set_by_key(
    help_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(16.0F),
  )
  try! world.set_by_key(
    help_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(
    help_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    help_entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(
    help_entity,
    @text.ecs_key_text,
    @text.Text::new(create_help_text(SelectedColorGradingOption::default())),
  )
  try! world.set_by_key(
    help_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(16.0F),
  )
  try! world.set_by_key(
    help_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(
    help_entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(@text.Justify::Left),
  )
  try! world.set_by_key(help_entity, HelpText::component(), HelpText::{  })
}

///|
fn add_camera(world : @ecs.World, asset_server : @asset.AssetServer) -> Unit {
  let camera = @pbr.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(0.7F, 0.7F, 1.0F).looking_at(
        @math.Vec3::new(0.0F, 0.3F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_color_grading(Some(@post_process.ColorGrading::default()))
    .with_distance_fog(
      Some(
        @pbr.DistanceFog::new(
          @sprite.Color::srgb(43.0F / 255.0F, 44.0F / 255.0F, 47.0F / 255.0F),
          @pbr.FogFalloff3d::linear(1.0F, 8.0F),
        ),
      ),
    )
    .spawn(world)
  try! world.set_by_key(camera, @pbr.ecs_key_hdr, @pbr.Hdr::default())
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_environment_map_light,
    @pbr.EnvironmentMapLight::new(
      Some(asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2")),
      Some(asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2")),
      2000.0F,
    ),
  )
  try! world.set_by_key(camera, ColorGradingCamera::component(), ColorGradingCamera::{

  })
}

///|
fn add_basic_scene(
  world : @ecs.World,
  asset_server : @asset.AssetServer,
) -> Unit {
  let main_scene = world.spawn_empty()
  try! world.set_by_key(
    main_scene,
    @scene.ecs_key_scene_root,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @gltf.GltfAssetLabel::Scene(0).from_asset(
          "models/TonemappingTest/TonemappingTest.gltf",
        ),
      ),
    ),
  )

  let helmet_scene = world.spawn_empty()
  try! world.set_by_key(
    helmet_scene,
    @scene.ecs_key_scene_root,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @gltf.GltfAssetLabel::Scene(0).from_asset(
          "models/FlightHelmet/FlightHelmet.gltf",
        ),
      ),
    ),
  )
  try! world.set_by_key(
    helmet_scene,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.5F, 0.0F, -0.5F).with_rotation(
      @math.Quat::from_rotation_y(-0.15F * PI),
    ),
  )

  let directional_light = world.spawn_empty()
  try! world.set_by_key(
    directional_light,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::new(@sprite.Color::white(), 15_000.0F, true).with_cascade_shadow_config_builder(
      @pbr.CascadeShadowConfigBuilder::default()
      .with_maximum_distance(3.0F)
      .with_first_cascade_far_bound(0.9F),
    ),
  )
  try! world.set_by_key(
    directional_light,
    @transform.ecs_key_transform,
    @transform.Transform::from_rotation(
      @math.Quat::from_euler(
        @math.EulerRot::ZYX,
        0.0F,
        PI * -0.15F,
        PI * -0.15F,
      ),
    ),
  )
}

///|
fn setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraMono-Medium.ttf")

  add_basic_scene(world, asset_server)
  add_buttons(world, font, @post_process.ColorGrading::default())
  add_camera(world, asset_server)

  let overlay_camera = @sprite.Camera2dBundle::new(
    @sprite.Camera::default().with_order(100).with_clear_color_none(),
    @transform.Transform::identity(),
  ).spawn(world)
  try! world.set_by_key(
    overlay_camera,
    @ui.IsDefaultUiCamera::component(),
    @ui.IsDefaultUiCamera::default(),
  )
}

///|
fn handle_button_presses(world : @ecs.World) -> Unit {
  let tick = world.advance_sequence()
  ignore(tick)
  guard (try! world.get_resource_ref_mut(SelectedColorGradingOption::resource()))
    is Some(selected_option) else {
    return
  }
  world.for_each_component(@ui.ecs_key_interaction, fn(entity, interaction) {
    if interaction != @ui.Interaction::Pressed {
      return
    }
    guard (try! world.get_by_key(entity, ColorGradingOptionWidget::component()))
      is Some(widget) else {
      return
    }
    if widget.widget_type != ColorGradingOptionWidgetType::Button {
      return
    }
    if selected_option.val != widget.option {
      selected_option.val = widget.option
    }
  })
}

///|
fn adjust_color_grading_option(world : @ecs.World) -> Unit {
  let mut delta = 0.0F
  if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    delta = delta - OPTION_ADJUSTMENT_SPEED
  }
  if @input.key_pressed(@window.KeyCode::ArrowRight) {
    delta = delta + OPTION_ADJUSTMENT_SPEED
  }
  if delta == 0.0F {
    return
  }

  guard (try! world.get_resource(SelectedColorGradingOption::resource()))
    is Some(selected_option) else {
    return
  }
  guard color_grading_camera_value(world)
    is Some((camera_entity, color_grading)) else {
    return
  }

  let next_color_grading = selected_option.set(
    color_grading,
    selected_option.get(color_grading) + delta,
  )
  let tick = world.advance_sequence()
  ignore(tick)
  try! (world.replace(
    camera_entity, @post_process.ecs_key_color_grading, next_color_grading,
  )
  |> ignore)
}

///|
fn update_ui_state(world : @ecs.World) -> Unit {
  guard (try! world.get_resource(SelectedColorGradingOption::resource()))
    is Some(selected_option) else {
    return
  }
  guard color_grading_camera_value(world)
    is Some((_camera_entity, color_grading)) else {
    return
  }

  let tick = world.advance_sequence()
  ignore(tick)
  world.for_each_component(ColorGradingOptionWidget::component(), fn(
    entity,
    widget,
  ) {
    match widget.widget_type {
      Button => {
        let is_selected = widget.option == selected_option
        let background = @ui.BackgroundColor::new(
          if is_selected {
            selected_button_color()
          } else {
            normal_button_color()
          },
        )
        let border = @ui.BorderColor::new(
          if is_selected {
            @sprite.Color::black()
          } else {
            @sprite.Color::white()
          },
        )
        if (try! world.contains_by_key(entity, @ui.ecs_key_background_color)) {
          try! (world.replace(entity, @ui.ecs_key_background_color, background)
          |> ignore)
        } else {
          try! world.set_by_key(
            entity, @ui.ecs_key_background_color, background,
          )
        }
        if (try! world.contains_by_key(entity, @ui.ecs_key_border_color)) {
          try! (world.replace(entity, @ui.ecs_key_border_color, border)
          |> ignore)
        } else {
          try! world.set_by_key(entity, @ui.ecs_key_border_color, border)
        }
      }
      Label => {
        guard (try! world.get_by_key(entity, @text.ecs_key_text))
          is Some(text_value) else {
          return
        }
        text_value.content = selected_option_button_label(widget.option)
        ignore(try! world.replace(entity, @text.ecs_key_text, text_value))
      }
      Value => {
        guard (try! world.get_by_key(entity, @text.ecs_key_text))
          is Some(text_value) else {
          return
        }
        text_value.content = option_value_text(widget.option, color_grading)
        ignore(try! world.replace(entity, @text.ecs_key_text, text_value))
      }
    }
  })

  guard first_marked_entity(world, HelpText::component()) is Some(help_entity) else {
    return
  }
  guard (try! world.get_by_key(help_entity, @text.ecs_key_text))
    is Some(help_text) else {
    return
  }
  help_text.content = create_help_text(selected_option)
  ignore(try! world.replace(help_entity, @text.ecs_key_text, help_text))
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .insert_resource(SelectedColorGradingOption::default())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(
    @app.Update,
    @app.system(handle_button_presses)
    .after(@ui.ui_set_focus)
    .in_set(color_grading_button_press_set),
  )
  .add_systems(
    @app.Update,
    @app.system(adjust_color_grading_option)
    .in_set(color_grading_adjust_set)
    .after(color_grading_button_press_set),
  )
  .add_systems(
    @app.Update,
    @app.system(update_ui_state).after(color_grading_adjust_set),
  )
  .run()
}
