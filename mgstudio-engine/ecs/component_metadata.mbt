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
priv struct ComponentRequiredMetadata {
  required_component_id : Int
  init_value : () -> ErasedWriter
}

///|
pub enum ComponentStorageType {
  Table
  SparseSet
} derive(Eq)

///|
pub(all) struct ComponentRelationshipSourceMetadata {
  target_entity : (World, @core.Entity) -> @core.Entity?
  observer_parent_lookup : Bool
}

///|
pub(all) struct ComponentRelationshipTargetMetadata {
  linked_spawn : Bool
  linked_entities : ((DeferredWorld, @core.Entity) -> Array[@core.Entity])?
}

///|
priv struct ComponentMetadata {
  debug_name : String
  storage_type : ComponentStorageType
  hooks : ComponentHooks
  required_components : Array[ComponentRequiredMetadata]
  relationship_source : ComponentRelationshipSourceMetadata?
  relationship_target : ComponentRelationshipTargetMetadata?
}

///|
pub struct ComponentMetadataBuilder[T] {
  key : ComponentKey[T]
}

///|
let component_metadata_registry : @hashmap.HashMap[Int, Ref[ComponentMetadata]] = @hashmap.HashMap::new()

///|
let component_relationship_metadata_generation_ref : Ref[Int] = Ref::new(0)

///|
let component_metadata_bootstrap_ref : Ref[Bool] = Ref::new(false)

///|
fn component_relationship_metadata_generation() -> Int {
  component_relationship_metadata_generation_ref.val
}

///|
fn bump_component_relationship_metadata_generation() -> Unit {
  component_relationship_metadata_generation_ref.val = component_relationship_metadata_generation_ref.val +
    1
}

///|
fn bootstrap_component_metadata() -> Unit {
  if component_metadata_bootstrap_ref.val {
    return
  }
  ignore(
    component_metadata_ref(
      ecs_builtin_component_definition_add,
      debug_name="ecs::lifecycle::add",
    ),
  )
  ignore(
    component_metadata_ref(
      ecs_builtin_component_definition_insert,
      debug_name="ecs::lifecycle::insert",
    ),
  )
  ignore(
    component_metadata_ref(
      ecs_builtin_component_definition_replace,
      debug_name="ecs::lifecycle::replace",
    ),
  )
  ignore(
    component_metadata_ref(
      ecs_builtin_component_definition_remove,
      debug_name="ecs::lifecycle::remove",
    ),
  )
  ignore(
    component_metadata_ref(
      ecs_builtin_component_definition_despawn,
      debug_name="ecs::lifecycle::despawn",
    ),
  )
  ignore(
    component_metadata_ref(
      ecs_builtin_component_definition_is_resource,
      debug_name="ecs::resource::is_resource",
    ),
  )
  component_metadata_bootstrap_ref.val = true
}

///|
fn component_metadata_default(debug_name : String) -> ComponentMetadata {
  {
    debug_name,
    storage_type: Table,
    hooks: ComponentHooks::new(),
    required_components: [],
    relationship_source: None,
    relationship_target: None,
  }
}

///|
fn component_metadata_ref(
  component_id : Int,
  debug_name? : String = "",
) -> Ref[ComponentMetadata] {
  component_metadata_registry.get_or_init(component_id, fn() {
    Ref::new(component_metadata_default(debug_name))
  })
}

///|
fn component_metadata(
  component_id : Int,
  debug_name? : String = "",
) -> ComponentMetadata {
  component_metadata_ref(component_id, debug_name~).val
}

///|
pub fn[T] component_metadata_builder(
  key : ComponentKey[T],
) -> ComponentMetadataBuilder[T] {
  ignore(component_metadata_ref(key.id(), debug_name=key.debug_name()))
  ComponentMetadataBuilder::{ key, }
}

///|
fn component_metadata_require_index(
  entries : Array[ComponentRequiredMetadata],
  required_component_id : Int,
) -> Int? {
  for i in 0..<entries.length() {
    if entries[i].required_component_id == required_component_id {
      return Some(i)
    }
  }
  None
}

///|
fn component_metadata_register_hook(
  component_id : Int,
  debug_name : String,
  kind : ComponentHookKind,
  hook : (DeferredWorld, HookContext) -> Unit,
) -> Unit {
  let metadata_ref = component_metadata_ref(component_id, debug_name~)
  let hooks = metadata_ref.val.hooks
  if component_hooks_kind_registered(hooks, kind) {
    abort(
      "Duplicate static component hook registration for component `\{debug_name}` (\{component_id.to_string()})",
    )
  }
  let updated_hooks = match kind {
    OnAdd => ComponentHooks::{ ..hooks, on_add: Some(hook) }
    OnInsert => ComponentHooks::{ ..hooks, on_insert: Some(hook) }
    OnReplace => ComponentHooks::{ ..hooks, on_replace: Some(hook) }
    OnRemove => ComponentHooks::{ ..hooks, on_remove: Some(hook) }
    OnDespawn => ComponentHooks::{ ..hooks, on_despawn: Some(hook) }
  }
  metadata_ref.val = ComponentMetadata::{
    ..metadata_ref.val,
    hooks: updated_hooks,
  }
}

///|
pub fn[T] ComponentMetadataBuilder::on_add(
  self : ComponentMetadataBuilder[T],
  hook : (DeferredWorld, HookContext) -> Unit,
) -> ComponentMetadataBuilder[T] {
  component_metadata_register_hook(
    self.key.id(),
    self.key.debug_name(),
    OnAdd,
    hook,
  )
  self
}

