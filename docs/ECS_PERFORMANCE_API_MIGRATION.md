# ECS Performance Branch Public API Migration

This document records the source-breaking public API changes retained by the
ECS and render performance work tracked by `ISS-442`, `ISS-444`, `ISS-456`,
`ISS-461`, and `ISS-463`.

These changes are intentional, but they are not source compatible. The
generated interfaces expose struct fields, struct mutability, return types,
error variants, and generic bounds as public API. Downstream code that used
those details must be migrated before updating to this branch.

The audit compares this branch against its `main` merge base,
`df70870662fe5fb4ad151098fe6edd329431838b`.

## Value-Type Semantics

`Duration`, `Stopwatch`, `TimerMode`, `Timer`, `TextureAtlas`, `Aabb`, `Sphere`,
`InheritedVisibility`, and `ViewVisibility` are now MoonBit value types. Copies
no longer share object identity. Value updates return replacement values that
the caller must store.

MoonBit value types cannot contain the reference-typed fields used by the old
representations. The flattened fields are an implementation detail; downstream
code should use constructors and methods instead of depending on the new scalar
layout.

## Time

`Stopwatch` previously exported `elapsed : Duration`; it now stores
`elapsed_nanos : Int64`. `Timer` previously exported `stopwatch`, `duration`,
and `mode`; those fields are now flattened scalar state.

| Previous source | Replacement |
| --- | --- |
| `stopwatch.elapsed` | `stopwatch.elapsed()` |
| `Stopwatch::{ elapsed, paused: false }` | `Stopwatch::new().set_elapsed(elapsed)` |
| `Stopwatch::{ elapsed, paused: true }` | `Stopwatch::new().set_elapsed(elapsed).pause()` |
| `timer.stopwatch.elapsed()` | `timer.elapsed()` |
| `timer.stopwatch.is_paused()` | `timer.is_paused()` |
| `timer.duration` | `timer.duration()` |
| `timer.mode` | `timer.mode()` |
| `Timer::{ stopwatch, duration, mode, .. }` | Start with `Timer::new(duration, mode)`, then apply `set_elapsed`, `pause`, `finish`, or `tick` as required |

There is no supported replacement for constructing arbitrary inconsistent
`Timer` internals through a struct literal. Use the public state-transition
methods. Existing `Timer` and `Stopwatch` mutators already return a replacement
value, so retain the result, for example `timer = timer.tick(delta)`.

## Camera Primitives

`Aabb` no longer exports `inner : Aabb3d`; it stores six scalar center and
half-extent values. `Sphere` no longer exports `center : Vec3`; it stores three
scalar center values.

| Previous source | Replacement |
| --- | --- |
| `Aabb::{ inner }` | `Aabb::from_math(inner)` |
| `aabb.inner` | `aabb.to_math()` |
| `aabb.inner.center` | `aabb.center()` |
| `aabb.inner.half_size` | `aabb.half_size()` |
| `Sphere::{ center, radius }` | `Sphere::new(center, radius)` |
| `sphere.center` | `sphere.center()` |
| Scalar sphere construction | `Sphere::from_xyz(x, y, z, radius)` |

The scalar getters such as `center_x()` and `half_extents_x()` exist for hot
paths, but callers should not construct the flattened representation directly.

## Visibility

`InheritedVisibility` is now a value type with otherwise unchanged constructor
and getter APIs.

`ViewVisibility.bits` is no longer mutable. The former mutating
`ViewVisibility::update` method is deliberately not retained with a
value-returning signature: an old `view.update()` call would still compile,
discard the returned value, and silently preserve the old state. The
replacement is named `advance_frame` so unmigrated calls fail at compile time.

| Previous source | Replacement |
| --- | --- |
| `view.update()` | `view = view.advance_frame()` |
| `view.set_visible()` | `view = view.with_visible()` |
| `view.bits = bits` | Use `ViewVisibility::new`, `visible`, `hidden`, `with_visible`, or `advance_frame` |
| Component mutation through direct field access | Use `Write::set`, `Write::update`, or the `SetViewVisibility` API |

