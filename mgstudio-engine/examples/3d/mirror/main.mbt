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
const FRAC_PI_2 : Float = 1.5707963267948966F

///|
const SCREEN_SPACE_TEXTURE_SHADER : String = "shaders/screen_space_texture_material.wgsl"

///|
const CAMERA_ORBIT_DISTANCE : Float = 500.0F

///|
const CAMERA_PITCH_SPEED : Float = 0.003F

///|
const CAMERA_YAW_SPEED : Float = 0.004F

///|
const CAMERA_PITCH_LIMIT : Float = 1.5607963267948965F

///|
const MIRROR_ROTATION_ANGLE : Float = -FRAC_PI_2

///|
const FOX_ASSET_PATH : String = "models/animated/Fox.glb"

///|
const LAYER_MAIN_SCENE : Int = 0

///|
const LAYER_MIRROR_SURFACE : Int = 1

///|
priv enum DragAction {
  MoveCamera
  MoveFox
} derive(Eq)

///|
impl @widgets_lib.WidgetValue for DragAction with fn widget_debug_name() {
  "examples.3d.mirror.DragAction"
}

///|
let drag_action_widget_click_event_key : @ecs.MessageKey[
  @widgets_lib.WidgetClickEvent[DragAction],
] = @ecs.register_message(
  debug_name="examples.helpers.widgets_lib.WidgetClickEvent<examples.3d.mirror.DragAction>",
)

///|
impl @widgets_lib.WidgetValue for DragAction with fn widget_click_event_key() {
  drag_action_widget_click_event_key
}

///|
let drag_action_widget_click_sender_key : @ecs.ComponentKey[
  @widgets_lib.WidgetClickSender[DragAction],
] = @ecs.register_component(
  debug_name="examples.helpers.widgets_lib.WidgetClickSender<examples.3d.mirror.DragAction>",
)

///|
impl @widgets_lib.WidgetValue for DragAction with fn widget_click_sender_key() {
  drag_action_widget_click_sender_key
}

///|
priv struct MirrorImage {
  mut image : @asset.Handle[@asset.Image]
}

///|
fn MirrorImage::new(image : @asset.Handle[@asset.Image]) -> MirrorImage {
  MirrorImage::{ image, }
}

///|
let mirror_image_resource_key : @ecs.ResourceKey[MirrorImage] = @ecs.register_resource(
  debug_name="examples.3d.mirror.MirrorImage",
)

///|
impl @app.Resource for MirrorImage with fn resource() {
  mirror_image_resource_key
}

///|
priv struct MirrorCamera {}

///|
let mirror_camera_component_key : @ecs.ComponentKey[MirrorCamera] = @ecs.register_component(
  debug_name="examples.3d.mirror.MirrorCamera",
)

///|
impl @ecs.Component for MirrorCamera with fn component() {
  mirror_camera_component_key
}

///|
priv struct Mirror {}

///|
let mirror_component_key : @ecs.ComponentKey[Mirror] = @ecs.register_component(
  debug_name="examples.3d.mirror.Mirror",
)

///|
impl @ecs.Component for Mirror with fn component() {
  mirror_component_key
}

///|
pub(all) struct ScreenSpaceTextureExtension {
  dummy : Float
}

///|
fn ScreenSpaceTextureExtension::ScreenSpaceTextureExtension() -> ScreenSpaceTextureExtension {
  ScreenSpaceTextureExtension::{ dummy: 0.0F }
}

