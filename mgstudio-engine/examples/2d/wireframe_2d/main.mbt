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
priv struct WireframeSceneState {
  mut circle_entity : @core.Entity
  mut overlay_text_handle : @text.TextHandle?
}

///|
let wireframe_scene_state : Ref[WireframeSceneState] = Ref::new(WireframeSceneState::{
  circle_entity: @core.Entity::placeholder(),
  overlay_text_handle: None,
})

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_plugins([@sprite.wireframe2d_plugin])
  .add_systems(@app.Startup, @app.system(wireframe_setup))
  .add_systems(@app.Startup, @app.system(setup_wireframe2d_config))
  .add_systems(@app.Update, @app.system(wireframe_update))
  .run()
}

///|
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn color_close(a : @sprite.Color, b : @sprite.Color) -> Bool {
  absf(a.r - b.r) < 0.0001F &&
  absf(a.g - b.g) < 0.0001F &&
  absf(a.b - b.b) < 0.0001F &&
  absf(a.a - b.a) < 0.0001F
}

///|
fn color_red() -> @sprite.Color {
  @sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F)
}

///|
fn color_green() -> @sprite.Color {
  @sprite.Color::new(0.0F, 1.0F, 0.0F, 1.0F)
}

///|
fn color_default_white() -> @sprite.Color {
  @sprite.Color::white()
}

///|
fn wireframe_color_text(color : @sprite.Color) -> String {
  if color_close(color, color_red()) {
    "Srgba { red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0 }"
  } else {
    "Srgba { red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0 }"
  }
}

///|
fn wireframe_overlay_text(config : @sprite.Wireframe2dConfig) -> String {
  let global_value = if config.global { "true" } else { "false" }
  "Controls\n---------------\nZ - Toggle global\nX - Change global color\nC - Change color of the circle wireframe\n\nWireframe2dConfig\n-------------\nGlobal: " +
  global_value +
  "\nColor: " +
  wireframe_color_text(config.default_color)
}

///|
fn spawn_ui_text_handle(
  content : String,
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  color : @sprite.Color,
) -> @text.TextHandle {
  @text.Text2dBundle::new(
    @text.Text2d::new(content),
    @text.TextFont::default().with_font(font).with_font_size(font_size),
    @transform.Transform::identity(),
  )
  .with_color(@text.TextColor::new(color))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
  .spawn()
}

///|
fn spawn_wireframe_overlay(
  world : @ecs.World,
  config : @sprite.Wireframe2dConfig,
) -> @text.TextHandle {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let text_handle = spawn_ui_text_handle(
    wireframe_overlay_text(config),
    font,
    20.0F,
    @sprite.Color::white(),
  )
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
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(text_entity, @ui.UiText::new(text_handle), tick)
  text_handle
}

///|
fn setup_wireframe2d_config(world : @ecs.World) -> Unit {
  let config = @sprite.Wireframe2dConfig::new(true, color_default_white())
  world.insert_resource(@sprite.ecs_key_wireframe2d_config, config)
}

///|
fn wireframe_setup(world : @ecs.World) -> Unit {
  let black = @sprite.Color::black()

  let tick = world.read_change_tick()

  let triangle_entity = @sprite.Mesh2dBundle::new(
    @sprite.Mesh2d::from_triangle(
      @sprite.Triangle2d::new(
        @math.Vec2::new(0.0F, 50.0F),
        @math.Vec2::new(-50.0F, -50.0F),
        @math.Vec2::new(50.0F, -50.0F),
      ),
    ),
    @sprite.ColorMaterial::new(black),
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-150.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  ).spawn(world)
  world
  .component(@sprite.ecs_key_no_wireframe2d)
  .insert(triangle_entity, @sprite.NoWireframe2d::default(), tick)

  @sprite.Mesh2dBundle::new(
    @sprite.Mesh2d::from_rectangle(@sprite.Rectangle::new(100.0F, 100.0F)),
    @sprite.ColorMaterial::new(black),
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  ).spawn(world)
  |> ignore

  let circle_entity = @sprite.Mesh2dBundle::new(
    @sprite.Mesh2d::from_circle(@sprite.Circle::new(50.0F)),
    @sprite.ColorMaterial::new(black),
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(150.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  ).spawn(world)
  world
  .component(@sprite.ecs_key_wireframe2d)
  .insert(circle_entity, @sprite.Wireframe2d::default(), tick)
  world
  .component(@sprite.ecs_key_wireframe2d_color)
  .insert(circle_entity, @sprite.Wireframe2dColor::new(color_green()), tick)

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  wireframe_scene_state.val.circle_entity = circle_entity

  let config = try
    world.get_resource(@sprite.ecs_key_wireframe2d_config)
  catch {
    _ => @sprite.Wireframe2dConfig::default()
  } noraise {
    Some(value) => value
    None => @sprite.Wireframe2dConfig::default()
  }
  wireframe_scene_state.val.overlay_text_handle = Some(
    spawn_wireframe_overlay(world, config),
  )
}

///|
fn wireframe_update(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()

  let mut config = try
    world.get_resource(@sprite.ecs_key_wireframe2d_config)
  catch {
    _ => @sprite.Wireframe2dConfig::default()
  } noraise {
    Some(value) => value
    None => @sprite.Wireframe2dConfig::default()
  }
  let mut config_changed = false
  if @input.key_just_pressed(@window.KeyCode::KeyZ) {
    config = config.with_global(!config.global)
    config_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyX) {
    let next_color = if color_close(config.default_color, color_default_white()) {
      color_red()
    } else {
      color_default_white()
    }
    config = config.with_default_color(next_color)
    config_changed = true
  }
  if config_changed {
    world.insert_resource(@sprite.ecs_key_wireframe2d_config, config)
  }

  if @input.key_just_pressed(@window.KeyCode::KeyC) {
    let store = world.component(@sprite.ecs_key_wireframe2d_color)
    if store.get(wireframe_scene_state.val.circle_entity)
      is Some(color_component) {
      let next = if color_close(color_component.color, color_green()) {
        color_red()
      } else {
        color_green()
      }
      store.set(
        wireframe_scene_state.val.circle_entity,
        @sprite.Wireframe2dColor::new(next),
        tick,
      )
      |> ignore
    }
  }

  if wireframe_scene_state.val.overlay_text_handle is Some(text_handle) {
    let config = try
      world.get_resource(@sprite.ecs_key_wireframe2d_config)
    catch {
      _ => @sprite.Wireframe2dConfig::default()
    } noraise {
      Some(value) => value
      None => @sprite.Wireframe2dConfig::default()
    }
    @text.text_set_content(text_handle, wireframe_overlay_text(config))
  }
}
