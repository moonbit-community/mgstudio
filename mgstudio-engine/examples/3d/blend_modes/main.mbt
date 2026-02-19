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
/// Port of `bevy/examples/3d/blend_modes.rs`.

///|
const PI : Float = 3.141592653589793F

///|
const TAU : Float = 6.283185307179586F

///|
const LCG_MOD : Int = 2147483647

///|
const CAMERA_RADIUS : Float = 10.0F

///|
const LABEL_HEIGHT_OFFSET : Float = 1.0F

///|
const CONTROL_TEXT : String = "Up / Down - Increase / Decrease Alpha\nLeft / Right - Rotate Camera\nH - Toggle HDR\nSpacebar - Toggle Unlit\nC - Randomize Colors"

///|
priv struct ControlledMaterial {
  handle : @asset.Handle[@render3d.StandardMaterial]
  allow_unlit : Bool
  allow_color : Bool
}

///|
priv struct ExampleLabel {
  node : @core.Entity
  target : @core.Entity
}

///|
priv struct BlendModesState {
  mut alpha : Float
  mut camera : @core.Entity?
  mut camera_angle : Float
  mut random_seed : Int
  materials : Array[ControlledMaterial]
  labels : Array[ExampleLabel]
  mut display_text : @text.TextHandle?
  mut unlit : Bool
}

