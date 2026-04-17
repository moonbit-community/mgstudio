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
const FLIGHT_HELMET_SCENE_ASSET : String = "models/FlightHelmet/FlightHelmet.gltf"

///|
const PISA_DIFFUSE_MAP_ASSET : String = "environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"

///|
const PISA_SPECULAR_MAP_ASSET : String = "environment_maps/pisa_specular_rgb9e5_zstd.ktx2"

///|
struct ColorOverride {
  color : @sprite.Color
}

///|
let color_override_component_key : @ecs.ComponentKey[ColorOverride] = @ecs.register_component(
  debug_name="examples.gltf.edit_material_on_gltf.ColorOverride",
)

///|
pub impl @ecs.Component for ColorOverride with component() {
  color_override_component_key
}

///|
fn ColorOverride::new(color : @sprite.Color) -> ColorOverride {
  { color, }
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let server = asset_server.get()
  commands.queue(fn(world : @ecs.World) {
    world.insert_resource(
      @pbr.ecs_key_directional_light_shadow_map,
      @pbr.DirectionalLightShadowMap::new(4096),
    )
  })

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(0.0F, 1.0F, 2.5F).looking_at(
          @math.Vec3::new(0.0F, 0.25F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        @pbr.EnvironmentMapLight::new(
          Some(server.load(PISA_DIFFUSE_MAP_ASSET)),
          Some(server.load(PISA_SPECULAR_MAP_ASSET)),
          250.0F,
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::default(),
        @transform.Transform::from_xyz(0.0F, 1.0F, 0.25F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  let flight_helmet = server.load(
    @gltf.GltfAssetLabel::Scene(0).from_asset(FLIGHT_HELMET_SCENE_ASSET),
  )
  ignore(commands.spawn_component(@scene.SceneRoot::new(flight_helmet)))
  ignore(
    commands.spawn(
      (
        @scene.SceneRoot::new(flight_helmet),
        @transform.Transform::from_xyz(-1.25F, 0.0F, 0.0F),
        ColorOverride::new(@sprite.Color::srgb(0.98F, 0.65F, 0.65F)),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @scene.SceneRoot::new(flight_helmet),
        @transform.Transform::from_xyz(1.25F, 0.0F, 0.0F),
        ColorOverride::new(@sprite.Color::srgb(0.55F, 0.9F, 0.55F)),
      ),
    ),
  )
}

///|
fn visit_descendants(
  children_query : @ecs.Query[@ecs.Comp[@hierarchy.Children], @ecs.All],
  entity : @core.Entity,
  f : (@core.Entity) -> Unit,
) -> Unit raise {
  guard children_query.get(entity) is Some(children_comp) else { return }
  for child in children_comp.value().entities() {
    f(child)
    visit_descendants(children_query, child, f)
  }
}

///|
fn change_material(
  event : @ecs.ComponentOn[@ecs.Insert, @scene.SceneInstanceReady],
  colors : @ecs.Query[@ecs.Comp[ColorOverride], @ecs.All],
  children_query : @ecs.Query[@ecs.Comp[@hierarchy.Children], @ecs.All],
  mesh_materials : @ecs.Query[
    (@ecs.Mut[@pbr.MeshMaterial3d], @ecs.Comp[@gltf.GltfMaterialName]),
    @ecs.All,
  ],
) -> Unit {
  let scene_entity = event.entity
  guard (colors.get(scene_entity) catch { _ => None }) is Some(color_override) else {
    return
  }
  try! visit_descendants(children_query, scene_entity, fn(descendant) {
    guard (mesh_materials.get(descendant) catch { _ => None })
      is Some(material_data) else {
      return
    }
    let (mesh_material_comp, material_name_comp) = material_data
    if material_name_comp.value().as_str() != "LeatherPartsMat" {
      return
    }
    let mesh_material = mesh_material_comp.value()
    guard @pbr.standard_material_get(mesh_material.material) is Some(material) else {
      return
    }
    let updated_handle = @pbr.standard_material_add(
      material.with_base_color(color_override.value().color),
    )
    mesh_material_comp.set(@pbr.MeshMaterial3d::new(updated_handle))
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_component_observer4(change_material)
  .run()
}
