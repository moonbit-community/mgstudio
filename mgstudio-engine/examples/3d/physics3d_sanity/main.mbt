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
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(physics3d_sanity_setup)
  .add_system(physics3d_sanity_print)
  .run()
}

///|
priv struct SanityState {
  mut ball : @core.Entity?
}

///|
let state : Ref[SanityState] = Ref::new({ ball: None })

///|
fn physics3d_sanity_setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let cfg_res = @physics3d.get_physics3d_config_resource(world)
  match cfg_res.get_ref_mut(tick) {
    Some(r) =>
      r.val = @physics3d.Physics3dConfig::new(
        @math.Vec3::new(0.0F, -500.0F, 0.0F),
      )
    None => ()
  }
  let floor_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.28F, 0.32F, 0.36F, 1.0F),
    ),
  )
  let floor_bundle = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(640.0F, 640.0F),
    @render3d.MeshMaterial3d::new(floor_material),
    @math.Transform::from_xyz(0.0F, -200.0F, 0.0F),
  )
  let floor = floor_bundle.spawn(world)
  let rb_store = @physics3d.get_rigid_body3d_store(world)
  let col_store = @physics3d.get_collider3d_store(world)
  rb_store.insert(floor, @physics3d.RigidBody3d::fixed(), tick)
  col_store.insert(
    floor,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::cuboid(320.0F, 16.0F, 16.0F),
    ),
    tick,
  )

  let ball_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.9F, 0.2F, 0.2F, 1.0F),
    ),
  )
  let ball_bundle = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(24.0F, 24.0F, 24.0F),
    @render3d.MeshMaterial3d::new(ball_material),
    @math.Transform::from_xyz(0.0F, 200.0F, 0.0F),
  )
  let ball = ball_bundle.spawn(world)
  rb_store.insert(ball, @physics3d.RigidBody3d::dynamic(), tick)
  col_store.insert(
    ball,
    @physics3d.Collider3d::new(@physics3d.ColliderShape3d::ball(12.0F)),
    tick,
  )
  state.val.ball = Some(ball)

  world.insert_resource(
    @render3d.ecs_key_global_ambient_light,
    @render3d.GlobalAmbientLight::new(
      @render2d.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
      0.45F,
    ),
  )
  let light = world.spawn_empty()
  world
  .component(@render3d.ecs_key_point_light)
  .insert(
    light,
    @render3d.PointLight::new(
      @render2d.Color::white(),
      100000.0F,
      2000.0F,
      false,
    ),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(light, @math.Transform::from_xyz(220.0F, 360.0F, 220.0F), tick)

  let camera = @render2d.Camera::default()
  @render3d.Camera3dBundle::new(
    camera,
    @math.Transform::from_xyz(0.0F, 120.0F, 420.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn physics3d_sanity_print(world : @ecs.World) -> Unit {
  match state.val.ball {
    None => ()
    Some(ball) => {
      let transform_store = world.component(@math.ecs_key_transform)
      match transform_store.get(ball) {
        None => ()
        Some(t) => println("ball.y=\{t.translation.y}")
      }
      let ev_res = @physics3d.get_physics3d_events_resource(world)
      match ev_res.get_ref() {
        Some(r) =>
          for ev in r.val.collisions {
            match ev {
              @physics3d.CollisionEvent3d::Started(a, b, sensor) =>
                println("Collision Started: \{a.id}, \{b.id}, sensor=\{sensor}")
              @physics3d.CollisionEvent3d::Stopped(a, b, sensor) =>
                println("Collision Stopped: \{a.id}, \{b.id}, sensor=\{sensor}")
            }
          }
        None => ()
      }
    }
  }
}
