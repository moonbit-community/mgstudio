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
/// Port of `bevy/examples/3d/two_passes.rs`.
///
/// Baseline parity: Bevy's second camera uses `ClearColor::None` on full screen.
/// mgstudio currently always clears per camera pass, so the second pass is shown
/// in a dynamic picture-in-picture viewport instead.

///|
priv struct TwoPassesState {
  mut camera_overlay : @core.Entity
  mut last_window_size : @math.IVec2
}

///|
let two_passes_state : Ref[TwoPassesState] = Ref::new({
  camera_overlay: @core.Entity::placeholder(),
  last_window_size: @math.IVec2::new(0, 0),
})

///|
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  two_passes_state.val.camera_overlay = @core.Entity::placeholder()
  two_passes_state.val.last_window_size = @math.IVec2::new(0, 0)

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(5.0F, 5.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::new(0.3F, 0.5F, 0.3F, 1.0F),
        ),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::new(0.8F, 0.7F, 0.6F, 1.0F),
        ),
      ),
    ),
    @math.Transform::from_xyz(0.0F, 0.5F, 0.0F),
  ).spawn(world)
  |> ignore

  let light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(light, @render3d.PointLight::new(@render2d.Color::white(), 1_000_000.0F, 20.0F, true), tick)
  world
  .get_transform_store()
  .insert(light, @math.Transform::from_xyz(4.0F, 8.0F, 4.0F), tick)

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore

  let overlay_camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::new(@render2d.Color::new(0.08F, 0.08F, 0.08F, 1.0F)).with_order(1),
    @math.Transform::from_xyz(10.0F, 10.0F, -5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  two_passes_state.val.camera_overlay = overlay_camera

  update_overlay_viewport(world)
}

///|
fn update_overlay_viewport(world : @ecs_world.World) -> Unit {
  if two_passes_state.val.camera_overlay.is_placeholder() {
    return
  }
  let width = @window.window_width()
  let height = @window.window_height()
  if width <= 1 || height <= 1 {
    return
  }

  let window_size = @math.IVec2::new(width, height)
  if window_size.x == two_passes_state.val.last_window_size.x &&
    window_size.y == two_passes_state.val.last_window_size.y {
    return
  }

  let viewport_size = @math.IVec2::new(width / 3, height / 3)
  let viewport_position = @math.IVec2::new(
    width - viewport_size.x,
    0,
  )

  let tick = world.read_change_tick()
  let camera_store = world.get_camera_store()
  if camera_store.get(two_passes_state.val.camera_overlay) is Some(camera) {
    camera_store.set(
      two_passes_state.val.camera_overlay,
      camera.with_viewport(
        @render2d.Viewport::new(viewport_position, viewport_size),
      ),
      tick,
    )
    |> ignore
  }

  two_passes_state.val.last_window_size = window_size
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(update_overlay_viewport)
  .run()
}
