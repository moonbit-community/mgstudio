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
const FOX_COUNT : Int = 1000

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
  mut speed : Float
  mut moving : Bool
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
  { speed: 2.0F, moving: true }
}

///|
struct FoxMotion {
  radius : Float
  base_angle : Float
  direction : Float
}

///|
let fox_motion_key : @ecs.ComponentKey[FoxMotion] = @ecs.register_component(
  debug_name="examples.stress_tests.many_foxes.FoxMotion",
)

///|
pub impl @ecs.Component for FoxMotion with component() {
  fox_motion_key
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
  let mut foxes_remaining = FOX_COUNT
  let mut outer_radius = RING_SPACING
  while foxes_remaining > 0 {
    let radius = RING_SPACING + float_from_int(ring_index) * RING_SPACING
    outer_radius = radius
    let circumference = 6.283185307179586F * radius
    let estimated = max_int((circumference / FOX_SPACING).to_int(), 1)
    let foxes_in_ring = min_int(estimated, foxes_remaining)
    let direction = if ring_index % 2 == 0 { 1.0F } else { -1.0F }
    for fox_i in 0..<foxes_in_ring {
      let angle = float_from_int(fox_i) /
        float_from_int(foxes_in_ring) *
        6.283185307179586F
      let x = @math.cos(angle) * radius
      let z = @math.sin(angle) * radius
      let facing = if direction > 0.0F {
        3.141592653589793F - angle
      } else {
        -angle
      }
      let parent = commands.spawn(
        (
          @transform.Transform::from_xyz(x, 0.0F, z).with_rotation(
            @math.Quat::from_rotation_y(facing),
          ),
          FoxMotion::{ radius, base_angle: angle, direction },
        ),
      )
      ignore(
        commands.spawn(
          (
            @hierarchy.Parent::new(parent),
            @scene.SceneRoot::new(fox_scene),
            @transform.Transform::identity().with_scale(
              @math.Vec3::splat(FOX_SCALE),
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
fn setup_scene_once_loaded(
  scene_ready : @ecs.ComponentOn[@ecs.Insert, @scene.SceneInstanceReady],
  commands : @app.Commands,
  animations : @app.Res[FoxAnimations],
  players : @ecs.Query[@ecs.Mut[@animation.AnimationPlayer], @ecs.All],
) -> Unit {
  guard (try! players.get(scene_ready.entity)) is Some(player_mut) else {
    return
  }
  let player_ref = player_mut.get_ref()
  player_ref.val.play(animations.get().animation).repeat() |> ignore
  commands
  .entity(scene_ready.entity)
  .insert_component(
    @animation.AnimationGraphHandle::new(animations.get().graph_handle),
  )
}

///|
fn keyboard_control(foxes : @app.ResMut[Foxes]) -> Unit {
  let foxes_ref = foxes.get_ref()
  if @input.key_just_pressed(@input_events.KeyCode::Space) {
    foxes_ref.val.moving = !foxes_ref.val.moving
  }
  if @input.key_just_pressed(@input_events.KeyCode::ArrowUp) {
    foxes_ref.val.speed *= 1.25F
  }
  if @input.key_just_pressed(@input_events.KeyCode::ArrowDown) {
    foxes_ref.val.speed *= 0.8F
  }
}

///|
fn update_foxes(
  time : @app.Res[@time.Time[Unit]],
  foxes : @app.Res[Foxes],
  motions : @ecs.Query[
    (@ecs.Comp[FoxMotion], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  if !foxes.get().moving {
    return
  }
  let t = time.get().elapsed_secs() * foxes.get().speed
  try! motions.for_each(fn(_entity, data) {
    let (motion, transform) = data
    let motion_value = motion.value()
    let angle = motion_value.base_angle +
      t * motion_value.direction / motion_value.radius
    let x = @math.cos(angle) * motion_value.radius
    let z = @math.sin(angle) * motion_value.radius
    let facing = if motion_value.direction > 0.0F {
      3.141592653589793F - angle
    } else {
      -angle
    }
    let transform_ref = transform.get_ref()
    transform_ref.val.translation = @math.Vec3::new(x, 0.0F, z)
    transform_ref.val.rotation = @math.Quat::from_rotation_y(facing)
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(Foxes::default())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(
    [
      ..@mgstudio.default_plugins(),
      @diagnostic.frame_time_diagnostics_plugin,
      @diagnostic.log_diagnostics_plugin,
    ],
  )
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_component_observer4(setup_scene_once_loaded)
  .add_systems(@app.Update, @app.system(@app.system_param(keyboard_control)))
  .add_systems(@app.Update, @app.system(@app.system_param3(update_foxes)))
  .run()
}
