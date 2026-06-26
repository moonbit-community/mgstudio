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
/// Demonstrates clustered decals, which affix decals to surfaces.

///|
const SHADER_ASSET_PATH : String = "shaders/custom_clustered_decal.wgsl"

///|
const CUBE_ROTATION_SPEED : Float = 0.02F

///|
const PI : Float = 3.141592653589793F

///|
const FRAC_PI_3 : Float = 1.0471975511965976F

///|
const MOVE_SPEED : Float = 0.008F

///|
const SCALE_SPEED : Float = 0.05F

///|
const ROLL_SPEED : Float = 0.01F

///|
fn color_lime() -> @color.Color {
  @color.Color::srgb(0.0F, 1.0F, 0.0F)
}

///|
fn color_orange_red() -> @color.Color {
  @color.Color::srgb(1.0F, 0.27058825F, 0.0F)
}

///|
fn color_silver() -> @color.Color {
  @color.Color::srgb(0.7529412F, 0.7529412F, 0.7529412F)
}

///|
pub(all) enum Selection {
  Camera
  DecalA
  DecalB
} derive(Eq, Debug)

///|
pub impl Default for Selection with fn default() {
  Selection::Camera
}

///|
pub(all) enum DragMode {
  Move
  Scale
  Roll
} derive(Eq, Debug)

///|
pub impl Default for DragMode with fn default() {
  DragMode::Move
}

///|
priv struct AppStatus {
  mut selection : Selection
  mut drag_mode : DragMode
}

///|
fn AppStatus::AppStatus() -> AppStatus {
  AppStatus::{ selection: Selection::Camera, drag_mode: DragMode::Move }
}

///|
let app_status_resource_key : @ecs.ResourceKey[AppStatus] = @ecs.register_resource(
  debug_name="examples.3d.clustered_decals.AppStatus",
)

///|
impl @app.Resource for AppStatus with fn resource() {
  app_status_resource_key
}

///|
let selection_component_key : @ecs.ComponentKey[Selection] = @ecs.register_component(
  debug_name="examples.3d.clustered_decals.Selection",
)

///|
impl @ecs.Component for Selection with fn component() {
  selection_component_key
}

///|
impl @widgets_lib.WidgetValue for Selection with fn widget_debug_name() {
  "examples.3d.clustered_decals.Selection"
}

///|
let selection_widget_click_event_key : @ecs.MessageKey[
  @widgets_lib.WidgetClickEvent[Selection],
] = @ecs.register_message(
  debug_name="examples.helpers.widgets_lib.WidgetClickEvent<examples.3d.clustered_decals.Selection>",
)

///|
impl @widgets_lib.WidgetValue for Selection with fn widget_click_event_key() {
  selection_widget_click_event_key
}

///|
let selection_widget_click_sender_key : @ecs.ComponentKey[
  @widgets_lib.WidgetClickSender[Selection],
] = @ecs.register_component(
  debug_name="examples.helpers.widgets_lib.WidgetClickSender<examples.3d.clustered_decals.Selection>",
)

///|
impl @widgets_lib.WidgetValue for Selection with fn widget_click_sender_key() {
  selection_widget_click_sender_key
}

///|
let drag_mode_component_key : @ecs.ComponentKey[DragMode] = @ecs.register_component(
  debug_name="examples.3d.clustered_decals.DragMode",
)

///|
impl @ecs.Component for DragMode with fn component() {
  drag_mode_component_key
}

///|
priv struct HelpText {}

///|
let help_text_component_key : @ecs.ComponentKey[HelpText] = @ecs.register_component(
  debug_name="examples.3d.clustered_decals.HelpText",
)

///|
impl @ecs.Component for HelpText with fn component() {
  help_text_component_key
}

///|
pub(all) struct CustomDecalExtension {}

///|
fn CustomDecalExtension::CustomDecalExtension() -> CustomDecalExtension {
  CustomDecalExtension::{  }
}

///|
pub impl @pbr.MaterialExtension for CustomDecalExtension with fn extension_tag(
  _self,
) {
  106
}

///|
pub impl @pbr.MaterialExtension for CustomDecalExtension with fn vertex_shader(
  _self,
) {
  None
}

///|
pub impl @pbr.MaterialExtension for CustomDecalExtension with fn fragment_shader(
  _self,
) {
  Some(SHADER_ASSET_PATH)
}

///|
pub impl @pbr.MaterialExtension for CustomDecalExtension with fn prepass_vertex_shader(
  _self,
) {
  None
}

