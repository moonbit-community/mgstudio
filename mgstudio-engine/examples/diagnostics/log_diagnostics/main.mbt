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
pub(all) enum LogDiagnosticsStatus {
  Disabled
  Enabled
}

///|
struct LogDiagnosticsFilters {
  mut frame_time : Bool
  mut entity_count : Bool
  mut system_info : Bool
  render_diagnostics : Bool
}

///|
struct LogDiagnosticsCommandsText {
  entity : @text.TextHandle
}

///|
let log_diagnostics_status_resource_key : @ecs.ResourceKey[LogDiagnosticsStatus] = @ecs.register_resource(
  debug_name="examples.diagnostics.log_diagnostics.LogDiagnosticsStatus",
)

///|
let log_diagnostics_filters_resource_key : @ecs.ResourceKey[
  LogDiagnosticsFilters,
] = @ecs.register_resource(
  debug_name="examples.diagnostics.log_diagnostics.LogDiagnosticsFilters",
)

///|
let log_diagnostics_commands_text_resource_key : @ecs.ResourceKey[
  LogDiagnosticsCommandsText,
] = @ecs.register_resource(
  debug_name="examples.diagnostics.log_diagnostics.LogDiagnosticsCommandsText",
)

///|
pub impl @app.Resource for LogDiagnosticsStatus with resource() {
  log_diagnostics_status_resource_key
}

///|
pub impl @app.Resource for LogDiagnosticsFilters with resource() {
  log_diagnostics_filters_resource_key
}

///|
pub impl @app.Resource for LogDiagnosticsCommandsText with resource() {
  log_diagnostics_commands_text_resource_key
}

///|
fn default_filters() -> LogDiagnosticsFilters {
  {
    frame_time: false,
    entity_count: false,
    system_info: false,
    render_diagnostics: false,
  }
}

///|
fn frame_time_diagnostics() -> Array[@diagnostic.DiagnosticPath] {
  [
    @diagnostic.frame_time_diagnostic_fps, @diagnostic.frame_time_diagnostic_frame_count,
    @diagnostic.frame_time_diagnostic_frame_time,
  ]
}

///|
fn entity_count_diagnostics() -> Array[@diagnostic.DiagnosticPath] {
  [@diagnostic.entity_count_diagnostic_path]
}

///|
fn system_info_diagnostics() -> Array[@diagnostic.DiagnosticPath] {
  [
    @diagnostic.DiagnosticPath::const_new("process/cpu_usage"),
    @diagnostic.DiagnosticPath::const_new("process/mem_usage"),
    @diagnostic.DiagnosticPath::const_new("system/cpu_usage"),
    @diagnostic.DiagnosticPath::const_new("system/mem_usage"),
  ]
}

///|
fn status_enabled(status : LogDiagnosticsStatus) -> Bool {
  match status {
    LogDiagnosticsStatus::Disabled => false
    LogDiagnosticsStatus::Enabled => true
  }
}

