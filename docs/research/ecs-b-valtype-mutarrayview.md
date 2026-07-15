# MoonBit `#valtype` and `MutArrayView` enforcement capabilities

Date: 2026-07-15

## Executive conclusion

The current MoonBit toolchain can enforce that a concrete declaration is a valid `#valtype`, and `ArrayView[T]` / `MutArrayView[T]` return elements as `T` while `MutArrayView[T]` replaces an element with another `T`. It cannot express “`T` must be a `#valtype`” as a generic API bound, cannot infer deep immutability from `#valtype`, cannot keep a mutable view inside a query scope, and cannot let mgstudio intercept writes made through a raw `MutArrayView[T]`.

Therefore the proposed ECS-B contract is only partially implementable with the raw standard-library types:

- A scalar-only `#valtype` component can be read as a value and replaced in storage.
- A raw `MutArrayView[T]` is unsuitable as the public tracked-write query API if ECS-B requires per-component change ticks or runtime rejection of writes after the query scope ends.
- Preserving the desired `positions[i] = { ..positions[i], x: new_x }` syntax is possible with an mgstudio-owned view type that overloads `_[_]` and `_[_]=_`; the official language guide explicitly supports these overloads. It would not be a `MutArrayView[T]` at the API boundary.
- Hard rejection of non-value or shallowly mutable component types needs source generation/linting backed by a restricted schema, or a MoonBit language/toolchain capability. A user-implemented marker trait is only a convention.

## Baseline and evidence method

The behavior below was checked with:

```text
moon 0.1.20260714 (4620153 2026-07-14)
moonc v0.10.4+4f2e8f7dc-nightly (2026-07-13)
moonrun 0.1.20260714 (4620153 2026-07-14)
MOONBIT_NEW_NATIVE=1
```

