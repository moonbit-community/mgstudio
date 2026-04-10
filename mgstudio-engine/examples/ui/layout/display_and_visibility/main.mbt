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
pub(all) enum ToggleKind {
  DisplayTarget
  VisibilityTarget
} derive(Eq, Debug, ToJson, FromJson)

///|
struct TargetPanel {
  index : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
struct ToggleButtonAction {
  target_index : Int
  kind : ToggleKind
} derive(Eq, Debug, ToJson, FromJson)

///|
struct ButtonPressState {
  pressed : Bool
} derive(Eq, Debug, ToJson, FromJson)

///|
let target_panel_key : @ecs.ComponentKey[TargetPanel] = @ecs.register_component(
  debug_name="examples.ui.layout.display_and_visibility.TargetPanel",
)

///|
let toggle_button_action_key : @ecs.ComponentKey[ToggleButtonAction] = @ecs.register_component(
  debug_name="examples.ui.layout.display_and_visibility.ToggleButtonAction",
)

///|
let button_press_state_key : @ecs.ComponentKey[ButtonPressState] = @ecs.register_component(
  debug_name="examples.ui.layout.display_and_visibility.ButtonPressState",
)

///|
pub impl @ecs.Component for TargetPanel with component() {
  target_panel_key
}

///|
pub impl @ecs.Component for ToggleButtonAction with component() {
  toggle_button_action_key
}

///|
pub impl @ecs.Component for ButtonPressState with component() {
  button_press_state_key
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
fn text_color() -> @sprite.Color {
  @sprite.Color::srgb(0.92F, 0.92F, 0.92F)
}

///|
fn spawn_node(
  world : @ecs.World,
  parent : @core.Entity?,
  node : @ui.Node,
  background : @ui.BackgroundColor?,
) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(entity, @ui.ecs_key_node, node)
  if parent is Some(parent_entity) {
    try! world.set_by_key(
      entity,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(parent_entity),
    )
  }
  if background is Some(color) {
    try! world.set_by_key(entity, @ui.ecs_key_background_color, color)
  }
  entity
}

///|
fn spawn_text(
  world : @ecs.World,
  parent : @core.Entity,
  content : String,
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  color : @sprite.Color,
  node? : @ui.Node = @ui.Node::default(),
) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(entity, @ui.ecs_key_node, node)
  try! world.set_by_key(entity, @text.ecs_key_text, @text.Text::new(content))
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(font_size),
  )
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(color),
  )
  entity
}

///|
fn target_name(index : Int) -> String {
  match index {
    0 => "Outer"
    1 => "Upper Mid"
    2 => "Lower Mid"
    _ => "Inner"
  }
}

///|
fn panel_color(index : Int) -> @sprite.Color {
  match index {
    0 => @sprite.Color::srgb(0.15F, 0.29F, 0.43F)
    1 => @sprite.Color::srgb(0.27F, 0.42F, 0.48F)
    2 => @sprite.Color::srgb(0.40F, 0.62F, 0.70F)
    _ => @sprite.Color::srgb(0.68F, 0.80F, 0.89F)
  }
}

///|
fn panel_size(index : Int) -> Float {
  match index {
    0 => 360.0F
    1 => 280.0F
    2 => 200.0F
    _ => 120.0F
  }
}

///|
fn display_text(display : @ui.Display) -> String {
  match display {
    Flex => "Display::Flex"
    None => "Display::None"
    Block => "Display::Block"
    Grid => "Display::Grid"
  }
}

///|
fn next_display(display : @ui.Display) -> @ui.Display {
  match display {
    Flex => @ui.Display::None
    None => @ui.Display::Flex
    Block => @ui.Display::None
    Grid => @ui.Display::None
  }
}

///|
fn visibility_text(visibility : @visibility.Visibility) -> String {
  match visibility {
    Inherited => "Visibility::Inherited"
    Visible => "Visibility::Visible"
    Hidden => "Visibility::Hidden"
  }
}

///|
fn next_visibility(
  visibility : @visibility.Visibility,
) -> @visibility.Visibility {
  match visibility {
    Inherited => @visibility.Visibility::Visible
    Visible => @visibility.Visibility::Hidden
    Hidden => @visibility.Visibility::Inherited
  }
}

///|
fn find_target_entity(world : @ecs.World, target_index : Int) -> @core.Entity? {
  let found : Ref[@core.Entity?] = Ref::new(None)
  let query : @ecs.Query[(@core.Entity, @ecs.Comp[TargetPanel]), @ecs.All] = @ecs.query(
    world,
  )
  try! query.view(fn(_entity, data) {
    let (entity, marker) = data
    if found.val is None && marker.value().index == target_index {
      found.val = Some(entity)
    }
  })
  found.val
}

