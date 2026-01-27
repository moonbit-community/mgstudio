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
test "query: query2 iterates intersection" {
  let entities = Entities::new()
  let e1 = entities.spawn()
  let e2 = entities.spawn()
  let e3 = entities.spawn()
  let a : ComponentStore[Int] = ComponentStore::new()
  let b : ComponentStore[Int] = ComponentStore::new()
  a.insert(e1, 10, 1)
  a.insert(e2, 20, 1)
  b.insert(e2, 200, 1)
  b.insert(e3, 300, 1)
  let hits : Ref[Int] = Ref::new(0)
  query2(a, b, fn(_e, av, bv) { hits.val = hits.val + av + bv })
  inspect(hits.val == 220, content="true")
}

///|
test "query: query2_changed_a filters by A changed ticks" {
  let entities = Entities::new()
  let e = entities.spawn()
  let a : ComponentStore[Int] = ComponentStore::new()
  let b : ComponentStore[Int] = ComponentStore::new()
  a.insert(e, 1, 1)
  b.insert(e, 2, 1)

  // Outside range: should not hit
  let hits1 : Ref[Int] = Ref::new(0)
  query2_changed_a(a, b, SystemTicks::new(1, 2), fn(_e, _av, _bv) {
    hits1.val = hits1.val + 1
  })
  inspect(hits1.val == 0, content="true")

  // Mark A changed at tick 3 and query in range.
  a.set(e, 1, 3) |> ignore
  let hits2 : Ref[Int] = Ref::new(0)
  query2_changed_a(a, b, SystemTicks::new(2, 3), fn(_e, _av, _bv) {
    hits2.val = hits2.val + 1
  })
  inspect(hits2.val == 1, content="true")
}
