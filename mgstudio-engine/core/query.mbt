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
/// Minimal query helpers for `ComponentStore`-based worlds.
///
/// This is intentionally much smaller than Bevy's full `QueryState/Fetch`
/// machinery, but it supports the iteration patterns needed for incremental
/// engine migration.

///|
pub struct Query1[A] {
  a : ComponentStore[A]
}

///|
pub fn[A] Query1::new(a : ComponentStore[A]) -> Query1[A] {
  { a, }
}

///|
pub fn[A] Query1::for_each(self : Query1[A], f : (Entity, A) -> Unit) -> Unit {
  query1(self.a, f)
}

///|
pub fn[A] Query1::for_each_changed(
  self : Query1[A],
  system : SystemTicks,
  f : (Entity, A) -> Unit,
) -> Unit {
  query1_changed(self.a, system, f)
}

///|
pub fn[A] Query1::for_each_added(
  self : Query1[A],
  system : SystemTicks,
  f : (Entity, A) -> Unit,
) -> Unit {
  query1_added(self.a, system, f)
}

///|
pub fn[A] Query1::single(self : Query1[A]) -> (Entity, A)? {
  query1_single(self.a)
}

///|
pub fn[A] Query1::update(
  self : Query1[A],
  change_tick : Tick,
  f : (Entity, A) -> A,
) -> Unit {
  query1_update(self.a, change_tick, f)
}

///|
pub struct Query2[A, B] {
  a : ComponentStore[A]
  b : ComponentStore[B]
}

///|
pub fn[A, B] Query2::new(
  a : ComponentStore[A],
  b : ComponentStore[B],
) -> Query2[A, B] {
  { a, b }
}

///|
pub fn[A, B] Query2::for_each(
  self : Query2[A, B],
  f : (Entity, A, B) -> Unit,
) -> Unit {
  query2(self.a, self.b, f)
}

///|
pub fn[A, B] Query2::for_each_changed_a(
  self : Query2[A, B],
  system : SystemTicks,
  f : (Entity, A, B) -> Unit,
) -> Unit {
  query2_changed_a(self.a, self.b, system, f)
}

///|
pub fn[A, B] Query2::for_each_changed_b(
  self : Query2[A, B],
  system : SystemTicks,
  f : (Entity, A, B) -> Unit,
) -> Unit {
  query2_changed_b(self.a, self.b, system, f)
}

///|
pub fn[A, B] Query2::single(self : Query2[A, B]) -> (Entity, A, B)? {
  query2_single(self.a, self.b)
}

///|
pub fn[A, B] Query2::update_a(
  self : Query2[A, B],
  change_tick : Tick,
  f : (Entity, A, B) -> A,
) -> Unit {
  query2_update_a(self.a, self.b, change_tick, f)
}

///|
pub fn[A, B] Query2::update_b(
  self : Query2[A, B],
  change_tick : Tick,
  f : (Entity, A, B) -> B,
) -> Unit {
  query2_update_b(self.a, self.b, change_tick, f)
}

///|
pub fn[A, B] Query2::update_ab(
  self : Query2[A, B],
  change_tick : Tick,
  f : (Entity, A, B) -> (A, B),
) -> Unit {
  query2_update_ab(self.a, self.b, change_tick, f)
}

///|
pub struct Query3[A, B, C] {
  a : ComponentStore[A]
  b : ComponentStore[B]
  c : ComponentStore[C]
}

///|
pub fn[A, B, C] Query3::new(
  a : ComponentStore[A],
  b : ComponentStore[B],
  c : ComponentStore[C],
) -> Query3[A, B, C] {
  { a, b, c }
}

///|
pub fn[A, B, C] Query3::for_each(
  self : Query3[A, B, C],
  f : (Entity, A, B, C) -> Unit,
) -> Unit {
  query3(self.a, self.b, self.c, f)
}

///|
pub fn[A] query1(a : ComponentStore[A], f : (Entity, A) -> Unit) -> Unit {
  a.for_each(f)
}

///|
pub fn[A] query1_changed(
  a : ComponentStore[A],
  system : SystemTicks,
  f : (Entity, A) -> Unit,
) -> Unit {
  a.for_each_changed(system, f)
}

///|
pub fn[A] query1_added(
  a : ComponentStore[A],
  system : SystemTicks,
  f : (Entity, A) -> Unit,
) -> Unit {
  a.for_each_added(system, f)
}

///|
pub fn[A] query1_single(a : ComponentStore[A]) -> (Entity, A)? {
  if a.len() != 1 {
    return None
  }
  let mut out : (Entity, A)? = None
  a.for_each(fn(e, value) { out = Some((e, value)) })
  out
}

