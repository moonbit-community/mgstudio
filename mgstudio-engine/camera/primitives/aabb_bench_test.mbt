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
test "bench camera primitives: rebuild and compare Aabbs" (b : @bench.T) {
  let aabb_count = 20_000
  let aabbs = Array::make(
    aabb_count,
    Aabb::from_min_max(@math.Vec3::zero(), @math.Vec3::zero()),
  )
  b.bench(name="rebuild and compare Aabbs x20000", count=100U, () => {
    let mut changed = 0
    for index in 0..<aabbs.length() {
      let x = Float::from_int(index)
      let next = Aabb::from_min_max(
        @math.Vec3::new(x - 1.0F, -2.0F, 0.0F),
        @math.Vec3::new(x + 1.0F, 2.0F, 0.0F),
      )
      if !aabbs[index].equals(next) {
        aabbs[index] = next
        changed = changed + 1
      }
    }
    b.keep(changed)
  })
}

///|
test "bench camera primitives: rebuild and compare scalar Aabbs" (b : @bench.T) {
  let aabb_count = 20_000
  let aabbs = Array::make(
    aabb_count,
    Aabb::from_min_max_xyz(0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F),
  )
  b.bench(name="rebuild and compare scalar Aabbs x20000", count=100U, () => {
    let mut changed = 0
    for index in 0..<aabbs.length() {
      let x = Float::from_int(index)
      let next = Aabb::from_min_max_xyz(
        x - 1.0F,
        -2.0F,
        0.0F,
        x + 1.0F,
        2.0F,
        0.0F,
      )
      if !aabbs[index].equals(next) {
        aabbs[index] = next
        changed = changed + 1
      }
    }
    b.keep(changed)
  })
}
