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
fn reset_text_ecs_test_state() -> Unit {
  text_ecs_entries.clear()
  ui_text_ecs_entries.clear()
  text_ecs_runtime_state.world_id = None
  text_font_asset_events_cursor.clear(@ecs.Messages::new())
  text_state.next_text_id = 0
  text_state.next_span_id = 0
  text_state_clear_instances()
  text_pipeline_runtime_state.cosmic_font_system = CosmicFontSystemState::{
    font_system: @cosmic.FontSystem::new(),
    handle_to_font_id: [],
    font_id_to_handle_id: [],
    handle_to_family: [],
  }
  text_pipeline_runtime_state.font_atlas_set = FontAtlasSet::FontAtlasSet()
  text_runtime_state.rem_size = RemSize::RemSize().value()
  text_runtime_mark_layout_dirty()
  text_debug_frame_state.draws.clear()
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
  reset_text_ecs_test_state()
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
  debug_inspect(text_ecs_sync_candidate_entity_count.val, content="0")
  ui_text_sync_ecs_system(world)
  debug_inspect(text_ecs_sync_candidate_entity_count.val, content="0")
}

///|
test "text plugin inserts text runtime resources" {
  let lifecycle_world_47_0 = @ecs.World::new()
  defer lifecycle_world_47_0.close()
  let app = text_plugin(
    @app.App::new(lifecycle_world_47_0).add_plugins(
      @render.RenderPlugin::RenderPlugin(),
    ),
  )
  debug_inspect(app.contains_resource(RemSize::resource()), content="true")
  debug_inspect(app.contains_resource(FontCx::resource()), content="true")
  debug_inspect(app.contains_resource(FontAtlasSet::resource()), content="true")
}

///|
test "font asset Added events force text rerender on next update" {
  reset_text_ecs_test_state()
  let world = @ecs.World::new()
  defer world.close()
  let text_handle = text_spawn(
    Text2dBundle::new(
      Text2d::new("Font Event"),
      TextFont::{ ..TextFont(), font: FontSource::UiSansSerif },
      @transform.Transform::identity(),
    ),
  )
  let index = if text_state_find_index_by_id(text_handle.id()) is Some(i) {
    i
  } else {
    panic()
  }

  text_state.texts[index] = text_update_layout(text_state.texts[index])
  debug_inspect(text_state.texts[index].layout_dirty, content="false")
  text_runtime_clear_layout_dirty()

  let message_key : @ecs.MessageKey[@asset.AssetEvent[@asset.Font]] = @ecs.Message::message()
  world.init_message(message_key)
  ignore(
    world.send_message(
      message_key,
      @asset.AssetEvent::Added(@asset.Handle::new(1)),
    ),
  )

  text_sync_font_assets_system(world)
  debug_inspect(text_state.texts[index].layout_dirty, content="true")
  debug_inspect(text_state.texts[index].computed.needs_rerender, content="true")
  debug_inspect(text_runtime_layout_dirty(), content="true")

  text_state.texts[index] = TextInstance::{
    ..text_state.texts[index],
    layout_dirty: false,
    computed: ComputedTextBlock::{
      ..text_state.texts[index].computed,
      needs_rerender: false,
    },
  }
  text_runtime_clear_layout_dirty()
  text_sync_font_assets_system(world)
  debug_inspect(text_state.texts[index].layout_dirty, content="false")
}

///|
test "font asset non-Added events follow Bevy and do not rerender text" {
  reset_text_ecs_test_state()
  let world = @ecs.World::new()
  defer world.close()
  let text_handle = text_spawn(
    Text2dBundle::new(
      Text2d::new("Font Event"),
      TextFont::{ ..TextFont(), font: FontSource::UiSansSerif },
      @transform.Transform::identity(),
    ),
  )
  let index = if text_state_find_index_by_id(text_handle.id()) is Some(i) {
    i
  } else {
    panic()
  }

  text_state.texts[index] = text_update_layout(text_state.texts[index])
  text_state.texts[index] = TextInstance::{
    ..text_state.texts[index],
    layout_dirty: false,
    computed: ComputedTextBlock::{
      ..text_state.texts[index].computed,
      needs_rerender: false,
    },
  }
  text_runtime_clear_layout_dirty()

  let message_key : @ecs.MessageKey[@asset.AssetEvent[@asset.Font]] = @ecs.Message::message()
  world.init_message(message_key)
  ignore(
    world.send_message(
      message_key,
      @asset.AssetEvent::LoadedWithDependencies(@asset.Handle::new(1)),
    ),
  )
  ignore(
    world.send_message(
      message_key,
      @asset.AssetEvent::Modified(@asset.Handle::new(1)),
    ),
  )
  ignore(
    world.send_message(
      message_key,
      @asset.AssetEvent::Removed(@asset.Handle::new(1)),
    ),
  )

  text_sync_font_assets_system(world)
  debug_inspect(text_state.texts[index].layout_dirty, content="false")
  debug_inspect(
    text_state.texts[index].computed.needs_rerender,
    content="false",
  )
  debug_inspect(text_runtime_layout_dirty(), content="false")
}

