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
// Bevy source: `bevy/examples/picking/mesh_picking.rs`.

///|
struct Shape {}

///|
let ecs_key_shape : @ecs.ComponentKey[Shape] = @ecs.register_component(
  debug_name="examples.picking.mesh_picking.Shape",
)

///|
impl @ecs.Component for Shape with fn component() {
  ecs_key_shape
}

///|
const SHAPES_X_EXTENT : Float = 14.0F

///|
const EXTRUSION_X_EXTENT : Float = 16.0F

///|
const Z_EXTENT : Float = 5.0F

///|
fn gray_300() -> @color.Color {
  @color.Color::srgb(0.81960785F, 0.8352941F, 0.85882354F)
}

///|
fn cyan_300() -> @color.Color {
  @color.Color::srgb(0.40392157F, 0.9098039F, 0.9764706F)
}

///|
fn yellow_300() -> @color.Color {
  @color.Color::srgb(0.99215686F, 0.8784314F, 0.2784314F)
}

///|
fn red_500() -> @color.Color {
  @color.Color::srgb(0.9372549F, 0.26666668F, 0.26666668F)
}

///|
fn pink_100() -> @color.Color {
  @color.Color::srgb(0.9882353F, 0.90588236F, 0.9529412F)
}

///|
fn mesh3d_from_geometry(
  meshes : @asset.Assets[@mesh.Mesh],
  geometry : @mesh.Mesh3dGeometry,
) -> @mesh.Mesh3d {
  @mesh.Mesh3d::new(meshes.add(@mesh.Mesh::from_3d_geometry(geometry)))
}

///|
type MaterialQuery = @ecs.Query[
  @ecs.Write[@pbr.MeshMaterial3dTyped[@pbr.StandardMaterial]],
  @ecs.All,
]

///|
fn[K] update_material_on(
  new_material : @asset.Handle[@pbr.StandardMaterial],
) -> (@app.OnPointer[K], MaterialQuery) -> Unit {
  fn(event, materials) {
    guard event.target() is Some(entity) else { return }
    guard (materials.get(entity) catch { _ => None }) is Some(material) else {
      return
    }
    material.set(@pbr.MeshMaterial3dTyped::new(new_material))
  }
}

///|
fn rotate_on_drag(
  drag : @app.OnPointer[@app.PointerDrag],
  transforms : @ecs.Query[@ecs.Write[@transform.Transform], @ecs.All],
) -> Unit {
  guard drag.target() is Some(entity) else { return }
  guard (transforms.get(entity) catch { _ => None }) is Some(transform) else {
    return
  }
  transform.modify(fn(value) {
    value.rotate_y(drag.delta().x * 0.02F)
    value.rotate(@math.Quat::from_rotation_x(drag.delta().y * 0.02F))
  })
}

///|
fn spawn_shape(
  commands : @app.Commands,
  mesh : @mesh.Mesh3d,
  material : @asset.Handle[@pbr.StandardMaterial],
  hover_material : @asset.Handle[@pbr.StandardMaterial],
  pressed_material : @asset.Handle[@pbr.StandardMaterial],
  position : @math.Vec3,
) -> Unit {
  let entity = commands.spawn(
    (
      mesh,
      @pbr.MeshMaterial3dTyped::new(material),
      @transform.Transform::from_xyz(position.x, position.y, position.z).with_rotation(
        @math.Quat::from_rotation_x(-@math.pi() / 4.0F),
      ),
      Shape::{  },
    ),
  )
  let over_observer : (@app.OnPointer[@app.PointerOver], MaterialQuery) -> Unit = update_material_on(
    hover_material,
  )
  let out_observer : (@app.OnPointer[@app.PointerOut], MaterialQuery) -> Unit = update_material_on(
    material,
  )
  let press_observer : (@app.OnPointer[@app.PointerDown], MaterialQuery) -> Unit = update_material_on(
    pressed_material,
  )
  let release_observer : (@app.OnPointer[@app.PointerUp], MaterialQuery) -> Unit = update_material_on(
    hover_material,
  )
  ignore(
    commands
    .entity(entity)
    .observe_pointer2(over_observer)
    .observe_pointer2(out_observer)
    .observe_pointer2(press_observer)
    .observe_pointer2(release_observer)
    .observe_pointer2(rotate_on_drag),
  )
}

