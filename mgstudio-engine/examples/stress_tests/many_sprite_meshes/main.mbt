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
const GRID_HALF_X : Int = 160

///|
const GRID_HALF_Y : Int = 160

///|
const TILE_SIZE : Float = 64.0F

///|
const CAMERA_RADIUS : Float = 1000.0F

///|
struct SpriteMeshTag {}

///|
let sprite_mesh_tag_key : @ecs.ComponentKey[SpriteMeshTag] = @ecs.register_component(
  debug_name="examples.stress_tests.many_sprite_meshes.SpriteMeshTag",
)

///|
pub impl @ecs.Component for SpriteMeshTag with fn component() {
  sprite_mesh_tag_key
}

///|
struct PrintTimer {
  seconds : Float
}

///|
let print_timer_key : @ecs.ResourceKey[PrintTimer] = @ecs.register_resource(
  debug_name="examples.stress_tests.many_sprite_meshes.PrintTimer",
)

///|
impl @app.Resource for PrintTimer with fn resource() {
  print_timer_key
}

///|
fn PrintTimer::PrintTimer() -> PrintTimer {
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
  materials : @app.ResMut[
    @asset.Assets[@sprite_render_mesh2d_color_material.ColorMaterial],
  ],
) -> Unit {
  ignore(commands.spawn_component(@camera_components2d.Camera2d::Camera2d()))

  let texture = asset_server.get().load("branding/icon.png")
  let quad_mesh = meshes
    .peek()
    .add(
      @mesh_primitives.rectangle_to_mesh2d_geometry(
        @math.Rectangle::new(24.0F, 24.0F),
      ).to_mesh(),
    )
  let base_material = materials
    .peek()
    .add(
      @sprite_render_mesh2d_color_material.ColorMaterial::from_image(texture).with_alpha_mode(
        @sprite_render.AlphaMode2d::Mask(0.5F),
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
            @mesh.Mesh2d::new(quad_mesh),
            @sprite_render_mesh2d_material.MeshMaterial2d::new(base_material),
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
    @ecs.Write[@transform.Transform],
    @ecs.With[@camera_components2d.Camera2d],
  ],
) -> Unit {
  let elapsed = time.get().elapsed_secs()
  try! camera.for_each(fn(_entity, transform) {
    transform.modify(fn(value) {
      value.rotation = @math.Quat::from_rotation_z(elapsed * 0.5F)
      value.translation = value.translation.add(
        @math.Vec3::new(CAMERA_RADIUS * time.get().delta_secs(), 0.0F, 0.0F),
      )
    })
  })
}

///|
fn print_count(
  time : @app.Res[@time.Time[Unit]],
  timer : @app.ResMut[PrintTimer],
  sprites : @ecs.Query[@ecs.Read[SpriteMeshTag], @ecs.All],
) -> Unit {
  let next_seconds = timer.get().seconds + time.get().delta_secs()
  if next_seconds < 1.0F {
    timer.set(PrintTimer::{ seconds: next_seconds })
    return
  }
  timer.set(PrintTimer::{ seconds: next_seconds - 1.0F })
  println("Sprite meshes: \{sprites.count()}")
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(PrintTimer::PrintTimer())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(@diagnostic.StressDiagnosticsPlugin::StressDiagnosticsPlugin())
  .add_systems(@app.Startup, @app.system_config_param4(setup))
  .add_systems(@app.Update, @app.system_config_param2(move_camera))
  .add_systems(@app.Update, @app.system_config_param3(print_count))
  .run()
}