///|
fn bool_label(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
fn status_label(status : LogDiagnosticsStatus) -> String {
  match status {
    LogDiagnosticsStatus::Disabled => "Disabled"
    LogDiagnosticsStatus::Enabled => "Enabled"
  }
}

///|
fn command_text_content(
  status : LogDiagnosticsStatus,
  filters : LogDiagnosticsFilters,
) -> String {
  let render_diagnostics_label = if filters.render_diagnostics {
    "Private"
  } else {
    "Private"
  }
  "[Q] Toggle filtering: \{status_label(status)}\n[1] Frame times: \{bool_label(filters.frame_time)}\n[2] Entity count: \{bool_label(filters.entity_count)}\n[3] System info: \{bool_label(filters.system_info)}\n[4] Render diagnostics: \{render_diagnostics_label}"
}

///|
fn set_filter_enabled(
  log_state : @diagnostic.LogDiagnosticsState,
  diagnostics : Array[@diagnostic.DiagnosticPath],
  enabled : Bool,
) -> Unit {
  if enabled {
    log_state.extend_filter(diagnostics)
    return
  }
  for diagnostic in diagnostics {
    log_state.remove_filter(diagnostic) |> ignore
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(8.0F, 8.0F)),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(@sprite.Color::white()),
      ),
    ),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::new(124.0F / 255.0F, 144.0F / 255.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F),
  ).spawn(world)
  |> ignore

  let light = world.spawn_empty()
  try! world.set_by_key(
    light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::default(),
  )
  try! world.set_by_key(
    light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::default(),
  )
  try! world.set_by_key(
    light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F),
  )

  @camera.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(-2.5F, 4.5F, 9.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore

  let asset_server = @asset.AssetServer::new()
  let text_entity = @text.Text2dBundle::new(
      @text.Text2d::new(
        command_text_content(LogDiagnosticsStatus::Disabled, default_filters()),
      ),
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
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  world.insert_resource(LogDiagnosticsCommandsText::resource(), {
    entity: text_entity,
  })
}

///|
fn filters_inputs(
  status : @app.ResMut[LogDiagnosticsStatus],
  filters : @app.ResMut[LogDiagnosticsFilters],
  log_state : @app.ResMut[@diagnostic.LogDiagnosticsState],
) -> Unit {
  let status_ref = status.get_ref()
  let filters_ref = filters.get_ref()
  let log_state_ref = log_state.get_ref()

  if @input.key_just_pressed(@window.KeyCode::KeyQ) {
    match status_ref.val {
      LogDiagnosticsStatus::Enabled => {
        log_state_ref.val.disable_filtering()
        status_ref.val = LogDiagnosticsStatus::Disabled
      }
      LogDiagnosticsStatus::Disabled => {
        log_state_ref.val.enable_filtering()
        set_filter_enabled(
          log_state_ref.val,
          frame_time_diagnostics(),
          filters_ref.val.frame_time,
        )
        set_filter_enabled(
          log_state_ref.val,
          entity_count_diagnostics(),
          filters_ref.val.entity_count,
        )
        set_filter_enabled(
          log_state_ref.val,
          system_info_diagnostics(),
          filters_ref.val.system_info,
        )
        status_ref.val = LogDiagnosticsStatus::Enabled
      }
    }
  }

  let enabled = status_enabled(status_ref.val)
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    filters_ref.val.frame_time = !filters_ref.val.frame_time
    if enabled {
      set_filter_enabled(
        log_state_ref.val,
        frame_time_diagnostics(),
        filters_ref.val.frame_time,
      )
    }
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    filters_ref.val.entity_count = !filters_ref.val.entity_count
    if enabled {
      set_filter_enabled(
        log_state_ref.val,
        entity_count_diagnostics(),
        filters_ref.val.entity_count,
      )
    }
  }
  if @input.key_just_pressed(@window.KeyCode::Digit3) {
    filters_ref.val.system_info = !filters_ref.val.system_info
    if enabled {
      set_filter_enabled(
        log_state_ref.val,
        system_info_diagnostics(),
        filters_ref.val.system_info,
      )
    }
  }
}

///|
fn update_commands(
  status : @app.Res[LogDiagnosticsStatus],
  filters : @app.Res[LogDiagnosticsFilters],
  text_entity : @app.Res[LogDiagnosticsCommandsText],
) -> Unit {
  @text.text_set_content(
    text_entity.get().entity,
    command_text_content(status.get(), filters.get()),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_plugins(@diagnostic.LogDiagnosticsPlugin::default())
  .add_plugins(@diagnostic.FrameTimeDiagnosticsPlugin::default())
  .add_plugins(@diagnostic.EntityCountDiagnosticsPlugin::default())
  .add_plugins(@diagnostic.RenderDiagnosticsPlugin::default())
  .insert_resource(default_filters())
  .insert_resource(LogDiagnosticsStatus::Disabled)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(@app.system_param3(filters_inputs)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(update_commands)).run_if(
      @app.run_condition_or(
        @app.resource_exists_and_changed(LogDiagnosticsStatus::resource()),
        @app.resource_exists_and_changed(LogDiagnosticsFilters::resource()),
      ),
    ),
  )
  .run()
}
