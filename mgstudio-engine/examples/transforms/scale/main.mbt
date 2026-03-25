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
pub struct Scaling {
  mut scale_direction : @math.Vec3
  scale_speed : Float
  max_element_size : Float
  min_element_size : Float
}

///|
let scaling_component_key : @ecs.ComponentKey[Scaling] = @ecs.register_component(
  debug_name="examples.transforms.scale.Scaling",
)

///|
impl @ecs.Component for Scaling with component() {
  scaling_component_key
}

///|
fn Scaling::new() -> Scaling {
  {
    scale_direction: @math.Vec3::new(1.0F, 0.0F, 0.0F),
    scale_speed: 2.0F,
    max_element_size: 5.0F,
    min_element_size: 1.0F,
  }
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
          meshes.get_ref().val.add(
            @pbr.Mesh::from_3d_geometry(
              @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
            ),
          ),
        ),
        @pbr.MeshMaterial3d::new(
          materials.get_ref().val.add(
            @pbr.StandardMaterial::from_color(@sprite.Color::white()),
          ),
        ),
        @transform.Transform::from_rotation(
          @math.Quat::from_rotation_y(@math.pi() / 4.0F),
        ),
        Scaling::new(),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(0.0F, 10.0F, 20.0F).looking_at(
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
        @transform.Transform::from_xyz(3.0F, 3.0F, 3.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn change_scale_direction(
  commands : @app.Commands,
  cubes : @ecs.Query[
    (@ecs.Comp[Scaling], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  try! cubes.view(fn(entity, data) {
    let (cube, transform) = data
    let transform_ref = transform.get_ref()
    let next_cube = cube.value()
    let mut scaling_changed = false

    if transform_ref.val.scale.max_element() > cube.value().max_element_size {
      next_cube.scale_direction = next_cube.scale_direction.mul_scalar(-1.0F)
      transform_ref.val.scale = transform_ref.val.scale.floor()
      scaling_changed = true
    }

    if transform_ref.val.scale.min_element() < cube.value().min_element_size {
      next_cube.scale_direction = next_cube.scale_direction.mul_scalar(-1.0F)
      transform_ref.val.scale = transform_ref.val.scale.ceil()
      next_cube.scale_direction = next_cube.scale_direction.zxy()
      scaling_changed = true
    }

    if scaling_changed {
      commands.entity(entity).insert_component(next_cube)
    }
  })
}

///|
fn scale_cube(
  cubes : @ecs.Query[
    (@ecs.Comp[Scaling], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let delta = time.get().delta_secs()
  try! cubes.view(fn(_entity, data) {
    let (cube, transform) = data
    let transform_ref = transform.get_ref()
    transform_ref.val.scale = transform_ref.val.scale.add(
      cube.value().scale_direction.mul_scalar(cube.value().scale_speed * delta),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(change_scale_direction)),
  )
  .add_systems(@app.Update, @app.system(@app.system_param2(scale_cube)))
  .run()
}
