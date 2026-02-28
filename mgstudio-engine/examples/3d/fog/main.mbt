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
/// Port of `bevy/examples/3d/fog.rs`.
///
/// Baseline parity: Bevy's `DistanceFog` is camera-attached and runtime-applied,
/// while mgstudio currently uses a simplified fog blend path without directional
/// inscattering parameters.

///|
const PI : Float = 3.141592653589793F

///|
priv struct FogExampleState {
  mut camera : @core.Entity?
  mut help_text : @text.TextHandle?
}

///|
let fog_example_state : Ref[FogExampleState] = Ref::new({
  camera: None,
  help_text: None,
})

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
fn setup_camera_fog(world : @ecs_world.World) -> Unit {
  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(8.0F, 8.0F, 8.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  fog_example_state.val.camera = Some(camera)
  @render3d.render3d_set_distance_fog(
    @render3d.DistanceFog::new(
      @render2d.Color::new(0.25F, 0.25F, 0.25F, 1.0F),
      @render3d.FogFalloff3d::linear(5.0F, 20.0F),
    ),
  )
}

///|
fn setup_pyramid_scene(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let ambient = world.get_global_ambient_light_resource()
  if ambient.get_ref_mut(tick) is Some(value) {
    value.val = @render3d.GlobalAmbientLight::new(
      @render2d.Color::white(),
      0.0F,
    )
  }

  let stone_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(40.0F / 255.0F, 34.0F / 255.0F, 27.0F / 255.0F, 1.0F),
    ).with_perceptual_roughness(1.0F),
  )

  let pillar_positions = [
    @math.Vec2::new(-1.5F, -1.5F),
    @math.Vec2::new(1.5F, -1.5F),
    @math.Vec2::new(1.5F, 1.5F),
    @math.Vec2::new(-1.5F, 1.5F),
  ]
  for position in pillar_positions {
    spawn_mesh(
      world,
      @render3d.Mesh3d::from_cuboid(1.0F, 3.0F, 1.0F),
      stone_material,
      @math.Transform::from_xyz(position.x, 1.5F, position.y),
    )
    |> ignore
  }

  let orb_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.07F, 0.38F, 0.07F, 0.8F),
    )
    .with_reflectance(1.0F)
    .with_perceptual_roughness(0.0F)
    .with_metallic(0.5F)
    .with_alpha_mode(@render3d.AlphaMode3d::Blend),
  )
  let orb = spawn_mesh(
    world,
    uv_sphere_mesh(1.0F, 20, 36),
    orb_material,
    @math.Transform::from_xyz(0.0F, 4.0F, 0.0F).with_scale(
      @math.Vec3::splat(1.75F),
    ),
  )
  world
  .get_not_shadow_caster_store()
  .insert(orb, @render3d.NotShadowCaster::default(), tick)
  world
  .get_not_shadow_receiver_store()
  .insert(orb, @render3d.NotShadowReceiver::default(), tick)

  for i in 0..<50 {
    let i_f = float_from_int(i)
    let half_size = i_f / 2.0F + 3.0F
    let y = -i_f / 2.0F
    spawn_mesh(
      world,
      @render3d.Mesh3d::from_cuboid(2.0F * half_size, 0.5F, 2.0F * half_size),
      stone_material,
      @math.Transform::from_xyz(0.0F, y + 0.25F, 0.0F),
    )
    |> ignore
  }

  spawn_mesh(
    world,
    @render3d.Mesh3d::from_cuboid(2.0F, 1.0F, 1.0F),
    @render3d.standard_material_add(
      @render3d.StandardMaterial::from_color(
        @render2d.Color::new(136.0F / 255.0F, 136.0F / 255.0F, 136.0F / 255.0F, 1.0F),
      )
      .with_unlit(true)
      .with_cull_mode(None),
    ),
    @math.Transform::identity().with_scale(@math.Vec3::splat(1_000_000.0F)),
  )
  |> ignore

  let point_light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    point_light,
    @render3d.PointLight::default().with_shadow_maps_enabled(true),
    tick,
  )
  world
  .get_transform_store()
  .insert(point_light, @math.Transform::from_xyz(0.0F, 1.0F, 0.0F), tick)
}

