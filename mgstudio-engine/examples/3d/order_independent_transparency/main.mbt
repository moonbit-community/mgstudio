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
/// Port of `bevy/examples/3d/order_independent_transparency.rs`.
///
/// Parity target:
/// - Keep Bevy's camera OIT component flow and scene controls.
/// - Expose Bevy OIT settings fields on camera components.
/// - Preserve a visible fallback comparison (`Blend` vs `AlphaToCoverage`)
///   until renderer-side weighted OIT resolve parity is complete.

///|
const PI : Float = 3.141592653589793F

///|
const TAU : Float = 6.283185307179586F

///|
const LAYER_INDEX : Int = 1

///|
priv struct SpawnedScene {
  entities : Array[@core.Entity]
  materials : Array[@asset.Handle[@render3d.StandardMaterial]]
}

///|
priv struct OitExampleState {
  mut camera : @core.Entity?
  mut help_text : @text.TextHandle?
  mut scene_index : Int
  mut oit_enabled : Bool
  mut sorted_fragment_max_count : Int
  mut fragments_per_pixel_average : Float
  mut alpha_threshold : Float
  mut scene_entities : Array[Array[@core.Entity]]
  mut scene_materials : Array[Array[@asset.Handle[@render3d.StandardMaterial]]]
}

///|
let oit_state : Ref[OitExampleState] = Ref::new({
  camera: None,
  help_text: None,
  scene_index: 0,
  oit_enabled: true,
  sorted_fragment_max_count: 8,
  fragments_per_pixel_average: 4.0F,
  alpha_threshold: 0.0F,
  scene_entities: [],
  scene_materials: [],
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn float_text_2(value : Float) -> String {
  let rounded = (value * 100.0F).round() / 100.0F
  "\{rounded}"
}

///|
fn uv_sphere_mesh(
  radius : Float,
  stacks : Int,
  sectors : Int,
) -> @render3d.Mesh3d {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  let stacks_f = float_from_int(stacks)
  let sectors_f = float_from_int(sectors)
  let stack_step = PI / stacks_f
  let sector_step = TAU / sectors_f

  for i in 0..<(stacks + 1) {
    let stack_angle = PI / 2.0F - float_from_int(i) * stack_step
    let ring_radius = radius * @math.cos(stack_angle)
    let y = radius * @math.sin(stack_angle)
    for j in 0..<(sectors + 1) {
      let sector_angle = float_from_int(j) * sector_step
      let x = ring_radius * @math.cos(sector_angle)
      let z = ring_radius * @math.sin(sector_angle)
      positions.push(@math.Vec3::new(x, y, z))
      uvs.push(
        @math.Vec2::new(
          float_from_int(j) / sectors_f,
          float_from_int(i) / stacks_f,
        ),
      )
    }
  }

  let row = sectors + 1
  for i in 0..<stacks {
    let k1 = i * row
    let k2 = k1 + row
    for j in 0..<sectors {
      if i != 0 {
        indices.push(k1 + j)
        indices.push(k2 + j)
        indices.push(k1 + j + 1)
      }
      if i != stacks - 1 {
        indices.push(k1 + j + 1)
        indices.push(k2 + j)
        indices.push(k2 + j + 1)
      }
    }
  }

  @render3d.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
  )
}

///|
fn scene_name(scene_index : Int) -> String {
  if scene_index == 0 {
    "Spheres"
  } else if scene_index == 1 {
    "Quads"
  } else if scene_index == 2 {
    "Occlusion"
  } else {
    "Instancing"
  }
}

///|
fn help_text_content() -> String {
  "Press T to toggle OIT\n" +
  "OIT " +
  (if oit_state.val.oit_enabled { "enabled" } else { "disabled" }) +
  "\nTransparent fallback mode: " +
  (if oit_state.val.oit_enabled { "Blend" } else { "AlphaToCoverage" }) +
  "\n1/2: -/+ sorted_fragment_max_count (" +
  oit_state.val.sorted_fragment_max_count.to_string() +
  ")" +
  "\n3/4: -/+ fragments_per_pixel_average (" +
  float_text_2(oit_state.val.fragments_per_pixel_average) +
  ")" +
  "\n5/6: -/+ alpha_threshold (" +
  float_text_2(oit_state.val.alpha_threshold) +
  ")" +
  "\nPress C to cycle test scenes (" +
  scene_name(oit_state.val.scene_index) +
  ")"
}

///|
fn update_help_text() -> Unit {
  if oit_state.val.help_text is Some(text_handle) {
    @text.text_set_content(text_handle, help_text_content())
  }
}

///|
fn transparent_alpha_mode() -> @render3d.AlphaMode3d {
  if oit_state.val.oit_enabled {
    @render3d.AlphaMode3d::Blend
  } else {
    @render3d.AlphaMode3d::AlphaToCoverage
  }
}

///|
fn create_transparent_material(
  color : @render2d.Color,
) -> @asset.Handle[@render3d.StandardMaterial] {
  @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(color).with_alpha_mode(
      transparent_alpha_mode(),
    ),
  )
}

