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
const PI : Float = 3.141592653589793F

///|
const ROTATION_SPEED : Float = 0.1F

///|
const UI_TEXTURE_SIZE : Int = 512

///|
const UI_TEXTURE_SIZE_F : Float = 512.0F

///|
const CUBE_SIZE : Float = 4.0F

///|
const PANEL_WIDTH : Float = 180.0F

///|
const PANEL_HEIGHT : Float = 100.0F

///|
const DIEGETIC_POINTER_ID : @pointer_events.PointerId = 1

///|
struct Cube {}

///|
let cube_key : @ecs.ComponentKey[Cube] = @ecs.register_component(
  debug_name="examples.ui.render_ui_to_texture.Cube",
)

///|
pub impl @ecs.Component for Cube with component() {
  cube_key
}

///|
struct MainCamera {}

///|
let main_camera_key : @ecs.ComponentKey[MainCamera] = @ecs.register_component(
  debug_name="examples.ui.render_ui_to_texture.MainCamera",
)

///|
pub impl @ecs.Component for MainCamera with component() {
  main_camera_key
}

///|
struct DraggablePanel {}

///|
let draggable_panel_key : @ecs.ComponentKey[DraggablePanel] = @ecs.register_component(
  debug_name="examples.ui.render_ui_to_texture.DraggablePanel",
)

///|
pub impl @ecs.Component for DraggablePanel with component() {
  draggable_panel_key
}

///|
struct PanelDragState {
  mut active : Bool
}

///|
fn PanelDragState::default() -> PanelDragState {
  { active: false }
}

///|
let panel_drag_state_resource_key : @ecs.ResourceKey[PanelDragState] = @ecs.register_resource(
  debug_name="examples.ui.render_ui_to_texture.PanelDragState",
)

///|
pub impl @app.Resource for PanelDragState with resource() {
  panel_drag_state_resource_key
}

///|
fn gray() -> @sprite.Color {
  @sprite.Color::srgb(0.5F, 0.5F, 0.5F)
}

///|
fn blue() -> @sprite.Color {
  @sprite.Color::srgb(0.0F, 0.0F, 1.0F)
}

///|
fn red() -> @sprite.Color {
  @sprite.Color::srgb(1.0F, 0.0F, 0.0F)
}

///|
fn float_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
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
fn cube_face_uv(
  local_point : @math.Vec3,
  local_normal : @math.Vec3,
) -> @math.Vec2 {
  let half = CUBE_SIZE / 2.0F
  let x01 = clamp01((local_point.x + half) / CUBE_SIZE)
  let y01 = clamp01((local_point.y + half) / CUBE_SIZE)
  let z01 = clamp01((local_point.z + half) / CUBE_SIZE)
  let abs_x = float_abs(local_normal.x)
  let abs_y = float_abs(local_normal.y)
  let abs_z = float_abs(local_normal.z)

  if abs_x >= abs_y && abs_x >= abs_z {
    if local_normal.x >= 0.0F {
      @math.Vec2::new(1.0F - z01, 1.0F - y01)
    } else {
      @math.Vec2::new(z01, 1.0F - y01)
    }
  } else if abs_y >= abs_x && abs_y >= abs_z {
    if local_normal.y >= 0.0F {
      @math.Vec2::new(x01, z01)
    } else {
      @math.Vec2::new(x01, 1.0F - z01)
    }
  } else if local_normal.z >= 0.0F {
    @math.Vec2::new(x01, 1.0F - y01)
  } else {
    @math.Vec2::new(1.0F - x01, 1.0F - y01)
  }
}

///|
fn cuboid_pointer_position(
  hit_point : @math.Vec3,
  hit_normal : @math.Vec3,
  cube_transform : @transform.Transform,
) -> @math.Vec2 {
  let world_from_local = @math.Isometry3d::new(
    cube_transform.translation,
    cube_transform.rotation,
  )
  let local_from_world = world_from_local.inverse()
  let rotation_only_inverse = @math.Isometry3d::new(
    @math.Vec3::zero(),
    cube_transform.rotation,
  ).inverse()
  let local_point = local_from_world.transform_point3(hit_point)
  let local_normal = rotation_only_inverse
    .transform_point3(hit_normal)
    .normalize_or_zero()
  let uv = cube_face_uv(local_point, local_normal)
  @math.Vec2::new(uv.x * UI_TEXTURE_SIZE_F, uv.y * UI_TEXTURE_SIZE_F)
}

