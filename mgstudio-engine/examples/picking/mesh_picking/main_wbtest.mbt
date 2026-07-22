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
test "mesh_picking: setup matches the Bevy scene topology" {
  let mut app = mesh_picking_app()
  app = app.run_once()
  let world = app.world()
  let shape_count = Ref(0)
  let shape_mesh_count = Ref(0)
  let shape_material_count = Ref(0)
  let primitive_row_count = Ref(0)
  let extrusion_row_count = Ref(0)
  let material_key : @ecs.ComponentKey[
    @pbr.MeshMaterial3dTyped[@pbr.StandardMaterial],
  ] = @pbr.MeshMaterial3dTyped::component()
  world.for_each_component(ecs_key_shape, fn(entity, _shape) {
    shape_count.val = shape_count.val + 1
    if (world.contains_by_key(entity, @mesh.Mesh3d::component()) catch {
        _ => false
      }) {
      shape_mesh_count.val = shape_mesh_count.val + 1
    }
    if (world.contains_by_key(entity, material_key) catch { _ => false }) {
      shape_material_count.val = shape_material_count.val + 1
    }
    guard (world.get_by_key(entity, @transform.Transform::component()) catch {
        _ => None
      })
      is Some(transform) else {
      abort("expected a shape transform")
    }
    if transform.translation.z == Z_EXTENT / 2.0F {
      primitive_row_count.val = primitive_row_count.val + 1
    }
    if transform.translation.z == -Z_EXTENT / 2.0F {
      extrusion_row_count.val = extrusion_row_count.val + 1
    }
  })

  let ignored_ground_count = Ref(0)
  world.for_each_component(@picking.Pickable::component(), fn(
    entity,
    pickable,
  ) {
    if pickable == @picking.pickable_ignore &&
      (world.contains_by_key(entity, @mesh.Mesh3d::component()) catch {
        _ => false
      }) &&
      !(world.contains_by_key(entity, ecs_key_shape) catch { _ => false }) {
      ignored_ground_count.val = ignored_ground_count.val + 1
    }
  })

  let instruction_count = Ref(0)
  world.for_each_component(@text.Text::component(), fn(_entity, text) {
    if text.content == "Hover over the shapes to pick them\nDrag to rotate" {
      instruction_count.val = instruction_count.val + 1
    }
  })

  debug_inspect(shape_count.val, content="16")
  debug_inspect(shape_mesh_count.val, content="16")
  debug_inspect(shape_material_count.val, content="16")
  debug_inspect(primitive_row_count.val, content="9")
  debug_inspect(extrusion_row_count.val, content="7")
  debug_inspect(ignored_ground_count.val, content="1")
  debug_inspect(instruction_count.val, content="1")
}

///|
test "mesh_picking: entity observers update material and drag rotation" {
  let mut app = mesh_picking_app()
  app = app.run_once()
  let world = app.world()
  let shape_entity : Ref[@core.Entity?] = Ref(None)
  world.for_each_component(ecs_key_shape, fn(entity, _shape) {
    if shape_entity.val is None {
      shape_entity.val = Some(entity)
    }
  })
  guard shape_entity.val is Some(entity) else { abort("expected a shape") }
  let material_key : @ecs.ComponentKey[
    @pbr.MeshMaterial3dTyped[@pbr.StandardMaterial],
  ] = @pbr.MeshMaterial3dTyped::component()
  guard (try! world.get_by_key(entity, material_key)) is Some(initial_material) else {
    abort("expected shape material")
  }
  let initial_material_id = initial_material.handle().id()

  let over_events = @app.PickingEvents::PickingEvents()
  over_events.push(
    @pointer_events.PointerEvent::new(
      0,
      Enter,
      @math.Vec2::new(10.0F, 20.0F),
      target=Some(entity),
    ),
  )
  @app.get_picking_events_resource(world).insert(over_events)
  @app.dispatch_pointer_observers_system(world)
  guard (try! world.get_by_key(entity, material_key)) is Some(hover_material) else {
    abort("expected hover material")
  }
  let hover_material_id = hover_material.handle().id()
  assert_true(hover_material_id != initial_material_id)

  guard (try! world.get_by_key(entity, @transform.Transform::component()))
    is Some(initial_transform) else {
    abort("expected shape transform")
  }
  let initial_rotation = initial_transform.rotation
  let drag_events = @app.PickingEvents::PickingEvents()
  drag_events.push(
    @pointer_events.PointerEvent::new(
      0,
      Drag,
      @math.Vec2::new(18.0F, 25.0F),
      target=Some(entity),
      delta=@math.Vec2::new(8.0F, 5.0F),
      distance=@math.Vec2::new(8.0F, 5.0F),
    ),
  )
  @app.get_picking_events_resource(world).insert(drag_events)
  @app.dispatch_pointer_observers_system(world)
  guard (try! world.get_by_key(entity, @transform.Transform::component()))
    is Some(dragged_transform) else {
    abort("expected dragged transform")
  }
  assert_true(
    dragged_transform.rotation.x != initial_rotation.x ||
    dragged_transform.rotation.y != initial_rotation.y ||
    dragged_transform.rotation.z != initial_rotation.z ||
    dragged_transform.rotation.w != initial_rotation.w,
  )
}
