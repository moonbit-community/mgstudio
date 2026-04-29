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
test "gizmos_render boundary exposes render systems and plugin entry" {
  let app = @app.App::new(@ecs.World::new())
  let _ = @gizmos_render.gizmo_render_plugin(app)
  let _set2d = @gizmos_render.gizmo_render_system_set(
    @gizmos_render.GizmoRenderSystems::QueueLineGizmos2d,
  )
  let _set3d = @gizmos_render.gizmo_render_system_set(
    @gizmos_render.GizmoRenderSystems::QueueLineGizmos3d,
  )
  ignore(_set2d)
  ignore(_set3d)
}

///|
test "extract_line_gizmos spawns Bevy-shaped temporary render entities" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! world.set(entity, @gizmos.Gizmo::default())
  try! world.set(entity, @transform.GlobalTransform::identity())
  @gizmos_render.extract_line_gizmos(world)
  let query : @ecs.Query[
    (
      @ecs.Comp[@gizmos_render.LineGizmoUniform],
      @ecs.Comp[@gizmos.GizmoMeshConfig],
      @ecs.Comp[@render.MainEntity],
      @ecs.Comp[@render.TemporaryRenderEntity],
    ),
    @ecs.All,
  ] = @ecs.query(world)
  let count = Ref::new(0)
  let line_width = Ref::new(0.0F)
  let depth_bias = Ref::new(1.0F)
  let line_perspective = Ref::new(true)
  let main_entity_matches = Ref::new(false)
  try! query.view(fn(_render_entity, data) {
    let (uniform, mesh_config, main_entity, _temporary) = data
    count.val = count.val + 1
    line_width.val = uniform.value().line_width()
    depth_bias.val = uniform.value().depth_bias()
    line_perspective.val = mesh_config.value().line_perspective()
    main_entity_matches.val = main_entity.value().id() == entity
  })
  debug_inspect(line_width.val, content="2")
  debug_inspect(depth_bias.val, content="0")
  debug_inspect(line_perspective.val, content="false")
  debug_inspect(main_entity_matches.val, content="true")
  debug_inspect(count.val, content="1")
}

///|
test "extract_line_gizmos preserves dashed scale values" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! world.set(
    entity,
    @gizmos.Gizmo::default().with_line_config(@gizmos.GizmoLineConfig::{
      width: 2.0F,
      perspective: false,
      style: @gizmos.GizmoLineStyle::Dashed(gap_scale=-2.0F, line_scale=0.0F),
      joints: @gizmos.GizmoLineJoint::None,
    }),
  )
  try! world.set(entity, @transform.GlobalTransform::identity())
  @gizmos_render.extract_line_gizmos(world)
  let query : @ecs.Query[@ecs.Comp[@gizmos_render.LineGizmoUniform], @ecs.All] = @ecs.query(
    world,
  )
  let gap_scale = Ref::new(1.0F)
  let line_scale = Ref::new(1.0F)
  try! query.view(fn(_render_entity, uniform) {
    gap_scale.val = uniform.value().gap_scale()
    line_scale.val = uniform.value().line_scale()
  })
  debug_inspect(gap_scale.val, content="-2")
  debug_inspect(line_scale.val, content="0")
}
