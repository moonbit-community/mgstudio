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
/// Port of `bevy/examples/window/window_resizing.rs`.

///|
struct ResolutionText {} derive(Eq, Show)

///|
let resolution_text_key : @ecs.ComponentKey[ResolutionText] = @ecs.register_component(
  debug_name="examples.window.window_resizing.ResolutionText",
)

///|
struct ResolutionSettings {
  small : @math.Vec2
  medium : @math.Vec2
  large : @math.Vec2
}

///|
let resolution_settings_key : @ecs.ResourceKey[ResolutionSettings] = @ecs.register_resource(
  debug_name="examples.window.window_resizing.ResolutionSettings",
)

///|
impl @app.Resource for ResolutionSettings with resource() {
  resolution_settings_key
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .insert_resource(ResolutionSettings::{
    large: @math.Vec2::new(1920.0F, 1080.0F),
    medium: @math.Vec2::new(800.0F, 600.0F),
    small: @math.Vec2::new(640.0F, 360.0F),
  })
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup_camera))
  .add_systems(@app.Startup, @app.system(setup_ui))
  .add_systems(@app.Update, @app.system(@app.system_param2(toggle_resolution)))
  .add_systems(@app.Update, @app.system(@app.system_param(on_resize_system)))
  .run()
}

///|
fn setup_camera(world : @ecs.World) -> Unit {
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore
}

///|
fn setup_ui(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let tick = world.read_change_tick()
  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(root, @ui.Node::default().with_width(@ui.Val::Percent(100.0F)), tick)
  let text_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(root), tick)
  world
  .component(@text.ecs_key_text)
  .insert(text_entity, @text.Text::new("Resolution"), tick)
  world
  .component(@text.ecs_key_text_font)
  .insert(
    text_entity,
    @text.TextFont::default().with_font(font).with_font_size(42.0F),
    tick,
  )
  world
  .component(@text.ecs_key_text_color)
  .insert(text_entity, @text.TextColor::new(@sprite.Color::white()), tick)
  world
  .component(resolution_text_key)
  .insert(text_entity, ResolutionText::{  }, tick)
}

///|
fn resolution_text_entity(world : @ecs.World) -> @core.Entity? {
  let result : Ref[@core.Entity?] = Ref::new(None)
  world
  .query_entities_filtered(@ecs.With::new(resolution_text_key))
  .view(fn(entity) { if result.val is None { result.val = Some(entity) } })
  result.val
}

///|
fn update_resolution_text(
  world : @ecs.World,
  width : Float,
  height : Float,
) -> Unit {
  guard resolution_text_entity(world) is Some(entity) else { return }
  let text_store = world.component(@text.ecs_key_text)
  guard text_store.get(entity) is Some(text) else { return }
  text.content = width.to_string() + " x " + height.to_string()
  text_store.set(entity, text, world.read_change_tick()) |> ignore
}

///|
fn update_primary_window(
  world : @ecs.World,
  update : (@window.Window) -> Unit,
) -> Unit {
  let tick = world.read_change_tick()
  let window_store = world.component(@window.ecs_key_window)
  world
  .query_entities_filtered(
    (
      @ecs.With::new(@window.ecs_key_window),
      @ecs.With::new(@window.ecs_key_primary_window),
    ),
  )
  .view(fn(entity) {
    guard window_store.get(entity) is Some(window) else { return }
    update(window)
    window_store.set(entity, window, tick) |> ignore
  })
}

///|
fn toggle_resolution(
  keys : @input.ButtonInput[@window.KeyCode],
  resolution : @app.Res[ResolutionSettings],
) -> Unit {
  guard @app.current_world() is Some(world) else { return }
  let next_resolution : @math.Vec2? = if keys.just_pressed(Digit1) {
    Some(resolution.get().small)
  } else if keys.just_pressed(Digit2) {
    Some(resolution.get().medium)
  } else if keys.just_pressed(Digit3) {
    Some(resolution.get().large)
  } else {
    None
  }
  guard next_resolution is Some(next_resolution0) else { return }
  update_primary_window(world, fn(window) {
    window.resolution.set(next_resolution0.x, next_resolution0.y)
  })
}

///|
fn on_resize_system(
  resize_reader : @ecs.MessageReader[@window.WindowResized],
) -> Unit {
  guard @app.current_world() is Some(world) else { return }
  for event in (try! resize_reader.read()) {
    update_resolution_text(world, event.width, event.height)
  }
}
