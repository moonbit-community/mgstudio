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
  Global(Exposure)
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
let color_grading_button_press_set : @app.SystemSet = @app.system_set(
  "examples.3d.color_grading.handle_button_presses",
)

///|
let color_grading_adjust_set : @app.SystemSet = @app.system_set(
  "examples.3d.color_grading.adjust_color_grading_option",
)

///|
impl @app.Resource for SelectedColorGradingOption with fn resource() {
  selected_color_grading_option_resource_key
}

///|
impl @ecs.Component for ColorGradingOptionWidget with fn component() {
  color_grading_option_widget_component_key
}

///|
impl @ecs.Component for HelpText with fn component() {
  help_text_component_key
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
fn selected_button_color() -> @color.Color {
  @color.Color::white()
}

///|
fn normal_button_color() -> @color.Color {
  @color.Color::black()
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
fn text(
  label : String,
  font : @asset.Handle[@asset.Font],
  color : @color.Color,
) -> (@text.Text, @text.TextFont, @text.TextColor) {
  (
    @text.Text::new(label),
    @text.TextFont::TextFont().with_font(font).with_font_size(15.0F),
    @text.TextColor::new(color),
  )
}

///|
fn attach_to_parent(
  commands : @app.Commands,
  entity : @core.Entity,
  parent : @core.Entity,
) -> Unit {
  commands.entity(entity).insert_component(@hierarchy.Parent::new(parent))
}

///|
fn button_node() -> @ui.Node {
  @ui.Node::Node()
  .with_border(@ui.UiRect::all(Px(1.0F)))
  .with_width(Px(BUTTON_WIDTH))
  .with_justify_content(Center)
  .with_align_items(Center)
  .with_padding(@ui.UiRect::new(Px(12.0F), Px(6.0F), Px(12.0F), Px(6.0F)))
  .with_margin(@ui.UiRect::new(Px(0.0F), Px(0.0F), Px(12.0F), Px(0.0F)))
  .with_border_radius(@ui.BorderRadius::all(Percent(100.0F)))
}

///|
fn spawn_row(
  commands : @app.Commands,
  parent : @core.Entity,
  node : @ui.Node,
) -> @core.Entity {
  let row = commands.spawn_component(node)
  attach_to_parent(commands, row, parent)
  row
}

///|
fn spawn_row_label(
  commands : @app.Commands,
  row : @core.Entity,
  font : @asset.Handle[@asset.Font],
  label : String,
) -> Unit {
  let (text_value, text_font, text_color) = text(
    label,
    font,
    @color.Color::white(),
  )
  let label_entity = commands.spawn(
    (text_value, text_font, text_color, @ui.Node::Node().with_width(Px(125.0F))),
  )
  attach_to_parent(commands, label_entity, row)
}

///|
fn button_for_value(
  commands : @app.Commands,
  parent : @core.Entity,
  option : SelectedColorGradingOption,
  color_grading : @post_process.ColorGrading,
  font : @asset.Handle[@asset.Font],
) -> Unit {
  let button = commands.spawn(
    (
      @ui.Button::Button(),
      button_node(),
      @ui.BorderColor::new(@color.Color::white()),
      @ui.BackgroundColor::new(@color.Color::black()),
      ColorGradingOptionWidget::{ widget_type: Button, option },
    ),
  )
  attach_to_parent(commands, button, parent)

  let (label_text, label_font, label_color) = text(
    selected_option_button_label(option),
    font,
    @color.Color::white(),
  )
  let label_entity = commands.spawn(
    (
      label_text,
      label_font,
      label_color,
      ColorGradingOptionWidget::{ widget_type: Label, option },
    ),
  )
  attach_to_parent(commands, label_entity, button)

  let spacer = commands.spawn_component(@ui.Node::Node().with_flex_grow(1.0F))
  attach_to_parent(commands, spacer, button)

  let (value_text, value_font, value_color) = text(
    option_value_text(option, color_grading),
    font,
    @color.Color::white(),
  )
  let value_entity = commands.spawn(
    (
      value_text,
      value_font,
      value_color,
      ColorGradingOptionWidget::{ widget_type: Value, option },
    ),
  )
  attach_to_parent(commands, value_entity, button)
}

///|
fn buttons_for_global_controls(
  commands : @app.Commands,
  parent : @core.Entity,
  color_grading : @post_process.ColorGrading,
  font : @asset.Handle[@asset.Font],
) -> @core.Entity {
  let row = spawn_row(commands, parent, Node())
  ignore(
    commands.spawn(
      (@ui.Node::Node().with_width(Px(125.0F)), @hierarchy.Parent::new(row)),
    ),
  )
  for
    option in [
      SelectedGlobalColorGradingOption::Exposure,
      Temperature,
      Tint,
      Hue,
    ] {
    button_for_value(commands, row, Global(option), color_grading, font)
  }
  row
}

///|
fn buttons_for_section(
  commands : @app.Commands,
  parent : @core.Entity,
  section : SelectedColorGradingSection,
  color_grading : @post_process.ColorGrading,
  font : @asset.Handle[@asset.Font],
) -> @core.Entity {
  let row = spawn_row(
    commands,
    parent,
    @ui.Node::Node().with_align_items(Center),
  )
  spawn_row_label(commands, row, font, section_name(section))
  for
    option in [
      SelectedSectionColorGradingOption::Saturation,
      Contrast,
      Gamma,
      Gain,
      Lift,
    ] {
    button_for_value(
      commands,
      row,
      Section(section, option),
      color_grading,
      font,
    )
  }
  row
}

///|
fn add_buttons(
  commands : @app.Commands,
  font : @asset.Handle[@asset.Font],
  color_grading : @post_process.ColorGrading,
) -> Unit {
  let root = commands.spawn_component(
    @ui.Node::Node()
    .with_flex_direction(Column)
    .with_position_type(Absolute)
    .with_row_gap(Px(6.0F))
    .with_left(Px(12.0F))
    .with_bottom(Px(12.0F)),
  )
  ignore(buttons_for_global_controls(commands, root, color_grading, font))
  ignore(buttons_for_section(commands, root, Highlights, color_grading, font))
  ignore(buttons_for_section(commands, root, Midtones, color_grading, font))
  ignore(buttons_for_section(commands, root, Shadows, color_grading, font))
}

///|
fn add_help_text(
  commands : @app.Commands,
  font : @asset.Handle[@asset.Font],
  currently_selected_option : SelectedColorGradingOption,
) -> Unit {
  ignore(
    commands.spawn(
      (
        @text.Text::new(create_help_text(currently_selected_option)),
        @text.TextFont::TextFont().with_font(font),
        @ui.Node::Node()
        .with_position_type(Absolute)
        .with_left(Px(12.0F))
        .with_top(Px(12.0F)),
        HelpText::{  },
      ),
    ),
  )
}

///|
fn add_camera(
  commands : @app.Commands,
  asset_server : @asset.AssetServer,
  color_grading : @post_process.ColorGrading,
) -> Unit {
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @pbr.Hdr::Hdr(),
        @transform.Transform::from_xyz(0.7F, 0.7F, 1.0F).looking_at(
          @math.Vec3::new(0.0F, 0.3F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        color_grading,
        @pbr.DistanceFog::new(
          @color.Color::srgb(43.0F / 255.0F, 44.0F / 255.0F, 47.0F / 255.0F),
          @pbr.FogFalloff3d::linear(1.0F, 8.0F),
        ),
        @pbr.EnvironmentMapLight::new(
          Some(
            asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"),
          ),
          Some(
            asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
          ),
          2000.0F,
        ),
      ),
    ),
  )
}

///|
fn add_basic_scene(
  commands : @app.Commands,
  asset_server : @asset.AssetServer,
) -> Unit {
  ignore(
    commands.spawn_component(
      @scene.SceneRoot::new(
        @scene.scene_load_gltf_scene(
          asset_server,
          @gltf.GltfAssetLabel::Scene(0).from_asset(
            "models/TonemappingTest/TonemappingTest.gltf",
          ),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @scene.SceneRoot::new(
          @scene.scene_load_gltf_scene(
            asset_server,
            @gltf.GltfAssetLabel::Scene(0).from_asset(
              "models/FlightHelmet/FlightHelmet.gltf",
            ),
          ),
        ),
        @transform.Transform::from_xyz(0.5F, 0.0F, -0.5F).with_rotation(
          @math.Quat::from_rotation_y(-0.15F * PI),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(@color.Color::white(), 15_000.0F, true),
        @pbr.CascadeShadowConfigBuilder::CascadeShadowConfigBuilder()
        .with_maximum_distance(3.0F)
        .with_first_cascade_far_bound(0.9F)
        .build(),
        @transform.Transform::from_rotation(
          @math.Quat::from_euler(ZYX, 0.0F, PI * -0.15F, PI * -0.15F),
        ),
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  currently_selected_option : @app.Res[SelectedColorGradingOption],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let server = asset_server.get()
  let font = server.load_font("fonts/FiraMono-Medium.ttf")
  let color_grading = @post_process.ColorGrading::ColorGrading()

  add_basic_scene(commands, server)
  add_buttons(commands, font, color_grading)
  add_help_text(commands, font, currently_selected_option.get())
  add_camera(commands, server, color_grading)
}

///|
fn handle_button_presses(
  interactions : @ecs.Query[
    (@ecs.Read[@ui.Interaction], @ecs.Read[ColorGradingOptionWidget]),
    @ecs.Changed[@ui.Interaction],
  ],
  currently_selected_option : @app.ResMut[SelectedColorGradingOption],
) -> Unit {
  try! interactions.view(fn(_entity, data) {
    let (interaction, widget) = data
    let widget_value = widget.value()
    if widget_value.widget_type == Button && interaction.value() == Pressed {
      currently_selected_option.set(widget_value.option)
    }
  })
}

///|
fn adjust_color_grading_option(
  color_grading : @app.Single[@ecs.Write[@post_process.ColorGrading], @ecs.All],
  input : @input.ButtonInput[@window.KeyCode],
  currently_selected_option : @app.Res[SelectedColorGradingOption],
) -> Unit {
  let mut delta = 0.0F
  if input.pressed(ArrowLeft) {
    delta = delta - OPTION_ADJUSTMENT_SPEED
  }
  if input.pressed(ArrowRight) {
    delta = delta + OPTION_ADJUSTMENT_SPEED
  }
  if delta == 0.0F {
    return
  }

  let selected = currently_selected_option.get()
  let color_grading = color_grading.get()
  let next_value = selected.get(color_grading.value()) + delta
  color_grading.modify(fn(value) { ignore(selected.set(value, next_value)) })
}

///|
fn update_ui_state(
  buttons : @ecs.Query[
    (
      @ecs.Write[@ui.BackgroundColor],
      @ecs.Write[@ui.BorderColor],
      @ecs.Read[ColorGradingOptionWidget],
    ),
    @ecs.All,
  ],
  button_text : @ecs.Query[
    (@core.Entity, @ecs.Read[ColorGradingOptionWidget]),
    (@ecs.With[@text.Text], @ecs.Without[HelpText]),
  ],
  help_text : @app.Single[@core.Entity, @ecs.With[HelpText]],
  writer : @ui.TextUiWriter,
  cameras : @app.Single[@ecs.Read[@post_process.ColorGrading], @ecs.All],
  currently_selected_option : @app.Res[SelectedColorGradingOption],
) -> Unit {
  let color_grading = cameras.get()
  if !currently_selected_option.is_changed() && !color_grading.is_changed() {
    return
  }

  let selected = currently_selected_option.get()
  try! buttons.view(fn(_entity, data) {
    let (background, border_color, widget) = data
    let is_selected = selected == widget.value().option
    background.set(
      @ui.BackgroundColor::new(
        if is_selected {
          selected_button_color()
        } else {
          normal_button_color()
        },
      ),
    )
    border_color.set(
      @ui.BorderColor::new(
        if is_selected {
          @color.Color::black()
        } else {
          @color.Color::white()
        },
      ),
    )
  })

  let value_label = option_value_text(selected, color_grading.value())
  try! button_text.view(fn(_entity, data) {
    let (entity, widget) = data
    let widget_value = widget.value()
    let color = if selected == widget_value.option {
      @color.Color::black()
    } else {
      @color.Color::white()
    }
    ignore(writer.set_color(entity, 0, @text.TextColor::new(color)))
    if widget_value.widget_type == Value && selected == widget_value.option {
      ignore(writer.set_text(entity, 0, value_label))
    }
  })
  ignore(writer.set_text(help_text.get(), 0, create_help_text(selected)))
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(SelectedColorGradingOption::default())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param3(Startup, setup)
  .add_systems(
    Update,
    @app.system_config_param2(handle_button_presses)
    .after(@ui.ui_set_focus)
    .in_set(color_grading_button_press_set),
  )
  .add_systems(
    Update,
    @app.system_config_param3(adjust_color_grading_option)
    .in_set(color_grading_adjust_set)
    .after(color_grading_button_press_set),
  )
  .add_systems(
    Update,
    @app.system_config_param6(update_ui_state).after(color_grading_adjust_set),
  )
  .run()
}
