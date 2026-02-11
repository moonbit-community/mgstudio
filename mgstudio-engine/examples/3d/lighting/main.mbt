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
priv struct LightingState {
  mut angle : Float
  mut point_light : @core.Entity?
}

///|
let lighting_state : Ref[LightingState] = Ref::new({
  angle: 0.0F,
  point_light: None,
})

///|
pub fn game_main() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(lighting_setup)
  .add_system(lighting_animate_system)
  .run()
}

///|
fn lighting_setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let ambient = world.get_global_ambient_light_resource()
  if ambient.get_ref_mut(tick) is Some(a) {
    a.val = @render3d.GlobalAmbientLight::new(
      @render2d.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
      0.2F,
    )
  }

  let floor_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.82F, 0.82F, 0.85F, 1.0F),
    ),
  )
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(800.0F, 800.0F),
    @render3d.MeshMaterial3d::new(floor_material),
    @math.Transform::from_xyz(0.0F, -150.0F, 0.0F),
  ).spawn(world)
  |> ignore

  let wall_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.3F, 0.3F, 0.45F, 1.0F),
    ),
  )
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(800.0F, 260.0F, 16.0F),
    @render3d.MeshMaterial3d::new(wall_material),
    @math.Transform::from_xyz(0.0F, -20.0F, -380.0F),
  ).spawn(world)
  |> ignore

  let red_mat = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.95F, 0.35F, 0.35F, 1.0F),
    ),
  )
  let green_mat = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.35F, 0.95F, 0.45F, 1.0F),
    ),
  )
  let blue_mat = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.35F, 0.45F, 0.95F, 1.0F),
    ),
  )

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(120.0F, 120.0F, 120.0F),
    @render3d.MeshMaterial3d::new(red_mat),
    @math.Transform::from_xyz(-170.0F, -90.0F, -40.0F),
  ).spawn(world)
  |> ignore
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_tetrahedron(180.0F),
    @render3d.MeshMaterial3d::new(green_mat),
    @math.Transform::from_xyz(120.0F, -60.0F, 80.0F),
  ).spawn(world)
  |> ignore
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(60.0F, 220.0F, 60.0F),
    @render3d.MeshMaterial3d::new(blue_mat),
    @math.Transform::from_xyz(250.0F, -40.0F, -160.0F),
  ).spawn(world)
  |> ignore

  let directional = world.spawn_empty()
  world
  .get_directional_light_store()
  .insert(
    directional,
    @render3d.DirectionalLight::new(
      @render2d.Color::new(1.0F, 1.0F, 0.95F, 1.0F),
      12000.0F,
      false,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(
    directional,
    @math.Transform::from_xyz(0.0F, 200.0F, 0.0F).with_rotation(
      @math.Quat::from_rotation_x(-0.8F),
    ),
    tick,
  )

  let spot = world.spawn_empty()
  world
  .get_spot_light_store()
  .insert(
    spot,
    @render3d.SpotLight::new(
      @render2d.Color::new(0.45F, 1.0F, 0.45F, 1.0F),
      140000.0F,
      2000.0F,
      0.55F,
      0.8F,
      false,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(
    spot,
    @math.Transform::from_xyz(-280.0F, 210.0F, 180.0F).looking_at(
      @math.Vec3::new(-100.0F, -80.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  let point = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    point,
    @render3d.PointLight::new(
      @render2d.Color::new(0.45F, 0.6F, 1.0F, 1.0F),
      200000.0F,
      2400.0F,
      false,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(point, @math.Transform::from_xyz(280.0F, 220.0F, 0.0F), tick)
  lighting_state.val.point_light = Some(point)

  let camera = @render2d.Camera::default()
  @render3d.Camera3dBundle::new(
    camera,
    @math.Transform::from_xyz(0.0F, 160.0F, 760.0F).looking_at(
      @math.Vec3::new(0.0F, -70.0F, -40.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn lighting_animate_system(world : @ecs_world.World) -> Unit {
  lighting_state.val.angle = lighting_state.val.angle +
    @time.time_delta_seconds() * 0.8F
  if lighting_state.val.point_light is None {
    return
  }
  let tick = world.read_change_tick()
  let transform_store = world.get_transform_store()
  let angle = lighting_state.val.angle
  let x = @math.cos(angle) * 320.0F
  let z = @math.sin(angle) * 220.0F
  let point = lighting_state.val.point_light.unwrap()
  if transform_store.get(point) is Some(transform) {
    let next = transform.with_translation(@math.Vec3::new(x, 220.0F, z))
    transform_store.set(point, next, tick) |> ignore
  }
}

///|
fn main {
  game_main()
}
