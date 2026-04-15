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
struct LoadingState {
  mut progress : Float
  mut done : Bool
}

///|
struct LoadingBar {}

///|
let loading_state_key : @ecs.ResourceKey[LoadingState] = @ecs.register_resource(
  debug_name="examples.games.loading_screen.LoadingState",
)

///|
let loading_bar_key : @ecs.ComponentKey[LoadingBar] = @ecs.register_component(
  debug_name="examples.games.loading_screen.LoadingBar",
)

///|
impl @app.Resource for LoadingState with resource() {
  loading_state_key
}

///|
pub impl @ecs.Component for LoadingBar with component() {
  loading_bar_key
}

///|
fn setup(commands : @app.Commands) -> Unit {
  commands.insert_resource(LoadingState::{ progress: 0.0F, done: false })
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::sized(@math.Vec2::new(520.0F, 70.0F)).with_color(
          @sprite.Color::srgb(0.2F, 0.2F, 0.24F),
        ),
        @transform.Transform::from_xyz(0.0F, 0.0F, -0.5F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::sized(@math.Vec2::new(500.0F, 48.0F)).with_color(
          @sprite.Color::srgb(0.25F, 0.75F, 0.36F),
        ),
        @transform.Transform::from_xyz(-250.0F, 0.0F, 0.0F).with_scale(
          @math.Vec3::new(0.0F, 1.0F, 1.0F),
        ),
        LoadingBar::{  },
      ),
    ),
  )
}

///|
fn simulate_loading(
  time : @app.Res[@time.Time[Unit]],
  state : @app.ResMut[LoadingState],
  bars : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[LoadingBar]],
  commands : @app.Commands,
) -> Unit {
  if state.get_ref().val.done {
    return
  }
  let next = state.get_ref().val.progress + time.get().delta_secs() * 0.35F
  state.get_ref().val.progress = if next > 1.0F { 1.0F } else { next }
  let progress = state.get_ref().val.progress
  try! bars.for_each(fn(_entity, bar_transform) {
    let transform_ref = bar_transform.get_ref()
    transform_ref.val.scale.x = progress
  })
  if progress >= 1.0F {
    state.get_ref().val.done = true
    ignore(
      commands.spawn(
        (
          @sprite.Sprite::sized(@math.Vec2::new(260.0F, 260.0F)).with_color(
            @sprite.Color::srgb(0.35F, 0.7F, 1.0F),
          ),
          @transform.Transform::from_xyz(0.0F, 0.0F, 0.4F),
        ),
      ),
    )
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param4(simulate_loading)))
  .run()
}
