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
pub fn game_main() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(shapes_setup)
  .add_system(shapes_rotate)
  .run()
}

///|
fn shape_palette_color(index : Int, count : Int) -> @render2d.Color {
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
fn lane_x(index : Int, total : Int, extent : Float) -> Float {
  if total <= 1 {
    return 0.0F
  }
  let ratio = Float::from_double(index.to_double()) /
    Float::from_double((total - 1).to_double())
  -extent / 2.0F + ratio * extent
}

///|
fn spawn_shape(
  world : @ecs_world.World,
  mesh : @render2d.Mesh2d,
  position : @math.Vec2,
  color : @render2d.Color,
) -> Unit {
  let material = @render2d.ColorMaterial::new(color)
  let transform = @math.Transform::from_xy_rotation_scale(
    position,
    0.0F,
    @math.Vec2::new(1.0F, 1.0F),
  )
  @render2d.Mesh2dBundle::new(mesh, material, transform).spawn(world) |> ignore
}

///|
fn shapes_setup(world : @ecs_world.World) -> Unit {
  let top_shapes : Array[@render2d.Mesh2d] = [
    @render2d.Mesh2d::from_circle(
      @render2d.Circle::new(48.0F).with_vertices(40),
    ),
    @render2d.Mesh2d::from_ellipse(
      @render2d.Ellipse::new(30.0F, 52.0F).with_vertices(40),
    ),
    @render2d.Mesh2d::from_annulus(
      @render2d.Annulus::new(20.0F, 46.0F).with_vertices(48),
    ),
    @render2d.Mesh2d::from_capsule(@render2d.Capsule2d::new(24.0F, 30.0F, 20)),
    @render2d.Mesh2d::from_rhombus(@render2d.Rhombus::new(88.0F, 108.0F)),
    @render2d.Mesh2d::from_rectangle(@render2d.Rectangle::new(72.0F, 108.0F)),
    @render2d.Mesh2d::from_regular_polygon(
      @render2d.RegularPolygon::new(48.0F, 6),
    ),
    @render2d.Mesh2d::from_triangle(
      @render2d.Triangle2d::new(
        @math.Vec2::new(0.0F, 52.0F),
        @math.Vec2::new(-52.0F, -52.0F),
        @math.Vec2::new(52.0F, -52.0F),
      ),
    ),
    @render2d.Mesh2d::from_segment(
      @render2d.Segment2d::new(
        @math.Vec2::new(-52.0F, 52.0F),
        @math.Vec2::new(52.0F, -52.0F),
      ).with_half_thickness(5.0F),
    ),
    @render2d.Mesh2d::from_polyline(
      @render2d.Polyline2d::new([
        @math.Vec2::new(-52.0F, 52.0F),
        @math.Vec2::new(0.0F, -52.0F),
        @math.Vec2::new(52.0F, 52.0F),
      ]).with_half_thickness(5.0F),
    ),
  ]
  let bottom_shapes : Array[@render2d.Mesh2d] = [
    @render2d.Mesh2d::from_ring(
      @render2d.Ring2d::new(52.0F, 46.0F).with_vertices(56),
    ),
    @render2d.Mesh2d::from_ring(
      @render2d.Ring2d::new(52.0F, 36.0F).with_vertices(56),
    ),
    @render2d.Mesh2d::from_annulus(
      @render2d.Annulus::new(14.0F, 52.0F).with_vertices(56),
    ),
    @render2d.Mesh2d::from_ring(
      @render2d.Ring2d::new(52.0F, 22.0F).with_vertices(56),
    ),
    @render2d.Mesh2d::from_regular_polygon(
      @render2d.RegularPolygon::new(52.0F, 12),
    ),
    @render2d.Mesh2d::from_capsule(@render2d.Capsule2d::new(18.0F, 44.0F, 24)),
  ]
  let top_count = top_shapes.length()
  for i in 0..<top_count {
    spawn_shape(
      world,
      top_shapes[i],
      @math.Vec2::new(lane_x(i, top_count, 1040.0F), 140.0F),
      shape_palette_color(i, top_count),
    )
  }
  let bottom_count = bottom_shapes.length()
  for i in 0..<bottom_count {
    spawn_shape(
      world,
      bottom_shapes[i],
      @math.Vec2::new(lane_x(i, bottom_count, 820.0F), -140.0F),
      shape_palette_color(i + top_count, top_count + bottom_count),
    )
  }
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
}

///|
fn shapes_rotate(world : @ecs_world.World) -> Unit {
  let delta_secs = @time.time_delta_seconds()
  let speed = 0.5F
  let tick = world.read_change_tick()
  let transform_store = world.get_transform_store()
  let mesh_store = world.get_mesh2d_store()
  let entities : Array[(@core.Entity, @math.Transform)] = []
  @core.query2(transform_store, mesh_store, fn(entity, transform, _mesh) {
    entities.push((entity, transform))
  })
  for entry in entities {
    let entity = entry.0
    let transform = entry.1
    let next_rotation = transform.rotation_z() + speed * delta_secs
    let next_transform = @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(transform.translation.x, transform.translation.y),
      next_rotation,
      @math.Vec2::new(transform.scale.x, transform.scale.y),
      z=transform.translation.z,
    )
    transform_store.set(entity, next_transform, tick) |> ignore
  }
}

///|
fn main {
  game_main()
}
