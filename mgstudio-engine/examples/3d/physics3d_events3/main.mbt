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
/// Adapted line-by-line from:
/// https://github.com/dimforge/bevy_rapier/blob/master/bevy_rapier3d/examples/events3.rs
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup_graphics)
  .add_startup_system(setup_physics)
  .add_system(setup_overlay)
  .add_system(display_events)
  .run()
}

///|
priv struct Events3State {
  mut overlay_font : @asset.Handle[@asset.Font]?
  mut overlay_text : @text.TextHandle?
  mut overlay_spawned : Bool
  mut collision_started : Int
  mut collision_stopped : Int
  mut contact_force_events : Int
  mut max_force : Float
}

///|
let events3_state : Ref[Events3State] = Ref::new({
  overlay_font: None,
  overlay_text: None,
  overlay_spawned: false,
  collision_started: 0,
  collision_stopped: 0,
  contact_force_events: 0,
  max_force: 0.0F,
})

///|
fn events3_panel_text(
  started : Int,
  stopped : Int,
  contact_forces : Int,
  max_force : Float,
) -> String {
  "bevy_rapier events3 (migrated)\n" +
  "Ground: cuboid(4.0, 1.0, 1.0), y = -1.2\n" +
  "Sensor: cuboid(4.0, 1.5, 1.0), y = 5.0\n" +
  "Dynamic: cuboid(0.5, 0.5, 0.5), y = 13.0\n" +
  "Contact threshold: 30.0\n" +
  "Collision Started: " +
  started.to_string() +
  "\n" +
  "Collision Stopped: " +
  stopped.to_string() +
  "\n" +
  "Contact Force Events: " +
  contact_forces.to_string() +
  "\n" +
  "Max Contact Force: " +
  max_force.to_string()
}

///|
fn setup_graphics(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()

  let asset_server = @asset.AssetServer::new()
  events3_state.val.overlay_font = Some(
    asset_server.load_font("fonts/FiraSans-Bold.ttf"),
  )

  let ambient = world.get_global_ambient_light_resource()
  if ambient.get_ref_mut(tick) is Some(ambient_ref) {
    ambient_ref.val = @render3d.GlobalAmbientLight::new(
      @render2d.Color::white(),
      0.45F,
    )
  }

  let point_light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    point_light,
    @render3d.PointLight::new(
      @render2d.Color::white(),
      120000.0F,
      2000.0F,
      false,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(point_light, @math.Transform::from_xyz(22.0F, 28.0F, 24.0F), tick)

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.0F, 0.0F, 25.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn setup_overlay(_world : @ecs_world.World) -> Unit {
  if events3_state.val.overlay_spawned {
    return
  }
  guard events3_state.val.overlay_font is Some(font) else { return }
  if @asset.asset_font_read_bytes(font) is None {
    return
  }
  let overlay = @text.Text2dBundle::new(
      @text.Text2d::new(events3_panel_text(0, 0, 0, 0.0F)),
      @text.TextFont::default().with_font(font).with_font_size(18.0F),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-480.0F, 335.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=40.0F,
      ),
    )
    .with_anchor(@render2d.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(960.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  events3_state.val.overlay_text = Some(overlay)
  events3_state.val.overlay_spawned = true
}

///|
fn setup_physics(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let box_mesh = @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F)

  let ground_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.26F, 0.29F, 0.34F, 1.0F),
    ),
  )
  let sensor_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.15F, 0.75F, 0.85F, 0.35F),
    ),
  )
  let dynamic_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.92F, 0.25F, 0.3F, 1.0F),
    ),
  )

  let ground = @render3d.MeshMaterial3dBundle::new(
    box_mesh,
    @render3d.MeshMaterial3d::new(ground_material),
    @math.Transform::from_xyz(0.0F, -1.2F, 0.0F).with_scale(
      @math.Vec3::new(8.0F, 2.0F, 2.0F),
    ),
  ).spawn(world)
  world
  .get_collider3d_store()
  .insert(
    ground,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::cuboid(4.0F, 1.0F, 1.0F),
    ),
    tick,
  )

  let sensor = @render3d.MeshMaterial3dBundle::new(
    box_mesh,
    @render3d.MeshMaterial3d::new(sensor_material),
    @math.Transform::from_xyz(0.0F, 5.0F, 0.0F).with_scale(
      @math.Vec3::new(8.0F, 3.0F, 2.0F),
    ),
  ).spawn(world)
  world
  .get_collider3d_store()
  .insert(
    sensor,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::cuboid(4.0F, 1.5F, 1.0F),
    ).sensor(true),
    tick,
  )

  let dynamic_cube = @render3d.MeshMaterial3dBundle::new(
    box_mesh,
    @render3d.MeshMaterial3d::new(dynamic_material),
    @math.Transform::from_xyz(0.0F, 13.0F, 0.0F),
  ).spawn(world)
  world
  .get_rigid_body3d_store()
  .insert(dynamic_cube, @physics3d.RigidBody3d::dynamic(), tick)
  world
  .get_collider3d_store()
  .insert(
    dynamic_cube,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::cuboid(0.5F, 0.5F, 0.5F),
    ),
    tick,
  )
  world
  .get_active_events3d_store()
  .insert(
    dynamic_cube,
    @physics3d.ActiveEvents3d::new(
      @collision.ActiveEvents::collision_events().insert(
        @collision.ActiveEvents::contact_force_events(),
      ),
    ),
    tick,
  )
  world
  .get_contact_force_event_threshold3d_store()
  .insert(
    dynamic_cube,
    @physics3d.ContactForceEventThreshold3d::new(30.0F),
    tick,
  )
}

///|
fn display_events(world : @ecs_world.World) -> Unit {
  let events_resource = world.get_physics3d_events_resource()
  if events_resource.get_ref() is Some(events_ref) {
    let events = events_ref.val
    for collision_event in events.collisions {
      match collision_event {
        @physics3d.CollisionEvent3d::Started(_, _, _) =>
          events3_state.val.collision_started = events3_state.val.collision_started +
            1
        @physics3d.CollisionEvent3d::Stopped(_, _, _) =>
          events3_state.val.collision_stopped = events3_state.val.collision_stopped +
            1
      }
    }
    events3_state.val.contact_force_events = events3_state.val.contact_force_events +
      events.contact_forces.length()
    for contact_event in events.contact_forces {
      if contact_event.max_force_magnitude > events3_state.val.max_force {
        events3_state.val.max_force = contact_event.max_force_magnitude
      }
    }
  }

  if events3_state.val.overlay_text is Some(text_handle) {
    @text.text_set_content(
      text_handle,
      events3_panel_text(
        events3_state.val.collision_started,
        events3_state.val.collision_stopped,
        events3_state.val.contact_force_events,
        events3_state.val.max_force,
      ),
    )
  }
}