///|
fn set_panel_color(
  entity : @core.Entity,
  color : @sprite.Color,
  backgrounds : @ecs.Query[@ecs.Mut[@ui.BackgroundColor], @ecs.All],
) -> Unit raise {
  if backgrounds.get(entity) is Some(background) {
    background.set(@ui.BackgroundColor::new(color))
  }
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  images : @app.ResMut[@asset.Assets[@asset.Image]],
) -> Unit {
  commands.insert_resource(PanelDragState::default())

  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let image_handle = images.get_ref().val.add(
    @asset.Image::new_target_texture(
      UI_TEXTURE_SIZE,
      UI_TEXTURE_SIZE,
      @asset.TextureFormat::Rgba8Unorm,
      Some(@asset.TextureFormat::Rgba8UnormSrgb),
    ),
  )
  let cube_mesh = meshes.get_ref().val
    |> @pbr.add_mesh(@math.Cuboid::new(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE))
  let cube_material = materials.get_ref().val
    |> @pbr.add_material(
      @pbr.StandardMaterial::from_color(@sprite.Color::white())
      .with_base_color_texture(Some(image_handle))
      .with_reflectance(0.02F),
    )

  let texture_camera = commands.spawn(
    (
      @sprite.Camera2d::default(),
      @sprite.Camera::default().with_order(-1),
      @transform.Transform::identity(),
      @sprite.RenderTarget::Image(image_handle),
      @ui.IsDefaultUiCamera::default(),
    ),
  )

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
      @ui.BackgroundColor::new(gray()),
      @ui.UiTargetCamera::new(texture_camera),
    ),
  )

  let panel = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      DraggablePanel::{  },
      @ui.Button::default(),
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_width(@ui.Val::Px(PANEL_WIDTH))
      .with_height(@ui.Val::Px(PANEL_HEIGHT))
      .with_left(@ui.Val::Px((UI_TEXTURE_SIZE_F - PANEL_WIDTH) / 2.0F))
      .with_top(@ui.Val::Px((UI_TEXTURE_SIZE_F - PANEL_HEIGHT) / 2.0F))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center),
      @ui.BackgroundColor::new(blue()),
    ),
  )

  commands.spawn(
    (
      @hierarchy.Parent::new(panel),
      @text.Text::new("Drag Me!"),
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(40.0F)),
      @text.TextColor::new(@sprite.Color::white()),
    ),
  )
  |> ignore

  ignore(
    commands
    .entity(panel)
    .observe_pointer2(fn(
      _pointer : @app.OnPointer[@app.PointerEnter],
      backgrounds : @ecs.Query[@ecs.Mut[@ui.BackgroundColor], @ecs.All],
    ) raise {
      set_panel_color(panel, red(), backgrounds)
    })
    .observe_pointer2(fn(
      _pointer : @app.OnPointer[@app.PointerLeave],
      backgrounds : @ecs.Query[@ecs.Mut[@ui.BackgroundColor], @ecs.All],
    ) raise {
      set_panel_color(panel, blue(), backgrounds)
    })
    .observe_pointer2(fn(
      pointer : @app.OnPointer[@app.PointerDown],
      drag_state : @app.ResMut[PanelDragState],
    ) {
      ignore(pointer)
      drag_state.get_ref().val.active = true
    }),
  )

  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::default(),
        @transform.Transform::from_xyz(0.0F, 3.0F, 6.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(cube_mesh),
        @pbr.MeshMaterial3d::new(cube_material),
        @transform.Transform::from_xyz(0.0F, 0.0F, 1.5F).with_rotation(
          @math.Quat::from_rotation_x(PI),
        ),
        Cube::{  },
      ),
    ),
  )

  commands.queue(fn(world : @ecs.World) {
    let camera_entity = @pbr.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(0.0F, 0.0F, 5.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ).spawn(world)
    try! (world.entity_mut(camera_entity).insert_component(MainCamera::{  })
    |> ignore)
  })
}

