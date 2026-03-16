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
struct DummyMaterialAsset {}

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
  .add_plugins([@asset.asset_plugin, render2d_plugin])
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
    content="false",
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

///|
test "render2d: Mesh2dBundle constructors normalize to MeshMaterial2d" {
  let wrapped_material_handle : Ref[Int?] = Ref::new(None)
  let preserved_material_handle : Ref[Int?] = Ref::new(None)
  let color_material_handle : Ref[Int?] = Ref::new(None)
  let explicit_mesh_material_handle : Ref[Int?] = Ref::new(None)

  @app.App::new(@ecs.World::new())
  .add_plugins([@asset.asset_plugin, render2d_plugin])
  .add_system(fn(_world : @ecs.World) {
    let color_material = ColorMaterial::new(Color::white())
    let mesh_material = MeshMaterial2d::from_color_material(color_material)
    let mesh = Mesh2d::from_rectangle(Rectangle::new(4.0F, 4.0F))

    let wrapped_bundle = Mesh2dBundle::new(
      mesh,
      color_material,
      @math.Transform::identity(),
    )
    let preserved_bundle = Mesh2dBundle::new_with_mesh_material(
      mesh,
      mesh_material,
      @math.Transform::identity(),
    )

    wrapped_material_handle.val = Some(wrapped_bundle.material.handle.id())
    preserved_material_handle.val = Some(preserved_bundle.material.handle.id())
    color_material_handle.val = Some(color_material.handle.id())
    explicit_mesh_material_handle.val = Some(mesh_material.handle.id())
  })
  .run_once()
  |> ignore

  inspect(
    wrapped_material_handle.val == color_material_handle.val,
    content="true",
  )
  inspect(
    preserved_material_handle.val == explicit_mesh_material_handle.val,
    content="true",
  )
}

///|
test "render2d: ColorMaterialPlugin initializes the Bevy default material handle" {
  let app = @app.App::new(@ecs.World::new()).add_plugins([
    color_material_plugin(ColorMaterialPlugin::default()),
  ])
  let key : @ecs.ResourceKey[@asset.Assets[ColorMaterialAsset]] = @asset.assets_resource_key()
  let assets = try! app.world().get_resource(key).unwrap()
  let handle : @asset.Handle[ColorMaterialAsset] = @asset.Handle::new(0)
  let material = assets.get(handle).unwrap()

  inspect(assets.contains(handle), content="true")
  inspect(material.color.r.to_double(), content="1")
  inspect(material.color.g.to_double(), content="0")
  inspect(material.color.b.to_double(), content="1")
  inspect(material.color.a.to_double(), content="1")
  inspect(material.alpha_mode is Blend, content="true")
  inspect(material.texture is None, content="true")
}

///|
test "render2d: Material2dPlugin initializes generic material asset resources" {
  DummyMaterialAsset::{  } |> ignore
  let plugin : Material2dPlugin[DummyMaterialAsset] = Material2dPlugin::default()
  let app = @app.App::new(@ecs.World::new()).add_plugins([
    material2d_plugin(plugin),
  ])
  let key : @ecs.ResourceKey[@asset.Assets[DummyMaterialAsset]] = @asset.assets_resource_key()

  inspect(app.contains_resource(key), content="true")
}

///|
test "render2d: MeshMaterial2d component keys are registered per material type" {
  let color_key : @ecs.ComponentKey[MeshMaterial2d[ColorMaterialAsset]] = ecs_key_mesh_material2d
  let color_key_from_trait : @ecs.ComponentKey[
    MeshMaterial2d[ColorMaterialAsset],
  ] = MeshMaterial2d::component()
  let dummy_key : @ecs.ComponentKey[MeshMaterial2d[DummyMaterialAsset]] = MeshMaterial2d::component()

  inspect(color_key.id() == color_key_from_trait.id(), content="true")
  inspect(color_key.id() == dummy_key.id(), content="false")
}

///|
test "render2d: ColorMaterial::new matches Bevy alpha inference" {
  let opaque_alpha_mode : Ref[AlphaMode2d?] = Ref::new(None)
  let blend_alpha_mode : Ref[AlphaMode2d?] = Ref::new(None)

  @app.App::new(@ecs.World::new())
  .add_plugins([@asset.asset_plugin, render2d_plugin])
  .add_system(fn(_world : @ecs.World) {
    opaque_alpha_mode.val = Some(
      ColorMaterial::new(Color::white()).alpha_mode(),
    )
    blend_alpha_mode.val = Some(
      ColorMaterial::new(Color::new(0.25F, 0.5F, 0.75F, 0.4F)).alpha_mode(),
    )
  })
  .run_once()
  |> ignore

  inspect(
    opaque_alpha_mode.val.map(fn(mode) { mode is Opaque }),
    content="Some(true)",
  )
  inspect(
    blend_alpha_mode.val.map(fn(mode) { mode is Blend }),
    content="Some(true)",
  )
}
