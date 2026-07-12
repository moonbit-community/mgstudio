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
pub struct SubApp[W] {
  mut world : W
  update_schedule : ScheduleStage?
  schedule : ScheduleRegistry[W]
  extract : SubAppExtractFn[W]?
  allowed_ambiguous_components : @utils.IntBitSet
  allowed_ambiguous_resources : @utils.IntBitSet
}

///|
pub fn SubApp::new(world : @ecs.World) -> SubApp[@ecs.World] {
  app_runtime_reset()
  reset_main_schedule_resources(world)
  let schedule = ScheduleRegistry::new()
  schedule_set_executor_kind(schedule, Main, SingleThreaded)
  schedule_set_executor_kind(schedule, FixedMain, SingleThreaded)
  schedule_set_executor_kind(schedule, RunFixedMainLoop, SingleThreaded)
  schedule_push_config(schedule, Main, system(run_main_schedule_driver_system))
  schedule_push_config(
    schedule,
    FixedMain,
    system(run_fixed_main_schedule_driver_system),
  )
  SubApp::{
    world,
    update_schedule: None,
    schedule,
    extract: None,
    allowed_ambiguous_components: @utils.IntBitSet::new(),
    allowed_ambiguous_resources: @utils.IntBitSet::new(),
  }
}

///|
pub fn[W] SubApp::set_update_schedule(
  self : SubApp[W],
  schedule : ScheduleStage?,
) -> SubApp[W] {
  SubApp::{ ..self, update_schedule: schedule }
}

///|
pub fn[W] SubApp::world(self : SubApp[W]) -> W {
  self.world
}

///|
pub fn[W] SubApp::set_extract(
  self : SubApp[W],
  extract : SubAppExtractFn[W],
) -> SubApp[W] {
  SubApp::{ ..self, extract: Some(extract) }
}

///|
pub fn[W] SubApp::take_extract(
  self : SubApp[W],
) -> (SubApp[W], SubAppExtractFn[W]?) {
  let extract = self.extract
  (SubApp::{ ..self, extract: None }, extract)
}

///|
pub fn SubApp::run_startup(self : SubApp[@ecs.World]) -> SubApp[@ecs.World] {
  app_execution_context_state.current_app_schedule = Some(self.schedule)
  app_execution_context_state.current_allowed_ambiguous_components = Some(
    self.allowed_ambiguous_components,
  )
  app_execution_context_state.current_allowed_ambiguous_resources = Some(
    self.allowed_ambiguous_resources,
  )
  match self.update_schedule {
    Some(Main) => run_main_schedule_startup(self.world, self.schedule)
    Some(stage) => run_schedule_stage(self.world, self.schedule, stage)
    None => ()
  }
  app_execution_context_state.current_allowed_ambiguous_components = None
  app_execution_context_state.current_allowed_ambiguous_resources = None
  app_execution_context_state.current_app_schedule = None
  self
}

///|
pub fn SubApp::update(self : SubApp[@ecs.World]) -> SubApp[@ecs.World] {
  app_execution_context_state.current_app_schedule = Some(self.schedule)
  app_execution_context_state.current_allowed_ambiguous_components = Some(
    self.allowed_ambiguous_components,
  )
  app_execution_context_state.current_allowed_ambiguous_resources = Some(
    self.allowed_ambiguous_resources,
  )
  stepping_begin_frame(self.world)
  match self.update_schedule {
    Some(stage) => run_schedule_stage(self.world, self.schedule, stage)
    None => ()
  }
  app_execution_context_state.current_allowed_ambiguous_components = None
  app_execution_context_state.current_allowed_ambiguous_resources = None
  app_execution_context_state.current_app_schedule = None
  self
}

///|
pub fn SubApp::run_once(self : SubApp[@ecs.World]) -> SubApp[@ecs.World] {
  self.update()
}

///|
pub fn SubApp::shutdown(self : SubApp[@ecs.World]) -> SubApp[@ecs.World] {
  self.world.close()
  self
}

///|
pub fn[T : @ecs.Component] SubApp::allow_ambiguous_component(
  self : SubApp[@ecs.World],
  key? : @ecs.ComponentKey[T] = T::component(),
) -> SubApp[@ecs.World] {
  self.allowed_ambiguous_components.insert(key.id())
  self
}

///|
pub fn[T : @ecs.Component] SubApp::is_ambiguous_component_allowed(
  self : SubApp[@ecs.World],
  key? : @ecs.ComponentKey[T] = T::component(),
) -> Bool {
  self.allowed_ambiguous_components.contains(key.id())
}

///|
pub fn[T : Resource] SubApp::allow_ambiguous_resource(
  self : SubApp[@ecs.World],
  key? : @ecs.ResourceKey[T] = T::resource(),
) -> SubApp[@ecs.World] {
  self.allowed_ambiguous_resources.insert(key.id())
  self
}

///|
pub fn[T : Resource] SubApp::is_ambiguous_resource_allowed(
  self : SubApp[@ecs.World],
  key? : @ecs.ResourceKey[T] = T::resource(),
) -> Bool {
  self.allowed_ambiguous_resources.contains(key.id())
}

///|
pub struct SubApps[W] {
  mut main : SubApp[W]
  sub_apps : @hashmap.HashMap[String, SubApp[W]]
  sub_app_labels : @hashmap.HashMap[String, AppLabel]
  sub_app_order : Array[String]
}

///|
pub fn[W] SubApps::new(main : SubApp[W]) -> SubApps[W] {
  SubApps::{
    main,
    sub_apps: @hashmap.HashMap([]),
    sub_app_labels: @hashmap.HashMap([]),
    sub_app_order: [],
  }
}

