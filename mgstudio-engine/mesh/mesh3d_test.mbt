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
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
test "mesh: Mesh3dGeometry::circle lies on the XY plane" {
  let filled = Mesh3dGeometry::circle(2.0F, 4)
  let outline = Mesh3dGeometry::circle_line_strip(2.0F, 4)
  let mut filled_on_xy = true
  let mut outline_on_xy = true
  for position in filled.positions {
    if absf(position.z) > 1.0e-6F {
      filled_on_xy = false
    }
  }
  for position in outline.positions {
    if absf(position.z) > 1.0e-6F {
      outline_on_xy = false
    }
  }
  inspect(
    (filled.positions[1].x, filled.positions[1].y, filled.positions[1].z),
    content="(2, 0, 0)",
  )
  inspect(filled_on_xy, content="true")
  inspect(
    (outline.positions[0].x, outline.positions[0].y, outline.positions[0].z),
    content="(2, 0, 0)",
  )
  inspect(outline_on_xy, content="true")
}

///|
test "mesh: Mesh3dGeometry::cuboid matches primitive size" {
  let geometry = Mesh3dGeometry::cuboid(@math.Cuboid::new(2.0F, 4.0F, 6.0F))
  let mut min_x = geometry.positions[0].x
  let mut max_x = geometry.positions[0].x
  let mut min_y = geometry.positions[0].y
  let mut max_y = geometry.positions[0].y
  let mut min_z = geometry.positions[0].z
  let mut max_z = geometry.positions[0].z
  for position in geometry.positions {
    if position.x < min_x {
      min_x = position.x
    }
    if position.x > max_x {
      max_x = position.x
    }
    if position.y < min_y {
      min_y = position.y
    }
    if position.y > max_y {
      max_y = position.y
    }
    if position.z < min_z {
      min_z = position.z
    }
    if position.z > max_z {
      max_z = position.z
    }
  }
  inspect(geometry.positions.length(), content="36")
  inspect(
    (min_x, max_x, min_y, max_y, min_z, max_z),
    content="(-1, 1, -2, 2, -3, 3)",
  )
}

///|
test "mesh: Mesh3dGeometry::rectangle lies on the XY plane" {
  let geometry = Mesh3dGeometry::rectangle(2.0F, 4.0F)
  let mut on_xy = true
  let mut min_x = geometry.positions[0].x
  let mut max_x = geometry.positions[0].x
  let mut min_y = geometry.positions[0].y
  let mut max_y = geometry.positions[0].y
  for position in geometry.positions {
    if absf(position.z) > 1.0e-6F {
      on_xy = false
    }
    if position.x < min_x {
      min_x = position.x
    }
    if position.x > max_x {
      max_x = position.x
    }
    if position.y < min_y {
      min_y = position.y
    }
    if position.y > max_y {
      max_y = position.y
    }
  }
  inspect(geometry.positions.length(), content="6")
  inspect(on_xy, content="true")
  inspect((min_x, max_x, min_y, max_y), content="(-1, 1, -2, 2)")
}
