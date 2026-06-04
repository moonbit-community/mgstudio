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
fn sprite_test_u32le_word(bytes : Bytes, index : Int) -> UInt {
  let offset = index * 4
  bytes[offset].to_uint() |
  (bytes[offset + 1].to_uint() << 8) |
  (bytes[offset + 2].to_uint() << 16) |
  (bytes[offset + 3].to_uint() << 24)
}

///|
fn sprite_test_close(a : Float, b : Float) -> Bool {
  let delta = a - b
  delta > -0.0001F && delta < 0.0001F
}

///|
struct TestCustomMesh2d {}

///|
let test_custom_mesh2d_key : @ecs.ComponentKey[TestCustomMesh2d] = @ecs.register_component(
  debug_name="mgstudio_sprite_test::TestCustomMesh2d",
)

///|
pub impl @ecs.Component for TestCustomMesh2d with fn component() {
  test_custom_mesh2d_key
}

///|
test "sprite: default trait mirrors bevy component defaults" {
  let sprite = @sprite.Sprite::Sprite()
  let image_mode = SpriteImageMode::default()
  let scaling_mode = SpriteScalingMode::default()
  let anchor = @sprite.Anchor::Anchor()
  let clear_color = @camera_clear_color.ClearColor::ClearColor()
  debug_inspect(sprite.image.id(), content="0")
  debug_inspect(image_mode is SpriteImageMode::Auto, content="true")
  debug_inspect(scaling_mode is SpriteScalingMode::FillCenter, content="true")
  debug_inspect(anchor.as_vec().x.to_double(), content="0")
  debug_inspect(anchor.as_vec().y.to_double(), content="0")
  debug_inspect(clear_color.color.r.to_double(), content="0.024157630279660225")
}

///|
test "sprite: image mode scale accessor mirrors bevy" {
  let scaled = SpriteImageMode::Scale(SpriteScalingMode::FitEnd)
  let auto = SpriteImageMode::Auto
  debug_inspect(
    scaled.scale() is Some(SpriteScalingMode::FitEnd),
    content="true",
  )
  debug_inspect(auto.scale() is None, content="true")
}

///|
struct DummyMaterialAsset {
  color : Color
  color_texture : @asset.Handle[@asset.Image]?
}

///|
impl @asset.Asset for DummyMaterialAsset with fn asset_debug_name() {
  "mgstudio_sprite_test::DummyMaterialAsset"
}

///|
impl @asset.Asset for DummyMaterialAsset with fn asset_as_image(_self) {
  None
}

///|
let dummy_material_asset_resource_keys : @asset.AssetResourceKeys[
  DummyMaterialAsset,
] = @asset.register_asset_resource_keys(DummyMaterialAsset::asset_debug_name())

///|
impl @asset.Asset for DummyMaterialAsset with fn asset_resource_keys() {
  dummy_material_asset_resource_keys
}

