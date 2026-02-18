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
/// Port of `bevy/examples/3d/clustered_decal_maps.rs`.
///
/// Baseline parity:
/// - Bevy `ClusteredDecal` map channels (normal/metallic-roughness/emissive)
///   and clustered-decal pipeline are not yet exposed in mgstudio.
/// - This port keeps the same runtime behavior model (continuous spawn,
///   animated in/out lifetime, emissive toggle) using textured translucent
///   proxy meshes.

///|
const PLANE_HALF_SIZE : Float = 2.0F

///|
const PI : Float = 3.141592653589793F

///|
const DECAL_MIN_SIZE : Float = 0.5F

///|
const DECAL_MAX_SIZE : Float = 1.5F

///|
const DECAL_ANIMATE_IN_DURATION : Float = 0.30F

///|
const DECAL_IDLE_DURATION : Float = 10.0F

///|
const DECAL_ANIMATE_OUT_DURATION : Float = 0.30F

///|
const DECAL_SPAWN_INTERVAL : Float = 0.35F

///|
priv struct ActiveDecal {
  entity : @core.Entity
  base_scale : Float
  age : Float
}

///|
priv struct ClusteredDecalMapsState {
  mut spawn_accumulator : Float
  mut spawn_index : Int
  mut emissive_decals : Bool
  mut decals : Array[ActiveDecal]
  mut help_text : @text.TextHandle?
}