///|
fn screen_space_texture_extension_uniform_bytes(
  extension : ScreenSpaceTextureExtension,
) -> Bytes {
  let word = extension.dummy.reinterpret_as_uint()
  Bytes::makei(4, i => {
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
pub impl @pbr.MaterialExtension for ScreenSpaceTextureExtension with fn extension_tag(
  _self,
) {
  84
}

///|
pub impl @pbr.MaterialExtension for ScreenSpaceTextureExtension with fn vertex_shader(
  _self,
) {
  None
}

///|
pub impl @pbr.MaterialExtension for ScreenSpaceTextureExtension with fn fragment_shader(
  _self,
) {
  Some(SCREEN_SPACE_TEXTURE_SHADER)
}

///|
pub impl @pbr.MaterialExtension for ScreenSpaceTextureExtension with fn prepass_vertex_shader(
  _self,
) {
  None
}

///|
pub impl @pbr.MaterialExtension for ScreenSpaceTextureExtension with fn prepass_fragment_shader(
  _self,
) {
  None
}

///|
pub impl @pbr.MaterialExtension for ScreenSpaceTextureExtension with fn deferred_vertex_shader(
  _self,
) {
  None
}

///|
pub impl @pbr.MaterialExtension for ScreenSpaceTextureExtension with fn deferred_fragment_shader(
  _self,
) {
  None
}

///|
pub impl @pbr.MaterialExtension for ScreenSpaceTextureExtension with fn alpha_mode(
  _self,
) {
  None
}

///|
pub impl @pbr.MaterialExtension for ScreenSpaceTextureExtension with fn opaque_render_method(
  _self,
) {
  None
}

///|
pub impl @pbr.MaterialExtension for ScreenSpaceTextureExtension with fn enable_prepass(
  _self,
) {
  true
}

///|
pub impl @pbr.MaterialExtension for ScreenSpaceTextureExtension with fn enable_shadows(
  _self,
) {
  true
}

///|
pub impl @pbr.MaterialExtension for ScreenSpaceTextureExtension with fn specialize(
  _self,
) {
  None
}

///|
pub impl @pbr.MaterialExtension for ScreenSpaceTextureExtension with fn bind_group_layout_entries(
  _self,
) {
  [
    @render_resource.BindGroupLayoutEntry::new(
      100,
      @wgpu.SHADER_STAGE_FRAGMENT.to_uint(),
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Uniform,
        false,
        4UL,
      ),
    ),
  ]
}

///|
pub impl @pbr.MaterialExtension for ScreenSpaceTextureExtension with fn bind_group_bindings(
  self,
) {
  [
    @material.MaterialExtensionBinding3d::uniform(
      100,
      screen_space_texture_extension_uniform_bytes(self),
    ),
  ]
}

///|
priv struct AppStatus {
  mut drag_action : DragAction
}

///|
fn AppStatus::AppStatus() -> AppStatus {
  AppStatus::{ drag_action: DragAction::MoveCamera }
}

///|
let app_status_resource_key : @ecs.ResourceKey[AppStatus] = @ecs.register_resource(
  debug_name="examples.3d.mirror.AppStatus",
)

///|
impl @app.Resource for AppStatus with fn resource() {
  app_status_resource_key
}

///|
priv struct HelpText {}

///|
let help_text_component_key : @ecs.ComponentKey[HelpText] = @ecs.register_component(
  debug_name="examples.3d.mirror.HelpText",
)

///|
impl @ecs.Component for HelpText with fn component() {
  help_text_component_key
}

///|
fn clampf(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn normalize_or(value : @math.Vec3, fallback : @math.Vec3) -> @math.Vec3 {
  let normalized = value.normalize_or_zero()
  if normalized.length_squared() <= 0.0000001F {
    fallback
  } else {
    normalized
  }
}

///|
fn camera_target() -> @math.Vec3 {
  @math.Vec3::new(-25.0F, 20.0F, 0.0F)
}

///|
fn mirror_position() -> @math.Vec3 {
  @math.Vec3::new(-25.0F, 75.0F, 0.0F)
}

///|
fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
}

///|
fn quat_conjugate(q : @math.Quat) -> @math.Quat {
  @math.Quat::new(-q.x, -q.y, -q.z, q.w)
}

///|
fn mirror_reflection_affine_neg_z() -> @math.Affine3 {
  @math.Affine3::from_mat3_translation(
    @math.Mat3::from_cols(
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
      @math.Vec3::new(0.0F, 0.0F, -1.0F),
    ),
    @math.Vec3::zero(),
  )
}

///|
fn calculate_mirror_camera_transform_and_projection(
  main_camera_transform : @transform.Transform,
  main_camera_projection : @camera.PerspectiveProjection3d,
  mirror_transform : @transform.Transform,
) -> (@transform.Transform, @camera.PerspectiveProjection3d) {
  let world_up = @math.Vec3::new(0.0F, 1.0F, 0.0F)
  let negative_world_up = @math.Vec3::new(0.0F, -1.0F, 0.0F)

  let reflected_affine = mirror_reflection_affine_neg_z().mul(
    @transform.GlobalTransform::from_transform(main_camera_transform).affine(),
  )
  let (reflected_scale, reflected_rotation, reflected_translation) = reflected_affine.to_scale_rotation_translation()
  let mirror_camera_transform = @transform.Transform::new(
    reflected_translation, reflected_rotation, reflected_scale,
  )

  let mirror_normal = normalize_or(
    quat_rotate_vec3(mirror_transform.rotation, world_up),
    world_up,
  )
  let distance_from_camera_to_mirror = mirror_transform.translation
    .sub(main_camera_transform.translation)
    .dot(mirror_normal)
  let view_from_world_rotation = quat_conjugate(
    main_camera_transform.rotation.normalize(),
  )
  let mirror_projection_plane_normal = normalize_or(
    quat_rotate_vec3(
      view_from_world_rotation,
      quat_rotate_vec3(mirror_transform.rotation, negative_world_up),
    ),
    @math.Vec3::new(0.0F, 0.0F, -1.0F),
  )
  let mirror_camera_projection = @camera.PerspectiveProjection3d::{
    ..main_camera_projection,
    near_clip_plane: @math.Vec4::new(
      mirror_projection_plane_normal.x,
      mirror_projection_plane_normal.y,
      mirror_projection_plane_normal.z,
      distance_from_camera_to_mirror,
    ),
  }

  (mirror_camera_transform, mirror_camera_projection)
}

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::Window()
  window.title = "Mgstudio Mirror Example"
  window
}

///|
fn create_mirror_texture_image(
  window_size : @math.IVec2,
) -> @asset.Handle[@asset.Image] {
  guard @app.current_world() is Some(world) else {
    abort("mirror render target creation requires an active world")
  }
  @sprite_render.render2d_create_render_target(
    world,
    window_size.x.max(1),
    window_size.y.max(1),
    true,
  )
}

///|
fn first_window_size(
  windows_query : @ecs.Query[@ecs.Read[@window.Window], @ecs.All],
) -> @math.IVec2 {
  let size_ref : Ref[@math.IVec2?] = Ref(None)
  try! windows_query.view(fn(_entity, window) {
    if size_ref.val is None {
      let value = window.value()
      size_ref.val = Some(
        @math.IVec2::new(value.physical_width(), value.physical_height()),
      )
    }
  })
  size_ref.val.unwrap_or(@math.IVec2::new(1024, 1024))
}

///|
fn create_mirror_texture_resource(
  commands : @app.Commands,
  windows_query : @ecs.Query[@ecs.Read[@window.Window], @ecs.All],
) -> @asset.Handle[@asset.Image] {
  let image = create_mirror_texture_image(first_window_size(windows_query))
  commands.insert_resource(MirrorImage::new(image))
  image
}

///|
fn spawn_main_camera(
  commands : @app.Commands,
  camera_projection : @camera.PerspectiveProjection3d,
) -> @transform.Transform {
  let initial_main_translation = @math.Vec3::new(-2.0F, 1.0F, -2.0F)
    .normalize_or_zero()
    .mul_scalar(CAMERA_ORBIT_DISTANCE)
  let camera_transform = @transform.Transform::from_xyz(
    initial_main_translation.x,
    initial_main_translation.y,
    initial_main_translation.z,
  ).looking_at(camera_target(), @math.Vec3::new(0.0F, 1.0F, 0.0F))

  let camera = commands.spawn(
    @camera.Camera3dBundle::new_with_projection(
      @camera_camera.Camera::Camera(),
      @camera.Projection::Perspective(camera_projection),
      camera_transform,
    ),
  )
  commands
  .entity(camera)
  .insert_component(
    @camera_render_layers.RenderLayers::from_layers([
      LAYER_MAIN_SCENE,
      LAYER_MIRROR_SURFACE,
    ]),
  )
  camera_transform
}

///|
fn spawn_light(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(@color.Color::white(), 5000.0F, true),
        @transform.Transform::from_xyz(-85.0F, 16.0F, -200.0F).looking_at(
          @math.Vec3::new(-50.0F, 0.0F, 100.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn spawn_ground_plane(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  standard_materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh = meshes.modify(fn(assets) {
    assets
    |> @pbr.add_mesh(
      @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
        @math.Vec2::new(400.0F, 400.0F),
      ).build(),
    )
  })
  let material = standard_materials.modify(fn(assets) {
    assets.add(
      @pbr.StandardMaterial::from_color(
        @color.Color::new(0.0F, 0.5F, 0.0F, 1.0F),
      ),
    )
  })
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(mesh),
        @pbr.MeshMaterial3d::new(material),
        @transform.Transform::from_rotation(
          @math.Quat::from_rotation_x(-FRAC_PI_2),
        ).with_translation(@math.Vec3::new(-25.0F, 0.0F, 0.0F)),
      ),
    ),
  )
}

