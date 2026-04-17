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
struct Animations {
  animations : Array[@animation.AnimationNodeIndex]
  graph_handle : @asset.Handle[@animation.AnimationGraph]
}

///|
let animations_resource_key : @ecs.ResourceKey[Animations] = @ecs.register_resource(
  debug_name="examples.animation.animated_mesh_control.Animations",
)

///|
pub impl @app.Resource for Animations with resource() {
  animations_resource_key
}

///|
fn setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let (graph, animation_indices) = @animation.AnimationGraph::from_clips([
    asset_server.load(@gltf.GltfAssetLabel::Animation(2).from_asset(FOX_PATH)),
    asset_server.load(@gltf.GltfAssetLabel::Animation(1).from_asset(FOX_PATH)),
    asset_server.load(@gltf.GltfAssetLabel::Animation(0).from_asset(FOX_PATH)),
  ])
  let graph_handle = @animation.animation_graph_add(graph)
  world.insert_resource(animations_resource_key, Animations::{
    animations: animation_indices,
    graph_handle,
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
  ignore(
    @sprite.Camera2dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::identity(),
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

  ignore(
    try! world
    .entity_mut(world.spawn_empty())
    .insert_component(
      @scene.SceneRoot::new(
        asset_server.load(@gltf.GltfAssetLabel::Scene(0).from_asset(FOX_PATH)),
      ),
    ),
  )

  let root = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(root)
    .insert(
      (
        @ui.UiRoot::default(),
        @ui.Node::default()
        .with_width(@ui.Val::Percent(100.0F))
        .with_height(@ui.Val::Percent(100.0F)),
      ),
    ),
  )
  let instruction_text = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(instruction_text)
    .insert(
      (
        @hierarchy.Parent::new(root),
        @text.Text::new(
          "space: play / pause\nup / down: playback speed\nleft / right: seek\n1-3: play N times\nL: loop forever\nreturn: change animation\n",
        ),
        @text.TextFont::from_font_size(@text.FontSize::Px(26.0F)).with_font(
          asset_server.load_font("fonts/FiraSans-Bold.ttf"),
        ),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.Val::Px(12.0F))
        .with_left(@ui.Val::Px(12.0F)),
      ),
    ),
  )
}

///|
fn setup_scene_once_loaded(
  scene_ready : @ecs.ComponentOn[@ecs.Insert, @scene.SceneInstanceReady],
  commands : @app.Commands,
  animations : @app.Res[Animations],
  players : @ecs.Query[@ecs.Mut[@animation.AnimationPlayer], @ecs.All],
) -> Unit {
  guard (players.get(scene_ready.entity) catch { _ => None })
    is Some(player_mut) else {
    return
  }
  let player_ref = player_mut.get_ref()
  let transitions = @animation.AnimationTransitions::new()
  transitions
  .play(player_ref.val, animations.get().animations[0], 0.0F)
  .repeat()
  |> ignore
  commands
  .entity(scene_ready.entity)
  .insert(
    (
      @animation.AnimationGraphHandle::new(animations.get().graph_handle),
      transitions,
    ),
  )
}

///|
fn keyboard_control(
  keyboard_input : @input.ButtonInput[@window.KeyCode],
  animation_players : @ecs.Query[
    (
      @ecs.Mut[@animation.AnimationPlayer],
      @ecs.Mut[@animation.AnimationTransitions],
    ),
    @ecs.All,
  ],
  animations : @app.Res[Animations],
  current_animation : @app.Local[Int],
) -> Unit {
  let player_data = animation_players.require_single() catch { _ => return }
  let (player_mut, transitions_mut) = player_data
  let player_ref = player_mut.get_ref()
  let transitions_ref = transitions_mut.get_ref()
  let playing = player_ref.val.playing_animations()
  if playing.length() == 0 {
    return
  }
  let playing_animation_index = playing[0].0

  if keyboard_input.just_pressed(@window.KeyCode::Space) {
    if player_ref.val.animation_mut(playing_animation_index)
      is Some(animation_entry) {
      let active = playing[0].1
      if active.is_paused() {
        animation_entry.unpause() |> ignore
      } else {
        animation_entry.pause() |> ignore
      }
    }
  }

  if keyboard_input.just_pressed(@window.KeyCode::ArrowUp) {
    if player_ref.val.animation_mut(playing_animation_index)
      is Some(animation_entry) {
      animation_entry.set_speed(playing[0].1.speed() * 1.2F) |> ignore
    }
  }

  if keyboard_input.just_pressed(@window.KeyCode::ArrowDown) {
    if player_ref.val.animation_mut(playing_animation_index)
      is Some(animation_entry) {
      animation_entry.set_speed(playing[0].1.speed() * 0.8F) |> ignore
    }
  }

  if keyboard_input.just_pressed(@window.KeyCode::ArrowLeft) {
    if player_ref.val.animation_mut(playing_animation_index)
      is Some(animation_entry) {
      animation_entry.seek_to(playing[0].1.seek_time() - 0.1F) |> ignore
    }
  }

  if keyboard_input.just_pressed(@window.KeyCode::ArrowRight) {
    if player_ref.val.animation_mut(playing_animation_index)
      is Some(animation_entry) {
      animation_entry.seek_to(playing[0].1.seek_time() + 0.1F) |> ignore
    }
  }

  if keyboard_input.just_pressed(@window.KeyCode::Enter) {
    let next_index = (current_animation.get() + 1) %
      animations.get().animations.length()
    current_animation.set(next_index)
    transitions_ref.val
    .play(player_ref.val, animations.get().animations[next_index], 0.25F)
    .repeat()
    |> ignore
  }

  if keyboard_input.just_pressed(@window.KeyCode::Digit1) {
    if player_ref.val.animation_mut(playing_animation_index)
      is Some(animation_entry) {
      animation_entry.set_repeat(@animation.RepeatAnimation::Count(1)).replay()
      |> ignore
    }
  }

  if keyboard_input.just_pressed(@window.KeyCode::Digit2) {
    if player_ref.val.animation_mut(playing_animation_index)
      is Some(animation_entry) {
      animation_entry.set_repeat(@animation.RepeatAnimation::Count(2)).replay()
      |> ignore
    }
  }

  if keyboard_input.just_pressed(@window.KeyCode::Digit3) {
    if player_ref.val.animation_mut(playing_animation_index)
      is Some(animation_entry) {
      animation_entry.set_repeat(@animation.RepeatAnimation::Count(3)).replay()
      |> ignore
    }
  }

  if keyboard_input.just_pressed(@window.KeyCode::KeyL) {
    if player_ref.val.animation_mut(playing_animation_index)
      is Some(animation_entry) {
      animation_entry.set_repeat(@animation.RepeatAnimation::Forever) |> ignore
    }
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(@app.system_param4(keyboard_control)))
  .add_component_observer4(setup_scene_once_loaded)
  .run()
}
