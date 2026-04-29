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
test "render settings: default render creation is automatic" {
  match RenderCreation::default() {
    Automatic(settings) => {
      debug_inspect(
        settings.priority == WgpuSettingsPriority::default(),
        content="true",
      )
      debug_inspect(settings.force_fallback_adapter, content="false")
    }
    Manual(_) => abort("default render creation should be automatic")
  }
}

///|
test "render settings: bevy renderer resources use distinct world keys" {
  let device_key = render_device_resource_key()
  let queue_key = render_queue_resource_key()
  let adapter_key = render_adapter_resource_key()
  let adapter_info_key = render_adapter_info_resource_key()
  let instance_key = render_instance_resource_key()
  let pipeline_cache_key = pipeline_cache_resource_key()
  debug_inspect(device_key.id() != queue_key.id(), content="true")
  debug_inspect(device_key.id() != adapter_key.id(), content="true")
  debug_inspect(adapter_key.id() != adapter_info_key.id(), content="true")
  debug_inspect(instance_key.id() != pipeline_cache_key.id(), content="true")
}

///|
test "render schedule: render graph aliases canonical render schedule" {
  let graph = RenderGraph::default()
  ignore(graph)
  debug_inspect(
    RenderGraph::schedule() == render_schedule_stage(),
    content="true",
  )
  debug_inspect(
    RenderGraph::base_schedule().label() == render_schedule_stage(),
    content="true",
  )
}

///|
test "render settings: current view stores the render entity" {
  let entity = @core.Entity::new(42, 7)
  let current = CurrentView::new(entity)
  debug_inspect(current.entity() == entity, content="true")
  debug_inspect(
    current_view_resource_key().id() != render_device_resource_key().id(),
    content="true",
  )
}

///|
test "render plugin: initializes pending command buffers in render app" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    RenderPlugin::default(),
  )
  let render_sub_app = app.get_sub_app(@app.RenderApp).unwrap()
  let render_world = render_sub_app.world()
  let pending = (try! render_world.get_resource(
    pending_command_buffers_resource_key(),
  )).unwrap()
  debug_inspect(pending.is_empty(), content="true")
}

///|
test "render plugin: initializes render state as not ready" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    RenderPlugin::default(),
  )
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let state = (try! render_world.get_resource(render_state_resource_key())).unwrap()
  debug_inspect(state.is_ready(), content="false")
  debug_inspect(renderer_is_ready(render_world), content="false")
  mark_renderer_ready(render_world)
  debug_inspect(renderer_is_ready(render_world), content="true")
}
