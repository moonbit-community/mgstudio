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
test "plugin: ldtk_plugin installs its schedule after Update" {
  let app = ldtk_plugin(@app.App::new(@ecs.World::new()))
  let world = app.world()

  let main_schedule_order = match
    (try! world.get_resource(@app.main_schedule_order_resource_key())) {
    Some(value) => value
    None => abort("Expected MainScheduleOrder resource")
  }

  let update_index = match
    main_schedule_order.labels.search_by(fn(stage) {
      stage == @app.ScheduleStage::Update
    }) {
    Some(index) => index
    None => abort("Expected Update schedule stage")
  }

  let ldtk_index = match
    main_schedule_order.labels.search_by(fn(stage) {
      stage == process_ldtk_api_schedule
    }) {
    Some(index) => index
    None => abort("Expected ProcessLdtkApi schedule stage")
  }

  inspect(ldtk_index > update_index, content="true")
}

///|
test "plugin: ldtk_plugin initializes runtime resources" {
  let app = ldtk_plugin(@app.App::new(@ecs.World::new()))
  let world = app.world()

  inspect(
    (try! world.get_resource(LevelSelection::resource())) is Some(_),
    content="true",
  )
  inspect(
    (try! world.get_resource(LdtkSettings::resource())) is Some(_),
    content="true",
  )
  inspect(
    (try! world.get_resource(LdtkRuntimeState::resource())) is Some(_),
    content="true",
  )
  inspect(
    (try! world.get_resource(LdtkSpawnedLevelIids::resource())) is Some(_),
    content="true",
  )
}
