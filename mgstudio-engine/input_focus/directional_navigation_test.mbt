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
fn make_directional_navigation_app() -> @app.App[@ecs.World] {
  directional_navigation_plugin(
    input_dispatch_plugin(@app.App::new(@ecs.World::new())),
  )
}

///|
fn directional_navigation_focus(world : @ecs.World) -> @core.Entity? {
  match (try! world.get_resource(InputFocus::resource())) {
    Some(focus) => focus.get()
    None => None
  }
}

///|
fn set_directional_navigation_focus(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  match (try! world.get_resource_mut(InputFocus::resource())) {
    Some(focus) => focus.modify(fn(value) { value.set(entity) })
    None => abort("missing InputFocus resource")
  }
}

///|
fn directional_navigation_map_ref(
  world : @ecs.World,
) -> @ecs.ResourceMut[DirectionalNavigationMap] {
  match (try! world.get_resource_mut(DirectionalNavigationMap::resource())) {
    Some(map) => map
    None => abort("missing DirectionalNavigationMap resource")
  }
}

///|
fn navigate_direction(
  world : @ecs.World,
  direction : @math.CompassOctant,
) -> @core.Entity? {
  let result : Ref[@core.Entity?] = Ref(None)
  try! @app.run_system_once_param(world, fn(nav : DirectionalNavigation) {
    result.val = try nav.navigate(direction) catch {
      _ => None
    } noraise {
      value => Some(value)
    }
  })
  result.val
}

///|
test "directional_navigation_map supports manual edges and removal" {
  let app = make_directional_navigation_app()
  let world = app.world()
  let a = world.spawn()
  let b = world.spawn()
  let c = world.spawn()
  let map_ref = directional_navigation_map_ref(world)

  map_ref.modify(fn(value) {
    value.add_symmetrical_edge(a, b, @math.CompassOctant::East)
    value.add_edge(b, c, @math.CompassOctant::South)
  })

  debug_inspect(
    map_ref.peek().get_neighbor(a, @math.CompassOctant::East) == Some(b),
    content="true",
  )
  debug_inspect(
    map_ref.peek().get_neighbor(b, @math.CompassOctant::West) == Some(a),
    content="true",
  )
  debug_inspect(
    map_ref.peek().get_neighbor(b, @math.CompassOctant::South) == Some(c),
    content="true",
  )

  map_ref.modify(fn(value) { value.remove(b) })

  debug_inspect(
    map_ref.peek().get_neighbor(a, @math.CompassOctant::East) is None,
    content="true",
  )
  debug_inspect(
    map_ref.peek().get_neighbor(c, @math.CompassOctant::North) is None,
    content="true",
  )
}

///|
test "directional_navigation navigate follows manual map and updates focus" {
  let app = make_directional_navigation_app()
  let world = app.world()
  let a = world.spawn()
  let b = world.spawn()
  set_directional_navigation_focus(world, a)
  directional_navigation_map_ref(world).modify(fn(value) {
    value.add_edge(a, b, @math.CompassOctant::East)
  })

  debug_inspect(
    navigate_direction(world, @math.CompassOctant::East) == Some(b),
    content="true",
  )
  debug_inspect(directional_navigation_focus(world) == Some(b), content="true")
}

///|
test "auto_generate_navigation_edges connects nearest candidate without overwriting manual edges" {
  let app = make_directional_navigation_app()
  let world = app.world()
  let origin = world.spawn()
  let east = world.spawn()
  let south = world.spawn()
  let manual = world.spawn()
  let config = AutoNavigationConfig::default()
  let nodes = [
    FocusableArea::new(
      origin,
      @math.Vec2::new(50.0F, 50.0F),
      @math.Vec2::new(40.0F, 40.0F),
    ),
    FocusableArea::new(
      east,
      @math.Vec2::new(200.0F, 50.0F),
      @math.Vec2::new(40.0F, 40.0F),
    ),
    FocusableArea::new(
      south,
      @math.Vec2::new(50.0F, 200.0F),
      @math.Vec2::new(40.0F, 40.0F),
    ),
    FocusableArea::new(
      manual,
      @math.Vec2::new(400.0F, 50.0F),
      @math.Vec2::new(40.0F, 40.0F),
    ),
  ]
  let map_ref = directional_navigation_map_ref(world)
  map_ref.modify(fn(value) {
    value.add_edge(origin, manual, @math.CompassOctant::East)
  })

  auto_generate_navigation_edges(map_ref.peek(), nodes, config)

  debug_inspect(
    map_ref.peek().get_neighbor(origin, @math.CompassOctant::East) ==
    Some(manual),
    content="true",
  )
  debug_inspect(
    map_ref.peek().get_neighbor(origin, @math.CompassOctant::South) ==
    Some(south),
    content="true",
  )
}
