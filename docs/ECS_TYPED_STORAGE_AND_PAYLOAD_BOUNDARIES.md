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
- call sites must pass the typed key they already have; an integer definition id
  is only enough for typeless structural operations such as presence checks,
  removal, ticks, and metadata.
- deferred component insertion stores a typed writer closure that captures the
  pending value and applies it through the typed key later.

There is intentionally no API for reconstructing a typed key from an integer id.
That would require downcast-like behavior and would recreate the same boundary
problem under another name.

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
