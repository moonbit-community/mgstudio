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
pub(all) enum ShadowAction {
  BlurDec
  BlurInc
  Reset
  ShapeDec
  ShapeInc
  SpreadDec
  SpreadInc
  XOffsetDec
  XOffsetInc
  YOffsetDec
  YOffsetInc
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) enum ShadowField {
  Blur
  Shape
  Spread
  XOffset
  YOffset
} derive(Eq, Debug, ToJson, FromJson)

///|
struct ShadowControlButton {
  action : ShadowAction
} derive(Eq, Debug, ToJson, FromJson)

///|
struct ShadowValueLabel {
  field : ShadowField
} derive(Eq, Debug, ToJson, FromJson)

///|
struct ShadowNode {} derive(Eq, Debug, ToJson, FromJson)

///|
struct ShadowSettings {
  blur : Float
  shape_index : Int
  spread : Float
  x_offset : Float
  y_offset : Float
}

///|
struct PressedControls {
  entities : Array[@core.Entity]
}

///|
let shadow_control_button_key : @ecs.ComponentKey[ShadowControlButton] = @ecs.register_component(
  debug_name="examples.ui.styling.box_shadow.ShadowControlButton",
)

///|
let shadow_value_label_key : @ecs.ComponentKey[ShadowValueLabel] = @ecs.register_component(
  debug_name="examples.ui.styling.box_shadow.ShadowValueLabel",
)

///|
let shadow_node_key : @ecs.ComponentKey[ShadowNode] = @ecs.register_component(
  debug_name="examples.ui.styling.box_shadow.ShadowNode",
)

///|
let shadow_settings_key : @ecs.ResourceKey[ShadowSettings] = @ecs.register_resource(
  debug_name="examples.ui.styling.box_shadow.ShadowSettings",
)

///|
let pressed_controls_key : @ecs.ResourceKey[PressedControls] = @ecs.register_resource(
  debug_name="examples.ui.styling.box_shadow.PressedControls",
)

///|
pub impl @ecs.Component for ShadowControlButton with component() {
  shadow_control_button_key
}

///|
pub impl @ecs.Component for ShadowValueLabel with component() {
  shadow_value_label_key
}

///|
pub impl @ecs.Component for ShadowNode with component() {
  shadow_node_key
}

///|
pub impl @app.Resource for ShadowSettings with resource() {
  shadow_settings_key
}

///|
pub impl @app.Resource for PressedControls with resource() {
  pressed_controls_key
}

///|
impl Default for ShadowSettings with default() {
  ShadowSettings::{
    x_offset: 20.0F,
    y_offset: 20.0F,
    blur: 10.0F,
    spread: 15.0F,
    shape_index: 0,
  }
}

///|
impl Default for PressedControls with default() {
  PressedControls::{ entities: [] }
}

///|
fn panel_background() -> @sprite.Color {
  @sprite.Color::srgb(0.12F, 0.12F, 0.12F)
}

///|
fn normal_button_color() -> @sprite.Color {
  @sprite.Color::srgb(0.15F, 0.15F, 0.15F)
}

///|
fn hovered_button_color() -> @sprite.Color {
  @sprite.Color::srgb(0.25F, 0.25F, 0.25F)
}

///|
fn pressed_button_color() -> @sprite.Color {
  @sprite.Color::srgb(0.35F, 0.75F, 0.35F)
}

///|
fn shadow_card_color() -> @sprite.Color {
  @sprite.Color::srgb(0.21F, 0.21F, 0.21F)
}

///|
fn array_contains_entity(
  entities : Array[@core.Entity],
  entity : @core.Entity,
) -> Bool {
  for existing in entities {
    if existing == entity {
      return true
    }
  }
  false
}

///|
fn shape_label(index : Int) -> String {
  match index {
    0 => "Square"
    1 => "Rounded"
    2 => "Circle"
    3 => "Pill"
    _ => "Tall Pill"
  }
}

///|
fn clamp_shape_index(index : Int) -> Int {
  if index < 0 {
    4
  } else if index > 4 {
    0
  } else {
    index
  }
}

///|
fn action_label(action : ShadowAction) -> String {
  match action {
    ShapeDec => "<"
    ShapeInc => ">"
    XOffsetDec => "-"
    XOffsetInc => "+"
    YOffsetDec => "-"
    YOffsetInc => "+"
    BlurDec => "-"
    BlurInc => "+"
    SpreadDec => "-"
    SpreadInc => "+"
    Reset => "Reset"
  }
}