///|
fn fog_mode_label(falloff : @render3d.FogFalloff3d) -> String {
  match falloff {
    @render3d.FogFalloff3d::Atmospheric(_, _) => "Atmospheric"
    @render3d.FogFalloff3d::Linear(_, _) => "Linear"
    @render3d.FogFalloff3d::Exponential(_) => "Exponential"
    @render3d.FogFalloff3d::ExponentialSquared(_) => "ExponentialSquared"
  }
}

///|
fn fog_help_text(fog : @render3d.DistanceFog) -> String {
  let detail = match fog.falloff {
    @render3d.FogFalloff3d::Atmospheric(extinction, inscattering) =>
      "Atmospheric extinction: (\{extinction.x}, \{extinction.y}, \{extinction.z})\nAtmospheric inscattering: (\{inscattering.x}, \{inscattering.y}, \{inscattering.z})"
    @render3d.FogFalloff3d::Linear(start, end_) =>
      "Linear start/end: \{start} / \{end_}\nA/S adjust start, Z/X adjust end"
    @render3d.FogFalloff3d::Exponential(density) =>
      "Exponential density: \{density}\nA/S adjust density"
    @render3d.FogFalloff3d::ExponentialSquared(density) =>
      "ExpSquared density: \{density}\nA/S adjust density"
  }
  "Fog Falloff: \{fog_mode_label(fog.falloff)}\nFog Color: (\{fog.color.r}, \{fog.color.g}, \{fog.color.b}, \{fog.color.a})\n\n1/2/3 switch falloff mode\nMinus/Equal red -/+\nBracketLeft/BracketRight green -/+\nSemicolon/Quote blue -/+\nPeriod/Slash alpha -/+\n\n\{detail}"
}

