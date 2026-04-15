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
const GRID_SIDE : Int = 34

///|
struct Spin {
  speed : Float
}

///|
let spin_key : @ecs.ComponentKey[Spin] = @ecs.register_component(
  debug_name="examples.large_scenes.bistro.main.Spin",
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
      @pbr.GlobalAmbientLight::new(@sprite.Color::white(), 1000.0F),
    )
  })
  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @transform.Transform::from_xyz(0.0F, 36.0F, 42.0F).looking_at(
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
        .with_intensity(2_200_000.0F)
        .with_range(200.0F),
        @transform.Transform::from_xyz(0.0F, 38.0F, 0.0F),
        Spin::{ speed: 0.35F },
      ),
    ),
  )

  let floor_mesh = @pbr.add_mesh(
    @pbr.mesh_assets_mut_or_abort().val,
    @math.Cuboid::new(160.0F, 0.1F, 160.0F),
  )
  let floor_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.17F, 0.19F, 0.21F)),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(floor_mesh),
        @pbr.MeshMaterial3d::new(floor_material),
        @transform.Transform::from_xyz(0.0F, -0.05F, 0.0F),
      ),
    ),
  )

  let cube_mesh = @pbr.add_mesh(
    @pbr.mesh_assets_mut_or_abort().val,
    @math.Cuboid::new(0.85F, 0.85F, 0.85F),
  )
  for z in 0..<GRID_SIDE {
    for x in 0..<GRID_SIDE {
      let hue = (x * 17 + z * 29) % 360
      let material = @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::hsl(float_from_int(hue), 0.72F, 0.58F),
        ),
      )
      ignore(
        commands.spawn(
          (
            @pbr.Mesh3d::new(cube_mesh),
            @pbr.MeshMaterial3d::new(material),
            @transform.Transform::from_xyz(
              (float_from_int(x) - float_from_int(GRID_SIDE) * 0.5F) * 1.4F,
              0.55F,
              (float_from_int(z) - float_from_int(GRID_SIDE) * 0.5F) * 1.4F,
            ),
          ),
        ),
      )
    }
  }
}

///|
fn spin_light(
  time : @app.Res[@time.Time[Unit]],
  lights : @ecs.Query[
    (@ecs.Comp[Spin], @ecs.Mut[@transform.Transform]),
    @ecs.With[@pbr.PointLight],
  ],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! lights.for_each(fn(_entity, data) {
    let (spin, transform) = data
    let transform_ref = transform.get_ref()
    let angle = t * spin.value().speed
    transform_ref.val.translation = @math.Vec3::new(
      @math.cos(angle) * 28.0F,
      36.0F,
      @math.sin(angle) * 28.0F,
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(spin_light)))
  .run()
}
