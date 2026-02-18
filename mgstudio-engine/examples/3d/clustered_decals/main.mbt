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
/// Port of `bevy/examples/3d/clustered_decals.rs`.
///
/// Baseline parity:
/// - Bevy `ClusteredDecal` and custom decal-extension shader path are not yet
///   exposed in mgstudio.
/// - This port preserves Bevy's control model (selection + drag mode) and
///   scene layout, mapping decals onto textured translucent proxy meshes.

///|
const CUBE_ROTATION_SPEED : Float = 0.9F

///|
const MOVE_SPEED : Float = 0.01F

///|
const SCALE_SPEED : Float = 0.01F

///|
const ROLL_SPEED : Float = 0.01F

///|
pub(all) enum Selection {
  Camera
  DecalA
  DecalB
} derive(Eq, Show)

///|
pub(all) enum DragMode {
  Move
  Scale
  Roll
} derive(Eq, Show)

///|
priv struct ClusteredDecalsState {
  mut camera : @core.Entity?
  mut rotating_cube : @core.Entity?
  mut selection : Selection
  mut drag_mode : DragMode
  mut decal_a : @core.Entity?
  mut decal_b : @core.Entity?
  mut help_text : @text.TextHandle?
  mut last_mouse : @math.Vec2?
}

///|
let clustered_decals_state : Ref[ClusteredDecalsState] = Ref::new({
  camera: None,
  rotating_cube: None,
  selection: Selection::Camera,
  drag_mode: DragMode::Move,
  decal_a: None,
  decal_b: None,
  help_text: None,
  last_mouse: None,
})

///|
fn selection_text(selection : Selection) -> String {
  match selection {
    Selection::Camera => "Camera"
    Selection::DecalA => "Decal A"
    Selection::DecalB => "Decal B"
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
fn help_text_content() -> String {
  "Clustered Decals (Bevy-aligned controls)\n" +
  "1/2/3: Selection (" +
  selection_text(clustered_decals_state.val.selection) +
  ")\n" +
  "M/S/R: Drag Mode (" +
  drag_mode_text(clustered_decals_state.val.drag_mode) +
  ")\n" +
  "Drag Left Mouse: apply mode to selection\n"
}

///|
fn update_help_text() -> Unit {
  if clustered_decals_state.val.help_text is Some(help_text) {
    @text.text_set_content(help_text, help_text_content())
  }
}

///|
fn calculate_initial_decal_transform(
  position : @math.Vec3,
  target : @math.Vec3,
  scale_xy : @math.Vec2,
) -> @math.Transform {
  @math.Transform::from_xyz(position.x, position.y, position.z)
  .looking_at(target, @math.Vec3::new(0.0F, 1.0F, 0.0F))
  .with_scale(@math.Vec3::new(scale_xy.x, scale_xy.y, 0.20F))
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let asset_server = @asset.AssetServer::new()
  clustered_decals_state.val.camera = None
  clustered_decals_state.val.rotating_cube = None
  clustered_decals_state.val.selection = Selection::Camera
  clustered_decals_state.val.drag_mode = DragMode::Move
  clustered_decals_state.val.decal_a = None
  clustered_decals_state.val.decal_b = None
  clustered_decals_state.val.help_text = None
  clustered_decals_state.val.last_mouse = None

  let cube_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.75F, 0.75F, 0.75F, 1.0F),
    ),
  )
  let cube = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(3.0F, 3.0F, 3.0F),
    @render3d.MeshMaterial3d::new(cube_material),
    @math.Transform::from_xyz(0.0F, 0.0F, 0.0F).with_rotation(
      @math.Quat::from_rotation_y(1.0471975512F),
    ),
  ).spawn(world)
  clustered_decals_state.val.rotating_cube = Some(cube)

  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.0F, 2.5F, 9.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  clustered_decals_state.val.camera = Some(camera)

  let light = world.spawn_empty()
  world
  .get_directional_light_store()
  .insert(
    light,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 18_000.0F, true),
    tick,
  )
  world
  .get_transform_store()
  .insert(
    light,
    @math.Transform::from_xyz(4.0F, 8.0F, 4.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  let decal_texture = asset_server.load("branding/icon.png")
  let decal_a_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(1.0F, 0.27F, 0.0F, 0.80F),
    )
    .with_base_color_texture(Some(decal_texture))
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_unlit(true),
  )
  let decal_b_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.0F, 1.0F, 0.0F, 0.80F),
    )
    .with_base_color_texture(Some(decal_texture))
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_unlit(true),
  )

  let decal_a = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(decal_a_material),
    calculate_initial_decal_transform(
      @math.Vec3::new(1.0F, 3.0F, 5.0F),
      @math.Vec3::zero(),
      @math.Vec2::new(1.1F, 1.1F),
    ),
  ).spawn(world)
  clustered_decals_state.val.decal_a = Some(decal_a)

  let decal_b = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(decal_b_material),
    calculate_initial_decal_transform(
      @math.Vec3::new(-2.0F, -1.0F, 4.0F),
      @math.Vec3::zero(),
      @math.Vec2::new(2.0F, 2.0F),
    ),
  ).spawn(world)
  clustered_decals_state.val.decal_b = Some(decal_b)

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
  clustered_decals_state.val.help_text = Some(help_text)
  update_help_text()
}

