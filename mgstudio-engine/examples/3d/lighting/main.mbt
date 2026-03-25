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
/// Port of `bevy/examples/3d/lighting.rs`.

///|
const PI : Float = 3.141592653589793F

///|
const MOVE_SPEED : Float = 2.0F

///|
priv struct LightingParameters {
  aperture_f_stops : Float
  shutter_speed_s : Float
  sensitivity_iso : Float
}

///|
priv struct LightingState {
  mut parameters : LightingParameters
  mut ambient_enabled : Bool
  movables : Array[@core.Entity]
  mut directional_light : @core.Entity?
  mut ui_text : @text.TextHandle?
}

///|
let lighting_state : Ref[LightingState] = Ref::new({
  parameters: {
    aperture_f_stops: 1.0F,
    shutter_speed_s: 1.0F / 125.0F,
    sensitivity_iso: 100.0F,
  },
  ambient_enabled: true,
  movables: [],
  directional_light: None,
  ui_text: None,
})

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(update_exposure))
  .add_systems(@app.Update, @app.system(toggle_ambient_light))
  .add_systems(@app.Update, @app.system(movement))
  .add_systems(@app.Update, @app.system(animate_light_direction))
  .run()
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn round_to_int(value : Float) -> Int {
  if value >= 0.0F {
    (value + 0.5F).to_int()
  } else {
    (value - 0.5F).to_int()
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
  let sector_step = 2.0F * PI / sectors_f

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
fn rectangle_mesh(width : Float, height : Float) -> @pbr.Mesh3d {
  let hw = width / 2.0F
  let hh = height / 2.0F
  let positions = [
    @math.Vec3::new(-hw, -hh, 0.0F),
    @math.Vec3::new(hw, -hh, 0.0F),
    @math.Vec3::new(hw, hh, 0.0F),
    @math.Vec3::new(-hw, hh, 0.0F),
  ]
  let uvs = [
    @math.Vec2::new(0.0F, 1.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 0.0F),
  ]
  let indices = [0, 1, 2, 0, 2, 3]
  @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(
        @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
      ),
    ),
  )
}

///|
fn lighting_overlay_text() -> String {
  let params = lighting_state.val.parameters
  let ambient_state = if lighting_state.val.ambient_enabled {
    "on"
  } else {
    "off"
  }
  let shutter_denominator = if params.shutter_speed_s <= 0.0F {
    0
  } else {
    round_to_int(1.0F / params.shutter_speed_s)
  }
  "Ambient light is \{ambient_state}\nAperture: f/\{round_to_int(params.aperture_f_stops)}\nShutter speed: 1/\{shutter_denominator}s\nSensitivity: ISO \{round_to_int(params.sensitivity_iso)}\n\nControls\n---------------\nArrow keys - Move objects\nSpace - Toggle ambient light\n1/2 - Decrease/Increase aperture\n3/4 - Decrease/Increase shutter speed\n5/6 - Decrease/Increase sensitivity\nR - Reset exposure"
}

