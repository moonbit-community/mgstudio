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
pub enum SceneFilter {
  Unset
  Allowlist(@hashmap.HashMap[String, Bool])
  Denylist(@hashmap.HashMap[String, Bool])
}

///|
pub fn SceneFilter::default() -> SceneFilter {
  Unset
}

///|
pub fn SceneFilter::allow_all() -> SceneFilter {
  Denylist(HashMap([]))
}

///|
pub fn SceneFilter::deny_all() -> SceneFilter {
  Allowlist(HashMap([]))
}

///|
fn scene_filter_component_token(component_id : Int) -> String {
  "component:\{component_id}"
}

///|
fn scene_filter_resource_token(resource_id : Int) -> String {
  "resource:\{resource_id}"
}

///|
fn scene_filter_allow_token(
  filter : SceneFilter,
  token : String,
) -> SceneFilter {
  match filter {
    Unset => {
      let entries : @hashmap.HashMap[String, Bool] = HashMap([])
      entries.set(token, true)
      Allowlist(entries)
    }
    Allowlist(entries) => {
      entries.set(token, true)
      Allowlist(entries)
    }
    Denylist(entries) => {
      entries.remove(token)
      Denylist(entries)
    }
  }
}

///|
fn scene_filter_deny_token(filter : SceneFilter, token : String) -> SceneFilter {
  match filter {
    Unset => {
      let entries : @hashmap.HashMap[String, Bool] = HashMap([])
      entries.set(token, true)
      Denylist(entries)
    }
    Allowlist(entries) => {
      entries.remove(token)
      Allowlist(entries)
    }
    Denylist(entries) => {
      entries.set(token, true)
      Denylist(entries)
    }
  }
}

///|
fn scene_filter_is_allowed_token(filter : SceneFilter, token : String) -> Bool {
  match filter {
    Unset => true
    Allowlist(entries) => entries.contains(token)
    Denylist(entries) => !entries.contains(token)
  }
}

///|
fn scene_filter_len(entries : @hashmap.HashMap[String, Bool]) -> Int {
  let mut count = 0
  for _ in entries.iter() {
    count = count + 1
  }
  count
}

///|
pub fn SceneFilter::allow_component_by_id(
  self : SceneFilter,
  component_id : Int,
) -> SceneFilter {
  scene_filter_allow_token(self, scene_filter_component_token(component_id))
}

///|
pub fn SceneFilter::allow_resource_by_id(
  self : SceneFilter,
  resource_id : Int,
) -> SceneFilter {
  scene_filter_allow_token(self, scene_filter_resource_token(resource_id))
}

///|
pub fn SceneFilter::deny_component_by_id(
  self : SceneFilter,
  component_id : Int,
) -> SceneFilter {
  scene_filter_deny_token(self, scene_filter_component_token(component_id))
}

///|
pub fn SceneFilter::deny_resource_by_id(
  self : SceneFilter,
  resource_id : Int,
) -> SceneFilter {
  scene_filter_deny_token(self, scene_filter_resource_token(resource_id))
}

///|
pub fn SceneFilter::is_component_allowed_by_id(
  self : SceneFilter,
  component_id : Int,
) -> Bool {
  scene_filter_is_allowed_token(
    self,
    scene_filter_component_token(component_id),
  )
}

///|
pub fn SceneFilter::is_resource_allowed_by_id(
  self : SceneFilter,
  resource_id : Int,
) -> Bool {
  scene_filter_is_allowed_token(self, scene_filter_resource_token(resource_id))
}

///|
pub fn SceneFilter::is_component_denied_by_id(
  self : SceneFilter,
  component_id : Int,
) -> Bool {
  !self.is_component_allowed_by_id(component_id)
}

///|
pub fn SceneFilter::is_resource_denied_by_id(
  self : SceneFilter,
  resource_id : Int,
) -> Bool {
  !self.is_resource_allowed_by_id(resource_id)
}

///|
pub fn SceneFilter::len(self : SceneFilter) -> Int {
  match self {
    Unset => 0
    Allowlist(entries) => scene_filter_len(entries)
    Denylist(entries) => scene_filter_len(entries)
  }
}

///|
pub fn SceneFilter::is_empty(self : SceneFilter) -> Bool {
  self.len() == 0
}

///|
pub fn SceneFilter::iter_tokens(self : SceneFilter) -> Array[String] {
  match self {
    Unset => []
    Allowlist(entries) => {
      let tokens : Array[String] = []
      for entry in entries.iter() {
        let (token, _) = entry
        tokens.push(token)
      }
      tokens
    }
    Denylist(entries) => {
      let tokens : Array[String] = []
      for entry in entries.iter() {
        let (token, _) = entry
        tokens.push(token)
      }
      tokens
    }
  }
}