///|
fn dummy_material_asset(
  color? : Color = Color::white(),
  color_texture? : @asset.Handle[@asset.Image]? = None,
) -> DummyMaterialAsset {
  DummyMaterialAsset::{ color, color_texture }
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
fn material2d_bind_group_texture_id(
  bind_group : Material2dBindGroup,
  binding : Int,
) -> Int? {
  guard bind_group.binding(binding) is Some(entry) else { return None }
  match entry.value {
    Texture(Some(texture), _, _) => Some(texture.id())
    _ => None
  }
}

///|
pub impl Material2d for DummyMaterialAsset with fn alpha_mode(self) {
  self |> ignore
  Blend
}

///|
pub impl Material2d for DummyMaterialAsset with fn material2d_debug_name() {
  "mgstudio_sprite_test::DummyMaterialAsset"
}

///|
let dummy_material_asset_material2d_keys : Material2dKeys[DummyMaterialAsset] = register_material2d_keys(
  DummyMaterialAsset::material2d_debug_name(),
)

///|
pub impl Material2d for DummyMaterialAsset with fn material2d_keys() {
  dummy_material_asset_material2d_keys
}

///|
pub impl Material2d for DummyMaterialAsset with fn bind_group(self) {
  let texture = match self.color_texture {
    Some(texture) => texture
    None => @asset.asset_white_texture()
  }
  Material2dBindGroup::new([
    Material2dBinding::uniform(0, dummy_material_uniform_bytes(self.color)),
    Material2dBinding::texture(1, Some(texture)),
    Material2dBinding::sampler(2, Some(texture)),
  ])
}

///|
fn test_rectangle_mesh(width : Float, height : Float) -> @mesh.Mesh2d {
  let mesh_assets = mesh_assets_mut_or_abort()
  mesh_assets.set_changed()
  @mesh.Mesh2d::new(
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
  materials.modify(fn(store) {
    store.add(ColorMaterialAsset::from_color(color))
  })
}

///|
fn test_image_material_handle(id : Int) -> @asset.Handle[ColorMaterialAsset] {
  let materials = color_material_assets_mut_or_abort()
  materials.modify(fn(store) {
    store.add(ColorMaterialAsset::from_image(@asset.Handle::new(id)))
  })
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
    ecs_has_non_null_payload(
      world, entity, @camera_render_layers.ecs_key_render_layers,
    ),
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
  let spawned : Ref[@core.Entity?] = Ref(None)
  let bundle = SpriteBundle::new_with_layers(
    Sprite::from_image(@asset.Handle::new(7)),
    @transform.Transform::identity(),
    @camera_render_layers.RenderLayers::layer(2),
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
    ecs_has_non_null_payload(
      app.world(),
      entity,
      @camera_render_layers.ecs_key_render_layers,
    ),
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
      Camera::Camera(),
      @transform.Transform::identity(),
    )
    .with_bloom(Some(@post_process.Bloom::Bloom()))
    .with_color_grading(Some(ColorGrading()))
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
    ecs_has_non_null_payload(
      world, entity, @camera_render_layers.ecs_key_render_layers,
    ),
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
  let spawned : Ref[@core.Entity?] = Ref(None)

  let mut app = @app.App::new(world).add_system_param(fn(
    commands : @app.Commands,
  ) {
    spawned.val = Some(
      commands.spawn(
        Camera2dBundle::new(Camera::Camera(), @transform.Transform::identity())
        .with_bloom(Some(@post_process.Bloom::Bloom()))
        .with_color_grading(Some(ColorGrading())),
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
      Camera::Camera(),
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
      Camera::Camera(),
      @transform.Transform::identity(),
    )
    .with_bloom(Some(@post_process.Bloom::Bloom().with_intensity(0.35F)))
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

  try! (world.set_by_key(entity, ecs_key_camera2d, @sprite.Camera2d::Camera2d())
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
    ecs_has_non_null_payload(
      world, entity, @camera_render_layers.ecs_key_render_layers,
    ),
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
    Camera::Camera(),
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
  let entity_ref : Ref[@core.Entity?] = Ref(None)
  let expected_transform = @transform.Transform::identity()

  @app.App::new(world)
  .add_plugins(@asset.AssetPlugin::AssetPlugin())
  .add_plugins(@mesh.MeshPlugin::MeshPlugin())
  .add_plugins(@render.RenderPlugin::RenderPlugin())
  .add_plugins(@sprite.Render2dPlugin::Render2dPlugin())
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
    ecs_has_non_null_payload(world, entity, @mesh.ecs_key_mesh2d),
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
    ecs_has_non_null_payload(
      world, entity, @camera_render_layers.ecs_key_render_layers,
    ),
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
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@mesh.MeshPlugin::MeshPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(@sprite.Render2dPlugin::Render2dPlugin())
    .add_systems(
      @app.Startup,
      @app.system_config_param3(fn(
        commands : @app.Commands,
        meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
        materials : @app.ResMut[@asset.Assets[ColorMaterialAsset]],
      ) {
        ignore(commands.spawn_component(@sprite.Camera2d::Camera2d()))
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
              @mesh.Mesh2d::new(mesh_handle),
              MeshMaterial2d::new(material_handle),
              @transform.Transform::identity(),
            ),
          ),
        )
      }),
    )

  app = app.update()

  let mesh_query : @ecs.Query[@ecs.Comp[@mesh.Mesh2d], @ecs.All] = @ecs.query(
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
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@mesh.MeshPlugin::MeshPlugin())
    .add_plugins(@sprite.SpritePlugin::SpritePlugin())
  let world = app.world()
  let mesh_assets_key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  let mesh_assets = world.get_resource_mut(mesh_assets_key).unwrap()
  mesh_assets.set_changed()
  let mesh_handle = mesh_assets
    .peek()
    .add(
      Mesh::from_2d_geometry(
        mesh2d_geometry_rectangle(Rectangle::new(8.0F, 6.0F)),
      ),
    )
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @mesh.ecs_key_mesh2d,
    @mesh.Mesh2d::new(mesh_handle),
  )

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
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@mesh.MeshPlugin::MeshPlugin())
    .add_plugins(@sprite.SpritePlugin::SpritePlugin())
  let world = app.world()
  let mesh_assets_key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  let mesh_assets = world.get_resource_mut(mesh_assets_key).unwrap()
  mesh_assets.set_changed()
  let mesh_handle = mesh_assets
    .peek()
    .add(
      Mesh::from_2d_geometry(
        mesh2d_geometry_rectangle(Rectangle::new(8.0F, 6.0F)),
      ),
    )
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @mesh.ecs_key_mesh2d,
    @mesh.Mesh2d::new(mesh_handle),
  )
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_no_auto_aabb,
    @visibility.NoAutoAabb::NoAutoAabb(),
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
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@mesh.MeshPlugin::MeshPlugin())
    .add_plugins(@sprite.SpritePlugin::SpritePlugin())
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
test "sprite: Sprite and SpriteMesh install Bevy required components" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@mesh.MeshPlugin::MeshPlugin())
    .add_plugins(@sprite.SpritePlugin::SpritePlugin())
  let world = app.world()
  let sprite_entity = world.spawn()
  let sprite_mesh_entity = world.spawn()
  try! world.set_by_key(
    sprite_entity,
    ecs_key_sprite,
    Sprite::from_color(Color::white(), @math.Vec2::new(8.0F, 4.0F)),
  )
  try! world.set_by_key(
    sprite_mesh_entity,
    ecs_key_sprite_mesh,
    SpriteMesh::from_color(Color::white(), @math.Vec2::new(12.0F, 6.0F)),
  )
  app = app.update()
  let world = app.world()
  for entity in [sprite_entity, sprite_mesh_entity] {
    debug_inspect(
      try! world.contains_by_key(entity, @transform.ecs_key_transform),
      content="true",
    )
    debug_inspect(
      try! world.contains_by_key(entity, @visibility.ecs_key_visibility),
      content="true",
    )
    debug_inspect(
      try! world.contains_by_key(entity, ecs_key_anchor),
      content="true",
    )
    debug_inspect(
      try! world.contains_by_key(entity, @camera_primitives.ecs_key_aabb),
      content="true",
    )
  }
}

