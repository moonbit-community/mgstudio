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
const MORPH_SCENE_ASSET : String = "models/morph_targets/morph_targets.gltf"

///|
struct AnimationToPlay {
  graph_handle : @asset.Handle[@animation.AnimationGraph]
  index : @animation.AnimationNodeIndex
}

///|
struct MorphAssetState {
  primitive_handle : @asset.Handle[@mesh.Mesh]
  mut printed : Bool
}

///|
let animation_to_play_key : @ecs.ComponentKey[AnimationToPlay] = @ecs.register_component(
  debug_name="examples.tools.scene_viewer.morph_viewer_plugin.AnimationToPlay",
)

///|
let morph_asset_state_key : @ecs.ResourceKey[MorphAssetState] = @ecs.register_resource(
  debug_name="examples.tools.scene_viewer.morph_viewer_plugin.MorphAssetState",
)

///|
pub impl @ecs.Component for AnimationToPlay with component() {
  animation_to_play_key
}

///|
impl @app.Resource for MorphAssetState with resource() {
  morph_asset_state_key
}

///|
fn setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let primitive_handle = asset_server.load(
    @gltf.GltfAssetLabel::Primitive(0, 0).from_asset(MORPH_SCENE_ASSET),
  )
  let (graph, index) = @animation.AnimationGraph::from_clip(
    asset_server.load(
      @gltf.GltfAssetLabel::Animation(0).from_asset(MORPH_SCENE_ASSET),
    ),
  )
  let graph_handle = @animation.animation_graph_add(graph)
  world.insert_resource(morph_asset_state_key, MorphAssetState::{
    primitive_handle,
    printed: false,
  })
  ignore(
    @pbr.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(0.0F, 0.0F, 6.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ).spawn(world),
  )
  let light = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(light)
    .insert(
      (
        @pbr.DirectionalLight::new(@sprite.Color::white(), 7000.0F, true),
        @transform.Transform::from_xyz(2.5F, 5.0F, 2.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
  let root = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(root)
    .insert(
      (
        AnimationToPlay::{ graph_handle, index },
        @scene.SceneRoot::new(
          asset_server.load(
            @gltf.GltfAssetLabel::Scene(0).from_asset(MORPH_SCENE_ASSET),
          ),
        ),
        @transform.Transform::identity().with_scale(@math.Vec3::splat(1.8F)),
      ),
    ),
  )
}

///|
fn play_animation_when_ready(
  scene_ready : @ecs.ComponentOn[@ecs.Insert, @scene.SceneInstanceReady],
  commands : @app.Commands,
  animations_to_play : @ecs.Query[@ecs.Comp[AnimationToPlay], @ecs.All],
  players : @ecs.Query[@ecs.Mut[@animation.AnimationPlayer], @ecs.All],
) -> Unit {
  guard (try! animations_to_play.get(scene_ready.entity))
    is Some(animation_to_play) else {
    return
  }
  guard (try! players.get(scene_ready.entity)) is Some(player_mut) else {
    return
  }
  player_mut.get_ref().val.play(animation_to_play.value().index).repeat()
  |> ignore
  commands
  .entity(scene_ready.entity)
  .insert_component(
    @animation.AnimationGraphHandle::new(animation_to_play.value().graph_handle),
  )
}

///|
fn print_morph_target_names(
  state : @app.ResMut[MorphAssetState],
  events : @ecs.MessageReader[@asset.AssetEvent[@mesh.Mesh]],
  meshes : @app.Res[@asset.Assets[@mesh.Mesh]],
) -> Unit {
  if state.get_ref().val.printed {
    return
  }
  for event in (try! events.read()) {
    let handle = match event {
      Added(handle) => Some(handle)
      LoadedWithDependencies(handle) => Some(handle)
      _ => None
    }
    guard handle is Some(mesh_handle) else { continue }
    if mesh_handle.id() != state.get_ref().val.primitive_handle.id() {
      continue
    }
    guard meshes.get().get(mesh_handle) is Some(mesh_asset) else { continue }
    guard mesh_asset.morph_target_names() is Some(names) else { continue }
    println("Morph targets: " + names.join(", "))
    state.get_ref().val.printed = true
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(setup))
  .add_component_observer4(play_animation_when_ready)
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(print_morph_target_names)),
  )
  .run()
}
