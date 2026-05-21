# ECS Typed Storage And Payload Boundaries

Status: implementation note  
Date: 2026-05-21

## Summary

`EcsPayload` should not be the canonical storage representation for every ECS
component and resource. It is useful as an erased boundary format for deferred
commands, observer payloads, messages, events, debugging, and generated glue,
but Bevy parity requires normal ECS access to operate on the stored typed
objects themselves.

The current `GpuArrayBufferPayload` shape is a symptom of a larger boundary
problem. The important question is not whether this one payload can avoid
nested `EcsPayload`; the real question is whether runtime ECS storage should be
a recursively encoded payload tree at all. It should not.

The implemented direction is:

- components and resources are canonically stored as typed values;
- type erasure exists at the storage registry and command boundary, not inside
  each generic runtime value;
- `EcsPayloadCodec` is a boundary conversion mechanism, not the normal mutable
  storage path;
- `ResourceMut<T>` and query `Mut<T>` must mutate the canonical stored `T`,
  matching Bevy's `ResMut<T>` and query mutation semantics.

## Prior Implementation

Before the typed-storage refactor, `World` stored resources as:

```moonbit
struct ResourceSlot {
  mut payload : EcsPayload
  mut added_tick : @core.Tick?
  mut changed_tick : @core.Tick?
  mut changed_caller : String?
}
```

and component table/sparse storage also stored `EcsPayload` values. Public typed
APIs decoded from payload on read:

```moonbit
fn[T : EcsPayloadCodec] World::resource_value(
  _self : World,
  key : ResourceKey[T],
  payload : EcsPayload,
) -> T raise EcsError {
  match T::from_ecs_payload(payload) {
    Some(value) => value
    None => raise ResourceTypeMismatch(...)
  }
}
```

`ResourceMut::modify` then called `peek`, passed the decoded value to the user
closure, and only marked the resource as changed:

```moonbit
pub fn[T : EcsPayloadCodec, R] ResourceMut::modify(
  self : ResourceMut[T],
  f : (T) -> R,
) -> R {
  let value = self.peek()
  let result = f(value)
  self.set_changed()
  result
}
```

That API shape was only correct when `from_ecs_payload` returned an object graph
identical to the canonical storage graph. Some generated codecs did that by
wrapping the concrete value directly in an `EcsPayload` variant. Other codecs,
especially generic aggregate codecs, rebuilt typed values from nested payloads.
That made mutable access identity semantics inconsistent.

After the refactor, `ComponentKey<T>` and `ResourceKey<T>` carry typed access
capabilities. The world keeps structural metadata and erased boundary ops, while
the canonical component/resource values live in typed stores captured by those
keys and partitioned by `world_id`.

## Why `GpuArrayBufferPayload` Exists

`GpuArrayBuffer[T]` is generic:

```moonbit
pub struct GpuArrayBuffer[T] {
  values : Array[T]
  buffer_id : BufferId
}
```

The `EcsPayload` enum is not generic, so the generated payload cannot
store `Array[T]` directly while still being one non-generic `EcsPayload`
variant. A payload codec therefore has to erase every element when such a value
crosses an erased boundary:

```moonbit
pub(all) struct GpuArrayBufferPayload {
  values : Array[@ecs.EcsPayload]
  buffer_id : BufferId
}
```

and reconstructs a typed buffer on read:

```moonbit
let buffer : GpuArrayBuffer[T] = GpuArrayBuffer::{
  values: [],
  buffer_id: value.buffer_id,
}
for item_payload in value.values {
  match T::from_ecs_payload(item_payload) {
    Some(item) => buffer.values.push(item)
    None => return None
  }
}
Some(buffer)
```

This is acceptable as boundary encoding, but it must not be the live storage
representation for a generic runtime object. It is not how Bevy stores the
equivalent value.

## What Bevy Does

Bevy stores ECS data in typed component/resource storage keyed by type identity.
For example:

```rust
#[derive(Resource)]
pub enum GpuArrayBuffer<T: GpuArrayBufferable> {
    Uniform(BatchedUniformBuffer<T>),
    Storage(BufferVec<T>),
}
```

