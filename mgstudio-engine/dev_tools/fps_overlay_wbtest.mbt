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
fn overlay_test_app(config : FpsOverlayConfig) -> @app.App[@ecs.World] {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    @time.TimePlugin::default(),
  )
  fps_overlay_plugin_with(app, FpsOverlayPlugin::{ config, })
}

///|
test "dev_tools: fps overlay startup spawns root, text, graph, and bars" {
  let app = overlay_test_app(FpsOverlayConfig::default()).run_startup()
  let state = try! app
    .world()
    .get_resource(fps_overlay_state_resource_key)
    .unwrap()
  guard state.root_entity is Some(root_entity) else {
    abort("missing overlay root")
  }
  guard state.text_entity is Some(text_entity) else {
    abort("missing overlay text")
  }
  guard state.text_value_span_entity is Some(text_value_span_entity) else {
    abort("missing overlay text value span")
  }
  guard state.graph_entity is Some(graph_entity) else {
    abort("missing overlay graph")
  }

  debug_inspect(state.bar_entities.length(), content="0")
  debug_inspect(
    try! (app.world().get_by_key(root_entity, @ui.ecs_key_ui_root) is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (app.world().get_by_key(text_entity, @text.ecs_key_text) is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (app.world().get_by_key(text_entity, ecs_key_fps_text) is Some(_)),
    content="true",
  )
  debug_inspect(
    try! app.world().get_by_key(text_entity, @picking.ecs_key_pickable).unwrap(),
    content="{ should_block_lower: false, is_hoverable: false }",
  )
  debug_inspect(
    try! (app
    .world()
    .get_by_key(text_value_span_entity, @text.ecs_key_text_span)
    is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (app.world().get_by_key(graph_entity, @ui.ecs_key_node) is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (app.world().get_by_key(graph_entity, ecs_key_frame_time_graph)
    is Some(_)),
    content="true",
  )
  debug_inspect(
    try! app
    .world()
    .get_by_key(graph_entity, @picking.ecs_key_pickable)
    .unwrap(),
    content="{ should_block_lower: false, is_hoverable: false }",
  )
}

///|
test "dev_tools: fps overlay installs frame time graph plugin" {
  let app = overlay_test_app(FpsOverlayConfig::default())
  debug_inspect(
    app.plugin_names().contains("mgstudio.dev_tools.FrameTimeGraphPlugin"),
    content="true",
  )
}

///|
test "dev_tools: frame time graph plugin does not install fps overlay" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@diagnostic.DiagnosticsPlugin::default())
    .add_plugins(@diagnostic.FrameTimeDiagnosticsPlugin::default())
    .add_plugins(FrameTimeGraphPlugin::default())
  debug_inspect(
    (app.world().get_resource(FpsOverlayConfig::resource()) catch { _ => None })
    is Some(_),
    content="false",
  )
}

///|
test "dev_tools: fps overlay hides text and graph when disabled" {
  let mut app = overlay_test_app(FpsOverlayConfig::default()).run_startup()
  let state = try! app
    .world()
    .get_resource(fps_overlay_state_resource_key)
    .unwrap()
  let config = try! app
    .world()
    .get_resource(FpsOverlayConfig::resource())
    .unwrap()
  config.enabled = false
  config.frame_time_graph_config.enabled = false
  app.world().insert_resource(FpsOverlayConfig::resource(), config)
  app = app.update()
  guard state.text_entity is Some(text_entity) else {
    abort("missing overlay text")
  }
  guard state.graph_entity is Some(graph_entity) else {
    abort("missing overlay graph")
  }

  let text_node = try! app
    .world()
    .get_by_key(text_entity, @ui.ecs_key_node)
    .unwrap()
  let graph_node = try! app
    .world()
    .get_by_key(graph_entity, @ui.ecs_key_node)
    .unwrap()
  debug_inspect(text_node.display, content="None")
  debug_inspect(graph_node.display, content="None")
}

///|
test "dev_tools: fps overlay updates text and graph from diagnostics" {
  let mut app = overlay_test_app(FpsOverlayConfig::default()).run_startup()
  app = app.insert_resource(
    @time.TimeUpdateStrategy::ManualDuration(@core.Duration::from_millis(100)),
  )
  for _ in 0..<3 {
    app = app.update()
  }
  let state = try! app
    .world()
    .get_resource(fps_overlay_state_resource_key)
    .unwrap()
  guard state.text_entity is Some(text_entity) else {
    abort("missing overlay text entity")
  }
  guard state.text_value_span_entity is Some(text_value_span_entity) else {
    abort("missing overlay text value span")
  }
  debug_inspect(
    app.world().get_by_key(text_entity, @text.ecs_key_text).unwrap().content,
    content="\"FPS: \"",
  )
  debug_inspect(
    app
    .world()
    .get_by_key(text_value_span_entity, @text.ecs_key_text_span)
    .unwrap().content.length() >
    0,
    content="true",
  )
  debug_inspect(state.bar_entities.length() > 0, content="true")
  guard state.bar_entities.length() > 0 else {
    abort("missing frame time graph bars")
  }
  let first_bar = state.bar_entities[state.bar_entities.length() - 1]
  let bar_node = try! app
    .world()
    .get_by_key(first_bar, @ui.ecs_key_node)
    .unwrap()
  match bar_node.height {
    @ui.Val::Px(value) => debug_inspect(value > 0.0F, content="true")
    _ => debug_inspect(false, content="true")
  }
}
