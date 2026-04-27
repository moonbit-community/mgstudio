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
struct QuerySystemAccess {
  data_access : @ecs.QueryDataAccess
  filter_access : @ecs.QueryFilterAccess
}

///|
pub struct SystemAccess {
  query_accesses : Array[QuerySystemAccess]
  read_resource_ids : Array[Int]
  write_resource_ids : Array[Int]
  mut is_exclusive : Bool
  mut uses_deferred_commands : Bool
  mut validation_error : String?
}

///|
pub fn SystemAccess::new() -> SystemAccess {
  {
    query_accesses: [],
    read_resource_ids: [],
    write_resource_ids: [],
    is_exclusive: false,
    uses_deferred_commands: false,
    validation_error: None,
  }
}

///|
pub fn SystemAccess::exclusive() -> SystemAccess {
  let access = SystemAccess::new()
  access.is_exclusive = true
  access
}

///|
pub fn SystemAccess::is_exclusive(self : SystemAccess) -> Bool {
  self.is_exclusive
}

///|
fn system_access_push_unique(ids : Array[Int], id : Int) -> Unit {
  if !ids.contains(id) {
    ids.push(id)
  }
}

///|
pub fn SystemAccess::add_read_resource(self : SystemAccess, id : Int) -> Unit {
  system_access_push_unique(self.read_resource_ids, id)
}

///|
pub fn SystemAccess::add_write_resource(self : SystemAccess, id : Int) -> Unit {
  system_access_push_unique(self.write_resource_ids, id)
}

///|
pub fn SystemAccess::mark_deferred_commands(self : SystemAccess) -> Unit {
  self.uses_deferred_commands = true
}

///|
pub fn SystemAccess::uses_deferred_commands(self : SystemAccess) -> Bool {
  self.uses_deferred_commands
}

///|
pub fn SystemAccess::validation_error(self : SystemAccess) -> String? {
  self.validation_error
}

///|
fn SystemAccess::set_validation_error(
  self : SystemAccess,
  message : String,
) -> Unit {
  if self.validation_error is None {
    self.validation_error = Some(message)
  }
}

///|
pub fn SystemAccess::add_query_access(
  self : SystemAccess,
  data_access : @ecs.QueryDataAccess,
  filter_access : @ecs.QueryFilterAccess,
) -> Unit {
  match @ecs.query_validate_data_filter_access(data_access, filter_access) {
    Some(err) => self.set_validation_error(err.message())
    None => ()
  }
  self.query_accesses.push({ data_access, filter_access })
}

///|
pub fn system_access_merge_unchecked(
  target : SystemAccess,
  other : SystemAccess,
) -> Unit {
  for query_access in other.query_accesses {
    target.query_accesses.push(query_access)
  }
  for id in other.read_resource_ids {
    target.add_read_resource(id)
  }
  for id in other.write_resource_ids {
    target.add_write_resource(id)
  }
  if other.uses_deferred_commands() {
    target.mark_deferred_commands()
  }
  if other.is_exclusive() {
    target.is_exclusive = true
  }
  match other.validation_error() {
    Some(message) => target.set_validation_error(message)
    None => ()
  }
}

///|
fn system_access_component_overlap_ids(
  lhs : Array[Int],
  rhs : Array[Int],
) -> Array[Int] {
  let overlap : Array[Int] = []
  for component_id in lhs {
    if rhs.contains(component_id) && !overlap.contains(component_id) {
      overlap.push(component_id)
    }
  }
  overlap
}

///|
fn query_system_access_component_conflict_ids(
  lhs : QuerySystemAccess,
  rhs : QuerySystemAccess,
) -> Array[Int] {
  let conflicts : Array[Int] = []
  let overlaps = [
    system_access_component_overlap_ids(
      lhs.data_access.write_components(),
      rhs.data_access.read_components(),
    ),
    system_access_component_overlap_ids(
      lhs.data_access.write_components(),
      rhs.data_access.write_components(),
    ),
    system_access_component_overlap_ids(
      lhs.data_access.read_components(),
      rhs.data_access.write_components(),
    ),
  ]
  for overlap in overlaps {
    for component_id in overlap {
      if !conflicts.contains(component_id) {
        conflicts.push(component_id)
      }
    }
  }
  conflicts
}

///|
fn system_access_component_conflicts_allowed(
  conflict_ids : Array[Int],
  allowed_ambiguous_components : @utils.IntBitSet,
) -> Bool {
  if conflict_ids.length() == 0 {
    return false
  }
  allowed_ambiguous_components.contains_all_array(conflict_ids)
}

///|
fn query_system_accesses_compatible(
  lhs : QuerySystemAccess,
  rhs : QuerySystemAccess,
  allowed_ambiguous_components : @utils.IntBitSet,
) -> Bool {
  if @ecs.query_validate_data_data_compatibility(
      lhs.data_access,
      lhs.filter_access,
      rhs.data_access,
      rhs.filter_access,
    ) {
    return true
  }
  let conflict_ids = query_system_access_component_conflict_ids(lhs, rhs)
  system_access_component_conflicts_allowed(
    conflict_ids, allowed_ambiguous_components,
  )
}

///|
fn system_access_resource_conflict_ids(
  lhs : SystemAccess,
  rhs : SystemAccess,
) -> Array[Int] {
  let conflicts : Array[Int] = []
  for id in lhs.write_resource_ids {
    if rhs.read_resource_ids.contains(id) || rhs.write_resource_ids.contains(id) {
      if !conflicts.contains(id) {
        conflicts.push(id)
      }
    }
  }
  for id in lhs.read_resource_ids {
    if rhs.write_resource_ids.contains(id) {
      if !conflicts.contains(id) {
        conflicts.push(id)
      }
    }
  }
  conflicts
}

///|
pub fn system_access_compatible(
  lhs : SystemAccess,
  rhs : SystemAccess,
  allowed_ambiguous_components : @utils.IntBitSet,
  allowed_ambiguous_resources? : @utils.IntBitSet = @utils.IntBitSet::new(),
) -> Bool {
  if lhs.validation_error() is Some(_) || rhs.validation_error() is Some(_) {
    return false
  }
  if lhs.is_exclusive() || rhs.is_exclusive() {
    return false
  }
  let resource_conflicts = system_access_resource_conflict_ids(lhs, rhs)
  if resource_conflicts.length() > 0 &&
    !allowed_ambiguous_resources.contains_all_array(resource_conflicts) {
    return false
  }
  for lhs_query_access in lhs.query_accesses {
    for rhs_query_access in rhs.query_accesses {
      if !query_system_accesses_compatible(
          lhs_query_access, rhs_query_access, allowed_ambiguous_components,
        ) {
        return false
      }
    }
  }
  true
}

///|
pub fn system_access_merge_validated(
  target : SystemAccess,
  other : SystemAccess,
  allowed_ambiguous_components : @utils.IntBitSet,
  allowed_ambiguous_resources? : @utils.IntBitSet = @utils.IntBitSet::new(),
) -> Unit {
  if !system_access_compatible(
      target,
      other,
      allowed_ambiguous_components,
      allowed_ambiguous_resources~,
    ) {
    target.set_validation_error(
      "System parameters contain conflicting world accesses. Use ParamSet to split incompatible queries.",
    )
  }
  system_access_merge_unchecked(target, other)
}
