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
pub struct Disabled {} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn Disabled::new() -> Disabled {
  Disabled::{  }
}

///|
pub struct DefaultQueryFilters {
  disabling_component_ids : Array[Int]
}

///|
pub fn DefaultQueryFilters::empty() -> DefaultQueryFilters {
  DefaultQueryFilters::{ disabling_component_ids: [] }
}

///|
pub fn DefaultQueryFilters::register_disabling_component(
  self : DefaultQueryFilters,
  component_id : Int,
) -> DefaultQueryFilters {
  if !default_query_filters_contains_component_id(self, component_id) {
    self.disabling_component_ids.push(component_id)
  }
  self
}

///|
pub fn DefaultQueryFilters::disabling_component_ids(
  self : DefaultQueryFilters,
) -> Array[Int] {
  self.disabling_component_ids
}

///|
pub let ecs_key_disabled : ComponentKey[Disabled] = register_component(
  debug_name="mgstudio_ecs::entity_disabling::Disabled",
)

///|
pub let ecs_key_default_query_filters : ResourceKey[DefaultQueryFilters] = register_resource(
  debug_name="mgstudio_ecs::entity_disabling::DefaultQueryFilters",
)

///|
pub impl Component for Disabled with component() {
  ecs_key_disabled
}

///|
pub fn[T] World::register_disabling_component(
  self : World,
  key : ComponentKey[T],
) -> Unit raise EcsError {
  let component_id = key.id()
  if self.update_resource(ecs_key_default_query_filters, fn(filters) {
      filters.register_disabling_component(component_id)
    }) {
    return
  }
  self.insert_resource(
    ecs_key_default_query_filters,
    DefaultQueryFilters::empty().register_disabling_component(component_id),
  )
}

///|
fn default_query_filters_bootstrap_resource() -> DefaultQueryFilters {
  DefaultQueryFilters::empty().register_disabling_component(
    ecs_key_disabled.id(),
  )
}

///|
fn default_query_filters_contains_component_id(
  filters : DefaultQueryFilters,
  component_id : Int,
) -> Bool {
  for id in filters.disabling_component_ids {
    if id == component_id {
      return true
    }
  }
  false
}

///|
fn entity_has_component_id(
  world : World,
  component_id : Int,
  entity : @core.Entity,
) -> Bool {
  match world.component_store(component_id) {
    Some(store_ref) => store_ref.val.contains(entity)
    None => false
  }
}
