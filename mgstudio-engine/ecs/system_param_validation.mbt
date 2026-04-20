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
pub fn query_validate_data_filter_access(
  data_access : QueryDataAccess,
  filter_access : QueryFilterAccess,
) -> SystemParamValidationError? {
  if data_access.has_conflict() {
    return Some(
      Invalid(
        "Query data access contains conflicting read/write accesses for the same component",
      ),
    )
  }
  if query_access_component_overlap(
      data_access.write_components(),
      filter_access.read_components(),
    )
    is Some(component_id) {
    return Some(
      Invalid(
        "Query filter reads component \{component_id} while query data mutably accesses it",
      ),
    )
  }
  None
}