Code using ECS change detection must choose ordinary mutation or the explicit
bypass-change-detection API according to the same semantics as before; do not
replace every visibility write with a bypass update.

The former public `check_visibility_system` blanket producer was removed. It
marked every inherited-visible renderable as view-visible without applying the
camera-, layer-, range-, light-, or frustum-specific visibility owners. Normal
applications should install the root visibility plugin together with the
camera visibility plugin and relevant light plugins. A custom visibility
producer should set `ViewVisibility` through `SetViewVisibility` and run in
`visibility_set_check_visibility`; there is no source-faithful one-function
replacement for the old blanket scan.

## Texture Atlas

`TextureAtlas.layout` is now a private scalar asset id because the value type
cannot contain a reference-typed `Handle`.

| Previous source | Replacement |
| --- | --- |
| `TextureAtlas::{ layout, index }` | `TextureAtlas::new(layout, index)` |
| `atlas.layout` | `atlas.layout()` |
| Direct layout asset lookup through `atlas.layout` | `atlas.layout_asset(layout_assets)` |

`TextureAtlas.index` remains public. Prefer `index()` and `with_index()` when
the caller does not need field-pattern matching.

## ECS Change-Location Storage

`RawTableColumnKernel.changed_caller_ids` changed from `Array[Int]` to
`Array[Int]?`. Change-location allocation is now opt-in through
`World::new(track_change_locations=true)`.

Direct consumers of `RawTableColumnKernel` must handle `None`. `None` means the
world does not track caller locations; it is not an empty tracked column.
`RawTableColumnKernel` is a low-level storage type, so normal downstream ECS
code should use `Read::changed_by` and the corresponding query APIs instead of
accessing the raw field.

`EcsError` also gained `TableBatchUnavailable(String)`. Exhaustive downstream
matches must add that case or an explicit fallback arm.

`World::new` now accepts the optional `track_change_locations` argument.
Existing `World::new()` calls remain valid. Code that stored `World::new` as a
zero-argument function value should replace it with `() => World::new()`;
callers that need change locations should use
`World::new(track_change_locations=true)`.

## Bindless Material Allocation

`MaterialBindGroupBindlessAllocator::allocate` changed from
`MaterialBindingId?` to `MaterialBindingId`. A bindless allocator now grows a
new slab and cannot fail because the current slab is full.

Remove `Some`/`None` matching or `.unwrap()` from direct bindless allocator
calls:

```mbt nocheck
let binding = allocator.allocate(material_id)
```

The higher-level material allocator enum may still return `None` when a
bindless allocation is requested from a non-bindless allocator.

## Frustum System Generic Bound

`render3d_update_frusta_system_by_projection_key` now requires
`T : @ecs.Component`. Generic wrappers calling this function must add the same
bound. Concrete projection components that already implement `Component` need
no source change.

## Table-Batch Mutable Column Scope

`TableBatchWrite::update_inplace` and
`update_inplace_bypass_change_detection` now pass
`TableBatchMutValues[T]` instead of a raw `MutArrayView[T]`. The old view could
escape its callback and continue replacing ECS column values without a valid
lease, change ticks, or finalizer handling. A retained `TableBatchMutValues`
becomes inactive when the callback returns, and every subsequent indexed read
or write aborts.

Callbacks with inferred parameter types keep the same source shape:

```mbt nocheck
values.update_inplace(fn(items) {
  for index in 0..<items.length() {
    items[index] = update(items[index])
  }
})
```

Explicit callback parameter annotations must change:

| Previous source | Replacement |
| --- | --- |
| `fn(items : MutArrayView[T]) { ... }` | `fn(items : TableBatchMutValues[T]) { ... }` |
| Retain `items` and write after the callback | Perform every indexed read and write inside the callback |

The controlled view deliberately exposes only `length()` and indexed
`op_get`/`op_set`; it does not expose its backing array or a raw mutable view.

## Source-Compatible Interface Changes

The generated-interface audit also found additive changes that do not require
downstream migration: the table-batch query APIs, `ReadValue`, camera frustum
schedule symbols, and defaulted table-binding methods on the open query traits.