`ResMut<GpuArrayBuffer<T>>` is mutable access to the actual stored resource.
Query `Mut<T>` is mutable access to the actual stored component. Bevy does not
serialize a resource into an erased enum and then recursively decode it for
ordinary ECS access.

Therefore, Bevy parity is not just about the shape of `GpuArrayBuffer`. It is
also about the mutation and identity contract of ECS storage itself.

## Why Local Fixes Are Not Enough

### Special-casing `GpuArrayBuffer`

Making `GpuArrayBuffer` avoid `EcsPayloadCodec` would fix one symptom while
leaving the same identity problem in other generic runtime values, such as
render asset maps, prepare-next-frame queues, storage buffers, and future
generic component/resource containers.

It would also make render behavior depend on an exception instead of the ECS
contract.

### Adding a resource-only typed side channel

A second typed resource map would improve resource mutation, but it would not
solve component table storage, sparse storage, query mutation, deferred
component commands, observer payloads, or required component insertion.

It also risks two canonical sources of truth: one typed slot and one payload
slot. Any design with two canonical representations needs synchronization
rules, and those rules are exactly where the current bug came from.

### Generating concrete payload variants for every generic instantiation

Generating variants such as `EcsPayload_GpuArrayBuffer_SomeType` avoids nested
element payloads for that exact instantiation, but it still makes `EcsPayload`
the canonical storage layer. It also pushes the system toward large generated
enums and per-instantiation glue, while the runtime semantics still depend on
whether `from_ecs_payload` returns shared objects or reconstructed objects.

This approach treats the symptom, not the boundary mistake.

## Required Invariant

The ECS needs one invariant:

> A mutable ECS access API must mutate the canonical stored object for that
> component or resource.

This applies to:

- `ResourceMut<T>`;
- query `Mut<T>`;
- component table columns;
- sparse component stores;
- resource and component `update` helpers;
- observers and hooks that expose mutable access.

No public mutable API should depend on whether a generated codec happens to
share references with the underlying payload. That is an implementation detail,
and for generic aggregate codecs it is usually false.

## Recommended Architecture

The correct architecture is to split canonical typed storage from erased
boundary payloads.

### 1. Keep typed storage as the canonical source of truth

Each `ComponentKey<T>` and `ResourceKey<T>` should identify a typed storage
capability, not just an integer id and debug name. The world can still index
stores by erased ids internally, but the stored values should remain typed in
the store associated with that key.

The erased world registry should know how to perform structural operations
without knowing `T`:

- allocate a column/store;
- move or remove rows;
- clear a store;
- mark added/changed/removed ticks;
- run lifecycle hooks;
- optionally encode a value to `EcsPayload` for boundary operations.

Typed access should flow through the typed key:

- `ResourceKey<T>` accesses the typed resource slot for `T`;
- `ComponentKey<T>` accesses the typed column/sparse store for `T`;
- `ResourceMut<T>` and `Mut<T>` operate on those typed stores directly.

### 2. Use erased storage vtables for structural work

The world still needs heterogeneous collections. Instead of making every stored
value an `EcsPayload`, store an erased storage object with a small structural
vtable. The vtable should expose only operations that are genuinely type-erased:

- length;
- swap-remove or move-row;
- drop row;
- clone/move through payload when needed by deferred commands;
- debug name and storage kind;
- tick metadata access.

The typed arrays/maps remain hidden inside the store created for a specific
`ComponentKey<T>` or `ResourceKey<T>`. If MoonBit cannot express existential
typed stores directly, the erased store can be represented by closures that
capture typed arrays. The important part is that the canonical value is not
converted into `EcsPayload` for normal access.

### 3. Make `EcsPayload` a boundary format

`EcsPayload` should remain useful, but only at boundaries that truly need
erasure:

- deferred component insertion/removal commands;
- observer events that carry erased component lifecycle payloads;
- message/event queues when the queue is intentionally erased;
- debugging and inspection;
- optional save/snapshot/export paths;
- compatibility glue while migrating packages.

When a deferred command is applied, its payload should be decoded once and
inserted into the typed canonical store. After that, normal queries and resource
access should not decode it again every time.

