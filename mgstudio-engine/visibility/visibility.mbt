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
/// Bevy-like visibility components (2D-first).

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub(all) enum Visibility {
  Inherited
  Hidden
  Visible
} derive(Eq, Show)

///|
pub fn Visibility::is_visible(self : Visibility) -> Bool {
  match self {
    Hidden => false
    Inherited | Visible => true
  }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct InheritedVisibility {
  visible : Bool
} derive(Eq, Show)

///|
pub fn InheritedVisibility::new(visible : Bool) -> InheritedVisibility {
  InheritedVisibility::{ visible, }
}

///|
pub fn InheritedVisibility::is_visible(self : InheritedVisibility) -> Bool {
  self.visible
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct ViewVisibility {
  visible : Bool
} derive(Eq, Show)

///|
pub fn ViewVisibility::new(visible : Bool) -> ViewVisibility {
  ViewVisibility::{ visible, }
}

///|
pub fn ViewVisibility::is_visible(self : ViewVisibility) -> Bool {
  self.visible
}
