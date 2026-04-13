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
pub(all) enum ConstraintKind {
  FlexBasis
  Width
  MinWidth
  MaxWidth
} derive(Eq, Debug, ToJson, FromJson)

///|
struct Bar {} derive(Eq, Debug, ToJson, FromJson)

///|
struct ConstraintButton {
  kind : ConstraintKind
  value : @ui.Val
} derive(Eq, Debug, ToJson, FromJson)

///|
struct ConstraintSettings {
  flex_basis : @ui.Val
  width : @ui.Val
  min_width : @ui.Val
  max_width : @ui.Val
}

///|
let bar_key : @ecs.ComponentKey[Bar] = @ecs.register_component(
  debug_name="examples.ui.layout.size_constraints.Bar",
)

///|
let constraint_button_key : @ecs.ComponentKey[ConstraintButton] = @ecs.register_component(
  debug_name="examples.ui.layout.size_constraints.ConstraintButton",
)

///|
let constraint_settings_key : @ecs.ResourceKey[ConstraintSettings] = @ecs.register_resource(
  debug_name="examples.ui.layout.size_constraints.ConstraintSettings",
)

///|
pub impl @ecs.Component for Bar with component() {
  bar_key
}

///|
pub impl @ecs.Component for ConstraintButton with component() {
  constraint_button_key
}

///|
pub impl @app.Resource for ConstraintSettings with resource() {
  constraint_settings_key
}

///|
impl Default for ConstraintSettings with default() {
  ConstraintSettings::{
    flex_basis: @ui.Val::Percent(100.0F),
    width: @ui.Val::Auto,
    min_width: @ui.Val::Auto,
    max_width: @ui.Val::Auto,
  }
}

///|
fn title_color() -> @sprite.Color {
  @sprite.Color::srgb(0.9F, 0.9F, 0.9F)
}

///|
fn active_button_color() -> @sprite.Color {
  @sprite.Color::srgb(1.0F, 1.0F, 1.0F)
}

///|
fn inactive_button_color() -> @sprite.Color {
  @sprite.Color::srgb(0.07F, 0.07F, 0.3F)
}

///|
fn hovered_button_color() -> @sprite.Color {
  @sprite.Color::srgb(0.22F, 0.22F, 0.22F)
}

///|
fn active_border_color() -> @sprite.Color {
  @sprite.Color::srgb(0.98F, 0.92F, 0.84F)
}

///|
fn inactive_border_color() -> @sprite.Color {
  @sprite.Color::black()
}

///|
fn text_font(font : @asset.Handle[@asset.Font], size : Float) -> @text.TextFont {
  @text.TextFont::from_font_size(@text.FontSize::Px(size)).with_font(font)
}

///|
fn constraint_label(kind : ConstraintKind) -> String {
  match kind {
    FlexBasis => "flex_basis"
    Width => "width"
    MinWidth => "min_width"
    MaxWidth => "max_width"
  }
}

///|
fn settings_value(
  settings : ConstraintSettings,
  kind : ConstraintKind,
) -> @ui.Val {
  match kind {
    FlexBasis => settings.flex_basis
    Width => settings.width
    MinWidth => settings.min_width
    MaxWidth => settings.max_width
  }
}

///|
fn apply_constraint(
  settings : ConstraintSettings,
  button : ConstraintButton,
) -> ConstraintSettings {
  match button.kind {
    FlexBasis => ConstraintSettings::{ ..settings, flex_basis: button.value }
    Width => ConstraintSettings::{ ..settings, width: button.value }
    MinWidth => ConstraintSettings::{ ..settings, min_width: button.value }
    MaxWidth => ConstraintSettings::{ ..settings, max_width: button.value }
  }
}

///|
fn button_values() -> Array[(@ui.Val, String)] {
  [
    (@ui.Val::Auto, "Auto"),
    (@ui.Val::Percent(0.0F), "0%"),
    (@ui.Val::Percent(25.0F), "25%"),
    (@ui.Val::Percent(50.0F), "50%"),
    (@ui.Val::Percent(75.0F), "75%"),
    (@ui.Val::Percent(100.0F), "100%"),
    (@ui.Val::Percent(125.0F), "125%"),
  ]
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
fn spawn_button(
  world : @ecs.World,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
  kind : ConstraintKind,
  value : @ui.Val,
  label : String,
) -> Unit {
  let button = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(button)
    .insert(
      (
        @hierarchy.Parent::new(parent),
        @ui.Button::default(),
        ConstraintButton::{ kind, value },
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
        )
        .with_margin(
          @ui.UiRect::new(
            @ui.Val::Px(2.0F),
            @ui.Val::Px(2.0F),
            @ui.Val::Px(2.0F),
            @ui.Val::Px(2.0F),
          ),
        ),
        @ui.BackgroundColor::new(inactive_button_color()),
      ),
    ),
  )
  ignore(
    try! world
    .entity_mut(button)
    .insert_component(@ui.BorderColor::new(inactive_border_color())),
  )
  ignore(spawn_text(world, button, label, font, 16.0F, title_color()))
}

