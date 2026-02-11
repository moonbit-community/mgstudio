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
const CIRCLE_SEGMENTS : Int = 48

///|
const TAU : Float = 6.283185307179586F

///|
priv struct WireframeSceneState {
  mut rectangle_entity : @core.Entity
  mut circle_entity : @core.Entity
  mut rectangle_geometry : @mesh.Mesh2dGeometry?
  mut circle_geometry : @mesh.Mesh2dGeometry?
  mut global_enabled : Bool
  mut global_color_is_red : Bool
  mut circle_color_is_red : Bool
}

///|
let wireframe_scene_state : Ref[WireframeSceneState] = Ref::new(WireframeSceneState::{
  rectangle_entity: @core.Entity::placeholder(),
  circle_entity: @core.Entity::placeholder(),
  rectangle_geometry: None,
  circle_geometry: None,
  global_enabled: true,
  global_color_is_red: false,
  circle_color_is_red: false,
})

///|
pub fn app_main() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(wireframe_setup)
  .add_system(wireframe_update)
  .run()
}

///|
fn wireframe_setup(world : @ecs_world.World) -> Unit {
  let black = @render2d.Color::black()
  let triangle_geometry = build_triangle_geometry()
  let rectangle_geometry = build_rectangle_geometry()
  let circle_geometry = build_circle_geometry(50.0F, CIRCLE_SEGMENTS)

  @render2d.Mesh2dBundle::new(
    @render2d.Mesh2d::from_geometry(triangle_geometry),
    @render2d.ColorMaterial::new(black),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-150.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  ).spawn(world)
  |> ignore
  let rectangle_entity = @render2d.Mesh2dBundle::new(
    @render2d.Mesh2d::from_geometry(rectangle_geometry),
    @render2d.ColorMaterial::new(black),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  ).spawn(world)
  let circle_entity = @render2d.Mesh2dBundle::new(
    @render2d.Mesh2d::from_geometry(circle_geometry),
    @render2d.ColorMaterial::new(black),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(150.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  ).spawn(world)

  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  wireframe_scene_state.val.rectangle_entity = rectangle_entity
  wireframe_scene_state.val.circle_entity = circle_entity
  wireframe_scene_state.val.rectangle_geometry = Some(rectangle_geometry)
  wireframe_scene_state.val.circle_geometry = Some(circle_geometry)
}

///|
fn wireframe_update(world : @ecs_world.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::KeyZ) {
    wireframe_scene_state.val.global_enabled = !wireframe_scene_state.val.global_enabled
  }
  if @input.key_just_pressed(@window.KeyCode::KeyX) {
    wireframe_scene_state.val.global_color_is_red = !wireframe_scene_state.val.global_color_is_red
  }
  if @input.key_just_pressed(@window.KeyCode::KeyC) {
    wireframe_scene_state.val.circle_color_is_red = !wireframe_scene_state.val.circle_color_is_red
  }

  let global_color = if wireframe_scene_state.val.global_color_is_red {
    @render2d.Color::new(1.0F, 0.0F, 0.0F, 1.0F)
  } else {
    @render2d.Color::white()
  }
  let circle_color = if wireframe_scene_state.val.circle_color_is_red {
    @render2d.Color::new(1.0F, 0.0F, 0.0F, 1.0F)
  } else {
    @render2d.Color::new(0.0F, 1.0F, 0.0F, 1.0F)
  }

  let gizmos = @render2d.Gizmos::new()
  let transform_store = world.get_transform_store()

  if wireframe_scene_state.val.global_enabled {
    guard wireframe_scene_state.val.rectangle_geometry is Some(rect_geometry) else {
      return
    }
    if transform_store.get(wireframe_scene_state.val.rectangle_entity)
      is Some(rect_transform) {
      gizmos.mesh_wireframe_2d(rect_geometry, rect_transform, global_color)
    }
  }

  guard wireframe_scene_state.val.circle_geometry is Some(circle_geometry) else {
    return
  }
  if transform_store.get(wireframe_scene_state.val.circle_entity)
    is Some(circle_transform) {
    gizmos.mesh_wireframe_2d(circle_geometry, circle_transform, circle_color)
  }
}

///|
fn build_triangle_geometry() -> @mesh.Mesh2dGeometry {
  let positions = [
    @math.Vec2::new(0.0F, 50.0F),
    @math.Vec2::new(-50.0F, -50.0F),
    @math.Vec2::new(50.0F, -50.0F),
  ]
  let uvs = [
    @math.Vec2::new(0.5F, 1.0F),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 0.0F),
  ]
  @mesh.Mesh2dGeometry::new(positions, uvs, None)
}

///|
fn build_rectangle_geometry() -> @mesh.Mesh2dGeometry {
  let positions = [
    @math.Vec2::new(-50.0F, -50.0F),
    @math.Vec2::new(50.0F, -50.0F),
    @math.Vec2::new(50.0F, 50.0F),
    @math.Vec2::new(-50.0F, 50.0F),
  ]
  let uvs = [
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(0.0F, 1.0F),
  ]
  let indices = [0, 1, 2, 0, 2, 3]
  @mesh.Mesh2dGeometry::new(positions, uvs, Some(indices))
}

///|
fn build_circle_geometry(
  radius : Float,
  segments : Int,
) -> @mesh.Mesh2dGeometry {
  let safe_segments = if segments < 3 { 3 } else { segments }
  let positions : Array[@math.Vec2] = [@math.Vec2::new(0.0F, 0.0F)]
  let uvs : Array[@math.Vec2] = [@math.Vec2::new(0.5F, 0.5F)]
  let indices : Array[Int] = []
  let safe_radius = if radius < 0.0F { -radius } else { radius }

  for i in 0..<safe_segments {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(safe_segments.to_double())
    let angle = t * TAU
    let x = @math.cos(angle) * safe_radius
    let y = @math.sin(angle) * safe_radius
    positions.push(@math.Vec2::new(x, y))
    let uvx = 0.5F + x / (safe_radius * 2.0F)
    let uvy = 0.5F + y / (safe_radius * 2.0F)
    uvs.push(@math.Vec2::new(uvx, uvy))
  }

  for i in 0..<safe_segments {
    let next = if i + 1 < safe_segments { i + 1 } else { 0 }
    indices.push(0)
    indices.push(i + 1)
    indices.push(next + 1)
  }

  @mesh.Mesh2dGeometry::new(positions, uvs, Some(indices))
}

///|
fn main {
  app_main()
}