### 4. Remove recursive runtime container payloads from canonical storage

Types like `GpuArrayBuffer[T]` should not have canonical payloads shaped as
`Array[EcsPayload]`. If such a value must cross an erased boundary, it can be
encoded temporarily. But the render world should store the actual
`GpuArrayBuffer[T]`, not a recursively erased copy.

This also applies to similar generic runtime containers:

- `StorageBuffer[T]`;
- `RenderAssets[A]`;
- `PrepareNextFrameAssets[A]`;
- `ErasedRenderAssets[A]`;
- future generic GPU/resource caches.

The goal is not merely "no nested `EcsPayload` in `GpuArrayBufferPayload`". The
goal is "no recursive payload tree as the live representation of render runtime
state".

### 5. Fix mutable API contracts

After storage is typed, `ResourceMut::modify` can mean real mutation again.
Until then, APIs with misleading semantics should be renamed or changed to
write back automatically.

Acceptable contracts are:

- `peek`: read the current typed value, with no mutation guarantee;
- `set`: replace the canonical stored value;
- `update`: read, transform, and write back;
- `modify`: mutate canonical storage directly, or do not expose this name.

The current hybrid behavior is not acceptable because some fields may alias the
payload while other fields are reconstructed.

## Migration Plan

### Phase 1: Document and guard the current hazard

- Add tests proving that `modify` on a decoded generic resource does not
  currently mutate canonical storage unless written back.
- Add tests for both resource and component mutation identity.
- Avoid introducing new recursive generic payload codecs for runtime state.

### Phase 2: Introduce typed storage capabilities behind existing keys

- Extend `ComponentKey<T>` and `ResourceKey<T>` with storage access
  capabilities or references to generated typed storage handlers.
- Keep integer ids for archetype signatures, debug names, change tracking, and
  Bevy-like scheduling.
- Preserve current public API names where the semantics can be made correct.

### Phase 3: Move resources to typed canonical storage

Resources are the simplest vertical slice because they are not table-row based.
This phase should not be considered the final architecture; it is only the
first slice of the same typed-storage model that components must also use.

Acceptance criteria:

- `ResourceMut::modify` mutates the stored value without needing explicit
  `update`;
- `ResourceMut::update` remains a convenience wrapper;
- existing added/changed tick behavior is preserved;
- no resource has two canonical representations.

### Phase 4: Move table and sparse components to typed canonical storage

Component table columns and sparse stores should stop storing
`@core.ComponentStore[EcsPayload]` as their canonical value store. The erased
world still tracks archetypes by local component id, but each component's data
store remains typed.

Acceptance criteria:

- query `Mut<T>` mutates the stored `T`;
- structural moves preserve typed values without encode/decode churn;
- hooks, observers, removed-component messages, and required components keep
  their Bevy-shaped behavior;
- table and sparse storage both satisfy the same identity contract.

### Phase 5: Demote payload codecs to boundary code

After typed storage is canonical, generated `EcsPayloadCodec` implementations
should be audited:

- direct concrete payload variants can remain for simple boundary values;
- recursive generic runtime payloads should be removed or made boundary-only;
- render GPU/runtime resources should not be serialized into payload trees
  during normal frame execution.

### Phase 6: Validate Bevy parity and performance

The validation surface should include:

- ECS resource mutation tests;
- ECS query mutation tests;
- render `GpuComponentArrayBuffer` tests;
- render/PBR examples that use GPU component arrays and render asset resources;
- release-mode performance checks to prove encode/decode churn is gone from
  hot render paths.

## Consequences

This is a larger refactor than changing `GpuArrayBufferPayload`, but it is the
right level of change. Bevy's ECS semantics are based on typed storage and
direct mutable access. mgstudio can keep MoonBit-friendly generated payload
glue, but that glue must not define the live identity of ECS data.

The expected long-term result is:

- no nested `Array[EcsPayload]` for live generic render resources;
- no mutation behavior that depends on codec aliasing;
- fewer render hot-path allocations and conversions;
- cleaner Bevy parity for resources, components, queries, and render prepare
  systems.
