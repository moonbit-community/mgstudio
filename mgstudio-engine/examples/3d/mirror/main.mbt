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
/// Port of `bevy/examples/3d/mirror.rs`.
///
/// Parity note:
/// - Mirror camera transform/projection updates, mirror render target resizing,
///   drag-to-orbit camera, and drag-to-move-fox controls are mapped.
/// - Bevy-only features like `ExtendedMaterial` and `Camera::invert_culling`
///   are represented by the closest runtime behavior currently available in
///   mgstudio.

///|
const FRAC_PI_2 : Float = 1.5707963267948966F

///|
const CAMERA_ORBIT_DISTANCE : Float = 500.0F

///|
const CAMERA_PITCH_SPEED : Float = 0.003F

///|
const CAMERA_YAW_SPEED : Float = 0.004F

///|
const CAMERA_PITCH_LIMIT : Float = 1.5607963267948965F

///|
const FOX_ASSET_PATH : String = "models/animated/Fox.glb"

///|
pub(all) enum DragAction {
  MoveCamera
  MoveFox
} derive(Eq, Show)

///|
priv struct MirrorState {
  mut main_camera : @core.Entity
  mut mirror_camera : @core.Entity
  mut mirror_plane : @core.Entity
  mut fox : @core.Entity
  mut mirror_material : @asset.Handle[@render3d.StandardMaterial]?
  mut mirror_target_size : @math.IVec2
  mut drag_action : DragAction
  mut orbit_yaw : Float
  mut orbit_pitch : Float
  mut last_mouse_position : @math.Vec2?
  mut help_text : @text.TextHandle?
}

