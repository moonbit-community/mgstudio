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
fn gizmos_render_u32le_word(bytes : Bytes, word_offset : Int) -> UInt {
  let byte_offset = word_offset * 4
  bytes[byte_offset].to_uint() |
  (bytes[byte_offset + 1].to_uint() << 8) |
  (bytes[byte_offset + 2].to_uint() << 16) |
  (bytes[byte_offset + 3].to_uint() << 24)
}

///|
fn gizmos_render_f32_bits(value : Float) -> UInt {
  value.reinterpret_as_uint()
}

///|
test "gizmos_render embedded wgsl sources are registered" {
  @gizmos_render.register_embedded_wgsl_sources()
  let lines = match
    @shader_source.embedded_shader_source("gizmos_render/lines.wgsl") {
    Some(source) => source
    None => ""
  }
  let joints = match
    @shader_source.embedded_shader_source("gizmos_render/line_joints.wgsl") {
    Some(source) => source
    None => ""
  }
  debug_inspect(lines != "", content="true")
  debug_inspect(joints != "", content="true")
  debug_inspect(
    lines.contains("@group(1) @binding(0) var<uniform> line_gizmo"),
    content="true",
  )
  debug_inspect(
    joints.contains("@group(1) @binding(0) var<uniform> joints_gizmo"),
    content="true",
  )
}

