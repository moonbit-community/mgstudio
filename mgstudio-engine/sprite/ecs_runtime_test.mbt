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
  (try! world.get_by_key(entity, key)) is Some(_)
}

///|
fn ecs_transform_matches(
  world : @ecs.World,
  entity : @core.Entity,
  expected : @transform.Transform,
) -> Bool {
  let actual_transform = try! world.get_by_key(
    entity, @transform.ecs_key_transform,
  )
  match actual_transform {
    Some(actual) => actual.to_json() == expected.to_json()
    None => false
  }
}

///|
fn dummy_f32_bits(x : Float) -> UInt {
  x.reinterpret_as_uint()
}

///|
struct DummyMaterialAsset {
  color : Color
  checker_frequency : Float
  checker_low_value : Float
}

///|
fn dummy_material_asset(
  color? : Color = Color::white(),
  checker_frequency? : Float = 8.0F,
  checker_low_value? : Float = 0.35F,
) -> DummyMaterialAsset {
  DummyMaterialAsset::{ color, checker_frequency, checker_low_value }
}

///|
fn dummy_material_uniform_bytes(color : Color) -> Bytes {
  let words : Array[UInt] = [
    dummy_f32_bits(color.r),
    dummy_f32_bits(color.g),
    dummy_f32_bits(color.b),
    dummy_f32_bits(color.a),
  ]
  Bytes::makei(words.length() * 4, i => {
    let word = words[i / 4]
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
fn dummy_checker_settings_bytes(
  checker_frequency : Float,
  checker_low_value : Float,
) -> Bytes {
  let words : Array[UInt] = [
    dummy_f32_bits(checker_frequency),
    dummy_f32_bits(checker_low_value),
    dummy_f32_bits(0.0F),
    dummy_f32_bits(0.0F),
  ]
  Bytes::makei(words.length() * 4, i => {
    let word = words[i / 4]
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
fn material2d_bind_group_texture_id(
  bind_group : Material2dBindGroup,
  binding : Int,
) -> Int? {
  guard bind_group.binding(binding) is Some(entry) else { return None }
  match entry.value {
    Texture(Some(texture)) => Some(texture.id())
    _ => None
  }
}

///|
pub impl Material2d for DummyMaterialAsset with alpha_mode(self) {
  self |> ignore
  Blend
}

///|
pub impl Material2d for DummyMaterialAsset with bind_group(self) {
  Material2dBindGroup::new([
    Material2dBinding::uniform(0, dummy_material_uniform_bytes(self.color)),
    Material2dBinding::uniform(
      3,
      dummy_checker_settings_bytes(
        self.checker_frequency,
        self.checker_low_value,
      ),
    ),
  ])
}

///|
fn test_rectangle_mesh(width : Float, height : Float) -> Mesh2d {
  let mesh_assets = mesh_assets_mut_or_abort()
  mesh_assets.set_changed()
  Mesh2d::new(
    mesh_assets
    .peek()
    .add(
      Mesh::from_2d_geometry(
        mesh2d_geometry_rectangle(Rectangle::new(width, height)),
      ),
    ),
  )
}

///|
fn test_color_material_handle(
  color : Color,
) -> @asset.Handle[ColorMaterialAsset] {
  let materials = color_material_assets_mut_or_abort()
  materials.set_changed()
  materials.peek().add(ColorMaterialAsset::from_color(color))
}

///|
fn test_image_material_handle(id : Int) -> @asset.Handle[ColorMaterialAsset] {
  let materials = color_material_assets_mut_or_abort()
  materials.set_changed()
  materials.peek().add(ColorMaterialAsset::from_image(@asset.Handle::new(id)))
}

///|
test "render2d: SpriteBundle::spawn inserts expected components" {
  let world = @ecs.World::new()
  let image : @asset.Handle[@asset.Image] = @asset.Handle::new(1)
  let bundle = SpriteBundle::new(
    Sprite::from_image(image),
    @transform.Transform::identity(),
  )
  let entity = bundle.spawn(world)

  debug_inspect(world.is_alive(entity), content="true")
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_sprite),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_anchor),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_render_layers),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, @visibility.ecs_key_visibility),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(
      world, entity, @visibility.ecs_key_inherited_visibility,
    ),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, @visibility.ecs_key_view_visibility),
    content="true",
  )
  debug_inspect(
    ecs_transform_matches(world, entity, bundle.transform),
    content="true",
  )
}

