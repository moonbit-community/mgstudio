# ECS Typed Storage Boundary

Status: implemented  
Date: 2026-05-22

## Summary

ECS live storage is now typed. Components, resources, messages, events, and
asset stores no longer depend on a project-wide erased payload enum or generated
codec glue for ordinary access.

The canonical invariant is:

- `ComponentKey[T]`, `ResourceKey[T]`, `MessageKey[T]`, and `EventKey[T]` own
  their typed access closures.
- typed storage maps are captured by those keys at registration time and are
  partitioned by world id where needed.
- table components store their canonical values in typed table-row slots once
  the entity has a table location; entity-keyed staging exists only while a
  structural insert transaction is assembling the next table row.
- call sites must pass the typed key they already have for typed values and
  resource change metadata; an integer definition id is only enough for
  typeless structural operations such as component presence checks, removals,
  and membership metadata.
- deferred component insertion stores a typed writer closure that captures the
  pending value and applies it through the typed key later.

There is intentionally no API for reconstructing a typed key from an integer id.
That would require downcast-like behavior and would recreate the same boundary
problem under another name.

The old `core.Resource[T]` single-cell `Ref[T]` container has been removed. It
was not the ECS resource model and only preserved an outdated idea that generic
resources should expose mutable cells. ECS resources are owned by typed
`ResourceKey[T]` closures and surfaced through `Res[T]` / `ResMut[T]`.

Resource values and their change ticks live in the same typed
`TypedResourceSlot[T]` captured by `ResourceKey[T]`. `World` keeps only a
`WorldResourceTickRegistry` of active-resource tick-normalization callbacks so
`World::check_change_ticks` can visit resources without owning or recovering
their typed values.

App sub-app storage follows the same ownership rule. `SubApps` stores
`SubApp[W]` values directly and exposes explicit replacement/modification
operations; it does not wrap each sub-app in `Ref[SubApp[W]]`.

Internal app registries and system state follow the same direct-state rule:
registered one-shot systems, stepping state, observer run ticks, state
transition hooks, schedule-set run conditions, picking events, and picking state
are stored as mutable typed values, not as `Ref`-wrapped cells. `Local[T]`
persists through `SystemParamState` get/store closures that own the current `T`;
systems update it through `Local::set`.

Adjacent resource-backed registries use the same shape. Render asset stores,
erased render asset stores, diagnostics, UI stack state, and physics context /
event resources store direct typed values and mark resource changes through the
resource access API instead of exposing nested `Ref` handles.

## Table Storage

`RawTable` owns structure, entity rows, and change metadata. It does not own a
generic erased component payload. Instead, each registered `ComponentKey[T]`
captures the typed row storage for that component and exposes narrow structural
operations through `ComponentOps`.

When an entity migrates between tables, `RawTable::append_row_from_source_table`
moves typed values from the source row or from transaction staging into the
target row. When a table row is swap-removed, the same `ComponentOps` path keeps
the typed row storage in lock-step with the entity row and tick metadata buffers.

Hot table access should use `(table_id, row_index)` directly. Code that already
has a table row must not fetch by entity and then re-enter generic component
lookup, because that turns the table into a metadata-only index and loses the
Bevy-shaped column-storage boundary.

Query execution must obtain entity table coordinates through
`World::entity_table_location`. It must not inspect `WorldEntityStorageState`
arrays directly, because the alive/entity-id bounds checks and invalid-location
encoding are part of the world storage interface.

`ComponentColumn` follows the same rule. Cached table-row fast paths may reuse a
known `(table_id, row_index)`, but before reading or writing a value for an
entity they must confirm that `World::entity_table_location(entity)` still
matches the cached coordinates. Cached rows are invalid after structural
migration.

Planned query fetch uses explicit fetch contexts instead of repeated scalar
parameter lists. `QueryDataTableRowFetch` is the table-row authority,
`QueryDataPlannedFetch` pairs that row with a fetch plan and offset, and
`QueryDataSparseAnchorFetch` adds the sparse-set anchor component. Wrapper
methods that only forwarded to `*_with_plan_offset(..., 0)` are intentionally
absent from `QueryData`; the query executor constructs the root context with
offset `0`, and tuple query data advances the offset with `fetch_plan_size()`.

Fetched component items retain the exact typed key that produced them. Methods
such as `Comp::key()` and `Mut::key()` return the captured key, not a fresh
`Component::component()` lookup. This is required because MoonBit has no safe
runtime downcast path from a structural component id back to the original `T`;
the key is the typed storage authority.

Table component query fetches must fail if the table row has metadata but the
typed row value is missing. Sparse-set components are explicitly fetched through
entity-keyed typed storage, but table components must not silently fall back to
entity lookup, because that would hide table migration bugs.

## Mutation Boundaries

Read access does not mark values changed. `Mut::peek`, `Mut::value`,
`ResourceMut::peek`, and `ResMut::get` are read operations. Change ticks are
recorded only through explicit mutation APIs such as `set`, `modify`, `update`,
and `set_changed`.

This matches the engine invariant that dirty propagation should represent actual
component/resource mutation, not the mere acquisition of a mutable-capable handle.

## Generic Types

Generic runtime containers must not encode their elements into an erased payload
tree just to be stored in the ECS. Instead, generic owners expose typed key packs:

- assets implement `Asset::asset_resource_keys()`;
- states implement `States::state_resource_keys()`;
- 2D materials implement `Material2d::material2d_keys()`;
- gizmo config groups implement `GizmoConfigGroup::gizmo_storage_resource_key()`;
- focused-input and widget helper generics use source-type-provided typed keys.

This keeps registration local to the concrete type that knows the full `T` and
lets generic systems use the typed key without a registry lookup or runtime
type recovery.

## Custom Projection

Custom 3D projections also follow the same rule. `CustomProjection3d` stores
typed behavior closures that capture the original projection value. It does not
store an erased value and does not expose a generic `get[T]` downcast API.

If a caller needs to inspect the original projection data, that data must remain
owned by the caller or by an explicit typed component/resource. A projection enum
value only promises projection behavior: matrix generation, update, far plane,
and frustum-corner computation.

## Completion Checks

The migration is considered complete only when:

- no source package uses generated ECS payload files;
- no generated public interface exposes the removed payload codec surface;
- no source code calls erased component/resource registration or typed-key
  recovery from raw ids;
- `moon check --target native`, `moon fmt`, and `moon info` succeed.