///|
let mirror_state : Ref[MirrorState] = Ref::new({
  main_camera: @core.Entity::placeholder(),
  mirror_camera: @core.Entity::placeholder(),
  mirror_plane: @core.Entity::placeholder(),
  fox: @core.Entity::placeholder(),
  mirror_material: None,
  mirror_target_size: @math.IVec2::new(0, 0),
  drag_action: DragAction::MoveCamera,
  orbit_yaw: 0.0F,
  orbit_pitch: 0.0F,
  last_mouse_position: None,
  help_text: None,
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
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn normalize_or(value : @math.Vec3, fallback : @math.Vec3) -> @math.Vec3 {
  let normalized = value.normalize_or_zero()
  if normalized.length_squared() <= 0.0000001F {
    fallback
  } else {
    normalized
  }
}

///|
fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
}

///|
fn quat_conjugate(q : @math.Quat) -> @math.Quat {
  @math.Quat::new(-q.x, -q.y, -q.z, q.w)
}

///|
fn reflect_vector(value : @math.Vec3, normal : @math.Vec3) -> @math.Vec3 {
  value.sub(normal.mul_scalar(2.0F * value.dot(normal)))
}

///|
fn reflect_point(
  point : @math.Vec3,
  plane_point : @math.Vec3,
  plane_normal : @math.Vec3,
) -> @math.Vec3 {
  let offset = point.sub(plane_point)
  point.sub(plane_normal.mul_scalar(2.0F * offset.dot(plane_normal)))
}

///|
fn calculate_mirror_camera_transform_and_projection(
  main_camera_transform : @math.Transform,
  main_camera_projection : @render3d.PerspectiveProjection3d,
  mirror_transform : @math.Transform,
) -> (@math.Transform, @render3d.PerspectiveProjection3d) {
  let world_up = @math.Vec3::new(0.0F, 1.0F, 0.0F)
  let forward_axis = @math.Vec3::new(0.0F, 0.0F, -1.0F)
  let negative_world_up = @math.Vec3::new(0.0F, -1.0F, 0.0F)

  let mirror_normal = normalize_or(
    quat_rotate_vec3(mirror_transform.rotation, world_up),
    world_up,
  )
  let reflected_translation = reflect_point(
    main_camera_transform.translation,
    mirror_transform.translation,
    mirror_normal,
  )
  let main_forward = normalize_or(
    quat_rotate_vec3(main_camera_transform.rotation, forward_axis),
    forward_axis,
  )
  let main_up = normalize_or(
    quat_rotate_vec3(main_camera_transform.rotation, world_up),
    world_up,
  )
  let reflected_forward = normalize_or(
    reflect_vector(main_forward, mirror_normal),
    forward_axis,
  )
  let reflected_up = normalize_or(
    reflect_vector(main_up, mirror_normal),
    world_up,
  )
  let reflected_target = reflected_translation.add(reflected_forward)
  let mirror_camera_transform = @math.Transform::from_xyz(
    reflected_translation.x,
    reflected_translation.y,
    reflected_translation.z,
  ).looking_at(reflected_target, reflected_up)

  let distance_from_camera_to_mirror = mirror_transform.translation
    .sub(main_camera_transform.translation)
    .dot(mirror_normal)
  let view_from_world_rotation = quat_conjugate(
    main_camera_transform.rotation.normalize(),
  )
  let mirror_projection_plane_normal = normalize_or(
    quat_rotate_vec3(
      view_from_world_rotation,
      quat_rotate_vec3(mirror_transform.rotation, negative_world_up),
    ),
    forward_axis,
  )
  let mirror_camera_projection = @render3d.PerspectiveProjection3d::{
    ..main_camera_projection,
    near_clip_plane: @math.Vec4::new(
      mirror_projection_plane_normal.x,
      mirror_projection_plane_normal.y,
      mirror_projection_plane_normal.z,
      distance_from_camera_to_mirror,
    ),
  }

  (mirror_camera_transform, mirror_camera_projection)
}

///|
fn orbit_angles_from_translation(translation : @math.Vec3) -> (Float, Float) {
  let horizontal = @math.sqrt(
    translation.x * translation.x + translation.z * translation.z,
  )
  let yaw = @math.atan2(translation.x, translation.z)
  let pitch = @math.atan2(translation.y, horizontal)
  (yaw, pitch)
}

///|
fn camera_target() -> @math.Vec3 {
  @math.Vec3::new(-25.0F, 20.0F, 0.0F)
}

///|
fn set_main_camera_transform_from_orbit(world : @ecs.World) -> Unit {
  if mirror_state.val.main_camera.is_placeholder() {
    return
  }

  let target = camera_target()
  let cos_pitch = @math.cos(mirror_state.val.orbit_pitch)
  let offset_x = @math.sin(mirror_state.val.orbit_yaw) *
    cos_pitch *
    CAMERA_ORBIT_DISTANCE
  let offset_y = @math.sin(mirror_state.val.orbit_pitch) * CAMERA_ORBIT_DISTANCE
  let offset_z = @math.cos(mirror_state.val.orbit_yaw) *
    cos_pitch *
    CAMERA_ORBIT_DISTANCE
  let position = target.add(@math.Vec3::new(offset_x, offset_y, offset_z))

  let transform = @math.Transform::from_xyz(position.x, position.y, position.z).looking_at(
    target,
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )

  world
  .component(@math.ecs_key_transform)
  .set(mirror_state.val.main_camera, transform, world.read_change_tick())
  |> ignore
}

///|
fn create_help_text() -> String {
  let mode = if mirror_state.val.drag_action == DragAction::MoveCamera {
    "camera"
  } else {
    "fox"
  }
  "Click and drag to move the " + mode + "\n1: Move camera\n2: Move fox"
}

///|
fn update_help_text() -> Unit {
  if mirror_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, create_help_text())
  }
}