///|
fn button_label_text(world : @ecs.World, action : ToggleButtonAction) -> String {
  guard find_target_entity(world, action.target_index) is Some(target_entity) else {
    return if action.kind == ToggleKind::DisplayTarget {
      "Display::<missing>"
    } else {
      "Visibility::<missing>"
    }
  }
  match action.kind {
    DisplayTarget =>
      match (try! world.get_by_key(target_entity, @ui.ecs_key_node)) {
        Some(node) => display_text(node.display)
        None => "Display::<missing>"
      }
    VisibilityTarget =>
      match
        (try! world.get_by_key(
          target_entity,
          @visibility.Visibility::component(),
        )) {
        Some(visibility) => visibility_text(visibility)
        None => "Visibility::<missing>"
      }
  }
}

///|
fn apply_button_action(world : @ecs.World, action : ToggleButtonAction) -> Unit {
  guard find_target_entity(world, action.target_index) is Some(target_entity) else {
    return
  }
  let entity_mut = try! world.entity_mut(target_entity)
  match action.kind {
    DisplayTarget =>
      if (try! entity_mut.get_mut(key=@ui.ecs_key_node)) is Some(node) {
        let current = node.value()
        node.set({ ..current, display: next_display(current.display) })
      }
    VisibilityTarget =>
      if (try! entity_mut.get_mut(key=@visibility.Visibility::component()))
        is Some(visibility) {
        visibility.set(next_visibility(visibility.value()))
      }
  }
}

///|
fn update_button_visuals(
  world : @ecs.World,
  entity : @core.Entity,
  interaction : @ui.Interaction,
) -> Unit {
  let bg = match interaction {
    @ui.Interaction::Pressed => pressed_button_color()
    @ui.Interaction::Hovered => hovered_button_color()
    @ui.Interaction::None => normal_button_color()
  }
  let border = match interaction {
    @ui.Interaction::Pressed => @sprite.Color::srgb(1.0F, 0.2F, 0.2F)
    @ui.Interaction::Hovered => @sprite.Color::white()
    @ui.Interaction::None => @sprite.Color::black()
  }
  ignore(
    try! world.replace(
      entity,
      @ui.ecs_key_background_color,
      @ui.BackgroundColor::new(bg),
    ),
  )
  ignore(
    try! world.replace(
      entity,
      @ui.ecs_key_border_color,
      @ui.BorderColor::new(border),
    ),
  )
}

///|
fn update_button_label(
  world : @ecs.World,
  label_entity : @core.Entity,
  content : String,
) -> Unit {
  let entity_mut = try! world.entity_mut(label_entity)
  if (try! entity_mut.get_mut(key=@text.ecs_key_text)) is Some(text) {
    text.get_ref().val.content = content
  }
}

///|
fn spawn_button(
  world : @ecs.World,
  parent : @core.Entity,
  action : ToggleButtonAction,
  font : @asset.Handle[@asset.Font],
) -> Unit {
  let button = spawn_node(
    world,
    Some(parent),
    @ui.Node::default()
    .with_width(@ui.Val::Px(240.0F))
    .with_height(@ui.Val::Px(42.0F))
    .with_border(@ui.UiRect::all(@ui.Val::Px(3.0F)))
    .with_padding(@ui.UiRect::all(@ui.Val::Px(8.0F)))
    .with_align_items(@ui.AlignItems::Center)
    .with_justify_content(@ui.JustifyContent::Center),
    Some(@ui.BackgroundColor::new(normal_button_color())),
  )
  try! world.set_by_key(button, @ui.ecs_key_button, @ui.Button::default())
  try! world.set_by_key(
    button,
    @ui.ecs_key_border_color,
    @ui.BorderColor::new(@sprite.Color::black()),
  )
  try! world.set_by_key(
    button,
    @ui.ecs_key_border_radius,
    @ui.BorderRadius::all(@ui.Val::Percent(100.0F)),
  )
  try! world.set_by_key(button, toggle_button_action_key, action)
  try! world.set_by_key(button, button_press_state_key, ButtonPressState::{
    pressed: false,
  })
  ignore(spawn_text(world, button, "", font, 15.0F, text_color()))
}

///|
fn spawn_target_panel(
  world : @ecs.World,
  parent : @core.Entity?,
  index : Int,
  font : @asset.Handle[@asset.Font],
) -> @core.Entity {
  let size = panel_size(index)
  let panel = spawn_node(
    world,
    parent,
    @ui.Node::default()
    .with_width(@ui.Val::Px(size))
    .with_height(@ui.Val::Px(size))
    .with_padding(@ui.UiRect::all(@ui.Val::Px(18.0F)))
    .with_align_items(@ui.AlignItems::FlexEnd)
    .with_justify_content(@ui.JustifyContent::FlexEnd)
    .with_border(@ui.UiRect::all(@ui.Val::Px(4.0F))),
    Some(@ui.BackgroundColor::new(panel_color(index))),
  )
  try! world.set_by_key(panel, target_panel_key, TargetPanel::{ index, })
  try! world.set_by_key(
    panel,
    @visibility.Visibility::component(),
    @visibility.Visibility::Inherited,
  )
  try! world.set_by_key(
    panel,
    @ui.ecs_key_border_color,
    @ui.BorderColor::new(@sprite.Color::white()),
  )
  ignore(
    spawn_text(
      world,
      panel,
      target_name(index),
      font,
      20.0F,
      if index == 3 {
        @sprite.Color::black()
      } else {
        @sprite.Color::white()
      },
      node=@ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_left(@ui.Val::Px(10.0F))
        .with_top(@ui.Val::Px(10.0F)),
    ),
  )
  panel
}

