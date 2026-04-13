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
pub type DrawState = GpuPassState

///|
pub fn DrawState::target_id(self : DrawState) -> Int {
  self.target_id
}

///|
pub fn DrawState::target_layer(self : DrawState) -> Int {
  self.target_layer
}

///|
pub fn DrawState::secondary_target_id(self : DrawState) -> Int {
  self.secondary_target_id
}

///|
pub fn DrawState::pass_kind(self : DrawState) -> Int {
  self.pass_kind
}

///|
pub fn DrawState::is_3d(self : DrawState) -> Bool {
  self.is_3d
}

///|
pub fn DrawState::viewport(self : DrawState) -> (UInt, UInt, UInt, UInt) {
  (self.viewport_x, self.viewport_y, self.viewport_w, self.viewport_h)
}
