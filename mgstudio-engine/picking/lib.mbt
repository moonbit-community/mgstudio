// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_picking/src/lib.rs`.
/// Package-level plugin and system-set wiring.

///|
pub struct Pickable {
  should_block_lower : Bool
  is_hoverable : Bool
} derive(Eq, Debug, ToJson, FromJson)

///|
pub let pickable_ignore : Pickable = Pickable::{
  should_block_lower: false,
  is_hoverable: false,
}

///|
pub fn Pickable::default() -> Pickable {
  Pickable::{ should_block_lower: true, is_hoverable: true }
}

///|
pub fn Pickable::new(
  should_block_lower : Bool,
  is_hoverable : Bool,
) -> Pickable {
  Pickable::{ should_block_lower, is_hoverable }
}

///|
pub impl @ecs.Component for Pickable with component() {
  ecs_key_pickable
}

///|
/// Optional marker for cameras that may be used by sprite picking when
/// `SpritePickingSettings.require_markers` is enabled.
pub struct SpritePickingCamera {} derive(Eq, Debug, ToJson, FromJson)

///|
pub impl @ecs.Component for SpritePickingCamera with component() {
  ecs_key_sprite_picking_camera
}

///|
/// How sprite picking should treat transparent pixels.
pub(all) enum SpritePickingMode {
  BoundingBox
  AlphaThreshold(Float)
} derive(Debug)

///|
pub struct SpritePickingSettings {
  require_markers : Bool
  picking_mode : SpritePickingMode
} derive(Debug)

///|
pub fn SpritePickingSettings::default() -> SpritePickingSettings {
  SpritePickingSettings::{
    require_markers: false,
    picking_mode: AlphaThreshold(0.1F),
  }
}

///|
pub fn SpritePickingSettings::new(
  require_markers : Bool,
  picking_mode : SpritePickingMode,
) -> SpritePickingSettings {
  SpritePickingSettings::{ require_markers, picking_mode }
}

///|
pub impl @app.Resource for SpritePickingSettings with resource() {
  ecs_res_key_sprite_picking_settings
}

///|
pub struct PickingSettings {
  is_enabled : Bool
  is_input_enabled : Bool
  is_hover_enabled : Bool
  is_window_picking_enabled : Bool
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn PickingSettings::default() -> PickingSettings {
  PickingSettings::{
    is_enabled: true,
    is_input_enabled: true,
    is_hover_enabled: true,
    is_window_picking_enabled: true,
  }
}

///|
pub impl @app.Resource for PickingSettings with resource() {
  ecs_res_key_picking_settings
}

///|
fn current_picking_settings(world : @ecs.World) -> PickingSettings {
  match get_picking_settings_resource(world).get() {
    Some(settings) => settings
    None => PickingSettings::default()
  }
}

///|
pub fn picking_input_should_run(world : @ecs.World) -> Bool {
  let settings = current_picking_settings(world)
  settings.is_enabled && settings.is_input_enabled
}

///|
pub fn picking_hover_should_run(world : @ecs.World) -> Bool {
  let settings = current_picking_settings(world)
  settings.is_enabled && settings.is_hover_enabled
}

///|
pub fn picking_window_picking_should_run(world : @ecs.World) -> Bool {
  let settings = current_picking_settings(world)
  settings.is_enabled && settings.is_window_picking_enabled
}

///|
pub let picking_set : @app.SystemSet = @app.system_set("mgstudio.picking")

///|
pub let picking_set_input_stage : @app.SystemSet = @app.system_set(
  "mgstudio.picking.input",
)

///|
pub let picking_set_post_input : @app.SystemSet = @app.system_set(
  "mgstudio.picking.post_input",
)

///|
pub let picking_set_process_input : @app.SystemSet = @app.system_set(
  "mgstudio.picking.process_input",
)

///|
pub let picking_set_backend : @app.SystemSet = @app.system_set(
  "mgstudio.picking.backend",
)

///|
pub let picking_set_hover : @app.SystemSet = @app.system_set(
  "mgstudio.picking.hover",
)

///|
pub let picking_set_post_hover : @app.SystemSet = @app.system_set(
  "mgstudio.picking.post_hover",
)

///|
pub let picking_set_last : @app.SystemSet = @app.system_set(
  "mgstudio.picking.last",
)

///|
pub let picking_set_input : @app.SystemSet = picking_set_process_input

///|
pub let picking_set_hits : @app.SystemSet = picking_set_backend

///|
pub let picking_set_events : @app.SystemSet = picking_set_hover

///|
pub fn picking_clear_system(world : @ecs.World) -> Unit {
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
}

///|
pub fn picking_input_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .add_startup_system_config(@app.system(spawn_mouse_pointer_system))
  .add_first_system_config(
    @app.system(ensure_pointer_input_settings_system).in_set(
      picking_set_input_stage,
    ),
  )
  .add_first_system_config(
    @app.system(picking_collect_mouse_system)
    .run_if(picking_input_should_run)
    .in_set(picking_set_input_stage),
  )
  .configure_set(@app.First, picking_set_input_stage, before=[
    picking_set_post_input,
  ])
  .configure_set(@app.First, picking_set_post_input, after=[
    picking_set_input_stage,
  ])
}

