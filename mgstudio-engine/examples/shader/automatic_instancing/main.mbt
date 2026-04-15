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
const SHADER_PATH : String = "shaders/custom/automatic_instancing_3d.wgsl"

///|
const GRID_SIZE : Int = 32

///|
struct InstanceTag {
  index : Int
}

///|
let instance_tag_key : @ecs.ComponentKey[InstanceTag] = @ecs.register_component(
  debug_name="examples.shader.automatic_instancing.InstanceTag",
)

///|
pub impl @ecs.Component for InstanceTag with component() {
  instance_tag_key
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let mesh_handle = meshes.get_ref().val
    |> @pbr.add_mesh(@math.Cuboid::new(0.02F, 0.02F, 0.02F))
  let material_handle = materials.get_ref().val.add(
    @pbr.StandardMaterial::default()
    .with_base_color(@sprite.Color::white())
    .with_base_color_texture(
      Some(asset_server.get().load_image("branding/icon.png")),
    )
    .with_perceptual_roughness(0.9F),
  )
  let half = Float::from_int(GRID_SIZE) * 0.5F

  for row in 0..<GRID_SIZE {
    for column in 0..<GRID_SIZE {
      let index = row * GRID_SIZE + column
      let x = (Float::from_int(column) - half) / 8.0F
      let y = (Float::from_int(row) - half) / -8.0F
      commands.spawn(
        (
          @pbr.Mesh3d::new(mesh_handle),
          @pbr.MeshMaterial3d::new(material_handle).with_extension_shader_path(
            Some(SHADER_PATH),
          ),
          InstanceTag::{ index, },
          @transform.Transform::from_xyz(x, y, 0.0F),
        ),
      )
      |> ignore
    }
  }

  commands.spawn(
    (
      @pbr.Camera3d::default(),
      @transform.Transform::from_xyz(0.0F, 0.0F, 5.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
}

///|
fn update(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    (@ecs.Mut[@transform.Transform], @ecs.Comp[InstanceTag]),
    @ecs.All,
  ],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  try! query.view(fn(_entity, data) {
    let (transform, tag) = data
    let phase = Float::from_int(tag.value().index) * 0.01F
    transform.get_ref().val.translation.z = @math.sin(elapsed + phase)
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(update)))
  .run()
}
