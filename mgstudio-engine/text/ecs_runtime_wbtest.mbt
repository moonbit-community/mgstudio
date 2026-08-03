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
  ui_text_ecs_entries.clear()
  text_ecs_runtime_state.world_id = None
  text_font_asset_events_cursor.clear(@ecs.Messages::new())
  text_state.next_text_id = 0
  text_state.next_span_id = 0
  text_state_clear_instances()
  text_pipeline_runtime_state.cosmic_font_system = {
    font_system: @cosmic.FontSystem::new(),
    handle_to_font_id: [],
    font_id_to_handle_id: [],
    handle_to_family: [],
  }
  text_pipeline_runtime_state.font_atlas_set = FontAtlasSet()
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
  let text_handle = text_spawn_data(
    TextSpawnData::new(
      "Font Event",
      { ..TextFont(), font: UiSansSerif },
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
  ignore(world.send_message(message_key, Added(@asset.Handle::new(1))))

  text_sync_font_assets_system(world)
  debug_inspect(text_state.texts[index].layout_dirty, content="true")
  debug_inspect(text_state.texts[index].computed.needs_rerender, content="true")
  debug_inspect(text_runtime_layout_dirty(), content="true")

  text_state.texts[index] = {
    ..text_state.texts[index],
    layout_dirty: false,
    computed: { ..text_state.texts[index].computed, needs_rerender: false },
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
  let text_handle = text_spawn_data(
    TextSpawnData::new(
      "Font Event",
      { ..TextFont(), font: UiSansSerif },
      @transform.Transform::identity(),
    ),
  )
  let index = if text_state_find_index_by_id(text_handle.id()) is Some(i) {
    i
  } else {
    panic()
  }

  text_state.texts[index] = text_update_layout(text_state.texts[index])
  text_state.texts[index] = {
    ..text_state.texts[index],
    layout_dirty: false,
    computed: { ..text_state.texts[index].computed, needs_rerender: false },
  }
  text_runtime_clear_layout_dirty()

  let message_key : @ecs.MessageKey[@asset.AssetEvent[@asset.Font]] = @ecs.Message::message()
  world.init_message(message_key)
  ignore(
    world.send_message(
      message_key,
      LoadedWithDependencies(@asset.Handle::new(1)),
    ),
  )
  ignore(world.send_message(message_key, Modified(@asset.Handle::new(1))))
  ignore(world.send_message(message_key, Removed(@asset.Handle::new(1))))

  text_sync_font_assets_system(world)
  debug_inspect(text_state.texts[index].layout_dirty, content="false")
  debug_inspect(
    text_state.texts[index].computed.needs_rerender,
    content="false",
  )
  debug_inspect(text_runtime_layout_dirty(), content="false")
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
  ignore(next_system_ticks(world))
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  try! world.set_by_key(entity, ecs_key_text, Text::new("Visible UI"))
  ui_text_sync_ecs_system(world)
  debug_inspect(ui_text_ecs_entries[0].view_visible, content="true")
}

///|
test "ecs text bridge collects TextSpan children in hierarchy order" {
  let world = @ecs.World::new()
  defer world.close()
  let root = world.spawn()
  let first = world.spawn()
  let second = world.spawn()
  let root_font = TextFont::TextFont().with_font_size(35.0F)

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
    root_font,
    LineHeight::default(),
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
  let bundle = TextSpawnData::{
    content: "Button",
    font: TextFont(),
    color: TextColor(),
    background_color: None,
    underline: None,
    underline_color: None,
    strikethrough: None,
    strikethrough_color: None,
    layout: TextLayout(),
    bounds: TextBounds(),
    line_height: LineHeight::default(),
    font_hinting: FontHinting::default(),
    shadow: None,
    transform: @transform.Transform::identity(),
    layers: RenderLayers(),
    no_frustum_culling: false,
    anchor: @math.Vec2::new(0.0F, 0.0F),
    y_axis: TopToBottom,
    logical_viewport_size: None,
  }
  ui_text_ecs_spawn_entry(world, world.world_id(), entity, bundle, [], true)
  let entry = ui_text_ecs_entries[0]
  let runtime_transform = @transform.Transform::from_xyz(320.0F, -180.0F, 7.0F)
  let runtime_layers = @camera_render_layers.RenderLayers::layer(11)
  text_set_transform(entry.handle, runtime_transform)
  text_set_layers(entry.handle, runtime_layers)
  text_set_anchor_vec(entry.handle, @math.Vec2::new(0.0F, 0.0F))
  text_set_y_axis(entry.handle, BottomToTop)

  let synced = ui_text_ecs_sync_existing_entry(world, entry, bundle, [], true)
  let instance = text_state.texts[0]

  debug_inspect(
    text_get_transform(synced.handle).unwrap() |> ToJson::to_json,
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
  debug_inspect(instance.layers |> ToJson::to_json, content="Number(2048)")
  debug_inspect(
    instance.anchor |> ToJson::to_json,
    content="Array([Number(0), Number(0)])",
  )
  debug_inspect(y_axis_eq(instance.y_axis, BottomToTop), content="true")
}
