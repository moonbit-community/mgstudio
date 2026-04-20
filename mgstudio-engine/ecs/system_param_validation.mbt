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
pub(all) suberror SystemParamValidationError {
  Skipped(String)
  Invalid(String)
}

///|
pub fn SystemParamValidationError::message(
  self : SystemParamValidationError,
) -> String {
  match self {
    Skipped(message) => message
    Invalid(message) => message
  }
}

///|
pub fn SystemParamValidationError::is_skipped(
  self : SystemParamValidationError,
) -> Bool {
  match self {
    Skipped(_) => true
    Invalid(_) => false
  }
}

///|
pub fn SystemParamValidationError::is_invalid(
  self : SystemParamValidationError,
) -> Bool {
  !self.is_skipped()
}

///|
fn query_access_component_overlap(lhs : Array[Int], rhs : Array[Int]) -> Int? {
  for component_id in lhs {
    if rhs.contains(component_id) {
      return Some(component_id)
    }
  }
  None
}

///|
fn query_access_components_overlap(lhs : Array[Int], rhs : Array[Int]) -> Bool {
  query_access_component_overlap(lhs, rhs) is Some(_)
}

///|
fn query_filter_accesses_rule_out_each_other(
  lhs_filter_access : QueryFilterAccess,
  rhs_filter_access : QueryFilterAccess,
) -> Bool {
  query_access_components_overlap(
    lhs_filter_access.with_components(),
    rhs_filter_access.without_components(),
  ) ||
  query_access_components_overlap(
    lhs_filter_access.without_components(),
    rhs_filter_access.with_components(),
  )
}

///|
pub fn query_validate_data_filter_access(
  data_access : QueryDataAccess,
  filter_access : QueryFilterAccess,
) -> SystemParamValidationError? {
  ignore(filter_access)
  if data_access.has_conflict() {
    return Some(
      Invalid(
        "Query data access contains conflicting read/write accesses for the same component",
      ),
    )
  }
  None
}

///|
pub fn query_validate_data_data_compatibility(
  lhs_data_access : QueryDataAccess,
  lhs_filter_access : QueryFilterAccess,
  rhs_data_access : QueryDataAccess,
  rhs_filter_access : QueryFilterAccess,
) -> Bool {
  let has_component_conflict = query_access_components_overlap(
      lhs_data_access.write_components(),
      rhs_data_access.read_components(),
    ) ||
    query_access_components_overlap(
      lhs_data_access.write_components(),
      rhs_data_access.write_components(),
    ) ||
    query_access_components_overlap(
      lhs_data_access.read_components(),
      rhs_data_access.write_components(),
    )
  if !has_component_conflict {
    return true
  }
  query_filter_accesses_rule_out_each_other(
    lhs_filter_access, rhs_filter_access,
  )
}
