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
/// Baseline parity: Bevy's light-cookie projection pipeline is not yet applied
/// in current mgstudio renderer. This port preserves Bevy-style selection/drag
/// controls and light-texture API surfaces (`Directional/Spot/PointLightTexture`)
/// with runtime-adapted lighting behavior.

///|
const CUBE_ROTATION_SPEED : Float = 0.02F

///|
const MOVE_SPEED : Float = 0.01F

///|
const SCALE_SPEED : Float = 0.01F

///|
const ROLL_SPEED : Float = 0.01F

///|
const MAIN_LIGHT_INTENSITY : Float = 15_000.0F

///|
const FALLBACK_LIGHT_INTENSITY : Float = 1_200.0F

///|
const SPOT_LIGHT_INTENSITY : Float = 1_000_000.0F

///|
const POINT_LIGHT_INTENSITY : Float = 1_000_000.0F

///|
pub(all) enum Selection {
  Camera
  SpotLight
  PointLight
  DirectionalLight
} derive(Eq, Debug)

///|
pub(all) enum DragMode {
  Move
  Scale
  Roll
} derive(Eq, Debug)

///|
priv struct LightTexturesState {
  mut camera : @core.Entity?
  mut rotating_cube : @core.Entity?
  mut directional_light : @core.Entity?
  mut spot_light : @core.Entity?
  mut point_light : @core.Entity?
  mut spot_proxy : @core.Entity?
  mut point_proxy : @core.Entity?
  mut selection : Selection
  mut drag_mode : DragMode
  mut directional_visible : Bool
  mut spot_visible : Bool
  mut point_visible : Bool
  mut help_text : @text.TextHandle?
  mut last_mouse : @math.Vec2?
  mut directional_texture : @asset.Handle[@asset.Image]?
}

///|
let light_textures_state : Ref[LightTexturesState] = Ref::new({
  camera: None,
  rotating_cube: None,
  directional_light: None,
  spot_light: None,
  point_light: None,
  spot_proxy: None,
  point_proxy: None,
  selection: Selection::Camera,
  drag_mode: DragMode::Move,
  directional_visible: true,
  spot_visible: true,
  point_visible: true,
  help_text: None,
  last_mouse: None,
  directional_texture: None,
})

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
fn maxf(a : Float, b : Float) -> Float {
  if a >= b {
    a
  } else {
    b
  }
}

///|
fn selection_text(selection : Selection) -> String {
  match selection {
    Selection::Camera => "Camera"
    Selection::SpotLight => "Spot Light"
    Selection::PointLight => "Point Light"
    Selection::DirectionalLight => "Directional Light"
  }
}

///|
fn drag_mode_text(mode : DragMode) -> String {
  match mode {
    DragMode::Move => "Move"
    DragMode::Scale => "Scale"
    DragMode::Roll => "Roll"
  }
}

///|
fn visibility_text(visible : Bool) -> String {
  if visible {
    "Visible"
  } else {
    "Hidden"
  }
}

///|
fn current_selection_visibility() -> Bool {
  match light_textures_state.val.selection {
    Selection::Camera => true
    Selection::SpotLight => light_textures_state.val.spot_visible
    Selection::PointLight => light_textures_state.val.point_visible
    Selection::DirectionalLight => light_textures_state.val.directional_visible
  }
}

///|
fn help_text_content() -> String {
  "Light Textures (Bevy-aligned controls)\n1/2/3/4: Selection (\{selection_text(light_textures_state.val.selection)})\nM/S/R: Drag Mode (\{drag_mode_text(light_textures_state.val.drag_mode)})\nV: Toggle selected light visibility (\{visibility_text(current_selection_visibility())})\nDrag Left Mouse: apply mode to selection\n\nNote: light-cookie projection is currently renderer-adapted."
}

///|
fn update_help_text() -> Unit {
  if light_textures_state.val.help_text is Some(help_text) {
    @text.text_set_content(help_text, help_text_content())
  }
}

///|
fn set_proxy_visibility(
  world : @ecs.World,
  entity : @core.Entity?,
  visible : Bool,
) -> Unit {
  guard entity is Some(proxy) else { return }
  let value = if visible {
    @visibility.Visibility::Visible
  } else {
    @visibility.Visibility::Hidden
  }
  try! world.set_by_key(proxy, @visibility.ecs_key_visibility, value)
}

