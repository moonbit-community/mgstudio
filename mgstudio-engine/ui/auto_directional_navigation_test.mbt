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
fn make_auto_directional_navigation_app() -> @app.App[@ecs.World] {
  @input_focus.directional_navigation_plugin(
    @input_focus.input_dispatch_plugin(@app.App::new(@ecs.World::new())),
  )
}

///|
fn set_auto_navigation_focus(world : @ecs.World, entity : @core.Entity) -> Unit {
  match (try! world.get_resource_ref_mut(@input_focus.InputFocus::resource())) {
    Some(focus_ref) => focus_ref.val.set(entity)
    None => abort("missing InputFocus resource")
  }
}

///|
fn auto_navigation_focus(world : @ecs.World) -> @core.Entity? {
  match (try! world.get_resource(@input_focus.InputFocus::resource())) {
    Some(focus) => focus.get()
    None => None
  }
}

///|
fn insert_auto_navigation_node(
  world : @ecs.World,
  entity : @core.Entity,
  rect : @math.Rect,
) -> Unit {
  try! (world
  .entity_mut(entity)
  .insert(
    (
      AutoDirectionalNavigation::default(),
      UiLayout::new(rect),
      @visibility.InheritedVisibility::new(true),
    ),
  )
  |> ignore)
}

///|
fn navigate_auto(
  world : @ecs.World,
  direction : @math.CompassOctant,
) -> @core.Entity? {
  let result : Ref[@core.Entity?] = Ref::new(None)
  try! @app.run_system_once_param(world, fn(nav : AutoDirectionalNavigator) {
    result.val = try nav.navigate(direction) catch {
      _ => None
    } noraise {
      value => Some(value)
    }
  })
  result.val
}

///|
test "auto directional navigator selects the nearest visible candidate" {
  let app = make_auto_directional_navigation_app()
  let world = app.world()
  let origin = world.spawn()
  let east = world.spawn()
  let far_east = world.spawn()
  let south = world.spawn()

  insert_auto_navigation_node(
    world,
    origin,
    @math.Rect::new(@math.Vec2::new(0.0F, 0.0F), @math.Vec2::new(100.0F, 80.0F)),
  )
  insert_auto_navigation_node(
    world,
    east,
    @math.Rect::new(
      @math.Vec2::new(180.0F, 10.0F),
      @math.Vec2::new(280.0F, 90.0F),
    ),
  )
  insert_auto_navigation_node(
    world,
    far_east,
    @math.Rect::new(
      @math.Vec2::new(420.0F, 10.0F),
      @math.Vec2::new(520.0F, 90.0F),
    ),
  )
  insert_auto_navigation_node(
    world,
    south,
    @math.Rect::new(
      @math.Vec2::new(0.0F, 200.0F),
      @math.Vec2::new(100.0F, 280.0F),
    ),
  )
  set_auto_navigation_focus(world, origin)

  inspect(
    navigate_auto(world, @math.CompassOctant::East) == Some(east),
    content="true",
  )
  inspect(auto_navigation_focus(world) == Some(east), content="true")
}

///|
test "auto directional navigator respects manual override edges first" {
  let app = make_auto_directional_navigation_app()
  let world = app.world()
  let origin = world.spawn()
  let east = world.spawn()
  let manual = world.spawn()

  insert_auto_navigation_node(
    world,
    origin,
    @math.Rect::new(@math.Vec2::new(0.0F, 0.0F), @math.Vec2::new(100.0F, 80.0F)),
  )
  insert_auto_navigation_node(
    world,
    east,
    @math.Rect::new(
      @math.Vec2::new(180.0F, 0.0F),
      @math.Vec2::new(280.0F, 80.0F),
    ),
  )
  insert_auto_navigation_node(
    world,
    manual,
    @math.Rect::new(
      @math.Vec2::new(600.0F, 0.0F),
      @math.Vec2::new(700.0F, 80.0F),
    ),
  )
  set_auto_navigation_focus(world, origin)

  match
    (try! world.get_resource_ref_mut(
      @input_focus.DirectionalNavigationMap::resource(),
    )) {
    Some(map_ref) =>
      map_ref.val.add_edge(origin, manual, @math.CompassOctant::East)
    None => abort("missing DirectionalNavigationMap resource")
  }

  inspect(
    navigate_auto(world, @math.CompassOctant::East) == Some(manual),
    content="true",
  )
  inspect(auto_navigation_focus(world) == Some(manual), content="true")
}
