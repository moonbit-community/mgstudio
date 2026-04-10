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
  debug_inspect(
    (filled.positions[1].x, filled.positions[1].y, filled.positions[1].z),
    content="(2, 0, 0)",
  )
  debug_inspect(filled_on_xy, content="true")
  debug_inspect(
    (outline.positions[0].x, outline.positions[0].y, outline.positions[0].z),
    content="(2, 0, 0)",
  )
  debug_inspect(outline_on_xy, content="true")
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
  debug_inspect(geometry.positions.length(), content="36")
  debug_inspect(
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
  debug_inspect(geometry.positions.length(), content="6")
  debug_inspect(on_xy, content="true")
  debug_inspect((min_x, max_x, min_y, max_y), content="(-1, 1, -2, 2)")
}

///|
test "mesh: Mesh3dGeometry::flatten_interleaved_xyz_normal_uv_rgba emits flat triangle normals" {
  let geometry = Mesh3dGeometry::rectangle(2.0F, 4.0F)
  match geometry.flatten_interleaved_xyz_normal_uv_rgba() {
    Some(values) => {
      debug_inspect(values.length(), content="72")
      debug_inspect(
        (values[3], values[4], values[5], values[15], values[16], values[17]),
        content="(0, 0, 1, 0, 0, 1)",
      )
    }
    None => abort("expected normal-aware flatten data")
  }
}

///|
test "mesh: Mesh3dGeometry::flatten_interleaved_xyz_normal_uv_rgba gives default line normal" {
  let geometry = Mesh3dGeometry::circle_line_strip(2.0F, 4)
  match geometry.flatten_interleaved_xyz_normal_uv_rgba() {
    Some(values) => {
      debug_inspect(values.length() % 12, content="0")
      debug_inspect((values[3], values[4], values[5]), content="(0, 0, 1)")
    }
    None => abort("expected line-strip normal-aware flatten data")
  }
}
