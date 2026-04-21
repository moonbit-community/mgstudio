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
const ENTITY_COUNT : Int = 12000

///|
const VISIBLE_COUNT : Int = 1400

///|
const GRID_COLS : Int = 70

///|
const GRID_SPACING : Float = 8.0F

///|
struct CompA {
  mut value : Float
}

///|
struct CompB {
  mut value : Float
}

///|
struct CompC {
  value : Float
}

///|
struct CompD {
  mut value : Float
}

///|
struct CompE {
  mut value : Float
}

///|
struct CompF {
  mut value : Float
}

///|
let comp_a_key : @ecs.ComponentKey[CompA] = @ecs.register_component(
  debug_name="examples.stress_tests.many_components.CompA",
)

///|
let comp_b_key : @ecs.ComponentKey[CompB] = @ecs.register_component(
  debug_name="examples.stress_tests.many_components.CompB",
)

///|
let comp_c_key : @ecs.ComponentKey[CompC] = @ecs.register_component(
  debug_name="examples.stress_tests.many_components.CompC",
)

///|
let comp_d_key : @ecs.ComponentKey[CompD] = @ecs.register_component(
  debug_name="examples.stress_tests.many_components.CompD",
)

///|
let comp_e_key : @ecs.ComponentKey[CompE] = @ecs.register_component(
  debug_name="examples.stress_tests.many_components.CompE",
)

///|
let comp_f_key : @ecs.ComponentKey[CompF] = @ecs.register_component(
  debug_name="examples.stress_tests.many_components.CompF",
)

///|
pub impl @ecs.Component for CompA with component() {
  comp_a_key
}

///|
pub impl @ecs.Component for CompB with component() {
  comp_b_key
}

///|
pub impl @ecs.Component for CompC with component() {
  comp_c_key
}

///|
pub impl @ecs.Component for CompD with component() {
  comp_d_key
}

///|
pub impl @ecs.Component for CompE with component() {
  comp_e_key
}

///|
pub impl @ecs.Component for CompF with component() {
  comp_f_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  for i in 0..<ENTITY_COUNT {
    let a = CompA::{ value: float_from_int(i % 97) * 0.01F }
    let b = CompB::{ value: float_from_int(i % 89) * 0.01F }
    let c = CompC::{ value: float_from_int(i % 83) * 0.01F }
    let d = CompD::{ value: float_from_int(i % 79) * 0.01F }
    let e = CompE::{ value: float_from_int(i % 73) * 0.01F }
    let f = CompF::{ value: float_from_int(i % 71) * 0.01F }
    if i < VISIBLE_COUNT {
      let col = i % GRID_COLS
      let row = i / GRID_COLS
      ignore(
        commands.spawn(
          (
            a,
            b,
            c,
            d,
            e,
            f,
            @sprite.Sprite::sized(@math.Vec2::new(4.0F, 4.0F)).with_color(
              @sprite.Color::hsl(float_from_int(i % 360), 0.8F, 0.6F),
            ),
            @transform.Transform::from_xyz(
              (float_from_int(col) - float_from_int(GRID_COLS) * 0.5F) *
              GRID_SPACING,
              (
                float_from_int(row) -
                float_from_int(VISIBLE_COUNT / GRID_COLS) * 0.5F
              ) *
              GRID_SPACING,
              0.0F,
            ),
          ),
        ),
      )
    } else {
      ignore(commands.spawn((a, b, c, d, e, f)))
    }
  }
}

///|
fn update_component_group_1(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    (@ecs.Mut[CompA], @ecs.Mut[CompB], @ecs.Comp[CompC]),
    @ecs.All,
  ],
) -> Unit {
  let dt = time.get().delta_secs()
  try! query.for_each(fn(_entity, data) {
    let (a, b, c) = data
    let c_value = c.value().value
    a.modify(fn(value) { value.value += dt * (0.2F + c_value) })
    b.modify(fn(value) { value.value -= dt * (0.15F + c_value * 0.5F) })
  })
}

///|
fn update_component_group_2(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    (@ecs.Mut[CompD], @ecs.Mut[CompE], @ecs.Mut[CompF]),
    @ecs.All,
  ],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! query.for_each(fn(_entity, data) {
    let (d, e, f) = data
    d.modify(fn(value) { value.value = @math.sin(t + value.value) })
    e.modify(fn(value) { value.value = @math.cos(t * 0.5F + value.value) })
    f.modify(fn(value) { value.value = @math.sin(t * 0.25F + value.value) })
  })
}

///|
fn update_visible_sprites(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    (
      @ecs.Comp[CompA],
      @ecs.Comp[CompB],
      @ecs.Comp[CompD],
      @ecs.Mut[@transform.Transform],
    ),
    @ecs.With[@sprite.Sprite],
  ],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! query.for_each(fn(_entity, data) {
    let (a, b, d, transform) = data
    transform.modify(fn(value) {
      value.translation.x += @math.sin(t + a.value().value) * 0.02F
      value.translation.y += @math.cos(t + d.value().value + b.value().value) *
        0.02F
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_plugins(@diagnostic.StressDiagnosticsPlugin::default())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(update_component_group_1)),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(update_component_group_2)),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(update_visible_sprites)),
  )
  .run()
}