///|
pub fn picking_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .init_resource(() => PickingSettings::default())
  .init_resource(() => SpritePickingSettings::default())
  .add_message(pointer_input_message_key())
  .add_message(pointer_hits_message_key())
  .add_pre_update_system_config(
    @app.system(picking_clear_system).in_set(picking_set_process_input),
  )
  .add_pre_update_system_config(
    @app.system(picking_process_pointer_inputs_system).in_set(
      picking_set_process_input,
    ),
  )
  .add_pre_update_system_config(
    @app.system(picking_ui_hit_test_system).in_set(picking_set_backend),
  )
  .add_pre_update_system_config(
    @app.system(picking_sprite2d_hit_test_system).in_set(picking_set_backend),
  )
  .add_pre_update_system_config(
    @app.system(picking_mesh3d_hit_test_system).in_set(picking_set_backend),
  )
  .add_pre_update_system_config(
    @app.system(picking_window_hit_test_system)
    .run_if(picking_window_picking_should_run)
    .in_set(picking_set_backend),
  )
  .add_pre_update_system_config(
    @app.system(ensure_picking_state_system).in_set(picking_set_hover),
  )
  .add_pre_update_system_config(
    @app.system(ensure_hover_maps_system).in_set(picking_set_hover),
  )
  .configure_set(
    @app.PreUpdate,
    picking_set_process_input,
    after=[@input.input_systems_set],
    before=[picking_set_backend],
  )
  .configure_set(
    @app.PreUpdate,
    picking_set_backend,
    after=[picking_set_process_input, @transform.transform_set_propagate],
    before=[picking_set_hover],
  )
  .configure_set(
    @app.PreUpdate,
    picking_set_hover,
    after=[picking_set_backend],
    before=[picking_set_post_hover],
  )
  .configure_set(
    @app.PreUpdate,
    picking_set_post_hover,
    after=[picking_set_hover, @a11y.a11y_set, @ui.ui_set_focus],
    before=[picking_set_last],
  )
  .configure_set(@app.PreUpdate, picking_set_last, after=[
    picking_set_post_hover,
  ])
}

///|
pub fn picking_interaction_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
  .add_pre_update_system_config(
    @app.system(picking_apply_a11y_actions_system)
    .run_if(picking_hover_should_run)
    .in_set(picking_set_hover),
  )
  .add_pre_update_system_config(
    @app.system(picking_hover_pipeline_system)
    .run_if(picking_hover_should_run)
    .in_set(picking_set_hover),
  )
  .add_pre_update_system_config(
    @app.system(picking_generate_events_system)
    .run_if(picking_hover_should_run)
    .in_set(picking_set_post_hover),
  )
  .add_pre_update_system_config(
    @app.system(@app.dispatch_pointer_observers_system).in_set(picking_set_last),
  )
}