///|
test "render2d: Sprite::sized uses the white texture handle" {
  let size = @math.Vec2::new(24.0F, 16.0F)
  let sprite = Sprite::sized(size)
  let white = @asset.asset_white_texture()
  let matches_size = match sprite.custom_size {
    Some(custom_size) => custom_size.x == size.x && custom_size.y == size.y
    None => false
  }
  debug_inspect(matches_size, content="true")
  debug_inspect(sprite.image.id() == white.id(), content="true")
}

///|
test "render2d: Commands can spawn SpriteBundle" {
  let spawned : Ref[@core.Entity?] = Ref::new(None)
  let bundle = SpriteBundle::new_with_layers(
    Sprite::from_image(@asset.Handle::new(7)),
    @transform.Transform::identity(),
    RenderLayers::layer(2),
  )
  let mut app = @app.App::new(@ecs.World::new()).add_system_param(fn(
    commands : @app.Commands,
  ) {
    spawned.val = Some(commands.spawn(bundle))
  })

  app = app.run_once()

  guard spawned.val is Some(entity) else {
    abort("expected Commands::spawn(SpriteBundle) to return an entity")
  }
  debug_inspect(
    ecs_has_non_null_payload(app.world(), entity, ecs_key_sprite),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(app.world(), entity, ecs_key_render_layers),
    content="true",
  )
  debug_inspect(
    ecs_transform_matches(app.world(), entity, bundle.transform),
    content="true",
  )
}

///|
test "render2d: Camera2dBundle::spawn inserts expected components" {
  let world = @ecs.World::new()
  let bundle = Camera2dBundle::new(
      Camera::default(),
      @transform.Transform::identity(),
    )
    .with_bloom(Some(Bloom::default()))
    .with_color_grading(Some(ColorGrading::default()))
  let entity = bundle.spawn(world)

  debug_inspect(world.is_alive(entity), content="true")
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_camera2d),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_camera),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_projection),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_pan_camera),
    content="false",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_render_target),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_render_layers),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_bloom),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_tonemapping),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_deband_dither),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_color_grading),
    content="true",
  )
  debug_inspect(
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
        Camera2dBundle::new(Camera::default(), @transform.Transform::identity())
        .with_bloom(Some(Bloom::default()))
        .with_color_grading(Some(ColorGrading::default())),
      ),
    )
  })
  app = app.run_once()

  guard spawned.val is Some(entity) else {
    abort("expected Commands::spawn to return an entity")
  }
  debug_inspect(
    ecs_has_non_null_payload(app.world(), entity, ecs_key_camera2d),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(app.world(), entity, ecs_key_camera),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(app.world(), entity, ecs_key_bloom),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(app.world(), entity, ecs_key_color_grading),
    content="true",
  )
}

///|
test "render2d: tonemapping and deband components share post_process ownership" {
  let world = @ecs.World::new()
  let entity = Camera2dBundle::new(
      Camera::default(),
      @transform.Transform::identity(),
    )
    .with_tonemapping(Some(AgX))
    .with_deband_dither(Some(Enabled))
    .spawn(world)

  let tonemapping_ok = match
    (try! world.get_by_key(entity, @post_process.ecs_key_tonemapping)) {
    Some(AgX) => true
    _ => false
  }
  let deband_ok = match
    (try! world.get_by_key(entity, @post_process.ecs_key_deband_dither)) {
    Some(Enabled) => true
    _ => false
  }
  debug_inspect(tonemapping_ok, content="true")
  debug_inspect(deband_ok, content="true")
}

///|
test "render2d: bloom component shares post_process ownership" {
  let world = @ecs.World::new()
  let entity = Camera2dBundle::new(
      Camera::default(),
      @transform.Transform::identity(),
    )
    .with_bloom(Some(Bloom::default().with_intensity(0.35F)))
    .spawn(world)

  let bloom_ok = match
    (try! world.get_by_key(entity, @post_process.ecs_key_bloom)) {
    Some(bloom) => bloom.intensity == 0.35F
    None => false
  }
  debug_inspect(bloom_ok, content="true")
}