///|
fn spawn_fox(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    {
      let scene = @scene.scene_load_gltf_scene(
        asset_server.get(),
        @gltf.GltfAssetLabel::Scene(0).from_asset(FOX_ASSET_PATH),
      )
      commands.spawn(
        (
          @scene.WorldAssetRoot::new(scene),
          @transform.Transform::from_xyz(-50.0F, 0.0F, -100.0F),
        ),
      )
    },
  )
}

///|
fn spawn_mirror(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  standard_materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  mirror_render_target : @asset.Handle[@asset.Image],
) -> @transform.Transform {
  let mirror_transform = @transform.Transform::identity()
    .with_scale(@math.Vec3::new(300.0F, 1.0F, 150.0F))
    .with_rotation(@math.Quat::from_rotation_x(MIRROR_ROTATION_ANGLE))
    .with_translation(mirror_position())
  let mirror_material_value = @pbr.StandardMaterial::from_color(
      @color.Color::black(),
    )
    .with_emissive(@color.Color::white())
    .with_emissive_texture(Some(mirror_render_target))
    .with_perceptual_roughness(0.0F)
    .with_metallic(1.0F)
  let mesh = meshes.modify(fn(assets) {
    assets
    |> @pbr.add_mesh(
      @mesh_primitives_dim3.PlaneMeshBuilder::from_size(@math.Vec2::splat(1.0F)).build(),
    )
  })
  let material = standard_materials.modify(fn(assets) {
    assets.add(mirror_material_value)
  })
  let mirror_entity = commands.spawn(
    (
      @mesh.Mesh3d::new(mesh),
      @pbr.MeshMaterial3d::new(material).with_extended_material(
        Some(
          @pbr.ExtendedMaterial::new(
            mirror_material_value,
            ScreenSpaceTextureExtension::ScreenSpaceTextureExtension(),
          ).metadata(),
        ),
      ),
      mirror_transform,
      Mirror::{  },
      @camera_render_layers.RenderLayers::layer(LAYER_MIRROR_SURFACE),
    ),
  )
  ignore(mirror_entity)
  mirror_transform
}

