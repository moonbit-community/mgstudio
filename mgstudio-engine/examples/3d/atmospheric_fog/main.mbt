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
/// Parity notes:
/// - Uses `DistanceFog.directional_light_color` and
///   `DistanceFog.directional_light_exponent` directly.
/// - Uses `FogFalloff3d::from_visibility_colors` for atmospheric falloff setup.

///|
const FOG_BASE_R : Float = 0.35F

///|
const FOG_BASE_G : Float = 0.48F

///|
const FOG_BASE_B : Float = 0.66F

///|
const FOG_VISIBILITY : Float = 15.0F

///|
const FOG_SUN_R : Float = 1.0F

///|
const FOG_SUN_G : Float = 0.95F

///|
const FOG_SUN_B : Float = 0.85F

///|
const FOG_SUN_ALPHA : Float = 0.5F

///|
const FOG_INSCATTER_EXPONENT : Float = 30.0F

///|
const FOG_EXTINCTION_R : Float = 0.35F

///|
const FOG_EXTINCTION_G : Float = 0.50F

///|
const FOG_EXTINCTION_B : Float = 0.66F

///|
const FOG_INSCATTER_R : Float = 0.80F

///|
const FOG_INSCATTER_G : Float = 0.844F

///|
const FOG_INSCATTER_B : Float = 1.0F

///|
priv struct AtmosphericFogState {
  mut camera : @core.Entity?
  mut fog_enabled : Bool
  mut directional_influence_enabled : Bool
  mut help_text : @text.TextHandle?
}

///|
let atmospheric_fog_state : Ref[AtmosphericFogState] = Ref::new({
  camera: None,
  fog_enabled: true,
  directional_influence_enabled: true,
  help_text: None,
})

///|
fn fog_center() -> @math.Vec3 {
  @math.Vec3::new(0.0F, 0.0F, 0.0F)
}

///|
fn make_fog() -> @pbr.DistanceFog {
  let fog_alpha = if atmospheric_fog_state.val.fog_enabled {
    1.0F
  } else {
    0.0F
  }
  let directional_alpha = if atmospheric_fog_state.val.directional_influence_enabled {
    FOG_SUN_ALPHA
  } else {
    0.0F
  }
  @pbr.DistanceFog::default()
  .with_color(
    @sprite.Color::srgba(FOG_BASE_R, FOG_BASE_G, FOG_BASE_B, fog_alpha),
  )
  .with_directional_light_color(
    @sprite.Color::srgba(FOG_SUN_R, FOG_SUN_G, FOG_SUN_B, directional_alpha),
  )
  .with_directional_light_exponent(FOG_INSCATTER_EXPONENT)
  .with_falloff(
    @pbr.FogFalloff3d::from_visibility_colors(
      FOG_VISIBILITY,
      @sprite.Color::srgb(FOG_EXTINCTION_R, FOG_EXTINCTION_G, FOG_EXTINCTION_B),
      @sprite.Color::srgb(FOG_INSCATTER_R, FOG_INSCATTER_G, FOG_INSCATTER_B),
    ),
  )
}

///|
fn apply_fog(world : @ecs.World) -> Unit {
  guard atmospheric_fog_state.val.camera is Some(camera) else { return }
  let camera3d = match (try! world.get_by_key(camera, @pbr.ecs_key_camera3d)) {
    Some(value) => value
    None => @pbr.Camera3d::default()
  }
  try! (world.replace(
    camera,
    @pbr.ecs_key_camera3d,
    camera3d.with_distance_fog(Some(make_fog())),
  )
  |> ignore)
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
fn setup_camera_fog(world : @ecs.World) -> Unit {
  let camera = @pbr.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(-1.0F, 0.1F, 1.0F).looking_at(
        fog_center(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_distance_fog(Some(make_fog()))
    .spawn(world)
  atmospheric_fog_state.val.camera = Some(camera)
  apply_fog(world)
}

///|
fn setup_terrain_scene(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let cascade_shadow_config = @pbr.CascadeShadowConfigBuilder::default()
    .with_first_cascade_far_bound(0.3F)
    .with_maximum_distance(3.0F)
    .build()
  let sun = world.spawn_empty()
  try! world.set_by_key(
    sun,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F).looking_at(
      @math.Vec3::new(-0.15F, -0.05F, 0.25F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  try! world.set_by_key(
    sun,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::new(
      @sprite.Color::srgb(0.98F, 0.95F, 0.82F),
      100_000.0F,
      true,
    ).with_cascade_shadow_config(Some(cascade_shadow_config)),
  )
  let terrain = world.spawn_empty()
  try! world.set_by_key(
    terrain,
    @scene.ecs_key_scene_root,
    @scene.SceneRoot::new(
      asset_server.load(
        @gltf.GltfAssetLabel::Scene(0).from_asset(
          "models/terrain/Mountains.gltf",
        ),
      ),
    ),
  )

  let sky_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.53333336F, 0.53333336F, 0.53333336F, 1.0F),
    )
    .with_unlit(true)
    .with_cull_mode(None),
  )
  let sky = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(2.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(sky_material),
    @transform.Transform::identity().with_scale(@math.Vec3::splat(20.0F)),
  ).spawn(world)
  try! world.set_by_key(
    sky,
    @pbr.ecs_key_not_shadow_caster,
    @pbr.NotShadowCaster::default(),
  )
}

///|
fn setup_instructions(_world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let handle = @text.Text2dBundle::new(
      @text.Text2d::new(instruction_text()),
      @text.TextFont::default().with_font(font).with_font_size(18.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, -340.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::bottom_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  atmospheric_fog_state.val.help_text = Some(handle)
}

///|
fn toggle_system(world : @ecs.World) -> Unit {
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
fn setup(world : @ecs.World) -> Unit {
  atmospheric_fog_state.val.camera = None
  atmospheric_fog_state.val.fog_enabled = true
  atmospheric_fog_state.val.directional_influence_enabled = true
  atmospheric_fog_state.val.help_text = None

  setup_camera_fog(world)
  setup_terrain_scene(world)
  setup_instructions(world)
  apply_fog(world)
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(toggle_system))
  .run()
}