///|
fn spawn_mesh_with_layer(
  world : @ecs_world.World,
  mesh : @render3d.Mesh3d,
  material : @asset.Handle[@render3d.StandardMaterial],
  transform : @math.Transform,
  layers : @render2d.RenderLayers,
  tick : Int,
) -> @core.Entity {
  let entity = @render3d.MeshMaterial3dBundle::new(
    mesh,
    @render3d.MeshMaterial3d::new(material),
    transform,
  ).spawn(world)
  world.get_render_layers_store().insert(entity, layers, tick)
  entity
}

///|
fn spawn_scene_spheres(
  world : @ecs_world.World,
  layers : @render2d.RenderLayers,
  tick : Int,
) -> SpawnedScene {
  let entities : Array[@core.Entity] = []
  let sphere = uv_sphere_mesh(2.0F, 18, 32)
  let alpha = 0.25F
  let mat_a = create_transparent_material(
    @render2d.Color::new(1.0F, 0.0F, 0.0F, alpha),
  )
  let mat_b = create_transparent_material(
    @render2d.Color::new(0.0F, 1.0F, 0.0F, alpha),
  )
  let mat_c = create_transparent_material(
    @render2d.Color::new(0.0F, 0.0F, 1.0F, alpha),
  )
  entities.push(
    spawn_mesh_with_layer(
      world,
      sphere,
      mat_a,
      @math.Transform::from_xyz(-1.0F, 0.75F, 0.0F),
      layers,
      tick,
    ),
  )
  entities.push(
    spawn_mesh_with_layer(
      world,
      sphere,
      mat_b,
      @math.Transform::from_xyz(0.0F, -0.75F, 0.0F),
      layers,
      tick,
    ),
  )
  entities.push(
    spawn_mesh_with_layer(
      world,
      sphere,
      mat_c,
      @math.Transform::from_xyz(1.0F, 0.75F, 0.0F),
      layers,
      tick,
    ),
  )
  SpawnedScene::{ entities, materials: [mat_a, mat_b, mat_c] }
}

///|
fn spawn_scene_quads(
  world : @ecs_world.World,
  layers : @render2d.RenderLayers,
  tick : Int,
) -> SpawnedScene {
  let entities : Array[@core.Entity] = []
  let quad = @render3d.Mesh3d::from_cuboid(3.0F, 3.0F, 0.05F)
  let rotation = @math.Quat::from_rotation_y(0.5F)
  let mat0 = create_transparent_material(
    @render2d.Color::new(1.0F, 0.0F, 0.0F, 0.5F),
  )
  let mat1 = create_transparent_material(
    @render2d.Color::new(0.0F, 0.0F, 1.0F, 0.8F),
  )
  let mat2 = create_transparent_material(
    @render2d.Color::new(0.0F, 1.0F, 0.0F, 0.5F),
  )
  let mat3 = create_transparent_material(
    @render2d.Color::new(1.0F, 1.0F, 0.0F, 0.3F),
  )
  let mat4 = create_transparent_material(
    @render2d.Color::new(0.0F, 0.0F, 1.0F, 0.2F),
  )
  entities.push(
    spawn_mesh_with_layer(
      world,
      quad,
      mat0,
      @math.Transform::from_xyz(1.0F, -0.1F, 0.0F).with_rotation(rotation),
      layers,
      tick,
    ),
  )
  entities.push(
    spawn_mesh_with_layer(
      world,
      quad,
      mat1,
      @math.Transform::from_xyz(0.5F, 0.2F, -0.5F).with_rotation(rotation),
      layers,
      tick,
    ),
  )
  entities.push(
    spawn_mesh_with_layer(
      world,
      quad,
      mat2,
      @math.Transform::from_xyz(0.0F, 0.4F, -1.0F).with_rotation(rotation),
      layers,
      tick,
    ),
  )
  entities.push(
    spawn_mesh_with_layer(
      world,
      quad,
      mat3,
      @math.Transform::from_xyz(-0.5F, 0.6F, -1.1F).with_rotation(rotation),
      layers,
      tick,
    ),
  )
  entities.push(
    spawn_mesh_with_layer(
      world,
      quad,
      mat4,
      @math.Transform::from_xyz(-0.8F, 0.8F, -1.2F).with_rotation(rotation),
      layers,
      tick,
    ),
  )
  SpawnedScene::{ entities, materials: [mat0, mat1, mat2, mat3, mat4] }
}

