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
///
/// Rendering a scene with baked lightmaps.

///|
const LIGHTMAP_EXPOSURE : Float = 250.0F

///|
const LIGHTMAP_PATH_LARGE : String = "lightmaps/CornellBox-Large.zstd.ktx2"

///|
const LIGHTMAP_PATH_SMALL : String = "lightmaps/CornellBox-Small.zstd.ktx2"

///|
const LIGHTMAP_PATH_BOX : String = "lightmaps/CornellBox-Box.zstd.ktx2"

///|
pub(all) struct Args {
  deferred : Bool
  bicubic : Bool
}

///|
fn Args::Args() -> Args {
  { deferred: false, bicubic: false }
}

///|
let args_resource_key : @ecs.ResourceKey[Args] = @ecs.register_resource(
  debug_name="examples.3d.lightmaps.Args",
)

///|
impl @app.Resource for Args with fn resource() {
  args_resource_key
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  args : @app.Res[Args],
) -> Unit {
  let server = asset_server.get()
  ignore(
    commands.spawn_component(
      @scene.SceneRoot::new(
        @scene.scene_load_gltf_scene(
          server,
          @gltf.GltfAssetLabel::Scene(0).from_asset(
            "models/CornellBox/CornellBox.glb",
          ),
        ),
      ),
    ),
  )

  let camera = commands.spawn(
    (
      @camera.Camera3d::Camera3d(),
      @transform.Transform::from_xyz(-278.0F, 273.0F, 800.0F),
    ),
  )

  if args.get().deferred {
    commands
    .entity(camera)
    .insert(
      (
        @pbr.DepthPrepass::DepthPrepass(),
        @pbr.MotionVectorPrepass::MotionVectorPrepass(),
        @pbr.DeferredPrepass::DeferredPrepass(),
        @pbr.Msaa::Off,
      ),
    )
  }
}

///|
fn lightmap_handle_for_name(
  asset_server : @asset.AssetServer,
  name : String,
) -> @asset.Handle[@asset.Image]? {
  if name == "large_box" {
    return Some(asset_server.load(LIGHTMAP_PATH_LARGE))
  }
  if name == "small_box" {
    return Some(asset_server.load(LIGHTMAP_PATH_SMALL))
  }
  if name.has_prefix("cornell_box") {
    return Some(asset_server.load(LIGHTMAP_PATH_BOX))
  }
  None
}

///|
fn set_material_lightmap_exposure(
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  material_handle : @asset.Handle[@pbr.StandardMaterial],
) -> Unit {
  materials.modify(fn(material_assets) {
    guard material_assets.get(material_handle) is Some(material) else { return }
    ignore(
      material_assets.set(
        material_handle,
        material.with_lightmap_exposure(LIGHTMAP_EXPOSURE),
      ),
    )
  })
}

///|
// Bevy queries the typed material carrier here
// (`&MeshMaterial3d<StandardMaterial>` in `examples/3d/lightmaps.rs`); the
// glTF scene spawner attaches exactly that component (ISS-488).
type LightmappedMeshQuery = @ecs.Query[
  (
    @ecs.Read[@gltf.GltfMeshName],
    @ecs.Read[@pbr.MeshMaterial3dTyped[@pbr.StandardMaterial]],
  ),
  (@ecs.With[@mesh.Mesh3d], @ecs.Without[@pbr.Lightmap]),
]

///|
fn add_lightmaps_to_meshes(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  meshes : LightmappedMeshQuery,
  args : @app.Res[Args],
) -> Unit {
  let server = asset_server.get()
  try! meshes.view(fn(entity, mesh) {
    let (mesh_name, mesh_material) = mesh
    let name = mesh_name.value().as_str()
    guard lightmap_handle_for_name(server, name) is Some(lightmap_image) else {
      return
    }
    set_material_lightmap_exposure(materials, mesh_material.value().handle())
    commands
    .entity(entity)
    .insert_component(
      @pbr.Lightmap::new(lightmap_image).with_bicubic_sampling(
        args.get().bicubic,
      ),
    )
  })
}

///|
fn main {
  let args = Args::Args()
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
    .insert_resource(
      @pbr.GlobalAmbientLight::new(
        @color.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
        0.0F,
      ),
    )
  if args.deferred {
    app = app.insert_world_resource(
      @pbr.ecs_key_default_opaque_renderer_method,
      @pbr.DefaultOpaqueRendererMethod::deferred(),
    )
  }
  app
  .insert_resource(args)
  .add_systems_param3(Startup, setup)
  .add_systems_param5(Update, add_lightmaps_to_meshes)
  .run()
}
