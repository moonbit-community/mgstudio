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
pub(all) struct ProcessLdtkApi {}

///|
pub(all) struct LdtkPlugin {}

///|
const LDTK_PLUGIN_NAME : String = "mgstudio.ecs_ldtk.LdtkPlugin"

///|
let process_ldtk_api_schedule : @app.ScheduleStage = @app.schedule_label(
  "bevy_ecs_ldtk::ProcessLdtkApi",
)

///|
let process_api_set_pre_clean : @app.SystemSet = @app.system_set(
  "bevy_ecs_ldtk::ProcessApiSet::PreClean",
)

///|
let process_api_set_clean : @app.SystemSet = @app.system_set(
  "bevy_ecs_ldtk::ProcessApiSet::Clean",
)

///|
pub fn LdtkPlugin::default() -> LdtkPlugin {
  LdtkPlugin::{  }
}

///|
pub impl @app.PluginReplacement for LdtkPlugin with plugin_name(_self) {
  LDTK_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for LdtkPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    ldtk_plugin_with(app, self)
  }
}

///|
pub fn ldtk_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  ldtk_plugin_with(app, LdtkPlugin::default())
}

///|
pub fn ldtk_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : LdtkPlugin,
) -> @app.App[@ecs.World] {
  let world = app.world()
  let main_schedule_order_key : @ecs.ResourceKey[@app.MainScheduleOrder] = @app.main_schedule_order_resource_key()
  let main_schedule_order = match
    (try! world.get_resource(main_schedule_order_key)) {
    Some(value) => value
    None => @app.MainScheduleOrder::default()
  }
  ldtk_init_assets(app)
  .insert_world_resource(
    main_schedule_order_key,
    main_schedule_order.insert_after(@app.Update, process_ldtk_api_schedule),
  )
  .add_schedule(@app.Schedule::new(process_ldtk_api_schedule))
  .configure_set(process_ldtk_api_schedule, process_api_set_clean, after=[
    process_api_set_pre_clean,
  ])
  .init_resource(fn() { LdtkEntityMap::default() })
  .init_resource(fn() { LdtkIntCellMap::default() })
  .init_resource(fn() { LevelSelection::default() })
  .init_resource(fn() { LdtkSettings::default() })
  .init_resource(fn() { LdtkRuntimeState::default() })
  .init_resource(fn() { LdtkSpawnedLevelIids::default() })
  .add_message(ldtk_level_event_key)
  .add_systems(@app.PreUpdate, @app.system(process_ldtk_assets))
  .add_systems(@app.PreUpdate, @app.system(process_ldtk_levels))
  .add_systems(
    process_ldtk_api_schedule,
    (
      @app.system(apply_level_selection).in_set(process_api_set_pre_clean),
      @app.system(apply_level_set).in_set(process_api_set_pre_clean),
    )
    |> @app.chain(),
  )
  .add_systems(
    process_ldtk_api_schedule,
    @app.system(clean_respawn_entities).in_set(process_api_set_clean),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(@app.system_param2(detect_level_spawned_events)),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(@app.system_param2(fire_level_transformed_events)),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(worldly_adoption).after(@transform.transform_set_propagate),
  )
}
