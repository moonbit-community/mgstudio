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
struct ObserverTarget {
  mut step : Float
}

///|
let observer_target_key : @ecs.ComponentKey[ObserverTarget] = @ecs.register_component(
  debug_name="examples.ecs.error_handling.observer_target",
)

///|
pub impl @ecs.Component for ObserverTarget with component() {
  observer_target_key
}

///|
suberror ErrorHandlingExampleError {
  MissingUninitializedResource
}

///|
const OBSERVER_BOUND_X : Float = 300.0F

///|
fn main {
  println(
    "Move the cursor over the ship to trigger the fallible pointer observer.",
  )
  println(
    "Startup also queues one failing built-in command and one handled command.",
  )

  let mut app = @app.App::new(@ecs.World::new())
    .set_error_handler(@app.ErrorHandlers::warn)
    .add_plugins(@mgstudio.DefaultPlugins::default())
    .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
    .add_systems(@app.Startup, @app.system(@app.system_param(failing_commands)))
    .add_systems(
      @app.PostStartup,
      @app.fallible_system(failing_system).handle_error_with(
        capture_failing_system_error,
      ),
    )
  app = app.add_pointer_observer(fallible_observer)
  app.run()
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let ship = asset_server.get().load("textures/simplespace/ship_C.png")

  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  ignore(
    commands.spawn(
      (
        ObserverTarget::{ step: 18.0F },
        @sprite.Sprite::from_image(ship).with_color(
          @sprite.Color::srgb(0.25F, 0.55F, 0.95F),
        ),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F).with_scale(
          @math.Vec3::new(2.0F, 2.0F, 1.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @text.Text::new(
          "Raise-based error handling\n\nMove the cursor over the ship.\nWarnings come from the global handler.\nPostStartup uses a per-system handler.",
        ),
        @ui.Node::{
          ..@ui.Node::default(),
          position_type: @ui.PositionType::Absolute,
          left: @ui.Val::Px(12.0F),
          top: @ui.Val::Px(12.0F),
        },
        @text.TextFont::default().with_font(font).with_font_size(18.0F),
        @text.TextColor::new(@sprite.Color::white()),
        @text.TextLayout::new_with_justify(@text.Justify::Left),
      ),
    ),
  )
}

///|
fn fallible_observer(pointer : @app.OnPointer[@app.PointerMove]) -> Unit {
  guard pointer.target() is Some(entity) else { return }
  guard @app.current_world() is Some(world) else { return }
  let query : @ecs.QueryState[
    (@ecs.Mut[@transform.Transform], @ecs.Mut[ObserverTarget]),
    @ecs.All,
  ] = world.query_filtered(@ecs.All::new())
  let entity_data = query.get(world, entity) catch { _ => None }
  if entity_data is Some((transform_mut, target_mut)) {
    let transform_value = transform_mut.value()
    let current_step = target_mut.value().step
    let next_step = if transform_value.translation.x > OBSERVER_BOUND_X {
      -18.0F
    } else if transform_value.translation.x < 0.0F - OBSERVER_BOUND_X ||
      current_step == 0.0F {
      18.0F
    } else {
      current_step
    }
    target_mut.modify(fn(value) { value.step = next_step })
    transform_mut.modify(fn(value) {
      value.translation.x = value.translation.x + next_step
    })
  }
}

///|
fn failing_system(_world : @ecs.World) -> Unit raise {
  raise MissingUninitializedResource
}

///|
fn capture_failing_system_error(
  error : Error,
  context : @app.ErrorContext,
) -> Unit {
  println(
    "captured error via per-system handler from \{context.source()}: \{error.to_string()}",
  )
}

///|
fn failing_commands(commands : @app.Commands) -> Unit {
  commands
  .entity(@core.Entity::new(12345678, 1))
  .insert_component(@transform.Transform::default())

  commands.queue_handled(
    fn(_world : @ecs.World) raise { raise MissingUninitializedResource },
    fn(error, context) {
      println(
        "captured command-local error from \{context.source()}: \{error.to_string()}",
      )
    },
  )
}