///|
pub impl @pbr.MaterialExtension for CustomDecalExtension with fn prepass_fragment_shader(
  _self,
) {
  None
}

///|
pub impl @pbr.MaterialExtension for CustomDecalExtension with fn deferred_vertex_shader(
  _self,
) {
  None
}

///|
pub impl @pbr.MaterialExtension for CustomDecalExtension with fn deferred_fragment_shader(
  _self,
) {
  None
}

///|
pub impl @pbr.MaterialExtension for CustomDecalExtension with fn alpha_mode(
  _self,
) {
  None
}

///|
pub impl @pbr.MaterialExtension for CustomDecalExtension with fn opaque_render_method(
  _self,
) {
  None
}

///|
pub impl @pbr.MaterialExtension for CustomDecalExtension with fn enable_prepass(
  _self,
) {
  true
}

///|
pub impl @pbr.MaterialExtension for CustomDecalExtension with fn enable_shadows(
  _self,
) {
  true
}

///|
pub impl @pbr.MaterialExtension for CustomDecalExtension with fn specialize(
  _self,
) {
  None
}

///|
pub impl @pbr.MaterialExtension for CustomDecalExtension with fn bind_group_layout_entries(
  _self,
) {
  []
}

///|
pub impl @pbr.MaterialExtension for CustomDecalExtension with fn bind_group_bindings(
  _self,
) {
  []
}

///|
fn selection_text(selection : Selection) -> String {
  match selection {
    Selection::Camera => "camera"
    Selection::DecalA => "decal A"
    Selection::DecalB => "decal B"
  }
}

///|
fn drag_mode_text(mode : DragMode) -> String {
  match mode {
    DragMode::Move => "move"
    DragMode::Scale => "scale"
    DragMode::Roll => "roll"
  }
}

///|
fn create_help_string(app_status : AppStatus) -> String {
  "Click and drag to \{drag_mode_text(app_status.drag_mode)} \{selection_text(app_status.selection)}"
}

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::Window()
  window.title = "Mgstudio Clustered Decals Example"
  window
}

///|
fn clustered_decals_are_usable() -> Bool {
  @render.host_gpu_mesh3d_binding_arrays_are_usable(
    required_storage_textures_per_shader_stage=0U,
  )
}

///|
fn spawn_cube(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let transform = @transform.Transform::identity()
  transform.rotate_y(FRAC_PI_3)
  let material = @pbr.StandardMaterial::from_color(color_silver())
  let material_handle = materials.peek().add(material)
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(
          meshes.peek() |> @pbr.add_mesh(@math.Cuboid::new(3.0F, 3.0F, 3.0F)),
        ),
        @pbr.MeshMaterial3d::new(material_handle).with_extended_material(
          Some(
            @pbr.ExtendedMaterial::new(
              material,
              CustomDecalExtension::CustomDecalExtension(),
            ).metadata(),
          ),
        ),
        transform,
      ),
    ),
  )
}

///|
fn spawn_light(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::DirectionalLight(),
        @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn spawn_camera(commands : @app.Commands) -> Unit {
  let camera = commands.spawn_component(@camera.Camera3d::Camera3d())
  commands
  .entity(camera)
  .insert(
    (
      @transform.Transform::from_xyz(0.0F, 2.5F, 9.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
      Selection::Camera,
    ),
  )
}

///|
fn calculate_initial_decal_transform(
  start : @math.Vec3,
  looking_at : @math.Vec3,
  size : @math.Vec2,
) -> @transform.Transform {
  let direction = looking_at.sub(start)
  let center = start.add(direction.mul_scalar(0.5F))
  @transform.Transform::from_xyz(center.x, center.y, center.z)
  .with_scale(@math.Vec3::new(size.x * 0.5F, size.y * 0.5F, direction.length()))
  .looking_to(direction, @math.Vec3::new(0.0F, 1.0F, 0.0F))
}

///|
fn spawn_decals(
  commands : @app.Commands,
  asset_server : @asset.AssetServer,
) -> Unit {
  let base_color_texture = asset_server.load("branding/icon.png")
  ignore(
    commands.spawn(
      (
        @pbr.ClusteredDecal::ClusteredDecal()
        .with_base_color_texture(Some(base_color_texture))
        .with_tag(1U),
        calculate_initial_decal_transform(
          @math.Vec3::new(1.0F, 3.0F, 5.0F),
          @math.Vec3::zero(),
          @math.Vec2::splat(1.1F),
        ),
        Selection::DecalA,
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.ClusteredDecal::ClusteredDecal()
        .with_base_color_texture(Some(base_color_texture))
        .with_tag(2U),
        calculate_initial_decal_transform(
          @math.Vec3::new(-2.0F, -1.0F, 4.0F),
          @math.Vec3::zero(),
          @math.Vec2::splat(2.0F),
        ),
        Selection::DecalB,
      ),
    ),
  )
}

///|
fn drag_button(
  commands : @app.Commands,
  parent : @core.Entity,
  label : String,
  mode : DragMode,
) -> @core.Entity {
  let (text, text_font, text_color) = @widgets_lib.ui_text(
    label,
    @color.Color::white(),
  )
  let button = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @ui.Node::Node()
      .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F)))
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center)
      .with_padding(
        @ui.UiRect::new(
          @ui.Val::Px(12.0F),
          @ui.Val::Px(6.0F),
          @ui.Val::Px(12.0F),
          @ui.Val::Px(6.0F),
        ),
      )
      .with_border_radius(@ui.BorderRadius::all(@ui.Val::Px(6.0F))),
      @ui.Button::Button(),
      @ui.BackgroundColor::new(@color.Color::black()),
      @ui.BorderColor::new(@color.Color::white()),
      mode,
    ),
  )
  ignore(
    commands.spawn(
      (@hierarchy.Parent::new(button), text, text_font, text_color),
    ),
  )
  button
}