///|
fn spawn_mirror_camera(
  commands : @app.Commands,
  camera_transform : @transform.Transform,
  camera_projection : @camera.PerspectiveProjection3d,
  mirror_transform : @transform.Transform,
  mirror_render_target : @asset.Handle[@asset.Image],
) -> Unit {
  let (mirror_camera_transform, mirror_camera_projection) = calculate_mirror_camera_transform_and_projection(
    camera_transform, camera_projection, mirror_transform,
  )
  let mirror_camera = @camera.Camera3dBundle::new_with_projection(
    @camera_camera.Camera::new(@color.Color::black())
    .with_order(-1)
    .with_invert_culling(true),
    @camera.Projection::Perspective(mirror_camera_projection),
    mirror_camera_transform,
  )
  let mirror_camera = commands.spawn(mirror_camera)
  let entity = commands.entity(mirror_camera)
  entity.insert_component(
    @camera_camera.RenderTarget::Image(mirror_render_target),
  )
  entity.insert_component(
    @camera_render_layers.RenderLayers::layer(LAYER_MAIN_SCENE),
  )
  entity.insert_component(MirrorCamera::{  })
}

///|
fn spawn_buttons(commands : @app.Commands) -> Unit {
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
  let root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      @ui.Node::Node()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
      @ui.UiTargetCamera::new(ui_camera),
    ),
  )
  let panel = commands.spawn(
    (@hierarchy.Parent::new(root), @widgets_lib.main_ui_node()),
  )
  ignore(
    @widgets_lib.spawn_option_buttons(commands, panel, "Drag Action", [
      (DragAction::MoveCamera, "Move Camera"),
      (DragAction::MoveFox, "Move Fox"),
    ]),
  )
}

