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
priv struct PickState {
  camera : @sprite.Camera
  projection : @camera.Projection
  transform : @transform.Transform
}

///|
let pick_state : Ref[PickState] = Ref::new({
  camera: @sprite.Camera::default(),
  projection: @camera.Projection::default(),
  transform: @transform.Transform::identity(),
})

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@rapier_examples.rapier3d_plugins())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(pick))
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  let camera_transform = @transform.Transform::from_xyz(-2.5F, 4.5F, 9.0F).looking_at(
    @math.Vec3::zero(),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  pick_state.val = {
    camera: @sprite.Camera::default(),
    projection: @camera.Projection::default(),
    transform: camera_transform,
  }
  @rapier_examples.rapier3d_basic_lighting(world)
  @camera.Camera3dBundle::new(@sprite.Camera::default(), camera_transform).spawn(
    world,
  )
  |> ignore
  ignore(
    @rapier_examples.rapier3d_spawn_ground(
      world,
      @math.Vec3::new(3.1F, 0.1F, 3.1F),
      @math.Vec3::new(0.0F, -0.1F, 0.0F),
    ),
  )
  for i in 0..<12 {
    let x = -2.0F + Float::from_int(i % 4) * 1.2F
    let y = 0.5F + Float::from_int(i / 4) * 1.2F
    let z = Float::from_int(i / 4) * 0.8F - 1.5F
    ignore(
      @rapier_examples.rapier3d_spawn_cuboid(
        world,
        @math.Vec3::new(x, y + 0.4F * Float::from_int(i / 4), z),
        @math.Vec3::new(0.25F, 0.25F, 0.25F),
        @rapier_examples.rapier3d_color(i),
        Some(@physics3d.RigidBody3d::dynamic()),
      ),
    )
  }
}

///|
fn build_cursor_ray(
  world : @ecs.World,
  cursor_position : @math.Vec2,
) -> (@math.Vec3, @math.Vec3)? {
  let width = @window.window_physical_width_for(
    world,
    @window.WindowRef::Primary,
  )
  let height = @window.window_physical_height_for(
    world,
    @window.WindowRef::Primary,
  )
  let scale_factor = @window.window_scale_factor_for(
    world,
    @window.WindowRef::Primary,
  )
  @camera.camera_viewport_to_world_ray(
    cursor_position,
    pick_state.val.camera,
    pick_state.val.projection,
    pick_state.val.transform,
    @math.IVec2::new(width, height),
    scale_factor,
  )
}

///|
fn pick(world : @ecs.World) -> Unit {
  if !@input.mouse_button_just_pressed(@window.MouseButton::Left) {
    return
  }
  guard @input.mouse_position() is Some(cursor_position) else { return }
  guard build_cursor_ray(world, cursor_position) is Some(ray) else { return }
  guard @physics3d.get_physics3d_context_resource(world).get() is Some(ctx) else {
    return
  }
  match ctx.cast_ray_entity(ray.0, ray.1, 1000.0F, true) {
    Some(hit) => {
      let impulse = @physics3d.ExternalImpulse3d::new(
        ray.1.mul_scalar(4.0F),
        @math.Vec3::zero(),
      )
      try! world.set_by_key(
        hit.entity,
        @physics3d.ecs_key_external_impulse3d,
        impulse,
      )
      println("[picking3] picked entity=\{hit.entity.id}")
    }
    None => println("[picking3] nothing picked")
  }
}