///|
fn spawn_buttons(commands : @app.Commands) -> Unit {
  let panel = commands.spawn_component(@widgets_lib.main_ui_node())
  ignore(
    @widgets_lib.spawn_option_buttons(commands, panel, "Drag to Move", [
      (Selection::Camera, "Camera"),
      (Selection::DecalA, "Decal A"),
      (Selection::DecalB, "Decal B"),
    ]),
  )
  let drag_panel = commands.spawn_component(
    @ui.Node::Node()
    .with_flex_direction(@ui.FlexDirection::Row)
    .with_position_type(@ui.PositionType::Absolute)
    .with_right(@ui.Val::Px(10.0F))
    .with_bottom(@ui.Val::Px(10.0F))
    .with_column_gap(@ui.Val::Px(6.0F)),
  )
  ignore(drag_button(commands, drag_panel, "Scale", DragMode::Scale))
  ignore(drag_button(commands, drag_panel, "Roll", DragMode::Roll))
}

///|
fn spawn_help_text(commands : @app.Commands, app_status : AppStatus) -> Unit {
  ignore(
    commands.spawn(
      (
        @text.Text::new(create_help_string(app_status)),
        @ui.Node::Node()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.Val::Px(12.0F))
        .with_left(@ui.Val::Px(12.0F)),
        HelpText::{  },
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  app_status : @app.Res[AppStatus],
  app_exit : @ecs.MessageWriter[@app.AppExit],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  if !clustered_decals_are_usable() {
    ignore(app_exit.write(@app.AppExit::error()))
    return
  }
  let asset_server = asset_server.get()
  spawn_cube(commands, meshes, materials)
  spawn_camera(commands)
  spawn_light(commands)
  spawn_decals(commands, asset_server)
  spawn_buttons(commands)
  spawn_help_text(commands, app_status.get())
}

///|
fn draw_gizmos(
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
  decals : @ecs.Query[
    (@ecs.Read[@transform.GlobalTransform], @ecs.Read[Selection]),
    @ecs.With[@pbr.ClusteredDecal],
  ],
) -> Unit {
  try! decals.view(fn(_entity, data) {
    let (global_transform, selection) = data
    let color = match selection.value() {
      Selection::Camera => return
      Selection::DecalA => color_orange_red()
      Selection::DecalB => color_lime()
    }
    let transform = global_transform.value().to_transform_approx()
    gizmos.cuboid_3d(transform, transform.scale, color)
  })
}

///|
fn rotate_cube(
  meshes : @ecs.Query[@ecs.Write[@transform.Transform], @ecs.With[@mesh.Mesh3d]],
) -> Unit {
  try! meshes.view(fn(_entity, transform) {
    let next = transform.value()
    next.rotate_y(CUBE_ROTATION_SPEED)
    transform.set(next)
  })
}

///|
fn handle_ui_interactions(
  interactions : @ecs.Query[
    (
      @ecs.Read[@ui.Interaction],
      @ecs.Read[@widgets_lib.WidgetClickSender[Selection]],
    ),
    @ecs.With[@ui.Button],
  ],
  widget_click_events : @ecs.MessageWriter[
    @widgets_lib.WidgetClickEvent[Selection],
  ],
) -> Unit {
  @widgets_lib.handle_ui_interactions(interactions, widget_click_events)
}

///|
fn update_radio_buttons(
  radio_buttons : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[Selection]],
      @ecs.Write[@ui.BackgroundColor],
    ),
    @ecs.With[@widgets_lib.RadioButton],
  ],
  radio_button_texts : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[Selection]],
      @ecs.Write[@text.TextColor],
    ),
    @ecs.With[@widgets_lib.RadioButtonText],
  ],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let status = app_status.get()
  try! radio_buttons.view(fn(_entity, data) {
    let (sender, background_color) = data
    @widgets_lib.update_ui_radio_button(
      background_color,
      status.selection == sender.value().get(),
    )
  })
  try! radio_button_texts.view(fn(_entity, data) {
    let (sender, text_color) = data
    @widgets_lib.update_ui_radio_button_text(
      text_color,
      status.selection == sender.value().get(),
    )
  })
}

