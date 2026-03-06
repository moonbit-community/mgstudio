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
/// Baseline parity: use mgstudio's exposed SSAO/TemporalJitter components and
/// keyboard controls aligned with Bevy's sample flow.

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
  mut camera : @core.Entity?
  mut sphere : @core.Entity?
  mut help_text : @text.TextHandle?
}

///|
let ssao_state : Ref[SsaoState] = Ref::new({
  quality: 3,
  thickness: 0.25F,
  taa_enabled: true,
  camera: None,
  sphere: None,
  help_text: None,
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
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
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
    (if state.taa_enabled { "(Space) Enabled" } else { "(Space) Disabled" })
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
  world : @ecs.World,
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
fn set_global_ambient_light(
  world : @ecs.World,
  color : @render2d.Color,
  brightness : Float,
) -> Unit {
  let ambient = @render3d.GlobalAmbientLight::new(color, brightness)
  world.insert_resource(@render3d.ecs_key_global_ambient_light, ambient)
}

///|
fn ssao_quality_from_index(
  quality : Int,
) -> @render3d.ScreenSpaceAmbientOcclusionQualityLevel {
  if quality <= 1 {
    @render3d.ScreenSpaceAmbientOcclusionQualityLevel::Low
  } else if quality == 2 {
    @render3d.ScreenSpaceAmbientOcclusionQualityLevel::Medium
  } else if quality == 3 {
    @render3d.ScreenSpaceAmbientOcclusionQualityLevel::High
  } else {
    @render3d.ScreenSpaceAmbientOcclusionQualityLevel::Ultra
  }
}

///|
fn apply_ssao_settings(world : @ecs.World) -> Unit {
  guard ssao_state.val.camera is Some(camera_entity) else { return }
  let tick = world.read_change_tick()
  let ssao_store = world.component(
    @render3d.ecs_key_screen_space_ambient_occlusion,
  )

  if ssao_state.val.quality == 0 {
    ssao_store.remove(camera_entity) |> ignore
    return
  }

  let component = @render3d.ScreenSpaceAmbientOcclusion::default()
    .with_quality_level(ssao_quality_from_index(ssao_state.val.quality))
    .with_constant_object_thickness(ssao_state.val.thickness)
  if ssao_store.contains(camera_entity) {
    ssao_store.set(camera_entity, component, tick) |> ignore
  } else {
    ssao_store.insert(camera_entity, component, tick)
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  ssao_state.val = {
    quality: 3,
    thickness: 0.25F,
    taa_enabled: true,
    camera: None,
    sphere: None,
    help_text: None,
  }

  let tick = world.read_change_tick()
  set_global_ambient_light(world, @render2d.Color::white(), 1000.0F)

  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(-2.0F, 2.0F, -2.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  ssao_state.val.camera = Some(camera)
  world
  .component(@render3d.ecs_key_hdr)
  .insert(camera, @render3d.Hdr::default(), tick)
  world
  .component(@render3d.ecs_key_msaa)
  .insert(camera, @render3d.Msaa::Off, tick)
  world
  .component(@render3d.ecs_key_temporal_anti_aliasing)
  .insert(camera, @render3d.TemporalAntiAliasing::default(), tick)
  world
  .component(@render3d.ecs_key_temporal_jitter)
  .insert(camera, @render3d.TemporalJitter::default(), tick)

  let base_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.5F, 0.5F, 0.5F, 1.0F),
    )
    .with_perceptual_roughness(1.0F)
    .with_reflectance(0.0F),
  )

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

  let sphere = spawn_mesh(
    world,
    uv_sphere_mesh(0.4F, 36, 72),
    sphere_material,
    @math.Transform::from_xyz(0.0F, 0.0F, 0.0F),
  )
  ssao_state.val.sphere = Some(sphere)

  let light = world.spawn_empty()
  world
  .component(@math.ecs_key_transform)
  .insert(
    light,
    @math.Transform::identity().with_rotation(
      @math.Quat::from_rotation_y(-PI * 0.15F).mul(
        @math.Quat::from_rotation_x(-PI * 0.15F),
      ),
    ),
    tick,
  )
  world
  .component(@render3d.ecs_key_directional_light)
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

  apply_ssao_settings(world)
}

///|
fn update(world : @ecs.World) -> Unit {
  if ssao_state.val.sphere is Some(sphere_entity) {
    if world.component(@math.ecs_key_transform).get(sphere_entity)
      is Some(transform) {
      let next_y = @math.sin(@time.time_elapsed_seconds() / 1.7F) * 0.7F
      world
      .component(@math.ecs_key_transform)
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
    if ssao_state.val.camera is Some(camera_entity) {
      let tick = world.read_change_tick()
      let temporal_jitter_store = world.component(
        @render3d.ecs_key_temporal_jitter,
      )
      if ssao_state.val.taa_enabled {
        if !temporal_jitter_store.contains(camera_entity) {
          temporal_jitter_store.insert(
            camera_entity,
            @render3d.TemporalJitter::default(),
            tick,
          )
        }
      } else {
        temporal_jitter_store.remove(camera_entity) |> ignore
      }
    }
    changed = true
  }

  if changed {
    update_help_text()
  }

  apply_ssao_settings(world)
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(update)
  .run()
}
