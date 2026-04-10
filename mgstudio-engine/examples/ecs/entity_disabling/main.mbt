// Copyright 2025 International Digital Economy Academy
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

///|
struct DisableOnClick {} derive(Eq, Debug, ToJson, FromJson)

///|
struct EntityNameText {} derive(Eq, Debug, ToJson, FromJson)

///|
let disable_on_click_key : @ecs.ComponentKey[DisableOnClick] = @ecs.register_component(
  debug_name="examples.ecs.entity_disabling.DisableOnClick",
)

///|
let entity_name_text_key : @ecs.ComponentKey[EntityNameText] = @ecs.register_component(
  debug_name="examples.ecs.entity_disabling.EntityNameText",
)

///|
pub impl @ecs.Component for DisableOnClick with component() {
  disable_on_click_key
}

///|
pub impl @ecs.Component for EntityNameText with component() {
  entity_name_text_key
}

///|
const X_EXTENT : Float = 900.0F

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(Startup, @app.system(@app.system_param3(setup_scene)))
  .add_systems(Startup, @app.system(@app.system_param(display_instructions)))
  .add_systems(
    Update,
    @app.system(@app.system_param3(disable_entities_on_click)),
  )
  .add_systems(Update, @app.system(@app.system_param2(list_all_named_entities)))
  .add_systems(
    Update,
    @app.system(@app.system_param2(reenable_entities_on_space)),
  )
  .run()
}

///|
fn setup_scene(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  let mesh_assets = meshes.get_ref().val
  let material_assets = materials.get_ref().val
  let named_shapes : Array[(@ecs.Name, @asset.Handle[@mesh.Mesh])] = [
    (
      @ecs.Name::new("Annulus"),
      mesh_assets |> @sprite.add_mesh(@sprite.Annulus::new(25.0F, 50.0F)),
    ),
    (
      @ecs.Name::new("Bestagon"),
      mesh_assets |> @sprite.add_mesh(@sprite.RegularPolygon::new(50.0F, 6)),
    ),
    (
      @ecs.Name::new("Rhombus"),
      mesh_assets |> @sprite.add_mesh(@sprite.Rhombus::new(75.0F, 100.0F)),
    ),
  ]
  let num_shapes = named_shapes.length()

  for i in 0..<num_shapes {
    let name = named_shapes[i].0
    let mesh = named_shapes[i].1
    let hue = 360.0F *
      Float::from_double(i.to_double()) /
      Float::from_double(num_shapes.to_double())
    let color = @sprite.Color::hsl(hue, 0.95F, 0.7F)
    ignore(
      commands.spawn(
        (
          name,
          DisableOnClick::{  },
          @sprite.Mesh2d::new(mesh),
          @sprite.MeshMaterial2d::new(
            material_assets |> @sprite.add_material(color),
          ),
          @transform.Transform::from_xyz(
            -X_EXTENT / 2.0F +
            Float::from_double(i.to_double()) /
            Float::from_double((num_shapes - 1).to_double()) *
            X_EXTENT,
            0.0F,
            0.0F,
          ),
        ),
      ),
    )
  }

  ignore(
    commands.spawn(
      (
        EntityNameText::{  },
        @text.Text::new("Named entities found:\n"),
        @ui.Node::{
          ..@ui.Node::default(),
          position_type: @ui.PositionType::Absolute,
          top: @ui.Val::Px(12.0F),
          right: @ui.Val::Px(12.0F),
        },
      ),
    ),
  )
}

///|
fn display_instructions(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @text.Text::new(
          "Click an entity to disable it.\n\nPress Space to re-enable all disabled entities.",
        ),
        @ui.Node::{
          ..@ui.Node::default(),
          position_type: @ui.PositionType::Absolute,
          top: @ui.Val::Px(12.0F),
          left: @ui.Val::Px(12.0F),
        },
      ),
    ),
  )
}

///|
fn disable_entities_on_click(
  commands : @app.Commands,
  click_events : @app.ResMut[@app.PickingEvents],
  valid_query : @ecs.Query[@ecs.Comp[DisableOnClick], @ecs.All],
) -> Unit {
  for event in @app.PickingEvents::drain(click_events.get_ref()) {
    if event.kind != @pointer_events.PointerEventKind::Click {
      continue
    }
    if event.target is Some(target) &&
      (valid_query.get(target) catch { _ => None }) is Some(_) {
      commands.entity(target).insert_component(@ecs.Disabled::new())
    }
  }
}

///|
fn list_all_named_entities(
  query : @ecs.Query[@ecs.Comp[@ecs.Name], @ecs.All],
  name_text_query : @ecs.Query[
    (@ecs.Comp[EntityNameText], @ecs.Mut[@text.Text]),
    @ecs.All,
  ],
) -> Unit {
  let names : Array[String] = []
  try! query.view(fn(_entity, name) { names.push(name.value().as_str()) })
  sort_names(names)

  let text_string = Ref::new("Named entities found:\n")
  for name in names {
    text_string.val = "\{text_string.val}\{name}\n"
  }

  try! name_text_query.view(fn(_entity, data) {
    let (_marker, text) = data
    text.get_ref().val = @text.Text::new(text_string.val)
  })
}

///|
fn sort_names(names : Array[String]) -> Unit {
  for i in 1..<names.length() {
    let current = names[i]
    let mut j = i - 1
    while j >= 0 && current < names[j] {
      names[j + 1] = names[j]
      j = j - 1
    }
    names[j + 1] = current
  }
}

///|
fn reenable_entities_on_space(
  commands : @app.Commands,
  disabled_entities : @ecs.Query[@core.Entity, @ecs.With[@ecs.Disabled]],
) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Space) {
    return
  }
  let entities : Array[@core.Entity] = []
  try! disabled_entities.view(fn(entity, _value) { entities.push(entity) })
  for entity in entities {
    commands.entity(entity).remove_component(@ecs.ecs_key_disabled)
  }
}