///|
fn handle_selection_change(
  events : @ecs.MessageReader[@widgets_lib.WidgetClickEvent[Selection]],
  app_status : @app.ResMut[AppStatus],
) -> Unit {
  app_status.modify(fn(status) {
    for event in events.read() {
      status.selection = event.get()
    }
  })
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
fn signum(value : Float) -> Float {
  if value < 0.0F {
    -1.0F
  } else {
    1.0F
  }
}

///|
fn selection_move_factors(selection : Selection) -> (Float, Float) {
  match selection {
    Selection::Camera => (1.0F, -1.0F)
    Selection::DecalA | Selection::DecalB => (-1.0F, 1.0F)
  }
}

///|
fn move_selection_transform(
  transform : @transform.Transform,
  selection : Selection,
  delta : @math.Vec2,
) -> @transform.Transform {
  let position = transform.translation
  let radius = position.length()
  let horizontal = @math.sqrt(position.x * position.x + position.z * position.z)
  let mut theta = @math.acos(position.y / radius)
  let mut phi = signum(position.z) * @math.acos(position.x / horizontal)
  let (phi_factor, theta_factor) = selection_move_factors(selection)
  phi = phi + phi_factor * delta.x * MOVE_SPEED
  theta = clampf(
    theta + theta_factor * delta.y * MOVE_SPEED,
    0.001F,
    PI - 0.001F,
  )
  let translation = @math.Vec3::new(
    radius * @math.sin(theta) * @math.cos(phi),
    radius * @math.cos(theta),
    radius * @math.sin(theta) * @math.sin(phi),
  )
  let (_, _, roll) = transform.rotation.to_euler(@math.EulerRot::YXZ)
  let oriented = transform
    .with_translation(translation)
    .looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F))
  let (yaw, pitch, _) = oriented.rotation.to_euler(@math.EulerRot::YXZ)
  oriented.with_rotation(
    @math.Quat::from_euler(@math.EulerRot::YXZ, yaw, pitch, roll),
  )
}

///|
fn process_move_input(
  selections : @ecs.Query[
    (@ecs.Write[@transform.Transform], @ecs.Read[Selection]),
    @ecs.All,
  ],
  mouse_buttons : @input.ButtonInput[@window.MouseButton],
  mouse_motion : @app.Res[@input.AccumulatedMouseMotion],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let status = app_status.get()
  if !mouse_buttons.pressed(@window.MouseButton::Left) ||
    status.drag_mode != DragMode::Move {
    return
  }
  let delta = mouse_motion.get().delta
  try! selections.view(fn(_entity, data) {
    let (transform, selection) = data
    let selection = selection.value()
    if status.selection != selection {
      return
    }
    transform.set(move_selection_transform(transform.value(), selection, delta))
  })
}

///|
fn process_scale_input(
  selections : @ecs.Query[
    (@ecs.Write[@transform.Transform], @ecs.Read[Selection]),
    @ecs.All,
  ],
  mouse_buttons : @input.ButtonInput[@window.MouseButton],
  mouse_motion : @app.Res[@input.AccumulatedMouseMotion],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let status = app_status.get()
  if !mouse_buttons.pressed(@window.MouseButton::Left) ||
    status.drag_mode != DragMode::Scale {
    return
  }
  let delta = mouse_motion.get().delta
  try! selections.view(fn(_entity, data) {
    let (transform, selection) = data
    if status.selection == selection.value() {
      let value = transform.value()
      transform.set(
        value.with_scale(value.scale.mul_scalar(1.0F + delta.x * SCALE_SPEED)),
      )
    }
  })
}