///|
fn update_directional_light(world : @ecs.World) -> Unit {
  guard light_textures_state.val.directional_light is Some(entity) else {
    return
  }
  guard (try! world.get_by_key(entity, @pbr.ecs_key_directional_light))
    is Some(light) else {
    return
  }
  let any_texture_light_visible = light_textures_state.val.spot_visible ||
    light_textures_state.val.point_visible
  let next_illuminance = if light_textures_state.val.directional_visible {
    MAIN_LIGHT_INTENSITY
  } else if any_texture_light_visible {
    FALLBACK_LIGHT_INTENSITY
  } else {
    MAIN_LIGHT_INTENSITY
  }
  try! (world.replace(
    entity,
    @pbr.ecs_key_directional_light,
    light.with_illuminance(next_illuminance),
  )
  |> ignore)

  if light_textures_state.val.directional_visible {
    if light_textures_state.val.directional_texture is Some(texture) {
      try! world.set_by_key(
        entity,
        @pbr.ecs_key_directional_light_texture,
        @pbr.DirectionalLightTexture::new(Some(texture), true),
      )
    }
  } else {
    try! (world.take(entity, @pbr.ecs_key_directional_light_texture) |> ignore)
  }
}

///|
fn apply_light_visibility(world : @ecs.World) -> Unit {
  if light_textures_state.val.spot_light is Some(spot_entity) {
    if (try! world.get_by_key(spot_entity, @pbr.ecs_key_spot_light))
      is Some(spot) {
      let intensity = if light_textures_state.val.spot_visible {
        SPOT_LIGHT_INTENSITY
      } else {
        0.0F
      }
      try! (world.replace(
        spot_entity,
        @pbr.ecs_key_spot_light,
        spot.with_intensity(intensity),
      )
      |> ignore)
    }
  }
  if light_textures_state.val.point_light is Some(point_entity) {
    if (try! world.get_by_key(point_entity, @pbr.ecs_key_point_light))
      is Some(point) {
      let intensity = if light_textures_state.val.point_visible {
        POINT_LIGHT_INTENSITY
      } else {
        0.0F
      }
      try! (world.replace(
        point_entity,
        @pbr.ecs_key_point_light,
        point.with_intensity(intensity),
      )
      |> ignore)
    }
  }
  set_proxy_visibility(
    world,
    light_textures_state.val.spot_proxy,
    light_textures_state.val.spot_visible,
  )
  set_proxy_visibility(
    world,
    light_textures_state.val.point_proxy,
    light_textures_state.val.point_visible,
  )
  update_directional_light(world)
}

