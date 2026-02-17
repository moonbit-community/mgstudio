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
/// Port of `bevy/examples/3d/decal.rs`.
///
/// Baseline parity: Bevy's `ForwardDecal`, depth-prepass requirements, and
/// `Msaa/Fxaa` toggles are not exposed in current mgstudio runtime APIs. This
/// port preserves the same scene topology and random obstacle layout, and maps
/// the decal volume to a textured translucent proxy mesh.

///|
const PI : Float = 3.141592653589793F

///|
const GRID_COUNT : Int = 10

///|
const CUBE_SIZE : Float = 0.6F

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn obstacle_rotation(i : Int, j : Int) -> @math.Quat {
  let seed = float_from_int(i * 97 + j * 131 + 198783)
  let axis_raw = @math.Vec3::new(
    @math.sin(seed * 0.017F + 0.11F),
    @math.cos(seed * 0.023F + 0.73F),
    @math.sin(seed * 0.029F + 1.79F),
  )
  let axis = if axis_raw.length_squared() < 0.000001F {
    @math.Vec3::new(0.0F, 1.0F, 0.0F)
  } else {
    axis_raw.normalize_or_zero()
  }
  let angle = @math.sin(seed * 0.037F + 0.5F) * PI
  @math.Quat::from_axis_angle(axis, angle)
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let asset_server = @asset.AssetServer::new()

  let decal_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(1.0F, 1.0F, 1.0F, 0.85F),
    )
    .with_base_color_texture(
      Some(asset_server.load("textures/uv_checker_bw.png")),
    )
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_unlit(true),
  )
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(4.0F, 4.0F, 4.0F),
    @render3d.MeshMaterial3d::new(decal_material),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(2.0F, 9.5F, 2.5F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore

  let white_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::white()),
  )

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(10.0F, 10.0F),
    @render3d.MeshMaterial3d::new(white_material),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let center_offset = (float_from_int(GRID_COUNT) - 1.0F) * 0.5F
  for i in 0..<GRID_COUNT {
    for j in 0..<GRID_COUNT {
      let x = float_from_int(i) - center_offset
      let z = float_from_int(j) - center_offset
      let transform = @math.Transform::from_xyz(x, -0.2F, z).with_rotation(
        obstacle_rotation(i, j),
      )
      @render3d.MeshMaterial3dBundle::new(
        @render3d.Mesh3d::from_cuboid(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE),
        @render3d.MeshMaterial3d::new(white_material),
        transform,
      ).spawn(world)
      |> ignore
    }
  }

  let light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    light,
    @render3d.PointLight::new(@render2d.Color::white(), 300_000.0F, 30.0F, true),
    tick,
  )
  world
  .get_transform_store()
  .insert(light, @math.Transform::from_xyz(4.0F, 8.0F, 4.0F), tick)
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .run()
}
