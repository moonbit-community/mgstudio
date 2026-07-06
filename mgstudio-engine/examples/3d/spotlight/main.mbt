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
const PI : Float = 3.141592653589793F

///|
const MOVE_SPEED : Float = 2.0F

///|
const INSTRUCTIONS : String = "Controls\n--------\nHorizontal Movement: WASD\nVertical Movement: Space and Shift\nRotate Camera: Left and Right Arrows"

///|
struct Movable {}

///|
let movable_component_key : @ecs.ComponentKey[Movable] = @ecs.register_component(
  debug_name="examples.3d.spotlight.Movable",
)

///|
pub impl @ecs.Component for Movable with fn component() {
  movable_component_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn rng_float_range(
  rng : @chacha_rng.ChaCha8Rng,
  low : Float,
  high : Float,
) -> Float {
  low + rng.random_float() * (high - low)
}

///|
fn uv_sphere_mesh(
  meshes : @asset.Assets[@mesh.Mesh],
  radius : Float,
  stacks : Int,
  sectors : Int,
) -> @mesh.Mesh3d {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  let stacks_f = float_from_int(stacks)
  let sectors_f = float_from_int(sectors)
  let stack_step = PI / stacks_f
  let sector_step = 2.0F * PI / sectors_f

  for i in 0..<(stacks + 1) {
    let stack_angle = PI / 2.0F - float_from_int(i) * stack_step
    let ring_radius = radius * @math.cos(stack_angle)
    let y = radius * @math.sin(stack_angle)
    for j in 0..<(sectors + 1) {
      let sector_angle = float_from_int(j) * sector_step
      let x = ring_radius * @math.cos(sector_angle)
      let z = ring_radius * @math.sin(sector_angle)
      positions.push(@math.Vec3::new(x, y, z))
      uvs.push(
        @math.Vec2::new(
          float_from_int(j) / sectors_f,
          float_from_int(i) / stacks_f,
        ),
      )
    }
  }

  let row = sectors + 1
  for i in 0..<stacks {
    let k1 = i * row
    let k2 = k1 + row
    for j in 0..<sectors {
      if i != 0 {
        indices.push(k1 + j)
        indices.push(k2 + j)
        indices.push(k1 + j + 1)
      }
      if i != stacks - 1 {
        indices.push(k1 + j + 1)
        indices.push(k2 + j)
        indices.push(k2 + j + 1)
      }
    }
  }

  @mesh.Mesh3d::new(
    meshes.add(
      @mesh.Mesh::from_3d_geometry(
        @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let ground_material = materials.modify(fn(assets) {
    assets.add(@pbr.StandardMaterial::from_color(@color.Color::white()))
  })
  let cube_material = materials.modify(fn(assets) {
    assets.add(
      @pbr.StandardMaterial::from_color(
        @color.Color::new(124.0F / 255.0F, 144.0F / 255.0F, 1.0F, 1.0F),
      ),
    )
  })
  let red_emissive = materials.modify(fn(assets) {
    assets.add(
      @pbr.StandardMaterial::from_color(
        @color.Color::new(1.0F, 0.0F, 0.0F, 1.0F),
      ).with_emissive(@color.Color::new(1.0F, 0.0F, 0.0F, 0.0F)),
    )
  })
  let maroon_emissive = materials.modify(fn(assets) {
    assets.add(
      @pbr.StandardMaterial::from_color(
        @color.Color::new(0.502F, 0.0F, 0.0F, 1.0F),
      ).with_emissive(@color.Color::new(0.369F, 0.0F, 0.0F, 0.0F)),
    )
  })

  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(
          meshes.modify(fn(assets) {
            assets
            |> @pbr.add_mesh(
              @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
                @math.Vec2::new(100.0F, 100.0F),
              ).build(),
            )
          }),
        ),
        @pbr.MeshMaterial3dTyped::new(ground_material),
        Movable::{  },
      ),
    ),
  )

  let rng = @chacha_rng.ChaCha8Rng::seed_from_u64(19878367467713UL)
  let cube_mesh = @mesh.Mesh3d::new(
    meshes.modify(fn(assets) {
      assets |> @pbr.add_mesh(@math.Cuboid::new(0.5F, 0.5F, 0.5F))
    }),
  )
  for _ in 0..<40 {
    let x = rng_float_range(rng, -5.0F, 5.0F)
    let y = rng_float_range(rng, 0.0F, 3.0F)
    let z = rng_float_range(rng, -5.0F, 5.0F)
    ignore(
      commands.spawn(
        (
          cube_mesh,
          @pbr.MeshMaterial3dTyped::new(cube_material),
          @transform.Transform::from_xyz(x, y, z),
          Movable::{  },
        ),
      ),
    )
  }

