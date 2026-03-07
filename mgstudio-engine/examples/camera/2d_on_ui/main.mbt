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
/// Port of `bevy/examples/camera/2d_on_ui.rs`.

///|
priv struct CameraOnUiState {
  mut sprite : @core.Entity
}

///|
let camera_on_ui_state : Ref[CameraOnUiState] = Ref::new(CameraOnUiState::{
  sprite: @core.Entity::placeholder(),
})

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let ui_camera = @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  world
  .component(@ui.ecs_key_is_default_ui_camera)
  .insert(ui_camera, @ui.IsDefaultUiCamera::default(), tick)

  @render2d.Camera2dBundle::new_with_layers(
    @render2d.Camera::default().with_order(1).with_clear_color_none(),
    @math.Transform::identity(),
    @render2d.RenderTarget::Screen,
    @render2d.RenderLayers::layer(1),
  ).spawn(world)
  |> ignore

  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center),
    tick,
  )
  world
  .component(@ui.ecs_key_background_color)
  .insert(
    root,
    @ui.BackgroundColor::new(@render2d.Color::new(0.98F, 0.44F, 0.58F, 1.0F)),
    tick,
  )

  let panel = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(panel, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    panel,
    @ui.Node::default()
    .with_width(@ui.Val::Px(180.0F))
    .with_height(@ui.Val::Px(220.0F))
    .with_border(@ui.UiRect::all(@ui.Val::Px(2.0F))),
    tick,
  )
  world
  .component(@ui.ecs_key_background_color)
  .insert(
    panel,
    @ui.BackgroundColor::new(@render2d.Color::new(0.98F, 0.82F, 0.86F, 1.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_border_color)
  .insert(panel, @ui.BorderColor::new(@render2d.Color::white()), tick)
  world
  .component(@ui.ecs_key_border_radius)
  .insert(panel, @ui.BorderRadius::all(@ui.Val::Percent(25.0F)), tick)

  let asset_server = @asset.AssetServer::new()
  let sprite = @render2d.SpriteBundle::new_with_layers(
    @render2d.Sprite::from_image(
      asset_server.load("textures/rpg/chars/sensei/sensei.png"),
    ).with_custom_size(Some(@math.Vec2::new(100.0F, 100.0F))),
    @math.Transform::identity(),
    @render2d.RenderLayers::layer(1),
  ).spawn(world)
  camera_on_ui_state.val.sprite = sprite
}

///|
fn rotate_sprite(world : @ecs.World) -> Unit {
  let sprite = camera_on_ui_state.val.sprite
  if sprite.is_placeholder() {
    return
  }
  let tick = world.read_change_tick()
  let transform_store = @math.get_transform_store(world)
  guard transform_store.get(sprite) is Some(transform) else { return }

  let rotation = @math.Quat::from_rotation_z(@time.time_delta_seconds() * 0.5F).mul(
    @math.Quat::from_rotation_y(@time.time_delta_seconds()),
  )
  transform_store.set(
    sprite,
    transform.with_rotation(rotation.mul(transform.rotation).normalize()),
    tick,
  )
  |> ignore
}

///|
fn main {
  camera_on_ui_state.val.sprite = @core.Entity::placeholder()
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(rotate_sprite))
  .run()
}
