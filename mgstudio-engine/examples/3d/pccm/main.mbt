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
const ENVIRONMENT_MAP_INTENSITY : Float = 100.0F

///|
const ENV_DIFFUSE_MAP_ASSET : String = "environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"

///|
const ENV_SPECULAR_MAP_ASSET : String = "environment_maps/cubes_reflection_probe_specular_rgb9e5_zstd.ktx2"

///|
priv enum PccmEnableStatus {
  Enabled
  Disabled
} derive(Eq)

///|
priv struct PccmState {
  mut pccm_enabled : PccmEnableStatus
  mut light_probe : @core.Entity?
  mut help_text : @text.TextHandle?
}

///|
let pccm_state : Ref[PccmState] = Ref::new({
  pccm_enabled: PccmEnableStatus::Enabled,
  light_probe: None,
  help_text: None,
})

///|
fn status_text(status : PccmEnableStatus) -> String {
  match status {
    PccmEnableStatus::Enabled => "On"
    PccmEnableStatus::Disabled => "Off"
  }
}

///|
fn update_help_text() -> Unit {
  guard pccm_state.val.help_text is Some(handle) else { return }
  @text.text_set_content(
    handle,
    "Parallax Correction: \{status_text(pccm_state.val.pccm_enabled)}\n1: On, 2: Off",
  )
}

///|
fn apply_pccm_status(world : @ecs.World) -> Unit {
  guard pccm_state.val.light_probe is Some(light_probe_entity) else { return }

  let correction = match pccm_state.val.pccm_enabled {
    PccmEnableStatus::Enabled => @pbr.ParallaxCorrection::Auto
    PccmEnableStatus::Disabled => @pbr.ParallaxCorrection::None
  }
  if (try! world.contains_by_key(
      light_probe_entity, @pbr.ecs_key_parallax_correction,
    )) {
    try! (world.replace(
      light_probe_entity, @pbr.ecs_key_parallax_correction, correction,
    )
    |> ignore)
  } else {
    try! world.set_by_key(
      light_probe_entity, @pbr.ecs_key_parallax_correction, correction,
    )
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  pccm_state.val.pccm_enabled = PccmEnableStatus::Enabled
  pccm_state.val.light_probe = None
  pccm_state.val.help_text = None

  let asset_server = @asset.AssetServer::new()

  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(0.0F, 0.0F, 4.0F).looking_at(
      @math.Vec3::new(0.0F, -2.5F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
  let room_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.2F, 0.24F, 0.3F, 1.0F),
    )
    .with_perceptual_roughness(0.95F)
    .with_metallic(0.0F),
  )
  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(10.0F, 10.0F, 10.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(room_material),
    @transform.Transform::from_xyz(0.0F, -2.5F, -2.5F),
  ).spawn(world)
  |> ignore

  let inner_cube_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white())
    .with_metallic(1.0F)
    .with_reflectance(1.0F)
    .with_perceptual_roughness(0.0F),
  )
  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(10.0F, 2.0F, 4.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(inner_cube_material),
    @transform.Transform::from_xyz(0.0F, -4.0F, -2.5F),
  ).spawn(world)
  |> ignore

  let light_probe = world.spawn_empty()
  try! world.set_by_key(
    light_probe,
    @pbr.ecs_key_light_probe,
    @pbr.LightProbe::default(),
  )
  try! world.set_by_key(
    light_probe,
    @pbr.ecs_key_environment_map_light,
    @pbr.EnvironmentMapLight::new(
      Some(asset_server.load(ENV_DIFFUSE_MAP_ASSET)),
      Some(asset_server.load(ENV_SPECULAR_MAP_ASSET)),
      ENVIRONMENT_MAP_INTENSITY,
    ),
  )
  try! world.set_by_key(
    light_probe,
    @transform.ecs_key_transform,
    @transform.Transform::identity().with_scale(@math.Vec3::splat(10.01F)),
  )
  pccm_state.val.light_probe = Some(light_probe)

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
  pccm_state.val.help_text = Some(help_text)

  apply_pccm_status(world)
  update_help_text()
}

///|
fn handle_keyboard_input(world : @ecs.World) -> Unit {
  let mut changed = false
  if @input.key_just_pressed(@window.KeyCode::Digit1) &&
    pccm_state.val.pccm_enabled != PccmEnableStatus::Enabled {
    pccm_state.val.pccm_enabled = PccmEnableStatus::Enabled
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) &&
    pccm_state.val.pccm_enabled != PccmEnableStatus::Disabled {
    pccm_state.val.pccm_enabled = PccmEnableStatus::Disabled
    changed = true
  }
  if changed {
    apply_pccm_status(world)
    update_help_text()
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(handle_keyboard_input))
  .run()
}
