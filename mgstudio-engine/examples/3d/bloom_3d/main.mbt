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
/// Port of `bevy/examples/3d/bloom_3d.rs`.
///
/// Baseline parity:
/// - Camera `Bloom`, `Hdr`, and `Tonemapping::TonyMcMapface` are wired to
///   mgstudio camera components.
/// - Bevy bloom controls in this example now map directly to real bloom
///   component fields.

///|
const PI : Float = 3.141592653589793F

///|
priv struct BouncingSphere {
  entity : @core.Entity
  x : Float
  z : Float
  scale : Float
}

///|
priv struct BloomState {
  mut camera : @core.Entity?
  mut help_text : @text.TextHandle?
  mut bloom_enabled : Bool
  mut intensity : Float
  mut low_frequency_boost : Float
  mut low_frequency_boost_curvature : Float
  mut high_pass_frequency : Float
  mut prefilter_threshold : Float
  mut prefilter_threshold_softness : Float
  mut composite_mode : @render3d.BloomCompositeMode
  mut scale_x : Float
  spheres : Array[BouncingSphere]
}

///|
let bloom_state : Ref[BloomState] = Ref::new({
  camera: None,
  help_text: None,
  bloom_enabled: true,
  intensity: 0.15F,
  low_frequency_boost: 0.7F,
  low_frequency_boost_curvature: 0.95F,
  high_pass_frequency: 1.0F,
  prefilter_threshold: 0.0F,
  prefilter_threshold_softness: 0.0F,
  composite_mode: @render3d.BloomCompositeMode::EnergyConserving,
  scale_x: 1.0F,
  spheres: [],
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

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
fn stable_bucket(x : Int, z : Int) -> Int {
  let seed = (x + 11) * 37 + (z + 19) * 97 + x * z * 13
  let normalized = if seed < 0 { -seed } else { seed }
  (normalized + 3) % 6
}

///|
fn mode_label(mode : @render3d.BloomCompositeMode) -> String {
  match mode {
    EnergyConserving => "Energy-conserving"
    Additive => "Additive"
  }
}

///|
fn apply_camera_bloom(world : @ecs.World) -> Unit {
  guard bloom_state.val.camera is Some(camera_entity) else { return }
  let tick = world.read_change_tick()
  let bloom_store = world.component(@render3d.ecs_key_bloom)
  if bloom_state.val.bloom_enabled {
    let bloom = @render3d.Bloom::new(bloom_state.val.intensity)
      .with_low_frequency_boost(bloom_state.val.low_frequency_boost)
      .with_low_frequency_boost_curvature(
        bloom_state.val.low_frequency_boost_curvature,
      )
      .with_high_pass_frequency(bloom_state.val.high_pass_frequency)
      .with_prefilter(
        bloom_state.val.prefilter_threshold,
        bloom_state.val.prefilter_threshold_softness,
      )
      .with_composite_mode(bloom_state.val.composite_mode)
      .with_scale(@math.Vec2::new(bloom_state.val.scale_x, 1.0F))
    if bloom_store.contains(camera_entity) {
      bloom_store.set(camera_entity, bloom, tick) |> ignore
    } else {
      bloom_store.insert(camera_entity, bloom, tick)
    }
  } else {
    bloom_store.remove(camera_entity) |> ignore
  }
}

///|
fn ui_content() -> String {
  if !bloom_state.val.bloom_enabled {
    return "Bloom: Off (Toggle: Space)"
  }

  "Bloom (Toggle: Space)\n" +
  "(Q/A) Intensity: \{bloom_state.val.intensity}\n" +
  "(W/S) Low-frequency boost: \{bloom_state.val.low_frequency_boost}\n" +
  "(E/D) Low-frequency boost curvature: \{bloom_state.val.low_frequency_boost_curvature}\n" +
  "(R/F) High-pass frequency: \{bloom_state.val.high_pass_frequency}\n" +
  "(T/G) Mode: " +
  mode_label(bloom_state.val.composite_mode) +
  "\n" +
  "(Y/H) Threshold: \{bloom_state.val.prefilter_threshold}\n" +
  "(U/J) Threshold softness: \{bloom_state.val.prefilter_threshold_softness}\n" +
  "(I/K) Horizontal Scale: \{bloom_state.val.scale_x}"
}

///|
fn update_help_text() -> Unit {
  if bloom_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, ui_content())
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
fn setup_scene(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  bloom_state.val.camera = None
  bloom_state.val.help_text = None
  bloom_state.val.bloom_enabled = true
  bloom_state.val.intensity = 0.15F
  bloom_state.val.low_frequency_boost = 0.7F
  bloom_state.val.low_frequency_boost_curvature = 0.95F
  bloom_state.val.high_pass_frequency = 1.0F
  bloom_state.val.prefilter_threshold = 0.0F
  bloom_state.val.prefilter_threshold_softness = 0.0F
  bloom_state.val.composite_mode = @render3d.BloomCompositeMode::EnergyConserving
  bloom_state.val.scale_x = 1.0F
  bloom_state.val.spheres.clear()

  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default().with_clear_color(@render2d.Color::black()),
    @math.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world
  .component(@render3d.ecs_key_hdr)
  .insert(camera, @render3d.Hdr::default(), tick)
  world
  .component(@render3d.ecs_key_tonemapping)
  .insert(camera, @render3d.Tonemapping::TonyMcMapface, tick)
  world
  .component(@render3d.ecs_key_bloom)
  .insert(camera, @render3d.Bloom::new(bloom_state.val.intensity), tick)
  bloom_state.val.camera = Some(camera)

  let material_emissive1 = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::black()).with_emissive(
      @render2d.Color::new(0.0F, 0.0F, 150.0F, 1.0F),
    ),
  )
  let material_emissive2 = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::black()).with_emissive(
      @render2d.Color::new(1000.0F, 1000.0F, 1000.0F, 1.0F),
    ),
  )
  let material_emissive3 = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::black()).with_emissive(
      @render2d.Color::new(50.0F, 0.0F, 0.0F, 1.0F),
    ),
  )
  let material_non_emissive = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::black()),
  )

  let sphere_mesh = uv_sphere_mesh(0.4F, 20, 28)
  for xi in 0..<10 {
    let x = xi - 5
    for zi in 0..<10 {
      let z = zi - 5
      let rand = stable_bucket(x, z)
      let (material, scale) = if rand == 0 {
        (material_emissive1, 0.5F)
      } else if rand == 1 {
        (material_emissive2, 0.1F)
      } else if rand == 2 {
        (material_emissive3, 1.0F)
      } else {
        (material_non_emissive, 1.5F)
      }

      let x_pos = float_from_int(x) * 2.0F
      let z_pos = float_from_int(z) * 2.0F
      let entity = @render3d.MeshMaterial3dBundle::new(
        sphere_mesh,
        @render3d.MeshMaterial3d::new(material),
        @math.Transform::from_xyz(x_pos, 0.0F, z_pos).with_scale(
          @math.Vec3::splat(scale),
        ),
      ).spawn(world)
      bloom_state.val.spheres.push({ entity, x: x_pos, z: z_pos, scale })
    }
  }

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let help_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
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
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  bloom_state.val.help_text = Some(help_text)

  apply_camera_bloom(world)
  update_help_text()
}

