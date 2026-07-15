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
enum DemandDrivenChangedMarker {
  Marker
}

///|
let demand_driven_changed_marker_key : ComponentKey[DemandDrivenChangedMarker] = register_component(
  debug_name="demand_driven_changed_marker",
)

///|
test "ecs changed components: tick scan preserves first and repeated reads" {
  let world = World::new()
  defer world.close()
  let entity = world.spawn()

  try! world.set_by_key(
    entity,
    demand_driven_changed_marker_key,
    DemandDrivenChangedMarker::Marker,
  )

  let first = world
    .changed_components(
      demand_driven_changed_marker_key,
      @core.SystemTicks::new(0, 1),
    )
    .read()
  debug_inspect(first, content="[{ id: 0, generation: 1 }]")
  let repeated = world
    .changed_components(
      demand_driven_changed_marker_key,
      @core.SystemTicks::new(0, 1),
    )
    .read()
  debug_inspect(repeated, content="[{ id: 0, generation: 1 }]")

  world.increment_change_tick() |> ignore
  world.increment_change_tick() |> ignore
  debug_inspect(
    try! world.replace(
      entity,
      demand_driven_changed_marker_key,
      DemandDrivenChangedMarker::Marker,
    ),
    content="true",
  )
  let second = world
    .changed_components(
      demand_driven_changed_marker_key,
      @core.SystemTicks::new(1, 2),
    )
    .read()
  debug_inspect(second, content="[{ id: 0, generation: 1 }]")
}
