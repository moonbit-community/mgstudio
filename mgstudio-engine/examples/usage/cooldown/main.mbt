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
/// Demonstrates implementing a cooldown in UI.
/// We create four food buttons to eat with 2, 1, 10, and 4 seconds cooldown.

///|
struct FoodItem {
  name : String
  cooldown_seconds : Float
  index : Int
}

///|
struct AbilityName {
  value : String
}

///|
let ability_name_key : @ecs.ComponentKey[AbilityName] = @ecs.register_component(
  debug_name="examples.usage.cooldown.AbilityName",
)

///|
pub impl @ecs.Component for AbilityName with component() {
  ability_name_key
}

///|
struct Cooldown {
  mut timer : @time.Timer
  mut previous_interaction : @ui.Interaction
  overlay_entity : @core.Entity
}

///|
let cooldown_key : @ecs.ComponentKey[Cooldown] = @ecs.register_component(
  debug_name="examples.usage.cooldown.Cooldown",
)

///|
pub impl @ecs.Component for Cooldown with component() {
  cooldown_key
}

///|
struct ActiveCooldown {}

///|
let active_cooldown_key : @ecs.ComponentKey[ActiveCooldown] = @ecs.register_component(
  debug_name="examples.usage.cooldown.ActiveCooldown",
)

///|
pub impl @ecs.Component for ActiveCooldown with component() {
  active_cooldown_key
}

///|
struct StatusLabel {}

///|
let status_label_key : @ecs.ComponentKey[StatusLabel] = @ecs.register_component(
  debug_name="examples.usage.cooldown.StatusLabel",
)

///|
pub impl @ecs.Component for StatusLabel with component() {
  status_label_key
}

///|
fn food_items() -> Array[FoodItem] {
  [
    FoodItem::{ name: "an apple", cooldown_seconds: 2.0F, index: 2 },
    FoodItem::{ name: "a burger", cooldown_seconds: 1.0F, index: 23 },
    FoodItem::{ name: "chocolate", cooldown_seconds: 10.0F, index: 32 },
    FoodItem::{ name: "cherries", cooldown_seconds: 4.0F, index: 41 },
  ]
}

///|
fn food_button_color() -> @sprite.Color {
  @sprite.Color::new(0.5803922F, 0.6392157F, 0.72156864F, 1.0F)
}

///|
fn food_overlay_color() -> @sprite.Color {
  @sprite.Color::new(0.972549F, 0.98039216F, 0.9882353F, 0.5F)
}

///|
fn update_status_text(
  status_labels : @ecs.Query[@ecs.Mut[@text.Text], @ecs.With[StatusLabel]],
  content : String,
) -> Unit {
  try! status_labels.view(fn(_entity, text) {
    text.get_ref().val.content = content
  })
}

///|
fn build_ability(
  commands : @app.Commands,
  root : @core.Entity,
  texture : @asset.Handle[@asset.Image],
  layout : @asset.Handle[@asset.TextureAtlasLayout],
  food : FoodItem,
) -> Unit {
  let button = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_width(@ui.Val::Px(80.0F))
      .with_height(@ui.Val::Px(80.0F))
      .with_flex_direction(@ui.FlexDirection::ColumnReverse),
      @ui.BackgroundColor::new(food_button_color()),
      @ui.Button::default(),
      @ui.ImageNode::from_atlas_image(
        texture,
        @asset.TextureAtlas::new(layout, food.index),
      ),
    ),
  )
  let overlay = commands.spawn(
    (
      @hierarchy.Parent::new(button),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(0.0F)),
      @ui.BackgroundColor::new(food_overlay_color()),
    ),
  )
  commands
  .entity(button)
  .insert(
    (
      AbilityName::{ value: food.name },
      Cooldown::{
        timer: @time.Timer::from_seconds(
          food.cooldown_seconds,
          @time.TimerMode::Once,
        ),
        previous_interaction: @ui.Interaction::None,
        overlay_entity: overlay,
      },
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  texture_atlas_layouts : @app.ResMut[@asset.Assets[@asset.TextureAtlasLayout]],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  let texture = asset_server.get().load("textures/food_kenney.png")
  let layout = texture_atlas_layouts.get_ref().val.add(
    @asset.TextureAtlasLayout::from_grid(@math.UVec2::splat(64), 7, 7),
  )

  let root = commands.spawn_component(
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_align_items(@ui.AlignItems::Center)
    .with_justify_content(@ui.JustifyContent::Center)
    .with_column_gap(@ui.Val::Px(15.0F)),
  )
  for food in food_items() {
    build_ability(commands, root, texture, layout, food)
  }

  ignore(
    commands.spawn(
      (
        @text.Text::new("*Click some food to eat it*"),
        @text.TextFont::default().with_font_size(20.0F),
        @text.TextColor::new(@sprite.Color::white()),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.Val::Px(12.0F))
        .with_left(@ui.Val::Px(12.0F)),
        StatusLabel::{  },
      ),
    ),
  )
}

