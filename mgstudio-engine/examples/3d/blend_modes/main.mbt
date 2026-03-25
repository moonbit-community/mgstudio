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
  handle : @asset.Handle[@pbr.StandardMaterial]
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
  mut display_text : @core.Entity?
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
fn random_color(alpha : Float) -> @sprite.Color {
  @sprite.Color::new(
    next_random_unit(),
    next_random_unit(),
    next_random_unit(),
    alpha,
  )
}

///|
fn blend_modes_display_text(
  camera_entity : @core.Entity,
  world : @ecs.World,
) -> String {
  let alpha_text = ((blend_modes_state.val.alpha * 100.0F).round() / 100.0F).to_string()
  let hdr_on = try! world.contains_by_key(camera_entity, @pbr.ecs_key_hdr)
  "  HDR: " + (if hdr_on { "ON " } else { "OFF" }) + "\nAlpha: " + alpha_text
}

///|
fn setup_ui_overlay(
  world : @ecs.World,
  font : @asset.Handle[@asset.Font],
  opaque_entity : @core.Entity,
  blend_entity : @core.Entity,
  premultiplied_entity : @core.Entity,
  add_entity : @core.Entity,
  multiply_entity : @core.Entity,
) -> Unit {
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default().with_order(100).with_clear_color_none(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
  )

  let controls_entity = world.spawn_empty()
  try! world.set_by_key(
    controls_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    controls_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    controls_entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(
    controls_entity,
    @text.ecs_key_text,
    @text.Text::new(CONTROL_TEXT),
  )
  try! world.set_by_key(
    controls_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(14.0F),
  )
  try! world.set_by_key(
    controls_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
  )
  try! world.set_by_key(
    controls_entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(@text.Justify::Left),
  )

  guard blend_modes_state.val.camera is Some(camera_entity) else { return }
  let display_entity = world.spawn_empty()
  try! world.set_by_key(
    display_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    display_entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_right(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(
    display_entity,
    @text.ecs_key_text,
    @text.Text::new(blend_modes_display_text(camera_entity, world)),
  )
  try! world.set_by_key(
    display_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(14.0F),
  )
  try! world.set_by_key(
    display_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
  )
  try! world.set_by_key(
    display_entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(@text.Justify::Left),
  )
  blend_modes_state.val.display_text = Some(display_entity)

  let label_color = @sprite.Color::new(1.0F, 0.65F, 0.2F, 1.0F)
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
    let label_node = world.spawn_empty()
    try! world.set_by_key(
      label_node,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(root),
    )
    try! world.set_by_key(
      label_node,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(root),
    )
    try! world.set_by_key(
      label_node,
      @ui.ecs_key_node,
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_left(@ui.Val::Px(0.0F))
      .with_top(@ui.Val::Px(0.0F)),
    )
    try! world.set_by_key(label_node, @text.ecs_key_text, @text.Text::new(text))
    try! world.set_by_key(
      label_node,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(root),
    )
    try! world.set_by_key(
      label_node,
      @ui.ecs_key_node,
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_left(@ui.Val::Px(0.0F))
      .with_top(@ui.Val::Px(0.0F)),
    )
    try! world.set_by_key(label_node, @text.ecs_key_text, @text.Text::new(text))
    try! world.set_by_key(
      label_node,
      @text.ecs_key_text_font,
      @text.TextFont::default().with_font(font).with_font_size(16.0F),
    )
    try! world.set_by_key(
      label_node,
      @text.ecs_key_text_color,
      @text.TextColor::new(label_color),
    )
    blend_modes_state.val.labels.push({ node: label_node, target })
  }
}

///|
fn uv_sphere_mesh(radius : Float, stacks : Int, sectors : Int) -> @pbr.Mesh3d {
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
  @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(geometry),
    ),
  )
}

///|
fn register_material(
  handle : @asset.Handle[@pbr.StandardMaterial],
  allow_unlit : Bool,
  allow_color : Bool,
) -> Unit {
  blend_modes_state.val.materials.push({ handle, allow_unlit, allow_color })
}

///|
fn spawn_mesh(
  world : @ecs.World,
  mesh : @pbr.Mesh3d,
  material : @asset.Handle[@pbr.StandardMaterial],
  transform : @transform.Transform,
) -> @core.Entity {
  @pbr.MeshMaterial3dBundle::new(
    mesh,
    @pbr.MeshMaterial3d::new(material),
    transform,
  ).spawn(world)
}

