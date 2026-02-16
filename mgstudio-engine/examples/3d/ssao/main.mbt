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
/// Port of `bevy/examples/3d/ssao.rs`.
///
/// Baseline parity: Bevy's native SSAO + temporal jitter render pipeline is
/// approximated in mgstudio via AO proxy controls (material darkening,
/// ambient/fog response, temporal stability proxy).

///|
const PI : Float = 3.141592653589793F

///|
const SSAO_MIN_THICKNESS : Float = 0.0625F

///|
const SSAO_MAX_THICKNESS : Float = 4.0F

///|
priv struct SsaoState {
  mut quality : Int
  mut thickness : Float
  mut taa_enabled : Bool
  mut sphere : @core.Entity?
  mut help_text : @text.TextHandle?
  mut base_material : @asset.Handle[@render3d.StandardMaterial]?
  mut sphere_material : @asset.Handle[@render3d.StandardMaterial]?
}

///|
let ssao_state : Ref[SsaoState] = Ref::new({
  quality: 2,
  thickness: 1.0F,
  taa_enabled: true,
  sphere: None,
  help_text: None,
  base_material: None,
  sphere_material: None,
})

///|
fn clampf(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn clamp01(value : Float) -> Float {
  clampf(value, 0.0F, 1.0F)
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn quality_factor(quality : Int) -> Float {
  if quality <= 0 {
    0.0F
  } else if quality == 1 {
    0.25F
  } else if quality == 2 {
    0.5F
  } else if quality == 3 {
    0.75F
  } else {
    1.0F
  }
}

///|
fn marker(current_quality : Int, index : Int) -> String {
  if current_quality == index {
    "*"
  } else {
    ""
  }
}

///|
fn ssao_ui_text() -> String {
  let state = ssao_state.val
  let mut text = ""
  if state.quality != 0 {
    text = text + "Constant object thickness: \{state.thickness} (Up/Down)\n\n"
  }

  let o = marker(state.quality, 0)
  let l = marker(state.quality, 1)
  let m = marker(state.quality, 2)
  let h = marker(state.quality, 3)
  let u = marker(state.quality, 4)

  text = text + "SSAO Quality:\n"
  text = text + "(1) \{o}Off\{o}\n"
  text = text + "(2) \{l}Low\{l}\n"
  text = text + "(3) \{m}Medium\{m}\n"
  text = text + "(4) \{h}High\{h}\n"
  text = text + "(5) \{u}Ultra\{u}\n\n"
  text = text + "Temporal Antialiasing:\n"
  text = text +
    (if state.taa_enabled {
      "(Space) Enabled (Proxy)"
    } else {
      "(Space) Disabled (Proxy)"
    })
  text = text +
    "\n\nSSAO note: render-path approximation in current mgstudio runtime."
  text
}

///|
fn update_help_text() -> Unit {
  if ssao_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, ssao_ui_text())
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

  @render3d.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
  )
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
fn apply_ssao_proxy(world : @ecs_world.World) -> Unit {
  let quality = quality_factor(ssao_state.val.quality)
  let thickness_norm = clamp01(
    (ssao_state.val.thickness - SSAO_MIN_THICKNESS) /
    (SSAO_MAX_THICKNESS - SSAO_MIN_THICKNESS),
  )
  let ao_strength = quality * (0.5F + 0.5F * thickness_norm)

  let temporal_noise = if ssao_state.val.taa_enabled {
    0.0F
  } else {
    @math.sin(@time.time_elapsed_seconds() * 45.0F) * 0.004F
  }

  let ambient_brightness = clampf(
    0.06F - ao_strength * 0.04F + temporal_noise,
    0.0F,
    0.08F,
  )

  let tick = world.read_change_tick()
  let ambient = world.get_global_ambient_light_resource()
  if ambient.get_ref_mut(tick) is Some(value) {
    value.val = @render3d.GlobalAmbientLight::new(
      @render2d.Color::white(),
      ambient_brightness,
    )
  }

  let fog_start = clampf(0.8F - quality * 0.35F, 0.25F, 1.0F)
  let fog_end = clampf(7.5F - quality * 2.0F, 3.0F, 9.0F)
  let fog_base = clampf(0.18F - ao_strength * 0.08F, 0.08F, 0.22F)

  @render3d.render3d_set_distance_fog(
    @render3d.DistanceFog::new(
      @render2d.Color::new(
        clamp01(fog_base + temporal_noise),
        clamp01(fog_base + temporal_noise * 0.7F),
        clamp01(fog_base + temporal_noise * 0.5F),
        1.0F,
      ),
      @render3d.FogFalloff3d::linear(fog_start, fog_end),
    ),
  )

  if ssao_state.val.base_material is Some(handle) {
    if @render3d.standard_material_get(handle) is Some(material) {
      let shade = clampf(0.5F - ao_strength * 0.18F, 0.22F, 0.5F)
      @render3d.standard_material_set(
        handle,
        material
        .with_base_color(@render2d.Color::new(shade, shade, shade, 1.0F))
        .with_perceptual_roughness(1.0F)
        .with_reflectance(0.0F),
      )
      |> ignore
    }
  }

  if ssao_state.val.sphere_material is Some(handle) {
    if @render3d.standard_material_get(handle) is Some(material) {
      let shade = clampf(0.4F - ao_strength * 0.17F, 0.16F, 0.4F)
      @render3d.standard_material_set(
        handle,
        material
        .with_base_color(@render2d.Color::new(shade, shade, shade, 1.0F))
        .with_perceptual_roughness(1.0F)
        .with_reflectance(0.0F),
      )
      |> ignore
    }
  }
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  ssao_state.val = {
    quality: 2,
    thickness: 1.0F,
    taa_enabled: true,
    sphere: None,
    help_text: None,
    base_material: None,
    sphere_material: None,
  }

  let tick = world.read_change_tick()

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(-2.0F, 2.0F, -2.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore

  let base_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.5F, 0.5F, 0.5F, 1.0F),
    )
    .with_perceptual_roughness(1.0F)
    .with_reflectance(0.0F),
  )
  ssao_state.val.base_material = Some(base_material)

  spawn_mesh(
    world,
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    base_material,
    @math.Transform::from_xyz(0.0F, 0.0F, 1.0F),
  )
  |> ignore

  spawn_mesh(
    world,
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    base_material,
    @math.Transform::from_xyz(0.0F, -1.0F, 0.0F),
  )
  |> ignore

  spawn_mesh(
    world,
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    base_material,
    @math.Transform::from_xyz(1.0F, 0.0F, 0.0F),
  )
  |> ignore

  let sphere_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.4F, 0.4F, 0.4F, 1.0F),
    )
    .with_perceptual_roughness(1.0F)
    .with_reflectance(0.0F),
  )
  ssao_state.val.sphere_material = Some(sphere_material)

  let sphere = spawn_mesh(
    world,
    uv_sphere_mesh(0.4F, 36, 72),
    sphere_material,
    @math.Transform::from_xyz(0.0F, 0.0F, 0.0F),
  )
  ssao_state.val.sphere = Some(sphere)

  let light = world.spawn_empty()
  world
  .get_transform_store()
  .insert(
    light,
    @math.Transform::from_xyz(2.0F, 2.0F, -2.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  world
  .get_directional_light_store()
  .insert(
    light,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 9_000.0F, true),
    tick,
  )

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let text = @text.Text2dBundle::new(
      @text.Text2d::new(ssao_ui_text()),
      @text.TextFont::default().with_font(font).with_font_size(16.0F),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, -320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@render2d.Anchor::bottom_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .spawn()
  ssao_state.val.help_text = Some(text)

  apply_ssao_proxy(world)
}

///|
fn update(world : @ecs_world.World) -> Unit {
  if ssao_state.val.sphere is Some(sphere_entity) {
    if world.get_transform_store().get(sphere_entity) is Some(transform) {
      let next_y = @math.sin(@time.time_elapsed_seconds() / 1.7F) * 0.7F
      world
      .get_transform_store()
      .set(
        sphere_entity,
        transform.with_translation(
          @math.Vec3::new(
            transform.translation.x,
            next_y,
            transform.translation.z,
          ),
        ),
        world.read_change_tick(),
      )
      |> ignore
    }
  }

  let mut changed = false

  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    ssao_state.val.quality = 0
    changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit2) {
    ssao_state.val.quality = 1
    changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit3) {
    ssao_state.val.quality = 2
    changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit4) {
    ssao_state.val.quality = 3
    changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit5) {
    ssao_state.val.quality = 4
    changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::ArrowUp) {
    ssao_state.val.thickness = clampf(
      ssao_state.val.thickness * 2.0F,
      SSAO_MIN_THICKNESS,
      SSAO_MAX_THICKNESS,
    )
    changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::ArrowDown) {
    ssao_state.val.thickness = clampf(
      ssao_state.val.thickness * 0.5F,
      SSAO_MIN_THICKNESS,
      SSAO_MAX_THICKNESS,
    )
    changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::Space) {
    ssao_state.val.taa_enabled = !ssao_state.val.taa_enabled
    changed = true
  }

  if changed {
    update_help_text()
  }

  apply_ssao_proxy(world)
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(update)
  .run()
}
