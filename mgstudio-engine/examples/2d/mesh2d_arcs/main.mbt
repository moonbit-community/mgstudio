// Copyright 2025 International Digital Economy Academy
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
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(mesh2d_arcs_setup)
  .run()
}

///|
fn arc_palette_color(index : Int, count : Int) -> @render2d.Color {
  let safe_count = if count <= 0 { 1 } else { count }
  let hue = Float::from_double(index.to_double()) /
    Float::from_double(safe_count.to_double())
  let tau = @math.pi_half() * 4.0F
  let r = 0.5F + 0.5F * @math.sin(tau * hue)
  let g = 0.5F + 0.5F * @math.sin(tau * (hue + 0.33333333F))
  let b = 0.5F + 0.5F * @math.sin(tau * (hue + 0.66666667F))
  @render2d.Color::new(r, g, b, 1.0F)
}

///|
fn spawn_arc_shape(
  world : @ecs_world.World,
  mesh : @render2d.Mesh2d,
  color : @render2d.Color,
  position : @math.Vec2,
  rotation : Float,
) -> Unit {
  let material = @render2d.ColorMaterial::new(color)
  let transform = @math.Transform::from_xy_rotation_scale(
    position,
    rotation,
    @math.Vec2::new(1.0F, 1.0F),
  )
  @render2d.Mesh2dBundle::new(mesh, material, transform).spawn(world) |> ignore
}

///|
fn mesh2d_arcs_setup(world : @ecs_world.World) -> Unit {
  let camera = @render2d.Camera::new(
    @render2d.Color::new(0.85F, 0.85F, 0.88F, 1.0F),
  )
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
  let count = 8
  let spacing_x = 110.0F
  let offset_x = spacing_x * Float::from_double((count - 1).to_double()) / 2.0F
  for i in 0..<count {
    let fraction = Float::from_double((i + 1).to_double()) /
      Float::from_double(count.to_double())
    let x = spacing_x * Float::from_double(i.to_double()) - offset_x
    let sector = @render2d.CircularSector::from_turns(42.0F, fraction).with_vertices(
      32,
    )
    let sector_rotation = -sector.half_angle()
    spawn_arc_shape(
      world,
      @render2d.Mesh2d::from_circular_sector(sector),
      arc_palette_color(i, count * 2),
      @math.Vec2::new(x, 70.0F),
      sector_rotation,
    )
    let segment = @render2d.CircularSegment::from_turns(42.0F, fraction).with_vertices(
      32,
    )
    let segment_rotation = -@math.pi_half()
    spawn_arc_shape(
      world,
      @render2d.Mesh2d::from_circular_segment(segment),
      arc_palette_color(i + count, count * 2),
      @math.Vec2::new(x, -70.0F),
      segment_rotation,
    )
  }
}
