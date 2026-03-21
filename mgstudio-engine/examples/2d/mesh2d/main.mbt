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
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(mesh2d_setup))
  .run()
}

///|
fn mesh2d_setup(world : @ecs.World) -> Unit {
  let mesh = @sprite.Mesh2d::new(
    @sprite.mesh_assets_mut_or_abort().val.add(
      @sprite.mesh2d_geometry_rectangle(@sprite.Rectangle::default()).to_mesh(),
    ),
  )
  let material = @sprite.MeshMaterial2d::new(
    @sprite.color_material_assets_mut_or_abort().val.add(
      @sprite.ColorMaterialAsset::from_color(
        @sprite.Color::new(0.5019608F, 0.0F, 0.5019608F, 1.0F),
      ),
    ),
  )
  let transform = @transform.Transform::from_xy_rotation_scale(
    @math.Vec2::new(0.0F, 0.0F),
    0.0F,
    @math.Vec2::new(128.0F, 128.0F),
  )
  @sprite.Mesh2dBundle::new_with_mesh_material(mesh, material, transform).spawn(
    world,
  )
  |> ignore
  let camera = @sprite.Camera::default()
  @sprite.Camera2dBundle::new(camera, @transform.Transform::identity()).spawn(
    world,
  )
  |> ignore
}