///|
pub fn[T] ComponentMetadataBuilder::on_insert(
  self : ComponentMetadataBuilder[T],
  hook : (DeferredWorld, HookContext) -> Unit,
) -> ComponentMetadataBuilder[T] {
  component_metadata_register_hook(
    self.key.id(),
    self.key.debug_name(),
    OnInsert,
    hook,
  )
  self
}

///|
pub fn[T] ComponentMetadataBuilder::on_replace(
  self : ComponentMetadataBuilder[T],
  hook : (DeferredWorld, HookContext) -> Unit,
) -> ComponentMetadataBuilder[T] {
  component_metadata_register_hook(
    self.key.id(),
    self.key.debug_name(),
    OnReplace,
    hook,
  )
  self
}

///|
pub fn[T] ComponentMetadataBuilder::on_remove(
  self : ComponentMetadataBuilder[T],
  hook : (DeferredWorld, HookContext) -> Unit,
) -> ComponentMetadataBuilder[T] {
  component_metadata_register_hook(
    self.key.id(),
    self.key.debug_name(),
    OnRemove,
    hook,
  )
  self
}

///|
pub fn[T] ComponentMetadataBuilder::on_despawn(
  self : ComponentMetadataBuilder[T],
  hook : (DeferredWorld, HookContext) -> Unit,
) -> ComponentMetadataBuilder[T] {
  component_metadata_register_hook(
    self.key.id(),
    self.key.debug_name(),
    OnDespawn,
    hook,
  )
  self
}

///|
pub fn[T, R : Default] ComponentMetadataBuilder::require_default(
  self : ComponentMetadataBuilder[T],
  required_key : ComponentKey[R],
) -> ComponentMetadataBuilder[T] {
  self.require_with(required_key, fn() { R::default() })
}

///|
pub fn[T, R] ComponentMetadataBuilder::require_with(
  self : ComponentMetadataBuilder[T],
  required_key : ComponentKey[R],
  init : () -> R,
) -> ComponentMetadataBuilder[T] {
  let metadata_ref = component_metadata_ref(
    self.key.id(),
    debug_name=self.key.debug_name(),
  )
  if component_metadata_require_index(
      metadata_ref.val.required_components,
      required_key.id(),
    )
    is Some(_) {
    abort(
      "Duplicate static required-component registration for component `\{self.key.debug_name()}`",
    )
  }
  let entries = metadata_ref.val.required_components
  entries.push({
    required_component_id: required_key.id(),
    init_value: fn() { erased_writer(required_key, init()) },
  })
  metadata_ref.val = ComponentMetadata::{
    ..metadata_ref.val,
    required_components: entries,
  }
  self
}

///|
pub fn[T] ComponentMetadataBuilder::relationship_source(
  self : ComponentMetadataBuilder[T],
  target_entity : (World, @core.Entity) -> @core.Entity?,
  observer_parent_lookup? : Bool = false,
) -> ComponentMetadataBuilder[T] {
  let metadata_ref = component_metadata_ref(
    self.key.id(),
    debug_name=self.key.debug_name(),
  )
  metadata_ref.val = ComponentMetadata::{
    ..metadata_ref.val,
    relationship_source: Some({ target_entity, observer_parent_lookup }),
  }
  bump_component_relationship_metadata_generation()
  self
}

///|
pub fn[T] ComponentMetadataBuilder::relationship_target(
  self : ComponentMetadataBuilder[T],
  linked_spawn? : Bool = false,
  linked_entities? : ((T) -> Array[@core.Entity])? = None,
) -> ComponentMetadataBuilder[T] {
  let metadata_ref = component_metadata_ref(
    self.key.id(),
    debug_name=self.key.debug_name(),
  )
  let component_key = self.key
  let component_debug_name = self.key.debug_name()
  let linked_entities_accessor = match linked_entities {
    Some(entities_from_component) =>
      Some(fn(world : DeferredWorld, entity : @core.Entity) {
        match (try! world.get_by_key(entity, component_key)) {
          Some(component) => entities_from_component(component)
          None =>
            abort(
              "relationship_target linked_entities accessor missing component `\{component_debug_name}` on entity \{entity.id.to_string()}",
            )
        }
      })
    None => None
  }
  if linked_spawn && linked_entities_accessor is None {
    abort(
      "relationship_target(linked_spawn=true) requires linked_entities for component `\{self.key.debug_name()}`",
    )
  }
  metadata_ref.val = ComponentMetadata::{
    ..metadata_ref.val,
    relationship_target: Some({
      linked_spawn,
      linked_entities: linked_entities_accessor,
    }),
  }
  bump_component_relationship_metadata_generation()
  self
}

///|
pub fn[T] ComponentMetadataBuilder::storage_table(
  self : ComponentMetadataBuilder[T],
) -> ComponentMetadataBuilder[T] {
  let metadata_ref = component_metadata_ref(
    self.key.id(),
    debug_name=self.key.debug_name(),
  )
  metadata_ref.val = ComponentMetadata::{
    ..metadata_ref.val,
    storage_type: Table,
  }
  self
}

///|
pub fn[T] ComponentMetadataBuilder::storage_sparse_set(
  self : ComponentMetadataBuilder[T],
) -> ComponentMetadataBuilder[T] {
  let metadata_ref = component_metadata_ref(
    self.key.id(),
    debug_name=self.key.debug_name(),
  )
  metadata_ref.val = ComponentMetadata::{
    ..metadata_ref.val,
    storage_type: SparseSet,
  }
  self
}
