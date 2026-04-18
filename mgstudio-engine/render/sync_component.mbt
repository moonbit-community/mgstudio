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
// Bevy source: `bevy/crates/bevy_render/src/sync_component.rs`.

///|
const SYNC_COMPONENT_PLUGIN_NAME : String = "mgstudio.render.SyncComponentPlugin"

///|
pub struct SyncComponentPlugin[_, _] {}

///|
pub fn[C, F] SyncComponentPlugin::default() -> SyncComponentPlugin[C, F] {
  SyncComponentPlugin::{  }
}

///|
pub impl[C : @ecs.Component, F] @app.Plugin for SyncComponentPlugin[C, F] with name(
  _self,
) {
  SYNC_COMPONENT_PLUGIN_NAME
}

///|
pub impl[C : @ecs.Component, F] @app.Plugin for SyncComponentPlugin[C, F] with build(
  self,
  app,
) {
  sync_component_plugin_with(app, self)
}

///|
fn[C] sync_component_register_required_component(
  world : @ecs.World,
  component_key : @ecs.ComponentKey[C],
) -> Unit {
  world.try_register_required_components(
    component_key, ecs_key_sync_to_render_world,
  ) catch {
    _ =>
      abort(
        "sync_component: failed to register SyncToRenderWorld as required component",
      )
  }
}

///|
fn[C] sync_component_register_remove_hook(
  world : @ecs.World,
  component_key : @ecs.ComponentKey[C],
) -> Unit {
  let hook_builder = world.register_component_hooks_for_key(component_key)
  ignore(
    hook_builder.on_remove(fn(
      deferred_world : @ecs.DeferredWorld,
      context : @ecs.HookContext,
    ) -> Unit {
      let pending_resource = deferred_world.resource(
        ecs_key_pending_sync_entity,
      )
      if !pending_resource.is_present() {
        pending_resource.insert(PendingSyncEntity::default())
      }
      ignore(
        pending_resource.update(fn(
          pending : PendingSyncEntity,
        ) -> PendingSyncEntity {
          pending.push(
            EntityRecord::ComponentRemoved(context.entity, fn(
              render_world : @ecs.World,
              render_entity : @core.Entity,
            ) -> @ecs.World {
              ignore(
                render_world.remove_by_key(render_entity, component_key) catch {
                  _ => false
                },
              )
              render_world
            }),
          )
          pending
        }),
      )
    }) catch {
      _ => abort("sync_component: failed to register remove hook")
    },
  )
}

///|
pub fn sync_component_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
}

///|
pub fn[C : @ecs.Component, F] sync_component_plugin_with(
  app : @app.App[@ecs.World],
  plugin : SyncComponentPlugin[C, F],
) -> @app.App[@ecs.World] {
  ignore(plugin)
  let next = app
  let world = next.world()
  let component_key = C::component()
  sync_component_register_required_component(world, component_key)
  sync_component_register_remove_hook(world, component_key)
  next
}

///|
pub fn[C] sync_component(
  world : @ecs.World,
  entity : @core.Entity,
  component_key : @ecs.ComponentKey[C],
) -> @ecs.World {
  ignore(world.remove_by_key(entity, component_key) catch { _ => false })
  world
}
