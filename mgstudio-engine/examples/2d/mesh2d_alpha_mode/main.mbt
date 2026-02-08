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
  .add_startup_system(mesh2d_alpha_mode_setup)
  .run()
}

///|
fn spawn_quad(
  world : @ecs_world.World,
  position : @math.Vec2,
  scale : @math.Vec2,
  color : @render2d.Color,
  alpha_mode : @render2d.AlphaMode2d,
  z : Float,
) -> Unit {
  let mesh = @render2d.Mesh2d::from_rectangle(@render2d.Rectangle::default())
  let material = @render2d.ColorMaterial::new_with_alpha_mode(color, alpha_mode)
  let transform = @math.Transform::from_xy_rotation_scale(
    position,
    0.0F,
    scale,
    z~,
  )
  @render2d.Mesh2dBundle::new(mesh, material, transform).spawn(world) |> ignore
}

///|
fn mesh2d_alpha_mode_setup(world : @ecs_world.World) -> Unit {
  // Background board to make alpha-mode differences obvious.
  spawn_quad(
    world,
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(760.0F, 280.0F),
    @render2d.Color::new(0.15F, 0.15F, 0.2F, 1.0F),
    @render2d.AlphaMode2d::Opaque,
    -10.0F,
  )

  // Opaque: alpha ignored for blending, rendered as solid.
  spawn_quad(
    world,
    @math.Vec2::new(-260.0F, 0.0F),
    @math.Vec2::new(180.0F, 180.0F),
    @render2d.Color::new(1.0F, 0.2F, 0.2F, 0.25F),
    @render2d.AlphaMode2d::Opaque,
    0.0F,
  )

  // Mask below cutoff: should not be rendered.
  spawn_quad(
    world,
    @math.Vec2::new(-80.0F, 0.0F),
    @math.Vec2::new(180.0F, 180.0F),
    @render2d.Color::new(0.2F, 0.9F, 0.2F, 0.25F),
    @render2d.AlphaMode2d::Mask(0.5F),
    0.0F,
  )

  // Mask above cutoff: rendered as solid.
  spawn_quad(
    world,
    @math.Vec2::new(100.0F, 0.0F),
    @math.Vec2::new(180.0F, 180.0F),
    @render2d.Color::new(0.2F, 0.9F, 0.2F, 0.8F),
    @render2d.AlphaMode2d::Mask(0.5F),
    0.0F,
  )

  // Blend: alpha participates in blending.
  spawn_quad(
    world,
    @math.Vec2::new(280.0F, 0.0F),
    @math.Vec2::new(180.0F, 180.0F),
    @render2d.Color::new(0.2F, 0.6F, 1.0F, 0.25F),
    @render2d.AlphaMode2d::Blend,
    0.0F,
  )
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
}