The standard-library source bundled with this toolchain was compared with official `moonbitlang/core` commit [`4df746e8c4e47261bb843b3201d7c4656c45384c`](https://github.com/moonbitlang/core/commit/4df746e8c4e47261bb843b3201d7c4656c45384c). The installed `builtin/mutarrayview.mbt` and `builtin/arrayview.mbt` matched that commit byte-for-byte. Small native projects under `/tmp` were used to test accepted declarations, diagnostics, copying, aliasing, and escaped views.

## What `#valtype` actually guarantees

`#valtype` is a declaration attribute that asks the compiler for value representation. The compiler rejects unsupported layouts, including mutable fields, a direct type-parameter field, nested value-type fields, and extensible enums; these are documented under diagnostic [E4173](https://docs.moonbitlang.com/en/latest/language/error_codes/E4173.html) and were reproduced on the baseline toolchain.

The exact boundary is representation-based rather than “the declaration is non-generic”:

- `#valtype struct GenericBox[T] { value : T }` is rejected because the field layout depends directly on `T`.
- A generic `#valtype` whose stored layout is fixed can compile. The official immutable map is `#valtype struct HashMap[K, V] { data : Node[K, V]? }`, where the field is a reference-shaped optional regardless of `K` and `V` ([official source](https://github.com/moonbitlang/core/blob/4df746e8c4e47261bb843b3201d7c4656c45384c/immut/hashmap/types.mbt#L15-L28)).
- An extensible enum annotated with `#valtype` is rejected with “Value type is not allowed for extensible enum.”

Consequently, “value types do not support generics” is too strong. A direct generic payload is rejected, but generic value wrappers with a fixed physical representation exist in the official standard library.

### `#valtype` is not deep immutability

A `#valtype` struct cannot declare a `mut` field, but an immutable field may hold a mutable reference value. MoonBit explicitly distinguishes immutability of a binding or field from mutability of the value it contains; arrays, refs, and structs with mutable fields can still be mutated through an immutable binding ([E4087](https://docs.moonbitlang.com/en/latest/language/error_codes/E4087.html)). The official `BigInt` is a `#valtype` containing `FixedArray[UInt]` ([official source](https://github.com/moonbitlang/core/blob/4df746e8c4e47261bb843b3201d7c4656c45384c/bigint/bigint_nonjs.mbt#L27-L38)). Its encapsulation prevents public mutation, not `#valtype` alone.

The baseline compiler accepted:

```moonbit
#valtype
struct ArrayBox {
  value : Array[Int]
}
```

A test copied an `ArrayBox` out of an array, mutated `read_copy.value[0]`, and observed the mutation through the component still in storage. The outer value is copied, but the inner array reference aliases the same mutable object.

For ECS-B, the property required to guarantee read-only query semantics is therefore stronger than `#valtype`: every user-observable path reachable from a component must be immutable, or mutable references must be fully encapsulated behind an observationally immutable API. Current generic constraints cannot state that property.

## Valtype-only generic APIs

MoonBit constrained generics are trait constraints such as `[T : Eq]` ([official trait documentation](https://docs.moonbitlang.com/en/latest/language/methods.html#using-traits)). There is no exposed builtin `Valtype`/`ValueType` trait or kind constraint. Compiling `[T : Valtype]` on the baseline reports E4023, “The trait Valtype is not found.”

The apparent marker-trait alternatives do not provide the desired guarantee:

- An empty marker trait cannot discriminate because the current language automatically implements empty traits for all types ([official trait documentation](https://docs.moonbitlang.com/en/latest/language/methods.html#implementing-traits)).
- A non-empty `pub(open)` marker trait can be implemented by downstream component authors for a non-`#valtype` type, so it is an explicit promise rather than enforcement.
- A sealed `pub trait` can only be implemented by the package defining the trait ([official access-control documentation](https://docs.moonbitlang.com/en/latest/language/packages.html#access-control)). That prevents downstream authors from lying, but also prevents their packages from registering arbitrary user-defined component types through an implementation.
- MoonBit cannot automatically derive a user-defined marker trait; custom derives are rejected ([E4077](https://docs.moonbitlang.com/en/latest/language/error_codes/E4077.html)).

An opaque registration witness does not remove this limitation by itself. If downstream generated code can publicly construct the witness, handwritten code can do the same. If its constructor or trait is sealed, downstream generated code cannot construct or implement it unless generation writes into a package controlled by mgstudio.

### Enforcement classification

| Requirement | Current language/library | Code generation or convention | Toolchain change |
| --- | --- | --- | --- |
| Reject an invalid concrete `#valtype` declaration | Compiler-enforced | Not needed | Not needed |
| Require generic `T` to have `#valtype` representation | Not expressible | Generator/linter can inspect declarations; an open marker remains forgeable | Compiler-known `ValueType` kind/trait or reflection predicate |
| Require deep immutability | Not implied by `#valtype` | Restricted schema plus recursive field validation; otherwise convention | Compiler-known deep-immutable/sendable-style property |
| Allow downstream arbitrary component types with a sealed witness | Not directly possible across package boundary | Aggregate generated registrations inside an mgstudio-owned package, or accept a forgeable public hook | Compiler-supported custom derive or compiler-issued witness |

## Copy-returning reads

`ArrayView[T]::at` returns `T`, and its public API has no element setter ([official source](https://github.com/moonbitlang/core/blob/4df746e8c4e47261bb843b3201d7c4656c45384c/builtin/arrayview.mbt#L112-L173)). For a value component with no reachable mutable reference, this gives the intended local behavior:

1. `let old = positions[i]` obtains the old value.
2. `{ ..old, x: new_x }` creates a replacement value.
3. The stored component is unchanged until the write API receives that replacement.

This is not a complete query-level read guarantee:

- `ArrayView` is a borrowed view, not a snapshot. Official documentation notes that the underlying `Array` or `FixedArray` may still be modified ([ArrayView documentation](https://docs.moonbitlang.com/en/latest/language/fundamentals.html#arrayview)).
- A shallowly mutable `#valtype`, such as the accepted `ArrayBox`, can mutate storage-visible state through the copied field.
- MoonBit has no ownership/lifetime rule that makes a view non-escaping or uniquely borrowed. The baseline toolchain accepted a closure that captured `MutArrayView[Point]` and mutated the backing array after the function that created the closure had returned. It also accepted two overlapping mutable views of the same array.

Thus the ECS scheduler can prevent known systems from being scheduled concurrently, but the raw view type cannot prevent a system from retaining an alias and writing outside its declared access window.

## Replacement writes and interception

`MutArrayView[T]` is itself a builtin value-shaped view over an `UninitializedArray[T]` buffer, start, and length ([official source](https://github.com/moonbitlang/core/blob/4df746e8c4e47261bb843b3201d7c4656c45384c/builtin/mutarrayview.mbt#L16-L46)). Its getter returns `T` ([source](https://github.com/moonbitlang/core/blob/4df746e8c4e47261bb843b3201d7c4656c45384c/builtin/mutarrayview.mbt#L92-L150)); its `_[_]=_` operator is the builtin `set` intrinsic, which writes the supplied `T` directly into the backing buffer ([source](https://github.com/moonbitlang/core/blob/4df746e8c4e47261bb843b3201d7c4656c45384c/builtin/mutarrayview.mbt#L152-L186)). `unsafe_set` is another direct write path ([source](https://github.com/moonbitlang/core/blob/4df746e8c4e47261bb843b3201d7c4656c45384c/builtin/mutarrayview.mbt#L188-L216)).

This does implement physical replacement, but there is no callback, trait hook, or metadata parameter for mgstudio. Methods and operators for a foreign type cannot be overridden by the ECS package; MoonBit only permits the type-owning package to define its methods, and `_[_]=_` resolves to the annotated method ([operator-overloading documentation](https://docs.moonbitlang.com/en/latest/language/methods.html#operator-overloading), [access-control documentation](https://docs.moonbitlang.com/en/latest/language/packages.html#access-control)).

Therefore a raw `MutArrayView[T]` cannot provide exact ECS change detection:

- Marking the entire returned range changed when the view is granted is safe but creates false positives, including when no assignment occurs.
- Comparing a snapshot after the system returns adds an O(n) copy/compare path and still cannot account for a retained view that writes later.
- Returning the raw view alongside a tracker does not force callers to notify the tracker.
- Wrapping elements in a tracked value does not help because assigning through `MutArrayView` still replaces the element without invoking an mgstudio hook.

## Recommended boundary for the ECS-B design map

If ECS-B requires API-enforced read/write semantics and Bevy-like per-component change ticks, its tracked query API should be an mgstudio-owned abstraction:

```moonbit
let old = positions[i]
positions[i] = { ..old, x: new_x }
```

The syntax remains available because MoonBit lets user-defined types overload `_[_]` and `_[_]=_`. The wrapper setter can perform, in one operation:

1. bounds and entity-row validation;
2. replacement of the backing `T`;
3. update of that row's changed tick;
4. an active-lease/epoch check that rejects writes after the query scope is closed.

The backing storage may internally use an array and `MutArrayView[T]`, but the raw mutable view must not escape the ECS package. A separately named bulk/untracked API could expose raw `MutArrayView[T]` only if its contract intentionally marks the entire range changed and accepts non-escaping as a convention.

For component eligibility, choose explicitly between these contracts before implementation:

1. **Representation-only ECS-B:** require `#valtype` by generator/lint convention. Copying is shallow; read-only semantics exclude interior mutation only by user promise.
2. **Deeply immutable ECS-B:** restrict component schemas to compiler scalar types and an audited whitelist/recursive set of immutable types. This is stronger than current `#valtype` and needs generator/linter ownership of registration.
3. **Toolchain-gated ECS-B:** wait for or request a compiler-known generic value-layout constraint and, if deep read isolation is required, a separate deep-immutability property. Compile-time non-escaping mutable query borrows would require an ownership/lifetime capability; otherwise use the runtime lease wrapper above.

The original stated goal—read/write semantics guaranteed by the API—matches option 2 plus a custom tracked view today. Raw `MutArrayView[T]` plus `#valtype` alone does not meet it.

## Reproduction record

Commands were run one at a time, with the required native-backend environment variable:

```sh
MOONBIT_NEW_NATIVE=1 moon version --all
MOONBIT_NEW_NATIVE=1 moon check --target native
MOONBIT_NEW_NATIVE=1 moon test --target native
```

Observed compile-time results:

- direct generic field in `#valtype`: rejected with E4173;
- mutable field in `#valtype`: rejected with E4173;
- nested `#valtype` field: rejected with E4173;
- `#valtype` extensible enum: rejected with E4173;
- generic value wrapper containing `Node[T]?`: accepted;
- `#valtype` containing `Array[Int]`: accepted;
- `[T : Valtype]`: rejected because no such trait exists.

Observed native runtime results (`4` tests passed):

- scalar value read followed by record update did not change storage until assignment;
- copying a `#valtype` containing `Array[Int]` preserved an alias to the inner array;
- assigning through `MutArrayView` changed the backing array;
- overlapping `MutArrayView`s and a closure-captured escaping view were accepted and observed each other's writes.
