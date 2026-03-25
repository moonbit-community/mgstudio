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
pub fn[T : Component] World::get_component(
  self : World,
  entity : @core.Entity,
) -> T? raise EcsError {
  let key : ComponentKey[T] = Component::component()
  self.get(entity, key)
}

///|
#callsite(autofill(loc))
pub fn[T : Component] World::set_component(
  self : World,
  entity : @core.Entity,
  value : T,
  loc~ : SourceLoc,
) -> Unit raise EcsError {
  let key : ComponentKey[T] = Component::component()
  self.set(entity, key, value, loc~)
}

///|
#callsite(autofill(loc))
pub fn[T : Component] World::update_component(
  self : World,
  entity : @core.Entity,
  update : (T) -> T,
  loc~ : SourceLoc,
) -> Bool raise EcsError {
  let key : ComponentKey[T] = Component::component()
  self.update(entity, key, update, loc~)
}
