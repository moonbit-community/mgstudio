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
/// Marker component aligned with Bevy's `ForwardDecal`.
pub struct ForwardDecal {} derive(ToJson, FromJson)

///|
const FORWARD_DECAL_PLUGIN_NAME : String = "mgstudio.pbr.decal.ForwardDecalPlugin"

///|
pub type ForwardDecalMaterialExt = @material.ForwardDecalMaterialExt

///|
pub struct ForwardDecalPlugin {}

///|
pub fn ForwardDecalPlugin::ForwardDecalPlugin() -> ForwardDecalPlugin {
  ForwardDecalPlugin::{  }
}

///|
priv struct ForwardDecalMesh {
  mesh : @asset.Handle[@mesh.Mesh]
}

///|
fn ForwardDecalMesh::new(mesh : @asset.Handle[@mesh.Mesh]) -> ForwardDecalMesh {
  ForwardDecalMesh::{ mesh, }
}

///|
let forward_decal_mesh_resource_key : @ecs.ResourceKey[ForwardDecalMesh] = @ecs.register_resource(
  debug_name="mgstudio_pbr::ForwardDecalMesh",
)

///|
let forward_decal_required_components_registered : Ref[Bool] = Ref(false)

///|
impl @app.Resource for ForwardDecalMesh with fn resource() {
  forward_decal_mesh_resource_key
}

///|
fn default_forward_decal_mesh3d() -> @mesh.Mesh3d {
  @mesh.Mesh3d::new(@asset.Handle::new(-1))
}

