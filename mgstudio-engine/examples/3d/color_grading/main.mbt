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
/// Port of `bevy/examples/3d/color_grading.rs`.
///
/// Baseline parity:
/// - Camera-attached `ColorGrading` + `Hdr` are now wired to real mgstudio
///   camera components.
/// - Existing proxy adjustments (light/fog shaping) are retained to keep the
///   current visual response close to prior example behavior.

///|
const PI : Float = 3.141592653589793F

///|
const OPTION_ADJUSTMENT_SPEED : Float = 0.003F

///|
const BUTTON_WIDTH : Float = 200.0F

///|
const BUTTON_HEIGHT : Float = 36.0F

///|
pub(all) enum SelectedColorGradingSection {
  Highlights
  Midtones
  Shadows
}

///|
pub(all) enum SelectedGlobalColorGradingOption {
  Exposure
  Temperature
  Tint
  Hue
}

///|
pub(all) enum SelectedSectionColorGradingOption {
  Saturation
  Contrast
  Gamma
  Gain
  Lift
}

///|
pub(all) enum SelectedColorGradingOption {
  Global(SelectedGlobalColorGradingOption)
  Section(SelectedColorGradingSection, SelectedSectionColorGradingOption)
}

///|
priv struct ColorGradingGlobal {
  exposure : Float
  temperature : Float
  tint : Float
  hue : Float
}

///|
priv struct ColorGradingSection {
  saturation : Float
  contrast : Float
  gamma : Float
  gain : Float
  lift : Float
}

///|
priv struct ColorGradingValues {
  global : ColorGradingGlobal
  shadows : ColorGradingSection
  midtones : ColorGradingSection
  highlights : ColorGradingSection
}

///|
priv struct ColorGradingOptionWidget {
  button : @core.Entity
  text : @text.TextHandle
  option : SelectedColorGradingOption
}

///|
priv struct ColorGradingState {
  mut selected_option : SelectedColorGradingOption
  mut color_grading : ColorGradingValues
  mut camera : @core.Entity?
  mut directional_light : @core.Entity?
  mut help_text : @text.TextHandle?
  widgets : Array[ColorGradingOptionWidget]
  mut ui_dirty : Bool
}

///|
let color_grading_state : Ref[ColorGradingState] = Ref::new({
  selected_option: SelectedColorGradingOption::Global(
    SelectedGlobalColorGradingOption::Exposure,
  ),
  color_grading: {
    global: { exposure: 0.0F, temperature: 0.0F, tint: 0.0F, hue: 0.0F },
    shadows: {
      saturation: 1.0F,
      contrast: 1.0F,
      gamma: 1.0F,
      gain: 1.0F,
      lift: 0.0F,
    },
    midtones: {
      saturation: 1.0F,
      contrast: 1.0F,
      gamma: 1.0F,
      gain: 1.0F,
      lift: 0.0F,
    },
    highlights: {
      saturation: 1.0F,
      contrast: 1.0F,
      gamma: 1.0F,
      gain: 1.0F,
      lift: 0.0F,
    },
  },
  camera: None,
  directional_light: None,
  help_text: None,
  widgets: [],
  ui_dirty: true,
})

///|
fn default_color_grading_values() -> ColorGradingValues {
  {
    global: { exposure: 0.0F, temperature: 0.0F, tint: 0.0F, hue: 0.0F },
    shadows: {
      saturation: 1.0F,
      contrast: 1.0F,
      gamma: 1.0F,
      gain: 1.0F,
      lift: 0.0F,
    },
    midtones: {
      saturation: 1.0F,
      contrast: 1.0F,
      gamma: 1.0F,
      gain: 1.0F,
      lift: 0.0F,
    },
    highlights: {
      saturation: 1.0F,
      contrast: 1.0F,
      gamma: 1.0F,
      gain: 1.0F,
      lift: 0.0F,
    },
  }
}

