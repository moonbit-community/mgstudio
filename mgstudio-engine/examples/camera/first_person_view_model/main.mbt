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
/// Port of `bevy/examples/camera/first_person_view_model.rs`.

///|
priv struct Player {}

///|
let player_component_key : @ecs.ComponentKey[Player] = @ecs.register_component(
  debug_name="examples.camera.first_person_view_model.Player",
)

///|
impl @ecs.Component for Player with component() {
  player_component_key
}

///|
priv struct CameraSensitivity {
  x : Float
  y : Float
}

///|
let camera_sensitivity_component_key : @ecs.ComponentKey[CameraSensitivity] = @ecs.register_component(
  debug_name="examples.camera.first_person_view_model.CameraSensitivity",
)

///|
impl @ecs.Component for CameraSensitivity with component() {
  camera_sensitivity_component_key
}

///|
fn CameraSensitivity::default() -> CameraSensitivity {
  { x: 0.003F, y: 0.002F }
}

///|
priv struct WorldModelCamera {}

///|
let world_model_camera_component_key : @ecs.ComponentKey[WorldModelCamera] = @ecs.register_component(
  debug_name="examples.camera.first_person_view_model.WorldModelCamera",
)

///|
impl @ecs.Component for WorldModelCamera with component() {
  world_model_camera_component_key
}

///|
const DEFAULT_RENDER_LAYER : Int = 0

///|
const VIEW_MODEL_RENDER_LAYER : Int = 1

///|
fn degrees_to_radians(value : Float) -> Float {
  value * @math.pi() / 180.0F
}

///|
fn clamp_float(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn spawn_view_model(world : @ecs.World) -> Unit {
  let player = world.spawn_empty()
  world.component(Player::component()).insert(player, Player::{  })
  world
  .component(CameraSensitivity::component())
  .insert(player, CameraSensitivity::default())
  world
  .component(@transform.ecs_key_transform)
  .insert(player, @transform.Transform::from_xyz(0.0F, 1.0F, 0.0F))

  let world_camera = @camera.Camera3dBundle::new_with_projection(
    @sprite.Camera::default(),
    Perspective(@camera.PerspectiveProjection3d::{
      ..@camera.PerspectiveProjection3d::default(),
      fov: degrees_to_radians(90.0F),
    }),
    @transform.Transform::identity(),
  ).spawn(world)
  world
  .component(WorldModelCamera::component())
  .insert(world_camera, WorldModelCamera::{  })
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(world_camera, @hierarchy.Parent::new(player))

  let view_model_camera = @camera.Camera3dBundle::new_with_projection(
    @sprite.Camera::default().with_order(1),
    Perspective(@camera.PerspectiveProjection3d::{
      ..@camera.PerspectiveProjection3d::default(),
      fov: degrees_to_radians(70.0F),
    }),
    @transform.Transform::identity(),
  ).spawn(world)
  world
  .component(@sprite.ecs_key_render_layers)
  .insert(
    view_model_camera,
    @sprite.RenderLayers::layer(VIEW_MODEL_RENDER_LAYER),
  )
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(view_model_camera, @hierarchy.Parent::new(player))

  let arm = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(0.1F, 0.1F, 0.5F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::srgb(0.65F, 0.93F, 0.90F),
        ),
      ),
    ),
    @transform.Transform::from_xyz(0.2F, -0.1F, -0.25F),
  ).spawn(world)
  world
  .component(@sprite.ecs_key_render_layers)
  .insert(arm, @sprite.RenderLayers::layer(VIEW_MODEL_RENDER_LAYER))
  world
  .component(@pbr.NotShadowCaster::component())
  .insert(arm, @pbr.NotShadowCaster::default())
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(arm, @hierarchy.Parent::new(player))
}

///|
fn spawn_world_model(world : @ecs.World) -> Unit {
  let floor_material = @pbr.MeshMaterial3d::new(
    @pbr.standard_material_add(
      @pbr.StandardMaterial::from_color(@sprite.Color::white()),
    ),
  )
  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(10.0F, 10.0F)),
      ),
    ),
    floor_material,
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let cube_material = @pbr.MeshMaterial3d::new(
    @pbr.standard_material_add(
      @pbr.StandardMaterial::from_color(@sprite.Color::white()),
    ),
  )
  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(2.0F, 0.5F, 1.0F),
        ),
      ),
    ),
    cube_material,
    @transform.Transform::from_xyz(0.0F, 0.25F, -3.0F),
  ).spawn(world)
  |> ignore

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(2.0F, 0.5F, 1.0F),
        ),
      ),
    ),
    cube_material,
    @transform.Transform::from_xyz(0.75F, 1.75F, 0.0F),
  ).spawn(world)
  |> ignore
}

