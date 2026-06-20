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
  let assets_key : @ecs.ResourceKey[@asset.Assets[@gizmos.GizmoAsset]] = @asset.assets_resource_key()
  world.insert_resource(assets_key, @asset.Assets::new())
  let asset = @gizmos.GizmoAsset::GizmoAsset()
  let handle = match world.get_resource_mut(assets_key) {
    Some(assets_ref) => assets_ref.modify(fn(assets) { assets.add(asset) })
    None => abort("Missing GizmoAsset store in test")
  }
  let entity = world.spawn()
  try! world.set(
    entity,
    @gizmos.Gizmo::Gizmo()
    .with_handle(handle)
    .with_depth_bias(-0.25F)
    .with_line_config(@gizmos.GizmoLineConfig::{
      width: 7.0F,
      perspective: true,
      style: @gizmos.GizmoLineStyle::Dashed(gap_scale=3.0F, line_scale=5.0F),
      joints: @gizmos.GizmoLineJoint::Round(6),
    }),
  )
  try! world.set(entity, @transform.GlobalTransform::identity())
  try! world.set(entity, @camera_render_layers.RenderLayers::layer(3))
  @gizmos_render.extract_line_gizmos(world)
  let query : @ecs.Query[
    (
      @ecs.Read[@gizmos_render.LineGizmoUniform],
      @ecs.Read[@gizmos.GizmoMeshConfig],
      @ecs.Read[@render.MainEntity],
      @ecs.Read[@render.TemporaryRenderEntity],
    ),
    @ecs.All,
  ] = @ecs.query(world)
  let count = Ref(0)
  let line_width = Ref(0.0F)
  let depth_bias = Ref(0.0F)
  let joints_resolution = Ref(0)
  let line_perspective = Ref(false)
  let render_layers_match = Ref(false)
  let handle_match = Ref(false)
  let main_entity_matches = Ref(false)
  try! query.view(fn(_render_entity, data) {
    let (uniform, mesh_config, main_entity, _temporary) = data
    count.val = count.val + 1
    line_width.val = uniform.value().line_width()
    depth_bias.val = uniform.value().depth_bias()
    joints_resolution.val = uniform.value().joints_resolution()
    line_perspective.val = mesh_config.value().line_perspective()
    render_layers_match.val = mesh_config.value().render_layers().contains(3)
    handle_match.val = mesh_config.value().handle().id() == handle.id()
    main_entity_matches.val = main_entity.value().id() == entity
  })
  debug_inspect(line_width.val, content="7")
  debug_inspect(depth_bias.val, content="-0.25")
  debug_inspect(joints_resolution.val, content="6")
  debug_inspect(line_perspective.val, content="true")
  debug_inspect(render_layers_match.val, content="true")
  debug_inspect(handle_match.val, content="true")
  debug_inspect(main_entity_matches.val, content="true")
  debug_inspect(count.val, content="1")
}

///|
test "extract_line_gizmos preserves dashed scale values" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! world.set(
    entity,
    @gizmos.Gizmo::Gizmo().with_line_config(@gizmos.GizmoLineConfig::{
      width: 2.0F,
      perspective: false,
      style: @gizmos.GizmoLineStyle::Dashed(gap_scale=2.0F, line_scale=4.0F),
      joints: @gizmos.GizmoLineJoint::None,
    }),
  )
  try! world.set(entity, @transform.GlobalTransform::identity())
  @gizmos_render.extract_line_gizmos(world)
  let query : @ecs.Query[@ecs.Read[@gizmos_render.LineGizmoUniform], @ecs.All] = @ecs.query(
    world,
  )
  let gap_scale = Ref(1.0F)
  let line_scale = Ref(1.0F)
  try! query.view(fn(_render_entity, uniform) {
    gap_scale.val = uniform.value().gap_scale()
    line_scale.val = uniform.value().line_scale()
  })
  debug_inspect(gap_scale.val, content="2")
  debug_inspect(line_scale.val, content="4")
}

///|
test "queue_line_gizmos consumes extracted GizmoMeshConfig-backed assets" {
  let world = @ecs.World::new()
  let assets_key : @ecs.ResourceKey[@asset.Assets[@gizmos.GizmoAsset]] = @asset.assets_resource_key()
  world.insert_resource(assets_key, @asset.Assets::new())
  let asset = @gizmos.GizmoAsset::GizmoAsset()
  asset.line(
    @math.Vec3::zero(),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    @color.Color::white(),
  )
  let handle = match world.get_resource_mut(assets_key) {
    Some(assets_ref) => assets_ref.modify(fn(assets) { assets.add(asset) })
    None => abort("Missing GizmoAsset store in test")
  }
  let entity = world.spawn()
  try! world.set(entity, @gizmos.Gizmo::Gizmo().with_handle(handle))
  try! world.set(entity, @transform.GlobalTransform::identity())
  @gizmos_render.extract_line_gizmos(world)
  @sprite.gizmos_reset()
  debug_inspect(@gizmos_render.queue_line_gizmos_3d(world), content="1")
  @sprite.gizmos_reset()
  debug_inspect(@gizmos_render.queue_line_gizmos_2d(world), content="1")
}