///|
fn lighting_update_overlay_text() -> Unit {
  if lighting_state.val.ui_text is Some(handle) {
    @text.text_set_content(handle, lighting_overlay_text())
  }
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
fn setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let logo_texture = asset_server.load("branding/bevy_logo_light.png")

  // Ground plane.
  let ground_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white()).with_perceptual_roughness(
      1.0F,
    ),
  )
  spawn_mesh(
    world,
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(10.0F, 10.0F)),
      ),
    ),
    ground_material,
    @transform.Transform::identity(),
  )
  |> ignore

  // Left and back walls.
  let wall_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.294F, 0.0F, 0.51F, 1.0F),
    ).with_perceptual_roughness(1.0F),
  )
  spawn_mesh(
    world,
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(5.0F, 0.15F, 5.0F),
        ),
      ),
    ),
    wall_material,
    @transform.Transform::from_xyz(2.5F, 2.5F, 0.0F).with_rotation(
      @math.Quat::from_rotation_z(PI / 2.0F),
    ),
  )
  |> ignore
  spawn_mesh(
    world,
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(5.0F, 0.15F, 5.0F),
        ),
      ),
    ),
    wall_material,
    @transform.Transform::from_xyz(0.0F, 2.5F, -2.5F).with_rotation(
      @math.Quat::from_rotation_x(PI / 2.0F),
    ),
  )
  |> ignore

  // Bevy logo alpha-mask quad.
  let logo_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white())
    .with_base_color_texture(Some(logo_texture))
    .with_perceptual_roughness(1.0F)
    .with_alpha_mode(@pbr.AlphaMode3d::Mask(0.5F))
    .with_cull_mode(None),
  )
  let logo = spawn_mesh(
    world,
    rectangle_mesh(2.0F, 0.5F),
    logo_material,
    @transform.Transform::from_xyz(-2.2F, 0.5F, 1.0F).with_rotation(
      @math.Quat::from_rotation_y(PI / 8.0F),
    ),
  )
  lighting_state.val.movables.push(logo)

  let cube = spawn_mesh(
    world,
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.standard_material_add(
      @pbr.StandardMaterial::from_color(
        @sprite.Color::new(1.0F, 0.078F, 0.576F, 1.0F),
      ),
    ),
    @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F),
  )
  lighting_state.val.movables.push(cube)

  let sphere_mesh = uv_sphere_mesh(0.5F, 18, 32)
  let sphere = spawn_mesh(
    world,
    sphere_mesh,
    @pbr.standard_material_add(
      @pbr.StandardMaterial::from_color(
        @sprite.Color::new(0.196F, 0.804F, 0.196F, 1.0F),
      ),
    ),
    @transform.Transform::from_xyz(1.5F, 1.0F, 1.5F),
  )
  lighting_state.val.movables.push(sphere)

  // Ambient light.
  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(
      @sprite.Color::new(1.0F, 0.27F, 0.0F, 1.0F),
      200.0F,
    ),
  )
  lighting_state.val.ambient_enabled = true

  // Red point light + emissive marker.
  let red_light = world.spawn_empty()
  try! world.set_by_key(
    red_light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::new(
      @sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F),
      100_000.0F,
      20.0F,
      true,
    ),
  )
  try! world.set_by_key(
    red_light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(1.0F, 2.0F, 0.0F),
  )
  spawn_mesh(
    world,
    uv_sphere_mesh(0.1F, 12, 20),
    @pbr.standard_material_add(
      @pbr.StandardMaterial::from_color(
        @sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F),
      ).with_emissive(@sprite.Color::new(4.0F, 0.0F, 0.0F, 1.0F)),
    ),
    @transform.Transform::from_xyz(1.0F, 2.0F, 0.0F),
  )
  |> ignore

  // Green spot light + emissive marker.
  let green_light = world.spawn_empty()
  try! world.set_by_key(
    green_light,
    @pbr.ecs_key_spot_light,
    @pbr.SpotLight::new(
      @sprite.Color::new(0.0F, 1.0F, 0.0F, 1.0F),
      100_000.0F,
      20.0F,
      0.6F,
      0.8F,
      true,
    ),
  )
  try! world.set_by_key(
    green_light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(-1.0F, 2.0F, 0.0F).looking_at(
      @math.Vec3::new(-1.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 0.0F, 1.0F),
    ),
  )
  spawn_mesh(
    world,
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(0.1F, 0.125F, 0.1F),
        ),
      ),
    ),
    @pbr.standard_material_add(
      @pbr.StandardMaterial::from_color(
        @sprite.Color::new(0.0F, 1.0F, 0.0F, 1.0F),
      ).with_emissive(@sprite.Color::new(0.0F, 4.0F, 0.0F, 1.0F)),
    ),
    @transform.Transform::from_xyz(-1.0F, 2.0F, 0.0F).with_rotation(
      @math.Quat::from_rotation_x(PI / 2.0F),
    ),
  )
  |> ignore

  // Blue point light + emissive marker.
  let blue_light = world.spawn_empty()
  try! world.set_by_key(
    blue_light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::new(
      @sprite.Color::new(0.0F, 0.0F, 1.0F, 1.0F),
      100_000.0F,
      20.0F,
      true,
    ),
  )
  try! world.set_by_key(
    blue_light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 4.0F, 0.0F),
  )
  spawn_mesh(
    world,
    uv_sphere_mesh(0.1F, 12, 20),
    @pbr.standard_material_add(
      @pbr.StandardMaterial::from_color(
        @sprite.Color::new(0.0F, 0.0F, 1.0F, 1.0F),
      ).with_emissive(@sprite.Color::new(0.0F, 0.0F, 713.0F, 1.0F)),
    ),
    @transform.Transform::from_xyz(0.0F, 4.0F, 0.0F),
  )
  |> ignore

  // Directional light.
  let directional = world.spawn_empty()
  try! world.set_by_key(
    directional,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::new(@sprite.Color::white(), 10_000.0F, true),
  )
  try! world.set_by_key(
    directional,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 2.0F, 0.0F).with_rotation(
      @math.Quat::from_rotation_x(-PI / 4.0F),
    ),
  )
  lighting_state.val.directional_light = Some(directional)

  let overlay_font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let overlay = @text.Text2dBundle::new(
      @text.Text2d::new(lighting_overlay_text()),
      @text.TextFont::default().with_font(overlay_font).with_font_size(18.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, 300.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  lighting_state.val.ui_text = Some(overlay)

  // Camera.
  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn update_exposure(_world : @ecs.World) -> Unit {
  let mut changed = false
  let mut next = lighting_state.val.parameters
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    next = { ..next, aperture_f_stops: next.aperture_f_stops * 2.0F }
    changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit1) {
    next = { ..next, aperture_f_stops: next.aperture_f_stops * 0.5F }
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit4) {
    next = { ..next, shutter_speed_s: next.shutter_speed_s * 2.0F }
    changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit3) {
    next = { ..next, shutter_speed_s: next.shutter_speed_s * 0.5F }
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit6) {
    next = { ..next, sensitivity_iso: next.sensitivity_iso + 100.0F }
    changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit5) {
    next = { ..next, sensitivity_iso: next.sensitivity_iso - 100.0F }
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyR) {
    next = {
      aperture_f_stops: 1.0F,
      shutter_speed_s: 1.0F / 125.0F,
      sensitivity_iso: 100.0F,
    }
    changed = true
  }
  if changed {
    lighting_state.val.parameters = next
    lighting_update_overlay_text()
  }
}

///|
fn toggle_ambient_light(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Space) {
    return
  }
  if (try? world.get_resource(@pbr.ecs_key_global_ambient_light))
    is Ok(Some(ambient)) {
    if ambient.brightness > 1.0F {
      world.insert_resource(
        @pbr.ecs_key_global_ambient_light,
        @pbr.GlobalAmbientLight::new(ambient.color, 0.0F),
      )
      lighting_state.val.ambient_enabled = false
    } else {
      world.insert_resource(
        @pbr.ecs_key_global_ambient_light,
        @pbr.GlobalAmbientLight::new(ambient.color, 200.0F),
      )
      lighting_state.val.ambient_enabled = true
    }
    lighting_update_overlay_text()
  }
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in lighting example")
  }
}

