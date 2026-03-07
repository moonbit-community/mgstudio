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
/// Port of `bevy/examples/window/scale_factor_override.rs`.

///|
struct CustomText {} derive(Eq, Show)

///|
let custom_text_key : @ecs.ComponentKey[CustomText] = @ecs.register_component(
  debug_name="examples.window.scale_factor_override.CustomText",
)

///|
impl @ecs.Component for CustomText with component() {
  custom_text_key
}

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::default()
  window.resolution = @window.WindowResolution::new(500, 300).with_scale_factor_override(
    1.0F,
  )
  window
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugin_group(fn() {
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(configured_window()),
      primary_cursor_options: Some(@window.CursorOptions::default()),
      exit_condition: @window.ExitCondition::OnAllClosed,
      close_when_requested: true,
    })
  })
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(display_override))
  .add_systems(@app.Update, @app.system(@app.system_param(toggle_override)))
  .add_systems(@app.Update, @app.system(@app.system_param(change_scale_factor)))
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()

  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let text_handle = @text.Text2dBundle::new(
      @text.Text2d::new("Example text"),
      @text.TextFont::default().with_font(font).with_font_size(25.0F),
      @math.Transform::identity(),
    )
    .with_color(@text.TextColor::new(@render2d.Color::black()))
    .spawn()

  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_justify_content(@ui.JustifyContent::SpaceBetween),
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
    .with_width(@ui.Val::Px(300.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_border(@ui.UiRect::all(@ui.Val::Px(2.0F)))
    .with_align_items(@ui.AlignItems::FlexEnd),
    tick,
  )
  world
  .component(@ui.ecs_key_background_color)
  .insert(
    panel,
    @ui.BackgroundColor::new(@render2d.Color::new(0.65F, 0.65F, 0.65F, 1.0F)),
    tick,
  )

  let label = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(label, @hierarchy.Parent::new(panel), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    label,
    @ui.Node::default().with_width(@ui.Val::Auto).with_height(@ui.Val::Auto),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(label, @ui.UiText::new(text_handle), tick)
  world.component(custom_text_key).insert(label, CustomText::{  }, tick)
}

///|
fn primary_window_entity(world : @ecs.World) -> @core.Entity? {
  let result : Ref[@core.Entity?] = Ref::new(None)
  world
  .query_entities_filtered(
    (
      @ecs.With::new(@window.ecs_key_window),
      @ecs.With::new(@window.ecs_key_primary_window),
    ),
  )
  .view(fn(entity) { if result.val is None { result.val = Some(entity) } })
  result.val
}

///|
fn custom_text_entity(world : @ecs.World) -> @core.Entity? {
  let result : Ref[@core.Entity?] = Ref::new(None)
  world
  .query_entities_filtered(@ecs.With::new(custom_text_key))
  .view(fn(entity) { if result.val is None { result.val = Some(entity) } })
  result.val
}

///|
fn update_primary_window(
  world : @ecs.World,
  update : (@window.Window) -> Unit,
) -> Unit {
  guard primary_window_entity(world) is Some(entity) else { return }
  let tick = world.read_change_tick()
  let window_store = world.component(@window.ecs_key_window)
  guard window_store.get(entity) is Some(window) else { return }
  update(window)
  window_store.set(entity, window, tick) |> ignore
}

///|
fn set_custom_text(world : @ecs.World, text : String) -> Unit {
  guard custom_text_entity(world) is Some(entity) else { return }
  let ui_text_store = world.component(@ui.ecs_key_ui_text)
  guard ui_text_store.get(entity) is Some(ui_text) else { return }
  @text.text_set_content(ui_text.handle, text)
}

///|
fn format_scale_factor(value : Float) -> String {
  let scaled = (value * 10.0F).to_int()
  let whole = scaled / 10
  let fractional = scaled % 10
  whole.to_string() + "." + fractional.to_string()
}

///|
fn display_text(scale_factor : Float, overridden : Bool) -> String {
  let state = if overridden { "(overridden)" } else { "(default)" }
  "Scale factor: " + format_scale_factor(scale_factor) + " " + state
}

///|
fn display_override(world : @ecs.World) -> Unit {
  guard primary_window_entity(world) is Some(entity) else { return }
  let window_store = world.component(@window.ecs_key_window)
  guard window_store.get(entity) is Some(window) else { return }
  let text = display_text(
    window.scale_factor(),
    window.resolution.scale_factor_override() is Some(_),
  )
  update_primary_window(world, fn(primary_window) {
    primary_window.title = text
  })
  set_custom_text(world, text)
}

///|
fn toggle_override(keys : @input.ButtonInput[@window.KeyCode]) -> Unit {
  if !keys.just_pressed(Enter) {
    return
  }
  guard @app.current_world() is Some(world) else { return }
  update_primary_window(world, fn(window) {
    let next_override = match window.resolution.scale_factor_override() {
      Some(_) => None
      None => Some(1.0F)
    }
    window.resolution.set_scale_factor_override(next_override)
  })
}

///|
fn change_scale_factor(keys : @input.ButtonInput[@window.KeyCode]) -> Unit {
  guard @app.current_world() is Some(world) else { return }
  let is_up = keys.just_pressed(ArrowUp)
  let is_down = keys.just_pressed(ArrowDown)
  if !is_up && !is_down {
    return
  }
  update_primary_window(world, fn(window) {
    guard window.resolution.scale_factor_override() is Some(scale_factor) else {
      return
    }
    let next_scale_factor = if is_up {
      scale_factor + 1.0F
    } else {
      let next = scale_factor - 1.0F
      if next < 1.0F {
        1.0F
      } else {
        next
      }
    }
    window.resolution.set_scale_factor_override(Some(next_scale_factor))
  })
}
