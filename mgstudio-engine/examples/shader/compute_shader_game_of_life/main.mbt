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
const GRID_W : Int = 12

///|
const GRID_H : Int = 12

///|
const SHADER_PATH : String = "shaders/custom/game_of_life_3d.wgsl"

///|
struct Cell {
  index : Int
}

///|
let cell_key : @ecs.ComponentKey[Cell] = @ecs.register_component(
  debug_name="examples.shader.compute_shader_game_of_life.Cell",
)

///|
pub impl @ecs.Component for Cell with component() {
  cell_key
}

///|
struct LifeState {
  mut generation : Int
  cells : Array[Bool]
  scratch : Array[Bool]
}

///|
let life_state_key : @ecs.ResourceKey[LifeState] = @ecs.register_resource(
  debug_name="examples.shader.compute_shader_game_of_life.LifeState",
)

///|
pub impl @app.Resource for LifeState with resource() {
  life_state_key
}

///|
fn life_index(x : Int, y : Int) -> Int {
  y * GRID_W + x
}

///|
fn life_alive(state : LifeState, x : Int, y : Int) -> Bool {
  let wrapped_x = (x + GRID_W) % GRID_W
  let wrapped_y = (y + GRID_H) % GRID_H
  state.cells[life_index(wrapped_x, wrapped_y)]
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let cells : Array[Bool] = []
  let scratch : Array[Bool] = []
  for y in 0..<GRID_H {
    for x in 0..<GRID_W {
      cells.push((x + y) % 3 == 0)
      scratch.push(false)
    }
  }
  commands.insert_resource(LifeState::{ generation: 0, cells, scratch })

  let cell_mesh = meshes.get_ref().val
    |> @pbr.add_mesh(@math.Cuboid::new(0.26F, 0.26F, 0.26F))
  for y in 0..<GRID_H {
    for x in 0..<GRID_W {
      let ix = life_index(x, y)
      let material = materials.get_ref().val.add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::srgb(0.06F, 0.08F, 0.14F),
        ),
      )
      let px = (Float::from_int(x) - Float::from_int(GRID_W - 1) * 0.5F) * 0.3F
      let py = (Float::from_int(y) - Float::from_int(GRID_H - 1) * 0.5F) * 0.3F
      commands.spawn(
        (
          @pbr.Mesh3d::new(cell_mesh),
          @pbr.MeshMaterial3d::new(material).with_extension_shader_path(
            Some(SHADER_PATH),
          ),
          Cell::{ index: ix },
          @transform.Transform::from_xyz(px, py, 0.0F),
        ),
      )
      |> ignore
    }
  }

  commands.spawn(
    (
      @pbr.PointLight::new(@sprite.Color::white(), 1_000_000.0F, 30.0F, false),
      @transform.Transform::from_xyz(0.0F, 0.0F, 8.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.Camera3d::default(),
      @transform.Transform::from_xyz(0.0F, 0.0F, 12.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
}

///|
fn step_life(
  time : @app.Res[@time.Time[Unit]],
  life_state : @app.ResMut[LifeState],
) -> Unit {
  let step = (time.get().elapsed_seconds() * 8.0F).to_int()
  if step == life_state.get_ref().val.generation {
    return
  }
  let state_ref = life_state.get_ref()
  for y in 0..<GRID_H {
    for x in 0..<GRID_W {
      let mut neighbors = 0
      for oy in -1..<2 {
        for ox in -1..<2 {
          if ox == 0 && oy == 0 {
            continue
          }
          if life_alive(state_ref.val, x + ox, y + oy) {
            neighbors = neighbors + 1
          }
        }
      }
      let i = life_index(x, y)
      let alive = state_ref.val.cells[i]
      state_ref.val.scratch[i] = if alive {
        neighbors == 2 || neighbors == 3
      } else {
        neighbors == 3
      }
    }
  }
  for i in 0..<state_ref.val.cells.length() {
    state_ref.val.cells[i] = state_ref.val.scratch[i]
  }
  state_ref.val.generation = step
}

///|
fn apply_life_visuals(
  cells : @ecs.Query[
    (@ecs.Comp[Cell], @ecs.Comp[@pbr.MeshMaterial3d]),
    @ecs.All,
  ],
  life_state : @app.Res[LifeState],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  try! cells.view(fn(_entity, data) {
    let (cell, mesh_material) = data
    let alive = life_state.get().cells[cell.value().index]
    let handle = mesh_material.value().material
    guard materials.get_ref().val.get(handle) is Some(material) else { return }
    let next = if alive {
      material
      .with_base_color(@sprite.Color::srgb(0.18F, 0.95F, 0.45F))
      .with_emissive(@sprite.Color::srgb(0.08F, 0.2F, 0.08F))
    } else {
      material
      .with_base_color(@sprite.Color::srgb(0.06F, 0.08F, 0.14F))
      .with_emissive(@sprite.Color::black())
    }
    materials.get_ref().val.set(handle, next) |> ignore
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(step_life)))
  .add_systems(@app.Update, @app.system(@app.system_param3(apply_life_visuals)))
  .run()
}
