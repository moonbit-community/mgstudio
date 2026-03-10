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
/// Port of `bevy/examples/3d/light_textures.rs`.
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
} derive(Eq, Show)

///|
pub(all) enum DragMode {
  Move
  Scale
  Roll
} derive(Eq, Show)

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
  "Light Textures (Bevy-aligned controls)\n" +
  "1/2/3/4: Selection (" +
  selection_text(light_textures_state.val.selection) +
  ")\n" +
  "M/S/R: Drag Mode (" +
  drag_mode_text(light_textures_state.val.drag_mode) +
  ")\n" +
  "V: Toggle selected light visibility (" +
  visibility_text(current_selection_visibility()) +
  ")\n" +
  "Drag Left Mouse: apply mode to selection\n\n" +
  "Note: light-cookie projection is currently renderer-adapted."
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
  let tick = world.read_change_tick()
  let value = if visible {
    @visibility.Visibility::Visible
  } else {
    @visibility.Visibility::Hidden
  }
  world.component(@visibility.ecs_key_visibility).insert(proxy, value, tick)
}

///|
fn update_directional_light(world : @ecs.World) -> Unit {
  guard light_textures_state.val.directional_light is Some(entity) else {
    return
  }
  guard world.component(@render3d.ecs_key_directional_light).get(entity)
    is Some(light) else {
    return
  }
  let tick = world.read_change_tick()
  let any_texture_light_visible = light_textures_state.val.spot_visible ||
    light_textures_state.val.point_visible
  let next_illuminance = if light_textures_state.val.directional_visible {
    MAIN_LIGHT_INTENSITY
  } else if any_texture_light_visible {
    FALLBACK_LIGHT_INTENSITY
  } else {
    MAIN_LIGHT_INTENSITY
  }
  world
  .component(@render3d.ecs_key_directional_light)
  .set(entity, light.with_illuminance(next_illuminance), tick)
  |> ignore

  if light_textures_state.val.directional_visible {
    if light_textures_state.val.directional_texture is Some(texture) {
      world
      .component(@render3d.ecs_key_directional_light_texture)
      .insert(
        entity,
        @render3d.DirectionalLightTexture::new(Some(texture), true),
        tick,
      )
    }
  } else {
    world.component(@render3d.ecs_key_directional_light_texture).remove(entity)
    |> ignore
  }
}

///|
fn apply_light_visibility(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  if light_textures_state.val.spot_light is Some(spot_entity) {
    if world.component(@render3d.ecs_key_spot_light).get(spot_entity)
      is Some(spot) {
      let intensity = if light_textures_state.val.spot_visible {
        SPOT_LIGHT_INTENSITY
      } else {
        0.0F
      }
      world
      .component(@render3d.ecs_key_spot_light)
      .set(spot_entity, spot.with_intensity(intensity), tick)
      |> ignore
    }
  }
  if light_textures_state.val.point_light is Some(point_entity) {
    if world.component(@render3d.ecs_key_point_light).get(point_entity)
      is Some(point) {
      let intensity = if light_textures_state.val.point_visible {
        POINT_LIGHT_INTENSITY
      } else {
        0.0F
      }
      world
      .component(@render3d.ecs_key_point_light)
      .set(point_entity, point.with_intensity(intensity), tick)
      |> ignore
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
  let tick = world.read_change_tick()
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

  let cube_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @sprite.Color::new(0.75F, 0.75F, 0.75F, 1.0F),
    ),
  )
  let cube = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(3.0F, 3.0F, 3.0F),
    @render3d.MeshMaterial3d::new(cube_material),
    @math.Transform::from_xyz(0.0F, 0.0F, 0.0F).with_rotation(
      @math.Quat::from_rotation_y(1.0471975512F),
    ),
  ).spawn(world)
  light_textures_state.val.rotating_cube = Some(cube)

  let camera = @render3d.Camera3dBundle::new(
    @sprite.Camera::default(),
    @math.Transform::from_xyz(0.0F, 2.5F, 9.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  light_textures_state.val.camera = Some(camera)

  let directional = world.spawn_empty()
  light_textures_state.val.directional_light = Some(directional)
  world
  .component(@render3d.ecs_key_directional_light)
  .insert(
    directional,
    @render3d.DirectionalLight::new(
      @sprite.Color::white(),
      MAIN_LIGHT_INTENSITY,
      true,
    ),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(
    directional,
    @math.Transform::from_xyz(8.0F, 8.0F, 4.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  let spot = world.spawn_empty()
  light_textures_state.val.spot_light = Some(spot)
  world
  .component(@render3d.ecs_key_spot_light)
  .insert(
    spot,
    @render3d.SpotLight::new(
      @sprite.Color::new(1.0F, 1.0F, 0.8F, 1.0F),
      SPOT_LIGHT_INTENSITY,
      30.0F,
      0.25F,
      0.25F,
      true,
    ),
    tick,
  )
  world
  .component(@render3d.ecs_key_spot_light_texture)
  .insert(
    spot,
    @render3d.SpotLightTexture::new(
      Some(asset_server.load("branding/icon.png")),
    ),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(
    spot,
    @math.Transform::from_xyz(6.0F, 1.0F, 2.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  let point = world.spawn_empty()
  light_textures_state.val.point_light = Some(point)
  world
  .component(@render3d.ecs_key_point_light)
  .insert(
    point,
    @render3d.PointLight::new(
      @sprite.Color::new(0.0F, 0.0F, 1.0F, 1.0F),
      POINT_LIGHT_INTENSITY,
      20.0F,
      true,
    ),
    tick,
  )
  world
  .component(@render3d.ecs_key_point_light_texture)
  .insert(
    point,
    @render3d.PointLightTexture::new(
      Some(asset_server.load("branding/icon.png")),
      @render3d.CubemapLayout3d::CrossVertical,
    ),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(point, @math.Transform::from_xyz(0.0F, 1.8F, 0.01F), tick)

  let spot_proxy_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @sprite.Color::new(1.0F, 0.8F, 0.2F, 0.75F),
    )
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_unlit(true),
  )
  let point_proxy_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @sprite.Color::new(0.2F, 0.2F, 1.0F, 0.75F),
    )
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_unlit(true),
  )
  let spot_proxy = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(0.35F, 0.35F, 0.35F),
    @render3d.MeshMaterial3d::new(spot_proxy_material),
    @math.Transform::from_xyz(6.0F, 1.0F, 2.0F),
  ).spawn(world)
  let point_proxy = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(0.25F, 0.25F, 0.25F),
    @render3d.MeshMaterial3d::new(point_proxy_material),
    @math.Transform::from_xyz(0.0F, 1.8F, 0.01F),
  ).spawn(world)
  light_textures_state.val.spot_proxy = Some(spot_proxy)
  light_textures_state.val.point_proxy = Some(point_proxy)

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
  let tick = world.read_change_tick()
  guard world.component(@math.ecs_key_transform).get(camera_entity)
    is Some(transform) else {
    return
  }
  let next_translation = transform.translation.add(
    @math.Vec3::new(-delta.x * MOVE_SPEED, delta.y * MOVE_SPEED, 0.0F),
  )
  world
  .component(@math.ecs_key_transform)
  .set(
    camera_entity,
    transform
    .with_translation(next_translation)
    .looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F)),
    tick,
  )
  |> ignore
}

