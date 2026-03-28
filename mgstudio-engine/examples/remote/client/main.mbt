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
const GRID_HALF_X : Int = 14

///|
const GRID_HALF_Y : Int = 8

///|
const SPACING : Float = 54.0F

///|
struct Pulse {
  phase : Float
}

///|
let pulse_key : @ecs.ComponentKey[Pulse] = @ecs.register_component(
  debug_name="examples.remote.client.Pulse",
)

///|
pub impl @ecs.Component for Pulse with component() {
  pulse_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  for y in -GRID_HALF_Y..<GRID_HALF_Y {
    for x in -GRID_HALF_X..<GRID_HALF_X {
      let idx = (y + GRID_HALF_Y) * (GRID_HALF_X * 2) + (x + GRID_HALF_X)
      let phase = float_from_int(idx) * 0.11F
      ignore(
        commands.spawn(
          (
            @sprite.Sprite::sized(@math.Vec2::new(34.0F, 34.0F)).with_color(
              @sprite.Color::hsl(float_from_int(idx % 360), 0.76F, 0.55F),
            ),
            @transform.Transform::from_xyz(
              float_from_int(x) * SPACING,
              float_from_int(y) * SPACING,
              0.0F,
            ),
            Pulse::{ phase, },
          ),
        ),
      )
    }
  }
}

///|
fn animate_client_grid(
  time : @app.Res[@time.Time[Unit]],
  sprites : @ecs.Query[(@ecs.Comp[Pulse], @ecs.Mut[@sprite.Sprite]), @ecs.All],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! sprites.for_each(fn(_entity, data) {
    let (pulse, sprite) = data
    let amount = 0.5F + 0.5F * @math.sin(t * 2.2F + pulse.value().phase)
    let sprite_ref = sprite.get_ref()
    sprite_ref.val.color = @sprite.Color::srgb(
      0.2F + amount * 0.7F,
      0.35F + amount * 0.5F,
      0.55F + amount * 0.35F,
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.default_plugins())
  .add_plugins([@remote.remote_plugin(@remote.RemotePlugin::default())])
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(animate_client_grid)),
  )
  .run()
}
