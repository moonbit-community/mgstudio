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
const GLTF_PATH : String = "models/animated/Fox.glb"

///|
struct AnimationToPlay {
  graph_handle : @asset.Handle[@animation.AnimationGraph]
  index : @animation.AnimationNodeIndex
}

///|
let animation_to_play_key : @ecs.ComponentKey[AnimationToPlay] = @ecs.register_component(
  debug_name="examples.animation.animated_mesh.AnimationToPlay",
)

///|
pub impl @ecs.Component for AnimationToPlay with component() {
  animation_to_play_key
}

///|
fn setup_mesh_and_animation(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let (graph, index) = @animation.AnimationGraph::from_clip(
    asset_server
    .get()
    .load(@gltf.GltfAssetLabel::Animation(2).from_asset(GLTF_PATH)),
  )
  let graph_handle = @animation.animation_graph_add(graph)

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
fn setup_camera_and_environment(world : @ecs.World) -> Unit {
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
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(
    @app.Startup,
    @app.system(@app.system_param2(setup_mesh_and_animation)),
  )
  .add_systems(@app.Startup, @app.system(setup_camera_and_environment))
  .run()
}
