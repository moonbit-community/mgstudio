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
/// Port of `bevy/examples/3d/camera_sub_view.rs`.
///
/// Baseline parity: mgstudio currently has no `SubCameraView`, so moving sub-view
/// offset is approximated by moving dedicated cameras while preserving viewport
/// layout parity.

///|
pub(all) enum ExampleViewport {
  PerspectiveMain
  PerspectiveStretched
  PerspectiveMoving
  PerspectiveControl
  OrthographicMain
  OrthographicStretched
  OrthographicMoving
  OrthographicControl
}

///|
priv struct CameraSubViewState {
  cameras : Array[(@core.Entity, ExampleViewport)]
  moving_cameras : Array[@core.Entity]
  base_transform : @math.Transform
}

///|
let camera_sub_view_state : Ref[CameraSubViewState] = Ref::new({
  cameras: [],
  moving_cameras: [],
  base_transform: @math.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
    @math.Vec3::zero(),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  ),
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn spawn_perspective_camera(
  world : @ecs_world.World,
  kind : ExampleViewport,
  order : Int,
  moving~ : Bool = false,
) -> Unit {
  let entity = @render3d.Camera3dBundle::new(
    @render2d.Camera::default().with_order(order),
    camera_sub_view_state.val.base_transform,
  ).spawn(world)
  camera_sub_view_state.val.cameras.push((entity, kind))
  if moving {
    camera_sub_view_state.val.moving_cameras.push(entity)
  }
}

///|
fn spawn_orthographic_camera(
  world : @ecs_world.World,
  kind : ExampleViewport,
  order : Int,
  moving~ : Bool = false,
) -> Unit {
  let entity = @render3d.Camera3dBundle::new_with_projection(
    @render2d.Camera::default().with_order(order),
    @render3d.Projection3d::orthographic_default(),
    camera_sub_view_state.val.base_transform,
  ).spawn(world)
  camera_sub_view_state.val.cameras.push((entity, kind))
  if moving {
    camera_sub_view_state.val.moving_cameras.push(entity)
  }
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  camera_sub_view_state.val.cameras.clear()
  camera_sub_view_state.val.moving_cameras.clear()

  // Plane
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

  // Cube
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

  // Light
  let light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(light, @render3d.PointLight::new(@render2d.Color::white(), 1_000_000.0F, 30.0F, true), tick)
  world
  .get_transform_store()
  .insert(light, @math.Transform::from_xyz(4.0F, 8.0F, 4.0F), tick)

  // Perspective cameras
  spawn_perspective_camera(world, ExampleViewport::PerspectiveMain, 0)
  spawn_perspective_camera(world, ExampleViewport::PerspectiveStretched, 1)
  spawn_perspective_camera(
    world,
    ExampleViewport::PerspectiveMoving,
    2,
    moving=true,
  )
  spawn_perspective_camera(world, ExampleViewport::PerspectiveControl, 3)

  // Orthographic cameras
  spawn_orthographic_camera(world, ExampleViewport::OrthographicMain, 4)
  spawn_orthographic_camera(world, ExampleViewport::OrthographicStretched, 5)
  spawn_orthographic_camera(
    world,
    ExampleViewport::OrthographicMoving,
    6,
    moving=true,
  )
  spawn_orthographic_camera(world, ExampleViewport::OrthographicControl, 7)
}

///|
fn move_camera_view(world : @ecs_world.World) -> Unit {
  let elapsed = @time.time_elapsed_seconds()
  let sweep = elapsed * 150.0F
  let cycle = 450.0F
  let wrapped = sweep - float_from_int((sweep / cycle).to_int()) * cycle
  let offset = wrapped - 50.0F
  let world_offset = offset / 250.0F

  let base = camera_sub_view_state.val.base_transform.translation
  let next = @math.Transform::from_xyz(
    base.x + world_offset,
    base.y,
    base.z + world_offset,
  ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F))

  let tick = world.read_change_tick()
  let transform_store = world.get_transform_store()
  for entity in camera_sub_view_state.val.moving_cameras {
    transform_store.set(entity, next, tick) |> ignore
  }
}

///|
fn min_int(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn resize_viewports(world : @ecs_world.World) -> Unit {
  let window_width = @window.window_width()
  let window_height = @window.window_height()
  if window_width <= 0 || window_height <= 0 {
    return
  }

  let small_height = window_height / 5
  let small_width = window_width / 8
  if small_height <= 0 || small_width <= 0 {
    return
  }

  let large_height = small_height * 4
  let large_width = small_width * 4

  let large_size = @math.IVec2::new(large_width, large_height)
  let small_dim = min_int(small_height, small_width)
  let small_size = @math.IVec2::new(small_dim, small_dim)
  let small_wide_size = @math.IVec2::new(small_dim * 2, small_dim)

  let tick = world.read_change_tick()
  let camera_store = world.get_camera_store()

  for pair in camera_sub_view_state.val.cameras {
    let entity = pair.0
    let viewport_kind = pair.1
    let (size, position) = match viewport_kind {
      PerspectiveMain => (large_size, @math.IVec2::new(0, small_height))
      PerspectiveStretched => (small_size, @math.IVec2::new(0, 0))
      PerspectiveMoving => (small_size, @math.IVec2::new(small_width, 0))
      PerspectiveControl => (
        small_wide_size,
        @math.IVec2::new(small_width * 2, 0),
      )
      OrthographicMain => (
        large_size,
        @math.IVec2::new(large_width, small_height),
      )
      OrthographicStretched => (
        small_size,
        @math.IVec2::new(small_width * 4, 0),
      )
      OrthographicMoving => (
        small_size,
        @math.IVec2::new(small_width * 5, 0),
      )
      OrthographicControl => (
        small_wide_size,
        @math.IVec2::new(small_width * 6, 0),
      )
    }
    if camera_store.get(entity) is Some(camera) {
      camera_store.set(
        entity,
        camera.with_viewport(@render2d.Viewport::new(position, size)),
        tick,
      )
      |> ignore
    }
  }
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(move_camera_view)
  .add_system(resize_viewports)
  .run()
}
