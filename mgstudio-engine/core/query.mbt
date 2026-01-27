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
