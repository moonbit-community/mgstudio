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
const GLTF_PATH : String = "models/morph_targets/morph_targets.gltf"

///|
struct AnimationToPlay {
  graph_handle : @asset.Handle[@animation.AnimationGraph]
  index : @animation.AnimationNodeIndex
}

///|
struct MorphTargetAssetState {
  primitive_handle : @asset.Handle[@mesh.Mesh]
  mut named : Bool
}

///|
let animation_to_play_key : @ecs.ComponentKey[AnimationToPlay] = @ecs.register_component(
  debug_name="examples.animation.morph_targets.AnimationToPlay",
)

///|
let morph_target_asset_state_key : @ecs.ResourceKey[MorphTargetAssetState] = @ecs.register_resource(
  debug_name="examples.animation.morph_targets.MorphTargetAssetState",
)

///|
pub impl @ecs.Component for AnimationToPlay with component() {
  animation_to_play_key
}

///|
pub impl @app.Resource for MorphTargetAssetState with resource() {
  morph_target_asset_state_key
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let primitive_handle = asset_server
    .get()
    .load(@gltf.GltfAssetLabel::Primitive(0, 0).from_asset(GLTF_PATH))
  let (graph, index) = @animation.AnimationGraph::from_clip(
    asset_server
    .get()
    .load(@gltf.GltfAssetLabel::Animation(0).from_asset(GLTF_PATH)),
  )
  let graph_handle = @animation.animation_graph_add(graph)

  commands.insert_resource(MorphTargetAssetState::{
    primitive_handle,
    named: false,
  })
  commands.insert_resource(
    @pbr.GlobalAmbientLight::new(@sprite.Color::white(), 800.0F),
  )

  ignore(
    commands.spawn_bundle(
      @camera.Camera3dBundle::new(
        @sprite.Camera::default(),
        @transform.Transform::from_xyz(0.0F, 0.0F, 6.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @transform.Transform::from_rotation(
          @math.Quat::from_euler(@math.EulerRot::ZYX, 0.0F, 0.9F, -0.6F),
        ),
        @pbr.DirectionalLight::new(@sprite.Color::white(), 6000.0F, true),
      ),
    ),
  )

  let root = commands.spawn(
    (
      AnimationToPlay::{ graph_handle, index },
      @scene.SceneRoot::new(
        asset_server
        .get()
        .load(@gltf.GltfAssetLabel::Scene(0).from_asset(GLTF_PATH)),
      ),
      @transform.Transform::identity().with_scale(@math.Vec3::splat(1.8F)),
    ),
  )
  ignore(commands.entity(root).observe4(play_animation_when_ready))
}

///|
fn play_animation_when_ready(
  scene_ready : @ecs.On[@scene.SceneInstanceReady],
  commands : @app.Commands,
  animations_to_play : @ecs.Query[@ecs.Comp[AnimationToPlay], @ecs.All],
  players : @ecs.Query[@ecs.Mut[@animation.AnimationPlayer], @ecs.All],
) -> Unit {
  guard scene_ready.entity() is Some(scene_entity) else { return }
  guard (animations_to_play.get(scene_entity) catch { _ => None })
    is Some(animation_to_play) else {
    return
  }
  guard (players.get(scene_entity) catch { _ => None }) is Some(player_mut) else {
    return
  }
  player_mut.modify(fn(player) {
    player.play(animation_to_play.value().index).repeat() |> ignore
  })
  commands
  .entity(scene_entity)
  .insert_component(
    @animation.AnimationGraphHandle::new(animation_to_play.value().graph_handle),
  )
}

///|
fn name_morph_targets(
  state : @app.ResMut[MorphTargetAssetState],
  events : @ecs.MessageReader[@asset.AssetEvent[@mesh.Mesh]],
  meshes : @app.Res[@asset.Assets[@mesh.Mesh]],
) -> Unit {
  if state.peek().named {
    return
  }
  for event in (try! events.read()) {
    let handle = match event {
      Added(handle) => Some(handle)
      LoadedWithDependencies(handle) => Some(handle)
      _ => None
    }
    guard handle is Some(mesh_handle) else { continue }
    if mesh_handle.id() != state.peek().primitive_handle.id() {
      continue
    }
    guard meshes.get().get(mesh_handle) is Some(mesh_asset) else { continue }
    guard mesh_asset.morph_target_names() is Some(names) else { continue }
    let joined_names = names.join(", ")
    println("Morph target names: \{joined_names}")
    state.modify(fn(value) { value.named = true })
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param3(name_morph_targets)))
  .run()
}
