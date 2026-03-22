// Copyright 2025 International Digital Economy Academy
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
/// Port of `bevy/examples/window/multiple_windows.rs`.

///|
const TORUS_SCENE_PATH : String = "models/torus/torus.gltf"

///|
fn setup_scene(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let asset_server = @asset.AssetServer::new()

  // Scene
  let scene_entity = world.spawn_empty()
  world
  .component(@scene.ecs_key_scene_root)
  .insert(
    scene_entity,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @gltf.GltfAssetLabel::Scene(0).from_asset(TORUS_SCENE_PATH),
      ),
    ),
    tick,
  )

  // Directional light
  let light = world.spawn_empty()
  world
  .component(@pbr.ecs_key_directional_light)
  .insert(light, @pbr.DirectionalLight::default(), tick)
  world
  .component(@transform.ecs_key_transform)
  .insert(
    light,
    @transform.Transform::from_xyz(3.0F, 3.0F, 3.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  // Camera for primary window
  let first_window_camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(0.0F, 0.0F, 6.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)

  // Spawn second window
  let second_window = world.spawn_empty()
  let second_window_component = @window.Window::default()
  second_window_component.title = "Second window"
  world
  .component(@window.ecs_key_window)
  .insert(second_window, second_window_component, tick)

  // Camera for secondary window
  let second_window_camera = @pbr.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(6.0F, 0.0F, 0.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_target(
      @sprite.RenderTarget::Window(@window.WindowRef::Entity(second_window)),
    )
    .spawn(world)

  spawn_label(world, first_window_camera, "First window")
  spawn_label(world, second_window_camera, "Second window")
}

///|
fn spawn_label(
  world : @ecs.World,
  camera : @core.Entity,
  label : String,
) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let tick = world.read_change_tick()
  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.Val::Px(12.0F))
    .with_left(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_target_camera)
  .insert(root, @ui.UiTargetCamera::new(camera), tick)

  let text_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(root), tick)
  world
  .component(@text.ecs_key_text)
  .insert(text_entity, @text.Text::new(label), tick)
  world
  .component(@text.ecs_key_text_font)
  .insert(
    text_entity,
    @text.TextFont::default().with_font(font).with_font_size(24.0F),
    tick,
  )
  world
  .component(@text.ecs_key_text_color)
  .insert(text_entity, @text.TextColor::new(@sprite.Color::white()), tick)
  world
  .component(@text.ecs_key_text_shadow)
  .insert(text_entity, @text.TextShadow::default(), tick)
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup_scene))
  .run()
}