///|
fn rotate_cube(
  time : @app.Res[@time.Time[Unit]],
  cubes : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[Cube]],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! cubes.view(fn(_entity, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.rotation = transform_ref.val.rotation
      .mul(@math.Quat::from_rotation_x(delta * ROTATION_SPEED))
      .mul(@math.Quat::from_rotation_y(delta * ROTATION_SPEED * 0.7F))
      .normalize()
  })
}

///|
fn drive_diegetic_pointer(world : @ecs.World) -> Unit {
  let inputs_res = @picking.get_pointer_inputs_resource(world)
  guard inputs_res.get() is Some(inputs_value) else { return }

  let camera_query : @ecs.Query[
    (
      @ecs.Comp[@sprite.Camera],
      @ecs.Comp[@pbr.Projection],
      @ecs.Comp[@transform.Transform],
    ),
    @ecs.With[MainCamera],
  ] = @ecs.query_filtered(world, @ecs.With::new(MainCamera::component()))
  let cube_query : @ecs.Query[
    (@core.Entity, @ecs.Comp[@transform.Transform]),
    @ecs.With[Cube],
  ] = @ecs.query_filtered(world, @ecs.With::new(Cube::component()))
  guard (try! camera_query.single())
    is Some((camera, projection, camera_transform)) else {
    return
  }
  guard (try! cube_query.single()) is Some((cube_entity, cube_transform)) else {
    return
  }

  let down = @input.mouse_button_pressed(@window.MouseButton::Left)
  let just_pressed = @input.mouse_button_just_pressed(@window.MouseButton::Left)
  let just_released = @input.mouse_button_just_released(
    @window.MouseButton::Left,
  )

  let mut pointer_position : @math.Vec2? = None
  if @input.primary_pointer_position() is Some(cursor) &&
    @pbr.render3d_camera_viewport_to_world_ray(
      cursor,
      camera.value(),
      projection.value(),
      camera_transform.value(),
      @math.IVec2::new(@window.window_width(), @window.window_height()),
      @window.window_scale_factor(),
    )
    is Some((ray_origin, ray_direction)) {
    let settings = @pbr.MeshRayCastSettings::default()
      .with_max_hits(1)
      .with_only_entities(Some([cube_entity]))
    if @pbr.mesh_ray_cast_first(world, ray_origin, ray_direction, settings)
      is Some((_entity, hit)) {
      pointer_position = Some(
        cuboid_pointer_position(hit.point, hit.normal, cube_transform.value()),
      )
    }
  }

  let inputs = Ref::new(inputs_value)
  @picking.PointerInputs::push(
    inputs,
    @picking.PointerInput::new(
      DIEGETIC_POINTER_ID,
      pointer_position,
      down,
      just_pressed,
      just_released,
    ),
  )
  inputs_res.insert(inputs.val)
}

///|
fn drag_panel(
  pointer : @app.OnPointer[@app.PointerMove],
  drag_state : @app.ResMut[PanelDragState],
  panels : @ecs.Query[@ecs.Mut[@ui.Node], @ecs.With[DraggablePanel]],
) -> Unit raise {
  guard pointer.pointer() == DIEGETIC_POINTER_ID else { return }
  guard drag_state.get_ref().val.active else { return }
  guard panels.single() is Some(panel_node) else { return }
  panel_node.set(
    panel_node
    .value()
    .with_left(@ui.Val::Px(pointer.position().x - PANEL_WIDTH / 2.0F))
    .with_top(@ui.Val::Px(pointer.position().y - PANEL_HEIGHT / 2.0F)),
  )
}

///|
fn stop_drag_panel(
  pointer : @app.OnPointer[@app.PointerUp],
  drag_state : @app.ResMut[PanelDragState],
) -> Unit raise {
  if @app.current_world() is Some(world) {
    let entity_query : @ecs.QueryState[@core.Entity, @ecs.All] = world.query()
    ignore(entity_query.single(world))
  }
  guard pointer.pointer() == DIEGETIC_POINTER_ID else { return }
  drag_state.get_ref().val.active = false
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param5(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(rotate_cube)))
  .add_systems(
    @app.PreUpdate,
    @app.system(drive_diegetic_pointer)
    .after(@picking.picking_set_input)
    .after(@transform.transform_set_propagate)
    .before(@picking.picking_set_hits),
  )
  .add_pointer_observer3(drag_panel)
  .add_pointer_observer2(stop_drag_panel)
  .run()
}