///|
fn spawn_scene_occlusion(
  world : @ecs_world.World,
  layers : @render2d.RenderLayers,
  tick : Int,
) -> SpawnedScene {
  let entities : Array[@core.Entity] = []
  let cube = @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F)
  let sphere = uv_sphere_mesh(1.0F, 16, 24)

  let solid_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.80F, 0.70F, 0.60F, 1.0F),
    ),
  )
  let transparent = create_transparent_material(
    @render2d.Color::new(1.0F, 0.0F, 0.0F, 0.5F),
  )

  // Front pair.
  entities.push(
    spawn_mesh_with_layer(
      world,
      cube,
      solid_material,
      @math.Transform::from_xyz(-2.5F, 0.0F, 2.0F),
      layers,
      tick,
    ),
  )
  entities.push(
    spawn_mesh_with_layer(
      world,
      sphere,
      transparent,
      @math.Transform::from_xyz(-2.5F, 0.0F, 0.0F),
      layers,
      tick,
    ),
  )

  // Intersection pair.
  entities.push(
    spawn_mesh_with_layer(
      world,
      cube,
      solid_material,
      @math.Transform::from_xyz(-2.5F, 0.0F, 1.0F),
      layers,
      tick,
    ),
  )
  entities.push(
    spawn_mesh_with_layer(
      world,
      sphere,
      transparent,
      @math.Transform::from_xyz(0.0F, 0.0F, 0.0F),
      layers,
      tick,
    ),
  )

  // Back pair.
  entities.push(
    spawn_mesh_with_layer(
      world,
      cube,
      solid_material,
      @math.Transform::from_xyz(2.5F, 0.0F, -2.0F),
      layers,
      tick,
    ),
  )
  entities.push(
    spawn_mesh_with_layer(
      world,
      sphere,
      transparent,
      @math.Transform::from_xyz(2.5F, 0.0F, 0.0F),
      layers,
      tick,
    ),
  )

  SpawnedScene::{ entities, materials: [transparent] }
}

///|
fn spawn_scene_instancing(
  world : @ecs_world.World,
  layers : @render2d.RenderLayers,
  asset_server : @asset.AssetServer,
  tick : Int,
) -> SpawnedScene {
  let entities : Array[@core.Entity] = []
  let cube = @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F)
  let material = @render3d.standard_material_add(
    @render3d.StandardMaterial::default()
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_base_color_texture(
      Some(asset_server.load("textures/slice_square.png")),
    ),
  )
  for z in -1..<2 {
    for y in -1..<2 {
      for x in -1..<2 {
        entities.push(
          spawn_mesh_with_layer(
            world,
            cube,
            material,
            @math.Transform::from_xyz(
              float_from_int(x) * 2.0F,
              float_from_int(y) * 2.0F,
              float_from_int(z) * 2.0F,
            ),
            layers,
            tick,
          ),
        )
      }
    }
  }
  SpawnedScene::{ entities, materials: [material] }
}

///|
fn apply_scene_visibility(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let visibility_store = world.get_visibility_store()
  for i, entities in oit_state.val.scene_entities {
    let visibility = if i == oit_state.val.scene_index {
      @visibility.Visibility::Inherited
    } else {
      @visibility.Visibility::Hidden
    }
    for entity in entities {
      visibility_store.set(entity, visibility, tick) |> ignore
    }
  }
}

///|
fn apply_transparency_mode_proxy() -> Unit {
  let alpha_mode = transparent_alpha_mode()
  for materials in oit_state.val.scene_materials {
    for material_handle in materials {
      if @render3d.standard_material_get(material_handle) is Some(material) {
        @render3d.standard_material_set(
          material_handle,
          material.with_alpha_mode(alpha_mode),
        )
        |> ignore
      }
    }
  }
}