///|
test "render2d: required components align Camera2d and Bloom with Bevy camera authoring" {
  let world = @ecs.World::new()
  try! register_render2d_required_components(world)
  let entity = world.spawn_empty()

  try! (world.set_by_key(entity, ecs_key_camera2d, Camera2d::default())
  |> ignore)
  try! (world.set_by_key(entity, ecs_key_bloom, Bloom::natural()) |> ignore)

  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_camera),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_projection),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, @transform.ecs_key_transform),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_render_target),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_render_layers),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_tonemapping),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_deband_dither),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_hdr),
    content="true",
  )

  let tonemapping_ok = match
    (try! world.get_by_key(entity, ecs_key_tonemapping)) {
    Some(None) => true
    _ => false
  }
  let target_ok = match (try! world.get_by_key(entity, ecs_key_render_target)) {
    Some(Screen) => true
    _ => false
  }
  debug_inspect(tonemapping_ok, content="true")
  debug_inspect(target_ok, content="true")
}

///|
test "render2d: Camera2dBundle::new_with_target stores window render target" {
  let world = @ecs.World::new()
  let target_window = @core.Entity::new(7, 2)
  let bundle = Camera2dBundle::new_with_target(
    Camera::default(),
    @transform.Transform::identity(),
    RenderTarget::Window(@window.WindowRef::Entity(target_window)),
  )
  let entity = bundle.spawn(world)

  let target : RenderTarget? = try! world.get_by_key(
    entity, ecs_key_render_target,
  )
  debug_inspect(
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
  let expected_transform = @transform.Transform::identity()

  @app.App::new(world)
  .add_plugins(@asset.AssetPlugin::default())
  .add_plugins(@mesh.MeshPlugin::default())
  .add_plugins(@render.RenderPlugin::default())
  .add_plugins(Render2dPlugin::default())
  .add_system(fn(world : @ecs.World) {
    let mesh = test_rectangle_mesh(8.0F, 6.0F)
    let material = MeshMaterial2d::new(
      test_color_material_handle(Color::white()),
    )
    let bundle = Mesh2dBundle::new_with_mesh_material(
      mesh, material, expected_transform,
    )
    entity_ref.val = Some(bundle.spawn(world))
  })
  .run_once()
  |> ignore

  debug_inspect(entity_ref.val is Some(_), content="true")
  let entity = entity_ref.val.unwrap_or(@core.Entity::new(0, 0))

  debug_inspect(world.is_alive(entity), content="true")
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_mesh2d),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_color_material),
    content="false",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_mesh_material2d),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, ecs_key_render_layers),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, @visibility.ecs_key_visibility),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(
      world, entity, @visibility.ecs_key_inherited_visibility,
    ),
    content="true",
  )
  debug_inspect(
    ecs_has_non_null_payload(world, entity, @visibility.ecs_key_view_visibility),
    content="true",
  )
  debug_inspect(
    ecs_transform_matches(world, entity, expected_transform),
    content="true",
  )
}

///|
test "render2d: plain Mesh2d authoring extracts render mesh without gpu cache component" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::default())
    .add_plugins(@mesh.MeshPlugin::default())
    .add_plugins(@render.RenderPlugin::default())
    .add_plugins(Render2dPlugin::default())
    .add_systems(
      @app.Startup,
      @app.system(
        @app.system_param3(fn(
          commands : @app.Commands,
          meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
          materials : @app.ResMut[@asset.Assets[ColorMaterialAsset]],
        ) {
          ignore(commands.spawn_component(Camera2d::default()))
          meshes.set_changed()
          let mesh_handle = meshes
            .peek()
            .add(
              Mesh::from_2d_geometry(
                mesh2d_geometry_rectangle(Rectangle::new(8.0F, 6.0F)),
              ),
            )
          materials.set_changed()
          let material_handle = materials
            .peek()
            .add(ColorMaterialAsset::from_color(Color::white()))
          ignore(
            commands.spawn(
              (
                Mesh2d::new(mesh_handle),
                MeshMaterial2d::new(material_handle),
                @transform.Transform::identity(),
              ),
            ),
          )
        }),
      ),
    )

  app = app.update()

  let mesh_query : @ecs.Query[@ecs.Comp[Mesh2d], @ecs.All] = @ecs.query(
    app.world(),
  )
  debug_inspect(mesh_query.count(), content="1")
  debug_inspect(
    render2d_diagnostic_queued_draw_item_count() > 0,
    content="true",
  )
}

