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
const GLTF_EXTRAS_SCENE_ASSET : String = "models/extras/gltf_extras.glb"

///|
struct ExampleDisplay {}

///|
let example_display_component_key : @ecs.ComponentKey[ExampleDisplay] = @ecs.register_component(
  debug_name="examples.gltf.load_gltf_extras.ExampleDisplay",
)

///|
pub impl @ecs.Component for ExampleDisplay with component() {
  example_display_component_key
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let server = asset_server.get()

  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @transform.Transform::from_xyz(2.0F, 2.0F, 2.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::default(),
        @transform.Transform::from_xyz(3.0F, 5.0F, 3.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn_component(
      @scene.SceneRoot::new(
        server.load(
          @gltf.GltfAssetLabel::Scene(0).from_asset(GLTF_EXTRAS_SCENE_ASSET),
        ),
      ),
    ),
  )

  let ui_root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
    ),
  )

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(ui_root),
        @text.Text::new("Waiting for glTF extras..."),
        @text.TextFont::from_font_size(15.0F),
        @ui.Node::{
          ..@ui.Node::default(),
          position_type: @ui.PositionType::Absolute,
          top: @ui.Val::Px(12.0F),
          left: @ui.Val::Px(12.0F),
        },
        ExampleDisplay::{  },
      ),
    ),
  )
}

///|
fn format_optional_name(name : @ecs.Name?) -> String {
  match name {
    Some(value) => value.as_str()
    None => "<unnamed>"
  }
}

///|
fn format_optional_string(value : String?) -> String {
  match value {
    Some(text) => text
    None => "<none>"
  }
}

///|
fn update_display(
  entities : @ecs.Query[@ecs.EntityRef, @ecs.All],
  display : @app.Single[@ecs.Mut[@text.Text], @ecs.With[ExampleDisplay]],
) -> Unit {
  let lines : Array[String] = []

  try! entities.view(fn(_entity, entity_ref) {
    let name : @ecs.Name? = try! entity_ref.get()
    let scene_extras : @gltf.GltfSceneExtras? = try! entity_ref.get()
    let primitive_extras : @gltf.GltfExtras? = try! entity_ref.get()
    let mesh_extras : @gltf.GltfMeshExtras? = try! entity_ref.get()
    let material_extras : @gltf.GltfMaterialExtras? = try! entity_ref.get()

    guard scene_extras is Some(_) ||
      primitive_extras is Some(_) ||
      mesh_extras is Some(_) ||
      material_extras is Some(_) else {
      return
    }

    let entity_id = entity_ref.id()
    lines.push(
      "Entity " +
      entity_id.id.to_string() +
      ":" +
      entity_id.generation.to_string() +
      " ('" +
      format_optional_name(name) +
      "'):\n" +
      "  - scene extras:     " +
      format_optional_string(scene_extras.map(fn(value) { value.as_str() })) +
      "\n" +
      "  - primitive extras: " +
      format_optional_string(primitive_extras.map(fn(value) { value.as_str() })) +
      "\n" +
      "  - mesh extras:      " +
      format_optional_string(mesh_extras.map(fn(value) { value.as_str() })) +
      "\n" +
      "  - material extras:  " +
      format_optional_string(material_extras.map(fn(value) { value.as_str() })),
    )
  })

  let content = if lines.length() == 0 {
    "Waiting for glTF extras..."
  } else {
    lines.join("\n\n")
  }
  display.get().set(@text.Text::new(content))
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(update_display)))
  .run()
}
