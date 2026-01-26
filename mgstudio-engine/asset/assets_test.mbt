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
test "assets: insert/get/set/remove and events" {
  let assets : Assets[Int] = Assets::new()
  inspect(assets.is_empty(), content="true")
  let h = assets.add(10)
  inspect(assets.get(h).unwrap(), content="10")
  let ev1 = assets.drain_events()
  inspect(ev1.length(), content="1")
  match ev1[0] {
    AssetEvent::Added(h1) => inspect(h1.id() == h.id(), content="true")
    _ => inspect(false, content="false")
  }
  inspect(assets.set(h, 11), content="true")
  inspect(assets.get(h).unwrap(), content="11")
  let ev2 = assets.drain_events()
  inspect(ev2.length(), content="1")
  match ev2[0] {
    AssetEvent::Modified(h1) => inspect(h1.id() == h.id(), content="true")
    _ => inspect(false, content="false")
  }
  let removed = assets.remove(h).unwrap()
  inspect(removed, content="11")
  inspect(assets.contains(h), content="false")
  let ev3 = assets.drain_events()
  inspect(ev3.length(), content="1")
  match ev3[0] {
    AssetEvent::Removed(h1) => inspect(h1.id() == h.id(), content="true")
    _ => inspect(false, content="false")
  }
}