///|
test "sprite: SpritePlugin calculate_bounds_2d inserts Aabb for Mesh2d" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::default())
    .add_plugins(@mesh.MeshPlugin::default())
    .add_plugins(SpritePlugin::default())
  let world = app.world()
  let mesh_assets_key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  let mesh_assets = (try! world.get_resource_mut(mesh_assets_key)).unwrap()
  mesh_assets.set_changed()
  let mesh_handle = mesh_assets
    .peek()
    .add(
      Mesh::from_2d_geometry(
        mesh2d_geometry_rectangle(Rectangle::new(8.0F, 6.0F)),
      ),
    )
  let entity = world.spawn()
  try! world.set_by_key(entity, @mesh.ecs_key_mesh2d, Mesh2d::new(mesh_handle))

  app = app.update()

  let aabb = try! app
    .world()
    .get_by_key(entity, @camera_primitives.ecs_key_aabb)
  debug_inspect(aabb is Some(_), content="true")
  if aabb is Some(value) {
    let center = value.center()
    let half_size = value.half_size()
    debug_inspect(center.x.to_double(), content="0")
    debug_inspect(center.y.to_double(), content="0")
    debug_inspect(center.z.to_double(), content="0")
    debug_inspect(half_size.x.to_double(), content="4")
    debug_inspect(half_size.y.to_double(), content="3")
    debug_inspect(half_size.z.to_double(), content="0")
  }
}

///|
test "sprite: SpritePlugin calculate_bounds_2d respects NoAutoAabb marker" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::default())
    .add_plugins(@mesh.MeshPlugin::default())
    .add_plugins(SpritePlugin::default())
  let world = app.world()
  let mesh_assets_key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  let mesh_assets = (try! world.get_resource_mut(mesh_assets_key)).unwrap()
  mesh_assets.set_changed()
  let mesh_handle = mesh_assets
    .peek()
    .add(
      Mesh::from_2d_geometry(
        mesh2d_geometry_rectangle(Rectangle::new(8.0F, 6.0F)),
      ),
    )
  let entity = world.spawn()
  try! world.set_by_key(entity, @mesh.ecs_key_mesh2d, Mesh2d::new(mesh_handle))
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_no_auto_aabb,
    @visibility.NoAutoAabb::default(),
  )

  app = app.update()

  let aabb = try! app
    .world()
    .get_by_key(entity, @camera_primitives.ecs_key_aabb)
  debug_inspect(aabb is Some(_), content="false")
}

///|
test "sprite: SpritePlugin calculate_bounds_2d inserts Aabb for Sprite" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::default())
    .add_plugins(@mesh.MeshPlugin::default())
    .add_plugins(SpritePlugin::default())
  let world = app.world()
  let image = @asset.asset_create_dynamic_texture(
    @math.UVec2::new(40, 20),
    true,
  )
  let entity = world.spawn()
  try! world.set_by_key(entity, ecs_key_sprite, Sprite::from_image(image))
  try! world.set_by_key(entity, ecs_key_anchor, Anchor::center())

  app = app.update()

  let aabb = try! app
    .world()
    .get_by_key(entity, @camera_primitives.ecs_key_aabb)
  debug_inspect(aabb is Some(_), content="true")
  if aabb is Some(value) {
    let center = value.center()
    let half_size = value.half_size()
    debug_inspect(center.x.to_double(), content="0")
    debug_inspect(center.y.to_double(), content="0")
    debug_inspect(center.z.to_double(), content="0")
    debug_inspect(half_size.x.to_double(), content="20")
    debug_inspect(half_size.y.to_double(), content="10")
    debug_inspect(half_size.z.to_double(), content="0")
  }
}