///|
fn setup_scene(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let white_material = materials.modify(fn(material_assets) {
    material_assets |> @pbr.add_material(@color.Color::white())
  })
  let ground_material = materials.modify(fn(material_assets) {
    material_assets |> @pbr.add_material(gray_300())
  })
  let hover_material = materials.modify(fn(material_assets) {
    material_assets |> @pbr.add_material(cyan_300())
  })
  let pressed_material = materials.modify(fn(material_assets) {
    material_assets |> @pbr.add_material(yellow_300())
  })

  let shapes = meshes.modify(fn(mesh_assets) {
    [
      mesh3d_from_geometry(
        mesh_assets,
        @mesh_primitives_dim3.CuboidMeshBuilder::CuboidMeshBuilder().build(),
      ),
      mesh3d_from_geometry(
        mesh_assets,
        @mesh_primitives_dim3.TetrahedronMeshBuilder::TetrahedronMeshBuilder().build(),
      ),
      mesh3d_from_geometry(
        mesh_assets,
        @mesh_primitives_dim3.Capsule3dMeshBuilder::Capsule3dMeshBuilder().build(),
      ),
      mesh3d_from_geometry(
        mesh_assets,
        @mesh_primitives_dim3.TorusMeshBuilder::TorusMeshBuilder().build(),
      ),
      mesh3d_from_geometry(
        mesh_assets,
        @mesh_primitives_dim3.CylinderMeshBuilder::CylinderMeshBuilder().build(),
      ),
      mesh3d_from_geometry(
        mesh_assets,
        @mesh_primitives_dim3.ConeMeshBuilder::ConeMeshBuilder().build(),
      ),
      mesh3d_from_geometry(
        mesh_assets,
        @mesh_primitives_dim3.ConicalFrustumMeshBuilder::ConicalFrustumMeshBuilder().build(),
      ),
      mesh3d_from_geometry(
        mesh_assets,
        @mesh_primitives_dim3.SphereMeshBuilder::new(
          0.5F,
          @mesh_primitives_dim3.SphereKind::ico(5),
        ).build(),
      ),
      mesh3d_from_geometry(
        mesh_assets,
        @mesh_primitives_dim3.SphereMeshBuilder::new(
          0.5F,
          @mesh_primitives_dim3.SphereKind::uv(32, 18),
        ).build(),
      ),
    ]
  })
  for i in 0..<shapes.length() {
    spawn_shape(
      commands,
      shapes[i],
      white_material,
      hover_material,
      pressed_material,
      @math.Vec3::new(
        -SHAPES_X_EXTENT / 2.0F +
        Float::from_int(i) /
        Float::from_int(shapes.length() - 1) *
        SHAPES_X_EXTENT,
        2.0F,
        Z_EXTENT / 2.0F,
      ),
    )
  }

  let extrusions = meshes.modify(fn(mesh_assets) {
    [
      mesh3d_from_geometry(
        mesh_assets,
        @mesh_primitives.extrusion_mesh(
          @math.Extrusion::new(@math.Rectangle::Rectangle(), 1.0F),
        ),
      ),
      mesh3d_from_geometry(
        mesh_assets,
        @mesh_primitives.extrusion_mesh(
          @math.Extrusion::new(@math.Capsule2d::Capsule2d(), 1.0F),
        ),
      ),
      mesh3d_from_geometry(
        mesh_assets,
        @mesh_primitives.extrusion_mesh(
          @math.Extrusion::new(@math.Annulus::Annulus(), 1.0F),
        ),
      ),
      mesh3d_from_geometry(
        mesh_assets,
        @mesh_primitives.extrusion_mesh(
          @math.Extrusion::new(@math.Circle::Circle(), 1.0F),
        ),
      ),
      mesh3d_from_geometry(
        mesh_assets,
        @mesh_primitives.extrusion_mesh(
          @math.Extrusion::new(@math.Ellipse::Ellipse(), 1.0F),
        ),
      ),
      mesh3d_from_geometry(
        mesh_assets,
        @mesh_primitives.extrusion_mesh(
          @math.Extrusion::new(@math.RegularPolygon::RegularPolygon(), 1.0F),
        ),
      ),
      mesh3d_from_geometry(
        mesh_assets,
        @mesh_primitives.extrusion_mesh(
          @math.Extrusion::new(@math.Triangle2d::Triangle2d(), 1.0F),
        ),
      ),
    ]
  })
  for i in 0..<extrusions.length() {
    spawn_shape(
      commands,
      extrusions[i],
      white_material,
      hover_material,
      pressed_material,
      @math.Vec3::new(
        -EXTRUSION_X_EXTENT / 2.0F +
        Float::from_int(i) /
        Float::from_int(extrusions.length() - 1) *
        EXTRUSION_X_EXTENT,
        2.0F,
        -Z_EXTENT / 2.0F,
      ),
    )
  }

  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(
          meshes.modify(fn(mesh_assets) {
            mesh_assets.add(
              @mesh.Mesh::from_3d_geometry(
                @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
                  @math.Vec2::new(50.0F, 50.0F),
                )
                .subdivisions(10)
                .build(),
              ),
            )
          }),
        ),
        @pbr.MeshMaterial3dTyped::new(ground_material),
        @picking.pickable_ignore,
        @transform.Transform::identity(),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.PointLight::PointLight()
        .with_shadow_maps_enabled(true)
        .with_intensity(10_000_000.0F)
        .with_range(100.0F)
        .with_shadow_depth_bias(0.2F),
        @transform.Transform::from_xyz(8.0F, 16.0F, 8.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @transform.Transform::from_xyz(0.0F, 7.0F, 14.0F).looking_at(
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  let ui_camera = commands.spawn(
    (
      @camera_components2d.Camera2d::Camera2d(),
      @camera_camera.Camera::Camera().with_order(100).with_clear_color_none(),
      @transform.Transform::identity(),
    ),
  )
  commands
  .entity(ui_camera)
  .insert_component(@ui.IsDefaultUiCamera::IsDefaultUiCamera())
  let ui_root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      @ui.Node::Node().with_width(Percent(100.0F)).with_height(Percent(100.0F)),
      @ui.UiTargetCamera::new(ui_camera),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(ui_root),
        @text.Text::new("Hover over the shapes to pick them\nDrag to rotate"),
        @ui.Node::Node()
        .with_position_type(Absolute)
        .with_top(Px(12.0F))
        .with_left(Px(12.0F)),
        @text.TextFont::TextFont(),
        @text.TextColor::TextColor(),
        @text.TextLayout::TextLayout(),
        @text.LineHeight::default(),
        @text.FontHinting::default(),
      ),
    ),
  )
}

