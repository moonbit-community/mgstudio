# ECS Usage Guide

This package implements the typed ECS storage used by mgstudio. The current
model is key-owned typed storage: a `ComponentKey[T]`, `ResourceKey[T]`,
`MessageKey[T]`, or `EventKey[T]` is the authority for accessing values of that
exact `T`.

The `World` stores structural metadata such as entities, archetypes, tables,
local component ids, and tick metadata. It does not store values through a
project-wide erased payload. Typed values live behind access closures captured
by the typed keys at registration time.

## Registering Types

Define one stable key per component or resource type, then return that key from
the type implementation.

```moonbit
struct Position {
  mut x : Float
  mut y : Float
}

let position_key : ComponentKey[Position] = register_component(
  debug_name="mgstudio_example::Position",
)

pub impl Component for Position with component() {
  position_key
}

struct FrameStats {
  mut frame_count : Int
}

let frame_stats_key : ResourceKey[FrameStats] = register_resource(
  debug_name="mgstudio_example::FrameStats",
)
```

Do not reconstruct keys from integer ids. Integer component ids are only useful
for structural metadata, membership checks, removals, and archetype/table
bookkeeping. They are not enough to recover `T`.

Do not register the same component or resource from helper functions on demand.
Registration creates the typed storage closure, so the key should be a stable
package-level value.

## Components

Use the typed key when operating on entities directly:

```moonbit
let world = World::new()
let entity = world.spawn_empty()

try! world.set_by_key(entity, position_key, Position::{ x: 0.0F, y: 1.0F })

let position = try! world.get_by_key(entity, position_key)
debug_inspect(position, content="Some({ x: 0, y: 1 })")

let position_mut = (try! world.get_mut(entity, position_key)).unwrap()
position_mut.modify(fn(value) {
  value.x = value.x + 1.0F
})
```

`get_by_key` returns a typed snapshot. `get_mut` returns a `Mut[T]` handle that
keeps the exact key and table row that produced the fetch. Read methods such as
`Mut::peek` and `Mut::value` do not mark the component changed. Mutation methods
such as `Mut::set`, `Mut::modify`, `Mut::update`, and `Mut::set_changed` record
change ticks.

For types implementing `Component`, the convenience methods without an explicit
key use `T::component()`:

```moonbit
try! world.set(entity, Position::{ x: 0.0F, y: 1.0F })
let position : Position? = try! world.get(entity)
```

Prefer explicit keys in generic code when the caller already has the key. That
keeps the storage authority visible and avoids accidental fresh registration.

## Resources

Resources are direct typed values. Do not wrap a resource in `Ref[T]` just to
make it mutable. Use mutable fields on the resource value and mutate it through
`ResourceMut`.

```moonbit
world.insert_resource(frame_stats_key, FrameStats::{ frame_count: 0 })

let stats = world.get_resource(frame_stats_key).unwrap()
debug_inspect(stats.frame_count, content="0")

let stats_mut = world.get_resource_mut(frame_stats_key).unwrap()
stats_mut.modify(fn(value) {
  value.frame_count = value.frame_count + 1
})
```

The ECS package itself only needs the `ResourceKey[T]`. Packages that expose a
resource to app-level system parameters should additionally implement the app
resource trait by returning the same stable key:

```moonbit
pub impl @app.Resource for FrameStats with resource() {
  frame_stats_key
}
```

`ResourceMut::peek` is a read and does not mark the resource changed.
`ResourceMut::set`, `ResourceMut::modify`, `ResourceMut::update`, and
`ResourceMut::set_changed` update resource change metadata. Use
`ResourceMut::set_if_neq` for `Eq` resources when unchanged writes should not
produce change ticks.

## Queries

Queries fetch typed data through `QueryData`. Use `Comp[T]` for read access and
`Mut[T]` for write access:

```moonbit
struct Velocity {
  dx : Float
  dy : Float
}

let velocity_key : ComponentKey[Velocity] = register_component(
  debug_name="mgstudio_example::Velocity",
)

let query : Query[(Mut[Position], Comp[Velocity]), All] = query(world)

try! query.view(fn(_entity, data) {
  let (position, velocity) = data
  position.modify(fn(value) {
    value.x = value.x + velocity.value().dx
    value.y = value.y + velocity.value().dy
  })
})
```

Filters use typed component keys:

```moonbit
let moving : Query[Mut[Position], With[Velocity]] = query_filtered(
  world,
  With::new(velocity_key),
)
```

During `Query::view`, non-structural replacement of an already-present
component is allowed, but structural changes that would invalidate iteration are
not. Inserting a new component, removing a component, or despawning an entity
during active query iteration raises `StructuralChangeDuringQueryIteration`.

## Storage Model

Components use table storage by default. Table components store their canonical
values in typed table-row slots captured by `ComponentKey[T]`. Entity-keyed
staging exists only while an insertion transaction is assembling the next table
row.

Sparse-set components are explicit:

```moonbit
ignore(component_metadata_builder(my_key).storage_sparse_set())
```

The table itself owns structure and tick metadata, while typed component values
are moved through the `ComponentOps` attached to the registered key. Table-row
fast paths must keep `(table_id, row_index)` aligned with
`World::entity_table_location(entity)`; cached rows are invalid after structural
migration.

## Rules For New ECS Code

- Keep typed keys as the source of truth for value access.
- Pass `ComponentKey[T]` or `ResourceKey[T]` through generic APIs instead of
  recovering type information from raw integer ids.
- Store ordinary resources and components as direct typed values, not nested
  payload wrappers.
- Use `Mut` and `ResourceMut` mutation methods to update change ticks.
- Treat `peek`, `value`, and plain `get` calls as reads.
- Keep structural changes out of active query iteration.
- Use `component_metadata_builder` for storage policy, required components,
  hooks, and relationship metadata.

The old erased-payload model is intentionally gone. Reintroducing a generic
payload enum, downcast registry, or id-to-key recovery path would bypass the
typed storage boundary and recreate the same correctness problem under a
different name.