///|
fn clampf(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
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
fn selected_option_name(option : SelectedColorGradingOption) -> String {
  match option {
    Global(global_option) => global_option_name(global_option)
    Section(section, section_option) =>
      section_name(section) + " / " + section_option_name(section_option)
  }
}

///|
fn selected_option_eq(
  lhs : SelectedColorGradingOption,
  rhs : SelectedColorGradingOption,
) -> Bool {
  let global_option_eq = fn(
    lhs : SelectedGlobalColorGradingOption,
    rhs : SelectedGlobalColorGradingOption,
  ) -> Bool {
    match lhs {
      Exposure =>
        match rhs {
          Exposure => true
          _ => false
        }
      Temperature =>
        match rhs {
          Temperature => true
          _ => false
        }
      Tint =>
        match rhs {
          Tint => true
          _ => false
        }
      Hue =>
        match rhs {
          Hue => true
          _ => false
        }
    }
  }

  let section_eq = fn(
    lhs : SelectedColorGradingSection,
    rhs : SelectedColorGradingSection,
  ) -> Bool {
    match lhs {
      Highlights =>
        match rhs {
          Highlights => true
          _ => false
        }
      Midtones =>
        match rhs {
          Midtones => true
          _ => false
        }
      Shadows =>
        match rhs {
          Shadows => true
          _ => false
        }
    }
  }

  let section_option_eq = fn(
    lhs : SelectedSectionColorGradingOption,
    rhs : SelectedSectionColorGradingOption,
  ) -> Bool {
    match lhs {
      Saturation =>
        match rhs {
          Saturation => true
          _ => false
        }
      Contrast =>
        match rhs {
          Contrast => true
          _ => false
        }
      Gamma =>
        match rhs {
          Gamma => true
          _ => false
        }
      Gain =>
        match rhs {
          Gain => true
          _ => false
        }
      Lift =>
        match rhs {
          Lift => true
          _ => false
        }
    }
  }

  match lhs {
    Global(lhs_global) =>
      match rhs {
        Global(rhs_global) => global_option_eq(lhs_global, rhs_global)
        _ => false
      }
    Section(lhs_section, lhs_section_option) =>
      match rhs {
        Section(rhs_section, rhs_section_option) =>
          section_eq(lhs_section, rhs_section) &&
          section_option_eq(lhs_section_option, rhs_section_option)
        _ => false
      }
  }
}

///|
fn global_option_get(
  option : SelectedGlobalColorGradingOption,
  global : ColorGradingGlobal,
) -> Float {
  match option {
    Exposure => global.exposure
    Temperature => global.temperature
    Tint => global.tint
    Hue => global.hue
  }
}

///|
fn global_option_set(
  option : SelectedGlobalColorGradingOption,
  global : ColorGradingGlobal,
  value : Float,
) -> ColorGradingGlobal {
  match option {
    Exposure => { ..global, exposure: value }
    Temperature => { ..global, temperature: value }
    Tint => { ..global, tint: value }
    Hue => { ..global, hue: value }
  }
}

///|
fn section_option_get(
  option : SelectedSectionColorGradingOption,
  section : ColorGradingSection,
) -> Float {
  match option {
    Saturation => section.saturation
    Contrast => section.contrast
    Gamma => section.gamma
    Gain => section.gain
    Lift => section.lift
  }
}

///|
fn section_option_set(
  option : SelectedSectionColorGradingOption,
  section : ColorGradingSection,
  value : Float,
) -> ColorGradingSection {
  match option {
    Saturation => { ..section, saturation: value }
    Contrast => { ..section, contrast: value }
    Gamma => { ..section, gamma: value }
    Gain => { ..section, gain: value }
    Lift => { ..section, lift: value }
  }
}

///|
fn selected_option_get(
  option : SelectedColorGradingOption,
  color_grading : ColorGradingValues,
) -> Float {
  match option {
    Global(global_option) =>
      global_option_get(global_option, color_grading.global)
    Section(section, section_option) =>
      match section {
        Highlights =>
          section_option_get(section_option, color_grading.highlights)
        Midtones => section_option_get(section_option, color_grading.midtones)
        Shadows => section_option_get(section_option, color_grading.shadows)
      }
  }
}

///|
fn selected_option_set(
  option : SelectedColorGradingOption,
  color_grading : ColorGradingValues,
  value : Float,
) -> ColorGradingValues {
  match option {
    Global(global_option) =>
      {
        ..color_grading,
        global: global_option_set(global_option, color_grading.global, value),
      }
    Section(section, section_option) =>
      match section {
        Highlights =>
          {
            ..color_grading,
            highlights: section_option_set(
              section_option,
              color_grading.highlights,
              value,
            ),
          }
        Midtones =>
          {
            ..color_grading,
            midtones: section_option_set(
              section_option,
              color_grading.midtones,
              value,
            ),
          }
        Shadows =>
          {
            ..color_grading,
            shadows: section_option_set(
              section_option,
              color_grading.shadows,
              value,
            ),
          }
      }
  }
}

///|
fn to_render3d_section(
  section : ColorGradingSection,
) -> @render3d.ColorGradingSection {
  @render3d.ColorGradingSection::default()
  .with_saturation(section.saturation)
  .with_contrast(section.contrast)
  .with_gamma(section.gamma)
  .with_gain(section.gain)
  .with_lift(section.lift)
}

///|
fn to_render3d_color_grading(
  values : ColorGradingValues,
) -> @render3d.ColorGrading {
  let global = @render3d.ColorGradingGlobal::default()
    .with_exposure(values.global.exposure)
    .with_temperature(values.global.temperature)
    .with_tint(values.global.tint)
    .with_hue(values.global.hue)
  @render3d.ColorGrading::new(
    global,
    @render3d.ColorGradingSettings::default()
    .with_shadows(to_render3d_section(values.shadows))
    .with_midtones(to_render3d_section(values.midtones))
    .with_highlights(to_render3d_section(values.highlights)),
  )
}

///|
fn selected_button_color() -> @render2d.Color {
  @render2d.Color::white()
}

///|
fn normal_button_color() -> @render2d.Color {
  @render2d.Color::black()
}

///|
fn create_help_text() -> String {
  "Press Left/Right to adjust " +
  selected_option_name(color_grading_state.val.selected_option)
}

///|
fn set_global_ambient_light(
  world : @ecs.World,
  color : @render2d.Color,
  brightness : Float,
) -> Unit {
  let ambient = @render3d.GlobalAmbientLight::new(color, brightness)
  world.insert_resource(@render3d.ecs_key_global_ambient_light, ambient)
}

///|
fn global_white_balance(global : ColorGradingGlobal) -> (Float, Float, Float) {
  let temp = global.temperature
  let tint = global.tint
  let hue = global.hue
  let hue_r = 1.0F + 0.25F * @math.sin(hue)
  let hue_g = 1.0F + 0.25F * @math.sin(hue + 2.0F * PI / 3.0F)
  let hue_b = 1.0F + 0.25F * @math.sin(hue + 4.0F * PI / 3.0F)
  let r = clampf((1.0F + temp * 0.4F + tint * 0.2F) * hue_r, 0.2F, 2.0F)
  let g = clampf(
    (1.0F - absf(temp) * 0.2F - absf(tint) * 0.1F) * hue_g,
    0.2F,
    2.0F,
  )
  let b = clampf((1.0F - temp * 0.4F - tint * 0.2F) * hue_b, 0.2F, 2.0F)
  (r, g, b)
}

///|
fn apply_color_grading_proxy(world : @ecs.World) -> Unit {
  let values = color_grading_state.val.color_grading
  if color_grading_state.val.camera is Some(camera_entity) {
    let tick = world.increment_change_tick()
    let grading = to_render3d_color_grading(values)
    let store = world.component(@render3d.ecs_key_color_grading)
    if store.contains(camera_entity) {
      store.set(camera_entity, grading, tick) |> ignore
    } else {
      store.insert(camera_entity, grading, tick)
    }
  }

  let (white_r, white_g, white_b) = global_white_balance(values.global)
  let exposure_scale = @math.pow(2.0F, values.global.exposure)

  let highlights = values.highlights
  let highlight_intensity = clampf(
    highlights.gain * highlights.contrast,
    0.05F,
    4.0F,
  )
  let highlight_saturation = clampf(highlights.saturation, 0.0F, 2.0F)
  let highlight_lift = highlights.lift

  if color_grading_state.val.directional_light is Some(light_entity) {
    let tick = world.increment_change_tick()
    let light_color = @render2d.Color::new(
      clampf(
        white_r * (0.7F + 0.3F * highlight_saturation) + highlight_lift,
        0.0F,
        2.0F,
      ),
      clampf(
        white_g * (0.7F + 0.3F * highlight_saturation) + highlight_lift,
        0.0F,
        2.0F,
      ),
      clampf(
        white_b * (0.7F + 0.3F * highlight_saturation) + highlight_lift,
        0.0F,
        2.0F,
      ),
      1.0F,
    )
    let illuminance = clampf(
      15_000.0F * exposure_scale * highlight_intensity,
      0.0F,
      80_000.0F,
    )
    world
    .component(@render3d.ecs_key_directional_light)
    .set(
      light_entity,
      @render3d.DirectionalLight::new(light_color, illuminance, true),
      tick,
    )
    |> ignore
  }

  let midtones = values.midtones
  let midtone_gain = clampf(midtones.gain * midtones.contrast, 0.0F, 4.0F)
  let midtone_saturation = clampf(midtones.saturation, 0.0F, 2.0F)
  let ambient_color = @render2d.Color::new(
    clampf(white_r * (0.5F + 0.5F * midtone_saturation), 0.0F, 2.0F),
    clampf(white_g * (0.5F + 0.5F * midtone_saturation), 0.0F, 2.0F),
    clampf(white_b * (0.5F + 0.5F * midtone_saturation), 0.0F, 2.0F),
    1.0F,
  )
  let ambient_brightness = clampf(
    0.008F * exposure_scale * midtone_gain + midtones.lift * 0.04F,
    0.0F,
    0.25F,
  )
  set_global_ambient_light(world, ambient_color, ambient_brightness)

  let shadows = values.shadows
  let shadow_gamma = if shadows.gamma < 0.1F { 0.1F } else { shadows.gamma }
  let shadow_gain = if shadows.gain < 0.05F { 0.05F } else { shadows.gain }
  let fog_start = clampf(1.0F * shadow_gamma, 0.2F, 4.0F)
  let fog_end = clampf(
    8.0F * shadow_gain + shadows.contrast * 1.5F,
    2.0F,
    20.0F,
  )
  let shadow_saturation = clampf(shadows.saturation, 0.0F, 2.0F)
  let fog_color = @render2d.Color::new(
    clampf(
      0.16F * white_r * (0.5F + 0.5F * shadow_saturation) + shadows.lift * 0.2F,
      0.0F,
      1.0F,
    ),
    clampf(
      0.17F * white_g * (0.5F + 0.5F * shadow_saturation) + shadows.lift * 0.2F,
      0.0F,
      1.0F,
    ),
    clampf(
      0.18F * white_b * (0.5F + 0.5F * shadow_saturation) + shadows.lift * 0.2F,
      0.0F,
      1.0F,
    ),
    1.0F,
  )
  @render3d.render3d_set_distance_fog(
    @render3d.DistanceFog::new(
      fog_color,
      @render3d.FogFalloff3d::linear(fog_start, fog_end),
    ),
  )
}

///|
fn option_value_text(option : SelectedColorGradingOption) -> String {
  selected_option_name(option) +
  "\n" +
  selected_option_get(option, color_grading_state.val.color_grading).to_string()
}

///|
fn spawn_ui_text_handle(
  content : String,
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  color : @render2d.Color,
) -> @text.TextHandle {
  @text.Text2dBundle::new(
    @text.Text2d::new(content),
    @text.TextFont::default().with_font(font).with_font_size(font_size),
    @math.Transform::identity(),
  )
  .with_color(@text.TextColor::new(color))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
  .spawn()
}

///|
fn spawn_row(
  world : @ecs.World,
  parent : @core.Entity,
  tick : @core.Tick,
) -> @core.Entity {
  let row = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(row, @hierarchy.Parent::new(parent), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    row,
    @ui.Node::default().with_align_items(@ui.AlignItems::Center),
    tick,
  )
  row
}

///|
fn spawn_row_label(
  world : @ecs.World,
  row : @core.Entity,
  tick : @core.Tick,
  font : @asset.Handle[@asset.Font],
  label : String,
) -> Unit {
  let label_handle = spawn_ui_text_handle(
    label,
    font,
    15.0F,
    @render2d.Color::white(),
  )
  let label_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(label_entity, @hierarchy.Parent::new(row), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    label_entity,
    @ui.Node::default()
    .with_width(@ui.Val::Px(125.0F))
    .with_height(@ui.Val::Auto),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(label_entity, @ui.UiText::new(label_handle), tick)
}

///|
fn spawn_option_button(
  world : @ecs.World,
  row : @core.Entity,
  tick : @core.Tick,
  font : @asset.Handle[@asset.Font],
  option : SelectedColorGradingOption,
) -> Unit {
  let button = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(button, @hierarchy.Parent::new(row), tick)
  world
  .component(@ui.ecs_key_button)
  .insert(button, @ui.Button::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    button,
    @ui.Node::default()
    .with_width(@ui.Val::Px(BUTTON_WIDTH))
    .with_height(@ui.Val::Px(BUTTON_HEIGHT))
    .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F)))
    .with_padding(@ui.UiRect::all(@ui.Val::Px(4.0F)))
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center),
    tick,
  )
  world
  .component(@ui.ecs_key_border_radius)
  .insert(button, @ui.BorderRadius::all(@ui.Val::Px(12.0F)), tick)
  world
  .component(@ui.ecs_key_background_color)
  .insert(button, @ui.BackgroundColor::new(normal_button_color()), tick)
  world
  .component(@ui.ecs_key_border_color)
  .insert(button, @ui.BorderColor::new(@render2d.Color::white()), tick)

  let option_text = spawn_ui_text_handle(
    option_value_text(option),
    font,
    12.0F,
    @render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F),
  )

  let text_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(button), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    text_entity,
    @ui.Node::default().with_width(@ui.Val::Auto).with_height(@ui.Val::Auto),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(text_entity, @ui.UiText::new(option_text), tick)

  color_grading_state.val.widgets.push({ button, text: option_text, option })
}