///|
test "render2d: Mesh2dBundle constructors normalize to MeshMaterial2d" {
  let wrapped_material_handle : Ref[Int?] = Ref::new(None)
  let preserved_material_handle : Ref[Int?] = Ref::new(None)
  let color_material_handle : Ref[Int?] = Ref::new(None)
  let explicit_mesh_material_handle : Ref[Int?] = Ref::new(None)

  @app.App::new(@ecs.World::new())
  .add_plugins(@asset.AssetPlugin::default())
  .add_plugins(@mesh.MeshPlugin::default())
  .add_plugins(@render.RenderPlugin::default())
  .add_plugins(Render2dPlugin::default())
  .add_system(fn(_world : @ecs.World) {
    let material_handle = test_color_material_handle(Color::white())
    let mesh_material = MeshMaterial2d::new(material_handle)
    let mesh = test_rectangle_mesh(4.0F, 4.0F)

    let wrapped_bundle = Mesh2dBundle::new_with_mesh_material(
      mesh,
      MeshMaterial2d::new(material_handle),
      @transform.Transform::identity(),
    )
    let preserved_bundle = Mesh2dBundle::new_with_mesh_material(
      mesh,
      mesh_material,
      @transform.Transform::identity(),
    )

    wrapped_material_handle.val = Some(wrapped_bundle.material.handle.id())
    preserved_material_handle.val = Some(preserved_bundle.material.handle.id())
    color_material_handle.val = Some(material_handle.id())
    explicit_mesh_material_handle.val = Some(mesh_material.handle.id())
  })
  .run_once()
  |> ignore

  debug_inspect(
    wrapped_material_handle.val == color_material_handle.val,
    content="true",
  )
  debug_inspect(
    preserved_material_handle.val == explicit_mesh_material_handle.val,
    content="true",
  )
}

///|
test "render2d: ColorMaterialPlugin initializes the Bevy default material handle" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@render.RenderPlugin::default())
    .add_plugins(ColorMaterialPlugin::default())
  let key : @ecs.ResourceKey[@asset.Assets[ColorMaterialAsset]] = @asset.assets_resource_key()
  let assets = try! app.world().get_resource(key).unwrap()
  let handle : @asset.Handle[ColorMaterialAsset] = @asset.Handle::new(0)
  let material = assets.get(handle).unwrap()

  debug_inspect(assets.contains(handle), content="true")
  debug_inspect(material.color.r.to_double(), content="1")
  debug_inspect(material.color.g.to_double(), content="0")
  debug_inspect(material.color.b.to_double(), content="1")
  debug_inspect(material.color.a.to_double(), content="1")
  debug_inspect(material.alpha_mode is Blend, content="true")
  debug_inspect(material.texture is None, content="true")
}

///|
test "render2d: Material2dPlugin initializes generic material asset resources" {
  let plugin : Material2dPlugin[DummyMaterialAsset] = Material2dPlugin::default()
    .with_asset_init(fn() { dummy_material_asset() })
    .with_vertex_shader("sprite_render/mesh2d/mesh2d.wgsl")
    .with_fragment_shader("shaders/mesh2d_checker_material.wgsl")
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@render.RenderPlugin::default())
    .add_plugins(plugin)
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let key : @ecs.ResourceKey[@asset.Assets[DummyMaterialAsset]] = @asset.assets_resource_key()
  let prepared_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial2d[DummyMaterialAsset]],
  ] = @render.RenderAssets::resource()
  let instances_key : @ecs.ResourceKey[
    RenderMaterial2dInstances[DummyMaterialAsset],
  ] = RenderMaterial2dInstances::resource()
  let pipeline_key : @ecs.ResourceKey[Material2dPipeline[DummyMaterialAsset]] = Material2dPipeline::resource()
  let registry_key : @ecs.ResourceKey[Material2dRuntimeRegistry] = Material2dRuntimeRegistry::resource()
  let pipeline = try! render_world.get_resource(pipeline_key).unwrap()
  let registry = try! render_world.get_resource(registry_key).unwrap()
  let probe : @asset.Handle[DummyMaterialAsset] = @asset.Handle::new(0)

  debug_inspect(app.contains_resource(key), content="true")
  debug_inspect(
    (try! render_world.get_resource(prepared_key)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! render_world.get_resource(instances_key)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! render_world.get_resource(pipeline_key)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! render_world.get_resource(registry_key)) is Some(_),
    content="true",
  )
  debug_inspect(
    pipeline.vertex_shader,
    content="Some(\"sprite_render/mesh2d/mesh2d.wgsl\")",
  )
  debug_inspect(
    pipeline.fragment_shader,
    content="Some(\"shaders/mesh2d_checker_material.wgsl\")",
  )
  debug_inspect(registry.entry_count(), content="1")
  debug_inspect(
    registry.contains_type_name(material2d_runtime_type_name(probe)),
    content="true",
  )
}

