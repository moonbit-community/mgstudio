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
// Bevy source: `bevy/examples/3d/rect_light.rs`.

///|
const CONTROLS_PREFIX : String = "Controls\nArrow Up/Down: Adjust floor roughness\nG: Toggle light gizmos\n\nRoughness: "

///|
struct FloorMaterial {
  handle : @asset.Handle[@pbr.StandardMaterial]
}

///|
let floor_material_resource_key : @ecs.ResourceKey[FloorMaterial] = @ecs.register_resource(
  debug_name="examples.3d.rect_light.FloorMaterial",
)

///|
pub impl @app.Resource for FloorMaterial with fn resource() {
  floor_material_resource_key
}

///|
struct RoughnessDisplay {}

///|
let roughness_display_component_key : @ecs.ComponentKey[RoughnessDisplay] = @ecs.register_component(
  debug_name="examples.3d.rect_light.RoughnessDisplay",
)

///|
pub impl @ecs.Component for RoughnessDisplay with fn component() {
  roughness_display_component_key
}

///|
fn roughness_text(value : Float) -> String {
  CONTROLS_PREFIX + format_float(value, 2)
}

///|
fn format_float(value : Float, precision : Int) -> String {
  let scale = match precision {
    1 => 10
    2 => 100
    _ => 1000
  }
  let scaled = (value * Float::from_int(scale)).round().to_int()
  let sign = if scaled < 0 { "-" } else { "" }
  let abs_scaled = if scaled < 0 { -scaled } else { scaled }
  let whole = abs_scaled / scale
  let fraction = abs_scaled % scale
  let fraction_text = if precision == 1 {
    fraction.to_string()
  } else if precision == 2 && fraction < 10 {
    "0\{fraction.to_string()}"
  } else if precision == 3 && fraction < 10 {
    "00\{fraction.to_string()}"
  } else if precision == 3 && fraction < 100 {
    "0\{fraction.to_string()}"
  } else {
    fraction.to_string()
  }
  "\{sign}\{whole.to_string()}.\{fraction_text}"
}

///|
fn spawn_mesh(
  commands : @app.Commands,
  mesh : @mesh.Mesh3d,
  material : @asset.Handle[@pbr.StandardMaterial],
  transform : @transform.Transform,
) -> Unit {
  ignore(
    commands.spawn(
      @pbr.MeshMaterial3dBundle::new(
        mesh,
        @pbr.MeshMaterial3dTyped::new(material),
        transform,
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let floor_material = materials.modify(fn(assets) {
    assets.add(
      @pbr.StandardMaterial::from_color(@color.Color::white())
      .with_metallic(1.0F)
      .with_perceptual_roughness(0.6F),
    )
  })
  commands.insert_resource(FloorMaterial::{ handle: floor_material })
  spawn_mesh(
    commands,
    @mesh.Mesh3d::new(
      meshes.modify(fn(assets) {
        assets
        |> @pbr.add_mesh(
          @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
            @math.Vec2::new(20.0F, 20.0F),
          ).build(),
        )
      }),
    ),
    floor_material,
    @transform.Transform::identity(),
  )
  spawn_mesh(
    commands,
    @mesh.Mesh3d::new(
      meshes.modify(fn(assets) {
        assets |> @pbr.add_mesh(@math.Sphere::new(1.0F))
      }),
    ),
    materials.modify(fn(assets) {
      assets.add(@pbr.StandardMaterial::from_color(@color.Color::white()))
    }),
    @transform.Transform::from_xyz(0.0F, 1.0F, 0.0F),
  )
  ignore(
    commands.spawn(
      (
        @light.RectLight::new(
          @color.Color::srgb(1.0F, 0.3F, 0.2F),
          100_000.0F,
          20.0F,
          2.0F,
          1.0F,
        ),
        @light.ShowLightGizmo::ShowLightGizmo(),
        @transform.Transform::from_xyz(1.0F, 3.0F, 1.0F).looking_at(
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @light.RectLight::new(
          @color.Color::srgb(0.5F, 0.7F, 1.0F),
          800_000.0F,
          20.0F,
          1.5F,
          4.0F,
        ),
        @light.ShowLightGizmo::ShowLightGizmo(),
        @transform.Transform::from_xyz(-2.0F, 1.5F, -3.0F).with_rotation(
          @math.Quat::from_rotation_y(@math.pi()),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @transform.Transform::from_xyz(-8.0F, 5.0F, 8.0F).looking_at(
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        @pbr.FreeCamera::FreeCamera(),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @text.Text::new(roughness_text(0.6F)),
        @text.TextFont::TextFont().with_font_size(18.0F),
        @text.TextColor::new(@color.Color::srgb(0.9F, 0.9F, 0.9F)),
        @ui.Node::Node()
        .with_position_type(Absolute)
        .with_top(@ui.px(12.0F))
        .with_left(@ui.px(12.0F)),
        RoughnessDisplay::{  },
      ),
    ),
  )
}

///|
fn clamp01(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn adjust_roughness(
  keys : @input.ButtonInput[@window.KeyCode],
  floor_material : @app.Res[FloorMaterial],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  text_query : @ecs.Query[@ecs.Write[@text.Text], @ecs.With[RoughnessDisplay]],
) -> Unit {
  let delta = if keys.pressed(ArrowUp) {
    0.005F
  } else if keys.pressed(ArrowDown) {
    -0.005F
  } else {
    return
  }
  let roughness = materials.modify(fn(assets) {
    match assets.get(floor_material.get().handle) {
      Some(material) => {
        let updated = material.with_perceptual_roughness(
          clamp01(material.perceptual_roughness + delta),
        )
        ignore(assets.set(floor_material.get().handle, updated))
        updated.perceptual_roughness
      }
      None => 0.6F
    }
  })
  try! text_query.view(fn(_entity, text) {
    text.set(@text.Text::new(roughness_text(roughness)))
  })
}

///|
fn toggle_gizmos(
  keys : @input.ButtonInput[@window.KeyCode],
  config_store : @app.ResMut[@gizmos.GizmoConfigStore],
) -> Unit {
  if !keys.just_pressed(KeyG) {
    return
  }
  config_store.modify(fn(store) {
    let (config, group) = store.config_mut(
      @light.LightGizmoConfigGroup::LightGizmoConfigGroup(),
    )
    group.val = { ..group.val, draw_all: false }
    config.val = { ..config.val, enabled: !config.val.enabled }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(@pbr.FreeCameraPlugin::FreeCameraPlugin())
  .add_systems_param3(Startup, setup)
  .add_systems_param4(Update, adjust_roughness)
  .add_systems_param2(Update, toggle_gizmos)
  .run()
}
