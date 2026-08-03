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
const GLTF_PATH : String = "models/animated/MorphStressTest.gltf"

///|
struct AnimationToPlay {
  graph_handle : @asset.Handle[@animation.AnimationGraph]
  index : @animation.AnimationNodeIndex
}

///|
let animation_to_play_key : @ecs.ComponentKey[AnimationToPlay] = @ecs.register_component(
  debug_name="examples.animation.morph_targets.AnimationToPlay",
)

///|
pub impl @ecs.Component for AnimationToPlay with fn component() {
  animation_to_play_key
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let (graph, index) = @animation.AnimationGraph::from_clip(
    asset_server
    .get()
    .load(@gltf.GltfAssetLabel::Animation(2).from_asset(GLTF_PATH)),
  )
  let graph_handle = @animation.animation_graph_add(graph)

  commands.insert_resource(
    @pbr.GlobalAmbientLight::new(@color.Color::white(), 150.0F),
  )

  ignore(
    commands.spawn(
      @pbr.Camera3dBundle::new(
        Camera(),
        @transform.Transform::from_xyz(3.0F, 2.1F, 10.2F).looking_at(
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
          @math.Quat::from_euler(ZYX, PI / 2.0F, 0.0F, 0.0F),
        ),
        @pbr.DirectionalLight::DirectionalLight(),
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
    ),
  )
  ignore(commands.entity(root).observe(play_animation_when_ready))
}

///|
fn visit_descendants(
  world : @ecs.World,
  entity : @core.Entity,
  f : (@core.Entity) -> Unit,
) -> Unit {
  match (try! world.get_by_key(entity, @hierarchy.ecs_key_children)) {
    Some(children) =>
      for child in children.entities() {
        f(child)
        visit_descendants(world, child, f)
      }
    None => ()
  }
}

///|
fn play_animation_when_ready(
  scene_ready : @ecs.On[@scene.SceneInstanceReady],
) -> Unit {
  guard scene_ready.entity() is Some(scene_entity) else { return }
  let world = scene_ready.world()
  guard (try! world.get_by_key(scene_entity, animation_to_play_key))
    is Some(animation_to_play) else {
    return
  }
  visit_descendants(world, scene_entity, fn(child) {
    guard (try! world.get_by_key(child, @animation.ecs_key_animation_player))
      is Some(player) else {
      return
    }
    ignore(player.play(animation_to_play.index).repeat())
    ignore(
      try! world.replace(child, @animation.ecs_key_animation_player, player),
    )
    ignore(
      try! world
      .entity_mut(child)
      .insert_component(
        @animation.AnimationGraphHandle::new(animation_to_play.graph_handle),
      ),
    )
  })
}

///|
fn name_morph_targets(
  events : @ecs.MessageReader[@asset.AssetEvent[@mesh.Mesh]],
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.Res[@asset.Assets[@mesh.Mesh]],
) -> Unit {
  for event in events.read() {
    let handle = match event {
      Added(handle) => Some(handle)
      LoadedWithDependencies(handle) => Some(handle)
      _ => None
    }
    guard handle is Some(mesh_handle) else { continue }
    guard asset_server.get().get_path(mesh_handle) is Some(path) else {
      continue
    }
    guard meshes.get().get(mesh_handle) is Some(mesh_asset) else { continue }
    guard mesh_asset.morph_target_names() is Some(names) else { continue }
    println("Morph target names for \{path}:")
    for name in names {
      println("  \{name}")
    }
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param2(Startup, setup)
  .add_systems_param3(Update, name_morph_targets)
  .run()
}
