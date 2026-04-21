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
const FOX_PATH : String = "models/animated/Fox.glb"

///|
const PARTICLE_COUNT : Int = 14

///|
struct StepEvent {
  observer_entity : @core.Entity?
  phase : Float
}

///|
struct AnimationSetup {
  clip_handle : @asset.Handle[@animation.AnimationClip]
  graph_handle : @asset.Handle[@animation.AnimationGraph]
  index : @animation.AnimationNodeIndex
  feet_targets : FoxFeetTargets
  mut events_installed : Bool
}

///|
struct ParticleAssets {
  mesh : @asset.Handle[@pbr.Mesh]
  material : @asset.Handle[@pbr.StandardMaterial]
}

///|
pub struct FoxFeetTargets {
  front_left : @animation.AnimationTargetId
  front_right : @animation.AnimationTargetId
  back_left : @animation.AnimationTargetId
  back_right : @animation.AnimationTargetId
}

///|
struct Particle {
  mut lifetime_timer : @time.Timer
  size : Float
  mut velocity : @math.Vec3
}

///|
let animation_setup_key : @ecs.ResourceKey[AnimationSetup] = @ecs.register_resource(
  debug_name="examples.animation.animated_mesh_events.animation_setup",
)

///|
let particle_assets_key : @ecs.ResourceKey[ParticleAssets] = @ecs.register_resource(
  debug_name="examples.animation.animated_mesh_events.particle_assets",
)

///|
let particle_key : @ecs.ComponentKey[Particle] = @ecs.register_component(
  debug_name="examples.animation.animated_mesh_events.particle",
)

///|
let step_event_key : @ecs.EventKey[StepEvent] = @ecs.register_event(
  debug_name="examples.animation.animated_mesh_events.step_event",
)

///|
pub impl @app.Resource for AnimationSetup with resource() {
  animation_setup_key
}

///|
pub impl @app.Resource for ParticleAssets with resource() {
  particle_assets_key
}

///|
pub impl @ecs.Component for Particle with component() {
  particle_key
}

///|
pub impl @animation.AnimationEvent for StepEvent with animation_event_marker(
  _self,
) {

}

///|
pub impl @ecs.TriggerEvent for StepEvent with observer_event() {
  step_event_key
}

///|
pub impl @ecs.TriggerEvent for StepEvent with observer_entity(self) {
  self.observer_entity
}

///|
pub impl @ecs.TriggerEvent for StepEvent with set_observer_entity(
  event_ref,
  entity,
) {
  StepEvent::{ ..event_ref, observer_entity: Some(entity) }
}

///|
pub impl @ecs.TriggerEvent for StepEvent with auto_propagate(_self) {
  false
}

///|
pub impl @ecs.TriggerEvent for StepEvent with debug_name() {
  "StepEvent"
}

///|
fn StepEvent::new(phase : Float) -> StepEvent {
  { observer_entity: None, phase }
}

///|
impl Default for FoxFeetTargets with default() {
  FoxFeetTargets::{
    front_left: @animation.AnimationTargetId::from_names([
      "root", "_rootJoint", "b_Root_00", "b_Hip_01", "b_Spine01_02", "b_Spine02_03",
      "b_LeftUpperArm_09", "b_LeftForeArm_010", "b_LeftHand_011",
    ]),
    front_right: @animation.AnimationTargetId::from_names([
      "root", "_rootJoint", "b_Root_00", "b_Hip_01", "b_Spine01_02", "b_Spine02_03",
      "b_RightUpperArm_06", "b_RightForeArm_07", "b_RightHand_08",
    ]),
    back_left: @animation.AnimationTargetId::from_names([
      "root", "_rootJoint", "b_Root_00", "b_Hip_01", "b_LeftLeg01_015", "b_LeftLeg02_016",
      "b_LeftFoot01_017", "b_LeftFoot02_018",
    ]),
    back_right: @animation.AnimationTargetId::from_names([
      "root", "_rootJoint", "b_Root_00", "b_Hip_01", "b_RightLeg01_019", "b_RightLeg02_020",
      "b_RightFoot01_021", "b_RightFoot02_022",
    ]),
  }
}

///|
fn install_step_events(
  clip : @animation.AnimationClip,
  feet_targets : FoxFeetTargets,
) -> @animation.AnimationClip {
  clip
  .add_typed_event_to_target(
    feet_targets.front_left,
    0.625F,
    StepEvent::new(0.625F),
  )
  .add_typed_event_to_target(
    feet_targets.front_right,
    0.5F,
    StepEvent::new(0.5F),
  )
  .add_typed_event_to_target(feet_targets.back_left, 0.0F, StepEvent::new(0.0F))
  .add_typed_event_to_target(
    feet_targets.back_right,
    0.125F,
    StepEvent::new(0.125F),
  )
}

