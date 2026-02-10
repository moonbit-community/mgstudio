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
priv struct ShapesState {
  rotating : Array[@core.Entity]
}

///|
let shapes_state : Ref[ShapesState] = Ref::new({ rotating: [] })

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(shapes_setup)
  .add_system(shapes_rotate_system)
  .run()
}

///|
fn spawn_shape(
  world : @ecs_world.World,
  mesh : @render3d.Mesh3d,
  material : @asset.Handle[@render3d.StandardMaterial],
  transform : @math.Transform,
) -> Unit {
  let entity = @render3d.MeshMaterial3dBundle::new(
    mesh,
    @render3d.MeshMaterial3d::new(material),
    transform,
  ).spawn(world)
  shapes_state.val.rotating.push(entity)
}

///|
fn shapes_setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let ambient = world.get_global_ambient_light_resource()
  if ambient.get_ref_mut(tick) is Some(a) {
    a.val = @render3d.GlobalAmbientLight::new(@render2d.Color::white(), 0.4F)
  }

  let point_light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    point_light,
    @render3d.PointLight::new(
      @render2d.Color::white(),
      180000.0F,
      2000.0F,
      false,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(point_light, @math.Transform::from_xyz(200.0F, 320.0F, 260.0F), tick)

  let floor_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.18F, 0.2F, 0.24F, 1.0F),
    ),
  )
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(1000.0F, 1000.0F),
    @render3d.MeshMaterial3d::new(floor_material),
    @math.Transform::from_xyz(0.0F, -180.0F, 0.0F),
  ).spawn(world)
  |> ignore

  let red = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.95F, 0.35F, 0.35F, 1.0F),
    ),
  )
  let green = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.35F, 0.95F, 0.55F, 1.0F),
    ),
  )
  let blue = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.35F, 0.55F, 0.95F, 1.0F),
    ),
  )
  let yellow = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.95F, 0.9F, 0.35F, 1.0F),
    ),
  )

  spawn_shape(
    world,
    @render3d.Mesh3d::from_cuboid(120.0F, 120.0F, 120.0F),
    red,
    @math.Transform::from_xyz(-280.0F, -40.0F, -120.0F),
  )
  spawn_shape(
    world,
    @render3d.Mesh3d::from_tetrahedron(170.0F),
    green,
    @math.Transform::from_xyz(-80.0F, -20.0F, 120.0F),
  )
  spawn_shape(
    world,
    @render3d.Mesh3d::from_cuboid(100.0F, 180.0F, 100.0F),
    blue,
    @math.Transform::from_xyz(120.0F, -10.0F, -120.0F),
  )
  spawn_shape(
    world,
    @render3d.Mesh3d::from_tetrahedron(140.0F),
    yellow,
    @math.Transform::from_xyz(320.0F, -20.0F, 120.0F),
  )

  let camera = @render2d.Camera::default()
  @render3d.Camera3dBundle::new(
    camera,
    @math.Transform::from_xyz(0.0F, 120.0F, 760.0F).looking_at(
      @math.Vec3::new(0.0F, -20.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn shapes_rotate_system(world : @ecs_world.World) -> Unit {
  let delta_secs = @time.time_delta_seconds()
  let tick = world.read_change_tick()
  let spin = @math.Quat::from_rotation_y(delta_secs * 0.8F)
  let transform_store = world.get_transform_store()
  for entity in shapes_state.val.rotating {
    if transform_store.get(entity) is Some(transform) {
      let next = transform.with_rotation(
        transform.rotation.mul(spin).normalize(),
      )
      transform_store.set(entity, next, tick) |> ignore
    }
  }
}
