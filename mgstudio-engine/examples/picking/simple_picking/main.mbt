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
let cube_spawn_counter : Ref[Int] = Ref(0)

///|
struct PickableCube {
  normal : @asset.Handle[@pbr.StandardMaterial]
  selected : @asset.Handle[@pbr.StandardMaterial]
  mut active : Bool
}

///|
let ecs_key_pickable_cube : @ecs.ComponentKey[PickableCube] = @ecs.register_component(
  debug_name="examples.picking.simple.pickable_cube",
)

///|
impl @ecs.Component for PickableCube with component() {
  ecs_key_pickable_cube
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh_assets = meshes.peek()
  let material_assets = materials.peek()
  let plane_material = material_assets
    |> @pbr.add_material(@sprite.Color::srgb(0.95F, 0.95F, 0.95F))
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(
          mesh_assets |> @pbr.add_mesh(@mesh.Mesh3dGeometry::circle(4.0F, 32)),
        ),
        @pbr.MeshMaterial3d::new(plane_material),
        @transform.Transform::identity().with_rotation(
          @math.Quat::from_rotation_x(-@math.pi_half()),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.PointLight::default().with_shadow_maps_enabled(true),
        @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(-2.5F, 4.5F, 9.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  let label = commands.spawn(
    (
      @ui.Button::default(),
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_top(@ui.Val::Percent(12.0F))
      .with_left(@ui.Val::Percent(12.0F)),
      @text.Text::new("Click me to spawn cubes\nClick cube to toggle color"),
      @text.TextColor::new(@sprite.Color::white()),
      @text.TextFont::from_font_size(@text.FontSize::Px(24.0F)),
    ),
  )
  ignore(
    commands
    .entity(label)
    .observe_pointer4(fn(
      _pointer : @app.OnPointer[@app.PointerClick],
      commands : @app.Commands,
      meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
      materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
    ) {
      let index = cube_spawn_counter.val
      cube_spawn_counter.val = index + 1
      let mesh_assets = meshes.peek()
      let material_assets = materials.peek()
      let normal = material_assets
        |> @pbr.add_material(
          @sprite.Color::srgb(124.0F / 255.0F, 144.0F / 255.0F, 1.0F),
        )
      let selected = material_assets
        |> @pbr.add_material(@sprite.Color::srgb(1.0F, 0.85F, 0.2F))
      let cube = commands.spawn(
        (
          @pbr.Mesh3d::new(
            mesh_assets |> @pbr.add_mesh(@math.Cuboid::new(0.5F, 0.5F, 0.5F)),
          ),
          @pbr.MeshMaterial3d::new(normal),
          @transform.Transform::from_xyz(
            0.0F,
            0.35F + Float::from_double(index.to_double()) * 0.6F,
            0.0F,
          ),
          PickableCube::{ normal, selected, active: false },
        ),
      )
      ignore(cube)
    })
    .observe_pointer2(fn(
      _pointer : @app.OnPointer[@app.PointerEnter],
      texts : @ecs.Query[@ecs.Mut[@text.TextColor], @ecs.All],
    ) {
      let color = texts.get(label) catch { _ => None }
      if color is Some(color) {
        color.set(@text.TextColor::new(@sprite.Color::srgb(0.3F, 0.9F, 0.95F)))
      }
    })
    .observe_pointer2(fn(
      _pointer : @app.OnPointer[@app.PointerLeave],
      texts : @ecs.Query[@ecs.Mut[@text.TextColor], @ecs.All],
    ) {
      let color = texts.get(label) catch { _ => None }
      if color is Some(color) {
        color.set(@text.TextColor::new(@sprite.Color::white()))
      }
    }),
  )
}

///|
fn toggle_cube_color_on_click(
  pointer : @app.OnPointer[@app.PointerClick],
  cubes : @ecs.Query[
    (@ecs.Mut[@pbr.MeshMaterial3d], @ecs.Mut[PickableCube]),
    @ecs.All,
  ],
) -> Unit {
  guard pointer.target() is Some(entity) else { return }
  let cube_data = cubes.get(entity) catch { _ => None }
  guard cube_data is Some((material, cube_state)) else { return }
  let next = cube_state.modify(fn(value) {
    value.active = !value.active
    if value.active {
      value.selected
    } else {
      value.normal
    }
  })
  material.set(@pbr.MeshMaterial3d::new(next))
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_startup_system_param3(setup)
  .add_pointer_observer2(fn(pointer, cubes) {
    toggle_cube_color_on_click(pointer, cubes)
  })
  .run()
}
