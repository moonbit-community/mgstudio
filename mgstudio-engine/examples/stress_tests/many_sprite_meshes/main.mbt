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
const GRID_HALF_X : Int = 90

///|
const GRID_HALF_Y : Int = 64

///|
const TILE_SIZE : Float = 30.0F

///|
const CAMERA_RADIUS : Float = 700.0F

///|
struct SpriteMeshTag {}

///|
let sprite_mesh_tag_key : @ecs.ComponentKey[SpriteMeshTag] = @ecs.register_component(
  debug_name="examples.stress_tests.many_sprite_meshes.SpriteMeshTag",
)

///|
pub impl @ecs.Component for SpriteMeshTag with component() {
  sprite_mesh_tag_key
}

///|
struct PrintTimer {
  mut seconds : Float
}

///|
let print_timer_key : @ecs.ResourceKey[PrintTimer] = @ecs.register_resource(
  debug_name="examples.stress_tests.many_sprite_meshes.PrintTimer",
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

  let texture = asset_server.get().load("branding/icon.png")
  let quad_mesh = meshes.get_ref().val.add(
    @sprite.mesh2d_geometry_rectangle(@sprite.Rectangle::new(24.0F, 24.0F)).to_mesh(),
  )
  let base_material = materials.get_ref().val.add(
    @sprite.ColorMaterialAsset::from_image(texture).with_alpha_mode(
      @sprite.AlphaMode2d::Mask(0.5F),
    ),
  )

  for y in -GRID_HALF_Y..<GRID_HALF_Y {
    for x in -GRID_HALF_X..<GRID_HALF_X {
      let idx = (y + GRID_HALF_Y) * (GRID_HALF_X * 2) + (x + GRID_HALF_X)
      let rotation = @math.Quat::from_rotation_z(
        float_from_int(idx % 360) * 0.017453292519943295F,
      )
      ignore(
        commands.spawn(
          (
            @sprite.Mesh2d::new(quad_mesh),
            @sprite.MeshMaterial2d::new(base_material),
            @transform.Transform::from_xyz(
              float_from_int(x) * TILE_SIZE,
              float_from_int(y) * TILE_SIZE,
              float_from_int(idx % 100) / 100.0F,
            ).with_rotation(rotation),
            SpriteMeshTag::{  },
          ),
        ),
      )
    }
  }
}

///|
fn move_camera(
  time : @app.Res[@time.Time[Unit]],
  camera : @ecs.Query[
    @ecs.Mut[@transform.Transform],
    @ecs.With[@sprite.Camera2d],
  ],
) -> Unit {
  let elapsed = time.get().elapsed_secs()
  try! camera.for_each(fn(_entity, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.rotation = @math.Quat::from_rotation_z(elapsed * 0.5F)
    transform_ref.val.translation = transform_ref.val.translation.add(
      @math.Vec3::new(CAMERA_RADIUS * time.get().delta_secs(), 0.0F, 0.0F),
    )
  })
}

///|
fn print_count(
  time : @app.Res[@time.Time[Unit]],
  timer : @app.ResMut[PrintTimer],
  sprites : @ecs.Query[@ecs.Comp[SpriteMeshTag], @ecs.All],
) -> Unit {
  let timer_ref = timer.get_ref()
  timer_ref.val.seconds += time.get().delta_secs()
  if timer_ref.val.seconds < 1.0F {
    return
  }
  timer_ref.val.seconds -= 1.0F
  println("Sprite meshes: \{sprites.count()}")
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
  .add_systems(@app.Update, @app.system(@app.system_param2(move_camera)))
  .add_systems(@app.Update, @app.system(@app.system_param3(print_count)))
  .run()
}
