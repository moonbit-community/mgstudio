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
// Bevy source: `bevy/crates/bevy_ui/src/stack.rs`.
pub struct ZIndex {
  value : Int
} derive(ToJson, FromJson)

///|
pub fn ZIndex::new(value : Int) -> ZIndex {
  ZIndex::{ value, }
}

///|
pub struct GlobalZIndex {
  value : Int
} derive(ToJson, FromJson)

///|
pub fn GlobalZIndex::new(value : Int) -> GlobalZIndex {
  GlobalZIndex::{ value, }
}

///|
pub struct UiScale {
  value : Float
} derive(ToJson, FromJson)

///|
pub fn UiScale::new(value : Float) -> UiScale {
  UiScale::{ value, }
}

///|
pub struct UiStack {
  mut uinodes : Array[@core.Entity]
} derive(ToJson, FromJson)

///|
pub fn UiStack::default() -> UiStack {
  UiStack::{ uinodes: [] }
}

///|
pub fn UiStack::uinodes(self : UiStack) -> Array[@core.Entity] {
  self.uinodes
}

///|
pub fn UiStack::clear(self : Ref[UiStack]) -> Unit {
  self.val.uinodes = []
}
