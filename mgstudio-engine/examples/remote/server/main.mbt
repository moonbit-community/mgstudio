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
const GRID_SIDE : Int = 11

///|
struct Spin {
  speed : Float
}

///|
let spin_key : @ecs.ComponentKey[Spin] = @ecs.register_component(
  debug_name="examples.remote.server.Spin",
)

///|
pub impl @ecs.Component for Spin with component() {
  spin_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn setup(commands : @app.Commands) -> Unit {
  commands.queue(fn(world : @ecs.World) {
    world.insert_resource(
      @pbr.ecs_key_global_ambient_light,
      @pbr.GlobalAmbientLight::new(@sprite.Color::white(), 1200.0F),
    )
  })
  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @transform.Transform::from_xyz(16.0F, 18.0F, 20.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.PointLight::default()
        .with_shadow_maps_enabled(true)
        .with_intensity(1_000_000.0F)
        .with_range(80.0F),
        @transform.Transform::from_xyz(6.0F, 18.0F, 10.0F),
      ),
    ),
  )
  let floor_mesh = @pbr.add_mesh(
    @pbr.mesh_assets_mut_or_abort().val,
    @math.Cuboid::new(40.0F, 0.08F, 40.0F),
  )
  let floor_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.2F, 0.22F, 0.24F)),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(floor_mesh),
        @pbr.MeshMaterial3d::new(floor_material),
        @transform.Transform::from_xyz(0.0F, -0.04F, 0.0F),
      ),
    ),
  )
  let cube_mesh = @pbr.add_mesh(
    @pbr.mesh_assets_mut_or_abort().val,
    @math.Cuboid::new(0.9F, 0.9F, 0.9F),
  )
  let cube_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.55F, 0.68F, 0.95F)),
  )
  for z in 0..<GRID_SIDE {
    for x in 0..<GRID_SIDE {
      let tx = (float_from_int(x) - float_from_int(GRID_SIDE) * 0.5F) * 1.35F
      let tz = (float_from_int(z) - float_from_int(GRID_SIDE) * 0.5F) * 1.35F
      let speed = 0.35F + float_from_int((x + z) % 6) * 0.14F
      ignore(
        commands.spawn(
          (
            @pbr.Mesh3d::new(cube_mesh),
            @pbr.MeshMaterial3d::new(cube_material),
            @transform.Transform::from_xyz(tx, 0.6F, tz),
            Spin::{ speed, },
          ),
        ),
      )
    }
  }
}

///|
fn rotate_cubes(
  time : @app.Res[@time.Time[Unit]],
  cubes : @ecs.Query[
    (@ecs.Comp[Spin], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! cubes.for_each(fn(_entity, data) {
    let (spin, transform) = data
    let transform_ref = transform.get_ref()
    transform_ref.val.rotation = @math.Quat::from_rotation_y(
      t * spin.value().speed,
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.default_plugins())
  .add_plugins([@remote.remote_plugin(@remote.RemotePlugin::default())])
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(rotate_cubes)))
  .run()
}