///|
fn build_forward_decal_mesh() -> @mesh.Mesh3dGeometry {
  let mesh = @mesh_primitives.RectangleMeshBuilder::new(1.0F, 1.0F)
    .build()
    .rotated_by(
      @math.Quat::from_rotation_arc(
        @math.Vec3::new(0.0F, 0.0F, 1.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
  match mesh.generate_tangents() {
    Some(err) => {
      ignore(err)
      abort("failed to generate forward decal mesh tangents")
    }
    None => ()
  }
  mesh
}

///|
fn ensure_forward_decal_required_components_registered() -> Unit {
  if forward_decal_required_components_registered.val {
    return
  }
  ignore(
    @ecs.component_metadata_builder(ecs_key_forward_decal).require_with(
      @mesh.ecs_key_mesh3d, default_forward_decal_mesh3d,
    ),
  )
  forward_decal_required_components_registered.val = true
}

///|
fn forward_decal_set_mesh(
  world : @ecs.DeferredWorld,
  context : @ecs.HookContext,
) -> Unit {
  guard world.resource(ForwardDecalMesh::resource()).get()
    is Some(forward_decal_mesh) else {
    return
  }
  let entity = context.entity()
  if world.contains_by_key(entity, @mesh.ecs_key_mesh3d) {
    let existing_mesh3d = world.get_by_key(entity, @mesh.ecs_key_mesh3d) catch {
      _ => None
    }
    match existing_mesh3d {
      Some(mesh3d) =>
        if mesh3d.mesh().id() < 0 {
          world.set_by_key(
            entity,
            @mesh.ecs_key_mesh3d,
            @mesh.Mesh3d::new(forward_decal_mesh.mesh),
          ) catch {
            _ => ()
          }
        }
      None => ()
    }
  } else {
    world.set_by_key(
      entity,
      @mesh.ecs_key_mesh3d,
      @mesh.Mesh3d::new(forward_decal_mesh.mesh),
    ) catch {
      _ => ()
    }
  }
}

///|
pub impl @app.Plugin for ForwardDecalPlugin with fn name(_self) {
  FORWARD_DECAL_PLUGIN_NAME
}

///|
pub impl @app.Plugin for ForwardDecalPlugin with fn build(self, app) {
  register_embedded_wgsl_sources()
  let mesh_assets_key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  let app = if app.contains_resource(mesh_assets_key) {
    app
  } else {
    @asset.init_asset(app, fn() {
      @mesh.Mesh::from_3d_geometry(@mesh.Mesh3dGeometry::new([], [], None))
    })
  }
  let decal_mesh = match app.world().get_resource_mut(mesh_assets_key) {
    Some(mesh_assets) =>
      mesh_assets.modify(fn(assets) {
        assets |> @mesh.add(build_forward_decal_mesh())
      })
    None =>
      abort(
        "ForwardDecalPlugin requires Assets<Mesh>; add MeshPlugin before ForwardDecalPlugin",
      )
  }
  app
  .world()
  .insert_resource(
    ForwardDecalMesh::resource(),
    ForwardDecalMesh::new(decal_mesh),
  )
  ensure_forward_decal_required_components_registered()
  let hook_builder = app
    .world()
    .register_component_hooks_for_key(ecs_key_forward_decal)
  ignore(
    hook_builder.on_add(forward_decal_set_mesh) catch {
      err => {
        ignore(err)
        abort("failed to register forward decal add hook")
      }
    },
  )
  ignore(self)
  app
}

///|
pub struct ForwardDecalMaterialExtUniform {
  inv_depth_fade_factor : Float
}

///|
pub fn ForwardDecalMaterialExtUniform::ForwardDecalMaterialExtUniform() -> ForwardDecalMaterialExtUniform {
  ForwardDecalMaterialExtUniform::{ inv_depth_fade_factor: 1.0F / 8.0F }
}

///|
pub fn pbr_forward_decal_material_ext_uniform(
  depth_fade_factor : Float,
) -> ForwardDecalMaterialExtUniform {
  let safe = if depth_fade_factor < 0.001F { 0.001F } else { depth_fade_factor }
  ForwardDecalMaterialExtUniform::{ inv_depth_fade_factor: 1.0F / safe }
}

///|
pub struct ForwardDecalPipelineKey {
  alpha_blend : Bool
  depth_compare_always : Bool
}

///|
pub fn ForwardDecalPipelineKey::ForwardDecalPipelineKey() -> ForwardDecalPipelineKey {
  ForwardDecalPipelineKey::{ alpha_blend: true, depth_compare_always: true }
}

///|
pub fn pbr_forward_decal_shader_defs(
  _key : ForwardDecalPipelineKey,
) -> Array[String] {
  ["FORWARD_DECAL"]
}

///|
pub fn pbr_forward_decal_specialized_label(base : String) -> String {
  "forward_decal_\{base}"
}

///|
pub fn ForwardDecal::ForwardDecal() -> ForwardDecal {
  ForwardDecal::{  }
}

///|
pub let ecs_key_forward_decal : @ecs.ComponentKey[ForwardDecal] = @ecs.register_component(
  debug_name="render3d.forward_decal",
)

///|
pub impl @ecs.Component for ForwardDecal with fn component() {
  ecs_key_forward_decal
}

///|
test "pbr decal forward: plugin mesh carries generated tangents" {
  let mesh = build_forward_decal_mesh()
  let mut has_tangent_attribute = false
  for attribute in mesh.attributes() {
    if attribute.attribute().id() == @mesh.MeshVertexAttribute::tangent().id() {
      has_tangent_attribute = true
    }
  }
  debug_inspect(mesh.has_tangents(), content="true")
  debug_inspect(has_tangent_attribute, content="true")
}

///|
test "pbr decal forward: component hook assigns plugin decal mesh" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    ForwardDecalPlugin::ForwardDecalPlugin(),
  )
  let world = app.world()
  let decal_mesh = world.get_resource(ForwardDecalMesh::resource()).unwrap()
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    ecs_key_forward_decal,
    ForwardDecal::ForwardDecal(),
  )
  guard world.get_by_key(entity, @mesh.ecs_key_mesh3d) is Some(mesh3d) else {
    abort("ForwardDecal on_add hook must insert Mesh3d")
  }
  debug_inspect(mesh3d.mesh().id(), content=decal_mesh.mesh.id().to_string())
}
