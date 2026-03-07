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
pub struct Name {
  name : String
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn Name::new(name : String) -> Name {
  Name::{ name, }
}

///|
pub fn Name::as_str(self : Name) -> String {
  self.name
}

///|
pub let ecs_key_name : ComponentKey[Name] = register_component(
  debug_name="ecs.name",
)

///|
pub impl Component for Name with component() {
  ecs_key_name
}
