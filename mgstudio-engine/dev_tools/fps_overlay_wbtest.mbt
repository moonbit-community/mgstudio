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
  @app.App::new(@ecs.World::new()).add_plugins([
    @time.time_plugin,
    fn(app) { fps_overlay_plugin_with(app, FpsOverlayPlugin::{ config, }) },
  ])
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
  guard state.graph_entity is Some(graph_entity) else {
    abort("missing overlay graph")
  }

  inspect(state.bar_entities.length(), content="0")
  inspect(
    try! (app.world().get_by_key(root_entity, @ui.ecs_key_ui_root) is Some(_)),
    content="true",
  )
  inspect(
    try! (app.world().get_by_key(text_entity, @text.ecs_key_text) is Some(_)),
    content="true",
  )
  inspect(
    try! (app.world().get_by_key(graph_entity, @ui.ecs_key_node) is Some(_)),
    content="true",
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
  inspect(text_node.display, content="None")
  inspect(graph_node.display, content="None")
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
  inspect(
    app.world().get_by_key(text_entity, @text.ecs_key_text).unwrap().content.contains(
      "FPS: ",
    ),
    content="true",
  )
  inspect(state.bar_entities.length() > 0, content="true")
  guard state.bar_entities.length() > 0 else {
    abort("missing frame time graph bars")
  }
  let first_bar = state.bar_entities[state.bar_entities.length() - 1]
  let bar_node = try! app
    .world()
    .get_by_key(first_bar, @ui.ecs_key_node)
    .unwrap()
  match bar_node.height {
    @ui.Val::Px(value) => inspect(value > 0.0F, content="true")
    _ => inspect(false, content="true")
  }
}