///|
fn selected_entity() -> @core.Entity? {
  match clustered_decals_state.val.selection {
    Selection::Camera => clustered_decals_state.val.camera
    Selection::DecalA => clustered_decals_state.val.decal_a
    Selection::DecalB => clustered_decals_state.val.decal_b
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
fn apply_camera_drag(
  world : @ecs_world.World,
  camera_entity : @core.Entity,
  delta : @math.Vec2,
) -> Unit {
  let tick = world.read_change_tick()
  guard world.get_transform_store().get(camera_entity) is Some(transform) else {
    return
  }
  let next_translation = transform.translation.add(
    @math.Vec3::new(-delta.x * MOVE_SPEED, delta.y * MOVE_SPEED, 0.0F),
  )
  world
  .get_transform_store()
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
fn apply_decal_drag(
  world : @ecs_world.World,
  entity : @core.Entity,
  delta : @math.Vec2,
) -> Unit {
  let tick = world.read_change_tick()
  guard world.get_transform_store().get(entity) is Some(transform) else {
    return
  }
  match clustered_decals_state.val.drag_mode {
    DragMode::Move => {
      let next_translation = transform.translation.add(
        @math.Vec3::new(delta.x * MOVE_SPEED, -delta.y * MOVE_SPEED, 0.0F),
      )
      world
      .get_transform_store()
      .set(entity, transform.with_translation(next_translation), tick)
      |> ignore
    }
    DragMode::Scale => {
      let next = maxf(0.20F, transform.scale.x + delta.y * SCALE_SPEED)
      world
      .get_transform_store()
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
      .get_transform_store()
      .set(entity, transform.with_rotation(rotation), tick)
      |> ignore
    }
  }
}

///|
fn controls(world : @ecs_world.World) -> Unit {
  let mut changed = false
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    clustered_decals_state.val.selection = Selection::Camera
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    clustered_decals_state.val.selection = Selection::DecalA
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit3) {
    clustered_decals_state.val.selection = Selection::DecalB
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyM) {
    clustered_decals_state.val.drag_mode = DragMode::Move
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyS) {
    clustered_decals_state.val.drag_mode = DragMode::Scale
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyR) {
    clustered_decals_state.val.drag_mode = DragMode::Roll
    changed = true
  }
  if changed {
    update_help_text()
  }

  if @input.mouse_button_just_pressed(@window.MouseButton::Left) {
    clustered_decals_state.val.last_mouse = @input.mouse_position()
  }
  if @input.mouse_button_just_released(@window.MouseButton::Left) {
    clustered_decals_state.val.last_mouse = None
  }
  if !@input.mouse_button_pressed(@window.MouseButton::Left) {
    return
  }
  guard @input.mouse_position() is Some(current_mouse) else { return }
  guard clustered_decals_state.val.last_mouse is Some(previous_mouse) else {
    clustered_decals_state.val.last_mouse = Some(current_mouse)
    return
  }
  let delta = current_mouse.sub(previous_mouse)
  clustered_decals_state.val.last_mouse = Some(current_mouse)
  guard selected_entity() is Some(entity) else { return }
  if clustered_decals_state.val.selection == Selection::Camera {
    apply_camera_drag(world, entity, delta)
  } else {
    apply_decal_drag(world, entity, delta)
  }
}

///|
fn rotate_cube(world : @ecs_world.World) -> Unit {
  guard clustered_decals_state.val.rotating_cube is Some(cube_entity) else {
    return
  }
  guard world.get_transform_store().get(cube_entity) is Some(transform) else {
    return
  }
  let tick = world.read_change_tick()
  let delta = @time.time_delta_seconds()
  let rotation = transform.rotation
    .mul(@math.Quat::from_rotation_y(CUBE_ROTATION_SPEED * delta))
    .normalize()
  world
  .get_transform_store()
  .set(cube_entity, transform.with_rotation(rotation), tick)
  |> ignore
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(controls)
  .add_system(rotate_cube)
  .run()
}
