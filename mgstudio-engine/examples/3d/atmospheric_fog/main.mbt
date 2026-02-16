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
/// Port of `bevy/examples/3d/atmospheric_fog.rs`.
///
/// Baseline parity: Bevy's atmospheric fog exposes directional-light
/// inscattering parameters directly on `DistanceFog`; mgstudio currently
/// approximates that behavior by dynamically tinting global distance fog.

///|
const FOG_BASE_R : Float = 0.35F

///|
const FOG_BASE_G : Float = 0.48F

///|
const FOG_BASE_B : Float = 0.66F

///|
const FOG_SUN_R : Float = 1.0F

///|
const FOG_SUN_G : Float = 0.95F

///|
const FOG_SUN_B : Float = 0.85F

///|
const FOG_SUN_ALPHA : Float = 0.5F

///|
const FOG_INSCATTER_EXPONENT : Float = 6.0F

///|
const TERRAIN_ROWS : Int = 28

///|
priv struct AtmosphericFogState {
  mut fog_enabled : Bool
  mut directional_influence_enabled : Bool
  mut camera : @core.Entity?
  mut light : @core.Entity?
  mut help_text : @text.TextHandle?
}

///|
let atmospheric_fog_state : Ref[AtmosphericFogState] = Ref::new({
  fog_enabled: true,
  directional_influence_enabled: true,
  camera: None,
  light: None,
  help_text: None,
})