///|
pub fn[W] SubApps::insert(
  self : SubApps[W],
  label : AppLabel,
  sub_app : SubApp[W],
) -> SubApps[W] {
  let key = app_label_storage_key(label)
  if !self.sub_apps.contains(key) {
    self.sub_app_order.push(key)
  }
  self.sub_apps.set(key, sub_app)
  self.sub_app_labels.set(key, label)
  self
}

///|
pub fn[W] SubApps::remove(self : SubApps[W], label : AppLabel) -> SubApp[W]? {
  let key = app_label_storage_key(label)
  let removed = self.sub_apps.get(key)
  self.sub_apps.remove(key)
  self.sub_app_labels.remove(key)
  for index in 0..<self.sub_app_order.length() {
    if self.sub_app_order[index] == key {
      ignore(self.sub_app_order.remove(index))
      break
    }
  }
  removed
}

///|
pub fn[W] SubApps::get(self : SubApps[W], label : AppLabel) -> SubApp[W]? {
  let key = app_label_storage_key(label)
  self.sub_apps.get(key)
}

///|
pub fn[W] SubApps::replace(
  self : SubApps[W],
  label : AppLabel,
  sub_app : SubApp[W],
) -> SubApp[W]? {
  let key = app_label_storage_key(label)
  guard self.sub_apps.get(key) is Some(previous) else { return None }
  self.sub_apps.set(key, sub_app)
  self.sub_app_labels.set(key, label)
  Some(previous)
}

///|
pub fn[W] SubApps::modify(
  self : SubApps[W],
  label : AppLabel,
  update : (SubApp[W]) -> SubApp[W],
) -> Bool {
  match self.get(label) {
    Some(sub_app) => self.replace(label, update(sub_app)) is Some(_)
    None => false
  }
}

///|
pub fn[W] SubApps::list(self : SubApps[W]) -> Array[(AppLabel, SubApp[W])] {
  let out : Array[(AppLabel, SubApp[W])] = []
  for entry in self.sub_apps.iter() {
    let (key, sub_app) = entry
    let label = match self.sub_app_labels.get(key) {
      Some(stored) => stored
      None => Custom(key)
    }
    out.push((label, sub_app))
  }
  out
}

///|
pub fn SubApps::run_startup(self : SubApps[@ecs.World]) -> SubApps[@ecs.World] {
  self.main = self.main.run_startup()
  // Bevy-aligned execution model: secondary sub-apps are driven only by
  // `update` (extract + update), not by an explicit startup pass.
  self
}

///|
pub fn SubApps::update(self : SubApps[@ecs.World]) -> SubApps[@ecs.World] {
  self.main = self.main.update()
  for entry in self.sub_apps.iter() {
    let (key, sub_app) = entry
    let mut next_sub_app = sub_app
    if next_sub_app.extract is Some(extract) {
      app_execution_context_state.current_app_schedule = Some(
        next_sub_app.schedule,
      )
      app_execution_context_state.current_allowed_ambiguous_components = Some(
        next_sub_app.allowed_ambiguous_components,
      )
      app_execution_context_state.current_allowed_ambiguous_resources = Some(
        next_sub_app.allowed_ambiguous_resources,
      )
      let worlds = extract(self.main.world, next_sub_app.world)
      app_execution_context_state.current_allowed_ambiguous_components = None
      app_execution_context_state.current_allowed_ambiguous_resources = None
      app_execution_context_state.current_app_schedule = None
      self.main.world = worlds.0
      next_sub_app = SubApp::{ ..next_sub_app, world: worlds.1 }
    }
    self.sub_apps.set(key, next_sub_app.update())
  }
  self
}

///|
pub fn SubApps::update_sub_app_by_label(
  self : SubApps[@ecs.World],
  label : AppLabel,
) -> SubApps[@ecs.World] {
  let key = app_label_storage_key(label)
  if self.sub_apps.get(key) is Some(sub_app) {
    let mut next_sub_app = sub_app
    if next_sub_app.extract is Some(extract) {
      app_execution_context_state.current_app_schedule = Some(
        next_sub_app.schedule,
      )
      app_execution_context_state.current_allowed_ambiguous_components = Some(
        next_sub_app.allowed_ambiguous_components,
      )
      app_execution_context_state.current_allowed_ambiguous_resources = Some(
        next_sub_app.allowed_ambiguous_resources,
      )
      let worlds = extract(self.main.world, next_sub_app.world)
      app_execution_context_state.current_allowed_ambiguous_components = None
      app_execution_context_state.current_allowed_ambiguous_resources = None
      app_execution_context_state.current_app_schedule = None
      self.main.world = worlds.0
      next_sub_app = SubApp::{ ..next_sub_app, world: worlds.1 }
    }
    self.sub_apps.set(key, next_sub_app.update())
  }
  self
}

///|
fn SubApps::shutdown_worlds(self : SubApps[@ecs.World]) -> Array[@ecs.World] {
  let worlds : Array[@ecs.World] = []
  let mut index = self.sub_app_order.length() - 1
  while index >= 0 {
    let key = self.sub_app_order[index]
    match self.sub_apps.get(key) {
      Some(sub_app) => worlds.push(sub_app.world())
      None => ()
    }
    index = index - 1
  }
  worlds.push(self.main.world())
  worlds
}

///|
fn SubApps::shutdown(self : SubApps[@ecs.World]) -> SubApps[@ecs.World] {
  for world in self.shutdown_worlds() {
    world.close()
  }
  self
}