///|
fn setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  light_textures_state.val.camera = None
  light_textures_state.val.rotating_cube = None
  light_textures_state.val.directional_light = None
  light_textures_state.val.spot_light = None
  light_textures_state.val.point_light = None
  light_textures_state.val.spot_proxy = None
  light_textures_state.val.point_proxy = None
  light_textures_state.val.selection = Selection::Camera
  light_textures_state.val.drag_mode = DragMode::Move
  light_textures_state.val.directional_visible = true
  light_textures_state.val.spot_visible = true
  light_textures_state.val.point_visible = true
  light_textures_state.val.help_text = None
  light_textures_state.val.last_mouse = None
  light_textures_state.val.directional_texture = Some(
    asset_server.load("branding/icon.png"),
  )

  let cube_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.75F, 0.75F, 0.75F, 1.0F),
    ),
  )
  let cube = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(3.0F, 3.0F, 3.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(cube_material),
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F).with_rotation(
      @math.Quat::from_rotation_y(1.0471975512F),
    ),
  ).spawn(world)
  light_textures_state.val.rotating_cube = Some(cube)

  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(0.0F, 2.5F, 9.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  light_textures_state.val.camera = Some(camera)

  let directional = world.spawn_empty()
  light_textures_state.val.directional_light = Some(directional)
  try! world.set_by_key(
    directional,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::new(
      @sprite.Color::white(),
      MAIN_LIGHT_INTENSITY,
      true,
    ),
  )
  try! world.set_by_key(
    directional,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(8.0F, 8.0F, 4.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )

  let spot = world.spawn_empty()
  light_textures_state.val.spot_light = Some(spot)
  try! world.set_by_key(
    spot,
    @pbr.ecs_key_spot_light,
    @pbr.SpotLight::new(
      @sprite.Color::new(1.0F, 1.0F, 0.8F, 1.0F),
      SPOT_LIGHT_INTENSITY,
      30.0F,
      0.25F,
      0.25F,
      true,
    ),
  )
  try! world.set_by_key(
    spot,
    @pbr.ecs_key_spot_light_texture,
    @pbr.SpotLightTexture::new(Some(asset_server.load("branding/icon.png"))),
  )
  try! world.set_by_key(
    spot,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(6.0F, 1.0F, 2.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )

  let point = world.spawn_empty()
  light_textures_state.val.point_light = Some(point)
  try! world.set_by_key(
    point,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::new(
      @sprite.Color::new(0.0F, 0.0F, 1.0F, 1.0F),
      POINT_LIGHT_INTENSITY,
      20.0F,
      true,
    ),
  )
  try! world.set_by_key(
    point,
    @pbr.ecs_key_point_light_texture,
    @pbr.PointLightTexture::new(
      Some(asset_server.load("branding/icon.png")),
      @pbr.CubemapLayout3d::CrossVertical,
    ),
  )
  try! world.set_by_key(
    point,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 1.8F, 0.01F),
  )

  let spot_proxy_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(1.0F, 0.8F, 0.2F, 0.75F),
    )
    .with_alpha_mode(@pbr.AlphaMode3d::Blend)
    .with_unlit(true),
  )
  let point_proxy_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.2F, 0.2F, 1.0F, 0.75F),
    )
    .with_alpha_mode(@pbr.AlphaMode3d::Blend)
    .with_unlit(true),
  )
  let spot_proxy = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(0.35F, 0.35F, 0.35F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(spot_proxy_material),
    @transform.Transform::from_xyz(6.0F, 1.0F, 2.0F),
  ).spawn(world)
  let point_proxy = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(0.25F, 0.25F, 0.25F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(point_proxy_material),
    @transform.Transform::from_xyz(0.0F, 1.8F, 0.01F),
  ).spawn(world)
  light_textures_state.val.spot_proxy = Some(spot_proxy)
  light_textures_state.val.point_proxy = Some(point_proxy)

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
  light_textures_state.val.help_text = Some(help_text)

  apply_light_visibility(world)
  update_help_text()
}

///|
fn selected_entity() -> @core.Entity? {
  match light_textures_state.val.selection {
    Selection::Camera => light_textures_state.val.camera
    Selection::SpotLight => light_textures_state.val.spot_light
    Selection::PointLight => light_textures_state.val.point_light
    Selection::DirectionalLight => light_textures_state.val.directional_light
  }
}

///|
fn apply_camera_drag(
  world : @ecs.World,
  camera_entity : @core.Entity,
  delta : @math.Vec2,
) -> Unit {
  guard (try! world.get_by_key(camera_entity, @transform.ecs_key_transform))
    is Some(transform) else {
    return
  }
  let next_translation = transform.translation.add(
    @math.Vec3::new(-delta.x * MOVE_SPEED, delta.y * MOVE_SPEED, 0.0F),
  )
  try! (world.replace(
    camera_entity,
    @transform.ecs_key_transform,
    transform
    .with_translation(next_translation)
    .looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F)),
  )
  |> ignore)
}

