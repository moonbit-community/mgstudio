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
/// Baseline parity: this example now attaches
/// `ForwardDecal`/`ForwardDecalMaterialExt` components directly on the decal
/// entity. Current backend rendering still does not project forward decals, so
/// a textured proxy volume is kept for visible behavior parity.

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
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let asset_server = @asset.AssetServer::new()

  let decal_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white()).with_base_color_texture(
      Some(asset_server.load("textures/uv_checker_bw.png")),
    ),
  )
  let decal = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(decal_material),
    @transform.Transform::identity().with_scale(@math.Vec3::splat(4.0F)),
  ).spawn(world)
  world
  .component(@pbr.ecs_key_forward_decal)
  .insert(decal, @pbr.ForwardDecal::default(), tick)
  world
  .component(@pbr.ecs_key_forward_decal_material_ext)
  .insert(decal, @pbr.ForwardDecalMaterialExt::new(1.0F), tick)

  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(2.0F, 9.5F, 2.5F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world
  .component(@pbr.ecs_key_free_camera)
  .insert(camera, @pbr.FreeCamera::default(), tick)
  world
  .component(@pbr.ecs_key_depth_prepass)
  .insert(camera, @pbr.DepthPrepass::default(), tick)
  world.component(@pbr.ecs_key_msaa).insert(camera, @pbr.Msaa::Off, tick)
  world
  .component(@post_process.ecs_key_fxaa)
  .insert(camera, @post_process.Fxaa::default(), tick)

  let white_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white()),
  )

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(10.0F, 10.0F)),
      ),
    ),
    @pbr.MeshMaterial3d::new(white_material),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let center_offset = (float_from_int(GRID_COUNT) - 1.0F) * 0.5F
  for i in 0..<GRID_COUNT {
    for j in 0..<GRID_COUNT {
      let x = float_from_int(i) - center_offset
      let z = float_from_int(j) - center_offset
      let transform = @transform.Transform::from_xyz(x, -0.2F, z).with_rotation(
        obstacle_rotation(i, j),
      )
      @pbr.MeshMaterial3dBundle::new(
        @pbr.Mesh3d::new(
          @pbr.mesh_assets_mut_or_abort().val.add(
            @pbr.Mesh::from_3d_geometry(
              @pbr.mesh3d_geometry_cuboid(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE),
            ),
          ),
        ),
        @pbr.MeshMaterial3d::new(white_material),
        transform,
      ).spawn(world)
      |> ignore
    }
  }

  let light = world.spawn_empty()
  world
  .component(@pbr.ecs_key_point_light)
  .insert(
    light,
    @pbr.PointLight::default().with_shadow_maps_enabled(true),
    tick,
  )
  world
  .component(@transform.ecs_key_transform)
  .insert(light, @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F), tick)
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .run()
}
