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
const GLTF_PATH : String = "models/animated/Fox.glb"

///|
struct AnimationToPlay {
  graph_handle : @asset.Handle[@animation.AnimationGraph]
  index : @animation.AnimationNodeIndex
}

///|
let animation_to_play_key : @ecs.ComponentKey[AnimationToPlay] = @ecs.register_component(
  debug_name="examples.gltf.gltf_extension_animation_graph.AnimationToPlay",
)

///|
pub impl @ecs.Component for AnimationToPlay with component() {
  animation_to_play_key
}

///|
let extension_animation_clips : Array[
  (String, @asset.Handle[@animation.AnimationClip]),
] = []

///|
fn set_extension_animation_clip(
  asset_path : String,
  handle : @asset.Handle[@animation.AnimationClip],
) -> Unit {
  for i in 0..<extension_animation_clips.length() {
    if extension_animation_clips[i].0 == asset_path {
      extension_animation_clips[i] = (asset_path, handle)
      return
    }
  }
  extension_animation_clips.push((asset_path, handle))
}

///|
fn get_extension_animation_clip(
  asset_path : String,
) -> @asset.Handle[@animation.AnimationClip]? {
  for entry in extension_animation_clips {
    if entry.0 == asset_path {
      return Some(entry.1)
    }
  }
  None
}

///|
fn collect_extension_animations(
  asset_path : String,
  _animations : Array[@asset.Handle[@animation.AnimationClip]],
  named_animations : Array[(String, @asset.Handle[@animation.AnimationClip])],
  _animation_roots : Array[Int],
) -> Unit {
  if asset_path != GLTF_PATH {
    return
  }
  for i in 0..<named_animations.length() {
    let entry = named_animations[i]
    if entry.0 == "Walk" {
      set_extension_animation_clip(asset_path, entry.1)
      return
    }
  }
  if named_animations.length() > 0 {
    set_extension_animation_clip(asset_path, named_animations[0].1)
  }
}

///|
fn attach_extension_animation_graph(
  asset_path : String,
  _scene_index : Int,
  root_entity : @core.Entity,
  world : @ecs.World,
) -> Unit {
  if asset_path != GLTF_PATH {
    return
  }
  guard get_extension_animation_clip(asset_path) is Some(handle) else { return }
  let graph_and_index = @animation.AnimationGraph::from_clip(handle)
  let graph = graph_and_index.0
  let index = graph_and_index.1
  let graph_handle = @animation.animation_graph_add(graph)
  ignore(
    try! world
    .entity_mut(root_entity)
    .insert_component(AnimationToPlay::{ graph_handle, index }),
  )
}

///|
fn setup_environment(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  @gltf_loader_extensions.gltf_clear_extension_handlers()
  extension_animation_clips.clear()
  @gltf_loader_extensions.gltf_register_extension_handler(
    @gltf.GltfExtensionHandler::new(
      on_animations_collected=Some(collect_extension_animations),
      on_scene_completed=Some(attach_extension_animation_graph),
    ),
  )

  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(@sprite.Color::white(), 2000.0F),
  )

  ignore(
    @pbr.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(100.0F, 100.0F, 150.0F).looking_at(
        @math.Vec3::new(0.0F, 20.0F, 0.0F),
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
        @transform.Transform::from_rotation(
          @math.Quat::from_euler(@math.EulerRot::ZYX, 0.0F, 1.0F, -0.7853982F),
        ),
        @pbr.DirectionalLight::new(@sprite.Color::white(), 10000.0F, true),
      ),
    ),
  )

  let root = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(root)
    .insert_component(
      @scene.SceneRoot::new(
        asset_server.load(@gltf.GltfAssetLabel::Scene(0).from_asset(GLTF_PATH)),
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
  guard (animations_to_play.get(scene_ready.entity) catch { _ => None })
    is Some(animation_to_play) else {
    return
  }
  guard (players.get(scene_ready.entity) catch { _ => None })
    is Some(player_mut) else {
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
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup_environment))
  .add_component_observer4(play_animation_when_ready)
  .run()
}