///|
fn setup_ui(world : @ecs.World, font : @asset.Handle[@asset.Font]) -> Unit {
  let tick = world.read_change_tick()

  // 2D overlay camera for UI.
  @render2d.Camera2dBundle::new(
    @render2d.Camera::default().with_order(100).with_clear_color_none(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
    tick,
  )

  let help_handle = spawn_ui_text_handle(
    "",
    font,
    16.0F,
    @render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F),
  )
  let help_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(help_entity, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    help_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F))
    .with_width(@ui.Val::Auto)
    .with_height(@ui.Val::Auto),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(help_entity, @ui.UiText::new(help_handle), tick)
  color_grading_state.val.help_text = Some(help_handle)

  let panel = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(panel, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    panel,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_bottom(@ui.Val::Px(12.0F))
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_row_gap(@ui.Val::Px(6.0F)),
    tick,
  )

  let global_row = spawn_row(world, panel, tick)
  spawn_row_label(world, global_row, tick, font, "".to_string())
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
      tick,
      font,
      SelectedColorGradingOption::Global(option),
    )
  }

  for
    section in [
      SelectedColorGradingSection::Highlights,
      SelectedColorGradingSection::Midtones,
      SelectedColorGradingSection::Shadows,
    ] {
    let row = spawn_row(world, panel, tick)
    spawn_row_label(world, row, tick, font, section_name(section))
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
        tick,
        font,
        SelectedColorGradingOption::Section(section, option),
      )
    }
  }
}

