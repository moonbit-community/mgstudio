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
const TRANSITION_DURATION : Float = 2.0F

///|
struct ShowAxes {}

///|
struct TransformTracking {
  mut initial_transform : @transform.Transform
  mut target_transform : @transform.Transform
  mut progress : Float
}

///|
struct SeededRng {
  rng : @example_rng.ChaCha8Rng
}

///|
let show_axes_key : @ecs.ComponentKey[ShowAxes] = @ecs.register_component(
  debug_name="examples.gizmos.axes.ShowAxes",
)

///|
let transform_tracking_key : @ecs.ComponentKey[TransformTracking] = @ecs.register_component(
  debug_name="examples.gizmos.axes.TransformTracking",
)

///|
let seeded_rng_key : @ecs.ResourceKey[SeededRng] = @ecs.register_resource(
  debug_name="examples.gizmos.axes.SeededRng",
)

///|
pub impl @ecs.Component for ShowAxes with fn component() {
  show_axes_key
}

///|
pub impl @ecs.Component for TransformTracking with fn component() {
  transform_tracking_key
}

///|
pub impl @app.Resource for SeededRng with fn resource() {
  seeded_rng_key
}

///|
fn seeded_rng() -> @example_rng.ChaCha8Rng {
  @example_rng.ChaCha8Rng::seed_from_u64(19878367467713UL)
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let rng = seeded_rng()

  commands.spawn(
    (
      @pbr.PointLight::new(@color.Color::white(), 800.0F, 20.0F, true),
      @transform.Transform::from_xyz(2.0F, 6.0F, 0.0F),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @camera.Camera3d::Camera3d(),
      @transform.Transform::from_xyz(0.0F, 1.5F, -8.0F).looking_at(
        @math.Vec3::new(0.0F, -0.5F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @mesh.Mesh3d::new(
        meshes.modify(fn(assets) {
          @pbr.add_mesh(assets, @math.Cuboid::new(1.0F, 1.0F, 1.0F))
        }),
      ),
      @pbr.MeshMaterial3dTyped::new(
        materials
        .peek()
        .add(
          @pbr.StandardMaterial::from_color(
            @color.Color::srgb(0.8F, 0.7F, 0.6F),
          ),
        ),
      ),
      ShowAxes::{  },
      TransformTracking::{
        initial_transform: @transform.Transform::identity(),
        target_transform: random_transform(rng),
        progress: 0.0F,
      },
    ),
  )
  |> ignore

  commands.spawn(
    (
      @mesh.Mesh3d::new(
        meshes.modify(fn(assets) {
          @pbr.add_mesh(assets, @math.Cuboid::new(0.5F, 0.5F, 0.5F))
        }),
      ),
      @pbr.MeshMaterial3dTyped::new(
        materials
        .peek()
        .add(
          @pbr.StandardMaterial::from_color(
            @color.Color::srgb(0.6F, 0.7F, 0.8F),
          ),
        ),
      ),
      ShowAxes::{  },
      TransformTracking::{
        initial_transform: @transform.Transform::identity(),
        target_transform: random_transform(rng),
        progress: 0.0F,
      },
    ),
  )
  |> ignore

  commands.spawn(
    (
      @mesh.Mesh3d::new(
        meshes.modify(fn(assets) {
          @pbr.add_mesh(
            assets,
            @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
              @math.Vec2::new(20.0F, 20.0F),
            ).build(),
          )
        }),
      ),
      @pbr.MeshMaterial3dTyped::new(
        materials
        .peek()
        .add(
          @pbr.StandardMaterial::from_color(
            @color.Color::srgb(0.1F, 0.1F, 0.1F),
          ),
        ),
      ),
      @transform.Transform::from_xyz(0.0F, -2.0F, 0.0F),
    ),
  )
  |> ignore

  commands.insert_resource(SeededRng::{ rng, })
}

///|
fn random_transform(rng : @example_rng.ChaCha8Rng) -> @transform.Transform {
  @transform.Transform::{
    translation: random_translation(rng),
    rotation: random_rotation(rng),
    scale: random_scale(rng),
  }
}

///|
fn random_translation(rng : @example_rng.ChaCha8Rng) -> @math.Vec3 {
  let x = rng.random_float() * 10.0F - 5.0F
  let y = rng.random_float() * 2.0F - 1.0F
  let z = rng.random_float() * 8.0F - 2.0F
  @math.Vec3::new(x, y, z)
}

///|
fn random_scale(rng : @example_rng.ChaCha8Rng) -> @math.Vec3 {
  let x_factor_log = rng.random_float() * 2.4F - 1.2F
  let y_factor_log = rng.random_float() * 2.4F - 1.2F
  let z_factor_log = rng.random_float() * 2.4F - 1.2F
  @math.Vec3::new(
    @math.pow(2.0F, x_factor_log),
    @math.pow(2.0F, y_factor_log),
    @math.pow(2.0F, z_factor_log),
  )
}

///|
fn random_rotation(rng : @example_rng.ChaCha8Rng) -> @math.Quat {
  let dir = random_direction(rng)
  let angle = rng.random_float() * 2.0F * PI
  @math.Quat::from_axis_angle(dir, angle)
}

///|
fn random_direction(rng : @example_rng.ChaCha8Rng) -> @math.Vec3 {
  let height = rng.random_float() * 2.0F - 1.0F
  let theta = rng.random_float() * 2.0F * PI
  build_direction(height, theta)
}

///|
fn build_direction(height : Float, theta : Float) -> @math.Vec3 {
  let z = height
  let m = @math.sin(@math.acos(z))
  let x = @math.cos(theta) * m
  let y = @math.sin(theta) * m
  @math.Vec3::new(x, y, z)
}

///|
fn vec3_lerp(a : @math.Vec3, b : @math.Vec3, t : Float) -> @math.Vec3 {
  @math.Vec3::new(
    a.x + (b.x - a.x) * t,
    a.y + (b.y - a.y) * t,
    a.z + (b.z - a.z) * t,
  )
}

///|
fn elerp(a : @math.Vec3, b : @math.Vec3, t : Float) -> @math.Vec3 {
  @math.Vec3::new(
    @math.pow(a.x, 1.0F - t) * @math.pow(b.x, t),
    @math.pow(a.y, 1.0F - t) * @math.pow(b.y, t),
    @math.pow(a.z, 1.0F - t) * @math.pow(b.z, t),
  )
}

///|
fn interpolate_transforms(
  a : @transform.Transform,
  b : @transform.Transform,
  t : Float,
) -> @transform.Transform {
  @transform.Transform::{
    translation: vec3_lerp(a.translation, b.translation, t),
    rotation: a.rotation.slerp(b.rotation, t),
    scale: elerp(a.scale, b.scale, t),
  }
}

///|
fn move_cubes(
  query : @ecs.Query[
    (@ecs.Write[@transform.Transform], @ecs.Write[TransformTracking]),
    @ecs.All,
  ],
  time : @app.Res[@time.Time[Unit]],
  seeded_rng : @app.ResMut[SeededRng],
) -> Unit {
  let delta_secs = time.get().delta_secs()
  try! query.view(fn(_entity, item) {
    let (transform_mut, tracking_mut) = item
    let next_transform = tracking_mut.modify(fn(tracking) {
      let transform = interpolate_transforms(
        tracking.initial_transform,
        tracking.target_transform,
        tracking.progress / TRANSITION_DURATION,
      )
      if tracking.progress < TRANSITION_DURATION {
        tracking.progress = tracking.progress + delta_secs
      } else {
        tracking.initial_transform = transform
        tracking.target_transform = seeded_rng.modify(fn(value) {
          random_transform(value.rng)
        })
        tracking.progress = 0.0F
      }
      transform
    })
    transform_mut.set(next_transform)
  })
}

///|
fn draw_axes(
  gizmos : @gizmos.Gizmos[@gizmos.DefaultGizmoConfigGroup],
  query : @ecs.Query[
    (@ecs.Read[@transform.Transform], @ecs.Read[@camera_primitives.Aabb]),
    @ecs.With[ShowAxes],
  ],
) -> Unit {
  try! query.view(fn(_entity, item) {
    let (transform_comp, aabb_comp) = item
    let length = aabb_comp.value().half_size().length()
    gizmos.axes_3d(transform_comp.value(), length)
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param3(@app.Startup, setup)
  .add_systems_param3(@app.Update, move_cubes)
  .add_systems_param2(@app.Update, draw_axes)
  .run()
}
