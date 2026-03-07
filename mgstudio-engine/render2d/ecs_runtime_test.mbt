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
test "render2d: Mesh2dBundle::spawn inserts expected components" {
  let world = @ecs.World::new()
  let mesh = Mesh2d::from_rectangle(Rectangle::new(8.0F, 6.0F))
  let material = ColorMaterial::new(Color::white())
  let bundle = Mesh2dBundle::new(mesh, material, @math.Transform::identity())
  let entity = bundle.spawn(world)

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
    ecs_transform_matches(world, entity, bundle.transform),
    content="true",
  )
}