///|
fn setup_instructions(_world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let handle = @text.Text2dBundle::new(
      @text.Text2d::new("Fog controls"),
      @text.TextFont::default().with_font(font).with_font_size(18.0F),
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
  fog_example_state.val.help_text = Some(handle)

  @text.text_set_content(
    handle,
    fog_help_text(@render3d.render3d_distance_fog()),
  )
}

///|
fn update_system(world : @ecs_world.World) -> Unit {
  let now = @time.time_elapsed_seconds()
  let delta = @time.time_delta_seconds()
  let tick = world.read_change_tick()

  guard fog_example_state.val.camera is Some(camera) else { return }
  let transform_store = world.get_transform_store()
  let mut fog = @render3d.render3d_distance_fog()

  let orbit_scale = 8.0F + @math.sin(now / 10.0F) * 7.0F
  let camera_transform = @math.Transform::from_xyz(
    @math.cos(now / 5.0F) * orbit_scale,
    12.0F - orbit_scale / 2.0F,
    @math.sin(now / 5.0F) * orbit_scale,
  ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F))
  transform_store.set(camera, camera_transform, tick) |> ignore

  if @input.key_pressed(@window.KeyCode::Digit1) {
    fog = fog.with_falloff(@render3d.FogFalloff3d::linear(5.0F, 20.0F))
  }
  if @input.key_pressed(@window.KeyCode::Digit2) {
    let density = match fog.falloff {
      @render3d.FogFalloff3d::Atmospheric(_, _) => 0.07F
      @render3d.FogFalloff3d::Exponential(d) => d
      @render3d.FogFalloff3d::ExponentialSquared(d) => d
      @render3d.FogFalloff3d::Linear(_, _) => 0.07F
    }
    fog = fog.with_falloff(@render3d.FogFalloff3d::exponential(density))
  }
  if @input.key_pressed(@window.KeyCode::Digit3) {
    let density = match fog.falloff {
      @render3d.FogFalloff3d::Atmospheric(_, _) => 0.07F
      @render3d.FogFalloff3d::Exponential(d) => d
      @render3d.FogFalloff3d::ExponentialSquared(d) => d
      @render3d.FogFalloff3d::Linear(_, _) => 0.07F
    }
    fog = fog.with_falloff(@render3d.FogFalloff3d::exponential_squared(density))
  }

  let next_falloff = match fog.falloff {
    @render3d.FogFalloff3d::Atmospheric(extinction, inscattering) =>
      @render3d.FogFalloff3d::atmospheric(extinction, inscattering)
    @render3d.FogFalloff3d::Linear(start, end_) => {
      let next_start = if @input.key_pressed(@window.KeyCode::KeyA) {
        start - delta * 3.0F
      } else if @input.key_pressed(@window.KeyCode::KeyS) {
        start + delta * 3.0F
      } else {
        start
      }
      let next_end = if @input.key_pressed(@window.KeyCode::KeyZ) {
        end_ - delta * 3.0F
      } else if @input.key_pressed(@window.KeyCode::KeyX) {
        end_ + delta * 3.0F
      } else {
        end_
      }
      @render3d.FogFalloff3d::linear(next_start, next_end)
    }
    @render3d.FogFalloff3d::Exponential(density) => {
      let next_density = if @input.key_pressed(@window.KeyCode::KeyA) {
        density - delta * 0.5F * density
      } else if @input.key_pressed(@window.KeyCode::KeyS) {
        density + delta * 0.5F * density
      } else {
        density
      }
      @render3d.FogFalloff3d::exponential(next_density)
    }
    @render3d.FogFalloff3d::ExponentialSquared(density) => {
      let next_density = if @input.key_pressed(@window.KeyCode::KeyA) {
        density - delta * 0.5F * density
      } else if @input.key_pressed(@window.KeyCode::KeyS) {
        density + delta * 0.5F * density
      } else {
        density
      }
      @render3d.FogFalloff3d::exponential_squared(next_density)
    }
  }
  fog = fog.with_falloff(next_falloff)

  let mut color = fog.color
  if @input.key_pressed(@window.KeyCode::Minus) {
    color = @render2d.Color::new(
      clamp01(color.r - 0.1F * delta),
      color.g,
      color.b,
      color.a,
    )
  }
  if @input.key_pressed(@window.KeyCode::Equal) {
    color = @render2d.Color::new(
      clamp01(color.r + 0.1F * delta),
      color.g,
      color.b,
      color.a,
    )
  }
  if @input.key_pressed(@window.KeyCode::BracketLeft) {
    color = @render2d.Color::new(
      color.r,
      clamp01(color.g - 0.1F * delta),
      color.b,
      color.a,
    )
  }
  if @input.key_pressed(@window.KeyCode::BracketRight) {
    color = @render2d.Color::new(
      color.r,
      clamp01(color.g + 0.1F * delta),
      color.b,
      color.a,
    )
  }
  if @input.key_pressed(@window.KeyCode::Semicolon) {
    color = @render2d.Color::new(
      color.r,
      color.g,
      clamp01(color.b - 0.1F * delta),
      color.a,
    )
  }
  if @input.key_pressed(@window.KeyCode::Quote) {
    color = @render2d.Color::new(
      color.r,
      color.g,
      clamp01(color.b + 0.1F * delta),
      color.a,
    )
  }
  if @input.key_pressed(@window.KeyCode::Period) {
    color = @render2d.Color::new(
      color.r,
      color.g,
      color.b,
      clamp01(color.a - 0.1F * delta),
    )
  }
  if @input.key_pressed(@window.KeyCode::Slash) {
    color = @render2d.Color::new(
      color.r,
      color.g,
      color.b,
      clamp01(color.a + 0.1F * delta),
    )
  }
  fog = fog.with_color(color)

  @render3d.render3d_set_distance_fog(fog)

  if fog_example_state.val.help_text is Some(text_handle) {
    @text.text_set_content(text_handle, fog_help_text(fog))
  }
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  fog_example_state.val.camera = None
  fog_example_state.val.help_text = None
  setup_camera_fog(world)
  setup_pyramid_scene(world)
  setup_instructions(world)
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(update_system)
  .run()
}
