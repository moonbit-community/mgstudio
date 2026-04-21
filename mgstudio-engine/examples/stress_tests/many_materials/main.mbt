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
const GRID_SIZE : Int = 22

///|
struct MaterialSlot {
  index : Int
}

///|
let material_slot_key : @ecs.ComponentKey[MaterialSlot] = @ecs.register_component(
  debug_name="examples.stress_tests.many_materials.MaterialSlot",
)

///|
pub impl @ecs.Component for MaterialSlot with component() {
  material_slot_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@pbr.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let grid = GRID_SIZE
  let gridf = float_from_int(grid)

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(
          gridf * 1.35F,
          gridf + 1.0F,
          gridf * 1.35F,
        ).looking_at(
          @math.Vec3::new(0.0F, -gridf * 0.6F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(@sprite.Color::white(), 3000.0F, true),
        @transform.Transform::from_xyz(-10.0F, 20.0F, -10.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  let cube_mesh = meshes
    .peek()
    .add(
      @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(0.9F, 0.9F, 0.9F)),
    )
  for x in 0..<grid {
    for z in 0..<grid {
      let mat_handle = materials
        .peek()
        .add(@pbr.StandardMaterial::from_color(@sprite.Color::white()))
      let idx = x * grid + z
      ignore(
        commands.spawn(
          (
            @pbr.Mesh3d::new(cube_mesh),
            @pbr.MeshMaterial3d::new(mat_handle),
            @transform.Transform::from_xyz(
              float_from_int(x),
              0.0F,
              float_from_int(z),
            ),
            MaterialSlot::{ index: idx },
          ),
        ),
      )
    }
  }
}

///|
fn animate_materials(
  time : @app.Res[@time.Time[Unit]],
  slots : @ecs.Query[
    (@ecs.Comp[MaterialSlot], @ecs.Comp[@pbr.MeshMaterial3d]),
    @ecs.All,
  ],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let elapsed = time.get().elapsed_secs()
  try! slots.for_each(fn(_entity, data) {
    let (slot, mesh_material) = data
    let handle = mesh_material.value().material
    guard materials.peek().get(handle) is Some(material) else { return }
    let idxf = float_from_int(slot.value().index)
    let color = @sprite.Color::hsl(
      (idxf * 2.345F + elapsed) * 100.0F % 360.0F,
      1.0F,
      0.5F,
    )
    ignore(materials.peek().set(handle, material.with_base_color(color)))
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_plugins(@diagnostic.StressDiagnosticsPlugin::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param3(animate_materials)))
  .run()
}
