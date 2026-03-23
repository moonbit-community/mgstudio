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
  base_transform : @transform.Transform
}

///|
let camera_sub_view_state : Ref[CameraSubViewState] = Ref::new({
  cameras: [],
  moving_cameras: [],
  base_transform: @transform.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
    @math.Vec3::zero(),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  ),
})

///|
const ORTHOGRAPHIC_VIEWPORT_HEIGHT : Float = 6.0F

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn spawn_perspective_camera(
  world : @ecs.World,
  kind : ExampleViewport,
  order : Int,
  sub_camera_view? : @pbr.SubCameraView3d? = None,
  moving? : Bool = false,
) -> Unit {
  let entity = @pbr.Camera3dBundle::new(
      @sprite.Camera::default().with_order(order),
      camera_sub_view_state.val.base_transform,
    )
    .with_sub_camera_view(sub_camera_view)
    .spawn(world)
  camera_sub_view_state.val.cameras.push((entity, kind))
  if moving {
    camera_sub_view_state.val.moving_cameras.push(entity)
  }
}

///|
fn spawn_orthographic_camera(
  world : @ecs.World,
  kind : ExampleViewport,
  order : Int,
  sub_camera_view? : @pbr.SubCameraView3d? = None,
  moving? : Bool = false,
) -> Unit {
  let entity = @pbr.Camera3dBundle::new_with_projection(
      @sprite.Camera::default().with_order(order),
      @pbr.Projection::Orthographic(@pbr.OrthographicProjection3d::{
        ..@pbr.OrthographicProjection3d::default_3d(),
        scaling_mode: @pbr.OrthographicScalingMode3d::FixedVertical(
          ORTHOGRAPHIC_VIEWPORT_HEIGHT,
        ),
      }),
      camera_sub_view_state.val.base_transform,
    )
    .with_sub_camera_view(sub_camera_view)
    .spawn(world)
  camera_sub_view_state.val.cameras.push((entity, kind))
  if moving {
    camera_sub_view_state.val.moving_cameras.push(entity)
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_sequence()
  camera_sub_view_state.val.cameras.clear()
  camera_sub_view_state.val.moving_cameras.clear()

  // Plane
  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(5.0F, 5.0F)),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::new(0.3F, 0.5F, 0.3F, 1.0F),
        ),
      ),
    ),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  // Cube
  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::new(0.8F, 0.7F, 0.6F, 1.0F),
        ),
      ),
    ),
    @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F),
  ).spawn(world)
  |> ignore

  // Light
  let light = world.spawn_empty()
  world
  .component(@pbr.ecs_key_point_light)
  .insert(
    light,
    @pbr.PointLight::new(@sprite.Color::white(), 1_000_000.0F, 20.0F, true),
    tick,
  )
  world
  .component(@transform.ecs_key_transform)
  .insert(light, @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F), tick)

  let perspective_stretched_sub_view = @pbr.SubCameraView3d::new(
    @math.IVec2::new(10, 10),
    @math.Vec2::new(5.0F, 0.0F),
    @math.IVec2::new(5, 10),
  )
  let perspective_moving_sub_view = @pbr.SubCameraView3d::new(
    @math.IVec2::new(500, 500),
    @math.Vec2::new(0.0F, 0.0F),
    @math.IVec2::new(100, 100),
  )
  let perspective_control_sub_view = @pbr.SubCameraView3d::new(
    @math.IVec2::new(800, 800),
    @math.Vec2::new(0.0F, 0.0F),
    @math.IVec2::new(800, 400),
  )
  let orthographic_stretched_sub_view = @pbr.SubCameraView3d::new(
    @math.IVec2::new(2, 2),
    @math.Vec2::new(0.0F, 0.0F),
    @math.IVec2::new(1, 2),
  )
  let orthographic_moving_sub_view = @pbr.SubCameraView3d::new(
    @math.IVec2::new(500, 500),
    @math.Vec2::new(0.0F, 0.0F),
    @math.IVec2::new(100, 100),
  )
  let orthographic_control_sub_view = @pbr.SubCameraView3d::new(
    @math.IVec2::new(200, 200),
    @math.Vec2::new(0.0F, 0.0F),
    @math.IVec2::new(200, 100),
  )

  // Perspective cameras
  spawn_perspective_camera(world, ExampleViewport::PerspectiveMain, 0)
  spawn_perspective_camera(
    world,
    ExampleViewport::PerspectiveStretched,
    1,
    sub_camera_view=Some(perspective_stretched_sub_view),
  )
  spawn_perspective_camera(
    world,
    ExampleViewport::PerspectiveMoving,
    2,
    sub_camera_view=Some(perspective_moving_sub_view),
    moving=true,
  )
  spawn_perspective_camera(
    world,
    ExampleViewport::PerspectiveControl,
    3,
    sub_camera_view=Some(perspective_control_sub_view),
  )

  // Orthographic cameras
  spawn_orthographic_camera(world, ExampleViewport::OrthographicMain, 4)
  spawn_orthographic_camera(
    world,
    ExampleViewport::OrthographicStretched,
    5,
    sub_camera_view=Some(orthographic_stretched_sub_view),
  )
  spawn_orthographic_camera(
    world,
    ExampleViewport::OrthographicMoving,
    6,
    sub_camera_view=Some(orthographic_moving_sub_view),
    moving=true,
  )
  spawn_orthographic_camera(
    world,
    ExampleViewport::OrthographicControl,
    7,
    sub_camera_view=Some(orthographic_control_sub_view),
  )
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in camera_sub_view example")
  }
}

