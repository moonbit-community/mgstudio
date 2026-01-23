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
pub struct QueryFilter {
  excluded_body : @dynamics.RigidBodyHandle?
  mut groups : @dynamics.InteractionGroups?
}

///|
pub fn QueryFilter::new() -> QueryFilter {
  { excluded_body: None, groups: None }
}

///|
pub fn QueryFilter::exclude_rigid_body(
  self : QueryFilter,
  handle : @dynamics.RigidBodyHandle,
) -> QueryFilter {
  self |> ignore
  { excluded_body: Some(handle), groups: self.groups }
}

///|
pub fn QueryFilter::groups(
  self : QueryFilter,
  groups : @dynamics.InteractionGroups,
) -> QueryFilter {
  self.groups = Some(groups)
  self
}

///|
pub fn QueryFilter::groups_filter(
  self : QueryFilter,
) -> @dynamics.InteractionGroups? {
  self.groups
}

///|
pub struct QueryPipeline {
  filter : QueryFilter
  dispatcher : QueryDispatcher
}

///|
pub struct QueryDispatcher {}

///|
pub fn QueryDispatcher::new() -> QueryDispatcher {
  QueryDispatcher::{  }
}

///|
pub fn QueryPipeline::new(
  filter : QueryFilter,
  dispatcher : QueryDispatcher,
) -> QueryPipeline {
  { filter, dispatcher }
}
