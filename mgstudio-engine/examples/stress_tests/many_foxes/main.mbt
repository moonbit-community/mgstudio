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
const FOX_PATH : String = "models/animated/Fox.glb"

///|
const DEFAULT_FOX_COUNT : Int = 1000

///|
const FOX_SPACING : Float = 2.0F

///|
const RING_SPACING : Float = 2.0F

///|
const FOX_SCALE : Float = 0.01F

///|
struct FoxAnimations {
  graph_handle : @asset.Handle[@animation.AnimationGraph]
  animation : @animation.AnimationNodeIndex
}

///|
let fox_animations_key : @ecs.ResourceKey[FoxAnimations] = @ecs.register_resource(
  debug_name="examples.stress_tests.many_foxes.FoxAnimations",
)

///|
impl @app.Resource for FoxAnimations with resource() {
  fox_animations_key
}

///|
struct Foxes {
  count : Int
  mut speed : Float
  mut moving : Bool
  sync : Bool
}

///|
let foxes_key : @ecs.ResourceKey[Foxes] = @ecs.register_resource(
  debug_name="examples.stress_tests.many_foxes.Foxes",
)

///|
impl @app.Resource for Foxes with resource() {
  foxes_key
}

///|
fn Foxes::default() -> Foxes {
  { count: DEFAULT_FOX_COUNT, speed: 2.0F, moving: true, sync: false }
}

///|
struct Args {
  mut sync : Bool
  mut count : Int
}

///|
fn parse_args() -> Args {
  let args = Args::{ sync: false, count: DEFAULT_FOX_COUNT }
  for arg in @env.args() {
    if arg == "--sync" {
      args.sync = true
      continue
    }
    if arg.has_prefix("--count=") {
      let value_text = arg[8:]
      try {
        let parsed = @string.parse_int(value_text[:], base=10)
        if parsed > 0 {
          args.count = parsed
        }
      } catch {
        _ => ()
      }
      continue
    }
  }
  args
}

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::default()
  window.present_mode = @window.PresentMode::AutoNoVsync
  window.resolution = @window.WindowResolution::new(1920, 1080).with_scale_factor_override(
    1.0F,
  )
  window
}

///|
struct Ring {
  radius : Float
}

///|
let ring_key : @ecs.ComponentKey[Ring] = @ecs.register_component(
  debug_name="examples.stress_tests.many_foxes.Ring",
)

///|
pub impl @ecs.Component for Ring with component() {
  ring_key
}

///|
struct RotationDirection {
  sign : Float
}

///|
let rotation_direction_key : @ecs.ComponentKey[RotationDirection] = @ecs.register_component(
  debug_name="examples.stress_tests.many_foxes.RotationDirection",
)

///|
pub impl @ecs.Component for RotationDirection with component() {
  rotation_direction_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn min_int(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn max_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  foxes : @app.Res[Foxes],
) -> Unit {
  let (graph, animation) = @animation.AnimationGraph::from_clip(
    asset_server
    .get()
    .load(@gltf.GltfAssetLabel::Animation(2).from_asset(FOX_PATH)),
  )
  commands.insert_resource(FoxAnimations::{
    graph_handle: @animation.animation_graph_add(graph),
    animation,
  })

  let fox_scene = asset_server
    .get()
    .load(@gltf.GltfAssetLabel::Scene(0).from_asset(FOX_PATH))

  let mut ring_index = 0
  let mut foxes_remaining = foxes.get().count
  let mut outer_radius = RING_SPACING
  while foxes_remaining > 0 {
    let radius = RING_SPACING + float_from_int(ring_index) * RING_SPACING
    outer_radius = radius
    let (base_rotation, direction_sign) = if ring_index % 2 == 0 {
      (@math.Quat::from_rotation_y(3.141592653589793F), 1.0F)
    } else {
      (@math.Quat::identity(), -1.0F)
    }
    let ring_parent = commands.spawn(
      (
        @transform.Transform::default(),
        @visibility.Visibility::Inherited,
        RotationDirection::{ sign: direction_sign },
        Ring::{ radius, },
      ),
    )
    let circumference = 6.283185307179586F * radius
    let estimated = max_int((circumference / FOX_SPACING).to_int(), 1)
    let foxes_in_ring = min_int(estimated, foxes_remaining)
    let fox_spacing_angle = circumference /
      (float_from_int(foxes_in_ring) * radius)
    for fox_i in 0..<foxes_in_ring {
      let angle = float_from_int(fox_i) * fox_spacing_angle
      let x = @math.cos(angle) * radius
      let z = @math.sin(angle) * radius
      ignore(
        commands.spawn(
          (
            @hierarchy.Parent::new(ring_parent),
            @scene.SceneRoot::new(fox_scene),
            @transform.Transform::from_xyz(x, 0.0F, z)
            .with_scale(@math.Vec3::splat(FOX_SCALE))
            .with_rotation(
              base_rotation.mul(@math.Quat::from_rotation_y(0.0F - angle)),
            ),
          ),
        ),
      )
    }
    foxes_remaining -= foxes_in_ring
    ring_index += 1
  }

  let zoom = 0.8F
  let camera_translation = @math.Vec3::new(
    outer_radius * 1.25F * zoom,
    outer_radius * 0.5F * zoom,
    outer_radius * 1.5F * zoom,
  )
  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @transform.Transform::from_translation(camera_translation).looking_at(
          @math.Vec3::new(
            camera_translation.x * 0.2F,
            0.0F,
            camera_translation.z * 0.2F,
          ),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(
          @pbr.mesh_assets_mut_or_abort().val
          |> @pbr.add_mesh(@math.Cuboid::new(5000.0F, 0.1F, 5000.0F)),
        ),
        @pbr.MeshMaterial3d::new(
          @pbr.standard_material_add(
            @pbr.StandardMaterial::from_color(
              @sprite.Color::srgb(0.3F, 0.5F, 0.3F),
            ),
          ),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(@sprite.Color::white(), 10000.0F, true),
        @transform.Transform::from_rotation(
          @math.Quat::from_euler(@math.EulerRot::ZYX, 0.0F, 1.0F, -0.75F),
        ),
      ),
    ),
  )
}