///|
fn move_camera_view(world : @ecs.World) -> Unit {
  let elapsed = world_time(world).elapsed_seconds()
  let sweep = elapsed * 150.0F
  let cycle = 450.0F
  let wrapped = sweep - float_from_int((sweep / cycle).to_int()) * cycle
  let offset = wrapped - 50.0F

  let tick = world.read_sequence()
  let sub_camera_view_store = world.component(@pbr.ecs_key_sub_camera_view3d)
  for entity in camera_sub_view_state.val.moving_cameras {
    if sub_camera_view_store.get(entity) is Some(sub_camera_view) {
      let next = sub_camera_view.with_offset(@math.Vec2::new(offset, offset))
      sub_camera_view_store.set(entity, next, tick) |> ignore
    }
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
fn resize_viewports(world : @ecs.World) -> Unit {
  let window_width = @window.window_width()
  let window_height = @window.window_height()
  let small_height = window_height / 5
  let small_width = window_width / 8
  let large_height = small_height * 4
  let large_width = small_width * 4

  let large_size = @math.IVec2::new(large_width, large_height)
  let small_dim = min_int(small_height, small_width)
  let small_size = @math.IVec2::new(small_dim, small_dim)
  let small_wide_size = @math.IVec2::new(small_dim * 2, small_dim)

  let tick = world.read_sequence()
  let camera_store = world.component(@sprite.ecs_key_camera)

  for pair in camera_sub_view_state.val.cameras {
    let entity = pair.0
    let viewport_kind = pair.1
    let (size, position) = match viewport_kind {
      PerspectiveMain => (large_size, @math.IVec2::new(0, small_height))
      PerspectiveStretched => (small_size, @math.IVec2::new(0, 0))
      PerspectiveMoving => (small_size, @math.IVec2::new(small_width, 0))
      PerspectiveControl =>
        (small_wide_size, @math.IVec2::new(small_width * 2, 0))
      OrthographicMain =>
        (large_size, @math.IVec2::new(large_width, small_height))
      OrthographicStretched =>
        (small_size, @math.IVec2::new(small_width * 4, 0))
      OrthographicMoving => (small_size, @math.IVec2::new(small_width * 5, 0))
      OrthographicControl =>
        (small_wide_size, @math.IVec2::new(small_width * 6, 0))
    }
    if camera_store.get(entity) is Some(camera) {
      let viewport = match camera.viewport {
        Some(viewport) => viewport
        None => @sprite.Viewport::default()
      }
      camera_store.set(
        entity,
        camera.with_viewport(
          @sprite.Viewport::new_with_depth(
            position,
            size,
            viewport.depth_min,
            viewport.depth_max,
          ),
        ),
        tick,
      )
      |> ignore
    }
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(move_camera_view))
  .add_systems(@app.Update, @app.system(resize_viewports))
  .run()
}