///|
test "gizmos_render boundary exposes render systems and plugin entry" {
  let lifecycle_world_54_0 = @ecs.World::new()
  defer lifecycle_world_54_0.close()
  let app = @app.App::new(lifecycle_world_54_0)
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
  defer world.close()
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
  defer world.close()
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
test "line gizmo uniform bytes match Bevy ShaderType layout" {
  let world = @ecs.World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set(
    entity,
    @gizmos.Gizmo::Gizmo()
    .with_depth_bias(-0.5F)
    .with_line_config(@gizmos.GizmoLineConfig::{
      width: 9.0F,
      perspective: true,
      style: @gizmos.GizmoLineStyle::Dashed(gap_scale=2.0F, line_scale=3.0F),
      joints: @gizmos.GizmoLineJoint::Round(5),
    }),
  )
  let transform = @transform.Transform::from_xyz(5.0F, 6.0F, 7.0F).with_scale(
    @math.Vec3::new(2.0F, 3.0F, 4.0F),
  )
  try! world.set(entity, @transform.GlobalTransform::from_transform(transform))
  @gizmos_render.extract_line_gizmos(world)
  let query : @ecs.Query[@ecs.Read[@gizmos_render.LineGizmoUniform], @ecs.All] = @ecs.query(
    world,
  )
  let packed = Ref(Bytes::make(0, (0).to_byte()))
  try! query.view(fn(_render_entity, uniform) {
    packed.val = @gizmos_render.line_gizmo_uniform_bytes(uniform.value())
  })
  debug_inspect(
    packed.val.length(),
    content="\{@gizmos_render.LINE_GIZMO_UNIFORM_SIZE_BYTES}",
  )
  debug_inspect(gizmos_render_u32le_word(packed.val, 0), content="1073741824")
  debug_inspect(gizmos_render_u32le_word(packed.val, 1), content="0")
  debug_inspect(gizmos_render_u32le_word(packed.val, 2), content="0")
  debug_inspect(gizmos_render_u32le_word(packed.val, 3), content="1084227584")
  debug_inspect(gizmos_render_u32le_word(packed.val, 5), content="1077936128")
  debug_inspect(gizmos_render_u32le_word(packed.val, 7), content="1086324736")
  debug_inspect(gizmos_render_u32le_word(packed.val, 10), content="1082130432")
  debug_inspect(gizmos_render_u32le_word(packed.val, 11), content="1088421888")
  debug_inspect(
    gizmos_render_u32le_word(packed.val, 12),
    content="\{gizmos_render_f32_bits(9.0F)}",
  )
  debug_inspect(
    gizmos_render_u32le_word(packed.val, 13),
    content="\{gizmos_render_f32_bits(-0.5F)}",
  )
  debug_inspect(gizmos_render_u32le_word(packed.val, 14), content="5")
  debug_inspect(
    gizmos_render_u32le_word(packed.val, 15),
    content="\{gizmos_render_f32_bits(2.0F)}",
  )
  debug_inspect(
    gizmos_render_u32le_word(packed.val, 16),
    content="\{gizmos_render_f32_bits(3.0F)}",
  )
  debug_inspect(gizmos_render_u32le_word(packed.val, 17), content="0")
  debug_inspect(gizmos_render_u32le_word(packed.val, 18), content="0")
  debug_inspect(gizmos_render_u32le_word(packed.val, 19), content="0")
}

///|
test "queue_line_gizmos consumes extracted GizmoMeshConfig-backed assets" {
  let world = @ecs.World::new()
  defer world.close()
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

///|
test "GpuLineGizmo source bytes keep Bevy vertex buffer layout sizes" {
  let position_bytes = @gizmos_render.line_gizmo_position_bytes([
    @math.Vec3::new(1.0F, 2.0F, 3.0F),
    @math.Vec3::new(4.0F, 5.0F, 6.0F),
  ])
  let color_bytes = @gizmos_render.line_gizmo_color_bytes([
    @color.linear_rgba_with_alpha(0.1F, 0.2F, 0.3F, 0.4F),
    @color.linear_rgba_with_alpha(0.5F, 0.6F, 0.7F, 0.8F),
  ])
  debug_inspect(position_bytes.length(), content="24")
  debug_inspect(color_bytes.length(), content="32")
}

///|
test "line gizmo vertex buffer layouts mirror Bevy list strip and joint layouts" {
  let list_layouts = @gizmos_render.line_gizmo_vertex_buffer_layouts(false)
  debug_inspect(list_layouts.length(), content="2")
  debug_inspect(list_layouts[0].array_stride(), content="24")
  debug_inspect(list_layouts[0].step_mode() is Instance, content="true")
  debug_inspect(list_layouts[0].attributes().length(), content="2")
  debug_inspect(list_layouts[0].attributes()[1].offset(), content="12")
  debug_inspect(list_layouts[0].attributes()[1].shader_location(), content="1")
  debug_inspect(list_layouts[1].array_stride(), content="32")
  debug_inspect(list_layouts[1].attributes()[1].offset(), content="16")
  debug_inspect(list_layouts[1].attributes()[1].shader_location(), content="3")
  let strip_layouts = @gizmos_render.line_gizmo_vertex_buffer_layouts(true)
  debug_inspect(strip_layouts.length(), content="4")
  debug_inspect(strip_layouts[0].array_stride(), content="12")
  debug_inspect(strip_layouts[1].attributes()[0].shader_location(), content="1")
  debug_inspect(strip_layouts[2].array_stride(), content="16")
  debug_inspect(strip_layouts[3].attributes()[0].shader_location(), content="3")
  let joint_layouts = @gizmos_render.line_joint_gizmo_vertex_buffer_layouts()
  debug_inspect(joint_layouts.length(), content="4")
  debug_inspect(joint_layouts[0].attributes()[0].shader_location(), content="0")
  debug_inspect(joint_layouts[1].attributes()[0].shader_location(), content="1")
  debug_inspect(joint_layouts[2].attributes()[0].shader_location(), content="2")
  debug_inspect(joint_layouts[3].attributes()[0].shader_location(), content="3")
}

///|
test "line gizmo pipeline plans preserve Bevy 2d and 3d specialization keys" {
  let plan2d = @gizmos_render.line_gizmo_2d_pipeline_plan(
    @gizmos_render.LineGizmo2dPipelineKey::new(
      msaa_samples=4U,
      target_format=@wgpu.TEXTURE_FORMAT_BGRA8_UNORM,
      strip=true,
      line_style=@gizmos.GizmoLineStyle::Dashed(gap_scale=2.0F, line_scale=3.0F),
    ),
  )
  debug_inspect(plan2d.label(), content="\"LineGizmo Pipeline 2D\"")
  debug_inspect(plan2d.fragment_entry_point(), content="\"fragment_dashed\"")
  debug_inspect(plan2d.vertex_buffer_layouts().length(), content="4")
  debug_inspect(plan2d.depth_write_enabled(), content="false")
  debug_inspect(
    plan2d.depth_compare() == @wgpu.COMPARE_FUNCTION_ALWAYS,
    content="true",
  )
  debug_inspect(plan2d.msaa_samples(), content="4")
  debug_inspect(plan2d.indexed(), content="false")
  let plan3d = @gizmos_render.line_gizmo_3d_pipeline_plan(
    @gizmos_render.LineGizmo3dPipelineKey::new(
      msaa_samples=2U,
      target_format=@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
      strip=false,
      perspective=true,
      line_style=@gizmos.GizmoLineStyle::Dotted,
    ),
  )
  debug_inspect(plan3d.label(), content="\"LineGizmo 3d Pipeline\"")
  debug_inspect(plan3d.fragment_entry_point(), content="\"fragment_dotted\"")
  debug_inspect(plan3d.vertex_buffer_layouts().length(), content="2")
  debug_inspect(plan3d.depth_write_enabled(), content="true")
  debug_inspect(
    plan3d.depth_compare() == @wgpu.COMPARE_FUNCTION_GREATER,
    content="true",
  )
  debug_inspect(plan3d.shader_defs().length(), content="1")
  debug_inspect(plan3d.indexed(), content="true")
}

///|
test "line joint gizmo pipeline plans preserve Bevy joint entry points" {
  let bevel = @gizmos_render.line_joint_gizmo_2d_pipeline_plan(
    @gizmos_render.LineJointGizmo2dPipelineKey::new(
      msaa_samples=1U,
      target_format=@wgpu.TEXTURE_FORMAT_BGRA8_UNORM,
      joints=@gizmos.GizmoLineJoint::Bevel,
    ),
  )
  debug_inspect(bevel.vertex_entry_point(), content="Some(\"vertex_bevel\")")
  debug_inspect(bevel.fragment_entry_point(), content="\"fragment\"")
  let round = @gizmos_render.line_joint_gizmo_3d_pipeline_plan(
    @gizmos_render.LineJointGizmo3dPipelineKey::new(
      msaa_samples=1U,
      target_format=@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
      perspective=true,
      joints=@gizmos.GizmoLineJoint::Round(12),
    ),
  )
  debug_inspect(round.vertex_entry_point(), content="Some(\"vertex_round\")")
  debug_inspect(round.shader_defs().length(), content="1")
  debug_inspect(round.depth_write_enabled(), content="true")
  debug_inspect(round.indexed(), content="true")
}

///|
test "draw line gizmo plan mirrors Bevy list and strip buffer slices" {
  guard @gizmos_render.draw_line_gizmo_plan(
      strip=false,
      list_vertex_count=4,
      strip_vertex_count=0,
    )
    is Some(list_plan) else {
    abort("expected list draw plan")
  }
  debug_inspect(list_plan.bindings().length(), content="2")
  debug_inspect(list_plan.vertex_count(), content="6")
  debug_inspect(list_plan.instance_count(), content="2")
  debug_inspect(
    list_plan.bindings()[0].buffer_kind() is ListPosition,
    content="true",
  )
  debug_inspect(list_plan.bindings()[0].offset_bytes(), content="0")
  debug_inspect(list_plan.bindings()[0].size_bytes(), content="48")
  debug_inspect(
    list_plan.bindings()[1].buffer_kind() is ListColor,
    content="true",
  )
  debug_inspect(list_plan.bindings()[1].size_bytes(), content="64")
  guard @gizmos_render.draw_line_gizmo_plan(
      strip=true,
      list_vertex_count=0,
      strip_vertex_count=5,
    )
    is Some(strip_plan) else {
    abort("expected strip draw plan")
  }
  debug_inspect(strip_plan.bindings().length(), content="4")
  debug_inspect(strip_plan.vertex_count(), content="6")
  debug_inspect(strip_plan.instance_count(), content="4")
  debug_inspect(strip_plan.bindings()[1].slot(), content="1")
  debug_inspect(
    strip_plan.bindings()[1].buffer_kind() is StripPosition,
    content="true",
  )
  debug_inspect(strip_plan.bindings()[1].offset_bytes(), content="12")
  debug_inspect(strip_plan.bindings()[1].size_bytes(), content="48")
  debug_inspect(
    strip_plan.bindings()[3].buffer_kind() is StripColor,
    content="true",
  )
  debug_inspect(strip_plan.bindings()[3].offset_bytes(), content="16")
  debug_inspect(strip_plan.bindings()[3].size_bytes(), content="64")
  debug_inspect(
    @gizmos_render.draw_line_gizmo_plan(
      strip=true,
      list_vertex_count=0,
      strip_vertex_count=1,
    )
    is None,
    content="true",
  )
}

///|
test "draw line joint gizmo plan mirrors Bevy joint draw conditions" {
  guard @gizmos_render.draw_line_joint_gizmo_plan(
      strip_vertex_count=6,
      joints=@gizmos.GizmoLineJoint::Round(8),
    )
    is Some(round_plan) else {
    abort("expected round joint draw plan")
  }
  debug_inspect(round_plan.bindings().length(), content="4")
  debug_inspect(round_plan.vertex_count(), content="24")
  debug_inspect(round_plan.instance_count(), content="4")
  debug_inspect(round_plan.bindings()[0].offset_bytes(), content="0")
  debug_inspect(round_plan.bindings()[0].size_bytes(), content="48")
  debug_inspect(round_plan.bindings()[1].offset_bytes(), content="12")
  debug_inspect(round_plan.bindings()[1].size_bytes(), content="48")
  debug_inspect(round_plan.bindings()[2].offset_bytes(), content="24")
  debug_inspect(round_plan.bindings()[2].size_bytes(), content="48")
  debug_inspect(
    round_plan.bindings()[3].buffer_kind() is StripColor,
    content="true",
  )
  debug_inspect(round_plan.bindings()[3].offset_bytes(), content="16")
  debug_inspect(round_plan.bindings()[3].size_bytes(), content="64")
  debug_inspect(
    @gizmos_render.draw_line_joint_gizmo_vertex_count(
      @gizmos.GizmoLineJoint::Miter,
    ),
    content="Some(6)",
  )
  debug_inspect(
    @gizmos_render.draw_line_joint_gizmo_vertex_count(
      @gizmos.GizmoLineJoint::Bevel,
    ),
    content="Some(3)",
  )
  debug_inspect(
    @gizmos_render.draw_line_joint_gizmo_plan(
      strip_vertex_count=2,
      joints=@gizmos.GizmoLineJoint::Miter,
    )
    is None,
    content="true",
  )
  debug_inspect(
    @gizmos_render.draw_line_joint_gizmo_plan(
      strip_vertex_count=6,
      joints=@gizmos.GizmoLineJoint::None,
    )
    is None,
    content="true",
  )
}

///|
test "line gizmo phase planning mirrors Bevy list strip and joint conditions" {
  let world = @ecs.World::new()
  defer world.close()
  let entities = @gizmos_render.ensure_line_gizmo_entities(world)
  let draw_functions = @gizmos_render.ensure_line_gizmo_draw_functions(world)
  let handle = @asset.Handle::new(7)
  let mesh_config = @gizmos.GizmoMeshConfig::new(
    line_perspective=true,
    line_style=@gizmos.GizmoLineStyle::Dotted,
    line_joints=@gizmos.GizmoLineJoint::Round(8),
    render_layers=@camera_render_layers.RenderLayers::layer(1),
    handle~,
  )
  let render_entity = world.spawn()
  let main_entity = @render.MainEntity::new(world.spawn())
  let items = @gizmos_render.line_gizmo_phase_items_for_counts(
    render_entity,
    main_entity,
    entities,
    draw_functions,
    @gizmos_render.LineGizmoRenderDimension::Dim3,
    mesh_config,
    2,
    4,
  )
  debug_inspect(items.length(), content="3")
  debug_inspect(
    items[0].pipeline_key().kind()
    is @gizmos_render.LineGizmoPhaseKind::LineList,
    content="true",
  )
  debug_inspect(
    items[1].pipeline_key().kind()
    is @gizmos_render.LineGizmoPhaseKind::LineStrip,
    content="true",
  )
  debug_inspect(
    items[2].pipeline_key().kind()
    is @gizmos_render.LineGizmoPhaseKind::LineJoint,
    content="true",
  )
  debug_inspect(items[0].indexed(), content="true")
  debug_inspect(items[0].handle_id(), content="7")
  debug_inspect(items[0].pipeline_key().perspective(), content="true")
  debug_inspect(
    items[2].pipeline_key().line_joints() is Round(8),
    content="true",
  )
}

///|
test "line gizmo phase planning skips joints without enough strip vertices" {
  let world = @ecs.World::new()
  defer world.close()
  let entities = @gizmos_render.ensure_line_gizmo_entities(world)
  let draw_functions = @gizmos_render.ensure_line_gizmo_draw_functions(world)
  let handle = @asset.Handle::new(9)
  let mesh_config = @gizmos.GizmoMeshConfig::new(
    line_perspective=false,
    line_style=@gizmos.GizmoLineStyle::Solid,
    line_joints=@gizmos.GizmoLineJoint::Miter,
    render_layers=@camera_render_layers.RenderLayers::RenderLayers(),
    handle~,
  )
  let items = @gizmos_render.line_gizmo_phase_items_for_counts(
    world.spawn(),
    @render.MainEntity::new(world.spawn()),
    entities,
    draw_functions,
    @gizmos_render.LineGizmoRenderDimension::Dim2,
    mesh_config,
    0,
    2,
  )
  debug_inspect(items.length(), content="1")
  debug_inspect(items[0].indexed(), content="false")
  debug_inspect(
    items[0].pipeline_key().kind()
    is @gizmos_render.LineGizmoPhaseKind::LineStrip,
    content="true",
  )
}

///|
test "line gizmo render command plan combines Bevy command tuple inputs" {
  let world = @ecs.World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set(
    entity,
    @gizmos.Gizmo::Gizmo().with_line_config(@gizmos.GizmoLineConfig::{
      width: 6.0F,
      perspective: true,
      style: @gizmos.GizmoLineStyle::Dotted,
      joints: @gizmos.GizmoLineJoint::Round(4),
    }),
  )
  try! world.set(entity, @transform.GlobalTransform::identity())
  @gizmos_render.extract_line_gizmos(world)
  let entities = @gizmos_render.ensure_line_gizmo_entities(world)
  let draw_functions = @gizmos_render.ensure_line_gizmo_draw_functions(world)
  let query : @ecs.Query[
    (
      @ecs.Read[@gizmos_render.LineGizmoUniform],
      @ecs.Read[@gizmos.GizmoMeshConfig],
      @ecs.Read[@render.MainEntity],
    ),
    @ecs.All,
  ] = @ecs.query(world)
  let planned = Ref(0)
  let phase_count = Ref(0)
  let line_view_slot = Ref(99U)
  let line_uniform_slot = Ref(99U)
  let line_uniform_bytes = Ref(0)
  let line_indexed = Ref(false)
  let line_binding_count = Ref(0)
  let line_instance_count = Ref(0U)
  let strip_binding_count = Ref(0)
  let strip_instance_count = Ref(0U)
  let joint_shader_path = Ref("")
  let joint_vertex_entry = Ref("")
  let joint_vertex_count = Ref(0U)
  let joint_instance_count = Ref(0U)
  try! query.view(fn(render_entity, data) {
    let (uniform_comp, mesh_config_comp, main_entity_comp) = data
    let phase_items = @gizmos_render.line_gizmo_phase_items_for_counts(
      render_entity,
      main_entity_comp.value(),
      entities,
      draw_functions,
      @gizmos_render.LineGizmoRenderDimension::Dim3,
      mesh_config_comp.value(),
      4,
      5,
    )
    phase_count.val = phase_items.length()
    match
      @gizmos_render.line_gizmo_render_command_plan(
        phase_items[0],
        uniform_comp.value(),
        list_vertex_count=4,
        strip_vertex_count=5,
        msaa_samples=4U,
        target_format=@wgpu.TEXTURE_FORMAT_BGRA8_UNORM,
      ) {
      Some(line_plan) => {
        line_view_slot.val = line_plan.bind_groups().view_slot()
        line_uniform_slot.val = line_plan.bind_groups().uniform_slot()
        line_uniform_bytes.val = line_plan
          .bind_groups()
          .uniform_bytes()
          .length()
        line_indexed.val = line_plan.pipeline().indexed()
        line_binding_count.val = line_plan.draw().bindings().length()
        line_instance_count.val = line_plan.draw().instance_count()
      }
      None => ()
    }
    match
      @gizmos_render.line_gizmo_render_command_plan(
        phase_items[1],
        uniform_comp.value(),
        list_vertex_count=4,
        strip_vertex_count=5,
        msaa_samples=4U,
        target_format=@wgpu.TEXTURE_FORMAT_BGRA8_UNORM,
      ) {
      Some(strip_plan) => {
        strip_binding_count.val = strip_plan.draw().bindings().length()
        strip_instance_count.val = strip_plan.draw().instance_count()
      }
      None => ()
    }
    match
      @gizmos_render.line_gizmo_render_command_plan(
        phase_items[2],
        uniform_comp.value(),
        list_vertex_count=4,
        strip_vertex_count=5,
        msaa_samples=4U,
        target_format=@wgpu.TEXTURE_FORMAT_BGRA8_UNORM,
      ) {
      Some(joint_plan) => {
        joint_shader_path.val = joint_plan.pipeline().shader_path()
        joint_vertex_entry.val = match
          joint_plan.pipeline().vertex_entry_point() {
          Some(value) => value
          None => ""
        }
        joint_vertex_count.val = joint_plan.draw().vertex_count()
        joint_instance_count.val = joint_plan.draw().instance_count()
      }
      None => ()
    }
    planned.val = planned.val + 1
  })
  debug_inspect(phase_count.val, content="3")
  debug_inspect(line_view_slot.val, content="0")
  debug_inspect(line_uniform_slot.val, content="1")
  debug_inspect(
    line_uniform_bytes.val,
    content="\{@gizmos_render.LINE_GIZMO_UNIFORM_SIZE_BYTES}",
  )
  debug_inspect(line_indexed.val, content="true")
  debug_inspect(line_binding_count.val, content="2")
  debug_inspect(line_instance_count.val, content="2")
  debug_inspect(strip_binding_count.val, content="4")
  debug_inspect(strip_instance_count.val, content="4")
  debug_inspect(
    joint_shader_path.val,
    content="\"gizmos_render/line_joints.wgsl\"",
  )
  debug_inspect(joint_vertex_entry.val, content="\"vertex_round\"")
  debug_inspect(joint_vertex_count.val, content="12")
  debug_inspect(joint_instance_count.val, content="3")
  debug_inspect(planned.val, content="1")
}
