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
  text_ecs_bridge_entries.val.clear()
  ui_text_ecs_bridge_entries.val.clear()
  text_runtime_world_id_ref.val = None
  text_state.val.next_text_id = 0
  text_state.val.next_span_id = 0
  text_state.val.texts.clear()
  text_runtime_rem_size_ref.val = RemSize::default().value()
  text_debug_frame_state.val.draws.clear()
}

///|
test "ecs text bridge resolves a world-space bundle from ECS components" {
  reset_text_ecs_test_state()
  let world = @ecs.World::new()
  let entity = world.spawn()
  let base_font = TextFont::default()
  let local_transform = @transform.Transform::from_xyz(0.0F, 125.0F, 0.0F)
  let global_transform = @transform.Transform::from_xyz(250.0F, 125.0F, 0.0F)
  let expected = Text2dBundle::{
    text: Text2d::new("Repeat On"),
    font: base_font,
    color: TextColor::default(),
    background_color: None,
    underline: None,
    strikethrough: None,
    layout: TextLayout::new_with_justify(Justify::Center),
    bounds: TextBounds::new_horizontal(200.0F),
    line_height: LineHeight::default(),
    shadow: None,
    transform: global_transform,
    layers: @sprite.RenderLayers::default(),
    anchor: @sprite.Anchor::default(),
    y_axis: YAxisOrientation::TopToBottom,
    logical_viewport_size: None,
  }
  try! world.set_component(entity, Text2d::new("Repeat On"))
  try! world.set_component(entity, base_font)
  try! world.set_component(entity, local_transform)
  try! world.set_component(
    entity,
    @transform.GlobalTransform::from_transform(global_transform),
  )
  try! world.set_component(entity, TextBounds::new_horizontal(200.0F))
  try! world.set_component(
    entity,
    TextLayout::new_with_justify(Justify::Center),
  )

  let bundle = text_ecs_bundle_from_entity(
    world,
    entity,
    Text2d::new("Repeat On"),
    base_font,
    local_transform,
  )

  inspect(text_bundle_rerender_eq(bundle, expected), content="true")
  inspect(
    bundle.transform.to_json(),
    content="Array([Number(250), Number(125), Number(0), Number(0), Number(0), Number(0), Number(1), Number(1), Number(1), Number(1)])",
  )
}

///|
test "ecs text bridge cleanup removes dead entity entries" {
  reset_text_ecs_test_state()
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! world.set_component(entity, Text2d::new("Cleanup"))
  try! world.set_component(entity, TextFont::default())
  try! world.set_component(
    entity,
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
  )
  text_ecs_bridge_entries.val.push(EcsTextBridgeEntry::{
    world_id: world.world_id(),
    entity,
    handle: TextHandle::new(42),
    bundle: Text2dBundle::new(
      Text2d::new("Cleanup"),
      TextFont::default(),
      @transform.Transform::identity(),
    ),
    span_bundles: [],
  })

  try! world.despawn(entity)
  text_ecs_cleanup_stale_entries(world)

  inspect(text_ecs_bridge_entries.val.length(), content="0")
}

///|
test "text ecs bridge registers Transform as a required component for Text2d" {
  let world = @ecs.World::new()
  try! register_text_required_components(world)
  let entity = world.spawn()
  try! world.set_component(entity, Text2d::new("Auto transform"))

  inspect(
    (try! world.get_component(entity) : @transform.Transform?) is Some(_),
    content="true",
  )
}

