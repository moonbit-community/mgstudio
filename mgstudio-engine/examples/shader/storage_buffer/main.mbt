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
const SHADER_PATH : String = "shaders/custom/storage_buffer_3d.wgsl"

///|
const INSTANCE_COUNT : Int = 128

///|
struct InstanceSlot {
  index : Int
}

///|
let instance_slot_key : @ecs.ComponentKey[InstanceSlot] = @ecs.register_component(
  debug_name="examples.shader.storage_buffer.InstanceSlot",
)

///|
pub impl @ecs.Component for InstanceSlot with component() {
  instance_slot_key
}

///|
struct StorageValues {
  values : Array[Float]
}

///|
let storage_values_key : @ecs.ResourceKey[StorageValues] = @ecs.register_resource(
  debug_name="examples.shader.storage_buffer.StorageValues",
)

///|
pub impl @app.Resource for StorageValues with resource() {
  storage_values_key
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let values : Array[Float] = []
  for i in 0..<INSTANCE_COUNT {
    values.push(Float::from_int(i) * 0.05F)
  }
  commands.insert_resource(StorageValues::{ values, })

  let mesh = meshes.get_ref().val
    |> @pbr.add_mesh(@math.Cuboid::new(0.15F, 0.15F, 0.15F))
  let material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.9F, 0.94F, 1.0F)),
  )
  for i in 0..<INSTANCE_COUNT {
    let x = Float::from_int(i % 16) - 7.5F
    let y = Float::from_int(i / 16) - 3.5F
    commands.spawn(
      (
        InstanceSlot::{ index: i },
        @pbr.Mesh3d::new(mesh),
        @pbr.MeshMaterial3d::new(material).with_extension_shader_path(
          Some(SHADER_PATH),
        ),
        @transform.Transform::from_xyz(x * 0.3F, y * 0.3F, 0.0F),
      ),
    )
    |> ignore
  }
  commands.spawn(
    (
      @pbr.PointLight::new(@sprite.Color::white(), 1_000_000.0F, 25.0F, false),
      @transform.Transform::from_xyz(0.0F, 2.0F, 8.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.Camera3d::default(),
      @transform.Transform::from_xyz(0.0F, 0.0F, 8.5F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
}

///|
fn update_storage_values(
  time : @app.Res[@time.Time[Unit]],
  storage_values : @app.ResMut[StorageValues],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  let values = storage_values.get_ref().val.values
  for i in 0..<values.length() {
    values[i] = @math.sin(elapsed * 1.3F + Float::from_int(i) * 0.08F)
  }
}

///|
fn apply_storage_values(
  storage_values : @app.Res[StorageValues],
  query : @ecs.Query[
    (@ecs.Comp[InstanceSlot], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  let values = storage_values.get().values
  try! query.view(fn(_entity, data) {
    let (slot, transform) = data
    let value = values[slot.value().index]
    transform.get_ref().val.translation.z = value * 0.7F
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(update_storage_values)),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(apply_storage_values)),
  )
  .run()
}
