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
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(visibility_setup)
  .add_system(visibility_toggle_system)
  .run()
}

///|
fn visibility_setup(world : @ecs.World) -> Unit {
  let parent = world.spawn_empty()
  parent_entity_state.val = Some(parent)
  try! world.set(parent, @math.ecs_key_transform, @math.Transform::identity())
  try! world.set(parent, @vis.ecs_key_visibility, @vis.Visibility::Visible)
  try! world.set(
    parent,
    @vis.ecs_key_inherited_visibility,
    @vis.InheritedVisibility::new(true),
  )
  try! world.set(
    parent,
    @vis.ecs_key_view_visibility,
    @vis.ViewVisibility::new(true),
  )
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/bevy_bird_dark.png")
  let sprite = @render2d.Sprite::from_image(texture)
  let child = @render2d.SpriteBundle::new(sprite, @math.Transform::identity()).spawn(
    world,
  )
  try! world.set(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
  @window.host_debug_string(
    value="Press H to toggle parent Visibility (Hidden/Visible).",
  )
}

///|
fn visibility_toggle_system(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::KeyH) {
    return
  }
  guard parent_entity_state.val is Some(parent) else { return }
  let next = match (try! world.get(parent, @vis.ecs_key_visibility)) {
    Some(@vis.Visibility::Hidden) => @vis.Visibility::Visible
    Some(@vis.Visibility::Visible) => @vis.Visibility::Hidden
    Some(@vis.Visibility::Inherited) => @vis.Visibility::Hidden
    None => @vis.Visibility::Hidden
  }
  try! world.set(parent, @vis.ecs_key_visibility, next)
  let msg = match next {
    @vis.Visibility::Hidden => "Parent Visibility: Hidden"
    @vis.Visibility::Visible => "Parent Visibility: Visible"
    @vis.Visibility::Inherited => "Parent Visibility: Inherited"
  }
  @window.host_debug_string(value=msg)
}
