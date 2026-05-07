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
pub struct CubeState {
  start_pos : @math.Vec3
  move_speed : Float
  turn_speed : Float
}

///|
let cube_state_component_key : @ecs.ComponentKey[CubeState] = @ecs.register_component(
  debug_name="examples.transforms.transform.CubeState",
)

///|
impl @ecs.Component for CubeState with component() {
  cube_state_component_key
}

///|
pub struct Center {
  max_size : Float
  min_size : Float
  scale_factor : Float
}

///|
let center_component_key : @ecs.ComponentKey[Center] = @ecs.register_component(
  debug_name="examples.transforms.transform.Center",
)

///|
impl @ecs.Component for Center with component() {
  center_component_key
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@pbr.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(
          meshes
          .peek()
          .add(@pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_sphere(3.0F))),
        ),
        @pbr.MeshMaterial3d::new(
          materials
          .peek()
          .add(
            @pbr.StandardMaterial::from_color(
              @sprite.Color::srgb(1.0F, 1.0F, 0.0F),
            ),
          ),
        ),
        @mgs_transform.Transform::from_translation(@math.Vec3::zero()),
        Center::{ max_size: 1.0F, min_size: 0.1F, scale_factor: 0.05F },
      ),
    ),
  )

  let cube_spawn = @mgs_transform.Transform::from_translation(
    @math.Vec3::new(0.0F, 0.0F, -10.0F),
  ).with_rotation(@math.Quat::from_rotation_y(@math.pi() / 2.0F))
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(
          meshes
          .peek()
          .add(
            @pbr.Mesh::from_3d_geometry(
              @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
            ),
          ),
        ),
        @pbr.MeshMaterial3d::new(
          materials
          .peek()
          .add(@pbr.StandardMaterial::from_color(@sprite.Color::white())),
        ),
        cube_spawn,
        CubeState::{
          start_pos: cube_spawn.translation,
          move_speed: 2.0F,
          turn_speed: 0.2F,
        },
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @mgs_transform.Transform::from_xyz(0.0F, 10.0F, 20.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::default(),
        @mgs_transform.Transform::from_xyz(3.0F, 3.0F, 3.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn move_cube(
  cubes : @ecs.Query[
    (@ecs.Comp[CubeState], @ecs.Mut[@mgs_transform.Transform]),
    @ecs.Without[Center],
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let delta = time.get().delta_secs()
  try! cubes.view(fn(_entity, data) {
    let (cube, transform) = data
    transform.modify(fn(value) {
      let forward = value.forward()
      value.translation = value.translation.add(
        forward.mul_scalar(cube.value().move_speed * delta),
      )
    })
  })
}

///|
fn rotate_cube(
  cubes : @ecs.Query[
    (@ecs.Comp[CubeState], @ecs.Mut[@mgs_transform.Transform]),
    @ecs.Without[Center],
  ],
  center_spheres : @ecs.Query[
    @ecs.Comp[@mgs_transform.Transform],
    @ecs.With[Center],
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  guard (center_spheres.single() catch { _ => None }) is Some(center_comp) else {
    return
  }
  let center = center_comp.value()

  let delta = time.get().delta_secs()
  try! cubes.view(fn(_entity, data) {
    let (cube, transform) = data
    transform.modify(fn(value) {
      let look_at_sphere = value.looking_at(center.translation, value.local_y())
      let weight = cube.value().turn_speed * delta
      let old_rotation = value.rotation
      value.rotation = old_rotation.lerp(look_at_sphere.rotation, weight)
    })
  })
}

///|
fn scale_down_sphere_proportional_to_cube_travel_distance(
  cubes : @ecs.Query[
    (@ecs.Comp[@mgs_transform.Transform], @ecs.Comp[CubeState]),
    @ecs.Without[Center],
  ],
  centers : @ecs.Query[
    (@ecs.Comp[Center], @ecs.Mut[@mgs_transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  let distances = Ref(0.0F)
  try! cubes.view(fn(_entity, data) {
    let (cube_transform, cube_state) = data
    distances.val = distances.val +
      cube_state.value().start_pos
      .sub(cube_transform.value().translation)
      .length()
  })
  try! centers.view(fn(_entity, data) {
    let (center, transform) = data
    let center_state = center.value()
    let mut new_size = center_state.max_size -
      center_state.scale_factor * distances.val
    if new_size < center_state.min_size {
      new_size = center_state.min_size
    }
    transform.modify(fn(value) { value.scale = @math.Vec3::splat(new_size) })
  })
}

///|
fn main {
  let move_cube_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(move_cube),
  )
  let rotate_cube_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param3(rotate_cube),
  )
  let scale_down_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(scale_down_sphere_proportional_to_cube_travel_distance),
  )

  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(
    @app.Update,
    (move_cube_system, rotate_cube_system, scale_down_system) |> @app.chain(),
  )
  .run()
}