///|
fn setting_label(field : ShadowField) -> String {
  match field {
    Shape => "Shape"
    XOffset => "X Offset"
    YOffset => "Y Offset"
    Blur => "Blur"
    Spread => "Spread"
  }
}

///|
fn apply_action(
  settings : ShadowSettings,
  action : ShadowAction,
) -> ShadowSettings {
  match action {
    ShapeDec =>
      ShadowSettings::{
        ..settings,
        shape_index: clamp_shape_index(settings.shape_index - 1),
      }
    ShapeInc =>
      ShadowSettings::{
        ..settings,
        shape_index: clamp_shape_index(settings.shape_index + 1),
      }
    XOffsetDec =>
      ShadowSettings::{ ..settings, x_offset: settings.x_offset - 5.0F }
    XOffsetInc =>
      ShadowSettings::{ ..settings, x_offset: settings.x_offset + 5.0F }
    YOffsetDec =>
      ShadowSettings::{ ..settings, y_offset: settings.y_offset - 5.0F }
    YOffsetInc =>
      ShadowSettings::{ ..settings, y_offset: settings.y_offset + 5.0F }
    BlurDec =>
      ShadowSettings::{
        ..settings,
        blur: if settings.blur < 2.0F {
          0.0F
        } else {
          settings.blur - 2.0F
        },
      }
    BlurInc => ShadowSettings::{ ..settings, blur: settings.blur + 2.0F }
    SpreadDec => ShadowSettings::{ ..settings, spread: settings.spread - 2.0F }
    SpreadInc => ShadowSettings::{ ..settings, spread: settings.spread + 2.0F }
    Reset => ShadowSettings::default()
  }
}

///|
fn field_value(settings : ShadowSettings, field : ShadowField) -> String {
  match field {
    Shape => shape_label(settings.shape_index)
    XOffset => "x = \{settings.x_offset.to_string()}"
    YOffset => "y = \{settings.y_offset.to_string()}"
    Blur => "blur = \{settings.blur.to_string()}"
    Spread => "spread = \{settings.spread.to_string()}"
  }
}

///|
fn shape_dimensions(index : Int) -> (@ui.Val, @ui.Val, @ui.BorderRadius) {
  match index {
    0 => (@ui.Val::Px(164.0F), @ui.Val::Px(164.0F), @ui.BorderRadius::default())
    1 =>
      (
        @ui.Val::Px(164.0F),
        @ui.Val::Px(164.0F),
        @ui.BorderRadius::all(@ui.Val::Px(41.0F)),
      )
    2 =>
      (
        @ui.Val::Px(164.0F),
        @ui.Val::Px(164.0F),
        @ui.BorderRadius::all(@ui.Val::Percent(100.0F)),
      )
    3 =>
      (
        @ui.Val::Px(240.0F),
        @ui.Val::Px(80.0F),
        @ui.BorderRadius::all(@ui.Val::Px(32.0F)),
      )
    _ =>
      (
        @ui.Val::Px(80.0F),
        @ui.Val::Px(240.0F),
        @ui.BorderRadius::all(@ui.Val::Px(32.0F)),
      )
  }
}

///|
fn text_font(font : @asset.Handle[@asset.Font], size : Float) -> @text.TextFont {
  @text.TextFont::from_font_size(@text.FontSize::Px(size)).with_font(font)
}

///|
fn spawn_text(
  world : @ecs.World,
  parent : @core.Entity,
  content : String,
  font : @asset.Handle[@asset.Font],
  size : Float,
  color : @sprite.Color,
) -> @core.Entity {
  let entity = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(entity)
    .insert(
      (
        @hierarchy.Parent::new(parent),
        @text.Text::new(content),
        text_font(font, size),
        @text.TextColor::new(color),
      ),
    ),
  )
  entity
}