///|
test "render2d: generic Material2d runtime extracts and prepares custom assets" {
  let entity_ref : Ref[@core.Entity?] = Ref::new(None)
  let handle_ref : Ref[@asset.Handle[DummyMaterialAsset]?] = Ref::new(None)
  let expected = dummy_material_asset(
    color=Color::new(0.3F, 0.6F, 0.9F, 1.0F),
    checker_frequency=5.0F,
    checker_low_value=0.2F,
  )

  let plugin : Material2dPlugin[DummyMaterialAsset] = Material2dPlugin::default()
    .with_asset_init(fn() { dummy_material_asset() })
    .with_vertex_shader("sprite_render/mesh2d/mesh2d.wgsl")
    .with_fragment_shader("shaders/mesh2d_checker_material.wgsl")
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::default())
    .add_plugins(@render.RenderPlugin::default())
    .add_plugins(plugin)
  app = app.add_system(fn(world : @ecs.World) {
    let handle : @asset.Handle[DummyMaterialAsset] = @asset.Handle::new(21)
    handle_ref.val = Some(handle)
    let key : @ecs.ResourceKey[@asset.Assets[DummyMaterialAsset]] = @asset.assets_resource_key()
    guard (try! world.get_resource_mut(key)) is Some(assets_ref) else {
      abort("expected DummyMaterialAsset asset store")
    }
    assets_ref.set_changed()
    assets_ref.peek().insert(handle, expected) |> ignore
    let entity = world.spawn()
    entity_ref.val = Some(entity)
    let material_key : @ecs.ComponentKey[MeshMaterial2d[DummyMaterialAsset]] = MeshMaterial2d::component()
    try! (world.set_by_key(entity, material_key, MeshMaterial2d::new(handle))
    |> ignore)
  })
  app = app.run_once()

  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let entity = entity_ref.val.unwrap_or(@core.Entity::new(0, 0))
  let handle = handle_ref.val.unwrap_or(@asset.Handle::new(-1))
  let instances_key : @ecs.ResourceKey[
    RenderMaterial2dInstances[DummyMaterialAsset],
  ] = RenderMaterial2dInstances::resource()
  let prepared_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial2d[DummyMaterialAsset]],
  ] = @render.RenderAssets::resource()
  let instances = try! render_world.get_resource(instances_key).unwrap()
  let prepared_assets = try! render_world.get_resource(prepared_key).unwrap()
  let prepared = prepared_assets
    .get(handle.id())
    .unwrap()

  debug_inspect(instances.contains(entity), content="true")
  debug_inspect(
    instances.get(entity).map(fn(value) { value.id() == handle.id() }),
    content="Some(true)",
  )
  debug_inspect(prepared.source.id() == handle.id(), content="true")
  debug_inspect(
    prepared.bind_group.layout_key(),
    content="\"0:uniform;3:uniform\"",
  )
  debug_inspect(
    prepared.key.bind_group_layout_key == prepared.bind_group.layout_key(),
    content="true",
  )
  debug_inspect(
    prepared.key.bind_group_data == expected.bind_group().bind_group_data(),
    content="true",
  )
}

///|
test "render2d: extract_color_material_mesh_instances_system populates resource" {
  let entity_ref : Ref[@core.Entity?] = Ref::new(None)
  let handle_ref : Ref[@asset.Handle[ColorMaterialAsset]?] = Ref::new(None)

  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::default())
    .add_plugins(@mesh.MeshPlugin::default())
    .add_plugins(@render.RenderPlugin::default())
    .add_plugins(Render2dPlugin::default())
  app = app.add_system(fn(world : @ecs.World) {
    let material_handle = test_image_material_handle(7)
    handle_ref.val = Some(material_handle)
    entity_ref.val = Some(
      Mesh2dBundle::new_with_mesh_material(
        test_rectangle_mesh(8.0F, 6.0F),
        MeshMaterial2d::new(material_handle),
        @transform.Transform::identity(),
      ).spawn(world),
    )
  })
  app = app.run_once()
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let entity = entity_ref.val.unwrap_or(@core.Entity::new(0, 0))
  let handle = handle_ref.val.unwrap_or(@asset.Handle::new(-1))

  let instances_key : @ecs.ResourceKey[
    RenderMaterial2dInstances[ColorMaterialAsset],
  ] = RenderMaterial2dInstances::resource()
  let instances = try! render_world.get_resource(instances_key).unwrap()

  debug_inspect(instances.contains(entity), content="true")
  debug_inspect(
    instances.get(entity).map(fn(value) { value.id() == handle.id() }),
    content="Some(true)",
  )
}

