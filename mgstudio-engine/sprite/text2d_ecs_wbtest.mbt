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
// Relocated from `text/ecs_runtime_wbtest.mbt` with the ECS-bridge move
// (ISS-480 phase 4): these exercise the Text2d bridge that now lives here.

///|
fn reset_text2d_ecs_test_state() -> Unit {
  text_ecs_entries.clear()
  text_ecs_index_by_world_id.clear()
  text2d_ecs_runtime_state.world_id = None
  @text.text_reset_runtime_state_for_tests()
}

///|
fn text_bundle_rerender_eq(lhs : Text2dBundle, rhs : Text2dBundle) -> Bool {
  text2d_eq(lhs.text, rhs.text) &&
  @text.text_font_eq(lhs.font, rhs.font) &&
  @text.text_color_eq(lhs.color, rhs.color) &&
  @text.text_background_color_eq(lhs.background_color, rhs.background_color) &&
  @text.empty_marker_opt_eq(lhs.underline, rhs.underline) &&
  @text.underline_color_eq(lhs.underline_color, rhs.underline_color) &&
  @text.empty_marker_opt_eq(lhs.strikethrough, rhs.strikethrough) &&
  @text.strikethrough_color_eq(lhs.strikethrough_color, rhs.strikethrough_color) &&
  @text.text_layout_eq(lhs.layout, rhs.layout) &&
  @text.text_bounds_eq(lhs.bounds, rhs.bounds) &&
  @text.line_height_eq(lhs.line_height, rhs.line_height) &&
  @text.font_hinting_eq(lhs.font_hinting, rhs.font_hinting) &&
  text_shadow_eq(lhs.shadow, rhs.shadow) &&
  @text.y_axis_eq(lhs.y_axis, rhs.y_axis) &&
  @text.vec2_opt_eq(lhs.logical_viewport_size, rhs.logical_viewport_size)
}

///|
fn next_system_ticks(world : @ecs.World) -> @core.SystemTicks {
  let this_run = world.increment_change_tick()
  let last_run = world.get_tick_context().ticks().this_run
  let tick = @core.SystemTicks::new(last_run, this_run)
  let ctx = @core.SystemTickContext::new()
  ctx.set(tick)
  world.set_tick_context(ctx)
  tick
}

///|
test "text ecs sync ignores unrelated changed component streams" {
  reset_text2d_ecs_test_state()
  let world = @ecs.World::new()
  defer world.close()
  ignore(next_system_ticks(world))
  for i in 0..<32 {
    let entity = world.spawn()
    try! (world
    .entity_mut(entity)
    .insert_component(
      @transform.Transform::from_xyz(Float::from_int(i), 0.0F, 0.0F),
    )
    |> ignore)
    try! (world
    .entity_mut(entity)
    .insert_component(@visibility.ViewVisibility::new(true))
    |> ignore)
  }

  text_sync_ecs_system(world)
  debug_inspect(@text.text_ecs_sync_candidate_entity_count.val, content="0")
  @text.ui_text_sync_ecs_system(world)
  debug_inspect(@text.text_ecs_sync_candidate_entity_count.val, content="0")
}

///|
test "ecs text bridge resolves a world-space bundle from ECS components" {
  reset_text2d_ecs_test_state()
  let world = @ecs.World::new()
  defer world.close()
  let entity = world.spawn()
  let base_font = @text.TextFont::TextFont()
  let local_transform = @transform.Transform::from_xyz(0.0F, 125.0F, 0.0F)
  let global_transform = @transform.Transform::from_xyz(250.0F, 125.0F, 0.0F)
  let expected = Text2dBundle::{
    text: Text2d::new("Repeat On"),
    font: base_font,
    color: @text.TextColor::TextColor(),
    background_color: None,
    underline: None,
    underline_color: None,
    strikethrough: None,
    strikethrough_color: None,
    layout: @text.TextLayout::new_with_justify(Center),
    bounds: @text.TextBounds::new_horizontal(200.0F),
    line_height: @text.LineHeight::default(),
    font_hinting: @text.FontHinting::default(),
    shadow: None,
    transform: global_transform,
    layers: @camera_render_layers.RenderLayers::RenderLayers(),
    no_frustum_culling: false,
    anchor: Anchor(),
    y_axis: TopToBottom,
    logical_viewport_size: None,
  }
  try! (world.entity_mut(entity).insert_component(Text2d::new("Repeat On"))
  |> ignore)
  try! (world.entity_mut(entity).insert_component(base_font) |> ignore)
  try! (world.entity_mut(entity).insert_component(local_transform) |> ignore)
  try! world.set_by_key(
    entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(global_transform),
  )
  try! (world
  .entity_mut(entity)
  .insert_component(@text.TextBounds::new_horizontal(200.0F))
  |> ignore)
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(Center),
  )

  let (bundle, view_visible) = text_ecs_bundle_from_entity(
    world,
    entity,
    Text2d::new("Repeat On"),
    base_font,
    local_transform,
  )

  debug_inspect(text_bundle_rerender_eq(bundle, expected), content="true")
  debug_inspect(view_visible, content="true")
  debug_inspect(
    bundle.transform |> ToJson::to_json,
    content=(
      #|Array(
      #|  [
      #|    Number(250),
      #|    Number(125),
      #|    Number(0),
      #|    Number(0),
      #|    Number(0),
      #|    Number(0),
      #|    Number(1),
      #|    Number(1),
      #|    Number(1),
      #|    Number(1),
      #|  ],
      #|)
    ),
  )
}