///|
fn ray_plane_intersection(
  ray_origin : @math.Vec3,
  ray_direction : @math.Vec3,
  plane_point : @math.Vec3,
  plane_normal : @math.Vec3,
) -> @math.Vec3? {
  let denom = plane_normal.dot(ray_direction)
  if absf(denom) <= 0.000001F {
    return None
  }
  let t = plane_point.sub(ray_origin).dot(plane_normal) / denom
  if t < 0.0F {
    return None
  }
  Some(ray_origin.add(ray_direction.mul_scalar(t)))
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  mirror_state.val.main_camera = @core.Entity::placeholder()
  mirror_state.val.mirror_camera = @core.Entity::placeholder()
  mirror_state.val.mirror_plane = @core.Entity::placeholder()
  mirror_state.val.fox = @core.Entity::placeholder()
  mirror_state.val.mirror_material = None
  mirror_state.val.mirror_target_size = @math.IVec2::new(0, 0)
  mirror_state.val.drag_action = DragAction::MoveCamera
  mirror_state.val.orbit_yaw = 0.0F
  mirror_state.val.orbit_pitch = 0.0F
  mirror_state.val.last_mouse_position = None
  mirror_state.val.help_text = None

  let target_width = if @window.window_width() > 1 {
    @window.window_width()
  } else {
    1024
  }
  let target_height = if @window.window_height() > 1 {
    @window.window_height()
  } else {
    1024
  }
  let mirror_target = @sprite.render2d_create_render_target(
    world, target_width, target_height, true,
  )
  mirror_state.val.mirror_target_size = @math.IVec2::new(
    target_width, target_height,
  )

  // Ground (Bevy uses a circle mesh; mgstudio currently uses a large plane).
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(400.0F, 400.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @sprite.Color::new(0.0F, 0.5F, 0.0F, 1.0F),
        ),
      ),
    ),
    @math.Transform::from_xyz(-25.0F, 0.0F, 0.0F).with_rotation(
      @math.Quat::from_rotation_x(-FRAC_PI_2),
    ),
  ).spawn(world)
  |> ignore

  // Fox scene.
  let asset_server = @asset.AssetServer::new()
  let fox = world.spawn_empty()
  world
  .component(@scene.ecs_key_scene_root)
  .insert(
    fox,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @scene.GltfAssetLabel::Scene(0).from_asset(FOX_ASSET_PATH),
      ),
    ),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(fox, @math.Transform::from_xyz(-50.0F, 0.0F, -100.0F), tick)
  mirror_state.val.fox = fox

  // Mirror plane.
  let mirror_transform = @math.Transform::from_xyz(-25.0F, 75.0F, 0.0F).with_rotation(
    @math.Quat::from_rotation_x(-FRAC_PI_2),
  )
  let mirror_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@sprite.Color::black())
    .with_emissive(@sprite.Color::white())
    .with_emissive_texture(Some(mirror_target))
    .with_perceptual_roughness(0.0F)
    .with_metallic(1.0F),
  )
  mirror_state.val.mirror_material = Some(mirror_material)
  let mirror_entity = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(300.0F, 150.0F),
    @render3d.MeshMaterial3d::new(mirror_material),
    mirror_transform,
  ).spawn(world)
  mirror_state.val.mirror_plane = mirror_entity

  // Lighting.
  let light = world.spawn_empty()
  world
  .component(@render3d.ecs_key_directional_light)
  .insert(
    light,
    @render3d.DirectionalLight::new(@sprite.Color::white(), 5000.0F, true),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(
    light,
    @math.Transform::from_xyz(-85.0F, 16.0F, -200.0F).looking_at(
      @math.Vec3::new(-50.0F, 0.0F, 100.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  // Main camera.
  let main_camera_projection = @render3d.PerspectiveProjection3d::default()
  let initial_main_translation = @math.Vec3::new(-2.0F, 1.0F, -2.0F)
    .normalize_or_zero()
    .mul_scalar(CAMERA_ORBIT_DISTANCE)
  let main_camera_transform = @math.Transform::from_xyz(
    initial_main_translation.x,
    initial_main_translation.y,
    initial_main_translation.z,
  ).looking_at(camera_target(), @math.Vec3::new(0.0F, 1.0F, 0.0F))
  let main_camera = @render3d.Camera3dBundle::new_with_projection(
    @sprite.Camera::default(),
    @render3d.Projection::Perspective(main_camera_projection),
    main_camera_transform,
  ).spawn(world)
  mirror_state.val.main_camera = main_camera
  let (initial_yaw, initial_pitch) = orbit_angles_from_translation(
    main_camera_transform.translation.sub(camera_target()),
  )
  mirror_state.val.orbit_yaw = initial_yaw
  mirror_state.val.orbit_pitch = initial_pitch

  // Mirror camera (renders to texture).
  let (mirror_camera_transform, mirror_camera_projection) = calculate_mirror_camera_transform_and_projection(
    main_camera_transform, main_camera_projection, mirror_transform,
  )
  let mirror_camera = @render3d.Camera3dBundle::new_with_projection(
    @sprite.Camera::new(@sprite.Color::black()).with_order(-1),
    @render3d.Projection::Perspective(mirror_camera_projection),
    mirror_camera_transform,
  ).spawn(world)
  world
  .component(@sprite.ecs_key_render_target)
  .insert(mirror_camera, @sprite.RenderTarget::Image(mirror_target), tick)
  mirror_state.val.mirror_camera = mirror_camera

  // Help text.
  let help_text = @text.Text2dBundle::new(
      @text.Text2d::new(create_help_text()),
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
  mirror_state.val.help_text = Some(help_text)
}

///|
fn handle_drag_action_change(_world : @ecs.World) -> Unit {
  let mut changed = false
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    mirror_state.val.drag_action = DragAction::MoveCamera
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    mirror_state.val.drag_action = DragAction::MoveFox
    changed = true
  }
  if changed {
    mirror_state.val.last_mouse_position = None
    update_help_text()
  }
}

///|
fn move_camera_on_mouse_down(world : @ecs.World) -> Unit {
  if mirror_state.val.drag_action != DragAction::MoveCamera ||
    !@input.mouse_button_pressed(@window.MouseButton::Left) {
    mirror_state.val.last_mouse_position = None
    return
  }
  guard @input.mouse_position() is Some(current_mouse_pos) else {
    mirror_state.val.last_mouse_position = None
    return
  }

  let delta = if mirror_state.val.last_mouse_position is Some(last_mouse_pos) {
    current_mouse_pos.sub(last_mouse_pos)
  } else {
    @math.Vec2::new(0.0F, 0.0F)
  }
  mirror_state.val.last_mouse_position = Some(current_mouse_pos)
  if delta.x == 0.0F && delta.y == 0.0F {
    return
  }

  mirror_state.val.orbit_pitch = clampf(
    mirror_state.val.orbit_pitch + delta.y * CAMERA_PITCH_SPEED,
    -CAMERA_PITCH_LIMIT,
    CAMERA_PITCH_LIMIT,
  )
  mirror_state.val.orbit_yaw = mirror_state.val.orbit_yaw +
    delta.x * CAMERA_YAW_SPEED
  set_main_camera_transform_from_orbit(world)
}

///|
fn move_fox_on_mouse_down(world : @ecs.World) -> Unit {
  if mirror_state.val.drag_action != DragAction::MoveFox ||
    !@input.mouse_button_pressed(@window.MouseButton::Left) ||
    mirror_state.val.fox.is_placeholder() ||
    mirror_state.val.main_camera.is_placeholder() {
    return
  }

  guard @input.mouse_position() is Some(screen_pos) else { return }
  let transform_store = world.component(@math.ecs_key_transform)
  let camera_store = world.component(@sprite.ecs_key_camera)
  let projection_store = world.component(@render3d.ecs_key_projection)

  guard transform_store.get(mirror_state.val.main_camera)
    is Some(camera_transform) else {
    return
  }
  guard camera_store.get(mirror_state.val.main_camera) is Some(camera) else {
    return
  }
  guard projection_store.get(mirror_state.val.main_camera) is Some(projection) else {
    return
  }

  let target_size = @math.IVec2::new(
    @window.window_width(),
    @window.window_height(),
  )
  let scale_factor = @window.window_scale_factor()
  guard @render3d.render3d_camera_viewport_to_world_ray(
      screen_pos, camera, projection, camera_transform, target_size, scale_factor,
    )
    is Some((ray_origin, ray_dir)) else {
    return
  }

  guard ray_plane_intersection(
      ray_origin,
      ray_dir,
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    )
    is Some(hit) else {
    return
  }

  let tick = world.read_change_tick()
  if transform_store.get(mirror_state.val.fox) is Some(fox_transform) {
    transform_store.set(
      mirror_state.val.fox,
      fox_transform.with_translation(
        @math.Vec3::new(hit.x, fox_transform.translation.y, hit.z),
      ),
      tick,
    )
    |> ignore
  }
}

///|
fn handle_window_resize_messages(world : @ecs.World) -> Unit {
  if mirror_state.val.mirror_camera.is_placeholder() {
    return
  }

  let width = @window.window_width()
  let height = @window.window_height()
  if width <= 1 || height <= 1 {
    return
  }

  let size = @math.IVec2::new(width, height)
  if size.x == mirror_state.val.mirror_target_size.x &&
    size.y == mirror_state.val.mirror_target_size.y {
    return
  }

  let mirror_target = @sprite.render2d_create_render_target(
    world, width, height, true,
  )
  mirror_state.val.mirror_target_size = size

  let tick = world.read_change_tick()
  let target_store = world.component(@sprite.ecs_key_render_target)
  if target_store.contains(mirror_state.val.mirror_camera) {
    target_store.set(
      mirror_state.val.mirror_camera,
      @sprite.RenderTarget::Image(mirror_target),
      tick,
    )
    |> ignore
  } else {
    target_store.insert(
      mirror_state.val.mirror_camera,
      @sprite.RenderTarget::Image(mirror_target),
      tick,
    )
  }

  if mirror_state.val.mirror_material is Some(material_handle) {
    if @render3d.standard_material_get(material_handle) is Some(material) {
      @render3d.standard_material_set(
        material_handle,
        material.with_emissive_texture(Some(mirror_target)),
      )
      |> ignore
    }
  }
}

///|
fn update_mirror_camera_on_main_camera_transform_change(
  world : @ecs.World,
) -> Unit {
  if mirror_state.val.main_camera.is_placeholder() ||
    mirror_state.val.mirror_camera.is_placeholder() ||
    mirror_state.val.mirror_plane.is_placeholder() {
    return
  }

  let transform_store = world.component(@math.ecs_key_transform)
  guard transform_store.get(mirror_state.val.main_camera)
    is Some(main_camera_transform) else {
    return
  }
  guard transform_store.get(mirror_state.val.mirror_plane)
    is Some(mirror_transform) else {
    return
  }

  let projection_store = world.component(@render3d.ecs_key_projection)
  guard projection_store.get(mirror_state.val.main_camera)
    is Some(main_camera_projection_component) else {
    return
  }
  guard main_camera_projection_component is Perspective(main_projection) else {
    return
  }

  let (mirror_camera_transform, mirror_camera_projection) = calculate_mirror_camera_transform_and_projection(
    main_camera_transform, main_projection, mirror_transform,
  )

  let tick = world.read_change_tick()
  transform_store.set(
    mirror_state.val.mirror_camera,
    mirror_camera_transform,
    tick,
  )
  |> ignore
  projection_store.set(
    mirror_state.val.mirror_camera,
    @render3d.Projection::Perspective(mirror_camera_projection),
    tick,
  )
  |> ignore
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(handle_window_resize_messages))
  .add_systems(@app.Update, @app.system(handle_drag_action_change))
  .add_systems(@app.Update, @app.system(move_camera_on_mouse_down))
  .add_systems(@app.Update, @app.system(move_fox_on_mouse_down))
  .add_systems(
    @app.Update,
    @app.system(update_mirror_camera_on_main_camera_transform_change),
  )
  .run()
}
