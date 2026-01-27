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
test "resource: insert/get/remove" {
  let res : Resource[Int] = Resource::new()
  inspect(res.is_present(), content="false")
  res.insert(7, 1)
  inspect(res.is_present(), content="true")
  inspect(res.get().unwrap() == 7, content="true")
  inspect(res.remove().unwrap() == 7, content="true")
  inspect(res.is_present(), content="false")
}

///|
test "resource: change ticks update on insert and mut access" {
  let res : Resource[Int] = Resource::new()
  res.insert(1, 10)
  let t1 = res.ticks()
  inspect(t1.is_added(SystemTicks::new(0, 10)), content="true")
  inspect(t1.is_changed(SystemTicks::new(0, 10)), content="true")

  // Mut access updates changed tick.
  let _r = res.get_ref_mut(20).unwrap()
  let t2 = res.ticks()
  inspect(t2.is_added(SystemTicks::new(10, 20)), content="false")
  inspect(t2.is_changed(SystemTicks::new(10, 20)), content="true")
}
