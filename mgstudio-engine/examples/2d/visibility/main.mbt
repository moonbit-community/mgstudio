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
/// Toggle Visibility/InheritedVisibility propagation (Bevy semantics).
///
/// Controls:
/// - Press `H` to toggle the parent entity between Hidden and Visible.
///
/// Expected:
/// - When the parent is Hidden, the child sprite is not drawn.
/// - When the parent is Visible, the child sprite is drawn.
let parent_entity_state : Ref[@core.Entity?] = Ref::new(None)

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(visibility_setup)
  .add_system(visibility_toggle_system)
  .run()
}

///|
fn visibility_setup(world : @ecs_world.World) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let parent = world.spawn_empty()
  parent_entity_state.val = Some(parent)
  @math.Has_Transform::get_transform_store(world).insert(
    parent,
    @math.Transform::identity(),
    tick,
  )
  @vis.Has_Visibility::get_visibility_store(world).insert(
    parent,
    @vis.Visibility::Visible,
    tick,
  )
  @vis.Has_InheritedVisibility::get_inherited_visibility_store(world).insert(
    parent,
    @vis.InheritedVisibility::new(true),
    tick,
  )
  @vis.Has_ViewVisibility::get_view_visibility_store(world).insert(
    parent,
    @vis.ViewVisibility::new(true),
    tick,
  )
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/bevy_bird_dark.png")
  let sprite = @render2d.Sprite::from_image(texture)
  let child = @render2d.SpriteBundle::new(sprite, @math.Transform::identity()).spawn(
    world,
  )
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    child,
    @hierarchy.Parent::new(parent),
    tick,
  )
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
  @window.host_debug_string(
    "Press H to toggle parent Visibility (Hidden/Visible).",
  )
}

///|
fn visibility_toggle_system(world : @ecs_world.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::KeyH) {
    return
  }
  guard parent_entity_state.val is Some(parent) else { return }
  let store = @vis.Has_Visibility::get_visibility_store(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let next = match store.get(parent) {
    Some(@vis.Visibility::Hidden) => @vis.Visibility::Visible
    Some(@vis.Visibility::Visible) => @vis.Visibility::Hidden
    Some(@vis.Visibility::Inherited) => @vis.Visibility::Hidden
    None => @vis.Visibility::Hidden
  }
  if store.contains(parent) {
    store.set(parent, next, tick) |> ignore
  } else {
    store.insert(parent, next, tick)
  }
  let msg = match next {
    @vis.Visibility::Hidden => "Parent Visibility: Hidden"
    @vis.Visibility::Visible => "Parent Visibility: Visible"
    @vis.Visibility::Inherited => "Parent Visibility: Inherited"
  }
  @window.host_debug_string(msg)
}
