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
///
/// Baseline parity:
/// - This example now attaches `ClusteredDecal` components directly with Bevy-
///   aligned map channels.
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
const DECAL_SPAWN_INTERVAL : Float = 1.0F

///|
const LCG_MOD : Int = 2147483647

///|
const LCG_MULTIPLIER : Int = 1103515245

///|
const LCG_INCREMENT : Int = 12345

///|
priv struct ActiveDecal {
  entity : @core.Entity
  base_scale : Float
  age : Float
}

///|
priv struct AppTextures {
  decal_base_color_texture : @asset.Handle[@asset.Image]
  decal_normal_map_texture : @asset.Handle[@asset.Image]
  decal_metallic_roughness_texture : @asset.Handle[@asset.Image]
  decal_emissive_texture : @asset.Handle[@asset.Image]
}

///|
priv struct ClusteredDecalMapsState {
  mut spawn_accumulator : Float
  mut random_seed : Int
  mut emissive_decals : Bool
  mut decals : Array[ActiveDecal]
  mut textures : AppTextures?
  mut help_text : @text.TextHandle?
}

///|
let clustered_decal_maps_state : Ref[ClusteredDecalMapsState] = Ref::new({
  spawn_accumulator: 0.0F,
  random_seed: 1_987_836_747,
  emissive_decals: true,
  decals: [],
  textures: None,
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
fn lcg_next(seed : Int) -> Int {
  let mut next = (seed * LCG_MULTIPLIER + LCG_INCREMENT) % LCG_MOD
  if next < 0 {
    next = next + LCG_MOD
  }
  next
}

///|
fn random_unit() -> Float {
  clustered_decal_maps_state.val.random_seed = lcg_next(
    clustered_decal_maps_state.val.random_seed,
  )
  float_from_int(clustered_decal_maps_state.val.random_seed) /
  float_from_int(LCG_MOD)
}

///|
fn random_range(min_value : Float, max_value : Float) -> Float {
  min_value + random_unit() * (max_value - min_value)
}

///|
fn help_text_content() -> String {
  let emissive_text = if clustered_decal_maps_state.val.emissive_decals {
    "On"
  } else {
    "Off"
  }
  "Clustered Decal Maps (Bevy-aligned behavior)\nE: Emissive On, R: Emissive Off (\{emissive_text})\nActive decals: \{clustered_decal_maps_state.val.decals.length().to_string()}\n"
}

///|
fn update_help_text() -> Unit {
  if clustered_decal_maps_state.val.help_text is Some(help_text) {
    @text.text_set_content(help_text, help_text_content())
  }
}

///|
fn spawn_plane(
  world : @ecs.World,
  base_color : @asset.Handle[@asset.Image],
  normal_map : @asset.Handle[@asset.Image],
) -> Unit {
  let material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.86F, 0.16F, 0.24F, 1.0F),
    )
    .with_base_color_texture(Some(base_color))
    .with_normal_map_texture(Some(normal_map))
    .with_metallic_roughness_texture(Some(base_color))
    .with_perceptual_roughness(0.35F),
  )
  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_plane(
            PLANE_HALF_SIZE * 2.0F,
            PLANE_HALF_SIZE * 2.0F,
          ),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(material),
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F).with_rotation(
      @math.Quat::from_rotation_x(PI),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn spawn_light(world : @ecs.World) -> Unit {
  let point = world.spawn_empty()
  try! world.set_by_key(
    point,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::new(@sprite.Color::white(), 10_000_000.0F, 100.0F, false),
  )
  try! world.set_by_key(
    point,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(8.0F, 16.0F, -8.0F),
  )
}

///|
fn spawn_camera(world : @ecs.World) -> Unit {
  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(2.0F, 0.0F, -7.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  try! world.set_by_key(camera, @pbr.ecs_key_hdr, @pbr.Hdr::default())
}

///|
fn setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  clustered_decal_maps_state.val.spawn_accumulator = 0.0F
  clustered_decal_maps_state.val.random_seed = 1_987_836_747
  clustered_decal_maps_state.val.emissive_decals = true
  clustered_decal_maps_state.val.decals = []
  clustered_decal_maps_state.val.textures = None
  clustered_decal_maps_state.val.help_text = None

  let textures : AppTextures = {
    decal_base_color_texture: asset_server.load("branding/bevy_bird_dark.png"),
    decal_normal_map_texture: asset_server.load_with_settings(
      "textures/ScratchedGold-Normal.png",
      fn(settings) { settings.is_srgb = false },
    ),
    decal_metallic_roughness_texture: asset_server.load_with_settings(
      "branding/icon.png",
      fn(settings) { settings.is_srgb = false },
    ),
    decal_emissive_texture: asset_server.load("branding/icon.png"),
  }
  clustered_decal_maps_state.val.textures = Some(textures)

  spawn_plane(
    world,
    textures.decal_base_color_texture,
    textures.decal_normal_map_texture,
  )
  spawn_light(world)
  spawn_camera(world)

  let help_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(16.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, 320.0F),
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
  clustered_decal_maps_state.val.help_text = Some(help_text)
  update_help_text()
}

///|
fn spawn_decal(world : @ecs.World) -> Unit {
  guard clustered_decal_maps_state.val.textures is Some(textures) else {
    return
  }

  let x = random_range(-PLANE_HALF_SIZE, PLANE_HALF_SIZE)
  let y = random_range(-PLANE_HALF_SIZE, PLANE_HALF_SIZE)
  let size = random_range(DECAL_MIN_SIZE, DECAL_MAX_SIZE)
  let theta = random_range(0.0F, PI)

  let mut material = @pbr.StandardMaterial::from_color(@sprite.Color::white())
    .with_base_color_texture(Some(textures.decal_base_color_texture))
    .with_normal_map_texture(Some(textures.decal_normal_map_texture))
    .with_metallic_roughness_texture(
      Some(textures.decal_metallic_roughness_texture),
    )
    .with_alpha_mode(@pbr.AlphaMode3d::Blend)
    .with_perceptual_roughness(0.25F)
  if clustered_decal_maps_state.val.emissive_decals {
    material = material
      .with_emissive_texture(Some(textures.decal_emissive_texture))
      .with_emissive(@sprite.Color::new(1.0F, 1.0F, 1.0F, 1.0F))
  }
  let mut clustered_decal = @pbr.ClusteredDecal::default()
    .with_base_color_texture(Some(textures.decal_base_color_texture))
    .with_normal_map_texture(Some(textures.decal_normal_map_texture))
    .with_metallic_roughness_texture(
      Some(textures.decal_metallic_roughness_texture),
    )
  if clustered_decal_maps_state.val.emissive_decals {
    clustered_decal = clustered_decal.with_emissive_texture(
      Some(textures.decal_emissive_texture),
    )
  }
  let entity = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 0.02F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(@pbr.standard_material_add(material)),
    @transform.Transform::from_xyz(x, y, -0.01F)
    .with_rotation(@math.Quat::from_rotation_z(theta))
    .with_scale(@math.Vec3::new(0.001F, 0.001F, 0.02F)),
  ).spawn(world)
  try! world.set_by_key(entity, @pbr.ecs_key_clustered_decal, clustered_decal)
  clustered_decal_maps_state.val.decals.push({
    entity,
    base_scale: size,
    age: 0.0F,
  })
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in clustered_decal_maps example")
  }
}

