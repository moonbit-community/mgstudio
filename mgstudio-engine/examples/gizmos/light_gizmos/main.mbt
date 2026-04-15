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
const FRAC_PI_2 : Float = 1.5707963267948966F

///|
const PI : Float = 3.141592653589793F

///|
priv struct LightGizmosState {
  mut camera : @core.Entity?
  mut color_text : @text.TextHandle?
}

///|
let light_gizmos_state : Ref[LightGizmosState] = Ref::new({
  camera: None,
  color_text: None,
})

///|
fn gizmo_color_text(color : @light.LightGizmoColor) -> String {
  let label = match color {
    Manual(_) => "Manual"
    Varied => "Random from entity"
    MatchLightColor => "Match light color"
    ByLightType => "By light type"
  }
  "Gizmo color mode: \{label}"
}

///|
fn clamp_float(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn update_color_text(config_group : @light.LightGizmoConfigGroup) -> Unit {
  guard light_gizmos_state.val.color_text is Some(handle) else { return }
  @text.text_set_content(handle, gizmo_color_text(config_group.color))
}

///|
fn setup_scene(world : @ecs.World) -> Unit {
  light_gizmos_state.val.camera = None
  light_gizmos_state.val.color_text = None

  let base_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white()),
  )
  let cube_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::srgb(124.0F / 255.0F, 144.0F / 255.0F, 1.0F),
    ),
  )

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_circle(4.0F)),
      ),
    ),
    @pbr.MeshMaterial3d::new(base_material),
    @transform.Transform::from_rotation(@math.Quat::from_rotation_x(-FRAC_PI_2)),
  ).spawn(world)
  |> ignore

  let cube_mesh = @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F)),
    ),
  )
  for x in [-2.0F, 0.0F, 2.0F] {
    @pbr.MeshMaterial3dBundle::new(
      cube_mesh,
      @pbr.MeshMaterial3d::new(cube_material),
      @transform.Transform::from_xyz(x, 0.5F, 0.0F),
    ).spawn(world)
    |> ignore
  }

  let point_light = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(point_light)
    .insert(
      (
        @pbr.PointLight::default()
        .with_shadow_maps_enabled(true)
        .with_range(2.0F)
        .with_color(@sprite.Color::srgb(0.0F, 0.55F, 0.55F)),
        @transform.Transform::from_xyz(0.0F, 1.5F, 0.0F),
      ),
    ),
  )

  let spot_light = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(spot_light)
    .insert(
      (
        @pbr.SpotLight::new(
          @sprite.Color::srgb(0.5F, 0.0F, 0.5F),
          @pbr.SpotLight::default().intensity,
          3.5F,
          PI / 4.0F * 0.8F,
          PI / 4.0F,
          true,
        ),
        @transform.Transform::from_xyz(4.0F, 2.0F, 0.0F).looking_at(
          @math.Vec3::new(1.5F, 0.5F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  let directional_light = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(directional_light)
    .insert(
      (
        @pbr.DirectionalLight::new(
          @sprite.Color::srgb(1.0F, 0.84F, 0.0F),
          @pbr.DirectionalLight::default().illuminance * 0.05F,
          true,
        ),
        @transform.Transform::from_xyz(-4.0F, 2.0F, 0.0F).looking_at(
          @math.Vec3::new(-1.5F, 0.5F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(-2.5F, 4.5F, 9.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  light_gizmos_state.val.camera = Some(camera)

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let instructions = @text.Text2dBundle::new(
      @text.Text2d::new(
        "Press D to toggle gizmo depth bias\nHold Left or Right to change line width\nPress A to toggle light gizmos\nPress C to cycle gizmo coloring modes",
      ),
      @text.TextFont::default().with_font(font).with_font_size(16.0F),
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
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  ignore(instructions)

  let color_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default().with_font(font).with_font_size(16.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, -330.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::bottom_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  light_gizmos_state.val.color_text = Some(color_text)
}

///|
fn configure_light_gizmos(
  config_store : @app.ResMut[@gizmos.GizmoConfigStore],
) -> Unit {
  let store_ref = config_store.get_ref()
  let (config, group) = store_ref.val.config_mut(
    @light.LightGizmoConfigGroup::default(),
  )
  config.val = {
    ..config.val,
    enabled: true,
    line: { ..config.val.line, width: 2.0F },
  }
  group.val = { ..group.val, draw_all: true, color: @light.MatchLightColor }
  update_color_text(group.val)
}

///|
fn rotate_camera(time : @app.Res[@time.Time[@time.Virtual]]) -> Unit {
  guard light_gizmos_state.val.camera is Some(camera_entity) else { return }
  guard @app.current_world() is Some(world) else { return }
  let orbit = time.get().elapsed_secs() / 2.0F
  let translation = @math.Vec3::new(
    @math.cos(orbit) * 9.0F,
    4.5F,
    @math.sin(orbit) * 9.0F,
  )
  let entity_mut = try! world.entity_mut(camera_entity)
  guard (try! entity_mut.get_mut(key=@transform.Transform::component()))
    is Some(transform) else {
    return
  }
  transform.set(
    @transform.Transform::from_translation(translation).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
}

///|
fn update_config(
  config_store : @app.ResMut[@gizmos.GizmoConfigStore],
  time : @app.Res[@time.Time[@time.Virtual]],
) -> Unit {
  let store_ref = config_store.get_ref()
  let (config, group) = store_ref.val.config_mut(
    @light.LightGizmoConfigGroup::default(),
  )
  if @input.key_just_pressed(@window.KeyCode::KeyD) {
    config.val = {
      ..config.val,
      depth_bias: if config.val.depth_bias == 0.0F {
        -1.0F
      } else {
        0.0F
      },
    }
  }
  if @input.key_pressed(@window.KeyCode::ArrowRight) {
    config.val = {
      ..config.val,
      line: {
        ..config.val.line,
        width: clamp_float(
          config.val.line.width + 5.0F * time.get().delta_secs(),
          0.0F,
          50.0F,
        ),
      },
    }
  }
  if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    config.val = {
      ..config.val,
      line: {
        ..config.val.line,
        width: clamp_float(
          config.val.line.width - 5.0F * time.get().delta_secs(),
          0.0F,
          50.0F,
        ),
      },
    }
  }
  if @input.key_just_pressed(@window.KeyCode::KeyA) {
    config.val = { ..config.val, enabled: !config.val.enabled }
  }
  if @input.key_just_pressed(@window.KeyCode::KeyC) {
    group.val = {
      ..group.val,
      color: match group.val.color {
        Manual(_) => @light.Varied
        Varied => @light.MatchLightColor
        MatchLightColor => @light.ByLightType
        ByLightType => @light.Manual(@sprite.Color::srgb(0.5F, 0.5F, 0.5F))
      },
    }
    update_color_text(group.val)
  }
}

///|
fn main {
  @gizmos.init_gizmo_group(
    @app.App::new(@ecs.World::new()).add_plugins(
      @mgstudio.DefaultPlugins::default(),
    ),
    @light.LightGizmoConfigGroup::default(),
  )
  .add_systems(@app.Startup, @app.system(setup_scene))
  .add_systems(
    @app.Startup,
    @app.system(@app.system_param(configure_light_gizmos)),
  )
  .add_systems(@app.Update, @app.system(@app.system_param(rotate_camera)))
  .add_systems(@app.Update, @app.system(@app.system_param2(update_config)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param4(@light.draw_light_gizmos)),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param4(@light.draw_all_light_gizmos)),
  )
  .run()
}