///|
let clustered_decal_maps_state : Ref[ClusteredDecalMapsState] = Ref::new({
  spawn_accumulator: 0.0F,
  spawn_index: 0,
  emissive_decals: true,
  decals: [],
  help_text: None,
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
fn help_text_content() -> String {
  "Clustered Decal Maps (Bevy-aligned behavior)\n" +
  "E: Toggle emissive decals (" +
  (if clustered_decal_maps_state.val.emissive_decals { "On" } else { "Off" }) +
  ")\n" +
  "Active decals: " +
  clustered_decal_maps_state.val.decals.length().to_string() +
  "\n"
}

///|
fn update_help_text() -> Unit {
  if clustered_decal_maps_state.val.help_text is Some(help_text) {
    @text.text_set_content(help_text, help_text_content())
  }
}

///|
fn spawn_plane(
  world : @ecs_world.World,
  base_color : @asset.Handle[@asset.Image],
  normal_map : @asset.Handle[@asset.Image],
) -> Unit {
  let material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.86F, 0.16F, 0.24F, 1.0F),
    )
    .with_base_color_texture(Some(base_color))
    .with_normal_map_texture(Some(normal_map))
    .with_metallic_roughness_texture(Some(base_color))
    .with_perceptual_roughness(0.35F),
  )
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(PLANE_HALF_SIZE * 2.0F, PLANE_HALF_SIZE * 2.0F),
    @render3d.MeshMaterial3d::new(material),
    @math.Transform::from_xyz(0.0F, 0.0F, 0.0F).with_rotation(
      @math.Quat::from_rotation_x(PI),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn spawn_light(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let point = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    point,
    @render3d.PointLight::new(
      @render2d.Color::white(),
      10_000_000.0F,
      100.0F,
      false,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(point, @math.Transform::from_xyz(8.0F, 16.0F, -8.0F), tick)
}

///|
fn spawn_camera(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(2.0F, 0.0F, -7.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world.get_hdr_store().insert(camera, @render3d.Hdr::default(), tick)
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  clustered_decal_maps_state.val.spawn_accumulator = 0.0F
  clustered_decal_maps_state.val.spawn_index = 0
  clustered_decal_maps_state.val.emissive_decals = true
  clustered_decal_maps_state.val.decals = []
  clustered_decal_maps_state.val.help_text = None

  let decal_base_color = asset_server.load("branding/bevy_bird_dark.png")
  let decal_normal_map = asset_server.load("textures/ScratchedGold-Normal.png")
  spawn_plane(world, decal_base_color, decal_normal_map)
  spawn_light(world)
  spawn_camera(world)

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
  clustered_decal_maps_state.val.help_text = Some(help_text)
  update_help_text()
}

///|
fn spawn_decal(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let index = clustered_decal_maps_state.val.spawn_index
  clustered_decal_maps_state.val.spawn_index = index + 1
  let phase = float_from_int(index)
  let x = @math.sin(phase * 1.91F + 0.37F) * (PLANE_HALF_SIZE - 0.2F)
  let y = @math.cos(phase * 2.73F + 1.13F) * (PLANE_HALF_SIZE - 0.2F)
  let size_factor = clamp01(@math.sin(phase * 3.17F + 0.77F) * 0.5F + 0.5F)
  let size = DECAL_MIN_SIZE + (DECAL_MAX_SIZE - DECAL_MIN_SIZE) * size_factor
  let color_tint = clamp01(@math.sin(phase * 4.03F + 0.24F) * 0.5F + 0.5F)
  let base_color = @render2d.Color::new(
    0.9F,
    0.8F + color_tint * 0.2F,
    0.8F + color_tint * 0.2F,
    0.95F,
  )

  let decal_base_color = asset_server.load("branding/bevy_bird_dark.png")
  let decal_normal_map = asset_server.load("textures/ScratchedGold-Normal.png")
  let decal_emissive_map = asset_server.load("branding/icon.png")
  let mut material = @render3d.StandardMaterial::from_color(base_color)
    .with_base_color_texture(Some(decal_base_color))
    .with_normal_map_texture(Some(decal_normal_map))
    .with_metallic_roughness_texture(Some(decal_base_color))
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_perceptual_roughness(0.25F)
  if clustered_decal_maps_state.val.emissive_decals {
    material = material
      .with_emissive_texture(Some(decal_emissive_map))
      .with_emissive(@render2d.Color::new(1.0F, 1.0F, 1.0F, 1.0F))
  }
  let entity = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 0.02F),
    @render3d.MeshMaterial3d::new(@render3d.standard_material_add(material)),
    @math.Transform::from_xyz(x, y, -0.01F).with_scale(
      @math.Vec3::new(0.001F, 0.001F, 0.02F),
    ),
  ).spawn(world)
  clustered_decal_maps_state.val.decals.push({
    entity,
    base_scale: size,
    age: 0.0F,
  })
}

///|
fn animate_decals(world : @ecs_world.World) -> Unit {
  let delta = @time.time_delta_seconds()
  if delta <= 0.0F {
    return
  }
  let tick = world.read_change_tick()
  let alive : Array[ActiveDecal] = []
  for decal in clustered_decal_maps_state.val.decals {
    let age = decal.age + delta
    let total_life = DECAL_ANIMATE_IN_DURATION +
      DECAL_IDLE_DURATION +
      DECAL_ANIMATE_OUT_DURATION
    if age >= total_life {
      world.despawn(decal.entity) catch {
        _ => ()
      }
      continue
    }
    if world.get_transform_store().get(decal.entity) is Some(transform) {
      let scale_factor = if age < DECAL_ANIMATE_IN_DURATION {
        clamp01(age / DECAL_ANIMATE_IN_DURATION)
      } else if age < DECAL_ANIMATE_IN_DURATION + DECAL_IDLE_DURATION {
        1.0F
      } else {
        let t = (age - DECAL_ANIMATE_IN_DURATION - DECAL_IDLE_DURATION) /
          DECAL_ANIMATE_OUT_DURATION
        1.0F - clamp01(t)
      }
      world
      .get_transform_store()
      .set(
        decal.entity,
        transform.with_scale(
          @math.Vec3::new(
            decal.base_scale * scale_factor,
            decal.base_scale * scale_factor,
            0.02F,
          ),
        ),
        tick,
      )
      |> ignore
    }
    alive.push({ ..decal, age, })
  }
  clustered_decal_maps_state.val.decals = alive
}

///|
fn controls(world : @ecs_world.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::KeyE) {
    clustered_decal_maps_state.val.emissive_decals = !clustered_decal_maps_state.val.emissive_decals
    update_help_text()
  }
  world |> ignore
}

///|
fn spawn_loop(world : @ecs_world.World) -> Unit {
  let delta = @time.time_delta_seconds()
  if delta <= 0.0F {
    return
  }
  clustered_decal_maps_state.val.spawn_accumulator = clustered_decal_maps_state.val.spawn_accumulator +
    delta
  while clustered_decal_maps_state.val.spawn_accumulator >= DECAL_SPAWN_INTERVAL {
    clustered_decal_maps_state.val.spawn_accumulator = clustered_decal_maps_state.val.spawn_accumulator -
      DECAL_SPAWN_INTERVAL
    spawn_decal(world)
  }
  update_help_text()
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(controls)
  .add_system(spawn_loop)
  .add_system(animate_decals)
  .run()
}