///|
fn spawn_control_button(
  world : @ecs.World,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
  action : ShadowAction,
) -> Unit {
  let button = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(button)
    .insert(
      (
        @hierarchy.Parent::new(parent),
        @ui.Button::default(),
        ShadowControlButton::{ action, },
        @ui.Node::default()
        .with_align_items(@ui.AlignItems::Center)
        .with_justify_content(@ui.JustifyContent::Center)
        .with_border(@ui.UiRect::all(@ui.Val::Px(2.0F)))
        .with_padding(
          @ui.UiRect::new(
            @ui.Val::Px(10.0F),
            @ui.Val::Px(5.0F),
            @ui.Val::Px(10.0F),
            @ui.Val::Px(5.0F),
          ),
        ),
        @ui.BackgroundColor::new(normal_button_color()),
      ),
    ),
  )
  ignore(
    try! world
    .entity_mut(button)
    .insert_component(@ui.BorderColor::new(@sprite.Color::white())),
  )
  ignore(
    spawn_text(
      world,
      button,
      action_label(action),
      font,
      18.0F,
      @sprite.Color::white(),
    ),
  )
}

///|
fn spawn_value_label(
  world : @ecs.World,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
  field : ShadowField,
) -> Unit {
  let entity = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(entity)
    .insert(
      (
        @hierarchy.Parent::new(parent),
        ShadowValueLabel::{ field, },
        @text.Text::new(""),
        text_font(font, 16.0F),
        @text.TextColor::new(@sprite.Color::srgb(0.95F, 0.95F, 0.95F)),
      ),
    ),
  )
}

///|
fn spawn_control_row(
  world : @ecs.World,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
  field : ShadowField,
  dec_action : ShadowAction,
  inc_action : ShadowAction,
) -> Unit {
  let row = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(row)
    .insert(
      (
        @hierarchy.Parent::new(parent),
        @ui.Node::default()
        .with_display(@ui.Display::Grid)
        .with_grid_template_columns([
          @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(4), [
            @ui.GridTrack::Fr(1.0F),
          ]),
        ])
        .with_column_gap(@ui.Val::Px(8.0F))
        .with_width(@ui.Val::Percent(100.0F)),
      ),
    ),
  )
  ignore(
    spawn_text(
      world,
      row,
      setting_label(field),
      font,
      16.0F,
      @sprite.Color::white(),
    ),
  )
  spawn_control_button(world, row, font, dec_action)
  spawn_value_label(world, row, font, field)
  spawn_control_button(world, row, font, inc_action)
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.advance_sequence()
  ignore(tick)

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  ignore(
    @sprite.Camera2dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::identity(),
    ).spawn(world),
  )

  let root = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(root)
    .insert(
      (
        @ui.UiRoot::default(),
        @ui.Node::default()
        .with_width(@ui.Val::Percent(100.0F))
        .with_height(@ui.Val::Percent(100.0F))
        .with_align_items(@ui.AlignItems::Center)
        .with_justify_content(@ui.JustifyContent::Center),
        @ui.BackgroundColor::new(@sprite.Color::srgb(0.5F, 0.5F, 0.5F)),
      ),
    ),
  )

  let shadow_card = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(shadow_card)
    .insert(
      (
        @hierarchy.Parent::new(root),
        ShadowNode::{  },
        @ui.Node::default()
        .with_width(@ui.Val::Px(164.0F))
        .with_height(@ui.Val::Px(164.0F))
        .with_align_items(@ui.AlignItems::Center)
        .with_justify_content(@ui.JustifyContent::Center)
        .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F))),
        @ui.BorderColor::new(@sprite.Color::white()),
        @ui.BackgroundColor::new(shadow_card_color()),
      ),
    ),
  )
  ignore(
    try! world
    .entity_mut(shadow_card)
    .insert_component(
      @ui.BoxShadow::new(
        @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.8F),
        @ui.Val::Px(20.0F),
        @ui.Val::Px(20.0F),
        @ui.Val::Px(15.0F),
        @ui.Val::Px(10.0F),
      ),
    ),
  )
  ignore(
    spawn_text(
      world,
      shadow_card,
      "Shadow",
      font,
      22.0F,
      @sprite.Color::white(),
    ),
  )

  let panel = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(panel)
    .insert(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_flex_direction(@ui.FlexDirection::Column)
        .with_position_type(@ui.PositionType::Absolute)
        .with_left(@ui.Val::Px(24.0F))
        .with_bottom(@ui.Val::Px(24.0F))
        .with_width(@ui.Val::Px(320.0F))
        .with_padding(@ui.UiRect::all(@ui.Val::Px(16.0F)))
        .with_row_gap(@ui.Val::Px(10.0F)),
        @ui.BackgroundColor::new(panel_background()),
        @ui.BorderColor::new(@sprite.Color::new(1.0F, 1.0F, 1.0F, 0.15F)),
      ),
    ),
  )
  ignore(
    spawn_text(
      world,
      panel,
      "Box Shadow Controls",
      font,
      24.0F,
      @sprite.Color::white(),
    ),
  )

  spawn_control_row(world, panel, font, Shape, ShapeDec, ShapeInc)
  spawn_control_row(world, panel, font, XOffset, XOffsetDec, XOffsetInc)
  spawn_control_row(world, panel, font, YOffset, YOffsetDec, YOffsetInc)
  spawn_control_row(world, panel, font, Blur, BlurDec, BlurInc)
  spawn_control_row(world, panel, font, Spread, SpreadDec, SpreadInc)
  spawn_control_button(world, panel, font, Reset)
}