///|
pub fn[A, B] query2(
  a : ComponentStore[A],
  b : ComponentStore[B],
  f : (Entity, A, B) -> Unit,
) -> Unit {
  // Iterate the smaller store for fewer lookups.
  let la = a.len()
  let lb = b.len()
  if la <= lb {
    a.for_each(fn(e, av) { if b.get(e) is Some(bv) { f(e, av, bv) } })
  } else {
    b.for_each(fn(e, bv) { if a.get(e) is Some(av) { f(e, av, bv) } })
  }
}

///|
pub fn[A, B] query2_changed_a(
  a : ComponentStore[A],
  b : ComponentStore[B],
  system : SystemTicks,
  f : (Entity, A, B) -> Unit,
) -> Unit {
  a.for_each_changed(system, fn(e, av) {
    if b.get(e) is Some(bv) {
      f(e, av, bv)
    }
  })
}

///|
pub fn[A, B] query2_changed_b(
  a : ComponentStore[A],
  b : ComponentStore[B],
  system : SystemTicks,
  f : (Entity, A, B) -> Unit,
) -> Unit {
  b.for_each_changed(system, fn(e, bv) {
    if a.get(e) is Some(av) {
      f(e, av, bv)
    }
  })
}

///|
pub fn[A, B] query2_single(
  a : ComponentStore[A],
  b : ComponentStore[B],
) -> (Entity, A, B)? {
  let mut out : (Entity, A, B)? = None
  let mut hit_count = 0
  query2(a, b, fn(e, av, bv) {
    hit_count = hit_count + 1
    if hit_count == 1 {
      out = Some((e, av, bv))
    }
  })
  if hit_count == 1 {
    out
  } else {
    None
  }
}

///|
pub fn[A, B, C] query3(
  a : ComponentStore[A],
  b : ComponentStore[B],
  c : ComponentStore[C],
  f : (Entity, A, B, C) -> Unit,
) -> Unit {
  let la = a.len()
  let lb = b.len()
  let lc = c.len()
  if la <= lb && la <= lc {
    a.for_each(fn(e, av) {
      if b.get(e) is Some(bv) && c.get(e) is Some(cv) {
        f(e, av, bv, cv)
      }
    })
    return
  }
  if lb <= la && lb <= lc {
    b.for_each(fn(e, bv) {
      if a.get(e) is Some(av) && c.get(e) is Some(cv) {
        f(e, av, bv, cv)
      }
    })
    return
  }
  c.for_each(fn(e, cv) {
    if a.get(e) is Some(av) && b.get(e) is Some(bv) {
      f(e, av, bv, cv)
    }
  })
}

///|
pub fn[A] query1_update(
  a : ComponentStore[A],
  change_tick : Tick,
  f : (Entity, A) -> A,
) -> Unit {
  let updates : Array[(Entity, A)] = []
  a.for_each(fn(e, value) { updates.push((e, f(e, value))) })
  for update in updates {
    a.set(update.0, update.1, change_tick) |> ignore
  }
}

///|
pub fn[A, B] query2_update_a(
  a : ComponentStore[A],
  b : ComponentStore[B],
  change_tick : Tick,
  f : (Entity, A, B) -> A,
) -> Unit {
  let updates : Array[(Entity, A)] = []
  query2(a, b, fn(e, av, bv) { updates.push((e, f(e, av, bv))) })
  for update in updates {
    a.set(update.0, update.1, change_tick) |> ignore
  }
}

///|
pub fn[A, B] query2_update_b(
  a : ComponentStore[A],
  b : ComponentStore[B],
  change_tick : Tick,
  f : (Entity, A, B) -> B,
) -> Unit {
  let updates : Array[(Entity, B)] = []
  query2(a, b, fn(e, av, bv) { updates.push((e, f(e, av, bv))) })
  for update in updates {
    b.set(update.0, update.1, change_tick) |> ignore
  }
}

///|
pub fn[A, B] query2_update_ab(
  a : ComponentStore[A],
  b : ComponentStore[B],
  change_tick : Tick,
  f : (Entity, A, B) -> (A, B),
) -> Unit {
  let updates : Array[(Entity, A, B)] = []
  query2(a, b, fn(e, av, bv) {
    let next = f(e, av, bv)
    updates.push((e, next.0, next.1))
  })
  for update in updates {
    a.set(update.0, update.1, change_tick) |> ignore
    b.set(update.0, update.2, change_tick) |> ignore
  }
}
