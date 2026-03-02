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
pub fn[T : ToJson] World::insert_resource(
  self : World,
  key : ResourceKey[T],
  value : T,
) -> Unit {
  self.resources.set(key.id(), value.to_json())
}

///|
pub fn[T : @json.FromJson] World::get_resource(
  self : World,
  key : ResourceKey[T],
) -> T? raise EcsError {
  match self.resources.get(key.id()) {
    Some(payload) => Some(self.decode_resource_payload(key, payload))
    None => None
  }
}

///|
pub fn[T : ToJson + @json.FromJson] World::update_resource(
  self : World,
  key : ResourceKey[T],
  update : (T) -> T,
) -> Bool raise EcsError {
  guard self.get_resource(key) is Some(old_value) else { return false }
  let new_value = update(old_value)
  self.insert_resource(key, new_value)
  true
}

///|
fn[T : @json.FromJson] World::decode_resource_payload(
  _self : World,
  key : ResourceKey[T],
  payload : Json,
) -> T raise EcsError {
  @json.from_json(payload) catch {
    err => raise ResourceDecodeFailed(key.id(), key.debug_name(), err)
  }
}
