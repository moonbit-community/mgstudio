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
fn mesh3d_test_rectangle() -> Mesh3dGeometry {
  Mesh3dGeometry::new(
    [
      @math.Vec3::new(-1.0F, -2.0F, 0.0F),
      @math.Vec3::new(1.0F, -2.0F, 0.0F),
      @math.Vec3::new(1.0F, 2.0F, 0.0F),
      @math.Vec3::new(-1.0F, -2.0F, 0.0F),
      @math.Vec3::new(1.0F, 2.0F, 0.0F),
      @math.Vec3::new(-1.0F, 2.0F, 0.0F),
    ],
    [
      @math.Vec2::new(0.0F, 1.0F),
      @math.Vec2::new(1.0F, 1.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 0.0F),
    ],
    None,
  )
}

///|
fn mesh3d_test_line_strip() -> Mesh3dGeometry {
  Mesh3dGeometry::new_with_topology(
    [
      @math.Vec3::new(2.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 2.0F, 0.0F),
      @math.Vec3::new(-2.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, -2.0F, 0.0F),
      @math.Vec3::new(2.0F, 0.0F, 0.0F),
    ],
    [
      @math.Vec2::zero(),
      @math.Vec2::zero(),
      @math.Vec2::zero(),
      @math.Vec2::zero(),
      @math.Vec2::zero(),
    ],
    None,
    Mesh3dPrimitiveTopology::LineStrip,
  )
}

///|
test "mesh: Mesh3dGeometry::flatten_interleaved_xyz_normal_uv_rgba emits flat triangle normals" {
  let geometry = mesh3d_test_rectangle()
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
  let geometry = mesh3d_test_line_strip()
  match geometry.flatten_interleaved_xyz_normal_uv_rgba() {
    Some(values) => {
      debug_inspect(values.length() % 12, content="0")
      debug_inspect((values[3], values[4], values[5]), content="(0, 0, 1)")
    }
    None => abort("expected line-strip normal-aware flatten data")
  }
}
