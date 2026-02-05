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
/// Internal layout engine target: Taffy v0.5 (Bevy UI v0.15.3 baseline).
///
/// NOTE: This package is intentionally **not** a stable public API. It exists to
/// support `Milky2018/mgstudio/ui`.
///
/// TODO: Full port is pending.

///|
pub type NodeId = Int

///|
pub struct Layout {
  size : @math.Vec2
  location : @math.Vec2
}

///|
pub fn Layout::default() -> Layout {
  Layout::{
    size: @math.Vec2::new(0.0F, 0.0F),
    location: @math.Vec2::new(0.0F, 0.0F),
  }
}

///|
pub struct Taffy {
  mut next_id : Int
}

///|
pub fn Taffy::new() -> Taffy {
  Taffy::{ next_id: 1 }
}

///|
pub fn Taffy::new_leaf(self : Taffy) -> NodeId {
  let id = self.next_id
  self.next_id = self.next_id + 1
  id
}

///|
pub fn Taffy::new_with_children(
  self : Taffy,
  _children : Array[NodeId],
) -> NodeId {
  // Placeholder: real implementation maintains a tree and style cache.
  self.new_leaf()
}

///|
pub fn Taffy::compute_layout(
  _self : Taffy,
  _root : NodeId,
  _available_space? : @math.Vec2 = @math.Vec2::new(0.0F, 0.0F),
) -> Unit {
  // Placeholder: real implementation will port Taffy v0.5 (Flex + Grid).
}
