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
pub fn layer_grid_tiles(
  grid_tiles : Array[TileInstance],
) -> Array[Array[TileInstance]] {
  let layer : Array[TileInstance] = []
  let overflow : Array[TileInstance] = []
  for tile in grid_tiles {
    let exists = layer.any(fn(existing) {
      existing.px.x == tile.px.x && existing.px.y == tile.px.y
    })
    if exists {
      overflow.push(tile)
    } else {
      layer.push(tile)
    }
  }
  let layered : Array[Array[TileInstance]] = [layer]
  if overflow.length() > 0 {
    for additional in layer_grid_tiles(overflow) {
      layered.push(additional)
    }
  }
  layered
}

///|
pub fn tile_in_layer_bounds(
  tile : TileInstance,
  layer_instance : LayerInstance,
) -> Bool {
  tile.px.x >= 0 &&
  tile.px.y >= 0 &&
  tile.px.x < layer_instance.c_wid * layer_instance.grid_size &&
  tile.px.y < layer_instance.c_hei * layer_instance.grid_size
}