///|
fn update_shadow_controls(
  settings : @app.ResMut[ShadowSettings],
  pressed_controls : @app.ResMut[PressedControls],
  buttons : @ecs.Query[
    (
      @core.Entity,
      (
        (@ecs.Mut[@ui.BackgroundColor], @ecs.Mut[@ui.BorderColor]),
        (@ecs.Comp[@ui.Interaction], @ecs.Comp[ShadowControlButton]),
      ),
    ),
    @ecs.All,
  ],
) -> Unit {
  let previous = pressed_controls.peek().entities
  let mut next_settings = settings.peek()
  let next_pressed : Array[@core.Entity] = []
  try! buttons.view(fn(_query_entity, data) {
    let entity = data.0
    let ((background_mut, border_mut), (interaction_comp, action_comp)) = data.1
    let interaction = interaction_comp.value()
    let action = action_comp.value().action

    let background = match interaction {
      @ui.Interaction::Pressed => pressed_button_color()
      @ui.Interaction::Hovered => hovered_button_color()
      @ui.Interaction::None => normal_button_color()
    }
    let border = if interaction == @ui.Interaction::Pressed {
      @sprite.Color::white()
    } else {
      @sprite.Color::new(1.0F, 1.0F, 1.0F, 0.6F)
    }
    background_mut.set(@ui.BackgroundColor::new(background))
    border_mut.set(@ui.BorderColor::new(border))

    if interaction == @ui.Interaction::Pressed {
      next_pressed.push(entity)
      if !array_contains_entity(previous, entity) {
        next_settings = apply_action(next_settings, action)
      }
    }
  })
  settings.set(next_settings)
  pressed_controls.set(PressedControls::{ entities: next_pressed })
}

///|
fn update_shadow_node(
  settings : @app.Res[ShadowSettings],
  shadow_nodes : @ecs.Query[
    (@ecs.Mut[@ui.Node], @ecs.Mut[@ui.BoxShadow]),
    @ecs.With[ShadowNode],
  ],
) -> Unit {
  let current = settings.get()
  let (width, height, border_radius) = shape_dimensions(current.shape_index)
  try! shadow_nodes.view(fn(_entity, data) {
    let node_mut = data.0
    let shadow_mut = data.1
    let node = node_mut.value()
    node_mut.set(@ui.Node::{ ..node, width, height, border_radius })
    shadow_mut.set(
      @ui.BoxShadow::new(
        @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.8F),
        @ui.Val::Px(current.x_offset),
        @ui.Val::Px(current.y_offset),
        @ui.Val::Px(current.spread),
        @ui.Val::Px(current.blur),
      ),
    )
  })
}

///|
fn update_shadow_labels(
  settings : @app.Res[ShadowSettings],
  labels : @ecs.Query[
    (@ecs.Mut[@text.Text], @ecs.Comp[ShadowValueLabel]),
    @ecs.All,
  ],
) -> Unit {
  let current = settings.get()
  try! labels.view(fn(_entity, data) {
    let text_mut = data.0
    let field = data.1.value().field
    text_mut.modify(fn(value) { value.content = field_value(current, field) })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .insert_resource(ShadowSettings::default())
  .insert_resource(PressedControls::default())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(update_shadow_controls)),
  )
  .add_systems(@app.Update, @app.system(@app.system_param2(update_shadow_node)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(update_shadow_labels)),
  )
  .run()
}
