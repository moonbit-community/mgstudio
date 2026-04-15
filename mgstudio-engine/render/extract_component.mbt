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
fn[C] extract_component_apply(
  render_world : @ecs.World,
  main_world : @ecs.World,
  main_entity : @core.Entity,
  render_entity : @core.Entity,
  component_key : @ecs.ComponentKey[C],
) -> Unit {
  guard (main_world.get_by_key(main_entity, component_key) catch { _ => None })
    is Some(component) else {
    return
  }
  render_world.set_by_key(render_entity, component_key, component) catch {
    _ => ()
  }
}

///|
fn[C] extract_components(
  render_world : @ecs.World,
  only_visible : Bool,
  component_key : @ecs.ComponentKey[C],
) -> Unit {
  let main_world = render_source_world(render_world)
  let query : @ecs.QueryState[@core.Entity, @ecs.With[SyncToRenderWorld]] = main_world.query_filtered(
    @ecs.With::new(ecs_key_sync_to_render_world),
  )
  let iter = query.iter(main_world)
  while (iter.fetch_next() catch { _ => None }) is Some((main_entity, _)) {
    guard (main_world.get(main_entity, key=ecs_key_render_entity) catch {
        _ => None
      })
      is Some(render_entity) else {
      continue
    }
    if only_visible {
      guard (main_world.get(
          main_entity,
          key=@visibility.ecs_key_view_visibility,
        ) catch {
          _ => None
        })
        is Some(view_visibility) else {
        continue
      }
      if !view_visibility.is_visible() {
        continue
      }
    }
    extract_component_apply(
      render_world,
      main_world,
      main_entity,
      render_entity.id(),
      component_key,
    )
  }
}

///|
pub fn extract_component_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  render_plugin(app)
}

///|
pub fn[C : @ecs.Component, F] extract_component_plugin_with(
  app : @app.App[@ecs.World],
  plugin : ExtractComponentPlugin[C, F],
) -> @app.App[@ecs.World] {
  let sync_component : SyncComponentPlugin[C, F] = SyncComponentPlugin::default()
  let next = sync_component_plugin_with(render_plugin(app), sync_component)
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