///|
fn apply_selection_drag(
  world : @ecs.World,
  entity : @core.Entity,
  delta : @math.Vec2,
) -> Unit {
  guard (try! world.get_by_key(entity, @transform.ecs_key_transform))
    is Some(transform) else {
    return
  }
  match light_textures_state.val.drag_mode {
    DragMode::Move => {
      let next_translation = transform.translation.add(
        @math.Vec3::new(delta.x * MOVE_SPEED, -delta.y * MOVE_SPEED, 0.0F),
      )
      try! (world.replace(
        entity,
        @transform.ecs_key_transform,
        transform.with_translation(next_translation),
      )
      |> ignore)
      if light_textures_state.val.selection == Selection::SpotLight {
        if light_textures_state.val.spot_proxy is Some(proxy) {
          try! (world.replace(
            proxy,
            @transform.ecs_key_transform,
            @transform.Transform::from_xyz(
              next_translation.x,
              next_translation.y,
              next_translation.z,
            ),
          )
          |> ignore)
        }
      }
      if light_textures_state.val.selection == Selection::PointLight {
        if light_textures_state.val.point_proxy is Some(proxy) {
          try! (world.replace(
            proxy,
            @transform.ecs_key_transform,
            @transform.Transform::from_xyz(
              next_translation.x,
              next_translation.y,
              next_translation.z,
            ),
          )
          |> ignore)
        }
      }
    }
    DragMode::Scale =>
      if light_textures_state.val.selection == Selection::SpotLight {
        guard (try! world.get_by_key(entity, @pbr.ecs_key_spot_light))
          is Some(spot) else {
          return
        }
        let next_angle = clampf(
          spot.outer_angle * (1.0F + delta.x * SCALE_SPEED),
          0.01F,
          0.78539816339F,
        )
        try! (world.replace(
          entity,
          @pbr.ecs_key_spot_light,
          spot.with_outer_angle(next_angle).with_inner_angle(next_angle),
        )
        |> ignore)
      } else {
        let next = maxf(0.20F, transform.scale.x + delta.y * SCALE_SPEED)
        try! (world.replace(
          entity,
          @transform.ecs_key_transform,
          transform.with_scale(@math.Vec3::new(next, next, transform.scale.z)),
        )
        |> ignore)
      }
    DragMode::Roll => {
      let rotation = transform.rotation
        .mul(@math.Quat::from_rotation_z(delta.x * ROLL_SPEED))
        .normalize()
      try! (world.replace(
        entity,
        @transform.ecs_key_transform,
        transform.with_rotation(rotation),
      )
      |> ignore)
    }
  }
}

///|
fn toggle_selected_visibility(world : @ecs.World) -> Unit {
  match light_textures_state.val.selection {
    Selection::Camera => ()
    Selection::SpotLight => {
      light_textures_state.val.spot_visible = !light_textures_state.val.spot_visible
      apply_light_visibility(world)
    }
    Selection::PointLight => {
      light_textures_state.val.point_visible = !light_textures_state.val.point_visible
      apply_light_visibility(world)
    }
    Selection::DirectionalLight => {
      light_textures_state.val.directional_visible = !light_textures_state.val.directional_visible
      apply_light_visibility(world)
    }
  }
}

///|
fn controls(world : @ecs.World) -> Unit {
  let mut changed = false
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    light_textures_state.val.selection = Selection::Camera
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    light_textures_state.val.selection = Selection::SpotLight
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit3) {
    light_textures_state.val.selection = Selection::PointLight
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit4) {
    light_textures_state.val.selection = Selection::DirectionalLight
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyM) {
    light_textures_state.val.drag_mode = DragMode::Move
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyS) {
    light_textures_state.val.drag_mode = DragMode::Scale
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyR) {
    light_textures_state.val.drag_mode = DragMode::Roll
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyV) {
    toggle_selected_visibility(world)
    changed = true
  }
  if changed {
    update_help_text()
  }

  if @input.mouse_button_just_pressed(@window.MouseButton::Left) {
    light_textures_state.val.last_mouse = @input.mouse_position()
  }
  if @input.mouse_button_just_released(@window.MouseButton::Left) {
    light_textures_state.val.last_mouse = None
  }
  if !@input.mouse_button_pressed(@window.MouseButton::Left) {
    return
  }
  guard @input.mouse_position() is Some(current_mouse) else { return }
  guard light_textures_state.val.last_mouse is Some(previous_mouse) else {
    light_textures_state.val.last_mouse = Some(current_mouse)
    return
  }
  let delta = current_mouse.sub(previous_mouse)
  light_textures_state.val.last_mouse = Some(current_mouse)
  guard selected_entity() is Some(entity) else { return }
  if light_textures_state.val.selection == Selection::Camera {
    apply_camera_drag(world, entity, delta)
  } else {
    apply_selection_drag(world, entity, delta)
  }
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in light_textures example")
  }
}

///|
fn rotate_cube(world : @ecs.World) -> Unit {
  guard light_textures_state.val.rotating_cube is Some(cube_entity) else {
    return
  }
  guard (try! world.get_by_key(cube_entity, @transform.ecs_key_transform))
    is Some(transform) else {
    return
  }
  let delta = world_time(world).delta_seconds()
  let rotation = transform.rotation
    .mul(@math.Quat::from_rotation_y(CUBE_ROTATION_SPEED * delta * 60.0F))
    .normalize()
  try! (world.replace(
    cube_entity,
    @transform.ecs_key_transform,
    transform.with_rotation(rotation),
  )
  |> ignore)
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(controls))
  .add_systems(@app.Update, @app.system(rotate_cube))
  .run()
}