///|
test "render2d: prepare_color_material2d_assets_system populates prepared assets" {
  let handle_ref : Ref[@asset.Handle[ColorMaterialAsset]?] = Ref::new(None)

  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::default())
    .add_plugins(@mesh.MeshPlugin::default())
    .add_plugins(@render.RenderPlugin::default())
    .add_plugins(Render2dPlugin::default())
  app = app.add_system(fn(world : @ecs.World) {
    let material_handle = test_image_material_handle(11)
    handle_ref.val = Some(material_handle)
    Mesh2dBundle::new_with_mesh_material(
      test_rectangle_mesh(8.0F, 6.0F),
      MeshMaterial2d::new(material_handle),
      @transform.Transform::identity(),
    ).spawn(world)
    |> ignore
  })
  app = app.run_once()
  let world = app.world()
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let handle = handle_ref.val.unwrap_or(@asset.Handle::new(-1))
  let source_key : @ecs.ResourceKey[@asset.Assets[ColorMaterialAsset]] = @asset.assets_resource_key()
  let prepared_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial2d[ColorMaterialAsset]],
  ] = @render.RenderAssets::resource()
  let pipeline_key : @ecs.ResourceKey[Material2dPipeline[ColorMaterialAsset]] = Material2dPipeline::resource()
  let source_assets = try! world.get_resource(source_key).unwrap()
  let prepared_assets = try! render_world.get_resource(prepared_key).unwrap()
  let pipeline = try! render_world.get_resource(pipeline_key).unwrap()
  let source_material = source_assets.get(handle).unwrap()
  let prepared = prepared_assets.get(handle.id()).unwrap()

  debug_inspect(prepared.source.id() == handle.id(), content="true")
  debug_inspect(
    material2d_bind_group_texture_id(prepared.bind_group, 1),
    content="Some(11)",
  )
  debug_inspect(prepared.properties.alpha_mode is Blend, content="true")
  debug_inspect(
    prepared.key.mesh_key == prepared.properties.mesh_pipeline_key_bits,
    content="true",
  )
  debug_inspect(
    prepared.key.bind_group_layout_key == prepared.bind_group.layout_key(),
    content="true",
  )
  debug_inspect(
    prepared.key.bind_group_data ==
    source_material.bind_group().bind_group_data(),
    content="true",
  )
  debug_inspect(
    pipeline.vertex_shader,
    content="Some(\"sprite_render/mesh2d/mesh2d.wgsl\")",
  )
  debug_inspect(
    pipeline.fragment_shader,
    content="Some(\"sprite_render/mesh2d/color_material.wgsl\")",
  )
}

///|
test "render2d: MeshMaterial2d component keys are registered per material type" {
  let color_key : @ecs.ComponentKey[MeshMaterial2d[ColorMaterialAsset]] = ecs_key_mesh_material2d
  let color_key_from_trait : @ecs.ComponentKey[
    MeshMaterial2d[ColorMaterialAsset],
  ] = MeshMaterial2d::component()
  let dummy_key : @ecs.ComponentKey[MeshMaterial2d[DummyMaterialAsset]] = MeshMaterial2d::component()

  debug_inspect(color_key.id() == color_key_from_trait.id(), content="true")
  debug_inspect(color_key.id() == dummy_key.id(), content="false")
}

///|
test "render2d: ColorMaterialAsset::from_color matches Bevy alpha inference" {
  let opaque_alpha_mode : Ref[AlphaMode2d?] = Ref::new(None)
  let blend_alpha_mode : Ref[AlphaMode2d?] = Ref::new(None)

  @app.App::new(@ecs.World::new())
  .add_plugins(@asset.AssetPlugin::default())
  .add_plugins(@mesh.MeshPlugin::default())
  .add_plugins(@render.RenderPlugin::default())
  .add_plugins(Render2dPlugin::default())
  .add_system(fn(_world : @ecs.World) {
    opaque_alpha_mode.val = Some(
      ColorMaterialAsset::from_color(Color::white()).alpha_mode(),
    )
    blend_alpha_mode.val = Some(
      ColorMaterialAsset::from_color(Color::new(0.25F, 0.5F, 0.75F, 0.4F)).alpha_mode(),
    )
  })
  .run_once()
  |> ignore

  debug_inspect(
    opaque_alpha_mode.val.map(fn(mode) { mode is Opaque }),
    content="Some(true)",
  )
  debug_inspect(
    blend_alpha_mode.val.map(fn(mode) { mode is Blend }),
    content="Some(true)",
  )
}