  let sphere_mesh = meshes.modify(fn(assets) {
    uv_sphere_mesh(assets, 0.05F, 18, 32)
  })
  let sphere_mesh_direction = meshes.modify(fn(assets) {
    uv_sphere_mesh(assets, 0.1F, 18, 32)
  })
  for x in 0..<4 {
    for z in 0..<4 {
      let x = float_from_int(x) - 2.0F
      let z = float_from_int(z) - 2.0F
      let spotlight = commands.spawn(
        (
          @pbr.SpotLight::new(
            @color.Color::white(),
            40_000.0F,
            20.0F,
            PI / 4.0F * 0.85F,
            PI / 4.0F,
            true,
          ),
          @transform.Transform::from_xyz(1.0F + x, 2.0F, z).looking_at(
            @math.Vec3::new(1.0F + x, 0.0F, z),
            @math.Vec3::new(1.0F, 0.0F, 0.0F),
          ),
        ),
      )

      ignore(
        commands.spawn(
          (
            @hierarchy.Parent::new(spotlight),
            sphere_mesh,
            @pbr.MeshMaterial3dTyped::new(red_emissive),
          ),
        ),
      )
      ignore(
        commands.spawn(
          (
            @hierarchy.Parent::new(spotlight),
            sphere_mesh_direction,
            @pbr.MeshMaterial3dTyped::new(maroon_emissive),
            @transform.Transform::from_translation(
              @math.Vec3::new(0.0F, 0.0F, -0.1F),
            ),
            @pbr.NotShadowCaster::NotShadowCaster(),
          ),
        ),
      )
    }
  }

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @pbr.Hdr::Hdr(),
        @transform.Transform::from_xyz(-4.0F, 5.0F, 10.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @text.Text::new(INSTRUCTIONS),
        @ui.Node::Node()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.px(12.0F))
        .with_left(@ui.px(12.0F)),
      ),
    ),
  )
}

///|
fn light_sway(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    (@ecs.Write[@transform.Transform], @ecs.Write[@pbr.SpotLight]),
    @ecs.All,
  ],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  try! query.for_each(fn(_entity, components) {
    let (transform, angles) = components
    transform.modify(fn(value) {
      value.rotation = @math.Quat::from_euler(
        @math.EulerRot::XYZ,
        -@math.pi_half() + @math.sin(elapsed * 0.67F * 3.0F) * 0.5F,
        @math.sin(elapsed * 3.0F) * 0.5F,
        0.0F,
      )
    })
    let angle = (@math.sin(elapsed * 1.2F) + 1.0F) *
      (@math.pi_half() / 2.0F - 0.1F)
    let light = angles.value()
    angles.set(light.with_outer_angle(angle).with_inner_angle(angle * 0.8F))
  })
}

///|
fn movement(
  input : @input.ButtonInput[@window.KeyCode],
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[@ecs.Write[@transform.Transform], @ecs.With[Movable]],
) -> Unit {
  let mut translation = @math.Vec3::zero()
  if input.pressed(@window.KeyCode::KeyW) {
    translation = translation.add(@math.Vec3::new(0.0F, 0.0F, 1.0F))
  } else if input.pressed(@window.KeyCode::KeyS) {
    translation = translation.add(@math.Vec3::new(0.0F, 0.0F, -1.0F))
  }

  if input.pressed(@window.KeyCode::KeyA) {
    translation = translation.add(@math.Vec3::new(1.0F, 0.0F, 0.0F))
  } else if input.pressed(@window.KeyCode::KeyD) {
    translation = translation.add(@math.Vec3::new(-1.0F, 0.0F, 0.0F))
  }

  if input.pressed(@window.KeyCode::ShiftLeft) {
    translation = translation.add(@math.Vec3::new(0.0F, 1.0F, 0.0F))
  } else if input.pressed(@window.KeyCode::Space) {
    translation = translation.add(@math.Vec3::new(0.0F, -1.0F, 0.0F))
  }

  let translation = translation.mul_scalar(
    MOVE_SPEED * time.get().delta_seconds(),
  )
  try! query.for_each(fn(_entity, transform) {
    transform.modify(fn(value) {
      value.translation = value.translation.add(translation)
    })
  })
}

///|
fn rotation(
  transform : @app.Single[
    @ecs.Write[@transform.Transform],
    @ecs.With[@camera_camera.Camera],
  ],
  input : @input.ButtonInput[@window.KeyCode],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let delta = time.get().delta_seconds()

  if input.pressed(@window.KeyCode::ArrowLeft) {
    transform
    .get()
    .modify(fn(value) {
      value.rotate_around(
        @math.Vec3::zero(),
        @math.Quat::from_rotation_y(delta),
      )
    })
  } else if input.pressed(@window.KeyCode::ArrowRight) {
    transform
    .get()
    .modify(fn(value) {
      value.rotate_around(
        @math.Vec3::zero(),
        @math.Quat::from_rotation_y(-delta),
      )
    })
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@pbr.GlobalAmbientLight::new(@color.Color::white(), 20.0F))
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param3(@app.Startup, setup)
  .add_systems_param2(@app.Update, light_sway)
  .add_systems_param3(@app.Update, movement)
  .add_systems_param3(@app.Update, rotation)
  .run()
}
