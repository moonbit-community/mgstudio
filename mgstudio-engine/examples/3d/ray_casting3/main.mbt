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
priv struct RayState {
  camera : @sprite.Camera
  projection : @pbr.Projection
  transform : @transform.Transform
}

///|
let ray_state : Ref[RayState] = Ref::new({
  camera: @sprite.Camera::default(),
  projection: @pbr.Projection::default(),
  transform: @transform.Transform::identity(),
})

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@rapier_examples.rapier3d_plugins())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(cast_ray))
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  let camera_transform = @transform.Transform::from_xyz(-30.0F, 30.0F, 100.0F).looking_at(
    @math.Vec3::new(0.0F, 10.0F, 0.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  ray_state.val = {
    camera: @sprite.Camera::default(),
    projection: @pbr.Projection::default(),
    transform: camera_transform,
  }
  @rapier_examples.rapier3d_basic_lighting(world)
  @pbr.Camera3dBundle::new(@sprite.Camera::default(), camera_transform).spawn(
    world,
  )
  |> ignore
  ignore(
    @rapier_examples.rapier3d_spawn_ground(
      world,
      @math.Vec3::new(200.1F, 0.1F, 200.1F),
      @math.Vec3::new(0.0F, -0.1F, 0.0F),
    ),
  )

  let num = 8
  let rad = 1.0F
  let shift = rad * 3.0F
  let centerx = shift * Float::from_int(num / 2)
  let centery = shift / 2.0F
  let centerz = shift * Float::from_int(num / 2)
  let mut offset = -Float::from_int(num) * shift * 0.5F
  for j in 0..<20 {
    for i in 0..<num {
      for k in 0..<num {
        let x = Float::from_int(i) * shift - centerx + offset
        let y = Float::from_int(j) * shift + centery + 3.0F
        let z = Float::from_int(k) * shift - centerz + offset
        ignore(
          @rapier_examples.rapier3d_spawn_cuboid(
            world,
            @math.Vec3::new(x, y, z),
            @math.Vec3::splat(rad),
            @rapier_examples.rapier3d_color(i + j + k),
            Some(@physics3d.RigidBody3d::dynamic()),
          ),
        )
      }
    }
    offset -= 0.05F * rad * Float::from_int(num - 1)
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
  @pbr.render3d_camera_viewport_to_world_ray(
    cursor_position,
    ray_state.val.camera,
    ray_state.val.projection,
    ray_state.val.transform,
    @math.IVec2::new(width, height),
    scale_factor,
  )
}

///|
fn cast_ray(world : @ecs.World) -> Unit {
  if !@input.mouse_button_just_pressed(@window.MouseButton::Left) {
    return
  }
  guard @input.mouse_position() is Some(cursor_position) else {
    println("[ray_casting3] cursor is outside the window")
    return
  }
  guard build_cursor_ray(world, cursor_position) is Some(ray) else {
    println("[ray_casting3] unable to compute ray")
    return
  }
  guard @physics3d.get_physics3d_context_resource(world).get() is Some(ctx) else {
    return
  }
  match ctx.cast_ray_entity(ray.0, ray.1, 1000.0F, true) {
    Some(hit) =>
      println("[ray_casting3] hit entity=\{hit.entity.id} toi=\{hit.toi}")
    None => println("[ray_casting3] ray missed")
  }
}
