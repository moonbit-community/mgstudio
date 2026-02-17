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
/// Port of `bevy/examples/3d/pccm.rs`.
///
/// Baseline parity: Bevy `LightProbe` + `EnvironmentMapLight` +
/// `ParallaxCorrection` are not exposed in current mgstudio APIs. This port
/// keeps Bevy's camera and outer/inner-cube scene topology, and maps the PCCM
/// On/Off toggle to a reflective-material proxy state on the inner cube.

///|
priv struct PccmState {
  mut enabled : Bool
  mut inner_cube_material : @asset.Handle[@render3d.StandardMaterial]?
  mut help_text : @text.TextHandle?
}

///|
let pccm_state : Ref[PccmState] = Ref::new({
  enabled: true,
  inner_cube_material: None,
  help_text: None,
})

///|
fn set_global_ambient_light(
  world : @ecs_world.World,
  color : @render2d.Color,
  brightness : Float,
) -> Unit {
  let tick = world.read_change_tick()
  let ambient = @render3d.GlobalAmbientLight::new(color, brightness)
  if world.get_global_ambient_light_resource().get_ref_mut(tick)
    is Some(current) {
    current.val = ambient
  } else {
    world.get_global_ambient_light_resource().insert(ambient, tick)
  }
}

///|
fn apply_pccm_proxy(world : @ecs_world.World) -> Unit {
  guard pccm_state.val.inner_cube_material is Some(material_handle) else {
    return
  }

  guard @render3d.standard_material_get(material_handle) is Some(current) else {
    return
  }

  if pccm_state.val.enabled {
    @render3d.standard_material_set(
      material_handle,
      current
      .with_base_color(@render2d.Color::white())
      .with_metallic(1.0F)
      .with_reflectance(1.0F)
      .with_perceptual_roughness(0.0F),
    )
    |> ignore
    set_global_ambient_light(world, @render2d.Color::white(), 1.0F)
  } else {
    @render3d.standard_material_set(
      material_handle,
      current
      .with_base_color(@render2d.Color::new(0.75F, 0.75F, 0.75F, 1.0F))
      .with_metallic(0.2F)
      .with_reflectance(0.25F)
      .with_perceptual_roughness(0.65F),
    )
    |> ignore
    set_global_ambient_light(world, @render2d.Color::white(), 0.45F)
  }
}

///|
fn update_help_text() -> Unit {
  guard pccm_state.val.help_text is Some(handle) else { return }
  let status = if pccm_state.val.enabled { "On" } else { "Off" }
  @text.text_set_content(
    handle,
    "Parallax Correction (Adapted): \{status}\n" +
    "1: On, 2: Off\n\n" +
    "Adapted runtime note: LightProbe/EnvironmentMap + ParallaxCorrection are represented by material reflection proxies.",
  )
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  pccm_state.val.enabled = true
  pccm_state.val.inner_cube_material = None
  pccm_state.val.help_text = None

  let tick = world.read_change_tick()
  let asset_server = @asset.AssetServer::new()

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.0F, 0.0F, 4.0F).looking_at(
      @math.Vec3::new(0.0F, -2.5F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore

  let room_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.2F, 0.24F, 0.3F, 1.0F),
    )
    .with_perceptual_roughness(0.95F)
    .with_metallic(0.0F),
  )
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(10.0F, 10.0F, 10.0F),
    @render3d.MeshMaterial3d::new(room_material),
    @math.Transform::from_xyz(0.0F, -2.5F, -2.5F),
  ).spawn(world)
  |> ignore

  let inner_cube_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::white())
    .with_metallic(1.0F)
    .with_reflectance(1.0F)
    .with_perceptual_roughness(0.0F),
  )
  pccm_state.val.inner_cube_material = Some(inner_cube_material)
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(10.0F, 2.0F, 4.0F),
    @render3d.MeshMaterial3d::new(inner_cube_material),
    @math.Transform::from_xyz(0.0F, -4.0F, -2.5F),
  ).spawn(world)
  |> ignore

  let point_light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    point_light,
    @render3d.PointLight::new(
      @render2d.Color::white(),
      180_000.0F,
      20.0F,
      false,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(point_light, @math.Transform::from_xyz(0.0F, 0.0F, 1.5F), tick)

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
  pccm_state.val.help_text = Some(help_text)

  apply_pccm_proxy(world)
  update_help_text()
}

///|
fn toggle_pccm(world : @ecs_world.World) -> Unit {
  let mut changed = false
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    pccm_state.val.enabled = true
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    pccm_state.val.enabled = false
    changed = true
  }
  if changed {
    apply_pccm_proxy(world)
    update_help_text()
  }
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(toggle_pccm)
  .run()
}
