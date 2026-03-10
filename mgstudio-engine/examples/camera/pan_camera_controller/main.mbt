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
/// Port of `bevy/examples/camera/pan_camera_controller.rs`.

///|
priv struct PanCameraExampleState {
  mut camera : @core.Entity
}

///|
let pan_camera_example_state : Ref[PanCameraExampleState] = Ref::new(PanCameraExampleState::{
  camera: @core.Entity::placeholder(),
})

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let camera = @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  world
  .component(@sprite.ecs_key_pan_camera)
  .insert(camera, @sprite.PanCamera::default(), tick)
  pan_camera_example_state.val.camera = camera

  let asset_server = @asset.AssetServer::new()
  @sprite.SpriteBundle::new(
    @sprite.Sprite::from_image(asset_server.load("branding/bevy_bird_dark.png")),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore
}

///|
fn spawn_text(world : @ecs.World) -> Unit {
  let camera = pan_camera_example_state.val.camera
  if camera.is_placeholder() {
    return
  }
  let tick = world.read_change_tick()
  let pan_camera_store = @sprite.get_pan_camera_store(world)
  guard pan_camera_store.get(camera) is Some(controller) else { return }

  let overlay_camera = @sprite.Camera2dBundle::new(
    @sprite.Camera::default().with_order(1).with_clear_color_none(),
    @math.Transform::identity(),
  ).spawn(world)
  world
  .component(@ui.ecs_key_is_default_ui_camera)
  .insert(overlay_camera, @ui.IsDefaultUiCamera::default(), tick)

  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
    tick,
  )

  let asset_server = @asset.AssetServer::new()
  let text_handle = @text.Text2dBundle::new(
      @text.Text2d::new(controller.to_string()),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(20.0F),
      @math.Transform::identity(),
    )
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()

  let text_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    text_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.Val::Px(-16.0F))
    .with_left(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(text_entity, @ui.UiText::new(text_handle), tick)
}

///|
fn main {
  pan_camera_example_state.val.camera = @core.Entity::placeholder()
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_plugins([@sprite.pan_camera_plugin])
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Startup, @app.system(spawn_text))
  .run()
}