///|
fn activate_ability(
  commands : @app.Commands,
  interactions : @ecs.Query[
    (@ecs.Comp[@ui.Interaction], @ecs.Mut[Cooldown], @ecs.Comp[AbilityName]),
    @ecs.With[@ui.Button],
  ],
  status_labels : @ecs.Query[@ecs.Mut[@text.Text], @ecs.With[StatusLabel]],
  active_cooldowns : @ecs.Query[@ecs.Comp[ActiveCooldown], @ecs.All],
) -> Unit {
  try! interactions.view(fn(entity, data) {
    let (interaction, cooldown, ability_name) = data
    let interaction = interaction.value()
    let ability_name = ability_name.value()
    let cooldown_ref = cooldown.get_ref()
    let was_pressed = cooldown_ref.val.previous_interaction ==
      @ui.Interaction::Pressed
    cooldown_ref.val.previous_interaction = interaction
    guard interaction == @ui.Interaction::Pressed && !was_pressed else {
      return
    }

    if (try! active_cooldowns.get(entity)) is Some(_) {
      let remaining_seconds = cooldown_ref.val.timer
        .remaining_secs()
        .to_double()
        .ceil()
        .to_int()
      let message = "You can eat " +
        ability_name.value +
        " again in " +
        remaining_seconds.to_string() +
        " seconds."
      update_status_text(status_labels, message)
      return
    }

    cooldown_ref.val.timer = cooldown_ref.val.timer.reset()
    commands.entity(entity).insert_component(ActiveCooldown::{  })
    update_status_text(status_labels, "You ate " + ability_name.value)
  })
}

///|
fn animate_cooldowns(
  time : @app.Res[@time.Time[Unit]],
  commands : @app.Commands,
  cooldowns : @ecs.Query[@ecs.Mut[Cooldown], @ecs.All],
  active_cooldowns : @ecs.Query[@ecs.Comp[ActiveCooldown], @ecs.All],
  nodes : @ecs.Query[@ecs.Mut[@ui.Node], @ecs.All],
) -> Unit {
  try! cooldowns.view(fn(entity, cooldown) {
    let cooldown_ref = cooldown.get_ref()
    guard (try! active_cooldowns.get(entity)) is Some(_) else { return }

    cooldown_ref.val.timer = cooldown_ref.val.timer.tick(time.get().delta())
    if (try! nodes.get(cooldown_ref.val.overlay_entity)) is Some(overlay_node) {
      let overlay_node_ref = overlay_node.get_ref()
      if cooldown_ref.val.timer.just_finished() {
        commands.entity(entity).remove_component(ActiveCooldown::component())
        overlay_node_ref.val = overlay_node_ref.val.with_height(
          @ui.Val::Percent(0.0F),
        )
      } else {
        overlay_node_ref.val = overlay_node_ref.val.with_height(
          @ui.Val::Percent((1.0F - cooldown_ref.val.timer.fraction()) * 100.0F),
        )
      }
    }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param4(activate_ability)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param5(animate_cooldowns)).run_if(
      @app.any_with_component(ActiveCooldown::component()),
    ),
  )
  .run()
}