///|
fn apply_selection_drag(
  world : @ecs.World,
  entity : @core.Entity,
  delta : @math.Vec2,
) -> Unit {
  let tick = world.read_change_tick()
  guard world.component(@math.ecs_key_transform).get(entity) is Some(transform) else {
    return
  }
  match light_textures_state.val.drag_mode {
    DragMode::Move => {
      let next_translation = transform.translation.add(
        @math.Vec3::new(delta.x * MOVE_SPEED, -delta.y * MOVE_SPEED, 0.0F),
      )
      world
      .component(@math.ecs_key_transform)
      .set(entity, transform.with_translation(next_translation), tick)
      |> ignore
      if light_textures_state.val.selection == Selection::SpotLight {
        if light_textures_state.val.spot_proxy is Some(proxy) {
          world
          .component(@math.ecs_key_transform)
          .set(
            proxy,
            @math.Transform::from_xyz(
              next_translation.x,
              next_translation.y,
              next_translation.z,
            ),
            tick,
          )
          |> ignore
        }
      }
      if light_textures_state.val.selection == Selection::PointLight {
        if light_textures_state.val.point_proxy is Some(proxy) {
          world
          .component(@math.ecs_key_transform)
          .set(
            proxy,
            @math.Transform::from_xyz(
              next_translation.x,
              next_translation.y,
              next_translation.z,
            ),
            tick,
          )
          |> ignore
        }
      }
    }
    DragMode::Scale =>
      if light_textures_state.val.selection == Selection::SpotLight {
        guard world.component(@render3d.ecs_key_spot_light).get(entity)
          is Some(spot) else {
          return
        }
        let next_angle = clampf(
          spot.outer_angle * (1.0F + delta.x * SCALE_SPEED),
          0.01F,
          0.78539816339F,
        )
        world
        .component(@render3d.ecs_key_spot_light)
        .set(
          entity,
          spot.with_outer_angle(next_angle).with_inner_angle(next_angle),
          tick,
        )
        |> ignore
      } else {
        let next = maxf(0.20F, transform.scale.x + delta.y * SCALE_SPEED)
        world
        .component(@math.ecs_key_transform)
        .set(
          entity,
          transform.with_scale(@math.Vec3::new(next, next, transform.scale.z)),
          tick,
        )
        |> ignore
      }
    DragMode::Roll => {
      let rotation = transform.rotation
        .mul(@math.Quat::from_rotation_z(delta.x * ROLL_SPEED))
        .normalize()
      world
      .component(@math.ecs_key_transform)
      .set(entity, transform.with_rotation(rotation), tick)
      |> ignore
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
fn rotate_cube(world : @ecs.World) -> Unit {
  guard light_textures_state.val.rotating_cube is Some(cube_entity) else {
    return
  }
  guard world.component(@math.ecs_key_transform).get(cube_entity)
    is Some(transform) else {
    return
  }
  let tick = world.read_change_tick()
  let delta = @time.time_delta_seconds()
  let rotation = transform.rotation
    .mul(@math.Quat::from_rotation_y(CUBE_ROTATION_SPEED * delta * 60.0F))
    .normalize()
  world
  .component(@math.ecs_key_transform)
  .set(cube_entity, transform.with_rotation(rotation), tick)
  |> ignore
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
