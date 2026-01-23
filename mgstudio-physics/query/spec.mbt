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
#declaration_only
pub type QueryFilter

///|
#declaration_only
pub fn QueryFilter::new() -> QueryFilter {
  ...
}

///|
#declaration_only
pub fn QueryFilter::exclude_rigid_body(
  self : QueryFilter,
  handle : @dynamics.RigidBodyHandle,
) -> QueryFilter {
  ...
}

///|
#declaration_only
pub fn QueryFilter::groups(
  self : QueryFilter,
  groups : @dynamics.InteractionGroups,
) -> QueryFilter {
  ...
}

///|
#declaration_only
pub fn QueryFilter::groups_filter(
  self : QueryFilter,
) -> @dynamics.InteractionGroups? {
  ...
}

///|
#declaration_only
pub type QueryPipeline

///|
#declaration_only
pub type QueryDispatcher

///|
#declaration_only
pub fn QueryDispatcher::new() -> QueryDispatcher {
  ...
}

///|
#declaration_only
pub fn QueryPipeline::new(
  filter : QueryFilter,
  dispatcher : QueryDispatcher,
) -> QueryPipeline {
  ...
}