///|
fn update_bloom_settings(world : @ecs.World) -> Unit {
  let delta = @time.time_delta_seconds()
  let mut changed = false

  if @input.key_just_pressed(@window.KeyCode::Space) {
    bloom_state.val.bloom_enabled = !bloom_state.val.bloom_enabled
    changed = true
  }

  if bloom_state.val.bloom_enabled {
    if @input.key_pressed(@window.KeyCode::KeyA) {
      bloom_state.val.intensity = bloom_state.val.intensity - delta / 10.0F
      changed = true
    }
    if @input.key_pressed(@window.KeyCode::KeyQ) {
      bloom_state.val.intensity = bloom_state.val.intensity + delta / 10.0F
      changed = true
    }
    bloom_state.val.intensity = clampf(bloom_state.val.intensity, 0.0F, 1.0F)

    if @input.key_pressed(@window.KeyCode::KeyS) {
      bloom_state.val.low_frequency_boost = bloom_state.val.low_frequency_boost -
        delta / 10.0F
      changed = true
    }
    if @input.key_pressed(@window.KeyCode::KeyW) {
      bloom_state.val.low_frequency_boost = bloom_state.val.low_frequency_boost +
        delta / 10.0F
      changed = true
    }
    bloom_state.val.low_frequency_boost = clampf(
      bloom_state.val.low_frequency_boost,
      0.0F,
      1.0F,
    )

    if @input.key_pressed(@window.KeyCode::KeyD) {
      bloom_state.val.low_frequency_boost_curvature = bloom_state.val.low_frequency_boost_curvature -
        delta / 10.0F
      changed = true
    }
    if @input.key_pressed(@window.KeyCode::KeyE) {
      bloom_state.val.low_frequency_boost_curvature = bloom_state.val.low_frequency_boost_curvature +
        delta / 10.0F
      changed = true
    }
    bloom_state.val.low_frequency_boost_curvature = clampf(
      bloom_state.val.low_frequency_boost_curvature,
      0.0F,
      1.0F,
    )

    if @input.key_pressed(@window.KeyCode::KeyF) {
      bloom_state.val.high_pass_frequency = bloom_state.val.high_pass_frequency -
        delta / 10.0F
      changed = true
    }
    if @input.key_pressed(@window.KeyCode::KeyR) {
      bloom_state.val.high_pass_frequency = bloom_state.val.high_pass_frequency +
        delta / 10.0F
      changed = true
    }
    bloom_state.val.high_pass_frequency = clampf(
      bloom_state.val.high_pass_frequency,
      0.0F,
      1.0F,
    )

    if @input.key_pressed(@window.KeyCode::KeyG) {
      bloom_state.val.composite_mode = @render3d.BloomCompositeMode::Additive
      changed = true
    }
    if @input.key_pressed(@window.KeyCode::KeyT) {
      bloom_state.val.composite_mode = @render3d.BloomCompositeMode::EnergyConserving
      changed = true
    }

    if @input.key_pressed(@window.KeyCode::KeyH) {
      bloom_state.val.prefilter_threshold = bloom_state.val.prefilter_threshold -
        delta
      changed = true
    }
    if @input.key_pressed(@window.KeyCode::KeyY) {
      bloom_state.val.prefilter_threshold = bloom_state.val.prefilter_threshold +
        delta
      changed = true
    }
    if bloom_state.val.prefilter_threshold < 0.0F {
      bloom_state.val.prefilter_threshold = 0.0F
    }

    if @input.key_pressed(@window.KeyCode::KeyJ) {
      bloom_state.val.prefilter_threshold_softness = bloom_state.val.prefilter_threshold_softness -
        delta / 10.0F
      changed = true
    }
    if @input.key_pressed(@window.KeyCode::KeyU) {
      bloom_state.val.prefilter_threshold_softness = bloom_state.val.prefilter_threshold_softness +
        delta / 10.0F
      changed = true
    }
    bloom_state.val.prefilter_threshold_softness = clampf(
      bloom_state.val.prefilter_threshold_softness,
      0.0F,
      1.0F,
    )

    if @input.key_pressed(@window.KeyCode::KeyK) {
      bloom_state.val.scale_x = bloom_state.val.scale_x - delta * 2.0F
      changed = true
    }
    if @input.key_pressed(@window.KeyCode::KeyI) {
      bloom_state.val.scale_x = bloom_state.val.scale_x + delta * 2.0F
      changed = true
    }
    bloom_state.val.scale_x = clampf(bloom_state.val.scale_x, 0.0F, 8.0F)
  }

  if changed {
    apply_camera_bloom(world)
  }
  update_help_text()
}

///|
fn bounce_spheres(world : @ecs.World) -> Unit {
  let elapsed = @time.time_elapsed_seconds()
  let tick = world.read_change_tick()
  for sphere in bloom_state.val.spheres {
    world
    .component(@math.ecs_key_transform)
    .set(
      sphere.entity,
      @math.Transform::from_xyz(
        sphere.x,
        @math.sin(sphere.x + sphere.z + elapsed),
        sphere.z,
      ).with_scale(@math.Vec3::splat(sphere.scale)),
      tick,
    )
    |> ignore
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup_scene)
  .add_system(update_bloom_settings)
  .add_system(bounce_spheres)
  .run()
}