///|
test "sprite: SpritePlugin calculate_bounds_2d inserts Aabb for SpriteMesh" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@mesh.MeshPlugin::MeshPlugin())
    .add_plugins(@sprite.SpritePlugin::SpritePlugin())
  let world = app.world()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    ecs_key_sprite_mesh,
    SpriteMesh::from_color(Color::white(), @math.Vec2::new(12.0F, 6.0F)),
  )

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
    debug_inspect(half_size.x.to_double(), content="6")
    debug_inspect(half_size.y.to_double(), content="3")
  }
}

///|
test "render2d: SpriteMeshPlugin adds quad Mesh2d and SpriteMaterial" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@mesh.MeshPlugin::MeshPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(@sprite.Render2dPlugin::Render2dPlugin())
  let world = app.world()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    ecs_key_sprite_mesh,
    SpriteMesh::from_color(
      Color::new(0.25F, 0.5F, 0.75F, 1.0F),
      @math.Vec2::new(12.0F, 6.0F),
    ),
  )
  try! world.set_by_key(entity, ecs_key_anchor, Anchor::center())

  app = app.update()

  let world = app.world()
  let material_key : @ecs.ComponentKey[MeshMaterial2d[SpriteMaterial]] = MeshMaterial2d::component()
  let mesh2d = try! world.get_by_key(entity, @mesh.ecs_key_mesh2d)
  let material = try! world.get_by_key(entity, material_key)
  let material_assets_key : @ecs.ResourceKey[@asset.Assets[SpriteMaterial]] = @asset.assets_resource_key()
  let material_assets = world.get_resource(material_assets_key).unwrap()

  debug_inspect(mesh2d is Some(_), content="true")
  debug_inspect(material is Some(_), content="true")
  if material is Some(value) {
    debug_inspect(material_assets.contains(value.handle), content="true")
  }
}

