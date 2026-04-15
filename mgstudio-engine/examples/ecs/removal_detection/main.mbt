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
struct MyComponent {} derive(Eq, Debug)

///|
let my_component_key : @ecs.ComponentKey[MyComponent] = @ecs.register_component(
  debug_name="examples.ecs.removal_detection.MyComponent",
)

///|
pub impl @ecs.Component for MyComponent with component() {
  my_component_key
}

///|
fn world_asset_server(world : @ecs.World) -> @asset.AssetServer {
  match (try! world.get_resource(@asset.AssetServer::resource())) {
    Some(asset_server) => asset_server
    None => abort("Missing AssetServer resource in removal_detection example")
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  let asset_server = world_asset_server(world)

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let sprite = @sprite.SpriteBundle::new(
    @sprite.Sprite::from_image(asset_server.load_image("branding/icon.png")),
    @transform.Transform::identity(),
  ).spawn(world)
  try! world.set_by_key(sprite, my_component_key, MyComponent::{  })
}

///|
fn remove_component(
  time : @app.Res[@time.Time[Unit]],
  commands : @app.Commands,
  query : @ecs.Query[@core.Entity, @ecs.With[MyComponent]],
) -> Unit {
  if time.get().elapsed_seconds() <= 2.0F {
    return
  }
  let target_ref : Ref[@core.Entity?] = Ref::new(None)
  try! query.view(fn(_query_entity, entity) {
    if target_ref.val is None {
      target_ref.val = Some(entity)
    }
  })
  if target_ref.val is Some(entity) {
    commands.entity(entity).remove(MyComponent::component())
  }
}

///|
fn react_on_removal(
  remove : @ecs.ComponentOn[@ecs.Remove, MyComponent],
  query : @ecs.Query[@ecs.Mut[@sprite.Sprite], @ecs.All],
) -> Unit {
  if (query.get(remove.entity) catch { _ => None }) is Some(sprite) {
    sprite.get_ref().val.color = @sprite.Color::srgb(0.5F, 1.0F, 1.0F)
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(@app.system_param3(remove_component)))
  .add_component_observer2(react_on_removal)
  .run()
}