///|
fn spawn_button_row(
  world : @ecs.World,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
  kind : ConstraintKind,
) -> Unit {
  let row = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(row)
    .insert(
      (
        @hierarchy.Parent::new(parent),
        @ui.Node::default()
        .with_flex_direction(@ui.FlexDirection::Row)
        .with_align_items(@ui.AlignItems::Center)
        .with_margin(
          @ui.UiRect::new(
            @ui.Val::Px(0.0F),
            @ui.Val::Px(2.0F),
            @ui.Val::Px(0.0F),
            @ui.Val::Px(2.0F),
          ),
        ),
        @ui.BackgroundColor::new(@sprite.Color::black()),
      ),
    ),
  )
  let label = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(label)
    .insert(
      (
        @hierarchy.Parent::new(row),
        @ui.Node::{
          ..@ui.Node::default(),
          min_width: @ui.Val::Px(180.0F),
          max_width: @ui.Val::Px(180.0F),
        },
      ),
    ),
  )
  ignore(
    spawn_text(
      world,
      label,
      constraint_label(kind),
      font,
      18.0F,
      @sprite.Color::black(),
    ),
  )

  let buttons = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(buttons)
    .insert(
      (
        @hierarchy.Parent::new(row),
        @ui.Node::default().with_flex_direction(@ui.FlexDirection::Row),
      ),
    ),
  )

  for button_value in button_values() {
    let (value, label_text) = button_value
    spawn_button(world, buttons, font, kind, value, label_text)
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.advance_sequence()
  ignore(tick)

  let font = @asset.AssetServer::new().load_font("fonts/FiraSans-Bold.ttf")

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
        .with_justify_content(@ui.JustifyContent::Center)
        .with_align_items(@ui.AlignItems::Center),
        @ui.BackgroundColor::new(@sprite.Color::black()),
      ),
    ),
  )

  let content = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(content)
    .insert(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_flex_direction(@ui.FlexDirection::Column)
        .with_align_items(@ui.AlignItems::Center)
        .with_justify_content(@ui.JustifyContent::Center),
      ),
    ),
  )

  ignore(
    spawn_text(
      world,
      content,
      "Size Constraints Example",
      font,
      33.0F,
      title_color(),
    ),
  )

  let outer_bar = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(outer_bar)
    .insert(
      (
        @hierarchy.Parent::new(content),
        @ui.Node::default()
        .with_flex_basis(@ui.Val::Percent(100.0F))
        .with_padding(@ui.UiRect::all(@ui.Val::Px(10.0F)))
        .with_margin(
          @ui.UiRect::new(
            @ui.Val::Px(0.0F),
            @ui.Val::Px(0.0F),
            @ui.Val::Px(0.0F),
            @ui.Val::Px(25.0F),
          ),
        ),
        @ui.BackgroundColor::new(@sprite.Color::srgb(1.0F, 0.92F, 0.0F)),
      ),
    ),
  )

  let frame = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(frame)
    .insert(
      (
        @hierarchy.Parent::new(outer_bar),
        @ui.Node::default()
        .with_width(@ui.Val::Percent(100.0F))
        .with_height(@ui.Val::Px(100.0F))
        .with_padding(@ui.UiRect::all(@ui.Val::Px(4.0F))),
        @ui.BackgroundColor::new(@sprite.Color::black()),
      ),
    ),
  )

  let bar = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(bar)
    .insert(
      (
        @hierarchy.Parent::new(frame),
        @ui.Node::default(),
        @ui.BackgroundColor::new(@sprite.Color::white()),
        Bar::{  },
      ),
    ),
  )

  let panel = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(panel)
    .insert(
      (
        @hierarchy.Parent::new(content),
        @ui.Node::default()
        .with_flex_direction(@ui.FlexDirection::Column)
        .with_padding(@ui.UiRect::all(@ui.Val::Px(10.0F)))
        .with_margin(
          @ui.UiRect::new(
            @ui.Val::Px(0.0F),
            @ui.Val::Px(50.0F),
            @ui.Val::Px(0.0F),
            @ui.Val::Px(0.0F),
          ),
        ),
        @ui.BackgroundColor::new(@sprite.Color::srgb(1.0F, 0.92F, 0.0F)),
      ),
    ),
  )

  for kind in [MinWidth, FlexBasis, Width, MaxWidth] {
    spawn_button_row(world, panel, font, kind)
  }
}

///|
fn update_buttons(
  settings : @app.ResMut[ConstraintSettings],
  buttons : @ecs.Query[
    (
      (@ecs.Mut[@ui.BackgroundColor], @ecs.Mut[@ui.BorderColor]),
      (@ecs.Comp[@ui.Interaction], @ecs.Comp[ConstraintButton]),
    ),
    @ecs.All,
  ],
) -> Unit {
  let settings_ref = settings.get_ref()
  try! buttons.view(fn(_entity, data) {
    let ((background_mut, border_mut), (interaction_comp, button_comp)) = data
    let interaction = interaction_comp.value()
    let button = button_comp.value()
    if interaction == @ui.Interaction::Pressed {
      settings_ref.val = apply_constraint(settings_ref.val, button)
    }
    let active = settings_value(settings_ref.val, button.kind) == button.value
    let background_color = match interaction {
      @ui.Interaction::Pressed => active_button_color()
      @ui.Interaction::Hovered => hovered_button_color()
      @ui.Interaction::None =>
        if active {
          active_button_color()
        } else {
          inactive_button_color()
        }
    }
    let border_color = if active {
      active_border_color()
    } else {
      inactive_border_color()
    }
    background_mut.set(@ui.BackgroundColor::new(background_color))
    border_mut.set(@ui.BorderColor::new(border_color))
  })
}

///|
fn apply_settings(
  settings : @app.Res[ConstraintSettings],
  bars : @ecs.Query[@ecs.Mut[@ui.Node], @ecs.With[Bar]],
) -> Unit {
  let current = settings.get()
  try! bars.view(fn(_entity, node_mut) {
    let node = node_mut.value()
    node_mut.set(@ui.Node::{
      ..node,
      flex_basis: current.flex_basis,
      width: current.width,
      min_width: current.min_width,
      max_width: current.max_width,
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .insert_resource(ConstraintSettings::default())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(@app.system_param2(update_buttons)))
  .add_systems(@app.Update, @app.system(@app.system_param2(apply_settings)))
  .run()
}
