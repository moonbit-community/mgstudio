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
const SHADER_PATH : String = "shaders/custom_material.wesl"

///|
const UTILITY_SHADER_PATH : String = "shaders/util.wesl"

///|
struct Spin {}

///|
let spin_key : @ecs.ComponentKey[Spin] = @ecs.register_component(
  debug_name="examples.shader.shader_material_wesl.Spin",
)

///|
pub impl @ecs.Component for Spin with fn component() {
  spin_key
}

///|
struct UtilityShaderHandle {
  handle : @asset.Handle[@shader.Shader]
}

///|
let utility_shader_handle_key : @ecs.ResourceKey[UtilityShaderHandle] = @ecs.register_resource(
  debug_name="examples.shader.shader_material_wesl.UtilityShaderHandle",
)

///|
pub impl @app.Resource for UtilityShaderHandle with fn resource() {
  utility_shader_handle_key
}

///|
struct UtilityShaderPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn UtilityShaderPlugin::UtilityShaderPlugin() -> UtilityShaderPlugin {
  UtilityShaderPlugin::{  }
}

///|
pub impl @app.Plugin for UtilityShaderPlugin with fn build(_self, app) {
  let world = app.world()
  let asset_server = match world.get_resource(@asset.AssetServer::resource()) {
    Some(asset_server) => asset_server
    None =>
      abort("expected AssetServer resource in shader_material_wesl example")
  }
  let utility_shader = UtilityShaderHandle::{
    handle: asset_server.load(UTILITY_SHADER_PATH),
  }
  ignore(utility_shader.handle.id())
  app.insert_resource(utility_shader)
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let mesh = meshes.modify(fn(meshes) {
    meshes |> @pbr.add_mesh(@math.Cuboid::new(1.5F, 1.5F, 1.5F))
  })
  let material = materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@color.Color::white()).with_base_color_texture(
        Some(asset_server.get().load_image("branding/icon.png")),
      ),
    )
  commands.spawn(
    (
      Spin::{  },
      @mesh.Mesh3d::new(mesh),
      @pbr.MeshMaterial3d::new(material).with_extension_fragment_shader_path(
        Some(SHADER_PATH),
      ),
      @transform.Transform::from_xyz(0.0F, 1.0F, 0.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @mesh.Mesh3d::new(
        meshes.peek()
        |> @pbr.add_mesh(
          @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
            @math.Vec2::new(8.0F, 8.0F),
          ).build(),
        ),
      ),
      @pbr.MeshMaterial3dTyped::new(
        materials
        .peek()
        .add(
          @pbr.StandardMaterial::from_color(
            @color.Color::srgb(0.1F, 0.11F, 0.15F),
          ),
        ),
      ),
      @transform.Transform::identity(),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.DirectionalLight::DirectionalLight(),
      @transform.Transform::from_xyz(-2.0F, 6.0F, 4.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @camera.Camera3d::Camera3d(),
      @transform.Transform::from_xyz(0.0F, 2.4F, 7.5F).looking_at(
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
}

///|
fn spin_system(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[@ecs.Write[@transform.Transform], @ecs.With[Spin]],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! query.view(fn(_entity, transform) {
    transform.modify(fn(value) {
      value.rotate_y(delta * 0.9F)
      value.rotate_z(delta * 0.4F)
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(UtilityShaderPlugin::UtilityShaderPlugin())
  .add_systems_param4(Startup, setup)
  .add_systems_param2(Update, spin_system)
  .run()
}