///|
let blend_modes_state : Ref[BlendModesState] = Ref::new({
  alpha: 0.9F,
  camera: None,
  camera_angle: 0.0F,
  random_seed: 1367130551,
  materials: [],
  labels: [],
  display_text: None,
  unlit: false,
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn clamp01(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn lcg_next(seed : Int) -> Int {
  let mut next = (seed * 1103515245 + 12345) % LCG_MOD
  if next < 0 {
    next = next + LCG_MOD
  }
  next
}

///|
fn next_random_unit() -> Float {
  blend_modes_state.val.random_seed = lcg_next(
    blend_modes_state.val.random_seed,
  )
  float_from_int(blend_modes_state.val.random_seed) / float_from_int(LCG_MOD)
}

///|
fn random_color(alpha : Float) -> @render2d.Color {
  @render2d.Color::new(
    next_random_unit(),
    next_random_unit(),
    next_random_unit(),
    alpha,
  )
}

///|
fn spawn_ui_text_handle(
  content : String,
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  color : @render2d.Color,
) -> @text.TextHandle {
  @text.Text2dBundle::new(
    @text.Text2d::new(content),
    @text.TextFont::default().with_font(font).with_font_size(font_size),
    @math.Transform::identity(),
  )
  .with_color(@text.TextColor::new(color))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
  .spawn()
}

///|
fn blend_modes_display_text(
  camera_entity : @core.Entity,
  world : @ecs_world.World,
) -> String {
  let alpha_text = ((blend_modes_state.val.alpha * 100.0F).round() / 100.0F).to_string()
  let hdr_on = world.get_hdr_store().contains(camera_entity)
  "  HDR: " + (if hdr_on { "ON " } else { "OFF" }) + "\nAlpha: " + alpha_text
}

///|
fn setup_ui_overlay(
  world : @ecs_world.World,
  font : @asset.Handle[@asset.Font],
  opaque_entity : @core.Entity,
  blend_entity : @core.Entity,
  premultiplied_entity : @core.Entity,
  add_entity : @core.Entity,
  multiply_entity : @core.Entity,
) -> Unit {
  let tick = world.read_change_tick()
  @render2d.Camera2dBundle::new(
    @render2d.Camera::default().with_order(100).with_clear_color_none(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let root = world.spawn_empty()
  world.get_ui_root_store().insert(root, @ui.UiRoot::default(), tick)
  world
  .get_node_store()
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
    tick,
  )

  let controls_text = spawn_ui_text_handle(
    CONTROL_TEXT,
    font,
    14.0F,
    @render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F),
  )
  let controls_entity = world.spawn_empty()
  world
  .get_parent_store()
  .insert(controls_entity, @hierarchy.Parent::new(root), tick)
  world
  .get_node_store()
  .insert(
    controls_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .get_ui_text_store()
  .insert(controls_entity, @ui.UiText::new(controls_text), tick)

  guard blend_modes_state.val.camera is Some(camera_entity) else { return }
  let display_text = spawn_ui_text_handle(
    blend_modes_display_text(camera_entity, world),
    font,
    14.0F,
    @render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F),
  )
  let display_entity = world.spawn_empty()
  world
  .get_parent_store()
  .insert(display_entity, @hierarchy.Parent::new(root), tick)
  world
  .get_node_store()
  .insert(
    display_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_right(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .get_ui_text_store()
  .insert(display_entity, @ui.UiText::new(display_text), tick)
  blend_modes_state.val.display_text = Some(display_text)

  let label_color = @render2d.Color::new(1.0F, 0.65F, 0.2F, 1.0F)
  let labels : Array[(@core.Entity, String)] = [
    (opaque_entity, "┌─ Opaque\n│\n│\n│\n│"),
    (blend_entity, "┌─ Blend\n│\n│\n│"),
    (premultiplied_entity, "┌─ Premultiplied\n│\n│"),
    (add_entity, "┌─ Add\n│"),
    (multiply_entity, "┌─ Multiply"),
  ]

  for pair in labels {
    let target = pair.0
    let text = pair.1
    let label_text = spawn_ui_text_handle(text, font, 16.0F, label_color)
    let label_node = world.spawn_empty()
    world
    .get_parent_store()
    .insert(label_node, @hierarchy.Parent::new(root), tick)
    world
    .get_node_store()
    .insert(
      label_node,
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_left(@ui.Val::Px(0.0F))
      .with_top(@ui.Val::Px(0.0F)),
      tick,
    )
    world
    .get_ui_text_store()
    .insert(label_node, @ui.UiText::new(label_text), tick)
    blend_modes_state.val.labels.push({ node: label_node, target })
  }
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

  let geometry = @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices))
  @render3d.Mesh3d::from_geometry(geometry)
}

///|
fn register_material(
  handle : @asset.Handle[@render3d.StandardMaterial],
  allow_unlit : Bool,
  allow_color : Bool,
) -> Unit {
  blend_modes_state.val.materials.push({ handle, allow_unlit, allow_color })
}

///|
fn spawn_mesh(
  world : @ecs_world.World,
  mesh : @render3d.Mesh3d,
  material : @asset.Handle[@render3d.StandardMaterial],
  transform : @math.Transform,
) -> @core.Entity {
  @render3d.MeshMaterial3dBundle::new(
    mesh,
    @render3d.MeshMaterial3d::new(material),
    transform,
  ).spawn(world)
}

///|
fn update_ui_overlay(world : @ecs_world.World) -> Unit {
  let state = blend_modes_state.val
  guard state.camera is Some(camera_entity) else { return }
  guard state.display_text is Some(display_text) else { return }

  @text.text_set_content(
    display_text,
    blend_modes_display_text(camera_entity, world),
  )

  let camera_store = world.get_camera_store()
  guard camera_store.get(camera_entity) is Some(camera) else { return }
  let projection_store = world.get_camera_projection3d_store()
  guard projection_store.get(camera_entity) is Some(projection) else { return }
  let transform_store = world.get_transform_store()
  guard transform_store.get(camera_entity) is Some(camera_transform) else {
    return
  }

  let target_size = @math.IVec2::new(
    @window.window_width(),
    @window.window_height(),
  )
  let scale_factor = @window.window_scale_factor()
  let tick = world.read_change_tick()
  let node_store = world.get_node_store()

  for label in state.labels {
    guard transform_store.get(label.target) is Some(target_transform) else {
      continue
    }
    let world_position = target_transform.translation.add(
      @math.Vec3::new(0.0F, LABEL_HEIGHT_OFFSET, 0.0F),
    )
    guard @render3d.render3d_camera_world_to_viewport(
        world_position, camera, projection, camera_transform, target_size, scale_factor,
      )
      is Some(screen_position) else {
      continue
    }
    if node_store.get(label.node) is Some(node) {
      node_store.set(
        label.node,
        node
        .with_left(@ui.Val::Px(screen_position.x))
        .with_top(@ui.Val::Px(screen_position.y)),
        tick,
      )
      |> ignore
    }
  }
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  blend_modes_state.val.alpha = 0.9F
  blend_modes_state.val.unlit = false
  blend_modes_state.val.camera = None
  blend_modes_state.val.camera_angle = 0.0F
  blend_modes_state.val.random_seed = 1367130551
  blend_modes_state.val.materials.clear()
  blend_modes_state.val.labels.clear()
  blend_modes_state.val.display_text = None

  let base_color = @render2d.Color::new(
    0.9F,
    0.2F,
    0.3F,
    blend_modes_state.val.alpha,
  )
  let sphere_mesh = uv_sphere_mesh(0.9F, 16, 24)

  let opaque_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(base_color).with_alpha_mode(
      @render3d.AlphaMode3d::Opaque,
    ),
  )
  register_material(opaque_material, true, true)
  let opaque_entity = spawn_mesh(
    world,
    sphere_mesh,
    opaque_material,
    @math.Transform::from_xyz(-4.0F, 0.0F, 0.0F),
  )

  let blend_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(base_color).with_alpha_mode(
      @render3d.AlphaMode3d::Blend,
    ),
  )
  register_material(blend_material, true, true)
  let blend_entity = spawn_mesh(
    world,
    sphere_mesh,
    blend_material,
    @math.Transform::from_xyz(-2.0F, 0.0F, 0.0F),
  )

  let premultiplied_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(base_color).with_alpha_mode(
      @render3d.AlphaMode3d::Premultiplied,
    ),
  )
  register_material(premultiplied_material, true, true)
  let premultiplied_entity = spawn_mesh(
    world,
    sphere_mesh,
    premultiplied_material,
    @math.Transform::from_xyz(0.0F, 0.0F, 0.0F),
  )

  let add_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(base_color).with_alpha_mode(
      @render3d.AlphaMode3d::Add,
    ),
  )
  register_material(add_material, true, true)
  let add_entity = spawn_mesh(
    world,
    sphere_mesh,
    add_material,
    @math.Transform::from_xyz(2.0F, 0.0F, 0.0F),
  )

  let multiply_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(base_color).with_alpha_mode(
      @render3d.AlphaMode3d::Multiply,
    ),
  )
  register_material(multiply_material, true, true)
  let multiply_entity = spawn_mesh(
    world,
    sphere_mesh,
    multiply_material,
    @math.Transform::from_xyz(4.0F, 0.0F, 0.0F),
  )

  let black_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
    ),
  )
  let white_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
    ),
  )
  register_material(black_material, false, true)
  register_material(white_material, false, true)

  let plane_mesh = @render3d.Mesh3d::from_plane(2.0F, 2.0F)
  for x in -3..<4 {
    for z in -3..<4 {
      let use_black = (x + z) % 2 == 0
      let material = if use_black { black_material } else { white_material }
      spawn_mesh(
        world,
        plane_mesh,
        material,
        @math.Transform::from_xyz(
          float_from_int(x) * 2.0F,
          -1.0F,
          float_from_int(z) * 2.0F,
        ),
      )
      |> ignore
    }
  }

  let light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    light,
    @render3d.PointLight::new(
      @render2d.Color::white(),
      1_000_000.0F,
      30.0F,
      true,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(light, @math.Transform::from_xyz(4.0F, 8.0F, 4.0F), tick)

  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.0F, 2.5F, 10.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world.get_hdr_store().insert(camera, @render3d.Hdr::default(), tick)
  blend_modes_state.val.camera = Some(camera)

  let asset_server = @asset.AssetServer::new()
  let label_font = asset_server.load_font("fonts/FiraMono-Medium.ttf")
  setup_ui_overlay(
    world, label_font, opaque_entity, blend_entity, premultiplied_entity, add_entity,
    multiply_entity,
  )
  update_ui_overlay(world)
}