///|
fn create_help_string(app_status : AppStatus) -> String {
  let mode = if app_status.drag_action == DragAction::MoveCamera {
    "camera"
  } else {
    "fox"
  }
  "Click and drag to move the \{mode}"
}

///|
fn spawn_help_text(
  commands : @app.Commands,
  app_status : @app.Res[AppStatus],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @text.Text::new(create_help_string(app_status.get())),
        @ui.Node::Node()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.Val::Px(12.0F))
        .with_left(@ui.Val::Px(12.0F)),
        HelpText::{  },
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  windows_query : @ecs.Query[@ecs.Read[@window.Window], @ecs.All],
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  standard_materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let camera_projection = @camera.PerspectiveProjection3d::PerspectiveProjection3d()
  let camera_transform = spawn_main_camera(commands, camera_projection)
  spawn_light(commands)
  spawn_ground_plane(commands, meshes, standard_materials)
  spawn_fox(commands, asset_server)
  let mirror_render_target = create_mirror_texture_resource(
    commands, windows_query,
  )
  let mirror_transform = spawn_mirror(
    commands, meshes, standard_materials, mirror_render_target,
  )
  spawn_mirror_camera(
    commands, camera_transform, camera_projection, mirror_transform, mirror_render_target,
  )
  spawn_buttons(commands)
  spawn_help_text(commands, app_status)
}

///|
fn pointer_over_ui(
  interactions_query : @ecs.Query[
    @ecs.Read[@ui.Interaction],
    @ecs.With[@widgets_lib.RadioButton],
  ],
) -> Bool {
  let over : Ref[Bool] = Ref(false)
  try! interactions_query.view(fn(_entity, interaction) {
    if interaction.value() != @ui.Interaction::None {
      over.val = true
    }
  })
  over.val
}

///|
fn ray_plane_intersection(
  ray_origin : @math.Vec3,
  ray_direction : @math.Vec3,
  plane_point : @math.Vec3,
  plane_normal : @math.Vec3,
) -> @math.Vec3? {
  let denom = plane_normal.dot(ray_direction)
  if absf(denom) <= 0.000001F {
    return None
  }
  let t = plane_point.sub(ray_origin).dot(plane_normal) / denom
  if t < 0.0F {
    return None
  }
  Some(ray_origin.add(ray_direction.mul_scalar(t)))
}

///|
fn handle_window_resize_messages(
  windows_query : @ecs.Query[@ecs.Read[@window.Window], @ecs.All],
  mirror_cameras_query : @ecs.Query[
    @ecs.Write[@camera_camera.RenderTarget],
    @ecs.With[MirrorCamera],
  ],
  mirrors_query : @ecs.Query[@ecs.Read[@pbr.MeshMaterial3d], @ecs.With[Mirror]],
  standard_materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  mirror_image : @app.ResMut[MirrorImage],
  resize_messages : @ecs.MessageReader[@window.WindowResized],
) -> Unit {
  guard resize_messages.read().length() > 0 else { return }
  let image = create_mirror_texture_image(first_window_size(windows_query))
  mirror_image.modify(fn(resource) {
    ignore(resource.image)
    resource.image = image
  })
  try! mirror_cameras_query.view(fn(_entity, target) {
    target.set(@camera_camera.RenderTarget::Image(image))
  })
  try! mirrors_query.view(fn(_entity, material) {
    let handle = material.value().material_asset_id()
    let material_handle : @asset.Handle[@pbr.StandardMaterial] = @asset.Handle::new(
      handle,
    )
    standard_materials.modify(fn(assets) {
      if assets.get(material_handle) is Some(material_value) {
        ignore(
          assets.set(
            material_handle,
            material_value.with_emissive_texture(Some(image)),
          ),
        )
      }
    })
  })
}