///|
test "ecs text bridge treats NoCpuCulling as no-frustum-culling opt-out" {
  reset_text2d_ecs_test_state()
  let world = @ecs.World::new()
  defer world.close()
  let entity = world.spawn()
  let font = @text.TextFont::TextFont()
  let transform = @transform.Transform::identity()
  try! (world.entity_mut(entity).insert_component(Text2d::new("NoCpu"))
  |> ignore)
  try! (world.entity_mut(entity).insert_component(font) |> ignore)
  try! (world.entity_mut(entity).insert_component(transform) |> ignore)
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_no_cpu_culling,
    NoCpuCulling(),
  )

  let (bundle, _view_visible) = text_ecs_bundle_from_entity(
    world,
    entity,
    Text2d::new("NoCpu"),
    font,
    transform,
  )

  debug_inspect(bundle.no_frustum_culling, content="true")
}

///|
test "ecs text cleanup removes dead entity entries" {
  reset_text2d_ecs_test_state()
  let world = @ecs.World::new()
  defer world.close()
  let entity = world.spawn()
  try! (world.entity_mut(entity).insert_component(Text2d::new("Cleanup"))
  |> ignore)
  try! (world.entity_mut(entity).insert_component(@text.TextFont::TextFont())
  |> ignore)
  try! world.set_by_key(
    entity,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
  )
  text_ecs_entries.push({
    world_id: world.world_id(),
    entity,
    handle: @text.TextHandle::new(42),
    bundle: Text2dBundle::new(
      Text2d::new("Cleanup"),
      @text.TextFont::TextFont(),
      @transform.Transform::identity(),
    ),
    view_visible: true,
    span_bundles: [],
  })

  try! world.despawn(entity)
  let world_id = world.world_id()
  let tick = @core.SystemTicks::new(0, 1)
  let index_by_entity_id = text_ecs_build_entry_index_by_entity_id(world_id)
  text_ecs_cleanup_removed_entries(world, world_id, tick, index_by_entity_id)

  debug_inspect(text_ecs_entries.length(), content="0")
}

///|
test "text ecs registers required components for Text2d" {
  let world = @ecs.World::new()
  defer world.close()
  try! register_text_required_components(world)
  let entity = world.spawn()
  try! (world.entity_mut(entity).insert_component(Text2d::new("Auto transform"))
  |> ignore)

  debug_inspect(
    (try! world.entity(entity).get() : @transform.Transform?) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.entity(entity).get() : @text.TextLayout?) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.entity(entity).get() : @text.TextFont?) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.entity(entity).get() : @text.TextColor?) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.entity(entity).get() : @text.LineHeight?) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.entity(entity).get() : @text.FontHinting?) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.entity(entity).get() : @text.TextBounds?) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.entity(entity).get() : Anchor?) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.entity(entity).get() : @visibility.Visibility?) is Some(_),
    content="true",
  )
}

///|
test "text ecs bridge syncs ViewVisibility into runtime visibility gating" {
  reset_text2d_ecs_test_state()
  let world = @ecs.World::new()
  defer world.close()
  try! register_text_required_components(world)
  let entity = world.spawn()
  try! (world.entity_mut(entity).insert_component(Text2d::new("Visibility"))
  |> ignore)
  try! (world.entity_mut(entity).insert_component(@text.TextFont::TextFont())
  |> ignore)
  try! (world
  .entity_mut(entity)
  .insert_component(@transform.Transform::identity())
  |> ignore)
  ignore(next_system_ticks(world))
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )

  text_sync_ecs_system(world)
  debug_inspect(text_ecs_entries.length(), content="1")
  debug_inspect(text_ecs_entries[0].view_visible, content="false")

  ignore(next_system_ticks(world))
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  try! world.set_by_key(
    entity,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(1.0F, 0.0F, 0.0F),
  )
  text_sync_ecs_system(world)
  debug_inspect(text_ecs_entries[0].view_visible, content="true")
}
