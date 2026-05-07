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
pub let ecs_key_parent : @ecs.ComponentKey[Parent] = @ecs.register_component(
  debug_name="hierarchy.parent",
)

///|
pub let ecs_key_children : @ecs.ComponentKey[Children] = @ecs.register_component(
  debug_name="hierarchy.children",
)

///|
pub impl @ecs.Component for Parent with component() {
  ecs_key_parent
}

///|
pub impl @ecs.Component for Children with component() {
  ecs_key_children
}

///|
let hierarchy_component_metadata_installed : Ref[Bool] = Ref(false)

///|
pub fn hierarchy_install_component_metadata() -> Unit {
  if hierarchy_component_metadata_installed.val {
    return
  }
  ignore(
    @ecs.component_metadata_builder(ecs_key_parent)
    .on_insert(fn(world, context) {
      hierarchy_parent_on_insert(
        world,
        ecs_key_parent,
        ecs_key_children,
        context.entity,
      )
    })
    .on_replace(fn(world, context) {
      hierarchy_parent_on_replace(
        world,
        ecs_key_parent,
        ecs_key_children,
        context.entity,
      )
    })
    .on_remove(fn(world, context) {
      hierarchy_parent_on_remove(
        world,
        ecs_key_parent,
        ecs_key_children,
        context.entity,
      )
    })
    .relationship_source(
      fn(world, entity) {
        match (try! world.get_by_key(entity, ecs_key_parent)) {
          Some(parent) => Some(parent.entity())
          None => None
        }
      },
      observer_parent_lookup=true,
    ),
  )
  ignore(
    @ecs.component_metadata_builder(ecs_key_children).relationship_target(
      linked_spawn=true,
      linked_entities=Some(fn(children : Children) { children.entities() }),
    ),
  )
  hierarchy_component_metadata_installed.val = true
}