///|
test "sprite: compute_pixel_space_point follows Bevy texture-coordinate convention" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    @asset.AssetPlugin::AssetPlugin(),
  )
  let world = app.world()
  let image = @asset.asset_create_dynamic_texture(
    @math.UVec2::new(10, 20),
    true,
  )
  let image_assets_key : @ecs.ResourceKey[@asset.Assets[@asset.Image]] = @asset.assets_resource_key()
  let atlas_assets_key : @ecs.ResourceKey[
    @asset.Assets[@asset.TextureAtlasLayout],
  ] = @asset.assets_resource_key()
  let image_assets = world.get_resource(image_assets_key).unwrap()
  let atlas_assets = world.get_resource(atlas_assets_key).unwrap()
  let sprite = Sprite::from_image(image)
  let inside = sprite.compute_pixel_space_point(
    @math.Vec2::new(4.0F, 9.0F),
    Anchor::center(),
    image_assets,
    atlas_assets,
  )
  let outside = sprite.compute_pixel_space_point(
    @math.Vec2::new(6.0F, 0.0F),
    Anchor::center(),
    image_assets,
    atlas_assets,
  )
  match inside {
    SpritePixelSpacePoint::Inside(point) => {
      debug_inspect(point.x.to_double(), content="9")
      debug_inspect(point.y.to_double(), content="1")
    }
    SpritePixelSpacePoint::Outside(_) => abort("expected inside point")
  }
  match outside {
    SpritePixelSpacePoint::Outside(point) => {
      debug_inspect(point.x.to_double(), content="11")
      debug_inspect(point.y.to_double(), content="10")
    }
    SpritePixelSpacePoint::Inside(_) => abort("expected outside point")
  }
}

///|
test "render2d: Mesh2dBundle constructors normalize to MeshMaterial2d" {
  let wrapped_material_handle : Ref[Int?] = Ref(None)
  let preserved_material_handle : Ref[Int?] = Ref(None)
  let color_material_handle : Ref[Int?] = Ref(None)
  let explicit_mesh_material_handle : Ref[Int?] = Ref(None)

  @app.App::new(@ecs.World::new())
  .add_plugins(@asset.AssetPlugin::AssetPlugin())
  .add_plugins(@mesh.MeshPlugin::MeshPlugin())
  .add_plugins(@render.RenderPlugin::RenderPlugin())
  .add_plugins(@sprite.Render2dPlugin::Render2dPlugin())
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
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@shader.ShaderPlugin::ShaderPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(@sprite.ColorMaterialPlugin::ColorMaterialPlugin())
  let key : @ecs.ResourceKey[@asset.Assets[ColorMaterialAsset]] = @asset.assets_resource_key()
  let assets = app.world().get_resource(key).unwrap()
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
  let plugin : Material2dPlugin[DummyMaterialAsset] = @sprite.Material2dPlugin::Material2dPlugin()
    .with_asset_init(fn() { dummy_material_asset() })
    .with_vertex_shader("sprite_render/mesh2d/mesh2d.wgsl")
    .with_fragment_shader("shaders/custom_material_2d.wgsl")
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@shader.ShaderPlugin::ShaderPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
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
  let pipeline = render_world.get_resource(pipeline_key).unwrap()
  let registry = render_world.get_resource(registry_key).unwrap()
  let probe : @asset.Handle[DummyMaterialAsset] = @asset.Handle::new(0)

  debug_inspect(app.contains_resource(key), content="true")
  debug_inspect(
    render_world.get_resource(prepared_key) is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(instances_key) is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(pipeline_key) is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(registry_key) is Some(_),
    content="true",
  )
  debug_inspect(
    pipeline.vertex_shader,
    content="Some(\"sprite_render/mesh2d/mesh2d.wgsl\")",
  )
  debug_inspect(
    pipeline.fragment_shader,
    content="Some(\"shaders/custom_material_2d.wgsl\")",
  )
  debug_inspect(registry.entry_count(), content="1")
  debug_inspect(
    registry.contains_type_name(material2d_runtime_type_name(probe)),
    content="true",
  )
}