///|
fn animate_light_direction(world : @ecs.World) -> Unit {
  guard lighting_state.val.directional_light is Some(light_entity) else {
    return
  }
  if (try! world.get_by_key(light_entity, @transform.ecs_key_transform))
    is Some(transform) {
    let delta = world_time(world).delta_seconds() * 0.5F
    let spin = @math.Quat::from_rotation_y(delta)
    let next = transform.with_rotation(transform.rotation.mul(spin).normalize())
    try! (world.replace(light_entity, @transform.ecs_key_transform, next)
    |> ignore)
  }
}

///|
fn movement(world : @ecs.World) -> Unit {
  let mut dx = 0.0F
  let mut dy = 0.0F
  if @input.key_pressed(@window.KeyCode::ArrowUp) {
    dy = dy + 1.0F
  }
  if @input.key_pressed(@window.KeyCode::ArrowDown) {
    dy = dy - 1.0F
  }
  if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    dx = dx - 1.0F
  }
  if @input.key_pressed(@window.KeyCode::ArrowRight) {
    dx = dx + 1.0F
  }
  if dx == 0.0F && dy == 0.0F {
    return
  }

  let delta = world_time(world).delta_seconds() * MOVE_SPEED
  for entity in lighting_state.val.movables {
    if (try! world.get_by_key(entity, @transform.ecs_key_transform))
      is Some(transform) {
      let next = transform.with_translation(
        @math.Vec3::new(
          transform.translation.x + delta * dx,
          transform.translation.y + delta * dy,
          transform.translation.z,
        ),
      )
      try! (world.replace(entity, @transform.ecs_key_transform, next) |> ignore)
    }
  }
}
