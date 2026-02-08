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
  .add_startup_system(transparency_2d_setup)
  .run()
}

///|
fn spawn_blend_quad(
  world : @ecs_world.World,
  position : @math.Vec2,
  scale : @math.Vec2,
  color : @render2d.Color,
  z : Float,
) -> Unit {
  let mesh = @render2d.Mesh2d::from_rectangle(@render2d.Rectangle::default())
  let material = @render2d.ColorMaterial::new_with_alpha_mode(
    color,
    @render2d.AlphaMode2d::Blend,
  )
  let transform = @math.Transform::from_xy_rotation_scale(
    position,
    0.0F,
    scale,
    z~,
  )
  @render2d.Mesh2dBundle::new(mesh, material, transform).spawn(world) |> ignore
}

///|
fn transparency_2d_setup(world : @ecs_world.World) -> Unit {
  spawn_blend_quad(
    world,
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(820.0F, 360.0F),
    @render2d.Color::new(0.06F, 0.06F, 0.08F, 1.0F),
    -10.0F,
  )
  spawn_blend_quad(
    world,
    @math.Vec2::new(-90.0F, -20.0F),
    @math.Vec2::new(260.0F, 260.0F),
    @render2d.Color::new(1.0F, 0.2F, 0.2F, 0.5F),
    -1.0F,
  )
  spawn_blend_quad(
    world,
    @math.Vec2::new(70.0F, -20.0F),
    @math.Vec2::new(260.0F, 260.0F),
    @render2d.Color::new(0.2F, 1.0F, 0.2F, 0.5F),
    0.0F,
  )
  spawn_blend_quad(
    world,
    @math.Vec2::new(-10.0F, 110.0F),
    @math.Vec2::new(260.0F, 260.0F),
    @render2d.Color::new(0.2F, 0.4F, 1.0F, 0.5F),
    1.0F,
  )
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
}
