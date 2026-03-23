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
/// Port of `bevy/examples/ecs/hierarchy.rs`.

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.Time::resource())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in hierarchy example")
  }
}

///|
fn world_asset_server(world : @ecs.World) -> @asset.AssetServer {
  match (try! world.get_resource(@asset.AssetServer::resource())) {
    Some(server) => server
    None => abort("Missing AssetServer resource in hierarchy example")
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_sequence()
  let asset_server = world_asset_server(world)
  let texture = asset_server.load_image("branding/icon.png")

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let parent = @sprite.SpriteBundle::new(
    @sprite.Sprite::from_image(texture),
    @transform.Transform::identity().with_scale(@math.Vec3::splat(0.75F)),
  ).spawn(world)

  let first_child = @sprite.SpriteBundle::new(
    @sprite.Sprite::from_image(texture).with_color(
      @sprite.Color::srgb(0.0F, 0.0F, 1.0F),
    ),
    @transform.Transform::from_xyz(250.0F, 0.0F, 0.0F).with_scale(
      @math.Vec3::splat(0.75F),
    ),
  ).spawn(world)
  world
  .component(@mg_hierarchy.ecs_key_parent)
  .insert(first_child, @mg_hierarchy.Parent::new(parent), tick)

  let second_child = @sprite.SpriteBundle::new(
    @sprite.Sprite::from_image(texture).with_color(
      @sprite.Color::srgb(0.0F, 1.0F, 0.0F),
    ),
    @transform.Transform::from_xyz(0.0F, 250.0F, 0.0F).with_scale(
      @math.Vec3::splat(0.75F),
    ),
  ).spawn(world)
  world
  .component(@mg_hierarchy.ecs_key_parent)
  .insert(second_child, @mg_hierarchy.Parent::new(parent), tick)
}

///|
fn rotate(world : @ecs.World) -> Unit {
  let time = world_time(world)
  let delta = time.delta_seconds()
  let elapsed = time.elapsed_seconds()
  let tick = world.read_sequence()

  let transform_store = @transform.get_transform_store(world)
  let children_store = @mg_hierarchy.get_children_store(world)
  let parents = world.query_entities_filtered(
    (
      @ecs.With::new(@sprite.ecs_key_sprite),
      @ecs.With::new(@mg_hierarchy.ecs_key_children),
    ),
  )

  parents.view(fn(parent) {
    if transform_store.get(parent) is Some(transform) {
      let next = transform
      next.rotate_z(-@math.pi_half() * delta)
      transform_store.set(parent, next, tick) |> ignore
    }

    guard children_store.get(parent) is Some(children) else { return }
    let child_entities = children.entities()
    for child in child_entities {
      if transform_store.get(child) is Some(transform) {
        let next = transform
        next.rotate_z(@math.pi() * delta)
        transform_store.set(child, next, tick) |> ignore
      }
    }

    if elapsed >= 2.0F && child_entities.length() == 2 {
      try! world.despawn(child_entities[child_entities.length() - 1])
    }

    if elapsed >= 4.0F {
      try! world.despawn(parent)
    }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(rotate))
  .run()
}
