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
pub(all) enum DebugPickingMode {
  Disabled
  Normal
  Noisy
}

///|
fn DebugPickingMode::next(self : DebugPickingMode) -> DebugPickingMode {
  match self {
    DebugPickingMode::Disabled => DebugPickingMode::Normal
    DebugPickingMode::Normal => DebugPickingMode::Noisy
    DebugPickingMode::Noisy => DebugPickingMode::Disabled
  }
}

///|
fn debug_mode_name(mode : DebugPickingMode) -> String {
  match mode {
    DebugPickingMode::Disabled => "Disabled"
    DebugPickingMode::Normal => "Normal"
    DebugPickingMode::Noisy => "Noisy"
  }
}

///|
struct DebugPickingState {
  mut mode : DebugPickingMode
  label_entity : @core.Entity
  mut last_event : String
}

///|
let ecs_res_key_debug_picking_state : @ecs.ResourceKey[DebugPickingState] = @ecs.register_resource(
  debug_name="examples.picking.debug.state",
)

///|
impl @app.Resource for DebugPickingState with resource() {
  ecs_res_key_debug_picking_state
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh_assets = meshes.get_ref().val
  let material_assets = materials.get_ref().val

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(
          mesh_assets |> @pbr.add_mesh(@mesh.Mesh3dGeometry::circle(4.0F, 32)),
        ),
        @pbr.MeshMaterial3d::new(
          material_assets |> @pbr.add_material(@sprite.Color::white()),
        ),
        @transform.Transform::identity().with_rotation(
          @math.Quat::from_rotation_x(-@math.pi_half()),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(
          mesh_assets |> @pbr.add_mesh(@math.Cuboid::new(1.0F, 1.0F, 1.0F)),
        ),
        @pbr.MeshMaterial3d::new(
          material_assets
          |> @pbr.add_material(@sprite.Color::srgb(0.5F, 0.7F, 1.0F)),
        ),
        @transform.Transform::from_xyz(0.0F, 0.6F, 0.0F),
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
        @pbr.Camera3d::default(),
        @transform.Transform::from_xyz(-2.5F, 4.5F, 9.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  let label = commands.spawn(
    (
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_left(@ui.Val::Px(12.0F))
      .with_top(@ui.Val::Px(12.0F)),
      @text.Text::new(""),
      @text.TextColor::new(@sprite.Color::white()),
      @text.TextFont::from_font_size(@text.FontSize::Px(20.0F)),
    ),
  )
  commands.insert_resource({
    mode: DebugPickingMode::Normal,
    label_entity: label,
    last_event: "none",
  })
}

///|
fn update_debug_mode(state : @app.ResMut[DebugPickingState]) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::F3) {
    state.get_ref().val.mode = state.get_ref().val.mode.next()
  }
}

///|
fn on_pointer_move(
  pointer : @app.OnPointer[@app.PointerMove],
  state : @app.ResMut[DebugPickingState],
) -> Unit {
  if state.get_ref().val.mode is DebugPickingMode::Noisy {
    let target_text = match pointer.target() {
      Some(entity) => entity.id.to_string()
      None => "none"
    }
    state.get_ref().val.last_event = "move target=" + target_text
  }
}

///|
fn on_pointer_click(
  pointer : @app.OnPointer[@app.PointerClick],
  state : @app.ResMut[DebugPickingState],
) -> Unit {
  if state.get_ref().val.mode is DebugPickingMode::Disabled {
    return
  }
  let target_text = match pointer.target() {
    Some(entity) => entity.id.to_string()
    None => "none"
  }
  state.get_ref().val.last_event = "click target=" + target_text
}

///|
fn refresh_overlay(
  state : @app.Res[DebugPickingState],
  texts : @ecs.Query[@ecs.Mut[@text.Text], @ecs.All],
) -> Unit {
  let text = texts.get(state.get().label_entity) catch { _ => None }
  if text is Some(text) {
    text.get_ref().val = @text.Text::new(
      "Press F3 to cycle debug mode\nMode: " +
      debug_mode_name(state.get().mode) +
      "\nLast event: " +
      state.get().last_event,
    )
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_startup_system_param3(setup)
  .add_system_param(update_debug_mode)
  .add_system_param2(refresh_overlay)
  .add_pointer_observer2(fn(pointer, state) { on_pointer_move(pointer, state) })
  .add_pointer_observer2(fn(pointer, state) { on_pointer_click(pointer, state) })
  .run()
}