///|
fn spawn_lights(world : @ecs.World) -> Unit {
  let light = world.spawn_empty()
  world
  .component(@pbr.ecs_key_point_light)
  .insert(
    light,
    @pbr.PointLight::default()
    .with_color(@sprite.Color::srgb(1.0F, 0.76F, 0.84F))
    .with_shadow_maps_enabled(true),
  )
  world
  .component(@transform.ecs_key_transform)
  .insert(light, @transform.Transform::from_xyz(-2.0F, 4.0F, -0.75F))
  world
  .component(@sprite.ecs_key_render_layers)
  .insert(
    light,
    @sprite.RenderLayers::from_layers([
      DEFAULT_RENDER_LAYER,
      VIEW_MODEL_RENDER_LAYER,
    ]),
  )
}

///|
fn spawn_text(world : @ecs.World) -> Unit {
  let overlay_camera = @sprite.Camera2dBundle::new(
    @sprite.Camera::default().with_order(2).with_clear_color_none(),
    @transform.Transform::identity(),
  ).spawn(world)
  world
  .component(@ui.IsDefaultUiCamera::component())
  .insert(overlay_camera, @ui.IsDefaultUiCamera::default())

  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default())
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
  )

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  let text_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(root))
  world
  .component(@ui.ecs_key_node)
  .insert(
    text_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_bottom(@ui.Val::Px(12.0F))
    .with_left(@ui.Val::Px(12.0F)),
  )
  world
  .component(@text.ecs_key_text)
  .insert(
    text_entity,
    @text.Text::new(
      "Move the camera with your mouse.\nPress arrow up to decrease the FOV of the world model.\nPress arrow down to increase the FOV of the world model.",
    ),
  )
  world
  .component(@text.ecs_key_text_font)
  .insert(
    text_entity,
    @text.TextFont::default().with_font(font).with_font_size(20.0F),
  )
  world
  .component(@text.ecs_key_text_color)
  .insert(text_entity, @text.TextColor::new(@sprite.Color::white()))
  world
  .component(@text.ecs_key_text_layout)
  .insert(text_entity, @text.TextLayout::new_with_justify(@text.Justify::Left))
}

///|
fn move_player(
  accumulated_mouse_motion : @app.Res[@input.AccumulatedMouseMotion],
  player_query : @ecs.Query[
    (@ecs.Comp[CameraSensitivity], @ecs.Mut[@transform.Transform]),
    @ecs.With[Player],
  ],
) -> Unit {
  let delta = accumulated_mouse_motion.get().delta
  if delta.x == 0.0F && delta.y == 0.0F {
    return
  }
  let pitch_limit = @math.pi_half() - 0.01F
  try! player_query.view(fn(_entity, data) {
    let (camera_sensitivity, player_transform) = data
    let sensitivity = camera_sensitivity.value()
    let delta_yaw = -delta.x * sensitivity.x
    let delta_pitch = -delta.y * sensitivity.y
    let transform = player_transform.get_ref()
    let (yaw, pitch, roll) = transform.val.rotation.to_euler(
      @math.EulerRot::YXZ,
    )
    let next_yaw = yaw + delta_yaw
    let next_pitch = clamp_float(pitch + delta_pitch, -pitch_limit, pitch_limit)
    transform.val.rotation = @math.Quat::from_euler(
      @math.EulerRot::YXZ,
      next_yaw,
      next_pitch,
      roll,
    )
  })
}

///|
fn change_fov(
  input : @input.ButtonInput[@window.KeyCode],
  world_model_projection_query : @ecs.Query[
    @ecs.Mut[@camera.Projection],
    @ecs.With[WorldModelCamera],
  ],
) -> Unit {
  let mut delta = 0.0F
  if input.pressed(@window.KeyCode::ArrowUp) {
    delta = delta - degrees_to_radians(1.0F)
  }
  if input.pressed(@window.KeyCode::ArrowDown) {
    delta = delta + degrees_to_radians(1.0F)
  }
  if delta == 0.0F {
    return
  }

  let min_fov = degrees_to_radians(20.0F)
  let max_fov = degrees_to_radians(160.0F)
  try! world_model_projection_query.view(fn(_entity, projection) {
    let projection_ref = projection.get_ref()
    match projection_ref.val {
      Perspective(perspective) =>
        perspective.fov = clamp_float(perspective.fov + delta, min_fov, max_fov)
      Orthographic(_) => ()
      Custom(_) => ()
    }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(spawn_view_model))
  .add_systems(@app.Startup, @app.system(spawn_world_model))
  .add_systems(@app.Startup, @app.system(spawn_lights))
  .add_systems(@app.Startup, @app.system(spawn_text))
  .add_systems(@app.Update, @app.system(@app.system_param2(move_player)))
  .add_systems(@app.Update, @app.system(@app.system_param2(change_fov)))
  .run()
}
