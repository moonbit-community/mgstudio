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
/// Port of `bevy/examples/3d/lines.rs`.

///|
/// Baseline parity: custom line-list/line-strip mesh topology and custom line
/// material shader are not available in current mgstudio runtime surfaces.

///|
/// Baseline parity: this port draws equivalent line segments with thin unlit
/// cuboids to preserve layout and camera behavior.

///|
const LINE_THICKNESS : Float = 0.03F

///|
fn spawn_line_segment(
  world : @ecs_world.World,
  start : @math.Vec3,
  end_ : @math.Vec3,
  offset : @math.Vec3,
  material : @asset.Handle[@render3d.StandardMaterial],
) -> Unit {
  let dx = end_.x - start.x
  let dy = end_.y - start.y
  let dz = end_.z - start.z
  let length = @math.sqrt(dx * dx + dy * dy + dz * dz)
  let angle_z = @math.atan2(dy, dx)

  let center = @math.Vec3::new(
    (start.x + end_.x) * 0.5F + offset.x,
    (start.y + end_.y) * 0.5F + offset.y,
    (start.z + end_.z) * 0.5F + offset.z,
  )

  let transform = @math.Transform::from_xyz(center.x, center.y, center.z).with_rotation(
    @math.Quat::from_rotation_z(angle_z),
  )

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(length, LINE_THICKNESS, LINE_THICKNESS),
    @render3d.MeshMaterial3d::new(material),
    transform,
  ).spawn(world)
  |> ignore
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  let green_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.0F, 1.0F, 0.0F, 1.0F),
    ).with_unlit(true),
  )
  let blue_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.2F, 0.5F, 1.0F, 1.0F),
    ).with_unlit(true),
  )

  let list_offset = @math.Vec3::new(-1.5F, 0.0F, 0.0F)
  spawn_line_segment(
    world,
    @math.Vec3::zero(),
    @math.Vec3::new(1.0F, 1.0F, 0.0F),
    list_offset,
    green_material,
  )
  spawn_line_segment(
    world,
    @math.Vec3::new(1.0F, 1.0F, 0.0F),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    list_offset,
    green_material,
  )

  let strip_offset = @math.Vec3::new(0.5F, 0.0F, 0.0F)
  spawn_line_segment(
    world,
    @math.Vec3::zero(),
    @math.Vec3::new(1.0F, 1.0F, 0.0F),
    strip_offset,
    blue_material,
  )
  spawn_line_segment(
    world,
    @math.Vec3::new(1.0F, 1.0F, 0.0F),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    strip_offset,
    blue_material,
  )

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .run()
}
