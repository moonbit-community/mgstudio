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
  allowed_ambiguous_components : @hashmap.HashMap[Int, Bool]
}

///|
pub fn SubApp::new(world : @ecs.World) -> SubApp[@ecs.World] {
  app_runtime_reset()
  reset_main_schedule_resources(world)
  let schedule = ScheduleRegistry::new()
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
    allowed_ambiguous_components: @hashmap.HashMap::new(),
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
  current_app_schedule_ref.val = Some(self.schedule)
  current_allowed_ambiguous_components_ref.val = Some(
    self.allowed_ambiguous_components,
  )
  match self.update_schedule {
    Some(Main) => run_main_schedule_startup(self.world, self.schedule)
    Some(stage) => run_schedule_stage(self.world, self.schedule, stage)
    None => ()
  }
  current_allowed_ambiguous_components_ref.val = None
  current_app_schedule_ref.val = None
  self
}

///|
pub fn SubApp::update(self : SubApp[@ecs.World]) -> SubApp[@ecs.World] {
  current_app_schedule_ref.val = Some(self.schedule)
  current_allowed_ambiguous_components_ref.val = Some(
    self.allowed_ambiguous_components,
  )
  stepping_begin_frame(self.world)
  match self.update_schedule {
    Some(stage) => run_schedule_stage(self.world, self.schedule, stage)
    None => ()
  }
  current_allowed_ambiguous_components_ref.val = None
  current_app_schedule_ref.val = None
  self
}

///|
pub fn SubApp::run_once(self : SubApp[@ecs.World]) -> SubApp[@ecs.World] {
  self.update()
}

///|
pub fn[T : @ecs.Component] SubApp::allow_ambiguous_component(
  self : SubApp[@ecs.World],
  key? : @ecs.ComponentKey[T] = T::component(),
) -> SubApp[@ecs.World] {
  self.allowed_ambiguous_components.set(key.id(), true)
  self
}

///|
pub fn[T : @ecs.Component] SubApp::is_ambiguous_component_allowed(
  self : SubApp[@ecs.World],
  key? : @ecs.ComponentKey[T] = T::component(),
) -> Bool {
  match self.allowed_ambiguous_components.get(key.id()) {
    Some(allowed) => allowed
    None => false
  }
}

///|
pub struct SubApps[W] {
  mut main : SubApp[W]
  sub_apps : @hashmap.HashMap[String, Ref[SubApp[W]]]
  sub_app_labels : @hashmap.HashMap[String, AppLabel]
}

///|
pub fn[W] SubApps::new(main : SubApp[W]) -> SubApps[W] {
  SubApps::{
    main,
    sub_apps: @hashmap.HashMap::new(),
    sub_app_labels: @hashmap.HashMap::new(),
  }
}

///|
pub fn[W] SubApps::insert(
  self : SubApps[W],
  label : AppLabel,
  sub_app : SubApp[W],
) -> SubApps[W] {
  let key = app_label_storage_key(label)
  self.sub_apps.set(key, Ref::new(sub_app))
  self.sub_app_labels.set(key, label)
  self
}

///|
pub fn[W] SubApps::remove(self : SubApps[W], label : AppLabel) -> SubApp[W]? {
  let key = app_label_storage_key(label)
  let removed = self.sub_apps.get(key)
  self.sub_apps.remove(key)
  self.sub_app_labels.remove(key)
  removed.map(fn(sub_app_ref) { sub_app_ref.val })
}

///|
pub fn[W] SubApps::get(self : SubApps[W], label : AppLabel) -> SubApp[W]? {
  let key = app_label_storage_key(label)
  self.sub_apps.get(key).map(fn(sub_app_ref) { sub_app_ref.val })
}

///|
pub fn[W] SubApps::get_mut(
  self : SubApps[W],
  label : AppLabel,
) -> Ref[SubApp[W]]? {
  let key = app_label_storage_key(label)
  self.sub_apps.get(key)
}

///|
pub fn[W] SubApps::list(self : SubApps[W]) -> Array[(AppLabel, SubApp[W])] {
  let out : Array[(AppLabel, SubApp[W])] = []
  for entry in self.sub_apps.iter() {
    let (key, sub_app_ref) = entry
    let label = match self.sub_app_labels.get(key) {
      Some(stored) => stored
      None => Custom(key)
    }
    out.push((label, sub_app_ref.val))
  }
  out
}

///|
pub fn[W] SubApps::list_mut(
  self : SubApps[W],
) -> Array[(AppLabel, Ref[SubApp[W]])] {
  let out : Array[(AppLabel, Ref[SubApp[W]])] = []
  for entry in self.sub_apps.iter() {
    let (key, sub_app_ref) = entry
    let label = match self.sub_app_labels.get(key) {
      Some(stored) => stored
      None => Custom(key)
    }
    out.push((label, sub_app_ref))
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
    let (_key, sub_app_ref) = entry
    if sub_app_ref.val.extract is Some(extract) {
      let worlds = extract(self.main.world, sub_app_ref.val.world)
      self.main.world = worlds.0
      sub_app_ref.val = SubApp::{ ..sub_app_ref.val, world: worlds.1 }
    }
    sub_app_ref.val = sub_app_ref.val.update()
  }
  self
}

///|
pub fn SubApps::update_sub_app_by_label(
  self : SubApps[@ecs.World],
  label : AppLabel,
) -> SubApps[@ecs.World] {
  let key = app_label_storage_key(label)
  if self.sub_apps.get(key) is Some(sub_app_ref) {
    if sub_app_ref.val.extract is Some(extract) {
      let worlds = extract(self.main.world, sub_app_ref.val.world)
      self.main.world = worlds.0
      sub_app_ref.val = SubApp::{ ..sub_app_ref.val, world: worlds.1 }
    }
    sub_app_ref.val = sub_app_ref.val.update()
  }
  self
}