///|
fn draw_mesh_intersections(
  pointers : @ecs.Query[@ecs.Read[@picking.PointerInteraction], @ecs.All],
  gizmos : @gizmos.Gizmos[@gizmos.DefaultGizmoConfigGroup],
) -> Unit {
  try! pointers.view(fn(_entity, interaction) {
    guard interaction.value().get_nearest_hit() is Some((_hit_entity, hit)) else {
      return
    }
    guard hit.position is Some(point) && hit.normal is Some(normal) else {
      return
    }
    gizmos.sphere_3d(
      @math.Isometry3d::new(point, @math.Quat::identity()),
      0.05F,
      red_500(),
    )
    gizmos.arrow_3d(
      point,
      point.add(normal.normalize().mul_scalar(0.5F)),
      pink_100(),
    )
  })
}

///|
fn rotate(
  shapes : @ecs.Query[@ecs.Write[@transform.Transform], @ecs.With[Shape]],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let delta = time.get().delta_secs() / 2.0F
  try! shapes.view(fn(_entity, transform) {
    transform.modify(fn(value) { value.rotate_y(delta) })
  })
}

///|
fn mesh_picking_app() -> @app.App[@ecs.World] {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(@mesh_picking_plugin.MeshPickingPlugin::MeshPickingPlugin())
  .add_systems_param3(Startup, setup_scene)
  .add_systems_param2(Update, draw_mesh_intersections)
  .add_systems_param2(Update, rotate)
}

///|
fn main {
  mesh_picking_app().run()
}