///|
fn process_roll_input(
  selections : @ecs.Query[
    (@ecs.Write[@transform.Transform], @ecs.Read[Selection]),
    @ecs.All,
  ],
  mouse_buttons : @input.ButtonInput[@window.MouseButton],
  mouse_motion : @app.Res[@input.AccumulatedMouseMotion],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let status = app_status.get()
  if !mouse_buttons.pressed(@window.MouseButton::Left) ||
    status.drag_mode != DragMode::Roll {
    return
  }
  let delta = mouse_motion.get().delta
  try! selections.view(fn(_entity, data) {
    let (transform, selection) = data
    if status.selection != selection.value() {
      return
    }
    let (yaw, pitch, roll) = transform.value().rotation.to_euler(
      @math.EulerRot::YXZ,
    )
    transform.set(
      transform
      .value()
      .with_rotation(
        @math.Quat::from_euler(
          @math.EulerRot::YXZ,
          yaw,
          pitch,
          roll + delta.x * ROLL_SPEED,
        ),
      ),
    )
  })
}

///|
fn switch_drag_mode(
  commands : @app.Commands,
  interactions : @ecs.Query[
    (@ecs.Read[@ui.Interaction], @ecs.Read[DragMode]),
    @ecs.All,
  ],
  windows : @ecs.Query[@core.Entity, @ecs.With[@window.Window]],
  mouse_buttons : @input.ButtonInput[@window.MouseButton],
  app_status : @app.ResMut[AppStatus],
) -> Unit {
  if mouse_buttons.pressed(@window.MouseButton::Left) {
    return
  }
  let mut hovered_mode : DragMode? = None
  try! interactions.view(fn(_entity, data) {
    let (interaction, drag_mode) = data
    if interaction.value() == @ui.Interaction::Hovered {
      hovered_mode = Some(drag_mode.value())
    }
  })
  app_status.modify(fn(status) {
    match hovered_mode {
      Some(mode) => status.drag_mode = mode
      None => status.drag_mode = DragMode::Move
    }
  })
  try! windows.view(fn(_query_entity, window_entity) {
    match hovered_mode {
      Some(_) =>
        commands
        .entity(window_entity)
        .insert_component(
          @window.CursorIcon::from(@window.SystemCursorIcon::EwResize),
        )
      None =>
        commands
        .entity(window_entity)
        .remove_component(@window.ecs_key_cursor_icon)
    }
  })
}

///|
fn update_help_text(
  help_text : @ecs.Query[@ecs.Write[@text.Text], @ecs.With[HelpText]],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let next = create_help_string(app_status.get())
  try! help_text.view(fn(_entity, text) { text.set(@text.Text::new(next)) })
}

///|
fn update_button_visibility(
  nodes : @ecs.Query[@ecs.Write[@visibility.Visibility], @ecs.With[DragMode]],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let visible = match app_status.get().selection {
    Selection::Camera => @visibility.Visibility::Hidden
    Selection::DecalA | Selection::DecalB => @visibility.Visibility::Visible
  }
  try! nodes.view(fn(_entity, visibility) { visibility.set(visible) })
}

///|
fn main {
  let widget_click_message_key : @ecs.MessageKey[
    @widgets_lib.WidgetClickEvent[Selection],
  ] = @widgets_lib.widget_click_event_key()
  @app.App::new(@ecs.World::new())
  .add_plugins(
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(configured_window()),
      primary_cursor_options: None,
      exit_condition: @window.ExitCondition::OnAllClosed,
      close_when_requested: true,
    }),
  )
  .init_resource(fn() { AppStatus::AppStatus() })
  .add_message(widget_click_message_key)
  .add_systems_param6(@app.Startup, setup)
  .add_systems_param2(@app.Update, draw_gizmos)
  .add_systems_param(@app.Update, rotate_cube)
  .add_systems_param2(@app.Update, handle_ui_interactions)
  .add_systems_param2(@app.Update, handle_selection_change)
  .add_systems_param3(@app.Update, update_radio_buttons)
  .add_systems_param4(@app.Update, process_move_input)
  .add_systems_param4(@app.Update, process_scale_input)
  .add_systems_param4(@app.Update, process_roll_input)
  .add_systems_param5(@app.Update, switch_drag_mode)
  .add_systems_param2(@app.Update, update_help_text)
  .add_systems_param2(@app.Update, update_button_visibility)
  .run()
}
