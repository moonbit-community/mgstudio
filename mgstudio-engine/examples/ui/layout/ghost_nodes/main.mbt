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
struct Counter {
  value : Int
} derive(ToJson, FromJson)

///|
struct ButtonPressState {
  pressed : Bool
} derive(ToJson, FromJson)

///|
let counter_key : @ecs.ComponentKey[Counter] = @ecs.register_component(
  debug_name="examples.ui.layout.ghost_nodes.counter",
)

///|
let button_press_state_key : @ecs.ComponentKey[ButtonPressState] = @ecs.register_component(
  debug_name="examples.ui.layout.ghost_nodes.button_press_state",
)

///|
pub impl @ecs.Component for Counter with component() {
  counter_key
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
fn button_color(interaction : @ui.Interaction) -> @sprite.Color {
  match interaction {
    @ui.Interaction::Pressed => pressed_button_color()
    @ui.Interaction::Hovered => hovered_button_color()
    @ui.Interaction::None => normal_button_color()
  }
}

///|
fn border_color(interaction : @ui.Interaction) -> @sprite.Color {
  match interaction {
    @ui.Interaction::Pressed => @sprite.Color::srgb(1.0F, 0.2F, 0.2F)
    @ui.Interaction::Hovered => @sprite.Color::white()
    @ui.Interaction::None => @sprite.Color::black()
  }
}

///|
fn spawn_text(
  commands : @app.Commands,
  parent : @core.Entity,
  content : String,
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  color : @sprite.Color,
  node? : @ui.Node = @ui.Node::default(),
) -> @core.Entity {
  commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      node,
      @text.Text::new(content),
      @text.TextFont::default().with_font(font).with_font_size(font_size),
      @text.TextColor::new(color),
    ),
  )
}

///|
fn spawn_button(
  commands : @app.Commands,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
) -> Unit {
  let button = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @ui.Button::default(),
      ButtonPressState::{ pressed: false },
      @ui.Node::default()
      .with_width(@ui.Val::Px(150.0F))
      .with_height(@ui.Val::Px(65.0F))
      .with_border(@ui.UiRect::all(@ui.Val::Px(5.0F)))
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center),
      @ui.BorderRadius::all(@ui.Val::Percent(100.0F)),
      @ui.BorderColor::new(@sprite.Color::black()),
      @ui.BackgroundColor::new(normal_button_color()),
    ),
  )
  ignore(
    spawn_text(
      commands,
      button,
      "0",
      font,
      33.0F,
      @sprite.Color::srgb(0.9F, 0.9F, 0.9F),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  let ghost_root = commands.spawn_component(@ui.GhostNode::default())
  let ghost_root_text_box = commands.spawn(
    (
      @hierarchy.Parent::new(ghost_root),
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_left(@ui.Val::Px(24.0F))
      .with_top(@ui.Val::Px(24.0F))
      .with_padding(@ui.UiRect::all(@ui.Val::Px(12.0F))),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.16F, 0.24F, 0.35F)),
    ),
  )
  ignore(
    spawn_text(
      commands,
      ghost_root_text_box,
      "This text node is rendered under a ghost root.",
      font,
      20.0F,
      @sprite.Color::white(),
    ),
  )

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center),
    ),
  )
  let panel = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_padding(@ui.UiRect::all(@ui.Val::Px(24.0F)))
      .with_row_gap(@ui.Val::Px(16.0F))
      .with_align_items(@ui.AlignItems::Center)
      .with_flex_direction(@ui.FlexDirection::Column),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.08F, 0.10F, 0.14F)),
    ),
  )
  ignore(
    spawn_text(
      commands,
      panel,
      "Ghost node children are laid out as direct descendants of the button row.",
      font,
      20.0F,
      @sprite.Color::srgb(0.92F, 0.92F, 0.92F),
    ),
  )
  let button_row = commands.spawn(
    (
      @hierarchy.Parent::new(panel),
      Counter::{ value: 0 },
      @ui.Node::default()
      .with_column_gap(@ui.Val::Px(16.0F))
      .with_align_items(@ui.AlignItems::Center)
      .with_flex_direction(@ui.FlexDirection::Row),
    ),
  )
  let ghost_parent = commands.spawn(
    (
      @hierarchy.Parent::new(button_row),
      @ui.GhostNode::default(),
      Counter::{ value: 0 },
    ),
  )
  spawn_button(commands, ghost_parent, font)
  spawn_button(commands, ghost_parent, font)
  spawn_button(commands, button_row, font)
}

///|
fn counter_value(world : @ecs.World, entity : @core.Entity) -> Int {
  match (try! world.get_by_key(entity, counter_key)) {
    Some(counter) => counter.value
    None => 0
  }
}

///|
fn increment_counter(world : @ecs.World, entity : @core.Entity) -> Unit {
  let entity_mut = try! world.entity_mut(entity)
  if (try! entity_mut.get_mut(key=counter_key)) is Some(counter) {
    let current = counter.value()
    counter.set(Counter::{ value: current.value + 1 })
  }
}

///|
fn update_label_text(
  world : @ecs.World,
  label_entity : @core.Entity,
  content : String,
) -> Unit {
  let entity_mut = try! world.entity_mut(label_entity)
  if (try! entity_mut.get_mut(key=@text.ecs_key_text)) is Some(text) {
    text.modify(fn(value) { value.content = content })
  }
}

///|
fn button_system(world : @ecs.World) -> Unit {
  world.for_each_component(@ui.ecs_key_interaction, fn(entity, interaction) {
    guard (try! world.contains_by_key(entity, @ui.ecs_key_button)) else {
      return
    }
    guard (try! world.get_by_key(entity, @hierarchy.ecs_key_parent))
      is Some(parent) else {
      return
    }
    let next_pressed = interaction == @ui.Interaction::Pressed
    let was_pressed = match
      (try! world.get_by_key(entity, button_press_state_key)) {
      Some(state) => state.pressed
      None => false
    }
    if next_pressed && !was_pressed {
      increment_counter(world, parent.entity)
    }
    if (try! world.contains_by_key(entity, button_press_state_key)) {
      try! (world.replace(entity, button_press_state_key, ButtonPressState::{
        pressed: next_pressed,
      })
      |> ignore)
    } else {
      try! world.set_by_key(entity, button_press_state_key, ButtonPressState::{
        pressed: next_pressed,
      })
    }
    ignore(
      try! world.replace(
        entity,
        @ui.ecs_key_background_color,
        @ui.BackgroundColor::new(button_color(interaction)),
      ),
    )
    ignore(
      try! world.replace(
        entity,
        @ui.ecs_key_border_color,
        @ui.BorderColor::new(border_color(interaction)),
      ),
    )
    guard (try! world.get_by_key(entity, @hierarchy.ecs_key_children))
      is Some(children) else {
      return
    }
    if children.entities.length() == 0 {
      return
    }
    update_label_text(
      world,
      children.entities[0],
      counter_value(world, parent.entity).to_string(),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_startup_system_param2(setup)
  .add_systems(@app.Update, @app.system(button_system).after(@ui.ui_set_focus))
  .run()
}
