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
struct StepState {
  mut ticks : Int
}

///|
struct StepSprite {}

///|
let step_state_key : @ecs.ResourceKey[StepState] = @ecs.register_resource(
  debug_name="examples.games.stepping.StepState",
)

///|
let step_sprite_key : @ecs.ComponentKey[StepSprite] = @ecs.register_component(
  debug_name="examples.games.stepping.StepSprite",
)

///|
impl @app.Resource for StepState with resource() {
  step_state_key
}

///|
pub impl @ecs.Component for StepSprite with component() {
  step_sprite_key
}

///|
fn setup(commands : @app.Commands) -> Unit {
  commands.insert_resource(StepState::{ ticks: 0 })
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::sized(@math.Vec2::new(44.0F, 44.0F)).with_color(
          @sprite.Color::srgb(0.95F, 0.92F, 0.28F),
        ),
        @transform.Transform::from_xyz(-520.0F, 0.0F, 0.0F),
        StepSprite::{  },
      ),
    ),
  )
}

///|
fn fixed_step(
  state : @app.ResMut[StepState],
  sprites : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[StepSprite]],
) -> Unit {
  state.get_ref().val.ticks += 1
  let ticks = state.get_ref().val.ticks
  let phase = Float::from_double(ticks.to_double()) * 0.08F
  try! sprites.for_each(fn(_entity, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.translation.x = -520.0F +
      Float::from_double((ticks % 220).to_double()) * 4.8F
    transform_ref.val.translation.y = @math.sin(phase) * 160.0F
  })
}

///|
fn color_feedback(
  state : @app.Res[StepState],
  sprites : @ecs.Query[@ecs.Mut[@sprite.Sprite], @ecs.With[StepSprite]],
) -> Unit {
  let ticks = state.get().ticks
  try! sprites.for_each(fn(_entity, sprite) {
    sprite.get_ref().val.color = if ticks % 2 == 0 {
      @sprite.Color::srgb(0.95F, 0.92F, 0.28F)
    } else {
      @sprite.Color::srgb(0.3F, 0.9F, 0.95F)
    }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.FixedUpdate, @app.system(@app.system_param2(fixed_step)))
  .add_systems(@app.Update, @app.system(@app.system_param2(color_feedback)))
  .run()
}