///|
fn move_fox_on_mouse_down(
  scene_roots_query : @ecs.Query[
    @ecs.Write[@transform.Transform],
    (@ecs.With[@scene.WorldAssetRoot], @ecs.Without[@camera.Camera3d]),
  ],
  windows_query : @ecs.Query[
    @ecs.Read[@window.Window],
    @ecs.With[@window.PrimaryWindow],
  ],
  cameras_query : @ecs.Query[
    (
      @ecs.Read[@camera_camera.Camera],
      @ecs.Read[@transform.Transform],
      @ecs.Read[@camera.Projection],
    ),
    (
      @ecs.With[@camera.Camera3d],
      @ecs.Without[MirrorCamera],
      @ecs.Without[@scene.WorldAssetRoot],
    ),
  ],
  interactions_query : @ecs.Query[
    @ecs.Read[@ui.Interaction],
    @ecs.With[@widgets_lib.RadioButton],
  ],
  mouse_buttons : @input.ButtonInput[@window.MouseButton],
  app_status : @app.Res[AppStatus],
) -> Unit {
  if app_status.get().drag_action != DragAction::MoveFox ||
    !mouse_buttons.pressed(@window.MouseButton::Left) ||
    pointer_over_ui(interactions_query) {
    return
  }
  let window_ref : Ref[@window.Window?] = Ref(None)
  try! windows_query.view(fn(_entity, window) {
    if window_ref.val is None {
      window_ref.val = Some(window.value())
    }
  })
  guard window_ref.val is Some(window) else { return }
  guard window.cursor_position() is Some(mouse_position) else { return }

  let camera_ref : Ref[
    (@camera_camera.Camera, @transform.Transform, @camera.Projection)?,
  ] = Ref(None)
  try! cameras_query.view(fn(_entity, data) {
    if camera_ref.val is None {
      let (camera, transform, projection) = data
      camera_ref.val = Some(
        (camera.value(), transform.value(), projection.value()),
      )
    }
  })
  guard camera_ref.val is Some((camera, camera_transform, projection)) else {
    return
  }
  guard @camera.camera_viewport_to_world_ray(
      mouse_position,
      camera,
      projection,
      camera_transform,
      @math.IVec2::new(window.physical_width(), window.physical_height()),
      window.scale_factor(),
    )
    is Some((ray_origin, ray_dir)) else {
    return
  }
  guard ray_plane_intersection(
      ray_origin,
      ray_dir,
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    )
    is Some(hit) else {
    return
  }
  try! scene_roots_query.view(fn(_entity, transform) {
    let value = transform.value()
    transform.set(
      value.with_translation(@math.Vec3::new(hit.x, value.translation.y, hit.z)),
    )
  })
}

///|
fn handle_mouse_action_change(
  app_status : @app.ResMut[AppStatus],
  events : @ecs.MessageReader[@widgets_lib.WidgetClickEvent[DragAction]],
) -> Unit {
  app_status.modify(fn(status) {
    for event in events.read() {
      status.drag_action = event.get()
    }
  })
}

///|
fn update_radio_buttons(
  radio_buttons : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[DragAction]],
      @ecs.Write[@ui.BackgroundColor],
    ),
    @ecs.With[@widgets_lib.RadioButton],
  ],
  radio_button_texts : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[DragAction]],
      @ecs.Write[@text.TextColor],
    ),
    @ecs.With[@widgets_lib.RadioButtonText],
  ],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let drag_action = app_status.get().drag_action
  try! radio_buttons.view(fn(_entity, data) {
    let (sender, background_color) = data
    @widgets_lib.update_ui_radio_button(
      background_color,
      sender.value().get() == drag_action,
    )
  })
  try! radio_button_texts.view(fn(_entity, data) {
    let (sender, text_color) = data
    @widgets_lib.update_ui_radio_button_text(
      text_color,
      sender.value().get() == drag_action,
    )
  })
}

