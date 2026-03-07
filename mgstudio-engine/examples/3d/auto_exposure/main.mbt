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
/// Port of `bevy/examples/3d/auto_exposure.rs`.
///
/// Baseline parity: Bevy's `AutoExposurePlugin` and camera
/// `AutoExposure`/compensation-curve assets are not available in current
/// mgstudio render APIs. This port keeps the same controls and scene topology,
/// uses a real camera `Skybox`, and approximates auto-exposure behavior with a
/// time-smoothed ambient-light model.

///|
const CAMERA_ORBIT_RADIUS : Float = 1.0F

///|
const CAMERA_ROTATE_SPEED : Float = 1.0F

///|
const AUTO_EXPOSURE_LERP_RATE : Float = 2.0F

///|
const MASK_OVERLAY_ALPHA : Float = 0.65F

///|
const INITIAL_EXPOSURE_EV100 : Float = 10.0F

///|
priv struct AutoExposureState {
  mut camera : @core.Entity?
  mut camera_angle : Float
  mut mask_overlay : @core.Entity?
  mut compensation_curve_enabled : Bool
  mut metering_mask_enabled : Bool
  mut exposure_ev100 : Float
  mut display_text : @text.TextHandle?
}

///|
let auto_exposure_state : Ref[AutoExposureState] = Ref::new({
  camera: None,
  camera_angle: 0.0F,
  mask_overlay: None,
  compensation_curve_enabled: true,
  metering_mask_enabled: true,
  exposure_ev100: INITIAL_EXPOSURE_EV100,
  display_text: None,
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
fn set_global_ambient_light(
  world : @ecs.World,
  color : @render2d.Color,
  brightness : Float,
) -> Unit {
  let ambient = @render3d.GlobalAmbientLight::new(color, brightness)
  world.insert_resource(@render3d.ecs_key_global_ambient_light, ambient)
}

///|
fn camera_transform_for_angle(angle : Float) -> @math.Transform {
  @math.Transform::from_xyz(
    @math.cos(angle) * CAMERA_ORBIT_RADIUS,
    0.0F,
    @math.sin(angle) * CAMERA_ORBIT_RADIUS,
  ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F))
}

///|
fn spawn_wall_panel(world : @ecs.World, side : @math.Vec3, level : Int) -> Unit {
  let level_f = float_from_int(level)
  let height = @math.Vec3::new(0.0F, level_f, 0.0F)
  let target = height
  let position = side.mul_scalar(2.0F).add(height)

  let base_color = @render2d.Color::new(
    clampf(0.5F + side.x * 0.5F, 0.0F, 1.0F),
    clampf(0.75F - level_f * 0.25F, 0.0F, 1.0F),
    clampf(0.5F + side.z * 0.5F, 0.0F, 1.0F),
    1.0F,
  )

  let material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(base_color),
  )

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(4.0F, 1.0F, 0.04F),
    @render3d.MeshMaterial3d::new(material),
    @math.Transform::from_xyz(position.x, position.y, position.z).looking_at(
      target,
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn update_display_text() -> Unit {
  if auto_exposure_state.val.display_text is Some(handle) {
    let compensation_label = if auto_exposure_state.val.compensation_curve_enabled {
      "Enabled"
    } else {
      "Disabled"
    }
    let metering_label = if auto_exposure_state.val.metering_mask_enabled {
      "Enabled"
    } else {
      "Disabled"
    }
    @text.text_set_content(
      handle,
      "Compensation Curve: " +
      compensation_label +
      "\nMetering Mask: " +
      metering_label,
    )
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  auto_exposure_state.val.camera = None
  auto_exposure_state.val.camera_angle = 0.0F
  auto_exposure_state.val.mask_overlay = None
  auto_exposure_state.val.compensation_curve_enabled = true
  auto_exposure_state.val.metering_mask_enabled = true
  auto_exposure_state.val.exposure_ev100 = INITIAL_EXPOSURE_EV100
  auto_exposure_state.val.display_text = None

  let asset_server = @asset.AssetServer::new()
  let metering_mask = asset_server.load("textures/basic_metering_mask.png")

  let tick = world.read_change_tick()
  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    camera_transform_for_angle(auto_exposure_state.val.camera_angle),
  ).spawn(world)
  world
  .component(@render3d.ecs_key_exposure)
  .insert(
    camera,
    @render3d.Exposure::new(auto_exposure_state.val.exposure_ev100),
    tick,
  )
  world
  .component(@render3d.ecs_key_skybox)
  .insert(
    camera,
    @render3d.Skybox::new(
      asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
      100_000.0F,
    ),
    tick,
  )
  auto_exposure_state.val.camera = Some(camera)

  for level in [-1, 0, 1] {
    for
      side in [
        @math.Vec3::new(-1.0F, 0.0F, 0.0F),
        @math.Vec3::new(1.0F, 0.0F, 0.0F),
        @math.Vec3::new(0.0F, 0.0F, -1.0F),
        @math.Vec3::new(0.0F, 0.0F, 1.0F),
      ] {
      if level == 0 && side.z == 1.0F {
        continue
      }
      spawn_wall_panel(world, side, level)
    }
  }

  set_global_ambient_light(world, @render2d.Color::white(), 0.0F)

  let point_light = world.spawn_empty()
  world
  .component(@render3d.ecs_key_point_light)
  .insert(
    point_light,
    @render3d.PointLight::new(@render2d.Color::white(), 2_000.0F, 20.0F, true),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(point_light, @math.Transform::identity(), tick)

  // 2D overlay camera + mask image proxy for Bevy's `ImageNode` visualization.
  @render2d.Camera2dBundle::new(
    @render2d.Camera::default().with_order(100).with_clear_color_none(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let mask_size = @math.Vec2::new(
    float_from_int(@window.window_width()),
    float_from_int(@window.window_height()),
  )
  let mask_overlay = @render2d.SpriteBundle::new(
    @render2d.Sprite::from_image(metering_mask)
    .with_custom_size(Some(mask_size))
    .with_color(@render2d.Color::new(1.0F, 1.0F, 1.0F, MASK_OVERLAY_ALPHA)),
    @math.Transform::identity(),
  ).spawn(world)
  world
  .component(@visibility.ecs_key_visibility)
  .insert(mask_overlay, @visibility.Visibility::Hidden, tick)
  auto_exposure_state.val.mask_overlay = Some(mask_overlay)

  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  @text.Text2dBundle::new(
    @text.Text2d::new(
      "Left / Right - Rotate Camera\n" +
      "C - Toggle Compensation Curve\n" +
      "M - Toggle Metering Mask\n" +
      "V - Visualize Metering Mask",
    ),
    @text.TextFont::default().with_font(font).with_font_size(16.0F),
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
  |> ignore

  let display_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default().with_font(font).with_font_size(16.0F),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(390.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@render2d.Anchor::top_right())
    .with_bounds(@text.TextBounds::new_horizontal(360.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  auto_exposure_state.val.display_text = Some(display_text)

  update_display_text()
}

///|
fn example_control_system(world : @ecs.World) -> Unit {
  let delta = @time.time_delta_seconds()

  let rotation = if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    CAMERA_ROTATE_SPEED * delta
  } else if @input.key_pressed(@window.KeyCode::ArrowRight) {
    -CAMERA_ROTATE_SPEED * delta
  } else {
    0.0F
  }

  if rotation != 0.0F {
    auto_exposure_state.val.camera_angle = auto_exposure_state.val.camera_angle +
      rotation
  }

  if @input.key_just_pressed(@window.KeyCode::KeyC) {
    auto_exposure_state.val.compensation_curve_enabled = !auto_exposure_state.val.compensation_curve_enabled
  }

  if @input.key_just_pressed(@window.KeyCode::KeyM) {
    auto_exposure_state.val.metering_mask_enabled = !auto_exposure_state.val.metering_mask_enabled
  }

  let tick = world.read_change_tick()
  if auto_exposure_state.val.camera is Some(camera_entity) {
    world
    .component(@math.ecs_key_transform)
    .set(
      camera_entity,
      camera_transform_for_angle(auto_exposure_state.val.camera_angle),
      tick,
    )
    |> ignore
  }

  if auto_exposure_state.val.mask_overlay is Some(mask_entity) {
    let show_mask = @input.key_pressed(@window.KeyCode::KeyV)
    world
    .component(@visibility.ecs_key_visibility)
    .set(
      mask_entity,
      if show_mask {
        @visibility.Visibility::Visible
      } else {
        @visibility.Visibility::Hidden
      },
      tick,
    )
    |> ignore
  }

  let camera_transform = if auto_exposure_state.val.camera
    is Some(camera_entity) {
    world.component(@math.ecs_key_transform).get(camera_entity)
  } else {
    None
  }

  let view_to_opening = match camera_transform {
    Some(transform) => {
      let view_dir = transform.translation.neg().normalize_or_zero()
      clampf(view_dir.dot(@math.Vec3::new(0.0F, 0.0F, 1.0F)), 0.0F, 1.0F)
    }
    None => 0.0F
  }

  let metering_weight = if auto_exposure_state.val.metering_mask_enabled {
    view_to_opening * view_to_opening
  } else {
    view_to_opening
  }

  let mut target_ev100 = 8.0F + metering_weight * 8.0F
  if auto_exposure_state.val.compensation_curve_enabled {
    let curve_input = metering_weight * 8.0F - 4.0F
    let compensation = if curve_input < 0.0F {
      curve_input * 0.5F
    } else if curve_input <= 2.0F {
      0.0F
    } else {
      curve_input - 2.0F
    }
    target_ev100 = target_ev100 + compensation
  }
  target_ev100 = clampf(target_ev100, 4.0F, 20.0F)

  let lerp = clampf(AUTO_EXPOSURE_LERP_RATE * delta, 0.0F, 1.0F)
  auto_exposure_state.val.exposure_ev100 = auto_exposure_state.val.exposure_ev100 +
    (target_ev100 - auto_exposure_state.val.exposure_ev100) * lerp
  auto_exposure_state.val.exposure_ev100 = clampf(
    auto_exposure_state.val.exposure_ev100,
    4.0F,
    20.0F,
  )
  if auto_exposure_state.val.camera is Some(camera_entity) {
    if world.component(@render3d.ecs_key_exposure).get(camera_entity)
      is Some(exposure) {
      world
      .component(@render3d.ecs_key_exposure)
      .set(
        camera_entity,
        exposure.with_ev100(auto_exposure_state.val.exposure_ev100),
        tick,
      )
      |> ignore
    } else {
      world
      .component(@render3d.ecs_key_exposure)
      .insert(
        camera_entity,
        @render3d.Exposure::new(auto_exposure_state.val.exposure_ev100),
        tick,
      )
    }
  }

  update_display_text()
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(example_control_system))
  .run()
}
