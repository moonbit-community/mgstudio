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
const ROTATION_SPEED : Float = 0.005F

///|
const HUE_SHIFT_SPEED : Float = 0.2F

///|
const SWITCH_TO_MAP_HELP_TEXT : String = "Press Space to switch to a specular map"

///|
const SWITCH_TO_SOLID_TINT_HELP_TEXT : String = "Press Space to switch to a solid specular tint"

///|
const TWO_PI : Float = 6.283185307179586F

///|
priv enum TintType {
  Solid
  Map
}

///|
priv struct SpecularTintState {
  mut tint_type : TintType
  mut hue_deg : Float
  mut camera : @core.Entity?
  mut material : @asset.Handle[@pbr.StandardMaterial]?
  mut noise_texture : @asset.Handle[@asset.Image]?
  mut help_text : @core.Entity?
}

///|
let specular_tint_state : Ref[SpecularTintState] = Ref::new({
  tint_type: TintType::Solid,
  hue_deg: 0.0F,
  camera: None,
  material: None,
  noise_texture: None,
  help_text: None,
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn wrap_hue_deg(value : Float) -> Float {
  let mut hue = value
  while hue >= 360.0F {
    hue = hue - 360.0F
  }
  while hue < 0.0F {
    hue = hue + 360.0F
  }
  hue
}

///|
fn tint_from_hue_deg(hue_deg : Float) -> @sprite.Color {
  let hue = wrap_hue_deg(hue_deg)
  let (r, g, b) = if hue < 60.0F {
    (1.0F, hue / 60.0F, 0.0F)
  } else if hue < 120.0F {
    (1.0F - (hue - 60.0F) / 60.0F, 1.0F, 0.0F)
  } else if hue < 180.0F {
    (0.0F, 1.0F, (hue - 120.0F) / 60.0F)
  } else if hue < 240.0F {
    (0.0F, 1.0F - (hue - 180.0F) / 60.0F, 1.0F)
  } else if hue < 300.0F {
    ((hue - 240.0F) / 60.0F, 0.0F, 1.0F)
  } else {
    (1.0F, 0.0F, 1.0F - (hue - 300.0F) / 60.0F)
  }
  @sprite.Color::new(r, g, b, 1.0F)
}

///|
fn app_status_help_text(tint_type : TintType) -> String {
  match tint_type {
    Solid => SWITCH_TO_MAP_HELP_TEXT
    Map => SWITCH_TO_SOLID_TINT_HELP_TEXT
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
  let sector_step = TWO_PI / sectors_f

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

  @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(
        @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
      ),
    ),
  )
}

///|
fn set_global_ambient_light(
  world : @ecs.World,
  color : @sprite.Color,
  brightness : Float,
) -> Unit {
  let ambient = @pbr.GlobalAmbientLight::new(color, brightness)
  world.insert_resource(@pbr.ecs_key_global_ambient_light, ambient)
}

///|
fn setup(world : @ecs.World) -> Unit {
  let state = specular_tint_state.val
  state.tint_type = TintType::Solid
  state.hue_deg = 0.0F
  state.camera = None
  state.material = None
  state.noise_texture = None
  state.help_text = None
  set_global_ambient_light(world, @sprite.Color::black(), 0.0F)

  let asset_server = @asset.AssetServer::new()
  let diffuse_env_map : @asset.Handle[@asset.Image] = asset_server.load(
    "environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2",
  )
  let specular_env_map : @asset.Handle[@asset.Image] = asset_server.load(
    "environment_maps/pisa_specular_rgb9e5_zstd.ktx2",
  )
  let noise_texture : @asset.Handle[@asset.Image] = asset_server.load(
    "textures/AlphaNoise.png",
  )
  let ui_font : @asset.Handle[@asset.Font] = asset_server.load_font(
    "fonts/FiraSans-Bold.ttf",
  )
  state.noise_texture = Some(noise_texture)

  let sphere_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::black())
    .with_reflectance(1.0F)
    .with_specular_tint(tint_from_hue_deg(state.hue_deg))
    .with_metallic(0.0F)
    .with_perceptual_roughness(0.0F),
  )
  state.material = Some(sphere_material)

  @pbr.MeshMaterial3dBundle::new(
    uv_sphere_mesh(1.0F, 18, 32),
    @pbr.MeshMaterial3d::new(sphere_material),
    @transform.Transform::identity().with_rotation(
      @math.Quat::from_rotation_x(PI * 0.5F),
    ),
  ).spawn(world)
  |> ignore

  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(-2.0F, 0.0F, 3.5F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  try! world.set_by_key(camera, @pbr.ecs_key_hdr, @pbr.Hdr::default())
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_skybox,
    @pbr.Skybox::new(specular_env_map, 3000.0F),
  )
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_environment_map_light,
    @pbr.EnvironmentMapLight::new(
      Some(diffuse_env_map),
      Some(specular_env_map),
      25000.0F,
    ),
  )
  state.camera = Some(camera)

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
  let help_entity = world.spawn_empty()
  try! world.set_by_key(
    help_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    help_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    help_entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_bottom(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(
    help_entity,
    @text.ecs_key_text,
    @text.Text::new(app_status_help_text(state.tint_type)),
  )
  try! world.set_by_key(
    help_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    help_entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_bottom(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(
    help_entity,
    @text.ecs_key_text,
    @text.Text::new(app_status_help_text(state.tint_type)),
  )
  try! world.set_by_key(
    help_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(ui_font).with_font_size(18.0F),
  )
  try! world.set_by_key(
    help_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
  )
  try! world.set_by_key(
    help_entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(@text.Justify::Left),
  )
  state.help_text = Some(help_entity)
}

///|
fn rotate_camera(world : @ecs.World) -> Unit {
  let state = specular_tint_state.val
  guard state.camera is Some(camera_entity) else { return }
  guard (try! world.get_by_key(camera_entity, @transform.ecs_key_transform))
    is Some(transform) else {
    return
  }

  let cos_v = @math.cos(ROTATION_SPEED)
  let sin_v = @math.sin(ROTATION_SPEED)
  let x = transform.translation.x
  let z = transform.translation.z
  let rotated_x = cos_v * x - sin_v * z
  let rotated_z = sin_v * x + cos_v * z

  try! (world.replace(
    camera_entity,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(
      rotated_x,
      transform.translation.y,
      rotated_z,
    ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F)),
  )
  |> ignore)
}

///|
fn toggle_specular_map(_world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Space) {
    return
  }

  let state = specular_tint_state.val
  state.tint_type = match state.tint_type {
    Solid => TintType::Map
    Map => TintType::Solid
  }

  guard state.material is Some(material_handle) else { return }
  guard @pbr.standard_material_get(material_handle) is Some(material) else {
    return
  }

  let next_material = match state.tint_type {
    Solid => material.with_reflectance(1.0F).with_specular_tint_texture(None)
    Map => {
      guard state.noise_texture is Some(noise_texture) else { return }
      material
      .with_reflectance(2.0F)
      .with_specular_tint(@sprite.Color::white())
      .with_specular_tint_texture(Some(noise_texture))
    }
  }
  @pbr.standard_material_set(material_handle, next_material) |> ignore
}

///|
fn shift_hue(_world : @ecs.World) -> Unit {
  let state = specular_tint_state.val
  if state.tint_type is Map {
    return
  }
  guard state.material is Some(material_handle) else { return }
  guard @pbr.standard_material_get(material_handle) is Some(material) else {
    return
  }

  state.hue_deg = wrap_hue_deg(state.hue_deg + HUE_SHIFT_SPEED)
  let next_material = material.with_specular_tint(
    tint_from_hue_deg(state.hue_deg),
  )
  @pbr.standard_material_set(material_handle, next_material) |> ignore
}

///|
fn update_help_text(_world : @ecs.World) -> Unit {
  let state = specular_tint_state.val
  guard state.help_text is Some(help_entity) else { return }
  guard @app.current_world() is Some(world) else { return }
  guard (try! world.get_by_key(help_entity, @text.ecs_key_text))
    is Some(text_value) else {
    return
  }
  text_value.content = app_status_help_text(state.tint_type)
  ignore(try! world.replace(help_entity, @text.ecs_key_text, text_value))
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(rotate_camera))
  .add_systems(@app.Update, @app.system(toggle_specular_map))
  .add_systems(@app.Update, @app.system(update_help_text))
  .add_systems(@app.Update, @app.system(shift_hue))
  .run()
}
