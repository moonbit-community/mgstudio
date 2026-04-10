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
fn test_tile_instance(px_x : Int, px_y : Int, t : Int) -> TileInstance {
  let json = "{\"__px\":[" +
    px_x.to_string() +
    "," +
    px_y.to_string() +
    "],\"src\":[" +
    px_x.to_string() +
    "," +
    px_y.to_string() +
    "],\"f\":0,\"t\":" +
    t.to_string() +
    ",\"d\":[]}"
  ldtk_decode_tile_instance(try! @json.parse(json))
}

///|
fn test_layer_instance() -> LayerInstance {
  ldtk_decode_layer_instance(
    try! @json.parse(
      "{\"__cHei\":3,\"__cWid\":2,\"__gridSize\":16,\"__identifier\":\"TestLayer\",\"__opacity\":1.0,\"__pxTotalOffsetX\":0,\"__pxTotalOffsetY\":0,\"__tilesetDefUid\":null,\"__tilesetRelPath\":null,\"__type\":\"Tiles\",\"iid\":\"layer-iid\",\"layerDefUid\":10,\"levelId\":42,\"optionalRules\":[],\"overrideTilesetUid\":null,\"pxOffsetX\":0,\"pxOffsetY\":0,\"seed\":7,\"visible\":true,\"intGridCsv\":[],\"gridTiles\":[],\"autoLayerTiles\":[],\"entityInstances\":[]}",
    ),
  )
}

///|
fn test_tile_tags(tiles : Array[TileInstance]) -> Array[Int] {
  let tags : Array[Int] = []
  for tile in tiles {
    tags.push(tile.t)
  }
  tags
}

///|
test "tile makers: layer_grid_tiles keep stable sublayers for overlapping tiles" {
  let layered = layer_grid_tiles([
    test_tile_instance(0, 0, 1),
    test_tile_instance(16, 0, 2),
    test_tile_instance(0, 0, 3),
    test_tile_instance(16, 0, 4),
    test_tile_instance(0, 0, 5),
  ])

  debug_inspect(layered.length(), content="3")
  debug_inspect(test_tile_tags(layered[0]), content="[1, 2]")
  debug_inspect(test_tile_tags(layered[1]), content="[3, 4]")
  debug_inspect(test_tile_tags(layered[2]), content="[5]")
}

///|
test "tile makers: tile_in_layer_bounds follows layer dimensions" {
  let layer = test_layer_instance()

  debug_inspect(
    tile_in_layer_bounds(test_tile_instance(0, 0, 1), layer),
    content="true",
  )
  debug_inspect(
    tile_in_layer_bounds(test_tile_instance(31, 47, 2), layer),
    content="true",
  )
  debug_inspect(
    tile_in_layer_bounds(test_tile_instance(-1, 0, 3), layer),
    content="false",
  )
  debug_inspect(
    tile_in_layer_bounds(test_tile_instance(32, 0, 4), layer),
    content="false",
  )
  debug_inspect(
    tile_in_layer_bounds(test_tile_instance(0, 48, 5), layer),
    content="false",
  )
}
