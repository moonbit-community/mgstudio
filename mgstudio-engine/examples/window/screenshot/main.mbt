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
/// Port of `bevy/examples/window/screenshot.rs`.

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(screenshot_on_spacebar)),
  )
  .add_systems(@app.Update, @app.system(screenshot_saving))
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  spawn_scene(world)
  spawn_ui(world)
}

///|
fn spawn_scene(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(5.0F, 5.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @sprite.Color::srgb(0.3F, 0.5F, 0.3F),
        ),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @sprite.Color::srgb(0.8F, 0.7F, 0.6F),
        ),
      ),
    ),
    @math.Transform::from_xyz(0.0F, 0.5F, 0.0F),
  ).spawn(world)
  |> ignore

  let light = world.spawn_empty()
  world
  .component(@render3d.ecs_key_point_light)
  .insert(
    light,
    @render3d.PointLight::default().with_shadow_maps_enabled(true),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(light, @math.Transform::from_xyz(4.0F, 8.0F, 4.0F), tick)

  @render3d.Camera3dBundle::new(
    @sprite.Camera::default(),
    @math.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
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

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default().with_order(100).with_clear_color_none(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let text_handle = @text.Text2dBundle::new(
      @text.Text2d::new("Press <spacebar> to save a screenshot to disk"),
      @text.TextFont::default().with_font(font).with_font_size(24.0F),
      @math.Transform::identity(),
    )
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()

  let tick = world.read_change_tick()
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
    .with_top(@ui.Val::Px(12.0F))
    .with_left(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(text_entity, @ui.UiText::new(text_handle), tick)
}

///|
fn screenshot_path(index : Int) -> String {
  "./screenshot-" + index.to_string() + ".png"
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
    world.add_entity_observer(screenshot_entity, @window.save_to_disk(path)),
  )
  try! world.set_component(
    screenshot_entity,
    @window.Screenshot::primary_window(),
  )
  counter.get_ref().val = counter.get_ref().val + 1
}

///|
fn screenshot_saving(world : @ecs.World) -> Unit {
  guard @window.window_entity_for_ref(world, @window.WindowRef::Primary)
    is Some(window) else {
    return
  }

  let cursor_store = world.component(@window.ecs_key_cursor_icon)
  if world.component(@window.ecs_key_capturing).len() == 0 {
    cursor_store.remove(window) |> ignore
    return
  }

  cursor_store.insert(
    window,
    @window.CursorIcon::from(@window.SystemCursorIcon::Progress),
    world.read_change_tick(),
  )
}
