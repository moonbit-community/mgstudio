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

///|
test "query: query3 iterates triple intersection" {
  let entities = Entities::new()
  let e1 = entities.spawn()
  let e2 = entities.spawn()
  let a : ComponentStore[Int] = ComponentStore::new()
  let b : ComponentStore[Int] = ComponentStore::new()
  let c : ComponentStore[Int] = ComponentStore::new()
  a.insert(e1, 10, 1)
  a.insert(e2, 20, 1)
  b.insert(e2, 30, 1)
  c.insert(e2, 40, 1)
  let sum : Ref[Int] = Ref::new(0)
  query3(a, b, c, fn(_e, av, bv, cv) { sum.val = sum.val + av + bv + cv })
  inspect(sum.val == 90, content="true")
}

///|
test "query: query2_single returns only for exactly one result" {
  let entities = Entities::new()
  let e1 = entities.spawn()
  let e2 = entities.spawn()
  let a : ComponentStore[Int] = ComponentStore::new()
  let b : ComponentStore[Int] = ComponentStore::new()
  a.insert(e1, 10, 1)
  b.insert(e1, 20, 1)
  inspect(
    query2_single(a, b) is Some((_e, av, bv)) && av == 10 && bv == 20,
    content="true",
  )
  a.insert(e2, 30, 1)
  b.insert(e2, 40, 1)
  inspect(query2_single(a, b) is None, content="true")
}

///|
test "query: query2_update_a rewrites first store in-place style" {
  let entities = Entities::new()
  let e = entities.spawn()
  let a : ComponentStore[Int] = ComponentStore::new()
  let b : ComponentStore[Int] = ComponentStore::new()
  a.insert(e, 1, 1)
  b.insert(e, 3, 1)
  query2_update_a(a, b, 2, fn(_e, av, bv) { av + bv })
  inspect(a.get(e) == Some(4), content="true")
  inspect(
    a.get_ticks(e) is Some(ticks) && ticks.is_changed(SystemTicks::new(1, 2)),
    content="true",
  )
}

///|
test "query: query2_update_b rewrites second store in-place style" {
  let entities = Entities::new()
  let e = entities.spawn()
  let a : ComponentStore[Int] = ComponentStore::new()
  let b : ComponentStore[Int] = ComponentStore::new()
  a.insert(e, 4, 1)
  b.insert(e, 5, 1)
  query2_update_b(a, b, 2, fn(_e, av, bv) { av + bv })
  inspect(b.get(e) == Some(9), content="true")
  inspect(
    b.get_ticks(e) is Some(ticks) && ticks.is_changed(SystemTicks::new(1, 2)),
    content="true",
  )
}

///|
test "query: query2_update_ab rewrites both stores in one pass" {
  let entities = Entities::new()
  let e = entities.spawn()
  let a : ComponentStore[Int] = ComponentStore::new()
  let b : ComponentStore[Int] = ComponentStore::new()
  a.insert(e, 1, 1)
  b.insert(e, 2, 1)
  query2_update_ab(a, b, 3, fn(_e, av, bv) { (av + 10, bv + 20) })
  inspect(a.get(e) == Some(11), content="true")
  inspect(b.get(e) == Some(22), content="true")
}
