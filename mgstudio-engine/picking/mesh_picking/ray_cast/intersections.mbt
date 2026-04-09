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
// Bevy source: `bevy/crates/bevy_picking/src/mesh_picking/ray_cast/intersections.rs`.
// Bridge surface to the current mesh-picking hit storage.
pub fn mesh_picking_hit_entity(
  hits : @picking.PickingHits,
  pointer : Int,
) -> @core.Entity? {
  hits.mesh3d(pointer)
}
