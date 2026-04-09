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
pub let picking_set : @app.SystemSet = @app.system_set("mgstudio.picking")

///|
pub let picking_set_input : @app.SystemSet = @app.system_set(
  "mgstudio.picking.input",
)

///|
pub let picking_set_hits : @app.SystemSet = @app.system_set(
  "mgstudio.picking.hits",
)

///|
pub let picking_set_events : @app.SystemSet = @app.system_set(
  "mgstudio.picking.events",
)

///|
pub fn picking_clear_system(world : @ecs.World) -> Unit {
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
}

///|
pub fn picking_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .add_pre_update_system_config(
    @app.system(picking_clear_system).in_set(picking_set_input),
  )
  .add_pre_update_system_config(
    @app.system(ensure_picking_state_system).in_set(picking_set_input),
  )
  .add_pre_update_system_config(
    @app.system(ensure_picking_hits_system).in_set(picking_set_input),
  )
  .add_pre_update_system_config(
    @app.system(ensure_pointer_inputs_system).in_set(picking_set_input),
  )
  .add_pre_update_system_config(
    @app.system(picking_collect_mouse_system).in_set(picking_set_input),
  )
  .add_pre_update_system_config(
    @app.system(picking_ui_hit_test_system).in_set(picking_set_hits),
  )
  .add_pre_update_system_config(
    @app.system(picking_sprite2d_hit_test_system).in_set(picking_set_hits),
  )
  .add_pre_update_system_config(
    @app.system(picking_mesh3d_hit_test_system).in_set(picking_set_hits),
  )
  .add_pre_update_system_config(
    @app.system(picking_apply_a11y_actions_system).in_set(picking_set_events),
  )
  .add_pre_update_system_config(
    @app.system(picking_generate_events_system).in_set(picking_set_events),
  )
  .add_pre_update_system_config(
    @app.system(@app.dispatch_pointer_observers_system).after(
      picking_set_events,
    ),
  )
  .configure_set(@app.PreUpdate, picking_set_input, before=[picking_set_hits])
  .configure_set(
    @app.PreUpdate,
    picking_set_hits,
    after=[picking_set_input, @transform.transform_set_propagate],
    before=[picking_set_events],
  )
  .configure_set(@app.PreUpdate, picking_set_events, after=[
    picking_set_hits, @a11y.a11y_set, @ui.ui_set_focus,
  ])
}
