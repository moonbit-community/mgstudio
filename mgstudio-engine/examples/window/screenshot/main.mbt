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
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_world(Startup, setup)
  .add_systems_param2(Update, screenshot_on_spacebar)
  .add_systems_world(Update, screenshot_saving)
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  spawn_scene(world)
  spawn_ui(world)
}

///|
fn spawn_scene(world : @ecs.World) -> Unit {
  @pbr.MeshMaterial3dBundle::new(
    @mesh.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
        assets
        |> @pbr.add_mesh(
          @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
            @math.Vec2::new(5.0F, 5.0F),
          ).build(),
        )
      }),
    ),
    @pbr.MeshMaterial3dTyped::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(@color.Color::srgb(0.3F, 0.5F, 0.3F)),
      ),
    ),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  @pbr.MeshMaterial3dBundle::new(
    @mesh.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
        assets |> @pbr.add_mesh(@math.Cuboid::new(1.0F, 1.0F, 1.0F))
      }),
    ),
    @pbr.MeshMaterial3dTyped::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(@color.Color::srgb(0.8F, 0.7F, 0.6F)),
      ),
    ),
    @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F),
  ).spawn(world)
  |> ignore

  let light = world.spawn_empty()
  try! world.set_by_key(
    light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::PointLight().with_shadow_maps_enabled(true),
  )
  try! world.set_by_key(
    light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::PointLight().with_shadow_maps_enabled(true),
  )
  try! world.set_by_key(
    light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F),
  )

  @pbr.Camera3dBundle::new(
    Camera(),
    @transform.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn spawn_ui(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  try! (world.spawn_bundle(
    (
      @camera_components2d.Camera2d::Camera2d(),
      @camera_camera.Camera::Camera().with_order(100).with_clear_color_none(),
      @transform.Transform::identity(),
    ),
  )
  |> ignore)

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, UiRoot())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::Node().with_width(Percent(100.0F)).with_height(Percent(100.0F)),
  )

  let text_entity = world.spawn_empty()
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @ui.ecs_key_node,
    @ui.Node::Node()
    .with_position_type(Absolute)
    .with_top(Px(12.0F))
    .with_left(Px(12.0F)),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new("Press <spacebar> to save a screenshot to disk"),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_font,
    @text.TextFont::TextFont().with_font(font).with_font_size(24.0F),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@color.Color::white()),
  )
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @ui.ecs_key_node,
    @ui.Node::Node()
    .with_position_type(Absolute)
    .with_top(Px(12.0F))
    .with_left(Px(12.0F)),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new("Press <spacebar> to save a screenshot to disk"),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_font,
    @text.TextFont::TextFont().with_font(font).with_font_size(24.0F),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@color.Color::white()),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(Left),
  )
}

///|
fn screenshot_path(index : Int) -> String {
  "./screenshot-\{index.to_string()}.png"
}

///|
fn screenshot_on_spacebar(
  input : @input.ButtonInput[@window.KeyCode],
  counter : @app.Local[Int],
) -> Unit {
  if !input.just_pressed(Space) {
    return
  }
  guard @app.current_world() is Some(world) else { return }

  let path = screenshot_path(counter.get())
  let screenshot_entity = world.spawn()
  ignore(
    world.add_entity_observer(screenshot_entity, @render.save_to_disk(path)),
  )
  try! world.set_by_key(
    screenshot_entity,
    @render.ecs_key_screenshot,
    @render.Screenshot::primary_window(),
  )
  counter.set(counter.get() + 1)
}

///|
fn screenshot_saving(world : @ecs.World) -> Unit {
  guard @window.window_entity_for_ref(world, Primary) is Some(window) else {
    return
  }

  if world.component_count(@render.ecs_key_capturing) == 0 {
    try! (world.take(window, @window.ecs_key_cursor_icon) |> ignore)
    return
  }

  try! world.set_by_key(
    window,
    @window.ecs_key_cursor_icon,
    @window.CursorIcon::from(Progress),
  )
}
