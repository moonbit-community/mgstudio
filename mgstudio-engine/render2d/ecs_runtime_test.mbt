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
fn[T] ecs_has_non_null_payload(
  world : @ecs.World,
  entity : @core.Entity,
  key : @ecs.ComponentKey[T],
) -> Bool {
  (try! world.get(entity, key)) is Some(_)
}

///|
fn ecs_transform_matches(
  world : @ecs.World,
  entity : @core.Entity,
  expected : @math.Transform,
) -> Bool {
  let actual_transform = try! world.get(entity, @math.ecs_key_transform)
  match actual_transform {
    Some(actual) => actual.to_json() == expected.to_json()
    None => false
  }
}

///|
test "render2d: SpriteBundle::spawn inserts expected components" {
  let world = @ecs.World::new()
  let image : @asset.Handle[@asset.Image] = @asset.Handle::new(1)
  let bundle = SpriteBundle::new(
    Sprite::from_image(image),
    @math.Transform::identity(),
  )
  let entity = bundle.spawn(world)

  inspect(world.is_alive(entity), content="true")
  inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_sprite),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_anchor),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_render_layers),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(world, entity, @visibility.ecs_key_visibility),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(
      world, entity, @visibility.ecs_key_inherited_visibility,
    ),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(world, entity, @visibility.ecs_key_view_visibility),
    content="true",
  )
  inspect(
    ecs_transform_matches(world, entity, bundle.transform),
    content="true",
  )
}

///|
test "render2d: Camera2dBundle::spawn inserts expected components" {
  let world = @ecs.World::new()
  let bundle = Camera2dBundle::new(
    Camera::default(),
    @math.Transform::identity(),
  ).with_bloom2d(Bloom2d::new())
  let entity = bundle.spawn(world)

  inspect(world.is_alive(entity), content="true")
  inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_camera2d),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_camera),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_projection),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_pan_camera),
    content="false",
  )
  inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_render_target),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_render_layers),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_bloom2d),
    content="true",
  )
  inspect(
    ecs_transform_matches(world, entity, bundle.transform),
    content="true",
  )
}

///|
test "render2d: Commands::spawn accepts Camera2dBundle" {
  let world = @ecs.World::new()
  let spawned : Ref[@core.Entity?] = Ref::new(None)

  let mut app = @app.App::new(world).add_system_param(fn(
    commands : @app.Commands,
  ) {
    spawned.val = Some(
      commands.spawn(
        Camera2dBundle::new(Camera::default(), @math.Transform::identity()).with_bloom2d(
          Bloom2d::new(),
        ),
      ),
    )
  })
  app = app.run_once()

  guard spawned.val is Some(entity) else {
    abort("expected Commands::spawn to return an entity")
  }
  inspect(
    ecs_has_non_null_payload(app.world(), entity, ecs_key_camera2d),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(app.world(), entity, ecs_key_camera),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(app.world(), entity, ecs_key_bloom2d),
    content="true",
  )
}

///|
test "render2d: Camera2dBundle::new_with_target stores window render target" {
  let world = @ecs.World::new()
  let target_window = @core.Entity::new(7, 2)
  let bundle = Camera2dBundle::new_with_target(
    Camera::default(),
    @math.Transform::identity(),
    RenderTarget::Window(@window.WindowRef::Entity(target_window)),
  )
  let entity = bundle.spawn(world)

  let target : RenderTarget? = try! world.get(entity, ecs_key_render_target)
  inspect(
    target.map(fn(value) {
      value.to_json() ==
      RenderTarget::Window(@window.WindowRef::Entity(target_window)).to_json()
    }),
    content="Some(true)",
  )
}

///|
test "render2d: Mesh2dBundle::spawn inserts expected components" {
  let world = @ecs.World::new()
  let entity_ref : Ref[@core.Entity?] = Ref::new(None)
  let expected_transform = @math.Transform::identity()

  @app.App::new(world)
  .add_plugins([render2d_plugin])
  .add_system(fn(world : @ecs.World) {
    let mesh = Mesh2d::from_rectangle(Rectangle::new(8.0F, 6.0F))
    let material = ColorMaterial::new(Color::white())
    let bundle = Mesh2dBundle::new(mesh, material, expected_transform)
    entity_ref.val = Some(bundle.spawn(world))
  })
  .run_once()
  |> ignore

  inspect(entity_ref.val is Some(_), content="true")
  let entity = entity_ref.val.unwrap_or(@core.Entity::new(0, 0))

  inspect(world.is_alive(entity), content="true")
  inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_mesh2d),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_color_material),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_mesh_material2d),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_gpu_mesh2d),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_render_layers),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(world, entity, @visibility.ecs_key_visibility),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(
      world, entity, @visibility.ecs_key_inherited_visibility,
    ),
    content="true",
  )
  inspect(
    ecs_has_non_null_payload(world, entity, @visibility.ecs_key_view_visibility),
    content="true",
  )
  inspect(
    ecs_transform_matches(world, entity, expected_transform),
    content="true",
  )
}