///|
fn setup(world : @ecs.World) -> Unit {
  ignore(world.advance_sequence())
  let font = @asset.AssetServer::new().load_font("fonts/FiraSans-Bold.ttf")

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let root = spawn_node(
    world,
    None,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_padding(@ui.UiRect::all(@ui.Val::Px(16.0F)))
    .with_row_gap(@ui.Val::Px(12.0F)),
    Some(@ui.BackgroundColor::new(@sprite.Color::black())),
  )
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())

  ignore(
    spawn_text(
      world,
      root,
      "Click the buttons to toggle Display and Visibility on the nested panels.",
      font,
      18.0F,
      text_color(),
    ),
  )

  let content = spawn_node(
    world,
    Some(root),
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_flex_direction(@ui.FlexDirection::Row)
    .with_column_gap(@ui.Val::Px(18.0F)),
    None,
  )

  let left = spawn_node(
    world,
    Some(content),
    @ui.Node::default()
    .with_width(@ui.Val::Percent(60.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_align_items(@ui.AlignItems::Center)
    .with_justify_content(@ui.JustifyContent::Center),
    Some(@ui.BackgroundColor::new(@sprite.Color::srgb(0.04F, 0.04F, 0.04F))),
  )
  let right = spawn_node(
    world,
    Some(content),
    @ui.Node::default()
    .with_width(@ui.Val::Px(320.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_padding(@ui.UiRect::all(@ui.Val::Px(12.0F)))
    .with_row_gap(@ui.Val::Px(12.0F)),
    Some(@ui.BackgroundColor::new(@sprite.Color::srgb(0.08F, 0.08F, 0.08F))),
  )

  let target0 = spawn_target_panel(world, Some(left), 0, font)
  let target1 = spawn_target_panel(world, Some(target0), 1, font)
  let target2 = spawn_target_panel(world, Some(target1), 2, font)
  ignore(spawn_target_panel(world, Some(target2), 3, font))

  for i in 0..<4 {
    let row = spawn_node(
      world,
      Some(right),
      @ui.Node::default()
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_row_gap(@ui.Val::Px(6.0F))
      .with_padding(@ui.UiRect::all(@ui.Val::Px(10.0F))),
      Some(@ui.BackgroundColor::new(@sprite.Color::srgb(0.12F, 0.12F, 0.12F))),
    )
    ignore(
      spawn_text(
        world,
        row,
        target_name(i),
        font,
        18.0F,
        @sprite.Color::white(),
      ),
    )
    spawn_button(
      world,
      row,
      ToggleButtonAction::{ target_index: i, kind: ToggleKind::DisplayTarget },
      font,
    )
    spawn_button(
      world,
      row,
      ToggleButtonAction::{
        target_index: i,
        kind: ToggleKind::VisibilityTarget,
      },
      font,
    )
  }

  ignore(
    spawn_text(
      world,
      right,
      "Display::None removes layout space.\nVisibility::Hidden keeps layout space but hides the subtree.",
      font,
      14.0F,
      @sprite.Color::srgb(1.0F, 0.85F, 0.85F),
    ),
  )
}

///|
fn display_and_visibility_system(world : @ecs.World) -> Unit {
  ignore(world.advance_sequence())

  let triggered : Array[ToggleButtonAction] = []
  let edge_query : @ecs.Query[
    (
      @ecs.Comp[ToggleButtonAction],
      @ecs.Comp[@ui.Interaction],
      @ecs.Mut[ButtonPressState],
    ),
    @ecs.With[@ui.Button],
  ] = @ecs.query_filtered(world, @ecs.With::new(@ui.Button::component()))
  try! edge_query.view(fn(_entity, data) {
    let (action, interaction, button_state) = data
    let is_pressed = interaction.value() == @ui.Interaction::Pressed
    if is_pressed && !button_state.value().pressed {
      triggered.push(action.value())
    }
    button_state.set(ButtonPressState::{ pressed: is_pressed })
  })

  for action in triggered {
    apply_button_action(world, action)
  }

  let button_query : @ecs.Query[
    (
      @ecs.Comp[ToggleButtonAction],
      @ecs.Comp[@ui.Interaction],
      @ecs.Comp[@hierarchy.Children],
    ),
    @ecs.With[@ui.Button],
  ] = @ecs.query_filtered(world, @ecs.With::new(@ui.Button::component()))
  try! button_query.view(fn(entity, data) {
    let (action, interaction, children) = data
    update_button_visuals(world, entity, interaction.value())
    let entities = children.value().entities()
    if entities.length() > 0 {
      update_button_label(
        world,
        entities[0],
        button_label_text(world, action.value()),
      )
    }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(setup))
  .add_system_config(
    @app.system(display_and_visibility_system).after(@ui.ui_set_focus),
  )
  .run()
}
