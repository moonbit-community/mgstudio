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
const INITIAL_CUBES : Int = 1000

///|
const CUBES_PER_CLICK : Int = 300

///|
const GRAVITY : Float = -18.0F

///|
const BOUNDS : Float = 22.0F

///|
const FLOOR_Y : Float = 0.5F

///|
struct CubeVelocity {
  value : @math.Vec3
}

///|
let cube_velocity_key : @ecs.ComponentKey[CubeVelocity] = @ecs.register_component(
  debug_name="examples.stress_tests.bevymark_3d.CubeVelocity",
)

///|
pub impl @ecs.Component for CubeVelocity with component() {
  cube_velocity_key
}

///|
struct CubeAssets {
  mesh : @asset.Handle[@pbr.Mesh]
  material : @asset.Handle[@pbr.StandardMaterial]
}

///|
let cube_assets_key : @ecs.ResourceKey[CubeAssets] = @ecs.register_resource(
  debug_name="examples.stress_tests.bevymark_3d.CubeAssets",
)

///|
impl @app.Resource for CubeAssets with resource() {
  cube_assets_key
}

///|
struct CubeCounter {
  mut count : Int
  mut print_timer : Float
}

///|
let cube_counter_key : @ecs.ResourceKey[CubeCounter] = @ecs.register_resource(
  debug_name="examples.stress_tests.bevymark_3d.CubeCounter",
)

///|
impl @app.Resource for CubeCounter with resource() {
  cube_counter_key
}

///|
fn CubeCounter::default() -> CubeCounter {
  { count: 0, print_timer: 0.0F }
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn spawn_cubes(
  commands : @app.Commands,
  assets : CubeAssets,
  count : Int,
  base_index : Int,
) -> Int {
  let mut next_index = base_index
  for _ in 0..<count {
    let idx = next_index
    let idxf = float_from_int(idx)
    let x = @math.sin(idxf * 0.31F) * 0.8F * BOUNDS
    let y = 8.0F + float_from_int(idx % 22)
    let z = @math.cos(idxf * 0.19F) * 0.8F * BOUNDS
    let vx = @math.sin(idxf * 0.73F) * 5.5F
    let vy = 2.0F + float_from_int(idx % 7) * 0.9F
    let vz = @math.cos(idxf * 0.47F) * 5.5F
    ignore(
      commands.spawn(
        (
          @pbr.Mesh3d::new(assets.mesh),
          @pbr.MeshMaterial3d::new(assets.material),
          @transform.Transform::from_xyz(x, y, z),
          CubeVelocity::{ value: @math.Vec3::new(vx, vy, vz) },
        ),
      ),
    )
    next_index += 1
  }
  next_index
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@pbr.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  counter : @app.ResMut[CubeCounter],
) -> Unit {
  let floor_mesh = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(
      @pbr.mesh3d_geometry_cuboid(120.0F, 1.0F, 120.0F),
    ),
  )
  let floor_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.16F, 0.19F, 0.24F)),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(floor_mesh),
        @pbr.MeshMaterial3d::new(floor_material),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
      ),
    ),
  )

  let cube_mesh = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(0.9F, 0.9F, 0.9F)),
  )
  let cube_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.78F, 0.86F, 0.95F)),
  )
  let cube_assets = CubeAssets::{ mesh: cube_mesh, material: cube_material }
  commands.insert_resource(cube_assets)

  ignore(
    commands.spawn(
      (
        @pbr.PointLight::default()
        .with_intensity(1800000.0F)
        .with_shadow_maps_enabled(true)
        .with_range(260.0F),
        @transform.Transform::from_xyz(26.0F, 42.0F, 20.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @transform.Transform::from_xyz(42.0F, 34.0F, 42.0F).looking_at(
          @math.Vec3::new(0.0F, 10.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  counter.get_ref().val.count = spawn_cubes(
    commands,
    cube_assets,
    INITIAL_CUBES,
    0,
  )
}

///|
fn mouse_spawn(
  commands : @app.Commands,
  assets : @app.Res[CubeAssets],
  counter : @app.ResMut[CubeCounter],
) -> Unit {
  if !@input.mouse_button_just_pressed(@input_events.MouseButton::Left) {
    return
  }
  let counter_ref = counter.get_ref()
  counter_ref.val.count = spawn_cubes(
    commands,
    assets.get(),
    CUBES_PER_CLICK,
    counter_ref.val.count,
  )
}

///|
fn movement(
  time : @app.Res[@time.Time[Unit]],
  cubes : @ecs.Query[
    (@ecs.Mut[CubeVelocity], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  let dt = time.get().delta_secs()
  try! cubes.for_each(fn(_entity, data) {
    let (velocity, transform) = data
    let velocity_ref = velocity.get_ref()
    let transform_ref = transform.get_ref()

    velocity_ref.val.value.y += GRAVITY * dt
    transform_ref.val.translation.x += velocity_ref.val.value.x * dt
    transform_ref.val.translation.y += velocity_ref.val.value.y * dt
    transform_ref.val.translation.z += velocity_ref.val.value.z * dt

    if transform_ref.val.translation.y < FLOOR_Y {
      transform_ref.val.translation.y = FLOOR_Y
      velocity_ref.val.value.y = -velocity_ref.val.value.y * 0.72F
    }
    if transform_ref.val.translation.x > BOUNDS {
      transform_ref.val.translation.x = BOUNDS
      velocity_ref.val.value.x = -@math.abs(velocity_ref.val.value.x)
    } else if transform_ref.val.translation.x < -BOUNDS {
      transform_ref.val.translation.x = -BOUNDS
      velocity_ref.val.value.x = @math.abs(velocity_ref.val.value.x)
    }
    if transform_ref.val.translation.z > BOUNDS {
      transform_ref.val.translation.z = BOUNDS
      velocity_ref.val.value.z = -@math.abs(velocity_ref.val.value.z)
    } else if transform_ref.val.translation.z < -BOUNDS {
      transform_ref.val.translation.z = -BOUNDS
      velocity_ref.val.value.z = @math.abs(velocity_ref.val.value.z)
    }
  })
}

///|
fn print_count(
  time : @app.Res[@time.Time[Unit]],
  counter : @app.ResMut[CubeCounter],
) -> Unit {
  let counter_ref = counter.get_ref()
  counter_ref.val.print_timer += time.get().delta_secs()
  if counter_ref.val.print_timer < 1.0F {
    return
  }
  counter_ref.val.print_timer -= 1.0F
  println("Cubes: \{counter_ref.val.count}")
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(CubeCounter::default())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(
    [
      ..@mgstudio.default_plugins(),
      @diagnostic.frame_time_diagnostics_plugin,
      @diagnostic.log_diagnostics_plugin,
    ],
  )
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param3(mouse_spawn)))
  .add_systems(@app.Update, @app.system(@app.system_param2(movement)))
  .add_systems(@app.Update, @app.system(@app.system_param2(print_count)))
  .run()
}