///|
test "ecs text bridge collects TextSpan children in hierarchy order" {
  let world = @ecs.World::new()
  let root = world.spawn()
  let first = world.spawn()
  let second = world.spawn()
  let root_font = TextFont::default().with_font_size(35.0F)
  let root_bundle = Text2dBundle::new(
    Text2d::new(" Anchor"),
    root_font,
    @transform.Transform::identity(),
  )
  try! world.set_component(root, @hierarchy.Children::new([first, second]))
  try! world.set_component(first, TextSpan::new("::"))
  try! world.set_component(first, root_font)
  try! world.set_component(
    first,
    TextColor::new(@sprite.Color::srgb(0.83F, 0.83F, 0.83F)),
  )
  try! world.set_component(
    first,
    TextBackgroundColor::new(@sprite.Color::srgb(0.0F, 0.0F, 0.55F)),
  )
  try! world.set_component(second, TextSpan::new("Anchor(Vec2(-0.5, 0.5)) "))
  try! world.set_component(second, root_font)
  try! world.set_component(
    second,
    TextColor::new(@sprite.Color::srgb(1.0F, 0.63F, 0.48F)),
  )
  try! world.set_component(
    second,
    TextBackgroundColor::new(@sprite.Color::srgb(0.7F, 0.441F, 0.336F)),
  )

  let span_bundles = text_ecs_collect_span_bundles_for_entity(
    world, root, root_bundle,
  )

  inspect(span_bundles.length(), content="2")
  inspect(
    text_span_bundle_eq(
      span_bundles[0],
      TextSpanBundle::new(TextSpan::new("::"), root_font)
      .with_color(TextColor::new(@sprite.Color::srgb(0.83F, 0.83F, 0.83F)))
      .with_background_color(
        Some(TextBackgroundColor::new(@sprite.Color::srgb(0.0F, 0.0F, 0.55F))),
      ),
    ),
    content="true",
  )
  inspect(
    text_span_bundle_eq(
      span_bundles[1],
      TextSpanBundle::new(TextSpan::new("Anchor(Vec2(-0.5, 0.5)) "), root_font)
      .with_color(TextColor::new(@sprite.Color::srgb(1.0F, 0.63F, 0.48F)))
      .with_background_color(
        Some(
          TextBackgroundColor::new(@sprite.Color::srgb(0.7F, 0.441F, 0.336F)),
        ),
      ),
    ),
    content="true",
  )
}

///|
test "ui text bridge preserves runtime-owned placement during sync" {
  reset_text_ecs_test_state()
  let app = @asset.asset_plugin(@app.App::new(@ecs.World::new()))
  let world = app.world()
  let entity = world.spawn()
  let bundle = Text2dBundle::{
    text: Text2d::new("Button"),
    font: TextFont::default(),
    color: TextColor::default(),
    background_color: None,
    underline: None,
    strikethrough: None,
    layout: TextLayout::default(),
    bounds: TextBounds::default(),
    line_height: LineHeight::default(),
    shadow: None,
    transform: @transform.Transform::identity(),
    layers: @sprite.RenderLayers::default(),
    anchor: @sprite.Anchor::default(),
    y_axis: YAxisOrientation::TopToBottom,
    logical_viewport_size: None,
  }
  ui_text_ecs_spawn_entry(world, world.world_id(), entity, bundle, [])
  let entry = ui_text_ecs_bridge_entries.val[0]
  let runtime_transform = @transform.Transform::from_xyz(320.0F, -180.0F, 7.0F)
  let runtime_layers = @sprite.RenderLayers::layer(11)
  text_set_transform(entry.handle, runtime_transform)
  text_set_layers(entry.handle, runtime_layers)
  text_set_anchor(entry.handle, @sprite.Anchor::center())
  text_set_y_axis(entry.handle, YAxisOrientation::BottomToTop)

  let synced = ui_text_ecs_sync_existing_entry(world, entry, bundle, [])
  let instance = text_state.val.texts[0]

  inspect(
    text_get_transform(synced.handle).unwrap().to_json(),
    content="Array([Number(320), Number(-180), Number(7), Number(0), Number(0), Number(0), Number(1), Number(1), Number(1), Number(1)])",
  )
  inspect(instance.layers.to_json(), content="Number(2048)")
  inspect(instance.anchor.to_json(), content="Array([Number(0), Number(0)])")
  inspect(
    y_axis_eq(instance.y_axis, YAxisOrientation::BottomToTop),
    content="true",
  )
}
