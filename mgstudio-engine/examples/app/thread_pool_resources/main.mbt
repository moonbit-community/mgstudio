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
const CUBE_COUNT : Int = 72

///|
struct WorkerCube {
  phase : Float
}

///|
let worker_cube_key : @ecs.ComponentKey[WorkerCube] = @ecs.register_component(
  debug_name="examples.app.thread_pool_resources.WorkerCube",
)

///|
pub impl @ecs.Component for WorkerCube with component() {
  worker_cube_key
}

///|
struct SimulatedPool {
  mut worker_count : Int
  mut queued_jobs : Int
  mut busy : Bool
  mut print_timer : Float
}

///|
let simulated_pool_key : @ecs.ResourceKey[SimulatedPool] = @ecs.register_resource(
  debug_name="examples.app.thread_pool_resources.SimulatedPool",
)

///|
impl @app.Resource for SimulatedPool with resource() {
  simulated_pool_key
}

///|
fn SimulatedPool::default() -> SimulatedPool {
  { worker_count: 8, queued_jobs: 0, busy: true, print_timer: 0.0F }
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn max_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@pbr.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let floor_mesh = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(90.0F, 0.1F, 90.0F)),
  )
  let floor_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.14F, 0.18F, 0.22F)),
  )
  ignore(
    commands.spawn(
      (@pbr.Mesh3d::new(floor_mesh), @pbr.MeshMaterial3d::new(floor_material)),
    ),
  )
  let cube_mesh = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(0.9F, 0.9F, 0.9F)),
  )
  let cube_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.55F, 0.75F, 1.0F)),
  )
  let side = 9
  let half = float_from_int(side) / 2.0F
  for i in 0..<CUBE_COUNT {
    let x = i % side
    let z = i / side
    ignore(
      commands.spawn(
        (
          @pbr.Mesh3d::new(cube_mesh),
          @pbr.MeshMaterial3d::new(cube_material),
          @transform.Transform::from_xyz(
            (float_from_int(x) - half) * 2.1F,
            0.45F,
            (float_from_int(z) - half) * 2.1F,
          ),
          WorkerCube::{ phase: float_from_int(i % 17) * 0.3F },
        ),
      ),
    )
  }
  ignore(
    commands.spawn(
      (
        @pbr.PointLight::default()
        .with_intensity(500000.0F)
        .with_shadow_maps_enabled(true),
        @transform.Transform::from_xyz(14.0F, 24.0F, 10.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(20.0F, 14.0F, 20.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn input_control(pool : @app.ResMut[SimulatedPool]) -> Unit {
  let pool_ref = pool.get_ref()
  if @input.key_just_pressed(@window.KeyCode::Space) {
    pool_ref.val.busy = !pool_ref.val.busy
  }
  if @input.key_just_pressed(@window.KeyCode::ArrowUp) {
    pool_ref.val.worker_count += 1
  }
  if @input.key_just_pressed(@window.KeyCode::ArrowDown) {
    pool_ref.val.worker_count = max_int(pool_ref.val.worker_count - 1, 1)
  }
}

///|
fn simulate_pool(
  time : @app.Res[@time.Time[Unit]],
  pool : @app.ResMut[SimulatedPool],
) -> Unit {
  let pool_ref = pool.get_ref()
  if pool_ref.val.busy {
    pool_ref.val.queued_jobs += (time.get().delta_secs() * 70.0F).to_int()
    let drained = (time.get().delta_secs() *
    float_from_int(pool_ref.val.worker_count) *
    9.0F).to_int()
    pool_ref.val.queued_jobs = max_int(pool_ref.val.queued_jobs - drained, 0)
  } else {
    pool_ref.val.queued_jobs = max_int(
      pool_ref.val.queued_jobs - (time.get().delta_secs() * 30.0F).to_int(),
      0,
    )
  }
  pool_ref.val.print_timer += time.get().delta_secs()
  if pool_ref.val.print_timer >= 1.0F {
    pool_ref.val.print_timer -= 1.0F
    println(
      "sim-pool workers=\{pool_ref.val.worker_count} queued=\{pool_ref.val.queued_jobs} busy=\{pool_ref.val.busy}",
    )
  }
}

///|
fn animate_cubes(
  time : @app.Res[@time.Time[Unit]],
  pool : @app.Res[SimulatedPool],
  cubes : @ecs.Query[
    (@ecs.Comp[WorkerCube], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  let load = float_from_int(pool.get().queued_jobs % 200) / 200.0F
  let t = time.get().elapsed_secs()
  try! cubes.for_each(fn(_entity, data) {
    let (worker, transform) = data
    let transform_ref = transform.get_ref()
    let phase = worker.value().phase
    transform_ref.val.translation.y = 0.45F +
      @math.sin(t * 2.0F + phase) * (0.2F + load * 1.2F)
    transform_ref.val.rotation = @math.Quat::from_rotation_y(t * 0.6F + phase)
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(SimulatedPool::default())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_plugins(@diagnostic.FrameTimeDiagnosticsPlugin::default())
  .add_plugins(@diagnostic.LogDiagnosticsPlugin::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param(input_control)))
  .add_systems(@app.Update, @app.system(@app.system_param2(simulate_pool)))
  .add_systems(@app.Update, @app.system(@app.system_param3(animate_cubes)))
  .run()
}