///|
fn clamp01(value : Float) -> Float {
  if value <= 0.0F {
    0.0F
  } else if value >= 1.0F {
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
fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
}

///|
fn transform_forward(transform : @math.Transform) -> @math.Vec3 {
  quat_rotate_vec3(transform.rotation, @math.Vec3::new(0.0F, 0.0F, -1.0F)).normalize_or_zero()
}

///|
fn fog_center() -> @math.Vec3 {
  @math.Vec3::new(0.0F, 0.0F, 0.0F)
}

///|
fn fog_color(world : @ecs_world.World) -> @render2d.Color {
  if !atmospheric_fog_state.val.fog_enabled {
    return @render2d.Color::new(FOG_BASE_R, FOG_BASE_G, FOG_BASE_B, 0.0F)
  }

  let mut influence = 0.0F
  if atmospheric_fog_state.val.directional_influence_enabled {
    if atmospheric_fog_state.val.camera is Some(camera_entity) {
      if atmospheric_fog_state.val.light is Some(light_entity) {
        if world.get_transform_store().get(camera_entity)
          is Some(camera_transform) {
          if world.get_transform_store().get(light_entity)
            is Some(light_transform) {
            let view_dir = fog_center()
              .sub(camera_transform.translation)
              .normalize_or_zero()
            let light_dir = transform_forward(light_transform).neg()
            let phase = clamp01(light_dir.dot(view_dir) * 0.5F + 0.5F)
            influence = @math.pow(phase, FOG_INSCATTER_EXPONENT) * FOG_SUN_ALPHA
          }
        }
      }
    }
  }

  let base_weight = 1.0F - influence
  @render2d.Color::new(
    FOG_BASE_R * base_weight + FOG_SUN_R * influence,
    FOG_BASE_G * base_weight + FOG_SUN_G * influence,
    FOG_BASE_B * base_weight + FOG_SUN_B * influence,
    1.0F,
  )
}

///|
fn apply_fog(world : @ecs_world.World) -> Unit {
  let color = fog_color(world)
  @render3d.render3d_set_distance_fog(
    @render3d.DistanceFog::new(
      color,
      @render3d.FogFalloff3d::exponential_squared(0.18F),
    ),
  )
}

///|
fn instruction_text() -> String {
  let fog_status = if atmospheric_fog_state.val.fog_enabled {
    "on"
  } else {
    "off"
  }
  let light_status = if atmospheric_fog_state.val.directional_influence_enabled {
    "on"
  } else {
    "off"
  }
  "Press Spacebar to Toggle Atmospheric Fog. (\{fog_status})\nPress S to Toggle Directional Light Fog Influence. (\{light_status})"
}

///|
fn setup_camera_fog(world : @ecs_world.World) -> Unit {
  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(-1.0F, 0.1F, 1.0F).looking_at(
      fog_center(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  atmospheric_fog_state.val.camera = Some(camera)
  apply_fog(world)
}

///|
fn spawn_mesh(
  world : @ecs_world.World,
  mesh : @render3d.Mesh3d,
  material : @asset.Handle[@render3d.StandardMaterial],
  transform : @math.Transform,
) -> Unit {
  @render3d.MeshMaterial3dBundle::new(
    mesh,
    @render3d.MeshMaterial3d::new(material),
    transform,
  ).spawn(world)
  |> ignore
}

///|
fn setup_terrain_scene(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let sun = world.spawn_empty()
  world
  .get_transform_store()
  .insert(
    sun,
    @math.Transform::from_xyz(0.0F, 0.0F, 0.0F).looking_at(
      @math.Vec3::new(-0.15F, -0.05F, 0.25F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  world
  .get_directional_light_store()
  .insert(
    sun,
    @render3d.DirectionalLight::new(
      @render2d.Color::new(0.98F, 0.95F, 0.82F, 1.0F),
      30_000.0F,
      true,
    ),
    tick,
  )
  atmospheric_fog_state.val.light = Some(sun)

  let terrain_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.35F, 0.32F, 0.29F, 1.0F),
    )
    .with_perceptual_roughness(1.0F)
    .with_metallic(0.0F),
  )

  for i in 0..<TERRAIN_ROWS {
    let i_f = float_from_int(i)
    let depth = i_f * 0.38F
    let width = 0.8F + i_f * 0.55F
    let height = 0.05F + i_f * 0.012F
    let shift = @math.sin(i_f * 0.45F) * 0.25F

    spawn_mesh(
      world,
      @render3d.Mesh3d::from_cuboid(width, height, 0.3F),
      terrain_material,
      @math.Transform::from_xyz(shift, height / 2.0F - 0.08F, -depth),
    )
  }

  let sky_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.53F, 0.53F, 0.53F, 1.0F),
    ).with_unlit(true),
  )
  spawn_mesh(
    world,
    @render3d.Mesh3d::from_cuboid(2.0F, 1.0F, 1.0F),
    sky_material,
    @math.Transform::identity().with_scale(@math.Vec3::splat(20.0F)),
  )
}

///|
fn setup_instructions(_world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let handle = @text.Text2dBundle::new(
      @text.Text2d::new(instruction_text()),
      @text.TextFont::default().with_font(font).with_font_size(18.0F),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, -340.0F),
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
  atmospheric_fog_state.val.help_text = Some(handle)
}

///|
fn toggle_system(world : @ecs_world.World) -> Unit {
  let mut changed = false

  if @input.key_just_pressed(@window.KeyCode::Space) {
    atmospheric_fog_state.val.fog_enabled = !atmospheric_fog_state.val.fog_enabled
    changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyS) {
    atmospheric_fog_state.val.directional_influence_enabled = !atmospheric_fog_state.val.directional_influence_enabled
    changed = true
  }

  if changed {
    apply_fog(world)
    if atmospheric_fog_state.val.help_text is Some(handle) {
      @text.text_set_content(handle, instruction_text())
    }
  }
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  atmospheric_fog_state.val.fog_enabled = true
  atmospheric_fog_state.val.directional_influence_enabled = true
  atmospheric_fog_state.val.camera = None
  atmospheric_fog_state.val.light = None
  atmospheric_fog_state.val.help_text = None

  setup_camera_fog(world)
  setup_terrain_scene(world)
  setup_instructions(world)
  apply_fog(world)
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(toggle_system)
  .run()
}