///|
fn example_control_system(world : @ecs_world.World) -> Unit {
  let delta = @time.time_delta_seconds()
  let state = blend_modes_state.val

  if @input.key_pressed(@window.KeyCode::ArrowUp) {
    state.alpha = clamp01(state.alpha + delta)
  } else if @input.key_pressed(@window.KeyCode::ArrowDown) {
    state.alpha = clamp01(state.alpha - delta)
  }

  if @input.key_just_pressed(@window.KeyCode::Space) {
    state.unlit = !state.unlit
  }

  let randomize_colors = @input.key_just_pressed(@window.KeyCode::KeyC)

  let rotation = if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    delta
  } else if @input.key_pressed(@window.KeyCode::ArrowRight) {
    -delta
  } else {
    0.0F
  }
  state.camera_angle = state.camera_angle + rotation

  guard state.camera is Some(camera_entity) else { return }
  let tick = world.read_change_tick()
  if @input.key_just_pressed(@window.KeyCode::KeyH) {
    let hdr_store = world.get_hdr_store()
    if hdr_store.contains(camera_entity) {
      hdr_store.remove(camera_entity) |> ignore
    } else {
      hdr_store.insert(camera_entity, @render3d.Hdr::default(), tick)
    }
  }
  let camera_x = @math.sin(state.camera_angle) * CAMERA_RADIUS
  let camera_z = @math.cos(state.camera_angle) * CAMERA_RADIUS
  world
  .get_transform_store()
  .set(
    camera_entity,
    @math.Transform::from_xyz(camera_x, 2.5F, camera_z).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  |> ignore

  for controlled in state.materials {
    if @render3d.standard_material_get(controlled.handle) is Some(material) {
      let mut next_material = material.with_base_color(
        @render2d.Color::new(
          material.base_color.r,
          material.base_color.g,
          material.base_color.b,
          state.alpha,
        ),
      )
      if controlled.allow_color && randomize_colors {
        next_material = next_material.with_base_color(random_color(state.alpha))
      }
      if controlled.allow_unlit {
        next_material = next_material.with_unlit(state.unlit)
      }
      @render3d.standard_material_set(controlled.handle, next_material)
      |> ignore
    }
  }

  update_ui_overlay(world)
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(example_control_system)
  .run()
}