///|
fn move_camera_on_mouse_down(
  main_cameras_query : @ecs.Query[
    @ecs.Write[@transform.Transform],
    (@ecs.With[@camera_camera.Camera], @ecs.Without[MirrorCamera]),
  ],
  interactions_query : @ecs.Query[
    @ecs.Read[@ui.Interaction],
    @ecs.With[@widgets_lib.RadioButton],
  ],
  mouse_buttons : @input.ButtonInput[@window.MouseButton],
  mouse_motion : @app.Res[@input.AccumulatedMouseMotion],
  app_status : @app.Res[AppStatus],
) -> Unit {
  if app_status.get().drag_action != DragAction::MoveCamera ||
    !mouse_buttons.pressed(@window.MouseButton::Left) ||
    pointer_over_ui(interactions_query) {
    return
  }
  let delta = mouse_motion.get().delta
  let delta_pitch = delta.y * CAMERA_PITCH_SPEED
  let delta_yaw = delta.x * CAMERA_YAW_SPEED
  try! main_cameras_query.view(fn(_entity, main_camera_transform) {
    let value = main_camera_transform.value()
    let (yaw, pitch, _roll) = value.rotation.to_euler(@math.EulerRot::YXZ)
    let pitch = clampf(
      pitch + delta_pitch,
      -CAMERA_PITCH_LIMIT,
      CAMERA_PITCH_LIMIT,
    )
    let yaw = yaw + delta_yaw
    let rotation = @math.Quat::from_euler(@math.EulerRot::YXZ, yaw, pitch, 0.0F)
    let forward = quat_rotate_vec3(rotation, @math.Vec3::new(0.0F, 0.0F, -1.0F))
    main_camera_transform.set(
      value
      .with_rotation(rotation)
      .with_translation(forward.mul_scalar(-CAMERA_ORBIT_DISTANCE)),
    )
  })
}

///|
fn update_mirror_camera_on_main_camera_transform_change(
  main_cameras_query : @ecs.Query[
    (@ecs.Read[@transform.Transform], @ecs.Read[@camera.Projection]),
    (
      @ecs.Changed[@transform.Transform],
      @ecs.With[@camera_camera.Camera],
      @ecs.Without[MirrorCamera],
    ),
  ],
  mirror_cameras_query : @ecs.Query[
    (@ecs.Write[@transform.Transform], @ecs.Write[@camera.Projection]),
    (
      @ecs.With[@camera_camera.Camera],
      @ecs.With[MirrorCamera],
      @ecs.Without[Mirror],
    ),
  ],
  mirrors_query : @ecs.Query[
    @ecs.Read[@transform.Transform],
    (@ecs.Without[MirrorCamera], @ecs.With[Mirror]),
  ],
) -> Unit {
  let main_ref : Ref[(@transform.Transform, @camera.PerspectiveProjection3d)?] = Ref(
    None,
  )
  try! main_cameras_query.view(fn(_entity, data) {
    if main_ref.val is None {
      let (transform, projection) = data
      if projection.value() is Perspective(perspective) {
        main_ref.val = Some((transform.value(), perspective))
      }
    }
  })
  guard main_ref.val is Some((main_camera_transform, main_projection)) else {
    return
  }
  let mirror_ref : Ref[@transform.Transform?] = Ref(None)
  try! mirrors_query.view(fn(_entity, mirror_transform) {
    if mirror_ref.val is None {
      mirror_ref.val = Some(mirror_transform.value())
    }
  })
  guard mirror_ref.val is Some(mirror_transform) else { return }
  let (mirror_camera_transform, mirror_camera_projection) = calculate_mirror_camera_transform_and_projection(
    main_camera_transform, main_projection, mirror_transform,
  )
  try! mirror_cameras_query.view(fn(_entity, data) {
    let (transform, projection) = data
    transform.set(mirror_camera_transform)
    projection.set(@camera.Projection::Perspective(mirror_camera_projection))
  })
}

