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
test "bench camera visibility: cull Aabb grid" (b : @bench.T) {
  let side = 320
  let transforms : Array[@transform.GlobalTransform] = []
  for y in 0..<side {
    for x in 0..<side {
      transforms.push(
        @transform.GlobalTransform::from_transform(
          @transform.Transform::from_xyz(
            Float::from_int(x - side / 2) * 64.0F,
            Float::from_int(y - side / 2) * 64.0F,
            0.0F,
          ),
        ),
      )
    }
  }
  let frustum = @camera_primitives.Frustum::default_2d()
  let aabb = @camera_primitives.Aabb::from_min_max_xyz(
    -32.0F,
    -32.0F,
    0.0F,
    32.0F,
    32.0F,
    0.0F,
  )
  b.bench(name="cull Aabb grid x102400", count=50U, () => {
    let mut culled = 0
    for transform in transforms {
      if visibility_cull_aabb(frustum, aabb, transform) {
        culled = culled + 1
      }
    }
    b.keep(culled)
  })
}
