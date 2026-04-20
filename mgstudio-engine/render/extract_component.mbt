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
// Bevy source: `bevy/crates/bevy_render/src/extract_component.rs`.

///|
const EXTRACT_COMPONENT_PLUGIN_NAME : String = "mgstudio.render.ExtractComponentPlugin"

///|
pub struct DynamicUniformIndex[_] {
  index : UInt
}

///|
pub fn[C] DynamicUniformIndex::new(index : UInt) -> DynamicUniformIndex[C] {
  DynamicUniformIndex::{ index, }
}

///|
pub fn[C] DynamicUniformIndex::index(self : DynamicUniformIndex[C]) -> UInt {
  self.index
}

///|
pub struct ComponentUniforms[C] {
  uniforms : Array[C]
}

///|
pub fn[C] ComponentUniforms::default() -> ComponentUniforms[C] {
  ComponentUniforms::{ uniforms: [] }
}

///|
pub fn[C] ComponentUniforms::push(
  self : ComponentUniforms[C],
  component : C,
) -> Unit {
  self.uniforms.push(component)
}

///|
pub fn[C] ComponentUniforms::len(self : ComponentUniforms[C]) -> Int {
  self.uniforms.length()
}

///|
pub struct ExtractComponentPlugin[_, _] {
  only_extract_visible : Bool
}

///|
pub fn[C, F] ExtractComponentPlugin::default() -> ExtractComponentPlugin[C, F] {
  ExtractComponentPlugin::{ only_extract_visible: false }
}

///|
pub fn[C, F] ExtractComponentPlugin::extract_visible() -> ExtractComponentPlugin[
  C,
  F,
] {
  ExtractComponentPlugin::{ only_extract_visible: true }
}

///|
pub fn[C, F] extract_component_only_extract_visible(
  plugin : ExtractComponentPlugin[C, F],
) -> Bool {
  plugin.only_extract_visible
}

///|
pub impl[C : @ecs.Component, F] @app.Plugin for ExtractComponentPlugin[C, F] with name(
  _self,
) {
  EXTRACT_COMPONENT_PLUGIN_NAME
}

///|
pub impl[C : @ecs.Component, F] @app.Plugin for ExtractComponentPlugin[C, F] with build(
  self,
  app,
) {
  extract_component_plugin_with(app, self)
}

///|
fn[C : @ecs.Component] extract_components(
  render_world : @ecs.World,
  only_visible : Bool,
  component_key : @ecs.ComponentKey[C],
) -> Unit {
  let main_world = render_source_world(render_world)
  guard main_world.component_column(component_key)
    is Some(main_component_column) else {
    return
  }
  guard main_world.component_column(ecs_key_render_entity)
    is Some(render_entity_column) else {
    return
  }
  let visibility_column = if only_visible {
    main_world.component_column(@visibility.ecs_key_view_visibility)
  } else {
    None
  }
  let sequence = main_world.get_sequence_context().sequence()
  let render_component_column = render_world.component_column(component_key)
  let processed : Map[UInt64, Bool] = {}
  let extract_entity = fn(main_entity : @core.Entity) {
    let key = (main_entity.id.reinterpret_as_uint().to_uint64() << 32) |
      (main_entity.generation.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL)
    if processed.contains(key) {
      return
    }
    processed.set(key, true)
    guard render_entity_column.get(main_entity) is Some(render_entity) else {
      return
    }
    if visibility_column is Some(visibility_column) {
      guard visibility_column.get(main_entity) is Some(view_visibility) else {
        return
      }
      if !view_visibility.is_visible() {
        return
      }
    }
    guard main_component_column.get_ref(main_entity) is Some(component) else {
      return
    }
    let wrote = match render_component_column {
      Some(column) =>
        column.set_sequence_only(render_entity.id(), component.val)
      None => false
    }
    if !wrote {
      render_world.set_by_key(render_entity.id(), component_key, component.val) catch {
        _ => ()
      }
    }
  }

  for entity in main_world.added_components(component_key, sequence).read() {
    extract_entity(entity)
  }
  for entity in main_world.changed_components(component_key, sequence).read() {
    extract_entity(entity)
  }
  for
    entity in main_world
    .added_components(ecs_key_render_entity, sequence)
    .read() {
    extract_entity(entity)
  }
  if only_visible {
    for
      entity in main_world
      .added_components(@visibility.ecs_key_view_visibility, sequence)
      .read() {
      extract_entity(entity)
    }
    for
      entity in main_world
      .changed_components(@visibility.ecs_key_view_visibility, sequence)
      .read() {
      extract_entity(entity)
    }
  }

  let render_component_query : @ecs.Query[@ecs.Comp[C], @ecs.All] = @ecs.query(
    render_world,
  )
  if processed.is_empty() && render_component_query.count() == 0 {
    main_component_column.for_each_ref(fn(main_entity, component) {
      guard render_entity_column.get(main_entity) is Some(render_entity) else {
        return
      }
      if visibility_column is Some(visibility_column) {
        guard visibility_column.get(main_entity) is Some(view_visibility) else {
          return
        }
        if !view_visibility.is_visible() {
          return
        }
      }
      let wrote = match render_component_column {
        Some(column) =>
          column.set_sequence_only(render_entity.id(), component.val)
        None => false
      }
      if !wrote {
        render_world.set_by_key(
          render_entity.id(),
          component_key,
          component.val,
        ) catch {
          _ => ()
        }
      }
    })
  }
}

///|
pub fn extract_component_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
}

///|
pub fn[C : @ecs.Component, F] extract_component_plugin_with(
  app : @app.App[@ecs.World],
  plugin : ExtractComponentPlugin[C, F],
) -> @app.App[@ecs.World] {
  let sync_component : SyncComponentPlugin[C, F] = SyncComponentPlugin::default()
  let next = sync_component_plugin_with(app, sync_component)
  let component_key = C::component()
  with_render_app(next, fn(sub_app : @app.SubApp[@ecs.World]) {
    let stage = render_schedule_stage()
    if plugin.only_extract_visible {
      sub_app.add_systems(
        stage,
        @app.system(fn(render_world : @ecs.World) -> Unit {
          extract_components(render_world, true, component_key)
        }).in_set(render_system_set_extract_commands),
      )
    } else {
      sub_app.add_systems(
        stage,
        @app.system(fn(render_world : @ecs.World) -> Unit {
          extract_components(render_world, false, component_key)
        }).in_set(render_system_set_extract_commands),
      )
    }
  })
}

///|
pub fn extract_component_source_world(world : @ecs.World) -> @ecs.World {
  render_source_world(world)
}
