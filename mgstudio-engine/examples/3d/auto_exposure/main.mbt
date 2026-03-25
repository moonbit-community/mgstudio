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
/// Uses `Camera3d.auto_exposure` with the render3d GPU histogram pipeline.

///|
const CAMERA_ORBIT_RADIUS : Float = 1.0F

///|
const CAMERA_ROTATE_SPEED : Float = 1.0F

///|
const MASK_OVERLAY_ALPHA : Float = 0.65F

///|
priv struct AutoExposureState {
  mut camera : @core.Entity?
  mut camera_angle : Float
  mut mask_overlay : @core.Entity?
  mut compensation_curve_enabled : Bool
  mut metering_mask_enabled : Bool
  mut display_text : @text.TextHandle?
  mut basic_compensation_curve : @asset.Handle[
    @pbr.AutoExposureCompensationCurve,
  ]?
  mut basic_metering_mask : @asset.Handle[@asset.Image]?
}

///|
let auto_exposure_state : Ref[AutoExposureState] = Ref::new({
  camera: None,
  camera_angle: 0.0F,
  mask_overlay: None,
  compensation_curve_enabled: true,
  metering_mask_enabled: true,
  display_text: None,
  basic_compensation_curve: None,
  basic_metering_mask: None,
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
  color : @sprite.Color,
  brightness : Float,
) -> Unit {
  let ambient = @pbr.GlobalAmbientLight::new(color, brightness)
  world.insert_resource(@pbr.ecs_key_global_ambient_light, ambient)
}

///|
fn camera_transform_for_angle(angle : Float) -> @transform.Transform {
  @transform.Transform::from_xyz(
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

  let base_color = @sprite.Color::new(
    clampf(0.5F + side.x * 0.5F, 0.0F, 1.0F),
    clampf(0.75F - level_f * 0.25F, 0.0F, 1.0F),
    clampf(0.5F + side.z * 0.5F, 0.0F, 1.0F),
    1.0F,
  )

  let material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(base_color),
  )

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(4.0F, 1.0F, 0.04F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(material),
    @transform.Transform::from_xyz(position.x, position.y, position.z).looking_at(
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
fn auto_exposure_curve_assets_ref_mut_or_abort(
  world : @ecs.World,
) -> Ref[@asset.Assets[@pbr.AutoExposureCompensationCurve]] {
  let key : @ecs.ResourceKey[@asset.Assets[@pbr.AutoExposureCompensationCurve]] = @asset.assets_resource_key()
  if (try! world.get_resource(key)) is None {
    world.insert_resource(key, @asset.Assets::new())
  }
  match (try! world.get_resource_ref_mut(key)) {
    Some(assets_ref) => assets_ref
    None =>
      abort(
        "Missing Assets<AutoExposureCompensationCurve> resource in auto_exposure example",
      )
  }
}

///|
fn build_basic_compensation_curve(
  world : @ecs.World,
) -> @asset.Handle[@pbr.AutoExposureCompensationCurve] {
  let curve = match
    @pbr.AutoExposureCompensationCurve::from_curve(
      @math.LinearSpline::new([
        @math.Vec2::new(-4.0F, -2.0F),
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(2.0F, 0.0F),
        @math.Vec2::new(4.0F, 2.0F),
      ]),
    ) {
    Ok(value) => value
    Err(err) =>
      abort(
        "Failed to build auto exposure compensation curve in example: " +
        auto_exposure_curve_error_message(err),
      )
  }
  auto_exposure_curve_assets_ref_mut_or_abort(world).val.add(curve)
}

///|
fn auto_exposure_curve_error_message(
  err : @pbr.AutoExposureCompensationCurveError,
) -> String {
  match err {
    @pbr.InvalidCurve => "invalid curve"
    @pbr.DiscontinuityFound => "discontinuity found"
    @pbr.NotMonotonic => "not monotonic"
  }
}

///|
fn example_auto_exposure_settings() -> @pbr.AutoExposure {
  let compensation_curve = if auto_exposure_state.val.compensation_curve_enabled {
    auto_exposure_state.val.basic_compensation_curve
  } else {
    None
  }
  let metering_mask = if auto_exposure_state.val.metering_mask_enabled {
    auto_exposure_state.val.basic_metering_mask
  } else {
    None
  }
  @pbr.AutoExposure::default()
  .with_compensation_curve(compensation_curve)
  .with_metering_mask(metering_mask)
}

///|
fn apply_example_auto_exposure_to_camera(
  world : @ecs.World,
  camera_entity : @core.Entity,
) -> Unit {
  let camera3d = match
    (try! world.get_by_key(camera_entity, @pbr.ecs_key_camera3d)) {
    Some(value) => value
    None => @pbr.Camera3d::default()
  }
  try! (world.replace(
    camera_entity,
    @pbr.ecs_key_camera3d,
    camera3d.with_auto_exposure(Some(example_auto_exposure_settings())),
  )
  |> ignore)
}

///|
fn setup(world : @ecs.World) -> Unit {
  auto_exposure_state.val.camera = None
  auto_exposure_state.val.camera_angle = 0.0F
  auto_exposure_state.val.mask_overlay = None
  auto_exposure_state.val.compensation_curve_enabled = true
  auto_exposure_state.val.metering_mask_enabled = true
  auto_exposure_state.val.display_text = None
  auto_exposure_state.val.basic_compensation_curve = None
  auto_exposure_state.val.basic_metering_mask = None

  let asset_server = @asset.AssetServer::new()
  let metering_mask = asset_server.load("textures/basic_metering_mask.png")

  let basic_curve = build_basic_compensation_curve(world)
  auto_exposure_state.val.basic_compensation_curve = Some(basic_curve)
  auto_exposure_state.val.basic_metering_mask = Some(metering_mask)

  let camera = @pbr.Camera3dBundle::new(
      @sprite.Camera::default(),
      camera_transform_for_angle(auto_exposure_state.val.camera_angle),
    )
    .with_camera3d(
      @pbr.Camera3d::default().with_auto_exposure(
        Some(example_auto_exposure_settings()),
      ),
    )
    .spawn(world)
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_skybox,
    @pbr.Skybox::new(
      asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
      100_000.0F,
    ),
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

  set_global_ambient_light(world, @sprite.Color::white(), 0.0F)

  let point_light = world.spawn_empty()
  try! world.set_by_key(
    point_light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::new(@sprite.Color::white(), 2_000.0F, 20.0F, true),
  )
  try! world.set_by_key(
    point_light,
    @transform.ecs_key_transform,
    @transform.Transform::identity(),
  )

  // 2D overlay camera + mask image proxy for Bevy's `ImageNode` visualization.
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default().with_order(100).with_clear_color_none(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let mask_size = @math.Vec2::new(
    float_from_int(@window.window_width()),
    float_from_int(@window.window_height()),
  )
  let mask_overlay = @sprite.SpriteBundle::new(
    @sprite.Sprite::from_image(metering_mask)
    .with_custom_size(Some(mask_size))
    .with_color(@sprite.Color::new(1.0F, 1.0F, 1.0F, MASK_OVERLAY_ALPHA)),
    @transform.Transform::identity(),
  ).spawn(world)
  try! world.set_by_key(
    mask_overlay,
    @visibility.ecs_key_visibility,
    @visibility.Visibility::Hidden,
  )
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
  |> ignore

  let display_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default().with_font(font).with_font_size(16.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(390.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::top_right())
    .with_bounds(@text.TextBounds::new_horizontal(360.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  auto_exposure_state.val.display_text = Some(display_text)

  update_display_text()
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in auto_exposure example")
  }
}

///|
fn example_control_system(world : @ecs.World) -> Unit {
  let delta = world_time(world).delta_seconds()

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

  if auto_exposure_state.val.camera is Some(camera_entity) {
    try! (world.replace(
      camera_entity,
      @transform.ecs_key_transform,
      camera_transform_for_angle(auto_exposure_state.val.camera_angle),
    )
    |> ignore)
    apply_example_auto_exposure_to_camera(world, camera_entity)
  }

  if auto_exposure_state.val.mask_overlay is Some(mask_entity) {
    let show_mask = @input.key_pressed(@window.KeyCode::KeyV)
    try! (world.replace(
      mask_entity,
      @visibility.ecs_key_visibility,
      if show_mask {
        @visibility.Visibility::Visible
      } else {
        @visibility.Visibility::Hidden
      },
    )
    |> ignore)
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
