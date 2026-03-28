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
const CONTRIBUTOR_COUNT : Int = 48

///|
struct ContributorOrbit {
  base_angle : Float
  speed : Float
  radius : Float
}

///|
let contributor_orbit_key : @ecs.ComponentKey[ContributorOrbit] = @ecs.register_component(
  debug_name="examples.games.contributors.ContributorOrbit",
)

///|
pub impl @ecs.Component for ContributorOrbit with component() {
  contributor_orbit_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::sized(@math.Vec2::new(180.0F, 180.0F)).with_color(
          @sprite.Color::srgb(0.2F, 0.28F, 0.95F),
        ),
        @transform.Transform::from_xyz(0.0F, 0.0F, -0.5F),
      ),
    ),
  )
  for i in 0..<CONTRIBUTOR_COUNT {
    let angle = float_from_int(i) *
      6.283185307179586F /
      float_from_int(CONTRIBUTOR_COUNT)
    let radius = 130.0F + float_from_int(i % 9) * 24.0F
    let speed = 0.2F + float_from_int(i % 7) * 0.07F
    ignore(
      commands.spawn(
        (
          @sprite.Sprite::sized(@math.Vec2::new(26.0F, 26.0F)).with_color(
            @sprite.Color::hsl(float_from_int(i * 29 % 360), 0.82F, 0.58F),
          ),
          @transform.Transform::from_xyz(
            @math.cos(angle) * radius,
            @math.sin(angle) * radius,
            0.0F,
          ),
          ContributorOrbit::{ base_angle: angle, speed, radius },
        ),
      ),
    )
  }
}

///|
fn animate_contributors(
  time : @app.Res[@time.Time[Unit]],
  contributors : @ecs.Query[
    (@ecs.Comp[ContributorOrbit], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! contributors.for_each(fn(_entity, data) {
    let (orbit, transform) = data
    let angle = orbit.value().base_angle + t * orbit.value().speed
    let wobble = 1.0F + 0.07F * @math.sin(t * 2.0F + orbit.value().base_angle)
    let transform_ref = transform.get_ref()
    transform_ref.val.translation = @math.Vec3::new(
      @math.cos(angle) * orbit.value().radius * wobble,
      @math.sin(angle) * orbit.value().radius * wobble,
      0.0F,
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(animate_contributors)),
  )
  .run()
}