///|
fn play_fox_animation(
  commands : @app.Commands,
  animation_players_query : @ecs.Query[
    (@core.Entity, @ecs.Write[@animation.AnimationPlayer]),
    @ecs.Without[@animation.AnimationGraphHandle],
  ],
  asset_server : @app.Res[@asset.AssetServer],
  animation_graphs : @app.ResMut[@asset.Assets[@animation.AnimationGraph]],
) -> Unit {
  if animation_players_query.count() == 0 {
    return
  }
  let fox_animation = asset_server
    .get()
    .load(@gltf.GltfAssetLabel::Animation(0).from_asset(FOX_ASSET_PATH))
  let (fox_animation_graph, fox_animation_node) = @animation.AnimationGraph::from_clip(
    fox_animation,
  )
  let fox_animation_graph = animation_graphs.modify(fn(assets) {
    assets.add(fox_animation_graph)
  })
  try! animation_players_query.view(fn(_query_entity, data) {
    let (entity, animation_player) = data
    commands
    .entity(entity)
    .insert_component(@animation.AnimationGraphHandle::new(fox_animation_graph))
    animation_player.modify(fn(player) {
      player.play(fox_animation_node).repeat() |> ignore
    })
  })
}

///|
fn update_help_text(
  help_text : @ecs.Query[@ecs.Write[@text.Text], @ecs.With[HelpText]],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let content = create_help_string(app_status.get())
  try! help_text.view(fn(_entity, text) { text.set(@text.Text::new(content)) })
}

///|
fn handle_ui_interactions(
  interactions : @ecs.Query[
    (
      @ecs.Read[@ui.Interaction],
      @ecs.Read[@widgets_lib.WidgetClickSender[DragAction]],
    ),
    @ecs.With[@ui.Button],
  ],
  widget_click_events : @ecs.MessageWriter[
    @widgets_lib.WidgetClickEvent[DragAction],
  ],
) -> Unit {
  @widgets_lib.handle_ui_interactions(interactions, widget_click_events)
}

///|
fn main {
  let widget_click_message_key : @ecs.MessageKey[
    @widgets_lib.WidgetClickEvent[DragAction],
  ] = @widgets_lib.widget_click_event_key()
  @app.App::new(@ecs.World::new())
  .add_plugins(
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(configured_window()),
      primary_cursor_options: None,
      exit_condition: @window.ExitCondition::OnAllClosed,
      close_when_requested: true,
    }),
  )
  .init_resource(fn() { AppStatus::AppStatus() })
  .add_message(widget_click_message_key)
  .add_systems(
    @app.Startup,
    @app.system_config_param6(setup).named("mirror.setup"),
  )
  .add_systems(
    @app.Update,
    @app.system_config_param6(handle_window_resize_messages).named(
      "mirror.handle_window_resize_messages",
    ),
  )
  .add_systems(
    @app.Update,
    @app.system_config_param5(move_camera_on_mouse_down).named(
      "mirror.move_camera_on_mouse_down",
    ),
  )
  .add_systems(
    @app.Update,
    @app.system_config_param6(move_fox_on_mouse_down).named(
      "mirror.move_fox_on_mouse_down",
    ),
  )
  .add_systems(
    @app.Update,
    @app.system_config_param2(handle_ui_interactions).named(
      "mirror.handle_ui_interactions",
    ),
  )
  .add_systems(
    @app.Update,
    @app.system_config_param2(handle_mouse_action_change)
    .named("mirror.handle_mouse_action_change")
    .run_if_on_message(widget_click_message_key),
  )
  .add_systems(
    @app.Update,
    @app.system_config_param3(update_radio_buttons).named(
      "mirror.update_radio_buttons",
    ),
  )
  .add_systems(
    @app.Update,
    @app.system_config_param3(
      update_mirror_camera_on_main_camera_transform_change,
    ).named("mirror.update_mirror_camera_on_main_camera_transform_change"),
  )
  .add_systems(
    @app.Update,
    @app.system_config_param4(play_fox_animation).named(
      "mirror.play_fox_animation",
    ),
  )
  .add_systems(
    @app.Update,
    @app.system_config_param2(update_help_text).named("mirror.update_help_text"),
  )
  .run()
}