///|
fn setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let clip_handle = asset_server.load(
    @gltf.GltfAssetLabel::Animation(2).from_asset(FOX_PATH),
  )
  let (graph, index) = @animation.AnimationGraph::from_clip(clip_handle)
  let graph_handle = @animation.animation_graph_add(graph)
  let feet_targets = FoxFeetTargets::default()

  world.insert_resource(animation_setup_key, AnimationSetup::{
    clip_handle,
    graph_handle,
    index,
    feet_targets,
    events_installed: false,
  })

  let particle_mesh = @pbr.mesh_assets_mut_or_abort().val
    |> @pbr.add_mesh(@math.Sphere::new(0.4F))
  let particle_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white()).with_unlit(true),
  )
  world.insert_resource(particle_assets_key, ParticleAssets::{
    mesh: particle_mesh,
    material: particle_material,
  })

  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(@sprite.Color::white(), 2000.0F),
  )

  ignore(
    @camera.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(100.0F, 100.0F, 150.0F).looking_at(
        @math.Vec3::new(0.0F, 20.0F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ).spawn(world),
  )

  let plane = world.spawn_empty()
  let plane_mesh = @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val
    |> @pbr.add_mesh(@math.Cuboid::new(500000.0F, 0.1F, 500000.0F)),
  )
  let plane_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.3F, 0.5F, 0.3F)),
  )
  ignore(
    try! world
    .entity_mut(plane)
    .insert(
      (
        plane_mesh,
        @pbr.MeshMaterial3d::new(plane_material),
        @transform.Transform::identity(),
      ),
    ),
  )

  let light = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(light)
    .insert(
      (
        @transform.Transform::from_rotation(
          @math.Quat::from_euler(@math.EulerRot::ZYX, 0.0F, 1.0F, -PI / 4.0F),
        ),
        @pbr.DirectionalLight::new(@sprite.Color::white(), 10000.0F, true).with_cascade_shadow_config_builder(
          @pbr.CascadeShadowConfigBuilder::default()
          .with_first_cascade_far_bound(200.0F)
          .with_maximum_distance(400.0F),
        ),
      ),
    ),
  )

  let fox = world.spawn()
  ignore(
    try! world
    .entity_mut(fox)
    .insert_component(
      @scene.SceneRoot::new(
        asset_server.load(@gltf.GltfAssetLabel::Scene(0).from_asset(FOX_PATH)),
      ),
    ),
  )
}

///|
fn setup_scene_once_loaded(
  scene_ready : @ecs.ComponentOn[@ecs.Insert, @scene.SceneInstanceReady],
  commands : @app.Commands,
  animation_setup : @app.ResMut[AnimationSetup],
  players : @ecs.Query[@ecs.Mut[@animation.AnimationPlayer], @ecs.All],
) -> Unit {
  guard (players.get(scene_ready.entity) catch { _ => None })
    is Some(player_mut) else {
    return
  }

  let setup_value = animation_setup.peek()
  if !setup_value.events_installed {
    guard @animation.animation_clip_get(setup_value.clip_handle) is Some(clip) else {
      return
    }
    ignore(
      @animation.animation_clip_set(
        setup_value.clip_handle,
        install_step_events(clip, setup_value.feet_targets),
      ),
    )
    animation_setup.modify(fn(value) { value.events_installed = true })
  }

  let transitions = @animation.AnimationTransitions::new()
  player_mut.modify(fn(player) {
    ignore(transitions.play(player, setup_value.index, 0.0F).repeat())
  })
  commands
  .entity(scene_ready.entity)
  .insert(
    (
      @animation.AnimationGraphHandle::new(setup_value.graph_handle),
      transitions,
    ),
  )
}

///|
fn observe_on_step(
  step_event : @ecs.On[StepEvent],
  particle_assets : @app.Res[ParticleAssets],
  commands : @app.Commands,
  transforms : @ecs.Query[@ecs.Comp[@transform.Transform], @ecs.All],
) -> Unit {
  let event = step_event.event()
  guard step_event.entity() is Some(target_entity) else { return }
  guard (transforms.get(target_entity) catch { _ => None }) is Some(transform) else {
    return
  }
  let translation = transform.value().translation
  for i in 0..<PARTICLE_COUNT {
    let i_float = Float::from_int(i)
    let angle = event.phase * 8.0F +
      i_float * (2.0F * PI / Float::from_int(PARTICLE_COUNT))
    let speed = 8.0F + 0.25F * i_float
    let vertical = 3.0F + 0.1F * i_float
    let size = 0.2F + 0.05F * Float::from_int(i % 5)
    ignore(
      commands.spawn(
        (
          Particle::{
            lifetime_timer: @time.Timer::from_seconds(
              0.2F + 0.03F * i_float,
              @time.TimerMode::Once,
            ),
            size,
            velocity: @math.Vec3::new(
              @math.cos(angle) * speed,
              vertical,
              @math.sin(angle) * speed,
            ),
          },
          @pbr.Mesh3d::new(particle_assets.get().mesh),
          @pbr.MeshMaterial3d::new(particle_assets.get().material),
          @transform.Transform::from_translation(translation).with_scale(
            @math.Vec3::splat(size),
          ),
        ),
      ),
    )
  }
}

///|
fn simulate_particles(
  commands : @app.Commands,
  particles : @ecs.Query[
    (@core.Entity, @ecs.Mut[@transform.Transform], @ecs.Mut[Particle]),
    @ecs.All,
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! particles.view(fn(_entity, entry) {
    let (entity, transform, particle) = entry
    let particle_state = particle.modify(fn(value) {
      value.lifetime_timer = value.lifetime_timer.tick(time.get().delta())
      if value.lifetime_timer.just_finished() {
        None
      } else {
        value.velocity = value.velocity.add(
          @math.Vec3::new(0.0F, -20.0F * delta, 0.0F),
        )
        Some((value.velocity, value.size, value.lifetime_timer.fraction()))
      }
    })
    if particle_state is None {
      commands.entity(entity).despawn()
      return
    }
    guard particle_state is Some((velocity, size, fraction)) else { return }
    transform.modify(fn(value) {
      value.translation = value.translation.add(velocity.mul_scalar(delta))
      value.scale = @math.Vec3::splat(size * (1.0F - fraction))
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .add_component_observer4(setup_scene_once_loaded)
  .add_observer4(observe_on_step)
  .add_systems(@app.Update, @app.system(@app.system_param3(simulate_particles)))
  .run()
}
