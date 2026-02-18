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
/// Baseline parity:
/// - Bevy weighted OIT resolve is not available in current mgstudio renderer.
/// - This port keeps Bevy's scene/control topology and camera OIT marker API,
///   while mapping toggle behavior onto a transparency-mode proxy (`Blend` vs
///   `AlphaToCoverage`) for visual comparison.

///|
const PI : Float = 3.141592653589793F

///|
const TAU : Float = 6.283185307179586F

///|
const LAYER_INDEX : Int = 1

///|
priv struct OitExampleState {
  mut camera : @core.Entity?
  mut help_text : @text.TextHandle?
  mut scene_index : Int
  mut oit_enabled : Bool
  mut scene_entities : Array[Array[@core.Entity]]
  mut transparent_materials : Array[@asset.Handle[@render3d.StandardMaterial]]
}

///|
let oit_state : Ref[OitExampleState] = Ref::new({
  camera: None,
  help_text: None,
  scene_index: 0,
  oit_enabled: true,
  scene_entities: [],
  transparent_materials: [],
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
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
  "Order Independent Transparency (Bevy-aligned controls)\n" +
  "T: Toggle OIT proxy (" +
  (if oit_state.val.oit_enabled { "Enabled" } else { "Disabled" }) +
  ")\n" +
  "C: Cycle scene (" +
  scene_name(oit_state.val.scene_index) +
  ")\n"
}

///|
fn update_help_text() -> Unit {
  if oit_state.val.help_text is Some(text_handle) {
    @text.text_set_content(text_handle, help_text_content())
  }
}

///|
fn create_blend_material(
  color : @render2d.Color,
) -> @asset.Handle[@render3d.StandardMaterial] {
  let material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(color).with_alpha_mode(
      @render3d.AlphaMode3d::Blend,
    ),
  )
  oit_state.val.transparent_materials.push(material)
  material
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
) -> Array[@core.Entity] {
  let entities : Array[@core.Entity] = []
  let sphere = uv_sphere_mesh(2.0F, 18, 32)
  let alpha = 0.25F
  let mat_a = create_blend_material(
    @render2d.Color::new(1.0F, 0.0F, 0.0F, alpha),
  )
  let mat_b = create_blend_material(
    @render2d.Color::new(0.0F, 1.0F, 0.0F, alpha),
  )
  let mat_c = create_blend_material(
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
  entities
}

///|
fn spawn_scene_quads(
  world : @ecs_world.World,
  layers : @render2d.RenderLayers,
  tick : Int,
) -> Array[@core.Entity] {
  let entities : Array[@core.Entity] = []
  let quad = @render3d.Mesh3d::from_cuboid(3.0F, 3.0F, 0.05F)
  let rotation = @math.Quat::from_rotation_y(0.5F)
  let mat0 = create_blend_material(@render2d.Color::new(1.0F, 0.0F, 0.0F, 0.5F))
  let mat1 = create_blend_material(@render2d.Color::new(0.0F, 0.0F, 1.0F, 0.8F))
  let mat2 = create_blend_material(@render2d.Color::new(0.0F, 1.0F, 0.0F, 0.5F))
  let mat3 = create_blend_material(@render2d.Color::new(1.0F, 1.0F, 0.0F, 0.3F))
  let mat4 = create_blend_material(@render2d.Color::new(0.0F, 0.0F, 1.0F, 0.2F))
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
  entities
}

///|
fn spawn_scene_occlusion(
  world : @ecs_world.World,
  layers : @render2d.RenderLayers,
  tick : Int,
) -> Array[@core.Entity] {
  let entities : Array[@core.Entity] = []
  let cube = @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F)
  let sphere = uv_sphere_mesh(1.0F, 16, 24)

  let solid_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.80F, 0.70F, 0.60F, 1.0F),
    ),
  )
  let transparent = create_blend_material(
    @render2d.Color::new(0.30F, 0.60F, 1.00F, 0.30F),
  )

  for z in [1.0F, 0.0F, -1.0F] {
    entities.push(
      spawn_mesh_with_layer(
        world,
        cube,
        solid_material,
        @math.Transform::from_xyz(0.0F, 0.0F, z),
        layers,
        tick,
      ),
    )
  }

  for x in [-1.5F, 0.0F, 1.5F] {
    entities.push(
      spawn_mesh_with_layer(
        world,
        sphere,
        transparent,
        @math.Transform::from_xyz(x, 0.0F, 0.0F),
        layers,
        tick,
      ),
    )
  }

  entities
}

///|
fn spawn_scene_instancing(
  world : @ecs_world.World,
  layers : @render2d.RenderLayers,
  tick : Int,
) -> Array[@core.Entity] {
  let entities : Array[@core.Entity] = []
  let sphere = uv_sphere_mesh(0.35F, 12, 20)
  for zi in 0..<4 {
    for yi in 0..<4 {
      for xi in 0..<4 {
        let x = float_from_int(xi) - 1.5F
        let y = float_from_int(yi) - 1.5F
        let z = -float_from_int(zi) * 0.8F
        let alpha = 0.20F + float_from_int((xi + yi + zi) % 3) * 0.10F
        let color = @render2d.Color::new(
          0.25F + float_from_int(xi) * 0.15F,
          0.20F + float_from_int(yi) * 0.18F,
          0.30F + float_from_int(zi) * 0.15F,
          alpha,
        )
        let material = create_blend_material(color)
        entities.push(
          spawn_mesh_with_layer(
            world,
            sphere,
            material,
            @math.Transform::from_xyz(x, y, z),
            layers,
            tick,
          ),
        )
      }
    }
  }
  entities
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
fn apply_oit_mode(world : @ecs_world.World) -> Unit {
  let alpha_mode = if oit_state.val.oit_enabled {
    @render3d.AlphaMode3d::AlphaToCoverage
  } else {
    @render3d.AlphaMode3d::Blend
  }
  for handle in oit_state.val.transparent_materials {
    if @render3d.standard_material_get(handle) is Some(material) {
      @render3d.standard_material_set(
        handle,
        material.with_alpha_mode(alpha_mode),
      )
      |> ignore
    }
  }
  if oit_state.val.camera is Some(camera) {
    let tick = world.read_change_tick()
    if oit_state.val.oit_enabled {
      world
      .get_order_independent_transparency_settings_store()
      .insert(
        camera,
        @render3d.OrderIndependentTransparencySettings::default(),
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
  oit_state.val.scene_entities = []
  oit_state.val.transparent_materials = []

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
  let scene3 = spawn_scene_instancing(world, layer, tick)
  oit_state.val.scene_entities = [scene0, scene1, scene2, scene3]

  apply_scene_visibility(world)
  apply_oit_mode(world)
  update_help_text()
}

///|
fn controls(world : @ecs_world.World) -> Unit {
  let mut updated = false
  if @input.key_just_pressed(@window.KeyCode::KeyT) {
    oit_state.val.oit_enabled = !oit_state.val.oit_enabled
    apply_oit_mode(world)
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
