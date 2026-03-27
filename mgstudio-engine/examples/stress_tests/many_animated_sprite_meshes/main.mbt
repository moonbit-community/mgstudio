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
const GRID_HALF_X : Int = 72

///|
const GRID_HALF_Y : Int = 54

///|
const TILE_SIZE : Float = 36.0F

///|
const CAMERA_SPEED : Float = 1000.0F

///|
struct MeshPulse {
  phase : Float
  speed : Float
}

///|
let mesh_pulse_key : @ecs.ComponentKey[MeshPulse] = @ecs.register_component(
  debug_name="examples.stress_tests.many_animated_sprite_meshes.MeshPulse",
)

///|
pub impl @ecs.Component for MeshPulse with component() {
  mesh_pulse_key
}

///|
struct PrintTimer {
  mut seconds : Float
}

///|
let print_timer_key : @ecs.ResourceKey[PrintTimer] = @ecs.register_resource(
  debug_name="examples.stress_tests.many_animated_sprite_meshes.PrintTimer",
)

///|
impl @app.Resource for PrintTimer with resource() {
  print_timer_key
}

///|
fn PrintTimer::default() -> PrintTimer {
  { seconds: 0.0F }
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  let texture = asset_server
    .get()
    .load("textures/rpg/chars/gabe/gabe-idle-run.png")
  let mesh = meshes.get_ref().val.add(
    @sprite.mesh2d_geometry_rectangle(@sprite.Rectangle::new(24.0F, 24.0F)).to_mesh(),
  )
  let material = materials.get_ref().val.add(
    @sprite.ColorMaterialAsset::from_image(texture).with_uv_scale(
      @math.Vec2::new(0.2F, 1.0F),
    ),
  )

  for y in -GRID_HALF_Y..<GRID_HALF_Y {
    for x in -GRID_HALF_X..<GRID_HALF_X {
      let idx = (y + GRID_HALF_Y) * (GRID_HALF_X * 2) + (x + GRID_HALF_X)
      ignore(
        commands.spawn(
          (
            @sprite.Mesh2d::new(mesh),
            @sprite.MeshMaterial2d::new(material),
            @transform.Transform::from_xyz(
              float_from_int(x) * TILE_SIZE,
              float_from_int(y) * TILE_SIZE,
              float_from_int(idx % 100) / 100.0F,
            ),
            MeshPulse::{
              phase: float_from_int(idx % 360) * 0.017453292519943295F,
              speed: 0.5F + float_from_int(idx % 7) * 0.12F,
            },
          ),
        ),
      )
    }
  }
}

///|
fn animate_meshes(
  time : @app.Res[@time.Time[Unit]],
  meshes : @ecs.Query[
    (@ecs.Comp[MeshPulse], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! meshes.for_each(fn(_entity, data) {
    let (pulse, transform) = data
    let pulse_value = pulse.value()
    let transform_ref = transform.get_ref()
    let angle = t * pulse_value.speed + pulse_value.phase
    let scale = 0.65F + 0.35F * @math.sin(angle)
    transform_ref.val.rotation = @math.Quat::from_rotation_z(angle * 0.75F)
    transform_ref.val.scale = @math.Vec3::new(scale, scale, 1.0F)
  })
}

///|
fn move_camera(
  time : @app.Res[@time.Time[Unit]],
  camera : @ecs.Query[
    @ecs.Mut[@transform.Transform],
    @ecs.With[@sprite.Camera2d],
  ],
) -> Unit {
  try! camera.for_each(fn(_entity, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.rotation = @math.Quat::from_rotation_z(
      time.get().elapsed_secs() * 0.4F,
    )
    transform_ref.val.translation = transform_ref.val.translation.add(
      @math.Vec3::new(CAMERA_SPEED * time.get().delta_secs(), 0.0F, 0.0F),
    )
  })
}

///|
fn print_count(
  time : @app.Res[@time.Time[Unit]],
  timer : @app.ResMut[PrintTimer],
  meshes : @ecs.Query[@ecs.Comp[MeshPulse], @ecs.All],
) -> Unit {
  let timer_ref = timer.get_ref()
  timer_ref.val.seconds += time.get().delta_secs()
  if timer_ref.val.seconds < 1.0F {
    return
  }
  timer_ref.val.seconds -= 1.0F
  println("Animated sprite meshes: \{meshes.count()}")
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(PrintTimer::default())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(
    [
      ..@mgstudio.default_plugins(),
      @diagnostic.frame_time_diagnostics_plugin,
      @diagnostic.log_diagnostics_plugin,
    ],
  )
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(animate_meshes)))
  .add_systems(@app.Update, @app.system(@app.system_param2(move_camera)))
  .add_systems(@app.Update, @app.system(@app.system_param3(print_count)))
  .run()
}