///|
fn animate_decals(world : @ecs.World) -> Unit {
  let delta = world_time(world).delta_seconds()
  if delta <= 0.0F {
    return
  }
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
    if (try! world.get_by_key(decal.entity, @transform.ecs_key_transform))
      is Some(transform) {
      let scale_factor = if age < DECAL_ANIMATE_IN_DURATION {
        clamp01(age / DECAL_ANIMATE_IN_DURATION)
      } else if age < DECAL_ANIMATE_IN_DURATION + DECAL_IDLE_DURATION {
        1.0F
      } else {
        let t = (age - DECAL_ANIMATE_IN_DURATION - DECAL_IDLE_DURATION) /
          DECAL_ANIMATE_OUT_DURATION
        1.0F - clamp01(t)
      }
      try! (world.replace(
        decal.entity,
        @transform.ecs_key_transform,
        transform.with_scale(
          @math.Vec3::new(
            decal.base_scale * scale_factor,
            decal.base_scale * scale_factor,
            0.02F,
          ),
        ),
      )
      |> ignore)
    }
    alive.push({ ..decal, age, })
  }
  clustered_decal_maps_state.val.decals = alive
}

///|
fn controls(world : @ecs.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::KeyE) {
    if !clustered_decal_maps_state.val.emissive_decals {
      clustered_decal_maps_state.val.emissive_decals = true
      update_help_text()
    }
  }
  if @input.key_just_pressed(@window.KeyCode::KeyR) {
    if clustered_decal_maps_state.val.emissive_decals {
      clustered_decal_maps_state.val.emissive_decals = false
      update_help_text()
    }
  }
  world |> ignore
}

///|
fn spawn_loop(world : @ecs.World) -> Unit {
  let delta = world_time(world).delta_seconds()
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
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(controls))
  .add_systems(@app.Update, @app.system(spawn_loop))
  .add_systems(@app.Update, @app.system(animate_decals))
  .run()
}
