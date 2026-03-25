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
struct Callback {
  system_id : @app.SystemId
}

///|
struct Triggered {}

///|
struct CallbackA {}

///|
struct CallbackB {}

///|
struct LastTriggeredLabel {}

///|
let callback_key : @ecs.ComponentKey[Callback] = @ecs.register_component(
  debug_name="examples.ecs.one_shot_systems.callback",
)

///|
let triggered_key : @ecs.ComponentKey[Triggered] = @ecs.register_component(
  debug_name="examples.ecs.one_shot_systems.triggered",
)

///|
let callback_a_key : @ecs.ComponentKey[CallbackA] = @ecs.register_component(
  debug_name="examples.ecs.one_shot_systems.callback_a",
)

///|
let callback_b_key : @ecs.ComponentKey[CallbackB] = @ecs.register_component(
  debug_name="examples.ecs.one_shot_systems.callback_b",
)

///|
let last_triggered_label_key : @ecs.ComponentKey[LastTriggeredLabel] = @ecs.register_component(
  debug_name="examples.ecs.one_shot_systems.last_triggered_label",
)

///|
pub impl @ecs.Component for Callback with component() {
  callback_key
}

///|
pub impl @ecs.Component for Triggered with component() {
  triggered_key
}

///|
pub impl @ecs.Component for CallbackA with component() {
  callback_a_key
}

///|
pub impl @ecs.Component for CallbackB with component() {
  callback_b_key
}

///|
pub impl @ecs.Component for LastTriggeredLabel with component() {
  last_triggered_label_key
}

///|
fn main {
  println("Press A or B to trigger a one-shot system.")

  let trigger_system_config : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param4(trigger_system),
  )
  let evaluate_callbacks_config : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(evaluate_callbacks),
  )
  let update_chain : @app.SystemConfig[@ecs.World] = (
      trigger_system_config, evaluate_callbacks_config,
    )
    |> @app.chain()

  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@mgstudio.default_plugins())
    .add_systems(@app.Startup, @app.system(@app.system_param2(setup_ui)))
    .add_systems(
      @app.Startup,
      @app.system(@app.system_param(setup_with_commands)),
    )
    .add_systems(@app.Startup, @app.system(setup_with_world))
    .add_systems(@app.Update, update_chain)
  app.run()
}

///|
fn setup_ui(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")

  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  ignore(
    commands.spawn(
      (
        @text.Text::new(
          "Press A or B to trigger a one-shot system.\nThe label below updates when a registered callback runs.",
        ),
        @ui.Node::{
          ..@ui.Node::default(),
          position_type: @ui.PositionType::Absolute,
          left: @ui.Val::Px(16.0F),
          top: @ui.Val::Px(16.0F),
        },
        @text.TextFont::default().with_font(font).with_font_size(18.0F),
        @text.TextColor::new(@sprite.Color::white()),
        @text.TextLayout::new_with_justify(@text.Justify::Left),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @text.Text::new("Last Triggered: -"),
        @ui.Node::{
          ..@ui.Node::default(),
          position_type: @ui.PositionType::Absolute,
          left: @ui.Val::Px(16.0F),
          top: @ui.Val::Px(96.0F),
        },
        @text.TextFont::default().with_font(font).with_font_size(22.0F),
        @text.TextColor::new(@sprite.Color::srgb(1.0F, 0.55F, 0.2F)),
        @text.TextLayout::new_with_justify(@text.Justify::Left),
        LastTriggeredLabel::{  },
      ),
    ),
  )
}

///|
fn setup_with_commands(commands : @app.Commands) -> Unit {
  let system_id = commands.register_system_param(system_a)
  ignore(commands.spawn((Callback::{ system_id, }, CallbackA::{  })))
}

///|
fn setup_with_world(world : @ecs.World) -> Unit {
  try! @app.run_system_once_param(world, system_b)
  let system_id = @app.register_system_param(world, system_b)
  let entity = world.spawn()
  try! (world
  .entity_mut(entity)
  .insert((Callback::{ system_id, }, CallbackB::{  }))
  |> ignore)
}

///|
fn trigger_system(
  commands : @app.Commands,
  callback_a : @app.Single[@core.Entity, @ecs.With[CallbackA]],
  callback_b : @app.Single[@core.Entity, @ecs.With[CallbackB]],
  keyboard_input : @input.ButtonInput[@window.KeyCode],
) -> Unit {
  if keyboard_input.just_pressed(@window.KeyCode::KeyA) {
    commands.entity(callback_a.get()).insert_component(Triggered::{  })
  }
  if keyboard_input.just_pressed(@window.KeyCode::KeyB) {
    commands.entity(callback_b.get()).insert_component(Triggered::{  })
  }
}

///|
fn evaluate_callbacks(
  callbacks : @ecs.Query[
    (@core.Entity, @ecs.Comp[Callback]),
    @ecs.With[Triggered],
  ],
  commands : @app.Commands,
) -> Unit {
  try! callbacks.view(fn(_query_entity, data) {
    let (entity, callback) = data
    commands.run_system(callback.value().system_id)
    commands.entity(entity).remove_component(triggered_key)
  })
}

///|
fn system_a(
  label : @app.Single[@ecs.Mut[@text.Text], @ecs.With[LastTriggeredLabel]],
) -> Unit {
  label.get().set(@text.Text::new("Last Triggered: A"))
  println("A: registered callback triggered")
}

///|
fn system_b(
  label : @app.Single[@ecs.Mut[@text.Text], @ecs.With[LastTriggeredLabel]],
) -> Unit {
  label.get().set(@text.Text::new("Last Triggered: B"))
  println("B: world-registered callback triggered")
}