///|
fn add_basic_scene(
  world : @ecs.World,
  asset_server : @asset.AssetServer,
) -> Unit {
  let tick = world.read_change_tick()

  let main_scene = world.spawn_empty()
  world
  .component(@scene.ecs_key_scene_root)
  .insert(
    main_scene,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @scene.GltfAssetLabel::Scene(0).from_asset(
          "models/TonemappingTest/TonemappingTest.gltf",
        ),
      ),
    ),
    tick,
  )

  let helmet_scene = world.spawn_empty()
  world
  .component(@scene.ecs_key_scene_root)
  .insert(
    helmet_scene,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @scene.GltfAssetLabel::Scene(0).from_asset(
          "models/FlightHelmet/FlightHelmet.gltf",
        ),
      ),
    ),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(
    helmet_scene,
    @math.Transform::from_xyz(0.5F, 0.0F, -0.5F).with_rotation(
      @math.Quat::from_rotation_y(-0.15F * PI),
    ),
    tick,
  )

  let directional_light = world.spawn_empty()
  world
  .component(@render3d.ecs_key_directional_light)
  .insert(
    directional_light,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 15_000.0F, true),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(
    directional_light,
    @math.Transform::from_xyz(0.0F, 4.0F, 4.0F).looking_at(
      @math.Vec3::new(0.0F, 0.3F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  color_grading_state.val.directional_light = Some(directional_light)
}

///|
fn add_camera(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.7F, 0.7F, 1.0F).looking_at(
      @math.Vec3::new(0.0F, 0.3F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world
  .component(@render3d.ecs_key_hdr)
  .insert(camera, @render3d.Hdr::default(), tick)
  world
  .component(@render3d.ecs_key_color_grading)
  .insert(
    camera,
    to_render3d_color_grading(color_grading_state.val.color_grading),
    tick,
  )
  color_grading_state.val.camera = Some(camera)
}

///|
fn update_ui_state(world : @ecs.World) -> Unit {
  let tick = world.increment_change_tick()
  let selected_option = color_grading_state.val.selected_option
  let background_store = world.component(@ui.ecs_key_background_color)
  let border_store = world.component(@ui.ecs_key_border_color)

  for widget in color_grading_state.val.widgets {
    let is_selected = selected_option_eq(widget.option, selected_option)
    if background_store.contains(widget.button) {
      background_store.set(
        widget.button,
        @ui.BackgroundColor::new(
          if is_selected {
            selected_button_color()
          } else {
            normal_button_color()
          },
        ),
        tick,
      )
      |> ignore
    } else {
      background_store.insert(
        widget.button,
        @ui.BackgroundColor::new(
          if is_selected {
            selected_button_color()
          } else {
            normal_button_color()
          },
        ),
        tick,
      )
    }

    if border_store.contains(widget.button) {
      border_store.set(
        widget.button,
        @ui.BorderColor::new(
          if is_selected {
            @render2d.Color::black()
          } else {
            @render2d.Color::white()
          },
        ),
        tick,
      )
      |> ignore
    } else {
      border_store.insert(
        widget.button,
        @ui.BorderColor::new(
          if is_selected {
            @render2d.Color::black()
          } else {
            @render2d.Color::white()
          },
        ),
        tick,
      )
    }

    @text.text_set_content(widget.text, option_value_text(widget.option))
  }

  if color_grading_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, create_help_text())
  }
}

///|
fn handle_button_presses(world : @ecs.World) -> Bool {
  let mut changed = false
  let system_ticks = world.get_system_context().ticks()
  let interaction_store = world.component(@ui.ecs_key_interaction)
  interaction_store.for_each_changed(system_ticks, fn(entity, interaction) {
    if interaction != @ui.Interaction::Pressed {
      return
    }
    for widget in color_grading_state.val.widgets {
      if widget.button.id == entity.id &&
        widget.button.generation == entity.generation &&
        !selected_option_eq(
          color_grading_state.val.selected_option,
          widget.option,
        ) {
        color_grading_state.val.selected_option = widget.option
        changed = true
        break
      }
    }
  })
  changed
}

///|
fn adjust_color_grading_option(world : @ecs.World) -> Bool {
  let mut delta = 0.0F
  if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    delta = delta - OPTION_ADJUSTMENT_SPEED
  }
  if @input.key_pressed(@window.KeyCode::ArrowRight) {
    delta = delta + OPTION_ADJUSTMENT_SPEED
  }
  if delta == 0.0F {
    return false
  }

  let option = color_grading_state.val.selected_option
  let old_value = selected_option_get(
    option,
    color_grading_state.val.color_grading,
  )
  color_grading_state.val.color_grading = selected_option_set(
    option,
    color_grading_state.val.color_grading,
    old_value + delta,
  )
  apply_color_grading_proxy(world)
  true
}

///|
fn setup(world : @ecs.World) -> Unit {
  color_grading_state.val.selected_option = SelectedColorGradingOption::Global(
    SelectedGlobalColorGradingOption::Exposure,
  )
  color_grading_state.val.color_grading = default_color_grading_values()
  color_grading_state.val.camera = None
  color_grading_state.val.directional_light = None
  color_grading_state.val.help_text = None
  color_grading_state.val.widgets.clear()
  color_grading_state.val.ui_dirty = true

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraMono-Medium.ttf")

  add_basic_scene(world, asset_server)
  add_camera(world)
  setup_ui(world, font)
  apply_color_grading_proxy(world)
  update_ui_state(world)
  color_grading_state.val.ui_dirty = false
}

///|
fn update_system(world : @ecs.World) -> Unit {
  let selection_changed = handle_button_presses(world)
  let value_changed = adjust_color_grading_option(world)
  if selection_changed || value_changed || color_grading_state.val.ui_dirty {
    update_ui_state(world)
    color_grading_state.val.ui_dirty = false
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system_config(@app.system(update_system).after(@ui.ui_set_focus))
  .run()
}