///|
test "render2d: custom Mesh2d runtime registry matches marker components" {
  let source_world = @ecs.World::new()
  let render_world = @ecs.World::new()
  let descriptor = CustomMesh2dPipelineDescriptor::new(
    "examples/2d/mesh2d_manual/colored_mesh2d.wgsl",
  )
  register_custom_mesh2d_pipeline_world(
    render_world,
    type_name="mgstudio_sprite_test::TestCustomMesh2d",
    component_key=test_custom_mesh2d_key,
    descriptor~,
  )
  let entity = source_world.spawn()
  try! (source_world.set_by_key(entity, test_custom_mesh2d_key, TestCustomMesh2d::{

  })
  |> ignore)
  let registry = render_world
    .get_resource(CustomMesh2dRuntimeRegistry::resource())
    .unwrap()
  debug_inspect(registry.entry_count(), content="1")
  debug_inspect(
    registry.contains_type_name("mgstudio_sprite_test::TestCustomMesh2d"),
    content="true",
  )
  debug_inspect(registry.contains_entity(source_world, entity), content="true")
}

///|
test "render2d: generic Material2d runtime extracts and prepares custom assets" {
  let entity_ref : Ref[@core.Entity?] = Ref(None)
  let handle_ref : Ref[@asset.Handle[DummyMaterialAsset]?] = Ref(None)
  let expected = dummy_material_asset(color=Color::new(0.3F, 0.6F, 0.9F, 1.0F))

  let plugin : Material2dPlugin[DummyMaterialAsset] = @sprite.Material2dPlugin::Material2dPlugin()
    .with_asset_init(fn() { dummy_material_asset() })
    .with_vertex_shader("sprite_render/mesh2d/mesh2d.wgsl")
    .with_fragment_shader("shaders/custom_material_2d.wgsl")
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@shader.ShaderPlugin::ShaderPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(plugin)
  app = app.add_system(fn(world : @ecs.World) {
    let handle : @asset.Handle[DummyMaterialAsset] = @asset.Handle::new(21)
    handle_ref.val = Some(handle)
    let key : @ecs.ResourceKey[@asset.Assets[DummyMaterialAsset]] = @asset.assets_resource_key()
    guard world.get_resource_mut(key) is Some(assets_ref) else {
      abort("expected DummyMaterialAsset asset store")
    }
    assets_ref.modify(fn(assets) { assets.insert(handle, expected) |> ignore })
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
  let instances = render_world.get_resource(instances_key).unwrap()
  let prepared_assets = render_world.get_resource(prepared_key).unwrap()
  let prepared = prepared_assets.get(handle.id()).unwrap()

  debug_inspect(instances.contains(entity), content="true")
  debug_inspect(
    instances.get(entity).map(fn(value) { value.id() == handle.id() }),
    content="Some(true)",
  )
  debug_inspect(prepared.source.id() == handle.id(), content="true")
  debug_inspect(
    prepared.bind_group.layout_key(),
    content="\"0:uniform;1:texture(float,2d);2:sampler\"",
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
  let entity_ref : Ref[@core.Entity?] = Ref(None)
  let handle_ref : Ref[@asset.Handle[ColorMaterialAsset]?] = Ref(None)

  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@mesh.MeshPlugin::MeshPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(@sprite.Render2dPlugin::Render2dPlugin())
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
  let instances = render_world.get_resource(instances_key).unwrap()

  debug_inspect(instances.contains(entity), content="true")
  debug_inspect(
    instances.get(entity).map(fn(value) { value.id() == handle.id() }),
    content="Some(true)",
  )
}

///|
test "render2d: prepare_color_material2d_assets_system populates prepared assets" {
  let handle_ref : Ref[@asset.Handle[ColorMaterialAsset]?] = Ref(None)

  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@mesh.MeshPlugin::MeshPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(@sprite.Render2dPlugin::Render2dPlugin())
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
  let source_assets = world.get_resource(source_key).unwrap()
  let prepared_assets = render_world.get_resource(prepared_key).unwrap()
  let pipeline = render_world.get_resource(pipeline_key).unwrap()
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
test "render2d: ColorMaterialAsset constructors match Bevy alpha modes" {
  let opaque_alpha_mode : Ref[@sprite_render_mesh2d_material.AlphaMode2d?] = Ref(
    None,
  )
  let blend_alpha_mode : Ref[@sprite_render_mesh2d_material.AlphaMode2d?] = Ref(
    None,
  )
  let default_alpha_mode : Ref[@sprite_render_mesh2d_material.AlphaMode2d?] = Ref(
    None,
  )

  @app.App::new(@ecs.World::new())
  .add_plugins(@asset.AssetPlugin::AssetPlugin())
  .add_plugins(@mesh.MeshPlugin::MeshPlugin())
  .add_plugins(@render.RenderPlugin::RenderPlugin())
  .add_plugins(@sprite.Render2dPlugin::Render2dPlugin())
  .add_system(fn(_world : @ecs.World) {
    opaque_alpha_mode.val = Some(
      ColorMaterialAsset::from_color(Color::white()).alpha_mode(),
    )
    blend_alpha_mode.val = Some(
      ColorMaterialAsset::from_color(Color::new(0.25F, 0.5F, 0.75F, 0.4F)).alpha_mode(),
    )
    default_alpha_mode.val = Some(
      ColorMaterialAsset::ColorMaterialAsset().alpha_mode(),
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
  debug_inspect(
    default_alpha_mode.val.map(fn(mode) { mode is Blend }),
    content="Some(true)",
  )
}

///|
test "render2d: ColorMaterialAsset stores full affine uv transform" {
  let uv_transform = @transform.Affine2::from_translation(
    @math.Vec2::new(0.25F, -0.5F),
  ).mul(@transform.Affine2::from_scale(@math.Vec2::new(2.0F, 3.0F)))
  let material = ColorMaterialAsset::from_image(@asset.Handle::new(7)).with_uv_transform(
    uv_transform,
  )
  let point = material.uv_transform.transform_point2(
    @math.Vec2::new(0.5F, 0.25F),
  )

  debug_inspect(sprite_test_close(point.x, 1.25F), content="true")
  debug_inspect(sprite_test_close(point.y, 0.25F), content="true")
}

///|
test "render2d: ColorMaterialAsset bind group uploads full affine uv transform" {
  let uv_transform = @transform.Affine2::from_cols(
    @math.Vec2::new(2.0F, 0.5F),
    @math.Vec2::new(-0.25F, 3.0F),
    @math.Vec2::new(0.25F, -0.5F),
  )
  let bind_group = ColorMaterialAsset::from_image(@asset.Handle::new(7))
    .with_uv_transform(uv_transform)
    .bind_group()

  guard bind_group.binding(0) is Some(binding) else {
    abort("missing color material uniform binding")
  }
  guard binding.value is Uniform(bytes) else {
    abort("color material binding 0 is not uniform data")
  }

  debug_inspect(bytes.length(), content="80")
  debug_inspect(
    sprite_test_u32le_word(bytes, 4) == dummy_f32_bits(2.0F),
    content="true",
  )
  debug_inspect(
    sprite_test_u32le_word(bytes, 5) == dummy_f32_bits(0.5F),
    content="true",
  )
  debug_inspect(
    sprite_test_u32le_word(bytes, 8) == dummy_f32_bits(-0.25F),
    content="true",
  )
  debug_inspect(
    sprite_test_u32le_word(bytes, 9) == dummy_f32_bits(3.0F),
    content="true",
  )
  debug_inspect(
    sprite_test_u32le_word(bytes, 12) == dummy_f32_bits(0.25F),
    content="true",
  )
  debug_inspect(
    sprite_test_u32le_word(bytes, 13) == dummy_f32_bits(-0.5F),
    content="true",
  )
}