///|
test "ecs text bridge resolves a world-space bundle from ECS components" {
  reset_text_ecs_test_state()
  let world = @ecs.World::new()
  defer world.close()
  let entity = world.spawn()
  let base_font = TextFont::TextFont()
  let local_transform = @transform.Transform::from_xyz(0.0F, 125.0F, 0.0F)
  let global_transform = @transform.Transform::from_xyz(250.0F, 125.0F, 0.0F)
  let expected = Text2dBundle::{
    text: Text2d::new("Repeat On"),
    font: base_font,
    color: TextColor::TextColor(),
    background_color: None,
    underline: None,
    underline_color: None,
    strikethrough: None,
    strikethrough_color: None,
    layout: TextLayout::new_with_justify(Justify::Center),
    bounds: TextBounds::new_horizontal(200.0F),
    line_height: LineHeight::default(),
    font_hinting: FontHinting::default(),
    shadow: None,
    transform: global_transform,
    layers: @camera_render_layers.RenderLayers::RenderLayers(),
    no_frustum_culling: false,
    anchor: @sprite.Anchor::Anchor(),
    y_axis: YAxisOrientation::TopToBottom,
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
  .insert_component(TextBounds::new_horizontal(200.0F))
  |> ignore)
  try! world.set_by_key(
    entity,
    ecs_key_text_layout,
    TextLayout::new_with_justify(Justify::Center),
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
    bundle.transform.to_json(),
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
  reset_text_ecs_test_state()
  let world = @ecs.World::new()
  defer world.close()
  let entity = world.spawn()
  let font = TextFont::TextFont()
  let transform = @transform.Transform::identity()
  try! (world.entity_mut(entity).insert_component(Text2d::new("NoCpu"))
  |> ignore)
  try! (world.entity_mut(entity).insert_component(font) |> ignore)
  try! (world.entity_mut(entity).insert_component(transform) |> ignore)
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_no_cpu_culling,
    @visibility.NoCpuCulling::NoCpuCulling(),
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
  reset_text_ecs_test_state()
  let world = @ecs.World::new()
  defer world.close()
  let entity = world.spawn()
  try! (world.entity_mut(entity).insert_component(Text2d::new("Cleanup"))
  |> ignore)
  try! (world.entity_mut(entity).insert_component(TextFont::TextFont())
  |> ignore)
  try! world.set_by_key(
    entity,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
  )
  text_ecs_entries.push(EcsTextEntry::{
    world_id: world.world_id(),
    entity,
    handle: TextHandle::new(42),
    bundle: Text2dBundle::new(
      Text2d::new("Cleanup"),
      TextFont::TextFont(),
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
    (try! world.entity(entity).get() : TextLayout?) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.entity(entity).get() : TextFont?) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.entity(entity).get() : TextColor?) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.entity(entity).get() : LineHeight?) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.entity(entity).get() : FontHinting?) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.entity(entity).get() : TextBounds?) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.entity(entity).get() : @sprite.Anchor?) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.entity(entity).get() : @visibility.Visibility?) is Some(_),
    content="true",
  )
}

///|
test "text ecs bridge syncs ViewVisibility into runtime visibility gating" {
  reset_text_ecs_test_state()
  let world = @ecs.World::new()
  defer world.close()
  try! register_text_required_components(world)
  let entity = world.spawn()
  try! (world.entity_mut(entity).insert_component(Text2d::new("Visibility"))
  |> ignore)
  try! (world.entity_mut(entity).insert_component(TextFont::TextFont())
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
  text_render_system(world)
  debug_inspect(text_diagnostic_render_visible_text_count(), content="0")

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
  text_render_system(world)
  debug_inspect(text_diagnostic_render_visible_text_count(), content="1")
}

///|
test "ui text ecs bridge syncs ViewVisibility into runtime visibility gating" {
  reset_text_ecs_test_state()
  let world = @ecs.World::new()
  defer world.close()
  let entity = world.spawn()
  try! (world.entity_mut(entity).insert_component(Text::new("Hidden UI"))
  |> ignore)
  try! (world.entity_mut(entity).insert_component(TextFont::TextFont())
  |> ignore)
  ignore(next_system_ticks(world))
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )

  ui_text_sync_ecs_system(world)
  debug_inspect(ui_text_ecs_entries.length(), content="1")
  debug_inspect(ui_text_ecs_entries[0].view_visible, content="false")
  text_render_system(world)
  debug_inspect(text_diagnostic_render_visible_text_count(), content="0")

  ignore(next_system_ticks(world))
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  try! world.set_by_key(entity, ecs_key_text, Text::new("Visible UI"))
  ui_text_sync_ecs_system(world)
  debug_inspect(ui_text_ecs_entries[0].view_visible, content="true")
  text_render_system(world)
  debug_inspect(text_diagnostic_render_visible_text_count(), content="1")
}