///|
fn visit_descendants(
  world : @ecs.World,
  children_state : @ecs.QueryState[@ecs.Comp[@hierarchy.Children], @ecs.All],
  entity : @core.Entity,
  f : (@core.Entity) -> Unit,
) -> Unit raise {
  guard children_state.get(world, entity) is Some(children_comp) else { return }
  for child in children_comp.value().entities() {
    f(child)
    visit_descendants(world, children_state, child, f)
  }
}

///|
fn setup_scene_once_loaded(
  scene_ready : @ecs.ComponentOn[@ecs.Insert, @scene.SceneInstanceReady],
  commands : @app.Commands,
  animations : @app.Res[FoxAnimations],
  foxes : @app.Res[Foxes],
) -> Unit {
  let scene_entity = scene_ready.entity
  let animation_node = animations.get().animation
  let graph_handle = animations.get().graph_handle
  let sync = foxes.get().sync
  commands.queue(fn(world : @ecs.World) {
    let children_state : @ecs.QueryState[
      @ecs.Comp[@hierarchy.Children],
      @ecs.All,
    ] = world.query()
    let players_state : @ecs.QueryState[
      @ecs.Mut[@animation.AnimationPlayer],
      @ecs.All,
    ] = world.query()
    try! visit_descendants(world, children_state, scene_entity, fn(descendant) {
      guard (try! players_state.get(world, descendant)) is Some(player_mut) else {
        return
      }
      let player_ref = player_mut.get_ref()
      let active = player_ref.val.play(animation_node).repeat()
      if !sync {
        active.seek_to(float_from_int(scene_entity.id) / 10.0F) |> ignore
      }
      try! (world
      .entity_mut(descendant)
      .insert(
        (
          @animation.AnimationGraphHandle::new(graph_handle),
          @animation.AnimationTransitions::new(),
        ),
      )
      |> ignore)
    })
  })
}

///|
fn keyboard_animation_control(
  foxes : @app.ResMut[Foxes],
  players : @ecs.Query[@ecs.Mut[@animation.AnimationPlayer], @ecs.All],
) -> Unit {
  let foxes_ref = foxes.get_ref()
  let space = @input.key_just_pressed(@input_events.KeyCode::Space)
  let up = @input.key_just_pressed(@input_events.KeyCode::ArrowUp)
  let down = @input.key_just_pressed(@input_events.KeyCode::ArrowDown)
  let left = @input.key_just_pressed(@input_events.KeyCode::ArrowLeft)
  let right = @input.key_just_pressed(@input_events.KeyCode::ArrowRight)

  if space {
    foxes_ref.val.moving = !foxes_ref.val.moving
  }
  if up {
    foxes_ref.val.speed *= 1.25F
  }
  if down {
    foxes_ref.val.speed *= 0.8F
  }
  try! players.for_each(fn(_entity, player_mut) {
    let player_ref = player_mut.get_ref()
    if space {
      if player_ref.val.all_paused() {
        player_ref.val.resume_all() |> ignore
      } else {
        player_ref.val.pause_all() |> ignore
      }
    }
    if up {
      player_ref.val.adjust_speeds(1.25F) |> ignore
    }
    if down {
      player_ref.val.adjust_speeds(0.8F) |> ignore
    }
    if left {
      player_ref.val.seek_all_by(-0.1F) |> ignore
    }
    if right {
      player_ref.val.seek_all_by(0.1F) |> ignore
    }
  })
}

///|
fn update_fox_rings(
  time : @app.Res[@time.Time[Unit]],
  foxes : @app.Res[Foxes],
  motions : @ecs.Query[
    (
      @ecs.Comp[Ring],
      @ecs.Comp[RotationDirection],
      @ecs.Mut[@transform.Transform],
    ),
    @ecs.All,
  ],
) -> Unit {
  if !foxes.get().moving {
    return
  }
  let dt = time.get().delta_secs()
  try! motions.for_each(fn(_entity, data) {
    let (ring, direction, transform) = data
    let transform_ref = transform.get_ref()
    let angular_velocity = foxes.get().speed / ring.value().radius
    transform_ref.val.rotate_y(direction.value().sign * angular_velocity * dt)
  })
}

///|
fn main {
  let args = parse_args()
  @app.App::new(@ecs.World::new())
  .insert_resource(Foxes::{
    ..Foxes::default(),
    count: args.count,
    sync: args.sync,
  })
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugin_group(fn() {
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(configured_window()),
      primary_cursor_options: None,
      exit_condition: @window.ExitCondition::OnAllClosed,
      close_when_requested: true,
    })
  })
  .add_plugin(@diagnostic.frame_time_diagnostics_plugin)
  .add_plugin(@diagnostic.log_diagnostics_plugin)
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_component_observer4(setup_scene_once_loaded)
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(keyboard_animation_control)),
  )
  .add_systems(@app.Update, @app.system(@app.system_param3(update_fox_rings)))
  .run()
}