///|
fn update_ui_overlay(world : @ecs.World) -> Unit {
  let state = blend_modes_state.val
  guard state.camera is Some(camera_entity) else { return }
  guard state.display_text is Some(display_entity) else { return }
  guard (try! world.get_by_key(display_entity, @text.ecs_key_text))
    is Some(display_text) else {
    return
  }
  display_text.content = blend_modes_display_text(camera_entity, world)
  ignore(try! world.replace(display_entity, @text.ecs_key_text, display_text))

  guard (try! world.get_by_key(camera_entity, @sprite.ecs_key_camera))
    is Some(camera) else {
    return
  }
  guard (try! world.get_by_key(camera_entity, @pbr.ecs_key_projection))
    is Some(projection) else {
    return
  }
  guard (try! world.get_by_key(camera_entity, @transform.ecs_key_transform))
    is Some(camera_transform) else {
    return
  }

  let target_size = @math.IVec2::new(
    @window.window_width(),
    @window.window_height(),
  )
  let scale_factor = @window.window_scale_factor()

  for label in state.labels {
    guard (try! world.get_by_key(label.target, @transform.ecs_key_transform))
      is Some(target_transform) else {
      continue
    }
    let world_position = target_transform.translation.add(
      @math.Vec3::new(0.0F, LABEL_HEIGHT_OFFSET, 0.0F),
    )
    guard @pbr.render3d_camera_world_to_viewport(
        world_position, camera, projection, camera_transform, target_size, scale_factor,
      )
      is Some(screen_position) else {
      continue
    }
    if (try! world.get_by_key(label.node, @ui.ecs_key_node)) is Some(node) {
      try! (world.replace(
        label.node,
        @ui.ecs_key_node,
        node
        .with_left(@ui.Val::Px(screen_position.x))
        .with_top(@ui.Val::Px(screen_position.y)),
      )
      |> ignore)
    }
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  blend_modes_state.val.alpha = 0.9F
  blend_modes_state.val.unlit = false
  blend_modes_state.val.camera = None
  blend_modes_state.val.camera_angle = 0.0F
  blend_modes_state.val.random_seed = 1367130551
  blend_modes_state.val.materials.clear()
  blend_modes_state.val.labels.clear()
  blend_modes_state.val.display_text = None

  let base_color = @sprite.Color::new(
    0.9F,
    0.2F,
    0.3F,
    blend_modes_state.val.alpha,
  )
  let sphere_mesh = uv_sphere_mesh(0.9F, 16, 24)

  let opaque_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(base_color).with_alpha_mode(
      @pbr.AlphaMode3d::Opaque,
    ),
  )
  register_material(opaque_material, true, true)
  let opaque_entity = spawn_mesh(
    world,
    sphere_mesh,
    opaque_material,
    @transform.Transform::from_xyz(-4.0F, 0.0F, 0.0F),
  )

  let blend_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(base_color).with_alpha_mode(
      @pbr.AlphaMode3d::Blend,
    ),
  )
  register_material(blend_material, true, true)
  let blend_entity = spawn_mesh(
    world,
    sphere_mesh,
    blend_material,
    @transform.Transform::from_xyz(-2.0F, 0.0F, 0.0F),
  )

  let premultiplied_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(base_color).with_alpha_mode(
      @pbr.AlphaMode3d::Premultiplied,
    ),
  )
  register_material(premultiplied_material, true, true)
  let premultiplied_entity = spawn_mesh(
    world,
    sphere_mesh,
    premultiplied_material,
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
  )

  let add_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(base_color).with_alpha_mode(
      @pbr.AlphaMode3d::Add,
    ),
  )
  register_material(add_material, true, true)
  let add_entity = spawn_mesh(
    world,
    sphere_mesh,
    add_material,
    @transform.Transform::from_xyz(2.0F, 0.0F, 0.0F),
  )

  let multiply_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(base_color).with_alpha_mode(
      @pbr.AlphaMode3d::Multiply,
    ),
  )
  register_material(multiply_material, true, true)
  let multiply_entity = spawn_mesh(
    world,
    sphere_mesh,
    multiply_material,
    @transform.Transform::from_xyz(4.0F, 0.0F, 0.0F),
  )

  let black_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
    ),
  )
  let white_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
    ),
  )
  register_material(black_material, false, true)
  register_material(white_material, false, true)

  let plane_mesh = @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(2.0F, 2.0F)),
    ),
  )
  for x in -3..<4 {
    for z in -3..<4 {
      let use_black = (x + z) % 2 == 0
      let material = if use_black { black_material } else { white_material }
      spawn_mesh(
        world,
        plane_mesh,
        material,
        @transform.Transform::from_xyz(
          float_from_int(x) * 2.0F,
          -1.0F,
          float_from_int(z) * 2.0F,
        ),
      )
      |> ignore
    }
  }

  let light = world.spawn_empty()
  try! world.set_by_key(
    light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::default(),
  )
  try! world.set_by_key(
    light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::default(),
  )
  try! world.set_by_key(
    light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F),
  )

  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(0.0F, 2.5F, 10.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  try! world.set_by_key(camera, @pbr.ecs_key_hdr, @pbr.Hdr::default())
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
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in blend_modes example")
  }
}

///|
fn example_control_system(world : @ecs.World) -> Unit {
  let delta = world_time(world).delta_seconds()
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
  if @input.key_just_pressed(@window.KeyCode::KeyH) {
    if (try! world.contains_by_key(camera_entity, @pbr.ecs_key_hdr)) {
      try! (world.take(camera_entity, @pbr.ecs_key_hdr) |> ignore)
    } else {
      try! world.set_by_key(
        camera_entity,
        @pbr.ecs_key_hdr,
        @pbr.Hdr::default(),
      )
    }
  }
  let camera_x = @math.sin(state.camera_angle) * CAMERA_RADIUS
  let camera_z = @math.cos(state.camera_angle) * CAMERA_RADIUS
  try! (world.replace(
    camera_entity,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(camera_x, 2.5F, camera_z).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  |> ignore)

  for controlled in state.materials {
    if @pbr.standard_material_get(controlled.handle) is Some(material) {
      let mut next_material = material.with_base_color(
        @sprite.Color::new(
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
      @pbr.standard_material_set(controlled.handle, next_material) |> ignore
    }
  }

  update_ui_overlay(world)
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(example_control_system))
  .run()
}