///|
test "ecs text bridge collects TextSpan children in hierarchy order" {
  let world = @ecs.World::new()
  defer world.close()
  let root = world.spawn()
  let first = world.spawn()
  let second = world.spawn()
  let root_font = TextFont::TextFont().with_font_size(35.0F)
  let root_bundle = Text2dBundle::new(
    Text2d::new(" Anchor"),
    root_font,
    @transform.Transform::identity(),
  )
  try! (world
  .entity_mut(root)
  .insert_component(@hierarchy.Children::new([first, second]))
  |> ignore)
  try! (world.entity_mut(first).insert_component(TextSpan::new("::")) |> ignore)
  try! (world.entity_mut(first).insert_component(root_font) |> ignore)
  try! world.set_by_key(
    first,
    ecs_key_text_color,
    TextColor::new(@color.Color::srgb(0.83F, 0.83F, 0.83F)),
  )
  try! world.set_by_key(
    first,
    ecs_key_text_background_color,
    TextBackgroundColor::new(@color.Color::srgb(0.0F, 0.0F, 0.55F)),
  )
  try! (world
  .entity_mut(second)
  .insert_component(TextSpan::new("Anchor(Vec2(-0.5, 0.5)) "))
  |> ignore)
  try! (world.entity_mut(second).insert_component(root_font) |> ignore)
  try! world.set_by_key(
    second,
    ecs_key_text_color,
    TextColor::new(@color.Color::srgb(1.0F, 0.63F, 0.48F)),
  )
  try! world.set_by_key(
    second,
    ecs_key_text_background_color,
    TextBackgroundColor::new(@color.Color::srgb(0.7F, 0.441F, 0.336F)),
  )

  let span_bundles = text_ecs_collect_span_bundles_for_entity(
    world,
    root,
    root_bundle,
    text_ecs_collect_span_edges(world),
  )

  debug_inspect(span_bundles.length(), content="2")
  debug_inspect(
    text_span_bundle_eq(
      span_bundles[0],
      TextSpanBundle::new(TextSpan::new("::"), root_font)
      .with_color(TextColor::new(@color.Color::srgb(0.83F, 0.83F, 0.83F)))
      .with_background_color(
        Some(TextBackgroundColor::new(@color.Color::srgb(0.0F, 0.0F, 0.55F))),
      ),
    ),
    content="true",
  )
  debug_inspect(
    text_span_bundle_eq(
      span_bundles[1],
      TextSpanBundle::new(TextSpan::new("Anchor(Vec2(-0.5, 0.5)) "), root_font)
      .with_color(TextColor::new(@color.Color::srgb(1.0F, 0.63F, 0.48F)))
      .with_background_color(
        Some(TextBackgroundColor::new(@color.Color::srgb(0.7F, 0.441F, 0.336F))),
      ),
    ),
    content="true",
  )
}

///|
test "ui text bridge preserves runtime-owned placement during sync" {
  reset_text_ecs_test_state()
  let lifecycle_world_518_0 = @ecs.World::new()
  defer lifecycle_world_518_0.close()
  let app = @asset.asset_plugin(@app.App::new(lifecycle_world_518_0))
  let world = app.world()
  let entity = world.spawn()
  let bundle = Text2dBundle::{
    text: Text2d::new("Button"),
    font: TextFont::TextFont(),
    color: TextColor::TextColor(),
    background_color: None,
    underline: None,
    underline_color: None,
    strikethrough: None,
    strikethrough_color: None,
    layout: TextLayout::TextLayout(),
    bounds: TextBounds::TextBounds(),
    line_height: LineHeight::default(),
    font_hinting: FontHinting::default(),
    shadow: None,
    transform: @transform.Transform::identity(),
    layers: @camera_render_layers.RenderLayers::RenderLayers(),
    no_frustum_culling: false,
    anchor: @sprite.Anchor::Anchor(),
    y_axis: YAxisOrientation::TopToBottom,
    logical_viewport_size: None,
  }
  ui_text_ecs_spawn_entry(world, world.world_id(), entity, bundle, [], true)
  let entry = ui_text_ecs_entries[0]
  let runtime_transform = @transform.Transform::from_xyz(320.0F, -180.0F, 7.0F)
  let runtime_layers = @camera_render_layers.RenderLayers::layer(11)
  text_set_transform(entry.handle, runtime_transform)
  text_set_layers(entry.handle, runtime_layers)
  text_set_anchor(entry.handle, @sprite.Anchor::center())
  text_set_y_axis(entry.handle, YAxisOrientation::BottomToTop)

  let synced = ui_text_ecs_sync_existing_entry(world, entry, bundle, [], true)
  let instance = text_state.texts[0]

  debug_inspect(
    text_get_transform(synced.handle).unwrap().to_json(),
    content=(
      #|Array(
      #|  [
      #|    Number(320),
      #|    Number(-180),
      #|    Number(7),
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
  debug_inspect(instance.layers.to_json(), content="Number(2048)")
  debug_inspect(
    instance.anchor.to_json(),
    content="Array([Number(0), Number(0)])",
  )
  debug_inspect(
    y_axis_eq(instance.y_axis, YAxisOrientation::BottomToTop),
    content="true",
  )
}