///|
fn apply_oit_mode(world : @ecs_world.World) -> Unit {
  if oit_state.val.camera is Some(camera) {
    let tick = world.read_change_tick()
    world.get_msaa_store().insert(camera, @render3d.Msaa::Off, tick)
    if oit_state.val.oit_enabled {
      world
      .get_order_independent_transparency_settings_store()
      .insert(
        camera,
        @render3d.OrderIndependentTransparencySettings::new(
          oit_state.val.sorted_fragment_max_count,
          oit_state.val.fragments_per_pixel_average,
          oit_state.val.alpha_threshold,
        ),
        tick,
      )
    } else {
      world.get_order_independent_transparency_settings_store().remove(camera)
      |> ignore
    }
  }
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let layer = @render2d.RenderLayers::layer(LAYER_INDEX)
  let asset_server = @asset.AssetServer::new()

  oit_state.val.camera = None
  oit_state.val.help_text = None
  oit_state.val.scene_index = 0
  oit_state.val.oit_enabled = true
  oit_state.val.sorted_fragment_max_count = 8
  oit_state.val.fragments_per_pixel_average = 4.0F
  oit_state.val.alpha_threshold = 0.0F
  oit_state.val.scene_entities = []
  oit_state.val.scene_materials = []

  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.0F, 0.0F, 10.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world.get_render_layers_store().insert(camera, layer, tick)
  world
  .get_depth_prepass_store()
  .insert(camera, @render3d.DepthPrepass::default(), tick)
  oit_state.val.camera = Some(camera)

  let light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    light,
    @render3d.PointLight::new(
      @render2d.Color::white(),
      900_000.0F,
      40.0F,
      false,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(light, @math.Transform::from_xyz(4.0F, 8.0F, 4.0F), tick)
  world.get_render_layers_store().insert(light, layer, tick)

  let help_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(16.0F),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@render2d.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  oit_state.val.help_text = Some(help_text)

  let scene0 = spawn_scene_spheres(world, layer, tick)
  let scene1 = spawn_scene_quads(world, layer, tick)
  let scene2 = spawn_scene_occlusion(world, layer, tick)
  let scene3 = spawn_scene_instancing(world, layer, asset_server, tick)
  oit_state.val.scene_entities = [
    scene0.entities,
    scene1.entities,
    scene2.entities,
    scene3.entities,
  ]
  oit_state.val.scene_materials = [
    scene0.materials,
    scene1.materials,
    scene2.materials,
    scene3.materials,
  ]

  apply_scene_visibility(world)
  apply_oit_mode(world)
  apply_transparency_mode_proxy()
  update_help_text()
}

///|
fn controls(world : @ecs_world.World) -> Unit {
  let mut updated = false
  if @input.key_just_pressed(@window.KeyCode::KeyT) {
    oit_state.val.oit_enabled = !oit_state.val.oit_enabled
    apply_oit_mode(world)
    apply_transparency_mode_proxy()
    updated = true
  }
  let mut settings_changed = false
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    oit_state.val.sorted_fragment_max_count = oit_state.val.sorted_fragment_max_count -
      1
    settings_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    oit_state.val.sorted_fragment_max_count = oit_state.val.sorted_fragment_max_count +
      1
    settings_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit3) {
    oit_state.val.fragments_per_pixel_average = oit_state.val.fragments_per_pixel_average -
      0.5F
    settings_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit4) {
    oit_state.val.fragments_per_pixel_average = oit_state.val.fragments_per_pixel_average +
      0.5F
    settings_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit5) {
    oit_state.val.alpha_threshold = oit_state.val.alpha_threshold - 0.05F
    settings_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit6) {
    oit_state.val.alpha_threshold = oit_state.val.alpha_threshold + 0.05F
    settings_changed = true
  }
  if settings_changed {
    if oit_state.val.sorted_fragment_max_count < 1 {
      oit_state.val.sorted_fragment_max_count = 1
    } else if oit_state.val.sorted_fragment_max_count > 64 {
      oit_state.val.sorted_fragment_max_count = 64
    }
    if oit_state.val.fragments_per_pixel_average < 0.25F {
      oit_state.val.fragments_per_pixel_average = 0.25F
    } else if oit_state.val.fragments_per_pixel_average > 16.0F {
      oit_state.val.fragments_per_pixel_average = 16.0F
    }
    if oit_state.val.alpha_threshold < 0.0F {
      oit_state.val.alpha_threshold = 0.0F
    } else if oit_state.val.alpha_threshold > 1.0F {
      oit_state.val.alpha_threshold = 1.0F
    }
    if oit_state.val.oit_enabled {
      apply_oit_mode(world)
    }
    updated = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyC) {
    let scene_count = oit_state.val.scene_entities.length()
    if scene_count > 0 {
      oit_state.val.scene_index = (oit_state.val.scene_index + 1) % scene_count
      apply_scene_visibility(world)
      updated = true
    }
  }
  if updated {
    update_help_text()
  }
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(controls)
  .run()
}
